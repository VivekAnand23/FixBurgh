import 'package:fixburgh/app/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `bootstrap`.
final flavorProvider = Provider<Flavor>(
  (ref) => throw UnimplementedError('flavorProvider must be overridden'),
);

/// Overridden in `bootstrap` (and in tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);
