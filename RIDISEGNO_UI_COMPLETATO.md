# Ridisegno Completo UI - App "15 Maggio – Festa dei Ceri"

## ✅ Modifiche Implementate

Il ridisegno completo dell'interfaccia utente è stato completato con successo seguendo esattamente le specifiche richieste.

---

## 🎨 Stile Grafico

### Colori Implementati
- **Bianco dominante**: `#FFFFFF` - colore principale dell'app
- **Rosso principale**: `#B22222` - per header, icone attive, pulsanti
- **Rosso hover**: `#C0392B` - per stati attivi
- **Blu posizione**: `#2F80ED` - marker posizione utente
- **Grigio testo**: `#6B6B6B` - testo secondario
- **Grigio separatori**: `#EAEAEA` - bordi e divisori

### Design Pulito
✅ Nessun gradiente  
✅ Nessun rosa o rosso acceso  
✅ Ombre leggerissime  
✅ Stile elegante, moderno e istituzionale  

---

## 🎯 Componenti Principali

### 1️⃣ Header Fisso (`CustomHeader`)
- **Altezza**: 60px
- **Sinistra**: Icona casa rossa + testo "15 Maggio"
- **Destra**: Avatar utente con menu dropdown
- **Menu**: Profilo Utente | Logout
- **File**: `lib/widgets/custom_header.dart`

### 2️⃣ Footer Fisso (`CustomBottomNav`)
- **Altezza**: 70px
- **Icone**:
  - 🏠 **Home** - torna alla home
  - 📍 **Dove sono** - geolocalizzazione
  - 📅 **Programma** - timeline eventi
  - 👥 **Mute** - solo per ceraioli
- **File**: `lib/widgets/custom_bottom_nav.dart`

### 3️⃣ Popup di Benvenuto (`WelcomePopup`)
- Card bianca con ombra elegante
- Titolo: "Benvenuto alla Festa dei Ceri"
- Sottotitolo rosso: "Oggi, [data]"
- Immagine segnaposto Ceri
- Info prossimo evento
- Pulsante rosso: "Vedi programma"
- X per chiudere (in alto a destra)
- **File**: `lib/widgets/welcome_popup.dart`

### 4️⃣ Timeline Eventi (`EventTimeline`)
- Linea verticale del tempo a sinistra
- Eventi ordinati per orario
- **Stati automatici**:
  - ⏹️ **Passato**: card oscurata, testo grigio
  - ▶️ **In corso**: card azzurra, tag "IN CORSO"
  - ⏭️ **Futuro**: card bianca normale
- **File**: `lib/widgets/event_timeline.dart`

### 5️⃣ Pagina Programma (`ProgramPage`)
- Titolo: "Programma Festa dei Ceri"
- **3 Tabs**:
  - 15 Maggio (attivo con timeline completa)
  - 19 Maggio (Ceri Mezzani - coming soon)
  - 2 Giugno (Ceri Piccoli - coming soon)
- **File**: `lib/pages/program_page.dart`

### 6️⃣ Home Page Ridisegnata (`HomePage`)
**Struttura**:
- Header fisso (CustomHeader)
- Mappa interattiva (50% schermo)
- Sezione eventi (50% schermo):
  - Card "Prossimo evento" evidenziata
  - Lista "Oggi alla Festa"
- Footer fisso (CustomBottomNav)

**Popup benvenuto**: mostrato alla prima apertura

**File**: `lib/pages/home_page.dart`

### 7️⃣ Pagina Profilo Utente (`UserProfilePage`)
Completamente ridisegnata con:
- CustomHeader
- Avatar circolare
- Badge Ceraiolo/Turista
- Card informazioni personali
- Card dettagli Ceri
- **File**: `lib/pages/user_profile_page.dart`

---

## 📅 Eventi della Festa

### 15 Maggio 2026 - Programma Completo

| Orario | Evento |
|--------|--------|
| 05:30 | Tamburi svegliano i Capitani |
| 06:00 | Campanone |
| 07:00 | Al Cimitero |
| 08:00 | Messa ceraioli |
| 09:00 | Corteo dei Santi |
| 11:30 | Alzata dei Ceri |
| 17:00 | Processione Sant'Ubaldo |
| 18:00 | **Corsa dei Ceri** |

**File dati**: `lib/data/events_data.dart`

---

## 🔧 Modello Dati

### EventModel Esteso
Aggiunto supporto per:
- `startTime` e `endTime` (DateTime)
- `category` ("15 Maggio", "19 Maggio", "2 Giugno")
- `imageUrl` (opzionale)
- Metodo `getStatus()` - calcolo automatico stato evento
- Metodo `isToday()` - verifica se evento è oggi

**File**: `lib/models/event_model.dart`

---

## 🎨 Tema App

Tema completamente aggiornato in `lib/main.dart`:
- ColorScheme con nuovi colori
- TextTheme esteso
- CardTheme con bordi arrotondati
- ElevatedButtonTheme rosso
- BottomNavigationBarTheme pulito

---

## 🚀 Funzionalità Implementate

### ✅ Header
- Menu utente con dropdown
- Navigazione profilo
- Logout

### ✅ Footer Navigation
- Home: centra mappa su Gubbio
- Dove sono: attiva GPS e centra su posizione utente (marker blu)
- Programma: apre pagina timeline eventi
- Mute: solo per ceraioli (mostra lista mute)

### ✅ Stati Eventi Automatici
Gli eventi cambiano automaticamente stato in base all'orario corrente:
- Il sistema confronta `DateTime.now()` con `startTime` e `endTime` di ogni evento
- La UI si aggiorna automaticamente senza intervento manuale

### ✅ Mappa
- Percorso rosso dei Ceri (polyline)
- Marker rossi per eventi
- Marker blu per posizione utente

---

## 📁 Nuovi File Creati

1. `lib/widgets/custom_header.dart` - Header elegante
2. `lib/widgets/custom_bottom_nav.dart` - Footer navigation
3. `lib/widgets/welcome_popup.dart` - Popup di benvenuto
4. `lib/widgets/event_timeline.dart` - Timeline con stati automatici
5. `lib/pages/program_page.dart` - Pagina programma con tabs

---

## 📝 File Modificati

1. `lib/main.dart` - Tema app aggiornato
2. `lib/models/event_model.dart` - Esteso con stati
3. `lib/data/events_data.dart` - Eventi completi 15 Maggio
4. `lib/pages/home_page.dart` - Ridisegno completo
5. `lib/pages/user_profile_page.dart` - UI moderna

---

## 🎯 Risultato Finale

L'app ora presenta:
- ✅ Design moderno, pulito e istituzionale
- ✅ UI elegante senza gradienti o colori accesi
- ✅ Header e footer fissi
- ✅ Navigazione intuitiva
- ✅ Stati eventi automatici
- ✅ Timeline interattiva
- ✅ Popup di benvenuto
- ✅ Mappa con percorso Ceri
- ✅ Geolocalizzazione utente

---

## 🚀 Test dell'Applicazione

Per testare l'app:

```bash
flutter run
```

### Flow Utente:
1. **Login** → entra nell'app
2. **Popup Benvenuto** → appare alla prima apertura
3. **Home** → mappa + eventi del giorno
4. **Footer "Dove sono"** → geolocalizzazione (punto blu)
5. **Footer "Programma"** → timeline eventi con stati automatici
6. **Header > Avatar** → Profilo utente o Logout

---

## 💡 Note Tecniche

- **No errori di compilazione**: tutti gli errori sono stati risolti
- **Compatibilità**: funziona con l'architettura esistente (Supabase, Provider)
- **Stati automatici**: gli eventi cambiano colore/stato automaticamente in base all'ora
- **Responsive**: l'UI si adatta a diverse dimensioni schermo
- **Performance**: uso di Container e Column/Row ottimizzati

---

## 🎨 Principi UI Seguiti

✅ Bianco dominante  
✅ Rosso elegante (#B22222), non acceso  
✅ Spaziature generose  
✅ Tipografia leggibile  
✅ Card con bordi arrotondati (16px)  
✅ Ombre leggerissime  
✅ Icone Material pulite  
✅ Stati visivi chiari  

---

## 📱 Screenshot Concettuali

### Home
```
┌─────────────────────────────┐
│ 🏠 15 Maggio        👤      │  ← Header fisso
├─────────────────────────────┤
│                             │
│      🗺️ MAPPA GUBBIO        │
│   (Percorso Ceri + Marker)  │
│                             │
├─────────────────────────────┤
│  📍 Prossimo evento          │
│  [17:00 Processione...]     │
│  [Apri sulla mappa]         │
│                             │
│  📅 Oggi alla Festa          │
│  [Event card 1]             │
│  [Event card 2]             │
├─────────────────────────────┤
│ 🏠  📍  📅  👥              │  ← Footer fisso
└─────────────────────────────┘
```

### Timeline Eventi
```
┌─────────────────────────────┐
│ 🏠 15 Maggio        👤      │
├─────────────────────────────┤
│ Programma Festa dei Ceri    │
├─────────────────────────────┤
│ [15 Mag][19 Mag][2 Giu]    │
├─────────────────────────────┤
│ ⚫──┐                       │
│    │ 05:30                  │
│    │ Tamburi svegliano...   │
│    │                        │
│ ⚫──┐                       │
│    │ 06:00                  │
│    │ Campanone              │
│    │                        │
│ ⚫──┐ [IN CORSO]            │ ← Evento corrente
│    │ 09:00                  │
│    └ Corteo dei Santi       │
└─────────────────────────────┘
```

---

## 🎉 Completamento

Il ridisegno completo dell'UI è stato implementato con successo! 

L'applicazione ora ha un'interfaccia:
- **Moderna** ✨
- **Elegante** 💎
- **Pulita** 🎨
- **Istituzionale** 🏛️

Pronta per la Festa dei Ceri 2026! 🕯️🕯️🕯️
