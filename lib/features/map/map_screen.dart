import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderView(
      icon: Icons.map_outlined,
      title: l10n.mapTitle,
      message: l10n.mapPlaceholder,
    );
  }
}
