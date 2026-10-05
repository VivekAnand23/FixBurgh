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
  String get reportTitle => 'Report a problem';

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

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get next => 'Next';

  @override
  String get edit => 'Edit';

  @override
  String editSection(String section) {
    return 'Edit $section';
  }

  @override
  String get safetyTitle => 'First, is anyone in danger right now?';

  @override
  String get dangerWires => 'Downed or sparking power lines';

  @override
  String get dangerGasFire => 'Gas smell, smoke or fire';

  @override
  String get dangerCrash => 'A crash or a car stuck in traffic';

  @override
  String get dangerTrapped => 'Someone hurt or trapped';

  @override
  String get dangerWater => 'Water over a road deeper than a car\'s wheels';

  @override
  String get safetyYes => 'Yes, someone could get hurt';

  @override
  String get safetyNo => 'No, continue to report';

  @override
  String get safetyPhotoTip =>
      'Only take photos when it\'s safe. Never stop in traffic.';

  @override
  String get emergencyTitle => 'Call 911 now';

  @override
  String get emergencyBody =>
      'This needs emergency responders. FixBurgh reports are not monitored for emergencies. Stay back from wires and water.';

  @override
  String get call911 => 'Call 911';

  @override
  String get notAnEmergency => 'It\'s not an emergency';

  @override
  String get photoTitle => 'Add a photo';

  @override
  String photoBody(int count) {
    return 'Up to $count photos. Try to show the whole problem.';
  }

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromLibrary => 'Choose from library';

  @override
  String get locationTitle => 'Where is it?';

  @override
  String get locationHint =>
      'Search an address, or zoom in and drag the pin to the exact spot.';

  @override
  String get locationDenied =>
      'Location is off, so we started downtown. Move the pin to the spot.';

  @override
  String get mapSemantics => 'Map. Drag the pin to mark the problem.';

  @override
  String inMunicipality(String name) {
    return 'In $name';
  }

  @override
  String get outsideCounty =>
      'This spot is outside Allegheny County. FixBurgh only covers Allegheny County for now.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get whatIsIt => 'What is it?';

  @override
  String get howBad => 'How bad is it?';

  @override
  String get describeIt => 'Describe it (optional)';

  @override
  String get describeHint => 'e.g. Deep pothole in the right lane';

  @override
  String get catPothole => 'Pothole';

  @override
  String get catLandslide => 'Landslide';

  @override
  String get catFlooding => 'Flooding or drain';

  @override
  String get catStreetlight => 'Streetlight';

  @override
  String get catDumping => 'Illegal dumping';

  @override
  String get catFallenTree => 'Fallen tree';

  @override
  String get catSidewalk => 'Sidewalk';

  @override
  String get catOther => 'Other';

  @override
  String get sevLow => 'Low';

  @override
  String get sevMedium => 'Medium';

  @override
  String get sevUrgent => 'Urgent';

  @override
  String get statusReported => 'Reported';

  @override
  String get statusSent => 'Sent to agency';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get reviewTitle => 'Check and send';

  @override
  String get photos => 'Photos';

  @override
  String get location => 'Location';

  @override
  String get details => 'Details';

  @override
  String get reviewPublicNote =>
      'Your report goes on the community map so neighbors can say \"Me too\". Your name is never shown.';

  @override
  String get submitReport => 'Submit report';

  @override
  String get submitting => 'Sending...';

  @override
  String get reportSubmitted =>
      'Report sent. Thanks for looking out for your neighborhood.';

  @override
  String get submitFailed =>
      'We couldn\'t send your report. Check your connection and try again.';

  @override
  String get markFixed => 'Mark fixed';

  @override
  String mapReportsSemantics(int count) {
    return 'Map showing $count open reports';
  }

  @override
  String get locating => 'Finding your location...';

  @override
  String improvingAccuracy(int meters) {
    return 'Improving accuracy... now within $meters m';
  }

  @override
  String accurateTo(int meters) {
    return 'GPS accurate to about $meters m. Drag the pin if it\'s off.';
  }

  @override
  String get pinPlacedByHand => 'Pin placed by hand.';

  @override
  String get approximateOnly =>
      'Precise Location is off, so GPS is approximate. Turn it on in Settings or drag the pin to the exact spot.';

  @override
  String get showSatellite => 'Show satellite view';

  @override
  String get showMap => 'Show map view';

  @override
  String get searchAddress => 'Search address';

  @override
  String get searchAddressHint => 'e.g. 414 Grant St, Pittsburgh';

  @override
  String get addressNotFound =>
      'We couldn\'t find that address in Allegheny County. Try adding the street number or town.';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get pinFromSearch =>
      'Pin placed at the address you searched. Drag it to the exact spot.';

  @override
  String get whoFixesThis => 'Who fixes this?';

  @override
  String get routingUnavailable =>
      'We couldn\'t find the responsible office for this spot.';

  @override
  String get thisRoad => 'This road';

  @override
  String whyStateRoad(String road) {
    return '$road is a state road, so PennDOT maintains it, even inside a city or borough.';
  }

  @override
  String whyTurnpike(String road) {
    return '$road is part of the Pennsylvania Turnpike.';
  }

  @override
  String whyCountyRoad(String road) {
    return '$road is maintained by Allegheny County, not the municipality.';
  }

  @override
  String whyLocalRoad(String municipality) {
    return 'This is a local street, so $municipality handles it.';
  }

  @override
  String whyMunicipalService(String municipality) {
    return '$municipality handles this kind of problem in its area.';
  }

  @override
  String get badgeStateRoad => 'State road';

  @override
  String badgeStateRoute(String route) {
    return 'State road · Route $route';
  }

  @override
  String get badgeTurnpike => 'PA Turnpike';

  @override
  String get badgeCountyRoad => 'County road';

  @override
  String get badgeLocalRoad => 'Local street';

  @override
  String notTheirs(String name) {
    return 'If they say it isn\'t theirs, contact $name.';
  }

  @override
  String get callOffice => 'Call';

  @override
  String get emailOffice => 'Email';

  @override
  String get openWebForm => 'Web form';

  @override
  String get website => 'Website';

  @override
  String get copyDetails => 'Copy details';

  @override
  String get detailsCopied =>
      'Report details copied. Paste them into the form or email.';

  @override
  String get summaryIssue => 'Issue';

  @override
  String get summaryLocation => 'Location';

  @override
  String get summaryCoordinates => 'Coordinates';

  @override
  String get summaryMap => 'Map';

  @override
  String get summaryDescription => 'Description';

  @override
  String get summaryFooter =>
      'Reported with FixBurgh, a free community app for Allegheny County.';

  @override
  String emailSubject(String category, String severity, String place) {
    return '[FixBurgh] $category ($severity) at $place';
  }

  @override
  String get nowTellThem => 'Now tell them';

  @override
  String get nowTellThemBody =>
      'Your report is on the map. Contacting the office is what gets it fixed. We copy the details for you.';

  @override
  String get later => 'Later';

  @override
  String get contactOffice => 'Contact office';
}
