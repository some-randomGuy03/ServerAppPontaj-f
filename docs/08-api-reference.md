# 🔌 API Reference / Documentație API

---

## 🇷🇴 Română

### Prezentare Generală API

Aplicația **Pontaj Admin** comunică cu un backend REST API. Toate cererile folosesc **HTTPS** și autentificare prin **JWT Bearer Token**.

**Base URL:**
```
https://api.pontaj.binarysquad.club
```

**Headers obligatorii pentru rute protejate:**
```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

### 🔐 Autentificare

#### `POST /admin/login`

Autentifică un utilizator administrator și returnează un token JWT.

**Request Body:**
```json
{
  "email": "admin@scoala.ro",
  "password": "parola_secreta"
}
```

**Response 200 OK:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "admin@scoala.ro",
    "name": "Administrator",
    "role": "admin"
  }
}
```

**Response 401 Unauthorized:**
```json
{
  "error": "Invalid credentials",
  "message": "Email sau parolă incorectă"
}
```

**Implementare în aplicație:** `lib/services/auth_service.dart`

---

### 👥 Elevi (Students)

#### `GET /admin/elevi`

Returnează lista tuturor elevilor din sistem.

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "nume": "Popescu",
    "prenume": "Ioan",
    "clasa": "12A",
    "qr_code": "QR_UNIQUE_123",
    "activ": true,
    "created_at": "2024-09-01T08:00:00Z"
  },
  {
    "id": 2,
    "nume": "Ionescu",
    "prenume": "Maria",
    "clasa": "11B",
    "qr_code": "QR_UNIQUE_456",
    "activ": true,
    "created_at": "2024-09-01T08:00:00Z"
  }
]
```

**Implementare:** `lib/services/elev_service.dart`

---

#### `GET /admin/elevi/{id}`

Returnează detaliile unui elev specific.

**Response 200 OK:**
```json
{
  "id": 1,
  "nume": "Popescu",
  "prenume": "Ioan",
  "clasa": "12A",
  "qr_code": "QR_UNIQUE_123",
  "activ": true,
  "total_scanari": 142,
  "ultima_scanare": "2026-05-15T08:12:00Z",
  "created_at": "2024-09-01T08:00:00Z"
}
```

---

### 📋 Scanări (Scan Logs)

#### `GET /admin/scan-logs`

Returnează istoricul tuturor scanărilor.

**Query Parameters:**

| Parametru | Tip | Descriere | Exemplu |
|-----------|-----|-----------|---------|
| `from` | string (ISO 8601) | Data de început | `2026-05-01T00:00:00Z` |
| `to` | string (ISO 8601) | Data de final | `2026-05-15T23:59:59Z` |
| `elev_id` | integer | Filtrare per elev | `42` |
| `limit` | integer | Număr maxim rezultate | `100` |
| `offset` | integer | Paginare (skip) | `0` |

**Exemplu cerere:**
```
GET /admin/scan-logs?from=2026-05-01T00:00:00Z&to=2026-05-15T23:59:59Z&limit=50
```

**Response 200 OK:**
```json
{
  "total": 234,
  "logs": [
    {
      "id": 1001,
      "elev_id": 42,
      "elev_nume": "Popescu Ioan",
      "clasa": "12A",
      "timestamp": "2026-05-15T08:12:34Z",
      "tip": "intrare",
      "locatie": "Poarta principala"
    }
  ]
}
```

**Implementare:** `lib/services/elev_service.dart`

---

### 📊 Statistici (Statistics)

#### `GET /admin/stats`

Returnează statistici agregate pentru dashboard.

**Query Parameters:**

| Parametru | Tip | Descriere |
|-----------|-----|-----------|
| `period` | string | `today` / `week` / `month` / `custom` |
| `from` | string | Obligatoriu dacă `period=custom` |
| `to` | string | Obligatoriu dacă `period=custom` |

**Response 200 OK:**
```json
{
  "total_scanari_azi": 312,
  "total_scanari_saptamana": 1847,
  "total_scanari_luna": 6234,
  "elevi_prezenti_azi": 267,
  "elevi_prezenti_saptamana": 298,
  "grafic_zilnic": [
    { "data": "2026-05-09", "scanari": 289 },
    { "data": "2026-05-10", "scanari": 0 },
    { "data": "2026-05-11", "scanari": 0 },
    { "data": "2026-05-12", "scanari": 301 },
    { "data": "2026-05-13", "scanari": 315 },
    { "data": "2026-05-14", "scanari": 298 },
    { "data": "2026-05-15", "scanari": 312 }
  ],
  "top_absenti": [
    { "elev_id": 77, "nume": "Ionescu Mihai", "clasa": "10C", "zile_absente": 12 },
    { "elev_id": 34, "nume": "Pop Ana", "clasa": "11A", "zile_absente": 9 }
  ]
}
```

---

### 👨‍🏫 Profesori (Professors)

#### `GET /admin/profesori`

Returnează lista profesorilor.

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "nume": "Prof. Gheorghe",
    "prenume": "Alexandru",
    "email": "prof@scoala.ro",
    "materie": "Matematică",
    "clasa_diriginte": "12A"
  }
]
```

**Model Dart:** `lib/models/professor.dart`

---

### 🔄 Fluxul Complet de Date

```
Flutter App                    API Backend                   Database
    │                               │                            │
    │  POST /admin/login            │                            │
    │──────────────────────────────►│                            │
    │                               │  SELECT user WHERE email   │
    │                               │───────────────────────────►│
    │                               │◄───────────────────────────│
    │  { token: "eyJ..." }          │  Verifică parola (bcrypt)  │
    │◄──────────────────────────────│  Generează JWT             │
    │                               │                            │
    │  [Salvează token în           │                            │
    │   SharedPreferences]          │                            │
    │                               │                            │
    │  GET /admin/elevi             │                            │
    │  Authorization: Bearer eyJ... │                            │
    │──────────────────────────────►│                            │
    │                               │  Validează JWT             │
    │                               │  SELECT * FROM elevi       │
    │                               │───────────────────────────►│
    │                               │◄───────────────────────────│
    │  [{ id, nume, ... }]          │                            │
    │◄──────────────────────────────│                            │
    │                               │                            │
    │  [Afișează în Dashboard]      │                            │
```

---

### ⚠️ Gestionare Erori

Toate răspunsurile de eroare urmează formatul:

```json
{
  "error": "Descriere scurtă",
  "message": "Mesaj detaliat pentru utilizator",
  "code": 401
}
```

| Cod HTTP | Semnificație |
|----------|-------------|
| `200` | Succes |
| `400` | Date de intrare invalide |
| `401` | Neautentificat / Token expirat |
| `403` | Acces interzis (permisiuni insuficiente) |
| `404` | Resursa nu există |
| `500` | Eroare internă server |

**Gestionare în aplicație:** `lib/services/error_service.dart`

---

## 🇬🇧 English

### Base URL

```
https://api.pontaj.binarysquad.club
```

### Authentication Flow

```
1. POST /admin/login → receive JWT token
2. Store token in SharedPreferences
3. Include in all requests: Authorization: Bearer <token>
4. On 401 response → redirect to login screen
```

### Endpoint Summary

| Method | Endpoint | Auth Required | Description |
|--------|----------|--------------|-------------|
| `POST` | `/admin/login` | ❌ | Authenticate and get JWT token |
| `GET` | `/admin/elevi` | ✅ | List all students |
| `GET` | `/admin/elevi/{id}` | ✅ | Get student details |
| `GET` | `/admin/scan-logs` | ✅ | Get scan history (filterable) |
| `GET` | `/admin/stats` | ✅ | Get dashboard statistics |
| `GET` | `/admin/profesori` | ✅ | List all professors |

### Service Files

| Service | File | Responsibilities |
|---------|------|-----------------|
| `AuthService` | `lib/services/auth_service.dart` | Login, logout, token storage |
| `AdminService` | `lib/services/admin_service.dart` | Statistics, admin operations |
| `ElevService` | `lib/services/elev_service.dart` | Students, scan logs |
| `ErrorService` | `lib/services/error_service.dart` | Global error handling |

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Java Troubleshooting](./07-java-troubleshooting.md) | [Index](./README.md) | [Ghid UI/UX →](./09-ui-ux-guide.md)
