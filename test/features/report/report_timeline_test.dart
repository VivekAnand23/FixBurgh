import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/status_timeline.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Report _report({
  ReportStatus status = ReportStatus.resolved,
  DateTime? sentAt,
  DateTime? resolvedAt,
  String? resolvedBy,
}) => Report(
  id: 'r',
  category: ReportCategory.pothole,
  severity: Severity.medium,
  status: status,
  location: const GeoPoint(40.44, -80),
  municipalityName: 'Pittsburgh',
  createdAt: DateTime(2026, 9),
  sentAt: sentAt,
  resolvedAt: resolvedAt,
  resolvedBy: resolvedBy,
);

void main() {
  test('rebuilds history from timestamps when no events were recorded', () {
    final r = _report(
      sentAt: DateTime(2026, 9, 2),
      resolvedAt: DateTime(2026, 9, 10),
      resolvedBy: 'community',
    );
    final t = reportTimeline(r, const []);
    expect(t.map((e) => e.type), [
      ReportEventType.reported,
      ReportEventType.sent,
      ReportEventType.resolved,
    ]);
    expect(t.last.by, 'community');
  });

  test('uses recorded events, oldest first', () {
    final events = [
      ReportEvent(type: ReportEventType.reopened, at: DateTime(2026, 9, 12)),
      ReportEvent(type: ReportEventType.reported, at: DateTime(2026, 9)),
      ReportEvent(type: ReportEventType.resolved, at: DateTime(2026, 9, 10)),
    ];
    expect(reportTimeline(_report(), events).map((e) => e.type), [
      ReportEventType.reported,
      ReportEventType.resolved,
      ReportEventType.reopened,
    ]);
  });

  test('can reopen within 30 days, back to the earlier open status', () {
    final fixed = _report(
      sentAt: DateTime(2026, 9, 2),
      resolvedAt: DateTime(2026, 9, 10),
    );
    expect(fixed.canReopen(now: DateTime(2026, 10, 9)), isTrue);
    expect(fixed.canReopen(now: DateTime(2026, 10, 11)), isFalse);
    expect(fixed.reopenStatus, ReportStatus.sent);
    expect(_report().reopenStatus, ReportStatus.reported);
    expect(
      _report(status: ReportStatus.reported).canReopen(),
      isFalse,
    );
  });

  testWidgets('timeline shows each step with its channel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatusTimelineView(
            events: [
              ReportEvent(
                type: ReportEventType.reported,
                at: DateTime(2026, 9),
              ),
              ReportEvent(
                type: ReportEventType.sent,
                at: DateTime(2026, 9, 2),
                channel: 'call',
              ),
              ReportEvent(
                type: ReportEventType.resolved,
                at: DateTime(2026, 9, 10),
                by: 'community',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Sent to agency by phone'), findsOneWidget);
    expect(find.text('Confirmed fixed by neighbors'), findsOneWidget);
  });
}
