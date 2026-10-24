import 'dart:async';

import 'package:fixburgh/app/links.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// The society admin's Manage area: join requests, the invite code, HOA
/// links, and shortcuts to post a notice or upload a document. Member
/// roles and removal are on the Members tab.
class ManageScreen extends ConsumerWidget {
  const ManageScreen({required this.societyId, super.key});

  final String societyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(myMembershipProvider(societyId)).value;
    final society = ref.watch(societyProvider(societyId)).value;
    if (me == null || society == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!me.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manage)),
        body: Center(child: Text(l10n.adminsOnly)),
      );
    }
    final members = ref.watch(membersProvider(societyId)).value ?? const [];
    final requests =
        members.where((m) => m.status == MemberStatus.pending).toList()..sort(
          (a, b) => (a.requestedAt ?? DateTime(0)).compareTo(
            b.requestedAt ?? DateTime(0),
          ),
        );
    TextStyle? heading() =>
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageSociety(society.name))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.joinRequests(requests.length), style: heading()),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            Text(l10n.noJoinRequests)
          else
            SocietyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, m) in requests.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _RequestRow(societyId: societyId, member: m),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(l10n.inviteCode, style: heading()),
          const SizedBox(height: 8),
          _InviteCodeCard(society: society),
          const SizedBox(height: 24),
          Text(l10n.shareWithMembers, style: heading()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.campaign_outlined),
                label: Text(l10n.newNotice),
                onPressed: () => context.push(Routes.newNotice(societyId)),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.uploadDocument),
                onPressed: () => context.push(Routes.uploadDocument(societyId)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.sectionHoa, style: heading()),
          const SizedBox(height: 8),
          _HoaForm(societyId: societyId),
        ],
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.societyId, required this.member});

  final String societyId;
  final Membership member;

  Future<void> _decide(WidgetRef ref, MemberStatus status) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    await ref
        .read(societyRepositoryProvider)
        .updateMember(societyId, member.uid, adminUid: uid, status: status);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = member.displayName.isEmpty
        ? l10n.neighbor
        : member.displayName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          CircleAvatar(child: Text(name[0].toUpperCase())),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(l10n.unitLabel(member.unit)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _decide(ref, MemberStatus.declined),
            child: Text(l10n.decline),
          ),
          FilledButton(
            onPressed: () => _decide(ref, MemberStatus.approved),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends ConsumerWidget {
  const _InviteCodeCard({required this.society});

  final Society society;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final code = ref.watch(inviteCodeProvider(society.id)).value;
    final messenger = ScaffoldMessenger.of(context);
    return SocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.inviteCodeBody),
          const SizedBox(height: 12),
          SelectableText(
            code == null ? '…' : '${code.substring(0, 4)}-${code.substring(4)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l10n.copy),
                onPressed: code == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.copied)),
                        );
                      },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.share),
                onPressed: code == null
                    ? null
                    : () => SharePlus.instance.share(
                        ShareParams(
                          text: l10n.inviteMembersMessage(
                            society.name,
                            code,
                            AppLinks(ref.read(flavorProvider)).site,
                          ),
                        ),
                      ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.newCode),
                onPressed: () => _regenerate(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.newCodeTitle),
        content: Text(l10n.newCodeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.newCode),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(societyRepositoryProvider)
          .regenerateInviteCode(society.id);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _HoaForm extends ConsumerStatefulWidget {
  const _HoaForm({required this.societyId});

  final String societyId;

  @override
  ConsumerState<_HoaForm> createState() => _HoaFormState();
}

class _HoaFormState extends ConsumerState<_HoaForm> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _website = TextEditingController();
  final _account = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _company.dispose();
    _website.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(societyRepositoryProvider)
          .saveHoa(
            widget.societyId,
            HoaInfo(
              company: _company.text,
              website: _website.text,
              accountUrl: _account.text,
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hoa = ref.watch(hoaProvider(widget.societyId)).value;
    if (hoa != null && !_loaded) {
      _loaded = true;
      _company.text = hoa.company;
      _website.text = hoa.website;
      _account.text = hoa.accountUrl;
    }
    String? url(String? v) =>
        isValidHttpsUrl(normalizeUrl(v ?? '')) ? null : l10n.invalidLink;
    return SocietyCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.hoaHelp),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.hoaCompany),
            ),
            TextFormField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.hoaWebsite),
              validator: url,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.hoaAccountLink,
                helperText: l10n.hoaAccountLinkHelp,
                helperMaxLines: 2,
              ),
              validator: url,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
