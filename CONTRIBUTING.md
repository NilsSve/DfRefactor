# Contributing to DFRefactor

Thank you for wanting to help. DFRefactor aims to be *the* place for refactoring work on DataFlex
code, and every new refactoring function, bug fix and test makes it better for everyone who has
legacy DataFlex code to move forward.

This page says how to contribute. For how the code is put together — the build, the function
library, the meta-tags and the rules a refactoring function must follow — read
[`AGENTS.md`](AGENTS.md). It is written for AI coding assistants, but it is just as useful for people.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## What is welcome

- **New refactoring functions** — a legacy construct DFRefactor does not convert yet, or a report
  that helps a developer decide what to change.
- **Bug fixes** — a function that changes code it should leave alone, misses code it should change,
  or writes code that does not compile.
- **Tests** — more cases for an existing function, especially the odd shapes real code has.
- **Documentation** — the help, the README, `AGENTS.md`, examples.
- **Legacy code samples** — small, anonymized snippets that DFRefactor handles badly. Often the most
  useful contribution of all.

For anything larger than a small fix, please open an [issue](https://github.com/NilsSve/DfRefactor/issues)
or a [discussion](https://github.com/NilsSve/DfRefactor/discussions) first, so we can agree on the
approach before you spend time on it. Issues labelled
[**good first issue**](https://github.com/NilsSve/DfRefactor/labels/good%20first%20issue) are a good
place to start.

---

## Getting set up

You need **DataFlex Studio 2026 (DataFlex 26)**.

1. Fork the repository on GitHub and clone your fork.
2. Open **`DFRefactorFlexTron.sws`** in DataFlex Studio. The Studio installs the library packages the
   workspace pins the first time it opens. (From the command line, `df-cli config DFRefactorFlexTron.sws`
   does the same.)
3. Compile **`DUFUpdateProgram.src`** once. It brings the database in `Data\` up to date; the other
   programs run it at startup when the database is older than the code — a fresh clone's always is.
4. Compile and run **`UnitTests.src`**. Every test should pass before you change anything — if one
   does not, please report it.

You do not need the git submodules in `Libraries\`; the build uses the packages.

---

## Making a change

### A new refactoring function

1. Put it in the function library: in the `AppSrc\*RefactorFunctions.inc` file of its family if it has
   one, otherwise in `AppSrc\oRefactorFuncLib.pkg`. `AGENTS.md` has the table of families.
2. Give it the `{ Published = True }` and `{ Description }` meta-tags, with its `{ MethodType }`. If it
   fixes a compiler message, connect it with a `{ ModRecipe }` tag. `AGENTS.md` explains each one.
3. Add its tests (see below).
4. Try it on real code in the **TestBench** (`TestBench.src`): put legacy code in
   `AppSrc\LegacyCode.pkg`, run the function, and compare the result side by side — and check that
   the result compiles.

### Tests

Every change needs tests, and a bug fix needs a test that **fails without the fix**.

- Tests for a function go in `AppSrc\o<FunctionName>-Tests.pkg`: one `cTestFixture` object per
  function. A new file is registered with a `Use` line in `AppSrc\oUnit_Tests.pkg`.
- Each test is a procedure with `{ Published = True }` above it.
- Test both sides: the legacy form **is** changed, and the modern look-alike — or code in a comment
  or a string — is **not**.
- Run the whole suite before you send the pull request. Headless:
  `UnitTests64.exe -c` (add `-o results.xml` for a JUnit report, `--filter <text>` to run only some
  tests). An error raised inside a test fails that test.

### Ground rules

- **Never put a customer's code or names in the repository.** That includes source, tests, comments
  and commit messages: no workspace, file, class, table or column name from someone's private code.
  Rename and shorten a sample until it shows only the problem.
- **Keep the file format.** Studio files are UTF-8 with a byte-order mark and Windows (CRLF) line
  endings. Keep them that way — an editor that changes them turns a one-line fix into a whole-file
  diff.
- **Do not commit test-run leftovers**: changes to `AppSrc\LegacyCode.pkg`, the `Data\` folder,
  `Programs\` executables, or compiler listings.
- **One topic per pull request.** A fix and an unrelated clean-up are easier to review apart.
- A function never changes code silently in a way the developer cannot see: when in doubt, it leaves
  the line alone, or reports it instead.

---

## Sending a pull request

Open the pull request against `master`, and say in it:

- what it changes, and why;
- the legacy code it was tested on (anonymized), with the before and after;
- that the full unit test suite passes.

Checklist:

- [ ] All unit tests pass.
- [ ] New or changed behaviour has tests, including a "leave it alone" case.
- [ ] No customer code or names anywhere in the change.
- [ ] File encoding and line endings unchanged.
- [ ] `AGENTS.md` updated if the change affects what it says.

---

## Using an AI coding assistant

You are welcome to. `AGENTS.md` is read automatically by most AI coding tools (Claude Code through
`CLAUDE.md`), so the assistant starts with the project's rules. You are still responsible for the
result: review every change, and run the tests yourself before sending it.

---

## Reporting a bug or asking for a function

Use the [issue forms](https://github.com/NilsSve/DfRefactor/issues/new/choose). Include the DataFlex
version, a short code snippet that shows the problem, and what you expected to happen. For questions
and ideas, [Discussions](https://github.com/NilsSve/DfRefactor/discussions) is the place.

---

## License

DFRefactor is MIT licensed. By sending a contribution you agree that it is licensed under the same
[MIT License](LICENSE).
