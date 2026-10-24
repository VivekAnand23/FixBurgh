// Burghood Phase 1 exit check, on a simulator or emulator against the
// local Firebase emulators. Two runs work together: an admin who claims a
// society (approved by a platform admin in the /admin console), and a
// resident who finds it, asks to join and, once approved, reads a notice
// and a PDF.
//
//   firebase emulators:start --project fixburgh-dev
//   flutter test integration_test/society_walkthrough_test.dart -d <device> \
//     --flavor dev --dart-define=USE_EMULATORS=true \
//     --dart-define=FEATURES=society --dart-define=ROLE=admin   # or resident
//
// The test prints "SHOT <name>" and pauses at key screens so a script can
// take screenshots from outside.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

const role = String.fromEnvironment('ROLE', defaultValue: 'admin');
const societyName = 'Grant Street Lofts';
const address = '414 Grant St, Pittsburgh, PA 15219';
const noticeTitle = 'Water off Tuesday';
const documentTitle = 'Bylaws 2026';

/// A one-page PDF, enough for Storage and the browser.
const _pdf = '''
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 66>>stream
BT /F1 24 Tf 72 700 Td (Grant Street Lofts: test document) Tj ET
endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Root 1 0 R>>
%%EOF
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File idFile;
  late File proofFile;
  late File pdfFile;

  setUpAll(() async {
    await Firebase.initializeApp(options: Flavor.dev.firebaseOptions);
    await connectEmulators();
    final dir = await getTemporaryDirectory();
    final png = await rootBundle.load('Images/AppIcon.png');
    idFile = await File(
      '${dir.path}/test-photo-id.png',
    ).writeAsBytes(png.buffer.asUint8List());
    proofFile = await File(
      '${dir.path}/test-proof-of-office.pdf',
    ).writeAsString(_pdf.trimLeft());
    pdfFile = await File(
      '${dir.path}/bylaws.pdf',
    ).writeAsString(_pdf.trimLeft());
  });

  Future<void> start(WidgetTester tester, String name) async {
    await FirebaseAuth.instance.signOut();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: '$role$stamp@example.test',
      password: 'emulator-$stamp',
    );
    await cred.user!.updateDisplayName(name);
    await cred.user!.reload();
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
          pickImageProvider.overrideWithValue((_) async => idFile),
          pickFileProvider.overrideWithValue(
            (ext) async => ext.length == 1 ? pdfFile : proofFile,
          ),
        ],
        child: const FixBurghApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('Phase 1 walkthrough as $role', (tester) async {
    if (role == 'admin') {
      await adminWalkthrough(tester, start);
    } else {
      await residentWalkthrough(tester, start);
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}

typedef Start = Future<void> Function(WidgetTester, String);

Future<void> adminWalkthrough(WidgetTester tester, Start start) async {
  await start(tester, 'Ann Lee');
  await openSocietyTab(tester);
  await waitFor(tester, find.text('Find your society'));
  await shot(tester, 'find-your-society');

  // Claim the society.
  await tapText(tester, "I'm the admin, create it");
  await waitFor(tester, find.text('Society name'));
  await enter(tester, 'Society name', societyName);
  await enter(tester, 'Address', address);
  await tester.tap(find.byTooltip('Check address'));
  await waitFor(tester, find.textContaining('In City of Pittsburgh'));
  await enter(tester, 'Number of homes', '84');
  await tapText(tester, 'President');
  await enter(tester, 'Company name', 'Acme Property Management');
  await enter(tester, 'Website', 'acme-hoa.example.com');
  await enter(
    tester,
    'Account section link',
    'https://acme-hoa.example.com/residents',
  );
  await shot(tester, 'create-society-details');
  await tapText(tester, 'Photos', first: true);
  await tapText(tester, 'Files', first: false);
  await reveal(tester, find.byType(CheckboxListTile));
  await tester.tap(find.byType(CheckboxListTile));
  await settle(tester);
  await shot(tester, 'create-society-documents');
  await tapText(tester, 'Send for review');

  await waitFor(tester, find.text('Checking $societyName'));
  await shot(tester, 'claim-pending');
  debugPrint('WAITING_FOR_APPROVAL: approve "$societyName" in /admin');
  await waitFor(
    tester,
    find.text('$societyName is live'),
    timeout: const Duration(minutes: 20),
  );
  await shot(tester, 'claim-approved');
  await tapText(tester, 'Open my society');
  await waitFor(tester, find.textContaining("You're an admin"));
  await shot(tester, 'society-home-admin');

  // Wait for the resident's request and approve it.
  debugPrint('WAITING_FOR_REQUEST');
  await tapText(tester, 'Manage');
  await waitFor(
    tester,
    find.text('Approve'),
    timeout: const Duration(minutes: 20),
  );
  await shot(tester, 'manage');
  await tapText(tester, 'Approve');
  await waitFor(tester, find.text('No requests waiting.'));

  // A notice and a document for members.
  await tapText(tester, 'New notice');
  await enter(tester, 'Title', noticeTitle);
  await enter(
    tester,
    'Message',
    'The water is off from 9 to 12 for pipe repairs.',
  );
  await shot(tester, 'new-notice');
  await tapText(tester, 'Post notice');
  await waitFor(tester, find.text('Join requests'));
  await tapText(tester, 'Upload document');
  await tapText(tester, 'Choose a PDF');
  await enter(tester, 'Title', documentTitle);
  await tapText(tester, 'Upload');
  await waitFor(tester, find.text('Join requests'));
  await tester.pageBack();
  await waitFor(tester, find.text(noticeTitle));
  await shot(tester, 'society-home-notice');
  await tapText(tester, 'Docs');
  await waitFor(tester, find.text(documentTitle));
  await shot(tester, 'society-docs');
  await tapText(tester, 'Members');
  await waitFor(tester, find.text('Nia Patel'));
  await shot(tester, 'society-members');
  debugPrint('ADMIN_DONE');
}

Future<void> residentWalkthrough(WidgetTester tester, Start start) async {
  await start(tester, 'Nia Patel');
  await openSocietyTab(tester);
  await waitFor(tester, find.text('Find your society'));

  // Wait until the admin's claim is approved and the society is live.
  final societies = FirebaseFirestore.instance
      .collection('societies')
      .where('status', isEqualTo: 'active')
      .where('nameLower', isEqualTo: societyName.toLowerCase());
  final end = DateTime.now().add(const Duration(minutes: 25));
  while ((await societies.get(
    const GetOptions(source: Source.server),
  )).docs.isEmpty) {
    if (DateTime.now().isAfter(end)) fail('The society never went live.');
    await settle(tester, seconds: 5);
  }
  debugPrint('SOCIETY_LIVE');

  // Then find it the way a resident would: by address, or by name when
  // the platform geocoder isn't set up (as on some emulators).
  await tester.enterText(find.byType(TextField).first, address);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  try {
    await waitFor(
      tester,
      find.text(societyName),
      timeout: const Duration(seconds: 20),
    );
  } on TestFailure {
    debugPrint('ADDRESS_SEARCH_EMPTY: searching by name');
    await tester.enterText(find.byType(TextField).first, 'Grant Street');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await waitFor(tester, find.text(societyName));
  }
  await shot(tester, 'find-results');

  // Not a member yet: the rules keep notices out of reach.
  final society = await societies.get();
  final sid = society.docs.first.id;
  try {
    await FirebaseFirestore.instance
        .collection('societies/$sid/notices')
        .get(const GetOptions(source: Source.server));
    fail('A non-member read the notices.');
  } on FirebaseException catch (e) {
    expect(e.code, 'permission-denied');
    debugPrint('NON_MEMBER_REFUSED: ${e.code}');
  }

  await tapText(tester, 'Request to join');
  await waitFor(tester, find.text('Join $societyName'));
  await tester.enterText(find.byType(TextField).last, '4B');
  await settle(tester);
  await shot(tester, 'join-request');
  await tester.tap(find.widgetWithText(FilledButton, 'Request to join').last);
  await waitFor(tester, find.text('Request to join $societyName'));
  await shot(tester, 'request-pending');

  await waitFor(
    tester,
    find.textContaining("You're a member"),
    timeout: const Duration(minutes: 20),
  );
  await waitFor(
    tester,
    find.text(noticeTitle),
    timeout: const Duration(minutes: 10),
  );
  await shot(tester, 'society-home-member');
  await tapText(tester, noticeTitle);
  await waitFor(tester, find.textContaining('pipe repairs'));
  await shot(tester, 'notice');
  await tester.pageBack();
  await settle(tester);
  await tapText(tester, 'Docs');
  await waitFor(
    tester,
    find.text(documentTitle),
    timeout: const Duration(minutes: 10),
  );
  await shot(tester, 'member-docs');
  await tapText(tester, documentTitle);
  await settle(tester, seconds: 6);
  await shot(tester, 'member-pdf');
  debugPrint('RESIDENT_DONE');
}

// ---- helpers ----

Future<void> settle(WidgetTester tester, {int seconds = 1}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  await settle(tester);
}

Future<void> shot(WidgetTester tester, String name) async {
  await settle(tester);
  debugPrint('SHOT $role-$name');
  // Time for the screenshot script.
  await settle(tester, seconds: 3);
}

Future<void> openSocietyTab(WidgetTester tester) async {
  await waitFor(tester, find.byType(NavigationBar));
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Society'),
    ),
  );
  await settle(tester, seconds: 2);
}

/// The page's vertical list, if it has one.
Finder get _list => find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Waits for [finder], scrolling down the page to build it if needed.
Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.hitTestable().evaluate().isEmpty) {
    if (_list.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: _list.first,
          maxScrolls: 30,
        );
      } on Object {
        // Not built yet, or not in this list; keep waiting.
      }
    }
    if (finder.hitTestable().evaluate().isNotEmpty) break;
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $finder');
    await tester.pump(const Duration(milliseconds: 250));
  }
  await settle(tester);
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool? first,
}) async {
  final finder = find.text(text);
  await reveal(tester, finder);
  final hits = finder.hitTestable();
  await tester.tap(first == false ? hits.last : hits.first);
  await settle(tester, seconds: 2);
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(TextField),
  );
  await reveal(tester, field.first);
  await tester.enterText(field.first, text);
  await settle(tester);
}
