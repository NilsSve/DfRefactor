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
| `CompiledRefactoredCode.src` | View for compiled/refactored output |

## Running Tests

- **Unit tests**: Run `DFUnit_TestRunner.exe` (compiled from `DFUnit_TestRunner.src`). Test fixtures are defined in `AppSrc/oUnit_Tests.pkg` and additional test packages under `AppSrc/Tests/`. Each test procedure must have the `{Published = True}` meta-tag to be discovered.
- **Interactive testing**: Run `TestBench.exe`. It processes the code in `AppSrc/LegacyCode.pkg` (gitignored working file) through refactoring functions and shows results side-by-side.

To run a single test fixture, the `TearDown` procedure calls `Send _InitializeFuncLib of ghoRefactorFuncLib` to reset state between tests.

## Architecture

### Core Object Hierarchy

```
cRefactorApplication  (AppSrc/cRefactorApplication.pkg)
    └── Creates: ghoFileSystem (cFilesystem)
    └── Application-wide settings, workspace management

cRefactorEngine       (AppSrc/cRefactorEngine.pkg)
    └── Extends BusinessProcess
    └── Global handle: ghoRefactorEngine
    └── Orchestrates running refactoring functions against source files
    └── Calls into ghoRefactorFuncLib for each function

cBaseFuncLib          (AppSrc/cBaseFuncLib.pkg)
    └── All low-level/private refactoring primitives (prefixed with "_")
    └── Includes _ExpressionExtractor, _ExtractParenthesisExpression, tokenizer, etc.
    └── Global handle: ghoRefactorFuncLib (shared with cRefactorFuncLib)

cRefactorFuncLib      (AppSrc/cRefactorFuncLib.pkg)
    └── Extends cBaseFuncLib
    └── Adds RegisterInterface meta-tag parsing logic
    └── IsMetaTag global function for parsing {Description} compound tags

oRefactorFuncLib      (AppSrc/oRefactorFuncLib.pkg)
    └── Instantiates cRefactorFuncLib
    └── Contains ALL public refactoring functions, decorated with meta-tags
    └── This is where new refactoring functions are added
```

### Key Global Handles

| Handle | Type | Set in |
|---|---|---|
| `ghoRefactorEngine` | `cRefactorEngine` | `cRefactorEngine.pkg` constructor |
| `ghoRefactorFuncLib` | `cRefactorFuncLib` | `oRefactorFuncLib.pkg` object creation |
| `ghoFileSystem` | `cFilesystem` | `cRefactorApplication.pkg` |
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
3. Optional: add `{EnumList}`, `{InitialValue}`, and `{HelpTopic}` meta-tags inside `{Description}` if the function takes an `sParameter` enum argument.
4. **Note**: DataFlex Studio breaks Code Explorer and Code Completion when triple-quote strings are used in `{Description}`. Develop and test new functions in a separate package, then copy the finished function into `oRefactorFuncLib.pkg`.

### Git Submodules (Libraries/)

| Submodule | Purpose |
|---|---|
| `Libraries/cFilesystem` | File system utilities |
| `Libraries/DFUnit` | Unit testing framework (provides `cTestFixture`) |
| `Libraries/DUF` | DbUpdateFramework — database schema migrations |
| `Libraries/SciControlLib` | Scintilla editor control integration |

### Data & Configuration (gitignored)

- `AppSrc/LegacyCode.pkg` — working file containing legacy DataFlex code snippets used as test input (gitignored)
- `AppSrc/RefactoredCode.pkg` — output of refactoring runs (gitignored)
- `Data/` — DataFlex database files (`.dat`, `.k*`, `.hdr`, etc.) — all gitignored

### Batch / Command-line Mode

The engine supports headless operation via `/bm` or `/batch_mode` flags (defined as `CS_BatchModeShort` / `CS_BatchModeLong` in `cRefactorApplication.pkg`). INI files `DFRefactorCmdLineRF.ini`, `DFRefactorCmdLineSC.ini`, `DFRefactorCmdLineWS.ini` configure different batch-mode runs.

### Constants and Structs

All shared constants, enumerations, and struct definitions live in `AppSrc/RefactorConstants.h.pkg`. Key structs: `tRefactorSettings`, `tRefactorFiles`, `tFuncLib`, `tFuncParam`, `tFuncEnumList`, `tWorkspace`.
