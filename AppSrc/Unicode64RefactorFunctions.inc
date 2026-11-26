// Unicode64RefactorFunctions.inc
//
// The UNICODE / 64-BIT family of refactoring functions - { FnGroup = Unicode64 } - #Include'd
// into the oRefactorFuncLib object so they read and compile exactly as if they were written
// there.
//
// They are one file because they are one event. DataFlex went Unicode and 64-bit together, and
// a workspace crossing that line meets both at once: a String buffer handed to a wide API, an
// External_Function declared ANSI, a Type block whose 4-byte member is 8 bytes to Windows, a
// pointer truncated by an Integer. Fixing one of those usually means looking at the others,
// which is why the group exists as a { FnGroup } in the first place.
//
// TWO OF THESE ARE TAGGED { FnGroup = Modernization }, not Unicode64:
// ChangeExternalFunction32ToExternalFunction (a 16-bit leftover) and
// GuardDuplicateExternalFunctions. They are here because they work on the same
// External_Function declarations as the rest, and splitting GuardDuplicate* from
// GuardAnsi*WithWide would separate a pair that is read together. If you would rather the file
// be exactly one FnGroup, those two are the ones to move back.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    { Published = True }
    { Description = """
        Replaces the obsolete 'External_Function32' declaration with 'External_Function' (the '32' is removed).
        Example: External_Function32 Foo "FooA" X.DLL ... returns integer  -->  External_Function Foo "FooA" ...
        { MethodType = eStandardFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4533 | command: External_Function32 }
        { SummaryText = External_Function32 -> External_Function }
        """ }
    Function ChangeExternalFunction32ToExternalFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        tTokenizer TokenizerData
        Get pTokenizer to TokenizerData
        Get _SwapLeadingCommandKeyword (&sLine) TokenizerData "External_Function32" "External_Function" to bChanged
        Function_Return bChanged
    End_Function

    /* ChangeExternalFunctionCallers - the BYTE-LEVEL half of the legacy Win32 Type problem.

       ConvertWinAPITypeToStruct (below) handles a Type whose buffers are already reached by
       dot-member access: only the DECLARATION moves and the code around it compiles unchanged. That
       shape barely exists in real legacy code. Measured across three workspaces on 2026-08-30: of
       the 17 legacy Types the Windows catalogue covers, SEVENTEEN are reached with ZeroType / Put..At
       / GetBuff / GetAddress and NONE by dot-member alone. This converts that population - 365
       accessor lines over 16 Types on those same workspaces.

       WHY IT IS SAFE NOW AND WAS NOT IN JULY. The Tier-1 study graded these clusters and found none
       convertible, because it counted A TAKEN ADDRESS as a blocker - and every marshaled Win32
       buffer takes its address, that being how it reaches the API. Correct while the replacement
       layout was a guess; the harvested struct catalogue is what retires it, since the SDK widths
       and the alignment rule are now known. Address-taken is not a blocker here, but ONLY for a Type
       the catalogue covers.

       WHAT IT FIXES, on the real BROWSEINFO block: "lParam as dWord" where the SDK needs LongPtr,
       and no interior padding at all - 52 bytes where Windows expects 64, so SHBrowseForFolder reads
       twelve bytes past the buffer. It compiles clean today and always has.

       ALL OR NOTHING PER TYPE. One unrecognised use of a buffer refuses the whole cluster with the
       line named, because half a conversion leaves a Struct and a byte buffer as the same variable.

       A TYPE DATAFLEX SHIPS NO STRUCT FOR (2026-11-13): DEVMODE and DEVNAMES, which DataFlex's own printer-dialog
       code fills and many workspaces copied. The Struct is its Dftypes.pkg declaration copied member for member
       (cRefactorFuncLib _DfTypesStructNameFor says why it must be the same bytes) into DfTypesStructs.pkg in the
       workspace's AppSrc folder - one package, because two files of one program both fill a DEVMODE - and the file
       gets a Use for it. This function writes that package; when it cannot, the file is left as it was.
    */
    { Published = True }
    { Description = """
        Changes the code that calls a Windows API, so that it uses a modern Struct instead of a byte buffer.
        The Type block is commented out, not deleted. A Struct with the same member names and the types that the Windows SDK uses is added instead, including the padding between members that a legacy Type block cannot describe.
        Then every line that used the buffer is changed: ZeroType, Put..At, GetBuff and GetAddress become struct assignments, member access and AddressOf.
        This fixes a 64-bit error that the compiler does not report. A legacy block that declares 4 bytes where Windows reads 8 makes the struct too short, and the API then writes past its end.
        The Type is found by its name, or by its member names when the name does not match the SDK. A match by member names is reported in the run notes, so that you can check that it is the right struct.
        Every use of the buffer must be one that this function can change. If one line cannot be recognised, the whole Type is left unchanged, and the run notes name that line.
        A Type that DataFlex's Dftypes.pkg declares, but for which DataFlex has no Struct (DEVMODE, DEVNAMES), becomes a Struct that is copied member by member into DfTypesStructs.pkg in the workspace's AppSrc folder, and a Use of that file is added.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Rewritten: External_Function callers moved from Type buffers to Structs }
        """ }
    Function ChangeExternalFunctionCallers String[] ByRef asCode String sParameter Returns Integer
        String[] asNotes asBefore
        String sFile
        Integer iCount i iLast
        Boolean bGate bOK

        /* Cheap raw gate. NOT "end_type" alone: the second pass exists precisely for files that have
           no Type block - the declaration lived in an obsolete install package and only the accessors
           are here - so gating on End_Type skipped exactly the population that pass was written for.
           RCdbModalPanel.pkg never reached the converter for that reason, and its tWindowPlacement
           cluster was reported neither converted nor refused, which is worse than either. */
        Get _FileContainsText (&asCode) "end_type" to bGate
        If (bGate = False) ;
            Get _FileContainsText (&asCode) "zerotype" to bGate
        If (bGate = False) ;
            Get _FileContainsText (&asCode) "filltype" to bGate
        If (bGate = False) ;
            Get _FileContainsText (&asCode) "getbuff" to bGate
        If (bGate = False) ;
            Function_Return 0
        Move asCode to asBefore
        Get _ConvertWin32TypeBuffersInLines (&asCode) (&asNotes) to iCount
        /* A TYPE COPIED FROM Dftypes.pkg NEEDS ITS PACKAGE ON DISK (2026-11-13): the file now Uses DfTypesStructs.pkg
           and names a Struct only that package declares. When the package cannot be written the file stays as it was
           - a Use of a package that is not there compiles nothing at all. */
        If (iCount > 0) Begin
            Get _WriteDfTypesStructs (&asNotes) to bOK
            If (bOK = False) Begin
                Move asBefore to asCode
                Move 0 to iCount
            End
        End
        // A refusal is the interesting outcome, so it travels to the run summary rather than being
        // swallowed - "converted 0" with no reason is the readout this app keeps retiring.
        /* THE NOTE NAMES ITS FILE. One Type can be DECLARED in one file and merely USED in another,
           and the two produce different refusals - DEVMODE came back both as a member-count mismatch
           and as "not declared in this file", which reads like the summary contradicting itself
           until you know they are about different files. The leaf only: a full path buries the
           reason at the far end of the line. */
        // OF ghoEngine, not ghoApplication. The application carries a property of the same name that
        // is set once, to the first file; the ENGINE keeps the per-file one honest and says so at its
        // own Set. Reading the wrong one produced no prefix at all, silently (2026-08-30).
        Get psCurrentSourceFileName of ghoEngine to sFile
        Move (Trim(ExtractFileName(sFile))) to sFile
        Move (SizeOfArray(asNotes) - 1) to iLast
        For i from 0 to iLast
            If (sFile <> "") ;
                Move (sFile + ": " + asNotes[i]) to asNotes[i]
            Send AddRunNote "ChangeExternalFunctionCallers" asNotes[i]
        Loop
        Function_Return iCount
    End_Function

    /* ChangeLegacyTypeToWinStruct - the Tier-2 half of the Type->Struct plan (step 1 was
       TypeToStructReport's feasibility grading, 2026-07-17; this is step 2, Nils 2026-08-31).

       Tier 1 refuses any byte-buffer whose ADDRESS is taken, because nothing it can see proves a
       hand-written Struct has the Type's layout - and that refusal is what leaves every Windows-API
       buffer permanently in the report. Tier 2 lifts exactly that blocker, and only for the 22
       legacy Types DataFlex has REPLACED with a shipped tWin<X> struct: the install marshals those
       same structs to those same APIs itself (cApplication.pkg passes AddressOf(WindowPlacement)
       and SizeOfType(tWinWindowPlacement)), so the layout is the vendor's guarantee, not our
       inference. Every other blocker still refuses the cluster.

       The pair is a CANDIDATE by name and a fact only after verification against the TARGET
       install: the struct must be declared in its tWinStructs.pkg, and every field the code
       actually touches must resolve on it - walked segment by segment, so the old flat
       "rcPaint.left" and the new nested "tWinRect rcPaint" are compared honestly. An unreadable
       install refuses everything rather than guessing.

       Detection + rewrite core is PURE + unit-tested: _LegacyTypeToWinStructInLines
       (cRefactorFuncLib), over the lines _TypeClustersFromLinesEx graded - the grading and the
       rewrite must never be two opinions about the same code.

       NOT here: tWindowPlacement and tTvInsertStruct, whose structs RENAMED members
       (ptMinPosition -> MinPosition, tTvItemEx -> TvItemEx). They need a member map, which is the
       next slice; until then their fields fail to resolve and the cluster is refused with a note. */
    { Published = True }
    { Description = """
        Replaces a legacy Type byte buffer with the Struct that DataFlex now includes for the same Windows API. This is the modern way, and it works with Unicode, which a String buffer did not.
        The String declaration gets the new type, and the ZeroType line is removed, because a local Struct is already empty, as the compiler's message also says. Put and GetBuff become Move statements, and <Type>_size becomes SizeOfType(<Struct>). AddressOf is not changed, because the API needs the struct's address.
        The change is made only where DataFlex actually includes the replacement Struct, checked against the compiler you are moving to: the struct must exist there, and every field that the code uses must exist in it.
        A buffer that is used in any other way, that is declared on the same line as other variables, or that is used with two different Types is not changed, and the run notes say so. The change is made completely or not at all.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Legacy Type buffers moved to DataFlex's shipped tWin* Structs }
        """ }
    Function ChangeLegacyTypeToWinStruct String[] ByRef asCode String sParameter Returns Integer
        String[] asNotes
        String sFile
        Integer iConv
        Boolean bGate

        // Cheap gate: no ZeroType in the file, no cluster can bind a buffer to a Type here.
        Get _FileContainsText (&asCode) "zerotype" to bGate
        If (bGate = False) ;
            Function_Return 0
        Get psCurrentSourceFileName of ghoEngine to sFile
        Get _LegacyTypeToWinStructInLines (&asCode) sFile (&asNotes) to iConv
        Function_Return iConv
    End_Function

    /* ConvertWinAPITypeToStruct - rewrites a legacy Win32 "Type ... End_Type" as a modern Struct
       whose member TYPES come from the Windows SDK, keeping the type name and every member name.

       WHY THIS IS SAFE FOR THIS SHAPE, and why it is not the general Type->Struct converter that
       TypeToStructReport measures the ground for. Legacy Win32 buffers are reached by DOT-MEMBER
       access - "Move (AddressOf(sTitle)) to BrowseInfo.lpszTitle" - and passed whole with
       AddressOf(BrowseInfo). A modern Struct supports both, so the code AROUND the declaration
       compiles unchanged. The byte-level family (Put / GetBuff / Offset_of_Field / ZeroType) is a
       different population that TypeToStructReport lists for hand-migration, and this never
       rewrites those - it changes a declaration and refuses whenever the surrounding code would
       have to move with it.

       THE GATE IS THE MEMBER NAMES, IN ORDER. Matching names mean every existing X.member reference
       keeps working while the TYPES are corrected - which is the whole value, because a legacy Word
       where the SDK says a pointer is the x64 bug this app exists to find. Differing names mean the
       legacy block flattened what the SDK nests (13 members against 8, the WIN32_FIND_DATA shape)
       and the conversion is refused with the member that disagreed.

       Types the catalogue does not know are left alone. Refusals are reported as run notes, so a
       file that converts nothing still says why. */
    { Published = True }
    { Description = """
        Changes legacy Win32 'Type ... End_Type' blocks to modern Structs, with the member types from the Windows SDK. The type name and all member names are kept, so existing X.member references and AddressOf() calls still compile.
        Only Types in DFRefactor's Win32 catalogue are changed, and only when the member names match the SDK exactly. Other Types are not changed, and each one is reported in the run notes with the member that did not match, so a file where nothing was changed still shows why.
        Only the declaration is changed, and only when the code around it does not need to change too. Byte-level access (Put, GetBuff, Offset_of_Field, ZeroType) is never changed; TypeToStructReport lists those lines for manual migration.
        When the names match, the corrected member types are what matters: a legacy Word where the SDK uses a pointer is exactly the kind of 64-bit error this function finds. When the names are different, the legacy block has combined members that the SDK keeps in a nested struct, so the block is not changed.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Legacy Win32 Types rewritten as SDK-typed Structs }
        """ }
    Function ConvertWinAPITypeToStruct String[] ByRef asCode String sParameter Returns Integer
        String[] asNotes asProblems
        String sNote
        Integer iCount i iLast
        Boolean bGate

        // Cheap raw gate: no "end_type" anywhere means there is no legacy Type block to convert.
        Get _FileContainsText (&asCode) "end_type" to bGate
        If (bGate = False) ;
            Function_Return 0

        /* SAY IT WHEN THE CATALOGUE IS NOT THERE. Everything below refuses an API it cannot find,
           so a missing or unreadable Data\WinAPI*.json produces a clean "converted 0" - which
           reads exactly like "nothing needed converting" and is the one failure this cannot be
           allowed to make quietly. AddRunNote de-duplicates, so a note appears once per run
           however many files the run walks. */
        Send RefreshWinAPICatalogsFromJson
        Get pasWinAPILoadProblems to asProblems
        Move (SizeOfArray(asProblems) - 1) to iLast
        For i from 0 to iLast
            Send AddRunNote "ConvertWinAPITypeToStruct" asProblems[i]
        Loop
        Get _ConvertWinAPITypesInLines (&asCode) (&asNotes) to iCount
        // A refusal is the interesting outcome here, so it travels to the run summary through the
        // canonical AddRunNote (which also de-duplicates) rather than being swallowed - "converted
        // 0" with no reason is the readout this app keeps retiring.
        Move (SizeOfArray(asNotes) - 1) to iLast
        For i from 0 to iLast
            Send AddRunNote "ConvertWinAPITypeToStruct" asNotes[i]
        Loop
        Function_Return iCount
    End_Function

    /* ConvertWinAPIDeclarationTypes corrects the x86-era TYPES on an External_Function, which is
       the one Win32 mistake the compiler never mentions.

       A declaration written for a 32-bit build that types a pointer argument as Integer compiles
       clean on x64 and truncates the address at run time - no error, no warning, a wrong pointer.
       That is why this has no ModRecipe: there is no compiler message to hang one on, and the
       Deep Scan rule is what will surface it.

       ONE CORRECTED LINE SERVES BOTH PLATFORMS. DataFlex sizes Pointer, Handle and LongPtr per
       build (Pkg\Dll.pkg sets POINTER_DTSIZE to 8 under IS$WIN64 and 4 otherwise), so nothing here
       needs an #IFDEF - and wrapping an unchanged pair of arms in one would state a difference
       that does not exist. The four APIs whose exported ENTRY POINT really does change by bitness
       are refused and noted; guarding those is a different rewrite.

       The local NAME, ENTRY POINT and DLL are all kept. Only the types move, taken from the SDK
       prototype the catalogue stores - so call sites compile untouched, an ...A wrapper stays an
       ...A wrapper, and the same entry point in another library is still another function. */
    { Published = True }
    { Description = """
        Corrects the parameter and return types of External_Function declarations to match the Windows SDK: an Integer or DWord where the API uses a pointer becomes Pointer, Handle or Longptr.
        This fixes a 64-bit error that the compiler does not report: a declaration written for 32-bit compiles without errors as 64-bit, but cuts off the address when the program runs.
        One corrected declaration works for both 32-bit and 64-bit, because DataFlex sets the size of its pointer types for each, so no #IFDEF is added.
        The declaration's name, entry point and DLL are kept, so the calls still compile, and an ANSI ("...A") declaration stays ANSI. Changing it to the wide ("...W") version is a separate decision.
        Only APIs in the Win32 catalogue are changed. A declaration is not changed, and the run notes say why, when its number of parameters differs from the SDK, or when the API needs different declarations for 32-bit and 64-bit. A declaration that is already correct is not changed, so a second run changes nothing.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Corrected External_Function types against the Windows SDK }
        """ }
    Function ConvertWinAPIDeclarationTypes String[] ByRef asCode String sParameter Returns Integer
        String[] asNotes
        Integer iCount i iLast
        Boolean bGate

        // Cheap raw gate: a file with no External_Function has nothing here to correct.
        Get _FileContainsText (&asCode) "external_function" to bGate
        If (bGate = False) ;
            Function_Return 0

        /* SAY IT WHEN THE CATALOGUE IS NOT THERE. Everything below refuses an API it cannot find,
           so a missing or unreadable Data\WinAPI*.json produces a clean "converted 0" - which
           reads exactly like "nothing needed converting" and is the one failure this cannot be
           allowed to make quietly. AddRunNote de-duplicates, so a note appears once per run
           however many files the run walks. */
        Send _NoteWinAPICatalogueState "ConvertWinAPIDeclarationTypes"
        Get _ConvertApiDeclTypesInLines (&asCode) (&asNotes) to iCount
        // A refusal is the interesting outcome, so it reaches the run summary rather than being
        // swallowed - "corrected 0" with no reason is the readout this app keeps retiring.
        Move (SizeOfArray(asNotes) - 1) to iLast
        For i from 0 to iLast
            Send AddRunNote "ConvertWinAPIDeclarationTypes" asNotes[i]
        Loop
        Function_Return iCount
    End_Function

    /* GuardAnsiExternalFunctionWithWide - puts an ANSI External_Function and its wide twin side by
       side under one version guard, so the SAME DataFlex name resolves to ...A on a pre-Unicode
       DataFlex and ...W on a Unicode one. No call site changes; the compiler chooses. The
       user-facing half - the catalogue limit, the parameter types and what gets added - now lives
       in the { Description } below.

       The wide arm is built from WinAPICatalog.inc, never by editing the entry string in place:
       LPCSTR converts to String and LPCWSTR to WString, so an in-place letter swap compiles while
       marshalling wrongly.

       THE VERSION IS A PARAMETER because the codebase does not agree with itself about where
       Unicode starts - one comment says "pre-Unicode (DataFlex < 2022)", another "DF21+" - and a
       boundary this function cannot verify is not one it should hardcode. Blank uses the selected
       workspace's own version, exactly as GuardDuplicateExternalFunctions does.

       THE TARGET INSTALL IS ASKED FIRST (Nils 2026-09-02): a name the target DataFlex declares
       itself gets 'Use <that package>' on the modern arm instead of a wide twin - a second
       External_Function of a name is error 4390 whatever its entry point, so the twin would break
       the build it was written for (WinServ's InternetOption.pkg against DataFlex 26's
       cHttpTransfer.pkg). That gate is bounded by the TARGET's version (psTargetDfVersion pairs
       with psTargetPkgFolder, the folder the catalogue walk reads), not by the Unicode boundary
       above; an earlier wide pair of such a name is repaired to the same shape.

       Detection core is PURE + unit-tested: _GuardAnsiWideInLines (cRefactorFuncLib). */
    { Published = True }
    { Description = """
        Adds the wide ("...W") version of an ANSI ("...A") External_Function declaration next to it, with both inside one #IF version check, so that the same DataFlex name works in DataFlex versions before and after Unicode.
        This is done only when DFRefactor's Win32 catalogue contains the wide version; its parameter types come from the Windows SDK. Calls to the function are not changed.
        A declaration whose wide version is not in the catalogue is not changed. The wide name is never made by changing or removing the last letter, which would turn SetClipboardData into SetClipboardDatW. The wide version also uses different parameter types (LPCSTR becomes String, LPCWSTR becomes WString), so changing only the letter would compile, but pass the data in the wrong form.
        Nothing is deleted: the original ANSI declaration is kept, and only the version check and the wide declaration are added around it.
        When the target DataFlex already declares the same name itself (a second declaration is error 4390), a Use of that package is added instead of a wide declaration.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ParamHelp = DataFlex version Unicode starts at, e.g. 22.0 (220 also accepted). Leave blank to use the selected workspace's own version. }
        { SummaryText = ANSI External_Functions given a version-guarded wide twin }
        """ }
    Function GuardAnsiExternalFunctionWithWide String[] ByRef asCode String sParameter Returns Integer
        String sVerText sTargetText sSelf
        Integer iVer iGuarded iTargetVer
        Boolean bGate
        tWorkspacePaths WS

        Get _FileContainsText (&asCode) "external_function" to bGate
        If (bGate = False) ;
            Function_Return 0
        // An empty or unloadable catalogue makes every twin lookup answer "" below, which reads
        // exactly like "no ANSI declaration had a wide twin" - so the state is voiced first.
        Send _NoteWinAPICatalogueState "GuardAnsiExternalFunctionWithWide"
        Move (Trim(sParameter)) to sVerText
        If (sVerText = "") Begin
            Get pTargetWS of ghoApplication to WS
            Move WS.sDfVersion to sVerText
        End
        Get DfVersionToMacroNumber sVerText to iVer
        If (iVer = 0) Begin
            /* REFUSE, BUT SAY SO. The engine hands this function whatever sits in the persisted
               Functions.Parameter column, and an unparsable value used to return 0 with no trace -
               a plan run reported "0 lines" over files whose declarations verifiably qualified,
               and only a headless probe with an explicit "26.0" proved the converter itself worked
               (WinServ, 2026-08-28). A refusal that cannot say why reads exactly like a failure -
               third time this lesson has been paid for this week. */
            Send AddRunNote "GuardAnsiExternalFunctionWithWide" ;
                ("Nothing done - the version parameter could not be read as a DataFlex version: '" ;
                + sVerText + "'. Blank uses the target workspace's version; otherwise e.g. 19.1 or 26.")
            Function_Return 0
        End
        // The TARGET's version bounds the Use-arms (see the header) - it pairs with the Pkg folder the
        // install catalogue walks. Unreadable = the core falls back to the Unicode boundary.
        Get psTargetDfVersion of ghoApplication to sTargetText
        Get DfVersionToMacroNumber sTargetText to iTargetVer
        // This file's leaf: a Use-arm naming the file itself would read nothing (_UseArmUnlessSelf).
        // OF ghoEngine - the per-file one; the application's is set once, to the first file.
        Get psCurrentSourceFileName of ghoEngine to sSelf
        Move (Trim(ExtractFileName(sSelf))) to sSelf
        Get _GuardAnsiWideInLines (&asCode) iVer sVerText iTargetVer sTargetText sSelf to iGuarded
        // The guided "Guard it" runs this silent over a name's declaring files and reads the tally back.
        Set piGuardedAnsiWideCount to (piGuardedAnsiWideCount(Self) + iGuarded)
        Function_Return iGuarded
    End_Function

/* GuardDuplicateExternalFunctions - the External_Function flavor of 4390 ("already defined as an
       external_function"). Newer DataFlex releases declare Windows APIs the workspace also declares
       (LegacyApp 2026-07-23: cHttpTransfer.pkg ships WinAPI_InternetQueryOption / WinAPI_InternetSetOption,
       which the workspace declared itself since 19.1). Both sides bind the SAME API, so the honest
       mechanical fix is the same version guard the globals converter writes - the workspace's own
       release keeps compiling its declaration, newer builds use DataFlex's, no call site changes.

       WHICH NAMES: only External_Functions the TARGET install's own Pkg source ALSO declares as an
       External_Function (RunInstallExternalFnNames - one walk per run, session-cached). A clash with
       something the runtime owns is not in that catalogue and is refused by construction - the same
       refuse-not-guess stance as the globals guard. Version boundary, inclusive "<=", blank-version
       refusal and Character()-built directive tokens: all exactly as GuardRedundantGlobalFunctions.

       CAUTION, carried into the emitted marker: entry points can differ in width - an ...A (ANSI)
       binding here vs DataFlex's ...W (wide). Identical for numeric arguments; verify wherever text
       buffers cross the boundary. Suggest, never auto-fix. */
    { Published = True }
    { Description = """
        Puts the External_Function declarations in this file that the target DataFlex now declares itself inside an #IF (!@ <= version) check, so that the duplicate declaration is only compiled in older versions. This fixes error 4390, "already defined as an external_function", without changing any calls.
        The change can be undone, and running it again changes nothing. A declaration that continues on the next line with ";" is protected as one block.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4390 | as an external_function | Suggest }
        { ParamHelp = DataFlex version this code is kept for, e.g. 19.1 (191 or 26 also accepted). Leave blank to use the selected workspace's own version. }
        { SummaryText = Version-guarded duplicate External_Function declarations }
        """ }
    Function GuardDuplicateExternalFunctions String[] ByRef asCode String sParameter Returns Integer
        String[] asNativeExt asOwn asGuard asNativeBind asSkipped
        String sVerText
        Integer iVer iGuarded i iAt
        Boolean bGate bTargetDerived
        tWorkspacePaths WS

        // Cheap raw-text gate first: no "external_function" anywhere = nothing this can touch.
        Get _FileContainsText (&asCode) "external_function" to bGate
        If (bGate = False) ;
            Function_Return 0
        // Version boundary: the parameter wins, else the selected workspace's own DataFlex version.
        // Blank/unparsable = REFUSE, never guess (the globals-guard rule).
        Move (Trim(sParameter)) to sVerText
        // NO PARAMETER = the version is the TARGET's, i.e. the release that now declares the API -
        // so the guard must EXCLUDE it, or it cannot clear the error that build is reporting. A
        // version the user named means "keep it for this release and older" and stays inclusive.
        Move False to bTargetDerived
        If (sVerText = "") Begin
            Get pTargetWS of ghoApplication to WS
            Move WS.sDfVersion to sVerText
            Move True to bTargetDerived
        End
        Get DfVersionToMacroNumber sVerText to iVer
        If (iVer = 0) Begin
            // The same silent refusal GuardAnsiExternalFunctionWithWide had - see the note there.
            Send AddRunNote "GuardDuplicateExternalFunctions" ;
                ("Nothing done - the version parameter could not be read as a DataFlex version: '" ;
                + sVerText + "'. Blank uses the target workspace's version; otherwise e.g. 19.1 or 26.")
            Function_Return 0
        End
        Get RunInstallExternalFnNames of Self to asNativeExt
        If (SizeOfArray(asNativeExt) = 0) ;
            Function_Return 0
        // This file's own External_Function names, kept only where the install declares the same name.
        Get _ExternalFnNamesFromLines asCode to asOwn
        For i from 0 to (SizeOfArray(asOwn) - 1)
            Move (BinarySearchArray(Uppercase(asOwn[i]), asNativeExt)) to iAt
            If (iAt <> -1) Begin
                If (SearchArray(asOwn[i], asGuard, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move asOwn[i] to asGuard[SizeOfArray(asGuard)]
            End
        Loop
        If (SizeOfArray(asGuard) = 0) ;
            Function_Return 0
        // The install's bindings ride the same cached walk the names came from, so the guard can say
        // WHICH declarations differ from DataFlex's instead of warning about all of them.
        Get RunInstallExternalFnBindings of Self to asNativeBind
        Get _GuardExternalsInLines (&asCode) asGuard asNativeBind iVer sVerText bTargetDerived to iGuarded
        Set piGuardedExternalCount to (piGuardedExternalCount(Self) + iGuarded)
        // A declaration this file CALLS is refused, and saying so is the point: the guard was
        // correct about the duplicate and wrong about the consequence, and a silent skip reads as
        // "already fine" when it is the opposite (LegacyApp4, 2026-08-26).
        Get pasGuardSkippedCalled to asSkipped
        For i from 0 to (SizeOfArray(asSkipped) - 1)
            Send AddRunNote "GuardDuplicateExternalFunctions" ("Not guarded - this file calls it: " + asSkipped[i])
        Loop
        Function_Return iGuarded
    End_Function

    /* Report-only worksheet for the legacy buffer-offset Type system (4532). PART 1: each
       "Type ... End_Type" with its proposed modern "Struct" (built by _TypeDefToStruct), each TAGGED
       [MARSHALED to native code - hand-migrate] vs [pure in-memory - safe to convert] by
       _MarshaledTypeNames (does any buffer bound to the Type have its address taken via GetAddress /
       AddressOf - i.e. is it passed to a Windows API / External_Function?). Each pure in-memory Type
       additionally gets its usage CLUSTERS graded for Tier-1 auto-convert feasibility
       (_TypeClustersFromLines): a cluster = one buffer in one scope; AUTO-CONVERTIBLE means every
       touch of that buffer is a mechanical Struct rewrite, else the blockers name the exact reason +
       line. This measures how much of a workspace a future opt-in Type->Struct converter could
       actually take on (step 1 of the plan, Nils 2026-07-17) - conservative, so the verdict can be
       trusted. A Type defined in the DataFlex install packages is flagged as a system Type (a Tier-2
       shipped-struct mapping candidate). PART 2: every buffer accessor (Put / Put_String /
       StoreField / GETBUFF / RETRIEVEFIELD / GetBuff_String / FillType / ZeroType / Offset_of_Field /
       Size_of_Field) with file + line. These are byte-level ops needing human judgement (which
       String buffer is which instance), so they are LISTED, never rewritten - review each (some
       "Put" lines may be unrelated). Logs to the Backup folder; surfaced via 'Other Log Files'.
    */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Lists every legacy Type definition with a suggested modern Struct. Each Type is marked [MARSHALED to native code - hand-migrate] when it is passed to Windows, or [pure in-memory - safe to convert] when it is only used in DataFlex. The report also lists the buffer commands (Put, GETBUFF, StoreField ...) that must be migrated by hand.
        For each Type that is only used in DataFlex, each group of lines that uses it is marked AUTO-CONVERTIBLE or BLOCKED, with the exact reason.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Unicode64 }
        { ModRecipe = 4532 | Suggest }
        { ModRecipe = 4536 | Dftypes | Suggest }
        { ModRecipe = 4533 | ArrayPut | Suggest }
        { ModRecipe = 4534 | CVTtoBytes | Suggest }
        { SummaryText = Report: Type definitions -> proposed Structs + buffer-accessor usage sites }
        """ }
    Function TypeToStructReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath sCmd sTok sPkg sMask sUsedName sCachePath sSuggest sSysNote
        String[] asCode asEmpty asBlock asStruct asAccessors asOtherLogFiles asUsedTypes asFileUsed asWords
        String[] asMarshaledTypes asFileMarshaled
        Integer iCh iFile iFileLast iLine iLineLast iBlk iStart iTypes iUsages iTok iN iAcc
        Integer i j iUsed iDup iDefLast iTickA iMarshaled iPure
        Integer iInstallDefs iClu iCluLast iB iBLast iCluClean iCluTotal iClustersClean iClustersTotal iTypesFullyClean
        Boolean bPanel bFoundEnd bHeader bFound bCacheHit bHasCvt bIsMarshaled bCancel
        tTypeDef[] aCatalog aDefs
        tTypeBufferCluster[] aClusters aFileClusters
        tRFSearchResult[] aPkgFiles

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_TypeToStructReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) ;
            Function_Return 0

        Writeln channel iCh "Type -> Struct migration worksheet  (report only - no changes made)."
        Writeln channel iCh "Legacy Type/Field is a byte-offset buffer system, used mainly to marshal to"
        Writeln channel iCh "External_Functions. PART 1 proposes a modern Struct for each Type; PART 2 lists"
        Writeln channel iCh "the buffer accessors to hand-migrate to Struct + Move (which buffer maps to which"
        Writeln channel iCh "instance is a human decision, so nothing here is rewritten - review each line)."
        Writeln channel iCh ""

        Move "Put"             to asAccessors[0]
        Move "Put_String"      to asAccessors[1]
        Move "StoreField"      to asAccessors[2]
        Move "GETBUFF"         to asAccessors[3]
        Move "RETRIEVEFIELD"   to asAccessors[4]
        Move "GetBuff_String"  to asAccessors[5]
        Move "FillType"        to asAccessors[6]
        Move "ZeroType"        to asAccessors[7]
        Move "Offset_of_Field" to asAccessors[8]
        Move "Size_of_Field"   to asAccessors[9]
        Move "ArrayPut"        to asAccessors[10]   // Put into a Struct[] element (At <Type>.<field>)

        Move 0 to iTypes
        Move 0 to iUsages
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        // The TOTAL bar spans all three passes: Phase A (install-Pkg catalogue; its
        // count joins the budget once the search below has run), Phase B (selected
        // files) and PART 2 (selected files again). Previously only Phase B advanced
        // it, so the panel froze through the whole Phase A scan and PART 2. The
        // per-file bar is driven in PART 2's line loop (the only line-local pass).
        If (bPanel = True) Begin
            Set piMaximumTot of ghoStatusPanel to (2 * (iFileLast + 1))
            Set piPosition  of ghoProgressBar to 0
            Set piAdvanceBy of ghoProgressBar to 1
        End

        // ---- Phase a: catalogue Type defs from the TARGET install's packages (DfTypes.pkg & co.) ----
        // The Type definitions live in the system packages, not the user's code (which only USES them),
        // so resolve them from psTargetPkgFolder - the same Pkg folder the ModAnalyzer scans. Those
        // packages change on a DataFlex version bump (different version folder -> different cache name)
        // AND on an in-place update (same folder): the cache stamps the newest *.pkg write time and a
        // cache READ self-invalidates when a package is newer (ReadTypeDefsCache / _PkgScanIsStale), so
        // no manual JSON delete is needed. CACHED per version in Data\DfVersion-TypeDefs-<ver>.json; a SHARED
        // install-Pkg walk (ghoFuncLib.EnsureInstallCaches) builds it AND the ModAnalyzer recipe scan
        // in ONE pass; a fresh cache hit skips the walk entirely.
        Move (GetTickCount()) to iTickA
        Get TypeDefsCacheJsonPath of Self to sCachePath
        // Try the cache first (ONE parse on the common hit path - do NOT pre-probe, which would parse
        // this potentially-large JSON twice). A peer ModAnalyzer Analyze earlier this session may have
        // filled it via the shared walk's piggyback, so even a "first" report run can hit here.
        Get ReadTypeDefsCache of Self (&aCatalog) to bCacheHit
        If (bCacheHit = True) Begin
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to "Type catalogue loaded from cache..."
            Writeln channel iCh ("Type catalogue: " + String(SizeOfArray(aCatalog)) + " definitions loaded from cache (" + sCachePath + ") in " + String(GetTickCount() - iTickA) + " ms - install-package scan skipped.")
        End
        Else Begin
            // Stale - the ONE shared install-package walk reads every package ONCE and refreshes this
            // Type-def cache AND (if it too is stale) the ModAnalyzer recipe scan; it drives the
            // per-package total bar itself (bShowProgress = True). Then re-read the now-fresh cache.
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to "Cataloguing Type definitions from the packages..."
            Send EnsureInstallCaches of Self False True False True
            Get ReadTypeDefsCache of Self (&aCatalog) to bCacheHit
            Writeln channel iCh ("Type catalogue: rebuilt from the install packages -> " + String(SizeOfArray(aCatalog)) + " definitions in " + String(GetTickCount() - iTickA) + " ms; cached to " + sCachePath + " for next run.")
        End
        Writeln channel iCh ""
        // Catalogue indexes below this are user-defined Types appended by Phase B; at or above =
        // system Types from the install packages (the Tier-2 shipped-struct mapping candidates).
        Move (SizeOfArray(aCatalog)) to iInstallDefs

        // ---- Phase B: add any user-defined Types to the catalogue, and collect the Types USED ----
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            If (bPanel = True) Begin
                // "File No: x of: y" counter (the engine sets this for line-by-line functions; an
                // eReportFunctionAll gets all files at once, so we set it ourselves - see cRefactorEngine).
                Set Caption_Text   of ghoStatusPanel to ("Type usage - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text of ghoStatusPanel to "Scanning Type usage:"
                Set TableName_Text of ghoStatusPanel to sFilePath
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            // Scale the per-file bar to THIS file's lines; the four walkers below step it as
            // they go. Without this Phase B showed only the file counter - the per-file bar and
            // the "line x of y" text sat dead through every file (Nils 2026-07-26).
            If (bPanel = True) ;
                Send _StartFileLineProgress (SizeOfArray(asCode))
            Get _TypeDefsFromLines of Self asCode to aDefs
            Move (SizeOfArray(aDefs) - 1) to iDefLast
            For j from 0 to iDefLast
                Move aDefs[j] to aCatalog[SizeOfArray(aCatalog)]
            Loop
            Get _UsedTypeNamesFromLines of Self asCode to asFileUsed
            Move (SizeOfArray(asFileUsed) - 1) to iDefLast
            For j from 0 to iDefLast
                Move (SearchArray(asFileUsed[j], asUsedTypes, Desktop, RefFunc(DFSTRICMP))) to iDup
                If (iDup = -1) ;
                    Move asFileUsed[j] to asUsedTypes[SizeOfArray(asUsedTypes)]
            Loop
            // Classify this file's Types: a Type is MARSHALED when a buffer bound to it (via ZeroType /
            // accessors) has its ADDRESS taken (GetAddress/AddressOf) - i.e. passed to native code - so it
            // must be hand-migrated. Union into the workspace-wide marshaled set (per-file, so a buffer
            // name reused in another file cannot cross-contaminate).
            Get _MarshaledTypeNames of Self asCode to asFileMarshaled
            Move (SizeOfArray(asFileMarshaled) - 1) to iDefLast
            For j from 0 to iDefLast
                Move (SearchArray(asFileMarshaled[j], asMarshaledTypes, Desktop, RefFunc(DFSTRICMP))) to iDup
                If (iDup = -1) ;
                    Move asFileMarshaled[j] to asMarshaledTypes[SizeOfArray(asMarshaledTypes)]
            Loop
            // Tier-1 feasibility: grade this file's buffer-usage clusters (scope + buffer + Type ->
            // AUTO-CONVERTIBLE, or the exact blockers). Accumulated workspace-wide; PART 1 prints
            // each pure in-memory Type's clusters under its proposed Struct.
            Get _TypeClustersFromLines of Self asCode sFilePath to aFileClusters
            Move (SizeOfArray(aFileClusters) - 1) to iDefLast
            For j from 0 to iDefLast
                Move aFileClusters[j] to aClusters[SizeOfArray(aClusters)]
            Loop
            // Mid-run cancel (the Cancel button): a *All function gets ONE call for all files,
            // so the engine's per-file Cancel_Check cannot fire while we scan. Poll the safe
            // accessor (NEVER Cancel_Check - it consumes the signal) and bail; the engine's
            // outer Cancel_Check then runs the confirm pipeline once.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        // ---- PART 1: proposed Struct for each Type used in the code ----
        Writeln channel iCh "=== PART 1: proposed Struct for each Type used in the code ==="
        Writeln channel iCh "  Each Type is tagged by how its buffer is used:"
        Writeln channel iCh "    [MARSHALED to native code] - a buffer of this Type has its ADDRESS taken (GetAddress /"
        Writeln channel iCh "        AddressOf) and is passed to a Windows API / External_Function. Converting to a Struct"
        Writeln channel iCh "        changes how it marshals - HAND-MIGRATE (pass the Struct's address; verify 64-bit layout)."
        Writeln channel iCh "    [pure in-memory] - no address is ever taken, so it is only an in-app record: safe to convert."
        Writeln channel iCh "  (Heuristic - conservative: a buffer name reused across procedures may over-tag as MARSHALED.)"
        Writeln channel iCh "  Each pure in-memory Type also gets its usage CLUSTERS graded (Tier-1 auto-convert feasibility):"
        Writeln channel iCh "    a cluster = ONE buffer variable in ONE scope (procedure/function, or the whole file for a"
        Writeln channel iCh "    file-scope buffer). AUTO-CONVERTIBLE = every touch of that buffer is a mechanical Struct"
        Writeln channel iCh "    rewrite; BLOCKED names the exact reason + line. Conservative: any use of the buffer beyond"
        Writeln channel iCh "    the accessors blocks the cluster, so an AUTO-CONVERTIBLE verdict can be trusted."
        Writeln channel iCh ""
        Move (SizeOfArray(asUsedTypes) - 1) to iN
        For iUsed from 0 to iN
            Move asUsedTypes[iUsed] to sUsedName
            Move False to bFound
            Move asEmpty to asBlock
            Move (SizeOfArray(aCatalog) - 1) to iDefLast
            Move 0 to j
            While (j <= iDefLast and bFound = False)
                If (Lowercase(aCatalog[j].sName) = Lowercase(sUsedName)) Begin
                    Move True to bFound
                    Move aCatalog[j].asBlock to asBlock
                End
                Increment j
            Loop
            If (bFound = True) Begin
                // Found index = j-1 (the While increments past the hit): below iInstallDefs = a
                // SYSTEM Type from the install packages - the Tier-2 shipped-struct mapping candidate.
                Move "" to sSysNote
                If ((j - 1) < iInstallDefs) ;
                    Move " (system Type - defined in the DataFlex install packages)" to sSysNote
                Move (SearchArray(sUsedName, asMarshaledTypes, Desktop, RefFunc(DFSTRICMP)) <> -1) to bIsMarshaled
                If (bIsMarshaled = True) Begin
                    Writeln channel iCh ("--- " + sUsedName + "   [MARSHALED to native code - HAND-MIGRATE]" + sSysNote + " ---")
                    Increment iMarshaled
                End
                Else Begin
                    Writeln channel iCh ("--- " + sUsedName + "   [pure in-memory - safe to convert]" + sSysNote + " ---")
                    Increment iPure
                End
                Get _TypeDefToStruct of Self asBlock to asStruct
                Move (SizeOfArray(asStruct) - 1) to iTok
                Move 0 to iBlk
                While (iBlk <= iTok)
                    Writeln channel iCh ("    " + asStruct[iBlk])
                    Increment iBlk
                Loop
                // Tier-1 feasibility grading (pure in-memory Types only - a MARSHALED Type is
                // hand-migrate regardless of how clean its clusters look).
                If (bIsMarshaled = False) Begin
                    Move 0 to iCluClean
                    Move 0 to iCluTotal
                    Writeln channel iCh "    Auto-convert feasibility (usage clusters):"
                    Move (SizeOfArray(aClusters) - 1) to iCluLast
                    For iClu from 0 to iCluLast
                        If (Lowercase(aClusters[iClu].sTypeName) = Lowercase(sUsedName)) Begin
                            Increment iCluTotal
                            Move (SizeOfArray(aClusters[iClu].asBlockers) - 1) to iBLast
                            If (iBLast < 0) Begin
                                Increment iCluClean
                                Writeln channel iCh ("      " + aClusters[iClu].sFile + " [" + aClusters[iClu].sScope + "] buffer " + aClusters[iClu].sBuffer + " - " + String(aClusters[iClu].iBindings) + " accessor line(s), first at line " + String(aClusters[iClu].iFirstLine) + ": AUTO-CONVERTIBLE")
                            End
                            Else Begin
                                Writeln channel iCh ("      " + aClusters[iClu].sFile + " [" + aClusters[iClu].sScope + "] buffer " + aClusters[iClu].sBuffer + " - " + String(aClusters[iClu].iBindings) + " accessor line(s), first at line " + String(aClusters[iClu].iFirstLine) + ": BLOCKED")
                                For iB from 0 to iBLast
                                    Writeln channel iCh ("          - " + aClusters[iClu].asBlockers[iB])
                                Loop
                            End
                        End
                    Loop
                    If (iCluTotal = 0) ;
                        Writeln channel iCh "      (no buffer-bound usage clusters found - used only via offset/size arithmetic or unrecognised shapes)"
                    Else ;
                        Writeln channel iCh ("      Verdict: " + String(iCluClean) + " of " + String(iCluTotal) + " cluster(s) auto-convertible.")
                    Move (iClustersClean + iCluClean) to iClustersClean
                    Move (iClustersTotal + iCluTotal) to iClustersTotal
                    If (iCluTotal > 0 and iCluClean = iCluTotal) ;
                        Increment iTypesFullyClean
                End
                Writeln channel iCh ""
                Increment iTypes
            End
            Else Begin
                Writeln channel iCh ("--- " + sUsedName + "  (definition not found - check it is a Type) ---")
                Writeln channel iCh ""
            End
        Loop
        Writeln channel iCh ("PART 1 summary: " + String(iTypes) + " Type(s) used - " + String(iMarshaled) + " MARSHALED to native code (hand-migrate), " + String(iPure) + " pure in-memory (safe to convert).")
        Writeln channel iCh ("Tier-1 auto-convert feasibility: " + String(iClustersClean) + " of " + String(iClustersTotal) + " usage cluster(s) across the pure in-memory Types are mechanically convertible; " + String(iTypesFullyClean) + " of " + String(iPure) + " pure in-memory Type(s) are fully clean (every cluster convertible).")
        Writeln channel iCh ""

        // ---- PART 2: buffer accessor usage sites ----
        Writeln channel iCh "=== PART 2: buffer accessor usage sites to hand-migrate ==="
        Writeln channel iCh "  A 'suggest:' line gives the mechanical Struct rewrite: the buffer becomes a Struct local"
        Writeln channel iCh "  named 'TheData' (rename its other uses to match) and the byte-offset Type. prefix drops."
        Writeln channel iCh "  REVIEW each: a buffer passed to an External_Function by AddressOf (e.g. a Windows API) must"
        Writeln channel iCh "  pass the Struct's address instead, and the field types must be 64-bit-correct (see the"
        Writeln channel iCh "  Win64StructPadding report). Nothing here is auto-applied."
        Writeln channel iCh ""
        // A Phase-B cancel skips PART 2 entirely (0-to--1 never enters the loop);
        // the INCOMPLETE note before the Total marks the truncation.
        If (bCancel = True) ;
            Move -1 to iFileLast
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            If (bPanel = True) Begin
                Set Caption_Text   of ghoStatusPanel to ("Buffer accessors - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text of ghoStatusPanel to "Scanning buffer accessors:"
                Set TableName_Text of ghoStatusPanel to sFilePath
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move (SizeOfArray(asCode)) to iLineLast
            Move False to bHeader
            If (bPanel = True) ;
                Send _StartFileLineProgress iLineLast
            If (iLineLast > 0) Begin
                Decrement iLineLast
                For iLine from 0 to iLineLast
                    // Canonical nudge. Was a direct Update_StatusPanel every 20 lines, which
                    // pumps the message queue on a fixed LINE count - the nudge gates on the
                    // wall clock instead, so paint cost no longer scales with throughput.
                    If (Mod(iLine, 64) = 0) ;
                        Send _NudgeLineProgress iLine (iLineLast + 1) "Buffer accessors, line:"
                    // Stateless split (no engine Tokenizer): a report makes no source
                    // changes, so it never needed position accuracy; this is the cheap
                    // first-token check, with strings/// comments already masked out.
                    Get _SplitSourceWords of Self asCode[iLine] to asWords
                    Move -1 to iAcc
                    Move False to bHasCvt
                    If (SizeOfArray(asWords) > 0) Begin
                        Move (SearchArray(asWords[0], asAccessors, Desktop, RefFunc(DFSTRICMP))) to iAcc
                        // CVTtoBytes is a FUNCTION used mid-line ("Move (CVTtoBytes(...)) to x"), not a
                        // leading command, so the first-token check misses it - detect it by content on
                        // the masked split (strings / comments already stripped, so no false match).
                        Move (SizeOfArray(asWords) - 1) to iTok
                        For j from 0 to iTok
                            If (Uppercase(asWords[j]) contains "CVTTOBYTES") ;
                                Move True to bHasCvt
                        Loop
                    End
                    If (iAcc <> -1 or bHasCvt = True) Begin
                        If (bHeader = False) Begin
                            Writeln channel iCh ("--- " + sFilePath + " ---")
                            Move True to bHeader
                        End
                        Writeln channel iCh ("  Line " + String(iLine + 1) + ":  " + Trim(asCode[iLine]))
                        If (iAcc <> -1) Begin
                            Get _SuggestStructLine of Self asWords aCatalog to sSuggest
                            If (sSuggest <> "") ;
                                Writeln channel iCh ("      suggest:  " + sSuggest)
                        End
                        Else ;
                            Writeln channel iCh ("      suggest:  byte-packing - a Struct assignment ('Move <value> to TheData.<field>') lays out the bytes; no CVTtoBytes needed.")
                        Increment iUsages
                    End
                Loop
                If (bHeader = True) ;
                    Writeln channel iCh ""
            End
        Loop

        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        If (bCancel = True) Begin
            Writeln channel iCh ""
            Writeln channel iCh "*** Cancelled by the user - this report is INCOMPLETE. ***"
        End
        Writeln channel iCh ("Total: " + String(iTypes) + " Type definition(s), " + String(iUsages) + " accessor line(s).")
        Writeln channel iCh ("Tier-1 feasibility: " + String(iClustersClean) + " of " + String(iClustersTotal) + " usage cluster(s) auto-convertible; " + String(iTypesFullyClean) + " of " + String(iPure) + " pure in-memory Type(s) fully clean.")
        Send rfCloseOutput iCh

        If ((iTypes + iUsages) > 0) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Move sLogFile to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Function_Return (iTypes + iUsages)
    End_Function

    { Published = True }
    { Description = """
        Replaces the two-line buffer conversion from DataFlex 19.1, "Move (OemToUtf8Buffer((AddressOf(sVar)),(Length(sVar)))) to aBuf" followed by "Move aBuf to sVar", with the single line "Move (OemToUtf8(sVar)) to sVar". All four CharTranslate pairs are handled.
        This removes the pointer, and the buffer that the old code never released.
        The lines are changed only when both arguments name the same variable, the next line moves the buffer back to that variable, and the buffer is not used anywhere else.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4539 | buffer pair }
        { SummaryText = Collapsed two-line buffer conversions to their String sibling }
        """ }
    Function UnicodeBufferPairToString String[] ByRef asCode String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        Get Create (RefClass(cUnicodePointerToString)) to ho
        If (ho = 0) Begin
            Error "Could not create cUnicodePointerToString object. (Function: UnicodeBufferPairToString)"
            Function_Return 0
        End

        Get UnicodeBufferPairToString of ho (&asCode) to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* UnicodeOemAnsiFunctions modernizes the legacy OEM/ANSI string-conversion calls
       (the "String" section of the Unicode guide): under the Unicode compiler ToOEM()
       and ToANSI() became Utf8ToOem() and Utf8ToAnsi(). Line-by-line
       (eStandardFunction) because the rename is purely local - no cross-line state -
       unlike the two functions above. The per-line overstrike the engine leaves in
       pTokenizer lets it skip strings/comments, and a left word-boundary keeps it
       idempotent (won't touch an already-converted Utf8ToOem). The boundary-aware,
       masked token-rename primitive lives in cRefactorUtilities._RenameMaskedCalls.
    */
    { Published = True }
    { Description = """
        Unicode fix for the legacy OEM/ANSI string conversions: changes ToOEM(x) to Utf8ToOem(x) and ToANSI(x) to Utf8ToAnsi(x).
        Only whole words are changed, and running it again changes nothing, because Utf8ToOem is not changed again. Strings and comments are skipped.
        { MethodType = eStandardFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4534 | use of ToOEM }
        { ModRecipe = 4534 | use of ToANSI }
        { SummaryText = Renamed: ToOEM/ToANSI -> Utf8ToOem/Utf8ToAnsi }
        """ }
    Function UnicodeOemAnsiFunctions String ByRef sLine String sParameter Returns Boolean
        String   sNewLine sOverFull
        String[] asFrom asTo
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        Move "ToOEM"      to asFrom[0]
        Move "Utf8ToOem"  to asTo[0]
        Move "ToANSI"     to asFrom[1]
        Move "Utf8ToAnsi" to asTo[1]

        // sOverstrikeLine is the LEFT-trimmed, masked line (the leading whitespace is
        // held separately in sIndentation). Re-attach it so the masked line is
        // position-aligned with the full sLine before the rename.
        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull
        Get _RenameMaskedCalls sLine sOverFull asFrom asTo to sNewLine
        If (sNewLine = sLine) Begin
            Function_Return False
        End
        Move sNewLine to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Unicode fix for compile error 4539, "Conversion from Pointer to String is not allowed, use PointerToString function".
        Wraps the source of a plain "Move <pointer/address> to <string>" in PointerToString(). An Address source causes the same error, so it is handled too.
        It also replaces the DataFlex 19.1 buffer call "Move (Utf8ToOemBuffer(sVar)) to sVar" with the version that returns a String (Utf8ToOem and the other three CharTranslate pairs).
        Examples:
        - Move aBuf to sResult becomes Move (PointerToString(aBuf)) to sResult
        - Move (Utf8ToOemBuffer(sLine)) to sLine becomes Move (Utf8ToOem(sLine)) to sLine
        A Move is changed only when the source is declared as a Pointer or Address and the destination as a String, in the same method. A buffer call is changed only when it has one argument, and both that argument and the destination are declared as Strings or String parameters. A line where the types cannot be determined from the declarations is not changed: a missed line does no harm, but a wrong change would.
        A buffer call with two arguments (AddressOf and a length, which uses pointers on purpose) is never changed, and needs a manual migration.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4539 | pointer to string }
        { SummaryText = Fixed 4539 Moves: PointerToString() wraps + buffer-call renames }
        """ }
    Function UnicodePointerToString String[] ByRef asCode String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        Get Create (RefClass(cUnicodePointerToString)) to ho
        If (ho = 0) Begin
            Error "Could not create cUnicodePointerToString object. (Function: UnicodePointerToString)"
            Function_Return 0
        End

        Get UnicodePointerToString of ho (&asCode) to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* UnicodeStringToPointer - the OTHER direction of compile error 4539 ("Conversion from
       String to Pointer is not allowed, use MemCopy function"). The before/after form and the
       limitations now live in the { Description }. Maintainer notes: unlike UnicodePointerToString
       this pass also reads the method's String / Pointer parameters, because the string source of
       these conversions is usually a parameter. It rewrites only when BOTH operand types are known
       from declarations or parameters - a missed line is harmless, a wrong rewrite is not. The
       actual work lives in the worker class cUnicodeStringToPointer; this is only the wrapper.
    */
    { Published = True }
    { Description = """
        Unicode fix for compile error 4539, in the direction String to Pointer: changes a plain "Move <string> to <pointer>" into a call to MemCopy().
        A line is changed only when the types of both variables are known from the declarations or parameters.
        Before:  Move <string var> to <pointer var>
        After:   Move (MemCopy(<ptr>, AddressOf(<str>), SizeOfString(<str>))) to iRFVoid
        An Integer variable, iRFVoid, which receives the return value of MemCopy, is declared once in each method that needs it.
        The number of bytes is calculated with SizeOfString, so the encoding is taken into account. The buffer's own ResizeArray line is not changed.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4539 | string to pointer }
        { SummaryText = Rewrite: String -> Pointer with MemCopy() }
        """ }
    Function UnicodeStringToPointer String[] ByRef asCode String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        Get Create (RefClass(cUnicodeStringToPointer)) to ho
        If (ho = 0) Begin
            Error "Could not create cUnicodeStringToPointer object. (Function: UnicodeStringToPointer)"
            Function_Return 0
        End

        Get UnicodeStringToPointer of ho (&asCode) to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    // The lines (0-based) UnicodePointerToString or UnicodeStringToPointer (sFn) would rewrite in asCode -
    // a dry run on the caller's copy, for the Deep Scan's pointer rules (cDeepScanner._PointerMoveHits,
    // 2026-10-20). Any other name: none.
    Function _PointerMoveLines String[] asCode String sFn Returns Integer[]
        Handle  ho
        Integer iChanges
        Integer[] aiLines

        If (sFn = "UnicodePointerToString") Begin
            Get Create (RefClass(cUnicodePointerToString)) to ho
            Get UnicodePointerToString of ho (&asCode) to iChanges
            Get paiChangedLines of ho to aiLines
            Send Destroy of ho
        End
        Else If (sFn = "UnicodeStringToPointer") Begin
            Get Create (RefClass(cUnicodeStringToPointer)) to ho
            Get UnicodeStringToPointer of ho (&asCode) to iChanges
            Get paiChangedLines of ho to aiLines
            Send Destroy of ho
        End
        Function_Return aiLines
    End_Function

    /* UnicodeWin64ReportExternalFunction audits External_Function / External_Procedure
       declarations for the DF21+ (64-bit + Unicode) era and writes a report - it changes
       NOTHING. The per-declaration analysis lives in cRefactorUtilities._AuditApiDeclaration
       (+ _SuggestPointerType); this wrapper walks each selected file, joins ";"-continued
       declaration lines into one logical line, runs the audit, and logs the findings to the
       backup folder (surfaced via the 'Other Log Files' toolbar button, like the Unused* reports).
       PASS 2 (Nils 2026-07-04, the A->W migration report): the ANSI ("...A" entry point)
       declarations collected in pass 1 get a workspace-wide CALL-SITE sweep - the full blast
       radius of migrating each wrapper to its ...W entry point - with address-taking calls
       tagged [structural] (those need the WString buffer + CString surgery, not just a rename).
       Detection cores are PURE + unit-tested: _AnsiExternalName / _AnsiCallSitePos (cRefactorUtilities).
    */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Checks every External_Function and External_Procedure declaration. It reports Integer and DWord parameters or return values whose name shows that they hold a pointer-sized Windows type (hWnd, lp*, lParam, *size* ...), which should be Handle, Pointer, Longptr or ULongptr. It also reports String parameters in an ANSI ("...A") declaration, which should be WString.
        Then it lists every call of each ANSI declaration, which shows how much code a change to the wide version would affect, and marks buffer calls that pass an address with [structural].
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Unicode64 }
        { SummaryText = Report: External_Function 64-bit/Unicode types + ANSI (...A) call sites }
        """ }
    Function UnicodeWin64ReportExternalFunction String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath sDecl sTrim sLC sDfName sEntry sDll sTag
        String[] asCode asFindings asEmpty asOtherLogFiles asAnsiNames asAnsiNamesLC asAnsiInfo
        Integer iCh iFile iFileLast iLine iLineLast iDeclLine iN iFind iFindLast iTotal
        Integer iIdx iName iAnsiLast iPos iCallTotal
        Integer[] aiCallCounts
        Boolean bFileHeader bPanel bCancel bGate

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_UnicodeWin64ReportLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Win64 / Unicode External_Function audit  (report only - no changes made)."
        Writeln channel iCh "Flags Integer/DWord params or returns that should be Handle/Pointer/Longptr/ULongptr,"
        Writeln channel iCh "and String params in an ANSI (...A) entry-point wrapper that should be WString."
        Writeln channel iCh "A second section lists every CALL SITE of each ANSI wrapper - the A->W blast radius."
        Writeln channel iCh ""

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per
        // file - otherwise it looks frozen when this is the only function run.
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        If (bPanel = True) ;
            Set piMaximumTot of ghoStatusPanel to (iFileLast + 1)
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            If (bPanel = True) Begin
                Set Caption_Text of ghoStatusPanel to ("External_Function audit - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text of ghoStatusPanel to "Auditing External_Function declarations:"
                Set TableName_Text of ghoStatusPanel to sFilePath
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move False to bFileHeader
            // FILE PRE-GATE (Nils 2026-07-16 perf sweep): declarations start with External_Function /
            // External_Procedure, so "external_" anywhere in the raw text is the necessary condition -
            // no mention folds iLineLast to 0 and the whole per-line trim/parse loop is skipped
            // (_FileContainsText semantics: false hits harmless, never a false miss).
            Get _FileContainsText (&asCode) "external_" to bGate
            If (bGate = True) ;
                Move (SizeOfArray(asCode)) to iLineLast
            Else ;
                Move 0 to iLineLast
            If (bPanel = True) Begin
                Set piPosition of ghoProgressBar to 0
                Set piMaximum  of ghoProgressBar to iLineLast
            End
            If (iLineLast > 0) Begin
                Decrement iLineLast
                Move 0 to iLine
                While (iLine <= iLineLast)
                    // Per-file bar + elapsed clock: the canonical ~20-line nudge
                    // (Update_StatusPanel sets Action_Text, which drives UpdateTimeSpan).
                    If (Mod(iLine, 20) = 0 and bPanel = True) Begin
                        Send Update_StatusPanel of ghoStatusPanel ("Source line:" * String(iLine + 1) * "of:" * String(iLineLast + 1))
                        Set piPosition of ghoProgressBar to (iLine + 1)
                    End
                    Move (Replaces((Character(9)), asCode[iLine], " ")) to sTrim
                    Move (Trim(sTrim)) to sTrim
                    Move (Lowercase(sTrim)) to sLC
                    If (Left(sLC, 18) = "external_function " or Left(sLC, 19) = "external_procedure ") Begin
                        // Join ";"-continued lines into one logical declaration before auditing.
                        Move sTrim to sDecl
                        Move iLine to iDeclLine
                        While (Right(Trim(sDecl), 1) = ";" and iLine < iLineLast)
                            Move (Trim(Left(Trim(sDecl), (Length(Trim(sDecl)) - 1)))) to sDecl
                            Increment iLine
                            Move (sDecl + " " + Trim(asCode[iLine])) to sDecl
                        Loop
                        /* THE CATALOGUE FIRST, THE HEURISTIC ONLY WHERE IT HAS TO (Nils 2026-08-09).
                           For an API in WinAPICatalog.inc the SDK's own signature is known, so the
                           finding is a fact - "parameter 1: Integer -> Handle (Windows SDK)" - rather
                           than an inference from what the parameter happens to be CALLED. Where the
                           catalogue is silent, which is still the long tail of 687 APIs, the name
                           heuristics are all there is and nothing changes. -1 is the not-covered
                           signal, deliberately distinct from 0 findings. */
                        Move asEmpty to asFindings
                        Get _WinAPICatalogueFindings sDecl (&asFindings) to iN
                        If (iN = -1) Begin
                            Move asEmpty to asFindings
                            Get _AuditApiDeclaration sDecl (&asFindings) to iN
                        End
                        If (iN > 0) Begin
                            If (bFileHeader = False) Begin
                                Writeln channel iCh ("=== " + sFilePath + " ===")
                                Move True to bFileHeader
                            End
                            Writeln channel iCh ("  Line " + String(iDeclLine + 1) + ":  " + Trim(sDecl))
                            Move (SizeOfArray(asFindings)) to iFindLast
                            Decrement iFindLast
                            For iFind from 0 to iFindLast
                                Writeln channel iCh ("        " + asFindings[iFind])
                            Loop
                            Add iN to iTotal
                        End
                        // Collect the ANSI ("...A") entry points for PASS 2 (call sites) - deduped by
                        // DF name (the #IFDEF-guarded redeclare pattern declares one name in several files).
                        Get _AnsiExternalName sDecl (&sEntry) (&sDll) to sDfName
                        If (sDfName <> "") Begin
                            Move (SearchArray(Lowercase(sDfName), asAnsiNamesLC)) to iIdx
                            If (iIdx = -1) Begin
                                Move sDfName to asAnsiNames[SizeOfArray(asAnsiNames)]
                                Move (Lowercase(sDfName)) to asAnsiNamesLC[SizeOfArray(asAnsiNamesLC)]
                                Move (sEntry + ", " + sDll + " - declared " + sFilePath + " line " + String(iDeclLine + 1)) to asAnsiInfo[SizeOfArray(asAnsiInfo)]
                            End
                        End
                    End
                    Increment iLine
                Loop
                If (bFileHeader = True) ;
                    Writeln channel iCh ""
            End
            // Mid-run cancel (the Cancel button): a *All function gets ONE call for all files,
            // so the engine's per-file Cancel_Check cannot fire while we scan. Poll the safe
            // accessor (NEVER Cancel_Check - it consumes the signal) and bail; the engine's
            // outer Cancel_Check then runs the confirm pipeline once. The panel text setters
            // pump ProcessEvents, so the click lands via the ~20-line nudges above.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        // ---- PASS 2: call sites of the collected ANSI (...A) entry points. ----
        // This is the A->W migration blast radius: an in-parameter String still passes after
        // switching to the ...W entry point (WString), but an OUT buffer needs a null-filled
        // WString (Repeat(Character(0), N)) + AddressOf + CString back out - so calls that
        // already take an address are tagged [structural].
        Move 0 to iCallTotal
        Move (SizeOfArray(asAnsiNames) - 1) to iAnsiLast
        If (iAnsiLast >= 0 and bCancel = False) Begin
            Writeln channel iCh "=== ANSI (...A) entry points - call sites (the A->W migration blast radius) ==="
            Writeln channel iCh "Migrating a declaration to its ...W entry point (String -> WString) touches EVERY"
            Writeln channel iCh "call site: in-parameters still pass unchanged, but an OUT buffer needs a null-filled"
            Writeln channel iCh "WString (Repeat(Character(0), N)) + AddressOf + CString back out. [structural] marks"
            Writeln channel iCh "calls already taking an address - buffer surgery is certain there."
            Writeln channel iCh ""
            For iName from 0 to iAnsiLast
                Move 0 to aiCallCounts[iName]
            Loop
            If (bPanel = True) ;
                Set piPositionTot of ghoStatusPanel to 0
            For iFile from 0 to iFileLast
                Move asFiles[iFile] to sFilePath
                If (bPanel = True) Begin
                    Set Caption_Text of ghoStatusPanel to ("ANSI call-site scan - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text of ghoStatusPanel to "Scanning for ...A call sites:"
                    Set TableName_Text of ghoStatusPanel to sFilePath
                    Send DoAdvanceTot of ghoStatusPanel
                End
                Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
                Move False to bFileHeader
                // FILE PRE-GATE (Nils 2026-07-16 perf sweep): a call site requires one of the
                // collected ANSI names in the raw text - no mention folds iLineLast to 0 and the
                // per-line name loop is skipped for the whole file.
                Get _FileContainsAnyText (&asCode) (&asAnsiNamesLC) to bGate
                If (bGate = True) ;
                    Move (SizeOfArray(asCode)) to iLineLast
                Else ;
                    Move 0 to iLineLast
                If (bPanel = True) Begin
                    Set piPosition of ghoProgressBar to 0
                    Set piMaximum  of ghoProgressBar to iLineLast
                End
                If (iLineLast > 0) Begin
                    Decrement iLineLast
                    For iLine from 0 to iLineLast
                        // Per-file bar + elapsed clock: the canonical ~20-line nudge
                        // (Update_StatusPanel sets Action_Text, which drives UpdateTimeSpan).
                        If (Mod(iLine, 20) = 0 and bPanel = True) Begin
                            Send Update_StatusPanel of ghoStatusPanel ("Source line:" * String(iLine + 1) * "of:" * String(iLineLast + 1))
                            Set piPosition of ghoProgressBar to (iLine + 1)
                        End
                        Move (Replaces((Character(9)), asCode[iLine], " ")) to sTrim
                        Move (Trim(sTrim)) to sTrim
                        Move (Lowercase(sTrim)) to sLC
                        // Skip pure comment lines and the declarations themselves (pass 1's territory).
                        If (Left(sLC, 2) <> "//" and Left(sLC, 18) <> "external_function " and Left(sLC, 19) <> "external_procedure ") Begin
                            For iName from 0 to iAnsiLast
                                // Native Pos pre-gate per name: only a line that even CONTAINS the
                                // name pays the interpreted boundary-aware _AnsiCallSitePos check
                                // (N names x every line adds up on a big workspace).
                                Move 0 to iPos
                                If (Pos(asAnsiNamesLC[iName], sLC) > 0) ;
                                    Get _AnsiCallSitePos sLC asAnsiNamesLC[iName] to iPos
                                If (iPos > 0) Begin
                                    If (bFileHeader = False) Begin
                                        Writeln channel iCh ("=== " + sFilePath + " ===")
                                        Move True to bFileHeader
                                    End
                                    Move "" to sTag
                                    If (Pos("addressof", sLC) > 0 or Pos("getaddress", sLC) > 0) ;
                                        Move "   [structural - address-taking buffer call]" to sTag
                                    Writeln channel iCh ("  Line " + String(iLine + 1) + "  (" + asAnsiNames[iName] + "):  " + sTrim + sTag)
                                    Move (aiCallCounts[iName] + 1) to aiCallCounts[iName]
                                    Increment iCallTotal
                                End
                            Loop
                        End
                    Loop
                    If (bFileHeader = True) ;
                        Writeln channel iCh ""
                End
                // Same mid-run cancel poll as pass 1.
                Get pbUserCancelRequested of ghoEngine to bCancel
                If (bCancel = True) ;
                    Move iFileLast to iFile
            Loop
            Writeln channel iCh "Per ANSI entry point:"
            For iName from 0 to iAnsiLast
                Writeln channel iCh ("  " + asAnsiNames[iName] + "  (" + asAnsiInfo[iName] + ")  -  " + String(aiCallCounts[iName]) + " call site(s)")
            Loop
            Writeln channel iCh ""
        End

        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        If (bCancel = True) Begin
            Writeln channel iCh ""
            Writeln channel iCh "*** Cancelled by the user - this report is INCOMPLETE. ***"
        End
        Writeln channel iCh ("Total: " + String(iTotal) + " suggestion(s), " + String(iCallTotal) + " ANSI call site(s).")
        Send rfCloseOutput iCh

        If (iTotal + iCallTotal > 0) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Move sLogFile to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Function_Return (iTotal + iCallTotal)
    End_Function

    /* Win64AddressToPointer modernizes the legacy native-pointer TYPE for 64-bit: the guide
       calls Pointer "a replacement for Address" (the same pointer-sized type), so a
       declaration "Address pFoo" becomes "Pointer pFoo". Line-by-line (eStandardFunction);
       renames ONLY the type slot of a declaration (first token, or the token after Property
       / Global_Variable / Class_Global) via cRefactorUtilities._RenameLeadingType, which is
       whole-word and never touches a field (Customer.Address), a longer identifier
       (AddressOf, sAddress), or a variable merely named "Address". Parameter and "Returns"
       types sit mid-signature and are intentionally out of scope here.
    */
    { Published = True }
    { Description = """
        64-bit fix: changes the type Address to Pointer, the replacement that the DataFlex documentation names, in local variables, struct members, Property and Global_Variable declarations.
        Only whole words are changed, and running it again changes nothing. AddressOf, fields and a variable named "Address" are never changed. Parameter and return types are not changed.
        { MethodType = eStandardFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Renamed type: Address -> Pointer }
        """ }
    Function Win64AddressToPointer String ByRef sLine String sParameter Returns Boolean
        String sNewLine sOverFull
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (TokenizerData.bIsBlank = True or TokenizerData.bIsComment = True) Begin
            Function_Return False
        End

        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull
        Get _RenameLeadingType sLine sOverFull "Address" "Pointer" to sNewLine
        If (sNewLine = sLine) Begin
            Function_Return False
        End
        Move sNewLine to sLine
        Function_Return True
    End_Function

    /* Win64PointerTruncation is a REPORT-ONLY audit (makes no changes) for the 64-bit
       pointer-truncation bug. The per-method analysis lives in the worker class
       cWin64PointerTruncation; this wrapper walks each selected file, resets the lexer,
       runs the audit, and writes a consolidated log (surfaced via the 'Other Log Files'
       toolbar button, like the other report functions).
    */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        64-bit check: reports a pointer-sized value that is moved into a 32-bit Integer or DWord, which cuts it off without any message in a 64-bit program. The value can be a variable or parameter declared as Pointer or Address, or the result of AddressOf(). Each method is checked on its own.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Unicode64 }
        { SummaryText = Reported: pointer-to-Integer truncation risks (64-bit) }
        """ }
    Function Win64PointerTruncation String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        String sHomePath sLogFile sFilePath
        String[] asCode asFindings asEmpty
        Integer iCh iFile iFileLast iN iTotal
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_Win64PointerTruncationLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Win64 pointer-truncation audit  (report only - no changes made)."
        Writeln channel iCh "Flags a Pointer/Address variable, or an AddressOf() result, moved into a"
        Writeln channel iCh "32-bit Integer/DWord - which silently truncates the pointer on x64."
        Writeln channel iCh ""

        Get Create (RefClass(cWin64PointerTruncation)) to ho
        If (ho = 0) Begin
            Send rfCloseOutput iCh
            Error "Could not create cWin64PointerTruncation object."
            Function_Return 0
        End

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per
        // file - otherwise it looks frozen when Win64PointerTruncation is the only function run.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Pointer truncation - File No:" "Scanning for pointer truncation:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asFindings
            Send ClearFuncLibProperties of ghoFuncLib
            Get AuditFile of ho asCode (&asFindings) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asFindings
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
        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " truncation risk(s)."
        Function_Return iTotal
    End_Function

    /* ChangeStructMemberLegacyTypes (2026-11-12) - the repair for Structs that carry a legacy Type field type.
       Until 2026-11-12 the Win32 Type converters kept a Type's own member types when the catalogue did not know it,
       and wrote "Word StructSize" for "Field PEWindowOptions.StructSize as Word": 62 errors in one converted Crystal
       Reports package (4298 on each Word line, 4545 for the empty Structs, 4328 for every member read). The converter
       now maps the type (_LegacyFieldTypeToDataFlex); this fixes what it wrote before, and Structs written by hand.
       The worker is cRefactorFuncLib._LegacyStructMemberTypesInLines.
    */
    { Published = True }
    { Description = """
        Changes a Struct member of type Word, Byte or Long to UShort, UChar or Integer: the same size, in a type that DataFlex 26 knows.
        Word, Byte and Long are field types of legacy Type blocks. In a Struct, DataFlex 26 reads "Word wYear" as an unknown command (error 4298), the Struct is then empty (error 4545), and every use of its members fails.
        Converters before 2026-11-12 copied the field types of a legacy Type into the Struct they created, so a converted Type can contain them, and so can a Struct written by hand.
        Before:  Word StructSize
        After:   UShort StructSize
        Only member lines between Struct and End_Struct are changed, and only the type word.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4298 | not found word }
        { ModRecipe = 4298 | not found byte }
        { ModRecipe = 4298 | not found long }
        { SummaryText = Struct members retyped: Word/Byte/Long -> UShort/UChar/Integer }
        """ }
    Function ChangeStructMemberLegacyTypes String[] ByRef asCode String sParameter Returns Integer
        Integer iCount
        Boolean bGate

        // Cheap gate: no End_Struct in the file, no Struct to repair.
        Get _FileContainsText (&asCode) "end_struct" to bGate
        If (bGate = False) ;
            Function_Return 0
        Get _LegacyStructMemberTypesInLines (&asCode) to iCount
        Function_Return iCount
    End_Function

    /* Win64IntegerToLongPtr - the fix half of Win64PointerTruncation (2026-11-12). On a 64-bit build
       every pointer moved into a 32-bit Integer/DWord is compile error 4539, "Conversion from 64-bit
       pointer to integer is not allowed, use Longptr instead of Integer". This takes the compiler's
       advice where it is safe; what it leaves, and why, is in the { Description } and above the worker,
       cWin64PointerTruncation.RetypePointerTargets. Found on a legacy library's converted code: a 1990s
       "GetAddress Of OemStr To OemAdress" became "Move (AddressOf(OemStr)) to OemAdress" with OemAdress
       still declared Integer - the program's last two errors.
    */
    { Published = True }
    { Description = """
        64-bit fix for compile error 4539: a local Integer or DWord variable that holds a pointer becomes a LongPtr, as the compiler's message advises: "use Longptr instead of Integer".
        Before:  Integer iAddr
        Move (AddressOf(sBuffer)) to iAddr
        After:   LongPtr iAddr
        Move (AddressOf(sBuffer)) to iAddr
        The source can be AddressOf() or a variable declared as Pointer or Address. When a declaration names several variables, the others keep their type, and a LongPtr line for the changed ones is added after it.
        Only a variable declared in the same method gets the new type. A parameter, a global variable, a property, or a variable passed ByRef (&iAddr) is not changed; Win64PointerTruncation lists them for a manual fix. Only the plain form "Move <source> to <variable>" is recognised.
        A LongPtr can be used everywhere the Integer was used: in calculations, Move statements, parameters and comparisons.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4539 | 64-bit pointer to integer }
        { SummaryText = Retyped to LongPtr: Integer/DWord locals holding a pointer (64-bit) }
        """ }
    Function Win64IntegerToLongPtr String[] ByRef asCode String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        Get Create (RefClass(cWin64PointerTruncation)) to ho
        If (ho = 0) Begin
            Error "Could not create cWin64PointerTruncation object. (Function: Win64IntegerToLongPtr)"
            Function_Return 0
        End

        Get RetypePointerTargets of ho (&asCode) to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* Win64StructPadding - a report-only audit; what it flags, and the shape of the fix, now
       live in the { Description }. Maintainer notes: the per-struct analysis lives in the worker
       class cWin64StructPadding. This wrapper only walks each selected file, resets the lexer,
       runs the audit and writes a consolidated log, surfaced via the 'Other Log Files' toolbar
       button like the other report functions.
    */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        64-bit check: in each Struct...End_Struct, reports a pointer-sized member (Pointer, Address, Handle, Longptr or ULongptr) that does not start at an offset that is a multiple of 8, and therefore needs an extra member for 64-bit. A struct with a member of unknown size, or one that already uses an Is$Win64 condition, is noted and skipped.
        The report does not change the code. Make the fix with the "Structure Padding Helper" tool from Data Access.
        DataFlex structs do not add padding automatically as C does, so the fix is an extra member that is only compiled for 64-bit (#IFDEF Is$Win64 / Integer iAlign / #ENDIF), placed before the misaligned member in a struct that mirrors a Win32 API structure.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Unicode64 }
        { SummaryText = Reported: struct pointer-member alignment risks (64-bit) }
        """ }
    Function Win64StructPadding String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        String sHomePath sLogFile sFilePath
        String[] asCode asFindings asEmpty
        Integer iCh iFile iFileLast iN iTotal
        Boolean bPanel bCancel

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_Win64StructPaddingLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) Begin
            Function_Return 0
        End

        Writeln channel iCh "Win64 struct-padding audit  (report only - no changes made)."
        Writeln channel iCh "Flags a pointer-sized struct member that is not 8-byte aligned on x64"
        Writeln channel iCh "and so needs an Is$Win64 filler. DataFlex structs do not auto-pad like C."
        Writeln channel iCh ""

        Get Create (RefClass(cWin64StructPadding)) to ho
        If (ho = 0) Begin
            Send rfCloseOutput iCh
            Error "Could not create cWin64StructPadding object."
            Function_Return 0
        End

        Move 0 to iTotal
        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        // This report loops files itself (eReportFunctionAll), so drive the status panel per
        // file - otherwise it looks frozen when Win64StructPadding is the only function run.
        Get _ReportPanelStart iFileLast to bPanel
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            Send _ReportPanelFile bPanel "Struct padding - File No:" "Scanning structs for 64-bit padding:" sFilePath iFile iFileLast
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move asEmpty to asFindings
            Send ClearFuncLibProperties of ghoFuncLib
            Get AuditFile of ho asCode (&asFindings) to iN
            If (iN > 0) Begin
                Send _ReportWriteFindings iCh sFilePath asFindings
                Add iN to iTotal
            End
            // Same mid-run cancel poll as Win64PointerTruncation.
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Send Destroy of ho
        Send _ReportFinish iCh sLogFile iTotal bCancel bPanel " alignment finding(s)."
        Function_Return iTotal
    End_Function

    /* WinApiCallSiteReport - WHERE THE RESULT GOES, for every Windows API this workspace declares
       with a return type the SDK disagrees with. Report only.

       ConvertWinAPIDeclarationTypes fixes the DECLARATION. That is the half a compiler can check,
       and it is not the half that bites: correcting "Returns Integer" to "Returns Handle" leaves
       every "Move (Api(...)) to iRet" still assigning eight bytes into four, which compiles clean
       and truncates an address at run time on x64. _CallSiteNoteForReturnChange names those, but
       only inside the file being converted, only for a pointer-sized new return, and only while
       the run is happening. This is the standing, workspace-wide version.

       WHY IT REPORTS AND DOES NOT REWRITE: a receiver almost never exists to hold this one result.
       It is a local that other statements assign to and read, so widening it to Handle can break
       arithmetic somewhere else in the procedure, and narrowing anything is worse. The judgement
       needs a human who can see the whole routine - so the tool supplies evidence, not edits.
       (Backlog item raised 2026-08-28 with the WinAPI campaign; built 2026-08-30.)

       TWO PASSES over the selected files, like UnicodeWin64ReportExternalFunction: pass 1 finds the
       declarations the catalogue contradicts, pass 2 sweeps every file for calls to those names.
       The pure cores are cRefactorFuncLib._ApiCallReceiverOnLine and _DeclaredTypeOfVarInLines. */
    { Published = True }
    { Description = """
        Reports only. Makes no changes to the source code.
        Finds every External_Function whose declared return type differs from the Windows SDK, and lists each call that stores the result, with the variable that receives it and the type it was declared with.
        A receiving variable that is smaller than the SDK's return type is the 64-bit error this report finds: it compiles without errors, and loses the top four bytes of an address.
        Nothing is changed, because a receiving variable is usually used in other statements too, so changing its type is a decision that needs someone to read the whole method.
        The results are written to a log file; open it with Tools > Logs > Other Log Files.
        { MethodType = eReportFunctionAll }
        { FnGroup = Unicode64 }
        { SummaryText = Report: call sites whose receiver may truncate a corrected API return }
        """ }
    Function WinApiCallSiteReport String[] ByRef asFiles String sParameter Returns Integer
        String sHomePath sLogFile sFilePath sDecl sHead sLocalRet sSdkRet sName sReceiver sRecType
        String sSdkRow sLocalCls sSdkCls sRecCls sFlag sRest sDll sEntry
        String[] asCode asCat asTmp asNames asDeclWhere asLocal asSdk asEmpty asOtherLogFiles
        Integer iCh iFile iFileLast i iLast iBar iName iNameLast iTotal iSites iNarrow
        Boolean bPanel bCancel bAny

        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath) + CS_BackupFolder + CS_DirSeparator + CS_WinApiCallSiteLogFile) to sLogFile
        Get rfOpenOutput sLogFile to iCh
        If (iCh < 0) ;
            Function_Return 0

        Writeln channel iCh "Windows API call-site worksheet  (report only - no changes made)."
        Writeln channel iCh "Each API below is declared here with a RETURN type the SDK catalogue disagrees with, so every"
        Writeln channel iCh "call site that stores its result is listed with the receiver and the type it was declared as."
        Writeln channel iCh "A receiver NARROWER than the SDK return is the x64 bug this looks for: an 8-byte handle or"
        Writeln channel iCh "pointer assigned into a 4-byte Integer compiles clean and loses the top half of the address."
        Writeln channel iCh "Nothing is rewritten - the same variable usually serves other statements, so widening it is a"
        Writeln channel iCh "judgement for someone reading the whole routine. Fix the DECLARATION with"
        Writeln channel iCh "ConvertWinAPIDeclarationTypes first; this worksheet is the follow-up work it cannot do."
        Writeln channel iCh ""

        Send RefreshWinAPICatalogsFromJson
        Get pasWinAPICatalog to asCat
        If (SizeOfArray(asCat) = 0) Begin
            Writeln channel iCh "The Windows API catalogue is EMPTY - nothing could be judged. Run the Win32 projection"
            Writeln channel iCh "harvest (or restore Data\WinAPICatalog.json) and run this report again."
            Send rfCloseOutput iCh
            Function_Return 0
        End

        Move (SizeOfArray(asFiles)) to iFileLast
        Decrement iFileLast
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        If (bPanel = True) ;
            Set piMaximumTot of ghoStatusPanel to ((iFileLast + 1) * 2)

        // ---- PASS 1: declarations the catalogue contradicts -------------------------------------
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFilePath
            If (bPanel = True) Begin
                Set Caption_Text of ghoStatusPanel to ("API returns - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text of ghoStatusPanel to "Reading declarations:"
                Set TableName_Text of ghoStatusPanel to sFilePath
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
            Move (SizeOfArray(asCode) - 1) to iLast
            Move 0 to i
            While (i <= iLast)
                Get _ExternalFnHeadPacked of ghoFuncLib asCode[i] to sHead
                If (sHead <> "") Begin
                    // join the ";"-continued declaration into one logical line
                    Move (Trim(asCode[i])) to sDecl
                    While (Right(sDecl, 1) = ";" and i < iLast)
                        Move (Trim(Left(sDecl, (Length(sDecl) - 1)))) to sDecl
                        Increment i
                        Move (sDecl + " " + Trim(asCode[i])) to sDecl
                    Loop
                    /* The head packs "NAME|dll|entry"; split it the way _CorrectedApiDecl does, then
                       ask _WinAPIDataFlexDeclFromCat for the DECLARATION. Not _WinAPICatalogFindRow +
                       the raw row: a catalogue row is "dll|entry|DF|External_Function ...", so handing
                       it straight to _ExternalFnParamTypes would parse the routing prefix as tokens. */
                    Move (Pos("|", sHead)) to iBar
                    Move (Left(sHead, (iBar - 1)))                      to sName
                    Move (Right(sHead, (Length(sHead) - iBar)))         to sRest
                    Move (Pos("|", sRest)) to iBar
                    Move (Left(sRest, (iBar - 1)))                      to sDll
                    Move (Right(sRest, (Length(sRest) - iBar)))         to sEntry
                    Get _WinAPIDataFlexDeclFromCat of ghoFuncLib (&asCat) sDll sEntry to sSdkRow
                    If (sSdkRow <> "") Begin
                        Get _ExternalFnParamTypes of ghoFuncLib sDecl (&asTmp) to sLocalRet
                        Get _ExternalFnParamTypes of ghoFuncLib sSdkRow (&asTmp) to sSdkRet
                        Get _ApiTypeClass of ghoFuncLib sLocalRet to sLocalCls
                        Get _ApiTypeClass of ghoFuncLib sSdkRet   to sSdkCls
                        If (sLocalRet <> "" and sSdkRet <> "" and sLocalCls <> sSdkCls) Begin
                            Move sName                                   to asNames[SizeOfArray(asNames)]
                            Move (sFilePath + " (ln " + String(i + 1) + ")") to asDeclWhere[SizeOfArray(asDeclWhere)]
                            Move sLocalRet                               to asLocal[SizeOfArray(asLocal)]
                            Move sSdkRet                                 to asSdk[SizeOfArray(asSdk)]
                        End
                    End
                End
                Increment i
            Loop
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        Move (SizeOfArray(asNames) - 1) to iNameLast
        If (iNameLast < 0 or bCancel = True) Begin
            If (bPanel = True) ;
                Set Title_Text of ghoStatusPanel to ""
            If (bCancel = True) ;
                Writeln channel iCh "*** Cancelled by the user - this report is INCOMPLETE. ***"
            Else ;
                Writeln channel iCh "No declared API return disagrees with the catalogue. Nothing to chase."
            Send rfCloseOutput iCh
            Function_Return 0
        End

        // ---- PASS 2: every call site of those names ---------------------------------------------
        Move 0 to iTotal
        Move 0 to iNarrow
        For iName from 0 to iNameLast
            Move asNames[iName] to sName
            Get _ApiTypeClass of ghoFuncLib asSdk[iName] to sSdkCls
            Writeln channel iCh ("=== " + sName + "   declared in " + asDeclWhere[iName])
            Writeln channel iCh ("    declared Returns " + asLocal[iName] + "   |   SDK Returns " + asSdk[iName])
            Move 0 to iSites
            Move False to bAny
            For iFile from 0 to iFileLast
                Move asFiles[iFile] to sFilePath
                If (bPanel = True and iName = 0) Begin
                    Set Caption_Text of ghoStatusPanel to ("Call sites - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text of ghoStatusPanel to "Sweeping call sites:"
                    Set TableName_Text of ghoStatusPanel to sFilePath
                    Send DoAdvanceTot of ghoStatusPanel
                End
                Move (rfReadEncodedFileAsStringArray(sFilePath)) to asCode
                Move (SizeOfArray(asCode) - 1) to iLast
                For i from 0 to iLast
                    // a declaration line mentions the name but is not a call site
                    Get _ExternalFnHeadPacked of ghoFuncLib asCode[i] to sHead
                    If (sHead = "") Begin
                        Get _ApiCallReceiverOnLine of ghoFuncLib asCode[i] sName (&sReceiver) to bAny
                        If (bAny = True) Begin
                            Get _DeclaredTypeOfVarInLines of ghoFuncLib (&asCode) sReceiver to sRecType
                            Move "" to sFlag
                            If (sRecType = "") Begin
                                Move "   [not declared in this file - a property, a struct member, or an include]" to sFlag
                            End
                            Else Begin
                                Get _ApiTypeClass of ghoFuncLib sRecType to sRecCls
                                If (sRecCls <> sSdkCls and sSdkCls = "ptr") Begin
                                    Move "   *** NARROWER than the SDK return - truncates on x64" to sFlag
                                    Increment iNarrow
                                End
                            End
                            If (sRecType = "") ;
                                Move "?" to sRecType
                            Writeln channel iCh ("      " + sFilePath + " (ln " + String(i + 1) + ")  " ;
                                + sReceiver + " declared " + sRecType + sFlag)
                            Increment iSites
                            Increment iTotal
                        End
                    End
                Loop
                Get pbUserCancelRequested of ghoEngine to bCancel
                If (bCancel = True) ;
                    Move iFileLast to iFile
            Loop
            If (iSites = 0) ;
                Writeln channel iCh "      (no call site stores this result - the declaration alone needs fixing)"
            Writeln channel iCh ""
            If (bCancel = True) ;
                Move iNameLast to iName
        Loop

        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        If (bCancel = True) Begin
            Writeln channel iCh ""
            Writeln channel iCh "*** Cancelled by the user - this report is INCOMPLETE. ***"
        End
        Writeln channel iCh ("Total: " + String(iTotal) + " call site(s) across " + String(iNameLast + 1) ;
            + " API(s) whose declared return disagrees with the SDK; " + String(iNarrow) ;
            + " receiver(s) look NARROWER than the SDK return.")
        Send rfCloseOutput iCh

        If (iTotal > 0) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Move sLogFile to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Function_Return iTotal
    End_Function

    /* ChangeOemFileCommands drops the _Oem suffix from the legacy file commands.

       THE SAME WARNING AS ToANSI, A DIFFERENT SHAPE. File_Exist_Oem, EraseFile_Oem,
       CopyFile_Oem and Direct_Input_Oem are compiler intrinsics that convert their path
       from the OEM codepage before using it, so the compiler reports them as W 4534
       "Obsolete use of ToANSI" - the same message UnicodeOemAnsiFunctions answers. That
       function renames CALLS (it needs a following parenthesis), and these are COMMANDS,
       which is why a sweep that converted 5,854 ToANSI/ToOEM calls left every one of
       these standing: 35 of them in WinServ, and not one was a miss - they were never
       the same shape (2026-08-26).

       WHY DROPPING THE SUFFIX IS THE FIX. Under the Unicode compiler a path is UTF-8, so
       the OEM conversion these commands apply corrupts any non-ASCII name and is a no-op
       for the rest. The plain command is what DataFlex documents; the spellings emitted
       here (File_Exist, EraseFile, CopyFile, Direct_Input) are the install's own, taken
       from <install>\Lib\DataFlex.lng rather than typed from memory.

       SUGGEST, NOT AutoFix, deliberately. This rewrites file I/O and one of the four
       ERASES files, so it wants a live verification before it runs unasked - the same
       graduation any rule gets. Promote it once a workspace has been through it.

       Direct_Output_Oem and Append_Output_Oem are in the table without appearing in any
       corpus yet: they are the same family and their plain spellings are confirmed, so a
       workspace that has them is covered rather than half-covered.

       No ModRecipe MATCH TEXT can separate this from UnicodeOemAnsiFunctions - the
       compiler emits identical text for both, because both really are a ToANSI use. Both
       are therefore offered for a 4534 row, which costs nothing: each is a no-op on a
       line the other owns. */
    { Published = True }
    { Description = """
        Removes the obsolete _Oem ending from the legacy file commands: File_Exist_Oem, EraseFile_Oem, CopyFile_Oem, Direct_Input_Oem, Direct_Output_Oem and Append_Output_Oem become File_Exist, EraseFile, CopyFile, Direct_Input, Direct_Output and Append_Output.
        With the Unicode compiler, the OEM conversion that these commands make damages a path with non-ASCII characters, and does nothing for other paths.
        Only the command itself is changed, so a variable with a similar name is not changed. Strings and comments are skipped.
        { MethodType = eStandardFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4534 | use of ToANSI | Suggest }
        { SummaryText = Dropped: _Oem suffix from the legacy file commands }
        """ }
    Function ChangeOemFileCommands String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged bAny
        Integer i iLast
        String[] asFrom asTo

        Move "File_Exist_Oem"     to asFrom[0]
        Move "File_Exist"         to asTo[0]
        Move "EraseFile_Oem"      to asFrom[1]
        Move "EraseFile"          to asTo[1]
        Move "CopyFile_Oem"       to asFrom[2]
        Move "CopyFile"           to asTo[2]
        Move "Direct_Input_Oem"   to asFrom[3]
        Move "Direct_Input"       to asTo[3]
        Move "Direct_Output_Oem"  to asFrom[4]
        Move "Direct_Output"      to asTo[4]
        Move "Append_Output_Oem"  to asFrom[5]
        Move "Append_Output"      to asTo[5]

        // _SwapCommandKeyword carries its own LineIsNotCode guard and only fires when the
        // name is a whole token at the command position, so this is a plain walk of the table.
        Move False to bAny
        Move (SizeOfArray(asFrom) - 1) to iLast
        For i from 0 to iLast
            Get _SwapCommandKeyword (&sLine) asFrom[i] asTo[i] to bChanged
            If (bChanged = True) ;
                Move True to bAny
        Loop
        Function_Return bAny
    End_Function

    /* RetireOemTranslateState - the Oem_Translate_State property does nothing on a Unicode DataFlex.
       DataFlex says so itself: Windows.pkg marks BOTH accessors MARK$AS$OBSOLETEUNICODE, and every use
       raises W 4540 "Obsolete Object Function ... controls are Unicode now". The property still exists,
       so nothing fails to compile - the warning is the only signal, which is why these sites survive for
       years (Nils's WinServ: 20 of them).

       TWO SHAPES, TWO TREATMENTS - the distinction is the whole point of this function:

         Set Oem_Translate_State [of <obj>] to <x>     nothing reads a value -> a pure no-op today, so
                                                      the line is simply commented out.

         Get Oem_Translate_State ... to <var>          the value FEEDS A TEST. Commenting out the Get
         If (not(<var>)) Begin                         alone would leave <var> at its declared default
             <body>                                    (False), flipping the test to always-true and
         End                                           running <body> unconditionally - which in the
                                                       real case downgraded UTF-8 to ANSI on its way
                                                       into a Unicode control. So the WHOLE block is
                                                       commented behind a marker, for a human to delete
                                                       or to restore without the test.

       The four guards that must hold before a block is touched (next line is an If on that variable,
       the variable is read nowhere else, no Else, a matching End) live with the pure core in
       cRefactorFuncLib._RetireOemTranslateStateInLines, together with the reasoning. A read site that
       fails any of them is left exactly as it was and counted in piOemStateDeclined, so the run can
       name it as hand work instead of pretending it was handled.

       SUGGEST, not AutoFix: the write half is mechanical, but the block half ends in a decision only
       the code's owner can make. Everything is COMMENTED, never deleted, and carries a marker - so a
       wrong call is undone by deleting comment slashes.
    */
    { Published = True }
    { Description = """
        Removes the obsolete Oem_Translate_State property (warning 4540: it has no effect in a Unicode DataFlex).
        A "Set Oem_Translate_State ..." line is commented out, because nothing reads the property. A "Get ... to <var>" that is used by an If statement is commented out together with the whole If block, with a comment for you to review, because removing only the Get line would change the test so that the block always runs.
        A Get line whose variable is also used elsewhere, whose If has an Else, or whose block cannot be determined is not changed, and is reported. Nothing is deleted; lines are only commented out.
        { MethodType = eOtherFunction }
        { FnGroup = Unicode64 }
        { ModRecipe = 4540 | OEM_Translate_State | Suggest }
        { SummaryText = Retired: obsolete Oem_Translate_State property (commented, with a marker) }
        """ }
    Function RetireOemTranslateState String[] ByRef asCode String sParameter Returns Integer
        Integer iChanged iDeclined

        Get _RetireOemTranslateStateInLines (&asCode) to iChanged
        Get piOemStateDeclined to iDeclined
        // A guard that drops something must NAME what it dropped - a silent skip reads as coverage.
        If (iDeclined > 0 and ghoStatusLog <> 0) ;
            Send AddRunNote "RetireOemTranslateState" ("SKIPPED " + String(iDeclined) + " read site(s) of Oem_Translate_State: the variable is read elsewhere, the If has an Else, or the block could not be delimited. Those need a hand change - the value is meaningless on a Unicode DataFlex, so decide whether the guarded body should go or should run unconditionally.")
        Function_Return iChanged
    End_Function

    /* Win64WindowLongFunctions modernizes the Get/Set Window/Class Long Win32 calls for
       64-bit (the "GetWindowLong/SetWindowLong/GetClassLong/SetClassLong truncate a
       pointer" gotcha in the 64-bit guide): each is renamed to its *Ptr variant, which is
       pointer-safe and works on both 32- and 64-bit. Line-by-line (eStandardFunction) -
       the same masked, boundary-aware, idempotent rename as UnicodeOemAnsiFunctions
       (cRefactorUtilities._RenameMaskedCalls): it skips strings/comments, and the *Ptr
       suffix stops it from re-matching an already-converted call. NOTE: the renamed calls
       need a matching *Ptr External_Function in scope - the DataFlex 21+ Windows packages
       declare them; a hand-rolled GetWindowLong wrapper must Add its own *Ptr declaration.
    */
    { Published = True }
    { Description = """
        64-bit fix for the Win32 "long" functions that cut off pointers: changes GetWindowLong, SetWindowLong, GetClassLong and SetClassLong to their Ptr versions (GetWindowLongPtr and so on), which work with pointers in both 32-bit and 64-bit programs.
        Only whole words are changed, and running it again changes nothing. Strings and comments are skipped.
        { MethodType = eStandardFunction }
        { FnGroup = Unicode64 }
        { SummaryText = Renamed: Get/SetWindowLong + Get/SetClassLong -> *Ptr }
        """ }
    Function Win64WindowLongFunctions String ByRef sLine String sParameter Returns Boolean
        String   sNewLine sOverFull
        String[] asFrom asTo
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        Move "GetWindowLong"    to asFrom[0]
        Move "GetWindowLongPtr" to asTo[0]
        Move "SetWindowLong"    to asFrom[1]
        Move "SetWindowLongPtr" to asTo[1]
        Move "GetClassLong"     to asFrom[2]
        Move "GetClassLongPtr"  to asTo[2]
        Move "SetClassLong"     to asFrom[3]
        Move "SetClassLongPtr"  to asTo[3]

        // sOverstrikeLine is the LEFT-trimmed, masked line (indentation is held separately
        // in sIndentation). Re-attach it so the masked line is position-aligned with the
        // full sLine before the rename.
        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull
        Get _RenameMaskedCalls sLine sOverFull asFrom asTo to sNewLine
        If (sNewLine = sLine) Begin
            Function_Return False
        End
        Move sNewLine to sLine
        Function_Return True
    End_Function

