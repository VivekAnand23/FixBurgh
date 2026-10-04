import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      icon: Icons.list_alt,
      title: l10n.myReportsTitle,
      message: l10n.myReportsEmpty,
    );
  }
}
