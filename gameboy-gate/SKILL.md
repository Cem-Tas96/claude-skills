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

> 🛡️ **Token-Discipline:** Dieser Gate ist bewusst **deterministisches Bash** (G0–G8) — er braucht **keinen** Multi-Agenten-Fächer. Auch in einer `ultracode`-Session die Phasen sequenziell/inline abarbeiten, **nicht** in Dutzende Subagenten/Workflows aufblähen (genau das war der historische Token-Burn). Globaler Default: `~/.claude/skills/token-discipline/token-router.md`.

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
Coolify-Stack (gemessene docker-stats USAGE, NICHT die mem-Limits): ~400MB
  (live ~364MB Ist: coolify 198 + db 39 + redis 9 + sentinel 78 + proxy 40; auf 400 aufgerundet)
Safety-Buffer:            200MB
──────────────────────────────
FREI für Projekte:       ~2840MB  (3840 - 400 OS - 400 Coolify - 200 Safety; siehe G0-Formel)
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
- `COOLIFY_OVERHEAD_MB` = Summe aller Coolify-/Infra-eigenen Container (coolify, coolify-db, coolify-redis, coolify-sentinel, coolify-proxy, cem-registry, sowie evtl. `*-backup`-Container) aktuell aus `docker stats` MemUsage
- `RUNNING_PROJECTS_MB` = Summe der mem_limit aller laufenden Projekt-Container
- `AVAILABLE_MB` = TOTAL_RAM_MB - 400 (OS) - COOLIFY_OVERHEAD_MB - RUNNING_PROJECTS_MB - 200 (safety)

### Phase G0b: APP_UUID deterministisch ableiten (read-only, fail-closed)

> **PFLICHT** bevor irgendein UPDATE (G2 / Healthcheck) läuft — eine falsche/leere UUID schreibt sonst still die Limits einer ANDEREN App um. `<PROJECT_NAME>` = exakter Coolify `applications.name` aus `gameboy.local.md` (NICHT der anonymisierte Skill-Name; `applications.name` ist nur pro Environment eindeutig).

```bash
APP_UUID=$(<GAMEBOY_SSH> "docker exec coolify-db psql -U coolify -d coolify -tA -c \"SELECT uuid FROM applications WHERE name = '<PROJECT_NAME>'\"" | tr -d '[:space:]')
MATCHES=$(<GAMEBOY_SSH> "docker exec coolify-db psql -U coolify -d coolify -tA -c \"SELECT count(*) FROM applications WHERE name = '<PROJECT_NAME>'\"" | tr -d '[:space:]')
if [ "$MATCHES" -eq 0 ]; then
  echo "FAIL: 0 Apps mit name='<PROJECT_NAME>' — Name falsch? (Real-Name in gameboy.local.md pruefen)"; exit 1
elif [ "$MATCHES" -gt 1 ]; then
  echo "FAIL: $MATCHES Apps teilen name='<PROJECT_NAME>' — UUID nicht eindeutig. Manuell aufloesen."; exit 1
fi
echo "APP_UUID=$APP_UUID (eindeutig)"

# Vorlauf (read-only): frueheres Gate-Ergebnis dieser App? -> Idempotenz / Diff gegen letzten Lauf
<GAMEBOY_SSH> "f=\$(ls -1t /data/coolify/gate-results/$APP_UUID-*.json 2>/dev/null | head -1); [ -n \"\$f\" ] && { echo \"PRIOR GATE: \$f\"; cat \"\$f\"; } || echo 'PRIOR GATE: keine'"
```

> Ab hier `$APP_UUID` (shell-expandiert) in allen UPDATEs verwenden statt den Platzhalter manuell einzusetzen.

### Phase G0.5: CPU-Baseline + Spike-Capture (read-only, VOR jeder Last)

> Reine Diagnose, **kein** FAIL-Gate (Control-Plane-Last ist eine Host-Eigenheit, keine Projekt-Eigenheit). Erfasst (a) die Idle-Baseline und (b) die kurzen 100–150%-Transienten, die `docker stats --no-stream` (1 Frame) und `sar` (10-min-Buckets) verpassen.

```bash
<GAMEBOY_SSH> "
# (a) Host-Idle ueber 30s — Fallback wenn mpstat (sysstat) fehlt.
if command -v mpstat >/dev/null 2>&1; then
  IDLE=\$(mpstat 1 30 | awk '/Average/ {print \$NF}')
  echo \"BASELINE_BUSY_PCT=\$(awk -v i=\"\$IDLE\" 'BEGIN{printf \"%.1f\", 100-i}')\"
else
  read _ u n s idl rest < /proc/stat; T1=\$((u+n+s+idl)); I1=\$idl; sleep 5
  read _ u n s idl rest < /proc/stat; T2=\$((u+n+s+idl)); I2=\$idl
  echo \"BASELINE_BUSY_PCT~\$(awk -v dt=\$((T2-T1)) -v di=\$((I2-I1)) 'BEGIN{printf \"%.1f\", 100*(dt-di)/dt}')\"
fi
# (b) Per-Container Mittel-CPU ueber 10 Idle-Samples (~2s). Read-only.
echo '=== per-container idle CPU (10 samples) ==='
for i in \$(seq 1 10); do docker stats --no-stream --format '{{.Name}} {{.CPUPerc}}'; sleep 2; done \
  | awk '{v=\$2; sub(/%/,\"\",v); if (v ~ /^[0-9.]+\$/){c[\$1]+=v; n[\$1]++}} END{for(k in c) printf \"%s avg=%.1f%%\n\", k, c[k]/n[k]}' \
  | sort -t= -k2 -rn | head -6
# (c) High-res Host-CPU 90s ueber >=1 Minutengrenze (faengt den :00 Scheduler-Burst). %idle = letztes Feld.
mpstat 1 90 2>/dev/null | awk '/ all / && \$NF+0==\$NF { busy=100-\$NF; if (busy>50) print \$1, \$2, \"HOST_BUSY=\"busy\"%\" }'
# (d) Pro-Prozess-Attribution: %CPU=\$(NF-2), CPU=\$(NF-1), Command=\$NF (robust gegen AM/PM-Format).
pidstat -u 1 90 2>/dev/null | awk '\$0 ~ /php|node|sentinel|artisan|horizon/ { cpu=\$(NF-2)+0; if (cpu>40) print \$1, \$2, \$NF, \"CPU=\"cpu\"%\" }'
# (e) Scheduler korrelieren (eindeutige Attribution der Coolify-Bursts):
docker exec coolify php artisan schedule:list 2>/dev/null | head -30
"
```

**Erwartete Attribution (kein FAIL — Control-Plane, nicht die getestete App):**
- `coolify` → der Laravel-Scheduler kalt-bootet `php artisan`-Jobs auf Minuten-/5min-/Stundengrenzen (`ServerManagerJob` + `ScheduledJobManager` jede Minute; `horizon:snapshot` alle 5 min; stündlich CDN/Changelog/Update). Jeder PHP-Boot = kurzer 50–100%-Burst auf 2 ARM-Cores. Mehrere gleichzeitig auf der `:00`-Grenze → die großen 100–150%-Spikes.
- `coolify-sentinel` → steady ~24% durch Metrics-Collection alle 10s.
- App-Container (Activepieces) → ~26% transient alle 30s durch den `node`-spawnenden Healthcheck.

### Phase G0.7: Spike-Reduktion (Control-Plane-Tuning) — non-destruktiv, KEIN App-Restart

> Diese drei Quellen verursachen die kurzen 100–150%-CPU-Spikes (kein OOM, kein Crash — reine Effizienz). Optional, aber auf 2 vCPU empfohlen.

```bash
# Lever 1 — Sentinel-Metrics 10s -> 60s (steady ~24% CPU). Hetzner liefert CPU-Graphs schon,
# Coolify-Metrics sind weitgehend redundant. Wirkt beim naechsten Sentinel-Zyklus.
<GAMEBOY_SSH> 'docker exec coolify-db psql -U coolify -d coolify -c "UPDATE server_settings SET sentinel_metrics_refresh_rate_seconds = 60;"'
# Deterministisch anwenden — beruehrt KEINEN Prod-App-Container, nur den Metrics-Collector:
<GAMEBOY_SSH> 'docker restart coolify-sentinel'
# OPTIONAL (haerter, bewusst): Metrics ganz aus -> killt den ~24% steady cost UND die Coolify-UI-Graphs:
# <GAMEBOY_SSH> 'docker exec coolify-db psql -U coolify -d coolify -c "UPDATE server_settings SET is_metrics_enabled = false;"'

# Lever 2 — AP-Healthcheck startet alle 30s ein volles node-Runtime = Mini-Spike. Intervall >= 30s HALTEN
# (siehe Healthcheck-Block: health_check_interval = 30). Wenn moeglich auf curl/wget statt `node -e fetch(...)` umstellen.

# Lever 3 — AP-Tuning auf 2 vCPU (CPU- UND DB-Last). ACHTUNG: Werte kommen aus dem compose-File, NICHT aus
# Coolifys environment_variables. .env-Edit wird erst nach REDEPLOY live -> via G3.5 verifizieren.
AP_TRIGGER_DEFAULT_POLL_INTERVAL=30
AP_MAX_CONCURRENT_JOBS=2
```

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
CPU_LIMIT       = clamp(round(2.0 * (MEM_LIMIT_MB / AVAILABLE_MB), 1), 0.25, 1.0)
  -- HINWEIS: grobe Startheuristik (CPU-Bedarf ist NICHT proportional zu RAM). clamp() verhindert nur
  -- CPU_LIMIT=0 (winzige App) und >1.0 (eine App monopolisiert beide vCPUs). limits_cpus ist ein Docker
  -- --cpus QUOTA-CAP (CFS bandwidth), KEINE Reservierung: eine idle App gibt ihr Kontingent frei und kann
  -- die Control-Plane NICHT aushungern. Zu enge Caps drosseln die APP selbst bei Bursts — Gameboy ist
  -- ~86% idle, im Zweifel oberen Wert (1.0). CPU-lastige Apps (Worker/Build) manuell nach Lastprofil.

-- V8-Heap als Anteil des Container-Limits. Branch nach Prozess-Modell:
WENN App Worker-/Sandbox-Subprozesse spawnt (Activepieces, Code-Exec, Queue-Worker):
    NODE_OPTIONS_MB = floor(MEM_LIMIT_MB * 0.50)   -- konservativ 50%
SONST (reine Single-Process-Node/Next.js-App):
    NODE_OPTIONS_MB = floor(MEM_LIMIT_MB * 0.70)   -- 70%
-- Grund: max-old-space-size begrenzt NUR den V8-Heap des Hauptprozesses. Zusaetzlich noetig:
--   (a) native Off-Heap/GC-Worklist DESSELBEN Prozesses (zu wenig Headroom -> fataler OOM
--       'Worklist::Segment::Create', real bei 1024/1536 aufgetreten, commit 4e782ea),
--   (b) RAM der Sandbox-/Worker-Child-Prozesse (~200MB je Job; mit AP_MAX_CONCURRENT_JOBS kappen).
-- app-workflow: 1536MB-Limit, hat Sandbox-Worker -> floor(1536*0.50)=768 (== commit 4e782ea). 70% (=1075) ist hier zu hoch.

UV_THREADPOOL_SIZE = min(8, cpu_count * 2)                -- libuv Threads
```

**Validation-Checks VOR dem Setzen:**
- [ ] `MEM_LIMIT_MB >= 128` (Minimum um zu starten)
- [ ] `AVAILABLE_MB - MEM_LIMIT_MB >= 200` (Safety-Buffer bleibt übrig)
- [ ] Summe aller mem_limits ≤ 3500MB (kein Overcommit über 85% physischer RAM)
- [ ] (advisory) Bei mehreren gleichzeitig CPU-lastigen Apps: `cpu_shares`/Weight (Default 1024) im Blick behalten — NICHT über `--cpus`. Kein harter Block.
- [ ] Wenn Validation fehlschlägt → BLOCKIERT, Cem informieren

### Phase G2: Limits permanent in Coolify DB setzen

**Das ist der kritische Fix gegen deploy-Regressionen.** Coolify regeneriert docker-compose.yaml bei jedem Deploy aus seiner eigenen DB. Nur wenn die Limits in der DB stehen, überleben sie Deploys.

`$APP_UUID` stammt aus G0b (fail-closed abgeleitet). **Erst Row-Count prüfen** (muss `1` sein), dann erst schreiben:
```bash
# Pre-flight: existiert genau diese eine App? (sonst still 0 Rows oder falsche App)
<GAMEBOY_SSH> "docker exec coolify-db psql -U coolify -d coolify -v ON_ERROR_STOP=1 -tA -c \"SELECT count(*) AS must_be_1 FROM applications WHERE uuid='$APP_UUID';\""

# Nur wenn das '1' ist:
<GAMEBOY_SSH> "
docker exec coolify-db psql -U coolify -d coolify -c \"
UPDATE applications SET
  limits_memory = '<MEM_LIMIT_MB>m',
  limits_memory_swap = '<MEM_SWAP_MB>m',
  limits_memory_swappiness = 10,
  limits_memory_reservation = '<MEM_RESERVATION>m',
  limits_cpus = '<CPU_LIMIT>',
  limits_cpu_shares = 1024
WHERE uuid = '$APP_UUID';
SELECT uuid, name, limits_memory, limits_cpus FROM applications WHERE uuid='$APP_UUID';
\"
"
```

### Phase G3: Environment-Variablen setzen

In `.env` des Projekts (via `echo >> .env` oder Coolify UI):

```bash
# Für Node.js/Next.js:
NODE_OPTIONS=--max-old-space-size=<NODE_OPTIONS_MB>
UV_THREADPOOL_SIZE=<UV_THREADPOOL_SIZE>

# Für Workflow-Apps (Activepieces etc.) — getuned für 2-vCPU/4GB ARM (commit 4e782ea, 2026-06-27).
# Single Source of Truth = das committe docker-compose.coolify.yml. Werte aus G1/Repo uebernehmen,
# NICHT hier hardcoden — sonst prueft G3.5 gegen falsche Zielwerte:
AP_MAX_CONCURRENT_JOBS=2      # niedrig halten: jeder unsandboxed Flow-Step ~200MB -> 5 concurrent = OOM (war 5)
AP_TRIGGER_DEFAULT_POLL_INTERVAL=30  # reduziert DB- UND CPU-Baseline-Last; auf 2-vCPU eher 30 als 15 (war 15)
NODE_OPTIONS=--max-old-space-size=768  # ueberschreibt Dockerfile-Default 1024; Headroom fuer V8 GC + Sandbox-Worker (war 1024 -> OOM)

# Für alle Apps:
# (kein DEBUG logging in production!)
NODE_ENV=production
```

**WICHTIG: Kein Zeilenumbruch-Bug!** Jede Variable muss auf eigener Zeile stehen:
```bash
# 1) Anzahl deklarierter Variablen (Sanity vs. erwartete Anzahl):
grep -cE '^[A-Z_][A-Z0-9_]*=' .env
# 2) Echte Newline-Loss-Erkennung: ein VALUE direkt gefolgt von einem zweiten UPPERCASE_SNAKE KEY=
#    (der reale Bug, z.B. HOST=0.0.0.0NODE_OPTIONS=...). if-guard -> safe unter set -e.
if grep -nE '[^=]=[^=]*[A-Za-z0-9/.:_-]+[A-Z][A-Z0-9_]{2,}=' .env | grep -vE '^[0-9]+:[[:space:]]*#'; then
  echo 'WARN: moegliche zwei Variablen auf einer Zeile (fehlender Newline) -- Zeile manuell pruefen!'
  echo '      (base64/JWT-Werte mit = Padding koennen ebenfalls anschlagen -> nur echte Concatenation fixen.)'
else
  echo 'newline-check OK'
fi
```

### Phase G3.5: Config-Drift-Check (laufender Container == Soll) — PFLICHT, read-only

> Coolify-Env greift erst beim **Redeploy**. Ein Container der VOR dem Env-Commit gestartet wurde läuft mit STALE-Werten (genau das ist 27.06.2026 passiert: commit 4e782ea setzte 768/2/30, der laufende Container hatte noch 1024/5/15). Diese Phase liest die LIVE-Env des laufenden Containers und vergleicht hart gegen die Soll-Werte aus G1/Repo. Bei Abweichung: **GATE FAIL**. Startet NICHTS neu — liest nur.

```bash
# SOLL = aus G1/Repo (NICHT aus diesem Template hardcoden). printenv liefert die GANZE Zeichenkette,
# also NODE_OPTIONS=--max-old-space-size=768 (nicht nur 768).
<GAMEBOY_SSH> "
C='<CONTAINER_NAME>'   # via: docker ps --format '{{.Names}}' | grep <project>
fail=0
chk(){ a=\$(docker exec \"\$C\" printenv \"\$1\" 2>/dev/null); if [ \"\$a\" = \"\$2\" ]; then echo \"OK    \$1=\$a\"; else echo \"DRIFT \$1: running='\$a' soll='\$2'\"; fail=1; fi; }
chk NODE_OPTIONS '--max-old-space-size=<NODE_OPTIONS_MB>'
chk AP_MAX_CONCURRENT_JOBS '<AP_MAX_CONCURRENT_JOBS>'   # nur fuer Workflow-Apps
chk AP_TRIGGER_DEFAULT_POLL_INTERVAL '<AP_POLL>'        # nur fuer Workflow-Apps
chk NODE_ENV 'production'
if [ \$fail -eq 1 ]; then echo 'GATE FAIL (G3.5): running-env != soll -> Redeploy noetig, dann Gate erneut. KEIN Last-Test gegen alte Config.'; exit 1; fi
echo 'G3.5 PASS: running-env == soll'
"
```

- Leere/ungesetzte Variable zählt als DRIFT (der `!=`-Vergleich deckt das ab).
- Bei Drift → Gate = **FAIL** (BLOCKIERT). **KEIN** automatischer Force-Redeploy aus dem Gate: das committe Tuning ist nicht live; ein Coolify-Redeploy (mit Cem abstimmen, kurzer Downtime + Lastspitze) nötig, danach Gate erneut.
- Für Nicht-AP-Projekte nur die `NODE_OPTIONS`/`NODE_ENV`-Zeilen prüfen.

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

Die Datei selbst braucht keinen Restart (Traefik `watch=true`) — aber sie ist **INERT** bis ein Router sie referenziert.

**Middleware an den Router hängen (sonst schützt sie NICHTS):**
```bash
# Coolify-Router heissen https-0-<APP_UUID> / http-0-<APP_UUID> (NICHT ein Service-Name).
#
# A) docker-compose-Deployment (Activepieces / domoflow-app): custom traefik.http.routers.*-Labels werden
#    von Coolify UEBERSCHRIEBEN -> Coolify-Shorthand am Service nutzen (Coolify haengt es an die Router-Chain):
#        labels:
#          - coolify.traefik.middlewares=rate-limit-strict
#    In Coolify UI (Service -> Labels) ODER in den compose-Service-Labels setzen, dann REDEPLOY (kurzer Restart).
#
# B) Standard-App (nicht compose): in Coolify UI 'Readonly labels' deaktivieren, die bestehende Zeile
#    traefik.http.routers.https-0-<APP_UUID>.middlewares=...  finden und ,rate-limit-strict@file ANHAENGEN
#    (KEINE zweite middlewares-Zeile — sie merged nicht). Tippfehler macht die App unerreichbar. Dann redeploy.

# --- Verifikation: Burst feuern; ein verdrahteter Limiter MUSS 429 liefern ---
for i in $(seq 1 200); do curl -s -o /dev/null -w '%{http_code}\n' https://<APP_URL>/; done | sort | uniq -c
# Erwartung: ein Block 429 neben 200/30x. NULL 429 ueber 200 schnelle Requests => Middleware NICHT verdrahtet => FAIL.
```

### Phase G5: File Descriptor Limits setzen

Docker daemon muss Limits kennen. Einmalig pro Gameboy-Setup, bleibt persistent:

```bash
<GAMEBOY_SSH> "
F=/etc/docker/daemon.json
# Fehlende/leere Datei bootstrappen, damit json.load nie crasht (frischer Docker-Host)
[ -s \"\$F\" ] || echo '{}' > \"\$F\"
# Key-praezise Pruefung (NICHT Substring): nur true wenn default-ulimits.nofile wirklich existiert
if python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get(\"default-ulimits\",{}).get(\"nofile\") else 1)' \"\$F\"; then
  echo 'already set'
else
  cp \"\$F\" \"\$F.bak.\$(date +%Y%m%d%H%M%S)\"
  python3 -c 'import json,sys; f=sys.argv[1]; d=json.load(open(f)); d[\"default-ulimits\"]={\"nofile\":{\"Name\":\"nofile\",\"Hard\":65536,\"Soft\":65536}}; json.dump(d,open(f,\"w\"),indent=2)' \"\$F\"
  # Validieren BEVOR irgendein Restart empfohlen wird; bei kaputt -> Backup zurueck:
  python3 -c \"import json; json.load(open('/etc/docker/daemon.json'))\" || {
    echo 'daemon.json INVALID -> neuestes Backup zurueck, NICHT neustarten'
    BAK=\$(ls -1t /etc/docker/daemon.json.bak.* 2>/dev/null | head -1)
    [ -n \"\$BAK\" ] && cp \"\$BAK\" /etc/docker/daemon.json && echo \"restored from \$BAK\"
    exit 1
  }
  echo 'daemon.json updated + valide. Rollback bei Problem nach Restart:'
  echo \"  cp \$(ls -1t /etc/docker/daemon.json.bak.* | head -1) /etc/docker/daemon.json && systemctl restart docker\"
  # ACHTUNG: Docker NICHT automatisch neustarten — killt ALLE Container inkl. Public-App!
  echo 'NEEDS: systemctl restart docker (kurzer Downtime, mit Cem abstimmen)'
fi
"
```

### Phase G5.5: Tooling-Preflight (hard-fail BEVOR der Gate auf Tools baut)

```bash
# Runner-seitig: ab MUSS vorhanden sein (Load-Test ist der Kern des Gates)
if ! command -v ab >/dev/null 2>&1; then
  echo 'MISSING: ab -> apt-get install -y apache2-utils (Fallback: hey ODER wrk)'
  command -v hey >/dev/null 2>&1 || command -v wrk >/dev/null 2>&1 || { echo 'Kein ab/hey/wrk -> Gate ABBRUCH'; exit 1; }
fi
# Gameboy-seitig: python3 (G5 daemon.json-Update braucht es)
<GAMEBOY_SSH> "command -v python3 >/dev/null 2>&1 || echo 'MISSING-ON-GAMEBOY: python3 (G5 daemon.json-Update wird scheitern)'"
```

### Phase G6: Load-Test (die eigentliche Aufnahmeprüfung)

50 concurrent users, 60 Sekunden. Der Watchdog wird für das Testfenster pausiert (sonst killt seine Remediation evtl. mitten im Test den App-Container):

```bash
# --- Watchdog fuer das Testfenster pausieren (restore ZUERST armen, dann stoppen) ---
restore_watchdog() {
  <GAMEBOY_SSH> "systemctl start <WATCHDOG_TIMER> && systemctl is-active <WATCHDOG_TIMER>" \
    || echo 'WARNUNG: Watchdog-Timer NICHT wieder aktiv — manuell pruefen!'
}
trap restore_watchdog EXIT
<GAMEBOY_SSH> "systemctl stop <WATCHDOG_TIMER> && echo 'watchdog paused for gate window'"

# ab aufloesen (apache2-utils liegt auf Ubuntu unter /usr/bin/ab, NICHT /usr/sbin)
AB=$(command -v ab 2>/dev/null || true)
[ -x "$AB" ] || { echo 'ab fehlt -> apt-get install -y apache2-utils'; exit 1; }

# Test 1: Basis-Erreichbarkeit
curl -o /dev/null -s -w "HTTP=%{http_code} %{time_total}s\n" https://<APP_URL>/

# Test 2: HTTP keepalive. HINWEIS: bei -t ist -n nur ein Cap, -t 30 ist die echte Dauer.
"$AB" -k -c 50 -t 30 -n 50000 -r https://<APP_URL>/ 2>&1 \
  | grep -E 'Requests per second|Failed requests|Time per request|50%|90%|99%'

# Test 3: NON-keepalive (frische TCP-Conn je Request -> stresst FD/PG-Pool, den G7 prueft).
# Host-Memory+CPU-Monitor detached am Lastfenster starten, Log NACH ab lesen.
<GAMEBOY_SSH> "nohup sh -c 'for i in 1 2 3 4 5 6; do docker stats --no-stream --format \"{{.Name}}: {{.MemUsage}} {{.MemPerc}} CPU={{.CPUPerc}}\" | grep -v NAME; echo ---; sleep 10; done' >/tmp/gate-mon.log 2>&1 &"
"$AB" -c 50 -t 55 -n 50000 -r https://<APP_URL>/ 2>&1 \
  | grep -E 'Requests per second|Failed requests|99%'
<GAMEBOY_SSH> "cat /tmp/gate-mon.log; rm -f /tmp/gate-mon.log"

# Host-CPU + Load WAEHREND Last (read-only; kein Container wird angefasst)
<GAMEBOY_SSH> "echo 'idle/iowait/steal alle 10s:'; ( mpstat 10 6 2>/dev/null || sar -u 10 6 ) | awk '/all/{print \$0}'; echo 'load:'; uptime"

# --- Watchdog wieder aktivieren ---
trap - EXIT
restore_watchdog
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
| Load avg (5m) nach Test | < 1.6 (2 vCPU = < 0.8/Core) |
| Idle baseline (vor Last) | < 35%/Core busy — informativ, KEIN harter FAIL |
| Running-Env == committed config | NODE_OPTIONS / AP_MAX_CONCURRENT_JOBS / POLL des laufenden Containers identisch zu G1/Repo (G3.5 PASS) |
| Sentinel-Metrics CPU-Last | `sentinel_metrics_refresh_rate_seconds` >= 60 ODER `is_metrics_enabled = false` (SOLL, kein harter FAIL) |
| Healthcheck-Intervall | >= 30s wenn Probe einen Runtime kalt-startet (node/python -e) (SOLL) |
| Watchdog-Remediation auditiert | Remediation-Audit gelaufen; destruktiver `docker restart` des Kunden-Containers dokumentiert + Headroom-Margin >> 350MB-Trigger (siehe WATCHDOG-Abschnitt) |

> **Hinweis:** Kurze CPU-Transienten (1–2s, bis ~150% von 2 Cores) sind **NORMAL** — Coolify-Scheduler (`php artisan` jede 1/2/5 min), Sentinel-Metrics (10s), AP-Healthcheck (30s). Nur **SUSTAINED** CPU (>30s) ist ein FAIL.

**FAIL** (einer reicht für BLOCKIERT):
- Irgendein Container ist nach dem Test down/restarted
- Memory hat Limit erreicht (> 95%)
- `Failed requests > 1%`
- `p99 > 5000ms`
- Watchdog hat während des Tests eingegriffen (prüfen: `<WATCHDOG_LOG>`)
- **Running-Container-Env weicht vom committeten Soll ab (G3.5 DRIFT)** → committe Tuning nicht live, Redeploy nötig, Last-Test ungültig → BLOCKIERT. KEIN automatischer Force-Redeploy aus dem Gate.
- Host-CPU > 90%/Core **SUSTAINED** > 30s während Load-Test (idle < 10% über 3 aufeinanderfolgende mpstat-Samples) — NICHT transient
- Idle-Baseline (ohne Last) > 50%/Core über > 2 min → Control-Plane-Runaway (NICHT die normalen ~1/min Scheduler-Bursts)
- Rate-limit-yaml existiert, aber 200-Request-Burst liefert 0× 429 → Middleware nicht am Router → FAIL
- Load-Test lieferte KEINE verwertbaren Kennzahlen (ab/hey/wrk fehlte, leerer Output, 0 Requests) → FAIL, kein PASS-by-default

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
  ✅/❌ Running-Container-Env == Soll (NODE_OPTIONS / AP_MAX_CONCURRENT_JOBS / POLL) — Drift = FAIL
  ✅/❌ NODE_OPTIONS korrekt (kein Newline-Bug)
  ✅/❌ Rate-Limiting WIRED & ENFORCING (>=1× HTTP 429 im 200-Request-Burst; NICHT nur yaml vorhanden)
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

**CONTROL-PLANE CPU-BASELINE (idle, vor Last) — nicht-blockierende Notiz im Report:**
```
Host busy: [BASELINE_BUSY_PCT]%   (typisch ~14%)
Top-CPU:   [container avg%]
HINWEIS (kein FAIL): kurze Transienten (1–2s bis ~150% von 2 Cores) sind NORMAL (Scheduler/Sentinel/Healthcheck).
Falls Baseline > 40%: sentinel_metrics_refresh_rate_seconds (10 -> 30/60) erhoehen ODER
is_metrics_enabled=false (Hetzner liefert eigene Graphen). NICHT im Gate erzwingen.
```

**Durables Ergebnis schreiben (auditierbar, diffbar gegen den nächsten Lauf):**
```bash
<GAMEBOY_SSH> '
  set -e
  mkdir -p /data/coolify/gate-results
  TS=$(date -u +%Y%m%dT%H%M%SZ)
  F=/data/coolify/gate-results/<APP_UUID>-${TS}.json
  cat > "$F" <<JSON
{"app":"<NAME>","uuid":"<APP_UUID>","ts":"${TS}",
 "mem_limit_m":<MEM_LIMIT_MB>,"cpu_limit":"<CPU_LIMIT>","node_opt_mb":<NODE_OPTIONS_MB>,
 "reqs_per_sec":<RPS>,"p50_ms":<P50>,"p99_ms":<P99>,"failed_pct":<FAILED_PCT>,
 "mem_peak_m":<MEM_PEAK_MB>,"verdict":"<PASS|FAIL>","reason":"<REASON>"}
JSON
  echo "WROTE $F"
'
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

### FAIL: G3.5 Config-Drift (running-env != soll)
Das committe Tuning (NODE_OPTIONS / AP_MAX_CONCURRENT_JOBS / Poll) ist NICHT im laufenden Container.
Ursache: Coolify zieht diese aus dem compose-File und sie greifen erst beim **Redeploy**; der Container
ist älter als der Env-Commit.
```bash
# Bestätigen wie alt der Container vs. der Commit ist:
docker inspect -f '{{.State.StartedAt}}' <container>
git log -1 --format=%cI -- docker-compose.coolify.yml
# Fix: in Coolify ein Redeploy auslösen (kurzer Downtime + Lastspitze, mit Cem abstimmen), dann G3.5 erneut.
```

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

> **NACH dem Deploy IMMER G3.5 erneut laufen** — erst der Redeploy macht committe Env-Änderungen live.

### Healthcheck-Konfiguration (in Coolify UI oder direkt in DB):
```bash
docker exec coolify-db psql -U coolify -d coolify -c "
UPDATE applications SET
  health_check_enabled = true,
  health_check_path = '/api/v1/flags',  -- oder '/', '/health', '/ping'
  health_check_port = '80',
  health_check_interval = 30,  -- AP-Healthcheck kalt-bootet ein volles node-Runtime je Fire; kuerzer = mehr CPU-Spikes auf 2-vCPU. Matcht das laufende 30s.
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
Coolify-Stack:          ~400MB gemessene USAGE (coolify 198+db 39+redis 9+sentinel 78+proxy 40; +cem-registry ~7)
Safety-Buffer:          200MB
────────────────────────────────────────────────────────────
VERFÜGBAR FÜR PROJEKTE: ~2840MB   (= G0: 3840 - 400 - 400 - 200)
════════════════════════════════════════════════════════════
app-workflow:          1536MB limit / 768MB reservation
app-billing:            512MB limit / 256MB reservation
app-landing:            256MB limit / 128MB reservation
────────────────────────────────────────────────────────────
Belegt (Summe Limits): 2304MB
NOCH FREI:             ~536MB limit-Spielraum  (2840 - 2304)
════════════════════════════════════════════════════════════

HINWEIS: Der Gameboy ist zu ~81% seiner Limit-Kapazität belegt (2304/2840). Limits sind ein
Overcommit-Ceiling, kein Ist-Verbrauch. Vor Aufnahme eines neuen Projekts IMMER die live
G0-Messung (docker stats USAGE) heranziehen, nicht diese statische Tabelle.
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
  [ ] Running-Env == committed config (G3.5 — Drift = nicht live!)
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

Falls der Watchdog während des Gate-Tests eingreift → **FAIL** (kein PASS mit Watchdog-Intervention). Deshalb pausiert G6 den Timer für das Testfenster (mit garantiertem Restore).

### ⚠️ Remediation-Audit: Die "Heilung" des Watchdogs ist destruktiv

Der Watchdog ist KEIN passiver Sensor. Seine aktuelle Remediation (Stand 27.06.2026) ist:
`docker restart` des **größten Speicherverbrauchers** (sortiert nach `MemPerc`). Auf dem
Gameboy ist der größte Verbraucher der **Kunden-facing App-Container** (Activepieces,
1536MB Limit). Das heißt: greift der Watchdog je ein, killt er genau die öffentliche App
→ sofortiger Downtime + Restart-Lastspitze — also exakt das Ereignis, das dieser Gate
verhindern soll. Trigger: `MemAvailable < 350MB` (short-circuit darüber).

**Bei jedem Gate-Lauf prüfen (read-only, ändert nichts):**

```bash
# 1) Was tut die Remediation? (darf nicht blind den App-Container neustarten)
<GAMEBOY_SSH> "grep -nE 'docker (restart|kill|stop)' <WATCHDOG_SCRIPT>"

# 2) Headroom-Margin: aktueller freier RAM muss WEIT über dem Trigger (350MB) liegen
<GAMEBOY_SSH> "AVAIL=\$(awk '/MemAvailable/{printf \"%d\",\$2/1024}' /proc/meminfo); echo \"MemAvailable=\${AVAIL}MB  Trigger=350MB  Margin=\$((AVAIL-350))MB\""

# 3) Firing-Historie (read-only): hat der Watchdog real schon neugestartet? Quelle = WATCHDOG_LOG + .service
#    (NICHT die .timer-Unit — die loggt nur Scheduling, nicht die Restart-Aktion).
<GAMEBOY_SSH> "grep -iE 'restart' <WATCHDOG_LOG> 2>/dev/null | tail -n 20; echo '---'; journalctl -u <WATCHDOG_SERVICE> --since -24h --no-pager 2>/dev/null | grep -iE 'restart' || true"
# Bei >0 Treffern in 24h: als CPU-Spike-/Downtime-Quelle im Report dokumentieren (kein PASS-Blocker ausserhalb des Tests).
```

- Findet (1) ein `docker restart`/`kill`/`stop`, das den **öffentlichen App-Container**
  trifft (kein expliziter Throwaway-Allowlist) → als Risiko dokumentieren, **kein Hard-Fail
  des Gate** (der Watchdog liegt außerhalb des getesteten Projekts), aber Cem informieren.
- Empfehlung für eine sichere Remediation (nur dokumentieren, Script NICHT im Gate-Lauf
  umschreiben): erst nicht-destruktive Leiter (Page-Cache droppen / `docker exec` graceful),
  nur eine explizite Throwaway-Liste neustarten, **niemals** den Public-App-Container, und
  Alert-before-act mit kurzer Verzögerung.
- Margin-Check (2): aktuell ist der freie RAM (~2.1Gi) um Größenordnungen über dem
  350MB-Trigger → Watchdog feuert real nie. Sinkt die Margin nahe 0 → Risiko wird akut.

---

*Skill erstellt: 26.06.2026 — Basis: Server-Crash-Analyse + Stress-Test-Ergebnisse*
*Update 27.06.2026 (Opus/ultracode-Audit): CPU-Spike-Diagnose (G0.5/G0.7), Config-Drift-Gate (G3.5), Deploy-Drift-/Rate-Limit-Wiring-/UUID-/Artifact-Härtung, korrekte Bash-Snippets; Budget auf gemessene USAGE korrigiert.*
*Gameboy: Hetzner CAX11, 4GB RAM, 2 vCPU ARM, 40GB SSD*
