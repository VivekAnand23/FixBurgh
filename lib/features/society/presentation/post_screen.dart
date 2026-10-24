import 'dart:async';

import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/channel_screen.dart';
import 'package:fixburgh/features/society/presentation/composer.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A post with its comments; replies are indented under their comment
/// with a rule on the left, one level deep.
class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    required this.societyId,
    required this.channelId,
    required this.postId,
    super.key,
  });

  final String societyId;
  final String channelId;
  final String postId;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  final _composer = GlobalKey<ComposerState>();
  Comment? _replyTo;

  PostKey get _key =>
      (sid: widget.societyId, cid: widget.channelId, pid: widget.postId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = ref.watch(postProvider(_key));
    final comments = ref.watch(commentsProvider(_key)).value ?? const [];
    final me = ref.watch(myMembershipProvider(widget.societyId)).value;
    final blocked = ref.watch(blockedUsersProvider);
    final channel = ref
        .watch(channelProvider((sid: widget.societyId, cid: widget.channelId)))
        .value;
    final p = post.value;
    if (me == null || (p == null && post.isLoading)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.postGone)),
      );
    }
    final thread = threadComments(
      comments.where((c) => !blocked.contains(c.authorUid)).toList(),
    );
    final reply = _replyTo;
    return Scaffold(
      appBar: AppBar(title: Text('# ${channel?.name ?? ''}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                PostCard(
                  societyId: widget.societyId,
                  channelId: widget.channelId,
                  post: p,
                  me: me,
                  openOnTap: false,
                ),
                const SizedBox(height: 12),
                for (final (c, isReply) in thread)
                  _CommentTile(
                    societyId: widget.societyId,
                    channelId: widget.channelId,
                    postId: widget.postId,
                    comment: c,
                    isReply: isReply,
                    me: me,
                    onReply: () {
                      setState(() => _replyTo = c);
                      _composer.currentState?.focus();
                    },
                  ),
              ],
            ),
          ),
          Composer(
            key: _composer,
            societyId: widget.societyId,
            hint: l10n.writeComment,
            replyingTo: reply == null
                ? null
                : l10n.replyingTo(
                    reply.authorName.isEmpty ? l10n.neighbor : reply.authorName,
                  ),
            onCancelReply: () => setState(() => _replyTo = null),
            onSend: (c) async {
              await ref
                  .read(channelRepositoryProvider)
                  .addComment(
                    widget.societyId,
                    widget.channelId,
                    widget.postId,
                    uid: me.uid,
                    authorName: me.displayName,
                    text: c.text,
                    mentions: c.mentions,
                    // Replies stay one level deep.
                    replyTo: reply?.replyTo ?? reply?.id,
                  );
              if (mounted) setState(() => _replyTo = null);
            },
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    required this.societyId,
    required this.channelId,
    required this.postId,
    required this.comment,
    required this.isReply,
    required this.me,
    required this.onReply,
  });

  final String societyId;
  final String channelId;
  final String postId;
  final Comment comment;
  final bool isReply;
  final Membership me;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final members = ref.watch(membersProvider(societyId)).value ?? const [];
    final names = [
      for (final m in members)
        if (comment.mentions.contains(m.uid)) m.displayName,
    ];
    final name = comment.authorName.isEmpty
        ? l10n.neighbor
        : comment.authorName;
    final path =
        '${postPath(societyId, channelId, postId)}/comments/${comment.id}';
    final canDelete = comment.authorUid == me.uid || me.canPostNotices;
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 15, child: Text(name[0].toUpperCase())),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (comment.createdAt != null)
                        TextSpan(
                          text: ' · ${timeAgo(l10n, comment.createdAt!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                MentionText(
                  text: comment.text,
                  names: names,
                  style: theme.textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ReactionBar(
                        path: path,
                        counts: comment.reactionCounts,
                      ),
                    ),
                    TextButton(onPressed: onReply, child: Text(l10n.reply)),
                    if (canDelete)
                      IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => unawaited(
                          ref
                              .read(channelRepositoryProvider)
                              .deleteComment(
                                societyId,
                                channelId,
                                postId,
                                comment.id,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!isReply) return body;
    return Container(
      margin: const EdgeInsets.only(left: 22),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant, width: 2),
        ),
      ),
      child: body,
    );
  }
}
