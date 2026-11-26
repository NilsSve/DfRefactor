// CommandToFunctionRefactorFunctions.inc
//
// The COMMAND -> FUNCTION family of refactoring functions, #Include'd into the
// oRefactorFuncLib object so they read and compile exactly as if they were written there.
//
// One rewrite, fifteen keywords. DataFlex's string commands - Uppercase, Lowercase, Left,
// Mid, Right, Pos, Trim, Pad, Length, Ascii, ZeroString, Character, Insert, Replace, Cmdline
// - each take '<Cmd> <arg> to <dest>' and each become 'Move (<Cmd>(<arg>)) to <dest>'. Most
// are fifteen lines that hand the keyword to _SingleArgCommandToFunction, which is why that
// helper lives here too: it is the family, not a general utility.
//
// The exceptions earn their length - Trim, Insert and Replace have shapes the generic path
// cannot express, and Cmdline delegates to the class.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    /* Generic "<Cmd> <arg> to <dest>" -> "Move (<Cmd>(<arg>)) to <dest>" rewrite for a single-argument
       legacy string command (Uppercase, Lowercase, ...). Same robust approach as ChangeTrimCommandToFunction,
       generalised by the keyword: the argument is extracted by POSITION (raw text from after the command
       keyword up to the command "to"), so any shape survives - a simple var, a table.field (USER.SPRAK),
       or a parenthesised expression. A "<Cmd>(" function CALL is left untouched (the keyword must be
       FOLLOWED BY WHITESPACE, not "("). Requires an explicit "to <dest>".
    */
    Function _SingleArgCommandToFunction String ByRef sLine String sKeyWord Returns Boolean
        Boolean bFound
        Integer iPos iStart iCmdPos iArgStart iArgEnd iToPos
        tTokenizer TokenizerData
        String sOverFull sCh sArg

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        Get IsKeywordInLine sKeyWord TokenizerData.asLineTokens to bFound
        If (bFound = False) Begin
            Function_Return False
        End

        // Work on the MASKED line (indentation + overstrike) - position-aligned with sLine, string
        // content hidden, so a keyword/"to" inside a literal can never match.
        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull

        // Locate the legacy COMMAND: a boundary-aware keyword FOLLOWED BY WHITESPACE (a "<Cmd>(" call
        // has "(" right after the name, so it is never taken as the command - keeps a call untouched).
        Move 1 to iStart
        Move 0 to iCmdPos
        While (iCmdPos = 0)
            Get _FindKeywordPos sOverFull sKeyWord True iStart to iPos
            If (iPos = 0) ;
                Function_Return False
            Move (Mid(sOverFull, 1, (iPos + Length(sKeyWord)))) to sCh
            If (sCh = CS_S or sCh = Character(9)) ;
                Move iPos to iCmdPos
            Else ;
                Move (iPos + 1) to iStart
        Loop

        // Argument = RAW text from the first non-blank after the keyword up to the command "to".
        Move (iCmdPos + Length(sKeyWord)) to iArgStart
        While (iArgStart <= Length(sOverFull) and (Mid(sOverFull, 1, iArgStart) = CS_S or Mid(sOverFull, 1, iArgStart) = Character(9)))
            Increment iArgStart
        Loop

        Get _FindKeywordPos sOverFull CS_To True iArgStart to iToPos
        If (iToPos > iArgStart) Begin
            // "<Cmd> <arg> to <dest>": arg ends at the last non-blank before "to"; the gap + "to <dest>" +
            // any trailing comment is kept verbatim from the RAW line.
            Move (iToPos - 1) to iArgEnd
            While (iArgEnd >= iArgStart and (Mid(sOverFull, 1, iArgEnd) = CS_S or Mid(sOverFull, 1, iArgEnd) = Character(9)))
                Decrement iArgEnd
            Loop
            If (iArgEnd < iArgStart) ;
                Function_Return False
            Move (Mid(sLine, (iArgEnd - iArgStart + 1), iArgStart)) to sArg
            // Rebuild on the RAW line: <indent/nose> + Move (<Cmd>(<arg>)) + <original gap> to <dest>.
            Move (Left(sLine, (iCmdPos - 1)) + CS_Move + " (" + sKeyWord + "(" + sArg + "))" + Mid(sLine, CI_EOL, (iArgEnd + 1))) to sLine
            Function_Return True
        End

        // IN-PLACE form "<Cmd> <arg>" (no "to"). These single-arg string commands modify their argument IN
        // PLACE, so "Uppercase X" is exactly "Uppercase X to X" -> "Move (Uppercase(X)) to X" (destination IS
        // the argument). <arg> is the lone lvalue token after the command - it ends at the next blank / EOL
        // (a dotted Table.Field has no inner blank, so it is captured whole); any tail after it (trailing
        // spaces or a // comment) is preserved from the RAW line. Only the safe string transforms reach this
        // helper (Uppercase / Lowercase); Pos - whose no-"to" form is a [Found] side-effect, NOT convertible -
        // has its own function + skip-guard and never routes here. (LegacyApp: uppercase sUserName, etc.)
        Move iArgStart to iArgEnd
        While (iArgEnd <= Length(sOverFull) and Mid(sOverFull, 1, iArgEnd) <> CS_S and Mid(sOverFull, 1, iArgEnd) <> Character(9))
            Increment iArgEnd
        Loop
        Move (iArgEnd - 1) to iArgEnd
        If (iArgEnd < iArgStart) ;
            Function_Return False
        Move (Mid(sLine, (iArgEnd - iArgStart + 1), iArgStart)) to sArg
        // Rebuild: <indent/nose> + Move (<Cmd>(<arg>)) to <arg> + <trailing tail>.
        Move (Left(sLine, (iCmdPos - 1)) + CS_Move + " (" + sKeyWord + "(" + sArg + "))" + " to " + sArg + Mid(sLine, CI_EOL, (iArgEnd + 1))) to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Replaces the obsolete ASCII command with the Ascii() function, in a Move statement.
        Example: ASCII sChar TO iVal -> Move (Ascii(sChar)) to iVal
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Ascii }
        { SummaryText = Changed: 'ASCII' command to 'Move (Ascii(...))' }
        """ }
    Function ChangeAsciiCommandToFunction String ByRef sLine String sParameter Returns Boolean
        String sNose sArg sMid sDest
        Integer iItem iPos
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Function_Return False
        Move (SearchArray("ASCII", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) ;
            Function_Return False
        // Legacy syntax is "ASCII <arg> TO <dest>" -> needs 4 tokens from the keyword.
        If (SizeOfArray(TokenizerData.asLineTokens) < (iItem + 4)) ;
            Function_Return False
        Move TokenizerData.asLineTokens[iItem + 1] to sArg
        Move TokenizerData.asLineTokens[iItem + 2] to sMid
        Move TokenizerData.asLineTokens[iItem + 3] to sDest
        // The middle word MUST be "to", else this is not the legacy ASCII command.
        If (Lowercase(sMid) <> "to") ;
            Function_Return False
        Get _FindKeywordPos (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) "ASCII" True 1 to iPos
        If (iPos = 0) ;
            Function_Return False
        Move (Left(sLine, (iPos - 1))) to sNose
        Move (sNose + "Move (Ascii(" + sArg + ")) to " + sDest) to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Character command with the Character() function.
        Example: Character 13 to CR -> Move (Character(13)) to CR
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Character }
        { SummaryText = Changed: 'Character' command to function 'Character' }
        """ }
    Function ChangeCharacterCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Character to bChanged
        Function_Return bChanged
    End_Function

    /* Cmdline -> cCommandLine. The user-facing half of this comment (why the sequential semantics
       need a generated shim, what that shim contains, the conversion limits and the silent-compile
       note) moved into the { Description } on 2026-08-23.

       The Deep Scan triage's top-ranked converter candidate - 120 real sites across 101 files in the
       study workspace, virtually all in .src program shells. NO {ModRecipe} - the command compiles
       silently on modern DataFlex; Deep Scan (DS rule 'Cmdline command') is its discovery surface and
       routes here. Suggest until a real-workspace run verifies. */
    { Published = True }
    { Description = """
        Replaces the obsolete "Cmdline <var>" command, which reads the next command-line argument, with the cCommandLine class.
        Each line becomes "Move (NextCmdLineArgument()) to <var>". NextCmdLineArgument() is a small function that is added at the top of the file. Like the old command, it returns the next argument each time it is called, and "" after the last one.
        Why a helper function is needed: the old command read the next argument on every call, one after the other, while cCommandLine.Argument(i) reads the argument with a given number. Which number a line needs depends on the code around it, typically a While loop that reads until the value is empty. NextCmdLineArgument() goes through Argument(1..n) and returns "" after the last argument, just as the old command did, so such a loop still ends the way it always did.
        What is added at the top of the file: Use cCommandLine.pkg, a global counter and NextCmdLineArgument() itself. It is protected by #IFDEF, so running the function twice on the same file does not add it twice.
        Limitations: only the exact form of the command with two words is converted. A variable that happens to be named Cmdline elsewhere in a line, and the rare form with a length argument, are not changed.
        The old command still compiles without any message in modern DataFlex, so the compiler does not report it. Analyze Source finds it.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { SummaryText = Converted: Cmdline command -> cCommandLine (sequential shim) }
        """ }
    Function ChangeCmdlineCommandToFunction String[] ByRef asCode String sParameter Returns Integer
        Integer iRetval
        Get _TransformCmdlineCommands (&asCode) to iRetval
        Function_Return iRetval
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Insert command with the Insert() function.
        Example: Insert "," In sText At 2 --> Move (Insert(",", sText, 2)) to sText
        Without an 'At' clause, the position is 1: Insert " " in sLimit --> Move (Insert(" ", sLimit, 1)) to sLimit
        A one-line If statement is converted too: If sOne Eq "A" Insert "B" in sOne at 2 --> If sOne Eq "A" Move (Insert("B", sOne, 2)) to sOne
        The command also sets strmark (the position), which the Insert() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Insert }
        { SummaryText = Insert command -> (Insert( }
        """ }
    Function ChangeInsertCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged bFound bVeto bMarked
        String sNose sLineLC sToken sVar1 sVar2 sText sInPos
        Integer iPos iItem iIn
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        Move (SearchArray(CS_Insert, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) Begin
            Function_Return False
        End

        // The Insert COMMAND requires an 'in <collection>' clause (Insert <value> in <array> [at <pos>]).
        // Without it the token is NOT the command: 'Send Insert sText' / 'Send Insert (expr)' is a message
        // dispatch to a control's Insert method (LegacyApp XMLE0100.vw), which converting mangles into
        // 'Send Move (Insert(sText,,)) to '. Leave the line untouched when 'in' is absent.
        // The clause is the COMMAND's, so it is looked for AFTER the Insert token: a guarding condition
        // can carry its own 'In' ('If x In "A|B" Insert "+" In sBody At 1'), and a search from the
        // start of the line took that one - the target became the string constant (Nils 2026-09-19).
        Get _TokenIndexAfter TokenizerData iItem CS_In to iIn
        If (iIn = -1) Begin
            Function_Return False
        End

        // The command leaves the insert POSITION in strmark; Insert() does not. Last clean bail
        // point - sLine is rewritten from here on.
        Get _SideProductVeto (&sLine) "insert" (&bMarked) to bVeto
        If (bVeto = True) ;
            Function_Return bMarked

        Move (Trim(sLine)) to sLine
        Move "" to sNose
        Move (Lowercase(sLine)) to sLineLC
        // If anything left of the CS_Insert command, save it in "sNose" (start string)
        If (iItem > 0) Begin
            Move (Pos(Lowercase(CS_Insert), sLineLC)) to iPos
            Move (Left(sLine, (iPos -1))) to sNose
            Move (Replace(sNose, sLine, "")) to sLine
        End

        // Remove the CS_Insert command
        Move TokenizerData.asLineTokens[iItem] to sToken
        Move (Replace(sToken, sLine, "")) to sLine
        // Get the first variable
        Move TokenizerData.asLineTokens[iItem + 1] to sVar1

        // Find and remove the "IN" keyword - the command's own, after the Insert token (found above).
        Move iIn to iItem
        If (iItem <> -1) Begin
            Move TokenizerData.asLineTokens[iItem] to sToken
            Move (Replace(sToken, sLine, "")) to sLine
            Move TokenizerData.asLineTokens[iItem + 1] to sVar2
        End

        // Find and remove the "AT" keyword, and save the next parameter which is the position to insert at.
        // Same rule: the command's own 'At', after its 'In'.
        Get _TokenIndexAfter TokenizerData iItem CS_At to iItem
        If (iItem <> -1) Begin
            Move TokenizerData.asLineTokens[iItem] to sToken
            Move (Replace(sToken, sLine, "")) to sLine
            // Keep the position as a STRING (verbatim token). It can be a variable or expression - 'at iIndex',
            // 'at (Length(s))' - not just a literal. Moving it to an Integer makes DF EVALUATE it as a numeric
            // expression: that faults err 54 "Invalid symbol in expression" for a non-numeric symbol, and would
            // silently yield 0 even when it didn't fault (losing the position).
            Move TokenizerData.asLineTokens[iItem + 1] to sInPos
        End

        Move "" to sText
        If (sNose <> "") Begin
            Move sNose to sText
            Move (Trim(sText) + CS_S) to sText
        End
        // The Insert() function REQUIRES the 3rd (position, 1-based) arg - it is NOT optional, so always emit
        // three. When the legacy command omits the 'At <pos>' clause the position defaults to 1, so emit "1"
        // rather than an empty slot ('Insert(v,a,)' - a syntax error) or a 2-arg call (also invalid). (Nils
        // 2026-07-06.)
        If (Trim(sInPos) = "") ;
            Move "1" to sInPos
        Append sText CS_Move CS_S "(" CS_Insert "(" sVar1 "," sVar2 "," sInPos "))" " " CS_To CS_S sVar2

        Get AssembleOutputLine sText TokenizerData to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Left command with the Left() function.
        Example: Left sVar 5 to sLeft -> Move (Left(sVar, 5)) to sLeft
        The command also sets strmark (the count), which the Left() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Left }
        { SummaryText = Changed: 'Left' command to function: 'Left' }
        """ }
    Function ChangeLeftCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Left to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Length command with the Length() function.
        Example: Length sVar to iLength -> Move (Length(sVar)) to iLength
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Length }
        { SummaryText = Changed: 'Length' command to function 'Length' }
        """ }
    Function ChangeLengthCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Length to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Lowercase command with the Lowercase() function.
        Example: Lowercase sVal to sVal -> Move (Lowercase(sVal)) to sVal
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Lowercase }
        { SummaryText = Changed: Lowercase command to function Lowercase }
        """ }
    Function ChangeLowercaseCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get _SingleArgCommandToFunction (&sLine) CS_Lowercase to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Mid command with the Mid() function.
        Example: Mid sText to sResult 5 3 -> Move (Mid(sText, 5, 3)) to sResult
        The command also sets strmark (the start) and strlen (the length), which the Mid() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Mid }
        { SummaryText = Changed: 'Mid' command to function 'Mid' }
        """ }
    Function ChangeMidCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Mid to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Pad command with the Pad() function.
        Example: Pad sVar to sResult 20 -> Move (Pad(sVar, 20)) to sResult
        The command also sets strmark (the count), which the Pad() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Pad }
        { SummaryText = Changed: 'Pad' command to function 'Pad' }
        """ }
    Function ChangePadCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Pad to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Pos command with the Pos() function.
        Example: Pos "-"  in sIns to iPos --> Move (Pos("-",sIns)) to iPos
        The command also sets Found, strmark and strlen, which the Pos() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Pos }
        { SummaryText = Changed: Pos command to function Pos }
        """ }
    Function ChangePosCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Pos to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Right command with the Right() function.
        Example: Right sVar to sRight 5 -> Move (Right(sVar, 5)) to sRight
        The command also sets strlen (the count), which the Right() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Right }
        { SummaryText = Changed: Right command to function }
        """ }
    Function ChangeRightCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_Right to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Trim command with the Trim() function.
        Example: Trim sVal to sVal -> Move (Trim(sVal)) to sVal
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Trim }
        { SummaryText = Changed: Trim command to function Trim }
        """ }
    Function ChangeTrimCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bFound
        Integer iPos iStart iTrimPos iArgStart iArgEnd iToPos
        tTokenizer TokenizerData
        String sOverFull sCh

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        Get IsKeywordInLine CS_Trim TokenizerData.asLineTokens to bFound
        If (bFound = False) Begin
            Function_Return False
        End

        // Work on the MASKED line (indentation + overstrike) - position-aligned with sLine,
        // with string content hidden, so a "Trim"/"to" inside a literal can never match.
        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull

        // Locate the legacy Trim COMMAND: a boundary-aware "Trim" FOLLOWED BY WHITESPACE.
        // A "Trim(" function call has "(" right after the name, so it is never taken as the
        // command - that is what keeps a Trim(...) call on the same line untouched.
        Move 1 to iStart
        Move 0 to iTrimPos
        While (iTrimPos = 0)
            Get _FindKeywordPos sOverFull CS_Trim True iStart to iPos
            If (iPos = 0) ;
                Function_Return False
            Move (Mid(sOverFull, 1, (iPos + Length(CS_Trim)))) to sCh
            If (sCh = CS_S or sCh = Character(9)) ;
                Move iPos to iTrimPos
            Else ;
                Move (iPos + 1) to iStart
        Loop

        // Argument = the RAW text from the first non-blank after "Trim" up to the command
        // "to". Extracting by POSITION (not asLineTokens[next]) captures ANY argument shape -
        // a simple var, a table.field (USER.SPRAK), or a parenthesised expression
        // (Trim (Val(hDD,"X")) to y). The old single-token grab missed the paren form and
        // corrupted the dotted form into "Move (Trim(USER)).SPRAK" (Nils 2026-06-11).
        Move (iTrimPos + Length(CS_Trim)) to iArgStart
        While (iArgStart <= Length(sOverFull) and (Mid(sOverFull, 1, iArgStart) = CS_S or Mid(sOverFull, 1, iArgStart) = Character(9)))
            Increment iArgStart
        Loop

        Get _FindKeywordPos sOverFull CS_To True iArgStart to iToPos
        If (iToPos = 0 or iToPos <= iArgStart) ;
            Function_Return False

        // Last non-blank before "to" = the argument's end; the gap before "to" is kept verbatim.
        Move (iToPos - 1) to iArgEnd
        While (iArgEnd >= iArgStart and (Mid(sOverFull, 1, iArgEnd) = CS_S or Mid(sOverFull, 1, iArgEnd) = Character(9)))
            Decrement iArgEnd
        Loop
        If (iArgEnd < iArgStart) ;
            Function_Return False

        // Rebuild on the RAW line: <indent/nose> + Move (Trim(<arg>)) + <original gap> to <dest>.
        Move (Left(sLine, (iTrimPos - 1)) + CS_Move + " (" + CS_Trim + "(" + Mid(sLine, (iArgEnd - iArgStart + 1), iArgStart) + "))" + Mid(sLine, CI_EOL, (iArgEnd + 1))) to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Replace command with the Replace() function.
        Example: Replace "," in sQty with "." -> Move (Replace(",", sQty, ".")) to sQty
        The command replaces the first occurrence only, and so does the Replace() function. Replaces(), which replaces all occurrences, would change what the code does, so it is never used.
        A one-line If statement keeps its condition: If (sSep = ".") Replace "," in sQty with "." is converted with the If kept.
        Calls to the Replace() and Replaces() functions are never changed; only the command is converted.
        The command also sets Found, strmark and strlen, which the Replace() function does not. If the code that follows uses that value before it is set again, the line is not changed. Instead, a comment "// TODO (DFRefactor): NOT converted - ..." is added at the end of the line, naming the value that is used.
        When the value is no longer used, the next run converts the line and removes the comment.
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Replace }
        { SummaryText = Changed: Replace command to function Replace }
        """ }
    Function ChangeReplaceCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bFound bVeto bMarked
        Integer iPos iStart iCmdPos iBefore iFindStart iFindEnd iInPos iVarStart iVarEnd iWithPos iNewStart iNewEnd
        tTokenizer TokenizerData
        String sOverFull sCh sVar

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End
        Get IsKeywordInLine "replace" TokenizerData.asLineTokens to bFound
        If (bFound = False) Begin
            Function_Return False
        End
        // The MASKED line (indentation + overstrike), position-aligned with sLine: a "replace",
        // "in" or "with" inside a string literal can never match.
        Move (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sOverFull

        // The COMMAND: a boundary-aware "Replace" FOLLOWED BY WHITESPACE. "Replace(" is the
        // modern function and is never taken as the command.
        Move 1 to iStart
        Move 0 to iCmdPos
        While (iCmdPos = 0)
            Get _FindKeywordPos sOverFull "Replace" True iStart to iPos
            If (iPos = 0) ;
                Function_Return False
            Move (Mid(sOverFull, 1, (iPos + 7))) to sCh
            If (sCh = CS_S or sCh = Character(9)) ;
                Move iPos to iCmdPos
            Else ;
                Move (iPos + 1) to iStart
        Loop
        // Command position: only whitespace, a ")" or a "]" may precede it - the one-line
        // "If (...)" and "[ind]" prefixes ride along untouched in the rebuilt line.
        Move (iCmdPos - 1) to iBefore
        While (iBefore >= 1 and (Mid(sOverFull, 1, iBefore) = CS_S or Mid(sOverFull, 1, iBefore) = Character(9)))
            Decrement iBefore
        Loop
        If (iBefore >= 1) Begin
            Move (Mid(sOverFull, 1, iBefore)) to sCh
            If (sCh <> ")" and sCh <> "]") ;
                Function_Return False
        End

        // <find> = from the first non-blank after "Replace" up to the bounded "in".
        Move (iCmdPos + 7) to iFindStart
        While (iFindStart <= Length(sOverFull) and (Mid(sOverFull, 1, iFindStart) = CS_S or Mid(sOverFull, 1, iFindStart) = Character(9)))
            Increment iFindStart
        Loop
        Get _FindKeywordPos sOverFull "in" True iFindStart to iInPos
        If (iInPos = 0 or iInPos <= iFindStart) ;
            Function_Return False
        Move (iInPos - 1) to iFindEnd
        While (iFindEnd >= iFindStart and (Mid(sOverFull, 1, iFindEnd) = CS_S or Mid(sOverFull, 1, iFindEnd) = Character(9)))
            Decrement iFindEnd
        Loop
        If (iFindEnd < iFindStart) ;
            Function_Return False

        // <var> = up to the bounded "with". It is both the source and the destination.
        Move (iInPos + 2) to iVarStart
        While (iVarStart <= Length(sOverFull) and (Mid(sOverFull, 1, iVarStart) = CS_S or Mid(sOverFull, 1, iVarStart) = Character(9)))
            Increment iVarStart
        Loop
        Get _FindKeywordPos sOverFull "with" True iVarStart to iWithPos
        If (iWithPos = 0 or iWithPos <= iVarStart) ;
            Function_Return False
        Move (iWithPos - 1) to iVarEnd
        While (iVarEnd >= iVarStart and (Mid(sOverFull, 1, iVarEnd) = CS_S or Mid(sOverFull, 1, iVarEnd) = Character(9)))
            Decrement iVarEnd
        Loop
        If (iVarEnd < iVarStart) ;
            Function_Return False

        // <new> = from after "with" to the last non-blank of the CODE (the masked line ends
        // where the code ends; the raw tail behind it - trailing comment included - is kept).
        Move (iWithPos + 4) to iNewStart
        While (iNewStart <= Length(sOverFull) and (Mid(sOverFull, 1, iNewStart) = CS_S or Mid(sOverFull, 1, iNewStart) = Character(9)))
            Increment iNewStart
        Loop
        Move (Length(sOverFull)) to iNewEnd
        While (iNewEnd >= iNewStart and (Mid(sOverFull, 1, iNewEnd) = CS_S or Mid(sOverFull, 1, iNewEnd) = Character(9)))
            Decrement iNewEnd
        Loop
        If (iNewEnd < iNewStart) ;
            Function_Return False

        // The command leaves Found, strmark and strlen behind and Replace() leaves all three
        // exactly as they were. While anything below still reads one of them, the line keeps its
        // legacy form and says why. The marker goes on the END of the line, so the positions
        // computed above (which all point into the code) stay valid either way.
        Get _SideProductVeto (&sLine) "replace" (&bMarked) to bVeto
        If (bVeto = True) ;
            Function_Return bMarked

        // Rebuild on the RAW line: <prefix> + Move (Replace(<find>, <var>, <new>)) to <var> + <raw tail>.
        Move (Mid(sLine, (iVarEnd - iVarStart + 1), iVarStart)) to sVar
        Move (Left(sLine, (iCmdPos - 1)) + CS_Move + " (Replace(" + Mid(sLine, (iFindEnd - iFindStart + 1), iFindStart) + ", " + sVar + ", " + Mid(sLine, (iNewEnd - iNewStart + 1), iNewStart) + ")) to " + sVar + Mid(sLine, CI_EOL, (iNewEnd + 1))) to sLine
        Function_Return True
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy Uppercase command with the Uppercase() function.
        Example: Uppercase sVal to sVal -> Move (Uppercase(sVal)) to sVal
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4531 | command: Uppercase }
        { SummaryText = Changed: Uppercase command to function Uppercase }
        """ }
    Function ChangeUppercaseCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get _SingleArgCommandToFunction (&sLine) CS_Uppercase to bChanged
        Function_Return bChanged
    End_Function

    { Published = True }
    { Description = """
        Replaces the legacy ZeroString command with the ZeroString() function.
        Example: ZeroString iLength to sParameter --> Move (ZeroString(iLength)) to sParameter
        { MethodType = eStandardFunction }
        { FnFamily = Command to function }
        { FnGroup = Modernization }
        { ModRecipe = 4532 | ZeroString }
        { SummaryText = Changed: ZeroString command to function }
        """ }
    Function ChangeZeroStringCommandToFunction String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Get SingleCommandSyntaxToFunction (&sLine) CS_ZeroString to bChanged
        Function_Return bChanged
    End_Function

