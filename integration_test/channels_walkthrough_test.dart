// Burghood Phase 2 exit check, on two devices against the local Firebase
// emulators. Seed them first, then run both roles at the same time:
//
//   firebase emulators:start --project fixburgh-dev
//   node firebase/test/seed-channels-walkthrough.js fixburgh-dev
//   flutter test integration_test/channels_walkthrough_test.dart -d <device> \
//     --flavor dev --dart-define=USE_EMULATORS=true \
//     --dart-define=FEATURES=society,channels --dart-define=ROLE=admin \
//     <the ADMIN_ and RESIDENT_ dart-defines the seed script prints>
//
// The admin posts in General with an @mention and a photo; the resident
// sees it arrive live, reacts and comments; the admin sees both live and
// replies; the resident sees the reply, mutes the channel, and finds the
// mention in the inbox and the mute in notification settings.
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fixburgh/app/app.dart';
import 'package:fixburgh/app/bootstrap.dart';
import 'package:fixburgh/app/flavor.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _email = role == 'admin'
    ? String.fromEnvironment('ADMIN_EMAIL')
    : String.fromEnvironment('RESIDENT_EMAIL');
const _password = role == 'admin'
    ? String.fromEnvironment('ADMIN_PASSWORD')
    : String.fromEnvironment('RESIDENT_PASSWORD');

const postText = 'Water is off in B block until noon. ';
const commentText = 'Same here since 9';
const replyText = 'The plumber is on the way';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late File photo;

  setUpAll(() async {
    await Firebase.initializeApp(options: Flavor.dev.firebaseOptions);
    await connectEmulators();
    final png = await rootBundle.load('Images/AppIcon.png');
    final dir = await getTemporaryDirectory();
    photo = await File(
      '${dir.path}/channel-photo.png',
    ).writeAsBytes(png.buffer.asUint8List());
  });

  testWidgets('Phase 2 walkthrough as $role', (tester) async {
    await FirebaseAuth.instance.signOut();
    debugPrint(
      'SIGNING_IN $role ${_email.isEmpty ? '(no email)' : _email} '
      '(${_password.length} chars)',
    );
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email,
      password: _password,
    );
    SharedPreferences.setMockInitialValues({
      'onboarding.welcomeSeen': true,
      'onboarding.ageConfirmed13': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.dev),
          sharedPreferencesProvider.overrideWithValue(prefs),
          pickImageProvider.overrideWithValue((_) async => photo),
        ],
        child: const FixBurghApp(),
      ),
    );
    await settle(tester);
    await openSocietyTab(tester);
    await waitFor(tester, find.text('Channels'));
    await waitFor(tester, find.text('General'));
    if (role == 'admin') {
      await admin(tester);
    } else {
      await resident(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}

Future<void> admin(WidgetTester tester) async {
  await tapText(tester, 'New channel');
  await tester.enterText(find.byType(TextField).last, 'Events');
  await tapText(tester, 'Save');
  await waitFor(tester, find.text('Events'));
  await shot(tester, 'channels');

  await tapText(tester, 'General');
  await waitFor(
    tester,
    find.text('Nothing here yet. Say hello to your neighbors.'),
  );
  final box = find.byType(TextField).last;
  await tester.enterText(box, '${postText}Thanks @Ni');
  await waitFor(tester, find.text('Nia Patel'));
  await shot(tester, 'mention-picker');
  await tapText(tester, 'Nia Patel');
  await tester.tap(find.byTooltip('Add photo'));
  await settle(tester);
  await tester.tap(find.byTooltip('Send'));
  await waitFor(
    tester,
    find.textContaining('Water is off', findRichText: true),
  );
  await shot(tester, 'channel-post');

  debugPrint('WAITING_FOR_RESIDENT');
  await waitFor(
    tester,
    find.text('1 comment'),
    timeout: const Duration(minutes: 15),
  );
  await waitFor(tester, find.text('👍 1'), timeout: const Duration(minutes: 5));
  await shot(tester, 'channel-live');
  await tapText(tester, '1 comment');
  await reveal(tester, find.textContaining(commentText, findRichText: true));
  await tapText(tester, 'Reply');
  await tester.enterText(find.byType(TextField).last, replyText);
  await tester.tap(find.byTooltip('Send'));
  await reveal(tester, find.textContaining(replyText, findRichText: true));
  await shot(tester, 'post-thread');
  debugPrint('ADMIN_DONE');
}

Future<void> resident(WidgetTester tester) async {
  await tapText(tester, 'General');
  debugPrint('WAITING_FOR_ADMIN');
  await waitFor(
    tester,
    find.textContaining('Water is off', findRichText: true),
    timeout: const Duration(minutes: 15),
  );
  await shot(tester, 'channel-live');

  await tester.tap(find.byTooltip('Add reaction').first);
  await settle(tester, seconds: 2);
  await tester.tap(find.text('👍').last);
  await waitFor(tester, find.text('👍 1'));
  await tapText(tester, 'Comment');
  await waitFor(tester, find.text('Write a comment'));
  await tester.enterText(find.byType(TextField).last, commentText);
  await tester.tap(find.byTooltip('Send'));
  await reveal(tester, find.textContaining(commentText, findRichText: true));
  await reveal(
    tester,
    find.textContaining(replyText, findRichText: true),
    timeout: const Duration(minutes: 10),
  );
  await shot(tester, 'post-thread');

  await tester.pageBack();
  await settle(tester, seconds: 2);
  await tester.tap(find.byTooltip('Channel options'));
  await settle(tester);
  await tapText(tester, 'Mute for 8 hours');
  await tester.pageBack();
  await settle(tester, seconds: 2);
  await shot(tester, 'channels-muted');

  await tester.tap(find.byTooltip('Notifications'));
  await waitFor(
    tester,
    find.textContaining('mentioned you'),
    timeout: const Duration(minutes: 2),
  );
  await shot(tester, 'inbox');
  await tester.pageBack();
  await settle(tester);

  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profile'),
    ),
  );
  await settle(tester, seconds: 2);
  await tapText(tester, 'Notifications');
  await waitFor(tester, find.text('Interaction notifications'));
  await reveal(tester, find.text('Muted channels'));
  await shot(tester, 'notification-settings');
  debugPrint('RESIDENT_DONE');
}
