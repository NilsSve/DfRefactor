# AGENTS.md

Guidance for AI coding assistants - and for developers - working in this repository. It is written to be
tool-neutral: Claude Code reads it through `CLAUDE.md`, and Codex, Cursor, GitHub Copilot and other tools
that follow the `AGENTS.md` convention read it directly. Keep it to facts about the project, and keep every
statement true - a wrong one misleads every contributor's tool.

Lines marked **(maintainer only)** describe how the maintainer's own checkout is set up. A contributor
does not need to reproduce them.

## Project Overview

DFRefactor is an automated code refactoring tool for DataFlex source code, developed by Nils Svedmyr, RDC Tools International. It is written entirely in DataFlex (a business application language). Source files use extensions `.src` (program entry points), `.pkg` (packages/classes), `.vw` (views/UI), `.sl` (sort lists), `.dd` (data dictionaries).

## Building

DataFlex **26.0**, x64 (`64BitSuffix=64`, so a program builds as `<Name>64.exe`). The workspace is **`DFRefactorFlexTron.sws`** (JSON format) in the repo root: open it in DataFlex Studio and compile there. Its `libraries` block pins every library by version, and the Studio's package manager (or `df-cli config DFRefactorFlexTron.sws`) installs them; `Programs\Config.ws` is generated from it and stays tracked. Outside the Studio, `df-cli build-file` compiles one program; build into a scratch `--output-dir`, never into `Programs\`.

## Programs (Entry Points)

The workspace's projects, all in `AppSrc/`:

| Source file | Purpose |
|---|---|
| `DFRefactorFT.src` | The main program — the FlexTron (web-control) user interface |
| `DFRefactor.src` | The classic Windows user interface, same engine |
| `TestBench.src` | Interactive test bench for developing/testing refactoring functions |
| `UnitTests.src` | The DFUnit test program |
| `DUFUpdateProgram.src` | Database updater (DUF), run before the main program when the schema changes |
| `MetaTagCheck.src` | Maintainer tool: checks multi-line meta-tag values against the DF26 compiler limits that crash a build silently |
| `FunctionHelpGen.src` | Maintainer tool: writes the manual's function reference out of the meta-tags (markdown for HelpNDoc) |
| `HarvestWin32Projection.src` | Maintainer tool: merges Win32 API rows into `Data\WinAPICatalog.json` / `WinAPIStructCatalog.json` |

`CompiledRefactoredCode.src` (a wrapper that compiles the TestBench output) and `ScintillaControlProbe.src` are tracked but are not workspace projects — never build `CompiledRefactoredCode`.

## Running Tests

- **Unit tests**: build and run `UnitTests64.exe` (from `UnitTests.src`). Headless: `UnitTests64.exe -c -o results.xml` (`-c` console/CI mode, `-o` writes JUnit XML); `--list` lists the tests and `--filter <text>` runs only matching ones (no match = exit -1). The fixtures are the `AppSrc/o*-Tests.pkg` files, pulled in by `AppSrc/oUnit_Tests.pkg`; `AppSrc/Tests/` holds sample *input* files, not fixtures. Each test procedure needs `{ Published = True }`. Since DFUnit 0.1.2 an error raised inside a test **fails** that test.
- `UnitTests.src` is a plain `cApplication`, so it carries stubs for what the code under test asks the real application object (`psTargetPkgFolder`, `SavedPlanJsonPath`, `WorkspaceSourceRoots`, …). A new `Get … of ghoApplication` in tested code may need a stub there.
- **Interactive testing**: run `TestBench64.exe`. It runs the code in `AppSrc/LegacyCode.pkg` through refactoring functions and shows the result side-by-side, in `AppSrc/RefactoredCode.pkg` (gitignored).

Between tests the fixture's `TearDown` sends `_InitializeFuncLib of ghoFuncLib` to reset the function library's state.

## Architecture

### Core Object Hierarchy

```
cRefactorApplication  (AppSrc/cRefactorApplication.pkg)
    └── Application-wide settings, workspace management
    └── Uses RefactorFileIO.pkg for file I/O — DF26-compatible global
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

oRefactorFuncLib      (AppSrc/oRefactorFuncLib.pkg + eight *RefactorFunctions.inc files)
    └── Instantiates cRefactorFuncLib
    └── Global handle: ghoFuncLib
    └── Holds ALL public refactoring functions, decorated with meta-tags — but
        SPLIT ACROSS NINE FILES (2026-09-01, two more 2026-11-27), eight of them
        #Include'd into the object. Searching only the .pkg misses most of them.
```

**The function library is nine files.** `oRefactorFuncLib.pkg` plus one `.inc` per family, each `#Include`d inside the `Object … End_Object` block so they compile as if written there:

| file | holds | rule |
|---|---|---|
| `oRefactorFuncLib.pkg` | everything without a family | the fallback |
| `Unicode64RefactorFunctions.inc` | the DF20/21 Unicode + 64-bit shift | **every** `{ FnGroup = Unicode64 }` |
| `IndicatorRefactorFunctions.inc` | the indicator conversion passes | — |
| `CleanupRefactorFunctions.inc` | dead code, markers, formatting | **every** `{ FnGroup = Cleanup }` |
| `CommandToFunctionRefactorFunctions.inc` | `<Cmd> <arg> to <dest>` → `Move (<Cmd>(<arg>)) to <dest>` | — |
| `CodeJockRefactorFunctions.inc` | legacy controls → CodeJock | — |
| `CommentOutRefactorFunctions.inc` | constructs retired by commenting out | — |
| `ReportRefactorFunctions.inc` | workspace reports — change nothing, write a worksheet | — (some reports belong to the Cleanup and Unicode64 groups) |
| `CollisionRefactorFunctions.inc` | DF 25/26 name collisions (4544, 4390, 4345, 4379): rename, align, guard, drop arguments | — |

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

### Libraries (DataFlex packages)

Every library the build uses comes from a **package pin** in `DFRefactorFlexTron.sws` (by version), installed under the machine's `DfPkg` folder — those installed copies are read-only and are what compiles:

| Library | Repository | Holds |
|---|---|---|
| DFUnit | `NilsSve/Library-DFUnit` | unit testing framework (`cTestFixture`) |
| DUF | `NilsSve/Library-DUF` | DbUpdateFramework — database schema updates |
| RDCToolsLib | `NilsSve/Library-RDCToolsLib` | shared RDC classes (`cRDCCJCommandBarSystem`, `cRDCModalPanel`, grid subclasses, …) |
| DFAbout | `NilsSve/Library-DFAbout` | About dialog (`DfAbout.pkg`) |
| vwin32fh | `NilsSve/Library-vwin32fh` | Windows file functions (`vWin32fh.pkg`) |
| RDCFlexTron | `NilsSve/Library-RDCFlexTron` | the FlexTron toolkit (see below) |

Plus the Data Access packages `Web UI FlexTron` and `Web UI Material Theme` (`dependencies`).

To change a library: change it in its own clone, commit, tag a release and push there, then move the `version` pin in the `.sws`; the Studio (or `df-cli config DFRefactorFlexTron.sws`) installs it. A library that pins another library (RDCFlexTron pins RDCToolsLib) must name the same version as this workspace.

`Libraries/` still holds four git submodules (DUF, RDCToolsLib, DFAbout, vwin32fh). The build does not read them; they are left over from before the package pins. Don't edit library code there expecting it to compile in.

### The repository is public

`NilsSve/DfRefactor` is **public** (since 2026-11-26; the former private FlexTron repository is archived). Contributors fork the repository and send a pull request against `master`. **(maintainer only)** The maintainer works on `master` directly and pushes `origin master`.

**Never write a customer's name into anything that gets committed** — source, tests, comments, commit messages: no workspace, file, class, table or column name taken from a customer's code. Test workspaces are referred to by neutral names (`LegacyApp1`, …).

### The FlexTron toolkit comes from the Library-RDCFlexTron package

The FlexTron toolkit is not kept in this repository. The package manager puts:

- its classes and packages in `DfPkg\NilsSve_RDC_FlexTron_Library_26.0-<version>\AppSrc`: the hosts
  (`cFTLocalWebControlHost`, `cFTDbLocalWebControlHost`, `cFTThemeHost_mixin`), the web controls
  (`cFTWeb*`), `cFTModalPanel`, `cFTDbModalPanel`, `cFTComboForm`, `cFTDockArea`, `FTConstants.h.pkg`,
  `FTThemeColors`, `FTMarkupBuilders`, `FTDashIcons` and `FTAllWebControlClasses`;
- its five style sheets (`palette`, `buttons`, `bars`, `pagefit`, `pills`) in `AppHtml\RDCFlexTron`
  (ignored), linked through `CS_PaletteCssLink`, `CS_PageFitCssLink` and `CS_PillsCssLink`.

`FTThemeSeed.pkg`, which reads the theme choice, is DFRefactor's own (`AppSrc`): the library's
`cFTApplication` reads it for its programs, and DFRefactorFT's application object is a
`cRefactorApplication`, shared with the light builds. That object sends `SeedFTTheme` at the end of its
construction.

### Data & Configuration

- `AppSrc/LegacyCode.pkg` — the TestBench's input; tracked as a public sample. Change it freely while testing, but don't commit those changes. **(maintainer only)** It is marked `skip-worktree` in the maintainer's checkout for that reason.
- `AppSrc/RefactoredCode.pkg` — output of TestBench runs (gitignored).
- `Data/ScintillaEdit.json` — the user's editor settings (gitignored). Until it exists, the tracked `Data/ScintillaEdit.default.json` is read instead: it holds the DF language row (keywords, operators, comment markers) that nothing else supplies.
- **Database version**: `CN_DbVersionNeeded` (`RefactorConstants.h.pkg`) is the version of the newest `DUF_MultipleTablesX_X.pkg` that `DUFUpdateProgram.src` Uses — bump the two together. A program whose database is older runs `DUFUpdateProgram64.exe` at startup (`DoDatabaseUpdateStuff.pkg`; `UnitTests.src` has its own copy of the check). A fresh clone's database is always older.
- `Data/` — the DataFlex database; tracked as the shipped starting data. Don't commit the changes a test run makes to it. **(maintainer only)** Marked `skip-worktree` in the maintainer's checkout.

### Batch / Command-line Mode

The engine supports headless operation via the `/bm` or `/batch_mode` flags (`CS_BatchModeShort` / `CS_BatchModeLong` in `RefactorConstants.h.pkg`), each taking the INI file to run. Don't confuse these with `CS_CmdConfigFile1..3` (`/c`, `-c`, `--console`) — DFRefactor's OWN superseded ini-file flags, still parsed (`DFRefactorFT.src:400`) so existing scripts keep running. `UnitTests` has an unrelated `-c`/`--console` meaning console/CI mode, taking no argument. No batch INI files ship with the repository; the Export dialog writes one INI plus `<name>_RUN.ps1` and, after a run, `<name>_RESULT.txt`.

**A batch run executes inside `OnStartup`, before `Start_UI`** — so no window exists yet unless something pages the main panel. That matters for anything that drives a windowed control: `eEditorFunction` refactorings talk to the live Scintilla control, and with no window handle every call is a silent no-op. `eEditorFunctions` in `cRefactorEngine.pkg` therefore activates the editor *before* writing to it, pages the main panel once as a retry, and records a per-function "SKIPPED" run note if the editor is still unavailable — never a silent 0-changes result.

### Constants and Structs

All shared constants, enumerations, and struct definitions live in `AppSrc/RefactorConstants.h.pkg`. Key structs: `tRefactorSettings`, `tRefactorFiles`, `tFuncLib`, `tFuncParam`, `tFuncEnumList`, `tWorkspace`.
