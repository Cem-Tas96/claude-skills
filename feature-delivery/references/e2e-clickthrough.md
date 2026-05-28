# E2E User-Klick-Through — Voll-Protokoll

> Ein Skill der nur Tech-Pfade verifiziert findet keine Käufer-Bugs. Diese Datei ist das operationelle Spielbuch für `PHASE 5.5` von `/feature-delivery`. Trigger: jeder Change der eine User-Journey berührt (Auth, Payment, Onboarding, Trial, Cancel, Refund, Permission, Mail).

## §1 Voraussetzungen die VOR Stage 1 stimmen müssen

| # | Voraussetzung | Wenn nicht da → |
|---|---|---|
| 1 | Ein echter, sauberer Browser-Kontext (Inkognito-Tab oder dedizierter Profil/Container) | Browser-Cache verfälscht Auth-Tests |
| 2 | Eine echte, **inspizierbare** Mailbox — Gmail-Account / Mailtrap / Mailpit / MailHog | "SMTP 250" reicht nicht |
| 3 | Stripe-Test-Mode aktiv (Frontend + Backend nutzen `pk_test_…` / `sk_test_…`) | Real-Karten gefährlich, Test-Karten werden abgelehnt |
| 4 | Lokaler / Stage-Endpunkt erreichbar (kein Prod-Klick-Through, außer Smoke-Subset) | Risiko unbeabsichtigter Prod-Mutation |
| 5 | Screenshot-Tool (`cmd+shift+4` macOS / `mcp__chrome*.screenshot` / Playwright `page.screenshot`) bereit | Ohne Screenshot kein DoD-Beleg |

> Eine Voraussetzung fehlt → das Resultat ist **nicht** „best effort", sondern **BLOCKIERT** mit Grund "Klick-Through-Voraussetzung X fehlt". Ehrlich blocken ist immer besser als "läuft bei mir" zu behaupten.

## §2 Das 10-Stage-Skript

### Stage 1 — Discovery
- URL: Landing/Pricing-Page
- Screenshot: `01_pricing.png`
- Pro Plan-Karte: Plan-Name, Preis, Feature-Liste, CTA-Text mit der **Spec-Source-of-Truth** (P1.8) Zeichen-für-Zeichen vergleichen
- Hidden Trap: zwei Pläne mit identischem CTA-Text aber unterschiedlicher Landing-Ziel-URL — beide Ziele dokumentieren

### Stage 2 — Signup
- Neue zufällige Mail-Adresse aus inspizierbarer Mailbox (z.B. `claudetest+$(date +%s)@gmail.com` mit Plus-Addressing)
- Echtes nicht-triviales Passwort merken (in Notizen ablegen — wird in Stage 7 wieder gebraucht)
- Submit → Screenshot `02_post_signup.png`
- Beobachten: Geht die UI in einen "Verify-Email"-Zustand? Oder wird der User direkt eingeloggt? Beides sind valide Patterns, aber das eigentliche Spec sollte das eindeutig vorgeben (P1.8).

### Stage 3 — Verify-Mail
- Mailbox refreshen, Verify-Mail finden (Timeout: 60s; länger → Mail-Delivery-Bug)
- Mail in **echtem Mail-Client** öffnen (Gmail-Web, Apple Mail, Outlook-Web) — `03_verify_mail.png`
- Visual-Audit: Anrede, Brand, Button funktioniert, Link-Domain stimmt
- Verify-Link klicken im **demselben Browser** wie Stage 2 (Stage-State-Sync-Test)

### Stage 4 — Plan-Auswahl + Checkout-Öffnen
- Plan-Karte aus Stage 1 wählen (z.B. Starter)
- Stripe-Checkout-Seite → Screenshot `04_checkout.png`
- **Pflicht-Audit der Line-Items:**
  - Anzahl Items == 1 (oder die explizit erwartete Zahl aus dem Plan-Spec)
  - Jedes Item: Name + Preis exakt wie auf Pricing-Page
  - Kein Phantom-Posten („0,80 € pro Einheit", „Der Preis variiert" sind nur valide wenn der Plan **explizit** metered ist und das im Spec steht)
  - Checkout-Footer: korrekter Brand (nicht „Powered by Stripe + Original-Brand")

### Stage 5 — Echte Stripe-Test-Karte
- Karte: `4242 4242 4242 4242` (universal Test-Success-Karte)
- Datum: zukünftig (z.B. `12/30`)
- CVC: beliebig (`123`)
- Name + Land + Rechnungsadresse + Firmen-Option (falls B2B)
- Submit
- **Bei B2B-Pflicht-Daten**: testen ob "Firma" als Option vorhanden ist + Rechnungsadress-Pflichtfelder vorhanden. Fehlt das → BLOCKIERT (häufiger Bug)

### Stage 6 — Post-Payment-Redirect & Receipts
- Wo landet der User? Erwartet: Success-Page mit klarem Next-Step ("Zur App")
- Screenshot `06_post_payment.png`
- Mailbox: welche Mail(s) kommen jetzt? Erwartet: Stripe-Receipt + Welcome-Paid + ggf. Invoice-PDF
- Jede Mail in P5.7-Manier visuell auditieren
- Häufiger Bug: zwei doppelte Welcome-Mails (eine vom Signup-Trigger, eine vom Subscription-Active-Trigger) — Idempotenz-Bug in der Mailer-Schicht

### Stage 7 — Login mit dem Signup-Passwort  ★ Multi-Repo-Bruch-Detektor
- In neuem Browser-Tab (Cookie/Session der Signup-Strecke verworfen) zur App-Login-URL
- Mail aus Stage 2 + Passwort aus Stage 2 eingeben
- Submit → erwartet: Login erfolgreich, User landet im App-Dashboard
- Screenshot `07_login_result.png`
- **Wenn "Ungültige E-Mail oder Kennwort" obwohl korrekt:** das ist der Multi-Repo-Auth-Sync-Bruch (P1.7). Sofort BLOCKIERT. In den Backend-Logs prüfen: wurde der Provision-Webhook empfangen? Wurde das PW-Hash an die App-DB propagiert? Ist der Hash-Algo identisch (bcrypt vs argon2id)?

### Stage 8 — First-Workflow / First-Value
- Behauptete Hauptaktion ausführen: 1 Workflow erstellen, 1 Custom-App auswählen, 1 Aktion ausführen
- Falls eine Custom-App im Plan beworben ist aber im UI fehlt → BLOCKIERT (Boss-Feedback: "casavi taucht gar nicht auf")
- Screenshot `08_first_workflow.png`

### Stage 9 — Cancel-Pfad
- Im UI: Subscription kündigen
- Erwartet: Cancel-Bestätigungs-Mail (DSGVO Art. 7 Abs. 3 — Widerruf so einfach wie Einwilligung)
- Keine Mail → BLOCKIERT mit `MAIL-MISSING:cancel-confirmation`
- Stripe-Dashboard prüfen: Subscription-Status `canceled` oder `canceled_at_period_end`?

### Stage 10 — Forgot-Password
- Logout
- "Passwort vergessen" anklicken, Mail aus Stage 2 eingeben
- Reset-Mail in Mailbox finden, Link klicken, neues PW setzen
- Mit neuem PW einloggen
- Häufiger Bug: Reset-Mail kommt nicht, oder Link führt zu 404, oder neues PW wird nicht akzeptiert

## §3 Browser-Agent-Automatisierung (wenn verfügbar)

Wenn der Projekt-Stack ein Browser-Automation-Tool hat (`agent-browser`-Skill, Playwright, MCP-Chrome, Cypress):
- Das 10-Stage-Skript automatisiert ablaufen lassen
- Screenshots automatisch nach `e2e-screenshots/<timestamp>/` speichern
- Mail-Bodies via Mailtrap-API / IMAP / Mailpit-API dumpen
- Stripe-Test-Karten-Inputs scripten

Fallback: manueller Klick-Through. **Schmaler als die volle Automatisierung — aber lieber manueller Klick mit Screenshots als gar kein Klick.**

## §4 BLOCKIERT-Bedingungen (jede einzeln triggert SHIP-Stopp)

1. Eine Stage schlägt fehl
2. Stripe-Checkout zeigt unerwartete oder Phantom-Line-Items
3. Eine Pflicht-Mail (P2.6) erreicht die Mailbox nicht innerhalb 120s
4. Eine Mail rendert kaputt im echten Client (Anrede, Links, Buttons, Brand)
5. Login mit Signup-PW über Multi-Repo-Grenze schlägt fehl
6. UI-Plan-Limit ist in P5.6 nicht enforced
7. Brand-Leak in einer Mail oder UI-Seite
8. Cancel ohne Confirmation-Mail
9. Forgot-Password Mail-/Link-Bruch
10. Custom-App im Plan beworben aber im UI fehlt

> Jede dieser Bedingungen war ein historischer Real-Miss. Sie sind nicht hypothetisch.

## §5 Output

In den Delivery-Report kommt:
- Liste der Screenshots mit Pfaden (relativ zum Repo)
- Pro Stage: ✓ / ✗ / N/A
- Pro Mail in Stage 3/6/9/10: visual-audit-Status (✓ Anrede OK + ✓ Brand OK + ✓ Links OK)
- Beobachtete Backend-Log-Snippets bei Webhook-Übergängen
