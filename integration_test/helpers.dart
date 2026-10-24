// Shared helpers for the walkthrough tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which side of a two-device walkthrough this run plays.
const role = String.fromEnvironment('ROLE', defaultValue: 'admin');

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
