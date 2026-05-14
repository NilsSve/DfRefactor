# DFRefactor

### Modernize legacy DataFlex code without modernizing it by hand.

---

If you maintain a DataFlex codebase that has accumulated layers across DF 2.3, DF 18, DF 20, and now DF 26, you know the shape of the problem. Old idioms scattered through hundreds of thousands of lines:

```
If iA Eq iB Move (Trim(sName)) to sLabel
[Not Found] Begin
Indicate Select as WindowIndex Eq FieldIndex
Calc x = y * 2
```

They still compile. They still run. But they don't match the language you're writing today, and every new developer who reads them has to learn a different dialect of DataFlex before they can contribute.

Touching it manually is slow. Touching it manually is risky — the compiler doesn't catch every behavioural shift a careless rewrite can introduce. Touching it manually doesn't scale.

**DFRefactor is a programmable refactoring engine for DataFlex source code.** It walks your `.src`, `.pkg`, `.vw`, and other DataFlex source files line by line and applies a configurable library of safe, test-covered transformations.

---

## What makes it different: metadata-driven dispatch

Most refactoring tools are a fixed list of features baked into the engine. DFRefactor flips that around.

The engine itself is small. The interesting code lives in a library of **self-describing refactoring functions**, each one declaring its own contract via DataFlex meta-tags:

```dataflex
{Published = True}
{ Description = """
    Rewrites legacy bracket-style boolean indicators to modern syntax.
    Example: [Not Found] Begin -> If (not(Found)) Begin
    { MethodType = eStandardFunction }
    { SummaryText = Changed legacy bracket indicators }
    """ }
Function ChangeLegacyIndicators String ByRef sLine String sParameter Returns Boolean
    ...
End_Function
```

At startup, the engine reads those tags, populates the UI list, and routes each source line through the right function based on `{MethodType}`. **Adding a new refactoring function is just writing the function with the right meta-tags** — no engine code to touch, no central switch statement to extend, no registry to update. The function shows up in the UI on the next run.

That metadata-driven dispatch is what lets the project ship 40+ refactoring functions without the engine itself getting harder to maintain. Each function is a small, independently testable unit. Adding the forty-first is the same shape of work as adding the second.

---

## What ships in the box

A non-exhaustive sample of the transformations included today:

| Function | What it does |
|---|---|
| `ChangeLegacyOperators` | `If iA Eq iB` → `If (iA = iB)` (and `Ne`, `Gt`, `Ge`, `Lt`, `Le`) |
| `ChangeLegacyIndicators` | `[Found]`, `[Not Found]`, `Indicate X as Y Eq Z` → modern `If (...)` syntax |
| `ChangeCalcToMoveStatement` | `Calc x = y` → `Move y to x` |
| `ChangeInToContains` | `If "X" in sShow ...` → `If (sShow contains "X") ...` |
| `ChangeIfNotCommandToExpression` | `If not bFoo` → `If (not(bFoo))` |
| `ChangeUClassToRefClass` | Legacy unscoped class refs → modern `RefClass(...)` form |
| `ChangeCurrent_ObjectToSelf` | `Current_Object` → `Self` |
| `ChangeDfTrueDfFalse` | `DfTrue` / `DfFalse` → `True` / `False` |
| `ChangeLeftCommandToFunction`, `ChangeRightCommandToFunction`, `ChangeTrimCommandToFunction`, `ChangeLengthCommandToFunction`, `ChangePosCommandToFunction`, `ChangeReplaceCommandToFunction`, `ChangeInsertCommandToFunction` | Legacy commands → equivalent function calls |
| `ChangeSysdate4` | Deprecated `Sysdate4` → modern date access |
| `ChangeSquareBracketsIndicators` | `[X]` style indicators → expression form |
| `ChangeLegacyShadow_State` | Legacy `Shadow_State` → modern equivalent |
| `A_InsertSpaceAfterParenthesis` | Cosmetic: enforce style across the codebase |
| `RemoveUnusedLocals` | Scope-aware deletion of dead local declarations |
| `ReportUnusedSourceFiles` | Analysis-only: surface dead code at the file level |
| ...and many more | Plus everything you write yourself |

Each function declares its mode via `{MethodType}`:

| Mode | What it operates on |
|---|---|
| `eStandardFunction` | One source line at a time. Fast, surgical, line-by-line transformations. |
| `eRemoveFunction` | One source line, for deletions. |
| `eEditorFunction` | Whole source file as a string array. Multi-line transformations and reflows. |
| `eReportFunction` | Read-only analysis on a whole file. Counts, statistics, "things that look wrong." |
| `eReportFunctionAll` | Same, aggregated across every file in the run. |
| `eOtherFunction` / `eOtherFunctionAll` | Bespoke per-file or cross-file logic. |

You declare the mode; the engine handles the dispatching.

---

## Built right

This isn't a weekend hack. DFRefactor has:

- **685+ test procedures across 46 test fixtures**, run by an integrated DFUnit-based test runner. Every refactoring function has direct tests that cover happy paths and edge cases (comments, string literals, triple-quoted blocks, multi-line continuations, and mixed legacy and modern syntax on the same line).
- **A cleanly-layered architecture**. Low-level helpers, lexer/tokenizer, expression/boolean parser, init/error plumbing, and public refactoring functions each live in their own focused class file. No god objects\*.
- **A live TestBench app**: paste legacy code into one pane, click the function you want to test, see the refactored output in the other pane. Iterate in seconds.
- **Batch / CLI mode** for headless runs against entire workspaces. Configurable via INI files. Suitable for CI integration or scheduled overnight runs across a large codebase.
- **Open source, MIT licensed**. The full repository, including the test suite, is on GitHub.

---

## Who it's for

- **Teams maintaining DataFlex codebases** that have accumulated multiple generations of idioms and need to modernize without rewriting everything by hand.
- **Consultants doing DataFlex version migrations** — DF 18 → DF 23, DF 23 → DF 26 — who want a repeatable, audit-able transformation pipeline instead of grep-and-sed and prayer.
- **Anyone writing DataFlex today** who wants to enforce consistent style and modern syntax across contributions from multiple developers, on every commit if they wire DFRefactor into CI.
- **Anyone extending DataFlex tooling** — DFRefactor's metadata-driven architecture is the simplest example you'll find of a "small core, large plugin library" design in DataFlex.

---

## Get started

See [README.md](README.md) for installation, cloning (with submodules), and a tour of the three programs (`DFRefactor.exe`, `TestBench.exe`, `DFUnit_TestRunner.exe`). The short version:

1. Clone the repo with `--recurse-submodules` (the DFUnit, DUF, and SciControlLib libraries are submodules).
2. Open `DFRefactor25.0.sws` in DataFlex Studio. Target is x64.
3. Compile `AppSrc/DFRefactor.src`. Point the resulting `.exe` at a workspace, select refactoring functions, and hit *Start Refactoring*.

For experimenting with a single function on a sample of legacy code, use the TestBench.
For automated test runs against the refactoring library itself, use the DFUnit test runner.

---

## Need help, or want it done for you?

See [SUPPORT.md](SUPPORT.md) for bug reports, feature requests, contributing, and paid refactoring services from RDC Tools International — codebase audits, targeted refactors, custom refactoring function design, full DataFlex version migrations, and team training.

---

\* **"God object"** — a class that has accumulated so many responsibilities it becomes the bottleneck for every change to the system: hundreds of methods, thousands of lines, touched by half the codebase. DFRefactor's `cBaseFuncLib.pkg` was the textbook example — 4,705 lines in a single file — before its responsibilities were split across four focused classes earlier this year.
