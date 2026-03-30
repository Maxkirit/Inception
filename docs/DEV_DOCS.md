*If you are a user, please refer to USER_DOC.md.*


## 1. Architecture Overview

Inception is a multi-container Docker infrastructure managed through a single `docker-compose.yml`. All services communicate over a private bridge network (`inception`). The only ports exposed to the host are `443` (HTTPS via NGINX) and `21` / `21100-21110` (FTP).

```
                         Host
                          │
              ┌───────────┴──────────────┐
              │ 443 (HTTPS)   21 (FTP)   │
              │                          │
         ┌────▼────┐              ┌──────▼──────┐
         │  NGINX  │              │  vsftpd/FTP │
         └────┬────┘              └──────┬──────┘
              │                          │
     ┌────────┼──────────┐               │
     │        │          │               │
┌────▼──┐ ┌───▼───┐ ┌────▼──────┐  (nginx_wp volume)
│ WP/   │ │ Zola  │ │  Adminer  │
│PHP-FPM│ │static │ │  (PHP-FPM)│
└────┬──┘ └───────┘ └────┬──────┘
     │                    │
┌────▼────────────────────▼────┐
│            MariaDB            │
└───────────────┬───────────────┘
                │
      ┌─────────┴──────────┐
      │                    │
  ┌───▼───┐      ┌─────────▼────────┐
  │ Redis │      │  MariaDB Backup  │
  └───────┘      └──────────────────┘
```

**Shared volumes** are the primary mechanism for inter-service file sharing (e.g., `nginx_wp` is written by WordPress/PHP-FPM and read by NGINX and FTP).

---

## 2. Repository Structure

```
├── docs
│   ├── DEV_DOC.md
│   └── USER_DOC.md
├── Makefile
├── README.md
├── .env                          #not committed
├── .env_example                  #example value only, fill with yours and rename to .env
├── secrets                       #not committed  
│   ├── db_backup_password.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   ├── ssl_key.pem
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs
    ├── adminer
    │   ├── adminer.php
    │   └── Dockerfile
    ├── docker-compose.yml
    ├── ftp
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   └── vsftpd.conf
    ├── mariadb
    │   ├── Dockerfile
    │   ├── entrypoint.sh
    │   └── my.cnf
    ├── mariadb-backup
    │   ├── backup.sh
    │   ├── Dockerfile
    │   └── entrypoint.sh
    ├── nginx
    │   ├── Dockerfile
    │   ├── nginx.conf
    │   └── ssl_cert.pem
    ├── redis
    │   ├── Dockerfile
    │   └── redis.conf
    ├── wordpress
    │   ├── Dockerfile
    │   └── ressources
    │       ├── build_script.sh
    │       ├── entrypoint.sh
    │       └── www.conf
    └── zola_website
        ├── Dockerfile
        ├── entrypoint.sh
        └── project/                #Zola files for website generation
```

> **Note:** The `.env` file and `secrets/` directory must sit at the **repository root** (one level above `srcs/`). Docker Compose references them as `../.env` and `../secrets/`.

---

## 3. Prerequisites

| Requirement | Notes |
|---|---|
| Docker Engine ≥ 24.x | Tested on Debian |
| Docker Compose plugin (v2) | Included in Docker Desktop; install separately on Linux (`docker compose`, not `docker-compose`) |
| `make` | GNU Make, standard on Linux |
| `openssl` (optional) | To generate a self-signed SSL key if not provided |

---

## 4. Environment Setup

### 4.1 `.env` File

Copy `.env_example` to `.env` at the repository root and fill in every variable. Missing or malformed variables will cause containers to fail silently or at startup. No ASCII whitespaces either.
> Passwords are **not** stored in `.env` — they are handled exclusively via Docker secrets (see section 4.2).

### 4.2 Secrets

Create a `secrets/` directory at the repository root. Each file must contain exactly one value — no trailing newlines, no surrounding whitespace.

```
secrets/
├── db_password.txt          # Password for MARIA_DB_USER
├── db_root_password.txt     # MariaDB root password
├── db_backup_password.txt   # Dedicated password for the mariabackup user
├── wp_admin_password.txt    # WordPress admin account password
├── ssl_key.pem              # SSL private key (PEM format, self-signed or CA-issued)
├── wp_user_password.txt     # WordPress regular user password
└── ftp_password.txt         # vsftpd user password
```

**Generating a self-signed certificate and key:**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/ssl_key.pem \
  -out srcs/requirements/nginx/conf/ssl_cert.pem \
  -subj "/CN=mturgeon.42.fr"
```

> The certificate (`.pem` public part) is baked into the NGINX image at build time. Only the **private key** is injected as a Docker secret at runtime.

---

## 5. Building and Launching

All commands are run from the **repository root** via `make`.

### 5.1 Makefile Commands

| Command | Effect |
|---|---|
| `make upd` | Build images if needed and start all services in detached mode |
| `make up` | Same, but in the foreground (blocks terminal, shows all logs) |
| `make down` | Stop and remove containers; volumes are preserved |
| `make vdown` | Stop containers **and delete all volumes** (full reset) |
| `make check` | Show the status of all containers (`docker compose ps`) |
| `make start` | starts containers that where paused|
| `make stop` | pause the container (freezes runtime) |
> Refer to the Makefile itself for the exact `docker compose` invocations. The compose file is located at `srcs/docker-compose.yml`.

### 5.2 First Launch

The first `make upd` triggers a full image build for every service. Expected timeline:

- **Build phase**: 1-2 minutes depending on network speed (package downloads, Zola build).
- **Init phase** (after containers start): ~1 minutes. MariaDB initialises its data directory, WordPress runs WP-CLI setup, and Zola generates the static site.

Use `make check` repeatedly to watch services transition to `Running`. The expected final state is:

| Container | Status |
|---|---|
| nginx | Running |
| wordpress | Running |
| mariadb | Running |
| redis | Running |
| adminer | Running |
| ftp | Running |
| mariadb-backup | Running |
| zola_website | Exited (0) — expected, it's a one-shot build container |

---

## 6. Service Reference

### 6.1 NGINX

**Role:** TLS termination and reverse proxy.

**Build context:** `srcs/requirements/nginx/`

**Key behaviour:**
- Listens exclusively on port `443` with TLSv1.2/1.3. No HTTP redirect — port 80 is not exposed.
- The site config template uses `envsubst` at container startup to substitute `$DOMAIN_NAME` into the final nginx config.
- Two `server` blocks: one for the WordPress upstream (FastCGI → `wordpress:9000`) and one for the Zola static site (served from the `zola` volume mount at `/var/www/html/zola`).
- The Adminer PHP file is served via a `location /adminer.php` FastCGI block proxied to `adminer:9000`.
- The SSL private key is mounted at runtime from the Docker secret `ssl_certificate_key`.

**Depends on:** `wordpress` (healthy), `mariadb` (healthy), `redis` (healthy), `zola_website` (completed successfully).

**Volumes:** `nginx_wp` at `/var/www/html`, `zola` at `/var/www/html/zola`.

---

### 6.2 WordPress / PHP-FPM

**Role:** WordPress application server (PHP-FPM on port 9000).

**Build context:** `srcs/requirements/wordpress/`

**Key behaviour:**
- Installs WordPress and WP-CLI at build time.
- On first startup, the entrypoint script checks whether `wp-config.php` already exists. If not, it:
  1. Reads secrets from `/run/secrets/` to build the DB credentials.
  2. Runs `wp config create` and `wp core install` via WP-CLI.
  3. Installs and activates the Redis Object Cache plugin, writing `object-cache.php` to `wp-content/`.
- Exposes a healthcheck (e.g., `nc -z localhost 9000` or equivalent).
- PHP-FPM listens on `wordpress:9000` (all interfaces on the inception network).

**Secrets used:** `wpadminpwd`, `dbpassword`, `dbrootpassword`, `wp_user_password`.

**Volumes:** `nginx_wp` at `/var/www/html` (shared with NGINX and FTP).

---

### 6.3 MariaDB

**Build context:** `srcs/requirements/mariadb/`

**Build arg:** `MARIADB_CONFIG_FILE=mariadb_config_file.txt` — this file is copied into the image and used to configure the MariaDB server (e.g., `bind-address`, `max_connections`, charset settings).

**Key behaviour:**
- Entrypoint initialises the data directory, creates the WordPress database and user, sets the root password, and creates a dedicated `mariabackup` user for the backup service.
- Exposes a healthcheck (typically `healthcheck --connect --user=root`).
- MariaDB binds on `mariadb:3306` within the inception network only.

**Secrets used:** `dbpassword`, `dbrootpassword`, `dbbackuppassword`.

**Volumes:** `mariadb` at `/var/lib/mysql`.

---

### 6.4 Redis

**Role:** In-memory object cache between WordPress and MariaDB.

**Build context:** `srcs/requirements/redis/`

**Key behaviour:**
- Custom `redis.conf` disables persistence (no RDB snapshots, no AOF) — the cache is volatile by design.
- WordPress connects via the `WP_REDIS_HOST` / `WP_REDIS_PORT` constants (set in `wp-config.php` or via the Object Cache plugin config).
- Exposes a healthcheck (typically `redis-cli ping`).

**No secrets or volumes.** State is ephemeral.

---

### 6.5 Adminer

**Role:** Web-based database GUI.

**Build context:** `srcs/requirements/adminer/`

**Key behaviour:**
- Runs PHP-FPM serving `adminer.php`. NGINX proxies `location /adminer.php` FastCGI requests to `adminer:9000`.
- The `adminer.php` file is either downloaded at build time or baked in.
- No authentication at the container level — Adminer uses MariaDB credentials directly.

**Access:** `https://<DOMAIN_NAME>/adminer.php`

Log in with `MARIA_DB_USER` and the password from `db_password.txt` (not root).

---

### 6.6 FTP (vsftpd)

**Role:** FTP access to the WordPress web root.

**Build context:** `srcs/requirements/ftp/`

**Key behaviour:**
- vsftpd is configured in passive mode. The passive port range `21100-21110` is mapped to the host.
- The FTP user is created at container startup using `FTP_USER` from `.env` and the password from the `ftp_password` secret.
- The FTP root is chrooted to `/var/www/html` (the `nginx_wp` volume mount).
- Write access allows uploading themes, plugins, and media directly to the WordPress file tree.

**Ports:** `21` (control), `21100-21110` (passive data).

**Secrets:** `ftp_password`.

**Volumes:** `nginx_wp` at `/var/www/html`.

---

### 6.7 MariaDB Backup

**Role:** Automated incremental database backup using `mariabackup`.

**Build context:** `srcs/requirements/mariadb-backup/`

**Key behaviour:**
- `init: true` in the compose file adds `tini` as PID 1, which ensures correct signal handling for `crond`.
- **At build time / first start:** a full backup is taken with `mariabackup --backup`.
- **Daily at 02:00:** a cron job runs an incremental backup (`mariabackup --backup --incremental-basedir=<last backup>`), updating the full backup copy with changes since.
- The `mariabackup` user credentials come from `dbbackuppassword` and must match the user created by MariaDB's entrypoint.
- Connects to MariaDB over the inception network (host: `mariadb`, port: `3306`).

**Known issue (at last session):** A `setpgid` crash was observed — investigate whether the `init: true` flag and the crond invocation correctly isolate the process group, or whether a wrapper script is needed.

**Secrets:** `dbbackuppassword`.

**Volumes:**
- `mariadb` at `/var/lib/mysql` (read-only access to live DB files for hot backup).
- `mariadb-copy` at `/backups` (backup destination).

---

### 6.8 Zola Static Site

**Role:** One-shot static site generator for the resume/blog.

**Build context:** `srcs/requirements/zola_website/`

**Key behaviour:**
- Runs `zola build` at container startup, writing output to the `zola` volume (`/data`).
- The container exits with code 0 on success. Docker Compose records the status as `Exited (0)` — this is expected and intentional.
- NGINX depends on `zola_website` with `condition: service_completed_successfully`, ensuring the static files are present before NGINX starts.
- `restart: on-failure:5` allows recovery from transient build failures (e.g., network issues during asset fetching), but does not restart after a clean exit.

**To update the static site** without a full restart:
```bash
docker compose stop nginx
docker compose up zola_website   # rebuilds static files
docker compose up -d nginx
```

**Volumes:** `zola` at `/data`.

---

## 7. Volumes and Data Persistence

| Volume name | Docker name | Services | Contents |
|---|---|---|---|
| `mariadb` | `mariadb_volume` | mariadb, mariadb-backup | MariaDB data directory (`/var/lib/mysql`) |
| `nginx_wp` | `wp_volume` | wordpress, nginx, ftp | WordPress web root (`/var/www/html`) |
| `mariadb-copy` | `mariadb-backup-volume` | mariadb-backup | Incremental backup files |
| `zola` | `zola` | zola_website, nginx | Generated static site files |

**Persistence behaviour:**
- `make down` stops containers but **preserves** all volumes. A subsequent `make upd` resumes from the existing state in ~1 minute.
- `make vdown` removes containers **and deletes all volumes**. All WordPress content, database data, and backups are wiped. The next start rebuilds everything from scratch (~2 minutes).

**Inspecting volumes on the host:**
```bash
docker volume inspect mariadb_volume     # shows actual mount path
docker volume ls                         # list all project volumes
```

---

## 8. Secrets Management

Docker secrets are mounted as files inside containers at `/run/secrets/<secret_name>`. Scripts and entrypoints read them with:

```bash
cat /run/secrets/dbpassword
```

or in PHP:

```php
file_get_contents('/run/secrets/dbpassword')
```

**Rules:**
- One credential per file. No trailing newline (`printf 'mypassword' > secrets/db_password.txt`).
- Never store secrets in `.env`, Dockerfiles, or image layers.
- Never commit `secrets/` or `.env` to version control. Add both to `.gitignore`.

**Adding a new secret:**
1. Add the file under `secrets/`.
2. Declare it in the `secrets:` top-level block of `docker-compose.yml`.
3. Add it under the relevant service's `secrets:` list.
4. Reference it at `/run/secrets/<name>` inside the container.

---

## 9. Networking

All services share a single bridge network named `inception`. No service is directly reachable from the host except through the exposed ports (`443`, `21`, `21100-21110`).

Inter-service communication uses Docker's internal DNS. Services reference each other by **container name**:

| Service | Internal address | Port |
|---|---|---|
| nginx | `nginx` | 443 |
| wordpress | `wordpress` | 9000 (FastCGI) |
| mariadb | `mariadb` | 3306 |
| redis | `redis` | 6379 |
| adminer | `adminer` | 9000 (FastCGI) |
| ftp | `ftp` | 21 / 21100-21110 |
| mariadb-backup | `mariadb-backup` | — (client only) |
| zola_website | `zola_website` | — (build only) |

---

## 10. Service Health and Dependencies

The startup order is enforced via `depends_on` with `condition` checks. MariaDB does **not** declare a healthcheck in the compose file — it must be defined in the MariaDB Dockerfile using `HEALTHCHECK`. The same applies to WordPress and Redis.

**Dependency graph:**

```
zola_website ──(completed_successfully)──► nginx
wordpress    ──(healthy)──────────────────► nginx
mariadb      ──(healthy)──────────────────► nginx, wordpress, adminer, mariadb-backup
redis        ──(healthy)──────────────────► nginx, wordpress
wordpress    ──(healthy)──────────────────► ftp
```

If a healthcheck never passes, dependent services will remain in `Waiting` state indefinitely. Use `make logs` and `docker inspect <container>` to diagnose.

---

## 11. Debugging and Logs

**View logs for a specific service:**
```bash
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

**Open a shell in a running container:**
```bash
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

**Check MariaDB directly:**
```bash
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u"$MARIA_DB_USER" -p"$(cat secrets/db_password.txt)" "$MARIA_DB_NAME"
```

**Inspect a volume's contents:**
```bash
docker run --rm -v mariadb_volume:/data alpine ls /data
docker run --rm -v mariadb-backup-volume:/backups alpine ls /backups
```

**Inspect healthcheck status:**
```bash
docker inspect --format='{{json .State.Health}}' mariadb | python3 -m json.tool
```

**Rebuild a single service without full reset:**
```bash
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

**Wipe and restart a single service (keep other volumes):**
```bash
docker compose -f srcs/docker-compose.yml stop wordpress
docker compose -f srcs/docker-compose.yml rm -f wordpress
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```