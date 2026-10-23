// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get about => 'Informazioni';

  @override
  String get account => 'Account';

  @override
  String get appTitle => 'Veribus';

  @override
  String get appearance => 'Aspetto';

  @override
  String get cancel => 'Annulla';

  @override
  String get changePhoto => 'Cambia foto';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get createAccount => 'Crea account';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountConfirm =>
      'Il tuo account e tutti i suoi dati verranno eliminati definitivamente. L\'operazione è irreversibile.';

  @override
  String get deleteAccountDescription => 'Elimina definitivamente il tuo account e tutti i suoi dati.';

  @override
  String get email => 'Email';

  @override
  String get errorCancelled => 'Operazione annullata.';

  @override
  String get errorEmailNotConfirmed => 'Conferma l\'indirizzo email con il link che ti abbiamo inviato, poi accedi.';

  @override
  String get errorEmailInUse => 'Esiste già un account con questa email.';

  @override
  String get errorInvalidCredentials => 'Email o password errati.';

  @override
  String get errorNetwork => 'Nessuna connessione. Controlla la rete e riprova.';

  @override
  String get errorNotSupported => 'Non disponibile su questo dispositivo.';

  @override
  String get errorRequiresRecentLogin => 'Per sicurezza, accedi di nuovo e riprova.';

  @override
  String get errorServer => 'Il server non è riuscito a completare la richiesta.';

  @override
  String get errorTooManyRequests => 'Troppi tentativi. Riprova più tardi.';

  @override
  String get errorUnauthorized => 'La sessione è scaduta. Accedi di nuovo.';

  @override
  String get errorUnknown => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errorWeakPassword => 'La password è troppo debole.';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get forgotPasswordSubtitle => 'Inserisci la tua email e ti invieremo un link per reimpostare la password.';

  @override
  String get forgotPasswordTitle => 'Recupera password';

  @override
  String get fullName => 'Nome e cognome';

  @override
  String get goHome => 'Vai alla home';

  @override
  String get language => 'Lingua';

  @override
  String get licenses => 'Licenze open source';

  @override
  String get loginSubtitle => 'Accedi per continuare';

  @override
  String get loginTitle => 'Bentornato';

  @override
  String get logs => 'Log';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get noAccountRegister => 'Non hai un account? Registrati';

  @override
  String get offline => 'Sei offline';

  @override
  String get orContinueWith => 'oppure';

  @override
  String get pageNotFound => 'Pagina non trovata.';

  @override
  String get password => 'Password';

  @override
  String get passwordUpdated => 'Password aggiornata. Ora puoi accedere.';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get profile => 'Profilo';

  @override
  String get registerTitle => 'Crea il tuo account';

  @override
  String get resetEmailSent => 'Se l\'email esiste, ti abbiamo inviato un link di reset.';

  @override
  String get resetPasswordTitle => 'Scegli una nuova password';

  @override
  String get retry => 'Riprova';

  @override
  String get save => 'Salva';

  @override
  String get savePassword => 'Salva password';

  @override
  String get saved => 'Salvato';

  @override
  String get sendResetLink => 'Invia link';

  @override
  String get settings => 'Impostazioni';

  @override
  String get signIn => 'Accedi';

  @override
  String get signOut => 'Esci';

  @override
  String get signOutConfirm => 'Vuoi uscire dall\'account?';

  @override
  String get support => 'Supporto';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get terms => 'Termini di servizio';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get update => 'Aggiorna';

  @override
  String get updateRequired => 'Per continuare è necessaria una nuova versione.';

  @override
  String get validationEmail => 'Inserisci un\'email valida';

  @override
  String get validationPassword => 'Almeno 8 caratteri, con una lettera e un numero';

  @override
  String get validationPasswordsMatch => 'Le password non coincidono';

  @override
  String get validationRequired => 'Campo obbligatorio';

  @override
  String get version => 'Versione';

  @override
  String get appUpdates => 'Aggiornamenti';

  @override
  String get appUpdatesBody => 'Scarica l\'ultima versione dalle release di GitHub';

  @override
  String get nearby => 'Esplora';

  @override
  String get search => 'Linee';

  @override
  String get favorites => 'Preferiti';

  @override
  String get alerts => 'Avvisi';

  @override
  String get mapView => 'Mappa';

  @override
  String get listView => 'Elenco';

  @override
  String get addFavorite => 'Aggiungi ai preferiti';

  @override
  String get removeFavorite => 'Togli dai preferiti';

  @override
  String get reportProblem => 'Segnala un problema';

  @override
  String get allLines => 'Tutte';

  @override
  String get line => 'Linea';

  @override
  String get stop => 'Fermata';

  @override
  String get lines => 'Linee';

  @override
  String get stops => 'Fermate';

  @override
  String lineDetail(String name) {
    return 'Linea $name';
  }

  @override
  String stopCode(String code) {
    return 'palina $code';
  }

  @override
  String get stopNotServed => 'Questa fermata non è più servita.';

  @override
  String get lineNotServed => 'Questa linea non è in servizio.';

  @override
  String get notServedAnymore => 'Non più servito';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String around(String time) {
    return 'verso le $time';
  }

  @override
  String get arriving => 'in arrivo';

  @override
  String stopsAway(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'a $n fermate',
      one: 'a 1 fermata',
      zero: 'alla fermata',
    );
    return '$_temp0';
  }

  @override
  String approximateTime(int n) {
    return 'tra circa $n min, orario approssimato';
  }

  @override
  String vehicle(String label) {
    return 'vettura $label';
  }

  @override
  String get noRealtimeData => 'nessun dato in tempo reale';

  @override
  String get lineWithoutRealtime => 'questa linea non trasmette la posizione';

  @override
  String get withoutRealtime => 'Senza tempo reale, solo orari programmati';

  @override
  String get statusConfirmed => 'Confermato';

  @override
  String get statusUncertain => 'Da verificare';

  @override
  String get statusScheduled => 'Programmato';

  @override
  String get statusCanceled => 'Cancellata';

  @override
  String get statusSuppressed => 'Soppressa';

  @override
  String get signalCanceled => 'Corsa cancellata';

  @override
  String signalNotTransmitting(int n) {
    return 'Il mezzo non trasmette da $n min';
  }

  @override
  String get signalNoVehicle => 'Nessun mezzo localizzato';

  @override
  String signalStill(int n) {
    return 'Mezzo fermo da $n min';
  }

  @override
  String signalOldGps(int n) {
    return 'Ultimo segnale GPS $n min fa';
  }

  @override
  String signalAtTerminus(String time) {
    return 'Parte dal capolinea alle $time';
  }

  @override
  String get signalAtTerminusNoTime => 'Ancora al capolinea';

  @override
  String get signalLateData => 'Dati in tempo reale in ritardo';

  @override
  String get realtimeUnavailable => 'Tempo reale non disponibile: orari programmati';

  @override
  String get noArrivals => 'Nessun arrivo nei prossimi 60 minuti';

  @override
  String updatedAgo(int s) {
    return 'aggiornato $s s fa';
  }

  @override
  String get timetable => 'Orari della giornata';

  @override
  String get previousDay => 'Giorno precedente';

  @override
  String get nextDay => 'Giorno successivo';

  @override
  String get scheduledTimesNote => 'Orari programmati: non tengono conto del traffico.';

  @override
  String get noServiceThisDay => 'Nessuna corsa in questo giorno';

  @override
  String get firstTrip => 'prima';

  @override
  String get lastTrip => 'ultima';

  @override
  String lastPositionAt(String time) {
    return 'ultima posizione nota alle $time';
  }

  @override
  String get terminus => 'capolinea';

  @override
  String get noTripsInService => 'Nessuna corsa in servizio';

  @override
  String nextDeparture(String time) {
    return 'Prossima partenza alle $time';
  }

  @override
  String vehiclesInService(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mezzi in servizio',
      one: '1 mezzo in servizio',
      zero: 'Nessun mezzo in servizio',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResults => 'Nessun risultato. Controlla il codice scritto sulla palina.';

  @override
  String get locationDenied => 'Attiva la posizione per vedere le fermate vicine';

  @override
  String get locationDeniedList => 'Senza posizione l\'elenco è vuoto: usa Cerca per trovare una fermata.';

  @override
  String get enableLocation => 'Attiva';

  @override
  String get you => 'Tu sei qui';

  @override
  String get backToMyPosition => 'Torna sulla mia posizione';

  @override
  String get noStopsNearby => 'Nessuna fermata entro 1 km';

  @override
  String get nearbyNote =>
      'Fermate entro 500 m, ordinate per distanza. Se non ce ne sono, il raggio si allarga a 1 km.';

  @override
  String meters(int n) {
    return '$n m';
  }

  @override
  String get noFavorites => 'Nessun preferito';

  @override
  String get noFavoritesHint => 'Tocca la stella su una fermata o una linea: l\'app si aprirà qui.';

  @override
  String get noAlerts => 'Nessun avviso attivo';

  @override
  String alertsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n avvisi', one: '1 avviso');
    return '$_temp0';
  }

  @override
  String get arrivalStates => 'Stati degli arrivi';

  @override
  String get arrivalStatesHint => 'Cosa significano Confermato, Da verificare, Programmato…';

  @override
  String get stateConfirmedMeaning => 'Un mezzo localizzato da poco e in movimento sta facendo questa corsa.';

  @override
  String get stateUncertainMeaning => 'C\'è una previsione, ma qualcosa la rende dubbia: il motivo è sempre scritto.';

  @override
  String get stateScheduledMeaning =>
      'Nessun dato in tempo reale per questa corsa: solo l\'orario programmato, mai i minuti.';

  @override
  String get stateSuppressedMeaning => 'Il mezzo è sparito prima di completare la corsa: resta visibile per 5 minuti.';

  @override
  String get stateCanceledMeaning => 'L\'operatore ha cancellato la corsa.';

  @override
  String get dataSource => 'Fonte dei dati';

  @override
  String get dataSourceBody =>
      'Open data di Roma Servizi per la Mobilità (GTFS e GTFS-Realtime). Questa app non è affiliata ad Atac né a RSM.';

  @override
  String get dataDisclaimer =>
      'I dati provengono da strumentazione automatica e non vanno considerati esaustivi: la variabilità della strada e possibili malfunzionamenti possono renderli imprecisi.';

  @override
  String get variantStops => 'Servite solo da alcune corse';

  @override
  String get routeTravelled => 'Già percorso';

  @override
  String get routeAhead => 'Ancora da percorrere';

  @override
  String nextStopName(String stop) {
    return 'Prossima fermata: $stop';
  }

  @override
  String vehicleNumber(String label) {
    return 'Vettura $label';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get clear => 'Cancella';

  @override
  String get followedTrips => 'Corse seguite';

  @override
  String get followTrip => 'Segui questa corsa';

  @override
  String get followTripHint => 'Tocca un orario per essere avvisato quando quell\'autobus sta per passare.';

  @override
  String get followDays => 'Giorni';

  @override
  String get followLeads => 'Avvisami prima';

  @override
  String followLeadsHint(int n) {
    return 'Fino a $n avvisi';
  }

  @override
  String followLeadsSummary(String minutes) {
    return '$minutes min prima';
  }

  @override
  String get followEnabled => 'Avvisi attivi';

  @override
  String get followRemove => 'Smetti di seguire';

  @override
  String get followRemoveTitle => 'Smettere di seguire questa corsa?';

  @override
  String get followRemoveBody => 'Non riceverai più avvisi su questa corsa.';

  @override
  String get followSaved => 'Corsa seguita';

  @override
  String get followedMarker => 'Corsa seguita';

  @override
  String get everyDay => 'Ogni giorno';

  @override
  String get weekdays => 'Lun–Ven';

  @override
  String get weekend => 'Sab, Dom';

  @override
  String get noFollows => 'Nessuna corsa seguita';

  @override
  String get noFollowsHint =>
      'Apri gli orari di una fermata e tocca l\'orario della corsa che ti interessa: ti avviseremo prima che passi.';

  @override
  String get notificationsOff => 'Le notifiche sono disattivate';

  @override
  String get notificationsOffBody => 'Senza notifiche non puoi essere avvisato quando l\'autobus sta per passare.';

  @override
  String get notificationsBlocked => 'Attiva le notifiche per questa app dalle impostazioni del telefono.';

  @override
  String get notificationsUnavailable => 'Questo dispositivo non può ricevere notifiche.';

  @override
  String get enableNotifications => 'Attiva';

  @override
  String get noticeChannelName => 'Corse seguite';

  @override
  String get noticeChannelDescription => 'Il tuo autobus sta per passare, o gli è successo qualcosa';

  @override
  String get errorFollowLimit => 'Puoi seguire al massimo 30 corse. Eliminane una prima.';

  @override
  String pushLead(String route, int minutes) {
    return 'Linea $route: tra $minutes min';
  }

  @override
  String pushArriving(String route) {
    return 'Linea $route: sta arrivando';
  }

  @override
  String get pushScheduled => 'orario programmato';

  @override
  String pushStopTo(String stop, String headsign) {
    return '$stop verso $headsign';
  }

  @override
  String pushCanceledTitle(String route) {
    return 'Linea $route: corsa cancellata';
  }

  @override
  String pushCanceledBody(String time, String place) {
    return 'La corsa delle $time a $place è stata cancellata';
  }

  @override
  String pushStillTitle(String route, int minutes) {
    return 'Linea $route: bus fermo da $minutes min';
  }

  @override
  String pushStillBody(String time, String place) {
    return 'Corsa delle $time a $place';
  }

  @override
  String pushLostTitle(String route) {
    return 'Linea $route: segnale perso';
  }

  @override
  String pushLostBody(String time, String place) {
    return 'Il mezzo della corsa delle $time a $place ha smesso di trasmettere: potrebbe non arrivare';
  }

  @override
  String overdue(String time) {
    return 'Prevista alle $time, potrebbe ancora passare';
  }

  @override
  String get showOnMap => 'Mostra sulla mappa';

  @override
  String get editFollow => 'Modifica';

  @override
  String tripAt(String time, String stop) {
    return 'Corsa delle $time a $stop';
  }

  @override
  String get tripHistoryWeekdays => 'Ultimi giorni feriali';

  @override
  String get tripHistoryWeekend => 'Ultimi weekend';

  @override
  String get tripHistoryEmpty => 'Nessun dato ancora: lo storico si riempie giorno dopo giorno.';

  @override
  String get tripUsuallyOnTime => 'Di solito puntuale';

  @override
  String tripUsuallyLate(int n) {
    return 'Di solito in ritardo di circa $n min';
  }

  @override
  String tripUsuallyEarly(int n) {
    return 'Di solito in anticipo di circa $n min';
  }

  @override
  String get tripRarelyTracked => 'Raramente tracciata: potrebbe passare comunque';

  @override
  String tripOnTimeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n puntuali', one: '1 puntuale');
    return '$_temp0';
  }

  @override
  String tripLateCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n in ritardo', one: '1 in ritardo');
    return '$_temp0';
  }

  @override
  String tripEarlyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n in anticipo', one: '1 in anticipo');
    return '$_temp0';
  }

  @override
  String tripNotTrackedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n non tracciate', one: '1 non tracciata');
    return '$_temp0';
  }

  @override
  String tripCanceledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n cancellate', one: '1 cancellata');
    return '$_temp0';
  }

  @override
  String get tripDayNotTracked => 'non tracciata';

  @override
  String get tripDayCanceled => 'cancellata';

  @override
  String get journeysHomePlace => 'Casa';

  @override
  String get journeysWhereTo => 'Dove vai?';

  @override
  String get journeysAlreadyThere => 'Sei già arrivato';

  @override
  String get journeysSearchHint => 'Indirizzo o luogo';

  @override
  String get journeysSearchAddress => 'Cerca un indirizzo';

  @override
  String get journeysSearchNone => 'Nessun indirizzo trovato a Roma';

  @override
  String get journeysRecent => 'Recenti';

  @override
  String get journeysSetHome => 'Imposta casa';

  @override
  String get journeysRemoveHome => 'Rimuovi casa';

  @override
  String get journeysHomeSaved => 'Casa salvata';

  @override
  String get journeysNoHomeHint =>
      'Impostala una volta e Veribus ti dice quale mezzo prendere per tornarci, da dove sei. Oppure cerca qui sopra una destinazione qualsiasi.';

  @override
  String get journeysNeedPosition => 'Serve la tua posizione per calcolare il percorso';

  @override
  String get journeysAtHome => 'Sei già a casa';

  @override
  String get journeysNone => 'Nessun percorso con al massimo due cambi';

  @override
  String get journeysNoneHint =>
      'A quest\'ora la rete potrebbe non arrivarci. L\'ultimo percorso della notte, quando c\'è, è in cima.';

  @override
  String get journeysUnavailable => 'I percorsi di oggi non sono disponibili';

  @override
  String get journeysUnavailableHint =>
      'L\'orario per il calcolo dei percorsi non è ancora stato pubblicato. Gli arrivi alle fermate funzionano lo stesso.';

  @override
  String get journeysOpenGoogleMaps => 'Apri in Google Maps';

  @override
  String get journeysDirect => 'Diretto';

  @override
  String journeysChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n cambi', one: '1 cambio');
    return '$_temp0';
  }

  @override
  String get journeysWalkOnly => 'A piedi';

  @override
  String journeysTimes(String depart, String arrive) {
    return '$depart → $arrive';
  }

  @override
  String journeysFrom(String stop) {
    return 'da $stop';
  }

  @override
  String journeysStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n fermate', one: '1 fermata');
    return '$_temp0';
  }

  @override
  String journeysArriveHome(String time) {
    return 'A casa verso le $time';
  }

  @override
  String journeysArriveDestination(String time) {
    return 'Arrivo verso le $time';
  }

  @override
  String journeysIfMissed(String line, String time) {
    return 'Se lo perdi: il prossimo $line alle $time';
  }

  @override
  String journeysIfMissedNone(String line) {
    return 'Se lo perdi, stanotte non ci sono altri $line';
  }

  @override
  String journeysLast(String time) {
    return 'Ultimo percorso: esci entro le $time';
  }

  @override
  String get journeysLastHint => 'Dopo non c\'è più un percorso con al massimo due cambi.';

  @override
  String journeysChangeRecord(int made, int days) {
    return 'Questa coincidenza ha funzionato $made volte su $days';
  }

  @override
  String get journeysChangeNoRecord => 'Ancora nessuno storico per questa coincidenza';

  @override
  String get journeysLongWait => 'Un\'attesa lunga';

  @override
  String journeysMetro(String line) {
    return 'Metro $line';
  }

  @override
  String get journeysNote =>
      'I tratti a piedi da te alla prima fermata e dall\'ultima fermata alla destinazione sono stimati in linea d\'aria. Oltre la prossima ora gli orari sono quelli programmati.';

  @override
  String get journeysDetails => 'Percorso';

  @override
  String get journeysGone => 'Questo percorso non è più disponibile: torna all\'elenco.';

  @override
  String get journeysYourPosition => 'La tua posizione';

  @override
  String get journeysSwap => 'Inverti partenza e arrivo';

  @override
  String get journeysNow => 'Parti ora';

  @override
  String journeysDepartAt(String time) {
    return 'Parti alle $time';
  }

  @override
  String get journeysOptions => 'Opzioni';

  @override
  String get journeysOptionsTitle => 'Quando e come';

  @override
  String get journeysToday => 'Oggi';

  @override
  String get journeysTomorrow => 'Domani';

  @override
  String get journeysUseMetro => 'Usa la metro';

  @override
  String get journeysUseNight => 'Includi i notturni';

  @override
  String get journeysReset => 'Ripristina';

  @override
  String get journeysShow => 'Mostra percorsi';

  @override
  String journeysWalkTotal(int minutes) {
    return '$minutes min a piedi';
  }

  @override
  String journeysDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get journeysRemind => 'Ricordamelo';

  @override
  String journeysWalkMinutes(int minutes) {
    return 'Cammina $minutes min';
  }

  @override
  String get journeysGetOff => 'scendi';

  @override
  String journeysChangeAt(String stop) {
    return 'Cambio a $stop';
  }

  @override
  String journeysChangeTimes(int walk, int wait) {
    return '$walk min a piedi · $wait min di attesa';
  }

  @override
  String get journeysStart => 'Avvia';

  @override
  String journeysIntermediate(String stops, int minutes) {
    return '$stops · $minutes min';
  }

  @override
  String journeysInMinutes(int minutes) {
    return 'fra $minutes min';
  }

  @override
  String get journeysLeaveAtLabel => 'Parti alle';

  @override
  String get journeysWorkPlace => 'Lavoro';

  @override
  String get journeysSetWork => 'Imposta lavoro';

  @override
  String get journeysPlacesSection => 'Indirizzi e luoghi';

  @override
  String get journeysStopsSection => 'Fermate';

  @override
  String get journeysFromLabel => 'Da';

  @override
  String get journeysToLabel => 'A';

  @override
  String get journeysSavedSection => 'Luoghi salvati';

  @override
  String get journeysSaveAs => 'Salva come';

  @override
  String get journeysSaveHome => 'Salva Casa';

  @override
  String get journeysSaveWork => 'Salva Lavoro';

  @override
  String get journeysSaveHint =>
      'Trascina la mappa se il segnaposto non è sul portone. Resta salvato solo su questo telefono.';

  @override
  String get journeysWorkSaved => 'Lavoro salvato';

  @override
  String get journeysRemoveWork => 'Rimuovi Lavoro';

  @override
  String get journeysPinPlace => 'Posizione sulla mappa';

  @override
  String get exploreNearYou => 'Vicino a te';

  @override
  String exploreWalk(int minutes, int meters) {
    return '$minutes min a piedi · $meters m';
  }

  @override
  String get exploreAll => 'Tutti';

  @override
  String get exploreBus => 'Bus';

  @override
  String get exploreTram => 'Tram';

  @override
  String get exploreProfile => 'Profilo e impostazioni';

  @override
  String get linesBus => 'Bus';

  @override
  String get linesTram => 'Tram';

  @override
  String get linesNight => 'Notturni';

  @override
  String get linesSearchHint => 'Cerca una linea o una palina';

  @override
  String get lineYourStop => 'La tua fermata';

  @override
  String get stopDirectionsHere => 'Indicazioni fin qui';

  @override
  String tripWalkTo(String place) {
    return 'Cammina fino a $place';
  }

  @override
  String tripDistance(int meters, int minutes) {
    return '$meters m · $minutes min';
  }

  @override
  String tripYourLine(String line, String when) {
    return 'Il tuo $line passa $when';
  }

  @override
  String tripBoard(String line) {
    return 'Sali sul $line';
  }

  @override
  String tripWaitHere(String headsign) {
    return '$headsign, in arrivo qui';
  }

  @override
  String tripGetOffIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n fermate', one: '1 fermata');
    return 'Scendi fra $_temp0';
  }

  @override
  String get tripGetOffNext => 'Scendi alla prossima';

  @override
  String tripGetOffAt(String stop, String time) {
    return 'a $stop · $time';
  }

  @override
  String tripThenNoWalk(String line, String time) {
    return 'Poi $line alle $time';
  }

  @override
  String get tripArrived => 'Sei arrivato';

  @override
  String get tripEnd => 'Termina';

  @override
  String get tripAllSteps => 'Tutti i passaggi';

  @override
  String get tripAlertHint => 'Il telefono vibra una fermata prima, con lo schermo acceso.';

  @override
  String get tripAlertTitle => 'Scendi alla prossima';

  @override
  String get tripNeedPosition => 'Serve la posizione per seguirti passo per passo';

  @override
  String tripAtTime(String time) {
    return 'alle $time';
  }

  @override
  String get tripChannelName => 'Percorso in corso';

  @override
  String get tripShowMap => 'Mostra la mappa';

  @override
  String get tripShowList => 'Mostra le fermate';

  @override
  String get exploreMetro => 'Metro';

  @override
  String metroEvery(int minutes) {
    return 'Ogni circa $minutes min adesso';
  }

  @override
  String get metroNoTrains => 'Nessun treno nella prossima ora';

  @override
  String get metroScheduled => 'Dati da orario programmato, non in tempo reale.';

  @override
  String get metroNoneNearby => 'Nessuna stazione della metro vicina';

  @override
  String get tripOngoingTitle => 'Veribus · in viaggio';

  @override
  String tripOngoingText(String destination) {
    return 'Ti accompagno verso $destination';
  }

  @override
  String tripMissed(String line, String next, String time) {
    return 'Il $line è passato: il prossimo è il $next alle $time';
  }

  @override
  String tripReplanned(String next, String time) {
    return 'Percorso aggiornato: il prossimo è il $next alle $time';
  }

  @override
  String tripOnBoardDetected(String line) {
    return 'Sei sul $line: ti seguo da qui';
  }

  @override
  String get tripAlreadyOnBoard => 'Sei già su un autobus?';

  @override
  String get tripPickBus => 'Su quale autobus sei?';

  @override
  String get tripNoBusNear => 'Nessun autobus vicino a te in questo momento';
}
