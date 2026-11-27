// CollisionRefactorFunctions.inc
//
// The NAME-COLLISION family of refactoring functions, #Include'd into the oRefactorFuncLib object
// so they read and compile exactly as if they were written there.
//
// What they have in common: each clears a compile error that DataFlex 25/26 raises when two
// declarations meet under one name - the ambiguous-return error 4544, the duplicate global
// 4390, the class 4345, the surplus-argument 4379 - by renaming, aligning types, guarding a
// redundant global, or dropping the arguments the target no longer takes. Most take their
// target name(s) as the parameter, typically set from the Modernization Analyzer.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    /* AlignCollidingDeclarationType - makes every declaration of one name agree on ONE type. The second
       of the two DF 25/26 error-4544 fixes. The user-facing half of this comment (which of the two fixes
       to pick, the never-run-unasked rule and the missing-parameter skip) moved into the { Description }
       on 2026-08-23.

       The evidence: the pbSilent case (Nils, 2026-07-22) - Boolean in WordTemplateCreator and
       KeyFieldValidation, String in ChilKat, 151 errors, and one word between them and a clean build.

       Rewrites DECLARATION LINES ONLY - "Property <type> <name>" and "Function <name> ... Returns <type>".
       No call site is touched, which is what makes this the small change it looks like. */
    { Published = True }
    { Description = """
        Changes a name that is declared with more than one type so that all its declarations have the same type. This fixes error 4544 in DataFlex 25 and 26 for a name that is declared only in the workspace, where renaming would not help.
        The function's parameter is 'Name=Type', for example 'pbSilent=Boolean'.
        Only declaration lines are changed (Property <type> <name>, Function <name> ... Returns <type>); no calls are changed. Changing a declared type can change what the code does, so read the report first.
        Which 4544 fix to choose: rename the name when DataFlex itself declares it with a different type, because that declaration cannot be changed. Use this function when the declarations that differ are all in the workspace; renaming all of them would only move the same problem to the new name. A typical case: pbSilent is declared as Boolean in two packages and as String in a third, and changing one word makes them the same.
        It never runs unless you choose it. Only you know whether some code assigns a value that the new type cannot hold, so the guided flow shows the file, the line and both types before it runs, and the run summary lists every line it changed.
        When it is selected without a parameter, or with a parameter that is not Name=Type, it changes nothing and says so in the run notes.
        A declaration marked Overloaded is not changed, and the run notes say how many there were. Overloaded versions are meant to return different types, because DataFlex chooses between them by the number of parameters, so they cause no 4544 error.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Aligned a colliding declaration to one type (DF25 error 4544) }
        """ }
    Function AlignCollidingDeclarationType String[] ByRef asFiles String sParameter Returns Integer
        String[] asCode
        String sName sType sParam sFile
        Integer iPos iFile iFileLast iChanged iTotal iOvlSkips
        Boolean bPanel bCancel bIsUtf8 bOK

        Move (Trim(sParameter)) to sParam
        Move (Pos("=", sParam)) to iPos
        If (iPos < 2) Begin
            /* A MISSING PARAMETER IS A CONFIGURATION STATE, NOT A PROGRAM FAULT (Nils
               2026-08-03). This used to `Error DFErr_Program`, which raises a RUNTIME error:
               a modal mid-run in the UI, and in a headless run an entry in Error_Count that
               reads as an engine failure. It fires whenever a parameterised function is
               selected WITHOUT its parameter - which a Select All does by definition, and
               which is how it surfaced in the first /bm run over Order Entry.

               Logged and skipped instead: the user still learns why nothing happened (the
               note lands in the Refactor Engine Error log that the run summary points at),
               the run is not interrupted, and a genuine engine error still means a genuine
               engine error. Real failures - a write that did not land - are still raised.
               Guarded on ghoStatusLog: the DFUnit runner builds no engine, so no log. */
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "AlignCollidingDeclarationType" "SKIPPED - needs a parameter of the form Name=Type, for example pbSilent=Boolean."
            Function_Return 0
        End
        Move (Trim(Left(sParam, (iPos - 1))))               to sName
        Move (Trim(Right(sParam, (Length(sParam) - iPos)))) to sType
        If (sName = "" or sType = "") Begin
            // Configuration state, not a fault - logged and skipped. See the note above.
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "AlignCollidingDeclarationType" "SKIPPED - both a name and a type are required, as in pbSilent=Boolean."
            Function_Return 0
        End

        Move (SizeOfArray(asFiles) - 1) to iFileLast
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        If (bPanel = True) Begin
            // Overall bar = the file list; per-file bar = the LINE walk inside the current file
            // (scaled + reset per file below, stepped by _AlignDeclTypeInLines). It used to be
            // initialised here and never advanced (Nils 2026-07-25, the same dead initialisation
            // as ChangeCollidingMethodName - a still bar reads as a stopped clock).
            Set piMaximumTot of ghoStatusPanel to (iFileLast + 1)
            Set piPosition   of ghoProgressBar to 0
            Set piAdvanceBy  of ghoProgressBar to 1
        End
        Move 0 to iTotal
        Move False to bCancel
        For iFile from 0 to iFileLast
            If (bCancel = False) Begin
                Move asFiles[iFile] to sFile
                If (bPanel = True) Begin
                    Set Caption_Text   of ghoStatusPanel to ("File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text     of ghoStatusPanel to "Aligning declarations:"
                    Set TableName_Text of ghoStatusPanel to sFile
                    Send DoAdvanceTot of ghoStatusPanel
                End
                Move (rfFileHasBOM(sFile)) to bIsUtf8
                Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
                If (bPanel = True) Begin
                    Set piMaximum  of ghoStatusPanel to (SizeOfArray(asCode))
                    Set piPosition of ghoProgressBar to 0
                End
                Get _AlignDeclTypeInLines of Self (&asCode) sName sType to iChanged
                If (iChanged > 0) Begin
                    // Through the write-time macro guard: macro code is never refactored (see _GuardedWriteEncodedFile).
                    Get _GuardedWriteEncodedFile sFile (&asCode) bIsUtf8 to bOK
                    If (bOK = False) ;
                        Error DFErr_Program ("Write failed:" * sFile * "(AlignCollidingDeclarationType)")
                    Move (iTotal + iChanged) to iTotal
                End
                // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal).
                Get pbUserCancelRequested of ghoEngine to bCancel
            End
        Loop
        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        Set piAlignedDecls to iTotal
        // Name what was left alone: a count of aligned declarations on its own reads as "that is
        // all of them" when some were deliberately skipped.
        Get piOverloadSkips to iOvlSkips
        If (iOvlSkips > 0) ;
            Send AddRunNote "AlignCollidingDeclarationType" ("Left " + String(iOvlSkips) + " Overloaded declaration(s) of " + sName + " unchanged. DataFlex resolves an overloaded name by parameter count, so its variants are MEANT to return different types - retyping them would change what they return, and the name cannot raise error 4544 anyway.")
        Function_Return iTotal
    End_Function

    /* ChangeAmbiguousCallToGet - clears error 4544 ("Function GET_<name> with ambiguous return type used in
       expression") by HOISTING the expression-style call into a Get statement, without touching a single
       declaration. What 4544 is, the before/after, the side-effect caution and what is left untouched are
       now in the { Description } below.

       Both halves are verified against DF25 on a minimal two-class fixture: the expression form errors 4544,
       the hoisted Get compiles clean. Local declarations mid-method and inside a Begin/End block are both
       legal (also verified), so the temp is declared right at the hoist site - no declaration-block tracking.

       This is the CALL-SITE route. The other route is to change the few conflicting DECLARATIONS (rename or
       type-align), which is a far smaller diff but a design decision only the code's owners can make - and
       impossible in code you merely have read access to. Neither is "the" answer, so this is Suggest and
       the report names the declarations for whoever can decide. The caution also rides in the emitted marker.

       Conservative by construction: comment lines, continuation lines (the one above ends with ";"),
       unbalanced parentheses and object-less calls are all left untouched rather than half-converted, and
       nested calls hoist innermost-first. The pure core is cRefactorFuncLib._HoistAmbiguousCallsInLines.
    */
    { Published = True }
    { Description = """
        Fixes error 4544 by changing calls in expressions of a method with an ambiguous return type into Get statements, without changing any declarations. Enter the method name or names as the function's parameter.
        Error 4544 is reported when one message name is declared with different return types in the workspace, for example a container class and a DEO that both declare Function Value. The compiler cannot determine the type of a call in an expression, and reports every one of them. A few declarations can cause hundreds of errors, in files that have nothing to do with those classes.
        Example: If (Value(oFoo,"k") = 1) becomes three lines, with a Variant variable declared where the call was:
        Variant vDfrGet1
        Get Value of (oFoo) ("k") to vDfrGet1
        If (vDfrGet1 = 1)
        Caution: the call is now made before the rest of the expression is evaluated, so for a call with side effects, this changes what the code does. The other way to fix the error is to rename the few conflicting declarations, or give them the same type. That is a much smaller change, but a design decision that only the code's owners can make, which is why this function is a suggestion.
        Comment lines, lines that continue a statement, calls without an object, and lines with unbalanced parentheses are not changed. Nested calls are changed from the innermost one outwards.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ParamHelp = Method name(s) to convert, separated by ; or , - e.g. Value;pbSilent. Read them off the compiler's 4544 messages (GET_VALUE means Value). Object methods only. Blank does nothing. }
        { SummaryText = Converted ambiguous function calls to Get statements }
        """ }
    Function ChangeAmbiguousCallToGet String[] ByRef asCode String sParameter Returns Integer
        String[] asNames
        String sParam sOne sThisFile
        Integer iCount iN iP

        Move (Trim(sParameter)) to sParam
        // No names = nothing to do. Deliberately NOT auto-derived yet: deriving the ambiguous set needs a
        // workspace-wide declaration harvest, and caching that across a per-file run is exactly the kind of
        // lingering state that caused trouble before. The compiler's 4544 messages name them outright.
        If (sParam = "") Begin
            // Configuration state, not a fault - logged and skipped, same policy as the collision
            // converters (Nils 2026-08-03). Was a SILENT return: the guided Check always passes the
            // names it read off the 4544s, so a manual tick was the one path that got nothing back
            // and no reason why.
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "ChangeAmbiguousCallToGet" "SKIPPED - needs the ambiguous function name(s) as a parameter, separated by ; or , - for example Value;Split. A guided Check fills these in from the compiler's 4544 messages."
            Function_Return 0
        End
        Move (Replaces(",", sParam, ";")) to sParam
        Move 0 to iN
        While (sParam <> "")
            Move (Pos(";", sParam)) to iP
            If (iP = 0) Begin
                Move (Trim(sParam)) to sOne
                Move "" to sParam
            End
            Else Begin
                Move (Trim(Left(sParam, (iP - 1)))) to sOne
                Move (Trim(Mid(sParam, (Length(sParam) - iP), (iP + 1)))) to sParam
            End
            If (sOne <> "") Begin
                Move sOne to asNames[iN]
                Increment iN
            End
        Loop
        If (iN = 0) ;
            Function_Return 0
        // The core records WHERE it declines; give it the file to record against. Read from the
        // engine because a whole-file function is handed only the lines, not the path.
        Get psCurrentSourceFileName of ghoEngine to sThisFile
        Set psHoistCurrentFile to sThisFile
        Get _HoistAmbiguousCallsInLines (&asCode) asNames to iCount
        Function_Return iCount
    End_Function

    /* ChangeCollidingMethodName - the DF 25/26 error 4544 fix applied AT THE DECLARATION rather than at
       the call sites. The user-facing half of this comment moved into the { Description } on 2026-08-23,
       where the generated help can reach it; what is left is the rationale.

       Built because the alternative was to tell the user to do it by hand (Nils, 2026-07-22: "Aren't we
       building a tool to help the user to fix anomalies in their code prior moving to a later DF
       version?"). A mechanical, scoped rename is exactly what a refactoring tool is for.

       Scope is worked out in three passes over the selected files, because none of it can be known from
       one file alone:
         1. which CLASSES declare the name, and the whole class family beneath them - a subclass that
            overrides it (cSummaryTable over cHashTable) must be renamed too, or the workspace is left
            half-renamed and still ambiguous;
         2. which identifiers hold an object of that family - Object declarations are workspace-wide
            (Register_Object) so they carry across files, while a local handle from Get Create stays
            local to its own file, since an "hTbl" here has nothing to do with an "hTbl" there;
         3. the rewrite itself, renaming only what step 2 proved.

       Anything whose receiver cannot be typed from the source is LEFT ALONE and listed on the Manual
       Changes tab. Guessing would break somebody's build - and this runs over library code. */
    { Published = True }
    { Description = """
        Renames a method that is declared with more than one return type. This fixes error 4544 in DataFlex 25 and 26 at the declaration, which changing the calls alone cannot fully do.
        The function's parameter is 'OldName=NewName', for example 'Value=ValueByKey'.
        The declaration is renamed in the class and all its subclasses, and so is every call where the object can be shown to belong to one of them. Calls where this cannot be shown are listed on the Manual Changes tab instead of being guessed.
        Renaming the declaration fixes every call of the name, including calls that continue on the next line, calls inside a macro (reported where the macro is used), and calls in DataFlex's own packages, which are never changed. In one test workspace, 3 declarations were behind about 400 calls.
        A subclass that overrides the method is renamed too; otherwise the workspace would be only partly renamed and still ambiguous. Object declarations are recognised in the whole workspace (Register_Object), while a local handle from Get Create is only followed within its own file.
        A declaration outside the workspace's home folder is renamed and also reported, because a shared library can be used by other workspaces as well, which still compile with the old name.
        Nothing is guessed: this also runs on library code, so a call whose object type cannot be determined from the source code is reported, never changed.
        A name declared as Overloaded is not changed: DataFlex chooses the version by the number of parameters, so several return types are valid and no 4544 error occurs.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Renamed a colliding method declaration and its provable call sites }
        """ }
    Function ChangeCollidingMethodName String[] ByRef asFiles String sParameter Returns Integer
        String[] asCode asClassPairs asFilePairs asSeeds asFileSeeds asFamily asObjRecv asFileObj
        String[] asRecv asLocalRecv asShared asEmptyStr asHandRows asSiteRows
        String sOld sNew sParam sFile sHome sLc sWhatDecl sWhatUse sWhyHand
        Integer i iLast iFile iFileLast iPos iChanged iTotal iDecls iCalls
        Boolean bPanel bCancel bIsUtf8 bOK bInPlay bOvlFound

        Move (Trim(sParameter)) to sParam
        Move (Pos("=", sParam)) to iPos
        // NO GUESSING what to rename to. A blank or malformed parameter is a question for the user, not
        // an invitation to invent an identifier and rewrite a library with it.
        If (iPos < 2) Begin
            // Configuration state, not a fault - logged and skipped. See the note above.
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "ChangeCollidingMethodName" "SKIPPED - needs a parameter of the form OldName=NewName, for example Value=ValueByKey."
            Function_Return 0
        End
        Move (Trim(Left(sParam, (iPos - 1))))                    to sOld
        Move (Trim(Right(sParam, (Length(sParam) - iPos))))      to sNew
        If (sOld = "" or sNew = "" or Lowercase(sOld) = Lowercase(sNew)) Begin
            // Configuration state, not a fault - logged and skipped. See the note above.
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "ChangeCollidingMethodName" "SKIPPED - the old and new names must both be given, and must differ."
            Function_Return 0
        End

        Get psHomeTarget of ghoApplication to sHome
        Move (Lowercase(vFolderFormat(sHome))) to sHome
        Move (SizeOfArray(asFiles) - 1) to iFileLast
        Move (ghoStatusPanel <> 0 and Active_State(ghoStatusPanel) = True) to bPanel
        If (bPanel = True) Begin
            // OVERALL bar = the whole job (3 passes x the file list). The PER-FILE bar shows the
            // LINE walk inside the current file: its maximum is set per file below and the
            // line-walking helpers step it (_NudgeLineProgress, every ~20 lines). It used to be
            // initialised here and then never advanced at all, so it sat empty for the whole run -
            // and a still bar reads as a stopped CLOCK, since the Elapsed Time only repaints when
            // a panel setter fires and this function's finest update was one FILE (Nils 2026-07-25).
            Set piMaximumTot of ghoStatusPanel to (3 * (iFileLast + 1))
            Set piPosition   of ghoProgressBar to 0
            Set piAdvanceBy  of ghoProgressBar to 1
        End
        Move False to bCancel

        // ---- Pass 1: the class family that declares the name ----
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFile
            If (bPanel = True) Begin
                Set Caption_Text   of ghoStatusPanel to ("Classes - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text     of ghoStatusPanel to "Finding the classes that declare it:"
                Set TableName_Text of ghoStatusPanel to sFile
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
            // Scale the per-file bar to THIS file's lines; the helpers below step it as they walk.
            If (bPanel = True) Begin
                Set piMaximum  of ghoStatusPanel to (SizeOfArray(asCode))
                Set piPosition of ghoProgressBar to 0
            End
            Get _ClassPairsFromLines of Self asCode to asFilePairs
            For i from 0 to (SizeOfArray(asFilePairs) - 1)
                Move asFilePairs[i] to asClassPairs[SizeOfArray(asClassPairs)]
            Loop
            // An OVERLOADED declaration of the name stops the whole run, before anything is written.
            // A rename has to be all-or-nothing here: rename some declarations of an overload set and
            // not the rest and you leave an overloaded and a non-overloaded method sharing a name -
            // DataFlex error 4390. And there is nothing to fix anyway: an overloaded name resolves by
            // parameter count, so it cannot raise the 4544 this function exists to clear.
            If (bOvlFound = False) ;
                Get _NameIsOverloadedInLines of Self asCode sOld to bOvlFound
            Get _ClassesDeclaringName of Self asCode sOld to asFileSeeds
            For i from 0 to (SizeOfArray(asFileSeeds) - 1)
                If (SearchArray(asFileSeeds[i], asSeeds, Desktop, RefFunc(DFSTRICMP)) = -1) Begin
                    Move asFileSeeds[i] to asSeeds[SizeOfArray(asSeeds)]
                    // A declaration outside the workspace home lives in a shared library tree - renamed,
                    // but the user has to know that other applications compile against the old name.
                    Move (Lowercase(sFile)) to sLc
                    If (sHome <> "" and Pos(sHome, sLc) <> 1) Begin
                        If (SearchArray(sFile, asShared, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                            Move sFile to asShared[SizeOfArray(asShared)]
                    End
                End
            Loop
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop
        If (bOvlFound = True) Begin
            Send AddRunNote "ChangeCollidingMethodName" ("SKIPPED - " + sOld + " is declared Overloaded. DataFlex resolves an overloaded name by parameter count, so it holds several return types legally and cannot raise error 4544 - there is nothing here to rename. Renaming part of an overload set would raise error 4390 instead. Nothing was changed.")
            Function_Return 0
        End
        If (SizeOfArray(asSeeds) = 0 or bCancel = True) Begin
            // Distinguish "no class declares this" from "nothing to do" - see pbRenameNoClassSeeds.
            Set pbRenameNoClassSeeds to (SizeOfArray(asSeeds) = 0)
            Set pasRenameSharedFiles to asShared
            // CANNOT rename it - so hand back the whole job instead of a shrug. The declarations AND every
            // use of the name, because a rename is both and the uses are the half nobody can find by eye.
            If (SizeOfArray(asSeeds) = 0 and bCancel = False) Begin
                Move ("Rename this " + sOld + " declaration - the name belongs to DataFlex") to sWhatDecl
                Move ("Rename this use of " + sOld + " to match its renamed declaration")     to sWhatUse
                Move ("DataFlex owns the name " + sOld + ", so the workspace's declaration has to change - and every call that means THAT declaration has to change with it. Which declaration a call means cannot be told from the source, so none of this was guessed at.") to sWhyHand
                Get pasRenameUnproven to asHandRows
                For iFile from 0 to iFileLast
                    Move asFiles[iFile] to sFile
                    If (bPanel = True) Begin
                        Set Caption_Text   of ghoStatusPanel to ("Listing sites - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                        Set Title_Text     of ghoStatusPanel to "Finding every place it is used:"
                        Set TableName_Text of ghoStatusPanel to sFile
                        Send DoAdvanceTot of ghoStatusPanel
                    End
                    Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
                    If (bPanel = True) Begin
                        Set piMaximum  of ghoStatusPanel to (SizeOfArray(asCode))
                        Set piPosition of ghoProgressBar to 0
                    End
                    Get _NameSitesInLines of Self asCode sOld sFile sWhatDecl sWhatUse sWhyHand to asSiteRows
                    For i from 0 to (SizeOfArray(asSiteRows) - 1)
                        Move asSiteRows[i] to asHandRows[SizeOfArray(asHandRows)]
                    Loop
                    Get pbUserCancelRequested of ghoEngine to bCancel
                    If (bCancel = True) ;
                        Move iFileLast to iFile
                Loop
                Set pasRenameUnproven to asHandRows
                If (bPanel = True) ;
                    Set Title_Text of ghoStatusPanel to ""
            End
            Function_Return 0
        End
        Get _ExpandClassFamily of Self asClassPairs asSeeds to asFamily

        // ---- Pass 2: the OBJECT names of that family (workspace-wide, so gathered across all files) ----
        For iFile from 0 to iFileLast
            Move asFiles[iFile] to sFile
            If (bPanel = True) Begin
                Set Caption_Text   of ghoStatusPanel to ("Receivers - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                Set Title_Text     of ghoStatusPanel to "Finding the objects it is called on:"
                Set TableName_Text of ghoStatusPanel to sFile
                Send DoAdvanceTot of ghoStatusPanel
            End
            Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
            If (bPanel = True) Begin
                Set piMaximum  of ghoStatusPanel to (SizeOfArray(asCode))
                Set piPosition of ghoProgressBar to 0
            End
            Get _ReceiverNamesFromLines of Self asCode asFamily True to asFileObj
            For i from 0 to (SizeOfArray(asFileObj) - 1)
                If (SearchArray(asFileObj[i], asObjRecv, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move asFileObj[i] to asObjRecv[SizeOfArray(asObjRecv)]
            Loop
            Get pbUserCancelRequested of ghoEngine to bCancel
            If (bCancel = True) ;
                Move iFileLast to iFile
        Loop

        // ---- Pass 3: rewrite ----
        Move 0 to iTotal
        Move 0 to iDecls
        Move 0 to iCalls
        For iFile from 0 to iFileLast
            If (bCancel = False) Begin
                Move asFiles[iFile] to sFile
                If (bPanel = True) Begin
                    Set Caption_Text   of ghoStatusPanel to ("Renaming - File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text     of ghoStatusPanel to "Renaming:"
                    Set TableName_Text of ghoStatusPanel to sFile
                    Send DoAdvanceTot of ghoStatusPanel
                End
                Move (rfFileHasBOM(sFile)) to bIsUtf8
                Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
                If (bPanel = True) Begin
                    Set piMaximum  of ghoStatusPanel to (SizeOfArray(asCode))
                    Set piPosition of ghoProgressBar to 0
                End
                // Local handles come from THIS file only; object names are workspace-wide.
                Get _ReceiverNamesFromLines of Self asCode asFamily False to asLocalRecv
                Move asObjRecv to asRecv
                For i from 0 to (SizeOfArray(asLocalRecv) - 1)
                    If (SearchArray(asLocalRecv[i], asRecv, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                        Move asLocalRecv[i] to asRecv[SizeOfArray(asRecv)]
                Loop
                // Is the family in play in this file at all? If not, a same-named call belongs to somebody
                // else and must not be reported as unfinished work.
                Get _ClassesDeclaringName of Self asCode sOld to asFileSeeds
                Move ((SizeOfArray(asLocalRecv) > 0) or (SizeOfArray(asFileSeeds) > 0)) to bInPlay
                Get _RenameMethodInLines of Self (&asCode) sOld sNew asRecv asFamily sFile bInPlay to iChanged
                If (iChanged > 0) Begin
                    // Through the write-time macro guard: macro code is never refactored (see _GuardedWriteEncodedFile).
                    Get _GuardedWriteEncodedFile sFile (&asCode) bIsUtf8 to bOK
                    If (bOK = False) ;
                        Error DFErr_Program ("Write failed:" * sFile * "(ChangeCollidingMethodName)")
                    Move (iTotal + iChanged) to iTotal
                End
                Get pbUserCancelRequested of ghoEngine to bCancel
            End
        Loop
        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        Set piRenamedDecls       to (SizeOfArray(asFamily))
        Set piRenamedCalls       to iTotal
        Set pasRenameSharedFiles to asShared
        Move asEmptyStr to asFileObj
        Function_Return iTotal
    End_Function

    /* DropSurplusCallArguments - the ARITHMETIC half of E 4379 (Nils 2026-09-04, a view).
       ChangeObjectFunctionCallToGet above is the cure for the other half, a name collision. On his
       line - "Entry_Item (fheadvalue(Self, plandetail.ref, plandetail.porder))" against a fHeadValue
       declaring ONE parameter - a Get rewrite would have compiled clean and dropped the second
       argument without a word (probe-compiled: a message send does not count arguments). The board
       therefore withholds the Get there and offers THIS instead, because it is the one change that is
       provably nothing at run time: 19.1 passed the surplus and the method never saw it.
       Never a {ModRecipe}: the compiler's 4379 cannot tell this shape from the collision, and a
       recipe cannot see the line (feedback_compiler_recipe_cannot_see_the_line_shape). The guided
       board offers it only after DeclaredParamCountIn measured the declaration and
       _DropSurplusArgsInLine confirmed it would change the row's own line. The core is that pure
       helper in cRefactorFuncLib; this is the file walk, the progress nudge and the tally.
    */
    { Published = True }
    { Description = """
        Removes the extra arguments at the end of an object method call, in the expression form Name(Self, args), when the call passes more arguments than the method declares.
        DataFlex 19.1 and earlier accepted the extra arguments without checking, and the method never read them, so removing them changes nothing when the program runs. DataFlex 26 counts them and reports error 4379. Only the argument list is changed; the declaration is not.
        Example: with fHeadValue declaring one parameter, 'Entry_Item (fheadvalue(Self, plandetail.ref, plandetail.porder))' becomes 'Entry_Item (fheadvalue(Self, plandetail.ref))'.
        Not changed: a call whose extra argument contains another call (which could have side effects), a call that continues over several lines, and a call whose first argument is not Self. If the method was meant to receive the extra value, add the parameter by hand and do not run this function.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ParamHelp = Name|Count - the object method's name and the parameter count it declares, for example fHeadValue|1. A guided Check fills it in from the file's own declaration. Blank = nothing is changed. }
        { SummaryText = Dropped surplus call arguments (E 4379) }
        """ }
    Function DropSurplusCallArguments String[] ByRef asCode String sParameter Returns Integer
        String sParam sName sKeep sLine sNew
        Integer iBar iKeep iCount iSize iChanged iDropped iPos
        Boolean bHasAny bDigits

        Move (Trim(sParameter)) to sParam
        Move (Pos("|", sParam)) to iBar
        If (iBar = 0) Begin
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "DropSurplusCallArguments" "SKIPPED - needs a parameter of the form Name|Count: the object method's name and the parameter count it declares, for example fHeadValue|1. A guided Check fills it in from the file's own declaration."
            Function_Return 0
        End
        Move (Trim(Left(sParam, (iBar - 1))))               to sName
        Move (Trim(Right(sParam, (Length(sParam) - iBar)))) to sKeep
        // Digits only, checked BEFORE the Move: moving "x" into an Integer is DataFlex error 54.
        Move (sKeep <> "") to bDigits
        For iPos from 1 to (Length(sKeep))
            If (Pos(Mid(sKeep, 1, iPos), "0123456789") = 0) ;
                Move False to bDigits
        Loop
        Move -1 to iKeep
        If (bDigits) ;
            Move sKeep to iKeep
        // A count that did not read back as itself ("x", "") would drop EVERY argument - refuse it.
        If (sName = "" or sKeep = "" or bDigits = False or String(iKeep) <> sKeep or iKeep < 0) Begin
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "DropSurplusCallArguments" ("SKIPPED - the parameter must be Name|Count with a whole-number count, as in fHeadValue|1; got '" + sParam + "'.")
            Function_Return 0
        End
        // Fast gate: the name is never called in this file -> nothing to read.
        Get _FileContainsText of Self (&asCode) (Lowercase(sName) + "(") to bHasAny
        If (bHasAny = False) ;
            Function_Return 0
        Move 0 to iChanged
        Move (SizeOfArray(asCode)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            If (Mod(iCount, 20) = 0 and (Active_State(ghoStatusPanel) = True)) Begin
                Send Update_StatusPanel of ghoStatusPanel ("Source line:" * String(iCount + 1) * "of:" * String(iSize + 1))
                Set piPosition of ghoProgressBar to (iCount + 1)
            End
            Move asCode[iCount] to sLine
            Get _DropSurplusArgsInLine of Self sLine sName iKeep (&iDropped) to sNew
            If (iDropped > 0) Begin
                Move sNew to asCode[iCount]
                Increment iChanged
            End
        Loop
        // Per-RUN tally on top of the per-file return value (the engine calls this once per file).
        Set piSurplusArgsDropped to (piSurplusArgsDropped(Self) + iChanged)
        Function_Return iChanged
    End_Function

    /* GuardRedundantGlobalFunctions - wraps a file's OWN global Function/Procedure declarations that the
       TARGET DataFlex now ships NATIVELY in a compiler-version guard, so the home-brewed copy compiles only
       on the releases that lack the built-in. That clears duplicate-global error 4390 at the few
       DECLARATIONS instead of the (often hundreds of) callers. The emitted shape, the inclusive "<=" rule,
       the GLOBAL-keyword limit and the behaviour caution now live in the { Description } below.

       VERSION = sParameter when set, else the TARGET workspace's own DataFlex version (pTargetWS.sDfVersion,
       read from its .sws - JSON "df" or legacy [Properties] Version). Guessing is REFUSED: a blank or
       unparsable version changes nothing rather than writing a wrong number into someone's source.

       WHICH NAMES: the per-version catalogue of the target install's own Global function names
       (InstallGlobalFuncNames), so it follows the release the user actually targets instead of a hardcoded
       list. The GLOBAL keyword FOLLOWS the name (Function Utf8ToOem Global String s Returns String), which
       is why the match is positional - a same-named method inside a class never clashes with a global
       built-in, and a non-Global top-level function is not a backport at all. A global Set procedure goes by
       its two-word name, "Set Profile_Dword" (_GlobalDeclaredName).

       The emitted "#" and "!" are Character()-built (35 / 33). FMAC processes its directive/counter tokens
       BEFORE string-literal semantics exist, so a literal "#IF (!@ ..." held here would be evaluated during
       DFRefactor's OWN compile - writing our version into the output - exactly the |!C / #COMMAND lesson.

       (Was UnicodeRetireRedundantConversions, which COMMENTED OUT 10 hardcoded CharTranslate names.
       Commenting out makes the source compile only on the NEW release; a version guard keeps ONE tree
       building on both - what library code mid-migration actually needs. Nils 2026-07-20.)
    */
    { Published = True }
    { Description = """
        Puts the global functions in this file that the target DataFlex now provides itself inside an #IF (!@ <= version) check, so that they are only compiled in older versions. This fixes the duplicate-global error 4390 without changing any calls.
        The function is placed, unchanged and at its own indentation, between the version check and its #ENDIF. Nothing is deleted or rewritten; the change can be undone, and a function that already has the check is skipped when it runs again.
        The "<=" includes the workspace's own version on purpose: that version must still compile its own copy, because the DataFlex function does not exist there (a "< 191" check would break a 19.1 application). If the version cannot be read, nothing is changed, rather than writing a wrong number into the source code.
        Only top-level declarations with the GLOBAL keyword are changed, and only names that the target DataFlex itself includes. A method with the same name inside a class is not changed.
        Caution: in the newer version, every call then uses DataFlex's own function, which can differ in code page, error handling or special cases. This is why the function is a suggestion to review, not an automatic fix.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4390 | OemToUtf8 | Suggest }
        { ModRecipe = 4390 | Utf8ToOem | Suggest }
        { ModRecipe = 4390 | AnsiToUtf8 | Suggest }
        { ModRecipe = 4390 | Utf8ToAnsi | Suggest }
        { ParamHelp = DataFlex version this code is kept for, e.g. 19.1 (191 or 26 also accepted). Leave blank to use the selected workspace's own version. }
        { SummaryText = Version-guarded global functions that DataFlex now provides natively }
        """ }
    Function GuardRedundantGlobalFunctions String[] ByRef asCode String sParameter Returns Integer
        String[] asNative
        String sVerText
        Integer iVer iGuarded
        tWorkspacePaths WS

        // Version boundary: the parameter wins, else the selected TARGET workspace's own DataFlex version
        // (from its .sws - JSON "df" or legacy [Properties] Version). Blank/unparsable = REFUSE, never
        // guess: writing a wrong version into someone's source is worse than changing nothing.
        Move (Trim(sParameter)) to sVerText
        If (sVerText = "") Begin
            Get pTargetWS of ghoApplication to WS
            Move WS.sDfVersion to sVerText
        End
        Get DfVersionToMacroNumber sVerText to iVer
        If (iVer = 0) Begin
            // The refusal is right - a wrong version written into someone else's source is worse
            // than no change - but it has to SAY so, or the caller invents a cause. sVerText is
            // whatever the target workspace .sws offered, so quoting it points straight at it.
            Set psGuardSkipReason to ("the target workspace does not state a DataFlex version this tool can read - got " + (If(sVerText = "", "nothing at all", (Character(34) + sVerText + Character(34)))) + ". The guard directive needs a version number to write.")
            Function_Return 0
        End
        // The Global function names the TARGET install itself ships (per-version catalogue), so this
        // follows the release the user actually targets instead of a hardcoded list. RunNativeGlobalFuncNames
        // (not InstallGlobalFuncNames) because this runs PER FILE: the underlying call re-probes and
        // re-parses the cache JSON every time, which on a big workspace stalled the run between files.
        Get RunNativeGlobalFuncNames of Self to asNative
        Get _GuardGlobalsInLines (&asCode) asNative iVer sVerText to iGuarded
        Function_Return iGuarded
    End_Function

    /* RenameCollidingGlobalFunction - the RENAME half of the 4390 story, for names a guard cannot
       help: the newer DataFlex owns the name from its RUNTIME or a CLASS METHOD (Split is
       regex-flavoured in the runtime; SQLExecute is sql.pkg's statement procedure), so the
       workspace's own global must stop using the name. The declaration rename is one line; the CALL
       SITES are the pain - Nils hand-renamed SPLIT across 164 instances (2026-07-23) before this
       converter existed.

       WHAT RENAMES: the Global declaration (Function <Old> ... Global / Register_Function <Old>),
       expression calls (<Old> followed by "(", spaces allowed), and OF-LESS Get statements
       (Get <Old> args to var). WHAT NEVER RENAMES: Get/Send <Old> OF hObject - the of-form is
       OBJECT-targeted, which is a class method and usually exactly the native API the name clashes
       with (Send SQLExecute of hStmt must survive the rename untouched). That discriminator is what
       makes the rename safe to automate. Masked matching (literals/comments never touched);
       whole-word boundaries make it idempotent (SplitX never re-matches Split).

       Run it over the WHOLE selected scope - call sites live everywhere, not just the declaring
       file. A half-migrated workspace UNIFIES: sites already on the new name are simply not
       matched. Suggest-tier by design: renames on customer code are opt-in, never auto-fix. */
    { Published = True }
    { Description = """
        Renames a global function that has the same name as a function in the newer DataFlex (error 4390, where a version check cannot help).
        The declaration, calls in expressions, and Get statements without 'of' are renamed. Get and Send ... OF <object> are never changed, because those call the class method that has the same name.
        Set the parameter to OldName|NewName, or only OldName to add an X to the name. Run it on all selected files, because the calls can be in any file.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ParamHelp = OldName|NewName, or OldName alone to rename to OldNameX (SPLIT -> SPLITX). The name of the global function to rename away from a DataFlex-owned name. }
        { SummaryText = Renamed a colliding global function and its call sites }
        """ }
    Function RenameCollidingGlobalFunction String[] ByRef asCode String sParameter Returns Integer
        String sOld sNew
        Integer iPos iRen
        Boolean bGate

        Move (Trim(sParameter)) to sOld
        If (sOld = "") Begin
            // Configuration state, not a fault - logged and skipped, per the policy set on
            // AlignCollidingDeclarationType (Nils 2026-08-03). This one returned 0 in SILENCE, so a
            // Select All that swept it in produced no change and no reason anywhere.
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "RenameCollidingGlobalFunction" "SKIPPED - needs a parameter of the form OldName|NewName, or OldName alone to rename to OldNameX, for example SPLIT|SPLITX."
            Function_Return 0
        End
        Move (Pos("|", sOld)) to iPos
        If (iPos > 1) Begin
            Move (Trim(Right(sOld, (Length(sOld) - iPos)))) to sNew
            Move (Trim(Left(sOld, (iPos - 1))))             to sOld
        End
        Else ;
            Move (sOld + "X") to sNew
        If (sOld = "" or sNew = "") ;
            Function_Return 0
        // Cheap raw-text gate: no occurrence of the old name = nothing this file can contribute.
        Get _FileContainsText (&asCode) (Lowercase(sOld)) to bGate
        If (bGate = False) ;
            Function_Return 0
        Get _RenameGlobalNameInLines (&asCode) sOld sNew to iRen
        Set piRenamedGlobalCount to (piRenamedGlobalCount(Self) + iRen)
        Function_Return iRen
    End_Function

    /* RenameSameNamedMethod - the THIRD 4544 fix (Nils 2026-09-04, a workspace's same-named function). Two unrelated
       methods share a name: Unit.sl's fCount returns a description ("Fixed amount"), RETBACK's and
       PRETBACK's return a count. The align offer retyped the text one to Integer - which compiles,
       and returns 0. Neither existing route fits that case: ChangeCollidingMethodName walks CLASS
       families and these are object-level declarations; RenameCollidingGlobalFunction refuses a
       keyword-less Function on purpose. This is that renamer with the method declaration allowed
       (pbRenameMethodDecl, a one-shot), meant to run over the ODD declaration's own file - the
       guided board scopes it so - so the other declarations keep their name. The declaration,
       expression calls and of-less Gets rename; of-forms never do. Never a {ModRecipe}: which
       declaration is the odd one is a harvest-time fact (FunctionReturnsTextIn), not a line shape. */
    { Published = True }
    { Description = """
        Renames a method that has the same name as an unrelated method with a different return type (error 4544), so that it gets a name of its own. Use this when giving them the same type would change what one of them returns (a function that returns text, changed to Integer, returns 0).
        The function's parameter is OldName|NewName, or only OldName to add Text to the name.
        The Function declaration (global or not), calls in expressions, and Get statements without 'of' are renamed in each file it runs on. Get and Send ... OF <object> are never changed.
        Run it only on the file with the declaration that differs, as the guided Check does, so that the other declarations keep their names.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ParamHelp = OldName|NewName, or OldName alone to rename to OldNameText (fCount -> fCountText). Run it over the file that declares the odd one out. }
        { SummaryText = Renamed a same-named method and its calls in its own file }
        """ }
    Function RenameSameNamedMethod String[] ByRef asCode String sParameter Returns Integer
        String sOld sNew
        Integer iPos iRen
        Boolean bGate

        Move (Trim(sParameter)) to sOld
        If (sOld = "") Begin
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "RenameSameNamedMethod" "SKIPPED - needs a parameter of the form OldName|NewName, or OldName alone to rename to OldNameText, for example fCount|fCountText."
            Function_Return 0
        End
        Move (Pos("|", sOld)) to iPos
        If (iPos > 1) Begin
            Move (Trim(Right(sOld, (Length(sOld) - iPos)))) to sNew
            Move (Trim(Left(sOld, (iPos - 1))))             to sOld
        End
        Else ;
            Move (sOld + "Text") to sNew
        If (sOld = "" or sNew = "") ;
            Function_Return 0
        Get _FileContainsText (&asCode) (Lowercase(sOld)) to bGate
        If (bGate = False) ;
            Function_Return 0
        Set pbRenameMethodDecl to True
        Get _RenameGlobalNameInLines (&asCode) sOld sNew to iRen
        Set pbRenameMethodDecl to False
        Set piRenamedMethodCount to (piRenamedMethodCount(Self) + iRen)
        Function_Return iRen
    End_Function

    /* RenameCollidingClass - the CLASS flavour of the duplicate-name error 4345 ("Type check error
       |CI<n>, SHOULD NOT BE DEFINED" on a "Class <Name> is a ..." line): the newer DataFlex has a
       class of that name - cRegEx moved into the DF 25/26 runtime, so no Pkg file declares it and
       no catalogue can see it; the compiler is the oracle. The workspace's own class must stop
       using the name, and its references live everywhere: Object declarations ("is a"), subclasses,
       RefClass() creates and "for <Class>" augmentations. Renames exactly those four shapes and
       nothing else that spells the word (see _RenameClassNameInLines). Masked, whole-word,
       idempotent. Suggest-tier by design: renames on customer code are opt-in. (Nils 2026-09-03:
       "it is vital that a class name clash gets a recipe and one with high priority".) */
    { Published = True }
    { Description = """
        Renames a class that has the same name as a class that the newer DataFlex defines itself (error 4345, "should not be defined", on its Class line).
        The Class declaration is renamed, and so is every "is a <Class>" (objects and subclasses), RefClass(<Class>) and "for <Class>" in the file. Nothing else that contains the word is changed.
        Run it on all selected files, because references can be in any file. Set the parameter to OldName|NewName, or only OldName to add an X to the name.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ParamHelp = OldName|NewName, or OldName alone to rename to OldNameX (cRegEx -> cRegExX). The class to rename away from a DataFlex-owned name. }
        { SummaryText = Renamed a colliding class and its references }
        """ }
    Function RenameCollidingClass String[] ByRef asCode String sParameter Returns Integer
        String sOld sNew
        Integer iPos iRen
        Boolean bGate

        Move (Trim(sParameter)) to sOld
        If (sOld = "") Begin
            Send AddRunNote "RenameCollidingClass" "SKIPPED - needs a parameter of the form OldName|NewName, or OldName alone to rename to OldNameX."
            Function_Return 0
        End
        Move (Pos("|", sOld)) to iPos
        If (iPos > 0) Begin
            Move (Trim(Right(sOld, (Length(sOld) - iPos)))) to sNew
            Move (Trim(Left(sOld, (iPos - 1))))             to sOld
        End
        Else ;
            Move (sOld + "X") to sNew
        If (sOld = "" or sNew = "") ;
            Function_Return 0
        Get _FileContainsText (&asCode) (Lowercase(sOld)) to bGate
        If (bGate = False) ;
            Function_Return 0
        Get _RenameClassNameInLines (&asCode) sOld sNew to iRen
        Set piRenamedClassCount to (piRenamedClassCount(Self) + iRen)
        Function_Return iRen
    End_Function
