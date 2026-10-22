// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get account => 'Account';

  @override
  String get appTitle => 'Veribus';

  @override
  String get appearance => 'Appearance';

  @override
  String get cancel => 'Cancel';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get createAccount => 'Create account';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Your account and all its data will be permanently deleted. This cannot be undone.';

  @override
  String get deleteAccountDescription => 'Permanently delete your account and all its data.';

  @override
  String get email => 'Email';

  @override
  String get errorCancelled => 'Operation cancelled.';

  @override
  String get errorEmailNotConfirmed => 'Confirm your email with the link we sent you, then sign in.';

  @override
  String get errorEmailInUse => 'An account with this email already exists.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorNotSupported => 'Not available on this device.';

  @override
  String get errorRequiresRecentLogin => 'For security, sign in again and retry.';

  @override
  String get errorServer => 'The server could not complete the request.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorUnauthorized => 'Your session has expired. Please sign in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorWeakPassword => 'The password is too weak.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get fullName => 'Full name';

  @override
  String get goHome => 'Go to home';

  @override
  String get language => 'Language';

  @override
  String get licenses => 'Open source licenses';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get logs => 'Logs';

  @override
  String get newPassword => 'New password';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get offline => 'You\'re offline';

  @override
  String get orContinueWith => 'or';

  @override
  String get pageNotFound => 'Page not found.';

  @override
  String get password => 'Password';

  @override
  String get passwordUpdated => 'Password updated. You can now sign in.';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get profile => 'Profile';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get resetEmailSent => 'If the email exists, we sent you a reset link.';

  @override
  String get resetPasswordTitle => 'Choose a new password';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get savePassword => 'Save password';

  @override
  String get saved => 'Saved';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get settings => 'Settings';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Do you want to sign out?';

  @override
  String get support => 'Support';

  @override
  String get systemDefault => 'System';

  @override
  String get terms => 'Terms of service';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get update => 'Update';

  @override
  String get updateRequired => 'A new version is required to continue.';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'At least 8 characters, with a letter and a number';

  @override
  String get validationPasswordsMatch => 'Passwords don\'t match';

  @override
  String get validationRequired => 'Required';

  @override
  String get version => 'Version';

  @override
  String get appUpdates => 'App updates';

  @override
  String get appUpdatesBody => 'Download the latest version from the GitHub releases';

  @override
  String get nearby => 'Explore';

  @override
  String get search => 'Lines';

  @override
  String get favorites => 'Favorites';

  @override
  String get alerts => 'Alerts';

  @override
  String get mapView => 'Map';

  @override
  String get listView => 'List';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get allLines => 'All';

  @override
  String get line => 'Line';

  @override
  String get stop => 'Stop';

  @override
  String get lines => 'Lines';

  @override
  String get stops => 'Stops';

  @override
  String lineDetail(String name) {
    return 'Line $name';
  }

  @override
  String stopCode(String code) {
    return 'stop $code';
  }

  @override
  String get stopNotServed => 'This stop is no longer served.';

  @override
  String get lineNotServed => 'This line is not in service.';

  @override
  String get notServedAnymore => 'No longer served';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String around(String time) {
    return 'around $time';
  }

  @override
  String get arriving => 'arriving';

  @override
  String stopsAway(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops away',
      one: '1 stop away',
      zero: 'at the stop',
    );
    return '$_temp0';
  }

  @override
  String approximateTime(int n) {
    return 'in about $n min, approximate time';
  }

  @override
  String vehicle(String label) {
    return 'vehicle $label';
  }

  @override
  String get noRealtimeData => 'no realtime data';

  @override
  String get lineWithoutRealtime => 'this line does not transmit its position';

  @override
  String get withoutRealtime => 'No realtime, scheduled times only';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusUncertain => 'To be checked';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusSuppressed => 'Suppressed';

  @override
  String get signalCanceled => 'Trip canceled';

  @override
  String signalNotTransmitting(int n) {
    return 'The vehicle has not transmitted for $n min';
  }

  @override
  String get signalNoVehicle => 'No vehicle located';

  @override
  String signalStill(int n) {
    return 'Vehicle stopped for $n min';
  }

  @override
  String signalOldGps(int n) {
    return 'Last GPS signal $n min ago';
  }

  @override
  String signalAtTerminus(String time) {
    return 'Leaves the terminus at $time';
  }

  @override
  String get signalAtTerminusNoTime => 'Still at the terminus';

  @override
  String get signalLateData => 'Realtime data delayed';

  @override
  String get realtimeUnavailable => 'Realtime unavailable: showing scheduled times';

  @override
  String get noArrivals => 'No arrivals in the next 60 minutes';

  @override
  String updatedAgo(int s) {
    return 'updated $s s ago';
  }

  @override
  String get timetable => 'Today\'s timetable';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get scheduledTimesNote => 'Scheduled times: they do not take traffic into account.';

  @override
  String get noServiceThisDay => 'No service on this day';

  @override
  String get firstTrip => 'first';

  @override
  String get lastTrip => 'last';

  @override
  String lastPositionAt(String time) {
    return 'last known position at $time';
  }

  @override
  String get terminus => 'terminus';

  @override
  String get noTripsInService => 'No trips in service';

  @override
  String nextDeparture(String time) {
    return 'Next departure at $time';
  }

  @override
  String vehiclesInService(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vehicles in service',
      one: '1 vehicle in service',
      zero: 'No vehicles in service',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Line or stop code';

  @override
  String get searchEmpty => 'Search runs on your phone: results show up as you type.';

  @override
  String get searchNoResults => 'No results. Check the code written on the stop pole.';

  @override
  String get locationDenied => 'Turn on location to see nearby stops';

  @override
  String get locationDeniedList => 'Without your position the list is empty: use Search to find a stop.';

  @override
  String get enableLocation => 'Turn on';

  @override
  String get you => 'You are here';

  @override
  String get backToMyPosition => 'Back to my position';

  @override
  String get zoomInForStops => 'Zoom in to see the stops';

  @override
  String get noStopsNearby => 'No stops within 1 km';

  @override
  String get nearbyNote => 'Stops within 500 m, sorted by distance. If there are none, the radius grows to 1 km.';

  @override
  String meters(int n) {
    return '$n m';
  }

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesHint => 'Tap the star on a stop or a line: the app will open here.';

  @override
  String get noAlerts => 'No active alerts';

  @override
  String alertsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n alerts', one: '1 alert');
    return '$_temp0';
  }

  @override
  String get arrivalStates => 'Arrival states';

  @override
  String get arrivalStatesHint => 'What Confirmed, To be checked, Scheduled… mean';

  @override
  String get stateConfirmedMeaning => 'A vehicle located a moment ago and moving is on this trip.';

  @override
  String get stateUncertainMeaning =>
      'There is a prediction, but something makes it doubtful: the reason is always written.';

  @override
  String get stateScheduledMeaning => 'No realtime data for this trip: only the scheduled time, never minutes.';

  @override
  String get stateSuppressedMeaning =>
      'The vehicle disappeared before completing the trip: it stays visible for 5 minutes.';

  @override
  String get stateCanceledMeaning => 'The operator canceled the trip.';

  @override
  String get dataSource => 'Data source';

  @override
  String get dataSourceBody =>
      'Open data by Roma Servizi per la Mobilità (GTFS and GTFS-Realtime). This app is not affiliated with Atac or RSM.';

  @override
  String get dataDisclaimer =>
      'Data come from automatic equipment and are not exhaustive: road conditions and malfunctions can make them inaccurate.';

  @override
  String get variantStops => 'Served only by some trips';

  @override
  String get routeTravelled => 'Already travelled';

  @override
  String get routeAhead => 'Still to go';

  @override
  String nextStopName(String stop) {
    return 'Next stop: $stop';
  }

  @override
  String vehicleNumber(String label) {
    return 'Vehicle $label';
  }

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get followedTrips => 'Followed trips';

  @override
  String get followTrip => 'Follow this trip';

  @override
  String get followTripHint => 'Tap a time to be notified when that bus is about to pass.';

  @override
  String get followDays => 'Days';

  @override
  String get followLeads => 'Notify me before';

  @override
  String followLeadsHint(int n) {
    return 'Up to $n notices';
  }

  @override
  String followLeadsSummary(String minutes) {
    return '$minutes min before';
  }

  @override
  String get followEnabled => 'Notices on';

  @override
  String get followRemove => 'Stop following';

  @override
  String get followRemoveTitle => 'Stop following this trip?';

  @override
  String get followRemoveBody => 'You will no longer be notified about it.';

  @override
  String get followSaved => 'Trip followed';

  @override
  String get followedMarker => 'Followed trip';

  @override
  String get everyDay => 'Every day';

  @override
  String get weekdays => 'Mon–Fri';

  @override
  String get weekend => 'Sat, Sun';

  @override
  String get noFollows => 'No followed trips';

  @override
  String get noFollowsHint =>
      'Open the timetable of a stop and tap the time of the trip you want: you will be notified before it passes.';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get notificationsOffBody => 'Without notifications you cannot be warned when the bus is about to pass.';

  @override
  String get notificationsBlocked => 'Turn notifications on for this app in the phone settings.';

  @override
  String get notificationsUnavailable => 'This device cannot receive notifications.';

  @override
  String get enableNotifications => 'Turn on';

  @override
  String get noticeChannelName => 'Followed trips';

  @override
  String get noticeChannelDescription => 'Your bus is about to pass, or something happened to it';

  @override
  String get errorFollowLimit => 'You can follow at most 30 trips. Remove one first.';

  @override
  String pushLead(String route, int minutes) {
    return 'Line $route: in $minutes min';
  }

  @override
  String pushArriving(String route) {
    return 'Line $route: is arriving';
  }

  @override
  String get pushScheduled => 'scheduled time';

  @override
  String pushStopTo(String stop, String headsign) {
    return '$stop to $headsign';
  }

  @override
  String pushCanceledTitle(String route) {
    return 'Line $route: trip canceled';
  }

  @override
  String pushCanceledBody(String time, String place) {
    return 'The $time at $place was canceled';
  }

  @override
  String pushStillTitle(String route, int minutes) {
    return 'Line $route: bus standing still for $minutes min';
  }

  @override
  String pushStillBody(String time, String place) {
    return 'The $time at $place';
  }

  @override
  String pushLostTitle(String route) {
    return 'Line $route: signal lost';
  }

  @override
  String pushLostBody(String time, String place) {
    return 'The vehicle of the $time at $place stopped transmitting: it may not arrive';
  }

  @override
  String overdue(String time) {
    return 'Due at $time, it may still come';
  }

  @override
  String get showOnMap => 'Show on the map';

  @override
  String get editFollow => 'Edit';

  @override
  String tripAt(String time, String stop) {
    return '$time trip at $stop';
  }

  @override
  String get tripHistoryWeekdays => 'Recent weekdays';

  @override
  String get tripHistoryWeekend => 'Recent weekends';

  @override
  String get tripHistoryEmpty => 'No data yet: the history fills up day by day.';

  @override
  String get tripUsuallyOnTime => 'Usually on time';

  @override
  String tripUsuallyLate(int n) {
    return 'Usually about $n min late';
  }

  @override
  String tripUsuallyEarly(int n) {
    return 'Usually about $n min early';
  }

  @override
  String get tripRarelyTracked => 'Rarely tracked: it may pass all the same';

  @override
  String tripOnTimeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n on time', one: '1 on time');
    return '$_temp0';
  }

  @override
  String tripLateCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n late', one: '1 late');
    return '$_temp0';
  }

  @override
  String tripEarlyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n early', one: '1 early');
    return '$_temp0';
  }

  @override
  String tripNotTrackedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n not tracked', one: '1 not tracked');
    return '$_temp0';
  }

  @override
  String tripCanceledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n canceled', one: '1 canceled');
    return '$_temp0';
  }

  @override
  String get tripDayNotTracked => 'not tracked';

  @override
  String get tripDayCanceled => 'canceled';

  @override
  String get journeysTitle => 'Journeys';

  @override
  String get journeysHomePlace => 'Home';

  @override
  String get journeysWhereTo => 'Where to?';

  @override
  String get journeysChangeDestination => 'Change';

  @override
  String get journeysAlreadyThere => 'You are already there';

  @override
  String get journeysSearchHint => 'Address or place';

  @override
  String get journeysSearchAddress => 'Search for an address';

  @override
  String get journeysSearchEmpty => 'Type an address or the name of a place';

  @override
  String get journeysSearchNone => 'No address found in Rome';

  @override
  String get journeysRecent => 'Recent';

  @override
  String get journeysSetHome => 'Set home';

  @override
  String get journeysChangeHome => 'Change home';

  @override
  String get journeysHomeTitle => 'Where is home?';

  @override
  String get journeysHomeHint =>
      'Search for the address, or move the map until the pin is on your home. It is saved only on this phone.';

  @override
  String get journeysRemoveHome => 'Remove home';

  @override
  String get journeysHomeSaved => 'Home saved';

  @override
  String get journeysNoHome => 'You have not set your home yet';

  @override
  String get journeysNoHomeHint =>
      'Set it once and Veribus tells you which bus to take to get back, from wherever you are. Or search for any destination above.';

  @override
  String get journeysNeedPosition => 'Your position is needed to plan the journey';

  @override
  String get journeysAtHome => 'You are already home';

  @override
  String get journeysNone => 'No journey with at most two changes';

  @override
  String get journeysNoneHint =>
      'At this hour the network may not get there. The last journey of the night, when there is one, is shown at the top.';

  @override
  String get journeysUnavailable => 'Journeys are not available for today';

  @override
  String get journeysUnavailableHint =>
      'The timetable for the planner has not been published yet. Arrivals at the stops still work.';

  @override
  String get journeysOpenGoogleMaps => 'Open in Google Maps';

  @override
  String get journeysDirect => 'Direct';

  @override
  String journeysChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n changes', one: '1 change');
    return '$_temp0';
  }

  @override
  String get journeysWalkOnly => 'On foot';

  @override
  String journeysTimes(String depart, String arrive) {
    return '$depart → $arrive';
  }

  @override
  String journeysFrom(String stop) {
    return 'from $stop';
  }

  @override
  String journeysLeaveAt(String time) {
    return 'Leave at $time';
  }

  @override
  String journeysWalkToStop(int minutes, String stop) {
    return 'Walk $minutes min to $stop';
  }

  @override
  String journeysWalkHome(int minutes) {
    return 'Walk $minutes min home';
  }

  @override
  String journeysWalkToDestination(int minutes) {
    return 'Walk $minutes min to the destination';
  }

  @override
  String journeysWalkBetween(int minutes, String stop) {
    return 'Walk $minutes min to $stop';
  }

  @override
  String journeysBoard(String stop, String time) {
    return 'Get on at $stop, $time';
  }

  @override
  String journeysAlight(String stop, String time, String stops) {
    return 'Get off at $stop, $time · $stops';
  }

  @override
  String journeysStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n stops', one: '1 stop');
    return '$_temp0';
  }

  @override
  String journeysWait(int minutes) {
    return 'Wait $minutes min';
  }

  @override
  String journeysArriveHome(String time) {
    return 'Home around $time';
  }

  @override
  String journeysArriveDestination(String time) {
    return 'There around $time';
  }

  @override
  String journeysIfMissed(String line, String time) {
    return 'If you miss it: next $line at $time';
  }

  @override
  String journeysIfMissedNone(String line) {
    return 'If you miss it there is no other $line tonight';
  }

  @override
  String journeysLast(String time) {
    return 'Last journey: leave by $time';
  }

  @override
  String get journeysLastHint => 'After that there is no journey with at most two changes.';

  @override
  String journeysChangeRecord(int made, int days) {
    return 'This change worked $made times out of $days';
  }

  @override
  String get journeysChangeNoRecord => 'No history for this change yet';

  @override
  String get journeysLongWait => 'A long wait';

  @override
  String journeysMetro(String line) {
    return 'Metro $line';
  }

  @override
  String get journeysNote =>
      'Walking from you to the first stop and from the last stop to the destination is estimated as the crow flies. Beyond the next hour, times are the scheduled ones.';

  @override
  String get journeysDetails => 'Journey';

  @override
  String get journeysGone => 'This journey is no longer available: go back to the list.';

  @override
  String get journeysYourPosition => 'Your location';

  @override
  String get journeysSwap => 'Swap start and destination';

  @override
  String get journeysNow => 'Leave now';

  @override
  String journeysDepartAt(String time) {
    return 'Leave at $time';
  }

  @override
  String get journeysOptions => 'Options';

  @override
  String get journeysOptionsTitle => 'When and how';

  @override
  String get journeysWhen => 'When';

  @override
  String get journeysDay => 'Day';

  @override
  String get journeysTime => 'Time';

  @override
  String get journeysToday => 'Today';

  @override
  String get journeysTomorrow => 'Tomorrow';

  @override
  String get journeysUseMetro => 'Use the metro';

  @override
  String get journeysUseNight => 'Include night buses';

  @override
  String get journeysReset => 'Reset';

  @override
  String get journeysShow => 'Show journeys';

  @override
  String journeysWalkTotal(int minutes) {
    return '$minutes min on foot';
  }

  @override
  String journeysDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get journeysRemind => 'Remind me';

  @override
  String journeysWalkMinutes(int minutes) {
    return 'Walk $minutes min';
  }

  @override
  String get journeysGetOff => 'get off';

  @override
  String journeysChangeAt(String stop) {
    return 'Change at $stop';
  }

  @override
  String journeysChangeTimes(int walk, int wait) {
    return '$walk min on foot · $wait min wait';
  }

  @override
  String get journeysStart => 'Start';

  @override
  String journeysIntermediate(String stops, int minutes) {
    return '$stops · $minutes min';
  }

  @override
  String journeysStartFrom(String line, String when, String stop) {
    return '$line $when from $stop';
  }

  @override
  String journeysInMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String get journeysLeaveAtLabel => 'Leave at';

  @override
  String get journeysWorkPlace => 'Work';

  @override
  String get journeysSetWork => 'Set work';

  @override
  String get journeysPlacesSection => 'Addresses and places';

  @override
  String get journeysStopsSection => 'Stops';

  @override
  String get journeysFromLabel => 'From';

  @override
  String get journeysToLabel => 'To';

  @override
  String get journeysSavedSection => 'Saved places';

  @override
  String get journeysSaveAs => 'Save as';

  @override
  String get journeysSaveHome => 'Save home';

  @override
  String get journeysSaveWork => 'Save work';

  @override
  String get journeysSaveHint => 'Drag the map if the pin is not on the door. It is saved only on this phone.';

  @override
  String get journeysWorkSaved => 'Work saved';

  @override
  String get journeysRemoveWork => 'Remove work';

  @override
  String get journeysPinPlace => 'Place on the map';

  @override
  String get journeysAddPlace => 'Add a place';

  @override
  String get exploreNearYou => 'Near you';

  @override
  String exploreWalk(int minutes, int meters) {
    return '$minutes min on foot · $meters m';
  }

  @override
  String get exploreAll => 'All';

  @override
  String get exploreBus => 'Bus';

  @override
  String get exploreTram => 'Tram';

  @override
  String get exploreProfile => 'Profile and settings';

  @override
  String get linesTitle => 'Lines';

  @override
  String get linesBus => 'Buses';

  @override
  String get linesTram => 'Trams';

  @override
  String get linesNight => 'Night buses';

  @override
  String get linesSearchHint => 'Search for a line or a stop';

  @override
  String get lineYourStop => 'Your stop';

  @override
  String get stopDirectionsHere => 'Directions here';

  @override
  String tripWalkTo(String place) {
    return 'Walk to $place';
  }

  @override
  String tripDistance(int meters, int minutes) {
    return '$meters m · $minutes min';
  }

  @override
  String tripYourLine(String line, String when) {
    return 'Your $line comes $when';
  }

  @override
  String tripBoard(String line) {
    return 'Get on the $line';
  }

  @override
  String tripWaitHere(String headsign) {
    return '$headsign, arriving here';
  }

  @override
  String tripGetOffIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n stops', one: '1 stop');
    return 'Get off in $_temp0';
  }

  @override
  String get tripGetOffNext => 'Get off at the next stop';

  @override
  String tripGetOffAt(String stop, String time) {
    return 'at $stop · $time';
  }

  @override
  String tripChangeAt(String stop) {
    return 'Change at $stop';
  }

  @override
  String tripThen(String line, String time, int walk) {
    return 'Then $line at $time, $walk min on foot';
  }

  @override
  String tripThenNoWalk(String line, String time) {
    return 'Then $line at $time';
  }

  @override
  String get tripArrived => 'You have arrived';

  @override
  String get tripEnd => 'End';

  @override
  String get tripAllSteps => 'All steps';

  @override
  String get tripAlertHint => 'The phone vibrates one stop before, with the screen on.';

  @override
  String get tripAlertTitle => 'Get off at the next stop';

  @override
  String get tripNeedPosition => 'Your position is needed to follow you step by step';

  @override
  String tripRemaining(String stops) {
    return '$stops to go';
  }

  @override
  String get tripNow => 'now';

  @override
  String get tripFollowing => 'Journey in progress';

  @override
  String tripAtTime(String time) {
    return 'at $time';
  }
}
