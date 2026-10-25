import 'dart:async';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/service_widgets.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Activity › Service requests: what this person asked for, with any still
/// waiting to send.
class ServiceRequestsView extends ConsumerWidget {
  const ServiceRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final waiting = ref.watch(requestOutboxProvider);
    return RequestList(
      requests: ref.watch(myServiceRequestsProvider),
      empty: l10n.serviceRequestsEmpty,
      header: [
        for (final q in waiting)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _QueuedCard(item: q),
          ),
      ],
    );
  }
}

/// Activity › Jobs: requests sent to this provider.
class JobsView extends ConsumerWidget {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RequestList(
    requests: ref.watch(myJobsProvider),
    empty: AppLocalizations.of(context).jobsEmpty,
    showPoster: true,
  );
}

/// A society's common-area requests, for its admins to assign.
class CommonRequestsScreen extends ConsumerWidget {
  const CommonRequestsScreen({required this.societyId, super.key});

  final String societyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonRequests)),
      body: RequestList(
        requests: ref.watch(commonRequestsProvider(societyId)),
        empty: l10n.commonRequestsEmpty,
        showPoster: true,
      ),
    );
  }
}

/// Requests split into Open and Done.
class RequestList extends StatelessWidget {
  const RequestList({
    required this.requests,
    required this.empty,
    this.header = const [],
    this.showPoster = false,
    super.key,
  });

  final AsyncValue<List<ServiceRequest>> requests;
  final String empty;
  final List<Widget> header;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          PlaceholderBody(icon: Icons.cloud_off, message: l10n.errorGeneric),
      data: (list) {
        if (list.isEmpty && header.isEmpty) {
          return PlaceholderBody(
            icon: Icons.handyman_outlined,
            message: empty,
          );
        }
        final open = list.where((r) => r.status.isOpen).toList();
        final done = list.where((r) => !r.status.isOpen).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...header,
            if (open.isNotEmpty) _Label(text: l10n.openCount(open.length)),
            for (final r in open)
              RequestTile(request: r, showPoster: showPoster),
            if (done.isNotEmpty) _Label(text: l10n.doneCount(done.length)),
            for (final r in done)
              RequestTile(request: r, showPoster: showPoster),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}

class RequestTile extends ConsumerWidget {
  const RequestTile({
    required this.request,
    this.showPoster = false,
    super.key,
  });

  final ServiceRequest request;
  final bool showPoster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(serviceCategoriesProvider);
    final r = request;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SocietyCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          key: Key('request-${r.id}'),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          title: Text(
            r.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              groups.category(r.category)?.label ?? r.category,
              if (r.scope == RequestScope.common) l10n.commonArea,
              if (showPoster && r.posterName.isNotEmpty) r.posterName,
              if (r.createdAt != null) DateFormat.MMMd().format(r.createdAt!),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          trailing: RequestStatusChip(status: r.status),
          onTap: () => context.push(Routes.serviceRequest(r.id)),
        ),
      ),
    );
  }
}

class _QueuedCard extends ConsumerWidget {
  const _QueuedCard({required this.item});

  final QueuedRequest item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctl = ref.read(requestOutboxProvider.notifier);
    return SocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.draft.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.failed ? l10n.requestFailed : l10n.requestWaiting),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => unawaited(ctl.cancel(item.id)),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => unawaited(ctl.sendNow(force: true)),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
