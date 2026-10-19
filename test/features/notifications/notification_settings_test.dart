import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/notifications/push_prompt.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings default to everything on, quiet hours off', () {
    final s = NotifySettings.fromDoc(null);
    expect(s.status, isTrue);
    expect(s.nearby, isTrue);
    expect(s.quietEnabled, isFalse);
  });

  test('settings round-trip with the local UTC offset', () {
    const s = NotifySettings(
      nearby: false,
      quietEnabled: true,
      quietStart: 21 * 60,
      quietEnd: 6 * 60 + 30,
    );
    final doc = s.toDoc(utcOffsetMinutes: -240);
    expect(doc['utcOffsetMinutes'], -240);
    final back = NotifySettings.fromDoc(doc);
    expect(back.nearby, isFalse);
    expect(back.quietStart, 21 * 60);
    expect(back.quietEnd, 390);
  });

  test('saved places store only coordinates and a geohash', () {
    const p = SavedPlace(
      id: 'p1',
      kind: 'school',
      location: GeoPoint(40.4406, -79.9959),
      radiusMiles: 0.75,
    );
    final doc = p.toDoc();
    expect(
      doc.keys,
      unorderedEquals([
        'kind',
        'label',
        'lat',
        'lng',
        'geohash',
        'radiusMiles',
        'updatedAt',
      ]),
    );
    expect(doc['geohash'], startsWith('dppn'));
  });

  test('at most 3 places', () {
    SavedPlace at(String id) => SavedPlace(
      id: id,
      kind: 'home',
      location: const GeoPoint(40.44, -80),
      radiusMiles: 1,
    );
    expect(freePlaceSlot(const []), 'p1');
    expect(freePlaceSlot([at('p1'), at('p3')]), 'p2');
    expect(freePlaceSlot([at('p1'), at('p2'), at('p3')]), isNull);
  });

  testWidgets('the explanation comes before the system prompt', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const NotificationRationale(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Hear when it gets fixed'), findsOneWidget);
    await tester.ensureVisible(find.text('Turn on notifications'));
    await tester.tap(find.text('Turn on notifications'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });
}
