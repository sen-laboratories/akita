# Refactor Assessment — Akita / SEN Tracker Fork

Status: **First-pass assessment complete. Mission/scope not yet clarified —
do not start implementation.** No refactoring branch has been created yet.

This document is the persisted output of an initial research pass over
`senryu/src/kits/tracker/` (see `CLAUDE.md` in this repo for the repo-layout
gotcha — actual source lives in the sibling `senryu` checkout, not here).

## Confirmed Action Items (approved by user, not yet implemented)

These two are confirmed findings — safe to act on once we're doing
implementation work, independent of the broader mission scope:

1. **Delete `src/kits/tracker/Sensei.h.h`** — a tracked, 0-byte file with a
   doubled extension, introduced in the same commit as the `Sen.h`/`Sensei.h`
   symlinks. Nothing in the tree includes it (`git log`/grep confirmed).
   Looks like a committed accident (stray `ln -s`/editor artifact).
2. **Fix `OpenRelationsMenu.cpp:360`** — `char *fileType[B_MIME_TYPE_LENGTH];`
   declares an array of pointers-to-char, not a value buffer, unlike every
   other MIME-type buffer declaration in the codebase (`char mimeType[B_MIME_TYPE_LENGTH]`
   pattern used elsewhere). Used with `BMessage::GetInfo`'s `char**` out-param
   and dereferenced as `*fileType` — plausibly "works by accident" but is
   the wrong declaration shape and should match the value-buffer idiom used
   everywhere else.

## Full Assessment Summary

### 1. Modularity — biggest structural gap
- `TrackerSen.cpp` (1216 lines) and `PoseViewSen.cpp` (290 lines) have **no
  headers of their own** — their public interface lives entirely inside
  stock `Tracker.h:166-187` and `PoseView.h:463-464`.
- `ContainerWindow.cpp` is the worst offender: 3 full SEN methods
  (`SetupNewRelationMenu`, `SetupNewAssociationMenu`, `SetupOpenRelationsMenu`,
  ~200 combined lines) live as first-class `BContainerWindow` methods, plus
  3 SEN member fields (`ContainerWindow.h:328-331`) indistinguishable from
  stock members, plus scattered init/cleanup in the destructor and
  menu-teardown paths.
- `TrackerSen.cpp` mixes 4 responsibilities in one flat file: message
  dispatch, filesystem/persistence writes, IPC to `sen_server`, MIME/icon
  lookup.
- `PoseView.cpp:3501-3521` has a ~20-line inline SEN business-logic blob
  (builds and sends a `SEN_RELATION_ADD` message) buried inside a stock
  template-instantiation method — belongs in `PoseViewSen.cpp`.
- Best-organized coupling point found: `Tracker.h:166-187`'s `// SEN
  integration` block — grouped, commented, implementations in one file.
  Use as the template for how the others should look.

### 2. Reuse
- `TemplateUtils` works when used (`OpenRelationTargetsMenu.cpp:297` reuses
  `GetInstalledTemplates` successfully) but two extension opportunities were
  skipped instead of added to it:
  - "sen" temp-dir path building, duplicated in `TemplateUtils.cpp:155-165`
    and `TrackerSen.cpp:1004-1017`.
  - User-settings-subdir resolution, duplicated in `TemplateUtils.cpp:111-126`
    (has a `/boot/home/config/settings` fallback) and `TrackerSen.cpp:1156-1216`
    (no fallback).
- MIME short-description-into-buffer idiom copy-pasted 3x across
  `TrackerSen.cpp`/`TemplateUtils.cpp`, no shared wrapper.
- Inconsistent SEN-attribute-prefix filtering: `TrackerSen.cpp:1103` checks
  one prefix case-sensitively; `PoseViewSen.cpp:220` checks two prefixes
  case-insensitively. Same intent, different logic — duplication *and* a
  latent correctness bug risk.
- `OpenRelationsMenu.cpp`/`OpenRelationTargetsMenu.cpp` duplicate ~5 lines
  of constructor setup and independent "is sen_server running" checks —
  candidate for a shared `SenSlowMenuBase`.
- Author already self-flagged one cross-repo duplication:
  `PoseViewSen.cpp:251` — `// todo: migrate to common method
  GetPluginsForTypeAndFeature in SEN SelfRelationHandler.cpp!` (spans into
  the separate `sen_server` codebase).

### 3. `#ifdef SEN` extension pattern — does not exist yet
No SEN-vs-stock compile guard exists anywhere. All SEN code compiles in
unconditionally; there is no way to build a "stock Tracker" binary from
this tree today. Largest gap relative to the stated goal.

Side finding: 5 of 6 SEN `.cpp` files force `#define DEBUG 1` at file
scope, unconditionally enabling verbose Haiku `PRINT`/`ASSERT` logging —
looks like a leftover dev crutch, not a real convention.

### 4. Modern C++20 style
- Pure BeOS idiom throughout: raw pointers, no smart pointers, no
  `std::vector`/`std::map`; `BMessage` used as an ad hoc stringly-typed
  container.
- C-style fixed buffers mixed inconsistently with `BString` in the same
  functions.
- Only stdlib usage found anywhere: `TrackerSen.cpp:7,1032-1033` uses
  `std::filesystem::remove_all()`, with the author's own comment
  acknowledging why (`// sadly there is no Haiku native wrapper for this
  (yet?)`).

### 5. Readability / dead code
- `Sensei.h.h` — see Confirmed Action Items above.
- `Tracker.h:171-173` declares `ConvertSelfRelationsToCommon(...)` with
  **no implementation found anywhere in the tree**. Either implemented
  elsewhere unseen, or a dead stub. Needs confirmation before touching —
  not yet an approved action item.
- No commented-out dead code blocks found in the SEN files themselves.

### 6. Existing TODO/FIXME inventory (already in the code)
14 TODOs found across the SEN files, several of which already self-diagnose
this exact refactor, e.g.:
- `TrackerSen.cpp:1155` — `// todo: move to library or SEN core later`
  (attached to `GetSenIcon`)
- `TemplateUtils.cpp:16` — `// NOTE: if used from TemplatesMenu later,
  remove this and move kTemplatesDirectory to this header!`
(Full list of 14 available in the original research agent transcript if
needed — not duplicated here to keep this doc scannable.)

### 7. Obsolete/duplicate — additional note
`Sen.h`/`Sensei.h` are symlinks to a Haiku-native path
(`/boot/home/config/non-packaged/develop/headers/sen/...`) not present in
either `akita` or `senryu`. The actual `SEN_*`/`SENSEI_*` constant
definitions live outside version control from this checkout's perspective
— unaudited for internal duplication. Whether these headers should move
into `senryu` or `akita` proper is an open question for the mission
clarification, not yet decided.

## Open / Not Yet Decided

- Overall refactor mission/scope — **pending clarification in next
  session**.
- Target file/header layout for `TrackerSen`/`PoseViewSen`/`ContainerWindow`
  SEN extraction.
- The `#ifdef SEN` (or equivalent) macro convention — name and where it's
  defined (build system vs. header).
- What to do about `ConvertSelfRelationsToCommon` (declared, no
  implementation found).
- Whether/where `Sen.h`/`Sensei.h` should live in-repo.
- No refactoring branch created yet — per project convention (see
  `CLAUDE.md`), branch only after the proposal is confirmed.
