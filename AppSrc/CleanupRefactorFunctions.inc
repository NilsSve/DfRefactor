// CleanupRefactorFunctions.inc
//
// The CLEANUP family of refactoring functions - { FnGroup = Cleanup } - #Include'd into the
// oRefactorFuncLib object so they read and compile exactly as if they were written there.
//
// Cleanup REMOVES; Modernization ADDS. Everything here takes something out of the source that
// nothing needs any more - dead Use statements and source files, Studio markers and generated
// comments, trailing spaces, blank-line runs, unused locals, a typeface line, an old project
// object structure - or reshapes what is left without changing what it does.
//
// FnGroup, NOT the name. Three Remove* functions are deliberately NOT here -
// RemoveLocalKeyWord, RemovePropertyPrivate and RemovePropertyPublic are tagged Modernization,
// because a keyword the language no longer needs is modernised syntax rather than tidying.
// Grouping by the prefix would have taken those and left UnusedUseStatements behind.
//
// EditorNormalizeCase and EditorReIndent are the odd pair: same intent, different kind. They
// need a realised GUI editor and self-skip in a console test run (see project_UnitTests
// _ci), so a green headless suite says nothing about them.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    { Published = True }
    { Description = """
        Changes the case of all scopes and keywords to the case defined in the language settings.
        Example: procedure OnClick -> Procedure OnClick, and if (iRec <> 0) begin -> If (iRec <> 0) Begin
        The case that each word is changed to is a setting. The spelling of every keyword and operator is set in the Editor Settings dialog, under Keywords and Operators, so the result follows the style you set there.
        The function uses the editor control, so the program's Editor view is shown while it runs.
        { MethodType = eEditorFunction }
        { FnGroup = Cleanup }
        { SummaryText = Changed: Proper Upper and lowercasing }
        """ }
    Function EditorNormalizeCase String[] ByRef asCode String sParameter Returns Boolean
        Handle hoEditor
        Boolean bOK bChanged
        String[] asRefactoredCode
        tRefactorSettings RefactorSettings

        Get phoEditor to hoEditor
        If (hoEditor = 0) Begin
            Error "phoEditor = 0 (Function: EditorNormalizeCase)"
            Function_Return 0
        End

        Set Changed_State of hoEditor to False
        Send RefactorNormalizeCase of hoEditor
        Send PumpMsgQueue of Desktop
        Get Changed_State of hoEditor to bChanged

        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Indents the source code again, with the number of spaces set in the function's parameter.
        Example: a file mixing 3-space, 8-space and flush-left lines is re-indented to the size you pick.
        The indentation of every line is calculated from the block structure, so a file that mixes indentation styles, or whose indentation has become inconsistent over the years, gets one consistent indentation.
        The tab size is the same setting as the tab size in the Editor Settings dialog; the two settings are linked.
        The function uses the editor control, so the program's Editor view is shown while it runs.
        { MethodType = eEditorFunction }
        { FnGroup = Cleanup }
        { EnumList = 1,2,3,4,5,6,7,8}
        { InitialValue = 4}
        { ParamHelp = Select the indent size you want to use for spaces when indenting code
        \nand when breaking a line on rewriting a single line to multiple lines.
        \nIt is the same value that can be set on the Editor Settings dialog tab size. }
        { SummaryText = Reindented code }
        """ }
    Function EditorReIndent String[] ByRef asCode String sParameter Returns Boolean
        Handle hoEditor
        Boolean bOK bChanged
        String[] asRefactoredCode
        tRefactorSettings RefactorSettings

        Get phoEditor to hoEditor
        If (hoEditor = 0) Begin
            Error "phoEditor = 0 (Function: EditorReIndent)"
            Function_Return 0
        End
        // This is automatically set by the _InitTabSize message in cBaseFuncLib
        // when the program is started.
        If (num_arguments > 1) Begin
            Set piTabSize of hoEditor to sParameter
        End

        Set Changed_State of hoEditor to False
        Send RefactorReIndent of hoEditor
        Send GotoLine of hoEditor 0
        Send PumpMsgQueue of Desktop
        Get Changed_State of hoEditor to bChanged

        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Removes the comments at the end of End_Class, End_Object, End_Function and End_Procedure lines.
        Example: End_Procedure //MyProcedure -> End_Procedure
        { MethodType = eStandardFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: End comments }
        """ }
    Function RemoveEndComments String ByRef sLine String sParameter Returns Boolean
        Boolean bFound bChanged
        String sOrig
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (TokenizerData.bIsBlank = True or TokenizerData.bIsComment = True or TokenizerData.sEndComment = "") Begin
            Function_Return False
        End
        Get IsValidRemoveEndCommentsLine sLine to bFound
        If (bFound = False) Begin
            Function_Return False
        End

        Move sLine to sOrig
        Get _RemoveEndComment sLine to sLine
        Move (sLine <> sOrig) to bChanged
        If (bChanged = True) Begin
            // _RemoveEndComment no longer Rtrims; do it here so the user-visible
            // refactor output stays as it was (e.g. "End_Class // foo" becomes
            // "End_Class", not "End_Class " with trailing whitespace).
            Move (Rtrim(sLine)) to sLine
        End
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Removes consecutive blank lines when there are more of them than the number set in the function's parameter.
        { MethodType = eOtherFunction }
        { FnGroup = Cleanup }
        { EnumList = 1,2,3,4,5,6}
        { InitialValue = 2 }
        { ParamHelp = Select max number of consecutive blank lines allowed in source files. }
        { SummaryText = Removed: Consecutive blank Lines }
        """ }
    Function RemoveMultipleBlankLines String[] ByRef asCode String sParameter Returns Integer
        String[] asCodeOut
        Integer iCount iSize iCurrentNoOfEmptyLines iEmptyLines iMaxNoOfEmptyLines
        String sLine
        Boolean bImageStart bImageEnd bMakeImageTest

        Move False to bImageStart
        Move False to bImageEnd
        Move True  to bMakeImageTest
        Move 0 to iCurrentNoOfEmptyLines
        Move sParameter to iMaxNoOfEmptyLines

        Move (SizeOfArray(asCode)) to iSize
        Decrement iSize

        For iCount from 0 to iSize
            Move (Trim(asCode[iCount])) to sLine

            If (bMakeImageTest = True) Begin
                If (bImageStart = False and bImageEnd = False) Begin
                    Get IsImageStart sLine to bImageStart
                End
            End

            If (bImageStart = False and bImageEnd = False) Begin
                If (sLine = "") Begin
                    Increment iCurrentNoOfEmptyLines
                End
                Else Begin
                    Move 0 to iCurrentNoOfEmptyLines
                End
            End
            If (iCurrentNoOfEmptyLines <= iMaxNoOfEmptyLines) Begin
                Move asCode[iCount] to asCodeOut[SizeOfArray(asCodeOut)]
            End

            If (bMakeImageTest = True) Begin
                If (bImageStart = True) Begin
                    Get IsImageEnd sLine to bImageEnd
                    If (bImageEnd = True) Begin
                        Move False to bImageStart
                        Move False to bImageEnd
                        Move False to bMakeImageTest
                    End
                End
            End
        Loop

        Move (SizeOfArray(asCode) - SizeOfArray(asCodeOut)) to iEmptyLines
        Move asCodeOut to asCode

        Function_Return iEmptyLines
    End_Function

    { Published = True }
    { Description = """
        Removes the code markers that old versions of the Studio added, such as '//AB-Store'.
        This includes the //AB/ line prefix, and the //AB-StoreStart and //AB-StoreEnd markers that the old Studio wrote around the code it generated.
        Example: //AB/ Object -> Object; a //AB-StoreStart and //AB-StoreEnd pair is removed, and the code between them is kept.
        { MethodType = eRemoveFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: Legacy IDE markers }
        """ }
    // ToDo: Make this into a MethodType = eRemoveFunctionAll, and pass a string array containing one source file?
    Function RemoveOldStudioMarkers String ByRef sLine Returns Boolean
        String sTrimmedLine

        Move (Trim(sLine)) to sTrimmedLine
        // The whole-line markers are one fenced list (CS_OldStudioMarkerLines, RefactorConstants.h.pkg); the
        // "//AB/ " prefix is tested on its own. A line holding a "|" cannot be a marker.
        Function_Return (Left(sTrimmedLine, 6) = "//AB/ " or ;
            (Pos("|", sTrimmedLine) = 0 and Pos("|" + sTrimmedLine + "|", CS_OldStudioMarkerLines) > 0))
    End_Function

    { Published = True }
    { Description = """
        Removes the old Studio 'Project Object Structure' blocks, with their Register_Object lines, at the top of files such as views.
        WebApp files (*.wo) are not changed.
        Example: the // Project Object Structure comment block and the Register_Object lines it names are removed together; everything else in the file stays.
        Only the Register_Object lines for the objects named in that block are removed. A Register_Object line for any other object is kept, so a file that registers objects for its own reasons keeps them.
        { MethodType = eRemoveFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: Register_Object structures }
        """ }
    Function RemoveProjectObjectStructure String ByRef sLine String sParameter Returns Boolean
        Boolean bWriteLine bRegisterAllObjectsStart bRegisterAllObjectsEnd
        Boolean bProjectObjectStructureStart bProjectObjectStructureEnd
        String[] asObjectNames
        tTokenizer TokenizerData

        Move True to bWriteLine
        Get pTokenizer to TokenizerData
        /* THIS FUNCTION'S WHOLE JOB IS COMMENT LINES, so it cannot use the standard bLineIsReady
           bail unmodified (Nils 2026-08-07: it stopped removing the block on customer.vw).

           bLineIsReady became the UNIVERSAL "hands off this line" signal when #HEADER protection
           was added to the Tokenizer (cRefactorLexer, "this ONE gate protects the whole region"),
           and the comment / blank / open-command gate a few lines below it sets the same flag. So
           every `//` line started arriving here pre-vetoed: the `// Project Object Structure`
           header and every `//   X is a Y` tree line returned False untouched, pasObjectNames was
           never filled, and the Register_Object run below therefore matched nothing either. The
           block came out completely untouched, which is what was reported.

           bIsComment is the discriminator, and it is exact: the two #HEADER branches in Tokenizer
           return BEFORE _IsCommentLine runs, so a header line carries bLineIsReady WITHOUT
           bIsComment. Multi-line strings and image pages return early the same way. Only an
           ordinary comment reaches here with both set - which is precisely the line this function
           exists to read. Everything else the flag protects is still protected. */
        If ((TokenizerData.bLineIsReady = True and TokenizerData.bIsComment = False) or ;
            TokenizerData.bIsVariableDeclaration = True or TokenizerData.bIsInCommand = True or ;
            TokenizerData.bIsInClass = True or TokenizerData.bIsInImage = True or TokenizerData.bIsInFunction = True or ;
            TokenizerData.bIsInProcedure = True or TokenizerData.bIsInDF23MultiLineString = True) Begin
            Function_Return False
        End

        Get pbRegisterAllObjectsStart     to bRegisterAllObjectsStart
        Get pbRegisterAllObjectsEnd       to bRegisterAllObjectsEnd
        Get pbProjectObjectStructureStart to bProjectObjectStructureStart
        Get pbProjectObjectStructureEnd   to bProjectObjectStructureEnd
        Get pasObjectNames                to asObjectNames

        If (bRegisterAllObjectsEnd = False) Begin
            If (bRegisterAllObjectsStart = False) Begin
                Get IsRegisterAllObjectsStart sLine to bRegisterAllObjectsStart
                Set pbRegisterAllObjectsStart        to bRegisterAllObjectsStart
            End
            If (bRegisterAllObjectsStart = True) Begin
                Get IsRegisterObjectInArray sLine asObjectNames to bWriteLine
                Move False to bProjectObjectStructureStart
                Set           pbProjectObjectStructureStart to False
            End
            If (bRegisterAllObjectsStart = False and bProjectObjectStructureEnd = False and bProjectObjectStructureStart = False) Begin
                Get IsProjectObjectStructureStart sLine to bProjectObjectStructureStart
                Set pbProjectObjectStructureStart       to bProjectObjectStructureStart
            End
            If (bProjectObjectStructureStart = True) Begin
                Get IsProjectObjectStructureLine sLine (&asObjectNames) to bWriteLine
            End
            Get IsRegisterAllObjectsEnd sLine to bRegisterAllObjectsEnd
            If (bRegisterAllObjectsEnd = True) Begin
                Send ClearProjectObjectStructureProperties
                // This means that we won't bother with the rest of the file.
                Set pbRegisterAllObjectsEnd to True
            End
        End
        If (bWriteLine = False) Begin
            Move "" to sLine
        End
        Function_Return (bWriteLine = False)
    End_Function

    /* RemoveSelfFromObjectReferences - why so narrow.

       (oName(Self)) and oName are the same object since DataFlex 8.2 ("Easy Object Referencing"), and a
       probe on DataFlex 26 said so for every shape tried (2026-10-23): a sibling, a child object a class
       builds for each instance, a forward reference, and a group-to-group reference across a view's
       neighborhood. What is NOT safe is the same rewrite of a name that is not an object: (piCount(Self))
       and (Value(Self, i)) are method calls and must stay. So a name counts only when this file declares
       'Object <name> is a', and only when no variable of that name is declared in it - a variable wins
       over an object of the same name, so oName alone would then read the variable. Objects declared in
       other files are left alone: this function cannot see them.

       Never touched: comments, string literals, block comments, report images, #COMMAND / #DATA bodies,
       directive lines and #HEADER regions. The parentheses around the reference stay - (oName(Self))
       becomes (oName) - so the expression keeps its shape. A nested reference loses its innermost (Self)
       only: (oA(oB(Self))) becomes (oA(oB)), the same object, because oB is oB(Self).

       Tidy Up, not Modernization: the long form still compiles. Its Deep Scan rule (DS 9246) shipped OFF
       and as Review - 98,288 references on the test drive would bury every other row of a Check (Nils
       2026-10-23), and the function had not had a live run. It is Auto-fix and on since rules v98 (Nils
       2026-10-30): a live run on a workspace copy changed 10,960 references, every line as predicted. */
    { Published = True }
    { Description = """
        Removes (Self) from references to objects that are declared in the same file.
        Example: Send Clear of (oCustomer_DD(Self)) -> Send Clear of (oCustomer_DD)
        Only the names that the file declares with 'Object <name> is a' are changed, and only when no variable has the same name. Comments, strings, #COMMAND blocks and #HEADER sections are not changed.
        { MethodType = eOtherFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: (Self) from object references }
        """ }
    Function RemoveSelfFromObjectReferences String[] ByRef asCode String sParameter Returns Integer
        Integer[] aiLines
        Integer iCount

        Get _RemoveSelfFromObjectRefs (&asCode) (&aiLines) True to iCount
        Function_Return iCount
    End_Function

    // The lines (0-based) RemoveSelfFromObjectReferences would change in asCode - a dry run on the
    // caller's copy, for the Deep Scan rule DS 9246 (cDeepScanner._SelfObjectRefHits).
    Function _SelfObjectRefLines String[] asCode Returns Integer[]
        Integer[] aiLines
        Integer iCount

        Get _RemoveSelfFromObjectRefs (&asCode) (&aiLines) False to iCount
        Function_Return aiLines
    End_Function

    // The core of both: rewrites asCode, lists the lines it changed (0-based) in aiLines and returns how
    // many references it changed. bProgress drives the per-file bar - the published function's walk;
    // the scan drives its own.
    Function _RemoveSelfFromObjectRefs String[] ByRef asCode Integer[] ByRef aiLines Boolean bProgress Returns Integer
        String[] asNames asVars asCodeOnly asTok
        String sLow sW1 sName sTok sLine
        Integer i iLast j jLast iFirst iCount iS iP iC iN iFrom iLen
        Boolean bLineChanged

        Move (ResizeArray(aiLines, 0)) to aiLines
        Move 0 to iCount
        Move (SizeOfArray(asCode) - 1) to iLast
        If (iLast < 0) ;
            Function_Return 0
        If (bProgress = True) ;
            Send _StartFileLineProgress (iLast + 1)
        // PASS 1 - the code of every line (strings masked, comments cut; block comments, report images,
        // macro code and #HEADER regions blank), the objects the file declares and the variables it declares.
        Get _CodeOnlyFileLines (&asCode) to asCodeOnly
        For i from 0 to iLast
            Move (Trim(Lowercase(Replaces(Character(9), asCodeOnly[i], " ")))) to sLow
            If (sLow <> "") Begin
                Move (Pos(" ", sLow)) to iP
                Move sLow to sW1
                If (iP > 0) ;
                    Move (Left(sLow, (iP - 1))) to sW1
                // 'Object <name> is a <class>'
                If (sW1 = "object") Begin
                    If (_NthWord(Self, sLow, 3) = "is") Begin
                        Get _NthWord sLow 2 to sName
                        If (sName <> "" and SearchArray(sName, asNames) = -1) ;
                            Move sName to asNames[SizeOfArray(asNames)]
                    End
                End
                // '<Type> <name> ...' and 'Property <Type> <name>' - the shapes _DeclaredTypeOfVarInLines reads
                Else If (sW1 = "property" or _IsDeclarationTypeName(Self, sW1) = True) Begin
                    Move (StrSplitToArray(sLow, " ")) to asTok
                    Move (SizeOfArray(asTok) - 1) to jLast
                    Move 1 to iFirst
                    If (sW1 = "property") ;
                        Move 2 to iFirst
                    For j from iFirst to jLast
                        Move (Trim(Replaces(",", asTok[j], ""))) to sTok
                        If (sTok <> "" and SearchArray(sTok, asVars) = -1) ;
                            Move sTok to asVars[SizeOfArray(asVars)]
                    Loop
                End
            End
        Loop
        If (SizeOfArray(asNames) = 0) ;
            Function_Return 0

        // PASS 2 - each '<name>(Self)' whose name is one of the file's objects and none of its variables
        // loses its '(Self)'. The code twin is edited with the raw line, so the positions stay matched.
        For i from 0 to iLast
            If (bProgress = True and Mod(i, 20) = 0) ;
                Send _NudgeLineProgress i (iLast + 1) "Source line:"
            Move (Lowercase(Replaces(Character(9), asCodeOnly[i], " "))) to sLow
            If (Pos("self", sLow) > 0) Begin
                Move asCode[i] to sLine
                Move False to bLineChanged
                Get _FindKeywordPos sLow "self" True 1 to iS
                While (iS > 0)
                    Move (Length(sLow)) to iLen
                    Move 0 to iP
                    Move 0 to iC
                    Move (iS - 1) to j
                    While (j > 0 and Mid(sLow, 1, j) = " ")
                        Decrement j
                    Loop
                    If (j > 1 and Mid(sLow, 1, j) = "(") ;
                        Move j to iP
                    Move (iS + 4) to j
                    While (j <= iLen and Mid(sLow, 1, j) = " ")
                        Increment j
                    Loop
                    If (j <= iLen and Mid(sLow, 1, j) = ")") ;
                        Move j to iC
                    // The name: the identifier characters straight before the "(".
                    Move "" to sName
                    If (iP > 1 and iC > 0) Begin
                        Move (iP - 1) to iN
                        While (iN >= 1 and _IsIdentifierChar(Self, Mid(sLow, 1, iN)) = True)
                            Decrement iN
                        Loop
                        If (iN < (iP - 1)) ;
                            Move (Mid(sLow, (iP - 1 - iN), (iN + 1))) to sName
                    End
                    Move (iS + 4) to iFrom
                    If (sName <> "" and SearchArray(sName, asNames) <> -1 and SearchArray(sName, asVars) = -1) Begin
                        Move (Left(sLine, (iP - 1)) + Mid(sLine, Length(sLine), (iC + 1))) to sLine
                        Move (Left(sLow, (iP - 1)) + Mid(sLow, Length(sLow), (iC + 1))) to sLow
                        Increment iCount
                        Move True to bLineChanged
                        Move iP to iFrom
                    End
                    Get _FindKeywordPos sLow "self" True iFrom to iS
                Loop
                If (bLineChanged = True) Begin
                    Move sLine to asCode[i]
                    Move i to aiLines[SizeOfArray(aiLines)]
                End
            End
        Loop
        Function_Return iCount
    End_Function

    { Published = True }
    { Description = """
        Removes comment lines that old versions of the Studio generated.
        Examples:
        // fires when the button is clicked
        //OnChange is called on every changed character
        // Visual DataFlex xx.x Client Size Adjuster
        // Visual DataFlex xx.x Migration Utility
        ...and so on
        Only lines that contain nothing but a comment are removed. A comment at the end of a line of code is never removed, because the code would be removed with it.
        Lines that contain //AB are not changed. Those are the old Studio markers, which RemoveOldStudioMarkers removes.
        { MethodType = eRemoveFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: Studio generated comments }
        """ }
    Function RemoveStudioGeneratedComments String ByRef sLine Returns Boolean
        String sText sComment sComment2
        Boolean bFound bChanged
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        Move False to bChanged
        Move (Trim(sLine)) to sText
        If (sText = "" or sText = CS_CommentSymbol or sText contains (CS_CommentSymbol + "AB") or TokenizerData.bIsComment = False) Begin
            Function_Return False
        End

        Move "fires when the button is clicked" to sComment
        Get IsStudioGeneratedComment sLine sComment to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "onchange is called on every changed character" to sComment
        Get IsStudioGeneratedComment sLine sComment to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "visual dataflex"      to sComment
        Move "client size adjuster" to sComment2
        Get IsStudioGeneratedComment sLine sComment sComment2 to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "visual dataflex"    to sComment
        Move "migration utility," to sComment2
        Get IsStudioGeneratedComment sLine sComment sComment2 to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "If you set Current_radio you must set this after the" to sComment
        Get IsStudioGeneratedComment sLine sComment to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "radio objects have been created AND after Notify_select_State has been" to sComment
        Get IsStudioGeneratedComment sLine sComment to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Move "created. i.e. Set in bottom-code at end!!" to sComment
        Get IsStudioGeneratedComment sLine sComment to bFound
        If (bFound = True) Begin
            Move "" to sLine
            Function_Return True
        End

        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Removes spaces at the end of lines (trailing spaces).
        Example: a line ending "Send Update   " keeps its text and loses the trailing blanks.
        { MethodType = eStandardFunction }
        { SummaryText = Removed: Spaces at end of line }
        { FnGroup = Cleanup }
        """ }
    Function RemoveTrailingSpaces String ByRef sLine Returns Boolean
        Integer iBefore iAfter
        Boolean bChanged
        tTokenizer TokenizerData

        // A DF 23 multi-line string's line: its trailing spaces are part of the string's value (2026-10-24).
        Get pTokenizer to TokenizerData
        If (TokenizerData.bIsInDF23MultiLineString = True) ;
            Function_Return False
        Move (Length(sLine))     to iBefore
        Move (RTrim(sLine))      to sLine
        Move (Length(sLine))     to iAfter
        Move (iBefore <> iAfter) to bChanged

        Function_Return bChanged
    End_Function

    /* RemoveTypefaceLine - the generalized successor of RemoveSansSerif (one of the very first
       functions, hardwired to "MS Sans Serif"; Nils 2026-07-12). The font is now the parameter,
       and * removes every Set Typeface line whatever the font (let the theme own the fonts).
       Matching is case-, whitespace- and quote-style-insensitive, and requires the line to START
       with Set Typeface (the old anywhere-in-line match would also have removed commented copies
       and inline-If forms, where deleting the whole line changes semantics). */
    { Published = True }
    { Description = """
        Removes 'Set Typeface to "<font>"' lines for the font named in the function's parameter. These lines set a font for a single control, which modern themes replace.
        Enter * as the parameter to remove every Set Typeface line, whatever the font.
        The whole line must be a Set Typeface line. Spaces and both kinds of quotes are ignored when lines are compared. A line where Set Typeface is commented out, or is part of a one-line If statement, is not changed, because removing the whole line would change what the code does.
        Example: Set Typeface to "MS Sans Serif" is removed, and so is Set  Typeface  to 'MS Sans Serif'.
        This function was previously named RemoveSansSerif and only removed that font. It was changed in 2026, so if you saved a selection with the old name, you need to select the function again.
        { MethodType = eRemoveFunction }
        { FnGroup = Cleanup }
        { EnumList = "ANY" }
        { InitialValue = MS Sans Serif }
        { ParamHelp = The font name whose 'Set Typeface to "..."' lines are removed -
        \nmatched case- and whitespace-insensitively, either quote style.
        \nDefaults to "MS Sans Serif", the classic legacy Windows font. Enter * to remove
        \nevery Set Typeface line, whatever the font. }
        { SummaryText = Removed: 'Set Typeface' font lines }
        """ }
    Function RemoveTypefaceLine String ByRef sLine String sParameter Returns Boolean
        String sTest sWant
        tTokenizer TokenizerData

        /* CHEAP GATE FIRST (Nils 2026-07-29: "instead of relying/calling the Tokenizer function
           first, it could start to check if there is a 'Typeface' word in the source line or not").

           The three Replaces below rewrite the WHOLE line - strip every space, then two quote
           substitutions - and they ran before the one test that rejects almost everything. On a
           workspace pass that is three full-line rewrites per line for the ~99.9% of lines that
           cannot possibly match; a no-op run over 1,796 files walks ~530,000 of them.

           A line without "typeface" in it can never be a Set Typeface line, so one native Pos over
           the lowercased line answers it. Same idiom as the pre-gate in _ComputePinnedIndicators
           (Nils 2026-07-17, ~940ms/file): native scan first, interpreted work only on the
           plausible lines. Behaviour is unchanged - every line this returns False for, the old
           code also returned False for, because "settypefaceto" contains "typeface". */
        Move (Lowercase(sLine)) to sTest
        If (Pos("typeface", sTest) = 0) ;
            Function_Return False
        // Not a line of a DF 23 multi-line string: its 'Set Typeface' is text (2026-10-24).
        Get pTokenizer to TokenizerData
        If (TokenizerData.bIsInDF23MultiLineString = True) ;
            Function_Return False
        Move (Trim(sTest)) to sTest
        Move (Replaces(CS_S, sTest, ""))  to sTest
        Move (Replaces("'", sTest, "*")) to sTest
        Move (Replaces('"', sTest, "*")) to sTest
        // The line itself must BE a Set Typeface line (see the header comment).
        If (Left(sTest, 14) <> "settypefaceto*") ;
            Function_Return False
        Move (Trim(sParameter)) to sWant
        If (sWant = "" or sWant = "*") ;
            Function_Return True
        Move (Lowercase(Replaces(CS_S, sWant, ""))) to sWant
        Function_Return (sTest contains ("settypefaceto*" + sWant + "*"))
    End_Function

    { Published = True }
    { Description = """
        Removes local variables that are declared but not used in procedures and functions.
        Unused struct variables are not removed.
        Files that contain #INCLUDE are skipped completely: an included file uses the same local variables as the file that includes it, so variables used there cannot be seen when one file at a time is scanned.
        { MethodType = eOtherFunction }
        { FnGroup = Cleanup }
        { SummaryText = Removed: Unused local variables }
        """ }
    Function RemoveUnusedLocals String[] ByRef asCode String sParameter Returns Integer
        Handle ho
        Integer iRetval

        Get Create (RefClass(cRemoveUnusedLocals)) to ho
        If (ho = 0) Begin
            Error "Could not create cRemoveUnusedLocals object."
            Function_Return 0
        End

        Set piNoOfUnusedLocalVariables of ho to 0
        Get RemoveUnusedLocals of ho (&asCode) to iRetval
        Send Destroy of ho

        Function_Return iRetval
    End_Function

    /* ShadowedPackageFilesReport - why the evidence is a compiler LISTING and not a folder rule.

       The user-facing half of this comment lives in the { Description }. What is left is the
       reason the report is shaped the way it is.

       A stale copy of a package compiles perfectly. That is the entire problem, and it is why no
       compiler message can point at it: the build succeeds, quietly, against the wrong file. The
       case that produced this report (2026-08-30) had nine copies of one wrapper package under a
       single workspace. The modernised one was a declared git dependency AND checked out - yet a
       vendored copy inside another package won the search path, so seven obsolete-function
       warnings survived every attempt to fix them at the library.

       NOT a Deep Scan rule: a scan rule reads one line of one file, and "this file is shadowed" is
       a fact about the whole workspace and about a build. Not a name list either - an earlier
       sketch warned when files named after two known libraries appeared outside a library folder,
       which would have flagged that workspace's hand-tweaked "..._ext.pkg" (a deliberate fork with
       renamed functions, which had to stay) while missing every other library. Duplicate
       RESOLUTION is the honest signal: it needs no catalogue of library names, and a uniquely
       named fork can never trip it.

       Measured before it was built, on the workspace above: duplicated names anywhere = 188, which
       is noise; duplicated AND actually included by the build = 36, which is a checklist. */
    { Published = True }
    { Description = """
      Reports only. Makes no changes to the source code.
      Lists package files that exist in more than one place in the workspace, and shows which copy the compiler actually used and which copies it did not use.
      The compiler never sees a copy that it does not use, so the program compiles without errors against the wrong file. This means that a fix in a library may have no effect, and a warning you have already fixed can still appear after every compile.
      The report uses the latest compiler listing (.prn) in the workspace, which shows the files that the compiler actually opened. The copies that were not opened are not in the listing, so the report also searches the workspace for .pkg, .inc and .h files with the same name. Compile the program at least once before you run this report.
      A second section lists library folders that the workspace no longer uses, usually folders left behind after a move to git packages. A folder is listed only when nothing in it was compiled and no .sws file mentions it. For each folder, the report compares it with the package that replaced it, shows how many source files exist only in the old folder, and shows a rename command that you can run and undo.
      Nothing is deleted or changed: a second copy can be an intended local version, and an old library folder can contain local changes.
      The results are written to a log file; open it with Tools > Logs > Other Log Files.
      { MethodType = eReportFunctionAll }
      { FnGroup = Cleanup }
      { SummaryText = Report: shadowed package files, and library folders nothing uses any more }
      """ }
    Function ShadowedPackageFilesReport String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        Integer iRetval
        String[] asOtherLogFiles

        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho = 0) Begin
            Error "Could not create cShadowedPackageFiles object."
            Function_Return 0
        End
        // Deliberately ignores asFiles: the selected set is the workspace's OWN sources, and a
        // shadowing copy usually sits where the selection does not reach - an old library folder,
        // or a package checkout. The sweep inside covers the whole workspace instead.
        Get FindShadowedPackageFiles of ho to iRetval

        Get pasOtherLogFiles to asOtherLogFiles
        Get psLogFile of ho  to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
        Set pasOtherLogFiles to asOtherLogFiles
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    { Published = True }
    { Description = """
        Splits If/Else statements written on one line into If/Else statements with a Begin/End block.
        A line that ends with Break is not split, because that could change what the program does.
        The function's parameter sets how the statement is split.
        Example: If (iRetval = 0) Procedure_Return -> If (iRetval = 0) Begin / Procedure_Return / End
        { MethodType = eStandardFunction }
        { FnGroup = Cleanup }
        { EnumList = "eSplitBySpaceAndSemicolon, eSplitBySemicolon, eSplitToBeginEndBlock" }
        { InitialValue = eSplitToBeginEndBlock }
        { ParamHelp = Valid values;
        \neSplitBySpaceAndSemicolon - Split line with space and semicolon
        \neSplitBySemicolon - Split line with semicolon
        \neSplitToBeginEndBlock - Use a Begin/End block }
        { SummaryText = Split If/Else line }
        """ }
    Function SplitInlineIfElseLine String ByRef sLine String sParameter Returns Boolean
        Boolean bStop bChanged bFound
        Integer iIndent eSplitBy iTabSize iItem
        String  sText sToken
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End
        Move (SearchArray(CS_If, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) Begin
            Move (Trim(sLine)) to sText
            Move (Left(sText, 3)) to sText
            Move (Lowercase(sText) = Lowercase(CS_If)) to bFound
            If (bFound = False) Begin
                Function_Return False
            End
        End
        
        // Note: We do *not* change the line if it ends with a "Break", or if it contains
        //       a "Goto" or "Gosub", because wrapping those in a Begin/End block would
        //       change the logic of the program.
        Move TokenizerData.iTokenCount to iItem
        If (iItem = 0) ;
            Function_Return False
        Move TokenizerData.asLineTokens[iItem -1] to sToken
        If (Lowercase(sToken) = "break") Begin
            Function_Return False
        End
        Move (SearchArray("goto",  TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) ;
            Function_Return False
        Move (SearchArray("gosub", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) ;
            Function_Return False
        
        Move False to bChanged
        // sParameter arrives as the enum NAME from the UI combo or as the numeric VALUE
        // from tests - resolve via _ParameterIsEnum (a bare Move of the name into the
        // Integer enum yielded eSplitUnknown from the UI). Default = the documented
        // {InitialValue}, eSplitToBeginEndBlock.
        Move eSplitToBeginEndBlock to eSplitBy
        Get _ParameterIsEnum sParameter "eSplitBySpaceAndSemicolon" eSplitBySpaceAndSemicolon to bFound
        If (bFound = True) ;
            Move eSplitBySpaceAndSemicolon to eSplitBy
        Get _ParameterIsEnum sParameter "eSplitBySemicolon" eSplitBySemicolon to bFound
        If (bFound = True) ;
            Move eSplitBySemicolon to eSplitBy
        /* A LINE THAT ALREADY CONTAINS A LINE BREAK IS A COMPOSED BLOCK, not an inline If.

           ChangeLegacyIndicators returns a three-line block ("If (...) Begin" / "Move ..." / "End")
           into this single-line slot, and the engine then re-tokenizes that whole block AS ONE LINE
           (cRefactorEngine, after any function changes sLine). What arrives here therefore starts
           with "If " and ENDS WITH "End" - so IsLineEndSemiColonOrBegin below, which is exactly the
           guard meant to stop this, sees "End" instead of "Begin" and lets it through. The split
           then wrote a ";" after the block's Begin and indented the Move line a second time
           (Nils 2026-08-04).

           Guarding on the line break rather than teaching the end-check about blocks: ANY converter
           in this family may compose a block, and a line-by-line function has no business rewriting
           one whoever produced it. */
        If (sLine contains (Character(10))) ;
            Function_Return False

        Get piTabSize to iTabSize
        If (eSplitBy = eSplitToBeginEndBlock) Begin
            Move (SearchArray(CS_Begin, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem <> -1) ;
                Function_Return False
        End

        Move (LTrim(sLine))     to sText
        Move (Pos(sText,sLine) - 1) to iIndent
        Move (Left(sText, 3))   to sText
        Move (Lowercase(sText)) to sText
        If (sText = (Lowercase(CS_If) + CS_S)) Begin
            Get IsLineEndSemiColonOrBegin TokenizerData.sOverstrikeLine to bStop
            If (bStop = False) Begin
                // It's one of those single line if statements, break it up
                Move (Lowercase(sLine)) to sText
                Get BreakupCompoundStatement iIndent (&sLine) eSplitBy iTabSize to bChanged
            End
        End
        Else Begin
            Move (LTrim(sLine))     to sText
            Move (Left(sText, 5))   to sText
            Move (Lowercase(sText)) to sText
            If (sText = (Lowercase(CS_Else) + CS_S)) Begin
                Get IsLineEndSemiColonOrBegin TokenizerData.sOverstrikeLine to bStop
                If (bStop = False) Begin
                    Get BreakupCompoundStatement iIndent (&sLine) eSplitBy iTabSize to bChanged
                End
            End
        End
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
      Reports only. Makes no changes to the source code.
      Checks every file in the current workspace, and lists the files that are not used anywhere.
      The report also writes a batch file, 'MoveUnusedSourceFiles.bat', to the DFRefactor_Backup folder. Running it moves the listed files into a sub-folder, without deleting them, so the change can be undone. Running the batch file is optional; the note at the end of the report explains how to undo it.
      The results are written to a log file; open it with Tools > Logs > Other Log Files.
      { MethodType = eReportFunctionAll }
      { FnGroup = Cleanup }
      { SummaryText = Creates a report of never-used files plus an optional .bat to quarantine them }
      """ }
    Function UnusedSourceFiles String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        Integer iRetval
        String sLogFile
        String[] asOtherLogFiles
        tRefactorSettings RefactorSettings

        Get Create (RefClass(cUnusedSourceFiles)) to ho
        If (ho = 0) Begin
            Error "Could not create cUnusedSourceFiles object."
            Function_Return 0
        End

        Get pRefactorSettings to RefactorSettings
        Get FindUnusedSourceFiles of ho RefactorSettings.FileData.asFullFileNames to iRetval

        If (iRetval <> 0) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Get psLogFile of ho  to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    { Published = True }
    { Description = """
      Reports only. Makes no changes to the source code.
      For each file, finds the classes that each Use statement makes available, and reports a Use statement when the file creates no object of any of those classes.
      Use files that contain only procedures or functions, and no classes, are not reported.
      The results for all files are written to one log file; open it with Tools > Logs > Other Log Files.
      { MethodType = eReportFunctionAll }
      { FnGroup = Cleanup }
      { SummaryText = Creates a report with unused Use statements }
      """ }
    Function UnusedUseStatements String[] ByRef asFiles String sParameter Returns Integer
        Handle ho
        Integer iRetval
        String sHomePath sLogFile
        String[] asOtherLogFiles

        Get Create (RefClass(cUnusedUseStatements)) to ho
        If (ho = 0) Begin
            Error "Could not create cUnusedUseStatements object."
            Function_Return 0
        End

        // DF_OPEN_PATH is already set to the target workspace's source folders
        // by cRefactorApplication.UpdateDFOpenPath when the workspace was opened.
        // No per-function path management is required here.
        Get psHomeTarget of ghoApplication to sHomePath
        Move (vFolderFormat(sHomePath)) to sHomePath
        Move (sHomePath + CS_BackupFolder + CS_DirSeparator + CS_UnusedUseStatementsLogFile) to sLogFile
        Set psLogFile of ho to sLogFile
        Get FindUnusedUseStatementsAllFiles of ho asFiles to iRetval

        If (pbOK(ho) = True) Begin
            Get pasOtherLogFiles to asOtherLogFiles
            Move sLogFile to asOtherLogFiles[SizeOfArray(asOtherLogFiles)]
            Set pasOtherLogFiles to asOtherLogFiles
        End
        Send Destroy of ho
        Function_Return iRetval
    End_Function

