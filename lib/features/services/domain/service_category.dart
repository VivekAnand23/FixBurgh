import 'dart:convert';

import 'package:fixburgh/app/remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One kind of service, e.g. plumbing or dog walking, with the everyday
/// words that point to it ("tap", "leak" for plumbing).
typedef ServiceCategory = ({String id, String label, List<String> synonyms});

/// A group of categories that share the checks a provider passes before
/// approval, e.g. Home repair needs a contractor registration.
typedef ServiceCategoryGroup = ({
  String id,
  String label,
  String approvalCheck,
  List<ServiceCategory> categories,
});

/// Reads the `service_categories` Remote Config JSON. Falls back to the
/// bundled default when the value is missing or malformed.
List<ServiceCategoryGroup> parseServiceCategories(String json) {
  Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    decoded = null;
  }
  if (decoded is! List<Object?>) {
    return json == serviceCategoriesDefault
        ? const []
        : parseServiceCategories(serviceCategoriesDefault);
  }
  return [
    for (final g in decoded)
      if (g case {
        'id': final String id,
        'label': final String label,
        'approvalCheck': final String check,
        'categories': final List<Object?> cats,
      })
        (
          id: id,
          label: label,
          approvalCheck: check,
          categories: [
            for (final c in cats)
              if (c case {'id': final String id, 'label': final String label})
                (
                  id: id,
                  label: label,
                  synonyms: [
                    ...((c as Map)['synonyms'] as List? ?? const [])
                        .whereType<String>(),
                  ],
                ),
          ],
        ),
  ];
}

/// The service category groups (Burghood Phase 3).
final serviceCategoriesProvider = Provider<List<ServiceCategoryGroup>>((ref) {
  final rc = ref.watch(remoteConfigProvider).value;
  final json = rc?.getString('service_categories') ?? '';
  return parseServiceCategories(
    json.trim().isEmpty ? serviceCategoriesDefault : json,
  );
});

/// The group that needs background checks; its providers show a
/// "Background checked" badge.
const personalCareGroup = 'personal_care';

/// Categories caring for children (also need PA clearances).
const childCareCategories = {'babysitting', 'nanny', 'tutoring'};

/// Personal care and everyday help are booked from Services; repairs and
/// home care are reported as problems.
bool isBookable(String groupId) =>
    groupId == personalCareGroup || groupId == 'everyday_help';

extension ServiceCategoryLookup on List<ServiceCategoryGroup> {
  ServiceCategory? category(String id) => [
    for (final g in this) ...g.categories,
  ].where((c) => c.id == id).firstOrNull;

  ServiceCategoryGroup? groupOf(String categoryId) => where(
    (g) => g.categories.any((c) => c.id == categoryId),
  ).firstOrNull;
}

const _stopWords = {
  'a',
  'an',
  'and',
  'the',
  'of',
  'for',
  'to',
  'in',
  'on',
  'my',
  'our',
  'is',
  'it',
  'with',
  'at',
  'we',
  'i',
  'you',
  'your',
  'need',
  'needs',
  'help',
  'please',
  'from',
  'or',
  'not',
  'no',
  'are',
  'be',
  'by',
  'under',
};

/// Lower-case words of [text], without common filler words. Matches the
/// server's `tokens` in functions/src/services.ts.
List<String> searchTokens(String text) => [
  for (final w in text.toLowerCase().split(RegExp('[^a-z0-9]+')))
    if (w.length > 1 && !_stopWords.contains(w)) w,
];

/// Categories a request's description points to, best first: each synonym
/// phrase or word found in [text] scores one, the category's own label two.
/// "kitchen tap leaking under the sink" finds Plumbing.
List<ServiceCategory> detectCategories(
  String text,
  List<ServiceCategoryGroup> groups, {
  int max = 3,
}) {
  final lower = ' ${searchTokens(text).join(' ')} ';
  if (lower.trim().isEmpty) return const [];
  final scored = <(ServiceCategory, int)>[];
  for (final c in [for (final g in groups) ...g.categories]) {
    var score = 0;
    for (final phrase in c.synonyms) {
      final p = searchTokens(phrase).join(' ');
      if (p.isNotEmpty && lower.contains(' $p ')) score += 1;
    }
    final label = searchTokens(c.label).join(' ');
    if (label.isNotEmpty && lower.contains(' $label ')) score += 2;
    if (score > 0) scored.add((c, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (c, _) in scored.take(max)) c];
}
