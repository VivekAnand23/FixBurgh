import 'dart:convert';
import 'dart:io';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final template =
      (jsonDecode(
                File('firebase/remoteconfig.template.json').readAsStringSync(),
              )
              as Map<String, Object?>)['parameters']!
          as Map<String, Object?>;
  String templateValue(String key) =>
      ((template[key]! as Map)['defaultValue'] as Map)['value'] as String;

  test('the bundled categories match the Remote Config template', () {
    expect(
      jsonDecode(serviceCategoriesDefault),
      jsonDecode(templateValue('service_categories')),
    );
  });

  test('has the four groups from the design', () {
    final groups = parseServiceCategories(serviceCategoriesDefault);
    expect(groups.map((g) => g.label), [
      'Home repair',
      'Home care',
      'Personal care',
      'Everyday help',
    ]);
    final personal = groups.firstWhere((g) => g.id == 'personal_care');
    expect(
      personal.categories.map((c) => c.id),
      containsAll(['babysitting', 'pet_sitting', 'dog_walking']),
    );
    final ids = [for (final g in groups) ...g.categories.map((c) => c.id)];
    expect(ids.toSet(), hasLength(ids.length), reason: 'ids are unique');
  });

  test('falls back to the bundled list on bad JSON', () {
    expect(parseServiceCategories('{oops'), hasLength(4));
    expect(parseServiceCategories('{"a": 1}'), hasLength(4));
  });

  test('Burghood flags default to off, in the app and the template', () {
    for (final key in [
      'feature_society',
      'feature_channels',
      'feature_services',
      'feature_monetisation',
    ]) {
      expect(remoteConfigDefaults[key], isFalse, reason: key);
      expect(templateValue(key), 'false', reason: key);
    }
  });
}
