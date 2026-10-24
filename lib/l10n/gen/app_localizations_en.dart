// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Burghood';

  @override
  String get navMap => 'Map';

  @override
  String get navSociety => 'Society';

  @override
  String get navReport => 'Report';

  @override
  String get navActivity => 'Activity';

  @override
  String get navProfile => 'Profile';

  @override
  String get notForEmergencies =>
      'Burghood is not monitored for emergencies. Call 911.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get welcomeTitle => 'Spot it. Snap it. Get it fixed.';

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
  String get ageBlockedTitle => 'Sorry, you can\'t use Burghood yet';

  @override
  String get ageBlockedBody =>
      'Ask a parent or guardian to report the problem for you. Nothing you entered was saved.';

  @override
  String get mapTitle => 'Community map';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityCityReports => 'City reports';

  @override
  String get societyTitle => 'Society';

  @override
  String get societyComingSoonBody =>
      'Join your building or neighborhood society to read notices, find documents and talk with neighbors.';

  @override
  String get societySignInToJoin => 'Sign in to join a society';

  @override
  String get societySignedInNote =>
      'You\'re signed in. We\'ll let you know when societies open.';

  @override
  String get societyFindBody => 'Find your society by address or name.';

  @override
  String get accountGateTitle => 'Sign in to continue';

  @override
  String get accountGateBody =>
      'This needs an account. When you sign in, anything you reported as a guest moves to your account.';

  @override
  String get accountGateSignIn => 'Sign in';

  @override
  String get accountGateNotNow => 'Not now';

  @override
  String get myReportsEmpty => 'You haven\'t reported anything yet.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuest => 'You\'re using Burghood as a guest';

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
      'This permanently deletes your account, your votes and your sign-in. This can\'t be undone.';

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
      'This needs emergency responders. Burghood reports are not monitored for emergencies. Stay back from wires and water.';

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
      'This spot is outside Allegheny County. Burghood only covers Allegheny County for now.';

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
      'Reported with Burghood, a free community app for Allegheny County.';

  @override
  String emailSubject(String category, String severity, String place) {
    return '[Burghood] $category ($severity) at $place';
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

  @override
  String get reportGone => 'This report was removed.';

  @override
  String photoOf(String category) {
    return 'Photo of the $category';
  }

  @override
  String routedTo(String name) {
    return 'Responsible office: $name';
  }

  @override
  String meToo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Me too ($count)',
      zero: 'Me too',
    );
    return '$_temp0';
  }

  @override
  String meTooDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You and $count neighbors said me too',
      one: 'You said me too',
    );
    return '$_temp0';
  }

  @override
  String meTooCount(int count) {
    return '$count ✋';
  }

  @override
  String get meTooShort => 'Me too';

  @override
  String get meTooAdded =>
      'Thanks! Your \"Me too\" was added to the existing report.';

  @override
  String looksFixed(int count, int needed) {
    return 'Looks fixed ($count of $needed)';
  }

  @override
  String get alreadyFixed => 'This was marked fixed.';

  @override
  String yourReportStats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your report. $count neighbors said me too.',
      one: 'Your report. 1 neighbor said me too.',
      zero: 'This is your report.',
    );
    return '$_temp0';
  }

  @override
  String get reopen => 'Not fixed? Reopen';

  @override
  String get flagReport => 'Report a problem with this';

  @override
  String get flagTitle => 'What\'s wrong?';

  @override
  String get flagWrongOffice => 'Wrong office';

  @override
  String get flagWrongLocation => 'Wrong location';

  @override
  String get flagWrongCategory => 'Wrong category';

  @override
  String get flagSpam => 'Spam or fake';

  @override
  String get flagOffensive => 'Offensive';

  @override
  String get flagPrivate => 'Shows private information';

  @override
  String get flagThanks => 'Thanks. We\'ll review it.';

  @override
  String get deleteReport => 'Delete report';

  @override
  String get deleteReportTitle => 'Delete this report?';

  @override
  String get deleteReportBody =>
      'It will be removed from the map, along with its photos.';

  @override
  String get showFixed => 'Show fixed';

  @override
  String get showListView => 'Show list';

  @override
  String get showMapView => 'Show map';

  @override
  String get noReportsMatch => 'No reports match these filters.';

  @override
  String get duplicateTitle => 'Already reported?';

  @override
  String duplicateBody(String category, int meters, int days, int upvotes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'yesterday',
      zero: 'today',
    );
    String _temp1 = intl.Intl.pluralLogic(
      upvotes,
      locale: localeName,
      other: ', and $upvotes neighbors said me too.',
      one: ', and 1 neighbor said me too.',
      zero: '.',
    );
    return '$category reported $meters m away $_temp0$_temp1 Is it the same problem?';
  }

  @override
  String get thisIsDifferent => 'It\'s different';

  @override
  String guestLimitReached(int count) {
    return 'You\'ve sent $count reports today. Sign in under Profile to send more and get updates.';
  }

  @override
  String userLimitReached(int count) {
    return 'You\'ve reached today\'s limit of $count reports. Thanks for helping! You can report more tomorrow.';
  }

  @override
  String get blockReporter => 'Hide reports from this person';

  @override
  String get blocked => 'You won\'t see reports from this person.';

  @override
  String blockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people hidden',
      one: '1 person hidden',
    );
    return '$_temp0';
  }

  @override
  String get unblockAll => 'Show again';

  @override
  String get resumeDraftTitle => 'Finish your report?';

  @override
  String get resumeDraftBody =>
      'You started a report earlier but didn\'t send it.';

  @override
  String get continueDraft => 'Continue';

  @override
  String get startOver => 'Start over';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get errorProviderDisabled =>
      'This sign-in method isn\'t available yet. Try another one.';

  @override
  String get markFixedTitle => 'Mark as fixed';

  @override
  String get markFixedBody =>
      'Add an \"after\" photo so neighbors can see the fix. It\'s optional.';

  @override
  String get afterPhotoCamera => 'Take an \"after\" photo';

  @override
  String get afterPhotoGallery => 'Choose an \"after\" photo';

  @override
  String get markFixedNoPhoto => 'Mark fixed without a photo';

  @override
  String get uploadingPhoto => 'Uploading photo…';

  @override
  String get markedFixed => 'Marked as fixed. Thanks for following up!';

  @override
  String get afterPhoto => 'Photo after the fix';

  @override
  String get historyTitle => 'History';

  @override
  String get eventReported => 'Reported';

  @override
  String get eventSentCall => 'Sent to agency by phone';

  @override
  String get eventSentEmail => 'Sent to agency by email';

  @override
  String get eventSentWeb => 'Sent to agency by web form';

  @override
  String get eventResolvedReporter => 'Marked fixed by the reporter';

  @override
  String get eventResolvedCommunity => 'Confirmed fixed by neighbors';

  @override
  String get eventReopened => 'Reopened: not fixed after all';

  @override
  String voteLimitReached(int count) {
    return 'You\'ve used today\'s $count \"Me too\" votes. Try again tomorrow.';
  }

  @override
  String get verifyToVote =>
      'Verify your email first. Check your inbox for the link, then try again.';

  @override
  String tabAll(int count) {
    return 'All ($count)';
  }

  @override
  String tabOpen(int count) {
    return 'Open ($count)';
  }

  @override
  String tabFixed(int count) {
    return 'Fixed ($count)';
  }

  @override
  String get noReportsInTab => 'Nothing here yet.';

  @override
  String get legendTitle => 'Map legend';

  @override
  String get legendUrgent => 'Urgent (red badge)';

  @override
  String get legendFixed => 'Fixed (faded)';

  @override
  String get legendCluster =>
      'A number means several reports close together. Zoom in to see them.';

  @override
  String get searchMap => 'Search an address or place';

  @override
  String get timeRangeTooltip => 'Choose how far back to show reports';

  @override
  String get rangeWeek => 'Last 7 days';

  @override
  String get rangeMonth => 'Last 30 days';

  @override
  String get rangeQuarter => 'Last 90 days';

  @override
  String get rangeYear => 'Last 12 months';

  @override
  String get rangeAll => 'All time';

  @override
  String get deletingAccount => 'Deleting your account…';

  @override
  String get confirmPasswordTitle => 'Enter your password to confirm';

  @override
  String get continueLabel => 'Continue';

  @override
  String get methodGoogle => 'Google';

  @override
  String get methodApple => 'Apple';

  @override
  String get methodEmail => 'email and password';

  @override
  String signedInWith(String method) {
    return 'Signed in with $method';
  }

  @override
  String reportCounts(int total, int open, int fixed) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total reports',
      one: '1 report',
      zero: 'No reports yet',
    );
    return '$_temp0 · $open open · $fixed fixed';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get textSizeTitle => 'Text size';

  @override
  String get textSizeBody => 'Adds to the text size set on your phone.';

  @override
  String get textSizeSystem => 'Default';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeLarger => 'Larger';

  @override
  String get textSizePreview =>
      'Preview: a pothole on Grant Street was reported 2 days ago.';

  @override
  String get aboutTitle => 'About';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get dataSourcesShort => 'Maps, road ownership and office contacts';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get deleteAccountReportsQuestion =>
      'What should happen to your reports?';

  @override
  String get deleteKeepReports => 'Keep them on the map, anonymously';

  @override
  String get deleteKeepReportsBody =>
      'The problems still exist. Nobody will be able to link them to you.';

  @override
  String get deleteRemoveReports => 'Delete them and their photos';

  @override
  String get deleteRemoveReportsBody =>
      'They disappear from the map for everyone.';

  @override
  String get dataSourcesIntro =>
      'Burghood works out who fixes what from public open data, bundled in the app so it works offline.';

  @override
  String get dataSourcesDirectory =>
      'Office contacts were collected from each office\'s official website and are re-checked regularly. Tell us about a wrong office from any report.';

  @override
  String get dataSourcesMaps =>
      'Maps © Google. Addresses come from your phone\'s built-in geocoder.';

  @override
  String get dataSourcesDisclaimer =>
      'Road ownership data can be out of date. Burghood is not affiliated with Allegheny County, PennDOT or any municipality.';

  @override
  String get safetyCompact => 'Is anyone in danger right now?';

  @override
  String get safetyCompactYes => 'Yes';

  @override
  String get utilityWires =>
      'Downed or sparking wires? After 911, tell your electric company:';

  @override
  String get utilityGas =>
      'Smell gas? Leave the area first, then call 911 and your gas company:';

  @override
  String callUtility(String name, String phone) {
    return 'Call $name: $phone';
  }

  @override
  String get recheckTitle => 'Is anyone in danger?';

  @override
  String get recheckBody =>
      'You described an urgent problem that might be dangerous, like live wires, gas or someone trapped. If anyone could get hurt, call for help now instead of filing a report.';

  @override
  String get recheckYes => 'Yes, get help';

  @override
  String get recheckNo => 'No, continue';

  @override
  String get savedForLater =>
      'You\'re offline. Your report is saved and will send when you\'re back online.';

  @override
  String get outboxWaiting =>
      'Waiting to send. It goes out when you\'re back online.';

  @override
  String get outboxLimit =>
      'Today\'s report limit is used up. It sends tomorrow.';

  @override
  String get outboxFailed =>
      'Couldn\'t send this report. Try again, or cancel it.';

  @override
  String get outboxDuplicate =>
      'Someone reported this nearby while you were offline. Add your voice instead?';

  @override
  String get sendAnyway => 'It\'s different, send it';

  @override
  String get retryNow => 'Try again now';

  @override
  String get stillOffline => 'Still can\'t reach Burghood. We\'ll keep trying.';

  @override
  String get cancelReport => 'Cancel report';

  @override
  String get unsentReportsTitle => 'Some reports haven\'t been sent';

  @override
  String unsentReportsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count reports are still waiting to send. Signing out deletes them from this phone.',
      one:
          '1 report is still waiting to send. Signing out deletes it from this phone.',
    );
    return '$_temp0';
  }

  @override
  String get pushRationaleTitle => 'Hear when it gets fixed';

  @override
  String get pushRationaleBody =>
      'We\'ll let you know when a report you made or said \"Me too\" to is sent to the office, fixed or reopened, and about urgent problems near places you save. At most 5 a day, and you choose which ones in Profile.';

  @override
  String get pushRationaleAllow => 'Turn on notifications';

  @override
  String get notNow => 'Not now';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Updates, saved places and quiet hours';

  @override
  String get pushOffBody => 'Notifications are off on this phone.';

  @override
  String get pushBlocked =>
      'Notifications are blocked. Turn them on for Burghood in your phone\'s settings.';

  @override
  String get notifyStatus => 'Updates on my reports';

  @override
  String get notifyStatusBody =>
      'Reports you made or said \"Me too\" to: sent to the office, fixed or reopened.';

  @override
  String get notifyNearby => 'Urgent problems near my places';

  @override
  String get notifyNearbyBody =>
      'New urgent reports within the alert radius of your saved places.';

  @override
  String get savedPlacesTitle => 'Saved places';

  @override
  String get savedPlacesBody => 'Home, school, work or anywhere you care about';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get quietHoursBody => 'No notifications during these hours.';

  @override
  String get quietFrom => 'From';

  @override
  String get quietUntil => 'Until';

  @override
  String get notifyLimitNote => 'You\'ll get at most 5 notifications a day.';

  @override
  String get sendTestNotification => 'Send a test notification';

  @override
  String get testSent => 'Test sent. It should arrive in a few seconds.';

  @override
  String get savedPlacesIntro =>
      'Save up to 3 places. We\'ll tell you about new urgent problems nearby. We store only the point on the map, not an address.';

  @override
  String get noSavedPlaces => 'No saved places yet.';

  @override
  String get addPlace => 'Add place';

  @override
  String get editPlace => 'Edit place';

  @override
  String alertRadius(String miles) {
    return 'Alert radius: $miles mi';
  }

  @override
  String placesFull(int count) {
    return 'You\'ve saved $count places, the most you can.';
  }

  @override
  String get placeHome => 'Home';

  @override
  String get placeSchool => 'School';

  @override
  String get placeWork => 'Work';

  @override
  String get placeOther => 'Other';

  @override
  String get placeLabel => 'Name (optional)';

  @override
  String get placeMapSemantics => 'Map of the saved place. Tap to move it.';

  @override
  String get placeTapMap =>
      'Search, use your location, or tap the map to choose the spot.';

  @override
  String get placeChosen => 'Tap the map to move the spot.';

  @override
  String get savePlace => 'Save place';

  @override
  String get view => 'View';

  @override
  String get findSocietyTitle => 'Find your society';

  @override
  String get findSocietyHint => 'Your address or society name';

  @override
  String get search => 'Search';

  @override
  String get noSocietiesFound => 'No society found here yet.';

  @override
  String societiesNearAddress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count societies near this address',
      one: '1 society near this address',
    );
    return '$_temp0';
  }

  @override
  String homesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count homes',
      one: '1 home',
    );
    return '$_temp0';
  }

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get verified => 'Verified';

  @override
  String get requestToJoin => 'Request to join';

  @override
  String get requestSent => 'Request sent';

  @override
  String get requestSentBody =>
      'Request sent. The society admin will review it.';

  @override
  String get dontSeeYours => 'Don\'t see yours?';

  @override
  String get createSociety => 'Create a society';

  @override
  String get createSocietyBody =>
      'For presidents, board members or managers. We check your documents before the society goes live.';

  @override
  String get createSocietyNeeds =>
      'You\'ll need: a government photo ID, and proof of office (board resolution, election minutes or management agreement).';

  @override
  String get imTheAdmin => 'I\'m the admin, create it';

  @override
  String get notTheAdmin => 'Not the admin? Invite them';

  @override
  String inviteAdminMessage(String link) {
    return 'Our society could use Burghood for notices, documents and neighbors. Could you set it up as our admin? Get the app: $link';
  }

  @override
  String get haveInviteCode => 'Have an invite code?';

  @override
  String requestPendingTitle(String name) {
    return 'Request to join $name';
  }

  @override
  String get requestPendingBody => 'Waiting for the society admin.';

  @override
  String get withdraw => 'Withdraw';

  @override
  String joinSocietyTitle(String name) {
    return 'Join $name';
  }

  @override
  String get joinSocietyBody =>
      'Add your unit number so the admin knows you live there. They\'ll approve or decline your request.';

  @override
  String get unitNumber => 'Unit or house number';

  @override
  String get unitNumberHint => 'For example 4B or 1200';

  @override
  String get unitNumberOptional => 'Unit or house number (optional)';

  @override
  String get joinWithCodeTitle => 'Join with an invite code';

  @override
  String get joinWithCodeBody =>
      'Your society admin can give you an 8-character code. With it you join straight away.';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get inviteCodeInvalid =>
      'That code didn\'t work. Check it with your society admin.';

  @override
  String get join => 'Join';

  @override
  String get joinedSociety => 'You\'ve joined.';

  @override
  String get societySignInTitle => 'Sign in to find your society';

  @override
  String get societySignInBody =>
      'Societies are for neighbors with an account, so admins know who\'s asking to join.';

  @override
  String get claimTitle => 'Your society claim';

  @override
  String claimPendingTitle(String name) {
    return 'Checking $name';
  }

  @override
  String get claimPendingBody =>
      'We\'re reviewing your documents, usually within 2 working days.';

  @override
  String claimApprovedTitle(String name) {
    return '$name is live';
  }

  @override
  String get claimApprovedBody => 'You\'re its admin.';

  @override
  String claimRejectedTitle(String name) {
    return 'We couldn\'t verify $name';
  }

  @override
  String get claimRejectedBody => 'See why, and send it again.';

  @override
  String get claimStepSubmitted => 'Submitted';

  @override
  String get claimStepReview => 'Being reviewed';

  @override
  String get claimStepReviewBody =>
      'Burghood staff check your photo ID and proof of office.';

  @override
  String get claimStepDecision => 'Decision';

  @override
  String get claimStepApproved => 'Approved: your society is live';

  @override
  String get claimStepRejected => 'Not approved';

  @override
  String get claimReason => 'Reason';

  @override
  String get resubmit => 'Fix and send again';

  @override
  String get openSociety => 'Open my society';

  @override
  String get claimFilesNote =>
      'Your ID and proof of office are seen only by Burghood staff and are deleted 30 days after the decision.';

  @override
  String get claimSubmitted => 'Sent for review.';

  @override
  String get createSocietyIntro =>
      'Tell us about your society and show that you run it. Burghood staff check every claim before the society appears in search.';

  @override
  String get sectionSociety => 'Society';

  @override
  String get societyName => 'Society name';

  @override
  String get societyAddress => 'Address';

  @override
  String get societyAddressHelp =>
      'Street address of the society or its main building';

  @override
  String get checkAddress => 'Check address';

  @override
  String get outsideCountySociety =>
      'That address is outside Allegheny County. Burghood only covers Allegheny County for now.';

  @override
  String get numberOfHomes => 'Number of homes';

  @override
  String get numberOfHomesInvalid => 'Enter a number from 2 to 5000.';

  @override
  String get societyDuplicateTitle => 'A society may already exist here';

  @override
  String societyDuplicateActive(String name, String distance) {
    return '$name is on Burghood, $distance away.';
  }

  @override
  String societyDuplicatePending(String name, String distance) {
    return 'A claim for $name, $distance away, is being reviewed.';
  }

  @override
  String get societyDuplicateBody =>
      'If it\'s yours, ask to join it instead. Only claim a new society if it\'s a different one.';

  @override
  String get sectionYou => 'You';

  @override
  String get yourFullName => 'Your full name, as on your ID';

  @override
  String get yourPosition => 'Your position';

  @override
  String get positionPresident => 'President';

  @override
  String get positionSecretary => 'Secretary';

  @override
  String get positionBoardMember => 'Board member';

  @override
  String get positionManager => 'Manager';

  @override
  String get sectionHoa => 'HOA management company';

  @override
  String get hoaHelp =>
      'Members get one button that opens your management company\'s account page. Burghood stores the link only, never balances or payments.';

  @override
  String get hoaCompany => 'Company name';

  @override
  String get hoaWebsite => 'Website';

  @override
  String get hoaAccountLink => 'Account section link';

  @override
  String get hoaAccountLinkHelp =>
      'The page where residents sign in to their HOA account. Your management company can give you this link.';

  @override
  String get invalidLink => 'Enter a web address starting with https://';

  @override
  String get sectionDocuments => 'Your documents';

  @override
  String get verificationRequirements =>
      'We need two documents.\n1. A government photo ID: a driver\'s license, state ID or passport, with your name and photo easy to read.\n2. Proof of office that names you and the society: a board resolution, election minutes, or a management agreement.\nPhotos or PDFs, up to 5 MB each. The name on both must match.';

  @override
  String get draftWording => 'Draft wording';

  @override
  String get photoId => 'Government photo ID';

  @override
  String get photoIdHelp => 'Driver\'s license, state ID or passport';

  @override
  String get proofOfOffice => 'Proof of office';

  @override
  String get proofOfOfficeHelp =>
      'Board resolution, election minutes or management agreement naming you';

  @override
  String get chooseFile => 'Files';

  @override
  String get choosePhoto => 'Photos';

  @override
  String fileTooLarge(int mb) {
    return 'That file is too large. The limit is $mb MB.';
  }

  @override
  String get claimConfirm =>
      'I hold this position in the society, and these documents are genuine.';

  @override
  String get howWeUseDocuments => 'How we use your documents';

  @override
  String get submitForReview => 'Send for review';

  @override
  String get reviewTarget => 'We aim to decide within 2 working days.';

  @override
  String get requiredField => 'Required';

  @override
  String get switchSociety => 'Switch society';

  @override
  String youAre(String role) {
    return 'You\'re $role';
  }

  @override
  String get roleMember => 'a member';

  @override
  String get roleCommittee => 'on the committee';

  @override
  String get roleAdmin => 'an admin';

  @override
  String get joinAnotherSociety => 'Join or create another society';

  @override
  String get manage => 'Manage';

  @override
  String get hoaAccount => 'HOA account';

  @override
  String get tabNotices => 'Notices';

  @override
  String get tabDocs => 'Docs';

  @override
  String get tabMembers => 'Members';

  @override
  String get noNotices => 'No notices yet.';

  @override
  String get noDocuments => 'No documents yet.';

  @override
  String get newNotice => 'New notice';

  @override
  String get pinnedNotice => '📌 Notice';

  @override
  String pinnedNoticeFrom(String name) {
    return '📌 Notice · from $name';
  }

  @override
  String postedAgo(String when) {
    return 'Posted $when';
  }

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get hasAttachment => 'Attachment';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String hoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String daysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get uploadDocument => 'Upload document';

  @override
  String deleteDocumentTitle(String title) {
    return 'Delete $title?';
  }

  @override
  String get docBylaws => 'Bylaws';

  @override
  String get docMinutes => 'Minutes';

  @override
  String get docBudget => 'Budget';

  @override
  String get docRules => 'Rules';

  @override
  String get docOther => 'Other';

  @override
  String get neighbor => 'Neighbor';

  @override
  String youName(String name) {
    return '$name (you)';
  }

  @override
  String unitLabel(String unit) {
    return 'Unit $unit';
  }

  @override
  String get memberActions => 'Member options';

  @override
  String get makeMember => 'Make member';

  @override
  String get makeCommittee => 'Add to committee';

  @override
  String get makeAdmin => 'Make co-admin';

  @override
  String get removeMember => 'Remove';

  @override
  String get removeMemberTitle => 'Remove this member?';

  @override
  String get removeMemberBody =>
      'They lose access to notices and documents. They can ask to join again.';

  @override
  String manageSociety(String name) {
    return 'Manage $name';
  }

  @override
  String get adminsOnly => 'Only society admins can see this.';

  @override
  String joinRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Join requests ($count)',
      zero: 'Join requests',
    );
    return '$_temp0';
  }

  @override
  String get noJoinRequests => 'No requests waiting.';

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get inviteCodeBody =>
      'Anyone with this code joins straight away, without your approval. Share it with residents only.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get newCode => 'New code';

  @override
  String get newCodeTitle => 'Make a new invite code?';

  @override
  String get newCodeBody =>
      'The current code will stop working. People who already joined stay in.';

  @override
  String inviteMembersMessage(String society, String code, String link) {
    return 'Join $society on Burghood for notices and documents. Get the app at $link and enter invite code $code.';
  }

  @override
  String get shareWithMembers => 'Share with members';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get noticeGone => 'This notice was removed.';

  @override
  String get noticeTitle => 'Title';

  @override
  String get noticeBody => 'Message';

  @override
  String get pinNotice => 'Pin to the top';

  @override
  String get pinNoticeBody => 'Pinned notices show first until they expire.';

  @override
  String get noExpiry => 'No expiry date';

  @override
  String get addExpiry => 'Add';

  @override
  String get removeExpiry => 'Remove expiry date';

  @override
  String get noAttachment => 'No attachment';

  @override
  String get attachFile => 'Attach';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get postNotice => 'Post notice';

  @override
  String get noticePushNote => 'Every member gets a notification.';

  @override
  String get noticePosted => 'Notice posted.';

  @override
  String get choosePdf => 'Choose a PDF';

  @override
  String get documentTitle => 'Title';

  @override
  String get documentCategory => 'Category';

  @override
  String get upload => 'Upload';

  @override
  String get documentUploaded => 'Document uploaded.';

  @override
  String get documentsMembersOnly =>
      'Only approved members can open documents.';

  @override
  String get notifyNotices => 'Notices from admins';

  @override
  String get notifyNoticesBody =>
      'Announcements from your society\'s admins and committee';
}
