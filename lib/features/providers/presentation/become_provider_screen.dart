import 'dart:async';
import 'dart:io';

import 'package:fixburgh/app/links.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/presentation/category_picker.dart';
import 'package:fixburgh/features/society/data/society_repository.dart'
    show maxClaimFileBytes;
import 'package:fixburgh/features/society/presentation/create_society_screen.dart'
    show findPlaceProvider;
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Become a provider: business details, services, area and the documents
/// the services need. Documents go to private Storage only platform admins
/// can read. Shows the application's status once sent.
class BecomeProviderScreen extends ConsumerStatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  ConsumerState<BecomeProviderScreen> createState() =>
      _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends ConsumerState<BecomeProviderScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mine = ref.watch(myProviderProvider);
    final p = mine.value;
    if (mine.isLoading && !mine.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final showForm =
        p == null || _editing || p.status == ProviderStatus.rejected;
    return Scaffold(
      appBar: AppBar(
        title: Text(p == null ? l10n.becomeProvider : l10n.yourProviderProfile),
      ),
      body: showForm
          ? _ApplicationForm(
              existing: p,
              onDone: () => setState(() => _editing = false),
            )
          : _Status(provider: p, onEdit: () => setState(() => _editing = true)),
    );
  }
}

class _Status extends ConsumerWidget {
  const _Status({required this.provider, required this.onEdit});

  final ServiceProvider provider;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = provider;
    final fees =
        ref.watch(monetisationSettingsProvider).value ?? defaultMonetisation;
    final through = p.listingPaidThrough;
    final (icon, title, body) = switch (p.status) {
      ProviderStatus.applied => (
        Icons.hourglass_top,
        l10n.providerAppliedTitle,
        l10n.providerApplied,
      ),
      ProviderStatus.approved => (
        Icons.check_circle_outline,
        l10n.providerLiveTitle,
        through == null
            ? l10n.providerLive
            : l10n.listingExpiresOn(DateFormat.yMMMd().format(through)),
      ),
      ProviderStatus.awaitingFee => (
        Icons.payments_outlined,
        l10n.providerAwaitingFeeTitle,
        l10n.providerAwaitingFee(
          NumberFormat.simpleCurrency(name: 'USD').format(fees.listingFeeUsd),
          fees.listingMonths,
        ),
      ),
      ProviderStatus.suspended => (
        Icons.pause_circle_outline,
        l10n.providerSuspendedTitle,
        p.rejectReason.isEmpty ? l10n.providerSuspended : p.rejectReason,
      ),
      ProviderStatus.rejected => (
        Icons.cancel_outlined,
        l10n.providerRejected,
        p.rejectReason,
      ),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SocietyCard(
          child: Column(
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(p.businessName),
          subtitle: Text(p.areaLabel),
        ),
        if (p.status == ProviderStatus.approved) ...[
          FilledButton.icon(
            icon: const Icon(Icons.storefront_outlined),
            label: Text(l10n.viewPublicProfile),
            onPressed: () => context.push(Routes.provider(p.id)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.work_outline),
            label: Text(l10n.activityJobs),
            onPressed: () => context.go(Routes.activity),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onEdit, child: Text(l10n.editDetails)),
        ],
      ],
    );
  }
}

class _ApplicationForm extends ConsumerStatefulWidget {
  const _ApplicationForm({required this.existing, required this.onDone});

  final ServiceProvider? existing;
  final VoidCallback onDone;

  @override
  ConsumerState<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends ConsumerState<_ApplicationForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.businessName);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _area = TextEditingController(text: widget.existing?.areaLabel);
  late Set<String> _categories = {...?widget.existing?.categories};
  late double _radius = widget.existing?.radiusMiles ?? 10;
  final _documents = <String, File>{};
  bool _agreed = false;
  bool _sending = false;

  /// A live provider editing their details, not applying.
  bool get _detailsOnly =>
      widget.existing?.status == ProviderStatus.approved ||
      widget.existing?.status == ProviderStatus.suspended;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _phone.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(serviceCategoriesProvider);
    final needed = requiredDocuments(_categories, groups);
    final have = widget.existing?.documents ?? const {};
    final existing = widget.existing;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (existing?.status == ProviderStatus.rejected &&
              existing!.rejectReason.isNotEmpty) ...[
            InfoBox(text: l10n.rejectedBecause(existing.rejectReason)),
            const SizedBox(height: 16),
          ] else if (!_detailsOnly) ...[
            InfoBox(text: l10n.becomeProviderIntro),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('provider-name'),
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.businessName,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l10n.requiredField : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('provider-description'),
            controller: _description,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.aboutYourWork,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('provider-phone'),
            controller: _phone,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              helperText: l10n.phoneHelper,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => RegExp(r'^[0-9+() .-]{7,20}$').hasMatch(v ?? '')
                ? null
                : l10n.phoneInvalid,
          ),
          if (!_detailsOnly) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                l10n.providerServices,
                style: theme.textTheme.titleMedium,
              ),
            ),
            CategoryChecklist(
              groups: groups,
              selected: _categories,
              onChanged: (s) => setState(() => _categories = s),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('provider-area'),
              controller: _area,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l10n.serviceAreaLabel,
                hintText: l10n.serviceAreaHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<double>(
              initialValue: _radius,
              decoration: InputDecoration(
                labelText: l10n.travelDistance,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final m in distanceOptions)
                  DropdownMenuItem(
                    value: m.toDouble(),
                    child: Text(l10n.withinMiles(m)),
                  ),
              ],
              onChanged: (v) => setState(() => _radius = v ?? 10),
            ),
            if (needed.isNotEmpty) ...[
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  l10n.documentsNeeded,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(l10n.documentsPrivate, style: theme.textTheme.bodySmall),
              for (final kind in needed)
                ListTile(
                  key: Key('doc-$kind'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _documents.containsKey(kind) || have.containsKey(kind)
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color:
                        _documents.containsKey(kind) || have.containsKey(kind)
                        ? Colors.green.shade700
                        : null,
                  ),
                  title: Text(_docLabel(l10n, kind)),
                  subtitle: Text(
                    _documents[kind]?.path.split('/').last ??
                        (have.containsKey(kind)
                            ? l10n.alreadyUploaded
                            : l10n.docFormats),
                  ),
                  onTap: have.containsKey(kind) ? null : () => _pick(kind),
                ),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('provider-agree'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: Text(l10n.providerAgree),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('provider-rules'),
                onPressed: () => openLink(
                  context,
                  AppLinks(ref.read(flavorProvider)).providerRules,
                ),
                child: Text(l10n.readProviderRules),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('provider-submit'),
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_detailsOnly ? l10n.save : l10n.submitForReview),
          ),
          if (!_detailsOnly) ...[
            const SizedBox(height: 8),
            Text(
              l10n.reviewTarget,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _docLabel(AppLocalizations l10n, String kind) => switch (kind) {
    'license' => l10n.docLicense,
    'insurance' => l10n.docInsurance,
    _ => l10n.docBackground,
  };

  Future<void> _pick(String kind) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final f = await ref.read(pickFileProvider)(['pdf', 'jpg', 'jpeg', 'png']);
    if (f == null) return;
    if (f.lengthSync() > maxClaimFileBytes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.fileTooLarge(5))));
      return;
    }
    setState(() => _documents[kind] = f);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!_form.currentState!.validate()) return;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = ref.read(providerRepositoryProvider);
    if (_detailsOnly) {
      setState(() => _sending = true);
      try {
        await repo.updateDetails(
          uid,
          businessName: _name.text,
          description: _description.text,
          phone: _phone.text,
        );
        widget.onDone();
      } on Object {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    final groups = ref.read(serviceCategoriesProvider);
    final have = widget.existing?.documents ?? const {};
    final missing = requiredDocuments(
      _categories,
      groups,
    ).where((k) => !_documents.containsKey(k) && !have.containsKey(k));
    final problem = _categories.isEmpty
        ? l10n.pickAService
        : missing.isNotEmpty
        ? l10n.documentsMissing
        : !_agreed
        ? l10n.agreeFirst
        : null;
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _sending = true);
    try {
      final area = await ref.read(findPlaceProvider)(_area.text);
      if (area == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.areaNotFound)));
        return;
      }
      await repo.apply(
        uid: uid,
        businessName: _name.text,
        description: _description.text,
        phone: _phone.text,
        categories: _categories.toList(),
        area: area,
        radiusMiles: _radius,
        areaLabel: _area.text.trim(),
        documents: _documents,
        existing: widget.existing,
      );
      widget.onDone();
    } on Object catch (e) {
      debugPrint('Provider application failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
