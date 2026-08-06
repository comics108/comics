# Specifications: comics-editor-uiux-lettering

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-07-30
> Requirements: [01-requirements.md](01-requirements.md)
> Visual: [02-visual.md](02-visual.md)

## Implementation finding (2026-07-30) — the Interfaces section below is wrong about RPCs

Discovered while starting implementation, by reading the real code instead of continuing to build
on the assumption below: **`ComicsCore` has no typed per-field methods at all.** It's one generic
`Future<dynamic> call(String method, Map<String, dynamic>? params)`. The entire app's mutation
pattern is: (1) mutate `EditorLayer` fields locally in memory (exactly like today's
`setImageFile`/`setImagePopup`/`toggleVisible` already do — no RPC involved), (2) on save, send the
*whole* document through the existing `saveComics` RPC (`comicsToCore(document)`), which the native
core (or `DartIoCore` on mobile) writes out by re-zipping a **working directory** it already
maintains across `openComics`→`saveComics`. That working directory's path is already returned as
`tempFolder` in both `openComics` and `ping` responses (`FileManager.TempFolder` in the C# core,
an app-support subdirectory in `DartIoCore`) — **but nothing in the Dart UI captures or uses it
today**, per `documents.dart`'s `comicsFromCore` discarding that key.

**Consequence**: `setLayerKind`/`setLayerTranslation` need **no RPC at all** — they're local
`EditorLayer` mutations, mirroring `setImageFile`, automatically included in the next `saveComics`.
`setLayerImage` needs **no RPC either** — write the new tile PNG files directly into
`<tempFolder>/layers/` from Dart (using the same 512px-tile filename convention as everywhere else
in this codebase and in `apps/comics-ai-baloons`), then call the existing `setImageFile` with the
new filename. The only genuinely new plumbing is: (a) capture `tempFolder` from `openComics`'s
response into `CoreDocument` (currently thrown away), (b) a Dart-side tile writer.

This replaces the entire "New Interfaces" section below and most of "Affected Systems" — kept
struck through rather than deleted, so the wrong assumption and the correction are both visible.
`04-plan.md` has the corrected task breakdown; that's the one to follow, not this section.

## Revision note (2026-07-30) — this flow returns to its original plan

A product-friend consultation (Джанава / Евгений Корытный) briefly narrowed this flow's scope in
an earlier draft of this document (v0.2): 3-language cap, no Lettering mode, a 4-value kind
taxonomy. The user judged that letting one consultation narrow an already-well-designed flow was
the wrong move, and asked to:

1. **Spin Джанава's bigger-picture insight into its own flow**: `flows/vdd-comics-editor-jhanava/`
   now owns the full background/character/balloon/sound taxonomy question and the "material
   systematization" prerequisite problem. This document no longer tries to answer those.
2. **Return this flow to its original plan**: Lettering mode (a distinct page, per `02-visual.md`)
   is back in scope. Kind taxonomy here stays narrow — `balloon`/`caption`, the values this flow
   actually needs — as an open string for forward compatibility with whatever the jhanava flow
   eventually settles on, not because it's importing that flow's answer.
3. **One genuine correction, kept regardless of the revert**: language coverage must be **dynamic**
   — driven by whatever languages the data actually has, never a hardcoded count. Neither "3 is
   enough" nor "expose all ~20" is the right framing; the right framing is "however many exist."
   This is reflected throughout Data Models and Interfaces below.

## Overview

Adds balloon/lettering awareness to `apps/comics-editor-v2.9`: an additive, backward-compatible
`data.json` schema extension (layer `kind` + per-language `translations` text, both dynamic/open),
a new Lettering mode UI (per `02-visual.md`'s original design), and a client-side AI generation
contract that can route on-device or to a server (contract only — no engine built in this flow).
`dataset/`-style files opened today keep working byte-for-byte; the schema extension is additive
per the existing serializer's own defaults (verified against the real config, not assumed — see
Data Models).

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| `native/Comics.Editor/Models/{Layer,Image}.cs` | Modify | Add `Kind`, `Style`, `Translations` properties |
| `native/Comics.Editor/Models/Cultures.cs` | Unmodified | The 3-value `En`/`Ru`/`Hi` enum stays exactly as-is — `Images` indexing continues to use it for those 3; `translations` is a separate, dynamically-keyed structure that isn't bound to this enum's size (see Data Models) |
| `lib/src/ui/models.dart` | Modify | Mirror the new fields on `EditorLayer` |
| `lib/src/bridge/models_mapping.dart` | Modify | Map new fields both directions; preserve unknown-field passthrough behavior already in place via `CoreDocument.raw` |
| `lib/src/bridge/comics_core.dart` + `core_client.dart` / `dart_io_core.dart` | Modify | New RPC: `setLayerImage`, `setLayerKind`, `setLayerTranslation`; fixes the existing no-op `setImageFile`/`setImagePopup` path |
| `lib/src/ui/widgets/properties_panel.dart` | Modify | Layer-kind chip in the layer list; a way to *set* a layer's kind (new — see Open Design Questions) |
| `lib/src/ui/screens/editor_screen.dart` | Modify | New "Lettering" mode switch + balloon rail / balloon editor layout per platform, per `02-visual.md` |
| New: AI client module (Dart, `lib/src/ai/` or similar) | Create | Client-side contract only (`BalloonAiClient`, below) — no on-device engine, no server, no hardware detection built in this flow |
| New: language registry (data, not code) | Create | Source of "what languages exist/can be added" — a data file, not a hardcoded Dart list, so growing it is a data change (see Data Models) |
| `apps/comics-ai-baloons/` | Not modified | Referenced as the algorithmic source of truth for whatever later implements `BalloonAiClient`, and as the existing canonical language-code list to reuse for the new registry |

## Architecture

### Component Diagram

```
                    Flutter UI (editor_screen.dart)
                              |
              +---------------+----------------+
              |                                |
       Edit mode (existing)              Lettering mode (new)
              |                                |
     properties_panel.dart          balloon rail + balloon editor card
     (kind chip + kind picker,                 |
      all layers)                              |
              |                                |
              +---------------+----------------+
                              |
                     ComicsCore (bridge, existing)
                    /                          \
      core_client.dart (desktop,        dart_io_core.dart (mobile,
      spawns Comics.Editor.Headless)     pure-Dart, no subprocess)
              |
    native/Comics.Editor(.Headless)  <-- reads/writes data.json
    (Layer/Image models, extended)

         balloon editor card also calls:
                     BalloonAiClient (new, this flow)
                              |
                    [ implementation out of scope --
                      on-device engine and/or server,
                      future work ]
```

### Data Flow — generate artwork

```
User edits text (Lettering mode, or the balloon editor card embedded in Properties panel --
both host the same component, per 02-visual.md)
  -> EditorController holds pending translation edit
  -> setLayerTranslation RPC persists it (debounced)
  -> user taps "Generate artwork with AI"
  -> BalloonAiClient.generate() -- routing/engine internals out of scope this flow
  -> on Success: EditorController receives PNG bytes
  -> ComicsCore.setLayerImage(layerId, langCode, bytes)  <-- NEW real RPC, see Interfaces
  -> native core writes the file into the document's asset store, updates Image.File/Width/Height,
     extending Images[] additively past index 2 if langCode isn't one of the 3 Cultures values
  -> UI reflects new artwork (balloon editor card + canvas thumbnail)
```

## Data Models

### Schema Changes — `data.json` layer shape

```jsonc
// Existing layer (unchanged fields shown for context)
{
  "images": [ /* unchanged base case: List<Image>, index-aligned to Cultures (En=0, Ru=1, Hi=2);
                 MAY be extended past index 2 for languages beyond the 3 Cultures values -- see below */ ],
  "animations": [ /* unchanged */ ],

  // NEW, all optional, all DefaultValueHandling.Ignore -> absent entirely when unset
  "kind": "balloon",               // open string; this flow uses "balloon" | "caption" | (absent = today's generic layer). Left open (not a closed enum) so a broader taxonomy (see vdd-comics-editor-jhanava) can adopt the same field later without a migration.
  "style": "speech",               // only meaningful when kind == "balloon"; "speech" | "hand_lettered"
  "translations": {                // NEW -- language-code-keyed, sparse, independent of Images/Cultures
    "en": "And Amba told Parashurama...",
    "ru": "И Амба рассказала Парашураме о несчастьях, что приключились с нею.",
    "uk": "Тестовий переклад..."
  }
}
```

Design decisions, each with rationale:

- **`kind` is an open string, not a closed C# enum**, scoped to `balloon`/`caption` values for what
  *this flow* builds UI for. Left open specifically so `vdd-comics-editor-jhanava`'s eventual
  answer (a broader taxonomy) can reuse the same field later without a schema migration — this
  flow doesn't try to anticipate or encode that answer itself.
- **`translations` is a plain `Dictionary<string, string>` keyed by ISO language code, with no
  fixed size or fixed value set** — this is the dynamic-language correction. The dictionary can
  hold any language code; nothing in the schema caps it at 3 or at 20.
- **Language registry is data, not code**: "which languages can be added" (the `[+ Add]` picker's
  option list) is sourced from a small JSON/config resource shipped with the app — seeded from
  `apps/comics-ai-baloons/scripts/languages.py`'s canonical list as a starting point (reuse, not
  reinvent), but structured so adding a language later is editing that data file, not changing
  Dart/C# code. This is the concrete mechanism behind "dynamic, not hardcoded to a fixed count."
- **`translations` is independent of `Images`**: a balloon can have `translations["uk"]` (text
  entered) with no corresponding rendered artwork yet — the "text entered, not yet generated" state
  in `02-visual.md`. When generating artwork: if the target language is one of the 3 `Cultures`
  values (en/ru/hi), it writes into the existing fixed `Images` index; for any other language code,
  `Images` is extended additively past index 2, in a stable, deterministic order (append new
  languages in first-seen order per document, recorded so the mapping is reconstructible) — the
  same forward-compatible mechanism `apps/comics-ai-baloons` already validated for exactly this
  problem. (This mechanism was dropped in the v0.2 draft when language scope was capped at 3; it's
  back because the dynamic/uncapped scope needs it again.)

### Backward compatibility — verified, not assumed

Checked `native/Comics.Editor/IWS/Utils/Extensions.cs` (`Extensions.SerializerSettings`, the
actual `JsonSerializerSettings` used for `data.json`):

```csharp
public static readonly JsonSerializerSettings SerializerSettings = new JsonSerializerSettings
{
    ContractResolver = new CamelCasePropertyNamesContractResolver(),
    DefaultValueHandling = DefaultValueHandling.Ignore,
    TypeNameHandling = TypeNameHandling.Auto
};
```

- `MissingMemberHandling` is **not set**, so it's Newtonsoft's default (`Ignore`): deserializing an
  old file (no `kind`/`style`/`translations`) into the new `Layer` class works with those
  properties simply staying at their C# default (`null`/empty dict) — no error, no data loss.
  Deserializing a *new* file in an *old* app build similarly ignores the unrecognized properties.
- `DefaultValueHandling.Ignore` means a `Layer` with `Kind == null` and an empty `Translations`
  dict **serializes with those properties entirely absent from the JSON**, not present-as-null.
  Re-saving an old file that was never touched by the new balloon/translation UI produces JSON
  identical in content to today's output — this is a property of the existing serializer config,
  not new code we have to write and hope is correct.
- Property names: `CamelCasePropertyNamesContractResolver` means the new C# properties `Kind`,
  `Style`, `Translations` serialize as `"kind"`, `"style"`, `"translations"` automatically,
  consistent with every other field already in the file.

### Flutter mirror (`lib/src/ui/models.dart`)

```dart
class EditorLayer {
  // ...existing fields (images, animations, etc.) unchanged...
  String? kind;                    // 'balloon' | 'caption' | null (this flow's value set)
  String? style;                   // 'speech' | 'hand_lettered' | null (balloon only)
  Map<String, String> translations; // lang code -> text, defaults to {}, any size
}
```

`models_mapping.dart`'s existing pattern of preserving unrecognized raw JSON (`CoreDocument.raw`)
already covers the "Flutter UI doesn't understand a field the native core wrote" direction; the new
fields just need to be added to the explicit mapping so the *UI* can read/edit them, not merely
pass them through.

## Interfaces

### New Interfaces

```dart
// lib/src/bridge/comics_core.dart -- new RPC methods
abstract class ComicsCore {
  // ...existing: openComics, saveComics...

  /// Writes generated (or manually picked) image bytes into a layer's language slot.
  /// This is also the fix for the existing setImageFile/setImagePopup stub -- both the
  /// AI-generation path and a real file-picker path converge on this one real RPC.
  /// langCode, not a positional index: the native core resolves it to an existing Cultures
  /// index (en/ru/hi) or an additive Images[] slot for anything else -- caller doesn't need to
  /// know which.
  Future<void> setLayerImage({
    required String documentId,
    required int layerIndex,
    required String langCode,
    required Uint8List pngBytes,
  });

  Future<void> setLayerKind({
    required String documentId,
    required int layerIndex,
    required String? kind,      // 'balloon' | 'caption' | null
    required String? style,     // balloon-only
  });

  Future<void> setLayerTranslation({
    required String documentId,
    required int layerIndex,
    required String langCode,
    required String text,        // empty string removes the entry
  });
}

// lib/src/ai/ (new module) -- CLIENT CONTRACT ONLY. No implementation in this flow; a stub/fake
// satisfying this interface is sufficient to build and test the UI end-to-end.
abstract class BalloonAiClient {
  Stream<GenerationEvent> generate({
    required Uint8List sourceBalloonPng,
    required String targetText,
    required String targetLangCode,   // any code from the language registry, not just en/ru/hi
    required bool isHandLettered,      // if true, caller should not have offered this at all
  });
}

sealed class GenerationEvent {}
class RoutingDecided extends GenerationEvent { final bool onDevice; final String? reason; }
class Progress extends GenerationEvent { final String stage; }
class Success extends GenerationEvent { final Uint8List pngBytes; final int width; final int height; }
class Failure extends GenerationEvent { final String reason; final bool retryable; }

// lib/src/i18n/language_registry.dart (new) -- the "dynamic, not hardcoded" language list
abstract class LanguageRegistry {
  List<LanguageOption> availableLanguages();  // sourced from bundled config, not a Dart constant
}
class LanguageOption { final String code; final String displayName; }
```

### Modified Interfaces

- `EditorController.setImageFile`/`setImagePopup` (`controller.dart:415-427`): currently mutate
  in-memory state only with a hardcoded placeholder filename and never call the bridge. Both need
  to actually call `ComicsCore.setLayerImage` with real bytes (from a real file picker, or from
  `BalloonAiClient`'s `Success` event) — this was already broken before this feature and blocks it
  regardless, since AI-generated output has to be written *somewhere* real.

## Behavior Specifications

### Happy Path

1. User opens a `.comics` file with some layers carrying `kind: "balloon"` and `translations`
   entries (or none — see Edge Cases for legacy files).
2. User switches to Lettering mode (mode switch, top bar) — or works from the Properties panel's
   embedded balloon editor card in Edit mode; both host the same underlying component.
3. Balloon rail (Lettering mode) or the selected layer's editor (Edit mode) shows language tabs
   sourced from `LanguageRegistry` (only languages already used in this document, plus `[+ Add]`
   for any other registry entry), text per language, artwork preview, Generate button.
4. User picks/adds a language tab, types/edits text. `setLayerTranslation` RPC fires (debounced).
5. User taps "Generate artwork with AI". `BalloonAiClient.generate()` streams `RoutingDecided`,
   `Progress`, then `Success`.
6. `setLayerImage` RPC writes the bytes by `langCode`; native core resolves to the right `Images`
   slot (existing Cultures index, or an additively-extended one).
7. Balloon editor and rail status dot update to reflect the new artwork.

### Edge Cases

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| Legacy file, no `kind` anywhere | Open a pre-existing `.comics` file | Every layer behaves exactly as today; Lettering mode's balloon rail is empty until a layer is explicitly marked `kind: "balloon"`/`"caption"` |
| Lettering mode entered on a file with zero balloon-kind layers | Legacy file, or balloons never tagged | Rail shows an empty state directing back to Edit mode to tag a layer's kind — needs a kind-setting UI (see Open Design Questions) |
| `translations` entry for a language beyond the 3 `Cultures` values | e.g. `uk`, `es`, any registry language | `Images` extended additively past index 2 on generation, per Data Models — this is the case the dynamic-language correction specifically restores support for |
| `translations` entry exists for a language with no `Images` slot populated | Text added, never generated | `Images` untouched; UI shows "text entered, not yet generated" |
| Generate requested for a `style: "hand_lettered"` balloon | Should be unreachable (button disabled per `02-visual.md`) | `BalloonAiClient.generate` rejects with `Failure(reason: "hand_lettered", retryable: false)` as defense-in-depth |
| Device capability check fails mid-generation | Routing was on-device, degrades | Leaning decide-once-at-generate-time, no live re-routing — still open, see below |
| Network unavailable and cloud routing required | Offline, device can't do the language locally | `Failure(reason: "network_required", retryable: true)` |
| `translations` text edited after artwork was already generated | User changes their mind post-generation | Artwork **not** auto-regenerated — needs a "stale" indicator prompting explicit Regenerate; not covered by `02-visual.md`'s states — flag for Plan |

### Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `text_overflow` | Layout couldn't fit text even at minimum font size | `Failure(reason: "text_overflow", retryable: true)`; UI: Retry + Edit text |
| Render/shaping error | Font/shaping engine failure for the target script | `Failure(reason: "render_error", retryable: true)` |
| `network_required` | Cloud routing needed, no connectivity | `Failure(reason: "network_required", retryable: true)`; distinct retry semantics vs. generic failure |
| RPC/bridge failure | Native core crash, IPC failure | Existing bridge error handling applies (not new to this feature) |

## Dependencies

### Requires

- `comics-ai-baloons`'s erase/layout/render algorithms as the reference implementation for whatever
  later implements `BalloonAiClient`; also its `languages.py` list as the seed for the new
  `LanguageRegistry` data file. Neither is built/ported by this flow.

### Blocks

- Nothing outside this flow.

## Integration Points

### External Systems

None in this flow — `BalloonAiClient` is a client-side interface with no implementation here.

### Internal Systems

- `native/Comics.Editor/Models/*.cs` (schema), `lib/src/bridge/*.dart` (RPC), `lib/src/ui/*.dart`
  (UI, including `editor_screen.dart`'s new mode), `lib/src/i18n/` (new registry).

## Testing Strategy

### Unit Tests

- [ ] C# `Layer`/`Image` (de)serialization: old-format JSON round-trips unchanged; new fields
      round-trip; `DefaultValueHandling.Ignore` confirmed empirically for the new properties
- [ ] `Images[]` additive-extension logic: writing a language beyond the 3 `Cultures` values
      extends the array correctly and deterministically; re-opening/re-writing doesn't duplicate
      or reorder existing entries
- [ ] Flutter `models_mapping.dart`: new field mapping both directions
- [ ] `LanguageRegistry`: loads from data file, not hardcoded; adding an entry to the data file
      requires no code change to pick it up
- [ ] `BalloonAiClient` contract: routing decision, event sequence, failure reasons, tested against
      a fake/stub implementation

### Integration Tests

- [ ] Open a real legacy `.comics` file (from `dataset/`, read-only, copy first) in the updated
      app; confirm no crash, no visible change, re-save produces equivalent JSON
- [ ] Full generate flow against a stub `BalloonAiClient`, including at least one language beyond
      the 3 `Cultures` values, confirming additive `Images` extension end-to-end

### Manual Verification

- [ ] Open an old file, confirm Edit mode is unchanged
- [ ] Mark a layer as balloon, enter Lettering mode, confirm it appears in the rail
- [ ] Add a language not in `en`/`ru`/`hi` via `[+ Add]`, generate, confirm it round-trips through
      save/reopen correctly
- [ ] Full walkthrough of every state in `02-visual.md` against the running app

## Migration / Rollout

No migration needed — additive schema, verified backward-compatible by existing serializer config.
Bulk-tagging existing balloons with `kind: "balloon"` across `dataset/`-style content is a separate
data-migration task, out of scope here; `comics-ai-baloons`'s `discover.py` heuristic could seed
such a pass later if wanted.

## Open Design Questions

- [ ] **Kind-setting mechanism**: how a user marks a layer's `kind` from the UI (dropdown? context
      menu?) — not designed in `02-visual.md`, needed for "legacy file, tag your first balloon."
- [ ] **Stale-artwork indicator** when translation text is edited after generation — not covered by
      `02-visual.md`'s states.
- [ ] **Live re-routing vs. decide-once-at-generate-time** if device capability changes mid-flight
      — leaning decide-once, unconfirmed.
- [ ] **`LanguageRegistry` data file format/location** and exact seeding process from
      `comics-ai-baloons/scripts/languages.py` — mechanism decided (data not code), format not yet.
- [ ] **AI engine scope + hosting** (unaffected by the revert — this was never one of the
      restrictive items): this flow specifies the client contract only; on-device engine,
      hardware-capability detection, and server implementation are follow-on work, not built here.
      What "the server" is (extended `comics-ai-baloons` vs. new backend) stays undecided.
- [ ] **Full kind taxonomy, character/background placement, material systematization**: explicitly
      out of scope here — tracked in `flows/vdd-comics-editor-jhanava/` instead. This flow's
      `kind` field is deliberately left open (not a closed enum) so that flow's eventual answer
      can adopt the same field without a migration, but this flow does not attempt to answer it.

---

## Approval

- [x] Reviewed by: Anton Dodonov
- [x] Approved on: 2026-07-30
- [x] Notes: Approved as v0.3 (original plan restored after brief narrowing/reversal — see
      Revision note at top). Remaining Open Design Questions are not blocking; expected to resolve
      during Plan/Implementation.
