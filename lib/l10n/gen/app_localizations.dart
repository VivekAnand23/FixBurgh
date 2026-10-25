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

  /// No description provided for @findSocietyTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your society'**
  String get findSocietyTitle;

  /// No description provided for @findSocietyHint.
  ///
  /// In en, this message translates to:
  /// **'Your address or society name'**
  String get findSocietyHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noSocietiesFound.
  ///
  /// In en, this message translates to:
  /// **'No society found here yet.'**
  String get noSocietiesFound;

  /// No description provided for @societiesNearAddress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 society near this address} other{{count} societies near this address}}'**
  String societiesNearAddress(int count);

  /// No description provided for @homesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 home} other{{count} homes}}'**
  String homesCount(int count);

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @requestToJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get requestToJoin;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @requestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Request sent. The society admin will review it.'**
  String get requestSentBody;

  /// No description provided for @dontSeeYours.
  ///
  /// In en, this message translates to:
  /// **'Don\'t see yours?'**
  String get dontSeeYours;

  /// No description provided for @createSociety.
  ///
  /// In en, this message translates to:
  /// **'Create a society'**
  String get createSociety;

  /// No description provided for @createSocietyBody.
  ///
  /// In en, this message translates to:
  /// **'For presidents, board members or managers. We check your documents before the society goes live.'**
  String get createSocietyBody;

  /// No description provided for @createSocietyNeeds.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need: a government photo ID, and proof of office (board resolution, election minutes or management agreement).'**
  String get createSocietyNeeds;

  /// No description provided for @imTheAdmin.
  ///
  /// In en, this message translates to:
  /// **'I\'m the admin, create it'**
  String get imTheAdmin;

  /// No description provided for @notTheAdmin.
  ///
  /// In en, this message translates to:
  /// **'Not the admin? Invite them'**
  String get notTheAdmin;

  /// No description provided for @inviteAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'Our society could use Burghood for notices, documents and neighbors. Could you set it up as our admin? Get the app: {link}'**
  String inviteAdminMessage(String link);

  /// No description provided for @haveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get haveInviteCode;

  /// No description provided for @requestPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Request to join {name}'**
  String requestPendingTitle(String name);

  /// No description provided for @requestPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the society admin.'**
  String get requestPendingBody;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @joinSocietyTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {name}'**
  String joinSocietyTitle(String name);

  /// No description provided for @joinSocietyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your unit number so the admin knows you live there. They\'ll approve or decline your request.'**
  String get joinSocietyBody;

  /// No description provided for @unitNumber.
  ///
  /// In en, this message translates to:
  /// **'Unit or house number'**
  String get unitNumber;

  /// No description provided for @unitNumberHint.
  ///
  /// In en, this message translates to:
  /// **'For example 4B or 1200'**
  String get unitNumberHint;

  /// No description provided for @unitNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit or house number (optional)'**
  String get unitNumberOptional;

  /// No description provided for @joinWithCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with an invite code'**
  String get joinWithCodeTitle;

  /// No description provided for @joinWithCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Your society admin can give you an 8-character code. With it you join straight away.'**
  String get joinWithCodeBody;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @inviteCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it with your society admin.'**
  String get inviteCodeInvalid;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joinedSociety.
  ///
  /// In en, this message translates to:
  /// **'You\'ve joined.'**
  String get joinedSociety;

  /// No description provided for @societySignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find your society'**
  String get societySignInTitle;

  /// No description provided for @societySignInBody.
  ///
  /// In en, this message translates to:
  /// **'Societies are for neighbors with an account, so admins know who\'s asking to join.'**
  String get societySignInBody;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Your society claim'**
  String get claimTitle;

  /// No description provided for @claimPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking {name}'**
  String claimPendingTitle(String name);

  /// No description provided for @claimPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your documents, usually within 2 working days.'**
  String get claimPendingBody;

  /// No description provided for @claimApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is live'**
  String claimApprovedTitle(String name);

  /// No description provided for @claimApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re its admin.'**
  String get claimApprovedBody;

  /// No description provided for @claimRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify {name}'**
  String claimRejectedTitle(String name);

  /// No description provided for @claimRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'See why, and send it again.'**
  String get claimRejectedBody;

  /// No description provided for @claimStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get claimStepSubmitted;

  /// No description provided for @claimStepReview.
  ///
  /// In en, this message translates to:
  /// **'Being reviewed'**
  String get claimStepReview;

  /// No description provided for @claimStepReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Burghood staff check your photo ID and proof of office.'**
  String get claimStepReviewBody;

  /// No description provided for @claimStepDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get claimStepDecision;

  /// No description provided for @claimStepApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved: your society is live'**
  String get claimStepApproved;

  /// No description provided for @claimStepRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get claimStepRejected;

  /// No description provided for @claimReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get claimReason;

  /// No description provided for @resubmit.
  ///
  /// In en, this message translates to:
  /// **'Fix and send again'**
  String get resubmit;

  /// No description provided for @openSociety.
  ///
  /// In en, this message translates to:
  /// **'Open my society'**
  String get openSociety;

  /// No description provided for @claimFilesNote.
  ///
  /// In en, this message translates to:
  /// **'Your ID and proof of office are seen only by Burghood staff and are deleted 30 days after the decision.'**
  String get claimFilesNote;

  /// No description provided for @claimSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for review.'**
  String get claimSubmitted;

  /// No description provided for @createSocietyIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your society and show that you run it. Burghood staff check every claim before the society appears in search.'**
  String get createSocietyIntro;

  /// No description provided for @sectionSociety.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get sectionSociety;

  /// No description provided for @societyName.
  ///
  /// In en, this message translates to:
  /// **'Society name'**
  String get societyName;

  /// No description provided for @societyAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get societyAddress;

  /// No description provided for @societyAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Street address of the society or its main building'**
  String get societyAddressHelp;

  /// No description provided for @checkAddress.
  ///
  /// In en, this message translates to:
  /// **'Check address'**
  String get checkAddress;

  /// No description provided for @outsideCountySociety.
  ///
  /// In en, this message translates to:
  /// **'That address is outside Allegheny County. Burghood only covers Allegheny County for now.'**
  String get outsideCountySociety;

  /// No description provided for @numberOfHomes.
  ///
  /// In en, this message translates to:
  /// **'Number of homes'**
  String get numberOfHomes;

  /// No description provided for @numberOfHomesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 2 to 5000.'**
  String get numberOfHomesInvalid;

  /// No description provided for @societyDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'A society may already exist here'**
  String get societyDuplicateTitle;

  /// No description provided for @societyDuplicateActive.
  ///
  /// In en, this message translates to:
  /// **'{name} is on Burghood, {distance} away.'**
  String societyDuplicateActive(String name, String distance);

  /// No description provided for @societyDuplicatePending.
  ///
  /// In en, this message translates to:
  /// **'A claim for {name}, {distance} away, is being reviewed.'**
  String societyDuplicatePending(String name, String distance);

  /// No description provided for @societyDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'If it\'s yours, ask to join it instead. Only claim a new society if it\'s a different one.'**
  String get societyDuplicateBody;

  /// No description provided for @sectionYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get sectionYou;

  /// No description provided for @yourFullName.
  ///
  /// In en, this message translates to:
  /// **'Your full name, as on your ID'**
  String get yourFullName;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get yourPosition;

  /// No description provided for @positionPresident.
  ///
  /// In en, this message translates to:
  /// **'President'**
  String get positionPresident;

  /// No description provided for @positionSecretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get positionSecretary;

  /// No description provided for @positionBoardMember.
  ///
  /// In en, this message translates to:
  /// **'Board member'**
  String get positionBoardMember;

  /// No description provided for @positionManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get positionManager;

  /// No description provided for @sectionHoa.
  ///
  /// In en, this message translates to:
  /// **'HOA management company'**
  String get sectionHoa;

  /// No description provided for @hoaHelp.
  ///
  /// In en, this message translates to:
  /// **'Members get one button that opens your management company\'s account page. Burghood stores the link only, never balances or payments.'**
  String get hoaHelp;

  /// No description provided for @hoaCompany.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get hoaCompany;

  /// No description provided for @hoaWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get hoaWebsite;

  /// No description provided for @hoaAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Account section link'**
  String get hoaAccountLink;

  /// No description provided for @hoaAccountLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'The page where residents sign in to their HOA account. Your management company can give you this link.'**
  String get hoaAccountLinkHelp;

  /// No description provided for @invalidLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a web address starting with https://'**
  String get invalidLink;

  /// No description provided for @sectionDocuments.
  ///
  /// In en, this message translates to:
  /// **'Your documents'**
  String get sectionDocuments;

  /// No description provided for @verificationRequirements.
  ///
  /// In en, this message translates to:
  /// **'We need two documents.\n1. A government photo ID: a driver\'s license, state ID, passport or passport card, or military ID, with your name and photo easy to read.\n2. Proof of office that names you and the society: a board resolution, election minutes, or a management agreement.\nPhotos or PDFs, up to 5 MB each. The name on both must match.'**
  String get verificationRequirements;

  /// No description provided for @photoId.
  ///
  /// In en, this message translates to:
  /// **'Government photo ID'**
  String get photoId;

  /// No description provided for @photoIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s license, state ID, passport or military ID'**
  String get photoIdHelp;

  /// No description provided for @proofOfOffice.
  ///
  /// In en, this message translates to:
  /// **'Proof of office'**
  String get proofOfOffice;

  /// No description provided for @proofOfOfficeHelp.
  ///
  /// In en, this message translates to:
  /// **'Board resolution, election minutes or management agreement naming you'**
  String get proofOfOfficeHelp;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chooseFile;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get choosePhoto;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large. The limit is {mb} MB.'**
  String fileTooLarge(int mb);

  /// No description provided for @claimConfirm.
  ///
  /// In en, this message translates to:
  /// **'I hold this position in the society, and these documents are genuine.'**
  String get claimConfirm;

  /// No description provided for @howWeUseDocuments.
  ///
  /// In en, this message translates to:
  /// **'How we use your documents'**
  String get howWeUseDocuments;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get submitForReview;

  /// No description provided for @reviewTarget.
  ///
  /// In en, this message translates to:
  /// **'We aim to decide within 2 working days.'**
  String get reviewTarget;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @switchSociety.
  ///
  /// In en, this message translates to:
  /// **'Switch society'**
  String get switchSociety;

  /// No description provided for @youAre.
  ///
  /// In en, this message translates to:
  /// **'You\'re {role}'**
  String youAre(String role);

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'a member'**
  String get roleMember;

  /// No description provided for @roleCommittee.
  ///
  /// In en, this message translates to:
  /// **'on the committee'**
  String get roleCommittee;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'an admin'**
  String get roleAdmin;

  /// No description provided for @joinAnotherSociety.
  ///
  /// In en, this message translates to:
  /// **'Join or create another society'**
  String get joinAnotherSociety;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @hoaAccount.
  ///
  /// In en, this message translates to:
  /// **'HOA account'**
  String get hoaAccount;

  /// No description provided for @tabNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get tabNotices;

  /// No description provided for @tabDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get tabDocs;

  /// No description provided for @tabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tabMembers;

  /// No description provided for @noNotices.
  ///
  /// In en, this message translates to:
  /// **'No notices yet.'**
  String get noNotices;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet.'**
  String get noDocuments;

  /// No description provided for @newNotice.
  ///
  /// In en, this message translates to:
  /// **'New notice'**
  String get newNotice;

  /// No description provided for @pinnedNotice.
  ///
  /// In en, this message translates to:
  /// **'📌 Notice'**
  String get pinnedNotice;

  /// No description provided for @pinnedNoticeFrom.
  ///
  /// In en, this message translates to:
  /// **'📌 Notice · from {name}'**
  String pinnedNoticeFrom(String name);

  /// No description provided for @postedAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {when}'**
  String postedAgo(String when);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @hasAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get hasAttachment;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String daysAgo(int n);

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}?'**
  String deleteDocumentTitle(String title);

  /// No description provided for @docBylaws.
  ///
  /// In en, this message translates to:
  /// **'Bylaws'**
  String get docBylaws;

  /// No description provided for @docMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get docMinutes;

  /// No description provided for @docBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get docBudget;

  /// No description provided for @docRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get docRules;

  /// No description provided for @docOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get docOther;

  /// No description provided for @neighbor.
  ///
  /// In en, this message translates to:
  /// **'Neighbor'**
  String get neighbor;

  /// No description provided for @youName.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youName(String name);

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}'**
  String unitLabel(String unit);

  /// No description provided for @memberActions.
  ///
  /// In en, this message translates to:
  /// **'Member options'**
  String get memberActions;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get makeMember;

  /// No description provided for @makeCommittee.
  ///
  /// In en, this message translates to:
  /// **'Add to committee'**
  String get makeCommittee;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make co-admin'**
  String get makeAdmin;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this member?'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They lose access to notices and documents. They can ask to join again.'**
  String get removeMemberBody;

  /// No description provided for @manageSociety.
  ///
  /// In en, this message translates to:
  /// **'Manage {name}'**
  String manageSociety(String name);

  /// No description provided for @adminsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only society admins can see this.'**
  String get adminsOnly;

  /// No description provided for @joinRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Join requests} other{Join requests ({count})}}'**
  String joinRequests(int count);

  /// No description provided for @noJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests waiting.'**
  String get noJoinRequests;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @inviteCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code joins straight away, without your approval. Share it with residents only.'**
  String get inviteCodeBody;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @newCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newCode;

  /// No description provided for @newCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a new invite code?'**
  String get newCodeTitle;

  /// No description provided for @newCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The current code will stop working. People who already joined stay in.'**
  String get newCodeBody;

  /// No description provided for @inviteMembersMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {society} on Burghood for notices and documents. Get the app at {link} and enter invite code {code}.'**
  String inviteMembersMessage(String society, String code, String link);

  /// No description provided for @shareWithMembers.
  ///
  /// In en, this message translates to:
  /// **'Share with members'**
  String get shareWithMembers;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noticeGone.
  ///
  /// In en, this message translates to:
  /// **'This notice was removed.'**
  String get noticeGone;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noticeTitle;

  /// No description provided for @noticeBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get noticeBody;

  /// No description provided for @pinNotice.
  ///
  /// In en, this message translates to:
  /// **'Pin to the top'**
  String get pinNotice;

  /// No description provided for @pinNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Pinned notices show first until they expire.'**
  String get pinNoticeBody;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get noExpiry;

  /// No description provided for @addExpiry.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addExpiry;

  /// No description provided for @removeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remove expiry date'**
  String get removeExpiry;

  /// No description provided for @noAttachment.
  ///
  /// In en, this message translates to:
  /// **'No attachment'**
  String get noAttachment;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attachFile;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @postNotice.
  ///
  /// In en, this message translates to:
  /// **'Post notice'**
  String get postNotice;

  /// No description provided for @noticePushNote.
  ///
  /// In en, this message translates to:
  /// **'Every member gets a notification.'**
  String get noticePushNote;

  /// No description provided for @noticePosted.
  ///
  /// In en, this message translates to:
  /// **'Notice posted.'**
  String get noticePosted;

  /// No description provided for @choosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get choosePdf;

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get documentTitle;

  /// No description provided for @documentCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get documentCategory;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded.'**
  String get documentUploaded;

  /// No description provided for @documentsMembersOnly.
  ///
  /// In en, this message translates to:
  /// **'Only approved members can open documents.'**
  String get documentsMembersOnly;

  /// No description provided for @notifyNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices from admins'**
  String get notifyNotices;

  /// No description provided for @notifyNoticesBody.
  ///
  /// In en, this message translates to:
  /// **'Announcements from your society\'s admins and committee'**
  String get notifyNoticesBody;

  /// No description provided for @tabChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get tabChannels;

  /// No description provided for @newChannel.
  ///
  /// In en, this message translates to:
  /// **'New channel'**
  String get newChannel;

  /// No description provided for @renameChannel.
  ///
  /// In en, this message translates to:
  /// **'Rename channel'**
  String get renameChannel;

  /// No description provided for @archiveChannel.
  ///
  /// In en, this message translates to:
  /// **'Archive channel'**
  String get archiveChannel;

  /// No description provided for @channelName.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelName;

  /// No description provided for @channelNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example Block B or Events'**
  String get channelNameHint;

  /// No description provided for @channelOptions.
  ///
  /// In en, this message translates to:
  /// **'Channel options'**
  String get channelOptions;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @firstPost.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Say hello to your neighbors.'**
  String get firstPost;

  /// No description provided for @messageChannel.
  ///
  /// In en, this message translates to:
  /// **'Message #{name}'**
  String messageChannel(String name);

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @muteFor8Hours.
  ///
  /// In en, this message translates to:
  /// **'Mute for 8 hours'**
  String get muteFor8Hours;

  /// No description provided for @muteFor1Week.
  ///
  /// In en, this message translates to:
  /// **'Mute for 1 week'**
  String get muteFor1Week;

  /// No description provided for @muteAlways.
  ///
  /// In en, this message translates to:
  /// **'Mute always'**
  String get muteAlways;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mentionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mention} other{{count} mentions}}'**
  String mentionsCount(int count);

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new post} other{{count} new posts}}'**
  String unreadCount(int count);

  /// No description provided for @pinnedPost.
  ///
  /// In en, this message translates to:
  /// **'📌 Pinned'**
  String get pinnedPost;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// No description provided for @postOptions.
  ///
  /// In en, this message translates to:
  /// **'Post options'**
  String get postOptions;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String commentsCount(int count);

  /// No description provided for @postPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo in post'**
  String get postPhoto;

  /// No description provided for @reactionCount.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {count}'**
  String reactionCount(String emoji, int count);

  /// No description provided for @addReaction.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get addReaction;

  /// No description provided for @pinPost.
  ///
  /// In en, this message translates to:
  /// **'Pin to the top'**
  String get pinPost;

  /// No description provided for @unpinPost.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report to admins'**
  String get reportPost;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. The society\'s admins will take a look.'**
  String get reportSent;

  /// No description provided for @blockAuthor.
  ///
  /// In en, this message translates to:
  /// **'Hide posts from this person'**
  String get blockAuthor;

  /// No description provided for @authorBlocked.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their posts or comments.'**
  String get authorBlocked;

  /// No description provided for @postGone.
  ///
  /// In en, this message translates to:
  /// **'This post was removed.'**
  String get postGone;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get writeComment;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get inboxTitle;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Updates on your reports and your society show up here.'**
  String get inboxEmpty;

  /// No description provided for @notifyInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interaction notifications'**
  String get notifyInteractions;

  /// No description provided for @notifyInteractionsBody.
  ///
  /// In en, this message translates to:
  /// **'Comments, replies, reactions and @mentions in your society\'s channels. Turn off to stop all of them.'**
  String get notifyInteractionsBody;

  /// No description provided for @notifyMentions.
  ///
  /// In en, this message translates to:
  /// **'@mentions'**
  String get notifyMentions;

  /// No description provided for @notifyMentionsBody.
  ///
  /// In en, this message translates to:
  /// **'When a neighbor mentions you, even in a muted channel'**
  String get notifyMentionsBody;

  /// No description provided for @mutedChannels.
  ///
  /// In en, this message translates to:
  /// **'Muted channels'**
  String get mutedChannels;

  /// No description provided for @mutedChannelsBody.
  ///
  /// In en, this message translates to:
  /// **'No comment or reaction notifications from these. @mentions still come through.'**
  String get mutedChannelsBody;

  /// No description provided for @noMutedChannels.
  ///
  /// In en, this message translates to:
  /// **'None. Mute a channel from its menu.'**
  String get noMutedChannels;

  /// No description provided for @mutedAlways.
  ///
  /// In en, this message translates to:
  /// **'Muted always'**
  String get mutedAlways;

  /// No description provided for @mutedUntil.
  ///
  /// In en, this message translates to:
  /// **'Muted until {time}'**
  String mutedUntil(String time);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @whereIsProblem.
  ///
  /// In en, this message translates to:
  /// **'Where is the problem?'**
  String get whereIsProblem;

  /// No description provided for @forkStreet.
  ///
  /// In en, this message translates to:
  /// **'On the street'**
  String get forkStreet;

  /// No description provided for @forkStreetBody.
  ///
  /// In en, this message translates to:
  /// **'Potholes, streetlights, trash. We send it to the city.'**
  String get forkStreetBody;

  /// No description provided for @forkHome.
  ///
  /// In en, this message translates to:
  /// **'In my home'**
  String get forkHome;

  /// No description provided for @forkHomeBody.
  ///
  /// In en, this message translates to:
  /// **'A leak, a broken appliance, or help you need. Find a local provider.'**
  String get forkHomeBody;

  /// No description provided for @forkCommon.
  ///
  /// In en, this message translates to:
  /// **'In my society\'s common areas'**
  String get forkCommon;

  /// No description provided for @forkCommonBody.
  ///
  /// In en, this message translates to:
  /// **'Lobby, hallways, grounds. Your society admin picks the provider.'**
  String get forkCommonBody;

  /// No description provided for @tabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get tabServices;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request a service'**
  String get requestService;

  /// No description provided for @commonRequests.
  ///
  /// In en, this message translates to:
  /// **'Common areas'**
  String get commonRequests;

  /// No description provided for @commonRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No common-area requests yet.'**
  String get commonRequestsEmpty;

  /// No description provided for @servicesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'What do you need? e.g. kitchen tap leaking'**
  String get servicesSearchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for:'**
  String get lookingFor;

  /// No description provided for @distanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceFilter;

  /// No description provided for @withinMiles.
  ///
  /// In en, this message translates to:
  /// **'Within {miles} mi'**
  String withinMiles(int miles);

  /// No description provided for @milesAway.
  ///
  /// In en, this message translates to:
  /// **'{miles} mi away'**
  String milesAway(String miles);

  /// No description provided for @noProvidersFound.
  ///
  /// In en, this message translates to:
  /// **'No providers found yet. Try a wider distance or other words.'**
  String get noProvidersFound;

  /// No description provided for @becomeProvider.
  ///
  /// In en, this message translates to:
  /// **'Offer your services'**
  String get becomeProvider;

  /// No description provided for @becomeProviderBody.
  ///
  /// In en, this message translates to:
  /// **'Neighbors can find you and send you requests.'**
  String get becomeProviderBody;

  /// No description provided for @yourProviderProfile.
  ///
  /// In en, this message translates to:
  /// **'Your provider profile'**
  String get yourProviderProfile;

  /// No description provided for @providerAppliedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get providerAppliedTitle;

  /// No description provided for @providerApplied.
  ///
  /// In en, this message translates to:
  /// **'We\'re checking your details and documents. We aim to decide within 2 working days.'**
  String get providerApplied;

  /// No description provided for @providerLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re live'**
  String get providerLiveTitle;

  /// No description provided for @providerLive.
  ///
  /// In en, this message translates to:
  /// **'Neighbors can find you and send you requests.'**
  String get providerLive;

  /// No description provided for @providerRejected.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t approve your application'**
  String get providerRejected;

  /// No description provided for @providerSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is paused'**
  String get providerSuspendedTitle;

  /// No description provided for @providerSuspended.
  ///
  /// In en, this message translates to:
  /// **'Neighbors can\'t find you right now. Contact support to find out more.'**
  String get providerSuspended;

  /// No description provided for @rejectedBecause.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t approve it: {reason}. Fix this and send it again.'**
  String rejectedBecause(String reason);

  /// No description provided for @becomeProviderIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell neighbors what you do. We check every provider before they appear, and the documents you add are seen only by the Burghood team.'**
  String get becomeProviderIntro;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business or your name'**
  String get businessName;

  /// No description provided for @aboutYourWork.
  ///
  /// In en, this message translates to:
  /// **'About your work'**
  String get aboutYourWork;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown to a neighbor once you accept their request.'**
  String get phoneHelper;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get phoneInvalid;

  /// No description provided for @serviceAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Where you\'re based'**
  String get serviceAreaLabel;

  /// No description provided for @serviceAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood, town or ZIP code'**
  String get serviceAreaHint;

  /// No description provided for @travelDistance.
  ///
  /// In en, this message translates to:
  /// **'How far you travel'**
  String get travelDistance;

  /// No description provided for @documentsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsNeeded;

  /// No description provided for @documentsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only the Burghood team can see these.'**
  String get documentsPrivate;

  /// No description provided for @docLicense.
  ///
  /// In en, this message translates to:
  /// **'Pennsylvania contractor registration (HIC)'**
  String get docLicense;

  /// No description provided for @docInsurance.
  ///
  /// In en, this message translates to:
  /// **'Proof of insurance'**
  String get docInsurance;

  /// No description provided for @docBackground.
  ///
  /// In en, this message translates to:
  /// **'Background check, plus child abuse clearances if you care for children'**
  String get docBackground;

  /// No description provided for @docFormats.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG or PNG, up to 5 MB'**
  String get docFormats;

  /// No description provided for @alreadyUploaded.
  ///
  /// In en, this message translates to:
  /// **'Already uploaded'**
  String get alreadyUploaded;

  /// No description provided for @providerAgree.
  ///
  /// In en, this message translates to:
  /// **'I\'ll follow the provider rules, and my details and documents are true.'**
  String get providerAgree;

  /// No description provided for @readProviderRules.
  ///
  /// In en, this message translates to:
  /// **'Read the provider rules'**
  String get readProviderRules;

  /// No description provided for @pickAService.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one service.'**
  String get pickAService;

  /// No description provided for @documentsMissing.
  ///
  /// In en, this message translates to:
  /// **'Add the documents these services need.'**
  String get documentsMissing;

  /// No description provided for @agreeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the provider rules first.'**
  String get agreeFirst;

  /// No description provided for @areaNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that place in Allegheny County.'**
  String get areaNotFound;

  /// No description provided for @viewPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'View public profile'**
  String get viewPublicProfile;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @providerNotFound.
  ///
  /// In en, this message translates to:
  /// **'This provider isn\'t available.'**
  String get providerNotFound;

  /// No description provided for @requestThisProvider.
  ///
  /// In en, this message translates to:
  /// **'Request this provider'**
  String get requestThisProvider;

  /// No description provided for @recommendToSociety.
  ///
  /// In en, this message translates to:
  /// **'Recommend to your society'**
  String get recommendToSociety;

  /// No description provided for @recommendToSocietyBody.
  ///
  /// In en, this message translates to:
  /// **'Shows a \"Recommended by your society\" tag to members.'**
  String get recommendToSocietyBody;

  /// No description provided for @recommendedBySociety.
  ///
  /// In en, this message translates to:
  /// **'Recommended by your society'**
  String get recommendedBySociety;

  /// No description provided for @backgroundChecked.
  ///
  /// In en, this message translates to:
  /// **'Background checked'**
  String get backgroundChecked;

  /// No description provided for @providerServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get providerServices;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get serviceArea;

  /// No description provided for @serviceAreaLine.
  ///
  /// In en, this message translates to:
  /// **'{area}, within {miles} mi'**
  String serviceAreaLine(String area, String miles);

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Past work'**
  String get portfolio;

  /// No description provided for @noPortfolio.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get noPortfolio;

  /// No description provided for @portfolioPhoto.
  ///
  /// In en, this message translates to:
  /// **'Past work photo {n}'**
  String portfolioPhoto(int n);

  /// No description provided for @addPortfolioPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of past work'**
  String get addPortfolioPhoto;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Reviews} =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @ratingSummary.
  ///
  /// In en, this message translates to:
  /// **'Rated {avg} out of 5 from {count, plural, =1{1 review} other{{count} reviews}}'**
  String ratingSummary(String avg, int count);

  /// No description provided for @providerReply.
  ///
  /// In en, this message translates to:
  /// **'Reply from the provider'**
  String get providerReply;

  /// No description provided for @replyToReview.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyToReview;

  /// No description provided for @starsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String starsLabel(int count);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @newRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequestTitle;

  /// No description provided for @commonRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Common-area request'**
  String get commonRequestTitle;

  /// No description provided for @commonRequestNote.
  ///
  /// In en, this message translates to:
  /// **'Your society admin will choose the provider and you\'ll get updates here.'**
  String get commonRequestNote;

  /// No description provided for @sendingTo.
  ///
  /// In en, this message translates to:
  /// **'Sending to {name}'**
  String sendingTo(String name);

  /// No description provided for @requestTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s the problem?'**
  String get requestTitleLabel;

  /// No description provided for @requestTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kitchen tap leaking'**
  String get requestTitleHint;

  /// No description provided for @requestDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get requestDescriptionLabel;

  /// No description provided for @requestDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Where it is, when it started, anything the provider should know'**
  String get requestDescriptionHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @pickCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a category first.'**
  String get pickCategoryFirst;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count} of {max})'**
  String photosCount(int count, int max);

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @requestQueued.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your request is saved and will send when you\'re back online.'**
  String get requestQueued;

  /// No description provided for @requestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send. It goes when you\'re back online.'**
  String get requestWaiting;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send this request. Try again, or cancel it.'**
  String get requestFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @detailUrgency.
  ///
  /// In en, this message translates to:
  /// **'How urgent?'**
  String get detailUrgency;

  /// No description provided for @detailAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get detailAccess;

  /// No description provided for @detailAccessHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Key with the front desk'**
  String get detailAccessHint;

  /// No description provided for @detailTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get detailTimeWindow;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailHours.
  ///
  /// In en, this message translates to:
  /// **'Hours needed'**
  String get detailHours;

  /// No description provided for @detailChildrenAges.
  ///
  /// In en, this message translates to:
  /// **'Children\'s ages'**
  String get detailChildrenAges;

  /// No description provided for @detailChildrenAgesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3 and 6'**
  String get detailChildrenAgesHint;

  /// No description provided for @detailPetType.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get detailPetType;

  /// No description provided for @detailPetSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get detailPetSize;

  /// No description provided for @detailBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get detailBudget;

  /// No description provided for @detailBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \$50 to \$100'**
  String get detailBudgetHint;

  /// No description provided for @urgencyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency, today'**
  String get urgencyEmergency;

  /// No description provided for @urgencySoon.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get urgencySoon;

  /// No description provided for @urgencyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get urgencyFlexible;

  /// No description provided for @windowMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get windowMorning;

  /// No description provided for @windowAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get windowAfternoon;

  /// No description provided for @windowEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get windowEvening;

  /// No description provided for @windowAny.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get windowAny;

  /// No description provided for @petDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get petDog;

  /// No description provided for @petCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petCat;

  /// No description provided for @petOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get petOther;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @requestTitle.
  ///
  /// In en, this message translates to:
  /// **'Service request'**
  String get requestTitle;

  /// No description provided for @requestNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request isn\'t available.'**
  String get requestNotFound;

  /// No description provided for @commonArea.
  ///
  /// In en, this message translates to:
  /// **'Common area'**
  String get commonArea;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @declinedBecause.
  ///
  /// In en, this message translates to:
  /// **'The provider declined: {reason}'**
  String declinedBecause(String reason);

  /// No description provided for @notFixedBecause.
  ///
  /// In en, this message translates to:
  /// **'Not fixed: {note}'**
  String notFixedBecause(String note);

  /// No description provided for @completionHeading.
  ///
  /// In en, this message translates to:
  /// **'Work done'**
  String get completionHeading;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get watchVideo;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Updates appear here.'**
  String get timelineEmpty;

  /// No description provided for @chooseProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider'**
  String get chooseProvider;

  /// No description provided for @waitingForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your society admin to choose a provider.'**
  String get waitingForAdmin;

  /// No description provided for @waitingForProvider.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the provider to accept.'**
  String get waitingForProvider;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @confirmDone.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s done'**
  String get confirmDone;

  /// No description provided for @notFixed.
  ///
  /// In en, this message translates to:
  /// **'Not fixed'**
  String get notFixed;

  /// No description provided for @notFixedTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s still wrong?'**
  String get notFixedTitle;

  /// No description provided for @notFixedHint.
  ///
  /// In en, this message translates to:
  /// **'The provider sees this and can come back to it.'**
  String get notFixedHint;

  /// No description provided for @rateProvider.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get rateProvider;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell neighbors about the work (optional)'**
  String get reviewHint;

  /// No description provided for @sendReview.
  ///
  /// In en, this message translates to:
  /// **'Send review'**
  String get sendReview;

  /// No description provided for @acceptJob.
  ///
  /// In en, this message translates to:
  /// **'Accept job'**
  String get acceptJob;

  /// No description provided for @declineJob.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineJob;

  /// No description provided for @declineHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional), e.g. fully booked this week'**
  String get declineHint;

  /// No description provided for @startJob.
  ///
  /// In en, this message translates to:
  /// **'Start job'**
  String get startJob;

  /// No description provided for @completeJob.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get completeJob;

  /// No description provided for @completionNote.
  ///
  /// In en, this message translates to:
  /// **'What you did'**
  String get completionNote;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add short video'**
  String get addVideo;

  /// No description provided for @videoAdded.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoAdded;

  /// No description provided for @videoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That video is too large. The limit is 30 MB.'**
  String get videoTooLarge;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Send to neighbor'**
  String get markDone;

  /// No description provided for @srPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get srPosted;

  /// No description provided for @srAssigned.
  ///
  /// In en, this message translates to:
  /// **'Sent to provider'**
  String get srAssigned;

  /// No description provided for @srAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get srAccepted;

  /// No description provided for @srDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get srDeclined;

  /// No description provided for @srInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get srInProgress;

  /// No description provided for @srCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done, please check'**
  String get srCompleted;

  /// No description provided for @srNotFixed.
  ///
  /// In en, this message translates to:
  /// **'Not fixed'**
  String get srNotFixed;

  /// No description provided for @srConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get srConfirmed;

  /// No description provided for @srClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get srClosed;

  /// No description provided for @srCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get srCancelled;

  /// No description provided for @activityServiceRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get activityServiceRequests;

  /// No description provided for @activityJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get activityJobs;

  /// No description provided for @serviceRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Requests you make for your home or society show up here.'**
  String get serviceRequestsEmpty;

  /// No description provided for @jobsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Requests neighbors send you show up here.'**
  String get jobsEmpty;

  /// No description provided for @openCount.
  ///
  /// In en, this message translates to:
  /// **'Open ({count})'**
  String openCount(int count);

  /// No description provided for @doneCount.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String doneCount(int count);

  /// No description provided for @notifyServices.
  ///
  /// In en, this message translates to:
  /// **'Service requests and jobs'**
  String get notifyServices;

  /// No description provided for @notifyServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Updates on requests you made and jobs sent to you'**
  String get notifyServicesBody;

  /// No description provided for @listingExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Neighbors can find you and send you requests. Your listing runs until {date}.'**
  String listingExpiresOn(String date);

  /// No description provided for @providerAwaitingFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Approved, waiting for the listing fee'**
  String get providerAwaitingFeeTitle;

  /// No description provided for @providerAwaitingFee.
  ///
  /// In en, this message translates to:
  /// **'You\'ll appear in search once the {fee} listing fee for {months} months is paid. The Burghood team will be in touch about payment.'**
  String providerAwaitingFee(String fee, int months);

  /// No description provided for @providerAwaitingFeeShort.
  ///
  /// In en, this message translates to:
  /// **'Approved. You\'ll be listed once the listing fee is paid.'**
  String get providerAwaitingFeeShort;

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsored;

  /// No description provided for @allProviders.
  ///
  /// In en, this message translates to:
  /// **'All providers'**
  String get allProviders;

  /// No description provided for @googleResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not on Burghood yet'**
  String get googleResultsTitle;

  /// No description provided for @googleResultsNote.
  ///
  /// In en, this message translates to:
  /// **'These businesses come from Google Maps. Burghood hasn\'t checked them, and they can\'t take requests in the app.'**
  String get googleResultsNote;

  /// No description provided for @googleAttribution.
  ///
  /// In en, this message translates to:
  /// **'Results from Google Maps'**
  String get googleAttribution;

  /// No description provided for @googleRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count, plural, =1{1 review} other{{count} reviews}} on Google)'**
  String googleRating(String rating, int count);

  /// No description provided for @searchGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Search Google Maps for {query}'**
  String searchGoogleMaps(String query);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @listingFeeDue.
  ///
  /// In en, this message translates to:
  /// **'Listing fee'**
  String get listingFeeDue;

  /// No description provided for @feeForMonths.
  ///
  /// In en, this message translates to:
  /// **'{amount} for {months} months'**
  String feeForMonths(String amount, int months);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String dueOn(String date);

  /// No description provided for @howToPay.
  ///
  /// In en, this message translates to:
  /// **'How to pay'**
  String get howToPay;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now'**
  String payNow(String amount);

  /// No description provided for @goesLiveWhenRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your profile goes live as soon as the Burghood team records your payment.'**
  String get goesLiveWhenRecorded;

  /// No description provided for @forProviders.
  ///
  /// In en, this message translates to:
  /// **'For service providers'**
  String get forProviders;
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
