import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/providers.dart';
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

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    GoogleSignIn.instance,
    googleServerClientId: ref.watch(flavorProvider).googleServerClientId,
    claimGuestReports: (token) => FirebaseFunctions.instanceFor(
      region: 'us-east1',
    ).httpsCallable('claimGuestReports').call<void>({'guestIdToken': token}),
  ),
);

/// Emits on sign-in, sign-out, linking and profile changes.
final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

/// Wraps Firebase Auth. Every new user starts as an anonymous guest; signing
/// in with Google or email links that credential to the same user ID so
/// guest reports are kept.
class AuthRepository {
  AuthRepository(
    this._auth,
    this._google, {
    required this.googleServerClientId,
    required this.claimGuestReports,
  });

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final String googleServerClientId;

  /// Server call that moves a guest's reports to the signed-in account.
  final Future<void> Function(String guestIdToken) claimGuestReports;
  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;

  Future<void> ensureGuest() async {
    if (_auth.currentUser != null) return;
    await _guard(_auth.signInAnonymously);
  }

  Future<void> signInWithGoogle() async {
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
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    await _linkOrSignIn(credential);
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

  Future<void> deleteAccount() async {
    await _guard(() async => _auth.currentUser?.delete());
    if (_googleReady) await _google.signOut();
    await ensureGuest();
  }

  Future<void> _linkOrSignIn(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      await _guard(() => _auth.signInWithCredential(credential));
      return;
    }
    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') throw _map(e);
      // The account already exists: sign in to it and bring the guest's
      // reports along.
      await _switchFromGuest(
        () => _auth.signInWithCredential(e.credential ?? credential),
      );
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
      'network-request-failed' => AuthFailure.network,
      _ => AuthFailure.unknown,
    },
  );
}
