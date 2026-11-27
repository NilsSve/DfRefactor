// ReportRefactorFunctions.inc
//
// The REPORT family of refactoring functions, #Include'd into the oRefactorFuncLib object so
// they read and compile exactly as if they were written there.
//
// What they have in common: they change nothing. Each walks the selected files (eReportFunctionAll)
// and writes a worksheet - where a workspace uses legacy Gosub, the Embedded-SQL commands, the
// registry commands, character-mode constructs, mismatched function returns, its TechStack
// readiness, and the Deep Scan's obsolete symbols - for the developer to decide from.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    /* Deep Scan (cDeepScanner.pkg): the source-driven complement to the Modernization Analyzer.
       The Analyzer triages what the COMPILER reports - but most of the retired language surface
       compiles silently (If Not, Chain, Cmdline, the Reg_* family, char-mode leftovers) or the
       user wants a map BEFORE compiling anything. This report scans the selected files against
       a catalog seeded from the docs' "Obsolete Commands, Functions & Other Symbols" list (187
       symbols incl. each page's replacement guidance, harvested 2026-07-10). Detection is
       context-aware (see cDeepScanner.pkg's header): command-form-only symbols match in command
       position only, comparison modes only on condition lines, everything comment/literal-safe
       via _CodeOnlyLine + boundary-aware matching. Findings carry the SAME eMod* triage
       categories as the Analyzer so a later phase can feed the analyze grid / fix-plan flow;
       for now the report names the routed refactor function (or the documented replacement)
       per finding. NO {ModRecipe} - there is no compiler message to route; that absence is
       this function's reason to exist.
       UNPUBLISHED BY DESIGN (Nils 2026-07-12): { Published = False } is PERMANENT, not merely the
       Alpha 3 gate. Deep Scan is a DEDICATED flow - the dashboard button runs RunDeepScan, which
       builds cDeepScanner directly, so this function is never on that path. As a report-only entry
       in the MANUAL function picker it would only DUPLICATE the button and confuse. Keep it False
       even when CB_DeepScanEnabled goes True for Alpha 4. (No {ModRecipe} -> no recipe-table effect.)
       See the gate notes on CB_DeepScanEnabled in RefactorConstants.h.pkg. */
    { Published = False }
    { Description = """
        Reports only. Makes no changes to the source code.
        Analyze Source (Deep Scan): scans the selected source files for obsolete DataFlex commands, functions and symbols, without compiling, so the code that the compiler never warns about is found at its line.
        Text in comments and strings is never matched, and symbols that exist as both commands and functions (Left, Mid, Pos, Trim ...) are only matched as commands; the function forms are modern and are ignored.
        Each finding names the refactoring function that converts it, or the modern replacement to make by hand.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Deep Scan: obsolete-symbol report written (see log) }
        """ }
    Function DeepScanObsoleteSymbols String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        String sHomePath sLogFile sFilePath sRoute
        String[] asCode
        tDeepScanRule[] aRules
        tDeepScanHit[] aHits
        Integer iCh iFile iFileLast iTotal iN i
        Boolean bPanel bCancel

        Get Create (RefClass(cDeepScanner)) to ho
        If (ho = 0) Begin
            Error "Could not create cDeepScanner object. (Function: DeepScanObsoleteSymbols)"
            Function_Return 0
        End
        Get LoadDeepScanRules of ho (DeepScanRulesJsonPath(ho)) to aRules

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_DeepScanReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Send Destroy of ho
            Function_Return 0
        End

        Writeln channel iCh "Analyze Source - obsolete commands, functions & other symbols  (report only - no changes made)."
        Writeln channel iCh "Source-driven: found by analyzing the code itself, not the compiler output - most of these"
        Writeln channel iCh "constructs produce NO compiler warning. Categories:"
        Writeln channel iCh "  [Auto-fix]  an existing refactor function converts it - run the named function"
        Writeln channel iCh "  [Review]    a refactor function/report addresses it - review, then run the named function"
        Writeln channel iCh "  [Explain]   no safe automatic transform - the modern replacement is described"
        Writeln channel iCh ""

        Move 0 to iTotal
        Move False to bCancel
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per
        // file - otherwise it looks frozen when this is the only function run.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Analyze Source - File No:" "Analyzing source for obsolete symbols:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Get ScanLines of ho (&asCode) (&aRules) to aHits
            Move (SizeOfArray(aHits)) to iN
            If (iN > 0) Begin
                Writeln channel iCh ("=== " + sFilePath + " ===")
                For i from 0 to (iN - 1)
                    If (aHits[i].sRefactorFn <> "") ;
                        Move ("-> run " + aHits[i].sRefactorFn + "   (" + aHits[i].sHint + ")") to sRoute
                    Else ;
                        Move ("-> " + aHits[i].sHint) to sRoute
                    Writeln channel iCh ("Ln " + Pad(String(aHits[i].iLine), 6) + "[" + DSCategoryText(ho, aHits[i].eCategory) + "]  " + Pad(aHits[i].sSymbol, 28) + sRoute)
                Loop
                Writeln channel iCh ""
                Add iN to iTotal
            End
            // Mid-run cancel (the Cancel button): a *All function gets ONE call for all files,
            // so the engine's per-file Cancel_Check cannot fire while we scan. Poll the safe
            // accessor (NEVER Cancel_Check - it consumes the signal) and bail; the engine's
            // outer Cancel_Check then runs the confirm pipeline once.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send Destroy of ho
        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " finding(s)."
        Function_Return iTotal
    End_Function

    /* FunctionReturnMismatchReport - the DECLARATION-level view of DF 25/26 error 4544 ("ambiguous
       return type in expression"). DataFlex message names are workspace-global: every Function /
       Property / Register_Function declaration REGISTERS a return type on the shared message id, and
       when two declarations of ONE name disagree, the newer compiler rejects every expression-style
       call of that name - in files that have nothing whatever to do with the class responsible. A
       clean DF 19.1 build never showed it.

       Which is why this reports DECLARATIONS, not the lines the compiler points at. The LegacyApp case
       (Nils, 2026-07-22): a third-party hash-table library declares Value as Variant / Variant / Number
       across three classes, DataFlex declares it String in nine of its own packages, and roughly 765
       expression call sites spread over 141 files go 4544 - while the library that caused it is
       referenced by twelve. Rewriting the 765 is the workaround; renaming the three is the fix.

       The install's OWN declarations are read live (InstallNameDeclsForNames) because without them the
       advice is wrong in the commonest case. "Align every declaration to one return type" is useless
       when DataFlex holds the name with a different type - you cannot change its side, so the only
       thing that clears the error is renaming yours. Getting that backwards costs a day.

       REPORT ONLY - renaming touches (often third-party) library code and is a human decision, so
       nothing is rewritten. Logs to the Backup folder; surfaced via the 'Other Log Files' toolbar
       button. Mirrors TypeToStructReport.

       Was NameCollisionReport, whose PART 2 inventoried error-4390 backports off a source scan of the
       install packages. That detector could not see names the RUNTIME owns (Split) and so contradicted
       the compiler; the guided findings list drives 4390 off the compiler message instead, which is
       where that job now lives. Dropping PART 2 is what let this report be named for what it does. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Finds the declarations behind error 4544 in DataFlex 25 and 26: one message name that is declared with more than one return type.
        It lists every declaration of each such name, both in the workspace and in the target DataFlex, so that you can fix the few declarations that cause the error, instead of the hundreds of calls that it reports.
        Names whose declarations are all marked Overloaded are listed separately, and are not counted: DataFlex chooses between them by the number of parameters, so several return types are valid, and neither 4544 fix is needed.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: declarations that disagree on a return type (DF25 error 4544) }
        """ }
    Function FunctionReturnMismatchReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath sNameOrig sParam sMcWhat sMcWhy sMajority sDeclClass
        String[] asCode asColNames asColNamesLc asOtherLogFiles asKeep asEmptyNames asInstNameLc asMcDecls asMcOdd asOwnerClasses asMcTypes
        String[] asOvlNames
        Integer iCh iFile iFileLast i j k iLast iCollisions iErroring iLatent
        Integer iOwnTypes iDfDecls iDfTypes iOwnDecls iGlobalDecls iGuardVer iOvlState m iOvlLast
        Integer[] aiCallCounts aiFileCounts
        Boolean bPanel bCancel bScanFailed bExtDup bIsComProxy
        tWorkspacePaths WS
        tNameDecl[] aAllDecls aFileDecls aInstDecls aOwn aDf aOvl
        String[] asEmptyCode

        Get psHomeTarget of ghoApplication to sHomePath
        // No workspace, no report: the log belongs in the workspace's backup folder, never in the root of a drive.
        If (Trim(sHomePath) = "") ;
            Function_Return 0
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_ReturnMismatchReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) ;
            Function_Return 0
        Move (Trim(sParameter)) to sParam
        // The workspace's own version, resolved ONCE and exactly as the guard converters resolve it -
        // so the duplicate-external advice below shows the precise directive they would write.
        Get pTargetWS of ghoApplication to WS
        Get DfVersionToMacroNumber WS.sDfVersion to iGuardVer

        Writeln channel iCh "Contested declaration report  (report only - no changes made)."
        Writeln channel iCh ""
        Writeln channel iCh "Two things can make a declaration contested, and this report covers both:"
        Writeln channel iCh "  RETURN-TYPE MISMATCH (error 4544) - one name declared with more than one type."
        Writeln channel iCh "  NAME ALREADY IN USE  (error 4390) - the name belongs to something else already;"
        Writeln channel iCh "                        when both sides are External_Functions, the same Windows"
        Writeln channel iCh "                        API is simply declared twice."
        Writeln channel iCh "Each block below says which one it is; the fix is different for each."
        Writeln channel iCh ""
        Writeln channel iCh "DataFlex message names are workspace-global. When two declarations of ONE name disagree"
        Writeln channel iCh "on the return type, DF 25/26 rejects EVERY expression-style call of that name (error 4544),"
        Writeln channel iCh "including in files that never touch the class responsible. DF 19.1 resolved it silently."
        Writeln channel iCh ""
        Writeln channel iCh "So the fix is at the few DECLARATIONS below, NOT at the (often hundreds of) call sites the"
        Writeln channel iCh "compiler points at. Each name lists every declaration of it - the ones DataFlex ships first,"
        Writeln channel iCh "then the workspace's - because DataFlex's side cannot be changed. If it holds the name with a"
        Writeln channel iCh "different type, aligning the workspace's declarations with EACH OTHER will not clear the error."
        Writeln channel iCh "Renaming them will, and every other call site then compiles untouched."
        Writeln channel iCh ""
        // ... with ONE exception, said here because this paragraph is read before any block below and
        // otherwise sends the reader looking for declarations that are none of their business.
        Writeln channel iCh "THE EXCEPTION is a name the workspace never declares - a DataFlex COM-wrapper method such as"
        Writeln channel iCh "ComItem, say - where every disagreeing declaration is DataFlex's own. Nothing there can be"
        Writeln channel iCh "renamed or aligned, and that name's block below says so: for those, the fix IS at the call"
        Writeln channel iCh "sites (each one becomes a Get statement)."
        Writeln channel iCh ""
        Writeln channel iCh "ERRORING = the name is used in an expression somewhere, so it 4544s today."
        Writeln channel iCh "LATENT   = a real conflict, but no expression call site found - harmless until there is one."
        Writeln channel iCh ""
        Writeln channel iCh "Note: if the source tree holds more than one copy or version of a library (VpeBase3/5/6,"
        Writeln channel iCh "two vwin32fh.pkg), only the COMPILED copy matters - a name listed only across such twins is"
        Writeln channel iCh "not a real collision. Check against the Use graph."
        Writeln channel iCh ""

        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        If (bPanel = True) Begin
            // Two file passes are budgeted: harvest declarations, then (if any collide) count call
            // sites. The install pass budgets itself on top when it runs.
            Set piMaximumTot of ghoStatusPanel to (2 * (iFileLast + 1))
            Set piPosition   of ghoProgressBar to 0
            Set piAdvanceBy  of ghoProgressBar to 1
        End

        // ---- Pass 1: harvest every Function / Property / Register_Function declaration ----
        Move False to bCancel
        Move "" to sDeclClass
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            If (bPanel = True) Begin
                // "File No: x of: y" - an eReportFunctionAll gets all files at once, so we set the
                // caption ourselves (the engine only does it for line-by-line functions).
                Set Caption_Text   of ghoStatusPanel to ("Declarations - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text     of ghoStatusPanel to "Scanning declarations:"
                Set TableName_Text of ghoStatusPanel to sFilePath
                Send DoAdvanceTot of ghoStatusPanel
            End
            /* A GENERATED COM PROXY DECLARES NOTHING OF YOURS. These files sit in the workspace
               (Excel9.pkg, MSWORD.pkg, msoutl.pkg, the Codejock wrappers), so every declaration in
               them counted as one of YOUR OWN - and ComItem, a name DataFlex generates and owns,
               was therefore offered as a one-click rename. It renamed 214 declarations across nine
               vendor packages and unresolved every "Set ComItem" in the workspace (WinServ,
               2026-08-26).

               Harvest nothing from them and the classification comes right on its own: with no
               declarations of its own the name is neither renameable nor alignable, and the flow
               falls through to the call-site rewrite - which is exactly what this report's own
               header has always promised for "a name you never declare yourself". The file is not
               even read: an empty array walks to nothing below. */
            Get _IsDataFlexCOMProxyClassesFile sFilePath to bIsComProxy
            If (bIsComProxy = True) Begin
                Move asEmptyCode to asCode
            End
            Else Begin
                Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            End
            // Scale the per-file bar to THIS file's lines; the walkers below step it as they go.
            If (bPanel = True) ;
                Send _StartFileLineProgress (SizeOfArray(asCode))
            Get _NameDeclsFromLines of Self asCode sFilePath to aFileDecls
            // Which CLASS (if any) declares the narrowed name here - the rename converter walks class
            // families, so a name declared only at global scope is out of its reach and must not be
            // offered as a one-click rename (Nils 2026-07-22: "SPLITByKey" on a global function).
            If (sParam <> "" and sDeclClass = "") Begin
                Get _ClassesDeclaringName of Self asCode sParam to asOwnerClasses
                If (SizeOfArray(asOwnerClasses) > 0) ;
                    Move (asOwnerClasses[0]) to sDeclClass
            End
            Move (SizeOfArray(aFileDecls) - 1) to iLast
            For j from 0 to iLast
                Move aFileDecls[j] to aAllDecls[SizeOfArray(aAllDecls)]
            Loop
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop
        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""

        // The contested set: names declared with >= 2 distinct return types (the pure, tested core).
        Get _CollidingNames of Self aAllDecls to asColNames
        // A caller can NARROW the report to one name (sParameter). The findings list does this: its rows
        // are per-name, so opening the same workspace-wide report from each of them told the user
        // nothing about the row they actually clicked (Nils 2026-07-21).
        If (sParam <> "") Begin
            Move asEmptyNames to asKeep
            Move (SizeOfArray(asColNames) - 1) to iLast
            For i from 0 to iLast
                If (Lowercase(Trim(asColNames[i])) = Lowercase(sParam)) ;
                    Move asColNames[i] to asKeep[SizeOfArray(asKeep)]
            Loop
            Move asKeep to asColNames
        End
        // NARROWED TO A NAME THE WORKSPACE DOES NOT SELF-COLLIDE ON: keep it anyway. The findings rows
        // are driven by what the COMPILER said, and the commonest 4544 shape is exactly this - ONE
        // workspace declaration against DataFlex's own. Dropping it here is what made the report read
        // as a flat contradiction of the row that opened it (Nils 2026-07-21); the install pass below
        // now has the declarations needed to explain it properly.
        If (sParam <> "" and SizeOfArray(asColNames) = 0) ;
            Move sParam to asColNames[0]
        Move (SizeOfArray(asColNames) - 1) to iLast

        // ---- Pass 2: count EXPRESSION-STYLE call sites per contested name, to split ERRORING (used in
        //      an expression -> actually 4544s today) from LATENT (a real conflict, but never
        //      expression-called, so harmless until it is). Only worth a re-read when names collide. ----
        For i from 0 to iLast
            Move (Lowercase(asColNames[i])) to asColNamesLc[i]
            Move 0 to aiCallCounts[i]
        Loop
        If (SizeOfArray(asColNames) > 0 and bCancel = False) Begin
            For iFile from 0 to iFileLast
                Move asFiles[iFile] to sFilePath
                If (bPanel = True) Begin
                    Set Caption_Text   of ghoStatusPanel to ("Call sites - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text     of ghoStatusPanel to "Counting expression call sites:"
                    Set TableName_Text of ghoStatusPanel to sFilePath
                    Send DoAdvanceTot of ghoStatusPanel
                End
                Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
                If (bPanel = True) ;
                    Send _StartFileLineProgress (SizeOfArray(asCode))
                Get _CountNameCallsInLines of Self asCode asColNamesLc to aiFileCounts
                For i from 0 to iLast
                    Move (aiCallCounts[i] + aiFileCounts[i]) to aiCallCounts[i]
                Loop
                Get pbUserCancelRequested of ghoEngine to bCancel
                If (bCancel = True) ;
                    Move iFileLast to iFile
            Loop
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to ""
        End

        // ---- Pass 3: what the TARGET DataFlex declares for these same names. The whole difference
        //      between advice that works and advice that merely sounds right (see the header). ----
        If (SizeOfArray(asColNames) > 0 and bCancel = False) Begin
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to "Reading the target DataFlex's own declarations:"
            For i from 0 to iLast
                Move (Lowercase(Trim(asColNames[i]))) to asInstNameLc[i]
            Loop
            Get InstallNameDeclsForNames of Self asInstNameLc bPanel to aInstDecls
            Set psMismatchDeclClass to sDeclClass
            Get pbInstallScanFailed to bScanFailed
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to ""
        End

        // ---- One block per contested name: who declares it, how badly, and what to actually do ----
        Move 0 to iCollisions
        Move 0 to iErroring
        Move 0 to iLatent
        For i from 0 to iLast
            Move asColNames[i] to sNameOrig
            Get _DeclsForName of Self aAllDecls  sNameOrig to aOwn
            Get _DeclsForName of Self aInstDecls sNameOrig to aDf
            Get _DistinctTypeCount of Self aOwn to iOwnTypes
            // The DataFlex side's own spread matters when the workspace declares the name NOWHERE: 51
            // ComItem declarations across the CodeJock/Crystal wrappers, Variant vs String vs Integer,
            // ARE the 4544 all by themselves - and then no rename or align of ours can reach it.
            Get _DistinctTypeCount of Self aDf  to iDfTypes
            Move (SizeOfArray(aDf))  to iDfDecls
            Move (SizeOfArray(aOwn)) to iOwnDecls
            // DUPLICATE-EXTERNAL flavor: every declaration on BOTH sides is an External_Function -
            // the "already defined as an external_function" 4390 (the WinInet pair, LegacyApp
            // 2026-07-23). The name is not owned by "something else": both sides bind the SAME
            // Windows API, so the fix is delete-or-guard the duplicate, not a rename.
            // ONE of yours being an External_Function is enough - see _IsDuplicateExternalPair for
            // why requiring ALL of them sent a wrapper class's method to the rename lane.
            Get _IsDuplicateExternalPair of Self aOwn aDf to bExtDup
            If (sParam <> "") ;
                Set pbMismatchExternalDup to bExtDup
            Writeln channel iCh ("=== " + sNameOrig + " ===")
            // MIXED Overloaded usage is its OWN error - 4390 "this method was previously defined as
            // non-overloaded" - and it breaks the build whether or not anyone calls the name in an
            // expression. Neither 4544 fix addresses it, so say what it actually is.
            Get _OverloadedState of Self aOwn to iOvlState
            If (iOvlState = CI_OverloadMixed) Begin
                Writeln channel iCh "  (MIXED Overloaded usage - some declarations carry the Overloaded token and some do not."
                Writeln channel iCh "   That is error 4390, not 4544: DataFlex refuses to let an overloaded and a"
                Writeln channel iCh "   non-overloaded method share a name. Add the token to all of them, or to none.)"
            End
            If (bExtDup = True) ;
                Writeln channel iCh "  (duplicate External_Function - both sides declare the same Windows API)"
            If (bExtDup = False and (iOwnTypes >= 2 or iDfDecls > 0)) ;
                Writeln channel iCh "  (return-type mismatch - one name, more than one type)"
            // "your declarations agree with each other" needs declarations of yours to agree - with none
            // in the scanned source there is nothing to say that about (2026-08-19).
            If (bExtDup = False and iOwnTypes < 2 and iDfDecls = 0 and iOwnDecls > 0) ;
                Writeln channel iCh "  (name already in use - the workspace's declarations agree with each other; something else owns the name)"
            If (bExtDup = False and iOwnTypes < 2 and iDfDecls = 0 and iOwnDecls = 0) ;
                Writeln channel iCh "  (name already in use - nothing in the scanned source declares it; something outside it owns the name)"
            Writeln channel iCh ""
            If (iDfDecls = 0 and bScanFailed = True) Begin
                Writeln channel iCh ("  Could NOT read the target DataFlex's packages (" + psInstallScanPath(Self) + "),")
                Writeln channel iCh  "  so whether DataFlex declares this name is unknown - not confirmed absent."
                Writeln channel iCh ""
            End
            If (iDfDecls > 0) Begin
                Writeln channel iCh ("  DataFlex declares this name itself, in " + String(iDfDecls) + " place(s). You cannot change these:")
                For k from 0 to (iDfDecls - 1)
                    Writeln channel iCh ("      " + aDf[k].sKind + " returns " + aDf[k].sReturnType + "   " + aDf[k].sFile + " line " + String(aDf[k].iLine))
                Loop
                Writeln channel iCh ""
            End
            If (iOwnDecls > 0) Begin
                // "with 1 different return type(s)" was nonsense on a name whose declarations agree - and
                // that is the 4390 case, where the problem is the NAME, not the type (Nils 2026-07-22).
                If (iOwnTypes >= 2) ;
                    Writeln channel iCh ("  The workspace declares it in " + String(iOwnDecls) + " place(s), disagreeing over " + String(iOwnTypes) + " return types:")
                If (iOwnTypes < 2) ;
                    Writeln channel iCh ("  The workspace declares it in " + String(iOwnDecls) + " place(s), all agreeing on the return type:")
                For k from 0 to (iOwnDecls - 1)
                    Writeln channel iCh ("      " + aOwn[k].sKind + " returns " + aOwn[k].sReturnType + "   " + aOwn[k].sFile + " line " + String(aOwn[k].iLine))
                Loop
                Writeln channel iCh ""
            End
            If (aiCallCounts[i] > 0) Begin
                Writeln channel iCh ("  Status: ERRORING - about " + String(aiCallCounts[i]) + " expression call site(s) use this name.")
                Increment iErroring
            End
            Else Begin
                Writeln channel iCh "  Status: LATENT - no expression call site found (harmless until the name is used in one)."
                Increment iLatent
            End
            Writeln channel iCh ""
            // WHICH OF THE TWO FIXES APPLIES, decided here where both sides are known, rather than left
            // for the caller to guess. DataFlex owning the name means its type cannot move, so ours must
            // be renamed. Nothing outside owning it means a rename would carry the SAME disagreement to
            // the new name - there the fix is to align the odd one out (Nils 2026-07-22: pbSilent).
            Move "" to sMajority
            Set piMismatchDfDecls to iDfDecls
            If (iDfDecls > 0) ;
                Set psMismatchDfType to (aDf[0].sReturnType)
            If (iDfDecls = 0 and iOwnTypes >= 2) Begin
                Get _MajorityReturnType of Self aOwn to sMajority
                Set psMismatchMajorityType to sMajority
                If (sMajority <> "") Begin
                    Get pasReturnMismatchOdd to asMcOdd
                    For k from 0 to (iOwnDecls - 1)
                        If (Lowercase(Trim(aOwn[k].sReturnType)) <> Lowercase(sMajority)) Begin
                            Move ("Change this " + sNameOrig + " declaration from " + aOwn[k].sReturnType + " to " + sMajority) to sMcWhat
                            Move ("The other declaration(s) say " + sMajority + ", and nothing outside this workspace uses the name - so aligning this one clears the ambiguity without touching a single call site.") to sMcWhy
                            Move (aOwn[k].sFile + "|" + String(aOwn[k].iLine) + "|" + sMcWhat + "|" + sMcWhy) to asMcOdd[SizeOfArray(asMcOdd)]
                        End
                    Loop
                    Set pasReturnMismatchOdd to asMcOdd
                End
            End
            Writeln channel iCh "  What to do:"
            If (bExtDup = True) Begin
                // The "#"/"!" are Character()-built (35/33): a literal directive token in a .pkg
                // string is consumed by FMAC during OUR own compile (the #COMMAND lesson). The
                // version-check guard is deliberately the SAME one the guard converters write - it is
                // order-independent, where an "IFDEF get_" probe only works when DataFlex's
                // declaration happens to compile first (Nils 2026-07-23).
                Writeln channel iCh  "      DataFlex now ships this External_Function declaration itself. The workspace's declaration is a"
                Writeln channel iCh  "      duplicate of the same Windows API - delete it, or wrap it in the same"
                Writeln channel iCh  "      version guard the globals converter writes, so it only compiles on"
                Writeln channel iCh  "      releases where DataFlex does not declare it:"
                If (iGuardVer > 0) ;
                    Writeln channel iCh ("          " + Character(35) + "IF (" + Character(33) + "@ <= " + String(iGuardVer) + ")")
                If (iGuardVer = 0) ;
                    Writeln channel iCh ("          " + Character(35) + "IF (" + Character(33) + "@ <= <the workspace's version, e.g. 191>)")
                Writeln channel iCh  "              External_Function ... (the workspace's declaration)"
                Writeln channel iCh ("          " + Character(35) + "ENDIF")
                Writeln channel iCh  "      GuardDuplicateExternalFunctions applies exactly this, and the guided flow"
                Writeln channel iCh  "      offers to run it when this report closes."
                Writeln channel iCh  "      Mind the entry points before deleting: if the workspace's declaration binds the ANSI variant (...A)"
                Writeln channel iCh  "      and DataFlex's the wide one (...W), they are the same API for numeric"
                Writeln channel iCh  "      arguments - only calls passing text buffers need a closer look."
            End
            Else If (iDfDecls > 0 and iOwnDecls > 0) Begin
                // The common shape, and the one where the obvious fix is the wrong one.
                Writeln channel iCh ("      DataFlex holds this name as " + aDf[0].sReturnType + ", and that cannot change. Aligning the")
                Writeln channel iCh ("      " + String(iOwnDecls) + " declaration(s) above with EACH OTHER will NOT clear the error - they have to")
                Writeln channel iCh  "      stop using the name at all. Rename them, and the calls that target THOSE objects;"
                Writeln channel iCh  "      every other call site of the name then compiles untouched."
            End
            Else If (iOwnTypes >= 2) Begin
                Writeln channel iCh ("      These " + String(iOwnDecls) + " declaration(s) disagree with each other, and nothing outside this")
                Writeln channel iCh  "      workspace uses the name - so a RENAME would carry the same disagreement to the new"
                Writeln channel iCh  "      name and change nothing. Align them instead."
                If (sMajority <> "") Begin
                    Writeln channel iCh ("      Most of them say " + sMajority + ". Changing the odd one(s) above to match clears this")
                    Writeln channel iCh  "      without touching a single call site."
                End
                If (sMajority = "") ;
                    Writeln channel iCh  "      They split evenly, so there is no odd one out - decide which type is correct."
            End
            Else If (iOwnDecls > 0 and bScanFailed = True) Begin
                // NOT a finding - a folder we could not open. Saying "DataFlex does not declare it" here
                // would be inventing evidence out of a failed read (Nils 2026-07-22: DF 26 uninstalled
                // mid-session while the workspace still targeted it).
                Writeln channel iCh  "      CANNOT TELL. The target DataFlex's Pkg folder could not be read, so whether"
                Writeln channel iCh  "      DataFlex declares this name is unknown - and that is what decides between"
                Writeln channel iCh  "      renaming the workspace's declarations and aligning them."
                Writeln channel iCh ("      Looked in: " + psInstallScanPath(Self))
                Writeln channel iCh  "      Point the workspace at an installed DataFlex version and run this again."
            End
            Else If (iOwnDecls > 0) Begin
                Writeln channel iCh  "      The compiler rejects this name, but DataFlex does not declare it in its own Pkg"
                Writeln channel iCh  "      folder either - so it comes from the runtime, from a class method, or from an"
                Writeln channel iCh  "      External_Function. A version guard cannot help with those. RENAME the"
                Writeln channel iCh  "      declaration(s) above."
            End
            /* NOTHING OF YOURS DECLARES THE NAME (iOwnDecls = 0). Three states, and until 2026-08-19 all
               three fell into one catch-all that said "no declaration of this name was found in the
               scanned source ... Widen the scope, or check your Use graph."

               On Nils's WinServ that line was printed directly UNDER 51 declarations of ComItem, each with
               its file and line, in DataFlex 26's own cCJCommandBars / cCJGridControl / cCrystal* wrappers
               (Variant, String and Integer among them). Nothing was outside anything, there was no scope
               to widen, and the Use graph had nothing to do with it - while the dialog that opened seconds
               later, off the SAME data, said correctly that DataFlex owns the name and the call rewrite is
               the only fix. The ladder above keys on OUR declaration count alone, so the commonest shape
               of all - a COM-wrapper name you merely CALL - had no branch of its own.

               A name you never declare is not yours to rename or align, so all three branches end at the
               same place: the call sites. That is what the "Rewrite the calls" offer does, and it changes
               no declaration. */
            Else If (iDfDecls > 0) Begin
                If (iDfTypes >= 2) Begin
                    Writeln channel iCh ("      Nothing in the scanned source declares this name - DataFlex does, in the " + String(iDfDecls) + " place(s)")
                    Writeln channel iCh ("      listed above, and they do NOT agree on the return type (" + String(iDfTypes) + " different types between them).")
                    Writeln channel iCh  "      That side cannot change, so there is nothing here to rename or align."
                End
                Else Begin
                    Writeln channel iCh ("      Nothing in the scanned source declares this name - DataFlex does, in the " + String(iDfDecls) + " place(s)")
                    Writeln channel iCh ("      listed above, all returning " + aDf[0].sReturnType + ". That side cannot change, so there is nothing here")
                    Writeln channel iCh  "      to rename or align; whatever disagrees with it sits outside the scanned source."
                End
                Writeln channel iCh  "      The fix is to stop calling it from INSIDE AN EXPRESSION: each such call becomes a"
                Writeln channel iCh  "      Get statement on the line before, which is offered when this report closes"
                Writeln channel iCh  "      (ChangeAmbiguousCallToGet). No declaration is touched, and no return type changes."
            End
            Else If (bScanFailed = True) Begin
                Writeln channel iCh  "      CANNOT TELL. Nothing in the scanned source declares this name, and the target"
                Writeln channel iCh  "      DataFlex's Pkg folder could not be read either - so whether DataFlex declares it,"
                Writeln channel iCh  "      and with which types, is unknown."
                Writeln channel iCh ("      Looked in: " + psInstallScanPath(Self))
                Writeln channel iCh  "      Point the workspace at an installed DataFlex version and run this again. The"
                Writeln channel iCh  "      call-site rewrite offered when this report closes works whoever owns the name."
            End
            Else Begin
                Writeln channel iCh  "      No declaration was found - not in the scanned source, and not in the target"
                Writeln channel iCh  "      DataFlex's Pkg folder either. So the name comes from the runtime, from a class"
                Writeln channel iCh  "      method or an External_Function, or from a source folder that was not scanned."
                Writeln channel iCh  "      Nothing here can be renamed. If one of the workspace's libraries declares it, add that"
                Writeln channel iCh  "      folder to the scope and run this again so this report can name the declarations;"
                Writeln channel iCh  "      otherwise rewrite the call sites as Get statements (offered when this report closes)."
            End
            Writeln channel iCh ""
            // HAND THE DECLARATION SITES ON, don't just print them. The report answers "which declarations
            // disagree"; these rows make the answer walkable - double-click opens the file at the line. The
            // three lines here are the entire fix for a workspace-wide 4544 (Nils 2026-07-22).
            // How many of ours are Global - the hand-rename dialog describes the declarations, and
            // "outside any class" and "Global" are different properties that can appear in any mix.
            Move 0 to iGlobalDecls
            For k from 0 to (iOwnDecls - 1)
                If (aOwn[k].bGlobal = True) ;
                    Increment iGlobalDecls
            Loop
            Set piMismatchGlobalDecls to iGlobalDecls
            Get pasReturnMismatchDecls    to asMcDecls
            Get pasReturnMismatchOwnTypes to asMcTypes
            For k from 0 to (iOwnDecls - 1)
                If (bExtDup = True) Begin
                    Move ("Delete or version-guard this duplicate External_Function " + sNameOrig) to sMcWhat
                    If (iGuardVer > 0) ;
                        Move ("DataFlex ships the same Windows API declaration itself and that side cannot change - wrap this one in " + Character(35) + "IF (" + Character(33) + "@ <= " + String(iGuardVer) + ") ... " + Character(35) + "ENDIF (GuardDuplicateExternalFunctions applies it), or delete it.") to sMcWhy
                    If (iGuardVer = 0) ;
                        Move ("DataFlex ships the same Windows API declaration itself and that side cannot change - version-guard this one (GuardDuplicateExternalFunctions applies it), or delete it.") to sMcWhy
                End
                Else Begin
                    Move ("Rename this " + sNameOrig + " declaration (it returns " + aOwn[k].sReturnType + ")") to sMcWhat
                    If (iDfDecls > 0) ;
                        Move ("DataFlex ships " + sNameOrig + " as " + aDf[0].sReturnType + " in " + String(iDfDecls) + " place(s) and that cannot change, so aligning the workspace's declarations with each other will not clear the error.") to sMcWhy
                    If (iDfDecls = 0) ;
                        Move ("Declared with " + String(iOwnTypes) + " different return types in this workspace - align them all to one type, or rename the odd one out.") to sMcWhy
                End
                Move (aOwn[k].sFile + "|" + String(aOwn[k].iLine) + "|" + sMcWhat + "|" + sMcWhy) to asMcDecls[SizeOfArray(asMcDecls)]
                // The bare type beside it, for the even-split align offer (2026-09-03): the user picks the
                // type when no majority can, and needs to see what each declaration returns to choose.
                Move (aOwn[k].sFile + "|" + String(aOwn[k].iLine) + "|" + aOwn[k].sReturnType) to asMcTypes[SizeOfArray(asMcTypes)]
            Loop
            Set pasReturnMismatchDecls    to asMcDecls
            Set pasReturnMismatchOwnTypes to asMcTypes
            Increment iCollisions
        Loop
        If (iCollisions = 0) Begin
            Writeln channel iCh "(no name in this scope is declared with conflicting return types)"
            Writeln channel iCh ""
        End

        // ---- Legal overload sets: listed, never counted as collisions -----------------------------
        // These carry several return types under one name and are FINE - every declaration has the
        // Overloaded token, so DataFlex resolves the call by parameter count and no 4544 can arise
        // (measured on DF26, 2026-08-23). They are shown rather than dropped silently, because a
        // report that says nothing about what it skipped reads as "there was nothing there" - and
        // because DataFlex's own documentation calls overloading obsolete.
        Get _OverloadedNames of Self aAllDecls to asOvlNames
        Move (SizeOfArray(asOvlNames) - 1) to iOvlLast
        If (iOvlLast >= 0) Begin
            Writeln channel iCh ""
            Writeln channel iCh "--- Overloaded names (NOT errors, not counted above) ---"
            Writeln channel iCh "Each of these declares one name with more than one return type, and EVERY declaration"
            Writeln channel iCh "carries the Overloaded token - so DataFlex picks the right one by parameter count and"
            Writeln channel iCh "the name cannot raise error 4544. Nothing needs fixing. Listed only because DataFlex"
            Writeln channel iCh "documents overloading as obsolete: if you want to retire it, give the variants distinct"
            Writeln channel iCh "names or take a variable argument list with Num_Arguments. Neither 4544 fix applies here,"
            Writeln channel iCh "and both refuse to touch these names."
            Writeln channel iCh ""
            For m from 0 to iOvlLast
                Get _DeclsForName of Self aAllDecls asOvlNames[m] to aOvl
                Writeln channel iCh ("=== " + asOvlNames[m] + " (overloaded, " + String(SizeOfArray(aOvl)) + " declarations) ===")
                For k from 0 to (SizeOfArray(aOvl) - 1)
                    Writeln channel iCh ("    returns " + aOvl[k].sReturnType + "   " + aOvl[k].sFile + " (ln " + String(aOvl[k].iLine) + ")")
                Loop
                Writeln channel iCh ""
            Loop
        End

        If (bCancel = True) Begin
            Writeln channel iCh "*** Cancelled by the user - this report is INCOMPLETE. ***"
            Writeln channel iCh ""
        End
        // The tail names the overload sets too: a total that counted only collisions would leave the
        // reader wondering what the section above it was.
        Writeln channel iCh ("Total: " + String(iCollisions) + " name(s) examined [" + String(iErroring) + " erroring, " + String(iLatent) + " latent] across " + String(SizeOfArray(aAllDecls)) + " declaration(s) scanned, plus " + String(iOvlLast + 1) + " legal overloaded name(s) listed and not counted.")
        Send rfCloseOutput iCh

        If (iCollisions > 0) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Move sLogFile to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Function_Return iCollisions
    End_Function

    /* GosubGotoReport - the Phase-1 worksheet for retiring legacy Gosub subroutines (and the
       Gotos interleaved with them; Nils 2026-07-09 - see the Gosub/Goto groundwork notes). The
       compiler flags Gosub (4533 "Obsolete command: Gosub") and the computed ON..GOSUB dispatch
       (4533 "Obsolete command: On"), but emits NOTHING for Goto - Goto is still legal DataFlex -
       so the report is where the developer gets the complete control-flow picture: which
       subroutines are mechanically extractable into Procedures, which need hand-untangling and
       WHY, plus every Goto with a concrete rewrite hint per class. The per-subroutine verdict is
       CONTROL-FLOW only: legacy flat modules share their variables across every subroutine, so
       an extraction still needs a variable-scope review (a Phase-2 concern). Analysis cores are
       pure + unit-tested: _GosubLineLabel / _GosubCallTargets / _GosubReturnKind / _GotoTarget /
       _GosubAuditFile (cRefactorFuncLib). Intra-subroutine goto/label pairs remain legal inside
       an extracted Procedure, so they never block a CANDIDATE verdict - only boundary-CROSSING
       gotos do.
    */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists every legacy Gosub subroutine (labels, calls, Gosub_Return lines and ON..GOSUB statements), and for each subroutine says whether it can be converted to a procedure (CANDIDATE) or must be changed by hand (MANUAL), and why.
        Each Goto gets a hint for how to rewrite it: a jump forward becomes an If/Else block, a jump backward becomes a While or Repeat loop, and a jump out of a block must be untangled first.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { ModRecipe = 4533 | command: Gosub | Suggest }
        { ModRecipe = 4533 | command: On | Suggest }
        { SummaryText = Report: Gosub subroutines + Goto rewrite hints }
        """ }
    Function GosubGotoReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_GosubGotoReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Gosub / Goto usage report  (report only - no changes made)."
        Writeln channel iCh "Per subroutine (a label called via Gosub): CANDIDATE = its control flow is self-contained"
        Writeln channel iCh "and a Procedure extraction is mechanical; MANUAL = the listed reasons must be untangled"
        Writeln channel iCh "first. NOTE: the verdict is control-flow only - a legacy flat module shares its variables"
        Writeln channel iCh "across every subroutine, so review the extracted code's variable use in any case."
        Writeln channel iCh "The 'ConvertGosubToProcedure' refactoring function converts the CANDIDATE subset for you"
        Writeln channel iCh "(subroutine -> global Procedure, Gosub -> Send, ON..GOSUB -> Case) and promotes the shared"
        Writeln channel iCh "file-scope variables to Global_Variable, each tagged for review; MANUAL subs are left alone."
        Writeln channel iCh "Every Goto is classified with a rewrite hint. Goto is still legal DataFlex (the compiler"
        Writeln channel iCh "emits no warning for it) - the hints are for finishing a module by hand:"
        Writeln channel iCh "  forward skip       -> rewrite as an If/Else block around the skipped lines"
        Writeln channel iCh "  backward jump      -> a loop - rewrite as While / Repeat-Until"
        Writeln channel iCh "  boundary-crossing  -> untangle first; it BLOCKS converting that subroutine"
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per
        // file - otherwise it looks frozen when this is the only function run.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Gosub/Goto usage - File No:" "Mapping Gosub subroutines + Gotos:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _GosubAuditFile (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel (the Cancel button): a *All function gets ONE call for all files,
            // so the engine's per-file Cancel_Check cannot fire while we scan. Poll the safe
            // accessor (NEVER Cancel_Check - it consumes the signal) and bail; the engine's
            // outer Cancel_Check then runs the confirm pipeline once.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " finding(s)."
        Function_Return iTotal
    End_Function

    /* LegacyDbApiReport - inventories the legacy Database-API attribute COMMANDS (File_Size,
       Size_of_Field, Get_Current_Lockcount, Get_date_format, Get_number_format, Get_filelist,
       Set_filelist, Get_Date_Attribute, Ifchange) and, for each site, names the modern
       Get_Attribute / Set_Attribute replacement. REPORT ONLY - no source changes. Most deliberately
       get no auto-converter: File_Size has a READ form and a SET-max form with reversed args; Ifchange
       is structural (an If-wrapped Get_Attribute DF_FILE_CHANGED); Size_of_Field is ambiguous
       (DF_FIELD_LENGTH vs DF_FIELD_PRECISION); Get_Date_Attribute reads Y2K/epoch no-op state INTO a
       variable. Get_date_format is the exception since 2026-09-15 - ChangeGetDateFormatToAttribute
       converts it, value-exact - and stays listed here so the worksheet is the whole inventory.
       So this worksheet lists the sites for a hand migration. Logs to the Backup folder;
       surfaced via the 'Other Log Files' toolbar button. Mirrors TypeToStructReport. Matched at
       COMMAND position (first word, on a strings/comment-masked split) so a mention never flags. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists the legacy database attribute commands (File_Size, Size_of_Field, Get_Current_Lockcount, Get_date_format, Get_number_format, Get_filelist, Set_filelist, Get_Date_Attribute and Ifchange), and for each line names the modern Get_Attribute or Set_Attribute replacement.
        These lines must be migrated by hand, because they have several forms, change the structure of the code, or are ambiguous, so nothing is changed here. Get_date_format has its own converter, ChangeGetDateFormatToAttribute.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: legacy Database-API commands -> modern Get_Attribute/Set_Attribute sites }
        """ }
    Function LegacyDbApiReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_LegacyDbApiReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Legacy Database-API command / constant worksheet  (report only - no changes made)."
        Writeln channel iCh "Each maps to a modern Get_Attribute / Set_Attribute call, but NOT by a simple token swap -"
        Writeln channel iCh "every one needs a hand migration (see the per-command note). This ALSO lists the obsolete DB-file"
        Writeln channel iCh "constants / predefined variables (Fieldindex, Filenumber, DF_FILE_PRIMARY_INDEX_TRIGGER,"
        Writeln channel iCh "DF_FILE_TRANSLATE_OEM_TO_ANSI) matched anywhere on the line. This lists the sites."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per file -
        // otherwise it looks frozen when this is the only function run. The scan is one call per file
        // (the pure _LegacyDbApiScanFile core), so only the TOTAL bar advances, like GosubGotoReport.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Legacy DB-API - File No:" "Scanning Database-API commands:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _LegacyDbApiScanFile of Self (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: a *All function gets ONE call for all files, so the engine's per-file
            // Cancel_Check cannot fire while we scan. Poll the safe accessor (NEVER Cancel_Check - it
            // consumes the signal) and bail; the engine's outer Cancel_Check then confirms once.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " legacy Database-API command / constant site(s)."
        Function_Return iTotal
    End_Function

    /* TechStackReadinessReport (Nils 2026-11-20) - where a workspace uses what DataFlex's TechStack, the DataFlex 27
       previews, changes or does not run yet: per topic, with its sites file by file. REPORT ONLY. The topics, their
       text and the DAW page each comes from are cRefactorFuncLib._TechStackTopics / _TechStackReportLines; the scan
       is the PURE _TechStackScanFile. Nils chose a report over analyzer rows: the data layer alone touches nearly
       every line of a Windows application, which would bury the grid. The summary comes first, so the sites are
       held until every file is read. A file counts as Windows UI by its extension (.vw .dg .sl .rv), or as a .src
       that names Start_UI. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Counts, for each topic and each file, where the workspace uses something that DataFlex's TechStack (the DataFlex 27 previews) changes:
        - the data layer: Open, Relate, Add_Server_File, Make_File, File_Number, Main_File, Validate_Save, Field_Validate_msg, Entry_Item <table>.<column> and the table commands;
        - cHttpTransfer;
        - what TechStack does not support yet: the Windows user interface, COM/ActiveX, SOAP web services, and External_Function outside Windows;
        - a String moved into a Boolean, which TechStack converts differently.
        Each topic names the Data Access page it is based on. TechStack is a preview, so read the report as a list of where the work is, not as a final verdict.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: what TechStack (DataFlex 27 previews) changes, counted per topic and file }
        """ }
    Function TechStackReadinessReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath sExt
        String[] asCode asReport asEmpty asSections asHead
        Integer[] aiSites aiFiles aiBefore
        Integer iCh iFile iFileLast iTotal iN iTopic i iRead
        Boolean bPanel bCancel bWindowsUI

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_TechStackReadinessLogFile) to sLogFile
        For iTopic from 0 to (CI_TSTopicCount - 1)
            Move 0 to aiSites[iTopic]
            Move 0 to aiFiles[iTopic]
        Loop
        Move 0 to iTotal
        Move 0 to iRead
        Move False to bCancel
        Move (SizeOfArray(asFiles) - 1) to iFileLast
        // This report loops files itself (eReportFunctionAll), so it drives the status panel per file.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "TechStack - File No:" "Counting what TechStack changes:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Increment iRead
            Move (Lowercase(ParseFileExtension(sFilePath))) to sExt
            Move (sExt = "vw" or sExt = "dg" or sExt = "sl" or sExt = "rv") to bWindowsUI
            If (bWindowsUI = False and sExt = "src") ;
                Get _FileContainsText (&asCode) "start_ui" to bWindowsUI
            Move aiSites to aiBefore
            Move asEmpty to asReport
            Get _TechStackScanFile (&asCode) bWindowsUI (&aiSites) (&asReport) to iN
            If (iN > 0) Begin
                For iTopic from 0 to (CI_TSTopicCount - 1)
                    If (aiSites[iTopic] > aiBefore[iTopic]) ;
                        Move (aiFiles[iTopic] + 1) to aiFiles[iTopic]
                Loop
                Move ("=== " + sFilePath + " ===") to asSections[SizeOfArray(asSections)]
                For i from 0 to (SizeOfArray(asReport) - 1)
                    Move asReport[i] to asSections[SizeOfArray(asSections)]
                Loop
                Move "" to asSections[SizeOfArray(asSections)]
                Add iN to iTotal
            End
            // Mid-run cancel: the safe accessor, NEVER Cancel_Check (it consumes the signal).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End
        Get _TechStackReportLines (&aiSites) (&aiFiles) iRead to asHead
        For i from 0 to (SizeOfArray(asHead) - 1)
            Writeln channel iCh asHead[i]
        Loop
        For i from 0 to (SizeOfArray(asSections) - 1)
            Writeln channel iCh asSections[i]
        Loop
        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " site(s) where the workspace uses something TechStack changes."
        Function_Return iTotal
    End_Function

    /* LegacyDfPathReport - inventories the obsolete Set_dfpath command (char-mode only; it REPLACED the
       whole DFPATH environment variable). REPORT ONLY - no source changes. Modern DataFlex assembles the
       runtime search path in the cWorkspace object: psSystemDfPath (the system Lib/Usr dirs plus any you
       add) feeds psDfPath during DoAssignPaths. So there is no safe 1:1 rewrite - the fix is a per-site
       judgement: most legacy calls are redundant now (the .ws config sets the paths -> delete); to ADD a
       search dir, append to psSystemDfPath; a literal wholesale replace maps to Set psDfPath but that
       wipes the system dirs. The three options are spelled out in the report header; each site gets a
       one-liner. The scan core is the pure cRefactorFuncLib._LegacyDfPathScanFile (unit-tested); this
       wrapper does the file I/O. Mirrors LegacySqlReport. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists the obsolete Set_dfpath command, which replaced the whole DFPATH and was used in character mode, and for each line explains the modern cWorkspace alternative:
        remove the line (the paths come from the .ws configuration), add a folder to psSystemDfPath, or, rarely, Set psDfPath to replace the whole path, which also removes the system folders.
        Each line needs its own decision, not a simple replacement, so nothing is changed.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: obsolete Set_dfpath -> cWorkspace pathing (psSystemDfPath / psDfPath) sites }
        """ }
    Function LegacyDfPathReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_LegacyDfPathReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Obsolete Set_dfpath worksheet  (report only - no changes made)."
        Writeln channel iCh "Set_dfpath REPLACED the whole DFPATH environment variable (char-mode DataFlex only). Modern"
        Writeln channel iCh "DataFlex assembles the runtime search path in the cWorkspace object: psSystemDfPath (the system"
        Writeln channel iCh "Lib/Usr dirs plus any you add) feeds psDfPath during DoAssignPaths. There is no safe 1:1 rewrite;"
        Writeln channel iCh "pick per site:"
        Writeln channel iCh "  1. DELETE - usually redundant now: the .ws / .sws workspace config already defines the paths."
        Writeln channel iCh "  2. ADD a dir - append to psSystemDfPath, e.g."
        Writeln channel iCh "       Set psSystemDfPath of (phoWorkspace(ghoApplication)) to (psSystemDfPath(phoWorkspace(ghoApplication)) + ';' + <dir>)"
        Writeln channel iCh "  3. TRUE wholesale replace (rare) - Set psDfPath of (phoWorkspace(ghoApplication)) to <value>,"
        Writeln channel iCh "       but that WIPES the Lib/Usr system dirs the runtime needs - almost never what you want."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per file. The
        // scan is one call per file (the pure _LegacyDfPathScanFile core), so only the TOTAL bar advances,
        // like LegacySqlReport.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Set_dfpath - File No:" "Scanning Set_dfpath:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _LegacyDfPathScanFile of Self (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal)
            // and bail; the engine's outer Cancel_Check then confirms once (see CLAUDE.md).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " obsolete Set_dfpath site(s)."
        Function_Return iTotal
    End_Function

    /* CharacterModeInventoryReport - what a DataFlex 3.x / console-mode program carries that DataFlex
       26 has no equivalent for (Nils 2026-09-20, on taking on character-mode workspaces). REPORT
       ONLY - no source changes. The guided Check runs it silently for such a program and shows the
       totals in its notice; the notice's chip opens this log. The scan core is the pure
       cRefactorFuncLib._CharModeInventoryScanFile (unit-tested); this wrapper does the file I/O and
       publishes the totals on pCharModeInventory. Mirrors LegacyDfPathReport. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists what a DataFlex character-mode program contains that has no equivalent in DataFlex 26: screen images (/name ... /*), screen and keyboard commands (Page, Accept, Entry, Gotoxy ...), user interface objects (Entry_Form, Entry_List, Menu, Query ...) and Keyproc handlers, for each file, with totals.
        Those parts must be rewritten by hand; the rest of the code can be modernized with DFRefactor.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: character-mode inventory (images, screen commands, UI objects, Keyprocs) }
        """ }
    Function CharacterModeInventoryReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        tCharModeInventory Inv
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Set pCharModeInventory to Inv          // zeroed until the scan below has run
        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_CharModeInventoryLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) ;
            Function_Return 0

        Writeln channel iCh "Character-mode inventory  (report only - no changes made)."
        Writeln channel iCh ""
        Writeln channel iCh "This program was written for DataFlex character mode (it starts with Use UI)."
        Writeln channel iCh "DataFlex 26 has no character mode, so the program cannot be compiled by DataFlex 26 until"
        Writeln channel iCh "it has been rewritten as a Windows program (one that starts with Use DFAllEnt.pkg)."
        Writeln channel iCh ""
        Writeln channel iCh "Most of the code can be modernised automatically by this tool. The screen handling cannot:"
        Writeln channel iCh "it has to be rewritten by hand. This report lists every place that needs that hand work."
        Writeln channel iCh "  IMAGES           the screen layouts, written as /name ... /*"
        Writeln channel iCh "                   -> become dbViews and dbForms (layouts used for printing can stay, for Output)"
        Writeln channel iCh "  SCREEN COMMANDS  Page, Accept, Entry, Entry_Display, Gotoxy, Show, Cls and the like"
        Writeln channel iCh "                   -> replaced by data-entry objects, or simply removed"
        Writeln channel iCh "  UI OBJECTS       Entry_Form, Entry_List, Menu, Query, Selection_List and the like"
        Writeln channel iCh "                   -> become dbView, dbForm and dbGrid objects, and CodeJock menus"
        Writeln channel iCh "  KEYPROC          keyboard handlers"
        Writeln channel iCh "                   -> become OnKey / On_Key procedures on the object"
        Writeln channel iCh "The counts below show how much of this program has to be rewritten by hand. Everything else -"
        Writeln channel iCh "Chain, Status, If-Not, Insert, Gosub, indicators, old comparison words - this tool changes for you."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Character-mode inventory - File No:" "Counting the screen layer:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _CharModeInventoryScanFile of Self (&asCode) (&asReport) (&Inv) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Set pCharModeInventory to Inv
        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel (" site(s) in " + String(Inv.iFiles) + " file(s): " + String(Inv.iImages) + " image(s), " + String(Inv.iScreenCmds) + " screen / keyboard command(s), " + String(Inv.iUiObjects) + " UI object(s), " + String(Inv.iKeyprocs) + " Keyproc handler(s).")
        Function_Return iTotal
    End_Function

    /* LegacyFieldOptionsReport - inventories the character-mode field ENTRY OPTIONS (autofind, capslock,
       displayonly, findreq, forceput, noenter, noput, skipfound, retainall, zero_suppress, autofind_ge) and
       names the modern DataDictionary Field_Options target per site. REPORT ONLY - no source changes: the
       modern equivalent lives in the DataDictionary CLASS (you set Field_Options / DD_* on the DD field),
       a CROSS-FILE change away from the old inline declaration, so there is no safe in-place rewrite. The
       scan is a boundary-aware token match (_FindKeywordPos, same as the Deep Scan grid) - it can in
       principle hit a same-named identifier; harmless for a read-only report (noted in the header). The
       scan core is the pure cRefactorFuncLib._LegacyFieldOptionsScanFile (unit-tested); this wrapper does
       the file I/O. Only the ENABLED entry-option Deep Scan rules are covered (the generic/noisy ones stay
       Explain). Mirrors LegacyDfPathReport. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists the character-mode field options (autofind, capslock, displayonly, findreq, forceput, noenter, noput, skipfound, retainall, zero_suppress and autofind_ge), and for each line names the modern Field_Options setting in the data dictionary.
        The modern setting belongs in the data dictionary class, which is a change in another file, so nothing is changed.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: char-mode field entry options -> DataDictionary Field_Options sites }
        """ }
    Function LegacyFieldOptionsReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_LegacyFieldOptionsReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Character-mode field entry-options worksheet  (report only - no changes made)."
        Writeln channel iCh "The old inline field options (autofind, noenter, displayonly, ...) are set on the modern side in"
        Writeln channel iCh "the DataDictionary CLASS via Field_Options / the DD_* constants (e.g. Set_Field_Options DD_NOENTER)."
        Writeln channel iCh "That is a CROSS-FILE change (the DD, not the declaration), so nothing is rewritten - this just lists"
        Writeln channel iCh "each site with its target. Matching is a boundary-aware token scan, so a same-named identifier could"
        Writeln channel iCh "occasionally appear here; verify each against its context."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per file. The
        // scan is one call per file (the pure _LegacyFieldOptionsScanFile core), so only the TOTAL bar
        // advances, like LegacyDfPathReport.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Field options - File No:" "Scanning field entry options:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _LegacyFieldOptionsScanFile of Self (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal)
            // and bail; the engine's outer Cancel_Check then confirms once (see CLAUDE.md).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " character-mode field entry-option site(s)."
        Function_Return iTotal
    End_Function

    /* LegacyRegistryReport - inventories the legacy Windows-Registry / profile-string / INI COMMANDS
       (Reg_Open_Key / Reg_Close_Key / Reg_Create_Key / Reg_Enum_* / Reg_*_Access_Rights, the
       Get/Set_Profile_String family, Get/Set_Registry_Root, Read_dfini) and names the modern class
       for each. REPORT ONLY - no source changes. The docs point every one at the cRegistry class
       (Read_dfini -> cIniFile) but give no 1:1 method map, because cRegistry is an OBJECT that holds
       the key path in properties - not the legacy Reg_Open_Key -> hKey -> Reg_Close_Key handle model,
       and the Reg_Enum_* enumerations used callbacks that have no modern equivalent (loop rewrite).
       So this worksheet lists the sites + the migration shape for a hand port. Get_Program_Key is
       left Explain (no modern equivalent). The scan core is the pure cRefactorFuncLib.
       _LegacyRegistryScanFile (unit-tested); this wrapper does the file I/O. Mirrors LegacyDbApiReport. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists the legacy commands for the Windows registry, profile strings and INI files (Reg_Open_Key, Reg_Enum_Value, Get/Set_Profile_String, Get/Set_Registry_Root, Read_dfini ...), and for each line names the modern class to use: cRegistry, or cIniFile for Read_dfini.
        cRegistry works with objects, not with the legacy handles and callbacks, so these lines must be changed by hand.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: legacy Registry / profile-string / INI commands -> cRegistry / cIniFile sites }
        """ }
    Function LegacyRegistryReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_LegacyRegistryReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Legacy Windows-Registry / profile-string / INI command worksheet  (report only - no changes made)."
        Writeln channel iCh "Modern target: the cRegistry class (registry + profile strings) and cIniFile (Read_dfini). cRegistry"
        Writeln channel iCh "is an OBJECT that HOLDS the key path in properties - NOT the legacy handle/callback model - so most of"
        Writeln channel iCh "these collapse rather than 1:1-swap, and the Reg_Enum_* enumerations need a loop rewrite. This lists the"
        Writeln channel iCh "sites; see the cRegistry class reference (docs.dataflex.dev .../VdfClassRef/WebAndWindows/cRegistry/)."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per file.
        // The scan is one call per file (the pure _LegacyRegistryScanFile core), so only the TOTAL
        // bar advances, like GosubGotoReport / LegacyDbApiReport.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Legacy Registry - File No:" "Scanning Registry / profile commands:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _LegacyRegistryScanFile of Self (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal)
            // and bail; the engine's outer Cancel_Check then confirms once (see CLAUDE.md).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " legacy Registry / profile / INI command site(s)."
        Function_Return iTotal
    End_Function

    /* LegacySqlReport - inventories the legacy Embedded-SQL COMMANDS (SQLConnect / SQLOpen / SQLPrepare
       / SQLExecute / SQLFetch / SQLGetData / the CLI_*_Attribute set / DB2_/MSSQL_SetConstraint, ~25 in
       all) and names the modern cSQL* class.method for each. REPORT ONLY - no source changes. The docs
       give a clean per-command method map (cSQLHandleManager for connections, cSQLConnection for open
       statements, cSQLStatement for prepare/execute/fetch), but it is a STATEFUL object port: the legacy
       commands share an implicit connection/statement handle, the classes hold them as objects you
       instantiate and thread - not a 1:1 token swap. Two renames the docs call out are surfaced per site
       (SQLGetArguments -> SQLGetArgument; SQLBindFetchFile / SQLFileFetch -> SQLBindFile). The scan core
       is the pure cRefactorFuncLib._LegacySqlScanFile (unit-tested); this wrapper does the file I/O.
       Mirrors LegacyRegistryReport. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists the legacy embedded SQL commands (SQLConnect, SQLOpen, SQLPrepare, SQLExecute, SQLFetch, SQLGetData, CLI_*_Attribute, DB2_/MSSQL_SetConstraint ...), and for each line names the modern cSQL class and method (cSQLHandleManager, cSQLConnection or cSQLStatement).
        The modern classes work with objects that keep their own state, so this is not a simple replacement of words, and nothing is changed.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Report: legacy Embedded SQL commands -> cSQL* class.method sites }
        """ }
    Function LegacySqlReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath
        String[] asCode asReport asEmpty
        Integer iCh iFile iFileLast iTotal iN
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_LegacySqlReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Legacy Embedded SQL command worksheet  (report only - no changes made)."
        Writeln channel iCh "The SQL command set maps to the cSQL* classes: cSQLHandleManager (connections), cSQLConnection"
        Writeln channel iCh "(open statements) and cSQLStatement (prepare / execute / fetch). The docs give a per-command"
        Writeln channel iCh "class.method (below), but this is a STATEFUL object port - the legacy commands share an implicit"
        Writeln channel iCh "connection/statement, the classes hold them as objects you instantiate and thread - NOT a 1:1 token"
        Writeln channel iCh "swap. This lists each site with its target method; see the cSQL* class reference on docs.dataflex.dev."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per file.
        // The scan is one call per file (the pure _LegacySqlScanFile core), so only the TOTAL bar
        // advances, like GosubGotoReport / LegacyRegistryReport.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Legacy SQL - File No:" "Scanning Embedded SQL commands:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asReport
            Get _LegacySqlScanFile of Self (&asCode) (&asReport) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asReport
                Add iN to iTotal
            End
            // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal)
            // and bail; the engine's outer Cancel_Check then confirms once (see CLAUDE.md).
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " legacy Embedded SQL command site(s)."
        Function_Return iTotal
    End_Function
