import 'package:fixburgh/features/report/data/draft_store.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/report/presentation/steps/details_step.dart';
import 'package:fixburgh/features/report/presentation/steps/location_step.dart';
import 'package:fixburgh/features/report/presentation/steps/photo_step.dart';
import 'package:fixburgh/features/report/presentation/steps/review_step.dart';
import 'package:fixburgh/features/report/presentation/steps/safety_step.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Report flow: safety check, photo, location, details, review.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerSavedDraft());
  }

  /// Offers to continue a report left unfinished when the app closed.
  Future<void> _offerSavedDraft() async {
    final saved = await ref.read(draftStoreProvider).load();
    if (saved == null || !ref.read(reportDraftProvider).isEmpty || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resumeDraftTitle),
        content: Text(l10n.resumeDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.startOver),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.continueDraft),
          ),
        ],
      ),
    );
    final notifier = ref.read(reportDraftProvider.notifier);
    if (resume != true) {
      await notifier.discard();
      return;
    }
    notifier.restore(saved);
    setState(
      () => _step = !saved.hasPhoto
          ? 1
          : !saved.hasLocation
          ? 2
          : saved.category == null
          ? 3
          : 4,
    );
  }

  static const _stepCount = 5;
  int _step = 0;

  void _next() => setState(() => _step = (_step + 1).clamp(0, _stepCount - 1));

  void _back() => setState(() => _step = (_step - 1).clamp(0, _stepCount - 1));

  void _restart() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Keeps the auto-disposing draft alive for the whole flow, including the
    // safety step, so a restored draft isn't dropped before a step reads it.
    ref.watch(reportDraftProvider.select((d) => d.isEmpty));
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reportTitle),
          leading: _step == 0 ? null : BackButton(onPressed: _back),
          bottom: _step == 0
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Semantics(
                      label: l10n.stepOf(_step, _stepCount - 1),
                      child: LinearProgressIndicator(
                        value: _step / (_stepCount - 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
        ),
        body: SafeArea(
          child: switch (_step) {
            0 => SafetyStep(onContinue: _next),
            1 => PhotoStep(onNext: _next),
            2 => LocationStep(onNext: _next),
            3 => DetailsStep(onNext: _next),
            _ => ReviewStep(
              onEditStep: (s) => setState(() => _step = s),
              onSubmitted: _restart,
            ),
          },
        ),
      ),
    );
  }
}
