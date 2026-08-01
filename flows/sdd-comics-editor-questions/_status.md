# Status: sdd-comics-editor-questions

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING (parked — this is a consolidated backlog, not an active build; nothing to draft further
until a real stakeholder session happens)

## Last Updated

2026-08-01 by Claude

## Blockers

- Every question in `01-requirements.md` still needs a real conversation with Джанава (Евгений
  Корытный) and Бхагаван (identity in this context not yet clarified) to resolve for real. No
  amount of further drafting here substitutes for that — see 2026-08-01 note below on what *has*
  changed without a stakeholder session happening.

## Progress

- [x] Requirements drafted (2026-07-30) — consolidation of questions extracted from
      `vdd-comics-editor-jhanava`, not an original elicitation
- [x] Requirements updated (2026-08-01) — annotated each Group A/B question against completed work
      (`sdd-comics-ai-multimodal`, `vdd-comics-editor-ai-uiux`) as ANSWERED-IN-PRACTICE / EVIDENCED
      / STILL OPEN. No question is closed — this is not a substitute for the real session.
- [ ] Requirements approved — not applicable; see Acceptance Criteria in `01-requirements.md` for
      this flow's actual "done" condition (questions answered, not a doc approved)
- [ ] Specifications drafted — not applicable to this flow's purpose
- [ ] Plan drafted — not applicable to this flow's purpose
- [ ] Implementation started — not applicable to this flow's purpose

## Context Notes

- **Purpose**: pure question backlog, not a feature spec. Exists so `vdd-comics-editor-jhanava`
  could keep moving without reading as "blocked on everything" — the genuinely unresolved,
  stakeholder-dependent questions live here instead of inline in that flow's requirements doc.
- Two source groups: (A) Джанава's kind-taxonomy/material-intake framing, (B) Бхагаван's
  `comics_video_sample` video-comic example. Kept as separate groups in `01-requirements.md` since
  they may get resolved in separate conversations.
- This flow's SDD phase machinery (Specifications/Plan/Implementation) doesn't really apply — it's
  being used here purely for its "durable, resumable document with a status file" shape, not for
  its usual build-a-feature purpose.

## Fork History

- Extracted from `flows/vdd-comics-editor-jhanava/01-requirements.md`'s "Open Questions" section on
  2026-07-30, per explicit user request ("вынеси все вопросы без ответа в
  sdd-comics-editor-questions и продолжи текущий vdd вынеся их за скоуп").

## Next Actions

1. Group B (video/motion-comic, Бхагаван) still needs a real session — untouched.
2. **2026-08-01, same day, two updates**:
   a. Re-surveyed all `sdd-*`/`vdd-*` flows against this backlog since two large builds landed:
      `sdd-comics-ai-multimodal` (cutting/segmentation pipeline, complete) and
      `vdd-comics-editor-ai-uiux` (in-editor review UI for it, in progress). Tagged 4 of 7 Group A
      questions with a de facto engineering answer or real evidence.
   b. **Real answer received directly (Anton), covering 3 questions at once**: what "raw source
      material" looks like (hand-drawn paneled paper original), and what "character/background
      placement" actually means (not simple placement — creative recomposition of paneled/scened
      paper art into one continuous vertical strip, with AI proposing layouts when the human cutter
      doesn't know how, trained on prior human cutters' work). This also explains a previously
      unexplained finding from `sdd-comics-ai-multimodal` (paginated print vs. scrolling digital
      canvas mismatch) and reframes its existing photo↔`.comics` alignment data as reusable training
      signal for a not-yet-built AI recomposition/layout capability. Routed into
      `vdd-comics-editor-jhanava/01-requirements.md`.
3. Still open, needs a real session: all of Group B, plus the *mechanics* of background continuity
   (parallax/tiling/retouch — the "how", not the "what" anymore) and the sound-layer-kind vs.
   audio-Sounds-list ambiguity.
4. **2026-08-01, same day, third update**: verified three technical claims against real code
   (`Layer.cs`/`TranslateAnim.cs`, `FileManager.cs`/`ImagePathConverter.cs`,
   `TileImageView.java`) rather than accepting them from memory. Confirmed: no layer-grouping
   concept exists (manual X/Y calibration between layers is real); 512×512 tiling exists for
   viewport-virtualized smooth rendering, but in the **mobile viewer**, not the editor. Corrected:
   512×512 tiling itself is fully automatic (slice-on-save/stitch-on-load), never something a
   "нарезатор" manually reassembles. Surfaced a new gap: no per-panel scene-description text source
   exists anywhere in `dataset/` — character identity and photo↔page ordering both run on weak
   heuristics/dialogue-OCR as a result, not by design choice. Added as a new Group A open question
   (does such a source exist upstream, just not yet in `dataset/`?). Full detail in
   `01-requirements.md`'s "Technical Verification (2026-08-01, continued)" section.
5. **2026-08-01, fourth update, same day**: checked point 4 above against real data instead of
   leaving it as an assumption — searched `spiritual_text/` for episode 21 (`21_ambas_plea`, the
   validated character-library example) and found real, scene-matching narrative prose *with direct
   speech* ("...permitted Amba... 'At heart I had chosen the king of Saubha for my husband...'"),
   plus nearby physical character descriptions (Ambika/Ambalika). **Revises the previous finding**:
   usable grounding text already exists in `dataset/` for at least this case — it was never used
   because text→`.comics` was deprioritized/deferred, not because the data is missing. Real caveat
   found in the same pass: this text file is "Book 1-3" only; the file's own table of contents points
   Amba's continued story to Book 5 (Udyoga Parva), not included — so coverage isn't guaranteed
   complete per episode. Reframed the relevant Group A question from "ask Джанава whether this data
   exists" to "spike whether automatic text↔episode alignment is feasible" — an engineering question,
   not a stakeholder one, for at least this specific gap.
