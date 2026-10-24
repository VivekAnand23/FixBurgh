import 'package:fixburgh/app/home_shell.dart';
import 'package:fixburgh/features/activity/activity_screen.dart';
import 'package:fixburgh/features/auth/sign_in_screen.dart';
import 'package:fixburgh/features/map/map_screen.dart';
import 'package:fixburgh/features/notifications/notifications_screen.dart';
import 'package:fixburgh/features/notifications/saved_places_screen.dart';
import 'package:fixburgh/features/onboarding/age_gate_screen.dart';
import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:fixburgh/features/onboarding/welcome_screen.dart';
import 'package:fixburgh/features/profile/data_sources_screen.dart';
import 'package:fixburgh/features/profile/profile_screen.dart';
import 'package:fixburgh/features/report/report_screen.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/claim_status.dart';
import 'package:fixburgh/features/society/presentation/create_society_screen.dart';
import 'package:fixburgh/features/society/presentation/find_society_view.dart';
import 'package:fixburgh/features/society/presentation/manage_screen.dart';
import 'package:fixburgh/features/society/presentation/notice_screens.dart';
import 'package:fixburgh/features/society/society_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const welcome = '/welcome';
  static const age = '/age';
  static const ageBlocked = '/age-blocked';
  static const map = '/map';
  static const society = '/society';
  static const report = '/report';
  static const activity = '/activity';
  static const profile = '/profile';
  static const signIn = '/sign-in';
  static const dataSources = '/data-sources';
  static const notifications = '/notifications';
  static const savedPlaces = '/saved-places';

  // Burghood societies. Screens on top of the tab bar.
  static const findSociety = '/society/find';
  static const createSociety = '/society/create';
  static String claim(String id) => '/society/claims/$id';
  static String manageSociety(String sid) => '/society/$sid/manage';
  static String newNotice(String sid) => '/society/$sid/notices/new';
  static String notice(String sid, String id) => '/society/$sid/notices/$id';
  static String uploadDocument(String sid) => '/society/$sid/documents/new';
}

/// Picks the onboarding screen the user must see, or null when done.
@visibleForTesting
String? onboardingRedirect(OnboardingState s, String location) {
  final target = s.ageBlocked
      ? Routes.ageBlocked
      : !s.welcomeSeen
      ? Routes.welcome
      : !s.ageConfirmed
      ? Routes.age
      : null;
  if (target != null) return location == target ? null : target;
  const onboarding = {Routes.welcome, Routes.age, Routes.ageBlocked};
  return onboarding.contains(location) ? Routes.map : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(onboardingProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.map,
    refreshListenable: refresh,
    redirect: (context, state) =>
        onboardingRedirect(ref.read(onboardingProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: Routes.age, builder: (_, _) => const AgeGateScreen()),
      GoRoute(
        path: Routes.ageBlocked,
        builder: (_, _) => const AgeBlockedScreen(),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.dataSources,
        builder: (_, _) => const DataSourcesScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.savedPlaces,
        builder: (_, _) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: Routes.findSociety,
        builder: (_, _) => const FindSocietyView(),
      ),
      GoRoute(
        path: Routes.createSociety,
        // A rejected claim to resubmit, if any.
        builder: (_, s) =>
            CreateSocietyScreen(previous: s.extra as SocietyClaim?),
      ),
      GoRoute(
        path: '/society/claims/:id',
        builder: (_, s) => ClaimStatusScreen(claimId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/society/:sid/manage',
        builder: (_, s) => ManageScreen(societyId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/society/:sid/notices/new',
        builder: (_, s) =>
            ComposeNoticeScreen(societyId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/society/:sid/notices/:id',
        builder: (_, s) => NoticeScreen(
          societyId: s.pathParameters['sid']!,
          noticeId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/society/:sid/documents/new',
        builder: (_, s) =>
            UploadDocumentScreen(societyId: s.pathParameters['sid']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.map, builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.society,
                builder: (_, _) => const SocietyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.report,
                builder: (_, _) => const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (_, _) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
