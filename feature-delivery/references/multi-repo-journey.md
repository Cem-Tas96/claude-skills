# Multi-Repo Journey-Map — Voll-Protokoll

> Spielbuch für `PHASE 1.7` und `PHASE 5.8`. Trigger: das Feature berührt mehrere Repos, oder ein User-State propagiert über Webhook/API/Queue an einen anderen Repo, oder mehrere `package.json`-Wurzeln liegen im Blast-Radius.

## §1 Warum das eine eigene Phase braucht

Wenn ein Feature über N Repos läuft, prüft die übliche Coverage-Ledger-Methode **N getrennte Bäume**. Die teuersten Bugs sitzen aber an den **N-1 Kanten** dazwischen: Webhook-Idempotenz, Auth-Hash-Format, Eventual-Consistency, Daten-Schema-Drift.

**Historischer Miss:** Signup-Passwort auf Landing wird gesetzt → Stripe-Webhook im Billing löst Account-Provision aus → Flow-Repo legt Account an aber **nicht mit dem Signup-Hash sondern mit einem neu generierten temporären PW** → User landet auf der Login-Seite mit dem PW das er beim Signup eingegeben hat → "Ungültige E-Mail oder Kennwort". Jeder Schritt für sich technisch korrekt. Die **Erwartung des Users** war nirgends modelliert.

## §2 Journey-Tabellen-Template

```
JOURNEY: [Name]
Erwartete-Invariante: [Was MUSS am Ende gelten? z.B. "Signup-PW == Login-PW über alle Repos"]

S# | Wo (Repo · Datei)         | Eingang             | Ausgang/Effekt          | Übergangs-Mechanismus       | Synchron? | Idempotenz? | Status
---|---------------------------|---------------------|--------------------------|------------------------------|-----------|-------------|-------
S1 | landing · signup.tsx      | Email + PW          | row in landing.users    | landing-Auth-API             | sync      | n/a         | offen
S2 | landing · post-signup     | landing-Session     | redirect → billing       | URL-Param + Session-Cookie   | sync      | n/a         | offen
S3 | billing · checkout.ts     | Email aus Cookie    | Stripe-Session erzeugen  | stripe-sdk createSession     | sync      | n/a         | offen
S4 | stripe                    | Card + Session      | Webhook payment.success  | Stripe-Webhook (signiert!)   | async     | Pflicht     | offen
S5 | billing · webhook.ts      | webhook payload     | row in billing.users    | DB-INSERT + Provision-Event  | async     | Pflicht     | offen
S6 | flow · provision-listener | Provision-Event     | row in flow.users       | API-Call billing→flow        | async     | Pflicht     | offen ← Bruchstelle
S7 | flow · login              | Email + Signup-PW   | Session                 | flow-Auth (bcrypt-Hash)      | sync      | n/a         | offen ← sichtbarer Fehler
```

## §3 Pflicht-Checks je Übergangs-Typ

### Webhook-Übergänge (S4, S5, S6 in unserem Beispiel)
- **Signatur verifiziert?** Stripe-Webhooks: `Stripe.webhooks.constructEvent(payload, sig, secret)`. Ungesigned Webhooks akzeptieren = Webhook-Forgery-Angriffe möglich.
- **Idempotent?** Webhook kommt potenziell 2-3× (Stripe-Retry bei `non-2xx`). Erster Treffer: process. Zweiter: erkenn als Duplikat (Event-ID-Dedup-Tabelle) und antworte 200 ohne Re-Provisionierung.
- **Retry-Resilient?** Was wenn S6 (API-Call billing→flow) timeout't? Wird der Webhook neu zugestellt? Gibt es eine Queue + Dead-Letter?
- **Out-of-Order?** Was wenn `payment.success` und `subscription.created` in falscher Reihenfolge ankommen?

### Auth-Übergänge (S1 ↔ S7)
- **Hash-Algo-Identität:** beide Seiten dokumentiert dieselbe Funktion + Salt-Rounds (bcrypt(12), argon2id, …)?
- **Hash-Storage:** Wer schreibt den Hash? Wenn S1 in landing.users schreibt aber S6 ein eigenes Default-PW vergibt → Bruch.
- **Re-Hashing:** wenn die Algos verschieden sind, gibt es eine Re-Hash-Strategie ("nächster erfolgreicher Login mit dem alten Hash → neu mit neuem Algo speichern")?
- **Reset-Token:** wenn der User das PW vergessen hat, ist der Reset-Pfad single-source-of-truth (landing.users? flow.users?) oder doppelt-mit-Sync?

### State-Übergänge mit Eventual-Consistency
- **Race:** S5 schreibt billing.users.status=`active`, S6 schreibt flow.users.status=`active`. Was sieht ein paralleler GET-Request auf flow während S5 schon durch ist aber S6 noch nicht?
- **UI-Lücke:** gibt es einen sichtbaren "wird eingerichtet"-State oder fliegt der User in eine 404?
- **Timeout-Verhalten:** wenn S6 fehlschlägt, was sieht der User? "Bitte später nochmal versuchen" mit Email-Notice oder leerer Screen?

## §4 Übergang-Beweise (für DoD und P5.8)

Pro Zeile in der Journey-Tabelle, beim Klick-Through aufzeichnen:
- **Sync-Übergänge:** Screenshot Vor + Nach + URL der Weiterleitung
- **Webhook-Übergänge:** Log-Snippet aus dem Receiver (Stripe → billing → flow), Event-ID dokumentieren
- **DB-Übergänge:** Query auf beiden Seiten:
  - `SELECT id, email, password_hash, created_at FROM landing.users WHERE email = 'test+xxx@gmail.com'`
  - `SELECT id, email, password_hash, created_at FROM flow.users WHERE email = 'test+xxx@gmail.com'`
  - Hashes Zeichen-für-Zeichen vergleichen (oder dokumentiert begründen warum sie verschieden sind).
- **API-Übergänge:** Request + Response-Dump (Header + Body), Status-Code, Latenz.

## §5 Anti-Pattern in Multi-Repo-Features

| Anti-Pattern | Beobachtung | Gegenmittel |
|---|---|---|
| "Webhook ist im billing-Repo, nicht mein Problem" | S5-S6-Lücke bleibt unbemerkt | Cross-Repo-Ledger zwingt zur Sicht |
| Zwei Auth-Quellen parallel | landing.users vs flow.users beide schreibbar | Single-Source-of-Truth definieren, andere read-only-Replik |
| Webhook ohne Signatur-Verify | Forgery-Risiko | Stripe-SDK constructEvent zwingen |
| Webhook ohne Dedup | Doppelter Account / Doppelte Charge | Event-ID-Tabelle (idempotency-key) |
| User-State über Polling syncen | Race-conditions, latente Inkonsistenzen | Push/Event-driven mit Idempotenz |
| Verschiedene Hash-Algos | Login funktioniert nirgends | Hash-Algo + Salt-Round in geteiltem Spec festschreiben |

## §6 Output für den Delivery-Report

- Vollständige Journey-Tabelle mit `✓` / `✗` je Schritt
- Für jeden ✗: was war erwartet vs was beobachtet, Repo-Datei-Zeile wo der Fix sitzen wird
- Hash-Identitäts-Beweis (zwei Hashes nebeneinander oder dokumentierte Begründung)
- Webhook-Dedup-Beweis (Event-ID + zweiter Aufruf antwortete 200 ohne Re-Provision)
