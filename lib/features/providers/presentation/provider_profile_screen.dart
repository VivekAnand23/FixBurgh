import 'dart:async';

import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/services/presentation/service_widgets.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/pickers.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// A provider's public profile: services, area, past work and reviews with
/// the provider's replies. Opened from a society, [societyId] adds its
/// recommendation (and the toggle for its admins).
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({
    required this.providerId,
    this.societyId,
    super.key,
  });

  final String providerId;
  final String? societyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = ref.watch(providerProvider(providerId));
    final groups = ref.watch(serviceCategoriesProvider);
    final uid = ref.watch(authUserProvider).value?.uid;
    final sid = societyId;
    final recommended =
        sid != null &&
        (ref.watch(recommendedProvider(sid)).value?.contains(providerId) ??
            false);
    final isAdmin =
        sid != null &&
        (ref.watch(myMembershipProvider(sid)).value?.isAdmin ?? false);
    final p = provider.value;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : PlaceholderBody(
                icon: Icons.storefront_outlined,
                message: l10n.providerNotFound,
              ),
      );
    }
    final isOwner = uid == p.id;
    return Scaffold(
      appBar: AppBar(title: Text(p.businessName)),
      bottomNavigationBar: isOwner || p.status != ProviderStatus.approved
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const Key('request-provider'),
                  icon: const Icon(Icons.send),
                  label: Text(l10n.requestThisProvider),
                  onPressed: () => context.push(
                    Routes.newServiceRequest,
                    extra: RequestFormArgs(
                      scope: RequestScope.home,
                      societyId: sid,
                      providerId: p.id,
                      providerName: p.businessName,
                      category: p.categories.length == 1
                          ? p.categories.first
                          : null,
                    ),
                  ),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              RatingLine(provider: p),
              const SizedBox(width: 12),
              Expanded(
                child: ProviderBadges(provider: p, recommended: recommended),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('recommend-toggle'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recommendToSociety),
              subtitle: Text(l10n.recommendToSocietyBody),
              value: recommended,
              onChanged: (v) => unawaited(
                ref
                    .read(providerRepositoryProvider)
                    .setRecommended(sid, p.id, uid: uid!, recommended: v),
              ),
            ),
          ],
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.description, style: theme.textTheme.bodyLarge),
          ],
          _Section(title: l10n.providerServices),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in p.categories)
                Chip(label: Text(groups.category(c)?.label ?? c)),
            ],
          ),
          _Section(title: l10n.serviceArea),
          Text(
            l10n.serviceAreaLine(
              p.areaLabel,
              p.radiusMiles.toStringAsFixed(0),
            ),
          ),
          _Section(title: l10n.portfolio),
          if (p.portfolio.isEmpty && !isOwner)
            Text(l10n.noPortfolio, style: theme.textTheme.bodySmall),
          SizedBox(
            height: p.portfolio.isEmpty && !isOwner ? 0 : 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, url) in p.portfolio.indexed)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                        semanticLabel: l10n.portfolioPhoto(i + 1),
                        errorBuilder: (_, _, _) => const SizedBox.square(
                          dimension: 104,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                if (isOwner)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size(104, 104),
                    ),
                    onPressed: () async {
                      final f = await ref.read(pickImageProvider)(
                        ImageSource.gallery,
                      );
                      if (f == null) return;
                      await ref
                          .read(providerRepositoryProvider)
                          .addPortfolioPhoto(p.id, f);
                    },
                    child: Semantics(
                      label: l10n.addPortfolioPhoto,
                      child: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                  ),
              ],
            ),
          ),
          _Section(title: l10n.reviewsCount(p.ratingCount)),
          _Reviews(providerId: p.id, isOwner: isOwner),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.providerId, required this.isOwner});

  final String providerId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reviews = ref.watch(reviewsProvider(providerId)).value ?? const [];
    if (reviews.isEmpty) {
      return Text(l10n.noReviewsYet, style: theme.textTheme.bodySmall);
    }
    return Column(
      children: [
        for (final r in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SocietyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: l10n.starsLabel(r.stars),
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                i <= r.stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            r.authorName,
                            if (r.createdAt != null)
                              DateFormat.yMMMd().format(r.createdAt!),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (r.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(r.comment),
                  ],
                  if (r.reply.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.providerReply,
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(r.reply),
                        ],
                      ),
                    )
                  else if (isOwner)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        icon: const Icon(Icons.reply),
                        label: Text(l10n.replyToReview),
                        onPressed: () => unawaited(_reply(context, ref, r)),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _reply(BuildContext context, WidgetRef ref, Review r) async {
    final text = await showTextDialog(
      context,
      title: AppLocalizations.of(context).replyToReview,
      maxLength: 500,
    );
    if (text == null || text.trim().isEmpty) return;
    await ref.read(providerRepositoryProvider).reply(providerId, r.id, text);
  }
}

/// Asks for a short text. Null when cancelled. Owns its controller, so it
/// isn't disposed while the dialog animates closed.
Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  String? hint,
  int maxLength = 300,
  bool required = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextDialog(
    title: title,
    hint: hint,
    maxLength: maxLength,
    required: required,
  ),
);

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.hint,
    required this.maxLength,
    required this.required,
  });

  final String title;
  final String? hint;
  final int maxLength;
  final bool required;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('text-dialog-field'),
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        minLines: 2,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('text-dialog-ok'),
          onPressed: widget.required && _text.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _text.text),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
