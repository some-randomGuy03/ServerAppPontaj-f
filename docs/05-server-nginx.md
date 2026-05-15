# 🌐 Configurare Server & Nginx / Server & Nginx Setup

---

## 🇷🇴 Română

### Opțiuni de Acces la Aplicație

Există trei moduri principale de a expune aplicația pe internet:

| Opțiune | URL Rezultat | Dificultate | Recomandat |
|---------|-------------|------------|------------|
| **Port direct** | `http://ip:24364` | ⭐ Ușor | ❌ Nu (nesecurizat) |
| **Subdomeniu propriu** | `https://adminpontaj.binarysquad.club` | ⭐⭐⭐ Mediu | ✅ Da |
| **Subdirector** | `https://binarysquad.club/pontaj-admin` | ⭐⭐ Mediu | ✅ Da |

---

### 🔌 Opțiunea 1: Acces Direct prin Port

Cel mai simplu mod, **fără configurare suplimentară**:

```
http://YOUR_SERVER_IP:24364
```

**Dezavantaje:**
- Fără HTTPS (trafic necriptat)
- Portul poate fi blocat de Cloudflare sau firewall
- Nu arată profesional

---

### 🌐 Opțiunea 2: Subdomeniu Dedicat (Recomandat)

#### Pasul 1: Adaugă DNS A Record

La furnizorul tău de domeniu (ex: Namecheap, GoDaddy, Cloudflare):

```
Tip:    A Record
Host:   adminpontaj
Valoare: YOUR_SERVER_IP
TTL:    Automatic (sau 3600)
```

Rezultat: `adminpontaj.binarysquad.club` → `YOUR_SERVER_IP`

> ⏳ Asteaptă 5-30 minute pentru propagarea DNS.

#### Pasul 2: Rulează Scriptul Automat

Am pregătit un script care face totul automat:

```bash
# Urci scriptul pe server sau îl creezi direct
chmod +x setup_proxy.sh
./setup_proxy.sh
```

Scriptul va:
1. Detecta directorul Nginx (`sites-available` sau `conf.d`)
2. Crea configurarea pentru subdomeniu
3. Testa și reîncărca Nginx
4. Verifica DNS-ul
5. Oferi să ruleze Certbot pentru SSL

#### Pasul 3: SSL cu Let's Encrypt (Manual)

```bash
# Instalează Certbot
sudo apt install certbot python3-certbot-nginx

# Obține certificat SSL
sudo certbot --nginx -d adminpontaj.binarysquad.club

# Certbot configurează automat HTTPS și redirecționare HTTP→HTTPS
```

#### Pasul 4: Configurare Nginx Manuală

Dacă scriptul automat eșuează, creează manual:

```bash
sudo nano /etc/nginx/sites-available/pontaj-admin
```

Conținut fișier:

```nginx
server {
    listen 80;
    server_name adminpontaj.binarysquad.club;

    location / {
        proxy_pass http://localhost:24364;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Activează site-ul
sudo ln -s /etc/nginx/sites-available/pontaj-admin /etc/nginx/sites-enabled/

# Testează configurarea
sudo nginx -t

# Reîncarcă Nginx
sudo systemctl reload nginx
```

---

### 📁 Opțiunea 3: Subdirector al Site-ului Existent

Dacă vrei să servești aplicația la `https://binarysquad.club/pontaj-admin`:

#### Pasul 1: Găsește fișierul Nginx activ

```bash
# Caută fișierul care gestionează domeniul principal
grep -rl "server_name binarysquad.club" /etc/nginx/sites-enabled/
```

#### Pasul 2: Editează fișierul găsit

```bash
sudo nano /etc/nginx/sites-enabled/FISIERUL_GASIT
```

#### Pasul 3: Adaugă blocul location

Adaugă **în interiorul** blocului `server { ... }`, înainte de `}`:

```nginx
    # Pontaj Admin - Subdirector Proxy
    location /pontaj-admin {
        # Elimină prefixul subdirectorului înainte de a trimite la container
        rewrite ^/pontaj-admin/(.*)$ /$1 break;
        
        proxy_pass http://localhost:24364;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
```

> ⚠️ **Notă:** Slash-ul final din URL este important: `https://binarysquad.club/pontaj-admin/`

#### Pasul 4: Testează și reîncarcă

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

### 🔍 Troubleshooting Nginx & Server

#### Nginx nu pornește / erori de sintaxă

```bash
# Testează configurarea
sudo nginx -t

# Verifică statusul
sudo systemctl status nginx

# Vizualizează log-urile de eroare
sudo tail -f /var/log/nginx/error.log

# Vizualizează log-urile de acces
sudo tail -f /var/log/nginx/access.log
```

#### "Directory not found" la crearea config

```bash
# Verifică ce directoare există
ls /etc/nginx/

# Dacă nu există sites-available, folosește conf.d
sudo nano /etc/nginx/conf.d/pontaj-admin.conf
# (nu mai este nevoie de symlink pentru conf.d)
```

#### Certbot eșuează — "Non-existent domain"

1. Verifică că DNS A Record este configurat corect
2. Testează propagarea DNS:
   ```bash
   ping adminpontaj.binarysquad.club
   # sau
   nslookup adminpontaj.binarysquad.club
   ```
3. Dacă nu răspunde, mai asteaptă 10-30 minute
4. **Abia după** ce ping funcționează, rulează Certbot

#### Port 8080/24364 inaccesibil din exterior

```bash
# Verifică firewall-ul
sudo ufw status

# Permite portul
sudo ufw allow 24364/tcp

# Sau cu firewalld
sudo firewall-cmd --permanent --add-port=24364/tcp
sudo firewall-cmd --reload
```

---

### 📊 Diagrama Flux DNS & SSL

```
Browser utilizator
        │
        │ https://adminpontaj.binarysquad.club
        ▼
   ┌─────────────┐
   │  DNS Lookup  │ → A Record → YOUR_SERVER_IP
   └──────┬──────┘
          │
          ▼ :443 (HTTPS)
   ┌─────────────────────────┐
   │   Server Linux           │
   │                          │
   │  ┌─────────────────────┐ │
   │  │  Nginx (host)        │ │
   │  │  Let's Encrypt SSL   │ │
   │  │  Decriptează HTTPS   │ │
   │  └──────────┬──────────┘ │
   │             │ HTTP intern  │
   │             ▼ :24364      │
   │  ┌─────────────────────┐ │
   │  │  Docker Container    │ │
   │  │  Nginx (intern)      │ │
   │  │  Servește Flutter    │ │
   │  └─────────────────────┘ │
   └─────────────────────────┘
```

---

## 🇬🇧 English

### Quick Setup Summary

**Option A — Dedicated subdomain (recommended):**
1. Add DNS A record: `adminpontaj` → `YOUR_SERVER_IP`
2. Run `./setup_proxy.sh` on the server
3. Run `sudo certbot --nginx -d adminpontaj.binarysquad.club` for HTTPS

**Option B — Subdirectory of existing site:**
1. Edit existing Nginx config for `binarysquad.club`
2. Add `/pontaj-admin` location block (see above)
3. Reload Nginx: `sudo systemctl reload nginx`

**Option C — Direct port access (no HTTPS):**
```
http://YOUR_SERVER_IP:24364
```

### Nginx Reload Commands

```bash
sudo nginx -t              # Test configuration syntax
sudo systemctl reload nginx  # Apply changes without downtime
sudo systemctl restart nginx # Full restart (brief downtime)
sudo systemctl status nginx  # Check current status
```

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Deployment Docker](./04-deployment.md) | [Index](./README.md) | [Build Android →](./06-android-build.md)
