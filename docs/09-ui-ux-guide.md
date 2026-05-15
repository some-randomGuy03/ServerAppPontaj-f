# 🎨 Ghid de Stil UI/UX / UI/UX Design Guide

---

## 🇷🇴 Română

### 🌟 Filosofia de Design

Aplicația **Pontaj Admin** este proiectată cu un focus pe o experiență de utilizare "Premium", aerisită și modernă.

**Principiile de bază:**
1. **Design Dinamic:** Interfața pare "vie" prin utilizarea animațiilor fluide, tranzițiilor și efectelor hover.
2. **Glassmorphism:** Utilizarea fundalurilor semi-transparente cu blur pentru a crea profunzime.
3. **Contrast Elegant:** O distincție clară între modul luminos (alb/gri deschis) și cel întunecat (negru/gri închis).
4. **Ierarhie Vizuală:** Elementele importante (statistici, alerte) ies în evidență prin culori accent și umbre subtile.

---

### 🎨 Sistemul de Culori (Theming)

Aplicația folosește clasa `AppTheme` (`lib/theme/app_theme.dart`) pentru a gestiona culorile centralizat.

#### Modul Luminos (Light Mode)
- **Fundal principal:** Alb pur `#FFFFFF` sau gri foarte deschis `#F8F9FA`
- **Card-uri:** Alb cu umbre subtile gri deschis
- **Text principal:** Gri închis `#212529`
- **Text secundar:** Gri mediu `#6C757D`

#### Modul Întunecat (Dark Mode)
- **Fundal principal:** Negru absolut `#000000` (pentru ecrane OLED) sau gri foarte închis `#121212`
- **Card-uri:** Gri închis `#1E1E1E` cu border-uri subtile transparente
- **Text principal:** Alb `#FFFFFF`
- **Text secundar:** Gri deschis `#ADB5BD` sau `#E0E0E0`

#### Culori de Accent (Accent Colors)
Utilizatorul poate schimba culoarea principală a aplicației (din `ThemeProvider`):
1. 🔵 **Albastru** (Implicit) — Profesional, de încredere
2. 🟢 **Verde** — Succes, prezență
3. 🔴 **Roșu/Roz** — Energie, alertă
4. 🟣 **Mov** — Premium, creativ
5. 🟠 **Portocaliu** — Dinamic, cald

---

### 🧩 Componente Core (Widgets)

#### 1. Hero Background (`hero_background.dart`)
Un fundal animat, fluid, care reacționează la tema aplicației. Folosește gradienți care se mișcă subtil pentru a adăuga dinamism fără a distrage atenția.

#### 2. Card-uri Glassmorphism
Containerele folosesc `BackdropFilter` cu `ImageFilter.blur` pentru un efect "înghețat" (frosted glass) pe deasupra fundalului.

```dart
// Exemplu de efect glassmorphism
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor.withOpacity(0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: /* Conținut */,
    ),
  ),
)
```

#### 3. Floating Stats Sidebar (`floating_stats_sidebar.dart`)
Un panou lateral ("plutitor") cu statistici importante, fixat vizual dar cu comportament adaptiv pe ecrane mici.

---

### 📱 Responsivitate (Responsive Design)

Interfața se adaptează dinamic folosind `MediaQuery` și `LayoutBuilder`:

| Breakpoint | Layout |
|------------|--------|
| **< 600px** (Mobil) | Sidebar ascuns în Drawer, grid cu 1 coloană, grafice restrânse |
| **600px - 1024px** (Tabletă) | Sidebar colapsat (doar iconițe), grid cu 2 coloane |
| **> 1024px** (Desktop) | Sidebar vizibil complet, grid cu 3+ coloane, utilizare completă a spațiului |

---

### 🔤 Tipografie

- **Font Principal:** `Roboto` / `Inter` (sau fontul implicit sistemului pentru performanță)
- **Titluri (Headings):** Bold, mari, clar delimitate
- **Metrici/Cifre:** Fonturi mai mari, posibil monospaced pentru aliniere perfectă
- Toate textele sunt mapate la `TextTheme` din Flutter pentru a se adapta automat la Dark/Light mode.

---

## 🇬🇧 English

### 🌟 Design Philosophy

The **Pontaj Admin** application is designed with a focus on a "Premium", airy, and modern user experience.

**Core Principles:**
1. **Dynamic Design:** The interface feels "alive" through fluid animations, transitions, and hover effects.
2. **Glassmorphism:** Using semi-transparent backgrounds with blur to create depth.
3. **Elegant Contrast:** Clear distinction between light mode (white/light gray) and dark mode (black/dark gray).
4. **Visual Hierarchy:** Important elements (stats, alerts) stand out using accent colors and subtle shadows.

### 🎨 Theming System

The app uses the `AppTheme` class (`lib/theme/app_theme.dart`) to manage colors centrally.

#### Light Mode
- **Background:** Pure white `#FFFFFF` or very light gray `#F8F9FA`
- **Cards:** White with subtle light gray shadows
- **Primary Text:** Dark gray `#212529`
- **Secondary Text:** Medium gray `#6C757D`

#### Dark Mode
- **Background:** Absolute black `#000000` (for OLED) or very dark gray `#121212`
- **Cards:** Dark gray `#1E1E1E` with subtle transparent borders
- **Primary Text:** White `#FFFFFF`
- **Secondary Text:** Light gray `#ADB5BD` or `#E0E0E0`

### 📱 Responsive Design

The interface adapts dynamically:

| Breakpoint | Layout |
|------------|--------|
| **< 600px** (Mobile) | Sidebar hidden in Drawer, 1-column grid, compact charts |
| **600px - 1024px** (Tablet) | Collapsed sidebar (icons only), 2-column grid |
| **> 1024px** (Desktop) | Fully visible sidebar, 3+ column grid, full space utilization |

---

## 🔗 Navigare Documentație / Documentation Navigation

← [API Reference](./08-api-reference.md) | [Index](./README.md) | [Changelog →](./10-changelog.md)
