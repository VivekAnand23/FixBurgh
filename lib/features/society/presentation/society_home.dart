import 'dart:async';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/inbox_screen.dart';
import 'package:fixburgh/features/services/presentation/services_tab.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/channels_tab.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A member's view of their society (mock 3): the switcher, Manage for
/// admins, the HOA account link, and Notices and Docs tabs (plus Members
/// for admins), plus Channels and Services behind their flags.
class SocietyHome extends ConsumerWidget {
  const SocietyHome({required this.societyId, super.key});

  final String societyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final society = ref.watch(societyProvider(societyId)).value;
    final me = ref.watch(myMembershipProvider(societyId)).value;
    final hoa = ref.watch(hoaProvider(societyId)).value;
    final isAdmin = me?.isAdmin ?? false;
    if (society == null || me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final channels = ref.watch(featureFlagsProvider).channels;
    final services = ref.watch(featureFlagsProvider).services;
    final unseen = ref.watch(inboxUnseenProvider);
    final tabs = [
      if (channels) Tab(text: l10n.tabChannels),
      Tab(text: l10n.tabNotices),
      Tab(text: l10n.tabDocs),
      if (services) Tab(text: l10n.tabServices),
      if (isAdmin) Tab(text: l10n.tabMembers),
    ];
    return DefaultTabController(
      key: ValueKey('$societyId-${tabs.length}'),
      length: tabs.length,
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.light
            ? AppColors.pageBg
            : null,
        appBar: AppBar(
          centerTitle: false,
          title: _Switcher(society: society, me: me),
          actions: [
            IconButton(
              tooltip: l10n.inboxTitle,
              icon: Badge(
                isLabelVisible: unseen > 0,
                label: Text('$unseen'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push(Routes.inbox),
            ),
          ],
          bottom: TabBar(
            tabs: tabs,
            // Five tabs don't fit a phone's width without cutting labels.
            isScrollable: tabs.length > 4,
            tabAlignment: tabs.length > 4 ? TabAlignment.start : null,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: Column(
          children: [
            if (isAdmin || hoa?.accountUrl.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (isAdmin)
                      Expanded(
                        child: _ManageButton(
                          pending: society.pendingCount,
                          onTap: () =>
                              context.push(Routes.manageSociety(societyId)),
                        ),
                      ),
                    if (isAdmin && hoa?.accountUrl.isNotEmpty == true)
                      const SizedBox(width: 8),
                    if (hoa?.accountUrl.isNotEmpty == true)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.account_balance_outlined),
                          label: Text(l10n.hoaAccount),
                          onPressed: () => openLink(context, hoa!.accountUrl),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  if (channels) ChannelsTab(societyId: societyId, me: me),
                  _NoticesTab(societyId: societyId, me: me),
                  _DocsTab(societyId: societyId, me: me),
                  if (services) ServicesTab(societyId: societyId, me: me),
                  if (isAdmin) MembersTab(societyId: societyId, me: me),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Switcher extends ConsumerWidget {
  const _Switcher({required this.society, required this.me});

  final Society society;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: l10n.switchSociety,
      child: InkWell(
        onTap: () => unawaited(_showSwitcher(context, ref)),
        child: ConstrainedBox(
          // Keeps the tap target at least 48 px tall.
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      society.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
              Text(
                [
                  l10n.homesCount(society.units),
                  l10n.youAre(l10n.role(me.role)),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSwitcher(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) {
          final l10n = AppLocalizations.of(sheet);
          final ids = ref.read(mySocietyIdsProvider).value ?? const [];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in ids)
                  Consumer(
                    builder: (context, ref, _) {
                      final s = ref.watch(societyProvider(id)).value;
                      return ListTile(
                        leading: s == null ? null : SocietyAvatar(society: s),
                        title: Text(s?.name ?? ''),
                        trailing: id == society.id
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () {
                          ref.read(selectedSocietyProvider.notifier).select(id);
                          Navigator.of(sheet).pop();
                        },
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.joinAnotherSociety),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(context.push(Routes.findSociety));
                  },
                ),
              ],
            ),
          );
        },
      );
}

class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.pending, required this.onTap});

  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        child: const Icon(Icons.admin_panel_settings_outlined),
      ),
      label: Text(l10n.manage),
    );
  }
}

class _NoticesTab extends ConsumerWidget {
  const _NoticesTab({required this.societyId, required this.me});

  final String societyId;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notices = ref.watch(noticesProvider(societyId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: me.canPostNotices
          ? FloatingActionButton.extended(
              heroTag: 'notice',
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.newNotice),
              onPressed: () => context.push(Routes.newNotice(societyId)),
            )
          : null,
      body: notices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          if (list.isEmpty) return _Empty(text: l10n.noNotices);
          final now = DateTime.now();
          final sorted = sortNotices(list, now);
          final pinned = sorted
              .where((n) => n.pinned && !n.isExpired(now))
              .toList();
          final rest = sorted.skip(pinned.length).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              for (final n in pinned) ...[
                PinnedNoticeCard(societyId: societyId, notice: n),
                const SizedBox(height: 12),
              ],
              if (rest.isNotEmpty)
                SocietyCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, n) in rest.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _NoticeRow(
                          societyId: societyId,
                          notice: n,
                          expired: n.isExpired(now),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Light orange card for a pinned notice, as in the mock.
class PinnedNoticeCard extends StatelessWidget {
  const PinnedNoticeCard({
    required this.societyId,
    required this.notice,
    super.key,
  });

  final String societyId;
  final SocietyNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? theme.colorScheme.secondary : AppColors.orange700;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: () => context.push(Routes.notice(societyId, notice.id)),
      child: SocietyCard(
        color: dark
            ? theme.colorScheme.secondaryContainer
            : AppColors.orangeTint,
        borderColor: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.authorName.isEmpty
                  ? l10n.pinnedNotice.toUpperCase()
                  : l10n.pinnedNoticeFrom(notice.authorName).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notice.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              noticeMeta(context, notice),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Posted 2h ago · Expires Oct 27".
String noticeMeta(BuildContext context, SocietyNotice n) {
  final l10n = AppLocalizations.of(context);
  final created = n.createdAt;
  return [
    if (created != null) l10n.postedAgo(timeAgo(l10n, created)),
    if (n.expiresAt != null)
      l10n.expiresOn(DateFormat.MMMd().format(n.expiresAt!)),
    if (n.attachment != null) l10n.hasAttachment,
  ].join(' · ');
}

/// "just now", "5m", "2h", "3d", or a date.
String timeAgo(AppLocalizations l10n, DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return l10n.justNow;
  if (d.inHours < 1) return l10n.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return l10n.hoursAgo(d.inHours);
  if (d.inDays < 7) return l10n.daysAgo(d.inDays);
  return DateFormat.MMMd().format(t);
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.societyId,
    required this.notice,
    required this.expired,
  });

  final String societyId;
  final SocietyNotice notice;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.campaign_outlined),
      ),
      title: Text(
        notice.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: expired ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(
        notice.body.isEmpty ? noticeMeta(context, notice) : notice.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: notice.createdAt == null
          ? null
          : Text(
              timeAgo(AppLocalizations.of(context), notice.createdAt!),
              style: theme.textTheme.bodySmall,
            ),
      onTap: () => context.push(Routes.notice(societyId, notice.id)),
    );
  }
}

class _DocsTab extends ConsumerWidget {
  const _DocsTab({required this.societyId, required this.me});

  final String societyId;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final docs = ref.watch(documentsProvider(societyId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: me.isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'doc',
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.uploadDocument),
              onPressed: () => context.push(Routes.uploadDocument(societyId)),
            )
          : null,
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) => list.isEmpty
            ? _Empty(text: l10n.noDocuments)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  SocietyCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, d) in list.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor:
                                  theme.colorScheme.onErrorContainer,
                              child: const Icon(Icons.picture_as_pdf_outlined),
                            ),
                            title: Text(
                              d.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              [
                                l10n.docCategory(d.category),
                                if (d.createdAt != null)
                                  DateFormat.yMMMd().format(d.createdAt!),
                                fileSize(d.sizeBytes),
                              ].join(' · '),
                            ),
                            trailing: me.isAdmin
                                ? IconButton(
                                    tooltip: l10n.delete,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _confirmDelete(context, ref, d),
                                  )
                                : const Icon(Icons.open_in_new),
                            onTap: () => openSocietyFile(context, ref, d.path),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SocietyDocument d,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.deleteDocumentTitle(d.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(societyRepositoryProvider).deleteDocument(societyId, d);
    }
  }
}

/// "1.2 MB", "340 KB".
String fileSize(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).ceil()} KB';

/// Approved members, with role changes and removal for admins.
class MembersTab extends ConsumerWidget {
  const MembersTab({required this.societyId, required this.me, super.key});

  final String societyId;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(membersProvider(societyId));
    return members.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.errorGeneric)),
      data: (all) {
        final list = all.where((m) => m.isApproved).toList()
          ..sort(
            (a, b) => b.role.index != a.role.index
                ? b.role.index.compareTo(a.role.index)
                : a.unit.compareTo(b.unit),
          );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SocietyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, m) in list.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    MemberRow(societyId: societyId, member: m, me: me),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _MemberAction { member, committee, admin, remove }

class MemberRow extends ConsumerWidget {
  const MemberRow({
    required this.societyId,
    required this.member,
    required this.me,
    super.key,
  });

  final String societyId;
  final Membership member;
  final Membership me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = member.displayName.isEmpty
        ? l10n.neighbor
        : member.displayName;
    final self = member.uid == me.uid;
    return ListTile(
      leading: CircleAvatar(child: Text(name[0].toUpperCase())),
      title: Text(self ? l10n.youName(name) : name),
      subtitle: Text(
        [
          if (member.unit.isNotEmpty) l10n.unitLabel(member.unit),
          l10n.role(member.role),
        ].join(' · '),
      ),
      trailing: !me.isAdmin || self
          ? null
          : PopupMenuButton<_MemberAction>(
              tooltip: l10n.memberActions,
              onSelected: (a) => _act(context, ref, a),
              itemBuilder: (_) => [
                if (member.role != MemberRole.member)
                  PopupMenuItem(
                    value: _MemberAction.member,
                    child: Text(l10n.makeMember),
                  ),
                if (member.role != MemberRole.committee)
                  PopupMenuItem(
                    value: _MemberAction.committee,
                    child: Text(l10n.makeCommittee),
                  ),
                if (member.role != MemberRole.admin)
                  PopupMenuItem(
                    value: _MemberAction.admin,
                    child: Text(l10n.makeAdmin),
                  ),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: Text(l10n.removeMember),
                ),
              ],
            ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final adminUid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (adminUid == null) return;
    if (action == _MemberAction.remove) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l10n.removeMemberTitle),
          content: Text(l10n.removeMemberBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.removeMember),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref
          .read(societyRepositoryProvider)
          .updateMember(
            societyId,
            member.uid,
            adminUid: adminUid,
            status: action == _MemberAction.remove
                ? MemberStatus.removed
                : null,
            role: switch (action) {
              _MemberAction.member => MemberRole.member,
              _MemberAction.committee => MemberRole.committee,
              _MemberAction.admin => MemberRole.admin,
              _MemberAction.remove => null,
            },
          );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
