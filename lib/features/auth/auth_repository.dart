import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Why a sign-in attempt failed, mapped to user-facing messages in the UI.
enum AuthFailure {
  cancelled,
  invalidEmail,
  weakPassword,
  invalidCredentials,
  emailInUse,
  credentialInUse,
  requiresRecentLogin,
  providerDisabled,
  network,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// What happens to a deleted account's reports (BRD journey 6.5).
enum ReportsOnDelete { anonymize, delete }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final functions = FirebaseFunctions.instanceFor(region: 'us-east1');
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    GoogleSignIn.instance,
    googleServerClientId: ref.watch(flavorProvider).googleServerClientId,
    claimGuestReports: (token) => functions
        .httpsCallable('claimGuestReports')
        .call<void>({'guestIdToken': token}),
    deleteAccountData: (reports) => functions
        .httpsCallable('deleteAccount')
        .call<void>({'reports': reports.name}),
  );
});

/// Sign in with Apple is offered on iOS, where App Store guideline 4.8
/// requires it next to Google sign-in.
bool get appleSignInAvailable =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Emits on sign-in, sign-out, linking and profile changes.
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

/// Wraps Firebase Auth. Every new user starts as an anonymous guest; signing
/// in with Google, Apple or email links that credential to the same user ID
/// so guest reports are kept.
class AuthRepository {
  AuthRepository(
    this._auth,
    this._google, {
    required this.googleServerClientId,
    required this.claimGuestReports,
    required this.deleteAccountData,
  });

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final String googleServerClientId;

  /// Server call that moves a guest's reports to the signed-in account.
  final Future<void> Function(String guestIdToken) claimGuestReports;

  /// Server call that deletes the account, its votes and (per the user's
  /// choice) its reports and photos.
  final Future<void> Function(ReportsOnDelete reports) deleteAccountData;
  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;

  Future<void> ensureGuest() async {
    if (_auth.currentUser != null) return;
    await _guard(_auth.signInAnonymously);
  }

  Future<void> signInWithGoogle() async {
    final credential = await _googleCredential();
    await _linkOrSignIn(
      link: (guest) => guest.linkWithCredential(credential),
      signIn: (existing) => _auth.signInWithCredential(existing ?? credential),
    );
  }

  /// Uses Firebase's Apple provider: the native sheet on iOS. Apple only
  /// shares the name and email the first time, and may hide the email.
  Future<void> signInWithApple() {
    final provider = _appleProvider();
    return _linkOrSignIn(
      link: (guest) => guest.linkWithProvider(provider),
      // Reuse the credential Apple just issued so the sheet doesn't show
      // twice.
      signIn: (existing) => existing != null
          ? _auth.signInWithCredential(existing)
          : _auth.signInWithProvider(provider),
    );
  }

  static AppleAuthProvider _appleProvider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  Future<AuthCredential> _googleCredential() async {
    if (!_googleReady) {
      await _google.initialize(serverClientId: googleServerClientId);
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown,
      );
    }
    return GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
  }

  /// Creates an email account by upgrading the current guest.
  Future<void> createEmailAccount(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final user = _auth.currentUser;
    await _guard(() async {
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      await _auth.currentUser?.sendEmailVerification();
    });
  }

  Future<void> signInWithEmail(String email, String password) =>
      _switchFromGuest(
        () =>
            _auth.signInWithEmailAndPassword(email: email, password: password),
      );

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  /// Signs out, then continues as a fresh guest.
  Future<void> signOut() async {
    if (_googleReady) await _google.signOut();
    await _auth.signOut();
    await ensureGuest();
  }

  /// The sign-in method of the current account, e.g. `google.com`,
  /// `apple.com` or `password`; `anonymous` for guests.
  String get signInMethod {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return 'anonymous';
    final ids = user.providerData.map((p) => p.providerId).toList();
    return ids.isEmpty ? 'password' : ids.first;
  }

  /// Deletes the account on the server (FR-PRF-04), then continues as a
  /// fresh guest. Throws [AuthFailure.requiresRecentLogin] when the user
  /// must confirm who they are first (see [reauthenticate]).
  Future<void> deleteAccount(ReportsOnDelete reports) async {
    try {
      await deleteAccountData(reports);
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        e.code == 'failed-precondition'
            ? AuthFailure.requiresRecentLogin
            : e.code == 'unavailable'
            ? AuthFailure.network
            : AuthFailure.unknown,
      );
    }
    if (_googleReady) await _google.signOut();
    await _auth.signOut();
    await ensureGuest();
  }

  /// Signs in again with the account's own method. [password] is needed
  /// for email accounts.
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    await _guard(() async {
      switch (signInMethod) {
        case 'google.com':
          await user.reauthenticateWithCredential(await _googleCredential());
        case 'apple.com':
          await user.reauthenticateWithProvider(_appleProvider());
        default:
          await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(
              email: user.email ?? '',
              password: password ?? '',
            ),
          );
      }
    });
  }

  /// Links a new credential to the guest so its user ID (and reports) stay
  /// the same. With no guest, or when the credential already has an
  /// account, signs in to that account instead. [signIn] gets the
  /// credential Firebase returned with the "already in use" error, if any.
  Future<void> _linkOrSignIn({
    required Future<void> Function(User guest) link,
    required Future<void> Function(AuthCredential? existing) signIn,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      await _guard(() => signIn(null));
      return;
    }
    try {
      await link(user);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') throw _map(e);
      // The account already exists: sign in to it and bring the guest's
      // reports along.
      await _switchFromGuest(() => signIn(e.credential));
      throw const AuthException(AuthFailure.credentialInUse);
    }
  }

  /// Runs [signIn], then moves the previous guest's reports to the new
  /// account. A failed move never blocks signing in.
  Future<void> _switchFromGuest(Future<void> Function() signIn) async {
    final guest = _auth.currentUser;
    final token = guest != null && guest.isAnonymous
        ? await guest.getIdToken()
        : null;
    await _guard(signIn);
    if (token == null || _auth.currentUser?.uid == guest?.uid) return;
    try {
      await claimGuestReports(token);
    } on Exception {
      // Reports stay with the guest ID; nothing else to do on the device.
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  static AuthException _map(FirebaseAuthException e) => AuthException(
    switch (e.code) {
      'invalid-email' => AuthFailure.invalidEmail,
      'weak-password' ||
      'password-does-not-meet-requirements' => AuthFailure.weakPassword,
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => AuthFailure.invalidCredentials,
      'email-already-in-use' => AuthFailure.emailInUse,
      'credential-already-in-use' => AuthFailure.credentialInUse,
      'requires-recent-login' => AuthFailure.requiresRecentLogin,
      'user-mismatch' => AuthFailure.invalidCredentials,
      'operation-not-allowed' => AuthFailure.providerDisabled,
      'canceled' ||
      'cancelled' ||
      'web-context-canceled' ||
      'web-context-cancelled' => AuthFailure.cancelled,
      'network-request-failed' => AuthFailure.network,
      _ => AuthFailure.unknown,
    },
  );
}
