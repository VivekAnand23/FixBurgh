import 'package:fixburgh/app/bootstrap.dart';
import 'package:fixburgh/app/flavor.dart';

/// Default entry point. Prefer `lib/main_dev.dart` or `lib/main_prod.dart`
/// with the matching `--flavor`.
Future<void> main() => bootstrap(Flavor.prod);
