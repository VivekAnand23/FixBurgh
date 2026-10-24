import 'dart:async';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The society's channels: "#" avatar, name, last message, time, and a
/// navy unread badge, an orange "@ n" badge for mentions, or a grey badge
/// with a bell-slash when muted.
class ChannelsTab extends ConsumerWidget {
  const ChannelsTab({required this.societyId, required this.me, super.key});

  final String societyId;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(channelsProvider(societyId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: me.isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'channel',
              icon: const Icon(Icons.add),
              label: Text(l10n.newChannel),
              onPressed: () => unawaited(
                editChannelName(context, ref, societyId: societyId),
              ),
            )
          : null,
      body: channels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            SocietyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, c) in list.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ChannelRow(societyId: societyId, channel: c, me: me),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChannelRow extends ConsumerWidget {
  const ChannelRow({
    required this.societyId,
    required this.channel,
    required this.me,
    super.key,
  });

  final String societyId;
  final Channel channel;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final muted = me.isMuted(channel.id, now);
    final unread =
        ref
            .watch(
              unreadProvider((
                sid: societyId,
                cid: channel.id,
                since:
                    me.lastRead[channel.id] ??
                    channel.lastPostAt?.subtract(const Duration(days: 1)),
                uid: me.uid,
              )),
            )
            .value ??
        (posts: 0, mentions: 0);
    final preview = channel.lastPostText.isEmpty
        ? l10n.noPostsYet
        : channel.lastPostAuthor.isEmpty
        ? channel.lastPostText
        : '${channel.lastPostAuthor}: ${channel.lastPostText}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Text(
          '#',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        channel.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (channel.lastPostAt != null)
            Text(
              timeAgo(l10n, channel.lastPostAt!),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (muted)
                Icon(
                  Icons.notifications_off_outlined,
                  size: 16,
                  semanticLabel: l10n.muted,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              if (unread.mentions > 0)
                _Count(
                  label: '@ ${unread.mentions}',
                  color: AppColors.orange700,
                  semantics: l10n.mentionsCount(unread.mentions),
                ),
              if (unread.posts > 0)
                _Count(
                  label: '${unread.posts}',
                  color: muted ? theme.colorScheme.outline : AppColors.navy,
                  semantics: l10n.unreadCount(unread.posts),
                ),
            ],
          ),
        ],
      ),
      onTap: () => context.push(Routes.channel(societyId, channel.id)),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.color,
    required this.semantics,
  });

  final String label;
  final Color color;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    excludeSemantics: true,
    child: Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// Asks for a channel name: a new channel, or [channel]'s new name.
Future<void> editChannelName(
  BuildContext context,
  WidgetRef ref, {
  required String societyId,
  Channel? channel,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: channel?.name ?? '');
  final name = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(channel == null ? l10n.newChannel : l10n.renameChannel),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(
          labelText: l10n.channelName,
          hintText: l10n.channelNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name == null || name.isEmpty) return;
  final repo = ref.read(channelRepositoryProvider);
  final uid = ref.read(myMembershipProvider(societyId)).value?.uid;
  if (uid == null) return;
  if (channel == null) {
    await repo.createChannel(societyId, uid, name);
  } else {
    await repo.updateChannel(societyId, channel.id, name: name);
  }
}
