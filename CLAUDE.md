# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DFRefactor is an automated code refactoring tool for DataFlex source code, developed by Nils Svedmyr, RDC Tools International. It is written entirely in DataFlex (a business application language). Source files use extensions `.src` (program entry points), `.pkg` (packages/classes), `.vw` (views/UI), `.sl` (sort lists), `.dd` (data dictionaries).

## Building

This project is compiled using the DataFlex IDE (Studio). The project configuration file is `AppSrc/DFRefactor.cfg` (main app) and `AppSrc/TestBench.cfg` (test bench). There is no command-line build system — open the `.sws` workspace file in DataFlex Studio and compile from there. The target platform is x64 (`64BitSuffix=64`).

## Programs (Entry Points)

There are four compiled programs in `AppSrc/`:

| Source file | Purpose |
|---|---|
| `DFRefactor.src` | Main production application |
| `TestBench.src` | Interactive test bench for developing/testing refactoring functions |
| `UnitTests.src` | Automated unit test runner (uses DFUnit framework) |
| `CompiledRefactoredCode.src` | Wrapper for the refactored output of LegacyCode.pkg to RefactoredCode.pkg |

## Running Tests

- **Unit tests**: Run `UnitTests.exe` (compiled from `UnitTests.src`). Test fixtures are defined in `AppSrc/oUnit_Tests.pkg` and additional test packages under `AppSrc/Tests/`. Each test procedure must have the `{Published = True}` meta-tag to be discovered.
- **Interactive testing**: Run `TestBench.exe`. It processes the code in `AppSrc/LegacyCode.pkg` (gitignored working file) through refactoring functions and shows results side-by-side, in `AppSrc/RefactoredCode.pkg`(gitignored working file).

To run a single test fixture, the `TearDown` procedure calls `Send _InitializeFuncLib of ghoFuncLib` to reset state between tests.

## Architecture

### Core Object Hierarchy

```
cRefactorApplication  (AppSrc/cRefactorApplication.pkg)
    └── Application-wide settings, workspace management
    └── Uses cRefactorFileIO.pkg for file I/O — DF26-compatible global
        functions that replaced the old cFilesystem submodule (removed,
        along with its ghoFileSystem handle) and absorbed DUF's channel-based
        file I/O (core code no longer routes file I/O through DUF)

cRefactorEngine       (AppSrc/cRefactorEngine.pkg)
    └── Extends BusinessProcess
    └── Global handle: ghoEngine
    └── Orchestrates running refactoring functions against source files
    └── Calls into ghoFuncLib for each function

The refactor function-library inheritance chain (bottom to top):

cRefactorUtilities    (AppSrc/cRefactorUtilities.pkg)
    └── Low-level reusable primitives: stack helpers, string/array utilities,
        scope-keyword detection (Class/Procedure/Function/Struct/Object decls),
        keyword-array lookups, command/file-filter classification

cRefactorLexer        (AppSrc/cRefactorLexer.pkg)
    └── Extends cRefactorUtilities
    └── Comment & string-literal detection (DF 23 block-comments, multi-line
        strings, single/double quote tracking)
    └── Tokenizer pipeline (_OverstrikeStrings, _SplitSourceLineToTokens) +
        the Tokenizer entry point and HandleMultiLineString
    └── Owns lexer-state properties (pbInProcedure, pbInFunction, pbInClass,
        piMultiLineStringType, etc.)

cRefactorExpressionParser (AppSrc/cRefactorExpressionParser.pkg)
    └── Extends cRefactorLexer
    └── Expression extraction (parenthesised + legacy gt/ge/lt/le/eq/ne)
    └── Boolean indicator parsing ([brackets], Indicate statements,
        Found/FindErr) and legacy operator transformation

cBaseFuncLib          (AppSrc/cBaseFuncLib.pkg)
    └── Extends cRefactorExpressionParser
    └── Init/error plumbing: _InitializeFuncLib, _AddAllKeyWords,
        _ClearRefactoringProperties, pbIgnoreErrorState

cRefactorFuncLib      (AppSrc/cRefactorFuncLib.pkg)
    └── Extends cBaseFuncLib
    └── Adds RegisterInterface meta-tag parsing logic
    └── IsMetaTag global function for parsing {Description} compound tags

oRefactorFuncLib      (AppSrc/oRefactorFuncLib.pkg + six *RefactorFunctions.inc files)
    └── Instantiates cRefactorFuncLib
    └── Global handle: ghoFuncLib
    └── Holds ALL public refactoring functions, decorated with meta-tags — but
        SPLIT ACROSS SEVEN FILES (2026-09-01), six of them #Include'd into the
        object. Searching only the .pkg misses 65 of the 120 functions.
```

**The function library is seven files.** `oRefactorFuncLib.pkg` plus one `.inc` per family, each `#Include`d inside the `Object … End_Object` block so they compile as if written there:

| file | holds | rule |
|---|---|---|
| `oRefactorFuncLib.pkg` | everything without a family | the fallback |
| `Unicode64RefactorFunctions.inc` | the DF20/21 Unicode + 64-bit shift | **every** `{ FnGroup = Unicode64 }` |
| `IndicatorRefactorFunctions.inc` | the indicator conversion passes | — |
| `CleanupRefactorFunctions.inc` | dead code, markers, formatting | **every** `{ FnGroup = Cleanup }` |
| `CommandToFunctionRefactorFunctions.inc` | `<Cmd> <arg> to <dest>` → `Move (<Cmd>(<arg>)) to <dest>` | — |
| `CodeJockRefactorFunctions.inc` | legacy controls → CodeJock | — |
| `CommentOutRefactorFunctions.inc` | constructs retired by commenting out | — |

To find a function, search them all: `grep -n "^    Function " AppSrc/oRefactorFuncLib.pkg AppSrc/*.inc`.

**Two constraints on the `#Include` block, pulling opposite ways** (see the comment at the block itself):

- It must come **last**, just above the closing note — these functions reference helpers defined earlier in the `.pkg`, and a `RefFunc()` / function-style reference resolves at *compile* time. `DefineSelectMacro` does `RefFunc(_HasBareSelectKeyword)`; with the `#Include` at the top it is Error 54.
- It must stay **above** the `// NOTE: Do *not* add any code after this "End_Object"!` lines. The JSON import finds `End_Object`, checks that `[End_Object - 2]` is that note, truncates at `[End_Object - 3]`, and re-appends note + `End_Object`. Anything below the note is outside the region it keeps, so `#Include` lines put there are silently dropped on the next import — taking those functions out of the build.

### Key Global Handles

| Handle | Type | Set in |
|---|---|---|
| `ghoEngine` | `cRefactorEngine` | `cRefactorEngine.pkg` constructor |
| `ghoFuncLib` | `cRefactorFuncLib` | `oRefactorFuncLib.pkg` object creation |
| `ghoStatusLog` | `cRefactorStatusLog` | `cRefactorEngine.pkg` constructor |
| `ghoStatusPanel` | `cRefactorStatusPanel` | `RefactorStatusPanel.pkg` |

### Function Types (MethodType)

Every refactoring function in the function library must declare its type via `{MethodType}` inside the `{Description}` meta-tag. The engine uses this to know how to invoke the function:

| Type | How called |
|---|---|
| `eStandardFunction` | One source line at a time (line-by-line, modifying) |
| `eRemoveFunction` | One source line at a time (line-by-line, for deletions) |
| `eEditorFunction` | Whole source file passed as a string array |
| `eReportFunction` | Whole source file as string array, **no changes** made |
| `eReportFunctionAll` | All selected files, **no changes** made |
| `eOtherFunction` | One file as a string array |
| `eOtherFunctionAll` | All selected files as a string array |

### Adding a New Refactoring Function

1. Add the function to **its family's `.inc` file** if it has one — see the table above — otherwise to `AppSrc/oRefactorFuncLib.pkg`. (`UserDefinedRefactorFunctions.pkg` is for personal use.) A `{ FnGroup = Unicode64 }` or `{ FnGroup = Cleanup }` function has no choice: those two files hold their whole group, and that is a rule worth keeping true.
2. Decorate with the required meta-tags:
   ```
   {Published = True}
   { Description = """
       Human-readable description.
       {MethodType = eStandardFunction}
       {SummaryText = Short post-run summary}
       """ }
   ```
3. Optional: add `{EnumList}`, `{InitialValue}`, and `{ParamHelp}` meta-tags inside `{Description}` if the function takes an `sParameter` enum argument. `{InitialValue}` is the **first-use default / fallback only** — a user's chosen parameter persists across program restarts and is *not* reset to `{InitialValue}` on every launch (the startup meta-data sync applies it only when the stored value is blank or is no longer one of the `{EnumList}` values).
4. Optional: add `{ Private = True }` inside `{Description}` for functions defined in `UserDefinedRefactorFunctions.pkg` that should *not* be included in the JSON Export/Import file. The export skips private functions and warns which ones were excluded.
5. **Wire it into the Modernization Analyzer** (if the function fixes a compiler message): add a `{ ModRecipe = "<msg#> | <match-text> | [category]" }` sub-tag inside `{Description}`. `<match-text>` disambiguates functions that share a message number (omit it for single-function messages); it matches the message text as a **substring**, which the stem families rely on (`4298 | DFWRITE` covers DFWRITELN and DFWRITEEOL) — write it as `symbol: X` when X must match as a **whole symbol** only, the form the undefined-symbol errors need (`4328 | symbol: DATETIME` must not fire on DWHIGHDATETIME); `[category]` is `AutoFix` (default), `Suggest`, or `Explain`. The function name is implicit, and the analyzer's suggested-fix hint is the `{Description}` first line. Tag order inside `{Description}` no longer matters — `ParseHelpTopic` consumes only `{ParamHelp}`'s own lines (until 2026-07-05 it swallowed every remaining line, so tags after `{ParamHelp}` were silently lost and the startup sync then blanked `Functions.SummaryText`). Repeat the tag for a function that fixes more than one message. After adding or changing a `{ModRecipe}`, bump `CI_ModAnalyzerRecipeVersion` (top of `cModAnalyzer.pkg`) so the recipe table and `ModAnalyzerRecipes.json` reseed. (The `_AddMetaTagRecipes` loop in `cModAnalyzer.pkg` reads these tags off `ghoFuncLib`; Explain-only recipes that have no refactor function stay hardcoded in `BuildDefaultRecipes`.) **Mind the `{Description}` size limit** — for a large function, relocate example/limitation prose into a `/* … */` block comment above `{Published = True}` to make room for the tag. (The function library's function-header comments are `/* */` blocks, not `//` lines — match that style.)
6. **JSON Export / Import knows about the split, but only one way.** Export reads the whole `#Include` set (`cExportImportFunctions.ReadCodeLibraryWithIncludes`), so every function's source round-trips out. Import can only write `oRefactorFuncLib.pkg` itself, so it **refuses** any function defined in an `.inc` and names the file — writing it into the `.pkg` would add a second definition. Apply those by hand.
7. **Note**: Earlier versions of DataFlex Studio had Code Explorer and Code Completion issues with triple-quote strings in `{Description}`. This is resolved in DF 26.
8. **Mid-loop cancel detection** (only relevant for `eOtherFunction` / `eOtherFunctionAll` types that iterate over many lines or files internally): if you want the user to be able to cancel quickly during your function's own inner loop, use `Get pbUserCancelRequested of ghoEngine to bCancel` and exit your local loop when it returns True. **Never call `Get Cancel_Check of ghoEngine`** — that's the engine's cancel pipeline (it deactivates the status panel and pops the YesNo) and calling it from inside a refactor function silently consumes the cancel signal, leaving the engine grinding through the rest of the workspace while the program appears locked up. See `cRefactorEngine.pkg`'s `pbUserCancelRequested` for the rationale, and `UserDefinedRefactorFunctions.pkg` for the canonical code pattern.
9. **Per-file progress bar** (whole-file types — `eOtherFunction` / `eReportFunction` / `eEditorFunction` / `eOtherFunctionAll` / `eReportFunctionAll`): the engine only auto-advances the per-file progress bar for line-by-line (`eStandardFunction` / `eRemoveFunction`) functions, because a whole-file function is one call per file. **Your function must nudge the bar itself** inside its line loop — every ~20 lines, guarded so it is a no-op when no panel shows: `If (Mod(iCount, 20) = 0 and (Active_State(ghoStatusPanel) = True)) Begin` … `Send Update_StatusPanel of ghoStatusPanel (...)` + `Set piPosition of ghoProgressBar to (iCount + 1)` … `End`. See `cUnicodePointerToString.pkg` or `ChangeDfTimerTocTimer` for the pattern. (An engine-side "set the bar to full after the call" does NOT work — it flashes full then resets per file; the bar must fill *as you scan*.)

### Updating the Deep Scan Catalog (BuildDefaultDeepScanRules)

The Deep Scan rules seed lives in `AppSrc/cDeepScanner.pkg` (`BuildDefaultDeepScanRules`); the full maintainer contract is the comment block above that function. The short version:

- **When**: a new converter should own an existing rule (edit `sRefactorFn`/`eCategory` in place), a coverage gap or misfire is found, a rule graduates Suggest → AutoFix after live verification, or a new DataFlex release extends the docs' obsolete-symbols list.
- **Append-only**: `iDSNumber` (9001+) is assigned by seed *position* and is the identity for ignore-list keys, the saved `DeepScanRules.json` toggles, and the recipe table. Append new rules at the tail under a dated `v<n>:` comment; edit existing rules' fields in place; **never insert, reorder, or delete** (retire a rule with `bEnabled False` instead).
- **Two version bumps, always**: `CI_DeepScanRulesVersion` (`RefactorConstants.h.pkg`) — without it the change never reaches an existing `DeepScanRules.json` (the file wins while versions match; the bump reseeds and merges the user's Enabled toggles by DS number) — and `CI_ModAnalyzerRecipeVersion` (`cModAnalyzer.pkg`) — the rules double as analyzer recipes and stay dormant in the grid/plan until the recipe table reseeds.
- A new detection *shape* needs a new `eDS*` kind (`RefactorConstants.h.pkg`) plus a `_RuleMatchesLine` branch and a `ScanLines` pre-gate. Tests go in `oDeepScanner-Tests.pkg`: the legacy form hits, the modern look-alike does not.

### Git Submodules (Libraries/)

Five submodules, all DIRECT children of `Libraries/` (2026-07-23 restructure: `RDCToolsLib`, `DFAbout`
and `vwin32fh` used to be nested submodules *inside* DUF; they were untangled and are now parallel to
it, listed in the workspace `.sws` `[Libraries]` alongside the rest — DUF no longer carries nested
submodules):

| Submodule | Purpose |
|---|---|
| `Libraries/DFUnit` | Unit testing framework (provides `cTestFixture`) |
| `Libraries/DUF` | DbUpdateFramework — database schema migrations |
| `Libraries/RDCToolsLib` | Shared RDC Tools classes (`cRDCCJCommandBarSystem`, `cRDCAutoCreateNewID`, grid subclasses) |
| `Libraries/DFAbout` | About-dialog package (`DfAbout.pkg`, `cAboutModalPanel`) |
| `Libraries/vwin32fh` | Windows file-handling functions (`vWin32fh.pkg` — `vFilePathExists`, `vFolderFormat`, …) |

Submodule remotes/branches (see `.gitmodules`): `DFUnit` → `NilsSve/Library-DFUnit.git` branch `release` (a maintained fork); `vwin32fh` → `NilsSve/Library-vwin32fh.git` branch `master`; the other three → `NilsSve/Library-<name>.git` branch `main`. There is no `SciControlLib` submodule: it was retired and the Scintilla integration now lives directly in `AppSrc/` (`ScintillaApi.h.pkg`, `RefactorDllLoader.pkg`, …).

The superproject only records a pinned commit (gitlink) per submodule; it does not contain their files. **First-time setup after cloning: run `git submodule update --init --recursive` once**, then `git config submodule.recurse true` so future pulls keep the libraries in sync automatically. Re-run the update command if `Libraries\` looks empty/out of date or a submodule is added.

**Pitfall:** GitHub Desktop pushes only the superproject, not new submodule commits. After committing inside a submodule, push it explicitly (e.g. `git -C Libraries/DFUnit push origin release`) before/with the superproject push, or collaborators' fetch fails with `not our ref <sha>`.

### Two repositories: `flextron` (private) and `origin` (public)

Day-to-day work goes to **`flextron`** — the private remote. `origin` is the **PUBLIC**
`NilsSve/DfRefactor` repo and lags well behind; it is brought forward by a curated,
FlexTron-excluded catch-up, never by pushing a branch.

**Never type `git push origin <anything>` casually.** A bare `git push` goes to the tracking
remote, which is private. `git push origin master` is safely rejected non-fast-forward, but
`git push origin HEAD` from a feature branch silently creates a new PUBLIC branch carrying full
FlexTron history. **Read the push output — `[new branch]` on a branch you expected to be tracked
is the tell.**

**No FlexTron file goes into the public repo**, at least until the two workspaces are merged. The
name says which files those are:

- **classes**: `cFT<Component>.pkg`, the file named after the class (`cFTWebHtmlBox.pkg`,
  `cFTModalPanel.pkg` ...; since 2026-09-21, replacing the old `<Framework>FT` suffix);
- **every other package**: the `FT` prefix (`FTMarkupBuilders.pkg`, `FTDashIcons.pkg`,
  `FTConstants.h.pkg` ...; since 2026-09-23, replacing the `xxxFT.pkg` suffix);
- **views, dialogs and the program**: the `FT` suffix (`DashboardFT.vw`, `MessageBoxFT.dg`,
  `DFRefactorFT.src`) - each is the twin of a non-FT original.

A public push is prepared in a throwaway worktree off `origin/master`, and must pass THREE leak
checks before it is pushed as `git push origin <tmp>:master`:

```bash
git diff --cached --name-status                       # 1. the staged change set
git ls-files | grep -E "FT\.|/c?FT[A-Z]"              # 2. tree level - no FT-named file (suffix, FT* or cFT*)
git ls-files -z '*.pkg' '*.src' '*.vw' '*.dg' '*.inc' '*.dd' \
  | xargs -0 grep -lIE "(Use|#Include)[[:space:]]+([A-Za-z_0-9]*FT|c?FT[A-Z][A-Za-z_0-9.]*)\.(pkg|vw|dg|inc)"
                                                      # 3. no NON-FT file that REFERENCES one
```

Check 2 is case-sensitive on purpose (with `-i`, `FT\.` also matches a name like `draft.md`), and
check 3 runs `-z` / `-0` because a tracked file name with a space splits a plain `xargs`. Before
2026-09-23 both patterns missed the `FT`-prefixed packages.

Check 3 exists because checks 1 and 2 both look for FT *files* and neither catches a non-FT file
that `Use`s one — which fails the public build on a missing include rather than on anything
obviously FlexTron-related. On 2026-09-23 it lists 15 such files: nine `Use FTThemeColors.pkg`
(`DFRefactor.src`, `TestBench.src`, `UnitTests.src`, `FunctionHelpGen.src`,
`SelectWorkspace.dg`, `cCmdLinkButton.pkg`, `cCompilerOutputContextMenu.pkg`, `cWSTextBox.pkg`,
`oCmdLnkButtonContextmenu.pkg` - it holds the programs' shared colour accessors, and itself Uses
`FTConstants.h.pkg`), three `Use FTRefactorGridToolTip.pkg` (`cRefactorCJGrid.pkg`,
`CompilerOutput.dg`, `oUnit_Tests.pkg`), `cDfCliPackages.pkg` Uses `cFTLibraryReport.pkg`, and
**`ScintillaParameters.dg`** and **`DropSelfConfirm.dg`** `Use cFTModalPanel.pkg`. Where the shared
colour accessors should live is still open. The two dialogs are simpler. `cFTModalPanel` is
FlexTron-only (`cFTModalPanel.pkg`, from the Library-RDCFlexTron package - see below); the standard one is **`cRDCModalPanel.pkg`**, in
`Libraries/RDCToolsLib/AppSrc/` and already used by `BackupFiles.dg`, `CompilerOutput.dg`,
`EngineLogFile.dg` and others. So the catch-up swap for both dialogs is
`cFTModalPanel.pkg` -> `cRDCModalPanel.pkg`. Left as-is on this line for now (Nils,
2026-08-04) — it is a catch-up task, not a fix needed here. (Scope the glob to source
extensions — unscoped, this very file matches its own rule.)

Afterwards remove the worktree (`git worktree remove --force`) and delete the temp branch. Note
that a worktree does NOT populate `Libraries/`, so the public tree cannot be compile-verified that
way — validate on the line where the submodules and database exist.

### The FlexTron toolkit comes from the Library-RDCFlexTron package

Since 2026-09-24 the FlexTron toolkit is not kept in this repository. `DFRefactorFlexTron.sws` pins the
private package **Library-RDCFlexTron** (`github.com/NilsSve/Library-RDCFlexTron`) by commit, and the
package manager puts:

- its classes and packages in `DfPkg\NilsSve_RDC_FlexTron_Library_26.0-<commit>\AppSrc`: the hosts
  (`cFTLocalWebControlHost`, `cFTDbLocalWebControlHost`, `cFTThemeHost_mixin`), the web controls
  (`cFTWeb*`), `cFTModalPanel`, `cFTDbModalPanel`, `cFTComboForm`, `cFTDockArea`, `FTConstants.h.pkg`,
  `FTThemeColors`, `FTMarkupBuilders`, `FTDashIcons` and `FTAllWebControlClasses`;
- its five style sheets (`palette`, `buttons`, `bars`, `pagefit`, `pills`) in `AppHtml\RDCFlexTron`
  (ignored), linked through `CS_PaletteCssLink`, `CS_PageFitCssLink` and `CS_PillsCssLink`.

`FTThemeSeed.pkg`, which reads the theme choice, is DFRefactor's own (`AppSrc`): the library's
`cFTApplication` reads it for its programs, and DFRefactorFT's application object is a
`cRefactorApplication`, shared with the light builds. That object sends `SeedFTTheme` at the end of its
construction.

Those copies are read-only. To change one of them, change it in a clone of Library-RDCFlexTron, commit
and push there, then move the `version` pin in `DFRefactorFlexTron.sws`; the Studio (or
`df-cli config DFRefactorFlexTron.sws`) installs the new commit. The library pins RDCToolsLib itself, so
a pin bump there must match this workspace's RDCToolsLib pin - every route to a library must name the
same commit.

The package is private, so for the public catch-up it counts as FlexTron: the files in check 3's list
still `Use` its packages (`FTThemeColors.pkg`, and through it `FTConstants.h.pkg`; `cFTModalPanel.pkg`).

### Data & Configuration (gitignored)

- `AppSrc/LegacyCode.pkg` — working file containing legacy DataFlex code snippets used as test input (gitignored)
- `AppSrc/RefactoredCode.pkg` — output of refactoring runs (gitignored)
- `Data/` — DataFlex database files (`.dat`, `.k*`, `.hdr`, etc.) — all gitignored

### Batch / Command-line Mode

The engine supports headless operation via the `/bm` or `/batch_mode` flags (`CS_BatchModeShort` / `CS_BatchModeLong` in `RefactorConstants.h.pkg`), each taking the INI file to run. Don't confuse these with `CS_CmdConfigFile1..3` (`/c`, `-c`, `--console`) — DFRefactor's OWN superseded ini-file flags, still parsed (`DFRefactorFT.src:400`) so existing scripts keep running. `UnitTests` has an unrelated `-c`/`--console` meaning console/CI mode, taking no argument. INI files `DFRefactorCmdLineRF.ini`, `DFRefactorCmdLineSC.ini`, `DFRefactorCmdLineWS.ini` configure different batch-mode runs; the Export dialog writes one INI plus `<name>_RUN.ps1` and, after a run, `<name>_RESULT.txt`.

**A batch run executes inside `OnStartup`, before `Start_UI`** — so no window exists yet unless something pages the main panel. That matters for anything that drives a windowed control: `eEditorFunction` refactorings talk to the live Scintilla control, and with no window handle every call is a silent no-op. `eEditorFunctions` in `cRefactorEngine.pkg` therefore activates the editor *before* writing to it, pages the main panel once as a retry, and records a per-function "SKIPPED" run note if the editor is still unavailable — never a silent 0-changes result.

### Constants and Structs

All shared constants, enumerations, and struct definitions live in `AppSrc/RefactorConstants.h.pkg`. Key structs: `tRefactorSettings`, `tRefactorFiles`, `tFuncLib`, `tFuncParam`, `tFuncEnumList`, `tWorkspace`.
