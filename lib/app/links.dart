/// Public pages from `hosting/public`, served by Firebase Hosting on the
/// prod project (the URLs given to the app stores).
abstract final class AppLinks {
  static const site = 'https://fixburgh-prod.web.app';
  static const privacy = '$site/privacy';
  static const terms = '$site/terms';
  static const deleteAccount = '$site/delete-account';

  /// Support address for Profile > Contact support. Until one is chosen,
  /// that row opens [site] instead.
  static const String? supportEmail = null;
}
