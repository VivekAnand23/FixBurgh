import 'dart:async';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/channels_tab.dart';
import 'package:fixburgh/features/society/presentation/composer.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A channel: pinned notices and posts, newest at the bottom, and the
/// composer. Opening it clears its unread badge.
class ChannelScreen extends ConsumerStatefulWidget {
  const ChannelScreen({
    required this.societyId,
    required this.channelId,
    super.key,
  });

  final String societyId;
  final String channelId;

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  ChannelKey get _key => (sid: widget.societyId, cid: widget.channelId);

  void _markRead() {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    unawaited(
      ref
          .read(channelRepositoryProvider)
          .markRead(widget.societyId, widget.channelId, uid)
          .catchError((_) {}),
    );
  }

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final channel = ref.watch(channelProvider(_key)).value;
    final me = ref.watch(myMembershipProvider(widget.societyId)).value;
    final posts = ref.watch(postsProvider(_key));
    final blocked = ref.watch(blockedUsersProvider);
    final notices = sortNotices(
      ref.watch(noticesProvider(widget.societyId)).value ?? const [],
      DateTime.now(),
    ).where((n) => n.pinned && !n.isExpired(DateTime.now())).take(2);
    // New posts while the channel is open count as read.
    ref.listen(postsProvider(_key), (prev, next) {
      if (prev?.value?.firstOrNull?.id != next.value?.firstOrNull?.id) {
        _markRead();
      }
    });
    if (me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final muted = me.isMuted(widget.channelId, DateTime.now());
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? AppColors.pageBg
          : null,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text('# ${channel?.name ?? ''}')),
            if (muted)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 18,
                  semanticLabel: l10n.muted,
                ),
              ),
          ],
        ),
        actions: [
          if (channel != null)
            _ChannelMenu(societyId: widget.societyId, channel: channel, me: me),
        ],
      ),
      body: Column(
        children: [
          for (final n in notices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: PinnedNoticeCard(societyId: widget.societyId, notice: n),
            ),
          Expanded(
            child: posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.errorGeneric)),
              data: (all) {
                final list = all
                    .where((p) => !blocked.contains(p.authorUid))
                    .toList();
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l10n.firstPost, textAlign: TextAlign.center),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PostCard(
                      societyId: widget.societyId,
                      channelId: widget.channelId,
                      post: list[i],
                      me: me,
                    ),
                  ),
                );
              },
            ),
          ),
          Composer(
            societyId: widget.societyId,
            hint: l10n.messageChannel(channel?.name ?? ''),
            allowPhotos: true,
            onSend: (c) => ref
                .read(channelRepositoryProvider)
                .createPost(
                  widget.societyId,
                  widget.channelId,
                  uid: me.uid,
                  authorName: me.displayName,
                  authorUnit: me.unit,
                  text: c.text,
                  mentions: c.mentions,
                  photos: c.photos,
                ),
          ),
        ],
      ),
    );
  }
}

enum _ChannelAction { mute8h, mute1w, muteAlways, unmute, rename, archive }

class _ChannelMenu extends ConsumerWidget {
  const _ChannelMenu({
    required this.societyId,
    required this.channel,
    required this.me,
  });

  final String societyId;
  final Channel channel;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final muted = me.isMuted(channel.id, DateTime.now());
    final repo = ref.read(channelRepositoryProvider);
    Future<void> mute(MuteLength length) => repo.setMute(
      societyId,
      channel.id,
      me.uid,
      muteFor(length, DateTime.now()),
    );
    return PopupMenuButton<_ChannelAction>(
      tooltip: l10n.channelOptions,
      onSelected: (a) async {
        switch (a) {
          case _ChannelAction.mute8h:
            await mute(MuteLength.eightHours);
          case _ChannelAction.mute1w:
            await mute(MuteLength.oneWeek);
          case _ChannelAction.muteAlways:
            await mute(MuteLength.always);
          case _ChannelAction.unmute:
            await repo.setMute(societyId, channel.id, me.uid, null);
          case _ChannelAction.rename:
            if (context.mounted) {
              await editChannelName(
                context,
                ref,
                societyId: societyId,
                channel: channel,
              );
            }
          case _ChannelAction.archive:
            await repo.updateChannel(societyId, channel.id, archived: true);
            if (context.mounted) context.pop();
        }
      },
      itemBuilder: (_) => [
        if (muted)
          PopupMenuItem(value: _ChannelAction.unmute, child: Text(l10n.unmute))
        else ...[
          PopupMenuItem(
            value: _ChannelAction.mute8h,
            child: Text(l10n.muteFor8Hours),
          ),
          PopupMenuItem(
            value: _ChannelAction.mute1w,
            child: Text(l10n.muteFor1Week),
          ),
          PopupMenuItem(
            value: _ChannelAction.muteAlways,
            child: Text(l10n.muteAlways),
          ),
        ],
        if (me.isAdmin) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _ChannelAction.rename,
            child: Text(l10n.renameChannel),
          ),
          if (!channel.isGeneral)
            PopupMenuItem(
              value: _ChannelAction.archive,
              child: Text(l10n.archiveChannel),
            ),
        ],
      ],
    );
  }
}

/// A post: author, unit and time, text with @mentions highlighted, photos,
/// reaction chips and the comment count.
class PostCard extends ConsumerWidget {
  const PostCard({
    required this.societyId,
    required this.channelId,
    required this.post,
    required this.me,
    this.openOnTap = true,
    super.key,
  });

  final String societyId;
  final String channelId;
  final Post post;
  final Membership me;
  final bool openOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final members = ref.watch(membersProvider(societyId)).value ?? const [];
    final names = [
      for (final m in members)
        if (post.mentions.contains(m.uid)) m.displayName,
    ];
    final path = postPath(societyId, channelId, post.id);
    final name = post.authorName.isEmpty ? l10n.neighbor : post.authorName;
    void open() => context.push(Routes.post(societyId, channelId, post.id));
    return SocietyCard(
      borderColor: post.pinned ? AppColors.orange700 : null,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: openOnTap ? open : null,
        onLongPress: () => unawaited(
          showPostActions(
            context,
            ref,
            societyId: societyId,
            channelId: channelId,
            post: post,
            me: me,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l10n.pinnedPost.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.orange700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(radius: 18, child: Text(name[0].toUpperCase())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: [
                              if (post.authorUnit.isNotEmpty)
                                ' · ${l10n.unitLabel(post.authorUnit)}',
                              if (post.createdAt != null)
                                ' · ${timeAgo(l10n, post.createdAt!)}',
                              if (post.edited) ' · ${l10n.edited}',
                            ].join(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.postOptions,
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => showPostActions(
                      context,
                      ref,
                      societyId: societyId,
                      channelId: channelId,
                      post: post,
                      me: me,
                    ),
                  ),
                ],
              ),
              if (post.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                MentionText(text: post.text, names: names),
              ],
              if (post.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Photos(photos: post.photos),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ReactionBar(path: path, counts: post.reactionCounts),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.mode_comment_outlined, size: 18),
                    label: Text(
                      post.commentCount == 0
                          ? l10n.comment
                          : l10n.commentsCount(post.commentCount),
                    ),
                    onPressed: open,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos});

  final List<PostPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(PostPhoto p) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        p.thumbUrl,
        fit: BoxFit.cover,
        semanticLabel: l10n.postPhoto,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
    if (photos.length == 1) {
      return AspectRatio(aspectRatio: 4 / 3, child: tile(photos.first));
    }
    return GridView.count(
      crossAxisCount: photos.length == 2 || photos.length == 4 ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [for (final p in photos) tile(p)],
    );
  }
}

/// Reaction chips ("👍 9") and an add button; tapping your own removes it.
class ReactionBar extends ConsumerWidget {
  const ReactionBar({required this.path, required this.counts, super.key});

  /// The post or comment.
  final String path;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mine = ref.watch(myReactionProvider(path)).value;
    final uid = ref.watch(authUserProvider).value?.uid;
    Future<void> toggle(String emoji) async {
      if (uid == null) return;
      await ref
          .read(channelRepositoryProvider)
          .toggleReaction(path, uid, emoji, current: mine);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final e in reactionEmoji)
          if ((counts[e] ?? 0) > 0)
            Semantics(
              button: true,
              label: l10n.reactionCount(e, counts[e]!),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                onTap: () => toggle(e),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: mine == e
                        ? (theme.brightness == Brightness.dark
                              ? theme.colorScheme.primaryContainer
                              : AppColors.navyTint)
                        : null,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  // widthFactor 1 keeps the chip as wide as its label.
                  child: Center(
                    widthFactor: 1,
                    child: Text('$e ${counts[e]}'),
                  ),
                ),
              ),
            ),
        IconButton(
          tooltip: l10n.addReaction,
          icon: const Icon(Icons.add_reaction_outlined, size: 20),
          onPressed: () async {
            final e = await pickReaction(context);
            if (e != null) await toggle(e);
          },
        ),
      ],
    );
  }
}

Future<String?> pickReaction(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: [
              for (final e in reactionEmoji)
                IconButton(
                  tooltip: e,
                  iconSize: 32,
                  icon: Text(e, style: const TextStyle(fontSize: 30)),
                  onPressed: () => Navigator.pop(c, e),
                ),
            ],
          ),
        ),
      ),
    );

enum _PostAction { pin, unpin, delete, report, block }

/// Pin, delete, report or block, depending on who's asking.
Future<void> showPostActions(
  BuildContext context,
  WidgetRef ref, {
  required String societyId,
  required String channelId,
  required Post post,
  required Membership me,
}) async {
  final l10n = AppLocalizations.of(context);
  final mine = post.authorUid == me.uid;
  final action = await showModalBottomSheet<_PostAction>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (me.canPostNotices)
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(post.pinned ? l10n.unpinPost : l10n.pinPost),
              onTap: () => Navigator.pop(
                c,
                post.pinned ? _PostAction.unpin : _PostAction.pin,
              ),
            ),
          if (mine || me.canPostNotices)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deletePost),
              onTap: () => Navigator.pop(c, _PostAction.delete),
            ),
          if (!mine) ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.reportPost),
              onTap: () => Navigator.pop(c, _PostAction.report),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.blockAuthor),
              onTap: () => Navigator.pop(c, _PostAction.block),
            ),
          ],
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(channelRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    switch (action) {
      case _PostAction.pin || _PostAction.unpin:
        await repo.setPinned(
          societyId,
          channelId,
          post.id,
          pinned: action == _PostAction.pin,
        );
      case _PostAction.delete:
        await repo.deletePost(societyId, channelId, post.id);
      case _PostAction.report:
        await repo.report(
          societyId,
          cid: channelId,
          pid: post.id,
          uid: me.uid,
          reason: 'other',
        );
        messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
      case _PostAction.block:
        await ref.read(blockedUsersProvider.notifier).block(post.authorUid);
        messenger.showSnackBar(SnackBar(content: Text(l10n.authorBlocked)));
    }
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}
