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
  String get appTitle => 'Template';

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
  String get nearby => 'Vicino a me';

  @override
  String get search => 'Cerca';

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
  String get searchHint => 'Linea o palina';

  @override
  String get searchEmpty => 'La ricerca lavora sul telefono: i risultati compaiono mentre scrivi.';

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
  String get zoomInForStops => 'Avvicinati per vedere le fermate';

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
}
