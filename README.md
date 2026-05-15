<div align="center">
  <img src="assets/images/logo_or_placeholder.png" alt="Pontaj Admin Logo" width="150" onError="this.style.display='none'"/>
  
  # 🚀 Pontaj Admin

  <p align="center">
    <strong>A Premium Flutter Web Application for School Attendance Management</strong>
  </p>

  <p align="center">
    <a href="#features">Features</a> •
    <a href="#documentation">Documentation</a> •
    <a href="#quick-start">Quick Start</a> •
    <a href="#deployment">Deployment</a>
  </p>

  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Version" />
    <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart Version" />
    <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Android-4CAF50?style=for-the-badge&logo=android&logoColor=white" alt="Platforms" />
    <img src="https://img.shields.io/badge/Docker-Supported-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Support" />
  </p>
</div>

---

## 🌟 Overview

**Pontaj Admin** is a modern, responsive administrative dashboard for managing student attendance via QR code scans. Built with Flutter, it features a stunning "glassmorphism" UI, dynamic theming (Dark/Light mode + accent colors), interactive charts, and complete bilingual support (Romanian and English).

<div align="center">
  <img src="https://via.placeholder.com/800x450/1E1E1E/FFFFFF?text=Pontaj+Admin+Dashboard" alt="Dashboard Preview" width="100%" style="border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.2);" />
</div>

> *Note: Add actual screenshots to your `assets/images/` folder later to make this README pop even more!*

---

## ✨ Features

- 🔐 **Secure Authentication**: JWT token-based session management
- 📊 **Interactive Analytics**: Daily, weekly, and monthly attendance charts
- 👥 **Student Management**: Filterable list of students with detailed scan history
- 🌍 **Bilingual Interface**: Native support for Romanian and English
- 🎨 **Dynamic Theming**: Premium Dark/Light mode and customizable accent colors
- 📱 **Cross-Platform**: Works beautifully on Web, Tablets, and Android phones
- 🐳 **Docker Ready**: One-click deployment with Docker Compose

---

## 📚 Complete Documentation

We have thoroughly documented every aspect of the project in the `docs/` folder. All documentation is completely bilingual (Romanian & English).

**Start Here:**
1. 🏠 [Overview & Architecture](docs/01-overview.md)
2. 🚀 [Getting Started & Installation](docs/03-getting-started.md)
3. 🐳 [Docker Deployment Guide](docs/04-deployment.md)

**Advanced Topics:**
- 🌐 [Server & Nginx Setup](docs/05-server-nginx.md)
- 📱 [Android Build Guide](docs/06-android-build.md)
- ☕ [Java/Gradle Troubleshooting](docs/07-java-troubleshooting.md)
- 🔌 [API Reference](docs/08-api-reference.md)
- 🎨 [UI/UX Design System Guide](docs/09-ui-ux-guide.md)
- 📝 [Changelog](docs/10-changelog.md)

---

## 🚀 Quick Start

### 1. Requirements
Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

### 2. Setup
```bash
# Clone the repository
git clone https://github.com/your-username/ServerAppPontaj-f.git
cd ServerAppPontaj-f

# Install dependencies
flutter pub get

# Generate localization files (REQUIRED)
flutter gen-l10n
```

### 3. Run Locally
```bash
# Run on Chrome
flutter run -d chrome
```

---

## 🐳 Docker Deployment

The fastest way to deploy the application on a server is using Docker.

```bash
# Start the container
docker-compose up -d

# View logs
docker-compose logs -f
```

The app will be accessible at `http://localhost:24364`. For full production server setup (HTTPS, Reverse Proxy), see the [Server Setup Guide](docs/05-server-nginx.md).

---

## 🏗️ Project Structure

```
lib/
├── models/         # Data structures (Elev, ScanLog, etc.)
├── screens/        # Main pages (Login, Dashboard, Reports)
├── services/       # API communication (Auth, Elevi, Admin)
├── theme/          # AppTheme, Colors, Glassmorphism
├── widgets/        # Reusable UI components
├── l10n/           # Romanian/English translations
└── main.dart       # App entry point
```

---

## 📄 License

This project is proprietary. All rights reserved. See the [LICENSE](LICENSE) file for details.

<div align="center">
  <sub>Built with ❤️ using Flutter</sub>
</div>
