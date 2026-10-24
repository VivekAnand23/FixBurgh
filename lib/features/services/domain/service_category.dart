import 'dart:convert';

import 'package:fixburgh/app/remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One kind of service, e.g. plumbing or dog walking.
typedef ServiceCategory = ({String id, String label});

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
                (id: id, label: label),
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
