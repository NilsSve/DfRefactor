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
| `DFUnit_TestRunner.src` | Automated unit test runner (uses DFUnit framework) |
| `CompiledRefactoredCode.src` | Wrapper for the refactored output of LegacyCode.pkg to RefactoredCode.pkg |

## Running Tests

- **Unit tests**: Run `DFUnit_TestRunner.exe` (compiled from `DFUnit_TestRunner.src`). Test fixtures are defined in `AppSrc/oUnit_Tests.pkg` and additional test packages under `AppSrc/Tests/`. Each test procedure must have the `{Published = True}` meta-tag to be discovered.
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

oRefactorFuncLib      (AppSrc/oRefactorFuncLib.pkg)
    └── Instantiates cRefactorFuncLib
    └── Global handle: ghoFuncLib
    └── Contains ALL public refactoring functions, decorated with meta-tags
    └── This is where new refactoring functions are added
```

### Key Global Handles

| Handle | Type | Set in |
|---|---|---|
| `ghoEngine` | `cRefactorEngine` | `cRefactorEngine.pkg` constructor |
| `ghoFuncLib` | `cRefactorFuncLib` | `oRefactorFuncLib.pkg` object creation |
| `ghoStatusLog` | `cRefactorStatusLog` | `cRefactorEngine.pkg` constructor |
| `ghoStatusPanel` | `cRefactorStatusPanel` | `RefactorStatusPanel.pkg` |

### Function Types (MethodType)

Every refactoring function in `oRefactorFuncLib.pkg` must declare its type via `{MethodType}` inside the `{Description}` meta-tag. The engine uses this to know how to invoke the function:

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

1. Add the function to `AppSrc/oRefactorFuncLib.pkg` (or `UserDefinedRefactorFunctions.pkg` for personal use).
2. Decorate with the required meta-tags:
   ```
   {Published = True}
   { Description = """
       Human-readable description.
       {MethodType = eStandardFunction}
       {SummaryText = Short post-run summary}
       """ }
   ```
3. Optional: add `{EnumList}`, `{InitialValue}`, and `{HelpTopic}` meta-tags inside `{Description}` if the function takes an `sParameter` enum argument. `{InitialValue}` is the **first-use default / fallback only** — a user's chosen parameter persists across program restarts and is *not* reset to `{InitialValue}` on every launch (the startup meta-data sync applies it only when the stored value is blank or is no longer one of the `{EnumList}` values).
4. Optional: add `{ Private = True }` inside `{Description}` for functions defined in `UserDefinedRefactorFunctions.pkg` that should *not* be included in the JSON Export/Import file. The export skips private functions and warns which ones were excluded.
5. **Note**: Earlier versions of DataFlex Studio had Code Explorer and Code Completion issues with triple-quote strings in `{Description}`. This is resolved in DF 26.

### Git Submodules (Libraries/)

| Submodule | Purpose |
|---|---|
| `Libraries/DFUnit` | Unit testing framework (provides `cTestFixture`) |
| `Libraries/DUF` | DbUpdateFramework — database schema migrations |
| `Libraries/SciControlLib` | Scintilla editor control integration |

Submodule remotes/branches (see `.gitmodules`): `DFUnit` → `NilsSve/Library-DFUnit.git` branch `release` (a maintained fork); `DUF` → `NilsSve/DbUpdateFramework.git` branch `main`; `SciControlLib` → `NilsSve/Library-SciControlLib.git` branch `main`.

The superproject only records a pinned commit (gitlink) per submodule; it does not contain their files. **First-time setup: run `setup.bat` in the repo root once after cloning** — it runs `git submodule update --init --recursive` and sets local `submodule.recurse true` so future pulls keep the libraries in sync automatically. Re-run it if `Libraries\` looks empty/out of date or a submodule is added.

**Pitfall:** GitHub Desktop pushes only the superproject, not new submodule commits. After committing inside a submodule, push it explicitly (e.g. `git -C Libraries/DFUnit push origin release`) before/with the superproject push, or collaborators' fetch fails with `not our ref <sha>`.

### Data & Configuration (gitignored)

- `AppSrc/LegacyCode.pkg` — working file containing legacy DataFlex code snippets used as test input (gitignored)
- `AppSrc/RefactoredCode.pkg` — output of refactoring runs (gitignored)
- `Data/` — DataFlex database files (`.dat`, `.k*`, `.hdr`, etc.) — all gitignored

### Batch / Command-line Mode

The engine supports headless operation via `/bm` or `/batch_mode` flags (defined as `CS_BatchModeShort` / `CS_BatchModeLong` in `cRefactorApplication.pkg`). INI files `DFRefactorCmdLineRF.ini`, `DFRefactorCmdLineSC.ini`, `DFRefactorCmdLineWS.ini` configure different batch-mode runs.

### Constants and Structs

All shared constants, enumerations, and struct definitions live in `AppSrc/RefactorConstants.h.pkg`. Key structs: `tRefactorSettings`, `tRefactorFiles`, `tFuncLib`, `tFuncParam`, `tFuncEnumList`, `tWorkspace`.
