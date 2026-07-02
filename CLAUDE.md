# Akita — Semantic Tracker Fork (SEN)

Akita is a fork of Haiku OS's Tracker (the native file manager), extended
with semantic-desktop features for the **SEN** (Semantic Extensions Native)
project. The goal is to stay close to stock Tracker and add semantic
capabilities ("relations" between files, templates, tagging-adjacent
features) as a clearly bounded layer on top, not a rewrite.

Eventually packaged as an HPKG and shipped as part of the SENryu distro.

## Repo Layout Gotcha — Read This First

This repo (`akita`) contains only build/install/run scripts, the app icon,
and **symlinks** to the actual source:

```
tracker-app -> /boot/home/Develop/senryu/src/apps/tracker
tracker-lib -> /boot/home/Develop/senryu/src/kits/tracker
```

Those targets are **Haiku-native paths** (`/boot/home/...`) that only
resolve on an actual Haiku build machine. On a non-Haiku dev machine (e.g.
this Mac), the symlinks are dangling.

The real, editable Tracker/SEN source lives in the sibling `senryu` repo
(a full Haiku OS fork) at:

```
../senryu/src/apps/tracker/    (Jamfile, Tracker.rdef, main.cpp)
../senryu/src/kits/tracker/    (the bulk of Tracker + SEN code, ~130 files, ~86k lines)
```

`senryu` was cloned shallow + sparse (`--depth 1 --filter=blob:none --sparse`,
scoped to `src/apps/tracker`, `src/kits/tracker`, `headers/os/storage`,
`headers/private/tracker`, `src/tests/kits/tracker`) — it's a 541 MiB /
68k-commit repo in full, so don't widen the sparse-checkout or deepen
history without a reason. (`src/tests/kits/tracker` was added to host the
Phase 2 MVP test harness — see below.)

**When working across both repos in one session, root the session at
`~/Develop/SEN` (parent of both `akita/` and `senryu/`)** so both are in
scope — a session rooted in `akita/` alone cannot see `senryu/` since it's
a sibling, not a subdirectory, and the symlinks won't bridge the gap here.

## Technology Stack

- **OS/API**: Haiku OS (BeAPI) — BEntry, BDirectory, BMessage, BLooper,
  BView, BWindow, BObjectList, BString, etc.
- **Language target**: C++20
- **Build**: Jam (Haiku's build system), driven by `build.sh` in this repo

## Refactoring Principles (current focus)

The codebase grew organically — SEN-specific files (`TrackerSen.cpp`,
`PoseViewSen.cpp`, `OpenRelationsMenu.*`, `OpenRelationTargetsMenu.*`) were
added alongside stock Tracker files without a consistent separation
strategy. Global constants are scattered, and some functionality is
reimplemented in multiple places instead of shared. A refactor is in
progress to address this. Guiding principles:

1. **Modularity** — one class, one domain responsibility. Split files that
   mix concerns (e.g. UI menu construction mixed with data-layer relation
   storage mixed with attribute I/O).
2. **Reuse** — check `TemplateUtils.cpp`/`.h` and other existing utility
   classes before writing a new helper. `TemplateUtils` is the reference
   pattern for how a focused SEN utility class should look.
3. **Clear SEN/stock separation** — SEN-specific extensions to otherwise
   stock Tracker files should be clearly bounded, e.g. via a conditional
   compile guard (`#ifdef SEN` or similar — confirm exact convention before
   using it, none is consistently established yet). New SEN-only files
   don't need the guard; it matters where SEN code is *interleaved* into
   stock files.
4. **Modern C++20, Haiku-idiomatic at the API boundary** — use the Haiku
   API where it's the natural fit (BMessage, BEntry, node/attribute I/O,
   BObjectList when interfacing with Haiku APIs that expect it), but prefer
   stdlib (`std::vector`, `std::map`/`std::unordered_map`, `std::optional`,
   `std::string_view`, etc.) for internal logic over hand-rolled or
   BeOS-era patterns.
5. **Readability over cleverness** — remove dead code (unreferenced
   functions, commented-out blocks). Keep comments that explain *why*, cut
   comments that just restate the code.
6. **Caution on uncertain code** — don't "fix" something mid-refactor
   unless the fix is obviously correct. Leave `FIXME:` for suspected bugs
   and `TODO:` for follow-up work, with enough context to act on later.
7. **Flag, don't silently delete, obsolete/duplicate code** — call out
   candidates explicitly (in review/PR notes) before removing.

## Workflow

- Refactoring proposals require explicit user confirmation before
  implementation — assessment/proposal first, code changes only after
  sign-off.
- Refactor work happens on a dedicated branch, never directly on
  `main`/`master`.
- No commits without explicit instruction.

## Known SEN-Specific Files (verified inventory, post Phase 1 cleanup)

In `senryu/src/kits/tracker/`:

- `TrackerSen.cpp` — SEN message dispatch + Tracker-app-state orchestration
  (`HandleSenMessage`, `PrepareRelationFolder`, `PrepareRelationTargetFolder`,
  `CreateNewAssociationEntity`, `EditNewEntity`, `PrepareLaunchTarget`), all
  declared directly on `TTracker` in `Tracker.h` — there is no
  `TrackerSen.h`, by design.
- `TrackerSenRelations.cpp` / `.h` — stateless SEN relation
  attribute/filesystem I/O, extracted from `TrackerSen.cpp` in the Phase 1
  cleanup (`ResolveRelation`, `ConvertAttributesToMessage`,
  `GetInodeForRef`, `GetRelationAttributeInfo`, `GetSenIcon`,
  `CreateRelationDirectory`, `WriteTargetRelations`, `ExtractSenParams`).
  Follows the `TemplateUtils` pattern (static-only, no instance state) so
  it's directly unit-testable — see `src/tests/kits/tracker/`.
- `PoseViewSen.cpp` — `BPoseView` SEN handlers, declared on `BPoseView` in
  `PoseView.h` — no separate header, same reasoning as `TrackerSen.cpp`.
- `OpenRelationsMenu.cpp` / `.h` — top-level relation menu (`BSlowMenu`).
- `OpenRelationTargetsMenu.cpp` / `.h` — nested relation-target submenu
  (`BSlowMenu`). SEN-server querying, template resolution, and GUI/menu
  construction are tightly interleaved per-item here (not a clean
  data/view split) — flagged as a deferred, higher-risk refactor candidate,
  not yet tackled.
- `TemplateUtils.cpp` / `.h` — the reuse reference pattern (see above).
- `TemplatesMenu.cpp` / `.h` — stock-derived template selection menu, used
  by SEN but not SEN-only.

Resolved from the original starting index:
- `Sensei.h.h` (0-byte, unreferenced) — deleted.
- `Sen.h` / `Sensei.h` — were dangling symlinks to
  `/boot/home/config/non-packaged/develop/headers/sen/*`; replaced with a
  `UseHeaders` entry in the Jamfile and `<sen/Sen.h>` / `<sen/Sensei.h>`
  includes.

Known loose end, left alone per the "caution on uncertain code" principle:
`TTracker::ConvertSelfRelationsToCommon` is declared in `Tracker.h` but has
no implementation anywhere in the tree — flagged with a `FIXME:` in place;
verify whether it's still needed before implementing or removing it.

## Test Harness (Phase 2 MVP)

`src/tests/kits/tracker/` (new) follows the Storage kit's pattern
(`BTestCase`/`CppUnit::TestSuite`, built via `UnitTestLib` for
`TARGET_PLATFORM = libbe_test`) — see `src/tests/kits/storage/` as the
fuller reference example. Currently covers `TrackerSenRelations` (attribute
round-trip, `GetInodeForRef` fallback) and `TemplateUtils`
(`GetInstalledTemplates`, `FindPartialMatch`, `GetTemplateForType`). Both
compile the source files directly into the test lib rather than linking
`libtracker.so`, so they don't pull in Tracker's GUI/app_server
dependencies. Not yet build- or run-verified — this Mac has no Jam/Haiku
toolchain; needs a pass on the Haiku build machine.

GUI-coupled SEN logic (`BPoseView::ExtractRefsFromSelection`/
`EnrichRefsFromSelection`, `EnrichRefWithPlugin`) is intentionally out of
scope for this harness — it needs a live pose view or a real
volume/plugin, not `libbe_test`.
