# Blast-Radius & Coverage — Recon-Rezepte

> Kernstück gegen "vergisst alle Stellen abzudecken". Ziel: ein **bewiesen vollständiges** Coverage-Ledger, bevor eine Zeile editiert wird. Vollständigkeit ist nicht "ich glaube ich hab alles" — sie ist "ich habe jede Klasse von Stelle systematisch durchsucht und das Ergebnis am Source verifiziert".

---

## 1. Symbol-Suche statt Datei-Suche

Suche **Symbole**, nicht Dateinamen. Ein vergessener Aufrufer heißt selten wie die Datei die du änderst.

```bash
# Alle Referenzen eines Symbols (ripgrep, sprachunabhängig)
rg -n --word-regexp 'grantSeekerRole'          # Funktions-/Methodenname
rg -n 'STRIPE_SECRET_KEY'                        # Env-Var (auch Teil-Familien!)
rg -n --word-regexp 'seeker'                     # Rollen-/Enum-Wert
rg -n 'from .*payment\.service'                  # Importeure eines Moduls
rg -n '\.priceId\b'                              # DB-/DTO-Feldzugriff

# Familien-Suche: NICHT nur das exakte Symbol — auch Varianten/Suffixe
rg -n 'STRIPE_(SECRET|WEBHOOK)_KEY(_[A-Z]+)?'    # findet _DOMOAI-Zwilling
rg -n -i 'grant|revoke|assign|unassign'          # Symmetrie-Paare auf einmal
```

Wenn die Codebase eine IDE/LSP-Indizierung hat: "Find all references" / "Call hierarchy" nutzen — fängt dynamische Aufrufe die grep verpasst. grep bleibt Pflicht für Strings, Configs, Templates, generierte Dateien.

**Checkliste je Anker-Symbol** — bis jede Zeile beantwortet ist, ist die Suche nicht fertig:
- [ ] Wer **ruft auf / importiert** es?
- [ ] Wer **liest seinen Output** (Rückgabe, DB-Feld, Event-Payload, HTTP-Response)?
- [ ] Wo ist dasselbe Konzept **nochmal definiert** (Konstante, Enum, paralleler Pfad)?
- [ ] Welche **Typen/DTOs/Schemas** beschreiben es?
- [ ] Welche **Tests/Fixtures/Seeds/Mocks** nennen es?
- [ ] Welche **Docs/`.env.example`/Config-Samples** nennen es?
- [ ] Welche **generierten Artefakte** leiten sich davon ab?

---

## 2. Sub-Agent-Fan-out (großer/unbekannter Code)

Bei breitem Blast-Radius parallele Explore-Agenten starten — je Agent ein scharf umrissener Suchauftrag. Vorlage:

```
Suche im Repo ALLE Stellen die <SYMBOL> betreffen, Kategorie <X>.
Gib eine Tabelle: file:line | wie referenziert | warum betroffen.
Nur Fundstellen mit Zeilennummer. Keine Bewertung, keine Änderung.
```

Empfohlene Streams (einer je Kategorie, parallel):
- **A** direkte Aufrufer / Importeure
- **B** Output-Konsumenten (Felder, Events, Responses)
- **C** Config-Duplikate & Env-Var-Familien
- **D** parallele/duplizierte Implementierungen desselben Konzepts
- **E** Tests, Fixtures, Seeds, Mocks
- **F** generierte Artefakte & deren Quellen
- **G** Docs, READMEs, `.env.example`, Migrations

> 🚨 **VERIFY-AGENT-REPORTS:** Jede gemeldete `file:line` mit `Read` gegenlesen, bevor sie ins Ledger geht. Agenten erfinden Pfade und widersprechen sich. "Der Agent sagte" ist kein Beleg — "ich habe die Zeile gesehen" ist einer.

> **Kopfzahl, Konsens, Verifier, das vollständige Anti-Halluzinations-Gate (Citation-or-void → Source-Abgleich → Konsens) und der Independent-Verifier-Prompt stehen in `references/multi-agent.md`.** Merksatz: mehr Agenten = mehr Recall, **nicht** weniger Halluzination — Präzision kommt nur durch Verifikation. Fan-out-Aufträge darum **disjunkt** schneiden (überlappende Streams bestätigen sich nur scheinbar) und jeden Befund mit wörtlichem Zeilen-Zitat verlangen; findet ein Stream nichts → "KEINE", nichts erfinden.

---

## 3. Cross-Layer-Kopplungs-Katalog (die unsichtbaren Stellen)

Die teuersten vergessenen Stellen sind nicht aus der editierten Datei sichtbar. Jede Kategorie aktiv prüfen:

| Kopplungstyp | Wie finden | Konkretes Beispiel |
|---|---|---|
| **Duplizierte Config-Familie** | Env-Var-Stamm + Suffix-Regex greppen | `STRIPE_*` vs `STRIPE_*_DOMOAI`; `_PROD`/`_STAGING`-Paare; zwei Auth-Provider |
| **Parallele Accounts/Tenants** | Multi-Provider-/Multi-Mandanten-Schalter suchen | zweiter Zahlungsanbieter, zweiter Mandant mit eigenem Code-Pfad |
| **Shared Lib → N Apps** | Wer importiert die Lib? In welchen Apps? | `libs/cookie-consent` → texter + embed + Keycloak-Theme |
| **Build-/Asset-Kopie** | Copy-Scripts in `package.json`/CI suchen | gebautes Element wird in mehrere Zielordner kopiert |
| **Generiertes Artefakt** | Codegen-Config + Output-Ordner finden | OpenAPI-Client, Prisma-Client, GraphQL-Codegen, Protobuf |
| **Env/Bootstrap/Realm-Init** | `.env*`, `docker-compose*`, Realm-/Seed-JSON | SMTP/Realm-Werte die zur Boot-Zeit injiziert werden |
| **Feature-Flag / Remote-Config** | Flag-Namen greppen, beide Branches | on-Pfad gefixt, off-Pfad (sauberer Aus-Zustand) vergessen |
| **i18n / Übersetzungs-Keys** | neuen/gelöschten Key in allen Locale-Files | Key in `de` ergänzt, `en` vergessen |
| **DB-Schema ↔ Code** | Migration + ORM-Model + Query-Stellen | Spalte umbenannt, Raw-SQL/Index/Seed vergessen |

**Projekt-Doku-Greppen (immer):** Existiert `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` mit einer Sektion à la *"behaviors that aren't visible from a single file"* / *"important coupling"* → prüfen ob ein geändertes Symbol dort steht. Wenn ja: alle dort genannten Konsumenten ins Ledger. Diese Sektion ist die institutionelle Erinnerung an genau die Stellen die sonst vergessen werden.

---

## 4. Symmetrie-Paar-Katalog

Für jede hinzugefügte/geänderte Aktion den Partner-Pfad ins Ledger. Wenn der Partner fehlt, ist das Feature halb gebaut.

| Vorwärts | Reverse | Typische Vergessens-Stelle |
|---|---|---|
| grant / assign role | revoke / unassign | Cancel-, Refund-, Dispute-, Freeze-Ende-Pfad |
| create / insert | delete / soft-delete | Cleanup, Cascade, Orphan-Vermeidung |
| open / start / mount / connect | close / stop / unmount / disconnect | Teardown, `finally`, `ngOnDestroy`, Shutdown-Hook |
| subscribe / addEventListener | unsubscribe / removeEventListener | Memory-Leak, Double-Fire bei Re-Mount |
| acquire / lock / increment ref | release / unlock / decrement ref | Deadlock, Leak, Stuck-Lock |
| enable / set flag true | disable / reset / expire | "Aus"-Zustand nie sauber definiert |
| cache write | cache invalidate | stale Daten nach Update |
| serialize / encode / encrypt | deserialize / decode / decrypt | Round-Trip-Mismatch, Versions-Drift |
| migration up | migration down | kein Rollback möglich |
| add to allowlist | remove from allowlist | verwaiste Berechtigung |

Bewusster Verzicht auf einen Reverse-Pfad → als `N/A — Grund: …` ins Ledger, nie stillschweigend.

---

## 5. Coverage-Ledger — Vorlage & Regeln

```
COVERAGE-LEDGER — [Feature/Fix]
ID  | Stelle (file:line / Symbol)         | Art             | Was muss passieren              | Status
----|-------------------------------------|-----------------|---------------------------------|--------
C1  | …                                   | Caller          | …                               | offen
C2  | …                                   | Reverse-Pfad    | … (Symmetrie zu C1)             | offen
C3  | …                                   | Config-Duplikat | …                               | offen
C4  | …                                   | Generat         | nach Source-Change neu erzeugen | offen
C5  | …                                   | Type/DTO        | …                               | offen
C6  | …                                   | Test            | …                               | offen
C7  | …                                   | Doc             | …                               | offen
```

- **Art** ∈ {Caller, Consumer, Reverse-Pfad, Config-Duplikat, Type/DTO, Generat, Test, Doc, Migration}
- **Status** ∈ {offen, ✓, N/A (+Grund)}
- **Kein SHIP solange eine Zeile `offen` ist.**
- **Neu entdeckte Stelle in Phase 4 → sofort als Zeile ergänzen**, nie weglassen.

---

## 6. Vollständigkeits-Selbstaudit (vor Phase 2)

Bevor du das Ledger für vollständig erklärst, diese Fragen beantworten — eine offene Antwort = weitersuchen:

- [ ] Habe ich nach dem Symbol **als Wort** gesucht (nicht nur als Datei)?
- [ ] Habe ich nach **Suffix-/Präfix-Varianten** gesucht (`*_DOMOAI`, `*_v2`, `legacy*`)?
- [ ] Habe ich **jede Symmetrie-Aktion** (Tabelle §4) gegen ihren Reverse geprüft?
- [ ] Habe ich **generierte Artefakte** und ihre Quelle erfasst?
- [ ] Habe ich die **Projekt-Kopplungs-Doku** gegrept?
- [ ] Habe ich **Tests + Docs + `.env.example`** einbezogen, nicht nur Produktivcode?
- [ ] Wenn Sub-Agenten genutzt: habe ich **jede** gemeldete Stelle am Source verifiziert?

> Wenn du diese sieben Boxen nicht ehrlich abhaken kannst, ist das Ledger unvollständig — und der Bug wartet in der Lücke.
