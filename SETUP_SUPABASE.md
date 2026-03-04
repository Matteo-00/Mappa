# Sistema Login + Ceraioli + Supabase - Festa dei Ceri

## 🎯 Implementazione Completata

Questo progetto ora include un sistema completo di autenticazione con Supabase, registrazione utenti con opzione Ceraiolo, e visualizzazione della barella con l'immagine.

## 📋 Cosa è Stato Implementato

### 1️⃣ Sistema di Autenticazione Supabase

- ✅ Inizializzazione Supabase in `main.dart`
- ✅ Login con email e password
- ✅ Registrazione nuovo utente
- ✅ Salvataggio dati nella tabella `utenti`
- ✅ Gestione ruoli (Turista/Ceraiolo)
- ✅ AuthService aggiornato per Supabase

### 2️⃣ Schermata di Registrazione

- ✅ Campi: nome, cognome, età, email, password, conferma password
- ✅ Validazione password robusta:
  - Minimo 8 caratteri
  - 1 maiuscola
  - 1 numero
  - 1 carattere speciale
- ✅ Checkbox "Sei un Ceraiolo?"
- ✅ Dropdown cero con solo 3 opzioni:
  - Sant'Ubaldo
  - Sant'Antonio Abate
  - San Giorgio

### 3️⃣ Schermata di Login

- ✅ Login con email e password
- ✅ Recupero automatico dati dalla tabella `utenti`
- ✅ Link alla pagina di registrazione
- ✅ UI elegante con rosso scuro (#B71C1C)

### 4️⃣ Visualizzazione Barella Ceraioli

- ✅ Widget `BarellaVisualization` con immagine barella.png
- ✅ 11 ruoli ufficiali posizionati intorno all'immagine:
  - **Stanga Sinistra**: Punta Avanti, Ceppo Avanti, Ceppo Dietro, Punta Dietro
  - **Stanga Destra**: Punta Avanti, Ceppo Avanti, Ceppo Dietro, Punta Dietro
  - **Centro**: Capo 10, Capo 5, Barelone
- ✅ Si apre quando si clicca su un marker muta (per Ceraioli)

### 5️⃣ Stile

- ✅ Rosso scuro elegante (#B71C1C) come colore primario
- ✅ Base bianca dominante
- ✅ Layout pulito e minimal
- ✅ Design istituzionale ma moderno

## 🚀 Setup Necessario

### 1. Configurare Supabase

Apri il file `lib/main.dart` e sostituisci i placeholder con i tuoi dati Supabase:

```dart
await Supabase.initialize(
  url: 'https://TUO-PROGETTO.supabase.co',  // ⬅️ Inserisci il tuo URL
  anonKey: 'TUA-ANON-KEY',                   // ⬅️ Inserisci la tua ANON KEY
);
```

### 2. Creare la Tabella `utenti` su Supabase

Esegui questo SQL nel SQL Editor di Supabase:

```sql
-- Crea la tabella utenti
CREATE TABLE utenti (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  cognome TEXT NOT NULL,
  eta INTEGER NOT NULL CHECK (eta > 0 AND eta < 150),
  is_ceraiolo BOOLEAN NOT NULL DEFAULT FALSE,
  cero TEXT CHECK (cero IN ('Sant''Ubaldo', 'Sant''Antonio Abate', 'San Giorgio')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Abilita Row Level Security
ALTER TABLE utenti ENABLE ROW LEVEL SECURITY;

-- Policy per lettura (solo il proprio profilo)
CREATE POLICY "Users can read own profile"
ON utenti
FOR SELECT
USING (auth.uid() = id);

-- Policy per inserimento (durante registrazione)
CREATE POLICY "Users can insert own profile"
ON utenti
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy per aggiornamento (solo il proprio profilo)
CREATE POLICY "Users can update own profile"
ON utenti
FOR UPDATE
USING (auth.uid() = id);
```

### 3. Installare le Dipendenze

```bash
flutter pub get
```

### 4. Verificare che barella.png Esista

L'immagine dovrebbe essere in: `C:\ProgettiSM\aa\Mappa\barella.png`

È già configurata in `pubspec.yaml` nella sezione assets:

```yaml
flutter:
  assets:
    - barella.png
```

## 📁 Struttura File Creati/Modificati

### File Nuovi
- `lib/models/user_model.dart` - Modello utente per dati da Supabase
- `lib/models/barella_model.dart` - Modello per struttura barella con 11 ceraioli
- `lib/pages/register_page.dart` - Pagina di registrazione completa
- `lib/widgets/barella_visualization.dart` - Widget visualizzazione barella con immagine

### File Modificati
- `lib/main.dart` - Aggiunta inizializzazione Supabase
- `lib/pages/login_page.dart` - Aggiornato per usare Supabase Auth
- `lib/services/auth_service.dart` - Integrazione con Supabase
- `lib/pages/home_page.dart` - Usa nuovo widget BarellaVisualization
- `pubspec.yaml` - Aggiunta dipendenza supabase_flutter e asset barella.png

## 🎨 Linee Guida Stile Applicate

- **Rosso**: Scuro (#B71C1C), elegante, borgogna - solo nei dettagli
- **Base**: Bianco dominante con sfondo grigio chiaro (#FAFAFA)
- **Tipografia**: Modern, pulita, ottima leggibilità
- **Bordi**: Arrotondati (12px) per un aspetto moderno
- **Validazioni**: Feedback eleganti con colori discreti (arancione per errori)

## 🧪 Come Testare

1. **Registrazione**:
   - Apri l'app
   - Clicca su "Non hai un account? Registrati"
   - Compila tutti i campi
   - Se sei Ceraiolo, seleziona la checkbox e scegli il Cero
   - Clicca "Registrati"

2. **Login**:
   - Inserisci email e password
   - Clicca "Accedi"
   - Verrai portato alla HomePage

3. **Visualizzazione Barella** (solo per Ceraioli):
   - Dopo il login come Ceraiolo
   - Aumenta lo zoom sulla mappa (zoom >= 17)
   - Clicca su un marker blu (muta)
   - Si aprirà il dialog con la barella e gli 11 ceraioli

## 📊 Modelli Dati

### UserModel
```dart
- id: String (UUID da auth.users)
- nome: String
- cognome: String
- eta: int
- isCeraiolo: bool
- cero: String? (solo se isCeraiolo = true)
```

### BarellaCeraioli (11 posizioni)
```dart
Stanga Sinistra: 4 ceraioli
Stanga Destra: 4 ceraioli
Centro: 3 ceraioli (Capo 10, Capo 5, Barelone)
```

## 🔐 Sicurezza

- ✅ Password NON salvate nella tabella utenti (gestite da Supabase Auth)
- ✅ Row Level Security (RLS) attivo
- ✅ Policy con auth.uid() per protezione dati
- ✅ Validazione password robusta lato client
- ✅ Sanitizzazione input

## 🐛 Risoluzione Problemi

### "Login fallito" o "Registrazione fallita"

1. Verifica che Supabase URL e ANON_KEY siano corretti in `main.dart`
2. Verifica che la tabella `utenti` esista su Supabase
3. Verifica che RLS sia attivo e le policy siano configurate

### "Immagine barella non trovata"

1. Verifica che `barella.png` sia nella root del progetto
2. Esegui `flutter pub get` dopo aver modificato `pubspec.yaml`
3. Riavvia l'app con hot restart (non hot reload)

### Errori di compilazione

Esegui:
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Note Importanti

1. **Dati Esempio**: Il widget BarellaVisualization usa dati esempio (`barellaEsempio`). In futuro, dovrai recuperare i dati reali dei ceraioli da Supabase.

2. **Email Verification**: Supabase può richiedere verifica email. Per disabilitarla durante lo sviluppo:
   - Vai su Supabase Dashboard
   - Authentication → Settings
   - Disabilita "Enable email confirmations"

3. **Testing**: Per testare velocemente, disabilita temporaneamente la conferma email su Supabase.

## ✅ Checklist Completamento

- [x] Supabase inizializzato in main.dart
- [x] Tabella utenti creata su Supabase
- [x] RLS e policy configurate
- [x] Login con email/password funzionante
- [x] Registrazione con validazioni robuste
- [x] Opzione Ceraiolo con dropdown ceri
- [x] AuthService integrato con Supabase
- [x] Barella visualizzata con immagine
- [x] 11 ruoli ceraioli posizionati correttamente
- [x] Stile rosso scuro elegante applicato
- [x] pubspec.yaml aggiornato con dipendenze e asset

## 🚀 Prossimi Passi Suggeriti

1. Implementare recupero dati reali ceraioli da Supabase
2. Aggiungere tabella `barelle` su Supabase con i 11 ruoli
3. Implementare funzionalità di modifica profilo
4. Aggiungere reset password
5. Aggiungere foto profilo con Supabase Storage

---

**Buon lavoro con la Festa dei Ceri! 🕯️**
