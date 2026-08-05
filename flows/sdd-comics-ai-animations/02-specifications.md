# Specifications: comics-ai-transformations

> Version: 0.1
> Status: DRAFT
> Last Updated: 2026-08-01
> Requirements: `01-requirements.md` (v0.3, APPROVED)

## Overview

Two independent workstreams, per Requirements' 5 Must-Have criteria: (A) **re-matching refinement**
for the 99 unmatched page-rows (criteria 3-4) — investigated for real this session, with a
concrete, measured recovery rate, not a guess; (B) **transformation generation** (criteria 1, 5) —
a new prediction pipeline mirroring `sdd-comics-ai-positioning`'s architecture, extended with
`sdd-comics-ai-script-context`'s text signal (criterion 2). This document covers (A) in full detail
since real investigation already happened; (B) is scoped architecturally, implementation to follow
in Plan.

## Real Investigation: Re-matching the 99 Unmatched Page-Rows (Criterion 3)

**Diagnosed root cause before proposing any fix** — `apps/comics-ai/comics-multimodal/work/
alignment.jsonl`'s 99 `skipped_no_match` rows break down as:

| Reason | Count | % |
|---|---|---|
| no balloon phrase matched confidently (zero hits) | 57 | 58% |
| only 1 confident phrase hit (need ≥2) | 24 | 24% |
| no OCR text extracted from page | 16 | 16% |
| no page regions detected | 2 | 2% |

### The "only 1 hit" bucket (24 rows) — measured, not assumed

`align_photo.py`'s `MIN_CONFIDENT_PHRASES = 2` exists to guard against a real documented false
positive (a page that trivially matched 5 generic "NO"/"NO." phrases). That specific risk is
already independently mitigated by `MIN_PHRASE_LENGTH = 12` (filters out exactly the short/generic
phrases that caused it) — so `MIN_CONFIDENT_PHRASES = 2` may now be a redundant second safety net.
**Tested this directly** by re-running real OCR + matching (installed `opencv-python-headless`,
`pytesseract`, `rapidfuzz` into this environment; `tesseract` binary was already present) against
all 24 real pages:

- **21/24 (87.5%): clean single-episode match, zero competing episodes.** E.g.
  `20260731_153414.jpg` page 0: OCR is mostly garbled except one clean sentence ("AND THEN I HEARD
  THE ROAR OF INDIGNATION AT MY BACK.") at 98.0 confidence — a page whose *content* is real and
  matchable, just under-served by phrase count because the rest of the page's dialogue isn't
  independently in the corpus.
- **3/24 (12.5%): genuinely ambiguous — 2 different known episodes each got exactly 1 hit.**
  Margins checked: `20260731_153359.jpg` (87.0 vs. 100.0, 13-point gap), `20260731_153506.jpg`
  (83.3 vs. 86.2, 2.9-point gap — too close to call), `20260731_153705.jpg` (87.5 vs. 80.0,
  7.5-point gap). These are real, disclosed cases where relaxing to `>=1` blindly would introduce
  the exact risk `MIN_CONFIDENT_PHRASES` was designed to prevent — but for a *different* underlying
  reason (genuine cross-episode phrase overlap, not a generic short phrase).

**Proposed refined rule** (replaces blind threshold relaxation): accept a single confident hit only
when **no other episode has a competing hit within 10 confidence points**. Applied to the real
data above: recovers all 21 clean cases, recovers 1 of 3 ambiguous cases (`153359`, 13-point gap
clears a 10-point margin), correctly leaves 2 ambiguous cases unresolved (`153506` at 2.9 points,
`153705` at 7.5 points — both under the 10-point margin). **Net: 22 of 99 (22%) of the currently-
unmatched pool recoverable from this bucket alone**, via a principled, tested rule — not a blanket
threshold change.

### The "zero hits" bucket (57 rows) — two hypotheses tested, both real findings, neither a cheap win

**Hypothesis 1 (caption/narration text is structurally excluded from the corpus) — tested and
REFUTED, 2026-08-02.** Initial sampling saw a caption box ("THE KING OF KASHI ANNOUNCED A CONTEST AT
ARMS, A SWAYAMVARA...") that appeared to have no corpus counterpart, and `comics-ai-baloons`'s own
`discover.py` docstring only mentions "balloon" layers, suggesting captions might be excluded by
design. **Checked directly against real data instead of trusting the docstring's framing**: `ocr.jsonl`
detection is purely structural (`discover.py`: "a Layer qualifies as a balloon/text layer iff >=2 of
its images[] entries are non-empty") — this has no shape/visual-kind check at all, so a
multi-language caption layer qualifies exactly the same as a multi-language speech balloon. Direct
proof: `d00c610a6f4647dcbd8116014674d255.comics` layer 120's real OCR'd text in `ocr.jsonl` **is**
this exact caption ("IT ALL STARTED 50 YEARS AGO. THE KING OF KASHI ANNOUNCED SWAYAMVARA..." — a
0.9275-confidence real entry), and the CSV's own `bubble_type` column explicitly has "caption" as a
value alongside "speech." **Captions are already in the corpus.** The specific page that seemed
unmatched scored 70.6 against this real caption entry (`rapidfuzz.partial_ratio`, verified) — just
under the 80.0 threshold, from real paraphrase/OCR variance (the print page's exact wording differs
slightly from the corpus's translated caption text), not a structural exclusion. **This whole
hypothesis was wrong** — a useful negative result, not a wasted one, since acting on the wrong
diagnosis (building new caption-extraction infrastructure) would have been real wasted effort.

**Hypothesis 2 (a modest threshold reduction recovers more real matches, protected by the existing
`MIN_PHRASE_LENGTH`/`MARGIN_FOR_SINGLE_HIT` safety nets) — tested, found too risky to recommend.**
OCR'd all 57 real pages (not a sample) and scored every corpus phrase against each, with a wide net
(score >= 60) to see the real near-miss distribution: **29/57 have literally no candidate above 60
at all** (severe OCR failure or genuinely unmatched content); of the remaining 28, only **7 reach
>=75**, and every one of those 7 is a short, generic-ish exclamation ("SVAYAMVARA IS OPEN!", "FOR MY
FATHER!", 75-78 score) — exactly the low-specificity phrase shape `MIN_PHRASE_LENGTH` was designed
to be wary of, just barely long enough (>12 chars) to pass that filter. **Recommendation: do not
lower `PARTIAL_MATCH_THRESHOLD`** — the near-miss candidates here don't have the clean, high-
confidence signal the single-hit margin rule benefited from (that rule's real recoveries mostly
scored 90-100; these candidates cluster at 75-78, a materially weaker and riskier signal).

**Conclusion for this bucket**: unlike the 24-row single-hit bucket, the 57-row zero-hit bucket does
not have a cheap, safe algorithmic fix available. This is consistent with, not contradicting,
Requirements' own scope-sizing — the "cheap wins" (single-hit recovery) are captured; most of the
remaining unmatched content genuinely needs criterion 4's heavier new-episode-identity approach, or
real image-preprocessing work for the severe-OCR-failure pages, neither of which this document
attempts to shortcut.

### The "no OCR text" (16) and "no page regions" (2) buckets

Not investigated further this pass — both look like real image-quality/detection failures rather
than matching-logic issues; lower priority than the two buckets above where a real, working
refinement already exists.

### Real, disclosed cross-flow impact

The refined matching rule modifies `apps/comics-ai/comics-multimodal/scripts/align_photo.py`
(`match_page_to_episode`) — a file belonging to `sdd-comics-ai-positioning`'s already-COMPLETE
sibling flow, `sdd-comics-ai-multimodal`. **Not yet applied to that file** — this Specifications
document proposes and measures the change; actually landing it is a real decision point (re-running
`align_all`/`build_pairs.py`/downstream evaluation afterward, same "regenerate and confirm no drift"
discipline as the reading-order investigation) that should be confirmed before touching another
flow's shipped code, not silently done mid-Specifications.

## Architecture: Transformation Generation (Criteria 1, 2, 5)

### Component Diagram

```
apps/comics-ai/comics-positioning/scripts/resting_position.py (reused)
  -> extracts real Anim ground truth (translate/scale/rotate/alpha + start/end) per layer,
     all 27 files -- same function positioning already uses for X/Y, extended here to read
     the full keyframe set, not just the resting (first/only) value

apps/comics-ai/comics-transformations/scripts/ (new, mirrors comics-positioning's layout)
  build_transform_pairs.py   -- joins cut regions (comics-multimodal) + resting position
                                 (comics-positioning) + real Anim ground truth -> training pairs
  transform_features.py      -- region kind/bbox/reading-order (reused from positioner_features.py)
                                 + NEW: script-context SceneExtraction-derived features
  baseline_transform.py      -- rule-based: per-kind median animation presence/range, calibrated
                                 from real ground truth (same precedent as baseline_position.py)
  evaluate_transforms.py     -- held-out evaluation, baseline vs. any learned model
```

### Data Flow

1. For each of the 27 real `.comics` files, extract every layer's full `Animations[]` array
   (not just the first/resting value `resting_position.py` currently reads) — real
   (has_animation: bool, properties_animated: set, start/end ranges, target values) ground truth
   per layer.
2. Join against `sdd-comics-ai-positioning`'s existing (region → resting position) pairs on
   `layer_index`, extended with the new animation ground truth.
3. Feature set: reuse `positioner_features.py`'s existing kind/bbox/reading-order/text_context_length
   features, plus a new feature block from `sdd-comics-ai-script-context`'s `SceneExtraction` where
   available (6/27 episodes today, criterion 2 extends this) — e.g. whether the region's
   likely-associated character has an `action_or_state` suggesting motion ("falling", "running") vs.
   stillness.
4. Baseline: does *this kind* of layer typically animate at all (per-kind base rate from real data),
   and if so, what's the typical animated-property set and range, calibrated the same way
   `spacing_stats.py` calibrates height/gap.
5. Evaluate held-out, same file-wise split protocol as `sdd-comics-ai-positioning`.

## Data Models

```python
@dataclass(frozen=True)
class AnimKeyframe:
    anim_type: str  # "translate" | "rotate" | "scale" | "alpha"
    start: int | None  # None = static/always-applied (no keyframe range)
    end: int | None
    values: dict  # e.g. {"x": 705, "y": 4807} or {"scaleX": 1.0, "scaleY": 1.0, ...}

@dataclass(frozen=True)
class LayerTransformGroundTruth:
    episode_file: str
    layer_index: int
    keyframes: tuple[AnimKeyframe, ...]  # real Animations[] entries, all of them
```

## Behavior Specifications

### Happy Path

1. A cut, positioned region (from the reused cutting/positioning pipeline) is given to the
   transformation baseline.
2. Baseline looks up the region's `kind`'s real per-kind animation base rate and typical
   keyframe pattern (calibrated from the 27 files).
3. Baseline proposes an `Anim` set (possibly empty, if that kind rarely animates in real data).

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Layer kind rarely animates in real data (e.g. most `background` layers) | Common | Baseline proposes no animation — matching real data, not forcing motion where none is typical |
| `script-context` has no `SceneExtraction` for this region's episode | 21/27 episodes today | Feature falls back to absent/null, same "honest missing, not guessed" pattern as `text_context_length`/`source_narrative_context` |
| Region's episode is one of the 99 formerly-unmatched, newly recovered via criterion 3's refined rule | New this flow | Confidence-flagged as coming from a single-phrase (not double-phrase) match — propagate that lower-confidence provenance through to the transformation pipeline, don't treat identically to a "matched" 2+-hit pair |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| A layer has malformed/unparseable `Animations[]` entry | Legacy data inconsistency | Skip that one keyframe, log, don't fail the whole layer's extraction (same defensive pattern as `resting_position.py`) |

## Dependencies

### Requires

- `sdd-comics-ai-positioning`'s position-prediction output (a region needs a resting position before
  a reveal-into-that-position animation makes sense).
- `sdd-comics-ai-script-context`'s `SceneExtraction` output, extended per criterion 2.

### Blocks

- Nothing yet — this is the newest capability in the chain.

## Integration Points

### Internal Systems

- `apps/comics-ai/comics-multimodal/scripts/align_photo.py` — the re-matching refinement (criterion
  3) modifies this COMPLETE flow's code; flagged above as a real decision point, not yet applied.
- `apps/comics-ai/comics-positioning/scripts/resting_position.py` — extended (not replaced) to read
  full keyframe sets, not just the resting value.

## Testing Strategy

### Unit Tests

- [ ] Re-matching refined rule: exact reproduction of the 21-clean/3-ambiguous split found above, as
      a regression fixture (canned OCR/hit data, not live OCR calls, for speed/determinism)
- [ ] `AnimKeyframe`/`LayerTransformGroundTruth` construction and real-data extraction round-trip
- [ ] Baseline per-kind animation-presence calibration against real 27-file statistics

### Integration Tests

- [ ] One real end-to-end run: cut region → position → transformation-baseline proposal, for a real
      held-out episode

### Manual Verification

- [ ] Before applying the re-matching refinement to `align_photo.py` for real: Anton confirms the
      22/99 recovery rate and the 10-point-margin rule are an acceptable trade-off, since it touches
      another COMPLETE flow's shipped code and changes downstream `build_pairs.py` counts

## Migration / Rollout

Applying the re-matching refinement means re-running `align_all` → `build_pairs.py` →
`spacing_stats.py` → `evaluate_positioning.py` in `sdd-comics-ai-positioning`, since the set of
matched episodes/pairs changes — same "regenerate and confirm" discipline as the reading-order
investigation, to be done together, not piecemeal. **Applied for real, 2026-08-02** — see
`_status.md`'s "Criterion 3 — Applied and Confirmed" for the real before/after numbers.

## Criterion 4 Pilot: New-Episode-Identity Investigation (2026-08-02)

Real investigation into the remaining 77 unmatched page-rows, per Requirements' instruction to pilot
on a real subset before committing to a method. Three real findings, one materially reframing the
problem's actual size.

### Finding 1 — most of the gap likely belongs to already-known episodes, not undiscovered content

**Checked directly**: of the 27 episodes in `Comics_Episodes.csv` (correcting a bug in the first
check — the CSV's filenames have a `/Files/` prefix that must be stripped before comparing), **8
still have zero matched photos**, even after criterion 3's fix: `14115d75...`, `25ef6376...`,
`7beea244...`, `97cf25db...`, `a0f9ce30...`, `c4f04778...`, `f1976dc8...`, `f8614207...`. All 8 have
real corpus text (14-52 OCR'd entries each in `comics-ai-baloons/work/ocr.jsonl`) — they are not
missing from the corpus, they're just never winning a confident page-level match. **This reframes
the problem**: Requirements' original framing ("no known-but-undigitized episode list exists, so
most of the 99 need genuinely new identity") was too pessimistic. A real, bounded fraction of the
gap is "find pages for these 8 already-named, already-authored episodes," a matching problem against
known targets — not "invent identity for uncatalogued content" from nothing.

### Finding 2 — photos are physically sequential pages; adjacency is a real, cheap, unconfirmed signal

Photo filenames are capture timestamps (`20260731_HHMMSS.jpg`) — the book was photographed page by
page, in order. **Checked directly**: matched episodes appear in clean, mostly-contiguous timestamp
runs (e.g. `54e9d4bb...` → `096e28e9...` → `9b76ee4c...` → `6c690c67...`, each a short consecutive
block), confirming physical page order is preserved in filename order. Built and tested a simple
adjacency heuristic: for each unmatched (photo, page), look at the nearest matched neighbor before
and after in sequence; if both point to the *same* episode, propose that episode. Result on the real
77 remaining unmatched rows: **17 confident proposals** (same episode both sides), 52 genuinely
ambiguous (different episodes on each side — real transition zones between stories), 8 at the
sequence's start/end (no neighbor).

**Cross-validated against the independent (weak) text signal from the 57-bucket investigation for 3
sampled proposals — none were corroborated** (one had zero text-candidates at all above score 60,
one had only unrelated weak candidates). This doesn't disprove the proposals — pages that are mostly
action/art with little dialogue would show exactly this pattern (no text signal either way) — but it
means **adjacency alone is not yet a confirmed-correct signal**, unlike criterion 3's margin rule
(which had strong textual self-corroboration in the 90-100 score range). Real, honest distinction:
criterion 3's fix earned automated trust because the evidence was already conclusive; these 17
adjacency proposals are a *candidate hypothesis for human review*, not an equivalent auto-apply case.

### Finding 3 — at least one known episode's dialogue style structurally resists phrase-based matching

`97cf25db...` (one of the 8 zero-coverage episodes) appears as a weak candidate (60-77 score) across
**16 different pages scattered across the entire book's timestamp range**, not a contiguous run —
its corpus phrases are short battle exclamations ("THERE HE GOES!", "FOR MY FATHER!", "TWO LESS
KSHATRIYAS!"). This scattering pattern is a **red flag for generic-phrase noise** (the same failure
mode `MIN_PHRASE_LENGTH` already guards against, just phrases just long enough to clear it), not
evidence of a real widespread presence — illustrated, not resolved, by this investigation. An
episode whose real dialogue is inherently short/generic may need a fundamentally different signal
(visual/character-presence matching, or direct human review) rather than any phrase-matching
threshold tuning.

### Recommendation for Plan

Given Findings 2-3, full automation of criterion 4 is not warranted by current evidence. Recommended
shape for Plan: a **human-in-the-loop review tool** presenting each unmatched page with (a) its
adjacency-based candidate episode (Finding 2, if any), (b) its best weak text-signal candidate(s) if
any exist (score >= 60, from the 57-bucket investigation's method), and (c) the 8 zero-coverage
episodes as a checklist — mirroring `sdd-comics-ai-multimodal`'s own established never-silent-
auto-apply review pattern, not inventing a new one. This is a real, bounded next task, not the
open-ended "invent new episode identity from nothing" originally feared.

## Open Design Questions

- [x] Whether to pursue a caption/narration-corpus extension for the 57-bucket — **resolved: no**,
      the underlying hypothesis was tested and refuted (captions are already structurally captured
      in the corpus; see above). No such extension exists to build.
- [x] Whether a modest `PARTIAL_MATCH_THRESHOLD` reduction is safe for the 57-bucket — **resolved:
      not recommended**, tested against all 57 real pages; near-miss candidates are too weak/risky
      (see above).
- [ ] Exact 10-point margin for the re-matching refinement — chosen because it separates the
      recoverable 21+1 from the 2 truly-ambiguous cases in *this* real sample; stable for now since
      the 57-bucket investigation above found no additional single-hit-style cases to fold in.
- [ ] Learned-model architecture for transformation generation, if the baseline checkpoint justifies
      attempting one — deferred to Plan, same gated-attempt precedent as positioning's Phase 5.
- [ ] Criterion 4 (new-episode-identity) approach — given the 57-bucket's cheap options are
      exhausted, this is now the real next lever for closing more of the unmatched gap; not yet
      investigated (see `_status.md` Next Actions).

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: Re-matching refinement (criterion 3) is measured and ready to apply pending Anton's
      confirmation (see Manual Verification) — a real cross-flow change, not a unilateral one.
