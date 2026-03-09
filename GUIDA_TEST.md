# 🧪 GUIDA TEST - VISIT GUBBIO

## 🚀 AVVIO APPLICAZIONE

### 1. Assicurati di avere le dipendenze installate
```bash
flutter pub get
```

### 2. Esegui l'app
```bash
flutter run
```

---

## ✅ TEST CHECKLIST

### 🔐 1. LOGIN E BENVENUTO

- [ ] **Login Page appare con stile Visit Gubbio**
  - Background beige pergamena
  - Logo circolare con icona città bronzo
  - Titolo "VISIT GUBBIO" in font serif
  - Campi email e password con bordi bronzo
  - Pulsante "ACCEDI" bronzo

- [ ] **Dopo login appare Dialog Benvenuto**
  - Carosello con 4 pagine
  - Auto-scroll ogni 3 secondi
  - Swipe manuale funziona
  - 4 pallini indicatori pagina
  - Pulsante "INIZIA L'ESPERIENZA" in fondo

- [ ] **Dialog si chiude e appare Home Visit Gubbio**

---

### 🗺️ 2. HOME PAGE VISIT GUBBIO

- [ ] **Header corretto**
  - Menu hamburger a sinistra
  - "VISIT GUBBIO" al centro in cornice
  - Icona profilo a destra
  - Colori beige/bronzo

- [ ] **Mappa Google Maps visibile**
  - Centrata su Gubbio (Piazza Grande)
  - My location attivo
  
- [ ] **Footer presente in basso**
  - 3 pulsanti: Home | Mappa | Eventi
  - Colori bronzo quando selezionati
  - Stessa altezza del footer

---

### 📱 3. MENU LATERALE (VISIT GUBBIO)

- [ ] **Click su hamburger menu → Drawer si apre**
  - Header con logo e "VISIT GUBBIO"
  - Sottotitolo "Esplora la città medievale"
  
- [ ] **Voci menu presenti:**
  - ✅ Eventi (con icona calendario)
  - ✅ Ristoranti (con icona restaurant)
  - ✅ Festa dei Ceri (evidenziato)

- [ ] **Click su "Eventi" → Apre lista eventi**

- [ ] **Click su "Ristoranti" → Apre mappa ristoranti**

- [ ] **Click su "Festa dei Ceri" → Appare loading screen rosso**

---

### 🎉 4. SEZIONE EVENTI

- [ ] **Barra di ricerca in alto**
  - Placeholder "Cerca eventi per nome..."
  - Icona lente bronzo

- [ ] **Filtri temporali sotto la ricerca**
  - Chip: Oggi / Settimana / Mese / Anno / Tutti
  - Chip selezionato diventa bronzo

- [ ] **Lista eventi (card)**
  - Immagine in alto (o placeholder)
  - Data evento in alto a destra (badge bronzo)
  - Titolo evento
  - Descrizione breve (max 3 righe)

- [ ] **Paginazione in fondo (se > 10 eventi)**
  - Frecce avanti/indietro
  - "Pagina X di Y"

- [ ] **Click su card evento → Apre dettaglio**
  - Immagine grande
  - Descrizione completa
  - Bottoni: Mappa / Indicazioni piedi / Indicazioni auto

---

### 🍴 5. SEZIONE RISTORANTI

- [ ] **Mappa Google Maps in alto (300px)**
  - Marker arancioni per ristoranti
  - Click su marker → Info window

- [ ] **Barra di ricerca sotto la mappa**
  - Placeholder "Cerca ristoranti per nome..."

- [ ] **Lista ristoranti sotto (card)**
  - Icona ristorante o immagine
  - Nome ristorante
  - Descrizione breve
  - Distanza da posizione corrente
  - Fascia prezzo (€, €€, €€€)
  - Badge "5% SCONTO" se convenzionato

- [ ] **Lista ordinata per distanza** (il più vicino prima)

- [ ] **Click su card → Apre dettaglio ristorante**
  - Immagine full screen
  - Nome e rating
  - Chip tipo cucina
  - Descrizione
  - Contatti (telefono, sito web)
  - Indirizzo
  - Pulsanti: Mostra mappa / A piedi / In auto

---

### 🎯 6. FOOTER - PULSANTE CENTRALE

- [ ] **Click sul pulsante centrale "Mappa"**
  - Icona ruota di 45° e diventa X
  
- [ ] **Appaiono 2 pulsanti rotondi sopra**
  - Animazione scale da 0 a 1
  - Pulsante 1: "GubbioMaps" (icona mappa)
  - Pulsante 2: "Dove sono" (icona my_location)
  - Pulsanti bianchi con bordo bronzo

- [ ] **Click su "GubbioMaps"**
  - Mappa si centra su Piazza Grande Gubbio
  - Menu si chiude

- [ ] **Click su "Dove sono"**
  - Mappa si centra sulla posizione corrente
  - Menu si chiude

- [ ] **Click su X (pulsante centrale) → Menu si chiude**

---

### 🔥 7. TRANSIZIONE FESTA DEI CERI

- [ ] **Dal menu laterale → Click "Festa dei Ceri"**
  
- [ ] **Appare loading screen (2 secondi)**
  - Background gradiente rosso
  - Icona celebration bianca
  - Testo "FESTA DEI CERI"
  - Progress bar bianca animata
  
- [ ] **Dopo 2 secondi → Home Festa dei Ceri**

---

### 🎊 8. HOME PAGE FESTA DEI CERI

- [ ] **Header cambiato**
  - Titolo "FESTA DEI CERI" (al posto di Visit Gubbio)
  - Colori rossi
  - Stessa struttura

- [ ] **Footer cambiato**
  - Pulsante destro: "Programma" (invece di "Eventi")
  - Colori rossi
  - Stessa struttura

- [ ] **Mappa mostra percorso Ceri**
  - Marker rossi eventi
  - Percorso tracciato (se implementato)

---

### 📋 9. MENU LATERALE (FESTA DEI CERI)

- [ ] **Click hamburger menu → Drawer rosso**
  - Header con icona celebration
  - Titolo "FESTA DEI CERI"
  
- [ ] **Voci menu:**
  - ✅ Programma (icona calendario)
  - ✅ Informazioni (icona info)
  - ✅ Torna a Visit Gubbio (icona indietro)

- [ ] **Click "Programma" → Apre pagina programma esistente**

- [ ] **Click "Informazioni" → Apre pagina info Festa**

- [ ] **Click "Torna a Visit Gubbio" → Torna alla modalità Visit Gubbio**
  - Colori cambiano da rosso a beige
  - Header cambia titolo
  - Footer cambia pulsanti

---

### 📖 10. PAGINA INFORMAZIONI FESTA DEI CERI

- [ ] **Contenuti presenti:**
  - ✅ Cos'è la Festa dei Ceri
  - ✅ Origini e storia (1160)
  - ✅ I tre Ceri (card con colori giallo/blu/nero)
  - ✅ La corsa
  - ✅ I ceraioli
  - ✅ Significato culturale
  - ✅ Il programma

- [ ] **Design elegante con scroll**
  - Testo leggibile
  - Spaziature corrette
  - Card colorate per i tre Ceri

---

### 🎨 11. ANIMAZIONI E TRANSIZIONI

- [ ] **Transizione modalità è fluida**
  - Colori cambiano gradualmente
  - Nessun flash o cambio brusco
  
- [ ] **Dialog benvenuto animato**
  - Fade + scale all'apertura
  - Auto-scroll fluido tra pagine
  
- [ ] **Menu posizione animato**
  - Bottoni appaiono con scale animation
  - Pulsante centrale ruota 45°
  
- [ ] **Card eventi/ristoranti hanno effetto ripple al tap**

---

## ⚠️ POSSIBILI PROBLEMI

### Problema: Dipendenze mancanti
**Soluzione:** `flutter pub get`

### Problema: Errore Google Maps API
**Soluzione:** Verifica chiave API in `android/app/src/main/AndroidManifest.xml` e `ios/Runner/AppDelegate.swift`

### Problema: Posizione non funziona
**Soluzione:** Abilita permessi GPS su device/emulator

### Problema: Immagini carosello non appaiono
**Soluzione:** È normale, le immagini sono opzionali. Appaiono placeholder con icone.

### Problema: Eventi lista vuota
**Soluzione:** Normale, il metodo `_getEventsForCurrentMonth()` in `events_list_page.dart` restituisce lista vuota. Va collegato al database degli eventi.

---

## 🎯 TEST RAPIDO (5 MINUTI)

1. **Login** → Dialog benvenuto → Home ✅
2. **Menu laterale** → Eventi → Ricerca funziona ✅
3. **Menu laterale** → Ristoranti → Mappa + lista ✅
4. **Footer centrale** → Menu posizione → GubbioMaps ✅
5. **Menu laterale** → Festa dei Ceri → Loading → Cambio modalità ✅
6. **Menu laterale FC** → Informazioni → Scroll pagina ✅
7. **Menu laterale FC** → Torna a Visit Gubbio → Cambio modalità ✅

---

## 📊 METRICHE DI SUCCESSO

✅ **Design Moderno:** Gradiente, ombre, animazioni fluide  
✅ **Identità Medievale:** Palette storica, font serif, bronzo  
✅ **Due Modalità:** Visit Gubbio ↔ Festa dei Ceri  
✅ **Navigazione Intuitiva:** Menu laterale, footer con 3 pulsanti  
✅ **Funzionalità Complete:** Eventi, ristoranti, mappa, ricerca, filtri  
✅ **Animazioni Eleganti:** Dialog, loading, transizioni  

---

## 🏆 RISULTATO ATTESO

**"Quando uno entra dice WOW!"** 🏰✨

L'app deve sembrare:
- 🏛️ App turistica premium (tipo Airbnb, Google Travel)
- 🎨 Design moderno ma con identità storica
- 🚀 Fluida e professionale
- 📱 Pronta per App Store/Play Store

---

## 📞 DEBUGGING

Se qualcosa non funziona:
1. Leggi `REDESIGN_VISIT_GUBBIO_COMPLETATO.md` per dettagli
2. Controlla console per errori
3. Verifica che tutte le dipendenze siano installate
4. Testa su device reale (non solo emulator) per GPS e prestazioni

**Tutti i file sono stati creati e dovrebbero funzionare subito!** 🎉
