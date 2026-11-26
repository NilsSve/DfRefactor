// DeadDependencies.inc
//
// Spliced into cBaseFuncLib._CreateDeadDependencyArray by #Include - no meaning on its own.
//
// A DEAD DEPENDENCY is a package family with no successor: it cannot be modernised, only removed
// and replaced by something else entirely. That is a different thing from an obsolete CLASS or
// COMMAND, which DFRefactor converts, and from a package DataFlex has absorbed, which it swaps.
// There is nothing here to convert or swap, so there is nothing worth refactoring INSIDE these
// files - the whole file is going away.
//
// WHY SKIPPING THEM MATTERS. Measured over the DF18/DF19 trees 2026-08-09: of 1,163 legacy Type
// blocks, 229 sit in crystal* files and 69 in winql* - 26% of the entire Type-to-Struct surface,
// plus 231 Win32 declarations. Every one of those is a finding somebody has to read, triage and
// dismiss, about code that is going to be deleted. Scanning them does not just waste effort; it
// buries the findings that matter.
//
// Same reasoning as _IsDataFlexCOMProxyClassesFile, which has excluded Studio-generated COM proxies
// from collection for years: refactoring a file that will be REGENERATED is wasted work, and
// refactoring one that will be DELETED is the same waste wearing a different hat.
//
// WARN BROADLY, SKIP NARROWLY. The Deep Scan rule for Crystal matches any Use line whose filename
// contains "crystal", because a warning that misses a new wrapper is useless. SKIPPING is the
// stricter act - it removes findings the user would otherwise see - so it is confined to the tokens
// below, and every skipped file is COUNTED AND NAMED on the board. A silent exclusion reads as
// coverage; a reported one is a decision the user can disagree with.
//
// NO CUSTOMER-SPECIFIC NAMES HERE, deliberately. The trees carry wrappers named after the companies
// that wrote them; a TOKEN match covers those without putting anyone's name in this repository.
//
// TO EXTEND: add the token and say why the family is dead - a successor that exists means it is not.

    Send _AddDeadDependency (&asDeadDeps) "crystal" "Crystal Reports - support dropped, no later version. The reports themselves move to another product (DataFlex Reports); no source change carries a report definition across."
    Send _AddDeadDependency (&asDeadDeps) "winql"   "WinQL32 - a 1997 query/report library with no successor. Older than Crystal and equally unmendable: there is no newer version to target."
