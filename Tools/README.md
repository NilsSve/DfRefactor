# Tools

Developer scripts. Nothing here is compiled into the product or shipped; they are checks you run by
hand while working on the source.

## VerifyConvertedStructs.py

Checks every `Struct` that ConvertWin32TypeBuffersToStructs emitted against the harvested SDK
catalogue (`Data/WinAPIStructCatalog.json`). Member TYPES come from the SDK and member NAMES from
the author's legacy block, so the check is positional on type.

```
py Tools\VerifyConvertedStructs.py E:\SomeWorkspace
```

**Run it after every conversion run.** On 2026-08-30 a DEVNAMES conversion emitted four `Integer`
where Windows reads four `WORD` - sixteen bytes instead of eight, every member after the first at
the wrong offset - and the run reported "1 lines Converted ... Process completed OK". Nothing in the
summary, the run notes or the unit suite could see it. Only comparing the emitted members against
the catalogue could, and doing that by hand does not scale past one struct.

It knows the catalogue's two row flavours and treats them differently, which is the distinction that
mattered: a `DF|` row is a ready-made DataFlex declaration harvested from win32metadata and is
compared directly, while a C prototype is mapped to DataFlex at EXACT width first. Every struct that
went wrong was a C row; every one that was fine was a DF row.

Pointer-ish types (Handle / Pointer / LongPtr / ULongPtr / Address) are treated as interchangeable -
they are all pointer-sized and the choice between them is a readability decision, not a layout one.

## VerifyMarkupEdit.py

Answers one question: **did this edit change what the app emits?**

```bash
py Tools\VerifyMarkupEdit.py AppSrc\DashboardFT.vw
```

Compares each statement against the same statement at `HEAD`, after substituting every
`FTMarkupBuilders` builder and every markup constant for its own definition — `CellHtml(c, x)`
becomes `'<td class="c">' + x + '</td>'`, `CS_WarnSign` becomes `'&#9888;'`. If the emitted text
still matches, the markup cannot have moved. Exit code 1 if anything differs.

**Why it exists.** The 2026-08-25 sweep replaced hand-written HTML in DataFlex string literals with
the builder vocabulary, and every edit was meant to be invisible at runtime. The compiler cannot
tell you whether it was — swap a tag for the wrong builder and you get markup that compiles
perfectly and renders wrongly. This caught 26 such lines that day.

**Keep it fed.** Every `CS_` string constant is read from `AppSrc\RefactorConstants.h.pkg` at run
time, so a new `Define` needs no edit here. New *builders* need one line in the tables at the top of the script.
Forget that and it will report a correct change as a difference — which happened three times in one
afternoon, each time looking exactly like a bug in the code.

**What it deliberately cannot see:** grouping parentheses (ignoring them is what makes a legitimate
fold provable), a stripped *call* parenthesis (that is compiler error 4328), and escaping
(`BoldText` escapes, `BoldHtml` does not — choosing between them is not something this can check).

## RunTimeHistory.py — was that run actually slow?

```
py Tools\RunTimeHistory.py "<workspace>\DFRefactor_Backup\DFRefactorLogFile.txt"
```

Reads the run log the tool already keeps and places the newest run against the spread of
**comparable** runs — same workspace, similar file count — rather than against a single remembered
number.

It exists because on 2026-07-29 a single 11:59 pass was quoted as "the baseline", and six runs over
byte-identical inputs that day ranged 10:43 to 17:00. A later 17:00 run then looked like a
regression while the hot path had not changed by one byte. The pass is disk-bound, so any other
disk activity moves it.

Use it before instrumenting anything. `--raw N` prints one log block if the labels ever change.

## HarvestWin32Projection.py — refill the Win32 catalogues from win32metadata

```
git clone https://github.com/frankchengproductions/Win32_DataFlex_Projection <clone>
py Tools\HarvestWin32Projection.py <clone>
```

Merges DF-flavoured rows (ready-made DataFlex declarations, MIT-licensed, generated from
Microsoft's win32metadata) into `Data\WinAPICatalog.json` and `Data\WinAPIStructCatalog.json`.
Harvests the intersection with the corpus scan (`AppSrc\WindowsAPI.json`) by default — the APIs
these workspaces actually declare — plus the transitive struct closure; `--all` takes everything.
Identity keys (`dll|entry`, struct `NAME`) make re-runs idempotent; rows the harvest does not
carry stay untouched. The file's own docstring records the normalisation rules and why each
exists.

## RegenerateDesignPlaceholders.py

Refreshes the Studio-Designer literals of every FlexTron HTML box from the running program (probe -> build -> run -> paste). The docstring at the top of the script is the whole procedure; `py Tools\RegenerateDesignPlaceholders.py` prints it.
