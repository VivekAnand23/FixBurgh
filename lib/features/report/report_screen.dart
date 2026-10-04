import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      icon: Icons.add_a_photo_outlined,
      title: l10n.reportTitle,
      message: l10n.reportPlaceholder,
    );
  }
}
