# 🚀 COME AVVIARE L'APP

## ⚠️ IMPORTANTE: NON usare `flutter run -d chrome` direttamente!

❌ **NON FARE:**
```powershell
flutter run -d chrome  # ← QUESTO DARÀ ERRORE!
```

✅ **USA QUESTO:**
```powershell
.\run.ps1
```

### Perché?
Windows blocca la cartella `build` quando Chrome è aperto. Lo script `run.ps1` chiude automaticamente Chrome e pulisce la build prima di avviare l'app.

---

## 📝 Durante lo sviluppo:

Quando l'app è già in esecuzione e modifichi il codice, usa:

- **`r`** - Hot reload (velocissimo, mantiene lo stato)
- **`R`** - Hot restart (riavvio completo)
- **`q`** - Chiudi app

**NON chiudere e riavviare** l'app manualmente - usa hot reload!

---

## 🔐 Login/Registrazione

L'app ora ha:
- Login con email/password
- Registrazione (nome, cognome, data nascita, email, password)
- Password dimenticata
- Cambio lingua IT/EN (in alto a destra)

---

## 🗄️ Database Supabase

Configurato in `lib/main.dart` con:
- URL: https://jqvsfnkypvnjymrnubdv.supabase.co
- Auth: Email/Password
- Tabella: `utenti`
