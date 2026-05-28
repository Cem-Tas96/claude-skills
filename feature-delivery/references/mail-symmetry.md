# Mail-Pflicht-Matrix — Vollprotokoll

> Spielbuch für `PHASE 2.6`. Trigger: jeder Status-Wechsel auf einer User-/Account-/Subscription-Identität.

## §1 Warum Mail-Symmetrie eine eigene Phase braucht

Code-Symmetrie (grant↔revoke, open↔close) prüft die meisten Skills. **Mail-Symmetrie** wird übersehen, weil die "andere Hälfte" nicht im Code-Pfad sondern in einem separaten Mailer-Service / Template-Repo lebt. Folge: Subscription-Cancel funktioniert technisch, aber **niemand hat den Cancel-User eine Bestätigung geschickt** — DSGVO Art. 7 Abs. 3 Beleg-Lücke.

Historischer Miss-Wortlaut: "es ist gar nicht im Code integriert, also ich hab kein einziger Kunde der das Paket gekündigt hat hat eine Kündigungsbestätigung … das ist schon DSGVO".

## §2 Die Pflicht-Matrix (Standard-SaaS)

| Trigger | Vorwärts-Mail (Pflicht) | Counter/Symmetrie-Mail | DSGVO/Wettbewerbs-Grund |
|---|---|---|---|
| signup-form-submit | verify-email (Doppel-Opt-In!) | (Erasure-Confirmation siehe unten) | DSGVO Art. 7 / UWG §7 — Einwilligungs-Doppel-Opt-In |
| verify-email-clicked | welcome-mail | — | UX, nicht legal-pflichtig |
| trial-started | — | trial-end-reminder T-3, T-1 + trial-expired | UX, Abuse-Prävention |
| subscription-create (paid) | payment-receipt + invoice-pdf-attachment | subscription-canceled-confirmation | DSGVO Art. 7 Abs. 3 (Widerruf belegen) + steuerrechtliche Rechnungspflicht |
| invoice-issued | invoice-mail mit PDF-Attachment | credit-note bei Storno | UStG §14 (Rechnungspflicht) |
| payment-failed | dunning-stufe-1 (T+0) | resolved-mail bei erfolgreichem Retry | UX, Cash-Flow |
| payment-failed-persistent | dunning-2 (T+3), dunning-3 (T+7) | subscription-suspended-notice | rechtlich: User muss informiert sein vor Lock |
| subscription-canceled (by user) | cancel-confirmation | reactivation-offer (optional, später) | DSGVO Art. 7 Abs. 3 Beleg + reduced churn |
| subscription-canceled (by admin/system) | account-suspended-mail mit Grund | — | rechtlich: Vertragsänderungs-Beleg |
| password-reset-requested | reset-link-mail (kurzlebiger Token, 10-30 min) | reset-completed-confirmation | Security: bestätigt dem User dass sein PW geändert wurde |
| password-changed (eingeloggt) | password-changed-notice | — | Security-Alert (klassischer Account-Takeover-Indikator) |
| email-changed | confirm-mail-old + confirm-mail-new | rollback-link-bei-old | Security: alter Mail-Owner kann widersprechen |
| 2fa-enabled | 2fa-enabled-notice + Recovery-Codes | 2fa-disabled-notice | Security |
| permission-grant (admin) | grant-notice an betroffenen User | revoke-notice | Compliance-Audit-Trail |
| account-anonymized (GDPR Art. 17) | erasure-confirmation | — | DSGVO Art. 17 Beleg |

## §3 Anrede-Logik (häufige Bruchstelle)

```
INPUT: User { firstName?: string, displayName?: string, email: string, usernameSlug: string }

ANREDE-FUNKTION:
1) wenn firstName != null && firstName.trim() != "" → "Hallo {{firstName}}"
2) sonst wenn displayName != null && displayName.trim() != "" && displayName != usernameSlug → "Hallo {{displayName}}"
3) sonst → "Hallo" (oder "Hi" / sprachspez. Fallback) — NIE den Username-Slug, NIE den Email-Local-Part
```

**Verbotene Anti-Patterns:**
- `Hi {{firstName}}!` ohne Fallback → bei `firstName=undefined` rendert `Hi {{firstName}}!` als Template-Leak
- `Hi {{user.username}}!` → bei autogenerierten Usernames (`appuser`) → "Hi appuser!"
- `Hi {{email.split('@')[0]}}!` → bei `firstname.lastname@…` → "Hi firstname.lastname!" (technisch lesbar aber sehr ungeschickt)

## §4 Mail-Symmetrie-Audit (operativ)

Pro Trigger im Diff:
1. Trigger-Symbol im Code finden (z.B. `subscriptionService.cancel()`).
2. Im selben Diff oder bestehendem Code prüfen: gibt es einen `mail.send('cancel-confirmation', …)` oder `enqueueMail({ template: 'cancel', … })` Aufruf?
3. Falls nein → `MAIL-MISSING:<trigger>`-Zeile ins Ledger.
4. Falls ja → Template-Pfad öffnen, Anrede-Logik prüfen (§3), Brand-Audit (P2.7), DSGVO-Footer (Impressum/Datenschutz/Unsubscribe).
5. **Visual-Audit-Pflicht in P5.7** — die Mail muss am Ende in einem echten Client geöffnet werden.

## §5 Idempotenz & Anti-Spam

- Pro Mail-Trigger: gibt es einen Schutz gegen doppelten Versand bei Retry/Webhook-Replay?
- Empfohlen: Mail-Send mit `idempotency_key` (Trigger-Event-ID + Mail-Template-Name).
- Bounce-Handling: Mails an bouncende Adressen nicht endlos retry'en, sonst Spam-Reputation futsch.

## §6 Output für Delivery-Report

```
MAIL-PFLICHT-MATRIX
  Trigger im Diff:              [n]
  Vorwärts-Mails belegt:        [n / m]
  Counter-Mails belegt:         [n / m]
  Anrede-Fallback OK:           [ja / Findings]
  Visual-Audit (P5.7):          [n / m Templates geöffnet]
  Idempotenz:                   [pro Trigger geprüft / Findings]
  DSGVO-Beleg (Cancel/Erasure): [vorhanden / fehlt]
```

`MAIL-MISSING offen` ist Ship-Blocker.
