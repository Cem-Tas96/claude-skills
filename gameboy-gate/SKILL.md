---
name: gameboy-gate
description: |
  Aufnahmeprüfung für jedes Projekt das auf dem Gameboy (Hetzner CAX11, 4GB RAM, 2 vCPU)
  deployed werden soll. Kein Projekt wird released bevor dieser Gate bestanden ist.
  Berechnet Limits dynamisch anhand des aktuellen Server-Zustands, konfiguriert Coolify
  persistent, testet unter Last und gibt PASS oder FAIL zurück.
triggers:
  - "gameboy gate"
  - "gameboy test"
  - "aufnahmeprüfung"
  - "server test"
  - "deploy check"
  - "gameboy check"
---

# 🎮 Gameboy-Gate — Aufnahmeprüfung für jedes Projekt

> **PFLICHT:** Jedes Projekt das auf dem Gameboy (`<GAMEBOY_IP>`) deployed wird, muss diesen Gate bestehen — egal wer Claude nutzt, egal welches Projekt. Kein Release ohne PASS.

> **🔒 Verbindungsdaten lokal:** Reale Werte für `<GAMEBOY_IP>`, `<GAMEBOY_SSH>`, `<COOLIFY_URL>`, `<WATCHDOG_*>` stehen in der **gitignored** Datei `gameboy-gate/gameboy.local.md` (NICHT im public Repo). Vor jedem Gate-Lauf diese Datei lesen und die Platzhalter ersetzen.

## KONTEXT: Der Gameboy

```
Server: Hetzner CAX11 (ARM)
IP:     <GAMEBOY_IP>          # real: siehe gameboy.local.md
SSH:    <GAMEBOY_SSH>         # real: siehe gameboy.local.md
RAM:    4GB total
CPU:    2x vCPU (ARM Neoverse-N1 @ 2.0GHz)
Disk:   40GB SSD
OS:     Ubuntu (Docker + Coolify)
Coolify UI: <COOLIFY_URL>     # real: siehe gameboy.local.md
```

**Feste Overhead-Reservierung (NIE unterschreiten):**
```
OS + Kernel:              400MB
Coolify (inkl. DB, Redis, Proxy, Sentinel): 900MB
Safety-Buffer:            200MB
──────────────────────────────
FREI für Projekte:       ~2500MB  (aus 4096MB Gesamt)
```

**Projekte die bereits laufen (Stand 26.06.2026 — reale Namen siehe `gameboy.local.md`):**
- `app-workflow` (Activepieces): 1536MB limit / 768MB reservation
- `app-billing` (Next.js): 512MB limit / 256MB reservation
- `app-landing` (Static): 256MB limit / 128MB reservation
- **Belegt:** 2304MB limit / 1152MB reservation

---

## GATE-ABLAUF (in dieser Reihenfolge, kein Überspringen)

### Phase G0: Server-Snapshot holen

Immer zuerst — das ist die Wahrheit über den aktuellen Server-Zustand:

```bash
<GAMEBOY_SSH> "
free -h &&
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}' &&
df -h / &&
docker inspect \$(docker ps -q) --format '{{.Name}}: mem={{.HostConfig.Memory}}' 2>/dev/null | sort
"
```

Daraus ableiten:
- `TOTAL_RAM_MB` (fast immer 3840MB = 3.7GB als Bytes)
- `COOLIFY_OVERHEAD_MB` = Summe aller Coolify-eigenen Container (coolify, coolify-db, coolify-redis, coolify-sentinel, coolify-proxy) aktuell
- `RUNNING_PROJECTS_MB` = Summe der mem_limit aller laufenden Projekt-Container
- `AVAILABLE_MB` = TOTAL_RAM_MB - 400 (OS) - COOLIFY_OVERHEAD_MB - RUNNING_PROJECTS_MB - 200 (safety)

### Phase G1: Limit-Berechnung (KI-gesteuert, keine Hardcodes)

Basierend auf dem Projekt-Typ berechnet die KI die richtigen Limits:

```
PROJEKT-TYP ERKENNEN:
- Node.js / Next.js App       → BASE_MB = 350, WORKER_OVERHEAD = 50 pro Worker
- Python / Django / FastAPI   → BASE_MB = 200, WORKER_OVERHEAD = 30 pro Worker
- Go / Rust Service           → BASE_MB = 80,  WORKER_OVERHEAD = 20 pro Worker
- Static-Site (nginx/caddy)   → BASE_MB = 64,  WORKER_OVERHEAD = 0
- Postgres                    → BASE_MB = 128, WORKER_OVERHEAD = 10 pro Connection
- Redis                       → BASE_MB = 64,  WORKER_OVERHEAD = 0
- Background-Worker (queues)  → BASE_MB = 200, WORKER_OVERHEAD = 50 pro Worker
- AI/LLM-Service (lokal)      → BASE_MB = 800+ (mindestens 2GB wenn Modell lokal)
```

**Limit-Formeln:**
```
MEM_LIMIT_MB    = min(AVAILABLE_MB * 0.8, BASE_MB * 3)   -- 80% des Verfügbaren, max 3x Base
MEM_RESERVATION = MEM_LIMIT_MB * 0.5                      -- 50% als garantiertes Minimum
MEM_SWAP_MB     = MEM_LIMIT_MB * 1.4                      -- 40% Swap-Overhead erlaubt
CPU_LIMIT       = round(2.0 * (MEM_LIMIT_MB / AVAILABLE_MB), 1)  -- proportional zu RAM-Anteil

NODE_OPTIONS_MB = floor(MEM_LIMIT_MB * 0.70)              -- V8 Heap = 70% des Container-Limits
UV_THREADPOOL_SIZE = min(8, cpu_count * 2)                -- libuv Threads
```

**Validation-Checks VOR dem Setzen:**
- [ ] `MEM_LIMIT_MB >= 128` (Minimum um zu starten)
- [ ] `AVAILABLE_MB - MEM_LIMIT_MB >= 200` (Safety-Buffer bleibt übrig)
- [ ] Summe aller mem_limits ≤ 3500MB (kein Overcommit über 85% physischer RAM)
- [ ] Wenn Validation fehlschlägt → BLOCKIERT, Cem informieren

### Phase G2: Limits permanent in Coolify DB setzen

**Das ist der kritische Fix gegen deploy-Regressionen.** Coolify regeneriert docker-compose.yaml bei jedem Deploy aus seiner eigenen DB. Nur wenn die Limits in der DB stehen, überleben sie Deploys.

Wenn die App-UUID bekannt ist:
```bash
<GAMEBOY_SSH> "
docker exec coolify-db psql -U coolify -d coolify -c \"
UPDATE applications SET
  limits_memory = '<MEM_LIMIT_MB>m',
  limits_memory_swap = '<MEM_SWAP_MB>m',
  limits_memory_swappiness = 10,
  limits_memory_reservation = '<MEM_RESERVATION>m',
  limits_cpus = '<CPU_LIMIT>',
  limits_cpu_shares = 1024
WHERE uuid = '<APP_UUID>';
SELECT uuid, name, limits_memory, limits_cpus FROM applications WHERE uuid='<APP_UUID>';
\"
"
```

UUID aus Coolify-URL holen: `<COOLIFY_URL>/project/.../application/<UUID>/...`

Wenn UUID unbekannt → via DB suchen:
```bash
docker exec coolify-db psql -U coolify -d coolify -c "SELECT uuid, name FROM applications ORDER BY created_at DESC LIMIT 10;"
```

### Phase G3: Environment-Variablen setzen

In `.env` des Projekts (via `echo >> .env` oder Coolify UI):

```bash
# Für Node.js/Next.js:
NODE_OPTIONS=--max-old-space-size=<NODE_OPTIONS_MB>
UV_THREADPOOL_SIZE=<UV_THREADPOOL_SIZE>

# Für Workflow-Apps (Activepieces etc.):
AP_MAX_CONCURRENT_JOBS=5     # verhindert Sandbox-Explosion
AP_TRIGGER_DEFAULT_POLL_INTERVAL=15  # reduziert DB-Baseline-Last

# Für alle Apps:
# (kein DEBUG logging in production!)
NODE_ENV=production
```

**WICHTIG: Kein Zeilenumbruch-Bug!** Jede Variable auf eigener Zeile prüfen:
```bash
grep -c '^[A-Z_].*=' .env  # sollte gleich sein wie die Anzahl Variablen
# Keine Zeile darf zwei '=' enthalten außer in Werten
awk -F= 'NF>2 && $1 ~ /^[A-Z_]/' .env && echo "BUG: doppelte = in Zeile!"
```

### Phase G4: Traefik Rate-Limiting aktivieren

Für JEDES neue öffentliche Service:

```bash
<GAMEBOY_SSH> "
cat > /data/coolify/proxy/dynamic/rate-limit-global.yaml << 'EOF'
http:
  middlewares:
    rate-limit-strict:
      rateLimit:
        average: 60
        burst: 120
        period: 1s
        sourceCriterion:
          ipStrategy:
            depth: 1
    rate-limit-api:
      rateLimit:
        average: 30
        burst: 60
        period: 1s
        sourceCriterion:
          ipStrategy:
            depth: 1
EOF
echo 'Rate-limiting config written'
"
```

Traefik picked das automatisch auf (watch=true) — kein Restart nötig.

Middleware dann zum App-Router hinzufügen (in der App-spezifischen Traefik-Konfig):
```yaml
middlewares:
  - rate-limit-strict
```

### Phase G5: File Descriptor Limits setzen

Docker daemon muss Limits kennen. Einmalig pro Gameboy-Setup, bleibt persistent:

```bash
<GAMEBOY_SSH> "
# Prüfen ob already set
grep -q 'nofile' /etc/docker/daemon.json && echo 'already set' || {
  # Backup und Update
  cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.\$(date +%Y%m%d)
  python3 -c \"
import json
with open('/etc/docker/daemon.json') as f: d = json.load(f)
d['default-ulimits'] = {'nofile': {'Name': 'nofile', 'Hard': 65536, 'Soft': 65536}}
with open('/etc/docker/daemon.json', 'w') as f: json.dump(d, f, indent=2)
print('daemon.json updated')
  \"
  # ACHTUNG: systemctl restart docker startet alle Container neu!
  # Nur wenn kein aktiver Traffic → mit Cem abstimmen
  echo 'NEEDS: systemctl restart docker (kurzer Downtime!)'
}
"
```

### Phase G6: Load-Test (die eigentliche Aufnahmeprüfung)

50 concurrent users, 60 Sekunden:

```bash
# Test 1: Basis-Erreichbarkeit
curl -o /dev/null -s -w "HTTP=%{http_code} %{time_total}s\n" https://<APP_URL>/

# Test 2: 50 concurrent HTTP-Requests (30s)
/usr/sbin/ab -n 3000 -c 50 -t 30 -r -k https://<APP_URL>/ 2>&1 | grep -E "Requests|Failed|Time per|50%|90%|99%"

# Test 3: Memory während Last monitoren
<GAMEBOY_SSH> "for i in \$(seq 1 6); do sleep 10; docker stats --no-stream --format '{{.Name}}: {{.MemUsage}} {{.MemPerc}} CPU={{.CPUPerc}}' | grep -v NAMES; echo '---'; done" &
MONITOR_PID=\$!
/usr/sbin/ab -n 5000 -c 50 -t 55 -r https://<APP_URL>/ 2>/dev/null
wait \$MONITOR_PID
```

### Phase G7: PASS/FAIL Kriterien

**PASS** (alle müssen erfüllt sein):

| Kriterium | Grenzwert |
|-----------|-----------|
| HTTP Status | 2xx oder 3xx (kein 502/503/504) |
| p99 Latenz | < 3000ms |
| Memory-Wachstum | stabil (< +20% zwischen t=0 und t=60s) |
| Memory bleibt unter Limit | < 90% des Container-Limits |
| Keine Failed-Requests | < 0.1% |
| Server nach Test erreichbar | HTTP 200/302 auf allen URLs |
| CPU nach Test | < 80% sustained |

**FAIL** (einer reicht für BLOCKIERT):
- Irgendein Container ist nach dem Test down/restarted
- Memory hat Limit erreicht (> 95%)
- `Failed requests > 1%`
- `p99 > 5000ms`
- Watchdog hat während des Tests eingegriffen (prüfen: `<WATCHDOG_LOG>`)

### Phase G8: Gate-Ergebnis

```
═══════════════════════════════════════════════════════
🎮 GAMEBOY-GATE ERGEBNIS
═══════════════════════════════════════════════════════
Projekt:     [Name]
App-UUID:    [Coolify UUID]
Test-Zeit:   [Datum/Uhrzeit]

LIMIT-BERECHNUNG:
  Server-RAM:              3840MB
  Coolify-Overhead:        [n]MB (gemessen)
  Andere Projekte:         [n]MB (Summe Limits)
  Verfügbar:               [n]MB
  Zugewiesen:              MEM=[n]m, CPU=[n], NODE_OPTIONS=[n]MB

CHECKS:
  ✅/❌ Coolify DB Limits persistent gesetzt
  ✅/❌ NODE_OPTIONS korrekt (kein Newline-Bug)
  ✅/❌ Rate-Limiting aktiv
  ✅/❌ File Descriptor Limit 65536
  ✅/❌ Redis maxmemory policy gesetzt (wenn Redis)
  ✅/❌ Load-Test 50c/30s bestanden

LOAD-TEST:
  Req/s:    [n]     (PASS wenn > 10)
  p50:      [n]ms
  p99:      [n]ms   (PASS wenn < 3000ms)
  Failed:   [n]%    (PASS wenn < 0.1%)
  Mem-Peak: [n]MB   (PASS wenn < 90% des Limits)

═══════════════════════════════════════════════════════
URTEIL: ✅ PASS — RELEASE ERLAUBT
       ❌ FAIL — RELEASE BLOCKIERT ([Grund])
═══════════════════════════════════════════════════════
```

---

## HÄUFIGE FAIL-GRÜNDE UND FIXES

### FAIL: NODE_OPTIONS nicht gesetzt
```bash
# Prüfen:
docker exec <container> printenv NODE_OPTIONS
# Fix:
grep -n 'NODE_OPTIONS' .env  # auf Newline-Bug prüfen
# Bug: HOST=0.0.0.0NODE_OPTIONS=... → Fix:
sed -i 's/HOST=0.0.0.0NODE_OPTIONS=/HOST=0.0.0.0\nNODE_OPTIONS=/' .env
```

### FAIL: Container OOM nach Test
Root-Cause fast immer eines von:
1. `NODE_OPTIONS` nicht gesetzt → V8 nimmt Container-RAM komplett
2. Sandbox-Prozesse (AP, Code-Execution) ohne Concurrency-Limit
3. Memory-Leak im App-Code (seltener)

```bash
# Prüfen ob Restart stattfand:
docker inspect <container> --format '{{.RestartCount}}'
# Prüfen ob OOM-Kill:
dmesg | grep -i 'oom\|killed' | tail -10
```

### FAIL: p99 > 3000ms
1. Heavy API-Endpoint ohne Caching → Redis-Cache implementieren
2. PG-Connection-Pool erschöpft → `MAX_CONCURRENT_REQUESTS` oder Pool-Size erhöhen
3. Forward-Auth-Overhead pro Request → JWT-Caching einbauen

### FAIL: Failed Requests > 0.1%
1. Traefik-Timeout kürzer als App-Response → Traefik-Timeouts erhöhen
2. FD-Limit erschöpft → Schritt G5 (ulimits)
3. PG max_connections erschöpft → `max_connections=200` in PG setzen

---

## DEPLOY-RESILIENZ: Das Deploy-Überlebens-Protokoll

Jeder Coolify-Deploy muss folgendes garantieren damit der Server nicht abstürzt:

### Vor jedem Deploy prüfen:
```bash
<GAMEBOY_SSH> "
# Freier RAM muss > 800MB sein
FREE=\$(free -m | awk '/^Mem:/{print \$7}')
echo \"Available: \${FREE}MB\"
[ \$FREE -lt 800 ] && echo 'WARNUNG: Zu wenig RAM für Deploy!' || echo 'RAM OK für Deploy'
# Disk muss > 5GB frei sein (Image-Pull braucht Platz)
DISK=\$(df / | awk 'NR==2{print \$4}')
echo \"Disk free: \$((DISK/1024))MB\"
[ \$DISK -lt 5242880 ] && echo 'WARNUNG: Zu wenig Disk!' || echo 'Disk OK'
"
```

### Was Coolify bei Deploy macht (und was wir sicherstellen müssen):
1. Coolify liest seine DB → generiert docker-compose.yaml **mit** den in DB gesetzten Limits (G2 → persistent ✅)
2. Container stoppt → kurzer Downtime
3. Neuer Container startet → Healthcheck wartet bis App bereit
4. Traefik bekommt neuen Backend-Endpunkt

### Healthcheck-Konfiguration (in Coolify UI oder direkt in DB):
```bash
docker exec coolify-db psql -U coolify -d coolify -c "
UPDATE applications SET
  health_check_enabled = true,
  health_check_path = '/api/v1/flags',  -- oder '/', '/health', '/ping'
  health_check_port = '80',
  health_check_interval = 15,
  health_check_timeout = 5,
  health_check_retries = 3,
  health_check_start_period = 90  -- 90s Startzeit für schwere Apps
WHERE uuid = '<APP_UUID>';
"
```

---

## MEMORY-BUDGET-TABELLE (Stand 26.06.2026)

```
GAMEBOY 4GB RAM — BUDGET-ÜBERSICHT
════════════════════════════════════════════════════════════
System/OS:              400MB (fix)
Coolify-Stack:          ~950MB (coolify+db+redis+sentinel+proxy)
────────────────────────────────────────────────────────────
VERFÜGBAR FÜR PROJEKTE: ~2650MB
════════════════════════════════════════════════════════════
app-workflow:          1536MB limit / 768MB reservation
app-billing:            512MB limit / 256MB reservation
app-landing:            256MB limit / 128MB reservation
────────────────────────────────────────────────────────────
NOCH FREI:             ~346MB limit-Spielraum
════════════════════════════════════════════════════════════

WARNUNG: Der Gameboy ist zu ~91% seiner Limit-Kapazität belegt.
Neues Projekt > 300MB braucht Rebalancing (existierendes 
Projekt verkleinern oder Coolify-Stack optimieren).
```

Wenn ein neues Projekt mehr als 200MB braucht → erst prüfen ob landing (256MB) auf 128MB reduziert werden kann (statische Site, braucht wenig RAM).

---

## CHECKLISTE FÜR JEDEN DEPLOY (Quick Reference)

```
VOR DEPLOY:
  [ ] Freier RAM > 800MB
  [ ] Disk > 5GB frei
  [ ] Coolify DB Limits gesetzt (nicht 0!)
  [ ] NODE_OPTIONS in .env korrekt (keine Zeilenumbruch-Bugs)
  [ ] Rate-Limiting für öffentliche Endpoints konfiguriert

NACH DEPLOY:
  [ ] Container läuft (docker ps → Up X seconds (healthy))
  [ ] URL erreichbar (HTTP 2xx/3xx)
  [ ] NODE_OPTIONS aktiv (docker exec <c> printenv NODE_OPTIONS)
  [ ] Memory stabil (docker stats → nicht an Limit)
  [ ] Kein OOM-Kill (dmesg | grep -i 'oom\|killed')

GAMEBOY-GATE TEST:
  [ ] 50 concurrent users / 30s Last-Test
  [ ] p99 < 3000ms
  [ ] Memory < 90% des Limits nach Test
  [ ] Alle URLs noch erreichbar nach Test
  → PASS = Release
  → FAIL = Fix first
```

---

## AUTOMATISCHER WATCHDOG (bereits installiert)

Der Memory-Watchdog läuft alle 2 Minuten und schützt den Server (reale Pfade siehe `gameboy.local.md`):
- Script: `<WATCHDOG_SCRIPT>`
- Timer: `systemctl status <WATCHDOG_TIMER>`
- Logs: `<WATCHDOG_LOG>`

Falls der Watchdog während des Gate-Tests eingreift → **FAIL** (kein PASS mit Watchdog-Intervention).

---

*Skill erstellt: 26.06.2026 — Basis: Server-Crash-Analyse + Stress-Test-Ergebnisse*
*Gameboy: Hetzner CAX11, 4GB RAM, 2 vCPU ARM, 40GB SSD*
