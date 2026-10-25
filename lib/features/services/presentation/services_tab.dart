import 'dart:async';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/google_results.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/services/presentation/service_widgets.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The society's Services tab: find a provider by category or by
/// describing the problem, within a distance, best rated first, with the
/// society's recommendations on top.
class ServicesTab extends ConsumerStatefulWidget {
  const ServicesTab({required this.societyId, required this.me, super.key});

  final String societyId;
  final Membership me;

  @override
  ConsumerState<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<ServicesTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _text = '';
  String? _category;
  int _miles = 10;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onText(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _text = v.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(serviceCategoriesProvider);
    final society = ref.watch(societyProvider(widget.societyId)).value;
    final detected = _category == null
        ? detectCategories(_text, groups)
        : const <ServiceCategory>[];
    final query = ProviderQuery(
      text: _category == null ? _text : '',
      categories: _category != null
          ? [_category!]
          : [for (final c in detected) c.id],
      near: society?.location,
      miles: _miles,
      societyId: widget.societyId,
    );
    final results = ref.watch(providerSearchProvider(query));
    // What to look up on Google when nothing listed matches: the category
    // picked or detected, else the words typed.
    final googleQuery = _category != null
        ? groups.category(_category!)?.label
        : detected.isNotEmpty
        ? detected.first.label
        : _text.isEmpty
        ? null
        : _text;
    final sponsored =
        ref.watch(sponsoredSearchProvider(query)).value ??
        const <SponsoredResult>[];
    final open = widget.me.isAdmin
        ? (ref.watch(commonRequestsProvider(widget.societyId)).value ??
                  const <ServiceRequest>[])
              .where((r) => r.status.isOpen)
              .length
        : 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('services-request'),
                icon: const Icon(Icons.add),
                label: Text(l10n.requestService),
                onPressed: () => context.push(
                  Routes.newServiceRequest,
                  extra: RequestFormArgs(
                    scope: RequestScope.home,
                    societyId: widget.societyId,
                  ),
                ),
              ),
            ),
            if (widget.me.isAdmin) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('services-common'),
                  icon: Badge(
                    isLabelVisible: open > 0,
                    label: Text('$open'),
                    child: const Icon(Icons.apartment),
                  ),
                  label: Text(l10n.commonRequests),
                  onPressed: () =>
                      context.push(Routes.commonRequests(widget.societyId)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('services-search'),
          controller: _search,
          onChanged: _onText,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.servicesSearchHint,
            border: const OutlineInputBorder(),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _text = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (_category != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputChip(
              label: Text(groups.category(_category!)?.label ?? _category!),
              selected: true,
              onDeleted: () => setState(() => _category = null),
            ),
          )
        else if (detected.isNotEmpty)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.lookingFor, style: theme.textTheme.bodySmall),
              for (final c in detected)
                ActionChip(
                  key: Key('detected-${c.id}'),
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(c.label),
                  onPressed: () => setState(() => _category = c.id),
                ),
            ],
          )
        else if (_text.isEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in [for (final g in groups) ...g.categories])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ActionChip(
                      label: Text(c.label),
                      onPressed: () => setState(() => _category = c.id),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Semantics(
          label: l10n.distanceFilter,
          child: Wrap(
            spacing: 8,
            children: [
              for (final m in distanceOptions)
                ChoiceChip(
                  key: Key('miles-$m'),
                  label: Text(l10n.withinMiles(m)),
                  selected: _miles == m,
                  onSelected: (_) => setState(() => _miles = m),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (sponsored.isNotEmpty) ...[
          _SectionLabel(text: l10n.sponsored),
          for (final s in sponsored)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ProviderCard(
                key: Key('sponsored-${s.sponsorshipId}'),
                result: (
                  provider: s.provider,
                  distanceMiles: null,
                  recommended: false,
                ),
                sponsored: true,
                onTap: () => context.push(
                  Routes.provider(s.provider.id, societyId: widget.societyId),
                ),
              ),
            ),
          const Divider(height: 24),
          _SectionLabel(text: l10n.allProviders),
        ],
        ...results.when(
          loading: () => [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [Text(l10n.errorGeneric)],
          data: (list) => list.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noProvidersFound,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (googleQuery != null && society != null)
                    GoogleResults(
                      query: googleQuery,
                      near: society.location,
                      miles: _miles,
                    ),
                ]
              : [
                  for (final r in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProviderCard(
                        result: r,
                        onTap: () => context.push(
                          Routes.provider(
                            r.provider.id,
                            societyId: widget.societyId,
                          ),
                        ),
                      ),
                    ),
                ],
        ),
        const SizedBox(height: 16),
        const BecomeProviderLink(),
      ],
    );
  }
}

/// A search result row.
class ProviderCard extends ConsumerWidget {
  const ProviderCard({
    required this.result,
    required this.onTap,
    this.sponsored = false,
    super.key,
  });

  final ProviderResult result;
  final VoidCallback onTap;

  /// A paid sponsorship: orange border and a Sponsored badge.
  final bool sponsored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ref.watch(serviceCategoriesProvider);
    final p = result.provider;
    return SocietyCard(
      padding: EdgeInsets.zero,
      borderColor: sponsored ? AppColors.orange : null,
      color: sponsored && theme.brightness == Brightness.light
          ? AppColors.orangeTint
          : null,
      child: InkWell(
        key: Key('${sponsored ? 'sponsored-card' : 'provider'}-${p.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sponsored) ...[
                const SponsoredBadge(),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.businessName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  RatingLine(provider: p),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  categoryLabels(p.categories, groups),
                  if (result.distanceMiles != null)
                    l10n.milesAway(result.distanceMiles!.toStringAsFixed(1)),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (result.recommended || p.backgroundChecked) ...[
                const SizedBox(height: 8),
                ProviderBadges(provider: p, recommended: result.recommended),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Offer your services" for neighbors, or their application's status.
class BecomeProviderLink extends ConsumerWidget {
  const BecomeProviderLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mine = ref.watch(myProviderProvider).value;
    final subtitle = switch (mine?.status) {
      null => l10n.becomeProviderBody,
      ProviderStatus.applied => l10n.providerApplied,
      ProviderStatus.approved => l10n.providerLive,
      ProviderStatus.awaitingFee => l10n.providerAwaitingFeeShort,
      ProviderStatus.rejected => l10n.providerRejected,
      ProviderStatus.suspended => l10n.providerSuspended,
    };
    return SocietyCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: const Key('become-provider'),
        leading: const Icon(Icons.storefront_outlined),
        title: Text(
          mine == null ? l10n.becomeProvider : l10n.yourProviderProfile,
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Providers need a full account; guests sign in first.
          if (!hasFullAccount(ref.read(authUserProvider).value) &&
              !await requireFullAccount(context, ref)) {
            return;
          }
          if (context.mounted) await context.push(Routes.becomeProvider);
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}

/// The "Sponsored" label on a paid listing.
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? AppColors.orange : AppColors.orange700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        AppLocalizations.of(context).sponsored,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
