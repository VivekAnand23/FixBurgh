// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FixBurgh';

  @override
  String get navMap => 'Map';

  @override
  String get navReport => 'Report';

  @override
  String get navMyReports => 'My Reports';

  @override
  String get navProfile => 'Profile';

  @override
  String get notForEmergencies =>
      'FixBurgh is not monitored for emergencies. Call 911.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get welcomeTitle => 'Spot it. Snap it. FixBurgh.';

  @override
  String get welcomeBody =>
      'Report potholes, landslides, dark streetlights and more anywhere in Allegheny County. We tell you exactly who fixes it.';

  @override
  String get welcomePrivacy =>
      'No ads. We never sell your data. Your name is never shown on the map.';

  @override
  String get welcomeContinue => 'Get started';

  @override
  String get ageTitle => 'When were you born?';

  @override
  String get ageBody => 'We ask everyone this question.';

  @override
  String get ageMonth => 'Month';

  @override
  String get ageYear => 'Year';

  @override
  String get ageContinue => 'Continue';

  @override
  String get ageBlockedTitle => 'Sorry, you can\'t use FixBurgh yet';

  @override
  String get ageBlockedBody =>
      'Ask a parent or guardian to report the problem for you. Nothing you entered was saved.';

  @override
  String get mapTitle => 'Community map';

  @override
  String get mapPlaceholder => 'Reports near you will appear here.';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportPlaceholder =>
      'The photo, location and details flow comes next.';

  @override
  String get myReportsTitle => 'My Reports';

  @override
  String get myReportsEmpty => 'You haven\'t reported anything yet.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuest => 'You\'re using FixBurgh as a guest';

  @override
  String get profileGuestBody =>
      'Sign in to keep your reports on every device and get updates.';

  @override
  String profileSignedInAs(String who) {
    return 'Signed in as $who';
  }

  @override
  String get profileEmailUnverified => 'Check your inbox to verify your email.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account. This can\'t be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get dataSources => 'Data sources';

  @override
  String get dataSourcesBody =>
      'Municipal boundaries and County roads: Allegheny County GIS via the Western Pennsylvania Regional Data Center. State roads: PennDOT open data.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInBody => 'Your guest reports stay with you.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orUseEmail => 'or use email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get needAccount => 'I need a new account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String resetEmailSent(String email) {
    return 'We sent a reset link to $email.';
  }

  @override
  String verifyEmailSent(String email) {
    return 'Account created. We sent a verification link to $email.';
  }

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorWeakPassword => 'Use at least 8 characters.';

  @override
  String get errorInvalidCredentials => 'That email and password don\'t match.';

  @override
  String get errorEmailInUse =>
      'That email already has an account. Sign in instead.';

  @override
  String get errorCredentialInUse =>
      'That account already exists, so we signed you in to it.';

  @override
  String get errorRequiresRecentLogin =>
      'For your security, sign in again and then retry.';

  @override
  String get errorNetwork => 'No connection. Check your signal and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';
}
