# Implementation Plan: comics-editor-publish

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-07-31
> Specifications: [02-specifications.md](02-specifications.md)

## Summary

Four independent workstreams, ordered by risk/dependency: README screenshots first (lowest risk,
pure copy + doc edit, zero CI/credentials involvement); iOS + Android screenshot wiring next (real
config changes, but to already-working lanes with already-configured credentials); macOS lane last
(new infrastructure, has real prerequisites outside the agent's reach — Apple Developer/App Store
Connect access — so its own task explicitly separates "what the agent can do" from "what needs the
user to do manually," rather than blocking the whole flow on it).

## Task Breakdown

### Phase 1: README screenshots

#### Task 1.1: Verify and pick the 3-image subset
- **Description**: Visually inspect all 6 `design/dc/screenshots/*.png` to confirm `board2-4.png`
  are genuinely redundant with `board.png` (Specifications' assumption, not yet confirmed) before
  finalizing which 3 ship in the README.
- **Files**: None (inspection only)
- **Dependencies**: None
- **Verification**: Read each image; confirm the chosen 3 are visually distinct from each other
- **Complexity**: Low

#### Task 1.2: Copy images + write README section
- **Description**: Copy the chosen 3 PNGs into a new `apps/comics-editor-v2.9/screenshots/`
  directory; add a `## Screenshots` section to `README.md` referencing them with captions.
- **Files**:
  - `apps/comics-editor-v2.9/screenshots/*.png` - Create (3 files)
  - `apps/comics-editor-v2.9/README.md` - Modify
- **Dependencies**: Task 1.1
- **Verification**: Markdown renders correctly (relative image paths resolve within the repo);
  no existing README content disturbed
- **Complexity**: Low

### Phase 2: iOS screenshots

#### Task 2.1: Copy screenshots into `ios/fastlane/screenshots/`
- **Description**: Copy `design/store/appstore-01/02-1290x2796.png` into all 5 locale folders per
  Specifications §1's layout.
- **Files**:
  - `ios/fastlane/screenshots/{ru,en-US,zh-Hans,hi,th}/appstore-0{1,2}.png` - Create (10 files)
- **Dependencies**: None
- **Verification**: `find ios/fastlane/screenshots -type f | wc -l` == 10; each file's pixel
  dimensions match the source (no accidental re-encoding)
- **Complexity**: Low

#### Task 2.2: Un-skip screenshots in `ios/fastlane/Fastfile`
- **Description**: Remove `skip_screenshots: true` from the `appstore` branch's `deliver(...)` call.
- **Files**:
  - `ios/fastlane/Fastfile` - Modify
- **Dependencies**: None (independent of 2.1, but both needed together for the lane to actually work)
- **Verification**: Diff review — only that one line removed, `testflight` branch untouched
- **Complexity**: Low

### Phase 3: Android screenshots

#### Task 3.1: Copy screenshots into `android/fastlane/metadata/android/`
- **Description**: Copy `googleplay-01-1440x2560.png` (phone) and `googleplay-cover-1024x500.png`
  (feature graphic) into all 5 locale folders per Specifications §2's layout.
- **Files**:
  - `android/fastlane/metadata/android/{ru-RU,en-US,zh-CN,hi-IN,th}/images/phoneScreenshots/1.png` - Create (5 files)
  - `android/fastlane/metadata/android/{ru-RU,en-US,zh-CN,hi-IN,th}/images/featureGraphic.png` - Create (5 files)
- **Dependencies**: None
- **Verification**: `find android/fastlane/metadata/android -type f | wc -l` == 10; dimensions match source
- **Complexity**: Low

#### Task 3.2: Un-skip images in `android/fastlane/Fastfile`
- **Description**: Remove `skip_upload_images: true, skip_upload_screenshots: true` from
  `upload_to_play_store(...)`.
- **Files**:
  - `android/fastlane/Fastfile` - Modify
- **Dependencies**: None
- **Verification**: Diff review — only those lines removed
- **Complexity**: Low

### Phase 4: macOS App Store release lane

#### Task 4.1: `macos/fastlane/Appfile` + `Fastfile`
- **Description**: Create both files per Specifications §3, mirroring `ios/fastlane/`'s structure
  and header-comment documentation style (including the "before first real release" manual
  prerequisites list).
- **Files**:
  - `macos/fastlane/Appfile` - Create
  - `macos/fastlane/Fastfile` - Create
- **Dependencies**: None
- **Verification**: `bundle exec fastlane macos deploy` -- **cannot run** (no macOS Developer
  credentials / match repo access available to the agent). Verification limited to: Ruby syntax
  is valid (`ruby -c`), structural comparison against the working `ios/fastlane/Fastfile` pattern
  it mirrors, and lane options match Specifications exactly.
- **Complexity**: Medium (new file, but directly mirrors an existing working pattern — not novel design)

#### Task 4.2: `macos/fastlane/screenshots/<locale>/macos-01.png`
- **Description**: Copy `design/store/pc-01-1440x900.png` into all 5 locale folders.
- **Files**:
  - `macos/fastlane/screenshots/{ru,en-US,zh-Hans,hi,th}/macos-01.png` - Create (5 files)
- **Dependencies**: Task 4.1 (directory structure)
- **Verification**: 5 files present, dimensions match source (1440x900 — already a valid Mac App
  Store screenshot size, no resize needed)
- **Complexity**: Low

#### Task 4.3: New `release-macos` job in `release.yml`
- **Description**: Add the job per Specifications §3, mirroring `release-ios`'s structure minus
  the Android-style credential-decoding step (match handles signing entirely).
- **Files**:
  - `.github/workflows/release.yml` - Modify
- **Dependencies**: Task 4.1
- **Verification**: YAML parses (`python3 -c "import yaml; yaml.safe_load(open('...'))"` or
  equivalent); job structure diffed against `release-ios` for consistency; **cannot verify the job
  actually succeeds** — needs a real `workflow_dispatch` run by the user after prerequisite 2
  (match macOS cert seeding) is done, which is entirely outside this flow's/agent's reach
- **Complexity**: Low

## Dependency Graph

```
1.1 → 1.2                      (README, fully independent)

2.1 ─┐
     ├─→ (iOS lane functional once both land)
2.2 ─┘

3.1 ─┐
     ├─→ (Android lane functional once both land)
3.2 ─┘

4.1 → 4.2
4.1 → 4.3                      (macOS lane -- NOT functional until manual prerequisites,
                                 see Specifications §3 Manual Prerequisites, are done outside this flow)
```

All four phases are independent of each other — no phase blocks another; ordered above purely by
ascending risk/verifiability, not by a real dependency requirement.

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `apps/comics-editor-v2.9/screenshots/*.png` | Create | README images (3 files) |
| `apps/comics-editor-v2.9/README.md` | Modify | New Screenshots section |
| `ios/fastlane/screenshots/<locale>/*.png` | Create | 10 files, 5 locales × 2 images |
| `ios/fastlane/Fastfile` | Modify | Un-skip App Store screenshots |
| `android/fastlane/metadata/android/<locale>/images/**` | Create | 10 files, 5 locales × 2 images |
| `android/fastlane/Fastfile` | Modify | Un-skip Play Store images |
| `macos/fastlane/Appfile` | Create | New macOS lane identity |
| `macos/fastlane/Fastfile` | Create | New macOS lane (match + build + upload) |
| `macos/fastlane/screenshots/<locale>/*.png` | Create | 5 files, 5 locales × 1 image |
| `.github/workflows/release.yml` | Modify | New `release-macos` job |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| macOS App Store record can't actually be created under the same bundle id as iOS in this Apple Developer account | Low-Medium (unverifiable without real access) | High (blocks the whole macOS lane) | Documented explicitly as a manual prerequisite the user must confirm; the agent's part (lane code) is fully written and correct regardless of this outcome — if it turns out infeasible, only the manual App Store Connect step needs revisiting, not the code |
| `match` macOS platform cert/profile never gets seeded (prerequisite 2, outside agent's reach) | Medium (real one-time manual step, easy to forget) | Medium (lane fails clearly at `match`, not silently) | Same "clear failure, not silent" pattern the Edge Cases table in Specifications already documents; no code workaround exists or should exist for a genuinely missing credential |
| `board2-4.png` turn out NOT redundant with `board.png` (Task 1.1's assumption) | Low | Low (cosmetic, easy to adjust) | Task 1.1 explicitly verifies before Task 1.2 commits to the 3-image subset |
| Locale code typos (App Store Connect vs Play Console use different strings for the same language) | Low (codes pinned exactly in Specifications, cross-checked against known fastlane/store conventions) | Medium (silent wrong-locale upload, or upload failure) | Specifications §1/§2 spell out both platforms' exact codes side by side specifically to avoid conflating them |
| None of this can be end-to-end verified without real store credentials + a real CI run | High (certain) | N/A (inherent to the task, not a bug) | Same limitation `sdd-comics-editor-build` already operates under for anything Windows/macOS-signing-related — verification is structural/local (file counts, dimensions, YAML/Ruby syntax) plus explicit user confirmation via a real `workflow_dispatch` run, not something to pretend around |

## Rollback Strategy

All changes are additive (new files) or narrow line-removals (Fastfile `skip_*` flags) — no
destructive changes to existing working lanes. Reverting any single phase is independent of the
others (per the Dependency Graph, nothing cross-links). If the macOS lane's manual prerequisites
never get completed, `release-macos` simply never succeeds — it doesn't affect `release-ios`/
`release-android`, which stay exactly as they work today plus their own now-un-skipped screenshots.

## Checkpoints

After each phase, verify:

- [ ] File counts match the File Change Summary exactly (no missing/extra locale folders)
- [ ] Copied image dimensions match source `design/store/`/`design/dc/screenshots/` files
      byte-for-byte where a straight copy is used (no accidental re-encoding via an image tool)
- [ ] Fastfile/workflow diffs are narrow and reviewed line-by-line (this touches real release
      credentials-adjacent config — no drive-by unrelated changes)
- [ ] `flutter analyze` / `flutter test` (full suite) still pass after README/workflow edits —
      sanity that nothing in the actual app was disturbed

## Open Implementation Questions

- [ ] None outstanding.

---

## Approval

- [ ] Reviewed by:
- [ ] Approved on:
- [ ] Notes:
