import 'dart:io';

import 'package:fixburgh/features/report/data/outbox.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements ReportRepository {}

void main() {
  late Directory tmp;
  late Outbox outbox;
  late String photo;

  setUpAll(() {
    registerFallbackValue(const ReportDraft());
    registerFallbackValue(const GeoPoint(0, 0));
    registerFallbackValue(ReportCategory.other);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('outbox');
    outbox = Outbox(baseDir: () async => tmp);
    photo = '${tmp.path}/picked.jpg';
    File(photo).writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  ReportDraft draft() => ReportDraft(
    photoPaths: [photo],
    location: const GeoPoint(40.44, -80),
    municipality: const Municipality(
      id: '100',
      name: 'City of Pittsburgh',
      type: 'city',
    ),
    category: ReportCategory.pothole,
    description: 'Deep one',
  );

  Future<OutboxItem> add([String id = 'r1']) =>
      outbox.add(id: id, draft: draft(), photoIds: ['p1']);

  group('Outbox', () {
    test('keeps its own copy of the photos and survives a reload', () async {
      await add();
      File(photo).deleteSync(); // The picker's copy can disappear.
      final again = await Outbox(baseDir: () async => tmp).load();
      expect(again, hasLength(1));
      final saved = again.single.draft.photoPaths.single;
      expect(File(saved).readAsBytesSync(), [1, 2, 3]);
      expect(again.single.draft.description, 'Deep one');
      expect(again.single.photoIds, ['p1']);
    });

    test('remove deletes the photo copies', () async {
      final item = await add();
      await outbox.remove('r1');
      expect(await outbox.load(), isEmpty);
      expect(File(item.draft.photoPaths.single).existsSync(), isFalse);
    });
  });

  test('retry delays double from 30 s up to an hour', () {
    expect(retryDelay(1), const Duration(seconds: 30));
    expect(retryDelay(2), const Duration(minutes: 1));
    expect(retryDelay(20), const Duration(hours: 1));
  });

  group('OutboxSender', () {
    late _Repo repo;
    final now = DateTime.utc(2026, 10, 19, 12);

    OutboxSender sender() => OutboxSender(
      outbox: outbox,
      repo: repo,
      sender: () async => (uid: 'me', isGuest: true),
      now: () => now,
    );

    setUp(() {
      repo = _Repo();
      when(() => repo.existsOnServer(any())).thenAnswer((_) async => false);
      when(
        () => repo.nearbyDuplicates(any(), any()),
      ).thenAnswer((_) async => const []);
      when(
        () => repo.submit(
          draft: any(named: 'draft'),
          uid: any(named: 'uid'),
          isGuest: any(named: 'isGuest'),
          routing: any(named: 'routing'),
          reportId: any(named: 'reportId'),
          photoIds: any(named: 'photoIds'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((i) async => i.namedArguments[#reportId] as String);
    });

    test('sends with the queued IDs and empties the outbox', () async {
      await add();
      final run = await sender().sendDue();
      expect(run, (sent: 1, waiting: 0));
      verify(
        () => repo.submit(
          draft: any(named: 'draft'),
          uid: 'me',
          isGuest: true,
          routing: any(named: 'routing'),
          reportId: 'r1',
          photoIds: ['p1'],
          source: 'offline_queue',
        ),
      ).called(1);
      expect(await outbox.load(), isEmpty);
    });

    test('an earlier send that got through is not sent twice', () async {
      await add();
      when(() => repo.existsOnServer('r1')).thenAnswer((_) async => true);
      expect((await sender().sendDue()).sent, 1);
      verifyNever(
        () => repo.submit(
          draft: any(named: 'draft'),
          uid: any(named: 'uid'),
          isGuest: any(named: 'isGuest'),
        ),
      );
    });

    test('offline: backs off and keeps the report', () async {
      await add();
      when(
        () => repo.existsOnServer(any()),
      ).thenThrow(Exception('unavailable'));
      final run = await sender().sendDue();
      expect(run, (sent: 0, waiting: 1));
      final item = (await outbox.load()).single;
      expect(item.attempts, 1);
      expect(item.nextAttemptAt, now.add(const Duration(seconds: 30)));
      // Not due again until the delay passes.
      expect((await sender().sendDue()).sent, 0);
      verify(() => repo.existsOnServer(any())).called(1);
    });

    test('gives up after repeated failures until retried', () async {
      await add();
      await outbox.update(
        (await outbox.load()).single.copyWith(attempts: maxSendAttempts - 1),
      );
      when(() => repo.existsOnServer(any())).thenThrow(Exception('rules'));
      final run = await sender().sendDue(force: true);
      expect((await outbox.load()).single.status, OutboxStatus.failed);
      // Waiting on the person now, so the background task can stop.
      expect(run.waiting, 0);
    });

    test(
      "a neighbor's report nearby waits for the person to decide",
      () async {
        await add();
        when(() => repo.nearbyDuplicates(any(), any())).thenAnswer(
          (_) async => [
            Report(
              id: 'theirs',
              authorUid: 'someone',
              category: ReportCategory.pothole,
              severity: Severity.medium,
              status: ReportStatus.reported,
              location: const GeoPoint(40.44, -80),
              municipalityName: 'Pittsburgh',
              createdAt: now,
            ),
          ],
        );
        final run = await sender().sendDue();
        expect(run, (sent: 0, waiting: 0));
        final item = (await outbox.load()).single;
        expect(item.status, OutboxStatus.duplicate);
        expect(item.duplicateOfId, 'theirs');

        // "Send anyway" skips the check.
        await outbox.update(
          item.copyWith(sendAnyway: true, status: OutboxStatus.waiting),
        );
        expect((await sender().sendDue()).sent, 1);
      },
    );

    test('daily limit: waits until tomorrow', () async {
      await add();
      when(
        () => repo.submit(
          draft: any(named: 'draft'),
          uid: any(named: 'uid'),
          isGuest: any(named: 'isGuest'),
          routing: any(named: 'routing'),
          reportId: any(named: 'reportId'),
          photoIds: any(named: 'photoIds'),
          source: any(named: 'source'),
        ),
      ).thenThrow(const DailyLimitReached(isGuest: true));
      await sender().sendDue();
      final item = (await outbox.load()).single;
      expect(item.status, OutboxStatus.limitReached);
      expect(item.nextAttemptAt, DateTime.utc(2026, 10, 20));
      expect(item.isDue(DateTime.utc(2026, 10, 20, 1)), isTrue);
    });
  });
}
