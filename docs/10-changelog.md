# 📝 Changelog / Istoric Versiuni

Toate modificările notabile ale acestui proiect vor fi documentate în acest fișier. / All notable changes to this project will be documented in this file.

Formatul este bazat pe [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), și acest proiect aderă la [Semantic Versioning](https://semver.org/spec/v2.0.0.html). / The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

---

## [Unreleased] / [Nelansat]

### 🆕 Adăugat / Added
- Documentație completă bilingvă în folderul `docs/` (Overview, Arhitectură, Deployment, etc.)
- Structură modulară de cod cu widget-uri reutilizabile

### 🔧 Modificat / Changed
- Actualizat meniul principal (App Drawer) pentru a reflecta noua structură a aplicației
- Refactoring major la componentele de UI (Glassmorphism, culori dinamice)

### 🐛 Reparat / Fixed
- Erori de compilare legate de `table_calendar` 
- Erori Java/Gradle în procesul de build Android

---

## [1.0.0] - 2026-05-15

Lansarea inițială a aplicației **Pontaj Admin**! 🎉

### 🆕 Adăugat / Added
- Sistem complet de autentificare (Login screen)
- Dashboard Admin cu statistici și grafice (prin `fl_chart`)
- Gestionare elevi (vizualizare, căutare, detalii loguri de scanare)
- Suport complet pentru Limba Română și Limba Engleză (`flutter_localizations`)
- Sistem de teme (Light Mode / Dark Mode)
- Selector de culoare accent (Albastru, Verde, Roșu, Mov, Portocaliu)
- Deployment complet pe Docker (Nginx, reverse proxy)
- Suport cross-platform: Funcționează pe Web și Android
- Interfață complet adaptabilă (Responsive design - Mobile, Tablet, Desktop)
