# Branch-Finish, PR-Handoff & Post-Merge-Retest

> **Zweck:** Nach SHIP (P6) und Rollout-Plan (P7.0) ist der lokale Work fertig — aber die Lieferung an Repo/Team noch nicht. Diese Phase deckt die Grenze zwischen „ich hab fertig" und „der Code lebt auf dem Default-Branch". Sie schließt den Lebenszyklus, den der Delivery-Report eröffnet hat.
>
> **Projekt-agnostisch (Leitplanke #0):** `git` ist universal; die PR-Erstellung ist **forge-bedingt** (GitHub/GitLab/Bitbucket/…); ohne Remote/CLI gilt das dokumentierte manuelle Handoff. Kein Git → diese Phase entfällt (`N/A`).

---

## 1. Disposition wählen (Tier-abhängig, VOR dem Push entscheiden)

| Option | Wann | Folge |
|---|---|---|
| **Lokal mergen** | klein · BEST-EFFORT · Hotfix mit Freigabe | direkt auf Default, kein Review — schnell, wenig Audit-Trail |
| **Push + PR/MR** | Standard · Risiko > BEST-EFFORT · Team-Gate | Review vor Merge, voller Audit-Trail |
| **Branch archiviert behalten** | Release-/White-Label-Branch · später mergen | bleibt als Referenz, kein sofortiger Merge |

> **Harte Regel:** **NO-FAIL** (Auth/Payment/Rollen/PII/Migration) geht in **Review (PR/MR)** — kein lokaler Merge ohne zweites Auge / schriftliche Bestätigung. Der Skill schlägt die Disposition vor oder fragt sie als Teil der einen gebündelten Rückfrage; er merged NO-FAIL nie still auf den Default.

---

## 2. Delivery-Report IST der PR-Body (keine Doppelung)

Der Delivery-Report aus P6.2 wird **wörtlich** der PR/MR-Body — er enthält bereits Contract, Coverage-Ledger, Verifikation und Rollout. Vor dem Handoff nur kurz redaktionell prüfen: Urteil = `SHIP`? Wichtigste Ledger-/Risiko-Zeilen oben zusammengefasst? Verifier-Urteil erwähnt?

Die **Commit-Message** benennt Invariante + Symmetrie-Kernpaar (nicht nur das Symptom) — wie in der DoD ohnehin gefordert.

---

## 3. Forge-Handoff (wenn PR/MR gewählt)

1. Branch pushen: `git push -u origin <branch>` *(universal)*.
2. PR/MR erstellen — **forge-bedingt**, mit dem Report als Body:
   - *GitHub:* `gh pr create --title "…" --body-file <report>` (nur wenn GitHub-Remote + `gh` vorhanden).
   - *GitLab:* `glab mr create …` · *Azure:* `az repos pr create …` · *Bitbucket:* Web/CLI.
3. **Fallback (kein passendes CLI / kein Remote):** **manuelles Handoff** — Report + Diff/Patch (`git diff <base>..<head>`) in Ticket/Chat/Mail posten. **Gleich bindend**, nur weniger automatisiert.

> Nie raten, welcher Forge vorliegt — aus dem Remote (`git remote -v`) ableiten; passt nichts, manuelles Handoff.

---

## 4. Post-Merge-Retest (Pflicht bei NO-FAIL, empfohlen ab Risiko-Signal)

> **Warum:** Lokales `/verify` auf dem Feature-Branch beweist *dort*. Nach Merge in den Default können: schlecht aufgelöste Konflikte (auch ohne Konflikt-Meldung), andere Dependencies/CI-Effekte, Integrations-only-Bugs auftreten.

1. Auf den Default syncen, Merge bestätigen (`git checkout <default> && git pull`).
2. **Nur die kritischen Verifikationsstufen aus Phase 5 wiederholen** (nicht die volle Suite — Zeit sparen):
   - [ ] **Spot-Check** der 3–5 wichtigsten Ledger-Stellen (Symmetrie-Paare, Cross-Layer-Kopplungen) — Merge-Konflikt in einer davon?
   - [ ] **Real-Stack-Smoke** des Hot-Path der neuen Aktion (kein voller E2E).
   - [ ] **Invarianten** (P2.2) einmal real triggern, wenn Code dafür existiert.
3. Spot-Check grün → fertig. Rot → **Merge lokal reverten, Root-Cause** (`systematic-debugging.md`), nicht raten.

> **Entfällt nur**, wenn: konfliktfreier Fast-Forward-Merge **oder** reiner Read-only-Change ohne State-Schreibvorgang **oder** winziger Diff ohne Auth/Payment/State-Bezug.

---

## 5. Abschluss-Checkliste (P7.1)

- [ ] Disposition gewählt (lokal / PR-MR / Archiv) und tier-konform (NO-FAIL → Review)
- [ ] Report als PR/MR-Body **oder** dokumentiertes manuelles Handoff
- [ ] Commit-Message benennt Invariante + Reverse-Pfad
- [ ] Post-Merge-Retest durchgeführt (oder begründet entfallen)
- [ ] Branch-Cleanup entschieden (lokalen/Remote-Branch löschen oder bewusst behalten)
- [ ] Wirksamkeits-Signal (P7) im Report festgehalten
