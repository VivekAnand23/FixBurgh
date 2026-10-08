import 'dart:io';

import 'package:fixburgh/features/report/data/draft_store.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late File photo;
  late Directory base;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    base = Directory.systemTemp.createTempSync();
    photo = File('${base.path}/draft_photos/p.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
  });

  DraftStore store(SharedPreferences prefs, {DateTime Function()? now}) =>
      DraftStore(prefs, now: now, baseDir: () async => base);

  ReportDraft sample() => ReportDraft(
    photoPaths: [photo.path],
    location: const GeoPoint(40.4406, -79.9959),
    accuracyM: 4,
    address: '414 Grant St, Pittsburgh',
    municipality: const Municipality(
      id: '100',
      name: 'City of Pittsburgh',
      type: 'city',
    ),
    category: ReportCategory.pothole,
    severity: Severity.urgent,
    description: 'Deep pothole',
  );

  test('a saved draft comes back with every field', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = store(prefs);
    await s.save(sample());
    final d = (await s.load())!;
    expect(d.photoPaths, [photo.path]);
    // Stored relative, so a moved app container still finds the photo.
    expect(prefs.getString('report.draft'), isNot(contains(base.path)));
    expect(d.location!.lat, 40.4406);
    expect(d.accuracyM, 4);
    expect(d.municipality!.name, 'City of Pittsburgh');
    expect(d.category, ReportCategory.pothole);
    expect(d.severity, Severity.urgent);
    expect(d.description, 'Deep pothole');
    expect(d.isComplete, isTrue);
  });

  test('drafts older than 24 hours are dropped', () async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DateTime(2026, 10, 8, 9);
    await store(prefs, now: () => saved).save(sample());
    final later = store(
      prefs,
      now: () => saved.add(const Duration(hours: 25)),
    );
    expect(await later.load(), isNull);
  });

  test('missing photos are dropped from the restored draft', () async {
    final s = store(await SharedPreferences.getInstance());
    await s.save(sample());
    photo.deleteSync();
    expect((await s.load())!.photoPaths, isEmpty);
  });

  test('an empty draft is not saved', () async {
    final s = store(await SharedPreferences.getInstance());
    await s.save(sample());
    await s.save(const ReportDraft());
    expect(await s.load(), isNull);
  });
}
