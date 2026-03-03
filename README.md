# 🔥 Festa dei Ceri - App Mobile

App mobile elegante e professionale per Android e iOS dedicata alla **Festa dei Ceri di Gubbio**.

## ✨ Caratteristiche

### 🔐 Login
- **Username:** admin
- **Password Turista:** adminturista
- **Password Ceraiolo:** adminceraiolo

### 🗺️ Mappa Interattiva
- Visualizzazione del percorso ufficiale dei Ceri
- Marker per eventi (Turista) o mute (Ceraiolo)
- Geolocalizzazione in tempo reale
- Calcolo distanza
- Navigazione pedonale integrata con Google Maps

### 👤 Modalità Turista
- Lista eventi della giornata del 15 maggio
- Orari, descrizioni, luoghi
- Accesso rapido a mappa e indicazioni
- Design emozionale ed elegante

### 👥 Modalità Ceraiolo
- Visualizzazione mute lungo il percorso
- Informazioni tecniche per ogni punto strategico
- Strumento funzionale e professionale

## 🎨 Design

- **Colori:** Base neutra (bianco/grigio) con rosso (#B71C1C) come accento
- **Material 3:** Design system moderno
- **Tipografia:** Font eleganti e leggibili
- **UI/UX:** Minimalista, funzionale, senza elementi superflui

## 🚀 Setup

### Prerequisiti
- Flutter SDK (^3.11.0)
- Android Studio / Xcode
- Google Maps API Key (già configurata)

### Installazione

```bash
# Clone del progetto
cd mappa

# Installazione dipendenze
flutter pub get

# Run su dispositivo/emulatore
flutter run
```

### Configurazione Google Maps

**Android:** API Key già configurata in `android/app/src/main/AndroidManifest.xml`

**iOS:** Aggiungi la tua API Key in `ios/Runner/AppDelegate.swift` se necessario

## 📱 Permessi

### Android
- `ACCESS_FINE_LOCATION` - Geolocalizzazione precisa
- `ACCESS_COARSE_LOCATION` - Geolocalizzazione approssimativa
- `INTERNET` - Connessione per mappe e navigazione

### iOS
- `NSLocationWhenInUseUsageDescription` - Accesso posizione durante l'uso
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Accesso posizione sempre

## 📦 Dipendenze Principali

- `google_maps_flutter` - Mappe interattive
- `geolocator` - Geolocalizzazione
- `permission_handler` - Gestione permessi
- `url_launcher` - Navigazione esterna
- `provider` - State management

## 🏗️ Struttura Progetto

```
lib/
├── main.dart                    # Entry point
├── models/                      # Modelli dati
│   ├── user_mode.dart
│   ├── event_model.dart
│   └── muta_model.dart
├── services/                    # Servizi business logic
│   ├── auth_service.dart
│   └── location_service.dart
├── data/                        # Dati demo
│   ├── events_data.dart
│   └── mute_data.dart
├── pages/                       # Schermate
│   ├── login_page.dart
│   ├── home_page.dart
│   └── turista_events_page.dart
└── widgets/                     # Widget comuni
    ├── map_action_button.dart
    └── event_card.dart
```

## 🎯 Funzionalità Implementate

✅ Login con credenziali demo  
✅ Mappa centrale con percorso Ceri  
✅ Geolocalizzazione utente  
✅ Calcolo distanza a piedi  
✅ Navigazione pedonale Google Maps  
✅ Modalità Turista con eventi  
✅ Modalità Ceraiolo con mute  
✅ UI elegante e professionale  
✅ Design responsive Android/iOS  
✅ Permessi configurati  

## 🔮 Possibilità Future

- Push notifications per eventi
- Aggiornamenti live in tempo reale
- Mappe offline
- Galleria foto
- Chat community
- Timeline storica

## 📱 Compatibilità

- **Android:** 5.0+ (API 21+)
- **iOS:** 12.0+

## 📄 Licenza

Progetto privato - Festa dei Ceri Gubbio

---

**Sviluppato con ❤️ utilizzando Flutter**
