import 'package:fixburgh/app/home_shell.dart';
import 'package:fixburgh/features/auth/sign_in_screen.dart';
import 'package:fixburgh/features/map/map_screen.dart';
import 'package:fixburgh/features/my_reports/my_reports_screen.dart';
import 'package:fixburgh/features/onboarding/age_gate_screen.dart';
import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:fixburgh/features/onboarding/welcome_screen.dart';
import 'package:fixburgh/features/profile/profile_screen.dart';
import 'package:fixburgh/features/report/report_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const welcome = '/welcome';
  static const age = '/age';
  static const ageBlocked = '/age-blocked';
  static const map = '/map';
  static const report = '/report';
  static const myReports = '/my-reports';
  static const profile = '/profile';
  static const signIn = '/sign-in';
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
                path: Routes.report,
                builder: (_, _) => const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myReports,
                builder: (_, _) => const MyReportsScreen(),
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
