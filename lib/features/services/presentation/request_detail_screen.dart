import 'dart:async';
import 'dart:io';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/providers/presentation/provider_profile_screen.dart'
    show showTextDialog;
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart'
    show detailLabel, detailValue, maxRequestPhotos;
import 'package:fixburgh/features/services/presentation/service_widgets.dart';
import 'package:fixburgh/features/services/presentation/services_tab.dart'
    show ProviderCard;
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// One service request: what was asked, who's on it, the timeline, and the
/// next step for whoever is looking (poster, provider or society admin).
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final request = ref.watch(serviceRequestProvider(requestId));
    final r = request.value;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: request.isLoading
            ? const Center(child: CircularProgressIndicator())
            : PlaceholderBody(
                icon: Icons.handyman_outlined,
                message: l10n.requestNotFound,
              ),
      );
    }
    final groups = ref.watch(serviceCategoriesProvider);
    final uid = ref.watch(authUserProvider).value?.uid;
    final provider = r.providerId == null
        ? null
        : ref.watch(providerProvider(r.providerId!)).value;
    final isPoster = uid == r.posterUid;
    final isProvider = uid != null && uid == r.providerId;
    final isAdmin =
        r.scope == RequestScope.common &&
        r.societyId != null &&
        (ref.watch(myMembershipProvider(r.societyId!)).value?.isAdmin ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                r.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              RequestStatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              groups.category(r.category)?.label ?? r.category,
              if (r.scope == RequestScope.common) l10n.commonArea,
              if (!isPoster && r.posterName.isNotEmpty) r.posterName,
              if (r.createdAt != null) DateFormat.yMMMd().format(r.createdAt!),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(r.description, style: theme.textTheme.bodyLarge),
          ],
          if (r.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final MapEntry(:key, :value) in r.details.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_label(l10n, key)}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: detailValue(l10n, key, value)),
                    ],
                  ),
                ),
              ),
          ],
          if (r.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Photos(photos: r.photos),
          ],
          if (provider != null) ...[
            _Heading(text: l10n.provider),
            ProviderCard(
              result: (
                provider: provider,
                distanceMiles: null,
                recommended: false,
              ),
              onTap: () => context.push(
                Routes.provider(provider.id, societyId: r.societyId),
              ),
            ),
            if (isPoster &&
                provider.phone.isNotEmpty &&
                {
                  RequestStatus.accepted,
                  RequestStatus.inProgress,
                  RequestStatus.completed,
                  RequestStatus.notFixed,
                }.contains(r.status))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined),
                title: Text(provider.phone),
                onTap: () => openLink(context, 'tel:${provider.phone}'),
              ),
          ],
          if (r.declineReason.isNotEmpty &&
              r.status == RequestStatus.declined) ...[
            const SizedBox(height: 8),
            InfoBox(text: l10n.declinedBecause(r.declineReason)),
          ],
          if (r.notFixedNote.isNotEmpty &&
              r.status == RequestStatus.notFixed) ...[
            const SizedBox(height: 8),
            InfoBox(text: l10n.notFixedBecause(r.notFixedNote)),
          ],
          if (r.completion case final c?) ...[
            _Heading(text: l10n.completionHeading),
            if (c.note.isNotEmpty) Text(c.note),
            if (c.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Photos(photos: c.photos),
            ],
            if (c.videoPath != null)
              TextButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.watchVideo),
                onPressed: () async {
                  final url = await ref
                      .read(serviceRequestRepositoryProvider)
                      .fileUrl(c.videoPath!);
                  if (context.mounted) await openLink(context, url);
                },
              ),
          ],
          const SizedBox(height: 16),
          _Actions(
            request: r,
            isPoster: isPoster,
            isProvider: isProvider,
            isAdmin: isAdmin,
          ),
          _Heading(text: l10n.timeline),
          _Timeline(requestId: r.id),
        ],
      ),
    );
  }

  static String _label(AppLocalizations l10n, String key) {
    final f = DetailField.values.where((f) => f.name == key).firstOrNull;
    return f == null ? key : detailLabel(l10n, f);
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos});

  final List<RequestPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (i, p) in photos.indexed)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.thumbUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.photoNumber(i + 1),
                  errorBuilder: (_, _, _) => const SizedBox.square(
                    dimension: 96,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The buttons for the next step, by who is looking.
class _Actions extends ConsumerStatefulWidget {
  const _Actions({
    required this.request,
    required this.isPoster,
    required this.isProvider,
    required this.isAdmin,
  });

  final ServiceRequest request;
  final bool isPoster;
  final bool isProvider;
  final bool isAdmin;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  bool _busy = false;
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() step) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await step();
    } on Object catch (e) {
      debugPrint('Request step failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.request;
    final repo = ref.read(serviceRequestRepositoryProvider);
    final s = r.status;
    final buttons = <Widget>[];
    void add(Widget w) => buttons.add(
      Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
    );

    final canPick = {RequestStatus.posted, RequestStatus.declined}.contains(s);
    if (canPick &&
        ((widget.isPoster && r.scope == RequestScope.home) || widget.isAdmin)) {
      add(
        FilledButton.icon(
          key: const Key('choose-provider'),
          icon: const Icon(Icons.person_search),
          label: Text(l10n.chooseProvider),
          onPressed: _busy ? null : () => _pickProvider(r),
        ),
      );
    } else if (canPick && widget.isPoster) {
      add(InfoBox(text: l10n.waitingForAdmin));
    }
    if (widget.isPoster) {
      if (s == RequestStatus.assigned) {
        add(InfoBox(text: l10n.waitingForProvider));
      }
      if ({
        RequestStatus.posted,
        RequestStatus.assigned,
        RequestStatus.declined,
      }.contains(s)) {
        add(
          OutlinedButton(
            key: const Key('cancel-request'),
            onPressed: _busy ? null : () => _run(() => repo.cancel(r.id)),
            child: Text(l10n.cancelRequest),
          ),
        );
      }
      if (s == RequestStatus.completed) {
        add(
          FilledButton.icon(
            key: const Key('confirm-done'),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.confirmDone),
            onPressed: _busy ? null : () => _run(() => repo.confirm(r.id)),
          ),
        );
        add(
          OutlinedButton.icon(
            key: const Key('not-fixed'),
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(l10n.notFixed),
            onPressed: _busy
                ? null
                : () async {
                    final note = await showTextDialog(
                      context,
                      title: l10n.notFixedTitle,
                      hint: l10n.notFixedHint,
                      maxLength: 500,
                      required: true,
                    );
                    if (note != null) {
                      await _run(() => repo.notFixed(r.id, note));
                    }
                  },
          ),
        );
      }
      if (r.canReview) add(_reviewForm(l10n, r));
    }
    if (widget.isProvider) {
      if (s == RequestStatus.assigned) {
        add(
          FilledButton.icon(
            key: const Key('accept-job'),
            icon: const Icon(Icons.thumb_up_alt_outlined),
            label: Text(l10n.acceptJob),
            onPressed: _busy ? null : () => _run(() => repo.accept(r.id)),
          ),
        );
        add(
          OutlinedButton(
            key: const Key('decline-job'),
            onPressed: _busy
                ? null
                : () async {
                    final reason = await showTextDialog(
                      context,
                      title: l10n.declineJob,
                      hint: l10n.declineHint,
                    );
                    if (reason != null) {
                      await _run(() => repo.decline(r.id, reason));
                    }
                  },
            child: Text(l10n.declineJob),
          ),
        );
      }
      if ({RequestStatus.accepted, RequestStatus.notFixed}.contains(s)) {
        add(
          FilledButton.tonalIcon(
            key: const Key('start-job'),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.startJob),
            onPressed: _busy ? null : () => _run(() => repo.start(r.id)),
          ),
        );
      }
      if ({
        RequestStatus.accepted,
        RequestStatus.inProgress,
        RequestStatus.notFixed,
      }.contains(s)) {
        add(
          FilledButton.icon(
            key: const Key('complete-job'),
            icon: const Icon(Icons.task_alt),
            label: Text(l10n.completeJob),
            onPressed: _busy
                ? null
                : () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => CompleteJobSheet(requestId: r.id),
                  ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  Widget _reviewForm(AppLocalizations l10n, ServiceRequest r) => SocietyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.rateProvider,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        StarPicker(value: _stars, onChanged: (v) => setState(() => _stars = v)),
        TextField(
          key: const Key('review-comment'),
          controller: _comment,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.reviewHint,
            border: const OutlineInputBorder(),
          ),
        ),
        FilledButton(
          key: const Key('send-review'),
          onPressed: _stars == 0 || _busy
              ? null
              : () => _run(() async {
                  final uid = ref.read(authUserProvider).value!.uid;
                  await ref
                      .read(providerRepositoryProvider)
                      .review(
                        providerId: r.providerId!,
                        requestId: r.id,
                        uid: uid,
                        authorName: r.posterName,
                        stars: _stars,
                        comment: _comment.text,
                        category: r.category,
                      );
                }),
          child: Text(l10n.sendReview),
        ),
      ],
    ),
  );

  Future<void> _pickProvider(ServiceRequest r) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProviderPicker(request: r),
    );
    if (id == null) return;
    await _run(
      () => ref.read(serviceRequestRepositoryProvider).assign(r.id, id),
    );
  }
}

/// Providers for the request's category near it, best first.
class _ProviderPicker extends ConsumerWidget {
  const _ProviderPicker({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(authUserProvider).value?.uid;
    final results = ref.watch(
      providerSearchProvider(
        ProviderQuery(
          text: '',
          categories: [request.category],
          near: request.location,
          miles: distanceOptions.last,
          societyId: request.societyId,
        ),
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.chooseProvider,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...results.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [Text(l10n.errorGeneric)],
            data: (list) {
              final mine = list.where((p) => p.provider.id != uid).toList();
              return mine.isEmpty
                  ? [Text(l10n.noProvidersFound)]
                  : [
                      for (final p in mine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ProviderCard(
                            result: p,
                            onTap: () => Navigator.pop(context, p.provider.id),
                          ),
                        ),
                    ];
            },
          ),
        ],
      ),
    );
  }
}

/// The provider marks the job done: a note, and before/after photos or a
/// short video.
class CompleteJobSheet extends ConsumerStatefulWidget {
  const CompleteJobSheet({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<CompleteJobSheet> createState() => _CompleteJobSheetState();
}

class _CompleteJobSheetState extends ConsumerState<CompleteJobSheet> {
  final _note = TextEditingController();
  final _photos = <File>[];
  File? _video;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.completeJob, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            key: const Key('completion-note'),
            controller: _note,
            maxLength: 1000,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.completionNote,
              border: const OutlineInputBorder(),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, _) in _photos.indexed)
                InputChip(
                  avatar: const Icon(Icons.photo_outlined),
                  label: Text(l10n.photoNumber(i + 1)),
                  onDeleted: () => setState(() => _photos.removeAt(i)),
                ),
              if (_video != null)
                InputChip(
                  avatar: const Icon(Icons.videocam_outlined),
                  label: Text(l10n.videoAdded),
                  onDeleted: () => setState(() => _video = null),
                ),
              if (_photos.length < maxRequestPhotos)
                ActionChip(
                  avatar: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.addPhoto),
                  onPressed: () async {
                    final f = await ref.read(pickImageProvider)(
                      ImageSource.gallery,
                    );
                    if (f != null) setState(() => _photos.add(f));
                  },
                ),
              if (_video == null)
                ActionChip(
                  avatar: const Icon(Icons.video_call_outlined),
                  label: Text(l10n.addVideo),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final f = await ref.read(pickVideoProvider)();
                    if (f == null) return;
                    if (f.lengthSync() > maxVideoBytes) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.videoTooLarge)),
                      );
                      return;
                    }
                    setState(() => _video = f);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('completion-send'),
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.markDone),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(serviceRequestRepositoryProvider)
          .complete(
            widget.requestId,
            note: _note.text,
            photos: _photos,
            video: _video,
          );
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      debugPrint('Complete failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final events =
        ref.watch(requestEventsProvider(requestId)).value ?? const [];
    if (events.isEmpty) {
      return Text(l10n.timelineEmpty, style: theme.textTheme.bodySmall);
    }
    return Column(
      children: [
        for (final (i, e) in events.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Icon(
                        i == events.length - 1
                            ? Icons.radio_button_checked
                            : Icons.circle,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      if (i < events.length - 1)
                        Expanded(
                          child: VerticalDivider(
                            width: 2,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requestStatusLabel(l10n, e.status),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (e.at != null)
                          Text(
                            DateFormat.yMMMd().add_jm().format(e.at!),
                            style: theme.textTheme.bodySmall,
                          ),
                        if (e.note.isNotEmpty) Text(e.note),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
