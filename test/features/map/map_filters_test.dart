import 'package:fixburgh/features/map/map_filters.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 18);

Report _report({
  ReportCategory category = ReportCategory.pothole,
  ReportStatus status = ReportStatus.reported,
  int ageDays = 1,
  int? fixedDaysAgo,
  String author = 'a',
}) => Report(
  id: 'r',
  authorUid: author,
  category: category,
  severity: Severity.medium,
  status: status,
  location: const GeoPoint(40.44, -80),
  municipalityName: 'Pittsburgh',
  createdAt: _now.subtract(Duration(days: ageDays)),
  resolvedAt: fixedDaysAgo == null
      ? null
      : _now.subtract(Duration(days: fixedDaysAgo)),
);

void main() {
  bool matches(MapFilters f, Report r, {Set<String> blocked = const {}}) =>
      f.matches(r, blocked: blocked, now: _now);

  test('defaults: open reports from the last 90 days', () {
    const f = MapFilters();
    expect(f.timeRange, TimeRange.quarter);
    expect(matches(f, _report(ageDays: 89)), isTrue);
    expect(matches(f, _report(ageDays: 91)), isFalse);
    expect(
      matches(f, _report(status: ReportStatus.resolved, fixedDaysAgo: 1)),
      isFalse,
    );
  });

  test('"Show fixed" reveals fixed reports inside the range', () {
    const f = MapFilters(showFixed: true);
    expect(
      matches(f, _report(status: ReportStatus.resolved, fixedDaysAgo: 40)),
      isTrue,
    );
    // An old report fixed recently still shows.
    expect(
      matches(
        f,
        _report(status: ReportStatus.resolved, ageDays: 200, fixedDaysAgo: 3),
      ),
      isTrue,
    );
  });

  test('category filter and "all time"', () {
    const f = MapFilters(
      categories: {ReportCategory.landslide},
      timeRange: TimeRange.all,
    );
    expect(matches(f, _report(category: ReportCategory.landslide)), isTrue);
    expect(matches(f, _report(ageDays: 900)), isFalse);
    expect(
      matches(f, _report(category: ReportCategory.landslide, ageDays: 900)),
      isTrue,
    );
  });

  test('hides people this user blocked', () {
    expect(
      matches(const MapFilters(), _report(author: 'x'), blocked: {'x'}),
      isFalse,
    );
  });
}
