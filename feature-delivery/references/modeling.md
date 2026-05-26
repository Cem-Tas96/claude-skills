# Modellierung — State-Tables, Invarianten, Falsy, Contracts

> Erst modellieren, dann coden. Eine vollständige State-Table + Invarianten-Liste VOR dem Code hätte historisch ~80% der Folgekommits gespart. Dieses Dokument liefert die Templates.

---

## 1. STATE-TABLE (Pflicht bei State/Rollen/Lifecycle/Subscription/Async-UI)

Jede `(Start-Zustand × Trigger → End-Zustand)`-Zelle ausfüllen. Eine leere/„weiß nicht"-Zelle ist ein zukünftiger Bug.

**Vorgehen:**
1. Alle **Zustände** auflisten (Spalten: `{anon}`, `{user}`, `{user+seeker}`, `{frozen}`, `{deactivated}` …).
2. Alle **Trigger/Events** auflisten (Zeilen: `register`, `pay`, `cancel`, `refund`, `dispute`, `freeze`, `unfreeze`, `expire` …).
3. Jede Zelle füllen: End-Zustand + Seiteneffekte (welche Rolle granten/revoken, welche Mail, welcher DB-Write).

```
            │ register │ pay(29€) │ cancel  │ refund  │ dispute │ freeze  │ expire
────────────┼──────────┼──────────┼─────────┼─────────┼─────────┼─────────┼────────
{anon}      │ {user}   │   —      │   —     │   —     │   —     │   —     │  —
{user}      │   —      │ {u+seek} │ {user}  │ {user}  │ {user}  │   —     │  —
{u+seeker}  │   —      │   —      │ {user}* │ {user}* │ {user}* │ {frozen}│ {user}*
{frozen}    │   —      │ {u+seek} │ {user}* │ {user}* │ {user}* │   —     │ {user}*
```
`*` = revoke seeker (Symmetrie!). Die mit `*` markierten Endzustände müssen **identisch** sein → das ist eine Invariante (siehe §2): "Jeder Weg der das Abo beendet landet in `{user}`, nie in `{deactivated}`."

> Wenn mehrere Endzustände gleich sein MÜSSEN, prüfe jede betroffene Zelle einzeln dagegen. Genau hier entstand historisch die Folgekommit-Kette: `cancel` landete fälschlich in `{deactivated}` statt `{user}`.

**Mini-Form für einfache Fälle** (Toggle/Flag): die zwei Übergänge `off→on` und `on→off` plus die Idempotenz-Fälle `on→on`, `off→off` explizit notieren.

---

## 2. INVARIANTEN-KATALOG

Invariante = Eigenschaft die nach JEDER Operation gilt. Sie werden später zu Test-Assertions. Häufige Klassen:

| Domäne | Beispiel-Invariante |
|---|---|
| Rollen/Abo | "Kein User hat `seeker` ohne aktives bezahltes Abo." / "Cancel-State == Fresh-Registration-State." |
| Geld | "Σ(Splits) == Gesamtbetrag." / "Kein negativer Kontostand ohne explizite Overdraft-Erlaubnis." |
| Counts | "`activeCount` == Anzahl Rows mit `status=active`." |
| Referenzen | "Kein Child-Row ohne existierenden Parent (kein Orphan)." |
| Idempotenz | "Dasselbe Event 2× verarbeitet == 1× verarbeitet." |
| Zeit | "`createdAt <= updatedAt <= now`." |
| Auth | "Jede mutierende Route prüft Berechtigung BEVOR sie schreibt." |

Pro Feature 2–5 Invarianten formulieren. Jede Invariante gegen jede State-Table-Zelle prüfen.

---

## 3. FALSY-/EDGE-ENTSCHEIDUNGSMATRIX (Pflicht bei jeder Validierung)

Niemals `if (x)` oder `x !== null` ohne diese Aufzählung. Pro geprüftem Wert eine Zeile, pro möglichem Wert eine Entscheidung:

```
Wert       | null | undefined | ''   | 0    | false | NaN  | []   | {}   | "  " (ws)
-----------|------|-----------|------|------|-------|------|------|------|----------
priceId    | rej  | rej       | rej  | n/a  | n/a   | n/a  | n/a  | n/a  | rej
amount     | rej  | rej       | n/a  | ???  | n/a   | rej  | n/a  | n/a  | n/a
tags[]     | rej  | rej       | n/a  | n/a  | n/a   | n/a  | ok   | n/a  | n/a
```
`rej` = ablehnen, `ok` = erlauben, `norm` = normalisieren, `n/a` = Typ kann das nicht annehmen.

> `0` und `''` sind die Klassiker: `if (amount)` lehnt `0` ab obwohl `0` gültig sein kann; `priceId !== null` lässt `''` durch. Jede `???`-Zelle ist eine Design-Entscheidung die du JETZT triffst, nicht der Bug-Report später.

**Sprach-Fallen:** In JS/TS `==` vs `===`, `??` vs `||` (`||` schluckt `0`/`''`/`false`!), `JSON.parse` von `"null"`, `Number("")===0`. In typisierten Sprachen: Laufzeit-`any`-Casts umgehen den Compiler.

---

## 4. CONTRACT-CHECKLISTE (API / Event / DB)

Bei jeder Änderung an einer Schnittstelle die andere konsumieren:

**API-Request/Response:**
- [ ] Neues Pflichtfeld → rückwärtskompatibel? (alte Clients senden es nicht) → optional + Default, oder versioniert
- [ ] Feld entfernt/umbenannt → wer liest es noch? (Konsumenten aus Ledger)
- [ ] Nullability/Typ geändert → Deserialisierung bei Konsumenten bricht?
- [ ] Statuscodes: jeder neue Fehlerfall hat definierten Code + Body-Shape

**Event/Message:**
- [ ] Payload-Schema-Änderung → alte Consumer? Versionierung?
- [ ] At-least-once-Delivery → Consumer idempotent?
- [ ] Reihenfolge garantiert? Wenn nein: Out-of-Order tolerieren

**DB-Schema:**
- [ ] Migration `up` UND `down` (Rollback)
- [ ] NOT-NULL-Spalte auf bestehende Tabelle → Default oder Backfill, sonst bricht Insert
- [ ] Index für neue WHERE-/JOIN-Filter (sonst Full-Scan unter Last)
- [ ] Umbenennung → alle Raw-SQL/ORM-Models/Seeds/Indexe (Ledger)

---

## 5. NEBENLÄUFIGKEIT, IDEMPOTENZ, FRISCHE

**Datenquelle-Frische (häufiger Auth-Bug):**
- Liest du aus Token/JWT/Cache/Session der **stale** sein kann? Beispiel: Berechtigung aus dem JWT gelesen, aber das Abo wurde nach Token-Ausstellung gekündigt → JWT lügt.
- Regel: Sicherheits-/Berechtigungs-Entscheidungen aus der **Quelle der Wahrheit** (DB) lesen, nicht aus einem cachebaren Token — oder Token-Invalidierung beim Statuswechsel erzwingen (Symmetrie!).

**Nebenläufigkeit:**
- Zwei parallele Requests auf denselben Datensatz → Lost Update? → optimistic locking (Version-Spalte) oder Transaktion mit Row-Lock.
- Check-then-act (lesen, prüfen, schreiben) ist ein Race → atomar machen (DB-Constraint, `UPDATE … WHERE`, Unique-Index).

**Idempotenz:**
- Retry/Doppel-Klick/Webhook-Redelivery → derselbe Effekt 2× == 1×? → Idempotency-Key, Unique-Constraint, oder Upsert.
- Partial-Failure: Schreibvorgang scheitert auf halbem Weg → Transaktion klammert alles, sonst inkonsistenter Zustand.

> Diese drei Klassen sind in jsdom/Unit-Tests unsichtbar. Wenn berührt → Test-Tier Integration (Nebenläufigkeit) bzw. Real-Browser via `/verify` (UI-Race) wählen — siehe `verification.md`.
