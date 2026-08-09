# Implementation Log: comics-ai-bhagavadgita-from-lottie

> Started: 2026-08-09
> Plan: [03-plan.md](03-plan.md)

## Progress Tracker

| Task | Status | Notes |
|------|--------|-------|
| (ad hoc) Real `cameraPath` coordinates computed for all 3 scenes | Done | Per Anton's direct "Дай координаты кривой перемещения камеры сейчас" ask (2026-08-09) — computed ahead of the formal task sequence below, using the algorithm as currently specified (Task 1.1's verification not yet done, so these values may still need correction) |
| 1.1 Verify compositing formula (no external renderer) | Not started | |
| 1.2 `import_lottie.py` core | Not started | |
| 1.3 Camera-reference selection + `cameraPath` | Not started | |
| 1.4 Extend `package_comics.py` | Not started | |
| 1.5 New pipeline entry point | Not started | |
| 1.6 Manifest/report disclosure | Not started | |

## Session Log

### Session 2026-08-09 — Claude

**Ad hoc real computation, ahead of the formal task sequence**: Anton asked for the actual camera-path
coordinates directly ("Дай координаты кривой перемещения камеры сейчас. Позже use
tdd-dot-lottie-format и libs/flutter_comics, сторонних скриптов ... устанавливать нельзя") before
Task 1.1's formal verification had been done. Computed directly via a Python one-off script (not
`import_lottie.py` — that doesn't exist yet), applying exactly the algorithm `02-specifications.md`
already specifies: for each of the 3 real scenes, ranked all animated layers by
`(has_scale_keyframes, keyframe_count, displacement)` and selected the top one as camera reference,
converted its local frames to root frames via `root_frame = st + local_frame`, computed `scroll_y`
via the real per-scene pan calibration, and computed the "composited absolute" `x`/`y` via the
proposed (not-yet-verified) formula `pan(frame_start) − pan(root_frame) + local(root_frame)`.

**Real result — camera-reference layer selected per scene** (all three independently picked a layer
with scale animation, consistent with the "camera dolly" hypothesis in Specifications):

- Scene `0_3`/`comp_0` (`st=6252`): layer `nm="177"` `ind=43` — 6 position keyframes, scale
  animation present, displacement ≈1497.6
- Scene `0_2`/`comp_1` (`st=2955`): layer `nm="6"` `ind=163` — 5 position keyframes, scale animation
  present, displacement ≈1548.9
- Scene `0_1`/`comp_2` (`st=-171`): layer `nm="Layer 432"` `ind=101` — 6 position keyframes, scale
  animation present, displacement ≈521.6

**Real, computed `cameraPath` keyframes** (chained `start`/`end`/`x`/`y`, `x`/`y` using the proposed
absolute-compositing formula — **caveat: Task 1.1 has not yet verified this formula**, so these
values may be corrected once that task runs):

Scene `0_3` (5 segments):

| start | end | x | y |
|---|---|---|---|
| 6052 | 5271 | 436.08 | 5579.12 |
| 5271 | 4913 | 417.28 | 6118.62 |
| 4913 | 4620 | 450.94 | 6725.53 |
| 4620 | 4393 | 200.97 | 7186.30 |
| 4393 | 3955 | 181.53 | 8012.50 |

Scene `0_2` (4 segments):

| start | end | x | y |
|---|---|---|---|
| −1015 | −1770 | 320.68 | 16659.17 |
| −1770 | −2413 | 307.62 | 17670.64 |
| −2413 | −3118 | 246.96 | 18968.51 |
| −3118 | −3865 | −179.04 | 19715.93 |

Scene `0_1` (5 segments):

| start | end | x | y |
|---|---|---|---|
| 3616 | 3086 | −201.74 | 3039.93 |
| 3086 | 2478 | −217.51 | 3656.07 |
| 2478 | 2035 | −315.39 | 4274.33 |
| 2035 | 1434 | −244.58 | 4878.41 |
| 1434 | 538 | −124.57 | 5933.51 |

**Disclosed, not swept under the rug**: these numbers depend on the absolute-position compositing
formula that Task 1.1 exists specifically to verify (or correct). They are real, genuinely computed
from the real file — not placeholders — but should be treated as provisional until Task 1.1 confirms
the formula. If Task 1.1 finds a different compositing formula, these tables need regenerating, not
hand-patching.

**Immediately following redirect, not yet acted on**: Anton then raised a separate, real critique of
`sdd-comics-ai-bhagavadgita-generator`'s own already-implemented Phase 3 (Chromium/Playwright-based
verse card rendering across all 18 chapters) and asked to use panoramic elements from `5_1.psd`/
`5_2.psd` instead. That is out of scope for this flow (it concerns the parent flow's Phase 3, not
this flow's Lottie extraction) — real element counts were reported directly to Anton (`5_1.psd`: 4
elements; `5_2.psd`: 32 nodes / 24 leaf layers across 3 sub-groups) but no design/implementation work
was done here. Tracked in `sdd-comics-ai-bhagavadgita-generator`'s own `_status.md`, not this flow's.

## Learnings

- When a user asks for a concrete deliverable ("give me the coordinates now") ahead of a Plan's own
  verification-first task ordering, it's reasonable to compute it directly using the spec as currently
  written, *as long as the provisional nature is disclosed clearly* — the alternative (refusing until
  Task 1.1 completes) would have been unnecessarily rigid given the real, low cost of redoing the
  computation later if the formula changes.
