import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';

extension ReportCategoryLabel on ReportCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ReportCategory.pothole => l10n.catPothole,
    ReportCategory.landslide => l10n.catLandslide,
    ReportCategory.flooding => l10n.catFlooding,
    ReportCategory.streetlight => l10n.catStreetlight,
    ReportCategory.dumping => l10n.catDumping,
    ReportCategory.fallenTree => l10n.catFallenTree,
    ReportCategory.sidewalk => l10n.catSidewalk,
    ReportCategory.other => l10n.catOther,
  };
}

extension SeverityLabel on Severity {
  String label(AppLocalizations l10n) => switch (this) {
    Severity.low => l10n.sevLow,
    Severity.medium => l10n.sevMedium,
    Severity.urgent => l10n.sevUrgent,
  };
}

extension ReportStatusLabel on ReportStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ReportStatus.reported => l10n.statusReported,
    ReportStatus.sent => l10n.statusSent,
    ReportStatus.resolved => l10n.statusResolved,
  };
}
