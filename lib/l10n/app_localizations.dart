/// Traduzioni per l'app - Italiano e Inglese
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String code) {
    return AppLocalizations(code);
  }

  // ============== LOGIN PAGE ==============
  String get welcome => languageCode == 'it' ? 'Benvenuto' : 'Welcome';
  String get toGubbio => languageCode == 'it' ? 'a Gubbio' : 'to Gubbio';
  String get discoverGubbio => languageCode == 'it' ? 'Scopri la magia della più bella città medievale' : 'Discover the magic of the most beautiful medieval city';
  String get email => languageCode == 'it' ? 'Email' : 'Email';
  String get password => languageCode == 'it' ? 'Password' : 'Password';
  String get login => languageCode == 'it' ? 'Accedi' : 'Login';
  String get noAccount => languageCode == 'it' ? 'Non hai un account?' : 'Don\'t have an account?';
  String get register => languageCode == 'it' ? 'Registrati' : 'Register';
  String get forgotPassword => languageCode == 'it' ? 'Password dimenticata?' : 'Forgot password?';
  String get enterEmail => languageCode == 'it' ? 'Inserisci email' : 'Enter email';
  String get invalidEmail => languageCode == 'it' ? 'Email non valida' : 'Invalid email';
  String get enterPassword => languageCode == 'it' ? 'Inserisci password' : 'Enter password';
  
  // ============== REGISTER PAGE ==============
  String get registration => languageCode == 'it' ? 'Registrazione' : 'Registration';
  String get createAccount => languageCode == 'it' ? 'Crea il tuo account' : 'Create your account';
  String get firstName => languageCode == 'it' ? 'Nome' : 'First Name';
  String get lastName => languageCode == 'it' ? 'Cognome' : 'Last Name';
  String get confirmPassword => languageCode == 'it' ? 'Conferma Password' : 'Confirm Password';
  String get haveAccount => languageCode == 'it' ? 'Hai già un account?' : 'Already have an account?';
  String get signIn => languageCode == 'it' ? 'Accedi' : 'Sign In';
  
  // Validazioni
  String get enterFirstName => languageCode == 'it' ? 'Inserisci il nome' : 'Enter first name';
  String get enterLastName => languageCode == 'it' ? 'Inserisci il cognome' : 'Enter last name';
  String get confirmPasswordText => languageCode == 'it' ? 'Conferma la password' : 'Confirm password';
  String get passwordsDontMatch => languageCode == 'it' ? 'Le password non coincidono' : 'Passwords don\'t match';
  String get passwordMinLength => languageCode == 'it' ? 'Minimo 6 caratteri' : 'Minimum 6 characters';
  
  // ============== FORGOT PASSWORD PAGE ==============
  String get resetPassword => languageCode == 'it' ? 'Recupera Password' : 'Reset Password';
  String get resetPasswordDescription => languageCode == 'it' 
      ? 'Inserisci la tua email per ricevere il link di recupero password' 
      : 'Enter your email to receive the password reset link';
  String get sendResetLink => languageCode == 'it' ? 'Invia Link' : 'Send Link';
  String get backToLogin => languageCode == 'it' ? 'Torna al Login' : 'Back to Login';
  
  // ============== ERRORI ==============
  String get loginError => languageCode == 'it' ? 'Errore durante il login' : 'Login error';
  String get invalidCredentials => languageCode == 'it' ? 'Email o password non corretti' : 'Invalid email or password';
  String get tooManyAttempts => languageCode == 'it' 
      ? 'Troppi tentativi! Attendi qualche minuto e riprova.' 
      : 'Too many attempts! Wait a few minutes and try again.';
  String get emailNotConfirmed => languageCode == 'it' 
      ? 'Email non confermata. Controlla la tua casella di posta.' 
      : 'Email not confirmed. Check your inbox.';
  String get connectionError => languageCode == 'it' 
      ? 'Errore di connessione. Controlla la tua rete.' 
      : 'Connection error. Check your network.';
  String get userNotFound => languageCode == 'it' 
      ? 'Account non trovato. Registrati prima.' 
      : 'Account not found. Please register first.';
  String get registrationError => languageCode == 'it' ? 'Errore durante la registrazione' : 'Registration error';
  String get emailAlreadyInUse => languageCode == 'it' 
      ? 'Email già registrata. Prova ad effettuare il login.' 
      : 'Email already in use. Try to login.';
  String get weakPassword => languageCode == 'it' 
      ? 'Password troppo debole. Usa almeno 6 caratteri.' 
      : 'Password too weak. Use at least 6 characters.';
  String get registrationSuccess => languageCode == 'it' 
      ? 'Registrazione completata! Effettua il login.' 
      : 'Registration completed! Please login.';
  String get resetLinkSent => languageCode == 'it' 
      ? 'Link di recupero inviato! Controlla la tua email.' 
      : 'Reset link sent! Check your email.';
  
  // ============== HOME PAGE ==============
  String get home => languageCode == 'it' ? 'Home' : 'Home';
  String get events => languageCode == 'it' ? 'Eventi' : 'Events';
  String get program => languageCode == 'it' ? 'Programma' : 'Program';
  String get profile => languageCode == 'it' ? 'Profilo' : 'Profile';
  String get logout => languageCode == 'it' ? 'Esci' : 'Logout';
  String get language => languageCode == 'it' ? 'Lingua' : 'Language';
  String get italian => languageCode == 'it' ? 'Italiano' : 'Italian';
  String get english => languageCode == 'it' ? 'Inglese' : 'English';
  
  // ============== MAP ==============
  String get myPosition => languageCode == 'it' ? 'La mia posizione' : 'My position';
  String get navigate => languageCode == 'it' ? 'Naviga' : 'Navigate';
  String get distance => languageCode == 'it' ? 'Distanza' : 'Distance';
  String get walkingTime => languageCode == 'it' ? 'Tempo a piedi' : 'Walking time';
  String get minutes => languageCode == 'it' ? 'min' : 'min';
  
  // ============== EVENTI ==============
  String get eventDetails => languageCode == 'it' ? 'Dettagli Evento' : 'Event Details';
  String get location => languageCode == 'it' ? 'Luogo' : 'Location';
  String get time => languageCode == 'it' ? 'Orario' : 'Time';
  String get description => languageCode == 'it' ? 'Descrizione' : 'Description';
  
  // ============== PROFILO ==============
  String get userProfile => languageCode == 'it' ? 'Profilo Utente' : 'User Profile';
  String get editProfile => languageCode == 'it' ? 'Modifica Profilo' : 'Edit Profile';
  String get save => languageCode == 'it' ? 'Salva' : 'Save';
  String get cancel => languageCode == 'it' ? 'Annulla' : 'Cancel';
}
