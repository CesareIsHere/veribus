import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('it')];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Veribus'**
  String get appTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your account and all its data will be permanently deleted. This cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all its data.'**
  String get deleteAccountDescription;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email with the link we sent you, then sign in.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailInUse;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get errorNotSupported;

  /// No description provided for @errorRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For security, sign in again and retry.'**
  String get errorRequiresRecentLogin;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the request.'**
  String get errorServer;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get errorWeakPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get goHome;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get licenses;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountRegister;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offline;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orContinueWith;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found.'**
  String get pageNotFound;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can now sign in.'**
  String get passwordUpdated;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, we sent you a reset link.'**
  String get resetEmailSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetPasswordTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendResetLink;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get terms;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'A new version is required to continue.'**
  String get updateRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a number'**
  String get validationPassword;

  /// No description provided for @validationPasswordsMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get validationPasswordsMatch;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get appUpdates;

  /// No description provided for @appUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'Download the latest version from the GitHub releases'**
  String get appUpdatesBody;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get nearby;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @allLines.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLines;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @lines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lines;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// No description provided for @lineDetail.
  ///
  /// In en, this message translates to:
  /// **'Line {name}'**
  String lineDetail(String name);

  /// No description provided for @stopCode.
  ///
  /// In en, this message translates to:
  /// **'stop {code}'**
  String stopCode(String code);

  /// No description provided for @stopNotServed.
  ///
  /// In en, this message translates to:
  /// **'This stop is no longer served.'**
  String get stopNotServed;

  /// No description provided for @lineNotServed.
  ///
  /// In en, this message translates to:
  /// **'This line is not in service.'**
  String get lineNotServed;

  /// No description provided for @notServedAnymore.
  ///
  /// In en, this message translates to:
  /// **'No longer served'**
  String get notServedAnymore;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutes(int n);

  /// No description provided for @around.
  ///
  /// In en, this message translates to:
  /// **'around {time}'**
  String around(String time);

  /// No description provided for @arriving.
  ///
  /// In en, this message translates to:
  /// **'arriving'**
  String get arriving;

  /// No description provided for @stopsAway.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{at the stop} =1{1 stop away} other{{n} stops away}}'**
  String stopsAway(int n);

  /// No description provided for @approximateTime.
  ///
  /// In en, this message translates to:
  /// **'in about {n} min, approximate time'**
  String approximateTime(int n);

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'vehicle {label}'**
  String vehicle(String label);

  /// No description provided for @noRealtimeData.
  ///
  /// In en, this message translates to:
  /// **'no realtime data'**
  String get noRealtimeData;

  /// No description provided for @lineWithoutRealtime.
  ///
  /// In en, this message translates to:
  /// **'this line does not transmit its position'**
  String get lineWithoutRealtime;

  /// No description provided for @withoutRealtime.
  ///
  /// In en, this message translates to:
  /// **'No realtime, scheduled times only'**
  String get withoutRealtime;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusUncertain.
  ///
  /// In en, this message translates to:
  /// **'To be checked'**
  String get statusUncertain;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusSuppressed.
  ///
  /// In en, this message translates to:
  /// **'Suppressed'**
  String get statusSuppressed;

  /// No description provided for @signalCanceled.
  ///
  /// In en, this message translates to:
  /// **'Trip canceled'**
  String get signalCanceled;

  /// No description provided for @signalNotTransmitting.
  ///
  /// In en, this message translates to:
  /// **'The vehicle has not transmitted for {n} min'**
  String signalNotTransmitting(int n);

  /// No description provided for @signalNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle located'**
  String get signalNoVehicle;

  /// No description provided for @signalStill.
  ///
  /// In en, this message translates to:
  /// **'Vehicle stopped for {n} min'**
  String signalStill(int n);

  /// No description provided for @signalOldGps.
  ///
  /// In en, this message translates to:
  /// **'Last GPS signal {n} min ago'**
  String signalOldGps(int n);

  /// No description provided for @signalAtTerminus.
  ///
  /// In en, this message translates to:
  /// **'Leaves the terminus at {time}'**
  String signalAtTerminus(String time);

  /// No description provided for @signalAtTerminusNoTime.
  ///
  /// In en, this message translates to:
  /// **'Still at the terminus'**
  String get signalAtTerminusNoTime;

  /// No description provided for @signalLateData.
  ///
  /// In en, this message translates to:
  /// **'Realtime data delayed'**
  String get signalLateData;

  /// No description provided for @realtimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Realtime unavailable: showing scheduled times'**
  String get realtimeUnavailable;

  /// No description provided for @noArrivals.
  ///
  /// In en, this message translates to:
  /// **'No arrivals in the next 60 minutes'**
  String get noArrivals;

  /// No description provided for @updatedAgo.
  ///
  /// In en, this message translates to:
  /// **'updated {s} s ago'**
  String updatedAgo(int s);

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Today\'s timetable'**
  String get timetable;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @scheduledTimesNote.
  ///
  /// In en, this message translates to:
  /// **'Scheduled times: they do not take traffic into account.'**
  String get scheduledTimesNote;

  /// No description provided for @noServiceThisDay.
  ///
  /// In en, this message translates to:
  /// **'No service on this day'**
  String get noServiceThisDay;

  /// No description provided for @firstTrip.
  ///
  /// In en, this message translates to:
  /// **'first'**
  String get firstTrip;

  /// No description provided for @lastTrip.
  ///
  /// In en, this message translates to:
  /// **'last'**
  String get lastTrip;

  /// No description provided for @lastPositionAt.
  ///
  /// In en, this message translates to:
  /// **'last known position at {time}'**
  String lastPositionAt(String time);

  /// No description provided for @terminus.
  ///
  /// In en, this message translates to:
  /// **'terminus'**
  String get terminus;

  /// No description provided for @noTripsInService.
  ///
  /// In en, this message translates to:
  /// **'No trips in service'**
  String get noTripsInService;

  /// No description provided for @nextDeparture.
  ///
  /// In en, this message translates to:
  /// **'Next departure at {time}'**
  String nextDeparture(String time);

  /// No description provided for @vehiclesInService.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No vehicles in service} =1{1 vehicle in service} other{{n} vehicles in service}}'**
  String vehiclesInService(int n);

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results. Check the code written on the stop pole.'**
  String get searchNoResults;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see nearby stops'**
  String get locationDenied;

  /// No description provided for @locationDeniedList.
  ///
  /// In en, this message translates to:
  /// **'Without your position the list is empty: use Search to find a stop.'**
  String get locationDeniedList;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get enableLocation;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get you;

  /// No description provided for @backToMyPosition.
  ///
  /// In en, this message translates to:
  /// **'Back to my position'**
  String get backToMyPosition;

  /// No description provided for @noStopsNearby.
  ///
  /// In en, this message translates to:
  /// **'No stops within 1 km'**
  String get noStopsNearby;

  /// No description provided for @nearbyNote.
  ///
  /// In en, this message translates to:
  /// **'Stops within 500 m, sorted by distance. If there are none, the radius grows to 1 km.'**
  String get nearbyNote;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'{n} m'**
  String meters(int n);

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on a stop or a line: the app will open here.'**
  String get noFavoritesHint;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noAlerts;

  /// No description provided for @alertsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 alert} other{{n} alerts}}'**
  String alertsCount(int n);

  /// No description provided for @arrivalStates.
  ///
  /// In en, this message translates to:
  /// **'Arrival states'**
  String get arrivalStates;

  /// No description provided for @arrivalStatesHint.
  ///
  /// In en, this message translates to:
  /// **'What Confirmed, To be checked, Scheduled… mean'**
  String get arrivalStatesHint;

  /// No description provided for @stateConfirmedMeaning.
  ///
  /// In en, this message translates to:
  /// **'A vehicle located a moment ago and moving is on this trip.'**
  String get stateConfirmedMeaning;

  /// No description provided for @stateUncertainMeaning.
  ///
  /// In en, this message translates to:
  /// **'There is a prediction, but something makes it doubtful: the reason is always written.'**
  String get stateUncertainMeaning;

  /// No description provided for @stateScheduledMeaning.
  ///
  /// In en, this message translates to:
  /// **'No realtime data for this trip: only the scheduled time, never minutes.'**
  String get stateScheduledMeaning;

  /// No description provided for @stateSuppressedMeaning.
  ///
  /// In en, this message translates to:
  /// **'The vehicle disappeared before completing the trip: it stays visible for 5 minutes.'**
  String get stateSuppressedMeaning;

  /// No description provided for @stateCanceledMeaning.
  ///
  /// In en, this message translates to:
  /// **'The operator canceled the trip.'**
  String get stateCanceledMeaning;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get dataSource;

  /// No description provided for @dataSourceBody.
  ///
  /// In en, this message translates to:
  /// **'Open data by Roma Servizi per la Mobilità (GTFS and GTFS-Realtime). This app is not affiliated with Atac or RSM.'**
  String get dataSourceBody;

  /// No description provided for @dataDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Data come from automatic equipment and are not exhaustive: road conditions and malfunctions can make them inaccurate.'**
  String get dataDisclaimer;

  /// No description provided for @variantStops.
  ///
  /// In en, this message translates to:
  /// **'Served only by some trips'**
  String get variantStops;

  /// No description provided for @routeTravelled.
  ///
  /// In en, this message translates to:
  /// **'Already travelled'**
  String get routeTravelled;

  /// No description provided for @routeAhead.
  ///
  /// In en, this message translates to:
  /// **'Still to go'**
  String get routeAhead;

  /// No description provided for @nextStopName.
  ///
  /// In en, this message translates to:
  /// **'Next stop: {stop}'**
  String nextStopName(String stop);

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {label}'**
  String vehicleNumber(String label);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @followedTrips.
  ///
  /// In en, this message translates to:
  /// **'Followed trips'**
  String get followedTrips;

  /// No description provided for @followTrip.
  ///
  /// In en, this message translates to:
  /// **'Follow this trip'**
  String get followTrip;

  /// No description provided for @followTripHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a time to be notified when that bus is about to pass.'**
  String get followTripHint;

  /// No description provided for @followDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get followDays;

  /// No description provided for @followLeads.
  ///
  /// In en, this message translates to:
  /// **'Notify me before'**
  String get followLeads;

  /// No description provided for @followLeadsHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {n} notices'**
  String followLeadsHint(int n);

  /// No description provided for @followLeadsSummary.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String followLeadsSummary(String minutes);

  /// No description provided for @followEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notices on'**
  String get followEnabled;

  /// No description provided for @followRemove.
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get followRemove;

  /// No description provided for @followRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop following this trip?'**
  String get followRemoveTitle;

  /// No description provided for @followRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be notified about it.'**
  String get followRemoveBody;

  /// No description provided for @followSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip followed'**
  String get followSaved;

  /// No description provided for @followedMarker.
  ///
  /// In en, this message translates to:
  /// **'Followed trip'**
  String get followedMarker;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri'**
  String get weekdays;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Sat, Sun'**
  String get weekend;

  /// No description provided for @noFollows.
  ///
  /// In en, this message translates to:
  /// **'No followed trips'**
  String get noFollows;

  /// No description provided for @noFollowsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the timetable of a stop and tap the time of the trip you want: you will be notified before it passes.'**
  String get noFollowsHint;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOff;

  /// No description provided for @notificationsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Without notifications you cannot be warned when the bus is about to pass.'**
  String get notificationsOffBody;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications on for this app in the phone settings.'**
  String get notificationsBlocked;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device cannot receive notifications.'**
  String get notificationsUnavailable;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get enableNotifications;

  /// No description provided for @noticeChannelName.
  ///
  /// In en, this message translates to:
  /// **'Followed trips'**
  String get noticeChannelName;

  /// No description provided for @noticeChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Your bus is about to pass, or something happened to it'**
  String get noticeChannelDescription;

  /// No description provided for @errorFollowLimit.
  ///
  /// In en, this message translates to:
  /// **'You can follow at most 30 trips. Remove one first.'**
  String get errorFollowLimit;

  /// No description provided for @pushLead.
  ///
  /// In en, this message translates to:
  /// **'Line {route}: in {minutes} min'**
  String pushLead(String route, int minutes);

  /// No description provided for @pushArriving.
  ///
  /// In en, this message translates to:
  /// **'Line {route}: is arriving'**
  String pushArriving(String route);

  /// No description provided for @pushScheduled.
  ///
  /// In en, this message translates to:
  /// **'scheduled time'**
  String get pushScheduled;

  /// No description provided for @pushStopTo.
  ///
  /// In en, this message translates to:
  /// **'{stop} to {headsign}'**
  String pushStopTo(String stop, String headsign);

  /// No description provided for @pushCanceledTitle.
  ///
  /// In en, this message translates to:
  /// **'Line {route}: trip canceled'**
  String pushCanceledTitle(String route);

  /// No description provided for @pushCanceledBody.
  ///
  /// In en, this message translates to:
  /// **'The {time} at {place} was canceled'**
  String pushCanceledBody(String time, String place);

  /// No description provided for @pushStillTitle.
  ///
  /// In en, this message translates to:
  /// **'Line {route}: bus standing still for {minutes} min'**
  String pushStillTitle(String route, int minutes);

  /// No description provided for @pushStillBody.
  ///
  /// In en, this message translates to:
  /// **'The {time} at {place}'**
  String pushStillBody(String time, String place);

  /// No description provided for @pushLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Line {route}: signal lost'**
  String pushLostTitle(String route);

  /// No description provided for @pushLostBody.
  ///
  /// In en, this message translates to:
  /// **'The vehicle of the {time} at {place} stopped transmitting: it may not arrive'**
  String pushLostBody(String time, String place);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Due at {time}, it may still come'**
  String overdue(String time);

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on the map'**
  String get showOnMap;

  /// No description provided for @editFollow.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editFollow;

  /// No description provided for @tripAt.
  ///
  /// In en, this message translates to:
  /// **'{time} trip at {stop}'**
  String tripAt(String time, String stop);

  /// No description provided for @tripHistoryWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Recent weekdays'**
  String get tripHistoryWeekdays;

  /// No description provided for @tripHistoryWeekend.
  ///
  /// In en, this message translates to:
  /// **'Recent weekends'**
  String get tripHistoryWeekend;

  /// No description provided for @tripHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet: the history fills up day by day.'**
  String get tripHistoryEmpty;

  /// No description provided for @tripUsuallyOnTime.
  ///
  /// In en, this message translates to:
  /// **'Usually on time'**
  String get tripUsuallyOnTime;

  /// No description provided for @tripUsuallyLate.
  ///
  /// In en, this message translates to:
  /// **'Usually about {n} min late'**
  String tripUsuallyLate(int n);

  /// No description provided for @tripUsuallyEarly.
  ///
  /// In en, this message translates to:
  /// **'Usually about {n} min early'**
  String tripUsuallyEarly(int n);

  /// No description provided for @tripRarelyTracked.
  ///
  /// In en, this message translates to:
  /// **'Rarely tracked: it may pass all the same'**
  String get tripRarelyTracked;

  /// No description provided for @tripOnTimeCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 on time} other{{n} on time}}'**
  String tripOnTimeCount(int n);

  /// No description provided for @tripLateCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 late} other{{n} late}}'**
  String tripLateCount(int n);

  /// No description provided for @tripEarlyCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 early} other{{n} early}}'**
  String tripEarlyCount(int n);

  /// No description provided for @tripNotTrackedCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 not tracked} other{{n} not tracked}}'**
  String tripNotTrackedCount(int n);

  /// No description provided for @tripCanceledCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 canceled} other{{n} canceled}}'**
  String tripCanceledCount(int n);

  /// No description provided for @tripDayNotTracked.
  ///
  /// In en, this message translates to:
  /// **'not tracked'**
  String get tripDayNotTracked;

  /// No description provided for @tripDayCanceled.
  ///
  /// In en, this message translates to:
  /// **'canceled'**
  String get tripDayCanceled;

  /// No description provided for @journeysHomePlace.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get journeysHomePlace;

  /// No description provided for @journeysWhereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get journeysWhereTo;

  /// No description provided for @journeysAlreadyThere.
  ///
  /// In en, this message translates to:
  /// **'You are already there'**
  String get journeysAlreadyThere;

  /// No description provided for @journeysSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Address or place'**
  String get journeysSearchHint;

  /// No description provided for @journeysSearchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search for an address'**
  String get journeysSearchAddress;

  /// No description provided for @journeysSearchNone.
  ///
  /// In en, this message translates to:
  /// **'No address found in Rome'**
  String get journeysSearchNone;

  /// No description provided for @journeysRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get journeysRecent;

  /// No description provided for @journeysSetHome.
  ///
  /// In en, this message translates to:
  /// **'Set home'**
  String get journeysSetHome;

  /// No description provided for @journeysRemoveHome.
  ///
  /// In en, this message translates to:
  /// **'Remove home'**
  String get journeysRemoveHome;

  /// No description provided for @journeysHomeSaved.
  ///
  /// In en, this message translates to:
  /// **'Home saved'**
  String get journeysHomeSaved;

  /// No description provided for @journeysNoHomeHint.
  ///
  /// In en, this message translates to:
  /// **'Set it once and Veribus tells you which bus to take to get back, from wherever you are. Or search for any destination above.'**
  String get journeysNoHomeHint;

  /// No description provided for @journeysNeedPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position is needed to plan the journey'**
  String get journeysNeedPosition;

  /// No description provided for @journeysAtHome.
  ///
  /// In en, this message translates to:
  /// **'You are already home'**
  String get journeysAtHome;

  /// No description provided for @journeysNone.
  ///
  /// In en, this message translates to:
  /// **'No journey with at most two changes'**
  String get journeysNone;

  /// No description provided for @journeysNoneHint.
  ///
  /// In en, this message translates to:
  /// **'At this hour the network may not get there. The last journey of the night, when there is one, is shown at the top.'**
  String get journeysNoneHint;

  /// No description provided for @journeysUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Journeys are not available for today'**
  String get journeysUnavailable;

  /// No description provided for @journeysUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'The timetable for the planner has not been published yet. Arrivals at the stops still work.'**
  String get journeysUnavailableHint;

  /// No description provided for @journeysOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get journeysOpenGoogleMaps;

  /// No description provided for @journeysDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get journeysDirect;

  /// No description provided for @journeysChanges.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 change} other{{n} changes}}'**
  String journeysChanges(int n);

  /// No description provided for @journeysWalkOnly.
  ///
  /// In en, this message translates to:
  /// **'On foot'**
  String get journeysWalkOnly;

  /// No description provided for @journeysTimes.
  ///
  /// In en, this message translates to:
  /// **'{depart} → {arrive}'**
  String journeysTimes(String depart, String arrive);

  /// No description provided for @journeysFrom.
  ///
  /// In en, this message translates to:
  /// **'from {stop}'**
  String journeysFrom(String stop);

  /// No description provided for @journeysStops.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 stop} other{{n} stops}}'**
  String journeysStops(int n);

  /// No description provided for @journeysArriveHome.
  ///
  /// In en, this message translates to:
  /// **'Home around {time}'**
  String journeysArriveHome(String time);

  /// No description provided for @journeysArriveDestination.
  ///
  /// In en, this message translates to:
  /// **'There around {time}'**
  String journeysArriveDestination(String time);

  /// No description provided for @journeysIfMissed.
  ///
  /// In en, this message translates to:
  /// **'If you miss it: next {line} at {time}'**
  String journeysIfMissed(String line, String time);

  /// No description provided for @journeysIfMissedNone.
  ///
  /// In en, this message translates to:
  /// **'If you miss it there is no other {line} tonight'**
  String journeysIfMissedNone(String line);

  /// No description provided for @journeysLast.
  ///
  /// In en, this message translates to:
  /// **'Last journey: leave by {time}'**
  String journeysLast(String time);

  /// No description provided for @journeysLastHint.
  ///
  /// In en, this message translates to:
  /// **'After that there is no journey with at most two changes.'**
  String get journeysLastHint;

  /// No description provided for @journeysChangeRecord.
  ///
  /// In en, this message translates to:
  /// **'This change worked {made} times out of {days}'**
  String journeysChangeRecord(int made, int days);

  /// No description provided for @journeysChangeNoRecord.
  ///
  /// In en, this message translates to:
  /// **'No history for this change yet'**
  String get journeysChangeNoRecord;

  /// No description provided for @journeysLongWait.
  ///
  /// In en, this message translates to:
  /// **'A long wait'**
  String get journeysLongWait;

  /// No description provided for @journeysMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro {line}'**
  String journeysMetro(String line);

  /// No description provided for @journeysNote.
  ///
  /// In en, this message translates to:
  /// **'Walking from you to the first stop and from the last stop to the destination is estimated as the crow flies. Beyond the next hour, times are the scheduled ones.'**
  String get journeysNote;

  /// No description provided for @journeysDetails.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journeysDetails;

  /// No description provided for @journeysGone.
  ///
  /// In en, this message translates to:
  /// **'This journey is no longer available: go back to the list.'**
  String get journeysGone;

  /// No description provided for @journeysYourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get journeysYourPosition;

  /// No description provided for @journeysSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap start and destination'**
  String get journeysSwap;

  /// No description provided for @journeysNow.
  ///
  /// In en, this message translates to:
  /// **'Leave now'**
  String get journeysNow;

  /// No description provided for @journeysDepartAt.
  ///
  /// In en, this message translates to:
  /// **'Leave at {time}'**
  String journeysDepartAt(String time);

  /// No description provided for @journeysOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get journeysOptions;

  /// No description provided for @journeysOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'When and how'**
  String get journeysOptionsTitle;

  /// No description provided for @journeysToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get journeysToday;

  /// No description provided for @journeysTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get journeysTomorrow;

  /// No description provided for @journeysUseMetro.
  ///
  /// In en, this message translates to:
  /// **'Use the metro'**
  String get journeysUseMetro;

  /// No description provided for @journeysUseNight.
  ///
  /// In en, this message translates to:
  /// **'Include night buses'**
  String get journeysUseNight;

  /// No description provided for @journeysReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get journeysReset;

  /// No description provided for @journeysShow.
  ///
  /// In en, this message translates to:
  /// **'Show journeys'**
  String get journeysShow;

  /// No description provided for @journeysWalkTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min on foot'**
  String journeysWalkTotal(int minutes);

  /// No description provided for @journeysDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String journeysDurationHm(int hours, int minutes);

  /// No description provided for @journeysRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get journeysRemind;

  /// No description provided for @journeysWalkMinutes.
  ///
  /// In en, this message translates to:
  /// **'Walk {minutes} min'**
  String journeysWalkMinutes(int minutes);

  /// No description provided for @journeysGetOff.
  ///
  /// In en, this message translates to:
  /// **'get off'**
  String get journeysGetOff;

  /// No description provided for @journeysChangeAt.
  ///
  /// In en, this message translates to:
  /// **'Change at {stop}'**
  String journeysChangeAt(String stop);

  /// No description provided for @journeysChangeTimes.
  ///
  /// In en, this message translates to:
  /// **'{walk} min on foot · {wait} min wait'**
  String journeysChangeTimes(int walk, int wait);

  /// No description provided for @journeysStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get journeysStart;

  /// No description provided for @journeysIntermediate.
  ///
  /// In en, this message translates to:
  /// **'{stops} · {minutes} min'**
  String journeysIntermediate(String stops, int minutes);

  /// No description provided for @journeysInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String journeysInMinutes(int minutes);

  /// No description provided for @journeysLeaveAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave at'**
  String get journeysLeaveAtLabel;

  /// No description provided for @journeysWorkPlace.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get journeysWorkPlace;

  /// No description provided for @journeysSetWork.
  ///
  /// In en, this message translates to:
  /// **'Set work'**
  String get journeysSetWork;

  /// No description provided for @journeysPlacesSection.
  ///
  /// In en, this message translates to:
  /// **'Addresses and places'**
  String get journeysPlacesSection;

  /// No description provided for @journeysStopsSection.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get journeysStopsSection;

  /// No description provided for @journeysFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get journeysFromLabel;

  /// No description provided for @journeysToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get journeysToLabel;

  /// No description provided for @journeysSavedSection.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get journeysSavedSection;

  /// No description provided for @journeysSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get journeysSaveAs;

  /// No description provided for @journeysSaveHome.
  ///
  /// In en, this message translates to:
  /// **'Save home'**
  String get journeysSaveHome;

  /// No description provided for @journeysSaveWork.
  ///
  /// In en, this message translates to:
  /// **'Save work'**
  String get journeysSaveWork;

  /// No description provided for @journeysSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the map if the pin is not on the door. It is saved only on this phone.'**
  String get journeysSaveHint;

  /// No description provided for @journeysWorkSaved.
  ///
  /// In en, this message translates to:
  /// **'Work saved'**
  String get journeysWorkSaved;

  /// No description provided for @journeysRemoveWork.
  ///
  /// In en, this message translates to:
  /// **'Remove work'**
  String get journeysRemoveWork;

  /// No description provided for @journeysPinPlace.
  ///
  /// In en, this message translates to:
  /// **'Place on the map'**
  String get journeysPinPlace;

  /// No description provided for @exploreNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get exploreNearYou;

  /// No description provided for @exploreWalk.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min on foot · {meters} m'**
  String exploreWalk(int minutes, int meters);

  /// No description provided for @exploreAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exploreAll;

  /// No description provided for @exploreBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get exploreBus;

  /// No description provided for @exploreTram.
  ///
  /// In en, this message translates to:
  /// **'Tram'**
  String get exploreTram;

  /// No description provided for @exploreProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get exploreProfile;

  /// No description provided for @linesBus.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get linesBus;

  /// No description provided for @linesTram.
  ///
  /// In en, this message translates to:
  /// **'Trams'**
  String get linesTram;

  /// No description provided for @linesNight.
  ///
  /// In en, this message translates to:
  /// **'Night buses'**
  String get linesNight;

  /// No description provided for @linesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a line or a stop'**
  String get linesSearchHint;

  /// No description provided for @lineYourStop.
  ///
  /// In en, this message translates to:
  /// **'Your stop'**
  String get lineYourStop;

  /// No description provided for @stopDirectionsHere.
  ///
  /// In en, this message translates to:
  /// **'Directions here'**
  String get stopDirectionsHere;

  /// No description provided for @tripWalkTo.
  ///
  /// In en, this message translates to:
  /// **'Walk to {place}'**
  String tripWalkTo(String place);

  /// No description provided for @tripDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters} m · {minutes} min'**
  String tripDistance(int meters, int minutes);

  /// No description provided for @tripYourLine.
  ///
  /// In en, this message translates to:
  /// **'Your {line} comes {when}'**
  String tripYourLine(String line, String when);

  /// No description provided for @tripBoard.
  ///
  /// In en, this message translates to:
  /// **'Get on the {line}'**
  String tripBoard(String line);

  /// No description provided for @tripWaitHere.
  ///
  /// In en, this message translates to:
  /// **'{headsign}, arriving here'**
  String tripWaitHere(String headsign);

  /// No description provided for @tripGetOffIn.
  ///
  /// In en, this message translates to:
  /// **'Get off in {n, plural, =1{1 stop} other{{n} stops}}'**
  String tripGetOffIn(int n);

  /// No description provided for @tripGetOffNext.
  ///
  /// In en, this message translates to:
  /// **'Get off at the next stop'**
  String get tripGetOffNext;

  /// No description provided for @tripGetOffAt.
  ///
  /// In en, this message translates to:
  /// **'at {stop} · {time}'**
  String tripGetOffAt(String stop, String time);

  /// No description provided for @tripThenNoWalk.
  ///
  /// In en, this message translates to:
  /// **'Then {line} at {time}'**
  String tripThenNoWalk(String line, String time);

  /// No description provided for @tripArrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived'**
  String get tripArrived;

  /// No description provided for @tripEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get tripEnd;

  /// No description provided for @tripAllSteps.
  ///
  /// In en, this message translates to:
  /// **'All steps'**
  String get tripAllSteps;

  /// No description provided for @tripAlertHint.
  ///
  /// In en, this message translates to:
  /// **'The phone vibrates one stop before, with the screen on.'**
  String get tripAlertHint;

  /// No description provided for @tripAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Get off at the next stop'**
  String get tripAlertTitle;

  /// No description provided for @tripNeedPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position is needed to follow you step by step'**
  String get tripNeedPosition;

  /// No description provided for @tripAtTime.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String tripAtTime(String time);

  /// No description provided for @tripChannelName.
  ///
  /// In en, this message translates to:
  /// **'Journey in progress'**
  String get tripChannelName;

  /// No description provided for @tripShowMap.
  ///
  /// In en, this message translates to:
  /// **'Show the map'**
  String get tripShowMap;

  /// No description provided for @tripShowList.
  ///
  /// In en, this message translates to:
  /// **'Show the stops'**
  String get tripShowList;

  /// No description provided for @exploreMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get exploreMetro;

  /// No description provided for @metroEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min or so now'**
  String metroEvery(int minutes);

  /// No description provided for @metroNoTrains.
  ///
  /// In en, this message translates to:
  /// **'No trains in the next hour'**
  String get metroNoTrains;

  /// No description provided for @metroScheduled.
  ///
  /// In en, this message translates to:
  /// **'From the timetable, not in real time.'**
  String get metroScheduled;

  /// No description provided for @metroNoneNearby.
  ///
  /// In en, this message translates to:
  /// **'No metro station nearby'**
  String get metroNoneNearby;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
