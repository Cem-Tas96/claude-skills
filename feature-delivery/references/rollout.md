# Rollout, Reversibilität & Post-Ship-Observability

> **„SHIP" ist nicht das Ende — es ist der Moment, in dem zahlende Kunden deinen Code treffen.**
> Lokal verifiziert (P5) beweist *korrekt*. Es beweist nicht *sicher ausgerollt*. Auf einem System mit aktiven, zahlenden Nutzern (Memory `feedback_zero_customer_impact_merges`) ist Lieferung erst fertig, wenn der Change **rückwärtskompatibel**, **phasenweise**, **umkehrbar** und **beobachtbar** in Produktion ist. Dieses Dokument ist die Nach-SHIP-Hälfte, die der Rest des Skills nicht abdeckt.

Rollout-**Strategie** wird in **Phase 3** entschieden (vor dem Code — Expand-Contract muss man planen, nicht nachrüsten). Rollout-**Ausführung** wird in **Phase 7** belegt.

---

## 1. Rückwärtskompatibilität — Expand-Contract (zuerst additiv, nie brechend)

Die laufende Vorgänger-Version läuft während des Deploys **gleichzeitig** weiter (Rolling Deploy, gecachte Clients, In-Flight-Requests). Jeder Change muss von der **alten** Version überlebbar sein.

| Änderung | FALSCH (brechend) | RICHTIG (Expand-Contract) |
|---|---|---|
| DB-Spalte hinzufügen | sofort `NOT NULL` | nullable + Default → backfill → später `NOT NULL` (separate Migration) |
| Spalte umbenennen | `RENAME` in einem Schritt | neue Spalte hinzu → dual-write → backfill → Leser umstellen → alte droppen (eigener Release) |
| API-Feld | Pflichtfeld entfernen/umbenennen | neues Feld **optional** hinzufügen; altes erst entfernen wenn kein Client es liest |
| Enum/Event | Wert ändern/entfernen | neuen Wert additiv; alten Wert weiter akzeptieren bis alle Produzenten migriert |
| Queue-Message | Shape ändern | versioniertes Schema; Consumer liest alte **und** neue Form |

**Regel:** Verändernde/entfernende Schritte (`contract`) kommen in einem **späteren** Release, nachdem der additive Schritt (`expand`) live und backfilled ist. Dual-Read/Dual-Write überbrückt die Übergangszeit. → Das ist die `migration up`/`down`-Symmetrie (blast-radius §4) auf Deploy-Ebene.

---

## 2. Phasenweiser Rollout & Kill-Switch (Risiko begrenzen, nicht alle Kunden auf einmal)

- **Dark Ship:** Code deployen, aber hinter einem **Feature-Flag** aus. Deploy ≠ Release.
- **Rampe:** Flag für interne User → kleine Kohorte → %-weise hochdrehen. Fehler trifft 1 % statt 100 %.
- **Kill-Switch (Pflicht bei NO-FAIL):** der Aus-Schalter muss **ohne Redeploy** in Sekunden greifen (Remote-Config/Flag/Env-Toggle, vom Code per `if (!flag) return oldPath`). Ein Rollback der einen vollen Deploy/Migration-Revert braucht ist bei einem Prod-Incident zu langsam.
- **Flag-Symmetrie:** der **Aus-Pfad** muss ein *sauberer, getesteter* Zustand sein — nicht „undefiniert wenn Flag false" (blast-radius §4: feature-flag on ↔ off).

---

## 3. Reversibilität — der Rollback-Plan (vor SHIP beantworten, nicht im Incident)

Für jede NO-FAIL-Änderung **vor** dem Merge schriftlich:

- [ ] **Wie macht man es rückgängig?** Kill-Switch (Sekunden) und/oder Deploy-Revert und/oder `migration down` — konkret benannt, nicht „revert halt".
- [ ] **`migration down` existiert und ist getestet** (nicht nur generiert) — Rollback darf keine Daten verlieren.
- [ ] **Forward-Compatibility der Daten:** Zeilen die die **neue** Version geschrieben hat, müssen von der **alten** Version (nach Rollback) lesbar bleiben — sonst ist der Rollback selbst ein Datenschaden.
- [ ] **Irreversibler Anteil isoliert:** Was sich nicht zurückrollen lässt (z. B. an Stripe gesendete echte Charge, versendete Mail) ist klar markiert und durch Idempotenz/Confirm-Gate (P3.3) gesondert geschützt.

> Faustregel: Wenn die Antwort auf „und wenn das in Prod schiefgeht?" ein neuer Hotfix-Deploy ist statt ein Schalter, ist der Change nicht produktionsreif.

---

## 4. Post-Ship-Observability — merken bevor der Kunde es meldet

Lokales `/verify` beweist *jetzt auf meiner Maschine*. Es sagt nichts über *Prod in 3 Stunden*. Der neue/geänderte Pfad braucht ein **Signal**:

- [ ] **Strukturiertes Log/Metrik** auf dem neuen Pfad (Erfolg **und** Fehler, mit Korrelations-ID) — du kannst die Frage „läuft es in Prod gerade?" beantworten ohne zu raten.
- [ ] **Alert** auf den relevanten Bruch: Fehlerrate, fehlgeschlagene Webhooks, Entitlement-Mismatch, Latenz-Spike auf dem Hot-Path. Ein NO-FAIL-Pfad ohne Alert ist blind.
- [ ] **Sentry/Error-Tracking** fängt die neue Exception-Klasse (der Skill bootet Sentry ohnehin — sicherstellen dass der neue Pfad nicht stillschweigend schluckt).
- [ ] **Business-Invariante als Monitor** (bei NO-FAIL): die Invariante aus P2.2 (z. B. „kein `seeker` ohne aktives Abo") als periodischer Check/Query, der bei Drift alarmiert — nicht nur als Test, der einmal grün war.

> Ohne Telemetrie ist deine Bug-Erkennung der Support-Posteingang. Auf zahlenden Kunden ist das zu spät.

---

## 5. Zero-Customer-Impact-Sequenzierung (die Liefer-Reihenfolge)

Direkt aus Memory `feedback_zero_customer_impact_merges`: aktive zahlende Kunden auf Main/Prod → **jeder** Merge phasenweise, rückwärtskompatibel, regressionsgesichert.

Sichere Reihenfolge eines riskanten Changes:

```
1. expand (additiv, rückwärtskompatibel)  →  deploy  →  läuft neben alter Version
2. backfill / dual-write                   →  Daten konsistent in beiden Welten
3. Leser/Verbraucher umstellen             →  hinter Flag, gerampt
4. verifizieren (Telemetrie grün, Invariante hält)  →  Flag auf 100 %
5. contract (alten Pfad/Spalte/Feld entfernen)  →  eigener, späterer Release
```

Jeder Schritt ist für sich rückwärtskompatibel und einzeln rückrollbar. Niemals 1→5 in einem Release wenn Kunden live sind.

---

## 6. Selbstaudit Rollout (vor SHIP eines Prod-gerichteten Changes)

- [ ] Ist der Change **additiv/rückwärtskompatibel** — überlebt ihn die laufende Vorgänger-Version (§1)?
- [ ] Brauchbarer **phasenweiser Rollout / Flag**, oder ist die Änderung klein & sicher genug für direkt (§2)?
- [ ] **Kill-Switch ohne Redeploy** vorhanden (Pflicht bei NO-FAIL)?
- [ ] **Rollback-Plan** beantwortet, `migration down` getestet, Daten forward-kompatibel (§3)?
- [ ] **Telemetrie + Alert** auf dem neuen Pfad — „läuft es in Prod?" ist beantwortbar (§4)?
- [ ] **Contract-Schritt** (Entfernen) auf einen späteren Release verschoben, nicht mit expand vermischt (§5)?

> Trifft „N/A" zu (rein lokales Tooling, kein Prod-Pfad, kein Datenmodell) → kurz begründen und überspringen. Auf Auth/Payment/PII/Migration ist „N/A" fast nie ehrlich.
