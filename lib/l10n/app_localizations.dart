/// Testi statici dell'app (tutto ciò che NON arriva dal database).
///
/// Lingue supportate: Italiano (it), Inglese (en), Tedesco (de), Francese (fr).
/// L'API pubblica (`AppLocalizations.of(code).xxx`) resta invariata rispetto
/// alla versione precedente: cambia solo l'implementazione interna, ora
/// basata su una mappa di traduzioni invece che su ternari it/en.
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String code) {
    return AppLocalizations(code);
  }

  String _t(String key) {
    final lang = _translations[languageCode] ?? _translations['it']!;
    return lang[key] ?? _translations['it']![key] ?? key;
  }

  // ============== LOGIN PAGE ==============
  String get welcome => _t('welcome');
  String get toGubbio => _t('toGubbio');
  String get discoverGubbio => _t('discoverGubbio');
  String get email => _t('email');
  String get password => _t('password');
  String get login => _t('login');
  String get noAccount => _t('noAccount');
  String get register => _t('register');
  String get forgotPassword => _t('forgotPassword');
  String get enterEmail => _t('enterEmail');
  String get invalidEmail => _t('invalidEmail');
  String get enterPassword => _t('enterPassword');
  String get privacyPolicy => _t('privacyPolicy');

  // ============== REGISTER PAGE ==============
  String get registration => _t('registration');
  String get createAccount => _t('createAccount');
  String get firstName => _t('firstName');
  String get lastName => _t('lastName');
  String get confirmPassword => _t('confirmPassword');
  String get haveAccount => _t('haveAccount');
  String get signIn => _t('signIn');

  // Validazioni
  String get enterFirstName => _t('enterFirstName');
  String get enterLastName => _t('enterLastName');
  String get confirmPasswordText => _t('confirmPasswordText');
  String get passwordsDontMatch => _t('passwordsDontMatch');
  String get passwordMinLength => _t('passwordMinLength');

  // ============== FORGOT PASSWORD PAGE ==============
  String get resetPassword => _t('resetPassword');
  String get resetPasswordDescription => _t('resetPasswordDescription');
  String get sendResetLink => _t('sendResetLink');
  String get backToLogin => _t('backToLogin');

  // ============== ERRORI ==============
  String get loginError => _t('loginError');
  String get invalidCredentials => _t('invalidCredentials');
  String get tooManyAttempts => _t('tooManyAttempts');
  String get emailNotConfirmed => _t('emailNotConfirmed');
  String get connectionError => _t('connectionError');
  String get userNotFound => _t('userNotFound');
  String get registrationError => _t('registrationError');
  String get emailAlreadyInUse => _t('emailAlreadyInUse');
  String get weakPassword => _t('weakPassword');
  String get registrationSuccess => _t('registrationSuccess');
  String get resetLinkSent => _t('resetLinkSent');

  // ============== HOME PAGE ==============
  String get home => _t('home');
  String get events => _t('events');
  String get program => _t('program');
  String get profile => _t('profile');
  String get logout => _t('logout');
  String get language => _t('language');
  String get selectLanguage => _t('selectLanguage');
  String get italian => _t('italian');
  String get english => _t('english');
  String get german => _t('german');
  String get french => _t('french');

  // ============== MAP ==============
  String get myPosition => _t('myPosition');
  String get navigate => _t('navigate');
  String get distance => _t('distance');
  String get walkingTime => _t('walkingTime');
  String get minutes => _t('minutes');

  // ============== EVENTI ==============
  String get eventDetails => _t('eventDetails');
  String get location => _t('location');
  String get time => _t('time');
  String get description => _t('description');

  // ============== PROFILO ==============
  String get userProfile => _t('userProfile');
  String get editProfile => _t('editProfile');
  String get save => _t('save');
  String get cancel => _t('cancel');

  // ============== GENERICI / ERRORI / CONFERME ==============
  String get errorPrefix => _t('errorPrefix');
  String get requiredField => _t('requiredField');
  String get featureUnavailable => _t('featureUnavailable');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get close => _t('close');
  String get menu => _t('menu');
  String deleteConfirmMessage(String name) =>
      _t('deleteConfirmMessage').replaceAll('{name}', name);

  // ============== HOME / NAVIGAZIONE ==============
  String get yourPosition => _t('yourPosition');
  String get nextEvent => _t('nextEvent');
  String get whereAmI => _t('whereAmI');
  String get gubbioMapsLabel => _t('gubbioMapsLabel');
  String get routeMapLabel => _t('routeMapLabel');
  String get restaurantsNav => _t('restaurantsNav');
  String get barsNav => _t('barsNav');
  String get mapNav => _t('mapNav');
  String get programNav => _t('programNav');
  String get storiaDiGubbioNav => _t('storiaDiGubbioNav');
  String get suggestedItinerariesNav => _t('suggestedItinerariesNav');
  String get userNav => _t('userNav');
  String get exitConfirmMessage => _t('exitConfirmMessage');
  String appVersionLabel(String version) =>
      _t('appVersionLabel').replaceAll('{version}', version);
  String get positionUnavailable => _t('positionUnavailable');

  // ============== EVENTI (LISTA/DETTAGLIO) ==============
  String get searchEventsHint => _t('searchEventsHint');
  String get noEventsFound => _t('noEventsFound');
  String get tryChangeFilters => _t('tryChangeFilters');
  String get concluded => _t('concluded');
  String get ongoing => _t('ongoing');
  String get goToDetails => _t('goToDetails');
  String get directions => _t('directions');
  String get showOnMap => _t('showOnMap');
  String get eventHeaderTitle => _t('eventHeaderTitle');
  String get festaCeriLabel => _t('festaCeriLabel');
  String get defaultEventDescription => _t('defaultEventDescription');
  String get contactsSection => _t('contactsSection');
  String get historicalContextLabel => _t('historicalContextLabel');
  String get didYouKnowLabel => _t('didYouKnowLabel');
  String get positionLabel => _t('positionLabel');
  String get viewOnMapLabel => _t('viewOnMapLabel');
  String get editEventTitle => _t('editEventTitle');
  String get addEventTitle => _t('addEventTitle');
  String get eventAdded => _t('eventAdded');
  String get eventUpdated => _t('eventUpdated');
  String get eventDeleted => _t('eventDeleted');
  String get titleFieldLabel => _t('titleFieldLabel');
  String get titleRequiredError => _t('titleRequiredError');
  String get descriptionFieldLabel => _t('descriptionFieldLabel');
  String get placeFieldLabel => _t('placeFieldLabel');
  String get categoryFieldLabel => _t('categoryFieldLabel');
  String get phoneFieldLabel => _t('phoneFieldLabel');
  String get websiteFieldLabel => _t('websiteFieldLabel');
  String get latitudeFieldLabel => _t('latitudeFieldLabel');
  String get longitudeFieldLabel => _t('longitudeFieldLabel');
  String get dateFieldLabel => _t('dateFieldLabel');
  String get startFieldLabel => _t('startFieldLabel');
  String get endFieldLabel => _t('endFieldLabel');
  String get saveLabel => _t('saveLabel');
  String get saveChangesLabel => _t('saveChangesLabel');

  // ============== BAR / RISTORANTI ==============
  String get editBarTitle => _t('editBarTitle');
  String get addBarTitle => _t('addBarTitle');
  String get editRestaurantTitle => _t('editRestaurantTitle');
  String get addRestaurantTitle => _t('addRestaurantTitle');
  String get barAdded => _t('barAdded');
  String get barUpdated => _t('barUpdated');
  String get barDeleted => _t('barDeleted');
  String get nameFieldLabel => _t('nameFieldLabel');
  String get nameRequiredSimpleError => _t('nameRequiredSimpleError');
  String get tagsFieldLabel => _t('tagsFieldLabel');
  String get ratingFieldLabel => _t('ratingFieldLabel');
  String get restaurantAdded => _t('restaurantAdded');
  String get restaurantUpdated => _t('restaurantUpdated');
  String get restaurantDeleted => _t('restaurantDeleted');

  // ============== ITINERARI ==============
  String get itinerariTitle => _t('itinerariTitle');
  String get itinerariDescription => _t('itinerariDescription');
  String get itinerarioAdded => _t('itinerarioAdded');
  String get itinerarioUpdated => _t('itinerarioUpdated');
  String get itinerarioDeleted => _t('itinerarioDeleted');

  // ============== STORIA DI GUBBIO ==============
  String get storiaTitle => _t('storiaTitle');
  String get addFab => _t('addFab');
  String get contenutoAdded => _t('contenutoAdded');
  String get contenutoUpdated => _t('contenutoUpdated');
  String get allCategories => _t('allCategories');
  String get categoryChiesa => _t('categoryChiesa');
  String get categoryPalazzo => _t('categoryPalazzo');
  String get categoryPiazza => _t('categoryPiazza');
  String get categoryMonumento => _t('categoryMonumento');
  String get categoryNatura => _t('categoryNatura');
  String get translateExistingContentTooltip =>
      _t('translateExistingContentTooltip');

  // ============== ADMIN: MENU AGGIUNGI CONTENUTO ==============
  String get addContentTitle => _t('addContentTitle');
  String get addRestaurantMenuItem => _t('addRestaurantMenuItem');
  String get addBarMenuItem => _t('addBarMenuItem');
  String get addEventMenuItem => _t('addEventMenuItem');
  String get addItinerarioMenuItem => _t('addItinerarioMenuItem');
  String get storiaShortLabel => _t('storiaShortLabel');
  String get exploreGubbioTitle => _t('exploreGubbioTitle');
  String get videoComingSoon => _t('videoComingSoon');
  String get seeAllLabel => _t('seeAllLabel');

  // ============== PROGRAMMA FESTA DEI CERI ==============
  String get programTitle => _t('programTitle');
  String get tab15Mag => _t('tab15Mag');
  String get tab19Mag => _t('tab19Mag');
  String get tab2Giu => _t('tab2Giu');
  String get ceriMezzani => _t('ceriMezzani');
  String get ceriPiccoli => _t('ceriPiccoli');
  String get comingSoonProgram => _t('comingSoonProgram');

  // ============== MUTE (CERAIOLI) ==============
  String get muteTitle => _t('muteTitle');
  String get newMuta => _t('newMuta');
  String get noMuteYet => _t('noMuteYet');
  String get createFirstMuta => _t('createFirstMuta');
  String get goToMapLocation => _t('goToMapLocation');
  String get editMutaTitle => _t('editMutaTitle');
  String get generalInfoSection => _t('generalInfoSection');
  String get mutaNameLabel => _t('mutaNameLabel');
  String get nameRequiredError => _t('nameRequiredError');
  String get zoneLocationLabel => _t('zoneLocationLabel');
  String get zoneRequiredError => _t('zoneRequiredError');
  String get capoMutaLabel => _t('capoMutaLabel');
  String get capoMutaRequiredError => _t('capoMutaRequiredError');
  String get capocorsaFrontSection => _t('capocorsaFrontSection');
  String get capocorsaLabel => _t('capocorsaLabel');
  String get capocorsaRequiredError => _t('capocorsaRequiredError');
  String get leftExternsSection => _t('leftExternsSection');
  String get rightExternsSection => _t('rightExternsSection');
  String get rearInternsSection => _t('rearInternsSection');
  String externalLeftLabel(int n) =>
      _t('externalLeftLabel').replaceAll('{n}', '$n');
  String externalRightLabel(int n) =>
      _t('externalRightLabel').replaceAll('{n}', '$n');
  String internalRearLabel(int n) =>
      _t('internalRearLabel').replaceAll('{n}', '$n');
  String get saveChangesButton => _t('saveChangesButton');
  String get createMutaButton => _t('createMutaButton');
  String get deleteMutaButton => _t('deleteMutaButton');
  String get fillAllRequiredFields => _t('fillAllRequiredFields');
  String get mutaUpdatedSuccess => _t('mutaUpdatedSuccess');
  String get mutaCreatedSuccess => _t('mutaCreatedSuccess');
  String get deleteMutaConfirmMessage => _t('deleteMutaConfirmMessage');
  String get mutaDeletedSuccess => _t('mutaDeletedSuccess');

  // ============== PROFILO UTENTE ==============
  String get personalInfoSection => _t('personalInfoSection');
  String get nameLabel => _t('nameLabel');
  String get surnameLabel => _t('surnameLabel');
  String get emailLabel => _t('emailLabel');
  String get noAuthenticatedUser => _t('noAuthenticatedUser');
  String get logoutAccountButton => _t('logoutAccountButton');
  String get deleteMyAccountButton => _t('deleteMyAccountButton');
  String get deleteAccountTitle => _t('deleteAccountTitle');
  String get deleteAccountMessage => _t('deleteAccountMessage');

  // ============== REGISTRAZIONE: CONFERMA EMAIL ==============
  String get confirmYourEmailTitle => _t('confirmYourEmailTitle');
  String confirmEmailMessage(String email) =>
      _t('confirmEmailMessage').replaceAll('{email}', email);
  String get goToLoginOk => _t('goToLoginOk');

  /// Bandiera + nome nativo per un codice lingua, usati nei selettori sparsi
  /// nell'app (login, registrazione, header, profilo).
  static String flagFor(String code) => switch (code) {
        'it' => '🇮🇹',
        'en' => '🇬🇧',
        'de' => '🇩🇪',
        'fr' => '🇫🇷',
        _ => '🇮🇹',
      };

  static String nameFor(String code) => switch (code) {
        'it' => 'Italiano',
        'en' => 'English',
        'de' => 'Deutsch',
        'fr' => 'Français',
        _ => code,
      };

  static const List<String> supportedCodes = ['it', 'en', 'de', 'fr'];

  static final Map<String, Map<String, String>> _translations = {
    'it': {
      'welcome': 'Benvenuto',
      'toGubbio': 'a Gubbio',
      'discoverGubbio': 'Scopri la magia della più bella città medievale',
      'email': 'Email',
      'password': 'Password',
      'login': 'Accedi',
      'noAccount': 'Non hai un account?',
      'register': 'Registrati',
      'forgotPassword': 'Password dimenticata?',
      'enterEmail': 'Inserisci email',
      'invalidEmail': 'Email non valida',
      'enterPassword': 'Inserisci password',
      'privacyPolicy': 'Informativa sulla privacy',
      'registration': 'Registrazione',
      'createAccount': 'Crea il tuo account',
      'firstName': 'Nome',
      'lastName': 'Cognome',
      'confirmPassword': 'Conferma Password',
      'haveAccount': 'Hai già un account?',
      'signIn': 'Accedi',
      'enterFirstName': 'Inserisci il nome',
      'enterLastName': 'Inserisci il cognome',
      'confirmPasswordText': 'Conferma la password',
      'passwordsDontMatch': 'Le password non coincidono',
      'passwordMinLength': 'Minimo 6 caratteri',
      'resetPassword': 'Recupera Password',
      'resetPasswordDescription':
          'Inserisci la tua email per ricevere il link di recupero password',
      'sendResetLink': 'Invia Link',
      'backToLogin': 'Torna al Login',
      'loginError': 'Errore durante il login',
      'invalidCredentials': 'Email o password non corretti',
      'tooManyAttempts': 'Troppi tentativi! Attendi qualche minuto e riprova.',
      'emailNotConfirmed': 'Email non confermata. Controlla la tua casella di posta.',
      'connectionError': 'Errore di connessione. Controlla la tua rete.',
      'userNotFound': 'Account non trovato. Registrati prima.',
      'registrationError': 'Errore durante la registrazione',
      'emailAlreadyInUse': 'Email già registrata. Prova ad effettuare il login.',
      'weakPassword': 'Password troppo debole. Usa almeno 6 caratteri.',
      'registrationSuccess': 'Registrazione completata! Effettua il login.',
      'resetLinkSent':
          'Link di recupero inviato! Controlla la tua email (e anche la cartella spam/posta indesiderata se non la trovi).',
      'home': 'Home',
      'events': 'Eventi',
      'program': 'Programma',
      'profile': 'Profilo',
      'logout': 'Esci',
      'language': 'Lingua',
      'selectLanguage': 'Seleziona Lingua',
      'italian': 'Italiano',
      'english': 'Inglese',
      'german': 'Tedesco',
      'french': 'Francese',
      'myPosition': 'La mia posizione',
      'navigate': 'Naviga',
      'distance': 'Distanza',
      'walkingTime': 'Tempo a piedi',
      'minutes': 'min',
      'eventDetails': 'Dettagli Evento',
      'location': 'Luogo',
      'time': 'Orario',
      'description': 'Descrizione',
      'userProfile': 'Profilo Utente',
      'editProfile': 'Modifica Profilo',
      'save': 'Salva',
      'cancel': 'Annulla',
      'errorPrefix': 'Errore',
      'requiredField': 'Campo obbligatorio',
      'featureUnavailable': 'Funzione non disponibile',
      'delete': 'Elimina',
      'edit': 'Modifica',
      'close': 'Chiudi',
      'menu': 'Menu',
      'deleteConfirmMessage': 'Vuoi eliminare "{name}"? L\'operazione è irreversibile.',
      'yourPosition': 'La tua posizione',
      'nextEvent': 'Prossimo evento',
      'whereAmI': 'Dove sono',
      'gubbioMapsLabel': 'GubbioMaps',
      'routeMapLabel': 'Mappa Percorso',
      'restaurantsNav': 'Ristoranti',
      'barsNav': 'Bar',
      'mapNav': 'Mappa',
      'programNav': 'Programma',
      'storiaDiGubbioNav': 'Storia di Gubbio',
      'suggestedItinerariesNav': 'Itinerari consigliati',
      'userNav': 'Utente',
      'exitConfirmMessage': 'Vuoi uscire dal tuo account?',
      'appVersionLabel': 'Versione {version}',
      'positionUnavailable': 'Posizione non disponibile',
      'searchEventsHint': 'Cerca eventi per nome...',
      'noEventsFound': 'Nessun evento trovato',
      'tryChangeFilters': 'Prova a modificare i filtri di ricerca',
      'concluded': 'CONCLUSO',
      'ongoing': 'IN CORSO',
      'goToDetails': 'Vai ai dettagli',
      'directions': 'Indicazioni',
      'showOnMap': 'Mostra sulla mappa',
      'eventHeaderTitle': 'Evento',
      'festaCeriLabel': 'Festa dei Ceri',
      'defaultEventDescription':
          'Uno degli eventi più importanti della Festa dei Ceri di Gubbio, una tradizione che si tramanda da secoli e che rappresenta il cuore pulsante della città.',
      'contactsSection': 'Contatti',
      'historicalContextLabel': 'Contesto Storico',
      'didYouKnowLabel': 'Lo sapevi che...',
      'positionLabel': 'Posizione',
      'viewOnMapLabel': 'Vedi sulla mappa',
      'editEventTitle': 'Modifica Evento',
      'addEventTitle': 'Aggiungi Evento',
      'eventAdded': 'Evento aggiunto!',
      'eventUpdated': 'Evento aggiornato!',
      'eventDeleted': 'Evento eliminato',
      'titleFieldLabel': 'Titolo',
      'titleRequiredError': 'Inserisci il titolo',
      'descriptionFieldLabel': 'Descrizione',
      'placeFieldLabel': 'Luogo',
      'categoryFieldLabel': 'Categoria',
      'phoneFieldLabel': 'Telefono',
      'websiteFieldLabel': 'Sito web',
      'latitudeFieldLabel': 'Latitudine',
      'longitudeFieldLabel': 'Longitudine',
      'dateFieldLabel': 'Data',
      'startFieldLabel': 'Inizio',
      'endFieldLabel': 'Fine',
      'saveLabel': 'SALVA',
      'saveChangesLabel': 'SALVA MODIFICHE',
      'editBarTitle': 'Modifica Bar',
      'addBarTitle': 'Aggiungi Bar',
      'editRestaurantTitle': 'Modifica Ristorante',
      'addRestaurantTitle': 'Aggiungi Ristorante',
      'barAdded': 'Bar aggiunto!',
      'barUpdated': 'Bar aggiornato!',
      'barDeleted': 'Bar eliminato',
      'nameFieldLabel': 'Nome',
      'nameRequiredSimpleError': 'Inserisci il nome',
      'tagsFieldLabel': 'Tag (separati da virgola, es. Umbra, Italiana, Medievale)',
      'ratingFieldLabel': 'Valutazione (media TripAdvisor / Google Maps)',
      'restaurantAdded': 'Ristorante aggiunto!',
      'restaurantUpdated': 'Ristorante aggiornato!',
      'restaurantDeleted': 'Ristorante eliminato',
      'itinerariTitle': 'Itinerari consigliati',
      'itinerariDescription':
          'Percorsi selezionati per vivere Gubbio al meglio, in base al tempo a disposizione e ai tuoi interessi.',
      'itinerarioAdded': 'Itinerario aggiunto!',
      'itinerarioUpdated': 'Itinerario aggiornato!',
      'itinerarioDeleted': 'Itinerario eliminato',
      'storiaTitle': 'Storia di Gubbio',
      'addFab': 'Aggiungi',
      'contenutoAdded': 'Contenuto aggiunto!',
      'contenutoUpdated': 'Contenuto aggiornato!',
      'allCategories': 'Tutte le categorie',
      'categoryChiesa': 'Chiese',
      'categoryPalazzo': 'Palazzi',
      'categoryPiazza': 'Piazze',
      'categoryMonumento': 'Monumenti',
      'categoryNatura': 'Natura',
      'translateExistingContentTooltip': 'Traduci contenuti già esistenti (EN/FR/DE)',
      'addContentTitle': 'AGGIUNGI CONTENUTO',
      'addRestaurantMenuItem': 'Aggiungi Ristorante',
      'addBarMenuItem': 'Aggiungi Bar',
      'addEventMenuItem': 'Aggiungi Evento',
      'addItinerarioMenuItem': 'Aggiungi Itinerario',
      'storiaShortLabel': 'Storia',
      'exploreGubbioTitle': 'ESPLORA GUBBIO',
      'videoComingSoon': 'Video di presentazione in arrivo',
      'seeAllLabel': 'Vedi tutti',
      'programTitle': 'Programma Festa dei Ceri',
      'tab15Mag': '15 Mag',
      'tab19Mag': '19 Mag',
      'tab2Giu': '2 Giu',
      'ceriMezzani': 'Ceri Mezzani',
      'ceriPiccoli': 'Ceri Piccoli',
      'comingSoonProgram': 'Programma in arrivo',
      'muteTitle': 'Mute',
      'newMuta': 'Nuova Muta',
      'noMuteYet': 'Nessuna muta presente',
      'createFirstMuta': 'Crea la prima muta',
      'goToMapLocation': 'Vai sulla mappa',
      'editMutaTitle': 'Modifica Muta',
      'generalInfoSection': 'Informazioni Generali',
      'mutaNameLabel': 'Nome Muta',
      'nameRequiredError': 'Il nome è obbligatorio',
      'zoneLocationLabel': 'Zona/Località',
      'zoneRequiredError': 'La zona è obbligatoria',
      'capoMutaLabel': 'Capo Muta',
      'capoMutaRequiredError': 'Il capo muta è obbligatorio',
      'capocorsaFrontSection': 'Capocorsa (Davanti)',
      'capocorsaLabel': 'Capocorsa',
      'capocorsaRequiredError': 'Il capocorsa è obbligatorio',
      'leftExternsSection': 'Esterni Sinistra (4 ceraioli)',
      'rightExternsSection': 'Esterni Destra (4 ceraioli)',
      'rearInternsSection': 'Interni Posteriori (2 ceraioli)',
      'externalLeftLabel': 'Esterno Sinistro {n}',
      'externalRightLabel': 'Esterno Destro {n}',
      'internalRearLabel': 'Interno Posteriore {n}',
      'saveChangesButton': 'Salva Modifiche',
      'createMutaButton': 'Crea Muta',
      'deleteMutaButton': 'Elimina Muta',
      'fillAllRequiredFields': 'Compila tutti i campi obbligatori',
      'mutaUpdatedSuccess': 'Muta modificata con successo',
      'mutaCreatedSuccess': 'Muta creata con successo',
      'deleteMutaConfirmMessage': 'Sei sicuro di voler eliminare questa muta?',
      'mutaDeletedSuccess': 'Muta eliminata',
      'personalInfoSection': 'Informazioni Personali',
      'nameLabel': 'Nome',
      'surnameLabel': 'Cognome',
      'emailLabel': 'Email',
      'noAuthenticatedUser': 'Nessun utente autenticato',
      'logoutAccountButton': 'Esci dall\'account',
      'deleteMyAccountButton': 'Elimina il mio account',
      'deleteAccountTitle': 'Elimina account',
      'deleteAccountMessage':
          'Questa azione cancellerà definitivamente il tuo profilo (nome, cognome, email) e disconnetterà il tuo account. L\'operazione non è reversibile. Vuoi continuare?',
      'confirmYourEmailTitle': 'Conferma la tua email',
      'confirmEmailMessage':
          'Ti abbiamo inviato un\'email a {email}.\n\nApri la tua casella di posta e clicca sul pulsante "Conferma email" per attivare il tuo account Visit Gubbio.\n\nSe non trovi l\'email, controlla anche la cartella Spam o Posta indesiderata.\n\nDopo aver confermato l\'indirizzo, torna nell\'app ed effettua il login.',
      'goToLoginOk': 'OK, vai al login',
    },
    'en': {
      'welcome': 'Welcome',
      'toGubbio': 'to Gubbio',
      'discoverGubbio': 'Discover the magic of the most beautiful medieval city',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'noAccount': "Don't have an account?",
      'register': 'Register',
      'forgotPassword': 'Forgot password?',
      'enterEmail': 'Enter email',
      'invalidEmail': 'Invalid email',
      'enterPassword': 'Enter password',
      'privacyPolicy': 'Privacy Policy',
      'registration': 'Registration',
      'createAccount': 'Create your account',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'confirmPassword': 'Confirm Password',
      'haveAccount': 'Already have an account?',
      'signIn': 'Sign In',
      'enterFirstName': 'Enter first name',
      'enterLastName': 'Enter last name',
      'confirmPasswordText': 'Confirm password',
      'passwordsDontMatch': "Passwords don't match",
      'passwordMinLength': 'Minimum 6 characters',
      'resetPassword': 'Reset Password',
      'resetPasswordDescription': 'Enter your email to receive the password reset link',
      'sendResetLink': 'Send Link',
      'backToLogin': 'Back to Login',
      'loginError': 'Login error',
      'invalidCredentials': 'Invalid email or password',
      'tooManyAttempts': 'Too many attempts! Wait a few minutes and try again.',
      'emailNotConfirmed': 'Email not confirmed. Check your inbox.',
      'connectionError': 'Connection error. Check your network.',
      'userNotFound': 'Account not found. Please register first.',
      'registrationError': 'Registration error',
      'emailAlreadyInUse': 'Email already in use. Try to login.',
      'weakPassword': 'Password too weak. Use at least 6 characters.',
      'registrationSuccess': 'Registration completed! Please login.',
      'resetLinkSent':
          "Reset link sent! Check your email (and also your spam/junk folder if you don't see it).",
      'home': 'Home',
      'events': 'Events',
      'program': 'Program',
      'profile': 'Profile',
      'logout': 'Logout',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'italian': 'Italian',
      'english': 'English',
      'german': 'German',
      'french': 'French',
      'myPosition': 'My position',
      'navigate': 'Navigate',
      'distance': 'Distance',
      'walkingTime': 'Walking time',
      'minutes': 'min',
      'eventDetails': 'Event Details',
      'location': 'Location',
      'time': 'Time',
      'description': 'Description',
      'userProfile': 'User Profile',
      'editProfile': 'Edit Profile',
      'save': 'Save',
      'cancel': 'Cancel',
      'errorPrefix': 'Error',
      'requiredField': 'Required field',
      'featureUnavailable': 'Feature not available',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'menu': 'Menu',
      'deleteConfirmMessage': 'Do you want to delete "{name}"? This action cannot be undone.',
      'yourPosition': 'Your position',
      'nextEvent': 'Next event',
      'whereAmI': 'Where am I',
      'gubbioMapsLabel': 'GubbioMaps',
      'routeMapLabel': 'Route Map',
      'restaurantsNav': 'Restaurants',
      'barsNav': 'Bars',
      'mapNav': 'Map',
      'programNav': 'Program',
      'storiaDiGubbioNav': 'History of Gubbio',
      'suggestedItinerariesNav': 'Suggested itineraries',
      'userNav': 'User',
      'exitConfirmMessage': 'Do you want to sign out of your account?',
      'appVersionLabel': 'Version {version}',
      'positionUnavailable': 'Position not available',
      'searchEventsHint': 'Search events by name...',
      'noEventsFound': 'No events found',
      'tryChangeFilters': 'Try changing the search filters',
      'concluded': 'ENDED',
      'ongoing': 'ONGOING',
      'goToDetails': 'Go to details',
      'directions': 'Directions',
      'showOnMap': 'Show on map',
      'eventHeaderTitle': 'Event',
      'festaCeriLabel': 'Festa dei Ceri',
      'defaultEventDescription':
          'One of the most important events of the Festa dei Ceri of Gubbio, a tradition handed down for centuries that represents the beating heart of the city.',
      'contactsSection': 'Contacts',
      'historicalContextLabel': 'Historical Context',
      'didYouKnowLabel': 'Did you know...',
      'positionLabel': 'Location',
      'viewOnMapLabel': 'View on map',
      'editEventTitle': 'Edit Event',
      'addEventTitle': 'Add Event',
      'eventAdded': 'Event added!',
      'eventUpdated': 'Event updated!',
      'eventDeleted': 'Event deleted',
      'titleFieldLabel': 'Title',
      'titleRequiredError': 'Enter the title',
      'descriptionFieldLabel': 'Description',
      'placeFieldLabel': 'Place',
      'categoryFieldLabel': 'Category',
      'phoneFieldLabel': 'Phone',
      'websiteFieldLabel': 'Website',
      'latitudeFieldLabel': 'Latitude',
      'longitudeFieldLabel': 'Longitude',
      'dateFieldLabel': 'Date',
      'startFieldLabel': 'Start',
      'endFieldLabel': 'End',
      'saveLabel': 'SAVE',
      'saveChangesLabel': 'SAVE CHANGES',
      'editBarTitle': 'Edit Bar',
      'addBarTitle': 'Add Bar',
      'editRestaurantTitle': 'Edit Restaurant',
      'addRestaurantTitle': 'Add Restaurant',
      'barAdded': 'Bar added!',
      'barUpdated': 'Bar updated!',
      'barDeleted': 'Bar deleted',
      'nameFieldLabel': 'Name',
      'nameRequiredSimpleError': 'Enter the name',
      'tagsFieldLabel': 'Tags (comma separated, e.g. Umbrian, Italian, Medieval)',
      'ratingFieldLabel': 'Rating (TripAdvisor / Google Maps average)',
      'restaurantAdded': 'Restaurant added!',
      'restaurantUpdated': 'Restaurant updated!',
      'restaurantDeleted': 'Restaurant deleted',
      'itinerariTitle': 'Suggested itineraries',
      'itinerariDescription':
          'Routes selected to make the most of Gubbio, based on the time available and your interests.',
      'itinerarioAdded': 'Itinerary added!',
      'itinerarioUpdated': 'Itinerary updated!',
      'itinerarioDeleted': 'Itinerary deleted',
      'storiaTitle': 'History of Gubbio',
      'addFab': 'Add',
      'contenutoAdded': 'Content added!',
      'contenutoUpdated': 'Content updated!',
      'allCategories': 'All categories',
      'categoryChiesa': 'Churches',
      'categoryPalazzo': 'Palaces',
      'categoryPiazza': 'Squares',
      'categoryMonumento': 'Monuments',
      'categoryNatura': 'Nature',
      'translateExistingContentTooltip': 'Translate existing content (EN/FR/DE)',
      'addContentTitle': 'ADD CONTENT',
      'addRestaurantMenuItem': 'Add Restaurant',
      'addBarMenuItem': 'Add Bar',
      'addEventMenuItem': 'Add Event',
      'addItinerarioMenuItem': 'Add Itinerary',
      'storiaShortLabel': 'History',
      'exploreGubbioTitle': 'EXPLORE GUBBIO',
      'videoComingSoon': 'Presentation video coming soon',
      'seeAllLabel': 'See all',
      'programTitle': 'Festa dei Ceri Program',
      'tab15Mag': 'May 15',
      'tab19Mag': 'May 19',
      'tab2Giu': 'Jun 2',
      'ceriMezzani': 'Medium Ceri',
      'ceriPiccoli': 'Small Ceri',
      'comingSoonProgram': 'Program coming soon',
      'muteTitle': 'Mute',
      'newMuta': 'New Muta',
      'noMuteYet': 'No muta yet',
      'createFirstMuta': 'Create the first muta',
      'goToMapLocation': 'Go to map',
      'editMutaTitle': 'Edit Muta',
      'generalInfoSection': 'General Information',
      'mutaNameLabel': 'Muta Name',
      'nameRequiredError': 'Name is required',
      'zoneLocationLabel': 'Zone/Location',
      'zoneRequiredError': 'Zone is required',
      'capoMutaLabel': 'Muta Leader',
      'capoMutaRequiredError': 'Muta leader is required',
      'capocorsaFrontSection': 'Capocorsa (Front)',
      'capocorsaLabel': 'Capocorsa',
      'capocorsaRequiredError': 'Capocorsa is required',
      'leftExternsSection': 'Left Externs (4 ceraioli)',
      'rightExternsSection': 'Right Externs (4 ceraioli)',
      'rearInternsSection': 'Rear Interns (2 ceraioli)',
      'externalLeftLabel': 'Left Extern {n}',
      'externalRightLabel': 'Right Extern {n}',
      'internalRearLabel': 'Rear Intern {n}',
      'saveChangesButton': 'Save Changes',
      'createMutaButton': 'Create Muta',
      'deleteMutaButton': 'Delete Muta',
      'fillAllRequiredFields': 'Fill in all required fields',
      'mutaUpdatedSuccess': 'Muta updated successfully',
      'mutaCreatedSuccess': 'Muta created successfully',
      'deleteMutaConfirmMessage': 'Are you sure you want to delete this muta?',
      'mutaDeletedSuccess': 'Muta deleted',
      'personalInfoSection': 'Personal Information',
      'nameLabel': 'First Name',
      'surnameLabel': 'Last Name',
      'emailLabel': 'Email',
      'noAuthenticatedUser': 'No authenticated user',
      'logoutAccountButton': 'Sign out of account',
      'deleteMyAccountButton': 'Delete my account',
      'deleteAccountTitle': 'Delete account',
      'deleteAccountMessage':
          'This action will permanently delete your profile (first name, last name, email) and sign you out. This action cannot be undone. Do you want to continue?',
      'confirmYourEmailTitle': 'Confirm your email',
      'confirmEmailMessage':
          'We sent an email to {email}.\n\nOpen your mailbox and click the "Confirm email" button to activate your Visit Gubbio account.\n\nIf you can\'t find the email, check your Spam or Junk folder too.\n\nAfter confirming your address, return to the app and log in.',
      'goToLoginOk': 'OK, go to login',
    },
    'de': {
      'welcome': 'Willkommen',
      'toGubbio': 'in Gubbio',
      'discoverGubbio': 'Entdecke die Magie der schönsten mittelalterlichen Stadt',
      'email': 'E-Mail',
      'password': 'Passwort',
      'login': 'Anmelden',
      'noAccount': 'Noch kein Konto?',
      'register': 'Registrieren',
      'forgotPassword': 'Passwort vergessen?',
      'enterEmail': 'E-Mail eingeben',
      'invalidEmail': 'Ungültige E-Mail',
      'enterPassword': 'Passwort eingeben',
      'privacyPolicy': 'Datenschutzerklärung',
      'registration': 'Registrierung',
      'createAccount': 'Erstelle dein Konto',
      'firstName': 'Vorname',
      'lastName': 'Nachname',
      'confirmPassword': 'Passwort bestätigen',
      'haveAccount': 'Hast du schon ein Konto?',
      'signIn': 'Anmelden',
      'enterFirstName': 'Vorname eingeben',
      'enterLastName': 'Nachname eingeben',
      'confirmPasswordText': 'Passwort bestätigen',
      'passwordsDontMatch': 'Die Passwörter stimmen nicht überein',
      'passwordMinLength': 'Mindestens 6 Zeichen',
      'resetPassword': 'Passwort zurücksetzen',
      'resetPasswordDescription':
          'Gib deine E-Mail ein, um den Link zum Zurücksetzen des Passworts zu erhalten',
      'sendResetLink': 'Link senden',
      'backToLogin': 'Zurück zum Login',
      'loginError': 'Fehler beim Login',
      'invalidCredentials': 'E-Mail oder Passwort falsch',
      'tooManyAttempts': 'Zu viele Versuche! Warte ein paar Minuten und versuche es erneut.',
      'emailNotConfirmed': 'E-Mail nicht bestätigt. Überprüfe dein Postfach.',
      'connectionError': 'Verbindungsfehler. Überprüfe dein Netzwerk.',
      'userNotFound': 'Konto nicht gefunden. Bitte zuerst registrieren.',
      'registrationError': 'Fehler bei der Registrierung',
      'emailAlreadyInUse': 'E-Mail bereits registriert. Versuche dich anzumelden.',
      'weakPassword': 'Passwort zu schwach. Verwende mindestens 6 Zeichen.',
      'registrationSuccess': 'Registrierung abgeschlossen! Bitte melde dich an.',
      'resetLinkSent':
          'Link zum Zurücksetzen gesendet! Überprüfe deine E-Mail (auch den Spam-Ordner).',
      'home': 'Home',
      'events': 'Veranstaltungen',
      'program': 'Programm',
      'profile': 'Profil',
      'logout': 'Abmelden',
      'language': 'Sprache',
      'selectLanguage': 'Sprache auswählen',
      'italian': 'Italienisch',
      'english': 'Englisch',
      'german': 'Deutsch',
      'french': 'Französisch',
      'myPosition': 'Mein Standort',
      'navigate': 'Navigieren',
      'distance': 'Entfernung',
      'walkingTime': 'Gehzeit',
      'minutes': 'Min',
      'eventDetails': 'Veranstaltungsdetails',
      'location': 'Ort',
      'time': 'Uhrzeit',
      'description': 'Beschreibung',
      'userProfile': 'Benutzerprofil',
      'editProfile': 'Profil bearbeiten',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'errorPrefix': 'Fehler',
      'requiredField': 'Pflichtfeld',
      'featureUnavailable': 'Funktion nicht verfügbar',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'close': 'Schließen',
      'menu': 'Menü',
      'deleteConfirmMessage': 'Möchtest du "{name}" löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      'yourPosition': 'Dein Standort',
      'nextEvent': 'Nächste Veranstaltung',
      'whereAmI': 'Wo bin ich',
      'gubbioMapsLabel': 'GubbioMaps',
      'routeMapLabel': 'Streckenkarte',
      'restaurantsNav': 'Restaurants',
      'barsNav': 'Bars',
      'mapNav': 'Karte',
      'programNav': 'Programm',
      'storiaDiGubbioNav': 'Geschichte von Gubbio',
      'suggestedItinerariesNav': 'Empfohlene Routen',
      'userNav': 'Benutzer',
      'exitConfirmMessage': 'Möchtest du dich von deinem Konto abmelden?',
      'appVersionLabel': 'Version {version}',
      'positionUnavailable': 'Standort nicht verfügbar',
      'searchEventsHint': 'Veranstaltungen nach Namen suchen...',
      'noEventsFound': 'Keine Veranstaltungen gefunden',
      'tryChangeFilters': 'Versuche die Suchfilter zu ändern',
      'concluded': 'BEENDET',
      'ongoing': 'LÄUFT',
      'goToDetails': 'Zu den Details',
      'directions': 'Wegbeschreibung',
      'showOnMap': 'Auf der Karte anzeigen',
      'eventHeaderTitle': 'Veranstaltung',
      'festaCeriLabel': 'Festa dei Ceri',
      'defaultEventDescription':
          'Eines der wichtigsten Ereignisse der Festa dei Ceri von Gubbio, eine jahrhundertealte Tradition, die das pulsierende Herz der Stadt darstellt.',
      'contactsSection': 'Kontakte',
      'historicalContextLabel': 'Historischer Kontext',
      'didYouKnowLabel': 'Wusstest du schon...',
      'positionLabel': 'Standort',
      'viewOnMapLabel': 'Auf der Karte anzeigen',
      'editEventTitle': 'Veranstaltung bearbeiten',
      'addEventTitle': 'Veranstaltung hinzufügen',
      'eventAdded': 'Veranstaltung hinzugefügt!',
      'eventUpdated': 'Veranstaltung aktualisiert!',
      'eventDeleted': 'Veranstaltung gelöscht',
      'titleFieldLabel': 'Titel',
      'titleRequiredError': 'Titel eingeben',
      'descriptionFieldLabel': 'Beschreibung',
      'placeFieldLabel': 'Ort',
      'categoryFieldLabel': 'Kategorie',
      'phoneFieldLabel': 'Telefon',
      'websiteFieldLabel': 'Webseite',
      'latitudeFieldLabel': 'Breitengrad',
      'longitudeFieldLabel': 'Längengrad',
      'dateFieldLabel': 'Datum',
      'startFieldLabel': 'Beginn',
      'endFieldLabel': 'Ende',
      'saveLabel': 'SPEICHERN',
      'saveChangesLabel': 'ÄNDERUNGEN SPEICHERN',
      'editBarTitle': 'Bar bearbeiten',
      'addBarTitle': 'Bar hinzufügen',
      'editRestaurantTitle': 'Restaurant bearbeiten',
      'addRestaurantTitle': 'Restaurant hinzufügen',
      'barAdded': 'Bar hinzugefügt!',
      'barUpdated': 'Bar aktualisiert!',
      'barDeleted': 'Bar gelöscht',
      'nameFieldLabel': 'Name',
      'nameRequiredSimpleError': 'Namen eingeben',
      'tagsFieldLabel': 'Tags (durch Komma getrennt, z.B. Umbrisch, Italienisch, Mittelalterlich)',
      'ratingFieldLabel': 'Bewertung (TripAdvisor / Google Maps Durchschnitt)',
      'restaurantAdded': 'Restaurant hinzugefügt!',
      'restaurantUpdated': 'Restaurant aktualisiert!',
      'restaurantDeleted': 'Restaurant gelöscht',
      'itinerariTitle': 'Empfohlene Routen',
      'itinerariDescription':
          'Ausgewählte Routen, um Gubbio optimal zu erleben, je nach verfügbarer Zeit und deinen Interessen.',
      'itinerarioAdded': 'Route hinzugefügt!',
      'itinerarioUpdated': 'Route aktualisiert!',
      'itinerarioDeleted': 'Route gelöscht',
      'storiaTitle': 'Geschichte von Gubbio',
      'addFab': 'Hinzufügen',
      'contenutoAdded': 'Inhalt hinzugefügt!',
      'contenutoUpdated': 'Inhalt aktualisiert!',
      'allCategories': 'Alle Kategorien',
      'categoryChiesa': 'Kirchen',
      'categoryPalazzo': 'Paläste',
      'categoryPiazza': 'Plätze',
      'categoryMonumento': 'Denkmäler',
      'categoryNatura': 'Natur',
      'translateExistingContentTooltip': 'Vorhandene Inhalte übersetzen (EN/FR/DE)',
      'addContentTitle': 'INHALT HINZUFÜGEN',
      'addRestaurantMenuItem': 'Restaurant hinzufügen',
      'addBarMenuItem': 'Bar hinzufügen',
      'addEventMenuItem': 'Veranstaltung hinzufügen',
      'addItinerarioMenuItem': 'Route hinzufügen',
      'storiaShortLabel': 'Geschichte',
      'exploreGubbioTitle': 'GUBBIO ENTDECKEN',
      'videoComingSoon': 'Präsentationsvideo in Kürze verfügbar',
      'seeAllLabel': 'Alle anzeigen',
      'programTitle': 'Programm der Festa dei Ceri',
      'tab15Mag': '15. Mai',
      'tab19Mag': '19. Mai',
      'tab2Giu': '2. Jun',
      'ceriMezzani': 'Mittlere Ceri',
      'ceriPiccoli': 'Kleine Ceri',
      'comingSoonProgram': 'Programm folgt in Kürze',
      'muteTitle': 'Mute',
      'newMuta': 'Neue Muta',
      'noMuteYet': 'Noch keine Muta vorhanden',
      'createFirstMuta': 'Erste Muta erstellen',
      'goToMapLocation': 'Zur Karte',
      'editMutaTitle': 'Muta bearbeiten',
      'generalInfoSection': 'Allgemeine Informationen',
      'mutaNameLabel': 'Name der Muta',
      'nameRequiredError': 'Der Name ist erforderlich',
      'zoneLocationLabel': 'Zone/Ort',
      'zoneRequiredError': 'Die Zone ist erforderlich',
      'capoMutaLabel': 'Muta-Anführer',
      'capoMutaRequiredError': 'Der Muta-Anführer ist erforderlich',
      'capocorsaFrontSection': 'Capocorsa (Vorne)',
      'capocorsaLabel': 'Capocorsa',
      'capocorsaRequiredError': 'Der Capocorsa ist erforderlich',
      'leftExternsSection': 'Außen Links (4 Ceraioli)',
      'rightExternsSection': 'Außen Rechts (4 Ceraioli)',
      'rearInternsSection': 'Innen Hinten (2 Ceraioli)',
      'externalLeftLabel': 'Außen Links {n}',
      'externalRightLabel': 'Außen Rechts {n}',
      'internalRearLabel': 'Innen Hinten {n}',
      'saveChangesButton': 'Änderungen speichern',
      'createMutaButton': 'Muta erstellen',
      'deleteMutaButton': 'Muta löschen',
      'fillAllRequiredFields': 'Fülle alle Pflichtfelder aus',
      'mutaUpdatedSuccess': 'Muta erfolgreich bearbeitet',
      'mutaCreatedSuccess': 'Muta erfolgreich erstellt',
      'deleteMutaConfirmMessage': 'Möchtest du diese Muta wirklich löschen?',
      'mutaDeletedSuccess': 'Muta gelöscht',
      'personalInfoSection': 'Persönliche Informationen',
      'nameLabel': 'Vorname',
      'surnameLabel': 'Nachname',
      'emailLabel': 'E-Mail',
      'noAuthenticatedUser': 'Kein authentifizierter Benutzer',
      'logoutAccountButton': 'Vom Konto abmelden',
      'deleteMyAccountButton': 'Mein Konto löschen',
      'deleteAccountTitle': 'Konto löschen',
      'deleteAccountMessage':
          'Diese Aktion löscht dein Profil (Vorname, Nachname, E-Mail) dauerhaft und meldet dich ab. Diese Aktion kann nicht rückgängig gemacht werden. Möchtest du fortfahren?',
      'confirmYourEmailTitle': 'Bestätige deine E-Mail',
      'confirmEmailMessage':
          'Wir haben eine E-Mail an {email} gesendet.\n\nÖffne dein Postfach und klicke auf "E-Mail bestätigen", um dein Visit-Gubbio-Konto zu aktivieren.\n\nFalls du die E-Mail nicht findest, überprüfe auch deinen Spam-Ordner.\n\nNach der Bestätigung kehre zur App zurück und melde dich an.',
      'goToLoginOk': 'OK, zum Login',
    },
    'fr': {
      'welcome': 'Bienvenue',
      'toGubbio': 'à Gubbio',
      'discoverGubbio': 'Découvrez la magie de la plus belle ville médiévale',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'login': 'Connexion',
      'noAccount': "Vous n'avez pas de compte ?",
      'register': "S'inscrire",
      'forgotPassword': 'Mot de passe oublié ?',
      'enterEmail': 'Entrez votre e-mail',
      'invalidEmail': 'E-mail invalide',
      'enterPassword': 'Entrez votre mot de passe',
      'privacyPolicy': 'Politique de confidentialité',
      'registration': 'Inscription',
      'createAccount': 'Créez votre compte',
      'firstName': 'Prénom',
      'lastName': 'Nom',
      'confirmPassword': 'Confirmez le mot de passe',
      'haveAccount': 'Vous avez déjà un compte ?',
      'signIn': 'Se connecter',
      'enterFirstName': 'Entrez le prénom',
      'enterLastName': 'Entrez le nom',
      'confirmPasswordText': 'Confirmez le mot de passe',
      'passwordsDontMatch': 'Les mots de passe ne correspondent pas',
      'passwordMinLength': 'Minimum 6 caractères',
      'resetPassword': 'Réinitialiser le mot de passe',
      'resetPasswordDescription':
          'Entrez votre e-mail pour recevoir le lien de réinitialisation du mot de passe',
      'sendResetLink': 'Envoyer le lien',
      'backToLogin': 'Retour à la connexion',
      'loginError': 'Erreur de connexion',
      'invalidCredentials': 'E-mail ou mot de passe incorrect',
      'tooManyAttempts': 'Trop de tentatives ! Attendez quelques minutes et réessayez.',
      'emailNotConfirmed': 'E-mail non confirmé. Vérifiez votre boîte de réception.',
      'connectionError': 'Erreur de connexion. Vérifiez votre réseau.',
      'userNotFound': "Compte introuvable. Inscrivez-vous d'abord.",
      'registrationError': "Erreur lors de l'inscription",
      'emailAlreadyInUse': 'E-mail déjà utilisé. Essayez de vous connecter.',
      'weakPassword': 'Mot de passe trop faible. Utilisez au moins 6 caractères.',
      'registrationSuccess': 'Inscription terminée ! Veuillez vous connecter.',
      'resetLinkSent':
          'Lien de réinitialisation envoyé ! Vérifiez votre e-mail (et le dossier spam).',
      'home': 'Accueil',
      'events': 'Événements',
      'program': 'Programme',
      'profile': 'Profil',
      'logout': 'Déconnexion',
      'language': 'Langue',
      'selectLanguage': 'Choisir la langue',
      'italian': 'Italien',
      'english': 'Anglais',
      'german': 'Allemand',
      'french': 'Français',
      'myPosition': 'Ma position',
      'navigate': 'Naviguer',
      'distance': 'Distance',
      'walkingTime': 'Temps à pied',
      'minutes': 'min',
      'eventDetails': "Détails de l'événement",
      'location': 'Lieu',
      'time': 'Horaire',
      'description': 'Description',
      'userProfile': 'Profil utilisateur',
      'editProfile': 'Modifier le profil',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'errorPrefix': 'Erreur',
      'requiredField': 'Champ obligatoire',
      'featureUnavailable': 'Fonctionnalité non disponible',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'menu': 'Menu',
      'deleteConfirmMessage': 'Voulez-vous supprimer "{name}" ? Cette action est irréversible.',
      'yourPosition': 'Votre position',
      'nextEvent': 'Prochain événement',
      'whereAmI': 'Où suis-je',
      'gubbioMapsLabel': 'GubbioMaps',
      'routeMapLabel': 'Carte du parcours',
      'restaurantsNav': 'Restaurants',
      'barsNav': 'Bars',
      'mapNav': 'Carte',
      'programNav': 'Programme',
      'storiaDiGubbioNav': 'Histoire de Gubbio',
      'suggestedItinerariesNav': 'Itinéraires suggérés',
      'userNav': 'Utilisateur',
      'exitConfirmMessage': 'Voulez-vous vous déconnecter de votre compte ?',
      'appVersionLabel': 'Version {version}',
      'positionUnavailable': 'Position non disponible',
      'searchEventsHint': 'Rechercher des événements par nom...',
      'noEventsFound': 'Aucun événement trouvé',
      'tryChangeFilters': 'Essayez de modifier les filtres de recherche',
      'concluded': 'TERMINÉ',
      'ongoing': 'EN COURS',
      'goToDetails': 'Voir les détails',
      'directions': 'Itinéraire',
      'showOnMap': 'Afficher sur la carte',
      'eventHeaderTitle': 'Événement',
      'festaCeriLabel': 'Festa dei Ceri',
      'defaultEventDescription':
          'L\'un des événements les plus importants de la Festa dei Ceri de Gubbio, une tradition séculaire qui représente le cœur battant de la ville.',
      'contactsSection': 'Contacts',
      'historicalContextLabel': 'Contexte historique',
      'didYouKnowLabel': 'Le saviez-vous...',
      'positionLabel': 'Emplacement',
      'viewOnMapLabel': 'Voir sur la carte',
      'editEventTitle': 'Modifier l\'événement',
      'addEventTitle': 'Ajouter un événement',
      'eventAdded': 'Événement ajouté !',
      'eventUpdated': 'Événement mis à jour !',
      'eventDeleted': 'Événement supprimé',
      'titleFieldLabel': 'Titre',
      'titleRequiredError': 'Entrez le titre',
      'descriptionFieldLabel': 'Description',
      'placeFieldLabel': 'Lieu',
      'categoryFieldLabel': 'Catégorie',
      'phoneFieldLabel': 'Téléphone',
      'websiteFieldLabel': 'Site web',
      'latitudeFieldLabel': 'Latitude',
      'longitudeFieldLabel': 'Longitude',
      'dateFieldLabel': 'Date',
      'startFieldLabel': 'Début',
      'endFieldLabel': 'Fin',
      'saveLabel': 'ENREGISTRER',
      'saveChangesLabel': 'ENREGISTRER LES MODIFICATIONS',
      'editBarTitle': 'Modifier le bar',
      'addBarTitle': 'Ajouter un bar',
      'editRestaurantTitle': 'Modifier le restaurant',
      'addRestaurantTitle': 'Ajouter un restaurant',
      'barAdded': 'Bar ajouté !',
      'barUpdated': 'Bar mis à jour !',
      'barDeleted': 'Bar supprimé',
      'nameFieldLabel': 'Nom',
      'nameRequiredSimpleError': 'Entrez le nom',
      'tagsFieldLabel': 'Tags (séparés par des virgules, ex. Ombrienne, Italienne, Médiévale)',
      'ratingFieldLabel': 'Évaluation (moyenne TripAdvisor / Google Maps)',
      'restaurantAdded': 'Restaurant ajouté !',
      'restaurantUpdated': 'Restaurant mis à jour !',
      'restaurantDeleted': 'Restaurant supprimé',
      'itinerariTitle': 'Itinéraires suggérés',
      'itinerariDescription':
          'Parcours sélectionnés pour profiter au mieux de Gubbio, selon le temps disponible et vos intérêts.',
      'itinerarioAdded': 'Itinéraire ajouté !',
      'itinerarioUpdated': 'Itinéraire mis à jour !',
      'itinerarioDeleted': 'Itinéraire supprimé',
      'storiaTitle': 'Histoire de Gubbio',
      'addFab': 'Ajouter',
      'contenutoAdded': 'Contenu ajouté !',
      'contenutoUpdated': 'Contenu mis à jour !',
      'allCategories': 'Toutes les catégories',
      'categoryChiesa': 'Églises',
      'categoryPalazzo': 'Palais',
      'categoryPiazza': 'Places',
      'categoryMonumento': 'Monuments',
      'categoryNatura': 'Nature',
      'translateExistingContentTooltip': 'Traduire le contenu existant (EN/FR/DE)',
      'addContentTitle': 'AJOUTER DU CONTENU',
      'addRestaurantMenuItem': 'Ajouter un restaurant',
      'addBarMenuItem': 'Ajouter un bar',
      'addEventMenuItem': 'Ajouter un événement',
      'addItinerarioMenuItem': 'Ajouter un itinéraire',
      'storiaShortLabel': 'Histoire',
      'exploreGubbioTitle': 'EXPLORER GUBBIO',
      'videoComingSoon': 'Vidéo de présentation bientôt disponible',
      'seeAllLabel': 'Voir tout',
      'programTitle': 'Programme de la Festa dei Ceri',
      'tab15Mag': '15 mai',
      'tab19Mag': '19 mai',
      'tab2Giu': '2 juin',
      'ceriMezzani': 'Ceri moyens',
      'ceriPiccoli': 'Petits Ceri',
      'comingSoonProgram': 'Programme à venir',
      'muteTitle': 'Mute',
      'newMuta': 'Nouvelle Muta',
      'noMuteYet': 'Aucune muta pour le moment',
      'createFirstMuta': 'Créer la première muta',
      'goToMapLocation': 'Voir sur la carte',
      'editMutaTitle': 'Modifier la Muta',
      'generalInfoSection': 'Informations générales',
      'mutaNameLabel': 'Nom de la Muta',
      'nameRequiredError': 'Le nom est obligatoire',
      'zoneLocationLabel': 'Zone/Lieu',
      'zoneRequiredError': 'La zone est obligatoire',
      'capoMutaLabel': 'Chef de la Muta',
      'capoMutaRequiredError': 'Le chef de la muta est obligatoire',
      'capocorsaFrontSection': 'Capocorsa (Avant)',
      'capocorsaLabel': 'Capocorsa',
      'capocorsaRequiredError': 'Le capocorsa est obligatoire',
      'leftExternsSection': 'Externes Gauche (4 ceraioli)',
      'rightExternsSection': 'Externes Droite (4 ceraioli)',
      'rearInternsSection': 'Internes Arrière (2 ceraioli)',
      'externalLeftLabel': 'Externe Gauche {n}',
      'externalRightLabel': 'Externe Droit {n}',
      'internalRearLabel': 'Interne Arrière {n}',
      'saveChangesButton': 'Enregistrer les modifications',
      'createMutaButton': 'Créer la Muta',
      'deleteMutaButton': 'Supprimer la Muta',
      'fillAllRequiredFields': 'Remplissez tous les champs obligatoires',
      'mutaUpdatedSuccess': 'Muta modifiée avec succès',
      'mutaCreatedSuccess': 'Muta créée avec succès',
      'deleteMutaConfirmMessage': 'Êtes-vous sûr de vouloir supprimer cette muta ?',
      'mutaDeletedSuccess': 'Muta supprimée',
      'personalInfoSection': 'Informations personnelles',
      'nameLabel': 'Prénom',
      'surnameLabel': 'Nom',
      'emailLabel': 'E-mail',
      'noAuthenticatedUser': 'Aucun utilisateur authentifié',
      'logoutAccountButton': 'Se déconnecter du compte',
      'deleteMyAccountButton': 'Supprimer mon compte',
      'deleteAccountTitle': 'Supprimer le compte',
      'deleteAccountMessage':
          'Cette action supprimera définitivement votre profil (prénom, nom, e-mail) et vous déconnectera. Cette action est irréversible. Voulez-vous continuer ?',
      'confirmYourEmailTitle': 'Confirmez votre e-mail',
      'confirmEmailMessage':
          'Nous avons envoyé un e-mail à {email}.\n\nOuvrez votre boîte de réception et cliquez sur le bouton "Confirmer l\'e-mail" pour activer votre compte Visit Gubbio.\n\nSi vous ne trouvez pas l\'e-mail, vérifiez aussi votre dossier spam.\n\nAprès confirmation, revenez dans l\'application et connectez-vous.',
      'goToLoginOk': 'OK, aller à la connexion',
    },
  };
}
