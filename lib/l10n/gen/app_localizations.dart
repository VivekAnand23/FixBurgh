import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FixBurgh'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get navMyReports;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notForEmergencies.
  ///
  /// In en, this message translates to:
  /// **'FixBurgh is not monitored for emergencies. Call 911.'**
  String get notForEmergencies;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Spot it. Snap it. FixBurgh.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Report potholes, landslides, dark streetlights and more anywhere in Allegheny County. We tell you exactly who fixes it.'**
  String get welcomeBody;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'No ads. We never sell your data. Your name is never shown on the map.'**
  String get welcomePrivacy;

  /// No description provided for @welcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeContinue;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get ageTitle;

  /// No description provided for @ageBody.
  ///
  /// In en, this message translates to:
  /// **'We ask everyone this question.'**
  String get ageBody;

  /// No description provided for @ageMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get ageMonth;

  /// No description provided for @ageYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get ageYear;

  /// No description provided for @ageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get ageContinue;

  /// No description provided for @ageBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sorry, you can\'t use FixBurgh yet'**
  String get ageBlockedTitle;

  /// No description provided for @ageBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask a parent or guardian to report the problem for you. Nothing you entered was saved.'**
  String get ageBlockedBody;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Community map'**
  String get mapTitle;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportTitle;

  /// No description provided for @myReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReportsTitle;

  /// No description provided for @myReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t reported anything yet.'**
  String get myReportsEmpty;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileGuest.
  ///
  /// In en, this message translates to:
  /// **'You\'re using FixBurgh as a guest'**
  String get profileGuest;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your reports on every device and get updates.'**
  String get profileGuestBody;

  /// No description provided for @profileSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {who}'**
  String profileSignedInAs(String who);

  /// No description provided for @profileEmailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox to verify your email.'**
  String get profileEmailUnverified;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account. This can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @dataSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get dataSources;

  /// No description provided for @dataSourcesBody.
  ///
  /// In en, this message translates to:
  /// **'Municipal boundaries and County roads: Allegheny County GIS via the Western Pennsylvania Regional Data Center. State roads: PennDOT open data.'**
  String get dataSourcesBody;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Your guest reports stay with you.'**
  String get signInBody;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orUseEmail.
  ///
  /// In en, this message translates to:
  /// **'or use email'**
  String get orUseEmail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'I need a new account'**
  String get needAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}.'**
  String resetEmailSent(String email);

  /// No description provided for @verifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Account created. We sent a verification link to {email}.'**
  String verifyEmailSent(String email);

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That email and password don\'t match.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'That email already has an account. Sign in instead.'**
  String get errorEmailInUse;

  /// No description provided for @errorCredentialInUse.
  ///
  /// In en, this message translates to:
  /// **'That account already exists, so we signed you in to it.'**
  String get errorCredentialInUse;

  /// No description provided for @errorRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again and then retry.'**
  String get errorRequiresRecentLogin;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your signal and try again.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editSection.
  ///
  /// In en, this message translates to:
  /// **'Edit {section}'**
  String editSection(String section);

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'First, is anyone in danger right now?'**
  String get safetyTitle;

  /// No description provided for @dangerWires.
  ///
  /// In en, this message translates to:
  /// **'Downed or sparking power lines'**
  String get dangerWires;

  /// No description provided for @dangerGasFire.
  ///
  /// In en, this message translates to:
  /// **'Gas smell, smoke or fire'**
  String get dangerGasFire;

  /// No description provided for @dangerCrash.
  ///
  /// In en, this message translates to:
  /// **'A crash or a car stuck in traffic'**
  String get dangerCrash;

  /// No description provided for @dangerTrapped.
  ///
  /// In en, this message translates to:
  /// **'Someone hurt or trapped'**
  String get dangerTrapped;

  /// No description provided for @dangerWater.
  ///
  /// In en, this message translates to:
  /// **'Water over a road deeper than a car\'s wheels'**
  String get dangerWater;

  /// No description provided for @safetyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, someone could get hurt'**
  String get safetyYes;

  /// No description provided for @safetyNo.
  ///
  /// In en, this message translates to:
  /// **'No, continue to report'**
  String get safetyNo;

  /// No description provided for @safetyPhotoTip.
  ///
  /// In en, this message translates to:
  /// **'Only take photos when it\'s safe. Never stop in traffic.'**
  String get safetyPhotoTip;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Call 911 now'**
  String get emergencyTitle;

  /// No description provided for @emergencyBody.
  ///
  /// In en, this message translates to:
  /// **'This needs emergency responders. FixBurgh reports are not monitored for emergencies. Stay back from wires and water.'**
  String get emergencyBody;

  /// No description provided for @call911.
  ///
  /// In en, this message translates to:
  /// **'Call 911'**
  String get call911;

  /// No description provided for @notAnEmergency.
  ///
  /// In en, this message translates to:
  /// **'It\'s not an emergency'**
  String get notAnEmergency;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get photoTitle;

  /// No description provided for @photoBody.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} photos. Try to show the whole problem.'**
  String photoBody(int count);

  /// No description provided for @photoNumber.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumber(int number);

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get chooseFromLibrary;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is it?'**
  String get locationTitle;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Search an address, or zoom in and drag the pin to the exact spot.'**
  String get locationHint;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off, so we started downtown. Move the pin to the spot.'**
  String get locationDenied;

  /// No description provided for @mapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Map. Drag the pin to mark the problem.'**
  String get mapSemantics;

  /// No description provided for @inMunicipality.
  ///
  /// In en, this message translates to:
  /// **'In {name}'**
  String inMunicipality(String name);

  /// No description provided for @outsideCounty.
  ///
  /// In en, this message translates to:
  /// **'This spot is outside Allegheny County. FixBurgh only covers Allegheny County for now.'**
  String get outsideCounty;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @whatIsIt.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get whatIsIt;

  /// No description provided for @howBad.
  ///
  /// In en, this message translates to:
  /// **'How bad is it?'**
  String get howBad;

  /// No description provided for @describeIt.
  ///
  /// In en, this message translates to:
  /// **'Describe it (optional)'**
  String get describeIt;

  /// No description provided for @describeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deep pothole in the right lane'**
  String get describeHint;

  /// No description provided for @catPothole.
  ///
  /// In en, this message translates to:
  /// **'Pothole'**
  String get catPothole;

  /// No description provided for @catLandslide.
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get catLandslide;

  /// No description provided for @catFlooding.
  ///
  /// In en, this message translates to:
  /// **'Flooding or drain'**
  String get catFlooding;

  /// No description provided for @catStreetlight.
  ///
  /// In en, this message translates to:
  /// **'Streetlight'**
  String get catStreetlight;

  /// No description provided for @catDumping.
  ///
  /// In en, this message translates to:
  /// **'Illegal dumping'**
  String get catDumping;

  /// No description provided for @catFallenTree.
  ///
  /// In en, this message translates to:
  /// **'Fallen tree'**
  String get catFallenTree;

  /// No description provided for @catSidewalk.
  ///
  /// In en, this message translates to:
  /// **'Sidewalk'**
  String get catSidewalk;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @sevLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get sevLow;

  /// No description provided for @sevMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sevMedium;

  /// No description provided for @sevUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get sevUrgent;

  /// No description provided for @statusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get statusReported;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to agency'**
  String get statusSent;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check and send'**
  String get reviewTitle;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @reviewPublicNote.
  ///
  /// In en, this message translates to:
  /// **'Your report goes on the community map so neighbors can say \"Me too\". Your name is never shown.'**
  String get reviewPublicNote;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get submitting;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thanks for looking out for your neighborhood.'**
  String get reportSubmitted;

  /// No description provided for @submitFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your report. Check your connection and try again.'**
  String get submitFailed;

  /// No description provided for @markFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark fixed'**
  String get markFixed;

  /// No description provided for @mapReportsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Map showing {count} open reports'**
  String mapReportsSemantics(int count);

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get locating;

  /// No description provided for @improvingAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Improving accuracy... now within {meters} m'**
  String improvingAccuracy(int meters);

  /// No description provided for @accurateTo.
  ///
  /// In en, this message translates to:
  /// **'GPS accurate to about {meters} m. Drag the pin if it\'s off.'**
  String accurateTo(int meters);

  /// No description provided for @pinPlacedByHand.
  ///
  /// In en, this message translates to:
  /// **'Pin placed by hand.'**
  String get pinPlacedByHand;

  /// No description provided for @approximateOnly.
  ///
  /// In en, this message translates to:
  /// **'Precise Location is off, so GPS is approximate. Turn it on in Settings or drag the pin to the exact spot.'**
  String get approximateOnly;

  /// No description provided for @showSatellite.
  ///
  /// In en, this message translates to:
  /// **'Show satellite view'**
  String get showSatellite;

  /// No description provided for @showMap.
  ///
  /// In en, this message translates to:
  /// **'Show map view'**
  String get showMap;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address'**
  String get searchAddress;

  /// No description provided for @searchAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 414 Grant St, Pittsburgh'**
  String get searchAddressHint;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that address in Allegheny County. Try adding the street number or town.'**
  String get addressNotFound;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @pinFromSearch.
  ///
  /// In en, this message translates to:
  /// **'Pin placed at the address you searched. Drag it to the exact spot.'**
  String get pinFromSearch;

  /// No description provided for @whoFixesThis.
  ///
  /// In en, this message translates to:
  /// **'Who fixes this?'**
  String get whoFixesThis;

  /// No description provided for @routingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the responsible office for this spot.'**
  String get routingUnavailable;

  /// No description provided for @thisRoad.
  ///
  /// In en, this message translates to:
  /// **'This road'**
  String get thisRoad;

  /// No description provided for @whyStateRoad.
  ///
  /// In en, this message translates to:
  /// **'{road} is a state road, so PennDOT maintains it, even inside a city or borough.'**
  String whyStateRoad(String road);

  /// No description provided for @whyTurnpike.
  ///
  /// In en, this message translates to:
  /// **'{road} is part of the Pennsylvania Turnpike.'**
  String whyTurnpike(String road);

  /// No description provided for @whyCountyRoad.
  ///
  /// In en, this message translates to:
  /// **'{road} is maintained by Allegheny County, not the municipality.'**
  String whyCountyRoad(String road);

  /// No description provided for @whyLocalRoad.
  ///
  /// In en, this message translates to:
  /// **'This is a local street, so {municipality} handles it.'**
  String whyLocalRoad(String municipality);

  /// No description provided for @whyMunicipalService.
  ///
  /// In en, this message translates to:
  /// **'{municipality} handles this kind of problem in its area.'**
  String whyMunicipalService(String municipality);

  /// No description provided for @badgeStateRoad.
  ///
  /// In en, this message translates to:
  /// **'State road'**
  String get badgeStateRoad;

  /// No description provided for @badgeStateRoute.
  ///
  /// In en, this message translates to:
  /// **'State road · Route {route}'**
  String badgeStateRoute(String route);

  /// No description provided for @badgeTurnpike.
  ///
  /// In en, this message translates to:
  /// **'PA Turnpike'**
  String get badgeTurnpike;

  /// No description provided for @badgeCountyRoad.
  ///
  /// In en, this message translates to:
  /// **'County road'**
  String get badgeCountyRoad;

  /// No description provided for @badgeLocalRoad.
  ///
  /// In en, this message translates to:
  /// **'Local street'**
  String get badgeLocalRoad;

  /// No description provided for @notTheirs.
  ///
  /// In en, this message translates to:
  /// **'If they say it isn\'t theirs, contact {name}.'**
  String notTheirs(String name);

  /// No description provided for @callOffice.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callOffice;

  /// No description provided for @emailOffice.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailOffice;

  /// No description provided for @openWebForm.
  ///
  /// In en, this message translates to:
  /// **'Web form'**
  String get openWebForm;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @copyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get copyDetails;

  /// No description provided for @detailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Report details copied. Paste them into the form or email.'**
  String get detailsCopied;

  /// No description provided for @summaryIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get summaryIssue;

  /// No description provided for @summaryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get summaryLocation;

  /// No description provided for @summaryCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get summaryCoordinates;

  /// No description provided for @summaryMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get summaryMap;

  /// No description provided for @summaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get summaryDescription;

  /// No description provided for @summaryFooter.
  ///
  /// In en, this message translates to:
  /// **'Reported with FixBurgh, a free community app for Allegheny County.'**
  String get summaryFooter;

  /// No description provided for @emailSubject.
  ///
  /// In en, this message translates to:
  /// **'[FixBurgh] {category} ({severity}) at {place}'**
  String emailSubject(String category, String severity, String place);

  /// No description provided for @nowTellThem.
  ///
  /// In en, this message translates to:
  /// **'Now tell them'**
  String get nowTellThem;

  /// No description provided for @nowTellThemBody.
  ///
  /// In en, this message translates to:
  /// **'Your report is on the map. Contacting the office is what gets it fixed. We copy the details for you.'**
  String get nowTellThemBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @contactOffice.
  ///
  /// In en, this message translates to:
  /// **'Contact office'**
  String get contactOffice;

  /// No description provided for @reportGone.
  ///
  /// In en, this message translates to:
  /// **'This report was removed.'**
  String get reportGone;

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo of the {category}'**
  String photoOf(String category);

  /// No description provided for @routedTo.
  ///
  /// In en, this message translates to:
  /// **'Responsible office: {name}'**
  String routedTo(String name);

  /// No description provided for @meToo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Me too} other{Me too ({count})}}'**
  String meToo(int count);

  /// No description provided for @meTooDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You said me too} other{You and {count} neighbors said me too}}'**
  String meTooDone(int count);

  /// No description provided for @meTooCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ✋'**
  String meTooCount(int count);

  /// No description provided for @meTooShort.
  ///
  /// In en, this message translates to:
  /// **'Me too'**
  String get meTooShort;

  /// No description provided for @meTooAdded.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your \"Me too\" was added to the existing report.'**
  String get meTooAdded;

  /// No description provided for @looksFixed.
  ///
  /// In en, this message translates to:
  /// **'Looks fixed ({count} of {needed})'**
  String looksFixed(int count, int needed);

  /// No description provided for @alreadyFixed.
  ///
  /// In en, this message translates to:
  /// **'This was marked fixed.'**
  String get alreadyFixed;

  /// No description provided for @yourReportStats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This is your report.} =1{Your report. 1 neighbor said me too.} other{Your report. {count} neighbors said me too.}}'**
  String yourReportStats(int count);

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Not fixed? Reopen'**
  String get reopen;

  /// No description provided for @flagReport.
  ///
  /// In en, this message translates to:
  /// **'Report a problem with this'**
  String get flagReport;

  /// No description provided for @flagTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get flagTitle;

  /// No description provided for @flagWrongOffice.
  ///
  /// In en, this message translates to:
  /// **'Wrong office'**
  String get flagWrongOffice;

  /// No description provided for @flagWrongLocation.
  ///
  /// In en, this message translates to:
  /// **'Wrong location'**
  String get flagWrongLocation;

  /// No description provided for @flagWrongCategory.
  ///
  /// In en, this message translates to:
  /// **'Wrong category'**
  String get flagWrongCategory;

  /// No description provided for @flagSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or fake'**
  String get flagSpam;

  /// No description provided for @flagOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive'**
  String get flagOffensive;

  /// No description provided for @flagPrivate.
  ///
  /// In en, this message translates to:
  /// **'Shows private information'**
  String get flagPrivate;

  /// No description provided for @flagThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We\'ll review it.'**
  String get flagThanks;

  /// No description provided for @deleteReport.
  ///
  /// In en, this message translates to:
  /// **'Delete report'**
  String get deleteReport;

  /// No description provided for @deleteReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this report?'**
  String get deleteReportTitle;

  /// No description provided for @deleteReportBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from the map, along with its photos.'**
  String get deleteReportBody;

  /// No description provided for @showFixed.
  ///
  /// In en, this message translates to:
  /// **'Show fixed'**
  String get showFixed;

  /// No description provided for @showListView.
  ///
  /// In en, this message translates to:
  /// **'Show list'**
  String get showListView;

  /// No description provided for @showMapView.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get showMapView;

  /// No description provided for @noReportsMatch.
  ///
  /// In en, this message translates to:
  /// **'No reports match these filters.'**
  String get noReportsMatch;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Already reported?'**
  String get duplicateTitle;

  /// No description provided for @duplicateBody.
  ///
  /// In en, this message translates to:
  /// **'{category} reported {meters} m away {days, plural, =0{today} =1{yesterday} other{{days} days ago}}{upvotes, plural, =0{.} =1{, and 1 neighbor said me too.} other{, and {upvotes} neighbors said me too.}} Is it the same problem?'**
  String duplicateBody(String category, int meters, int days, int upvotes);

  /// No description provided for @thisIsDifferent.
  ///
  /// In en, this message translates to:
  /// **'It\'s different'**
  String get thisIsDifferent;

  /// No description provided for @guestLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent {count} reports today. Sign in under Profile to send more and get updates.'**
  String guestLimitReached(int count);

  /// No description provided for @userLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit of {count} reports. Thanks for helping! You can report more tomorrow.'**
  String userLimitReached(int count);

  /// No description provided for @blockReporter.
  ///
  /// In en, this message translates to:
  /// **'Hide reports from this person'**
  String get blockReporter;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see reports from this person.'**
  String get blocked;

  /// No description provided for @blockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person hidden} other{{count} people hidden}}'**
  String blockedCount(int count);

  /// No description provided for @unblockAll.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get unblockAll;

  /// No description provided for @resumeDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish your report?'**
  String get resumeDraftTitle;

  /// No description provided for @resumeDraftBody.
  ///
  /// In en, this message translates to:
  /// **'You started a report earlier but didn\'t send it.'**
  String get resumeDraftBody;

  /// No description provided for @continueDraft.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueDraft;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
