import 'dart:async';

import 'package:fixburgh/app/links.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/map/data/place_search.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/claim_status.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Search finds a place with the free platform geocoder (as the map search
/// does) and lists active societies within [nearbySocietyM] of it, plus
/// any whose name starts with the text.
typedef SocietySearch =
    Future<List<SocietyResult>> Function(SocietyRepository repo, String q);

Future<List<SocietyResult>> searchSocieties(
  SocietyRepository repo,
  String q,
) async {
  final point = await findPlace(q);
  final results = await Future.wait([
    if (point != null) repo.searchNearby(point),
    repo.searchByName(q, near: point),
  ]);
  final byId = <String, SocietyResult>{};
  for (final r in results.expand((l) => l)) {
    byId.putIfAbsent(r.society.id, () => r);
  }
  return byId.values.toList()..sort(
    (a, b) => (a.distanceM ?? double.infinity).compareTo(
      b.distanceM ?? double.infinity,
    ),
  );
}

/// Overridden in tests.
final societySearchProvider = Provider<SocietySearch>(
  (ref) => searchSocieties,
);

/// Society tab for people not in a society yet (mock 2).
class FindSocietyView extends ConsumerStatefulWidget {
  const FindSocietyView({super.key});

  @override
  ConsumerState<FindSocietyView> createState() => _FindSocietyViewState();
}

class _FindSocietyViewState extends ConsumerState<FindSocietyView> {
  final _query = TextEditingController();
  AsyncValue<List<SocietyResult>>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() => _results = const AsyncLoading());
    final repo = ref.read(societyRepositoryProvider);
    final found = await AsyncValue.guard(
      () => ref.read(societySearchProvider)(repo, q),
    );
    if (mounted) setState(() => _results = found);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final claims = ref.watch(myClaimsProvider).value ?? const [];
    final pending = ref.watch(myPendingRequestsProvider).value ?? const [];
    final results = _results;
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? AppColors.pageBg
          : null,
      appBar: AppBar(
        title: Text(l10n.findSocietyTitle),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final c in claims.take(3)) ...[
            ClaimCard(claim: c),
            const SizedBox(height: 12),
          ],
          for (final sid in pending) ...[
            _PendingRequestCard(societyId: sid),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: l10n.findSocietyHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: l10n.search,
                icon: const Icon(Icons.arrow_forward),
                onPressed: _search,
              ),
              filled: true,
              fillColor: theme.brightness == Brightness.light
                  ? Colors.white
                  : null,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (results != null)
            ...results.when(
              loading: () => [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [Text(l10n.errorGeneric)],
              data: (list) => [
                Text(
                  list.isEmpty
                      ? l10n.noSocietiesFound
                      : l10n.societiesNearAddress(list.length),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, r) in list.indexed) ...[
                  _ResultCard(
                    result: r,
                    first: i == 0,
                    requested: pending.contains(r.society.id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          const SizedBox(height: 12),
          Text(
            l10n.dontSeeYours,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _CreateCard(),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.key_outlined),
              label: Text(l10n.haveInviteCode),
              onPressed: () => unawaited(showInviteCodeSheet(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({
    required this.result,
    required this.first,
    required this.requested,
  });

  final SocietyResult result;
  final bool first;
  final bool requested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = result.society;
    final join = requested
        ? OutlinedButton(onPressed: null, child: Text(l10n.requestSent))
        : FilledButton(
            onPressed: () => unawaited(showJoinSheet(context, s)),
            child: Text(l10n.requestToJoin),
          );
    return SocietyCard(
      child: Column(
        children: [
          InkWell(
            onTap: requested || first
                ? null
                : () => unawaited(showJoinSheet(context, s)),
            child: Row(
              children: [
                SocietyAvatar(society: s, highlight: first),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        societySummary(l10n, s, distanceM: result.distanceM),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.verified) const VerifiedLabel(),
              ],
            ),
          ),
          if (first || requested) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: join),
          ],
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createSociety,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.createSocietyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          InfoBox(text: l10n.createSocietyNeeds),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              onPressed: () => context.push(Routes.createSociety),
              child: Text(l10n.imTheAdmin),
            ),
          ),
          Center(
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => unawaited(shareInviteToAdmin(context, ref)),
                child: Text(l10n.notTheAdmin),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Not the admin? Invite them": shares a download link.
Future<void> shareInviteToAdmin(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final link = AppLinks(ref.read(flavorProvider)).site;
  return SharePlus.instance.share(
    ShareParams(text: l10n.inviteAdminMessage(link), subject: l10n.appTitle),
  );
}

class _PendingRequestCard extends ConsumerWidget {
  const _PendingRequestCard({required this.societyId});

  final String societyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final society = ref.watch(societyProvider(societyId)).value;
    final uid = ref.watch(authUserProvider).value?.uid;
    return SocietyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.hourglass_top),
        title: Text(l10n.requestPendingTitle(society?.name ?? '')),
        subtitle: Text(l10n.requestPendingBody),
        trailing: uid == null
            ? null
            : TextButton(
                onPressed: () =>
                    ref.read(societyRepositoryProvider).leave(societyId, uid),
                child: Text(l10n.withdraw),
              ),
      ),
    );
  }
}

/// Asks for a unit number and sends a join request.
Future<void> showJoinSheet(BuildContext context, Society society) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _JoinSheet(society: society),
    );

class _JoinSheet extends ConsumerStatefulWidget {
  const _JoinSheet({required this.society});

  final Society society;

  @override
  ConsumerState<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<_JoinSheet> {
  final _unit = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _unit.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _unit.text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(societyRepositoryProvider)
          .requestToJoin(
            widget.society.id,
            uid: user.uid,
            unit: _unit.text,
            displayName: user.displayName ?? '',
          );
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.requestSentBody)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.joinSocietyTitle(widget.society.name),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.joinSocietyBody),
          const SizedBox(height: 16),
          TextField(
            controller: _unit,
            autofocus: true,
            maxLength: 20,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.unitNumber,
              hintText: l10n.unitNumberHint,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || _unit.text.trim().isEmpty ? null : _send,
            child: Text(l10n.requestToJoin),
          ),
        ],
      ),
    );
  }
}

/// Joins straight away with an invite code from a society admin.
Future<void> showInviteCodeSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _InviteCodeSheet(),
    );

class _InviteCodeSheet extends ConsumerStatefulWidget {
  const _InviteCodeSheet();

  @override
  ConsumerState<_InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends ConsumerState<_InviteCodeSheet> {
  final _code = TextEditingController();
  final _unit = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sid = await ref
          .read(societyRepositoryProvider)
          .joinWithCode(_code.text, unit: _unit.text);
      ref.read(selectedSocietyProvider.notifier).select(sid);
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.joinedSociety)));
    } on InvalidInviteCode {
      setState(() => _error = l10n.inviteCodeInvalid);
    } on Exception {
      setState(() => _error = l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = normalizeInviteCode(_code.text).length == 8;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.joinWithCodeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.joinWithCodeBody),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.inviteCode,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unit,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: l10n.unitNumberOptional,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || !ready ? null : _join,
            child: Text(l10n.join),
          ),
        ],
      ),
    );
  }
}
