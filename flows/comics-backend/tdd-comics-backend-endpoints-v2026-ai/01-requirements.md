# Requirements: comics-backend-endpoints-v2026-ai

> Version: 0.2 (four foundational decisions made via discussion, 2026-08-07 — see "Decisions" below;
> superseded the corresponding Open Questions in v0.1)
> Status: DRAFT — core shape decided, refining acceptance criteria before requesting approval
> Last Updated: 2026-08-07

## Decisions (made via discussion, 2026-08-07)

1. **Art strategy (Category D priority order)**: reuse existing art first, generate only as a last
   resort. Order: (1) existing PSD/asset-bank illustration mapped to the chapter/scene, (2) a
   segmented region from a real scanned book that matches, (3) `gpt-image-2` generation, only if
   authorized and nothing in (1)/(2) exists, (4) deterministic text-only card (today's
   bhagavadgita-generator baseline) as the final fallback. `gpt-image-2`'s cost/review/safety gates
   (from its own draft Requirements) apply in full — this flow does not get a shortcut around them.
2. **Execution model**: async job submit + poll status for every stage, not just the slow ones.
   One consistent contract (`POST .../jobs` → job id, `GET .../jobs/{id}` → status/result) across
   the whole API, rather than a mix of sync and async shapes.
3. **Implementation scope**: real working Express routes now, invoking the real Python pipelines —
   not a yaml-only paper contract. Matches this repo's own `v2026`/`v2026-admin` convention (yaml
   documents what's really running).
4. **Book/dataset scope**: generic — not Bhagavad Gita-only, and not limited to books that already
   have a structured dataset (like the Gita's CSVs). Anton's own framing: **"может быть инструментом
   для любого нового художника и любой новой книги"** (can be a tool for any new artist and any new
   book). This means Category A (Source Ingestion) must accept a genuinely new book with *no*
   pre-existing structured data at all — raw scans/manuscript/art only — not just already-CSV-shaped
   input like the Gita dataset. It also means this API's audience includes a human artist/producer
   working interactively (e.g. from the Comics Editor app or a future admin UI), not only an
   unattended batch pipeline.

## Origin

Follows directly from `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/` (COMPLETE except one
manual verification step). That flow's real, generated 18-chapter output is text-forward: a
title card + one rendered Sanskrit/transcription/Russian card per verse, on a flat deterministic
color field, all produced via headless Chromium screenshots. Only chapter 5 has real illustrated
art (3 pre-existing PSD paintings composited in as-is).

Anton's feedback on that result: he expected substantially more visual art in the output, at a
density closer to `dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1` (a real, professionally
produced "Meditation of the Bhagavad Gita" experience — inspected this session: a 20MB Lottie
animation whose `assets` array embeds dozens of hand/professionally-illustrated raster images per
scene, plus music/translation side-files). That reference is in `.lottie` format, cited only for its
**art density**, not as a format target — the deliverable must remain `.comics`. His explicit
constraint: **"нельзя просто сделать скрины из chromium"** (must not just be Chromium screenshots).

This new flow's ask: design (and this session, discuss) a backend HTTP API — a new OpenAPI YAML
under this repo's real `v2026` convention (`apps/comics-backend/node/src/docs/`, paired with real
Express routes per that convention's existing precedent — `v2026-admin.yaml` ↔
`routes/v2026/admin/*.js`) — that exposes **every AI capability already built or drafted across
`comics-ai`** as composable pipeline stages, covering the full path from raw source data to a
finished `.comics` file, including real illustrated art, not text-only cards.

## Real Inventory of Existing comics-ai Capabilities (verified this session, 2026-08-07)

| Flow | App | Status | Real capability |
|---|---|---|---|
| `sdd-comics-ai-multimodal` | `comics-ai-multimodal` | IMPLEMENTATION (effectively complete) | Segments a flattened source page image into kind-tagged regions (`art`/`balloon`/`character`) with bounding boxes; a reopened decision (not yet resolved by Anton) considers upgrading to YOLO11-seg for real per-pixel bitmasks instead of just boxes |
| `sdd-comics-ai-positioning` | `comics-ai-positioning` | IMPLEMENTATION | Recomposes multimodal's cut regions into a finished continuous vertical-strip `.comics` layout (the inverse of cutting) |
| `sdd-comics-ai-story-script` | `comics-ai-script-context` | IMPLEMENTATION | LLM (local Ollama) narrative-text → structured pseudo-script with named entities/scenes, feeding the cutter/positioner |
| `sdd-comics-ai-baloons` | `comics-ai-baloons` | IMPLEMENTATION | Re-renders speech-balloon text into a new language inside the *existing* balloon shape (OCR + Playwright HTML shaping), without needing new art |
| `sdd-comics-ai-animations` | `comics-ai-animations` | IMPLEMENTATION | Full-book real coverage: matches existing scanned-book pages to episodes and fills previously-unmatched gaps; internally still named "transformations" in some docs (known drift) |
| `sdd-comics-ai-bhagavadgita-generator` | `comics-ai-bhagavadgita-generator` | COMPLETE (bar one manual step) | Raw CSV dataset → deterministic text cards (Playwright) + optional chapter-5 PSD reuse → 18 `.comics` files. **This is the flow whose text-only output triggered this new ask.** |
| `sdd-comics-ai-gpt-image-2` | *(no app yet — DRAFT, not started)* | REQUIREMENTS (awaiting approval) | The one flow that actually targets **generating new illustrated art** (via OpenAI's `gpt-image-2`), with real cost/review/safety gates already drafted (dry-run budget, human accept/reject, credential safety, no-baked-text-in-image rule, provenance) |

**Key structural fact this table makes visible**: of the six *built* capabilities, none generates
net-new illustration. Five reuse/recompose/re-letter *existing* art (from real scanned books or
real PSD files); one (bhagavadgita-generator) has almost no existing art to reuse (only chapter 5)
and falls back to text-only cards. The only flow that would produce new art for the other 17
Bhagavad Gita chapters (`sdd-comics-ai-gpt-image-2`) is still an unapproved draft. This is the real
gap behind Anton's feedback — not a bug in the generator, a missing capability in the pipeline.

## Problem Statement

There is no unified backend surface over these seven capabilities. Each exists only as a
standalone Python CLI script (`scripts/*.py`) inside its own `apps/comics-ai/*` directory, with its
own `.venv`, invoked ad hoc by a human or an agent session. There is no way to:

- submit raw source material (a book's scanned/photographed pages, a structured dataset like the
  Gita CSVs, existing hand-drawn art) through an HTTP API and get a pipeline job back;
- ask, for a given chapter/page, "is there real existing art for this, and if not, what are my
  options" (reuse via segmentation, reuse via PSD/asset bank, or generate via `gpt-image-2`);
- run any AI stage (script/storyboard generation, cutting, positioning, balloon re-lettering, art
  generation) independently, with a documented contract for what happens when its expected input is
  absent (no source image, no existing art, LLM unavailable, art-gen budget exhausted, etc.);
- compose stages into a full raw-data → `.comics` pipeline through one orchestrating endpoint, with
  the kind of resumable/idempotent/never-block-on-one-failure semantics the bhagavadgita-generator's
  own `pipeline.py` already proved out at the Python-script level this session.

## User Stories

### Primary

**As a** comics producer (Anton)
**I want** one backend API that can take raw source material for any book/chapter and run it
through cutting/positioning/script/balloon/art-generation stages in whatever combination the real
available inputs allow
**So that** producing a visually rich `.comics` file doesn't require me to know which of six
separate Python scripts to run by hand, in what order, with what fallback when something's missing.

### Secondary

- **As a** cost owner, **I want** the art-generation endpoints to expose the same dry-run/budget/
  review gates already designed in `sdd-comics-ai-gpt-image-2`'s requirements, **so that** no
  endpoint can trigger uncontrolled paid API spend.
- **As an** API consumer (another internal tool, or a future admin UI), **I want** a documented,
  typed contract for every "what if the input is missing" case, **so that** I can build a UI or
  automation against this without reverse-engineering each Python script's real behavior.
- **As a** future maintainer, **I want** this API to expose *existing* capabilities faithfully
  (matching what the real scripts actually do today, not aspirational behavior), **so that** the
  yaml contract doesn't promise something the current implementation can't deliver.

## Proposed Endpoint Categories (v0.2 — updated per the Decisions above)

Grouped by pipeline stage, mirroring the real inventory above. **Every** category uses the same
async job contract (`POST .../jobs` → `{jobId, status: "queued"}`; `GET .../jobs/{jobId}` →
status/progress/result/error), per Decision 2 — not just the slow stages, so API consumers never
have to remember which stages happen to be fast today. Each category also needs a documented
**input-presence matrix**: what happens when the thing this stage needs isn't there.

**A. Source Ingestion** — submit raw material for a book/chapter and get back a canonical
parsed/validated representation. Per Decision 4, must accept three real tiers, not just the
CSV-shaped case: (1) an already-structured dataset (like the Gita CSVs), (2) a scanned/photographed
page set with no structure yet (like the Mahabharata boranko pages), (3) a genuinely new book with
*only* raw manuscript text and/or raw art files and no prior structure at all — the "any new artist,
any new book" case. *No source at all* → reject with a clear error, never fabricate placeholder
content. *Ambiguous/unparseable structure* → reject with a specific diagnostic, never silently guess.

**B. Script / Storyboard Generation** — narrative text → structured scene script. Variants:
deterministic (no LLM) vs. Ollama-backed. *LLM unavailable/times out* → fall back to deterministic,
record a warning, never block. *No narrative text at all yet* (an artist has only raw art, no
script) → this stage is skippable, not required — Category D can still run against art-first input.

**C. Segmentation / Cutting** — flattened source image → kind-tagged regions (bbox today; bitmask
pending the reopened YOLO-seg decision, gated separately — see Open Questions). *No source image*
→ not applicable, stage is skipped, not an error.

**D. Art Sourcing** — decided priority order (Decision 1), now the core contract of this category:
given a chapter/scene, try in order (1) an existing PSD/asset-bank illustration mapped to it, (2) a
matching segmented region from a real scanned book (Category C's output), (3) `gpt-image-2`
generation — only if authorized and (1)/(2) found nothing — carrying that flow's full cost/review/
safety gate contract, (4) deterministic text-only card as the final, always-available fallback. The
endpoint must report *which* tier actually produced the result, never just "art" with no
provenance.

**E. Balloon / Text Rendering** — render (possibly translated) text into a balloon shape, reusing
an existing balloon shape from a segmented region when one exists. *No existing balloon shape* —
still an open question (generate a default shape vs. require Category D/art-sourcing to have
placed one first) — see Open Questions.

**F. Positioning / Layout** — arrange whatever combination of background/art/balloon layers a
chapter ended up with into the final continuous-strip layout, generalizing
bhagavadgita-generator's `layout_chapter.py` beyond a fixed text-card-only shape.

**G. Packaging / Export** — assemble the final `.comics` ZIP (tiling + `data.json`), reusing the
proven contract (`Cultures` slot indexing, tile filename convention) established across every prior
flow, generalized to arbitrary art/balloon layer mixes rather than only title+verse cards.

**H. Validation** — structural/fidelity checks on a produced archive, generalizing
bhagavadgita-generator's `validate_output.py` beyond its Gita-specific verse-count check.

**I. Pipeline Orchestration** — one top-level "generate this chapter/book" job chaining A-H end to
end for whatever real inputs are actually available, plus job status/history, matching
bhagavadgita-generator's own `pipeline.py` fingerprint-based resumability (never redo unchanged
work; never let one chapter's failure block the batch) — now as the real async-job contract from
Decision 2, not a CLI process.

## Acceptance Criteria

### Must Have

1. **Given** a book/chapter with an already-structured dataset (like the Gita CSVs), **when** it's
   submitted to Category A, **then** a canonical parsed representation is produced and a job id is
   returned; polling the job reaches a terminal `succeeded` state with the parsed data attached.
2. **Given** a brand-new book with only raw manuscript text and/or raw art files and no prior
   structure, **when** it's submitted to Category A, **then** ingestion still succeeds (the "any new
   artist, any new book" case is real, not aspirational) — no endpoint may assume a CSV-shaped input
   exists.
3. **Given** a chapter with an existing PSD or asset-bank illustration mapped to it, **when**
   Category D (Art Sourcing) runs, **then** that existing art is used and the result reports tier
   `existing-psd` (or equivalent) — `gpt-image-2` is never called when existing art already covers
   the chapter.
4. **Given** a chapter with no existing art and no matching segmented region, **when** Category D
   runs with generation authorized, **then** it invokes `gpt-image-2` under that flow's full
   cost/review/safety gate contract (dry-run estimate first, human accept/reject before any asset is
   packaged, credentials never logged/stored in the response) — this flow does not shortcut those
   gates.
5. **Given** a chapter with no existing art, no matching segmented region, and generation not
   authorized (or the budget/review gate not cleared), **when** Category D runs, **then** it falls
   back to a deterministic text-only card and reports tier `deterministic-fallback` — never blocks
   the pipeline and never silently fabricates art.
6. **Given** any job-producing endpoint, **when** a client polls its status, **then** the response
   distinguishes `queued`/`running`/`succeeded`/`failed` and a `failed` job carries a real,
   actionable error, never a silently-empty result.
7. **Given** the full orchestration endpoint (Category I) run over a multi-chapter book, **when**
   one chapter's stage fails, **then** the batch continues to the remaining chapters and the final
   report lists per-chapter status individually — matching `pipeline.py`'s own proven
   continue-after-failure semantics.
8. **Given** an unchanged chapter already successfully processed, **when** the orchestration
   endpoint is re-run without a force flag, **then** it's reused, not reprocessed — matching
   `pipeline.py`'s own proven fingerprint-based idempotency.
9. Every new route has a matching OpenAPI path in the new yaml, following this repo's
   `v2026-admin.yaml` conventions (tags, `$ref` component reuse, the standard success/error
   envelope), and is served through the existing `swagger-ui-express` setup.

### Should Have

- A "what would happen" dry-run/preview mode for Category D that reports which tier *would* be
  used for a chapter without actually running generation or spending budget.
- A way to list, per book, which chapters have real existing art available vs. which would need
  `gpt-image-2` (a coverage/gap report, conceptually extending `report.md`'s pattern).
- Webhook/callback support as an alternative to polling, for long-running jobs.

### Won't Have (This Iteration)

- Resolving the YOLO11-seg/AGPL licensing question itself (stays `sdd-comics-ai-multimodal`'s and
  Anton's own open call) — Category C ships bbox-only until that's separately resolved.
- A public-facing (non-internal) version of these endpoints; this is a producer/artist tool, not a
  consumer-facing API surface like `/public`.
- Building `sdd-comics-ai-gpt-image-2` itself if it isn't approved yet — Category D's generation
  tier depends on that flow existing and being approved; until then, Category D's first three tiers
  (existing art, segmented reuse, fallback) are still real and shippable on their own.

## Constraints

- Must not regress or silently replace the already-COMPLETE bhagavadgita-generator baseline; any
  art-enrichment path must be additive/optional, matching `sdd-comics-ai-gpt-image-2`'s own
  explicit non-goal ("Replacing the primary flow's deterministic chapter generation").
- `gpt-image-2` endpoints must carry the cost/review/safety gates already designed in that flow's
  Requirements (dry-run budget, human accept/reject, credential safety, no baked-in text, grounded
  citations) — this new flow does not get to relax those by building a shortcut HTTP path around
  them. If that flow isn't approved yet when this one reaches Implementation, Category D's
  generation tier is stubbed/deferred, not built around its own separate (weaker) gate.
- The six built Python capabilities each run in their own per-app `.venv` with different real
  dependencies (Playwright/Chromium, psd-tools, Ollama, OpenCV/torch for segmentation). Given
  Decision 3 (real routes now) and Decision 2 (async jobs), the real invocation mechanism (spawned
  subprocess per job? a persistent worker process pool? a small internal Python job-runner service
  the Node backend calls?) is a concrete architecture decision Specifications must make — not
  decided here, but now scoped as a Specifications-phase question, not an open Requirements one.
- `dataset/` stays read-only everywhere, per every prior flow's own constraint; new raw uploads
  (Decision 4's "any new book" case) need their own writable location, analogous to `work/`.

## Open Questions (remaining — narrower than v0.1's list)

- [ ] Auth/security model for these endpoints (`bearerAuth` like `/admin`? a separate internal-only
      scheme, given these can trigger paid external API calls and long-running local compute?).
- [ ] Real invocation mechanism for the underlying Python pipelines (subprocess-per-job vs. worker
      pool vs. internal service) — flagged above as a Specifications-phase decision.
- [ ] Category E: when no existing balloon shape exists for a chapter/scene, generate a default
      shape, or require Category D/art-sourcing to have already placed one?
- [ ] Job persistence/history: in-memory only (lost on server restart) or backed by real storage
      (a table, a file-based queue)? Affects whether "resumability" survives a server restart, not
      just a single run.
- [ ] What's the minimum real metadata an "any new book" (Decision 4, tier 3) submission must
      include — book title and language at minimum? Fully freeform, or a small required schema?

## References

- `flows/comics-ai/sdd-comics-ai-bhagavadgita-generator/` (the flow whose result prompted this one)
- `flows/comics-ai/sdd-comics-ai-gpt-image-2/` (draft; owns the actual new-art-generation gate design)
- `flows/comics-ai/sdd-comics-ai-multimodal/`, `sdd-comics-ai-positioning/`, `sdd-comics-ai-story-script/`,
  `sdd-comics-ai-baloons/`, `sdd-comics-ai-animations/`
- `apps/comics-backend/node/src/docs/v2026-admin.yaml` (real convention this new yaml should follow)
- `dataset/bhagavadgita/vaishnav/bhagavadgita_lottie/unzip/1/` (art-density reference, format not targeted)

---

## Approval

- [ ] Reviewed by: Anton
- [ ] Approved on:
- [ ] Notes:
