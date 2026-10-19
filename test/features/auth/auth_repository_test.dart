import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Google extends Mock implements GoogleSignIn {}

class _Info extends Mock implements UserInfo {}

class _Cred extends Mock implements UserCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppleAuthProvider());
    registerFallbackValue(
      const AuthCredential(providerId: 'x', signInMethod: 'x'),
    );
  });

  late _Auth auth;
  late _User guest;
  late User? current;
  late List<String> claimed;
  late Future<void> Function(ReportsOnDelete) deleteData;

  AuthRepository repo() => AuthRepository(
    auth,
    _Google(),
    googleServerClientId: 'id',
    claimGuestReports: (t) async => claimed.add(t),
    deleteAccountData: (r) => deleteData(r),
  );

  setUp(() {
    auth = _Auth();
    guest = _User();
    when(() => guest.isAnonymous).thenReturn(true);
    when(() => guest.uid).thenReturn('guest');
    when(() => guest.getIdToken()).thenAnswer((_) async => 'guest-token');
    current = guest;
    claimed = [];
    deleteData = (_) async {};
    when(() => auth.currentUser).thenAnswer((_) => current);
    when(() => auth.signOut()).thenAnswer((_) async => current = null);
    when(() => auth.signInAnonymously()).thenAnswer((_) async {
      current = guest;
      return _Cred();
    });
  });

  group('Sign in with Apple', () {
    test('links Apple to the guest so reports keep their owner', () async {
      when(
        () => guest.linkWithProvider(any()),
      ).thenAnswer((_) async => _Cred());
      await repo().signInWithApple();
      verify(() => guest.linkWithProvider(any())).called(1);
      verifyNever(() => auth.signInWithProvider(any()));
    });

    test(
      'an existing Apple account signs in and claims guest reports',
      () async {
        const existing = AuthCredential(
          providerId: 'apple.com',
          signInMethod: 'oauth',
        );
        when(() => guest.linkWithProvider(any())).thenThrow(
          FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: existing,
          ),
        );
        final account = _User();
        when(() => account.uid).thenReturn('account');
        when(() => account.isAnonymous).thenReturn(false);
        when(() => auth.signInWithCredential(existing)).thenAnswer((_) async {
          current = account;
          return _Cred();
        });

        await expectLater(
          repo().signInWithApple(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.failure,
              'failure',
              AuthFailure.credentialInUse,
            ),
          ),
        );
        expect(claimed, ['guest-token']);
      },
    );

    test('cancelling the Apple sheet is quiet', () async {
      when(
        () => guest.linkWithProvider(any()),
      ).thenThrow(FirebaseAuthException(code: 'canceled'));
      await expectLater(
        repo().signInWithApple(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.cancelled,
          ),
        ),
      );
    });
  });

  group('delete account', () {
    test(
      'asks to sign in again when the server needs a recent login',
      () async {
        deleteData = (_) async => throw FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'requires-recent-login',
        );
        await expectLater(
          repo().deleteAccount(ReportsOnDelete.anonymize),
          throwsA(
            isA<AuthException>().having(
              (e) => e.failure,
              'failure',
              AuthFailure.requiresRecentLogin,
            ),
          ),
        );
        verifyNever(() => auth.signOut());
      },
    );

    test('passes the choice, then continues as a new guest', () async {
      ReportsOnDelete? sent;
      deleteData = (r) async => sent = r;
      await repo().deleteAccount(ReportsOnDelete.delete);
      expect(sent, ReportsOnDelete.delete);
      verify(() => auth.signOut()).called(1);
      verify(() => auth.signInAnonymously()).called(1);
    });
  });

  test('reports the sign-in method', () {
    final user = _User();
    final info = _Info();
    when(() => info.providerId).thenReturn('apple.com');
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.providerData).thenReturn([info]);
    current = user;
    expect(repo().signInMethod, 'apple.com');
    current = guest;
    expect(repo().signInMethod, 'anonymous');
  });
}
