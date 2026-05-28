# Spec-Source-of-Truth — Erfundene Inhalte verhindern

> Spielbuch für `PHASE 1.8`. Trigger: jede UI-Stelle die user-sichtbaren Marketing-/Preis-/Limit-/Feature-Text enthält.

## §1 Das Problem

LLMs sind Wahrscheinlichkeits-Verteilungen über plausible Token-Folgen. Wenn man einen Pricing-Page-Bereich generieren lässt, kommt **plausibles Marketing** raus — nicht **das vereinbarte Spec**. Plausible Marketing-Texte sind nicht harmlos:

- Sie versprechen Features die nicht existieren ("Custom Connectors", "Dedizierter Ansprechpartner")
- Sie nennen Limits die nicht enforced sind ("1.000.000 Aktionen / Monat" ohne Backend-Cap)
- Sie weichen vom tatsächlichen Stripe-Plan ab (UI sagt 5 Nutzer, Stripe-Plan hat keine User-Quota)
- Sie sind nach Live-Schaltung schwer zu zurückzubauen ohne Kunden zu vergraulen

## §2 Akzeptable Quellen

| Quelle | Form |
|---|---|
| Notion-Page | URL der Page + Section-Anchor |
| Spec-File im Repo | `docs/pricing.md`-Pfad + Commit-Hash der den Wert eingeführt hat |
| CMS-Eintrag | CMS-System + Eintrag-ID |
| Stripe Dashboard | Product-ID + Price-ID |
| Backend-Config | Datei-Pfad + Variablen-Name |
| DB-Tabelle | Tabelle + WHERE-Filter, Beispiel-Row angefügt |
| Mail-Template-Spec | Template-Pfad + Version |
| Boss-WhatsApp-Audio (dokumentiert) | Audio-Datei + Timestamp + Transkript |

## §3 Inakzeptable Quellen

- "Aus dem Modell"
- "Plausibel"
- "Wie es bei Konkurrenten ist"
- "Cem hatte das im Call gesagt" ohne dokumentierte Quelle
- "War schon immer so" wenn die Stelle neu eingeführt ist

## §4 Abgleichs-Verfahren

Pro UI-Stelle, die P1 als „user-sichtbarer Marketing/Preis/Limit-Text" markiert hat:

1. **Quelle benennen** — pro Wert eine Quell-Zeile in Form:
   ```
   "Plan: Starter / Preis: 69 €" → Notion://app-pricing-v3#starter
   "Plan: Starter / Limit: Bis 500 Wohneinheiten" → spec/pricing.md@a1b2c3d Z. 18
   ```
2. **Zeichen-für-Zeichen-Diff** zwischen Code-Wert und Quell-Wert. Whitespace, Sonderzeichen, Einheit (€/EUR, /Mon/Monat). Abweichung → `SPEC-MISMATCH`-Zeile im Ledger.
3. **Quell-Vollständigkeit** — falls die Quelle nur Teil-Inhalte hat (z.B. Notion hat Preise aber keine Feature-Listen), klären wo der Rest steht. **Kein Auffüllen aus dem Modell.**
4. **Stripe-Plan-Quer-Check** — wenn UI ein Limit / Volumen / Preis behauptet, MUSS es einen Stripe-Plan-Eintrag (Price.tiers / Price.usage_type / Product.metadata) geben der das spiegelt. UI ohne Stripe-Backing = die Behauptung ist nicht enforcebar.

## §5 Häufige Halluzinations-Muster (gegen die der Check schützt)

| Halluzinations-Muster | Erkennungs-Heuristik | Gegenmittel |
|---|---|---|
| Runde Marketing-Zahlen ohne Backing | "1.000.000", "Unbegrenzt", "Bis zu 50" — prüfen ob Stripe-Plan/Code einen entsprechenden Cap hat | Stripe-Quer-Check (§4.4) |
| "Inkl. KI" / "Inkl. Custom Connectors" | Pflicht: zeigen wo im Code das Plan-Gate "KI"/"Connectors" durchschaltet | P5.6 Adversarial Test (Plan-Limit-Bypass) |
| "Priority Support / Dedizierter Ansprechpartner" | Existiert ein Ticket-System-Routing das Plan-basiert priorisiert? | Wenn nein → entfernen oder umformulieren |
| Doppelte Limits in mehreren Tier ("Bis 250.000" + "Bis 250.000 Aktionen / Monat") | Sind das verschiedene Caps oder ein Copy-Paste? | Spec-Quelle muss eindeutig sein |
| Plan-Name-Drift ("MyApp Starter" vs "Starter" vs "MyApp Pro") | Heißt der Plan im Code überall gleich? In Stripe? In der UI? | Globaler Name aus einer Quelle |
| Erfundene Trial-Längen | "14 Tage kostenlos" — wird der Trial-Period-Days-Wert in Stripe wirklich auf 14 gesetzt? | Stripe-Config diff'en |

## §6 Output für den Delivery-Report

```
SPEC-SOURCE-OF-TRUTH AUDIT
  UI-Stellen geprüft:        [n]
  Quellen benannt:           [n / m]   (m = mit Quelle, n = total)
  Spec-Mismatches:           [0 / Liste]
  Stripe-Backing-Mismatches: [0 / Liste]
  Erfundene Stellen (keine Quelle):  [0 / Liste]   ★ wenn >0 → BLOCKIERT
```
