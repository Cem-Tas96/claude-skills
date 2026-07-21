---
name: architecture
description: >
  Architektur-Disziplin für JEDEN System-/Infrastruktur-/Skalierungs-Vorschlag auf JEDEM Projekt.
  Diesen Skill verwenden BEVOR eine Architektur, ein Deployment-Modell, ein Multi-Tenancy-Ansatz,
  eine Transport-/Integrations-Schicht oder eine "wie hosten wir das für N Kunden"-Antwort vorgeschlagen
  wird — besonders bei SaaS-Mandantenfähigkeit, Messaging/WhatsApp/E-Mail-Kanälen, Container-/Orchestrierungs-
  Fragen, Build-vs-Buy, Self-Hosted-vs-Managed und "was skaliert das". Der Skill zwingt den Agent, JEDEN
  Design-Vorschlag ZUERST am Skalen-Test (1 → 10 → 100 → 1000 → 10k Mandanten) zu prüfen, Standard-Patterns
  gegen selbstgebaute Hacks abzuwägen, offizielle/managed Plattformen zu bevorzugen wo sie existieren, und
  offensichtlich nicht-skalierende Designs GAR NICHT ERST vorzuschlagen. Ziel: nie wieder ein Vorschlag wie
  "ein Container pro Kunde", der einen erfahrenen Architekten fassungslos macht. Denkt wie ein Principal/
  Staff-Architekt: erst Constraints + Skalen-Rechnung, dann Design, dann ehrlicher Trade-off. Ergänzt
  feature-delivery (Blast-Radius) — dieser Skill deckt die Ebene DARÜBER ab: das Systemdesign selbst.
---

# architecture — Systemdesign, das der Skalen-Prüfung standhält

> **Warum es diesen Skill gibt (der Auslöser):** Ein Vorschlag lautete "eine Baileys-Instanz /
> ein Container pro Hausverwaltung" für ein WhatsApp-SaaS. Bei 100 Kunden = 100 Container,
> 100 SIM-Nummern, 100 fragile Reverse-Engineering-Sessions mit Bann-Risiko. Ein erfahrener
> Architekt sieht sofort, dass das Unsinn ist — die offizielle **WhatsApp Business Platform
> (Cloud API) über einen BSP wie 360dialog/Twilio** ist multi-tenant über EINEN Dienst, Routing
> per `phone_number_id`, pay-per-conversation, kein Bann-Risiko. Der Fehler war nicht "falsch
> gemerkt", sondern **fehlende Architektur-Reflexe**. Dieser Skill installiert diese Reflexe.

## Die eine Regel, die alles zusammenhält

**Bevor du IRGENDEINE Architektur, ein Hosting-/Deployment-Modell oder ein "so skalieren wir das"
vorschlägst: rechne es an 100× und 1000× Last durch. Wenn die Antwort bei 100 Mandanten absurd
wird (Kosten, Container-Zahl, Handarbeit, Fragilität), ist es das falsche Design — und du schlägst
es NICHT vor, auch nicht als ersten Entwurf.** Der Kunde/Chef soll nie derjenige sein, der dir
sagt "100 Kunden = 100 Container?!". Das musst du selbst sehen.

## Pflicht-Ablauf vor jedem Design-Vorschlag

### 1. Constraints zuerst — nicht raten, fragen oder nachschlagen
- **Skala:** Wie viele Mandanten/Nutzer/Nachrichten heute, in 1 Jahr, im Best-Case? Rechne mit dem Best-Case.
- **Isolation:** Müssen Mandanten hart getrennt sein (Daten, Compliance, DSGVO) oder reicht logische Trennung per `tenant_id`?
- **Betreiber:** Wer betreibt/zahlt/wartet? Kunde oder wir? (Bei SaaS fast immer: wir betreiben, Kunde nutzt.)
- **Kanal-Realität:** Gibt es eine **offizielle** Plattform/API für den Kanal? (Messaging, Payments, Auth, Mail — meistens JA.)
- Wenn eine dieser Fakten unklar ist und das Design davon abhängt: **online verifizieren (WebSearch/WebFetch) oder Cem fragen — nicht annehmen.**

### 2. Skalen-Test — die Rechnung, die den Unsinn sofort zeigt
Nimm den Vorschlag und multipliziere. Für JEDEN Vorschlag explizit durchrechnen:

| Ressource pro Mandant | ×1 | ×100 | ×1000 | absurd ab? |
|---|---|---|---|---|
| Container/Prozesse | | | | >~20 pro Kunde = Alarm |
| Kosten/Monat | | | | |
| Manuelle Einrichtungs-Schritte | | | | >0 pro Kunde bei SaaS = Alarm |
| Externe Ressourcen (SIM, IP, Nummer) | | | | physische pro Kunde = fast immer falsch |
| Fragile/inoffizielle Abhängigkeiten | | | | Reverse-Engineering pro Kunde = Bann-Risiko × N |

**Rote Flaggen, die einen Vorschlag sofort disqualifizieren:**
- "Ein Container/eine Instanz/ein Prozess **pro Kunde**" für > ein paar Dutzend Kunden ohne harten Isolations-Zwang.
- Eine **physische Ressource pro Kunde** (SIM-Karte, eigener Server, manuelle IP), wo eine Cloud-API dasselbe multi-tenant kann.
- **Inoffizielle/Reverse-Engineering-Abhängigkeit** (z.B. Baileys/WhatsApp-Web) als Produkt-Fundament, wo eine offizielle API existiert.
- **Manuelle Einrichtung pro Kunde**, die nicht in Minuten automatisierbar ist.
- "Wir nehmen einfach Kubernetes/mehr Container" als Antwort auf ein Design, das gar nicht pro-Kunde-isoliert sein müsste. K8s löst Orchestrierung, nicht ein falsches Tenancy-Modell.

### 3. Standard-Pattern vor Eigenbau
Für die meisten "wie baue ich das für viele Kunden"-Fragen gibt es ein etabliertes Muster. Kenne sie und greife danach, bevor du etwas erfindest:

- **Multi-Tenancy (Default für SaaS):** EINE Anwendung/Deployment, Mandantentrennung per `tenant_id` in Daten + Routing. Getrennte Container/DBs nur bei hartem Compliance-/Isolations-Zwang oder Enterprise-Einzelkunden.
- **Messaging (WhatsApp/SMS):** **offizielle Business-Plattform über einen BSP** (360dialog, Twilio, Meta Cloud API direkt). Ein Endpoint, viele Nummern, Routing per Nummer/`phone_number_id`. NIE eine Web-Reverse-Engineering-Session pro Kunde für ein Produkt.
- **Transport-Schicht austauschbar halten:** Kanal-Adapter hinter einem Interface (send/receive), damit "Baileys → BSP" eine **Umstellung eines Adapters** ist, keine "Migration" des ganzen Systems. Wenn der Code das schon so trennt: sag "Umstellung", nicht "Migration".
- **Managed vor Self-Hosted**, wo es die Kern-Wertschöpfung NICHT ist (Auth, Mail, Payments, Messaging, Queues). Selbst hosten nur, wo es echten Vorteil bringt.
- **Skalierung:** zuerst horizontal-stateless + managed Datastore, dann Queue/Worker, dann Sharding — nicht "ein Prozess pro Einheit".

### 4. Ehrlicher Trade-off statt Verkaufston
Nenne bei jedem ernsthaften Vorschlag: die **empfohlene Option**, **eine Alternative**, und **was sie kostet/wo sie weh tut**. Wenn ein Ansatz nur für den Privat-/Hobby-/Owner-Fall taugt (z.B. Baileys für Cems eigene eine Nummer im Godmode) und für das Kunden-Produkt NICHT — sag genau diese Grenze dazu. "Privat okay, Produkt braucht X."

## Wenn du einen eigenen früheren Vorschlag als falsch erkennst
Nicht verteidigen. Sofort korrigieren, die Skalen-Rechnung nachliefern, die richtige Architektur nennen — und die Lehre ins Langzeitgedächtnis (`data/jarvis-knowledge.md`) schreiben, damit derselbe Reflex-Fehler nicht wiederkommt.

## Definition of Done für eine Architektur-Antwort
- [ ] Constraints (Skala, Isolation, Betreiber, offizielle API) geklärt — nicht geraten.
- [ ] Skalen-Test ×100/×1000 explizit gerechnet; keine rote Flagge im Vorschlag.
- [ ] Standard-Pattern geprüft, bevor etwas erfunden wurde.
- [ ] Empfehlung + Alternative + ehrlicher Trade-off genannt.
- [ ] Bei Kanal-/Plattform-Fragen: offizielle API bevorzugt, inoffizielle nur mit klarer Begründung + nur für Privat/Owner.
- [ ] Falls ein früherer Vorschlag revidiert wird: Lehre ins Gedächtnis geschrieben.
