import 'dart:async';

import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _seenKey = 'inbox.seenAt';

/// Notifications newer than the last time the inbox was opened.
final Provider<int> inboxUnseenProvider = Provider.autoDispose<int>((ref) {
  final seen = ref.watch(_inboxSeenProvider);
  final items = ref.watch(inboxProvider).value ?? const [];
  return items
      .where((i) => i.at != null && (seen == null || i.at!.isAfter(seen)))
      .length;
});

final _inboxSeenProvider = NotifierProvider<_InboxSeen, DateTime?>(
  _InboxSeen.new,
);

class _InboxSeen extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final ms = ref.watch(sharedPreferencesProvider).getInt(_seenKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void markSeen() {
    final now = DateTime.now();
    state = now;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setInt(_seenKey, now.millisecondsSinceEpoch),
    );
  }
}

/// The bell: every notification, city reports and society alike.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(_inboxSeenProvider.notifier).markSeen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inboxTitle)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.inboxEmpty))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = list[i];
                  return ListTile(
                    leading: CircleAvatar(child: Icon(_icon(n.kind))),
                    title: Text(n.title),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: n.at == null
                        ? null
                        : Text(
                            timeAgo(l10n, n.at!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                    onTap: () => openNotification(context, ref, n.targets),
                  );
                },
              ),
      ),
    );
  }

  static IconData _icon(String kind) => switch (kind) {
    'mention' => Icons.alternate_email,
    'interaction' => Icons.forum_outlined,
    'notice' => Icons.campaign_outlined,
    'society' => Icons.apartment,
    'nearby' => Icons.warning_amber_rounded,
    _ => Icons.update,
  };
}

/// Opens what a notification is about: a report, a channel post, a
/// notice, a claim or a society.
void openNotification(
  BuildContext context,
  WidgetRef ref,
  Map<String, Object?> data,
) {
  String? id(String key) => switch (data[key]) {
    final String v when v.isNotEmpty => v,
    _ => null,
  };
  final report = id('reportId');
  final society = id('societyId');
  final claim = id('claimId');
  if (report != null) {
    unawaited(showReportSheet(context, report));
    return;
  }
  if (claim != null && society == null) {
    unawaited(context.push(Routes.claim(claim)));
    return;
  }
  if (society == null) return;
  ref.read(selectedSocietyProvider.notifier).select(society);
  final router = GoRouter.of(context)..go(Routes.society);
  final notice = id('noticeId');
  final channel = id('channelId');
  final post = id('postId');
  if (channel != null && post != null) {
    unawaited(router.push(Routes.post(society, channel, post)));
  } else if (notice != null) {
    unawaited(router.push(Routes.notice(society, notice)));
  }
}
