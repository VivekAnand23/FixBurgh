import 'package:fixburgh/app/flavor.dart';

/// Public pages from `hosting/public`, served by Firebase Hosting on each
/// flavor's project (prod's are the URLs given to the app stores).
class AppLinks {
  const AppLinks(this.flavor);

  final Flavor flavor;

  String get site => switch (flavor) {
    Flavor.dev => 'https://fixburgh-dev.web.app',
    Flavor.prod => 'https://fixburgh-prod.web.app',
  };
  String get privacy => '$site/privacy';
  String get terms => '$site/terms';
  String get deleteAccount => '$site/delete-account';

  /// Support address for Profile > Contact support.
  static const supportEmail = 'viv.anand@gmail.com';
}
