# Security-Pass — der Schnelldurchgang des Security-Engineers

> Zweck: ein schneller, strukturierter Sicherheits-Durchgang über jede neue/geänderte Stelle in Phase 2.5 — und eine klare Eskalations-Regel, wann die tiefe NO-FAIL-Prüfliste (`zero-fail-zones.md` von /feature-testing) gezogen werden muss. Dieser Pass fängt die Bug-Klassen die wiederholt durchrutschen, nicht nur die exotischen.

> **Schnell vs. tief:** Dies ist der *Schnell*-Pass. Die **komplette Angriffs-Taxonomie** (OWASP + API Security Top 10), die **Paywall-/Abuse-Resistenz** (VPN/IP/Geo, Coupon-Abuse, Webhook-Integrität) und die Enterprise-Härtung stehen in [`security-hardening.md`](./security-hardening.md). Die **tagesaktuell neuen** Bedrohungen liefert der Pre-flight aus [`threat-intel.md`](./threat-intel.md) — dessen heutige Findings hier mit-prüfen.

---

## 0. Eskalations-Regel (zuerst entscheiden)

Berührt die Änderung eine dieser Domänen → **NO-FAIL**, dieser Schnellpass reicht NICHT, die vollständige `zero-fail-zones.md` ist Pflicht und das Risiko-Tier ist automatisch NO-FAIL:

- **Authentifizierung** (Login, Session, Token, Passwort, MFA, Reset)
- **Autorisierung** (Rollen, Berechtigungen, Ownership, Tenant-Isolation)
- **Geld / Payment** (Preise, Beträge, Webhooks, Gutscheine, Refunds)
- **Personenbezogene Daten / DSGVO** (Export, Löschung, Einwilligung, Logging von PII)
- **Datenmigrationen** (irreversibel, Massendaten)

Für alles andere: der folgende Schnellpass.

---

## 1. Autorisierung & IDOR (die #1-Lücke bei neuen Routen)

- [ ] Jede **neue/geänderte mutierende Route/Methode** prüft Berechtigung **bevor** sie schreibt — nicht erst nach dem Lesen.
- [ ] **IDOR:** Nimmt der Endpoint eine ID/Slug aus dem Request entgegen? → Prüfen dass der Caller auf **genau diese** Ressource Anrecht hat. Nicht nur "ist eingeloggt", sondern "besitzt dieses Objekt". (Klassiker: `/order/:id` lädt fremde Bestellung.)
- [ ] **Default-Deny:** Neue Route ohne explizite Rolle/Decorator → erbt sie eine sichere Default-Verweigerung, oder ist sie versehentlich offen? Bei global-auth-by-default-Frameworks: opt-out-Decorator nicht versehentlich gesetzt.
- [ ] **Vertikale Eskalation:** Kann ein normaler User durch Parameter-Manipulation (`role=admin`, `isAdmin=true` im Body) mehr erreichen?
- [ ] **Mass Assignment:** Werden Request-Body-Felder direkt auf ein DB-Model gemappt? → Allowlist der erlaubten Felder, sonst setzt der Angreifer `ownerId`/`status`/`balance`.

---

## 2. Falsy-as-Auth-Bypass (die stille Klasse)

Die Falsy-Lücken aus `modeling.md` §3 sind oft **Sicherheits**-Bugs:
- [ ] `if (user.priceId !== null)` lässt `''` durch → unbezahlter User gilt als zahlend.
- [ ] `if (token)` akzeptiert nicht, aber `if (!token) deny` vs `if (token) allow` — der Else-Zweig? Leerer String, `0`, `undefined` korrekt als "nicht autorisiert" behandelt?
- [ ] `role || 'admin'` (Default-Fallback in die falsche Richtung) — niemals nach **mehr** Rechten defaulten.
- [ ] Stale-Token: Berechtigung aus JWT/Cache der nach Statuswechsel nicht invalidiert wurde (siehe `modeling.md` §5).

---

## 3. Injection & Input-Validierung

Für **jede** user-gelieferte Eingabe (Query, Body, Header, Filename, URL, ID):
- [ ] **SQL/NoSQL:** Parametrisierte Queries / ORM-Bindings — nie String-Konkatenation. NoSQL: Operator-Injection (`{$gt:''}`) durch Schema-Validierung blocken.
- [ ] **Command/Path:** Kein user-Input in Shell-Aufrufe; Pfad-Traversal (`../`) bei Datei-/Upload-Pfaden normalisieren & einsperren.
- [ ] **XSS:** User-Content der ins DOM/HTML/Mail-Template fließt → kontext-korrekt escapen/sanitizen. Bei `innerHTML`/`dangerouslySetInnerHTML`/Template-`{{{ }}}` besonders.
- [ ] **SSRF:** Nimmt der Server eine **URL** vom User und ruft sie ab (Webhook, Image-Fetch, Import)? → Allowlist von Hosts/Schemes, interne IP-Ranges blocken.
- [ ] **Open-Redirect:** `?returnUrl=`/`?next=` ohne Allowlist → Phishing. Nur relative Pfade oder Allowlist-Hosts.
- [ ] **Schema-Validierung am Rand:** Eingaben mit Zod/Joi/class-validator o.ä. validieren bevor sie in die Logik gehen — Typ, Range, Länge, Format.

---

## 4. Secrets & Daten-Leak

- [ ] Keine Keys/Tokens/Passwörter in **Logs** (auch nicht in Stack-Traces / Request-Dumps).
- [ ] Keine Secrets in **Client-Bundles** (Frontend-Env die im Browser landet).
- [ ] Keine Secrets in **Fehlermeldungen** an den Client (interne Pfade, Stack-Traces, SQL).
- [ ] Keine echten Keys in **Test-Fixtures / Seeds / Commits**.
- [ ] **PII-Sparsamkeit:** Loggst/speicherst du mehr personenbezogene Daten als nötig? Maskieren (E-Mail, IBAN, Telefon).
- [ ] Response gibt nicht **mehr Felder** zurück als der Client braucht (Over-Fetching = Datenleck, z.B. `passwordHash`, interne Flags im User-DTO).

---

## 5. Krypto & Tokens (wenn berührt)

- [ ] Keine selbstgebaute Krypto. Etablierte Libs/Algorithmen.
- [ ] Passwörter: bcrypt/argon2 mit Salt — nie MD5/SHA-plain.
- [ ] Tokens: ausreichend Entropie (CSPRNG), Ablauf, serverseitig widerrufbar.
- [ ] Vergleich von Secrets in **constant time** (kein `===` auf Token bei Timing-sensitiven Pfaden, wo praktikabel).
- [ ] Symmetrie: Token **ausstellen** ↔ Token **invalidieren** (Logout, Statuswechsel, Rotation).

---

## 6. Abschluss des Passes

Ergebnis in den Delivery-Report (`SECURITY-PASS`-Block):
- Jede Klasse (1–5) als **OK** / **Finding** / **N/A** markieren.
- Findings: entweder im selben Change fixen (ins Coverage-Ledger als Zeile) oder — bei NO-FAIL — BLOCKIEREN bis behoben.
- Bei NO-FAIL zusätzlich vermerken: `zero-fail-zones.md` VOLLSTÄNDIG durchlaufen (ja/nein).

> Ein offenes Security-Finding auf einem NO-FAIL-Pfad ist immer **BLOCKIERT**. Kein "fixe ich gleich noch".
