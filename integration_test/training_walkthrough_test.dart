// The Burghood training video walkthrough: drives the real app like a user,
// chapter by chapter, against the local Firebase emulators seeded by
// tool/training_video/seed.mjs. Each step waits for its narration (see
// tool/training_video/script.json and voice.py), and prints "STEP <id>" so
// tool/training_video/record.sh can line the voice up with the recording.
//
//   flutter test integration_test/training_walkthrough_test.dart -d <simulator> \
//     --flavor dev --dart-define=USE_EMULATORS=true --dart-define=SCREENSHOTS=true \
//     --dart-define=FEATURES=society,channels,services,monetisation \
//     --dart-define=PHOTOS=$PWD/tool/training_video/photos --plain-name "chapter a"
//
// Add --dart-define=FAST=true to rehearse without the narration pauses.
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fixburgh/app/app.dart';
import 'package:fixburgh/app/bootstrap.dart';
import 'package:fixburgh/app/flavor.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/report/presentation/steps/photo_step.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training/durations.g.dart';
import 'training/touch_indicator.dart';

const _fast = bool.fromEnvironment('FAST');
const _photos = String.fromEnvironment('PHOTOS');
const _password = 'burghood-demo-1';

/// The pdf the document upload picks.
const _pdf = '''
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 52>>stream
BT /F1 22 Tf 72 700 Td (Maple Court: pool rules) Tj ET
endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Root 1 0 R>>
%%EOF
''';

late Directory _dir;

File _photo(String name) => File('${_dir.path}/$name.jpg');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: Flavor.dev.firebaseOptions);
    await connectEmulators();
    _dir = await getTemporaryDirectory();
    for (final name in ['pothole', 'leaking-tap', 'snowy-lot', 'keys']) {
      await File('$_photos/$name.jpg').copy(_photo(name).path);
    }
    await File('${_dir.path}/pool-rules.pdf').writeAsString(_pdf.trimLeft());
    _fakeLocation();
  });

  testWidgets('chapter a: getting started', (t) async {
    await FirebaseAuth.instance.signOut();
    await _launch(t, onboarded: false);
    await _step(t, 'a1', () async {
      await _tap(t, find.text('Get started'));
      await _tap(t, find.text('Month'));
      await _tap(t, find.text('June').last);
      await _pickYear(t);
      await _tap(t, find.text('Continue'));
    });
    await _step(t, 'a2', () async {
      await _waitFor(t, find.byType(NavigationBar));
      for (final tab in ['Society', 'Report', 'Activity']) {
        await _tab(t, tab, after: 0.6);
      }
    });
    await _step(t, 'a3', () async {
      await _tab(t, 'Profile', after: 0.4);
      await _tap(t, find.widgetWithText(FilledButton, 'Sign in').first);
      // The email form starts on "Create account"; switch to signing in.
      await _tap(t, find.text('I already have an account'));
      await _type(
        t,
        find.widgetWithText(TextField, 'Email'),
        'ann@burghood.test',
      );
      await _type(t, find.widgetWithText(TextField, 'Password'), _password);
      await _tap(t, find.widgetWithText(FilledButton, 'Sign in').last);
      await _waitFor(t, find.textContaining('Signed in as'));
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter b: the community map', (t) async {
    await _signIn('ann@burghood.test');
    await _launch(t);
    await _step(t, 'b1', () async {
      await _waitFor(t, find.text('Community map'));
      await _tap(t, find.widgetWithText(FilterChip, 'Pothole').first);
      await _tap(t, find.widgetWithText(FilterChip, 'Pothole').first);
      await _tap(t, find.byTooltip('Show list'));
    });
    await _step(t, 'b2', () async {
      await _tap(t, find.textContaining('414 Grant St ·').first);
      await _tap(t, find.textContaining('Me too').last);
    });
    await _dismissSheet(t);
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter c: reporting a problem', (t) async {
    await _signIn('ann@burghood.test');
    await _launch(t);
    await _step(t, 'c1', () async {
      await _tab(t, 'Report');
      await _tap(t, find.text('On the street'));
    });
    await _step(t, 'c2', () async {
      await _tap(t, find.text('No, continue to report'));
      await _tap(t, find.text('Choose from library'));
      await _tap(t, find.widgetWithText(FilledButton, 'Next'));
    });
    await _step(t, 'c3', () async {
      await _tap(t, find.text('Use my location'));
      await _tap(t, find.widgetWithText(FilledButton, 'Next'));
      await _tap(t, find.text('Pothole'));
      await _tap(t, find.text('Urgent'));
      await _type(
        t,
        find.byType(TextField).last,
        'Deep pothole in the right lane',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(t, find.widgetWithText(FilledButton, 'Next'));
    });
    await _step(t, 'c4', () async {
      await _waitFor(t, find.text('Who fixes this?'));
      await _scroll(t, 250);
      await _tap(t, find.text('Submit report'));
      await _waitFor(t, find.byType(NavigationBar));
    });
    await _step(t, 'c5', () async {
      await _tab(t, 'Activity');
      await _tap(t, find.textContaining('right lane').first);
      await _reveal(t, find.text('Mark fixed'));
      await _tap(t, find.text('Mark fixed').last);
      await _tap(t, find.text('Mark fixed without a photo'));
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter d: your society', (t) async {
    await _signIn('ann@burghood.test');
    await _launch(t);
    await _step(t, 'd1', () async {
      await _tab(t, 'Society');
      await _tap(t, find.text('Maple Court HOA'));
      await _pause(t, 1);
      await _tap(t, find.text('Maple Court HOA').last);
    });
    await _step(t, 'd2', () async {
      await _tap(t, find.text('General'));
      await _tap(t, find.byTooltip('Add reaction').first);
      await _tap(t, find.text('👍').last);
      await _type(
        t,
        find.byType(TextField).last,
        'Thanks Raj, I will book a plumber.',
      );
      await _tap(t, find.byTooltip('Send'));
      FocusManager.instance.primaryFocus?.unfocus();
      await _back(t);
    });
    await _step(t, 'd3', () async {
      await _tap(t, find.text('Notices'));
      await _pause(t, 1.5);
      await _tap(t, find.text('Docs'));
    });
    await _step(t, 'd4', () async {
      await _tap(t, find.text('Manage'));
      await _tap(t, find.text('Approve').first);
      await _scroll(t, 350);
      await _pause(t, 1);
      await _back(t);
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter e: finding a provider', (t) async {
    await _signIn('ann@burghood.test');
    await _launch(t);
    await _step(t, 'e1', () async {
      await _tab(t, 'Society');
      await _tap(t, find.text('Services'));
      await _type(
        t,
        find.byKey(const Key('services-search')),
        'kitchen tap leaking',
      );
      FocusManager.instance.primaryFocus?.unfocus();
    });
    await _step(t, 'e2', () => _scroll(t, 280));
    await _step(t, 'e3', () async {
      await _tap(t, find.text('Steel City Plumbing').first);
      await _scroll(t, 450);
      await _tap(t, find.text('Request this provider'));
      await _type(
        t,
        find.byKey(const Key('request-title')),
        'Kitchen tap leaking',
      );
      await _type(
        t,
        find.byKey(const Key('request-description')),
        'Dripping under the sink.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(t, find.byKey(const Key('detected-plumbing')));
      await _tap(t, find.bySemanticsLabel('Choose from library'));
      await _tap(t, find.byKey(const Key('request-send')));
      await _waitFor(t, find.text('Timeline'));
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter f: for service providers', (t) async {
    await _signIn('pete@burghood.test');
    await _launch(t);
    await _step(t, 'f1', () async {
      await _tab(t, 'Activity');
      await _tap(t, find.text('Jobs'));
      await _tap(t, find.text('Kitchen tap leaking').first);
      await _tap(t, find.byKey(const Key('accept-job')));
      await _tap(t, find.byKey(const Key('start-job')));
      await _tap(t, find.byKey(const Key('complete-job')));
      await _type(
        t,
        find.byKey(const Key('completion-note')),
        'Replaced the washer.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(t, find.text('Add photo'));
      await _tap(t, find.byKey(const Key('completion-send')));
      await _waitFor(t, find.text('Work done'));
    });
    await _signIn('rosa@burghood.test');
    await _step(t, 'f2', () async {
      await _back(t);
      await _tab(t, 'Profile');
      await _tap(t, find.byKey(const Key('become-provider')));
      await _type(t, find.byKey(const Key('provider-name')), 'Rosa Cleans');
      await _type(t, find.byKey(const Key('provider-phone')), '412-555-0199');
      await _tap(t, find.byKey(const Key('cat-errands_and_grocery_runs')));
      await _type(
        t,
        find.byKey(const Key('provider-area')),
        'Brookline, Pittsburgh',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(t, find.byKey(const Key('provider-agree')));
      await _tap(t, find.byKey(const Key('provider-submit')));
      await _waitFor(t, find.text('Application sent'));
      // The recording script approves it, as the Burghood team would.
      debugPrint('ACTION approve-provider rosa@burghood.test');
      await _waitFor(
        t,
        find.byKey(const Key('payment-request')),
        timeout: const Duration(seconds: 60),
      );
      await _scroll(t, 250);
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('chapter g: closing the loop', (t) async {
    await _signIn('ann@burghood.test');
    await _launch(t);
    await _step(t, 'g1', () async {
      await _tab(t, 'Activity');
      await _tap(t, find.text('Requests'));
      await _tap(t, find.text('Kitchen tap leaking').first);
      await _tap(t, find.byKey(const Key('confirm-done')));
      await _tap(t, find.byTooltip('5 stars'));
      await _tap(t, find.byKey(const Key('send-review')));
    });
    await _step(t, 'g2', () async {
      await _back(t);
      await _tab(t, 'Profile');
      await _tap(t, find.text('Dark'));
      await _pause(t, 1.2);
      await _tap(t, find.text('System'));
      await _tap(t, find.text('Larger'));
      await _pause(t, 1);
      await _tap(t, find.text('Default'));
    });
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Picks a birth year from the long year menu, scrolling it visibly.
Future<void> _pickYear(WidgetTester t) async {
  await _tap(t, find.text('Year'));
  // Its position, once: the item used to find it scrolls away.
  final menu = t.getCenter(
    find
        .ancestor(
          of: find.text('${DateTime.now().year}').last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  for (var i = 0; i < 4; i++) {
    await t.timedDragFrom(
      menu,
      const Offset(0, -160),
      const Duration(milliseconds: 260),
    );
    await t.pump(const Duration(milliseconds: 200));
  }
  // Tap the first visible year old enough to use the app.
  for (var y = DateTime.now().year - 20; y > 1950; y--) {
    final f = find.text('$y');
    if (f.evaluate().isNotEmpty) {
      await _pause(t, 0.4);
      await t.tap(f.last, warnIfMissed: false);
      await _pause(t, 0.7);
      return;
    }
  }
  fail('No birth year visible in the menu');
}

// ---- Helpers ----

/// Answers the location plugin from here: permission granted, the phone
/// downtown. So iOS never shows its location prompt during the recording.
void _fakeLocation() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final here = <String, Object>{
    'latitude': 40.4406,
    'longitude': -79.9959,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'accuracy': 4.0,
    'altitude': 230.0,
    'altitude_accuracy': 3.0,
    'heading': 0.0,
    'heading_accuracy': 0.0,
    'speed': 0.0,
    'speed_accuracy': 0.0,
    'is_mocked': false,
  };
  messenger
    ..setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator_apple'),
      (call) async => switch (call.method) {
        'checkPermission' || 'requestPermission' => 2, // While in use.
        'isLocationServiceEnabled' => true,
        'getLocationAccuracy' || 'requestTemporaryFullAccuracy' => 1,
        'getLastKnownPosition' || 'getCurrentPosition' => here,
        _ => null,
      },
    )
    ..setMockStreamHandler(
      const EventChannel('flutter.baseflow.com/geolocator_updates_apple'),
      MockStreamHandler.inline(onListen: (_, sink) => sink.success(here)),
    );
}

Future<void> _signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: _password,
  );
}

Future<void> _launch(WidgetTester t, {bool onboarded = true}) async {
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'onboarding.welcomeSeen': true,
    if (onboarded) 'onboarding.ageConfirmed13': true,
  });
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(Flavor.dev),
        sharedPreferencesProvider.overrideWithValue(prefs),
        pickImageProvider.overrideWithValue((_) async => _photo('leaking-tap')),
        pickReportPhotoProvider.overrideWithValue(
          (_) async => _photo('pothole').path,
        ),
        pickFileProvider.overrideWithValue(
          (_) async => File('${_dir.path}/pool-rules.pdf'),
        ),
      ],
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: TouchIndicator(child: FixBurghApp()),
      ),
    ),
  );
  await _pause(t, 2);
}

/// One narrated step: prints its marker, does [actions], then waits until
/// the narration for it has finished.
Future<void> _step(
  WidgetTester t,
  String id, [
  Future<void> Function()? actions,
]) async {
  final clock = Stopwatch()..start();
  debugPrint('STEP $id');
  await _pause(t, 0.3);
  if (actions != null) await actions();
  final want = Duration(
    milliseconds: (((narration[id] ?? 2) + 0.7) * 1000).round(),
  );
  if (!_fast) {
    while (clock.elapsed < want) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
  // The recording script takes the step's screenshot here.
  debugPrint('STEP-END $id');
  await _pause(t, 0.6);
}

Future<void> _pause(WidgetTester t, double seconds) async {
  final end = DateTime.now().add(
    Duration(milliseconds: (seconds * (_fast ? 300 : 1000)).round()),
  );
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _waitFor(
  WidgetTester t,
  Finder f, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  while (!_found(f)) {
    if (DateTime.now().isAfter(end)) {
      // The recording script screenshots the screen as it is.
      debugPrint('FAILSHOT');
      await _pause(t, 2);
      fail('Timed out waiting for ${f.toString(describeSelf: true)}');
    }
    await t.pump(const Duration(milliseconds: 200));
  }
  await _pause(t, 0.4);
}

/// Whether [f] matches now. A `.first` or `.last` finder throws when there
/// is nothing yet, which here just means "not yet".
bool _found(Finder f, {bool tappable = false}) {
  try {
    return (tappable ? f.hitTestable() : f).evaluate().isNotEmpty;
    // ignore: avoid_catching_errors, a finder's way of saying "nothing yet".
  } on StateError {
    return false;
  }
}

/// Waits for [f], then scrolls it into view. A long list builds what's
/// further down only once it's scrolled near, so if [f] isn't built yet
/// after a moment, scroll down to it.
Future<void> _reveal(WidgetTester t, Finder f) async {
  final start = DateTime.now();
  final end = start.add(const Duration(seconds: 40));
  var scrolls = 0;
  while (!_found(f, tappable: true) && DateTime.now().isBefore(end)) {
    if (_found(f)) {
      // Built but off screen (above or below): bring it into view. Started,
      // not awaited: frames only advance while the test pumps.
      Scrollable.ensureVisible(
        f.evaluate().first,
        duration: const Duration(milliseconds: 450),
        alignment: 0.4,
      );
      await _pause(t, 0.8);
      if (_found(f, tappable: true)) break;
      if (scrolls++ > 25) break;
    } else if (DateTime.now().difference(start) > const Duration(seconds: 3)) {
      if (scrolls++ > 25) break;
      await _scroll(t, 220, quick: true);
    } else {
      await t.pump(const Duration(milliseconds: 200));
    }
  }
  await _waitFor(t, f, timeout: const Duration(seconds: 1));
  await _pause(t, 0.3);
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await _reveal(t, f);
  await _pause(t, 0.5);
  final target = _found(f, tappable: true) ? f.hitTestable().first : f.first;
  await t.tap(target, warnIfMissed: false);
  await _pause(t, 0.7);
}

Future<void> _tab(WidgetTester t, String label, {double after = 0.7}) async {
  final f = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  await _waitFor(t, f);
  await t.tap(f.first);
  await _pause(t, after);
}

Future<void> _back(WidgetTester t) async {
  await _pause(t, 0.5);
  final back = find.byType(BackButton);
  if (back.evaluate().isNotEmpty) {
    await t.tap(back.first);
  } else {
    await t.pageBack();
  }
  await _pause(t, 1.2);
}

Future<void> _dismissSheet(WidgetTester t) async {
  await t.tapAt(const Offset(200, 140));
  await _pause(t, 1);
}

/// Types like a person: one character at a time.
Future<void> _type(
  WidgetTester t,
  Finder field,
  String text, {
  int perChar = 28,
}) async {
  await _tap(t, field);
  final target =
      find
          .descendant(of: field, matching: find.byType(EditableText))
          .evaluate()
          .isNotEmpty
      ? find.descendant(of: field, matching: find.byType(EditableText)).first
      : field.first;
  for (var i = 1; i <= text.length; i++) {
    await t.enterText(target, text.substring(0, i));
    await t.pump(Duration(milliseconds: _fast ? 5 : perChar));
  }
  await _pause(t, 0.6);
}

/// Scrolls the main list by [dy] pixels, at a visible pace.
Future<void> _scroll(WidgetTester t, double dy, {bool quick = false}) async {
  final lists = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (lists.evaluate().isEmpty) return;
  final target = lists.hitTestable().evaluate().isNotEmpty
      ? lists.hitTestable().last
      : lists.last;
  await t.timedDrag(
    target,
    Offset(0, -dy),
    Duration(milliseconds: quick ? 250 : 700),
    warnIfMissed: false,
  );
  await _pause(t, quick ? 0.2 : 0.5);
}
