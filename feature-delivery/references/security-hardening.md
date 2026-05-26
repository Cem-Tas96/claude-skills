# Security-Hardening — Enterprise-Härtung gegen die komplette Angriffs-Taxonomie

> Für Systeme mit echten, zahlenden Kunden. Dieses Dokument ist die **statische, vollständige** Abdeckung aller bekannten Angriffsklassen; `threat-intel.md` liefert das **tagesaktuell Neue** dazu. Zusammen = maximal erreichbarer Schutz.

> **Defense-in-Depth & ehrliche Bilanz:** Es gibt keinen „unhackbaren" Code. Ziel ist: jede Klasse aus der Taxonomie unten ist bewusst adressiert (mitigiert / nicht zutreffend / akzeptiertes Restrisiko mit Begründung), und kein kritischer Pfad geht ungeprüft live. Was nicht abgedeckt werden kann, wird als **Restrisiko** explizit benannt — nicht verschwiegen.

> **Client = feindlich.** Jede Entscheidung über Geld, Zugang und Berechtigung wird **server-seitig aus der Quelle der Wahrheit** getroffen. Niemals auf Client-Werte, IP, Geo, Header oder einen (cachebaren) JWT-Claim allein vertrauen.

---

## 1. Angriffs-Taxonomie (jede Klasse durchgehen — OWASP Top 10 + API Security Top 10)

| # | Klasse | Was prüfen | Mitigation-Kern |
|---|---|---|---|
| A01 | **Broken Access Control / IDOR / BOLA** | Jeder Endpoint: prüft er Ownership der konkreten Ressource, nicht nur „eingeloggt"? Funktions-Level (BFLA: darf diese Rolle diese Aktion)? | Server-seitige Authz pro Objekt **und** Funktion; Default-Deny |
| A02 | **Cryptographic Failures** | Secrets im Klartext? Schwache Hashes? TLS überall? Tokens mit Entropie+Ablauf? | argon2/bcrypt, TLS1.2+, CSPRNG, kein Eigenbau-Krypto |
| A03 | **Injection** (SQL/NoSQL/Cmd/LDAP/XXE/Template) | User-Input in Query/Shell/Template/XML? | Parametrisierung/ORM-Bindings, Schema-Validierung am Rand, kein String-Build |
| A04 | **Insecure Design** | Fehlt ein Rate-Limit/Abuse-Modell by design? Trust-Boundaries klar? | Threat-Model pro Feature (dieser Skill), Abuse-Cases (§3) |
| A05 | **Security Misconfiguration** | Debug/Stacktrace an Client? Default-Creds? Offene CORS? Fehlende Header? | helmet/CSP/HSTS, strikte CORS-Allowlist, keine Prod-Debug-Ausgaben |
| A06 | **Vulnerable/Outdated Components** | Veraltete Deps mit CVEs? Lockfile? | SCA (`npm audit`/Snyk), gepinnte Versionen, `threat-intel.md`-Refresh |
| A07 | **Identification & Auth Failures** | Session-Fixation, Credential-Stuffing, schwache Reset-Flows, fehlende MFA-Option | §2 |
| A08 | **Software/Data Integrity** | Unsignierte Updates, unsichere Deserialisierung, CI/CD-Supply-Chain | Signaturprüfung, keine unsichere Deserialisierung, §4 |
| A09 | **Logging/Monitoring Failures** | Werden Security-Events geloggt? Secrets im Log? Tamper-Evidenz? | Audit-Log ohne PII/Secrets, Alerting auf Auth-/Payment-Anomalien |
| A10 | **SSRF** | Server holt user-gelieferte URL (Webhook/Import/Image)? | Host-/Scheme-Allowlist, interne IP-Ranges blocken, keine Redirects folgen |
| API | **Mass Assignment / Excessive Data Exposure** | Body→Model direkt? Response leakt interne Felder? | Feld-Allowlist (DTO), Response-Whitelisting |
| API | **Unrestricted Resource Consumption** | Kein Payload-/Rate-/Pagination-Limit? Regex-DoS? | Limits + Timeouts + `safe-regex`, §5 |

Pro Klasse Status notieren: **mitigiert / N/A / Restrisiko (Grund)**.

---

## 2. AuthN / AuthZ / Session (echte Kunden = hohes Ziel)

- **Authz aus der Quelle der Wahrheit**, nicht aus dem JWT allein — ein Claim kann *stale* sein (Abo nach Token-Ausstellung gekündigt). Berechtigung server-seitig gegen DB prüfen **oder** Token bei Statuswechsel invalidieren (Symmetrie!).
- **JWT-Fallen:** `alg=none` ablehnen, Algorithmus serverseitig fixieren, Signatur+`exp`+`aud`+`iss` prüfen, kein Secret im Client.
- **Session:** Fixation verhindern (ID nach Login rotieren), Idle/Absolut-Timeout, server-seitiger Logout/Revoke.
- **Account-Takeover-Flächen:** Passwort-Reset (Token einmalig+kurzlebig, kein User-Enumeration-Leak), E-Mail-Änderung (Re-Auth), MFA-Option, Credential-Stuffing → Rate-Limit + Anomalie-Erkennung.
- **IDOR überall** wo eine ID/Slug aus dem Request kommt: gehört das Objekt dem Caller?

---

## 3. Payment, Paywall & Abuse-Resistenz (VPN / IP / Geo / Coupon)

> **Kernprinzip Paywall:** Zugang = *authentifizierter Account* + *server-seitig verifizierter Zahlungs-/Entitlement-Status*. **Niemals** IP, Geo, VPN-Erkennung oder ein Client-Flag als Gate. Wer per VPN/neuer IP „umgeht", umgeht nur ein schwaches Gate — das robuste Gate ist account-gebunden und kennt keine IP.

**Paywall-/Entitlement-Bypass:**
- Entitlement bei **jedem** gated Request server-seitig prüfen (nicht nur im Frontend-Routing, nicht nur einmal beim Login).
- Kein „premium"-Flag im JWT/LocalStorage/Cookie dem man vertraut → immer gegen Source-of-Truth.
- IP/Geo höchstens als **Signal** (Fraud-Scoring), nie als alleinige Schranke. VPN/Proxy-Erkennung ist umgehbar und DSGVO-heikel — nicht als Sicherheitsanker missbrauchen.
- Soft-Paywall-Inhalt (z.B. „erste N gratis") server-seitig zählen **pro Account**, nicht pro IP/Cookie (sonst: Inkognito/VPN umgeht).

**Coupon-/Discount-Abuse (relevant bei Gutschein-/Coupon-Code):**
- **Redemption-Race:** zwei parallele Einlösungen desselben Codes → atomar (DB-Constraint/`UPDATE … WHERE remaining>0`/Transaktion), sonst Doppel-Einlösung.
- **Caps:** pro-Code-Limit, pro-Account-Limit, Gültigkeitsfenster — server-seitig erzwungen.
- **Stacking:** dürfen Codes kombiniert werden? Explizit erlauben/verbieten, nicht implizit.
- **Negative/Overflow:** Rabatt > Betrag → Endpreis < 0? Betrag-Untergrenze + Typ-/Range-Validierung.
- **Enumeration/Brute-Force:** Codes nicht erratbar (CSPRNG, keine Sequenz), Rate-Limit + Lockout auf Einlöse-Endpoint.
- **Idempotenz:** Retry/Doppel-Klick auf „einlösen" == einmal (Idempotency-Key).

**Trial-/Multi-Account-Abuse:** „gratis Trial" pro Zahlungsmittel/Account begrenzen; Wegwerf-E-Mail-Toleranz bewusst entscheiden; Signale (gleiche Zahlungsquelle) statt harter Blockaden, privacy-aware.

**Payment-Integrität (Stripe & Co.):**
- **Webhook-Signatur verifizieren** (Raw-Body!) — sonst kann jeder „payment succeeded" faken. Bei mehreren Accounts/Provider **jeden** Webhook-Pfad + Secret prüfen (Config-Duplikat-Falle, siehe `blast-radius.md`).
- **Webhook-Idempotenz & Replay-Schutz** (Event-ID dedupe).
- Preise/Beträge **server-seitig** bestimmen, nie aus dem Client-Request übernehmen.
- Refund/Dispute → Entitlement symmetrisch entziehen (Symmetrie).

---

## 4. Supply-Chain & Build

- Lockfile committed & integritätsgeprüft; Versionen gepinnt; `npm audit`/SCA im CI.
- Neue Dependency: Reputation/Maintainer/Download-Trend prüfen (Typosquatting), `postinstall`-Scripts misstrauen.
- CI/CD-Secrets nicht in Logs/Artefakte; minimale Token-Scopes; Branch-Protection.
- Keine Secrets im Client-Bundle (Frontend-Env die im Browser landet).

---

## 5. Transport, Header, DoS, Daten

- **Header:** HSTS, CSP (keine `unsafe-inline` wo vermeidbar), `X-Content-Type-Options`, sichere Cookies (`HttpOnly`+`Secure`+`SameSite`).
- **CORS:** strikte Origin-Allowlist, keine `*` mit Credentials.
- **DoS/Resource:** Rate-Limit **pro IP UND pro Account**, Payload-Size-Limits, Query-Timeouts, Pagination-Caps, ReDoS-sichere Regexe.
- **Daten/DSGVO:** Verschlüsselung at-rest/in-transit, PII-Minimierung & Maskierung in Logs, Lösch-/Export-Pfade, Audit-Log tamper-evident.

---

## 6. Verifikation der Härtung (in P5)

- **`/security-review`** auf den Diff der laufenden Änderung aufrufen — fängt die konkreten eingeführten Schwächen. (Ergänzend `/code-review` für Korrektheits-Bugs.)
- Heutige **`threat-intel.md`**-Findings gegen den Diff + die berührten Klassen abgleichen.
- Bei **NO-FAIL** zusätzlich die `zero-fail-zones.md` von `/feature-testing` vollständig durchlaufen (Auth/Authz/Payment/PII/Migrationen) und adversariale Tests fahren.
- Ergebnis in den `SECURITY`-Block des Delivery-Reports; **exposed/kritisch ungemittelt = BLOCKIERT**.

> Eine Angriffsklasse aus §1 ohne Status (mitigiert/N/A/Restrisiko) gilt als **nicht geprüft** → bei NO-FAIL = BLOCKIERT.
