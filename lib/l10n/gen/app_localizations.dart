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
  /// **'Burghood'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSociety.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get navSociety;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notForEmergencies.
  ///
  /// In en, this message translates to:
  /// **'Burghood is not monitored for emergencies. Call 911.'**
  String get notForEmergencies;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Spot it. Snap it. Get it fixed.'**
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
  /// **'Sorry, you can\'t use Burghood yet'**
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

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityCityReports.
  ///
  /// In en, this message translates to:
  /// **'City reports'**
  String get activityCityReports;

  /// No description provided for @societyTitle.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get societyTitle;

  /// No description provided for @societyComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Join your building or neighborhood society to read notices, find documents and talk with neighbors.'**
  String get societyComingSoonBody;

  /// No description provided for @societySignInToJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join a society'**
  String get societySignInToJoin;

  /// No description provided for @societySignedInNote.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in. We\'ll let you know when societies open.'**
  String get societySignedInNote;

  /// No description provided for @societyFindBody.
  ///
  /// In en, this message translates to:
  /// **'Find your society by address or name.'**
  String get societyFindBody;

  /// No description provided for @accountGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get accountGateTitle;

  /// No description provided for @accountGateBody.
  ///
  /// In en, this message translates to:
  /// **'This needs an account. When you sign in, anything you reported as a guest moves to your account.'**
  String get accountGateBody;

  /// No description provided for @accountGateSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountGateSignIn;

  /// No description provided for @accountGateNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get accountGateNotNow;

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
  /// **'You\'re using Burghood as a guest'**
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
  /// **'This permanently deletes your account, your votes and your sign-in. This can\'t be undone.'**
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
  /// **'This needs emergency responders. Burghood reports are not monitored for emergencies. Stay back from wires and water.'**
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
  /// **'This spot is outside Allegheny County. Burghood only covers Allegheny County for now.'**
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
  /// **'Reported with Burghood, a free community app for Allegheny County.'**
  String get summaryFooter;

  /// No description provided for @emailSubject.
  ///
  /// In en, this message translates to:
  /// **'[Burghood] {category} ({severity}) at {place}'**
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

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @errorProviderDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method isn\'t available yet. Try another one.'**
  String get errorProviderDisabled;

  /// No description provided for @markFixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as fixed'**
  String get markFixedTitle;

  /// No description provided for @markFixedBody.
  ///
  /// In en, this message translates to:
  /// **'Add an \"after\" photo so neighbors can see the fix. It\'s optional.'**
  String get markFixedBody;

  /// No description provided for @afterPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take an \"after\" photo'**
  String get afterPhotoCamera;

  /// No description provided for @afterPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose an \"after\" photo'**
  String get afterPhotoGallery;

  /// No description provided for @markFixedNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Mark fixed without a photo'**
  String get markFixedNoPhoto;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get uploadingPhoto;

  /// No description provided for @markedFixed.
  ///
  /// In en, this message translates to:
  /// **'Marked as fixed. Thanks for following up!'**
  String get markedFixed;

  /// No description provided for @afterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo after the fix'**
  String get afterPhoto;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @eventReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get eventReported;

  /// No description provided for @eventSentCall.
  ///
  /// In en, this message translates to:
  /// **'Sent to agency by phone'**
  String get eventSentCall;

  /// No description provided for @eventSentEmail.
  ///
  /// In en, this message translates to:
  /// **'Sent to agency by email'**
  String get eventSentEmail;

  /// No description provided for @eventSentWeb.
  ///
  /// In en, this message translates to:
  /// **'Sent to agency by web form'**
  String get eventSentWeb;

  /// No description provided for @eventResolvedReporter.
  ///
  /// In en, this message translates to:
  /// **'Marked fixed by the reporter'**
  String get eventResolvedReporter;

  /// No description provided for @eventResolvedCommunity.
  ///
  /// In en, this message translates to:
  /// **'Confirmed fixed by neighbors'**
  String get eventResolvedCommunity;

  /// No description provided for @eventReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened: not fixed after all'**
  String get eventReopened;

  /// No description provided for @voteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s {count} \"Me too\" votes. Try again tomorrow.'**
  String voteLimitReached(int count);

  /// No description provided for @verifyToVote.
  ///
  /// In en, this message translates to:
  /// **'Verify your email first. Check your inbox for the link, then try again.'**
  String get verifyToVote;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String tabAll(int count);

  /// No description provided for @tabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open ({count})'**
  String tabOpen(int count);

  /// No description provided for @tabFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed ({count})'**
  String tabFixed(int count);

  /// No description provided for @noReportsInTab.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noReportsInTab;

  /// No description provided for @legendTitle.
  ///
  /// In en, this message translates to:
  /// **'Map legend'**
  String get legendTitle;

  /// No description provided for @legendUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent (red badge)'**
  String get legendUrgent;

  /// No description provided for @legendFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed (faded)'**
  String get legendFixed;

  /// No description provided for @legendCluster.
  ///
  /// In en, this message translates to:
  /// **'A number means several reports close together. Zoom in to see them.'**
  String get legendCluster;

  /// No description provided for @searchMap.
  ///
  /// In en, this message translates to:
  /// **'Search an address or place'**
  String get searchMap;

  /// No description provided for @timeRangeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose how far back to show reports'**
  String get timeRangeTooltip;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get rangeMonth;

  /// No description provided for @rangeQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get rangeQuarter;

  /// No description provided for @rangeYear.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get rangeYear;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rangeAll;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deletingAccount;

  /// No description provided for @confirmPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get confirmPasswordTitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @methodGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get methodGoogle;

  /// No description provided for @methodApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get methodApple;

  /// No description provided for @methodEmail.
  ///
  /// In en, this message translates to:
  /// **'email and password'**
  String get methodEmail;

  /// No description provided for @signedInWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with {method}'**
  String signedInWith(String method);

  /// No description provided for @reportCounts.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =0{No reports yet} =1{1 report} other{{total} reports}} · {open} open · {fixed} fixed'**
  String reportCounts(int total, int open, int fixed);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @textSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeTitle;

  /// No description provided for @textSizeBody.
  ///
  /// In en, this message translates to:
  /// **'Adds to the text size set on your phone.'**
  String get textSizeBody;

  /// No description provided for @textSizeSystem.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textSizeSystem;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textSizeLarger;

  /// No description provided for @textSizePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview: a pothole on Grant Street was reported 2 days ago.'**
  String get textSizePreview;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @dataSourcesShort.
  ///
  /// In en, this message translates to:
  /// **'Maps, road ownership and office contacts'**
  String get dataSourcesShort;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @deleteAccountReportsQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should happen to your reports?'**
  String get deleteAccountReportsQuestion;

  /// No description provided for @deleteKeepReports.
  ///
  /// In en, this message translates to:
  /// **'Keep them on the map, anonymously'**
  String get deleteKeepReports;

  /// No description provided for @deleteKeepReportsBody.
  ///
  /// In en, this message translates to:
  /// **'The problems still exist. Nobody will be able to link them to you.'**
  String get deleteKeepReportsBody;

  /// No description provided for @deleteRemoveReports.
  ///
  /// In en, this message translates to:
  /// **'Delete them and their photos'**
  String get deleteRemoveReports;

  /// No description provided for @deleteRemoveReportsBody.
  ///
  /// In en, this message translates to:
  /// **'They disappear from the map for everyone.'**
  String get deleteRemoveReportsBody;

  /// No description provided for @dataSourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'Burghood works out who fixes what from public open data, bundled in the app so it works offline.'**
  String get dataSourcesIntro;

  /// No description provided for @dataSourcesDirectory.
  ///
  /// In en, this message translates to:
  /// **'Office contacts were collected from each office\'s official website and are re-checked regularly. Tell us about a wrong office from any report.'**
  String get dataSourcesDirectory;

  /// No description provided for @dataSourcesMaps.
  ///
  /// In en, this message translates to:
  /// **'Maps © Google. Addresses come from your phone\'s built-in geocoder.'**
  String get dataSourcesMaps;

  /// No description provided for @dataSourcesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Road ownership data can be out of date. Burghood is not affiliated with Allegheny County, PennDOT or any municipality.'**
  String get dataSourcesDisclaimer;

  /// No description provided for @safetyCompact.
  ///
  /// In en, this message translates to:
  /// **'Is anyone in danger right now?'**
  String get safetyCompact;

  /// No description provided for @safetyCompactYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get safetyCompactYes;

  /// No description provided for @utilityWires.
  ///
  /// In en, this message translates to:
  /// **'Downed or sparking wires? After 911, tell your electric company:'**
  String get utilityWires;

  /// No description provided for @utilityGas.
  ///
  /// In en, this message translates to:
  /// **'Smell gas? Leave the area first, then call 911 and your gas company:'**
  String get utilityGas;

  /// No description provided for @callUtility.
  ///
  /// In en, this message translates to:
  /// **'Call {name}: {phone}'**
  String callUtility(String name, String phone);

  /// No description provided for @recheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Is anyone in danger?'**
  String get recheckTitle;

  /// No description provided for @recheckBody.
  ///
  /// In en, this message translates to:
  /// **'You described an urgent problem that might be dangerous, like live wires, gas or someone trapped. If anyone could get hurt, call for help now instead of filing a report.'**
  String get recheckBody;

  /// No description provided for @recheckYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, get help'**
  String get recheckYes;

  /// No description provided for @recheckNo.
  ///
  /// In en, this message translates to:
  /// **'No, continue'**
  String get recheckNo;

  /// No description provided for @savedForLater.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your report is saved and will send when you\'re back online.'**
  String get savedForLater;

  /// No description provided for @outboxWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send. It goes out when you\'re back online.'**
  String get outboxWaiting;

  /// No description provided for @outboxLimit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s report limit is used up. It sends tomorrow.'**
  String get outboxLimit;

  /// No description provided for @outboxFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send this report. Try again, or cancel it.'**
  String get outboxFailed;

  /// No description provided for @outboxDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Someone reported this nearby while you were offline. Add your voice instead?'**
  String get outboxDuplicate;

  /// No description provided for @sendAnyway.
  ///
  /// In en, this message translates to:
  /// **'It\'s different, send it'**
  String get sendAnyway;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Try again now'**
  String get retryNow;

  /// No description provided for @stillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still can\'t reach Burghood. We\'ll keep trying.'**
  String get stillOffline;

  /// No description provided for @cancelReport.
  ///
  /// In en, this message translates to:
  /// **'Cancel report'**
  String get cancelReport;

  /// No description provided for @unsentReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Some reports haven\'t been sent'**
  String get unsentReportsTitle;

  /// No description provided for @unsentReportsBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report is still waiting to send. Signing out deletes it from this phone.} other{{count} reports are still waiting to send. Signing out deletes them from this phone.}}'**
  String unsentReportsBody(int count);

  /// No description provided for @pushRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hear when it gets fixed'**
  String get pushRationaleTitle;

  /// No description provided for @pushRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when a report you made or said \"Me too\" to is sent to the office, fixed or reopened, and about urgent problems near places you save. At most 5 a day, and you choose which ones in Profile.'**
  String get pushRationaleBody;

  /// No description provided for @pushRationaleAllow.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushRationaleAllow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates, saved places and quiet hours'**
  String get notificationsSubtitle;

  /// No description provided for @pushOffBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off on this phone.'**
  String get pushOffBody;

  /// No description provided for @pushBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on for Burghood in your phone\'s settings.'**
  String get pushBlocked;

  /// No description provided for @notifyStatus.
  ///
  /// In en, this message translates to:
  /// **'Updates on my reports'**
  String get notifyStatus;

  /// No description provided for @notifyStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Reports you made or said \"Me too\" to: sent to the office, fixed or reopened.'**
  String get notifyStatusBody;

  /// No description provided for @notifyNearby.
  ///
  /// In en, this message translates to:
  /// **'Urgent problems near my places'**
  String get notifyNearby;

  /// No description provided for @notifyNearbyBody.
  ///
  /// In en, this message translates to:
  /// **'New urgent reports within the alert radius of your saved places.'**
  String get notifyNearbyBody;

  /// No description provided for @savedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlacesTitle;

  /// No description provided for @savedPlacesBody.
  ///
  /// In en, this message translates to:
  /// **'Home, school, work or anywhere you care about'**
  String get savedPlacesBody;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @quietHoursBody.
  ///
  /// In en, this message translates to:
  /// **'No notifications during these hours.'**
  String get quietHoursBody;

  /// No description provided for @quietFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quietFrom;

  /// No description provided for @quietUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get quietUntil;

  /// No description provided for @notifyLimitNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get at most 5 notifications a day.'**
  String get notifyLimitNote;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification'**
  String get sendTestNotification;

  /// No description provided for @testSent.
  ///
  /// In en, this message translates to:
  /// **'Test sent. It should arrive in a few seconds.'**
  String get testSent;

  /// No description provided for @savedPlacesIntro.
  ///
  /// In en, this message translates to:
  /// **'Save up to 3 places. We\'ll tell you about new urgent problems nearby. We store only the point on the map, not an address.'**
  String get savedPlacesIntro;

  /// No description provided for @noSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get noSavedPlaces;

  /// No description provided for @addPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// No description provided for @editPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// No description provided for @alertRadius.
  ///
  /// In en, this message translates to:
  /// **'Alert radius: {miles} mi'**
  String alertRadius(String miles);

  /// No description provided for @placesFull.
  ///
  /// In en, this message translates to:
  /// **'You\'ve saved {count} places, the most you can.'**
  String placesFull(int count);

  /// No description provided for @placeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get placeHome;

  /// No description provided for @placeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get placeSchool;

  /// No description provided for @placeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get placeWork;

  /// No description provided for @placeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get placeOther;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get placeLabel;

  /// No description provided for @placeMapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Map of the saved place. Tap to move it.'**
  String get placeMapSemantics;

  /// No description provided for @placeTapMap.
  ///
  /// In en, this message translates to:
  /// **'Search, use your location, or tap the map to choose the spot.'**
  String get placeTapMap;

  /// No description provided for @placeChosen.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to move the spot.'**
  String get placeChosen;

  /// No description provided for @savePlace.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get savePlace;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;
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
