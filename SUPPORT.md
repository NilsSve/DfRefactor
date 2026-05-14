# Getting help with DFRefactor

DFRefactor is open source and MIT licensed. There are two paths for support, depending on what you need.

---

## Community support (free)

- **Bug reports and feature requests** — open an issue on the GitHub repository. Include the DataFlex version, a short code snippet that triggers the problem, and what you expected to happen.
- **Pull requests** — welcome, especially for new refactoring functions. See [CLAUDE.md](CLAUDE.md) for the architecture overview and the meta-tag conventions a new refactoring function needs to follow.
- **Direct contact** — email the maintainer at [nils.svedmyr@gmail.com](mailto:nils.svedmyr@gmail.com).
- **If DFRefactor saves you a week of manual refactoring**, the [Ko-fi link in `FUNDING.yml`](FUNDING.yml) keeps the maintainer caffeinated.

---

## Paid services — RDC Tools International

DFRefactor is a powerful tool, but it's still a tool. Bringing it into a real codebase takes time — selecting the right refactoring functions, running them in the right order, reviewing output, handling edge cases that turn out to need a custom function, and verifying the test suite stays green at every step. For some teams, that's a useful exercise. For others it's time better spent shipping features, and they'd rather have someone else handle the modernization.

**RDC Tools International offers paid refactoring services on your codebase, performed by the author of DFRefactor.** Same engine, same test suite — applied by the person who knows every edge case in it firsthand.

### Typical engagements

- **Codebase audits** — run the report-only refactoring functions across your workspace and deliver a written report: legacy-syntax counts, dead code, unused source files, suspicious patterns. Useful as a first step before deciding what to refactor.
- **Targeted refactor** — modernize a specific set of idioms across the codebase. E.g. *"rewrite all legacy comparison operators"*, *"modernize all `Indicate` statements"*, *"remove all unused locals"*. You pick the transformations; we run them, review the output, and deliver a clean diff.
- **Custom refactoring function design** — when your codebase has a recurring idiom not covered by DFRefactor's built-in library, we design, implement, and unit-test a new refactoring function for it. You can keep it private to your team, or have it contributed back to the public DFRefactor codebase, where it benefits the community and gets ongoing maintenance from us at no further cost to you.
- **Full modernization** — multi-version migrations (DF 18 → DF 23, DF 23 → DF 26), full workspace passes with custom refactoring functions written for your codebase's specific idioms.
- **Team training** — a one-day workshop covering DFRefactor: writing custom refactoring functions, integrating with CI, using the TestBench for safe iteration on legacy code.

### Rates (USD, billed in arrears)

| Estimated project size | Hourly rate |
|---|---|
| 1–5 hours      | $100 |
| 5–10 hours     | $80  |
| 10+ hours      | $50  |

A discovery call (up to 30 minutes) is free. Email [nils.svedmyr@gmail.com](mailto:nils.svedmyr@gmail.com) with a rough description of your codebase — size, target DataFlex version, what you'd like cleaned up — and we'll come back with a written estimate before any work starts.

---

## Author

Built and maintained by **Nils Svedmyr** at [RDC Tools International](https://www.rdctools.com).
Contact: [nils.svedmyr@gmail.com](mailto:nils.svedmyr@gmail.com).
