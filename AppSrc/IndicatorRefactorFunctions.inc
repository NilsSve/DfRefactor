// IndicatorRefactorFunctions.inc
//
// The INDICATOR family of refactoring functions, #Include'd into the oRefactorFuncLib
// object so they read and compile exactly as if they were written there.
//
// They belong together because they are one conversion split across several passes, and
// the engine knows it: selecting any of the converters makes
// cFunctionsDataDictionary.EnsureCompanionsSelected pull DeclareRefactoredIndicators in as
// a companion, and an eModernizeSelect run pulls DefineSelectMacro too. Changing one of
// these almost always means looking at the others.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read.

    { Published = True }
    { Description = """
        Replaces a legacy global Indicator declaration with a global Boolean variable. In DataFlex, an Indicator declaration is always global.
        The new declaration is protected by #IFNDEF, so running the function again does not add it twice, and it cannot clash with the same name declared by DeclareRefactoredIndicators (warning 4390), whatever the compile order.
        Example: Indicator User -> #IFNDEF User / Global_Variable Boolean User / #ENDIF (one block per name).
        This function fixes the "Indicator. Use Boolean" form of compiler message 4538, which is about the declaration. Message 4538 is also reported for other forms: "Indicate. Use Move command" and "...without parentheses" are about where an indicator is used, and are fixed by ChangeLegacyIndicators and ChangeSquareBracketsIndicators.
        { MethodType = eStandardFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4538 | Use Boolean }
        { SummaryText = Changed: Indicator declaration -> Global_Variable Boolean }
        """ }
    Function ChangeIndicatorToBoolean String ByRef sLine String sParameter Returns Boolean
        tTokenizer TokenizerData
        String sIndent sComment sBlock sName
        Integer i iLast

        Get pTokenizer to TokenizerData
        // Only a standalone global "Indicator <name> [more names]" declaration: the FIRST code token is
        // exactly "Indicator" and at least one name follows. The first-token gate ignores incidental
        // uses - "Move Indicator_State to x", a "Property Indicator ..." inside a class, comments, etc.
        If (TokenizerData.bIsInCommand = True or TokenizerData.bIsInImage = True) ;
            Function_Return False
        If (SizeOfArray(TokenizerData.asLineTokens) < 2) ;
            Function_Return False
        If (Lowercase(TokenizerData.asLineTokens[0]) <> "indicator") ;
            Function_Return False

        // A PINNED name (GROUP/ALL participant, or read by an unconverted 'use'd include) must keep its
        // 'Indicator X' declaration - its uses stay legacy (the pinned line converters leave them), so a
        // gb Global_Variable would be the wrong target and the legacy [X]/Indicate X sites would reference
        // an undefined indicator. If ANY declared name on the line is pinned, leave the whole line legacy
        // (splitting a multi-name 'Indicator A B' declaration is not worth the risk). (Nils 2026-07-09.)
        // Instead of a SILENT bail, say so in the source (Nils 2026-07-12: the kept declarations read
        // as converter misses, and the compiler re-nags 4538 on them every build): a same-line NOTE -
        // the strmark TODO pattern, idempotent for a line-based function via the marker guard - names
        // the why. Deep Scan skips marker-carrying lines, so the row stops re-appearing there too.
        Move (SizeOfArray(TokenizerData.asLineTokens) - 1) to iLast
        For i from 1 to iLast
            If (SearchArray(Uppercase(Trim(TokenizerData.asLineTokens[i])), pasPinnedIndicators(Self)) <> -1) Begin
                If (not(sLine contains "(DFRefactor)")) Begin
                    Move (sLine + "   // NOTE (DFRefactor): kept as Indicator on purpose - the name is read by legacy code left unconverted (a .MAC include, a #COMMAND body, a raw directive, or a GROUP/ALL Indicate the converter does not write), so a Boolean here would break those reads. The compiler's 4538 warning on this line is expected until those reads retire.") to sLine
                    Function_Return True
                End
                Function_Return False
            End
        Loop

        // Emit an #IFNDEF-guarded "Global_Variable Boolean" per name (one block each for "Indicator A B C").
        // The guard makes the declaration IDEMPOTENT: this declared indicator and the SAME name SYNTHESISED by
        // DeclareRefactoredIndicators (in files that only USE it) collapse to one declaration in any compile
        // order - the compiler keeps the first #IFNDEF that fires and skips the rest, so no duplicate-global
        // 4390. #IFNDEF <var> tests the declared Global_Variable, not just a #DEFINE (cf. cBaseFuncLib's
        // #IFNDEF ghoErrorTracker guard). The original trailing comment rides the first declaration line.
        Move TokenizerData.sIndentation to sIndent
        Move TokenizerData.sEndComment  to sComment
        Move "" to sBlock
        Move (SizeOfArray(TokenizerData.asLineTokens) - 1) to iLast
        For i from 1 to iLast
            If (sBlock <> "") ;
                Append sBlock C_NewLine
            Move TokenizerData.asLineTokens[i] to sName
            // gb-prefix (Nils 2026-07-05): the declared name must MATCH every converted use - all
            // emitters funnel through _IndicatorVarName (system booleans pass through unchanged).
            Get _IndicatorVarName sName to sName
            Append sBlock sIndent "#IFNDEF " sName C_NewLine
            Append sBlock sIndent "    Global_Variable Boolean " sName
            If (i = 1 and sComment <> "") ;
                Append sBlock CS_S sComment
            Append sBlock C_NewLine sIndent "#ENDIF"
        Loop
        Move sBlock to sLine
        Function_Return True
    End_Function

    /* THE OPENING HALF of a ';'-continued Indicate. Takes exactly this shape, on the RAW line (the
       tokenizer's fabricated expression tokens are no use here - they swallow the ';'):
           [<ind>] indicate <target> as <expr-start> ;        (the bracket part optional; [not X] / [~X] too)
       and emits
           If (<ind>) Move (<expr-start> ;
       remembering <target> in psPendingIndicateTarget for _ContinuedIndicateClose. The extra '(' the Move
       opens is closed there. Positions come from the MASKED line (same length as the raw one, literals
       overstruck), the text from the raw one. Refuses - False, line untouched - a GROUP line (no 'as'), a
       prefix that is not one plain bracket, nothing after 'as', a non-identifier target, and a SELECT the
       parameter has not opted in (the same gate as the single-line path). Names go through
       _IndicatorVarName like every other emitter, so gbX here matches gbX everywhere else. */
    Function _ContinuedIndicateOpen tTokenizer TokenizerData String sLine Boolean bModernizeSelect String ByRef sNewCode Returns Boolean
        String sRaw sMasked sPrefix sInner sTarget sAs sCond sW1 sW2 sCh
        Integer iInd iAs iPos iLen i iAsc
        Boolean bSkip

        Move "" to sNewCode
        If (bModernizeSelect = False) Begin
            Get _IndicatorIsNonRefactorable TokenizerData to bSkip
            If (bSkip = True) ;
                Function_Return False
        End
        Get _RemoveEndComment sLine to sRaw
        Move (RTrim(sRaw)) to sRaw
        If (Right(sRaw, 1) <> ";") ;
            Function_Return False
        Move (RTrim(Left(sRaw, (Length(sRaw) - 1)))) to sRaw               // drop the ';'
        // The masked twin, trimmed the same way - the positions found on it are applied to the raw text.
        Get _RemoveEndComment (TokenizerData.sIndentation + TokenizerData.sOverstrikeLine) to sMasked
        Move (RTrim(sMasked)) to sMasked
        If (Right(sMasked, 1) = ";") ;
            Move (RTrim(Left(sMasked, (Length(sMasked) - 1)))) to sMasked
        If (Length(sMasked) <> Length(sRaw)) ;                              // not the same text - belt
            Function_Return False
        Get _FindKeywordPos sMasked CS_Indicate True 1 to iInd
        If (iInd = 0) ;
            Function_Return False
        // Everything after 'indicate': '<target> as <expr-start>'
        Move (Trim(Mid(sRaw, (Length(sRaw) - iInd - Length(CS_Indicate) + 1), (iInd + Length(CS_Indicate))))) to sTarget
        Move (Pos(" ", sTarget)) to iPos
        If (iPos = 0) ;
            Function_Return False
        Move (Left(sTarget, (iPos - 1))) to sTarget
        Move (Length(sTarget)) to iLen
        If (iLen = 0) ;
            Function_Return False
        For i from 1 to iLen                                                 // a plain identifier, or nothing
            Move (Mid(sTarget, 1, i)) to sCh
            Move (Ascii(sCh)) to iAsc
            If (not((iAsc >= 65 and iAsc <= 90) or (iAsc >= 97 and iAsc <= 122) or (iAsc >= 48 and iAsc <= 57) or sCh = "_" or sCh = "$" or sCh = "#")) ;
                Function_Return False
        Loop
        Get _FindKeywordPos sMasked CS_As True (iInd + Length(CS_Indicate)) to iAs
        If (iAs = 0) ;
            Function_Return False
        Move (Trim(Mid(sRaw, (Length(sRaw) - iAs - Length(CS_As) + 1), (iAs + Length(CS_As))))) to sAs
        If (sAs = "") ;
            Function_Return False
        // The prefix: nothing, or ONE bracket - '[x]', '[not x]', '[~x]' (the odd '[ x]' spacing included).
        Move (Trim(Left(sRaw, (iInd - 1)))) to sPrefix
        Move "" to sCond
        If (sPrefix <> "") Begin
            If (Left(sPrefix, 1) <> "[" or Right(sPrefix, 1) <> "]") ;
                Function_Return False
            Move (Trim(Mid(sPrefix, (Length(sPrefix) - 2), 2))) to sInner
            If (sInner = "" or Pos("[", sInner) > 0) ;
                Function_Return False
            Move (Pos(" ", sInner)) to iPos
            If (iPos > 0) Begin
                Move (Lowercase(Left(sInner, (iPos - 1)))) to sW1
                Move (Trim(Mid(sInner, (Length(sInner) - iPos), (iPos + 1)))) to sW2
                If (sW1 <> "not" or sW2 = "" or Pos(" ", sW2) > 0) ;
                    Function_Return False
                Move ("(Not(" + _IndicatorVarName(Self, sW2) + "))") to sCond
            End
            Else If (Left(sInner, 1) = CS_Tilde) Begin
                Move (Trim(Mid(sInner, (Length(sInner) - 1), 2))) to sW2
                If (sW2 = "") ;
                    Function_Return False
                Move ("(Not(" + _IndicatorVarName(Self, sW2) + "))") to sCond
            End
            Else ;
                Move ("(" + _IndicatorVarName(Self, sInner) + ")") to sCond
        End
        Move TokenizerData.sIndentation to sNewCode
        If (sCond <> "") ;
            Move (sNewCode + CS_If + " " + sCond + " ") to sNewCode
        Move (sNewCode + CS_Move + " (" + sAs + " ;") to sNewCode
        If (TokenizerData.sEndComment <> "") ;
            Move (sNewCode + " " + TokenizerData.sEndComment) to sNewCode
        Set psPendingIndicateTarget to (_IndicatorVarName(Self, sTarget))
        Function_Return True
    End_Function

    /* THE CLOSING HALF: a target is in flight (psPendingIndicateTarget). A line that still ends with ';'
       is the statement's middle - passes through unchanged, target kept. The line that ENDS it gets
       ') to <target>' (before any end comment) and the target is cleared. A line that is NOT a
       continuation at all means the state is stale (a file that ended mid-statement, an isolated line):
       drop the target and leave the line alone - never append a 'to' to a statement of its own. */
    Function _ContinuedIndicateClose tTokenizer TokenizerData String sLine String ByRef sNewCode Returns Boolean
        String sCode sTarget

        Move "" to sNewCode
        Get psPendingIndicateTarget to sTarget
        If (TokenizerData.bIsContinuationLine = False) Begin
            Set psPendingIndicateTarget to ""
            Function_Return False
        End
        Get _RemoveEndComment sLine to sCode
        Move (RTrim(sCode)) to sCode
        If (Right(sCode, 1) = ";") ;
            Function_Return False
        Move (sCode + ") " + CS_To + " " + sTarget) to sNewCode
        If (TokenizerData.sEndComment <> "") ;
            Move (sNewCode + " " + TokenizerData.sEndComment) to sNewCode
        Set psPendingIndicateTarget to ""
        Function_Return True
    End_Function

    /* The full example list, moved out of {Description} on 2026-09-17: the tag stood at 2,172
       characters as written, a hair under the DF26 meta-tag size cliff (~2,200 as written / 1,984
       dedented - a silent compiler crash beyond it). The tag keeps a compact line of them.
       - Indicate Found as True --> Move True to Found
       - [Found] and [FindErr] indicator statements.
       - [Found| Command -> e.g. If Found Command
       - While [Not Found]   -> e.g. While (Not(Found))
       - [~Found] begin -> If (Not(Found)) Begin
       - [Found ~Found] Begin -> If (Found and Not(Found)) Begin
       - [Select] Indicate Select as Windowindex Eq Fieldindex --> Move (WindowIndex = FieldIndex) to Select
       - [Found] Indicate Found as Invoice.CustNum eq Customer.Number
             -> If (Found) Move (Invoice.CustNum eq Customer.Number) to Found
       - If [Not Found] Reread hTable -> If (Not(Found)) Reread hTable
       - Indicate X GROUP ANY [a b] -> Move (gba or gbb) to gbX (ALL = and; not / ~ negate a member; a
         second AND / OR clause joins in its own parentheses; an 'If (cond)' in front rides along).
       - A ';'-continued Indicate converts in two halves (the opening line cannot place 'to <target>'):
             [found] indicate found as ((A eq x) and ;       ->   If (found) Move (((A eq x) and ;
                        (B eq y) and (C eq z))               ->               (B eq y) and (C eq z))) to found
         Shapes the opener does not take (a GROUP line, an If in front, nothing after 'as') stay as they are. */
    { Published = True }
    { Description = """
        Replaces the legacy 'Indicate' command and indicators with expressions.
        Use it together with ChangeSquareBracketsIndicators. This function does most of the work, but it skips lines that contain Find, Send or Constrain; ChangeSquareBracketsIndicators converts those lines. Run both at the same time; this function then reports most of the changes.
        Examples: Indicate Found as True -> Move True to Found; [~Found] Begin -> If (Not(Found)) Begin; [Select] Indicate Select as A Eq B -> Move (A = B) to Select; If [Not Found] Reread hTable -> If (Not(Found)) Reread hTable; Indicate X GROUP ANY [a b] -> Move (gba or gbb) to gbX.
        An 'Indicate X as <expr>' statement that continues over several lines with ';' is converted across those lines.
        Limitations: at most two indicators within one pair of square brackets, for example [Found Select]. A GROUP line that follows a bracket, a legacy condition or a ';' is not changed.
        { MethodType = eStandardFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4538 | Use Move command | AutoFix }
        { ModRecipe = 4538 | without parentheses | AutoFix }
        { ModRecipe = 4535 | indicators in If statements | AutoFix }
        { ModRecipe = 4538 | indicators in If statements | AutoFix }
        { EnumList = "eLeaveSelect, eModernizeSelect" }
        { InitialValue = eLeaveSelect }
        { ParamHelp = eLeaveSelect keeps [SELECT] as-is (safe default). eModernizeSelect also needs DefineSelectMacro selected (it defines the SELECT macro). }
        { SummaryText = Changed: [Found] -> (Not(Found)) }
        """ }
    Function ChangeLegacyIndicators String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged bStartBracket bHasBracket bIndicateStart bIfStart bIfNotStart
        String sToken sOverstrikeLine sNot sTo sMove sIf sFirstCmd sSecondCmd sExpression sOrgLine sVarName sNewCode
        String sElse sIndent sMasked sRestCmd
        String sRawFirst sRawSecond sRawTo sRawIndTarget
        Integer iItem iSize iPos iLeftBracketNo iStart iEnd iBracketTokenCount
        Boolean bSkip bModernizeSelect
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Begin
            Function_Return False
        End

        /* 'Ind <indicator> [as] <condition>' IS Indicate. DataFlex 26's dafmac.pkg defines Ind as a
           macro that expands to 'Indicate !1 !2 ...' and warns "Obsolete command: Ind. Use Move" -
           so the line is converted as the Indicate line it expands to: the command word swapped on
           a copy, the copy re-tokenized and sent back through this function (the ';'-stripped copy
           below takes the same route). Before this the spelling was never taken, and the board
           called five such lines "inside macro Ind - not yours to change" (Nils 2026-09-20, a
           character-mode workspace: 'ind gbFlag True', 'ind gbFlag as (A = B)', 'ind Found False').
           The word is taken wherever a command stands - first on the line, after an Else, behind a
           leading '[...]' group, after an If condition (_IndCommandWordPos). Only the first was, until GitHub
           2026-10-06 (a DataFlex 3.2 program): behind a bracket the line went down the bracket path
           below, which knows no Ind, and '[ found] ind found as <a> eq <b>' came out as 'If (found)
           ind found as (<a> eq <b>) to', while '[~found] ind X False' lost its command word. A copy
           the conversion declines leaves the line as written, and the line is tokenized again, so the
           functions after this one read the line - not the copy. */
        Get _IndCommandWordPos (Trim(TokenizerData.sOverstrikeLine)) to iPos
        If (iPos > 0) Begin
            Move (iPos + Length(TokenizerData.sIndentation)) to iPos      // the masked line drops the indentation
            If (Lowercase(Mid(sLine, 3, iPos)) = "ind") Begin
                Move (Left(sLine, (iPos - 1)) + CS_Indicate + Right(sLine, (Length(sLine) - iPos - 2))) to sNewCode
                Get Tokenizer sNewCode to TokenizerData
                Get ChangeLegacyIndicators of Self (&sNewCode) sParameter to bChanged
                If (bChanged = True) ;
                    Move sNewCode to sLine
                Else ;
                    Get Tokenizer sLine to TokenizerData
                Function_Return bChanged
            End
        End

        // THE CLOSING HALF of a ';'-continued Indicate (see _ContinuedIndicateOpen below): a target is
        // in flight and THIS line continues the statement the opening line rewrote. Comes before the
        // pinned check on purpose - the opening line already passed it, and this line carries no
        // indicator of its own. Owns the line whatever it decides (a still-continuing line passes
        // through unchanged, but stays the statement's).
        If (psPendingIndicateTarget(Self) <> "") Begin
            Get _ContinuedIndicateClose TokenizerData sLine (&sNewCode) to bChanged
            If (bChanged = True) ;
                Move sNewCode to sLine
            Function_Return bChanged
        End

        // PINNED indicator (a GROUP/ALL participant, or a name read by an unconverted 'use'd include):
        // leave the line ENTIRELY legacy - converting it would decouple from the unconvertible reference
        // (Nils 2026-07-09, a legacy customer workspace: a '[grp_flag]' read whose write is 'indicate
        // grp_flag GROUP ANY [...]', and lines whose name is read by a 'use'd .MAC include). Empty = no-op.
        If (_IndicatorIsPinned(Self, TokenizerData)) ;
            Function_Return False

        /* AN ELSE IN FRONT (Nils 2026-10-06, "Yes, fix the Else case too"). 'Else <statement>' runs the
           statement as it would run standing alone, but the paths below write their line from its start
           and keep nothing in front of the Indicate or the bracket. Measured: 'Else Indicate X False' came
           out as 'Move (False) to gbX' - the value set every time - 'Else [found] Move 1 to iCount' as
           'Move (iCount) to (found)', 'Else [~found] Begin' as 'Move  Begin', and 'Else If [found] Indicate
           X True' as 'If (found) Move True to gbX'. A COPY of the statement, under the same indentation, is
           converted instead, and the Else goes back in front of whatever comes out - 'Else If (found) Move
           ...', the first line of a block, the opening line of a continued Move. An 'Else If ...' copy
           reaches the If paths with its If first on the line, where they read it. A GROUP statement stays as
           written: the pin scan (_ComputePinnedIndicators) asks _GroupIndicateToMove about the line as
           written, which refuses the Else, so the group's names stay indicators everywhere else in the file.
           A copy the conversion declines leaves the line as written, tokenized again for the functions after
           this one. */
        Get _ElseStatementCopy TokenizerData sLine True (&sElse) to sNewCode
        If (sNewCode <> "") Begin
            Move TokenizerData.sIndentation to sIndent
            Move (sIndent + sNewCode) to sNewCode
            Get Tokenizer sNewCode to TokenizerData
            Move (Lowercase(TokenizerData.sOverstrikeLine)) to sMasked
            Move False to bChanged
            If ((_FindKeywordPos(Self, sMasked, CS_Indicate, True, 1) = 0) or (_FindKeywordPos(Self, sMasked, "group", True, 1) = 0)) ;
                Get ChangeLegacyIndicators of Self (&sNewCode) sParameter to bChanged
            If (bChanged = True) ;
                Move (sIndent + sElse + " " + LTrim(sNewCode)) to sLine
            Else ;
                Get Tokenizer sLine to TokenizerData
            Function_Return bChanged
        End

        /* TWO BOOLEANS IN THE LEADING BRACKETS (2026-11-01) - '[A][B]', '[A] [B]', '[A B]' (_LeadingTwoBooleans).
           Taken here when the statement is an Indicate - the stacked-bracket composer below converts it - or one word,
           Begin, Loop, Break: as two brackets, so '[A][B]', which the tokenizer read as ONE indicator 'A][B' (gbAB, a
           name nothing declares), is read as what it means. Any other statement is ChangeSquareBracketsIndicators'
           ('[A B] Clear Inv' came out as 'If (A and B) Clear' here - the arguments lost), which converts it whole.
           A copy the conversion declines leaves the line as written, tokenized again. */
        Get _LeadingTwoBooleans sLine True (&sRestCmd) to sNewCode
        If (sNewCode <> "") Begin
            Move (Trim(Replaces(Character(9), _RemoveEndComment(Self, sRestCmd), " "))) to sRestCmd
            If (Lowercase(_NthWord(Self, sRestCmd, 1)) <> Lowercase(CS_Indicate) and Pos(" ", sRestCmd) > 0) ;
                Function_Return False
            If (sNewCode <> sLine) Begin
                Get Tokenizer sNewCode to TokenizerData
                Get ChangeLegacyIndicators of Self (&sNewCode) sParameter to bChanged
                If (bChanged = True) ;
                    Move sNewCode to sLine
                Else ;
                    Get Tokenizer sLine to TokenizerData
                Function_Return bChanged
            End
        End

        // A CONTINUED 'Indicate' STATEMENT (Nils 2026-09-17, a 2005-era file: '[found] indicate found as ((A eq x)
        // and ;' with the rest of the expression on the NEXT physical line). The Move form puts 'to <target>' at
        // the END of the statement, and this function sees ONE line - so the single-line rewrite ended the first
        // line with 'and ); to found' (the unswallowed ';' stranded mid-line) and left the continuation dangling
        // with an unmatched ')'. Converted in TWO halves instead: this line becomes 'If (ind) Move (<expr> ;' and
        // the target is carried (psPendingIndicateTarget) to the line that ends the statement, which closes it
        // with ') to <target>' - see _ContinuedIndicateOpen / _ContinuedIndicateClose. A shape the opener does not
        // take (a GROUP line, an If in front, nothing after 'as') stays verbatim. Detected on the MASKED line, so
        // a string literal never trips it; the 'if [X];' shape below carries no Indicate word and keeps its own path.
        Get _HasLineEndSemiColon TokenizerData.sOverstrikeLine to bSkip
        If (bSkip = True and (_FindKeywordPos(Self, TokenizerData.sOverstrikeLine, CS_Indicate, True, 1) > 0)) Begin
            Get _ParameterIsEnum sParameter "eModernizeSelect" eModernizeSelect to bModernizeSelect
            Get _ContinuedIndicateOpen TokenizerData sLine bModernizeSelect (&sNewCode) to bChanged
            If (bChanged = True) ;
                Move sNewCode to sLine
            Function_Return bChanged
        End

        // A ';' line-continuation right after ']' ('if [gibDebugMode];', Begin on the NEXT line - LegacyApp
        // GFUNC.INC) leaves ']' not followed by whitespace, so the BooleanIndicator parse drops the bracket and
        // the in-place swap emits 'if ;' (malformed -> reverted -> never converts). Convert the ';'-stripped COPY
        // (recurse - the clean line no longer ends with ';', so no re-entry) and, on success, re-append the ';'.
        // Guarded to If-lines with a bracket and NO end comment (re-splicing a comment is not worth the risk); the
        // leading-'[' '[FINDERR];' path handles its own ';' via _UnswallowSemicolon. (Nils 2026-07-02: if[X];==if[X])
        Get _HasLineEndSemiColon TokenizerData.sOverstrikeLine to bSkip
        If (bSkip = True and TokenizerData.sEndComment = "" and TokenizerData.bHasIfCommand = True ;
            and (Pos("[", TokenizerData.sOverstrikeLine) > 0)) Begin
            Move (RTrim(sLine)) to sNewCode
            Move (RTrim(Left(sNewCode, Length(sNewCode) - 1))) to sNewCode      // drop the trailing ';'
            Get Tokenizer sNewCode to TokenizerData                             // re-tokenize the clean copy (sets pTokenizer)
            Get ChangeLegacyIndicators of Self (&sNewCode) sParameter to bChanged
            If (bChanged = True) ;
                Move (RTrim(sNewCode) + ";") to sLine
            Function_Return bChanged
        End

        Get HasBracket TokenizerData.BooleanIndicator to bHasBracket
        If (TokenizerData.BooleanIndicator.bHasIndicateCommand = False and bHasBracket = False) Begin
            // 'If (paren-cond) Indicate <target> ...' (Nils 2026-07-08, real legacy workspace): a
            // PARENTHESISED If-condition makes the expression extractor swallow the whole tail
            // after 'If' into ONE pseudo-expression token ('((cond) indicate X as ...)'), so there
            // is no clean Indicate token and bHasIndicateCommand reads False - the line used to
            // fall out RIGHT HERE unconverted, and the file-level gb-rename (PASS 2b in
            // DeclareRefactoredIndicators) then renamed the Indicate TARGET anyway = 'Indicate
            // gb...' 4345 compile error. Detect the Indicate WORD on the masked overstrike line
            // instead and compose the one-line guarded Move; _ComposeIfCondIndicate returns ""
            // for every shape it does not fully understand -> unchanged (False), never the
            // Case-path mangle. The Find/Send/Constrain skip mirrors the main-path guard below
            // (those lines belong to ChangeSquareBracketsIndicators' sweep).
            If (TokenizerData.bHasIfCommand = True and ;
                (Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Indicate) + CS_S))) Begin
                If (Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Find) + CS_S) or ;
                    Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Send) + CS_S) or ;
                    Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Constrain) + CS_S)) Begin
                    Function_Return False
                End
                Get _ParameterIsEnum sParameter "eModernizeSelect" eModernizeSelect to bModernizeSelect
                Get _ComposeIfCondIndicate TokenizerData bModernizeSelect (&sRawIndTarget) to sNewCode
                If (sNewCode <> "") Begin
                    // gb-prefix the composed line's indicator references (condition read AND
                    // Move target when they carry the same name) - this path returns before
                    // the shared exit post-process at the bottom.
                    Get _PrefixIndicatorRefs sNewCode sRawIndTarget to sNewCode
                    Move sNewCode to sLine
                    Function_Return True
                End
            End
            Function_Return False
        End

        // SELECT-handling gate. By default we respect CS_NonRefactorableIndicators and skip
        // lines whose indicator has no valid modern bare form, leaving the harmless [...]
        // warning - bare-ifying e.g. SELECT would turn that warning into a compile error.
        // The user opts in with eModernizeSelect; the companion DefineSelectMacro then defines the SELECT
        // macro in the file itself (an IFNDEF-guarded '#Replace SELECT' shim), so the bare Select compiles.
        // sParameter arrives as the enum NAME from the UI combo ("eModernizeSelect") or as
        // the numeric VALUE from tests - resolve via _ParameterIsEnum; a bare Move of the
        // name into the Integer enum left the gate at eLeaveSelect, so the opt-in never
        // worked from the UI (2026-06-10). NO num_arguments guard: it is unreliable here
        // (nested sends/dynamic engine dispatch can clobber it), and an omitted parameter
        // arrives as "" which _ParameterIsEnum already treats as no-match.
        Get _ParameterIsEnum sParameter "eModernizeSelect" eModernizeSelect to bModernizeSelect
        If (bModernizeSelect = False) Begin
            Get _IndicatorIsNonRefactorable TokenizerData to bSkip
            If (bSkip = True) ;
                Function_Return False
        End

        // Use sOverstrikeLine so string literal content cannot trigger a false-positive match.
        If (Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Find) + CS_S) or ;
            Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Send) + CS_S) or ;
            Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Constrain) + CS_S)) Begin
            Function_Return False
        End

        Move (SearchArray("GROUP", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            /* THE GROUP FORM HAS AN EXACT MOVE (2026-09-13, Nils: "how difficult would it be to
               resolve/refactor such lines as well?"): 'Indicate X GROUP ANY [a b]' is 'Move (gba or gbb)
               to gbX', ALL is 'and', 'not' / '~' negate a member, a second AND / OR ANY|ALL clause joins
               in its own parentheses, an 'If (cond)' in front rides along. _GroupIndicateToMove returns
               False - the line stays as it was - for a bracket ahead of it, a legacy condition, a
               continued line; and the pin computation asks the same function, so such a line still
               keeps its names legacy. Until today this guard refused EVERY group line and the pin then
               froze every participant across the file: 23 rows of one report view behind one line. */
            Get _GroupIndicateToMove (Trim(TokenizerData.sOverstrikeLine)) TokenizerData.sIndentation TokenizerData.sEndComment (&sNewCode) to bChanged
            If (bChanged = True) ;
                Move sNewCode to sLine
            Function_Return bChanged
        End
        Move (SearchArray("ALL", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            Function_Return False
        End
        // 'Indicate <ind> STATUS <df_file>' (the buffer-status form, docs form 6): the
        // missing-'as' fallback in the Case rebuild below takes the LAST token and would emit
        // 'Move (<df_file>) to (<ind>)' - a silent semantic corruption (assigns the file number
        // instead of the buffer state). No one-line Move equivalent exists, so leave the line
        // (and its warning) alone. Gated on a present Indicate command so a variable that merely
        // happens to be NAMED 'status' on a bracket line does not skip its bracket conversion.
        If (TokenizerData.BooleanIndicator.bHasIndicateCommand = True) Begin
            Move (SearchArray("STATUS", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem <> -1) Begin
                Function_Return False
            End
        End

        // 'not [X]' (word 'not' OUTSIDE the bracket, e.g. 'If not [Found]') - the tokeniser captures 'not' as the
        // boolean and mangles the bracket, so the plain paths below emit a dangling '(not)' (LegacyApp TIDR/over051).
        // Handle it HERE, AFTER the SELECT / Find-Send / GROUP / ALL guards so those still win ('not [SELECT]' was
        // already left alone by the SELECT gate). For an If line, normalize the CLEAN single 'not [<name>]' to
        // '[~X]' - STRING-based via _NotBracketToTilde, because the tokens drop the bracket so a token check can't
        // see it - then re-tokenize, so from here it is handled EXACTLY like 'If [~X]' / 'If [X]' (the in-place swap
        // below -> 'If (Not(X))', test 60). A compound / unclean 'not [...]' returns "" and falls through (the
        // malformed-check reverts any mangle). Non-If 'not [X]' (While/Until) is LEFT UNCHANGED via the old skip -
        // only the If path is verified, and leaving it keeps the harmless [...] warning, not a broken '(not)'.
        // (Nils 2026-07-02: 'if not [X]' should behave like 'if [X]'.)
        If (TokenizerData.bHasIfCommand = True) Begin
            Get _NotBracketToTilde sLine TokenizerData.sOverstrikeLine to sNewCode
            If (sNewCode <> "" and sNewCode <> sLine) Begin
                Move sNewCode to sLine
                Get Tokenizer sLine to TokenizerData        // '[~X]' now; the swap below converts it to '(Not(X))'
            End
        End
        Else Begin
            Get _HasNotBeforeBracketIndicator TokenizerData to bSkip
            If (bSkip = True) ;
                Function_Return False                       // non-If 'not [X]' -> unchanged (no '(not)' mangle)
        End

        // gb-PREFIX SUPPORT (Nils 2026-07-05): capture the RAW indicator names here - AFTER the guards
        // and the possible '[~X]' re-tokenize above, BEFORE any converting path - so EVERY emitting exit
        // (the two composed-block returns below AND the shared exit at the bottom) can rename them on its
        // FINAL line via _PrefixIndicatorRefs. They must stay raw in between: the bIfStart dispatch
        // searches the ORIGINAL line/tokens BY these names. ONLY BRACKETED members are captured - an
        // unbracketed First/To can be a NON-indicator ('[Not Found] Move iA to iB' puts the plain
        // destination iB in ToBoolean; 'If dDate LE ... Indicate X ...' puts the condition operand dDate
        // in FirstBoolean). The unbracketed indicator that IS always renamed - the Indicate TARGET - is
        // captured from the token stream instead (the composed-block + leading-bracket paths emit it from
        // the tokens, not from the struct).
        Move "" to sRawFirst
        Move "" to sRawSecond
        Move "" to sRawTo
        If (TokenizerData.BooleanIndicator.FirstBoolean.bHasBracket = True) ;
            Move TokenizerData.BooleanIndicator.FirstBoolean.sCode  to sRawFirst
        If (TokenizerData.BooleanIndicator.SecondBoolean.bHasBracket = True) ;
            Move TokenizerData.BooleanIndicator.SecondBoolean.sCode to sRawSecond
        If (TokenizerData.BooleanIndicator.ToBoolean.bHasBracket = True) ;
            Move TokenizerData.BooleanIndicator.ToBoolean.sCode     to sRawTo
        Move "" to sRawIndTarget
        Move (SearchArray(CS_Indicate, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1 and (iItem + 1 < SizeOfArray(TokenizerData.asLineTokens))) Begin
            Get ReplaceBrackets TokenizerData.asLineTokens[iItem + 1] to sRawIndTarget
        End

        // ANY no-bracket 'If <cond> Indicate ...' line with a clean Indicate token goes through
        // the composer - the Case rebuild below has now garbled THREE shapes of this family
        // (Nils 2026-07-09, identifiers generalized): the with-'as' '&'-window form
        // ('if (smaller) indicate smaller AS w_end& LE (day_end+1440)' -> 'if (gbsmaller) Move
        // indicate to gbsmaller'; the BooleanIndicator parse mis-fills Second with the target)
        // and the no-'as' leading-NOT form ('IF NOT tmp_state IN "..." INDICATE sta_flag FALSE'
        // -> 'IF (NOT) Move FALSE to gbsta_flag'; the parse captures the bare 'not' as the whole
        // condition). The composer handles both twins of every shape it understands and returns
        // "" for the rest -> UNCHANGED (False), never the Case mangle. Bracket-condition If+
        // Indicate lines ('If [Found] Indicate ...') keep the Case path - it handles them.
        If (bHasBracket = False and TokenizerData.bHasIfCommand = True and ;
            TokenizerData.BooleanIndicator.bHasIndicateCommand = True) Begin
            Get _FindKeywordPos TokenizerData.sOverstrikeLine CS_Indicate True 1 to iPos
            If (iPos > 0) Begin
                Get _ParameterIsEnum sParameter "eModernizeSelect" eModernizeSelect to bModernizeSelect
                Get _ComposeIfCondIndicate TokenizerData bModernizeSelect (&sRawIndTarget) to sNewCode
                If (sNewCode <> "") Begin
                    Get _PrefixIndicatorRefs sNewCode sRawIndTarget to sNewCode
                    Move sNewCode to sLine
                    Function_Return True
                End
                Function_Return False
            End
        End

        // A LEADING bracket indicator + an explicit If + an Indicate command on ONE line (e.g.
        // '[Found] If sResult ne "" Indicate Found as StatLog.Function_Name eq sData') is a 3-way compound
        // the plain Case logic below cannot compose (it mangled such lines into e.g.
        // "If Indicate (Found) to Found"). Build an explicit guarded block instead:
        //     If (<indicator> and (<if-condition>)) Begin
        //         Move (<indicate-expr>) to <indicate-target>
        //     End
        // _ComposeBracketIfIndicateBlock returns "" for shapes it will NOT touch (compound bracket, or the
        // rarer no-"as" Indicate) - those fall through unchanged (no corruption). Placed AFTER the SELECT /
        // Find-Send-Constrain / GROUP / ALL guards so those protections win. Each piece IS still supported
        // alone elsewhere: bracket+If (test 38), If+Indicate (test 37), If-condition-bracket+Indicate (test 6).
        // Indicate is detected via the overstrike line ("indicate " - strings are masked there, so it only
        // matches a real command), NOT BooleanIndicator.bHasIndicateCommand: that flag keys off asLineTokens,
        // which a PARENTHESISED If-condition leaves without a clean "Indicate" token, so it read False and the
        // line fell through to the half-done old path.
        If (SizeOfArray(TokenizerData.asLineTokens) > 0) Begin
            If (Left(TokenizerData.asLineTokens[0], 1) = "[" and ;
                TokenizerData.bHasIfCommand = True and ;
                (Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Indicate) + CS_S))) Begin
                Get _ComposeBracketIfIndicateBlock TokenizerData to sNewCode
                If (sNewCode <> "") Begin
                    // gb-prefix the composed block's indicator references - this path returns
                    // BEFORE the shared exit post-process at the bottom.
                    Get _PrefixIndicatorRefs sNewCode sRawFirst     to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawSecond    to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawTo        to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawIndTarget to sNewCode
                    Move sNewCode to sLine
                    Function_Return True
                End
                Function_Return False
            End
        End

        // TWO leading brackets + Indicate ('[Found] [~X] Indicate Found as ...', 2026-10-31): the bracket path read
        // the second bracket as the target - see _ComposeStackedBracketIndicate. Returns before the shared exit, so
        // the indicator references are gb-prefixed here, as the composers below do.
        If (SizeOfArray(TokenizerData.asLineTokens) > 1) Begin
            If (Left(TokenizerData.asLineTokens[0], 1) = "[" and Left(TokenizerData.asLineTokens[1], 1) = "[") Begin
                Get _ComposeStackedBracketIndicate TokenizerData to sNewCode
                If (sNewCode <> "") Begin
                    Get _PrefixIndicatorRefs sNewCode sRawFirst     to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawSecond    to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawTo        to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawIndTarget to sNewCode
                    Move sNewCode to sLine
                    Function_Return True
                End
            End
        End

        // [bracket] Indicate X <value> with NO "as" (e.g. '[FINDERR] Indicate HITTAT FALSE'): the old
        // bStartBracket -> _ChangeLegacyIndicators_Sub path reuses the BRACKET indicator as the Move source
        // ('If (FINDERR) Move (FINDERR)'), dropping the real target + value. _ComposeBracketNoAsIndicate builds
        // the correct one-line 'If (cond) Move (value) to target'; it returns "" for the with-"as" form (the
        // existing path composes that correctly) and every other shape - those fall through unchanged. The
        // [bracket] If ... Indicate compound is already consumed above.
        If (SizeOfArray(TokenizerData.asLineTokens) > 0) Begin
            If (Left(TokenizerData.asLineTokens[0], 1) = "[") Begin
                Get _ComposeBracketNoAsIndicate TokenizerData to sNewCode
                If (sNewCode <> "") Begin
                    // gb-prefix the composed line's indicator references - this path returns
                    // BEFORE the shared exit post-process at the bottom.
                    Get _PrefixIndicatorRefs sNewCode sRawFirst     to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawSecond    to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawTo        to sNewCode
                    Get _PrefixIndicatorRefs sNewCode sRawIndTarget to sNewCode
                    Move sNewCode to sLine
                    Function_Return True
                End
            End
        End

        // Note: a bare-ified [Select] (eModernizeSelect) needs the SELECT macro defined at the top of the
        // file. That is the companion DefineSelectMacro's job (an eOtherFunction run after this line-by-line
        // pass): it splices an IFNDEF-guarded '#Replace SELECT' shim - NOT a 'Use OldFMACCommands.pkg' line
        // (that only makes REPORT available). It SCANS the rewritten file for the bare Select rather than
        // relying on a flag set here - the engine resets per-function state before it runs, so a flag could
        // not survive.

        // Has If-statement?
        Move (TokenizerData.bHasIfCommand = True) to bIfStart
        If (bIfStart = True) Begin
            Move (SearchArray(CS_If, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem <> -1) Begin
                Move TokenizerData.asLineTokens[iItem] to sIf
            End
        End
        Else Begin
            Move CS_If to sIf
        End

        // Has Move-statement?
        Move (SearchArray(CS_Move, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            Move TokenizerData.asLineTokens[iItem] to sMove
        End
        Else Begin
            Move CS_Move to sMove
        End
        Move TokenizerData.FirstLeftCommand.sCode  to sFirstCmd
        Move TokenizerData.SecondLeftCommand.sCode to sSecondCmd

        // Has To-statement?
        Move (SearchArray(CS_To, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            Move TokenizerData.asLineTokens[iItem] to sTo
        End
        Else Begin
            Move CS_To to sTo
        End

        Move sLine to sOrgLine
        Move 0 to iItem
        Move TokenizerData.asLineTokens[iItem] to sToken
        // Starts with a indicator bracket?
        Move (Left(sToken, 1) = "[") to bStartBracket
        // A leading 'Ifnot [indicator] <rest>' ('ifnot [seqeof] begin') is NOT flagged as an If command -
        // bHasIfCommand keys off 'If', not 'Ifnot' - so without this it falls into the Case rebuild below, which
        // drops the trailing part ('begin') and orphans the matching 'end' (4348 'Unresolved control block' +
        // 4326 stack-pop, cascading bogus 'Undefined symbol ~' at downstream End_Objects). Route it through the
        // SAME surgical in-place bracket swap as 'If [indicator] <rest>', then finish the swapped 'ifnot (X)' as
        // 'If (Not(X))' (_FinishLeadingIfNot): 'ifnot [seqeof] begin' -> 'If (Not(seqeof)) begin'.
        Move (Lowercase(Trim(sToken)) = "ifnot") to bIfNotStart
        Move CS_Not to sNot

        // Get the "Not" keyword:
        If (TokenizerData.BooleanIndicator.FirstBoolean.bHasNot  = True or ;
            TokenizerData.BooleanIndicator.SecondBoolean.bHasNot = True or ;
            TokenizerData.BooleanIndicator.ToBoolean.bHasNot     = True or ;
            TokenizerData.BooleanIndicator.AsBoolean.bHasNot     = True) Begin
            Move (SearchArray("[not", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem = -1) Begin
                Move (Pos(("[" + CS_Tilde), TokenizerData.sLine)) to iItem
                If (iItem = 0) Begin
                    Move -1 to iItem
                End
                Else If (iItem > 0) Begin
                    Move -1 to iItem
                End
            End
            If (iItem <> -1) Begin
                Get ReplaceBrackets TokenizerData.asLineTokens[iItem] to sNot
            End
        End

        // Has an "Indicate" command?
        Move (SearchArray(CS_Indicate, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        Move (iItem <> -1) to bIndicateStart

        // Plain "If [indicator] <rest>" with NO Indicate command (e.g. "If [Found] Begin"): the
        // Case-based reconstruction further down rebuilds the line from the boolean pieces and drops
        // the trailing part, collapsing "If [Found] Begin" into just "If". Handle this case the SAME
        // surgical way ChangeSquareBracketsIndicators does - swap each [indicator] for its expression
        // IN PLACE so the rest of the line (the Begin / command / comment) survives untouched. Run
        // this BEFORE the sCode paren-wrapping below, so ConvertBracketIndicatorsToExpression sees the
        // RAW indicator tokens it expects (pre-wrapping them would double the parentheses). A line that
        // STARTS with a bracket is left to the bStartBracket sub (it parenthesises Move operands), and a
        // line that carries an Indicate command still needs the full rebuild below.
        If (bStartBracket = False and (bIfStart = True or bIfNotStart = True) and bIndicateStart = False) Begin
            Move 0 to iBracketTokenCount
            Move (SizeOfArray(TokenizerData.asLineTokens) - 1) to iSize
            For iItem from 0 to iSize
                If (Left(TokenizerData.asLineTokens[iItem], 1) = "[") Begin
                    Increment iBracketTokenCount
                End
            Loop
            Move TokenizerData.sOverstrikeLine to sOverstrikeLine
            Move 1 to iLeftBracketNo
            While (Pos("[", sOverstrikeLine) > 0 and iLeftBracketNo <= iBracketTokenCount)
                Move (Pos("[", sOverstrikeLine)) to iStart
                Move (Pos("]", sOverstrikeLine)) to iEnd
                Move (Mid(sOverstrikeLine, (iEnd - iStart - 1), (iStart + 1))) to sVarName
                Get ConvertBracketIndicatorsToExpression iLeftBracketNo TokenizerData to sExpression
                Increment iLeftBracketNo
                // FALLBACK (Nils 2026-07-03, LegacyApp INVC0183.rv 'If  [FINDERR]'): a DOUBLE space before the bracket
                // leaves FirstBoolean.bHasBracket un-set, so ConvertBracketIndicatorsToExpression returns "" - which
                // would DELETE the bracket ('If  Begin', a conditionless If the malformed-check reverts, leaving the
                // line unconverted). For a plain single-word indicator, parenthesise the raw name instead; compound
                // forms (space / tilde / nested bracket in the name) still fall through to the safe revert.
                If (Trim(sExpression) = "" and Trim(sVarName) <> "" and (Pos(" ", Trim(sVarName)) = 0) and (Pos("~", sVarName) = 0) and (Pos("[", sVarName) = 0)) ;
                    Move ("(" + _IndicatorVarName(Self, Trim(sVarName)) + ")") to sExpression
                If (sVarName <> "") Begin
                    Move (Replace("[" + sVarName + "]", sOverstrikeLine, sExpression)) to sOverstrikeLine
                End
            Loop
            Get RestoreOverstrikeLineValues sOverstrikeLine TokenizerData to sOverstrikeLine
            Get AssembleOutputLine sOverstrikeLine TokenizerData to sLine
            // Same safety net as the Case path below (this in-place [indicator] swap has its OWN return, so it
            // would otherwise bypass it): the swap can swallow a ';' line-continuation into the expression -
            // 'If [Found]; Begin' -> 'If (Found;); Begin' (err 52; LegacyApp LegacyAppFUNC.INC / GVAR.INC). First move an
            // INTRODUCED ';)' out to ');' (a valid conversion), then revert only the truly broken shapes.
            Get _UnswallowSemicolon sLine sOrgLine to sLine
            // A leading 'ifnot': finish the swapped 'ifnot (X)' as 'If (Not(X))' - see _FinishLeadingIfNot. Done
            // BEFORE the malformed check, so the line that is checked is the line that is written.
            If (bIfNotStart = True and sLine <> sOrgLine) ;
                Get _FinishLeadingIfNot sLine to sLine
            Get _IndicatorLineIsMalformed sLine sOrgLine to bChanged
            If (bChanged = True) Begin
                Move sOrgLine to sLine
                Function_Return False
            End
            Function_Return (sLine <> sOrgLine)
        End

        // Add "Not" operator and add paranthesis to boolean expressions/variables;
        If (TokenizerData.BooleanIndicator.FirstBoolean.bHasNot = True) Begin
            Move ("(" + sNot + "(" + TokenizerData.BooleanIndicator.FirstBoolean.sCode + "))") to TokenizerData.BooleanIndicator.FirstBoolean.sCode
        End
        Else If (TokenizerData.BooleanIndicator.FirstBoolean.sCode <> "" and Left(TokenizerData.BooleanIndicator.FirstBoolean.sCode, 1) <> "(") Begin
            Move ("(" + TokenizerData.BooleanIndicator.FirstBoolean.sCode + ")") to TokenizerData.BooleanIndicator.FirstBoolean.sCode
        End
        If (TokenizerData.BooleanIndicator.SecondBoolean.bHasNot = True) Begin
            Move ("(" + sNot + "(" + TokenizerData.BooleanIndicator.SecondBoolean.sCode + "))") to TokenizerData.BooleanIndicator.SecondBoolean.sCode
        End
        Else If (Left(TokenizerData.BooleanIndicator.SecondBoolean.sCode, 1) <> "(" and Right(TokenizerData.BooleanIndicator.SecondBoolean.sCode, 1) <> ")") Begin
            If (TokenizerData.BooleanIndicator.SecondBoolean.sCode <> "") Begin
                Move ("(" + TokenizerData.BooleanIndicator.SecondBoolean.sCode + ")") to TokenizerData.BooleanIndicator.SecondBoolean.sCode
            End
        End
        If (TokenizerData.BooleanIndicator.ToBoolean.bHasNot = True) Begin
            Move ("(" + sNot + "(" + TokenizerData.BooleanIndicator.ToBoolean.sCode + "))") to TokenizerData.BooleanIndicator.ToBoolean.sCode
        End
        If (Left(TokenizerData.BooleanIndicator.ToBoolean.sCode, 1) <> "(" and Right(TokenizerData.BooleanIndicator.ToBoolean.sCode, 1) <> ")") Begin
            If (TokenizerData.BooleanIndicator.ToBoolean.sCode <> "" and not(TokenizerData.BooleanIndicator.ToBoolean.sCode contains CS_S)) Begin
                Move ("(" + TokenizerData.BooleanIndicator.ToBoolean.sCode + ")") to TokenizerData.BooleanIndicator.ToBoolean.sCode
            End
        End
        If (TokenizerData.BooleanIndicator.AsBoolean.bHasNot = True) Begin
            Move ("(" + sNot + "(" + TokenizerData.BooleanIndicator.AsBoolean.sCode + "))") to TokenizerData.BooleanIndicator.AsBoolean.sCode
        End
        If (Left(TokenizerData.BooleanIndicator.AsBoolean.sCode, 1) <> "(" and Right(TokenizerData.BooleanIndicator.AsBoolean.sCode, 1) <> ")") Begin
            If (TokenizerData.BooleanIndicator.AsBoolean.sCode <> "") Begin
                Move ("(" + TokenizerData.BooleanIndicator.AsBoolean.sCode + ")") to TokenizerData.BooleanIndicator.AsBoolean.sCode
            End
        End

        Case Begin
            // This was too much code, so it was broken out to a helper-function (sub):
            Case (bStartBracket = True)
                Get _ChangeLegacyIndicators_Sub TokenizerData TokenizerData.sOverstrikeLine (&bChanged) to sOverstrikeLine
                Case Break

            // 'If [False] Indicate Select as Windowindex Eq Fieldindex // Comment'
            // 'If [not found] Move (Windowindex Eq Fieldindex) to Select // Comment'
            // 'If dDate LE '01/01/1984' Indicate ERROR_DATE True'
            Case (bIfStart = True)
                Move sIf to sOverstrikeLine
                Move TokenizerData.BooleanIndicator.FirstBoolean.sCode to sToken
                Get ReplaceParanthesis sToken to sToken
                Move (Pos(Lowercase(sToken), Lowercase(Trim(sLine)))) to iPos
                If (iPos < TokenizerData.SecondLeftCommand.iStartPos) Begin
                    Move TokenizerData.BooleanIndicator.SecondBoolean.sCode to sToken
                    Move (SearchArray(sToken, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
                    If (iItem = -1) Begin
                        Get ReplaceParanthesis sToken to sToken
                        Move (SearchArray(sToken, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
                    End
                    If (iItem <> -1) Begin
                        Increment iItem
                        If (iItem <= SizeOfArray(TokenizerData.asLineTokens)) Begin
                            Move TokenizerData.asLineTokens[iItem] to sToken
                            If (Lowercase(sToken) = Lowercase(CS_As)) Begin
                                Increment iItem
                                Move TokenizerData.asLineTokens[iItem] to sToken
                            End
                        End
                        If (Lowercase(sToken) = Lowercase(CS_To)) Begin
                            Increment iItem
                            Move TokenizerData.asLineTokens[iItem] to sToken
                            Append sOverstrikeLine CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode CS_S sMove
                            Move TokenizerData.BooleanIndicator.SecondBoolean.sCode to sExpression
                            Append sOverstrikeLine CS_S sExpression CS_S sTo CS_S sToken
                        End
                        Else Begin
                            Append sOverstrikeLine CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode CS_S sMove
                            Move TokenizerData.BooleanIndicator.SecondBoolean.sCode to sExpression
                            Get ReplaceParanthesis sExpression to sExpression
                            Append sOverstrikeLine CS_S sToken CS_S sTo CS_S sExpression
                        End
                    End
                End
                Else Begin
                    Append sOverstrikeLine CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode
                    If (TokenizerData.BooleanIndicator.AsBoolean.sCode <> "") Begin
                        Append sOverstrikeLine CS_S sMove CS_S TokenizerData.BooleanIndicator.AsBoolean.sCode
                        Move TokenizerData.BooleanIndicator.SecondBoolean.sCode to sToken
                        Append sOverstrikeLine CS_S sTo   CS_S sToken
                    End
                    Else Begin
                        Append sOverstrikeLine CS_S sMove CS_S TokenizerData.BooleanIndicator.SecondBoolean.sCode
                        Move TokenizerData.BooleanIndicator.ToBoolean.sCode to sToken
                        Get ReplaceParanthesis sToken to sToken
                        Append sOverstrikeLine CS_S sTo   CS_S sToken
                    End
                End

                Case Break

            // 'Indicate Found as True'
            // 'Indicate [Found] as True'
            // 'Indicate Select as Windowindex Eq Fieldindex // Comment'
            Case (bIndicateStart = True)
                Move CS_Move to sOverstrikeLine
                If (Left(TokenizerData.BooleanIndicator.FirstBoolean.sCode, 1) = "(") Begin
                    Get ReplaceParanthesis TokenizerData.BooleanIndicator.FirstBoolean.sCode to TokenizerData.BooleanIndicator.FirstBoolean.sCode
                End
                // If AsBoolean.sCode = "" we have a missing "as" keyword on line, so we adjust for that here.
                If (TokenizerData.BooleanIndicator.AsBoolean.sCode = "") Begin
                    Move (SizeOfArray(TokenizerData.asLineTokens)) to iSize
                    Move TokenizerData.asLineTokens[iSize -1] to TokenizerData.BooleanIndicator.AsBoolean.sCode
                End
                // Wrap unless ONE balanced group (a leading "(" alone is not enough: '(A) = (B)'
                // must still be wrapped - the operators-row-first plan order delivers that shape).
                Get _IsSingleParenGroup TokenizerData.BooleanIndicator.AsBoolean.sCode to bSkip
                If (TokenizerData.BooleanIndicator.AsBoolean.sCode <> "" and bSkip = False) Begin
                    Move ("(" + TokenizerData.BooleanIndicator.AsBoolean.sCode +")") to TokenizerData.BooleanIndicator.AsBoolean.sCode
                End
                Append sOverstrikeLine CS_S TokenizerData.BooleanIndicator.AsBoolean.sCode CS_S CS_To CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode
                Case Break

            // Starts with any other than: "If", "Indicate" or a square bracket indicator as e.g. "[Not Found]". I.e. another command.
            Case Else
                // Do we have a e.g. "While [Not Found]" construct?
                If (Pos(sFirstCmd, TokenizerData.sOverstrikeLine) < Pos("[", TokenizerData.sOverstrikeLine)) Begin
                    Move sFirstCmd to sOverstrikeLine
                    Append sOverstrikeLine CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode
                End
                Else Begin
                    Move TokenizerData.BooleanIndicator.ToBoolean.sCode to sToken
                    If (sToken = "") Begin
                        Move TokenizerData.BooleanIndicator.AsBoolean.sCode to sToken
                    End
                    Move (CS_Move * String(sToken)) to sOverstrikeLine
                    If (SearchArray(sTo, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP)) <> -1) Begin
                        Append sOverstrikeLine CS_S sTo CS_S TokenizerData.BooleanIndicator.FirstBoolean.sCode
                    End
                    Else Begin
                        Move TokenizerData.asLineTokens[(SizeOfArray(TokenizerData.asLineTokens) -1)] to sToken
                        Move (SearchArray(CS_As, TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
                        If (iItem <> -1) Begin
                            Move TokenizerData.BooleanIndicator.FirstBoolean.sCode to sToken
                            Append sOverstrikeLine CS_S sTo CS_S sToken
                        End
                        Else Begin
                            Append sOverstrikeLine CS_S sToken
                        End
                    End
                End
        Case End

        Get AssembleOutputLine sOverstrikeLine TokenizerData to sLine
        // SAFETY NET. First UN-SWALLOW a ';' line-continuation the sub pulled INTO the condition ('[FINDERR];' ->
        // 'If (FINDERR;)') by moving the INTRODUCED ';)' out to ');' ('If (FINDERR);') - a VALID conversion. Then
        // revert only the truly broken shapes (a conditionless 'If' or a dropped 'begin') - see
        // _IndicatorLineIsMalformed, the ONE check shared with ChangeSquareBracketsIndicators so the two callers
        // cannot drift. Leaves the original [...] warning, never a compile error (LegacyApp lreb/0042.vw, UFUNC.INC).
        Get _UnswallowSemicolon sLine sOrgLine to sLine
        Get _IndicatorLineIsMalformed sLine sOrgLine to bChanged
        If (bChanged = True) Begin
            Move sOrgLine to sLine
            Function_Return False
        End
        // gb-prefix the converted indicator references on the FINAL line (Nils 2026-07-05): each
        // captured raw name (+ the Indicate target) becomes its _IndicatorVarName form; system
        // booleans, already-prefixed and non-identifier names pass through unchanged inside the
        // helper. The As/VALUE side is deliberately never renamed - only the captured names are.
        Get _PrefixIndicatorRefs sLine sRawFirst     to sLine
        Get _PrefixIndicatorRefs sLine sRawSecond    to sLine
        Get _PrefixIndicatorRefs sLine sRawTo        to sLine
        Get _PrefixIndicatorRefs sLine sRawIndTarget to sLine
        Function_Return (sLine <> sOrgLine)
    End_Function

    { Published = True }
    { Description = """
        Replaces legacy indicators in square brackets, such as [Found] and [FindErr], with expressions such as (Found) and (Not(Found)).
        The 'Indicate' keyword itself is not changed; only the square brackets are.
        Use it together with ChangeLegacyIndicators, which runs first but skips lines that contain Find, Send or Constrain. This function converts those lines, so it is normal that it reports few or no changed lines when both are selected.
        Examples:
        - [Found] and [FindErr] indicator statements to (Found) and (FindErr).
        - [Found| Command -> e.g. If (Found) Command
        - [FindErr] Send Rebuild_constraints of oDD -> If (FindErr) Send Rebuild_constraints of oDD
        - While [Not Found] -> While (Not(Found)), and [Not Found] While likewise
        - If [Not Found] Reread hTable -> If (Not(Found)) Reread hTable
        - [~Found] Begin -> If (Not(Found)) Begin
        - [Found ~Found] Begin -> If (Found and Not(Found)) Begin
        - ifnot [SeqEof] Begin -> If (Not(SeqEof)) Begin
        Limitation: a line that contains a GROUP or ALL indicator is not changed.
        { MethodType = eStandardFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4538 | without parentheses | AutoFix }
        { ModRecipe = 4535 | indicators in If statements | AutoFix }
        { ModRecipe = 4538 | indicators in If statements | AutoFix }
        { EnumList = "eLeaveSelect, eModernizeSelect" }
        { InitialValue = eLeaveSelect }
        { ParamHelp = eLeaveSelect keeps [SELECT] as-is (safe default). eModernizeSelect also needs DefineSelectMacro selected (it defines the SELECT macro). }
        { SummaryText = Changed: Square indicator expression [xxx] --> Paranthesis expression (xxx) }
        """ }
    Function ChangeSquareBracketsIndicators String ByRef sLine String sParameter Returns Boolean
        String sNewCode sVarName sExpression sElse sIndent sRestCmd
        Boolean bFound bHasBracket bChanged
        Integer iStart iEnd iItem iLeftBracketNo iBracketTokenCount
        Boolean bSkip bModernizeSelect
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (TokenizerData.bLineIsReady = True or;
            TokenizerData.bIsInCommand = True or;
            TokenizerData.bIsInStruct  = True or;
            TokenizerData.bIsInImage   = True or;
            TokenizerData.bIsVariableDeclaration = True) Begin
            Function_Return False
        End
        Get HasBracket TokenizerData.BooleanIndicator to bHasBracket
        If (bHasBracket = False) Begin
            Function_Return False
        End

        // PINNED indicator (GROUP/ALL participant, or a name read by an unconverted 'use'd include):
        // leave the bracket legacy - see ChangeLegacyIndicators. (Nils 2026-07-09.) Empty set = no-op.
        If (_IndicatorIsPinned(Self, TokenizerData)) ;
            Function_Return False

        // AN ELSE IN FRONT (2026-10-06): a bracket behind an Else became an expression with no If in front -
        // 'Else [found] Move 1 to iCount' came out as 'Else (found) Move 1 to iCount', which does not compile
        // (measured). The statement is converted as a copy on its own line and the Else put back in front,
        // as ChangeLegacyIndicators does.
        Get _ElseStatementCopy TokenizerData sLine False (&sElse) to sNewCode
        If (sNewCode <> "") Begin
            Move TokenizerData.sIndentation to sIndent
            Move (sIndent + sNewCode) to sNewCode
            Get Tokenizer sNewCode to TokenizerData
            Get ChangeSquareBracketsIndicators of Self (&sNewCode) sParameter to bChanged
            If (bChanged = True) ;
                Move (sIndent + sElse + " " + LTrim(sNewCode)) to sLine
            Else ;
                Get Tokenizer sLine to TokenizerData
            Function_Return bChanged
        End

        // TWO BOOLEANS IN THE LEADING BRACKETS (2026-11-01): '[A][B]' and '[A] [B]' are converted as '[A B]', which this
        // reads right for every statement - two brackets put the condition in twice, 'If (A and B) (A and B) Clear Inv',
        // and '[A][B]' was one indicator 'A][B' (_LeadingTwoBooleans). A copy declined leaves the line as written.
        Get _LeadingTwoBooleans sLine False (&sRestCmd) to sNewCode
        If (sNewCode <> "" and sNewCode <> sLine) Begin
            Get Tokenizer sNewCode to TokenizerData
            Get ChangeSquareBracketsIndicators of Self (&sNewCode) sParameter to bChanged
            If (bChanged = True) ;
                Move sNewCode to sLine
            Else ;
                Get Tokenizer sLine to TokenizerData
            Function_Return bChanged
        End

        // See ChangeLegacyIndicators: a LEADING bracket + If + Indicate 3-way compound cannot be safely
        // modernised on one line - converting the leading bracket here would yield "If (Found) If sCustCode
        // ne "" Indicate ..." (double-If garbage). Leave it unchanged. A leading bracket is token[0]; the
        // supported "If [bool] Indicate ..." (test 6) has token[0] = "If" and is untouched by this guard.
        // Ind, Indicate's obsolete spelling, makes the same compound (_IndCommandWordPos, 2026-10-06).
        If (SizeOfArray(TokenizerData.asLineTokens) > 0) Begin
            If (Left(TokenizerData.asLineTokens[0], 1) = "[" and ;
                TokenizerData.bHasIfCommand = True and ;
                ((Lowercase(TokenizerData.sOverstrikeLine) contains (Lowercase(CS_Indicate) + CS_S)) or ;
                 (_IndCommandWordPos(Self, Trim(TokenizerData.sOverstrikeLine)) > 0))) ;
                Function_Return False
        End
        // We leave compound square bracket expessions combined withe keywords: "GROUP" and "ALL" alone:
        Move (SearchArray("GROUP", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            Function_Return False
        End
        Move (SearchArray("ALL", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem <> -1) Begin
            Function_Return False
        End

        // 'not [indicator]' (negation OUTSIDE the bracket, e.g. 'Until not [Found]') is mangled to a dangling
        // 'Until (not)' (-> bogus 'Undefined symbol ~'; LegacyApp TIDR/over051). Skip it - leave the [...] warning.
        Get _HasNotBeforeBracketIndicator TokenizerData to bSkip
        If (bSkip = True) ;
            Function_Return False

        // SELECT-handling gate. By default we respect CS_NonRefactorableIndicators and skip
        // lines whose bracket indicator has no valid modern bare form, leaving the harmless
        // [...] warning. The user opts in with eModernizeSelect; the companion DefineSelectMacro then
        // defines the SELECT macro in the file (an IFNDEF-guarded '#Replace SELECT' shim), so bare Select compiles.
        // sParameter arrives as the enum NAME from the UI combo ("eModernizeSelect") or as
        // the numeric VALUE from tests - resolve via _ParameterIsEnum; a bare Move of the
        // name into the Integer enum left the gate at eLeaveSelect, so the opt-in never
        // worked from the UI (2026-06-10). NO num_arguments guard: it is unreliable here
        // (nested sends/dynamic engine dispatch can clobber it), and an omitted parameter
        // arrives as "" which _ParameterIsEnum already treats as no-match.
        Get _ParameterIsEnum sParameter "eModernizeSelect" eModernizeSelect to bModernizeSelect
        If (bModernizeSelect = False) Begin
            Get _IndicatorIsNonRefactorable TokenizerData to bSkip
            If (bSkip = True) ;
                Function_Return False
        End

        // Note: a bare-ified [Select] (eModernizeSelect) needs the SELECT macro defined at the top of the
        // file - the companion DefineSelectMacro (an eOtherFunction) splices an IFNDEF-guarded '#Replace
        // SELECT' shim (NOT a 'Use OldFMACCommands.pkg' line) by SCANNING the rewritten file for the bare
        // Select, so nothing needs to be flagged from here.

        // Count the genuine bracket indicator tokens in asLineTokens.
        // The tokeniser replaces parenthesised expressions with | pipes in asLineTokens,
        // so brackets that appear INSIDE a paren expression (e.g. an array index like
        // daPeriodDates[0]) are absent from asLineTokens.  Without this cap the while
        // loop below would use sOverstrikeLine — which does NOT mask paren content —
        // and would incorrectly treat array-index brackets as indicator brackets.
        Move 0 to iBracketTokenCount
        For iStart from 0 to (SizeOfArray(TokenizerData.asLineTokens) - 1)
            If (Left(TokenizerData.asLineTokens[iStart], 1) = "[") Begin
                Increment iBracketTokenCount
            End
        Loop

        Move TokenizerData.sOverstrikeLine to sNewCode
        Move 1 to iLeftBracketNo

        While (Pos("[", sNewCode) > 0 and iLeftBracketNo <= iBracketTokenCount)

            Move (Pos("[", sNewCode)) to iStart
            Move (Pos("]", sNewCode)) to iEnd
            Move (Mid(sNewCode, (iEnd - iStart -1), (iStart +1))) to sVarName
            // Convert bracketed indicators variables to an expression
            Get ConvertBracketIndicatorsToExpression iLeftBracketNo TokenizerData to sExpression
            Increment iLeftBracketNo

            // Handle negation cases
            If (sVarName <> "") Begin
                Move (Replace("[" + sVarName + "]", sNewCode, sExpression)) to sNewCode
            End
        Loop

        Get FixIndicatorsLoopRepeatCommand sNewCode to sNewCode
        // If the old expression started with a bracket, insert an "If" statement at start of line.
        If (Left(Trim(sNewCode), 1) = "(") Begin
            Move ("If" * String(sNewCode)) to sNewCode
        End

        Get RestoreOverstrikeLineValues sNewCode TokenizerData to sNewCode
        Get AssembleOutputLine sNewCode TokenizerData to sNewCode
        // SAFETY NET: same shared check as ChangeLegacyIndicators. First UN-SWALLOW a ';' the swap pulled into the
        // condition ('[FINDERR];' -> '(FINDERR;)') by moving the INTRODUCED ';)' out to ');' ('If (FINDERR);') -
        // a VALID conversion; only truly broken shapes (a conditionless 'If') then revert (LegacyApp UFUNC.INC).
        Get _UnswallowSemicolon sNewCode sLine to sNewCode
        Get _IndicatorLineIsMalformed sNewCode sLine to bChanged
        If (bChanged = True) ;
            Function_Return False
        Move (sNewCode <> sLine) to bChanged
        Move sNewCode to sLine

        Function_Return bChanged
    End_Function

    /* DeclareRefactoredIndicators - the eOtherFunction companion to ChangeLegacyIndicators /
       ChangeSquareBracketsIndicators (auto-selected with them WHEN scope source actually uses an undeclared
       named indicator - the Modernization plan decides this in cModAnalyzer.AddNeededIndicatorCompanions via
       ghoFuncLib._ScopeHasUndeclaredNamedIndicator; the manual-grid / batch run-time net is the DD's
       EnsureCompanionsSelected). The user-facing half of this comment moved into the { Description } on
       2026-08-23, where the generated help can reach it.
       Those rewrite a USED legacy named indicator (Indicate X / [X]) into boolean-variable syntax (Move..to X /
       (X)); a named indicator carries NO declaration of its own, so unless an 'Indicator X' line existed (which
       ChangeIndicatorToBoolean turns into a Global_Variable) the rewritten X is an UNDEFINED symbol - the exact
       882->1119 LegacyApp break. This reads the PRE-conversion original (pasOriginalSource, stashed by the engine
       before the line-by-line pass - the converted file shows no Indicate/[X] any more), gathers the named
       indicators that are USED but NOT declared, and splices a guarded 'Global_Variable Boolean' per name at the
       top of the converted file. Skips built-ins (Found/FindErr/Err) and SELECT (DefineSelectMacro owns SELECT).

       gb-prefix follow-up (2026-07-05): a bare expression READ of a converted indicator is already-legal Boolean
       syntax that NO converter touches, so once the declaration and write sites carry the gb prefix such a read
       references a name that no longer exists. PASS 2b therefore renames whole-word occurrences of every SHIMMED
       name across the converted code, under the masking and shadowing rules now stated in the { Description }. */
    { Published = True }
    { Description = """
        Declares the legacy named indicators that the indicator converters change into Boolean variables, but that have no 'Indicator X' declaration. Without a declaration, the converted (X) or Move ... to X would refer to a name that does not exist.
        Each declaration is a Global_Variable Boolean, protected by #IFNDEF and added at the top of the file. The function reads the code as it was before the conversion, so it must run in the same run as the converters; it is selected automatically with them.
        Built-in indicators (Found, FindErr, Err), SELECT, and names that are already declared with 'Indicator X' in the same file are skipped.
        It also renames other uses of these indicators in expressions to the name with the gb prefix. A use such as 'If (not(Login_Successful)) Begin' is already valid Boolean syntax, so no converter changes it, but after the declaration has been renamed, it would refer to a name that no longer exists.
        Names in strings and comments, and File.Field references, are never renamed. A method that declares a local variable or a parameter with the same name is not changed.
        Running the function twice is safe: the #IFNDEF protection means that a declaration is never added twice, and never clashes with the declarations that ChangeIndicatorToBoolean adds, so warning 4390 cannot occur.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { SummaryText = Declared: undeclared named indicators }
        """ }
    Function DeclareRefactoredIndicators String[] ByRef asCode String sParameter Returns Integer
        String[] asOrig asUsed asDeclared asShimNames asRenameNames asShim asIdents asShadow asPinned asKeep
        String sLine sScan sLC sName sNameLC sContent sWork sMasked
        Integer iCount iSize iBr iBrEnd iLastUse iFirstCode i
        Boolean bSkip bIsUseOrInc bSeenCode bIsProcDecl bIsFuncDecl bLineChanged bNameChanged
        tTokenizer TD

        If (ghoEngine = 0) ;
            Function_Return 0
        Get pasOriginalSource of ghoEngine to asOrig
        Move (SizeOfArray(asOrig) - 1) to iSize
        If (iSize < 0) ;
            Function_Return 0

        // GATE 1 (run profiler 2026-07-04): the shims exist ONLY to back indicators that this run's
        // CONVERTERS turned into Boolean references. A file whose current content still equals the
        // pre-run snapshot was not touched by ANY conversion - no Boolean refs were created, so no
        // shim can be needed. IsSameArray is a native whole-array compare (the engine already runs
        // it twice per file); with ~8k changed lines across 530k, MOST files skip here - the text
        // gate below barely bit (242s) because legacy code has "[" nearly everywhere.
        If (IsSameArray(asCode, asOrig)) ;
            Function_Return 0

        // GATE 2: PASS 1 tokenizes EVERY original line (~420ms per file when it runs). An indicator
        // can only be USED via '[X]' or 'Indicate X' - or DECLARED via 'Indicator X' (whose bare
        // reads PASS 2b must rename; Nils 2026-07-09) - no "[", no "indicate" and no "indicator"
        // text ANYWHERE in the original (raw scan; images/comments count as hits and just run the
        // normal, masking pass) = nothing to do here.
        Get _FileContainsText of Self (&asOrig) "[" to bSkip
        If (bSkip = False) Begin
            Get _FileContainsText of Self (&asOrig) "indicate" to bSkip
        End
        If (bSkip = False) Begin
            Get _FileContainsText of Self (&asOrig) "indicator" to bSkip
        End
        If (bSkip = False) ;
            Function_Return 0
        Move False to bSkip

        // The USED-but-undeclared named indicators to shim (Indicate X / [X], minus built-ins/SELECT/indices/
        // already-declared) are computed by _UndeclaredNamedIndicatorsIn - the SAME scan the Auto-Select
        // companion gate uses (via _ScopeHasUndeclaredNamedIndicator), so the plan's decision to include this
        // companion and the work it actually does can never disagree.
        Get _UndeclaredNamedIndicatorsIn (&asOrig) to asShimNames
        // gb-prefix follow-up 3 (Nils 2026-07-09, a legacy customer workspace's 'indicator smaller'
        // + 'WHILE (smaller)'): bare reads of a DECLARED indicator need PASS 2b's rename too.
        // ChangeIndicatorToBoolean renames the 'Indicator X' DECLARATION to gbX and the usage
        // converters rename the WRITE sites they rewrite - but a bare expression READ of a declared
        // indicator was renamed by NOBODY (PASS 2b only covered the SHIMMED names), so
        // 'While (smaller)' kept pointing at a name whose declaration had become gbsmaller. The
        // rename list is therefore shims + DECLARED names;
        // built-ins/SELECT pass through unchanged inside _PrefixIndicatorRefsMasked, so a declared
        // built-in in the list costs nothing.
        Send _CollectIndicatorNames (&asOrig) (&asUsed) (&asDeclared)
        Move asShimNames to asRenameNames
        For iCount from 0 to (SizeOfArray(asDeclared) - 1)
            If (_NameInList(Self, asDeclared[iCount], asRenameNames) = False) ;
                Move asDeclared[iCount] to asRenameNames[SizeOfArray(asRenameNames)]
        Loop
        // Drop PINNED names (GROUP/ALL participants, or names read by an unconverted 'use'd include)
        // from BOTH lists: they stay entirely legacy, so neither a gb shim declaration nor a bare-read
        // rename applies (the line converters left their uses alone; renaming here would re-introduce the
        // very decoupling this guards against). pasPinnedIndicators is set by the engine per file (empty
        // in unit tests / when nothing pins -> both filters are no-ops). (Nils 2026-07-09.)
        Get pasPinnedIndicators to asPinned
        If (SizeOfArray(asPinned) > 0) Begin
            Move (ResizeArray(asKeep, 0)) to asKeep
            For iCount from 0 to (SizeOfArray(asShimNames) - 1)
                If (SearchArray(Uppercase(asShimNames[iCount]), asPinned) = -1) ;
                    Move asShimNames[iCount] to asKeep[SizeOfArray(asKeep)]
            Loop
            Move asKeep to asShimNames
            Move (ResizeArray(asKeep, 0)) to asKeep
            For iCount from 0 to (SizeOfArray(asRenameNames) - 1)
                If (SearchArray(Uppercase(asRenameNames[iCount]), asPinned) = -1) ;
                    Move asRenameNames[iCount] to asKeep[SizeOfArray(asKeep)]
            Loop
            Move asKeep to asRenameNames
        End
        If (SizeOfArray(asShimNames) = 0 and SizeOfArray(asRenameNames) = 0) ;
            Function_Return 0

        // Build the guarded shim - one '#IFNDEF X / Global_Variable Boolean X / #ENDIF' block per name.
        // gb-prefix (Nils 2026-07-05): the SHIM declares the name the converters emit at the use sites (via
        // _IndicatorVarName); asShimNames itself stays RAW for the PASS 2b read-rename below.
        Move (SizeOfArray(asShimNames) - 1) to iSize
        For iCount from 0 to iSize
            Move asShimNames[iCount] to sName
            Get _IndicatorVarName sName to sName
            Move ("#IFNDEF " + sName)                     to asShim[SizeOfArray(asShim)]
            Move ("    Global_Variable Boolean " + sName) to asShim[SizeOfArray(asShim)]
            Move "#ENDIF"                                 to asShim[SizeOfArray(asShim)]
        Loop

        // PASS 2b (gb-prefix follow-up, 2026-07-05): the converters rename the WRITE sites they rewrite and
        // the shim block renames the declaration - but a bare expression READ of a converted indicator
        // ('If (not(Login_Successful)) Begin') is already-legal Boolean syntax that NO converter touches, so
        // after the gb rename it would reference a name that no longer exists anywhere. Rename whole-word
        // occurrences of every shimmed name across the converted code. Hits are located on the MASKED,
        // position-aligned text (sIndentation + sOverstrikeLine: a name inside a string or comment never
        // matches); '.'-qualified hits are skipped (File.Field); and a method that declares a same-named
        // LOCAL - or carries one in its signature - is left alone for its whole body, because that local
        // legitimately shadowed the indicator's pre-gb same-named global too.
        Send ClearFuncLibProperties
        Move (SizeOfArray(asCode) - 1) to iSize
        For iCount from 0 to iSize
            Move asCode[iCount] to sLine
            Get Tokenizer sLine to TD
            If (TD.bIsComment = False and TD.bIsBlank = False and TD.bIsInImage = False and TD.bIsInDF23MultiLineString = False) Begin
                Move (Trim(TD.sOverstrikeLine)) to sScan
                Get _IsProcedureDeclaration sScan to bIsProcDecl
                Get _IsFunctionDeclaration  sScan to bIsFuncDecl
                If (bIsProcDecl = True or bIsFuncDecl = True) Begin
                    // New method = new local scope: reset, then shadow every renameable name the
                    // signature itself mentions (a parameter of that name owns it for the body).
                    Move (ResizeArray(asShadow, 0)) to asShadow
                    For i from 0 to (SizeOfArray(asRenameNames) - 1)
                        If (_FindKeywordPos(Self, sScan, asRenameNames[i], True, 1) > 0) ;
                            Move asRenameNames[i] to asShadow[SizeOfArray(asShadow)]
                    Loop
                End
                Else If (Pos("end_procedure", Lowercase(sScan)) = 1 or Pos("end_function", Lowercase(sScan)) = 1) Begin
                    // Method closed: object-level code that follows is rename-eligible again.
                    Move (ResizeArray(asShadow, 0)) to asShadow
                End
                Else If (TD.bIsVariableDeclaration = True and Lowercase(_NthWord(Self, sScan, 1)) <> "indicator") Begin
                    // A declaration line: a renameable name declared LOCAL here shadows the global
                    // for the rest of this method. The declaration line itself is never renamed.
                    // EXCEPT an 'Indicator X' line - that is the GLOBAL legacy indicator
                    // declaration itself (LocalVariableTypes.inc lists 'indicator', so bIsVariableDeclaration
                    // is True for it), NOT a shadowing local: in a flat module it would otherwise
                    // shadow every read below it forever. It falls through to the rename branch,
                    // so an UNCONVERTED 'indicator smaller' straggler becomes 'indicator gbsmaller'
                    // - consistent with the renamed writes/reads whichever converters ran.
                    For i from 0 to (SizeOfArray(asRenameNames) - 1)
                        If (_FindKeywordPos(Self, sScan, asRenameNames[i], True, 1) > 0) ;
                            Move asRenameNames[i] to asShadow[SizeOfArray(asShadow)]
                    Loop
                End
                Else If (Left(sScan, 1) <> "#" and (_FindKeywordPos(Self, sScan, CS_Indicate, True, 1) = 0)) Begin
                    // Executable line (preprocessor lines and any unconverted Indicate straggler are
                    // left alone): rename each unshadowed renameable name (shimmed OR declared) on
                    // the raw-aligned mask.
                    // The straggler check is a whole-word scan of the MASKED line, not a
                    // line-start Pos: an Indicate can sit INLINE after 'If (cond)' (Nils
                    // 2026-07-08), and renaming such a line's target would leave 'Indicate gb...'
                    // = a guaranteed 4345 compile error - strictly worse than the legacy-but-
                    // compiling line the converters chose to leave alone.
                    Move (TD.sIndentation + TD.sOverstrikeLine) to sMasked
                    Move False to bLineChanged
                    For i from 0 to (SizeOfArray(asRenameNames) - 1)
                        If (_NameInList(Self, asRenameNames[i], asShadow) = False) Begin
                            Get _PrefixIndicatorRefsMasked (&sLine) (&sMasked) asRenameNames[i] to bNameChanged
                            If (bNameChanged = True) ;
                                Move True to bLineChanged
                        End
                    Loop
                    If (bLineChanged = True) ;
                        Move sLine to asCode[iCount]
                End
            End
        Loop

        // PASS 3: splice the shim into the CONVERTED file at the top - after the leading Use/#include block,
        // else before the first real code line (same placement as DefineSelectMacro). Reset the stateful
        // tokeniser first so PASS 1's end-state cannot leak into this sequential scan of asCode.
        Send ClearFuncLibProperties
        Move -1 to iLastUse
        Move -1 to iFirstCode
        Move False to bSeenCode
        Move (SizeOfArray(asCode) - 1) to iSize
        For iCount from 0 to iSize
            // Per-file progress nudge; no-op when no panel is active (mirrors DefineSelectMacro).
            If (Mod(iCount, 20) = 0 and (Active_State(ghoStatusPanel) = True)) Begin
                Send Update_StatusPanel of ghoStatusPanel ("Source line:" * String(iCount + 1) * "of:" * String(iSize + 1))
                Set piPosition of ghoProgressBar to (iCount + 1)
            End
            If (bSeenCode = False) Begin
                Move asCode[iCount] to sLine
                Get Tokenizer sLine to TD
                Get _IsUseOrIncludeLine sLine to bIsUseOrInc
                If (bIsUseOrInc = True) Begin
                    Move iCount to iLastUse
                End
                Else If (TD.bIsComment = False and TD.bIsBlank = False) Begin
                    Move iCount to iFirstCode
                    Move True to bSeenCode
                End
            End
        Loop

        Send _InsertAfterPreamble (&asCode) asShim iLastUse iFirstCode
        Function_Return (SizeOfArray(asShimNames))
    End_Function

    /* THE TOP-OF-FILE SPLICE DeclareRefactoredIndicators and DefineSelectMacro share: the block goes in after
       the last leading Use/#include line, else before the first code line, else at the top - always before
       the first real code, so a declaration precedes every use and never lands inside a header comment. An
       all-preamble file (the insertion point past its last line) gets the block appended. */
    Procedure _InsertAfterPreamble String[] ByRef asCode String[] asShim Integer iLastUse Integer iFirstCode
        String[] asOut
        Integer iCount iSize iInsertAt iShim
        Boolean bInserted

        If (iLastUse >= 0) ;
            Move (iLastUse + 1) to iInsertAt
        Else If (iFirstCode >= 0) ;
            Move iFirstCode to iInsertAt
        Else ;
            Move 0 to iInsertAt

        Move (SizeOfArray(asCode) - 1) to iSize
        Move False to bInserted
        For iCount from 0 to iSize
            If (iCount = iInsertAt) Begin
                For iShim from 0 to (SizeOfArray(asShim) - 1)
                    Move asShim[iShim] to asOut[SizeOfArray(asOut)]
                Loop
                Move True to bInserted
            End
            Move asCode[iCount] to asOut[SizeOfArray(asOut)]
        Loop
        If (bInserted = False) Begin
            For iShim from 0 to (SizeOfArray(asShim) - 1)
                Move asShim[iShim] to asOut[SizeOfArray(asOut)]
            Loop
        End
        Move asOut to asCode
    End_Procedure

    /* DefineSelectMacro - the file-level companion to ChangeLegacyIndicators /
       ChangeSquareBracketsIndicators. Those two (eStandardFunction, one line at a time) cannot add a
       top-of-file definition themselves; under eModernizeSelect they bare-ify the legacy [Select] macro
       indicator (e.g. [Select] -> (Select), Indicate Select as X -> Move (X) to Select). Bare SELECT only
       compiles where the SELECT macro is defined. The user-facing half - placement, the IFNDEF no-op, why
       not a Use line, and the string/comment safety rules - is now in the { Description } below.

       This eOtherFunction runs AFTER the line-by-line pass on the SAME file (see cRefactorEngine), so by
       the time it sees asCode the legacy [Select] has ALREADY become the modern bare Select - there is no
       [Select] left to look for. It therefore SCANS the rewritten code for a bare, boundary-aware
       'Select' token in real code and, when found, splices in:
           #IFNDEF SELECT
               #Replace SELECT |!C
           #ENDIF
       - the SAME definition the legacy REPORT command macro uses. That listing stays HERE and not in the
       { Description }: FMAC would eat a literal |!C during DFRefactor's own compile.

       The scan is the trigger - a per-file flag cannot be, because the engine sends ClearFuncLibProperties
       before EVERY eOtherFunction (it would wipe any flag the indicators raised during the line-by-line
       pass). Reading the final text also means it works when the indicators were run in an earlier,
       separate run. The 'no Use OldFMACCommands.pkg' rule is not a preference: a (Select) in a REPORT-less
       file still failed to compile - the bug Nils hit.
    */
    { Published = True }
    { Description = """
        Defines the 'Select' macro indicator that remains when ChangeLegacyIndicators or ChangeSquareBracketsIndicators converts a legacy [Select] with the eModernizeSelect setting.
        A protected definition of the SELECT macro (a Replace inside #IFNDEF) is added near the top of the file, after the Use and #Include lines and before the first line of code, so that it comes before every use of it.
        A Use of OldFMACCommands.pkg is not added instead, because that package defines SELECT only when the REPORT command is used. A Select in a file without REPORT would then still not compile.
        Run it together with those two functions, or after them. It does nothing when no Select is found, or when the definition is already there. In a file that already defines SELECT, for example one that uses the legacy REPORT command, the protected definition has no effect.
        Strings, comments, blank lines and image sections are ignored, so a SQL SELECT in a string can never cause the definition to be added. Only the whole word is matched: Selected, Selection and Select_State are not.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4345 | SELECT, MUST BE DEFINED }
        { SummaryText = Defined: SELECT macro }
        """ }
    Function DefineSelectMacro String[] ByRef asCode String sParameter Returns Integer
        String[] asShim
        String sLine sLC
        Integer iCount iSize iLastUse iFirstCode iSelectPos
        Boolean bNeeds bAlreadyDefined bSeenCode bIsUseOrInc bSkipLine bIsMsgSend
        tTokenizer TD

        Move (SizeOfArray(asCode) - 1) to iSize
        If (iSize < 0) ;
            Function_Return 0

        // Fast reject (NO tokenising): this function only acts on a bare Select keyword/indicator. SearchArray
        // scans the raw lines via the _HasBareSelectKeyword comparator (boundary-aware - it rejects Selected /
        // Selection / Select_State) and returns -1 when none is present, letting us skip the expensive per-line
        // tokeniser pass below for files with no bare Select (the common case). A Select inside a comment/string
        // slips through here (the comparator does not mask) - harmless: that file falls through to the accurate pass.
        If (SearchArray(CS_Select, asCode, Self, (RefFunc(_HasBareSelectKeyword))) = -1) Begin
            Function_Return 0
        End

        Move False to bNeeds
        Move False to bAlreadyDefined
        Move False to bSeenCode
        Move -1 to iLastUse
        Move -1 to iFirstCode

        // ONE ordered pass (tokeniser is stateful, so top-to-bottom): detect the modernised bare Select
        // indicator (the reason to define the macro), note an existing '#Replace SELECT' definition, and
        // locate the top-of-file insertion point - after the leading Use/#include block, else before the
        // first real code line (so the macro precedes every use, and never lands inside a header comment).
        For iCount from 0 to iSize
            // Per-file progress nudge; no-op when no panel is active. Mirrors ChangeDfTimerTocTimer.
            If (Mod(iCount, 20) = 0 and (Active_State(ghoStatusPanel) = True)) Begin
                Send Update_StatusPanel of ghoStatusPanel ("Source line:" * String(iCount + 1) * "of:" * String(iSize + 1))
                Set piPosition of ghoProgressBar to (iCount + 1)
            End
            Move asCode[iCount] to sLine
            Get Tokenizer sLine to TD

            // An existing '#Replace SELECT ...' directive (our prior shim, or a hand-written define) means
            // SELECT is already defined in-source -> nothing to add. A REPORT-using file has NO such line
            // in its source (REPORT defines SELECT inside the macro), so we still add the guarded shim,
            // which the IFNDEF then makes a no-op at compile time. (Note: 'Use OldFMACCommands.pkg' is NOT
            // a marker - it does not define SELECT on its own, so a file with only that line still needs us.)
            Move (Lowercase(Trim(sLine))) to sLC
            If ((Left(sLC, 8) = "#replace") and (sLC contains "select")) ;
                Move True to bAlreadyDefined

            // Detect the modernised bare Select indicator. Skip lines that are NOT real code - comment,
            // blank, image page, or part of a multi-line string (the latter is where a multi-line SQL
            // SELECT lives, per tTokenizer.bIsInDF23MultiLineString) - so such a 'SELECT' never triggers.
            // On the remaining code lines, search the MASKED line (indentation + overstrike, position-
            // aligned, with string literals blanked) boundary-aware: (Select) / Not(Select) / "to Select"
            // all match, while Selected / Select_State / Selection and a 'SELECT' inside a "..." literal
            // do not. Stop searching once found.
            Move (TD.bIsComment = True or TD.bIsBlank = True or TD.bIsInImage = True or TD.bIsInDF23MultiLineString = True) to bSkipLine
            If (bNeeds = False and bSkipLine = False) Begin
                Get _FindKeywordPos (TD.sIndentation + TD.sOverstrikeLine) CS_Select True 1 to iSelectPos
                If (iSelectPos > 0) Begin
                    // A bare 'Select' after Send/Get/Set is the built-in Select MESSAGE ('Send Select 0 255' =
                    // select-a-range in an entry), NOT the SELECT FMAC indicator macro. Defining SELECT as |!C
                    // would turn it into 'Send |!C ...' -> 4345 'SELECT, INDICATOR NOT ALLOWED' (LegacyApp
                    // EXCLASS.INC). Only a Select used as an INDICATOR value needs the macro - ignore the
                    // message form and keep scanning for a real one.
                    Get _BareSelectIsMessageSend TD to bIsMsgSend
                    If (bIsMsgSend = False) ;
                        Move True to bNeeds
                End
            End

            If (bSeenCode = False) Begin
                Get _IsUseOrIncludeLine sLine to bIsUseOrInc
                If (bIsUseOrInc = True) Begin
                    Move iCount to iLastUse
                End
                Else If (TD.bIsComment = False and TD.bIsBlank = False) Begin
                    Move iCount to iFirstCode
                    Move True to bSeenCode
                End
            End
        Loop

        // No bare Select anywhere -> nothing to do. Already defined -> idempotent no-op.
        If (bNeeds = False) ;
            Function_Return 0
        If (bAlreadyDefined = True) ;
            Function_Return 0

        // The guarded SELECT-macro shim to splice in: a // comment + the IFNDEF/Replace/ENDIF block. The
        // IFNDEF guard makes it idempotent and conflict-free (a no-op in a file that already defines SELECT,
        // e.g. one using REPORT). This REPLACES the old 'Use OldFMACCommands.pkg' line, which only made
        // REPORT available and did NOT define bare SELECT on its own. The #Replace line comes from
        // CS_SelectMacroDefineLine - its |!C is built from Character() codes because |!C is a compile-time
        // counter that a literal "|!C" in our source would evaluate here instead of emitting verbatim.
        Move "// SELECT macro defined by DFRefactor (OldFMACCommands.pkg defines it only via REPORT); IFNDEF-guarded, a no-op if already defined." to asShim[0]
        Move "#IFNDEF SELECT"        to asShim[1]
        Move CS_SelectMacroDefineLine to asShim[2]
        Move "#ENDIF"                to asShim[3]

        // Splice point: after the last leading Use/#include; else before the first code line; else top -
        // always before the first real code, so the #Replace precedes every (Select) use.
        Send _InsertAfterPreamble (&asCode) asShim iLastUse iFirstCode
        Function_Return 1
    End_Function

