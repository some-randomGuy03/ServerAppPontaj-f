# 🚀 Ghid de Instalare și Pornire / Getting Started Guide

---

## 🇷🇴 Română

### Cerințe Preliminare

Înainte de a începe, asigură-te că ai instalat:

| Cerință | Versiune minimă | Link instalare |
|---------|----------------|----------------|
| **Flutter SDK** | 3.10.0+ | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.0.0+ | Inclus cu Flutter |
| **Chrome** (pentru web) | Orice versiune recentă | [chrome.google.com](https://www.google.com/chrome/) |
| **Git** | 2.x+ | [git-scm.com](https://git-scm.com/downloads) |
| **Java JDK** | 11+ (pentru Android) | [adoptium.net](https://adoptium.net/) |

---

### 📥 Pasul 1 — Clonează Repository-ul

```bash
git clone https://github.com/your-username/ServerAppPontaj-f.git
cd ServerAppPontaj-f
```

---

### 📦 Pasul 2 — Instalează Dependențele

```bash
flutter pub get
```

Aceasta va descărca toate pachetele definite în `pubspec.yaml`:
- `http` — client HTTP
- `provider` — gestionare stare
- `shared_preferences` — stocare locală
- `fl_chart` — grafice interactive
- `flutter_localizations` — localizare
- `table_calendar` — calendar
- `flutter_svg` — imagini SVG
- `url_launcher` — deschidere URL-uri externe

---

### 🌍 Pasul 3 — Generează Fișierele de Localizare

```bash
flutter gen-l10n
```

Aceasta generează fișierele de localizare din `lib/l10n/app_ro.arb` și `lib/l10n/app_en.arb`.

> ⚠️ **Important:** Acest pas este obligatoriu! Fără el, aplicația nu va compila.

---

### ▶️ Pasul 4 — Rulează Aplicația

#### Pe web (Chrome) — Recomandat pentru development:
```bash
flutter run -d chrome
```

#### Pe toate dispozitivele disponibile:
```bash
flutter devices          # listează dispozitivele disponibile
flutter run              # selectează automat primul dispozitiv
```

#### Pe Android (necesită device conectat sau emulator):
```bash
flutter run -d android
```

#### Pe Windows (desktop):
```bash
flutter run -d windows
```

---

### 🔨 Pasul 5 — Build pentru Producție

#### Build web (pentru deployment Docker):
```bash
flutter build web --release
```

Fișierele generate vor fi în `build/web/`.

#### Build APK Android:
```bash
flutter build apk --release
```

APK-ul va fi în: `build/app/outputs/flutter-apk/app-release.apk`

---

### 🔄 Comenzi Utile în Development

```bash
# Verifică mediul de development
flutter doctor

# Curăță cache-ul build
flutter clean

# Hot reload (în timp ce aplicația rulează, apasă 'r' în terminal)
# Hot restart complet (apasă 'R' în terminal)

# Actualizează dependențele la ultimele versiuni
flutter pub upgrade

# Verifică probleme de cod
flutter analyze

# Rulează testele
flutter test
```

---

### 🌐 Accesul la Aplicație

După pornire, aplicația este accesibilă la:
```
http://localhost:PORT
```

Portul implicit este **aleatoriu în development**, dar îl vei vedea în terminal:
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

🔥  To hot reload changes while running, press "r" or "F5".
    To hot restart (and rebuild state), press "R".
    An Observatory debugger and profiler on Chrome is available at:
    http://127.0.0.1:PORT/
```

---

### 🔑 Date de Autentificare (Development)

> ⚠️ **Atenție:** Schimbă aceste credențiale în producție!

```
URL API: https://api.pontaj.binarysquad.club
```

Credențialele de test sunt gestionate de backend-ul API.

---

## 🇬🇧 English

### Prerequisites

Before starting, make sure you have installed:

| Requirement | Min. Version | Install link |
|-------------|-------------|--------------|
| **Flutter SDK** | 3.10.0+ | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.0.0+ | Included with Flutter |
| **Chrome** (for web) | Any recent version | [chrome.google.com](https://www.google.com/chrome/) |
| **Git** | 2.x+ | [git-scm.com](https://git-scm.com/downloads) |
| **Java JDK** | 11+ (for Android) | [adoptium.net](https://adoptium.net/) |

### Quick Start (3 commands)

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate localization files (REQUIRED)
flutter gen-l10n

# 3. Run on Chrome
flutter run -d chrome
```

Or as a single combined command:
```bash
flutter pub get && flutter gen-l10n && flutter run -d chrome
```

### Build for Production

```bash
# Web build (for Docker deployment)
flutter build web --release

# Android APK
flutter build apk --release
```

### Verification

```bash
# Ensure environment is set up correctly
flutter doctor -v
```

All items should show ✅. If you see issues, refer to:
- [☕ Java Troubleshooting Guide](./07-java-troubleshooting.md)
- [📱 Android Build Guide](./06-android-build.md)

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Arhitectura](./02-architecture.md) | [Index](./README.md) | [Deployment Docker →](./04-deployment.md)
