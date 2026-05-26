# Threat-Intel — autonomer täglicher Schwachstellen-Refresh

> Zweck: bei **jedem** Skill-Aufzug einmal pro Kalendertag die **frischeste** Bedrohungslage aus dem Netz ziehen (neue CVEs, neue Angriffstechniken) und **sofort prüfen ob unser System exponiert ist**. Das schließt die Lücke zwischen dem Wissensstand des Modells und *heute*. Die statische Härtung (`security-hardening.md`) deckt das Bekannte; dieser Refresh deckt das Neue.

> **Ehrliche Grenze:** Web-Suche ist nicht erschöpfend und ersetzt kein SCA-Tool/keinen Pentest. Dieser Refresh ist **Best-Effort-Aktualität**, kein Beweis von Unverwundbarkeit. Er erhöht die Wahrscheinlichkeit dass ein brandneuer Angriff erkannt wird, bevor er uns trifft — mehr verspricht er nicht.

---

## 1. Die Einmal-pro-Tag-Regel (Stamp-Mechanismus)

Der Refresh läuft **bei jedem Skill-Aufruf zuerst**, aber die Online-Suche nur **einmal pro Kalendertag pro Projekt**. Schon heute geprüft → gespeicherte Findings anwenden, NICHT erneut suchen.

**Stamp-Datei (pro Projekt, außerhalb des Repos — kein Git-Müll):**
```bash
mkdir -p ~/.claude/.cache/feature-delivery
STAMP=~/.claude/.cache/feature-delivery/"$(pwd | sed 's#^/##; s#/#-#g')".json
TODAY=$(date +%F)                       # YYYY-MM-DD (oder System-Datum aus dem Kontext)
LAST=$(grep -o '"lastCheck"[^,]*' "$STAMP" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
if [ "$LAST" = "$TODAY" ]; then echo "SKIP — heute ($TODAY) schon geprüft"; else echo "REFRESH nötig (zuletzt: ${LAST:-nie})"; fi
```

- **`SKIP`** → die `findings` aus dem Stamp laden und in P2.5/P5 anwenden. **Keine** Web-Suche. Weiter mit P0.
- **`REFRESH nötig`** → §2–§4 ausführen, danach Stamp mit `lastCheck = heute` neu schreiben.

> Die Stamp-Datei ist projektspezifisch (Pfad-basierter Name, analog zur CC-Memory-Konvention `-Users-…`). So bekommt **jedes** Projekt einmal täglich seine eigene frische Bewertung — eine Prüfung in Projekt A blockt nicht die in Projekt B.

---

## 2. Stack erkennen (wonach gesucht wird)

Vor der Suche den Stack bestimmen — nur dann sind die Treffer relevant:
```bash
# Dependencies + Versionen
cat package.json 2>/dev/null | grep -A99 '"dependencies"'
[ -f package-lock.json ] && echo "npm-lock vorhanden"
cat Dockerfile docker-compose*.y*ml 2>/dev/null | grep -iE 'image:|FROM '
# Andere Ökosysteme:
cat requirements.txt pyproject.toml go.mod pom.xml Gemfile composer.json 2>/dev/null
```
Notiere: Frameworks (z.B. NestJS, Angular), Auth (Keycloak/JWT), Payment (Stripe), DB/ORM (Prisma/MySQL), Laufzeit (Node-Version), Infra (Docker-Images). Diese Begriffe + Versionen sind die Suchanker.

---

## 3. Suche (WebSearch / WebFetch — bei Bedarf via ToolSearch laden)

Pro erkannter Schlüssel-Dependency **und** für die immer-relevanten Klassen je eine Suche, Zeitfilter „neueste / aktuelles Jahr":

**Pro Dependency (mit Version):**
- `"<dependency> <majorVersion> CVE"` / `"<dependency> security advisory 2026"`
- GitHub Security Advisories: `https://github.com/advisories?query=<dependency>`
- NVD/CVE: `https://nvd.nist.gov/vuln/search` bzw. `https://cve.org`

**Immer (stack-unabhängig):**
- `"latest critical web application vulnerabilities <Jahr>"` / `"new attack technique <Jahr>"`
- `"OWASP Top 10"` / `"OWASP API Security Top 10"` (aktuelle Edition)
- Auth/Session: `"JWT attack <Jahr>"`, `"OAuth/OIDC vulnerability <Jahr>"`, Keycloak-Advisories falls genutzt
- Payment/Paywall: `"Stripe webhook bypass"`, `"coupon/discount abuse fraud technique"`, `"paywall bypass VPN <Jahr>"`
- Supply-Chain: `"npm malicious package <Jahr>"`, `"<dependency> supply chain compromise"`
- Node/Runtime: `"Node.js security release <Jahr>"`

> Quellen-Disziplin: bevorzugt **primäre** Quellen (NVD, GHSA, Vendor-Advisory, OWASP). Blog-Posts nur als Hinweis, dann an der Primärquelle verifizieren (VERIFY-AGENT-REPORTS-Geist gilt auch für Web-Treffer).

---

## 4. Exposure-Check & Stamp schreiben

Für **jeden relevanten Fund**: prüfen ob UNSER Code exponiert ist (nicht nur notieren) — grep/Read auf das betroffene Muster, Version vergleichen.

| Feld | Bedeutung |
|---|---|
| `id` | CVE-/GHSA-ID oder Technik-Name |
| `class` | Angriffsklasse (Auth, Injection, Payment-Abuse, Supply-Chain, …) |
| `affects` | Dependency+Version / Pattern |
| `ourExposure` | `exposed` / `safe` (warum) / `needs-review` |
| `evidence` | `file:line` bzw. installierte Version |
| `action` | Fix-Schritt bzw. „nicht betroffen weil …" |

**Stamp schreiben** (mit dem Write-Tool, gültiges JSON):
```json
{
  "lastCheck": "2026-05-26",
  "stack": ["NestJS@…", "Angular@…", "Prisma@…", "Keycloak", "Stripe"],
  "sources": ["NVD", "GHSA", "OWASP", "..."],
  "findings": [
    { "id": "CVE-…", "class": "…", "affects": "…", "ourExposure": "exposed|safe|needs-review", "evidence": "file:line", "action": "…" }
  ]
}
```

**Eskalation:**
- `exposed` auf einem **NO-FAIL-Pfad** (Auth, Payment/Paywall, PII, Berechtigungen) → sofort als **BLOCKER** ins Coverage-Ledger (P1). Kein SHIP bis gemittelt.
- `exposed` sonst → Ledger-Zeile mit Fix im selben Change wenn er die aktuelle Änderung berührt, sonst dokumentiertes Backlog-Item + Hinweis an den Boss.
- `needs-review` → in P5 mit `/security-review` gezielt prüfen.

> Der Refresh ist Pre-flight, kein Selbstzweck: seine Findings fließen in **P2.5** (Security-Pass), **P3.1** (kann Tier auf NO-FAIL heben) und **P5** (`/security-review`-Fokus) ein.
