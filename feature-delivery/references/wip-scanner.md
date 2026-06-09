# WIP-Scanner — Dummy/Placeholder/Mock-Detection

> Spielbuch für Pre-flight Teil 2 und Phase 4.5 von `/feature-delivery`. Der teuerste Bug-Typ, weil im Coverage-Ledger nichts „fehlt" — der Code-Pfad funktioniert technisch, liefert semantisch Müll.

## §1 Vollständige Grep-Pattern-Liste

```regex
\bTODO\b|\bFIXME\b|\bXXX\b|\bHACK\b|\bDUMMY\b|\bPLACEHOLDER\b|\bTEMP(?:ORARY)?\b|\bREPLACE(?:_ME)?\b
\bMOCK\b|\bSTUB\b|\bSAMPLE\b|\bEXAMPLE\b|\bFAKE\b|\bSEED(?:_ONLY)?\b
hardcoded|hard-coded|hard_coded
example\.com|example\.org|example\.net
test_|TEST_|_test\b|\.test\.|dummy_|DUMMY_|placeholder_
dev[_-]only|do not ship|DO NOT SHIP|do not deploy
lorem ipsum|Lorem Ipsum|foo bar|FooBar
\b(?:password123|admin|admin123|qwerty|changeme|secret123|test123)\b
\b\d{16}\b  # potenziell hardcoded Card-Numbers
sk_test_|pk_test_|whsec_test  # Stripe test keys (im prod-Pfad ein Bug)
```

Plus stack-spezifisch:
- **JS/TS:** `// @ts-ignore`, `// eslint-disable`, `console\.log`, `debugger;`
- **Python:** `pdb.set_trace`, `import pdb`, `# noqa`
- **SQL:** `DROP TABLE IF EXISTS`, `TRUNCATE`, `WHERE 1=1` ohne weiteren Filter
- **Configs:** `localhost`, `127\.0\.0\.1`, `0\.0\.0\.0`, `://my-…/` in Prod-Pfaden
- **Mail-Templates:** `{{firstName}}` ohne Fallback, `Lieber Kunde`, `Hi there`
- **Stripe:** `unit_amount: 100` (klassisch „1 Euro Dummy"), `product: prod_xxx` ohne dokumentierten Bezug zu UI

## §2 Entscheidungs-Matrix je Treffer

```
IST DER TREFFER IM TEST/SPEC/MOCK-PFAD?
├── ja → 
│   IST DAS EINE Datei in test/ oder __tests__/ oder *.spec.ts oder *.test.py oder fixtures/?
│   ├── ja → N/A (+ Pfad zur Test-Datei)
│   └── nein → REPLACE-Pflicht (Test-Pattern leakte in Production)
└── nein →
    BERÜHRT DER TREFFER PRODUCTION-PFAD ODER UI/DB/EXTERNAL-API?
    ├── ja → REPLACE-Pflicht, ins Ledger als WIP-REPLACE
    └── nein, ist intern-only (Dev-Script, Migration-Helper, CI-Tool) → 
        N/A nur mit explizitem Beleg dass der Pfad nicht Production aufruft
```

## §3 Typische Ersetzungs-Patterns

| WIP-Treffer | Ersetzt durch |
|---|---|
| Stripe `unit_amount: 100` / `product: prod_dummy_…` | Echte Product-/Price-ID aus dem Stripe-Dashboard (gegen Spec-Source-of-Truth gediffed) |
| `localhost:3000` in Env-Default | `process.env.APP_URL` mit dokumentiertem Pflicht-Set in `.env.example` + Bootstrap-Check |
| `lorem ipsum` Marketing-Text | Text aus Notion-Page / CMS / Spec-File (P1.8) |
| `{{firstName}}` Mail-Template ohne Fallback | `{{firstName \| default('')}}` + Anrede-Logik: `Hi {{firstName}}` wenn nicht-leer, sonst `Hi`, niemals `Hi {{firstName}}!` |
| `example.com` Mail-Adresse | `process.env.SUPPORT_EMAIL` + Validierungs-Layer |
| `password123` / `changeme` Test-User | Auto-generiertes Passwort via crypto.randomBytes + via Reset-Mail an User |
| `// TODO: error handling` | Echtes try/catch mit `logger.error` + User-facing Fallback |
| `console.log` in Production-Pfad | Strukturiertes Logger-Statement oder entfernen |
| `// @ts-ignore` | Echter Typ-Fix; wenn nicht möglich, Kommentar mit Begründung + Link zu Issue |

## §4 Subtile Klassen die normaler grep verfehlt

- **Stripe-Test-Produkt-IDs:** `prod_…` Strings sind keine offensichtlichen Test-Marker. Den Stripe-Dashboard-Status (`livemode: false`) prüfen. Test-Produkte im Live-Mode-Code = Bug.
- **Default-Werte in DB-Migrations:** `DEFAULT 'pending'` ist meistens ok, `DEFAULT 'test_value'` ein Lapsus.
- **Hardgecodete Admin-User-IDs:** `if (user.id === 1) { allowAdmin() }` in Production. Sucht nach `id === <small-number>` und `id == '…'`-Vergleichen mit fixen Strings.
- **Cron-Schedule die zu schnell laufen:** `* * * * *` (jede Minute) als "Test"-Schedule live geschickt.
- **Feature-Flags die immer `true` sind:** `const ENABLE_X = true` statt aus Config.

## §5 Output

Pro Treffer eine Ledger-Zeile:
```
W1  | billing/src/stripe-config.ts:42  | WIP-REPLACE  | unit_amount: 100 → echter Price aus Stripe-Dashboard | offen
W2  | mail/welcome.html:15             | WIP-REPLACE  | Hi {{firstName}}! → Hi {{firstName \| default('')}} + Fallback | offen
W3  | landing/src/components/Pricing.tsx:88 | N/A    | Lorem-ipsum nur in Storybook-Snapshot, nicht Production | ✓
```

`WIP-REPLACE offen` ist Ship-Blocker wie jede andere Ledger-Zeile.

## §6 Iron Law — keine test-only-Methoden in Produktionsklassen

> **Regel:** Eine Methode, die **ausschließlich von Tests** aufgerufen wird, gehört in eine Test-Utility, **nicht** in eine Produktionsklasse. Der WIP-Scan oben fängt Platzhalter-*Strings*; diese Klasse ist subtiler — legitim benannte Methoden (`reset`, `destroy`, `seed`, `clear`, `__resetForTest`), die nur existieren, weil ein Test sie braucht.

**Warum es ein Bug ist:** vergrößert die Produktions-API ohne Produktions-Nutzung · verletzt die Invariante „alles in Produktion wird ausgeführt" · erzeugt tot wirkende, aber öffentliche Code-Pfade.

**Erkennung (sprach-agnostisch — Symbol-Referenz-Analyse, nicht String-Grep):**
```
Kandidaten-Namen in PRODUKTIONS-Quellen suchen (typisch):
  reset|destroy|teardown|seed|wipe|clear|__test|_forTest|resetState
Pro Treffer:
  └─ Wird das Symbol von PRODUKTIONS-Code referenziert (außerhalb Test-Pfaden)?
      ├─ ja  → ✓ legitim (keine test-only-Methode)
      └─ nein → wird es von TEST-Code referenziert?
                 ├─ ja  → Bug: test-only-Methode in Produktion → HYGIENE-IRON ins Ledger
                 └─ nein → toter Code → entfernen oder begründen
```
*Beispiel-Werkzeug je Stack: `grep`/ripgrep, IDE-„Find usages", oder ein AST-Tool (ts-morph, Python `ast`, go/analysis). Pfad-Heuristik für Test-Code stack-abhängig: `*.test.*`/`*.spec.*`/`tests/`/`__tests__/` (JS), `test_*.py`/`*_test.py` (Python), `*_test.go` (Go).*

**Ersetzung:** Methode in eine Test-Utility/Factory verschieben (z.B. ein Test-Helper-Modul); braucht der Test einen anderen internen Zustand, via Dependency-Injection statt Extra-Methode lösen.

**Output:** `IRON1 | src/services/User.ts:42 | HYGIENE-IRON | reset() nur in Tests genutzt → Test-Utility | offen`. `HYGIENE-IRON offen` ist Ship-Blocker wie jede Ledger-Zeile.

> **Projekt-agnostisch:** Die Regel ist sprachunabhängig; nur die Such-Werkzeuge und Test-Pfad-Muster sind stack-spezifisch (siehe Beispiele).
