import 'package:flutter/material.dart';

/// Empty-state body used by screens that later milestones fill in.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PlaceholderBody(icon: icon, message: message),
  );
}

/// The centred icon and message of [PlaceholderView], for screens that
/// have their own app bar. [action] goes under the message.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({
    required this.icon,
    required this.message,
    this.title,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    final action = this.action;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }
}
