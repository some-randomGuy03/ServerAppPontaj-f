# 🐳 Deployment cu Docker / Docker Deployment Guide

---

## 🇷🇴 Română

### Cerințe Server

| Cerință | Versiune | Note |
|---------|---------|------|
| **Docker Engine** | 20.10+ | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| **Docker Compose** | v2.0+ | Inclus în Docker Desktop |
| **RAM** | minim 512 MB | Recomandat 1 GB+ |
| **Spațiu disk** | minim 2 GB | Pentru imagini Docker + build Flutter |
| **OS** | Linux (Ubuntu/Debian recomandat) | Windows Server suportat |

---

### ⚡ Pornire Rapidă

```bash
# 1. Clonează repository-ul pe server
git clone https://github.com/your-username/ServerAppPontaj-f.git
cd ServerAppPontaj-f

# 2. Pornește cu Docker Compose (build inclus)
docker compose up -d

# 3. Verifică dacă rulează
docker ps
# Ar trebui să vezi: 0.0.0.0:24364->80/tcp
```

Aplicația este accesibilă la: `http://YOUR_SERVER_IP:24364`

---

### 📋 Explicarea Fișierelor Docker

#### `Dockerfile`

Imaginea Docker folosește un **build multi-stage**:

```
Etapa 1: BUILD
  ├── Imagine: ghcr.io/cirruslabs/flutter (Flutter preinstalat)
  ├── Copiere cod sursă
  ├── flutter pub get (descărcare dependențe)
  ├── flutter gen-l10n (generare localizare)
  └── flutter build web --release (compilare)

Etapa 2: RUNTIME
  ├── Imagine: nginx:alpine (server web minimal)
  ├── Copiere fișiere din build/web/
  ├── Copiere nginx.conf
  └── Expunere port 80
```

#### `docker-compose.yml`

```yaml
# Structura services:
services:
  web:
    build: .                    # Construiește din Dockerfile local
    ports:
      - "24364:80"             # Port extern:intern
    restart: unless-stopped    # Repornire automată la crash
```

#### `nginx.conf`

Configurare Nginx pentru aplicație Flutter web:
- Servește fișierele statice din `build/web/`
- Redirecționează toate rutele la `index.html` (SPA routing)
- Endpoint `/health` pentru monitorizare
- Compresie gzip activată

---

### 🛠️ Comenzi Docker Utile

```bash
# Pornire (build + start)
docker compose up -d

# Pornire cu rebuild forțat (după modificări de cod)
docker compose up -d --build

# Oprire
docker compose down

# Vizualizare loguri în timp real
docker compose logs -f

# Vizualizare loguri ultimele 100 linii
docker compose logs --tail=100

# Restart container
docker compose restart

# Status containere
docker ps
docker stats pontaj-admin-web

# Intrare în container (debugging)
docker exec -it pontaj-admin-web sh
```

---

### 🔄 Actualizare Aplicație

```bash
# 1. Aduce ultimele modificări din git
git pull origin main

# 2. Rebuild și restart
docker compose down
docker compose up -d --build

# Sau mai scurt:
docker compose up -d --build --force-recreate
```

---

### 🚨 Troubleshooting Docker

#### Containerul nu pornește
```bash
# Verifică logurile
docker compose logs web

# Erori frecvente:
# - Port 24364 deja ocupat → schimbă portul în docker-compose.yml
# - Spațiu disk insuficient → docker system prune -a
```

#### Eroare "KeyError: ContainerConfig" (Docker Compose v1 vs v2)
Această eroare apare deoarece folosești versiunea veche și depreciată de `docker-compose` (V1 în Python, v1.29.2) cu o versiune mai nouă de Docker Engine.

**Soluția Recomandată:**
Treci la versiunea modernă **Docker Compose V2** (scrisă în Go) pur și simplu rulând comanda fără cratimă:
```bash
docker compose up -d --build
```
*(Dacă nu este instalat, îl poți instala pe Linux folosind `sudo apt install docker-compose-plugin`).*

**Alternativă (Comenzi plain Docker):**
Dacă nu poți instala Compose V2 imediat, oprește manual containerele vechi care creează conflictul și rulează-le direct:
```bash
# Oprire și ștergere container vechi
docker stop pontaj-admin-web || true
docker rm pontaj-admin-web || true

# Build manual
docker build -t pontaj-admin .

# Rulare manuală
docker run -d \
  --name pontaj-admin-web \
  -p 24364:80 \
  --restart unless-stopped \
  pontaj-admin
```

#### Port blocat de firewall
```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 24364/tcp
sudo ufw status

# CentOS/RHEL (Firewalld)
sudo firewall-cmd --permanent --add-port=24364/tcp
sudo firewall-cmd --reload
```

#### Verificare sănătate aplicație
```bash
# Health check endpoint
curl http://localhost:24364/health
# Răspuns așteptat: healthy

# Sau verifică direct
curl -I http://localhost:24364/
# Răspuns așteptat: HTTP/1.1 200 OK
```

---

### 🔒 Recomandări Securitate

1. **Folosește HTTPS** — Configurează SSL cu Let's Encrypt (vezi [Configurare Server](./05-server-nginx.md))
2. **Firewall** — Permite doar porturile necesare (80, 443, 22)
3. **Actualizează imaginile** periodic:
   ```bash
    docker compose pull
    docker compose up -d
   ```
4. **Nu expune portul 24364 direct** — Folosește reverse proxy Nginx
5. **Backup date** — Dacă ai volume Docker cu date persistente

---

### 🧹 Curățare Docker

```bash
# Curăță containere, imagini și volume neutilizate
docker system prune -a

# Doar imagini neutilizate
docker image prune -a

# Verifică spațiu utilizat
docker system df
```

---

## 🇬🇧 English

### Quick Reference

```bash
# Start
docker compose up -d

# Stop  
docker compose down

# Update (after code changes)
git pull && docker compose up -d --build

# View logs
docker compose logs -f

# Check health
curl http://localhost:24364/health
```

### Port Configuration

Default port is `24364`. To change it, edit `docker-compose.yml`:

```yaml
ports:
  - "YOUR_PORT:80"   # Change YOUR_PORT to desired port number
```

### Production Deployment Flow

```
Developer pushes code
         ↓
    git pull (on server)
         ↓
docker compose up -d --build
         ↓
  Docker builds Flutter web
         ↓
  Nginx serves build/web/
         ↓
  App available on port 24364
         ↓
  Nginx reverse proxy (optional)
         ↓
  HTTPS at your-domain.com
```

---

## 🔗 Navigare Documentație / Documentation Navigation

← [Ghid Instalare](./03-getting-started.md) | [Index](./README.md) | [Server & Nginx →](./05-server-nginx.md)
