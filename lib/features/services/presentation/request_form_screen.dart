import 'dart:async';
import 'dart:io';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/presentation/outbox_controller.dart'
    show isOnline;
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/category_picker.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Most photos a request can carry, as the rules allow.
const maxRequestPhotos = 6;

/// What opens the request form: where the problem is, and optionally the
/// provider (from their profile) and category.
@immutable
class RequestFormArgs {
  const RequestFormArgs({
    required this.scope,
    this.societyId,
    this.providerId,
    this.providerName,
    this.category,
  });

  final RequestScope scope;
  final String? societyId;
  final String? providerId;
  final String? providerName;
  final String? category;
}

/// A service request: what's needed, the category (suggested from the
/// words), fields that depend on it, and up to six photos. Saved to the
/// outbox when offline.
class RequestFormScreen extends ConsumerStatefulWidget {
  const RequestFormScreen({required this.args, super.key});

  final RequestFormArgs args;

  @override
  ConsumerState<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends ConsumerState<RequestFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _details = <DetailField, String>{};
  final _photos = <File>[];
  late String? _category = widget.args.category;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(serviceCategoriesProvider);
    final args = widget.args;
    final group = _category == null ? null : groups.groupOf(_category!);
    final detected = _category != null
        ? const <ServiceCategory>[]
        : detectCategories(
            '${_title.text} ${_description.text}',
            groups,
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          args.scope == RequestScope.common
              ? l10n.commonRequestTitle
              : l10n.newRequestTitle,
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (args.providerName != null)
              InfoBox(text: l10n.sendingTo(args.providerName!))
            else if (args.scope == RequestScope.common)
              InfoBox(text: l10n.commonRequestNote),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('request-title'),
              controller: _title,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.requestTitleLabel,
                hintText: l10n.requestTitleHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('request-description'),
              controller: _description,
              maxLength: 2000,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.requestDescriptionLabel,
                hintText: l10n.requestDescriptionHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.categoryLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_category != null)
              InputChip(
                key: const Key('request-category'),
                label: Text(groups.category(_category!)?.label ?? _category!),
                onDeleted: args.category != null
                    ? null
                    : () => setState(() {
                        _category = null;
                        _details.clear();
                      }),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in detected)
                    ActionChip(
                      key: Key('detected-${c.id}'),
                      avatar: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(c.label),
                      onPressed: () => setState(() => _category = c.id),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.list, size: 16),
                    label: Text(l10n.chooseCategory),
                    onPressed: () async {
                      final c = await pickServiceCategory(context, groups);
                      if (c != null) setState(() => _category = c);
                    },
                  ),
                ],
              ),
            if (group != null) ...[
              const SizedBox(height: 16),
              for (final f in detailFieldsFor(group.id, _category!))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DetailInput(
                    field: f,
                    value: _details[f],
                    onChanged: (v) => setState(() => _details[f] = v),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.photosCount(_photos.length, maxRequestPhotos),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, f) in _photos.indexed)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          f,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.photoNumber(i + 1),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.removePhoto,
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _photos.removeAt(i)),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < maxRequestPhotos) ...[
                  _AddPhoto(
                    icon: Icons.photo_camera_outlined,
                    label: l10n.takePhoto,
                    onTap: () => _addPhoto(ImageSource.camera),
                  ),
                  _AddPhoto(
                    icon: Icons.photo_library_outlined,
                    label: l10n.chooseFromLibrary,
                    onTap: () => _addPhoto(ImageSource.gallery),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('request-send'),
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(l10n.sendRequest),
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    final f = await ref.read(pickImageProvider)(source);
    if (f != null && mounted) setState(() => _photos.add(f));
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!_form.currentState!.validate()) return;
    final groups = ref.read(serviceCategoriesProvider);
    if (_category == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pickCategoryFirst)));
      return;
    }
    final user = ref.read(authUserProvider).value;
    if (user == null) return;
    final args = widget.args;
    final society = args.societyId == null
        ? null
        : ref.read(societyProvider(args.societyId!)).value;
    final me = args.societyId == null
        ? null
        : ref.read(myMembershipProvider(args.societyId!)).value;
    final draft = (
      scope: args.scope,
      // A home request is tied to the society only for its location.
      societyId: args.scope == RequestScope.common ? args.societyId : null,
      title: _title.text,
      description: _description.text,
      category: _category!,
      group: groups.groupOf(_category!)?.id ?? '',
      details: {
        for (final MapEntry(:key, :value) in _details.entries)
          if (value.trim().isNotEmpty) key.name: value.trim(),
      },
      photos: List.of(_photos),
      location: society?.location,
      providerId: args.providerId,
    );
    final name = me?.displayName ?? user.displayName ?? '';
    setState(() => _sending = true);
    final repo = ref.read(serviceRequestRepositoryProvider);
    final id = repo.newId();
    String? posted;
    try {
      if (await isOnline()) {
        posted = await repo
            .post(draft, uid: user.uid, posterName: name, id: id)
            .timeout(const Duration(seconds: 45));
      }
    } on Object catch (e) {
      debugPrint('Request: post failed, saving for later ($e)');
    }
    if (posted == null) {
      await ref
          .read(requestOutboxProvider.notifier)
          .enqueue(id, draft, posterName: name);
    }
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(posted == null ? l10n.requestQueued : l10n.requestSent),
      ),
    );
    context.pop();
    if (posted != null) unawaited(context.push(Routes.serviceRequest(posted)));
  }
}

class _AddPhoto extends StatelessWidget {
  const _AddPhoto({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Icon(icon),
      ),
    ),
  );
}

/// One category-specific field: a choice, a date, or free text.
class _DetailInput extends StatelessWidget {
  const _DetailInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final DetailField field;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = detailLabel(l10n, field);
    final options = detailOptions(l10n, field);
    if (options != null) {
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final MapEntry(:key, value: text) in options.entries)
            DropdownMenuItem(value: key, child: Text(text)),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      );
    }
    if (field == DetailField.date) {
      final date = DateTime.tryParse(value ?? '');
      return OutlinedButton.icon(
        icon: const Icon(Icons.event),
        label: Text(
          date == null ? label : '$label: ${DateFormat.yMMMEd().format(date)}',
        ),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            firstDate: now,
            lastDate: now.add(const Duration(days: 180)),
            initialDate: date ?? now,
          );
          if (picked != null) {
            onChanged(DateFormat('yyyy-MM-dd').format(picked));
          }
        },
      );
    }
    return TextFormField(
      initialValue: value,
      maxLength: 100,
      keyboardType: field == DetailField.hours
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: detailHint(l10n, field),
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      onChanged: onChanged,
    );
  }
}

String detailLabel(AppLocalizations l10n, DetailField f) => switch (f) {
  DetailField.urgency => l10n.detailUrgency,
  DetailField.access => l10n.detailAccess,
  DetailField.timeWindow => l10n.detailTimeWindow,
  DetailField.date => l10n.detailDate,
  DetailField.hours => l10n.detailHours,
  DetailField.childrenAges => l10n.detailChildrenAges,
  DetailField.petType => l10n.detailPetType,
  DetailField.petSize => l10n.detailPetSize,
  DetailField.budget => l10n.detailBudget,
};

String? detailHint(AppLocalizations l10n, DetailField f) => switch (f) {
  DetailField.access => l10n.detailAccessHint,
  DetailField.childrenAges => l10n.detailChildrenAgesHint,
  DetailField.budget => l10n.detailBudgetHint,
  _ => null,
};

/// The choices for a field picked from a list, by stored value.
Map<String, String>? detailOptions(AppLocalizations l10n, DetailField f) =>
    switch (f) {
      DetailField.urgency => {
        'emergency': l10n.urgencyEmergency,
        'soon': l10n.urgencySoon,
        'flexible': l10n.urgencyFlexible,
      },
      DetailField.timeWindow => {
        'morning': l10n.windowMorning,
        'afternoon': l10n.windowAfternoon,
        'evening': l10n.windowEvening,
        'any': l10n.windowAny,
      },
      DetailField.petType => {
        'dog': l10n.petDog,
        'cat': l10n.petCat,
        'other': l10n.petOther,
      },
      DetailField.petSize => {
        'small': l10n.sizeSmall,
        'medium': l10n.sizeMedium,
        'large': l10n.sizeLarge,
      },
      _ => null,
    };

/// A stored detail as shown on the request.
String detailValue(AppLocalizations l10n, String key, String value) {
  final f = DetailField.values.where((f) => f.name == key).firstOrNull;
  if (f == null) return value;
  if (f == DetailField.date) {
    final d = DateTime.tryParse(value);
    if (d != null) return DateFormat.yMMMEd().format(d);
  }
  return detailOptions(l10n, f)?[value] ?? value;
}
