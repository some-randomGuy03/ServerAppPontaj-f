# 🏗️ Arhitectura Proiectului / Project Architecture

---

## 🇷🇴 Română

### Stiva Tehnologică

| Strat | Tehnologie | Rol |
|-------|-----------|-----|
| **Frontend** | Flutter (Web) | Interfața utilizatorului |
| **HTTP Client** | `package:http` | Comunicare cu API-ul |
| **State Management** | Provider (`package:provider`) | Gestionarea stării aplicației |
| **Grafice** | `fl_chart` | Vizualizare date prezență |
| **Localizare** | `flutter_localizations` + ARB | Suport multilingv (RO/EN) |
| **Stocare locală** | `shared_preferences` | Token sesiune, preferințe |
| **Calendar** | `table_calendar` | Selectare intervale de timp |
| **Server web** | Nginx (în container Docker) | Servire fișiere Flutter web |
| **Containerizare** | Docker + Docker Compose | Deployment simplificat |

---

### 📁 Structura Directorului

```
ServerAppPontaj-f/
│
├── 📁 lib/                          # Codul sursă Flutter
│   ├── main.dart                    # Punct de intrare al aplicației
│   ├── pontaj_admin.dart            # Widget rădăcină (MaterialApp)
│   │
│   ├── 📁 models/                   # Modele de date
│   │   ├── elev.dart                # Model Elev (student)
│   │   ├── scan_log.dart            # Model intrare log scanare
│   │   ├── professor.dart           # Model Profesor
│   │   ├── login_request.dart       # Model cerere autentificare
│   │   └── login_response.dart      # Model răspuns autentificare
│   │
│   ├── 📁 screens/                  # Ecranele aplicației
│   │   ├── login_screen.dart        # Ecran autentificare
│   │   ├── admin_dashboard_screen.dart  # Dashboard principal
│   │   ├── student_reports_screen.dart  # Rapoarte per elev
│   │   └── debug_screen.dart        # Ecran debug (development)
│   │
│   ├── 📁 services/                 # Logica de business & API
│   │   ├── auth_service.dart        # Autentificare, token JWT
│   │   ├── admin_service.dart       # Operații administrative
│   │   ├── elev_service.dart        # Gestionare elevi & scanări
│   │   └── error_service.dart       # Gestionare erori globale
│   │
│   ├── 📁 providers/                # State management (Provider)
│   │   └── theme_provider.dart      # Provider temă (dark/light/accent)
│   │
│   ├── 📁 widgets/                  # Widget-uri reutilizabile
│   │   ├── hero_background.dart     # Fundal animat (hero section)
│   │   ├── floating_stats_sidebar.dart  # Sidebar statistici rapide
│   │   ├── language_switcher.dart   # Buton schimbare limbă
│   │   └── error_overlay.dart       # Overlay pentru mesaje de eroare
│   │
│   ├── 📁 theme/                    # Sistem de design
│   │   └── app_theme.dart           # Teme light/dark, culori accent
│   │
│   ├── 📁 l10n/                     # Fișiere de localizare
│   │   ├── app_ro.arb               # Traduceri Română
│   │   └── app_en.arb               # Traduceri Engleză
│   │
│   └── 📁 utils/                    # Utilitare
│
├── 📁 android/                      # Config platformă Android
├── 📁 ios/                          # Config platformă iOS
├── 📁 web/                          # Config platformă web
├── 📁 windows/                      # Config platformă Windows
├── 📁 assets/images/                # Resurse imagini
├── 📁 docs/                         # 📚 Documentație (acest folder)
│
├── Dockerfile                       # Imagine Docker pentru producție
├── docker-compose.yml               # Orchestrare containere
├── nginx.conf                       # Configurare server Nginx
├── nginx-reverse-proxy.conf         # Config reverse proxy
├── pubspec.yaml                     # Dependențe Flutter/Dart
└── README.md                        # README principal
```

---

### 🔄 Diagrama Arhitecturii

```
┌─────────────────────────────────────────────────────────────┐
│                    BROWSER / DEVICE                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                Flutter Web App                        │  │
│  │                                                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────────────┐  │  │
│  │  │  Screens  │  │ Widgets  │  │   Theme Provider   │  │  │
│  │  │ Login     │  │ HeroBg   │  │   (dark/light/     │  │  │
│  │  │ Dashboard │  │ Sidebar  │  │    accent color)   │  │  │
│  │  │ Reports   │  │ LangSwit │  └────────────────────┘  │  │
│  │  └─────┬─────┘  └──────────┘                          │  │
│  │        │                                               │  │
│  │  ┌─────▼─────────────────────┐                        │  │
│  │  │        Services Layer      │                        │  │
│  │  │  AuthService  │ ElevService│                        │  │
│  │  │  AdminService │ ErrorSvc   │                        │  │
│  │  └─────┬─────────────────────┘                        │  │
│  └────────┼─────────────────────────────────────────────┘  │
│           │ HTTPS / REST API                                │
└───────────┼─────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────┐
│     Backend API Server       │
│  api.pontaj.binarysquad.club │
│                             │
│  POST /admin/login           │
│  GET  /admin/elevi           │
│  GET  /admin/scan-logs       │
│  GET  /admin/stats           │
└─────────────────────────────┘
```

---

### 🐳 Diagrama Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVER LINUX                              │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │               Docker Engine                           │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────┐                │  │
│  │  │   Container: pontaj-admin-web    │                │  │
│  │  │                                  │                │  │
│  │  │  ┌──────────────────────────┐   │                │  │
│  │  │  │   Nginx Web Server       │   │                │  │
│  │  │  │   Port: 80 (intern)      │   │                │  │
│  │  │  │   Servește fișiere       │   │                │  │
│  │  │  │   Flutter build/web/     │   │                │  │
│  │  │  └──────────────────────────┘   │                │  │
│  │  └──────────────┬───────────────────┘                │  │
│  │                 │ Port mapping                        │  │
│  │              24364:80                                 │  │
│  └─────────────────┼──────────────────────────────────┘  │
│                    │                                        │
│  ┌─────────────────▼──────────────────────────────────┐   │
│  │          Nginx Reverse Proxy (host)                  │   │
│  │   binarysquad.club → localhost:24364                 │   │
│  │   HTTPS cu Let's Encrypt SSL                         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
            ↑
     Internet (HTTPS:443)
```

---

### 🔐 Fluxul de Autentificare

```
┌──────┐         ┌──────────────┐         ┌─────────────┐
│ User │         │ Pontaj Admin │         │ API Backend │
└──┬───┘         └──────┬───────┘         └──────┬──────┘
   │                    │                         │
   │  Enter credentials │                         │
   │───────────────────►│                         │
   │                    │  POST /admin/login       │
   │                    │  { email, password }     │
   │                    │────────────────────────►│
   │                    │                         │
   │                    │  200 OK { token, user }  │
   │                    │◄────────────────────────│
   │                    │                         │
   │                    │ Save token to            │
   │                    │ SharedPreferences        │
   │                    │                         │
   │  Redirect to       │                         │
   │  Dashboard         │                         │
   │◄───────────────────│                         │
   │                    │                         │
   │  [All subsequent   │                         │
   │   requests use     │                         │
   │   Bearer token]    │  GET /admin/... +        │
   │                    │  Authorization: Bearer   │
   │                    │────────────────────────►│
```

---

## 🇬🇧 English

### Technology Stack

| Layer | Technology | Role |
|-------|-----------|------|
| **Frontend** | Flutter (Web) | User interface |
| **HTTP Client** | `package:http` | Backend API communication |
| **State Management** | Provider (`package:provider`) | Application state management |
| **Charts** | `fl_chart` | Attendance data visualization |
| **Localization** | `flutter_localizations` + ARB | Multilingual support (RO/EN) |
| **Local storage** | `shared_preferences` | Session token, preferences |
| **Calendar** | `table_calendar` | Time range selection |
| **Web server** | Nginx (in Docker container) | Serve Flutter web build files |
| **Containerization** | Docker + Docker Compose | Simplified deployment |

> The architecture diagrams above are language-agnostic and apply equally to both Romanian and English contexts.

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Prezentare Generală](./01-overview.md) | [Index](./README.md) | [Ghid Instalare →](./03-getting-started.md)
