# Refactoring Catalog Map

How DFRefactor's catalog relates to the refactorings in Martin Fowler's *Refactoring: Improving the Design of Existing Code* (Addison-Wesley; 2nd edition, 2019).

The catalog has two distinct parts:

1. **Canonical refactorings from Fowler's book**, adapted to DataFlex syntax.
2. **DataFlex-specific legacy-syntax modernizations** — transformations with no analogue in Fowler's catalog because they address constructs unique to DataFlex's evolution from the 1980s onward.

The DataFlex-specific section is the larger part of the catalog. That's intentional: DataFlex carries a longer history of accumulated legacy syntax than most living languages, and DFRefactor exists primarily to mechanize the modernization of that syntax. The Fowler-book refactorings are present because they're useful at the same time — they're a natural complement, not the primary focus.

---

## Direct mappings to Fowler's catalog

| Fowler refactoring | DFRefactor function | Notes |
|---|---|---|
| **Remove Dead Code** *(Remove Unused Variable)* | `RemoveUnusedLocals` | Scans every Function/Procedure body and drops locals that are never referenced. |
| **Find Dead Code** *(read-only precursor)* | `ReportUnusedSourceFiles`, `ReportUnusedUseStatements` | Identify source files and `Use` statements that are never referenced. Generate a report; do not modify code. |
| **Replace Class** *(structural replacement)* | `RefactorGridToCJGrid`, `RefactorDbGridTocDbCJGrid` | Replace legacy `(Db)Grid` class hierarchies with the modern `c(Db)CJGrid` family, including column-object generation. |
| **Decompose Conditional** *(in spirit)* | `SplitInlineIfElseLine` | Expands a single-line `If…Else` into a multi-line `Begin/End` block, making each branch its own statement. Configurable via `EnumList`. |

---

## DataFlex-specific transformations

These have no analogue in Fowler's catalog. They exist because DataFlex evolved over four decades and accumulated syntax that has since been deprecated or replaced.

### Legacy syntax modernization

| DFRefactor function | What it does |
|---|---|
| `ChangeLegacyIndicators` | Rewrites 1980s square-bracket `[Found]` indicator syntax into modern `If` / `Move` expressions. |
| `ChangeSquareBracketsIndicators` | Lighter pass — converts `[Found]` / `[FindErr]` to `(Found)` / `(FindErr)` expressions only. |
| `ChangeCurrent_ObjectToSelf` | Replaces the legacy `Current_Object` reference with the modern `Self`. |
| `ChangeIfNotCommandToExpression` | Rewrites the legacy `If Not` command form into a modern expression form. |
| `ChangeInToContains` | Replaces the deprecated `In` operator with the modern `Contains` function. |
| `ChangeUClassToRefClass` | Replaces the obsolete `UClass` keyword with `RefClass`. |
| `ChangeDfTrueDfFalse` | Replaces the deprecated `DFTRUE` / `DFFALSE` legacy constants with the standard literals `True` / `False`. |
| `ChangeSysdate4` | Modernizes the obsolete `Sysdate4` call. |
| `ChangeGetAddress` | Modernizes legacy `Get_Address` syntax. |
| `ChangeLegacyOperators` | Updates deprecated operator syntax. |
| `ChangeLegacyShadow_State` | Updates the legacy `Shadow_State` syntax. |
| `ChangeCalcToMoveStatement` | Rewrites the legacy `Calc` keyword into a modern `Move` statement. |

### Command-to-function conversions

DataFlex's evolution moved string operations from statement-style commands to function-call expressions. These all rewrite the older form:

`ChangeInsertCommandToFunction`, `ChangeLeftCommandToFunction`, `ChangeRightCommandToFunction`, `ChangeLengthCommandToFunction`, `ChangePosCommandToFunction`, `ChangeReplaceCommandToFunction`, `ChangeTrimCommandToFunction`, `ChangeZeroStringCommandToFunction`.

### Removal of deprecated decorators

| DFRefactor function | What it does |
|---|---|
| `RemoveLocalKeyWord` | Drops the now-redundant `Local` keyword from variable declarations. |
| `RemovePropertyPrivate` / `RemovePropertyPublic` | Strips visibility decorators that are no longer required. |
| `RemoveProjectObjectStructure` | Removes obsolete project-object scaffolding. |
| `RemoveSansSerif` | Removes a deprecated font directive. |

---

## Formatting and hygiene

These aren't refactorings in Fowler's strict sense — they don't change structure — but they leave the code in a better state and are typically run as a final polish pass:

`EditorNormalizeCase`, `EditorReIndent`, `NormalizeArrayNotation`, `RemoveMultipleBlankLines`, `RemoveTrailingSpaces`, `RemoveEndComments`, `RemoveStudioGeneratedComments`, `RemoveOldStudioMarkers`, `RestyleDDOs`, `A_InsertSpaceAfterParenthesis`.

---

## Notes for readers coming from Fowler's book

- The mapping above is **partial** — not every DFRefactor function maps to a named Fowler refactoring, and not every named Fowler refactoring is mechanized in DFRefactor.
- Some DFRefactor functions are looser interpretations of Fowler's catalog (`SplitInlineIfElseLine` is "in the spirit of" Decompose Conditional rather than a literal implementation).
- The full source for each function lives in [`AppSrc/oRefactorFuncLib.pkg`](AppSrc/oRefactorFuncLib.pkg). Each function carries a `{Description}` meta-tag with a human-readable summary and example transformations.
