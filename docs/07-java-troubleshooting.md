# ☕ Probleme Java & Gradle / Java & Gradle Troubleshooting

---

## 🇷🇴 Română

### De ce e nevoie de Java?

**Gradle** (sistemul de build al Android) necesită Java pentru a compila aplicațiile Android. Flutter delegă build-ul Android la Gradle, care la rândul lui necesită Java 11 sau mai nou.

### Diagrama Dependinței Java

```
flutter build apk
        │
        ▼
   Gradle Build System
        │
        ▼
   Necesită Java 11+
        │
    ┌───┴────────────┐
    │                │
    ▼                ▼
Java 11 (LTS)   Java 17 (LTS)   ← Recomandat
Java 21 (LTS)   Java 25         ← Funcționează
    │
Java 8          ← ❌ INCOMPATIBIL cu Flutter modern
```

---

### 🔍 Pasul 1 — Diagnosticare

```bash
# Verifică versiunea Java curentă
java -version

# Verifică unde este instalat Java
where java              # Windows
which java              # Linux/Mac

# Verifică variabila JAVA_HOME
echo %JAVA_HOME%        # Windows CMD
echo $JAVA_HOME         # Linux/Mac

# Verifică versiunea Dart/Flutter
flutter --version

# Rulează diagnosticul complet Flutter
flutter doctor -v
```

**Interpretarea rezultatelor:**

| Output `java -version` | Status |
|-----------------------|--------|
| `openjdk version "8.x"` | ❌ Prea vechi — actualizează |
| `openjdk version "11.x"` | ✅ OK |
| `openjdk version "17.x"` | ✅ Recomandat |
| `openjdk version "21.x"` | ✅ OK |
| `openjdk version "25.x"` | ✅ OK (poate necesita configurare Gradle) |

---

### 🛠️ Pasul 2 — Instalare Java 11+ (Windows)

#### Opțiunea A: Chocolatey (Recomandat)

```powershell
# Instalează Chocolatey (dacă nu ai)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalează Java 11
choco install temurin11 -y

# Sau Java 17 (recomandat)
choco install temurin17 -y
```

#### Opțiunea B: Scoop

```powershell
# Instalează Scoop (dacă nu ai)
irm get.scoop.sh | iex

# Instalează Java
scoop bucket add java
scoop install temurin11-jdk
```

#### Opțiunea C: Instalare Manuală

1. Mergi la: **https://adoptium.net/temurin/releases/**
2. Selectează:
   - **Versiune:** 11 (LTS) sau 17 (LTS)
   - **OS:** Windows
   - **Arhitectura:** x64
   - **Tip pachet:** Installer (.msi)
3. Rulează installer-ul
4. **Bifează "Set JAVA_HOME variable"** în timpul instalării!

---

### ⚙️ Pasul 3 — Configurare JAVA_HOME (dacă nu s-a setat automat)

#### Windows (GUI):
1. `Win + R` → tastează `sysdm.cpl` → Enter
2. Tab **Advanced** → **Environment Variables**
3. Sub "System variables" → **New**:
   - Name: `JAVA_HOME`
   - Value: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
4. Găsește `Path` în "System variables" → **Edit** → **New**:
   - `%JAVA_HOME%\bin`
5. OK pe toate ferestrele

#### Windows (PowerShell — Administrator):
```powershell
# Setează JAVA_HOME (înlocuiește cu calea ta reală)
[System.Environment]::SetEnvironmentVariable(
    "JAVA_HOME",
    "C:\Program Files\Eclipse Adoptium\jdk-17.0.10.7-hotspot",
    "Machine"
)

# Adaugă la PATH
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
[System.Environment]::SetEnvironmentVariable(
    "Path",
    "$oldPath;%JAVA_HOME%\bin",
    "Machine"
)

# Închide și redeschide terminalul!
```

#### Verificare după configurare:
```powershell
# Deschide un terminal NOU, apoi:
java -version
javac -version
echo $env:JAVA_HOME
```

---

### 🔧 Pasul 4 — Configurare Gradle (Alternativă Rapidă)

Dacă nu vrei să schimbi PATH-ul sistemului, poți configura Gradle să folosească o instalare specifică de Java:

Editează `android/gradle.properties` și adaugă:

```properties
# Înlocuiește cu calea reală la Java
org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.10.7-hotspot
```

> ⚠️ **Important:** Folosește backslash dublu `\\` în calea Windows!

---

### 🧹 Pasul 5 — Curățare Cache Gradle

După schimbarea Java, curăță cache-ul:

```bash
# Curăță cache Flutter
flutter clean

# Curăță cache Gradle (Windows)
cd android
gradlew clean --no-daemon
cd ..

# Reinstalează dependențele
flutter pub get

# Testează build-ul
flutter run
```

---

### 🐛 Erori Frecvente și Rezolvări

#### `Gradle requires Java 11 or higher`

```
Cauza: JAVA_HOME sau PATH pointează la Java 8
Rezolvare:
  1. Instalează Java 11+ (Pasul 2)
  2. Setează JAVA_HOME (Pasul 3) SAU
  3. Configurează gradle.properties (Pasul 4)
```

#### `JAVA_HOME is set to an invalid directory`

```bash
# Verifică exact ce cale e setată
echo %JAVA_HOME%

# Găsește Java instalat
dir "C:\Program Files\Eclipse Adoptium" /b
dir "C:\Program Files\Java" /b

# Setează calea corectă în Environment Variables
```

#### `Could not determine java version`

```bash
# Java nu e în PATH
# Adaugă manual: %JAVA_HOME%\bin la PATH
# Sau specifică în gradle.properties
```

#### Sistemul are Java 25 dar Gradle folosește Java 8

Aceasta se întâmplă când Java 8 e primul în PATH. Soluții:

1. **Modifică ordinea în PATH** — mută Java 25 înaintea Java 8
2. **Sau setează explicit în Gradle:**

```properties
# android/gradle.properties
org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-25.0.1.9-hotspot
```

---

### 📋 Checklist Rapid

```
□ java -version → afișează Java 11+
□ javac -version → afișează versiunea corectă
□ JAVA_HOME → setat corect
□ %JAVA_HOME%\bin → în PATH
□ flutter clean → rulat
□ flutter pub get → rulat
□ flutter gen-l10n → rulat
□ flutter run → funcționează ✅
```

---

## 🇬🇧 English

### Quick Fix Summary

**Problem:** Gradle requires Java 11+ but Java 8 is being used.

**Solution options (pick one):**

1. **Install Java 17 via Chocolatey (easiest on Windows):**
   ```powershell
   choco install temurin17 -y
   ```
   Then restart your terminal.

2. **Set Gradle to use specific Java (no PATH change needed):**
   Add to `android/gradle.properties`:
   ```properties
   org.gradle.java.home=C:\\path\\to\\your\\jdk-17
   ```

3. **Manual install from Adoptium:**
   Download from [adoptium.net](https://adoptium.net), run installer, check "Set JAVA_HOME".

**After any fix, always run:**
```bash
flutter clean && flutter pub get && flutter run
```

### Find Your Java Installation Path

```powershell
# Windows - find all Java installations
Get-ChildItem "C:\Program Files\Eclipse Adoptium" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Program Files\Java" -ErrorAction SilentlyContinue
```

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Build Android](./06-android-build.md) | [Index](./README.md) | [API Reference →](./08-api-reference.md)
