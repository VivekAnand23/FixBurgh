import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far back the map looks (BRD FR-MAP-05; default 90 days).
enum TimeRange {
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  quarter(Duration(days: 90)),
  year(Duration(days: 365)),
  all(null);

  const TimeRange(this.duration);

  final Duration? duration;
}

@immutable
class MapFilters {
  const MapFilters({
    this.categories = const {},
    this.showFixed = false,
    this.timeRange = TimeRange.quarter,
  });

  /// Empty means every category.
  final Set<ReportCategory> categories;

  /// Open reports only unless set (FR-MAP-05, FR-MAP-10).
  final bool showFixed;
  final TimeRange timeRange;

  MapFilters copyWith({
    Set<ReportCategory>? categories,
    bool? showFixed,
    TimeRange? timeRange,
  }) => MapFilters(
    categories: categories ?? this.categories,
    showFixed: showFixed ?? this.showFixed,
    timeRange: timeRange ?? this.timeRange,
  );

  /// Whether [r] passes the filters. [blocked] are people this user hid.
  bool matches(Report r, {required Set<String> blocked, DateTime? now}) {
    if (blocked.contains(r.authorUid)) return false;
    if (categories.isNotEmpty && !categories.contains(r.category)) {
      return false;
    }
    if (!r.isOpen && !showFixed) return false;
    final range = timeRange.duration;
    if (range == null) return true;
    final since = (now ?? DateTime.now()).subtract(range);
    // A fix inside the range counts even if the report is older.
    final latest = r.resolvedAt ?? r.createdAt;
    return latest.isAfter(since);
  }
}

/// Map filters for this app session (FR-MAP-05 "persist per session").
final mapFiltersProvider = NotifierProvider<MapFiltersController, MapFilters>(
  MapFiltersController.new,
);

class MapFiltersController extends Notifier<MapFilters> {
  @override
  MapFilters build() => const MapFilters();

  void toggleCategory(ReportCategory c) => state = state.copyWith(
    categories: state.categories.contains(c)
        ? ({...state.categories}..remove(c))
        : {...state.categories, c},
  );

  // ignore: avoid_positional_boolean_parameters, matches onSelected.
  void setShowFixed(bool v) => state = state.copyWith(showFixed: v);

  void setTimeRange(TimeRange t) => state = state.copyWith(timeRange: t);
}
