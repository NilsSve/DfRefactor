# DFRefactor

### Modernize legacy DataFlex code without modernizing it by hand.

---

If you maintain a DataFlex codebase that has accumulated layers across DF 3.x, DF 18, DF 19, DF 20 and now DF 26, you know the shape of the problem. Old idioms scattered through hundreds of thousands of lines:

```
If iA Eq iB Move (Trim(sName)) to sLabel
[Not Found] Begin
Indicate Select as WindowIndex Eq FieldIndex
Calc x = y * 2
Pos '.' in sFileName
```

Some of it still compiles and runs, in a dialect every new developer has to learn first. Some of it no longer compiles in the DataFlex version you are moving to. And some of it compiles without a word — and breaks at runtime, because a 64-bit or Unicode DataFlex treats it differently.

Fixing it by hand is slow, risky — the compiler does not catch every change in behaviour a careless rewrite can introduce — and it does not scale.

**DFRefactor modernizes DataFlex source code automatically.** It reads your `.src`, `.pkg`, `.vw`, `.dg` and other DataFlex source files and rewrites them with a library of more than 140 tested refactoring functions — in many files at once, with every change backed up and reversible.

---

## From compiler messages to a finished migration

Moving a workspace to a newer DataFlex version is where DFRefactor does the most work. Its **guided refactor** turns the migration into a loop you can see the end of:

1. **Check** compiles your program with the compiler of the version you are moving to, and scans the source for obsolete code the compiler never mentions (**Analyze Source** / Deep Scan).
2. Every finding — error, warning or silent obsolete construct — is linked to the refactoring function that fixes it, and shown in one list, sorted by how serious it is.
3. You approve a **plan**: which functions run, on which files. Nothing changes without that approval; **Read Only** shows what *would* change.
4. The plan runs. Every changed file is backed up first; **Compare Source** shows the differences and **Revert** puts the originals back.
5. The next Check shows the number of findings going down, round by round, until the program compiles clean.

Prefer to drive it yourself? The **manual refactor** lets you pick folders and functions and run them directly. You can switch between the two at any time.

---

## What makes it different: metadata-driven dispatch

Most refactoring tools are a fixed list of features baked into the engine. DFRefactor turns that around.

The engine itself is small. The interesting code lives in a library of **self-describing refactoring functions**, each declaring its own contract with DataFlex meta-tags:

```dataflex
{ Published = True }
{ Description = """
    Changes legacy comparison operators to modern expressions.
    Example: If iA Eq iB -> If (iA = iB)
    { MethodType = eStandardFunction }
    { FnGroup = Modernization }
    { SummaryText = Changed legacy operators }
    """ }
Function ChangeLegacyOperators String ByRef sLine String sParameter Returns Boolean
    ...
End_Function
```

At startup the engine reads those tags, lists the function in the program, and calls it the right way for its `{ MethodType }`. A `{ ModRecipe }` tag links it to the compiler message it fixes, so the guided refactor can offer it automatically. **Adding a refactoring function is writing the function with the right meta-tags** — no engine code to touch, no central switch statement to extend, no registry to update.

That is what lets the library grow past 140 functions without the engine getting harder to maintain. Each function is a small, independently tested unit.

---

## What ships in the box

A sample of what is included today:

| Function | What it does |
|---|---|
| `ChangeLegacyOperators` | `If iA Eq iB` → `If (iA = iB)` (and `Ne`, `Gt`, `Ge`, `Lt`, `Le`) |
| `ChangeLegacyIndicators`, `ChangeSquareBracketsIndicators` | `[Found]`, `[Not Found]`, `Indicate X as Y Eq Z` → modern `If (...)` expressions |
| `ChangeCalcToMoveStatement` | `Calc x = y` → `Move y to x` |
| `ChangeLeftCommandToFunction`, `ChangePosCommandToFunction`, … | Legacy commands → their function equivalents: `Move (Left(...)) to ...` |
| `ChangeSysdate` | `Sysdate` / `Sysdate4` → `CurrentDateTime()` |
| `ChangeInToContains`, `ChangeIfNotCommandToExpression` | `If "X" in s` → `If (s contains "X")`; `If not b` → `If (not(b))` |
| `ChangeDfTrueDfFalse`, `ChangeCurrent_ObjectToSelf`, `ChangeUClassToRefClass` | Old names → `True` / `False`, `Self`, `RefClass(...)` |
| `ChangeLegacyShadow_State` | `Shadow_State` → `Enabled_State`, with the value turned round |
| `Win64AddressToPointer`, `UnicodePointerToString`, … | The DataFlex 20/21 64-bit and Unicode shift |
| `ConvertGridSubclassToCodeJock`, `ChangeDFCreateMenuToCodeJock`, … | Legacy controls and menus → CodeJock |
| `ConvertGosubToProcedure` | Legacy `Gosub` subroutines → procedures |
| `GuardRedundantGlobalFunctions`, `RenameCollidingClass`, … | The name collisions a newer DataFlex brings (errors 4390, 4345, 4544) |
| `RemoveUnusedLocals`, `UnusedSourceFiles`, `UnusedUseStatements` | Dead code: unused locals, files and `Use` lines |
| `TechStackReadinessReport`, `GosubGotoReport`, `LegacySqlReport`, … | Reports that change nothing — worksheets for the decisions only a developer can make |
| ...and many more | Plus anything you write yourself |

Each function declares how it is called with `{ MethodType }`:

| Mode | What it operates on |
|---|---|
| `eStandardFunction` | One source line at a time. Fast, precise, line-by-line changes. |
| `eRemoveFunction` | One source line, for deletions. |
| `eEditorFunction` | A whole source file, in the editor. |
| `eOtherFunction` / `eOtherFunctionAll` | A whole file as a string array, or all selected files — for changes that span lines or files. |
| `eReportFunction` / `eReportFunctionAll` | Read-only analysis of one file, or across every file in the run. |

You declare the mode; the engine does the calling.

---

## Built right

- **More than 3,300 unit tests in over 180 test fixtures**, run by a DFUnit-based test program. Every refactoring function has its own tests — the legacy form that must change, and the modern look-alikes, comments, string literals and line continuations that must not.
- **A layered architecture**: low-level helpers, the lexer/tokenizer, the expression parser, initialization and error handling, and the public refactoring functions each in their own class, with the function library split into one file per family.
- **The TestBench**: put legacy code in, run one function, and see the result side by side. Iterate in seconds.
- **Command line and CI**: export any setup to an INI file and run it unattended (`/bm`), or run the **CI scan** (`/scan`) — it fails the build only on findings that are not in a saved baseline, and writes SARIF that GitHub shows on a pull request.
- **Two user interfaces on one engine**: DFRefactor FlexTron (the main program) and the classic Windows interface.
- **Open source, MIT licensed.** The whole repository, including the test suite, is on GitHub, with a complete online manual.

---

## Who it's for

- **Teams maintaining DataFlex codebases** that have accumulated several generations of idioms and need to modernize without rewriting everything by hand.
- **Developers and consultants doing DataFlex version migrations** — to DataFlex 25 and 26 today — who want a repeatable, reviewable process instead of search-and-replace and hope.
- **Anyone writing DataFlex today** who wants consistent, modern syntax across contributions from several developers — on every pull request, with the CI scan.
- **Anyone extending DataFlex tooling** — DFRefactor's small core and large, self-describing function library is a working example of that design in DataFlex.

---

## Get started

You need **DataFlex Studio 2026 (DataFlex 26)**. See [README.md](README.md) for the details. The short version:

1. Clone the repository (or download the ZIP).
2. Open **`DFRefactorFlexTron.sws`** in DataFlex Studio. The Studio installs the library packages it uses.
3. Compile `DUFUpdateProgram.src` (it creates and updates the database), then `DFRefactorFT.src`.
4. Run DFRefactor FlexTron, select the workspace you want to modernize, and press **Check**.

The manual is online: **https://nilssve.github.io/DfRefactor/**

To try a single function on a sample of legacy code, use the TestBench. To run the test suite, compile and run `UnitTests.src`.

---

## Contributing

New refactoring functions, fixes, tests and small legacy code samples that DFRefactor handles badly are all welcome. [CONTRIBUTING.md](CONTRIBUTING.md) explains how, and [AGENTS.md](AGENTS.md) describes the project for developers and AI coding assistants alike. Issues labelled [good first issue](https://github.com/NilsSve/DfRefactor/labels/good%20first%20issue) are a good place to start.

---

## Need help, or want it done for you?

See [SUPPORT.md](SUPPORT.md) for bug reports, feature requests, and paid refactoring services from RDC Tools International — codebase audits, targeted refactors, custom refactoring functions, full DataFlex version migrations, and team training.
