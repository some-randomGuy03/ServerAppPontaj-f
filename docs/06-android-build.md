# 📱 Build & Rulare Android / Android Build Guide

---

## 🇷🇴 Română

### Cerințe Preliminare

Înainte de a rula aplicația pe Android, asigură-te că ai:

| Cerință | Cum se verifică |
|---------|----------------|
| ✅ **Flutter SDK** instalat | `flutter --version` |
| ✅ **Android Studio** sau **SDK** instalat | `flutter doctor` |
| ✅ **Java 11+** instalat | `java -version` |
| ✅ **Mod developer** activat pe telefon | Setări → Despre telefon → Apasă de 7× pe "Număr build" |
| ✅ **USB Debugging** activat | Setări → Opțiuni developer → USB debugging: ON |

---

### 📱 Pasul 1 — Conectează Dispozitivul Android

1. Conectează telefonul/tableta la calculator printr-un cablu USB
2. Pe telefon, permite **USB debugging** când apare popup-ul
   - Bifează "Permite întotdeauna de pe acest calculator" pentru confort
3. Asigură-te că telefonul este **deblocat**

> 💡 **Sfat:** Folosește un cablu USB care suportă transfer de date (nu doar încărcare). Cablurile de calitate slabă cauzează cel mai frecvent problema "device not detected".

---

### 🔍 Pasul 2 — Verifică Detectarea Dispozitivului

```bash
flutter devices
```

Ar trebui să vezi ceva similar cu:

```
Found 2 connected devices:
  SM G991B (mobile) • R5CT123456 • android-arm64 • Android 13 (API 33)
  Chrome (web)      • chrome      • web-javascript • Google Chrome 120.0
```

Sau dacă folosești emulator:
```
sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33)
```

Dacă **nu** apare dispozitivul, vezi secțiunea Troubleshooting mai jos.

---

### ▶️ Pasul 3 — Rulează Aplicația

#### Pe dispozitivul Android detectat:
```bash
flutter run
```

#### Specifică Android (dacă ai mai multe dispozitive):
```bash
flutter run -d android
```

#### Specifică un dispozitiv anume prin ID:
```bash
flutter run -d R5CT123456
```

**Ce se întâmplă:**
1. Flutter compilează aplicația (1-5 minute prima dată)
2. APK-ul este instalat pe dispozitiv
3. Aplicația pornește automat
4. Vei vedea ecranul de login

---

### 🔥 Hot Reload în Development

În timp ce aplicația rulează, în terminal poți folosi:

| Tastă | Acțiune |
|-------|---------|
| `r` | **Hot Reload** — aplică modificările rapid fără a pierde starea |
| `R` | **Hot Restart** — repornire completă a aplicației |
| `q` | **Quit** — oprire aplicație |
| `d` | **Detach** — lasă aplicația să ruleze, ieși din terminal |
| `h` | **Help** — afișează toate comenzile disponibile |

---

### 📦 Pasul 4 — Build APK pentru Distribuție

#### APK Debug (pentru testare):
```bash
flutter build apk --debug
```

#### APK Release (pentru distribuție):
```bash
flutter build apk --release
```

**Locație APK generat:**
```
build/app/outputs/flutter-apk/app-release.apk
```

#### APK Split pe arhitecturi (dimensiune mai mică):
```bash
flutter build apk --split-per-abi
```
Generează:
- `app-armeabi-v7a-release.apk` (telefoane vechi 32-bit)
- `app-arm64-v8a-release.apk` (telefoane moderne 64-bit)
- `app-x86_64-release.apk` (emulator)

---

### 🚨 Troubleshooting Android

#### Dispozitiv nedetectat

**1. Verifică cablul USB:**
```bash
adb devices
```
- Dacă apare `unauthorized` → verifică telefonul pentru popup de confirmare
- Dacă nu apare nimic → cablul nu suportă date sau USB debugging e dezactivat

**2. Resetează conexiunea ADB:**
```bash
adb kill-server
adb start-server
adb devices
```

**3. Instalează drivere USB (Windows):**
- Descarcă driverele de pe site-ul producătorului telefonului
- Samsung: [samsung.com/global/galaxy/apps/kies](https://www.samsung.com/global/galaxy/apps/kies/)
- Google: inclus în Android Studio

#### Erori de Build

**Curăță și reconstruiește:**
```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter run
```

**Verifică mediul Flutter:**
```bash
flutter doctor
```
Toate itemele trebuie să aibă ✅. Dacă există probleme cu Android:
```bash
flutter doctor --android-licenses
# Acceptă toate licențele cu 'y'
```

#### Aplicația crașează la pornire

**Verifică log-urile:**
```bash
flutter logs
# sau
adb logcat | grep flutter
```

---

### 🌟 Avantajele Android față de Web

> 💡 **Fără probleme CORS pe Android!**  
> Spre deosebire de web (browser), aplicația Android poate accesa direct API-ul backend fără configurare specială de CORS.

| Caracteristică | Web (Browser) | Android |
|---------------|--------------|---------|
| CORS | ⚠️ Necesită configurare server | ✅ Nu există CORS |
| API direct | ⚠️ Posibil blocat | ✅ Funcționează direct |
| Offline | ❌ Limitat | ✅ Posibil cu cache |
| Notificări push | ❌ Limitat | ✅ Suport complet |
| Performanță | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🇬🇧 English

### Quick Android Setup

```bash
# 1. Connect Android device with USB debugging enabled
# 2. Verify detection
flutter devices

# 3. Run app
flutter run -d android

# 4. Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android Requirements Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] Android SDK installed (via Android Studio or standalone)
- [ ] Java 11+ installed (see [Java Troubleshooting](./07-java-troubleshooting.md))
- [ ] Android device with **Developer Mode** enabled
- [ ] **USB Debugging** enabled on the device
- [ ] USB cable that supports data transfer (not charge-only)

### Verify ADB Connection

```bash
adb devices
# Should show: LIST OF DEVICES ATTACHED
# device_id    device
```

If you see `unauthorized`, look for the USB debugging confirmation popup on your phone.

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Server & Nginx](./05-server-nginx.md) | [Index](./README.md) | [Java Troubleshooting →](./07-java-troubleshooting.md)
