# 🏠 Prezentare Generală / Project Overview

---

## 🇷🇴 Română

### Ce este Pontaj Admin?

**Pontaj Admin** este o aplicație web modernă construită cu **Flutter**, destinată gestionării sistemului de pontaj (prezență) într-un mediu școlar. Aplicația oferă administratorilor o interfață vizuală elegantă pentru a urmări prezența elevilor prin scanare QR, a analiza statistici și a gestiona utilizatorii.

### 🎯 Scopul Aplicației

Sistemul **Pontaj** digitalizează procesul clasic de prezență prin intermediul codurilor QR. Fiecare elev are un cod QR unic; la intrarea în școală, codul este scanat, iar prezența este înregistrată automat în baza de date. Aplicația **Pontaj Admin** oferă o fereastră de control completă pentru personalul administrativ.

### ✨ Funcționalități Principale

| Funcționalitate | Descriere |
|----------------|-----------|
| 🔐 **Autentificare Securizată** | Login cu email și parolă, gestionare sesiuni cu token JWT |
| 📊 **Dashboard Analytics** | Grafice interactive cu date de prezență (zilnic, săptămânal, lunar) |
| 👥 **Gestionare Elevi** | Vizualizare, căutare și filtrare a bazei de elevi |
| 📋 **Rapoarte Detaliate** | Rapoarte individuale per elev cu istoric complet de scanări |
| 🔍 **Istoric Scanări** | Log complet al tuturor scanărilor cu filtrare temporală |
| 🌍 **Multilingv** | Interfață disponibilă în Română și Engleză |
| 🌙 **Teme Dark/Light** | Suport pentru modul întunecat și luminos, cu culori accent personalizabile |
| 📱 **Responsive** | Funcționează pe desktop, tabletă și mobil |
| 🐳 **Containerizat** | Deployment simplificat cu Docker |

### 🏫 Contextul Utilizării

Aplicația este proiectată pentru:
- **Administratori școlari** — urmăresc prezența generală și generează rapoarte
- **Profesori** — verifică prezența clasei lor
- **Personalul tehnic** — gestionează configurarea serverului și deployment-ul

---

## 🇬🇧 English

### What is Pontaj Admin?

**Pontaj Admin** is a modern web application built with **Flutter**, designed for managing an attendance ("pontaj") system in a school environment. The application provides administrators with an elegant visual interface to track student attendance via QR scanning, analyze statistics, and manage users.

### 🎯 Application Purpose

The **Pontaj** system digitizes the classical attendance process using QR codes. Each student has a unique QR code; when entering school, the code is scanned and attendance is automatically recorded in the database. The **Pontaj Admin** app provides a complete control window for administrative staff.

### ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔐 **Secure Authentication** | Email/password login, JWT token-based session management |
| 📊 **Analytics Dashboard** | Interactive charts with attendance data (daily, weekly, monthly) |
| 👥 **Student Management** | View, search and filter the student database |
| 📋 **Detailed Reports** | Individual per-student reports with complete scan history |
| 🔍 **Scan History** | Full log of all scans with time-based filtering |
| 🌍 **Multilingual** | Interface available in Romanian and English |
| 🌙 **Dark/Light Themes** | Dark and light mode support with customizable accent colors |
| 📱 **Responsive** | Works on desktop, tablet, and mobile |
| 🐳 **Containerized** | Simplified deployment with Docker |

### 🏫 Usage Context

The application is designed for:
- **School administrators** — track overall attendance and generate reports
- **Teachers** — check their class attendance
- **Technical staff** — manage server configuration and deployment

---

## 📸 Flux de Utilizare / User Flow

```
[Student] → scanează QR → [API Backend] → înregistrează prezența
                                ↓
[Admin] → deschide Pontaj Admin → [Login] → [Dashboard]
                                                  ↓
                              ┌───────────────────────────────┐
                              │  Grafice Prezență             │
                              │  Istoric Scanări              │
                              │  Rapoarte per Elev            │
                              │  Statistici Săptămânale       │
                              └───────────────────────────────┘
```

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Index Documentație](./README.md) | [Arhitectura →](./02-architecture.md)
