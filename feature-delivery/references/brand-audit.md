# Brand/White-Label-Audit — Voll-Protokoll

> Spielbuch für `PHASE 2.7`. Trigger: jede UI/Mail/Asset-Änderung in einem geforkten oder white-gelabelten Projekt.

## §1 Setup

1. **CLAUDE.md / AGENTS.md / CONTRIBUTING.md / BRAND.md** des Projekts lesen.
2. Extrahieren:
   - **Verbotene Strings** (Original-Brand-Name, Original-Slogan, Original-Domain, "Powered by …", "Built with …" wenn das offenlegt was geforkt wurde)
   - **Erforderliche Strings** (eigener Brand-Name, eigener Slogan, Impressum-Pflicht-Daten)
   - **Erforderliche Assets** (eigenes Logo SVG, eigene Favicon, eigene OG-Image)
   - **Erlaubte Farben + Schriften** (Hex-Codes, Google-Font-Family)

## §2 Verbots-Grep — über alle berührten + alle ausgelieferten Pfade

```bash
# 1) Source-Pfade (was Git versioniert)
git grep -nE '\bActivepieces\b|\bactivepieces\b|AP_|@activepieces/' -- ':!node_modules' ':!dist'
git grep -nE 'Powered by Activepieces|Built with Activepieces|activepieces\.com'

# 2) Generierte Bundles (manchmal Lecks im Compile-Output)
grep -rnE 'Activepieces|activepieces|AP_BRAND' dist/ build/ out/ 2>/dev/null

# 3) Asset-Verzeichnisse — Original-Logos die nicht gelöscht wurden
find . -type f \( -name '*activepieces*' -o -name '*AP_logo*' \) 2>/dev/null

# 4) Translation-Files / i18n
grep -rnE '"Activepieces"|"activepieces"' src/locales/ public/locales/ 2>/dev/null
```

Anpassen je nach Fork-Quelle. Patterns für andere Forks (Retool, Bubble, n8n, Lowdefy, Saleor, etc.) auf dieselbe Art.

## §3 Mail-Templates — der vergessene Brand-Pfad

Mail-Templates werden oft beim Brand-Sweep übersehen weil sie nicht über die Webapp rendern. Sie sind **die häufigste Brand-Leak-Klasse**.

```bash
# Mail-Template-Verzeichnisse finden
find . -type d \( -name 'emails' -o -name 'templates' -o -name 'mail' -o -name 'mailers' -o -name 'mjml' \) 2>/dev/null
# Footer/Header/Subject inspizieren
grep -rnE 'Activepieces|Powered by|<img.*logo' [gefundene-Pfade]/
```

Jede Mail-Template-Datei einzeln öffnen und visuell prüfen:
- Header-Logo: eigenes oder Original?
- Subject-Line: keine Brand-Reste?
- Body: Anrede, Brand-Name, Links, Footer korrekt?
- Footer-Impressum: eigenes Impressum + eigene Datenschutz-URL?
- Unsubscribe-Link: führt auf eigene Domain?

## §4 Generierte Bundles

`npm run build` oder Äquivalent ausführen, dann:
```bash
grep -rnE 'Activepieces|activepieces' dist/ build/ out/ public/ .next/ 2>/dev/null
```

Wenn etwas auftaucht: zur Source-Datei zurückverfolgen (Source-Map oder Suchen nach Pre-Compile-Variante). Manchmal lebt der alte Brand in einer i18n-Default-Übersetzung die im Source schon ersetzt aber im Build-Cache noch da ist (`.next/cache`, `node_modules/.cache`) — diese Caches dann purgen.

## §5 Visueller Schluss-Audit

Wenn alle Verbots-Greps grün und alle Mail-Templates audited:
1. App lokal hochfahren
2. Jede customer-facing Seite einmal öffnen (Landing, Pricing, Signup, App-Login, App-Dashboard, App-Settings, App-Billing-Page)
3. In jeder Seite: Browser-DevTools öffnen → "Find in page" mit Original-Brand-Name. Treffer in Inline-SVG, in `<title>`-Tags, in Meta-OG-Tags, in `aria-label`-Attributen.
4. Favicon-Tab anschauen.
5. Browser-Tab-Title prüfen.

## §6 Ledger-Output

Pro Treffer eine Zeile:
```
B1  | landing/app.tsx:42 footer    | BRAND-LEAK  | "Powered by Activepieces" → entfernt oder durch eigenen ersetzt | offen
B2  | mail/welcome.html:7 logo     | BRAND-LEAK  | Original-Logo URL → eigenes /assets/app-logo.svg | offen
B3  | dist/main.js:14523 i18n      | BRAND-LEAK  | Build-Cache nicht purged; Cache leeren + Rebuild | offen
```

`BRAND-LEAK offen` ist Ship-Blocker — Brand-Lecks haben sowohl rechtliche (Trademark) als auch Customer-Trust-Konsequenzen.

## §7 Sonderfall: bewusst offene Attribution

In MIT/GPL-lizenzierten Forks gibt es manchmal eine **gesetzliche Pflicht** zur Original-Attribution (z.B. AGPL-Network-Use). In dem Fall:
- Attribution gehört nicht in die UI-Hauptfläche sondern in `/about` oder `LICENSE.md` oder Impressum-Fussnote
- Verbots-Grep gibt einen N/A-Eintrag dafür mit Verweis auf die Lizenz-Pflicht
- **Niemals N/A ohne Lizenz-Beleg** — sonst ist es ein Brand-Leak getarnt als Compliance
