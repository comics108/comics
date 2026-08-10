# Status: vdd-comics-editor-camerapath-zdepth-uiux

## Current Phase

REQUIREMENTS

## Phase Status

DRAFTING

## Last Updated

2026-08-10 by Codex

## Blockers

- Requirements review and resolution of the primary camera-authoring interaction.

## Progress

- [x] Flow created (2026-08-10)
- [x] Existing camera/depth format, shared library, viewer, scroll, Properties, and timeline context
      consolidated into Requirements v0.1 (2026-08-10)
- [ ] Requirements approved
- [ ] Visual drafted
- [ ] Visual approved
- [ ] Specifications drafted
- [ ] Specifications approved
- [ ] Plan drafted
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- Shared camera/depth data and evaluator are already implemented; this flow owns editor authoring
  and visualization, not schema or rendering-math reinvention.
- Default product context is vertical-scroll comic strip in portrait, with horizontal/landscape
  affordances future-disabled.
- Properties follow `General / Selection / Document`; `zDepth` belongs to Selection and camera path
  belongs to Document unless Requirements review changes that information architecture.
- Viewer is result-only. Authoring controls exist only in Editor mode, while both modes render the
  same scroll/camera/depth result.
- Desktop numbers remain visible/editable beside sliders; phone precise editing opens in one action.

## Fork History

N/A — new flow.

## Next Actions

1. Review `01-requirements.md` v0.1 and resolve its five UI/UX questions.
2. Say `requirements approved` when the scope is correct; only then draft full cross-device ASCII
   Visuals and states.
