// CommentOutRefactorFunctions.inc
//
// The COMMENT-OUT family of refactoring functions, #Include'd into the oRefactorFuncLib
// object so they read and compile exactly as if they were written there.
//
// What they have in common is the answer they give. Each finds a construct the compiler no
// longer supports - a character-mode argument-size command, a dev-only command, a Use of a
// package that has been removed, Set_Date_Attribute, the Y2K date-attribute triplet - and comments the
// line out rather than deleting it. That is the whole idea: the original stays readable and
// revertable, because a construct with no modern equivalent is a decision for the developer,
// not something a converter should silently take away.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    /* Get_Argument_Size / Set_Argument_Size sized the legacy fixed string-argument buffer. Modern
       DataFlex strings are dynamic, so both are no-ops - the compiler flags them obsolete (4533). The
       usual idiom is save / enlarge / restore (Get_Argument_Size to v ... Set_Argument_Size n ...
       Set_Argument_Size v); since all three are no-ops now, commenting them out is safe. We COMMENT
       (not delete) so the change is visible and trivially reversible, and we match the keyword as a
       whole TOKEN anywhere on the line, so an inline "If (cond) Set_Argument_Size n" / "Else ..." is
       handled too. (After the save + restore are commented the saved-size local may go unused -
       cosmetic; RemoveUnusedLocals clears it.) Categorised Review (eModSuggest), not Auto-fix: the
       rare inline-If form drops the guarding If when the whole line is commented, so it's worth an eye.
    */
    { Published = True }
    { Description = """
        Comments out the obsolete Get_Argument_Size and Set_Argument_Size commands. They set the size of string buffers in older DataFlex versions, and have no effect now that strings have a dynamic size.
        Example: Set_Argument_Size 4096 -> // Set_Argument_Size 4096
        { MethodType = eStandardFunction }
        { FnFamily = Comment out obsolete }
        { FnGroup = Modernization }
        { ModRecipe = 4533 | Set_Argument_Size | Suggest }
        { ModRecipe = 4533 | Get_Argument_Size | Suggest }
        { SummaryText = Commented out: Get_Argument_Size / Set_Argument_Size (obsolete) }
        """ }
    Function CommentOutArgumentSizeCommands String ByRef sLine String sParameter Returns Boolean
        Integer iItem
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Function_Return False
        // Match either companion command as a whole token (case-insensitive), anywhere on the line - so
        // first-token, "If (cond) Set_Argument_Size n" and "Else Get_Argument_Size to v" all qualify. A
        // quoted string is a distinct token, so the keyword inside a literal/comment never false-matches.
        Move (SearchArray("Set_Argument_Size", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) ;
            Move (SearchArray("Get_Argument_Size", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) ;
            Function_Return False
        // Comment out the whole statement, preserving the original indentation.
        Move (TokenizerData.sIndentation + "// " + (Right(sLine, (Length(sLine) - Length(TokenizerData.sIndentation))))) to sLine
        Function_Return True
    End_Function

    /* CommentOutObsoleteDevCommands - dev-only / character-mode commands that are no-ops in a modern
       GUI app: Debug/Memory/Winput (dev display - use the Studio debugger) and the character-mode
       cursor / colour / map-mode / graphics relics. The fix is deletion; we COMMENT (reversible and
       visible) with a note that survives an un-comment, mirroring CommentOutArgumentSizeCommands.
       Matched at COMMAND position only (the FIRST token) so a variable named "debug"/"memory" never
       false-matches - these are ordinary English words, unlike Set_Argument_Size. Categorised Suggest
       (Review): a "Get_..." relic that fed a variable leaves it unset once commented, worth an eye.
       Idempotent - an already-commented line is skipped. Deep-Scan-routed only (no ModRecipe). */
    { Published = True }
    { Description = """
        Comments out obsolete development and character-mode commands that have no effect in a modern Windows program: Debug, Memory, Winput, Get/Set_cursor_visible, Get/Set_default_map_mode, Graphics_adjust_coords and Get_current_colors.
        The change can be undone: the line is kept as a comment, with a note.
        Example: Debug "here" -> // Debug "here" // obsolete command - no-op in modern DataFlex
        { MethodType = eStandardFunction }
        { FnFamily = Comment out obsolete }
        { FnGroup = Modernization }
        { SummaryText = Commented out: obsolete dev-only / character-mode command }
        """ }
    Function CommentOutObsoleteDevCommands String ByRef sLine String sParameter Returns Boolean
        String sBody
        String[] asDevCmds
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Function_Return False
        // Already commented (or a re-run) - do nothing, so we never stack "// // ...".
        If (Left(LTrim(sLine), 2) = "//") ;
            Function_Return False
        // Command position only (the FIRST token) - so a variable named "debug"/"memory" never matches.
        Move (StrSplitToArray("debug,memory,winput,get_current_colors,get_cursor_visible,set_cursor_visible,get_default_map_mode,set_default_map_mode,graphics_adjust_coords", ",")) to asDevCmds
        If (SearchArray(Lowercase(TokenizerData.sFirstToken), asDevCmds) = -1) ;
            Function_Return False
        // Comment out the whole statement, preserving indentation; the trailing note survives an un-comment.
        Move (Right(sLine, (Length(sLine) - Length(TokenizerData.sIndentation)))) to sBody
        Move (TokenizerData.sIndentation + "// " + sBody + " // obsolete command - no-op in modern DataFlex") to sLine
        Function_Return True
    End_Function

    /* CommentOutObsoletePackageUse - the compiler flags a 'Use <pkg>' for certain obsolete packages with
       4536 "obsolete package ... can be removed / just comment out the Use statement": their content is now
       in FMAC / the runtime, so the Use is a pure no-op and commenting it out is exactly the compiler's
       advice (Nils 2026-07-09, Case.mac - the Case command lives in FMAC). We COMMENT (not delete) so the
       change is visible + trivially reversible. The removable list is CS_RemovableObsoletePackages -
       genuinely-removable packages ONLY (not the "Use cX class instead" ones, which need a code change, nor
       func.pkg). Matches the Use'd package by BASENAME, case-insensitive, so 'Use Case.mac', 'use case.MAC'
       and a path-qualified form all qualify; an already-commented line (leading //) is skipped by
       _IsUseOrIncludeLine, so a re-run never double-comments.
       NOTE - not analyzer-routed: the 4536 warning is reported at the OBSOLETE PACKAGE's own line 1 (under
       the DataFlex install), which the plan scopes OUT (it is not a workspace file), so this is a standalone
       function the user selects and runs across their own source. (The '4536 -> use-sites' redirect is a
       separate ModAnalyzer backlog item.) Categorised via FnGroup only (no ModRecipe). */
    { Published = True }
    { Description = """
        Comments out 'Use <package>' for obsolete packages that the compiler says can be removed, because their content is now part of FMAC or the runtime. An example is Case.mac, since the Case command is now in FMAC.
        Example: Use Case.mac -> // Use Case.mac   // 4536: obsolete package, safe to remove
        The packages it removes are listed in CS_RemovableObsoletePackages.
        The Modernization Analyzer does not suggest this function, because the compiler reports warning 4536 in the DataFlex installation's package, which the plan leaves out. Select the function and run it on the workspace's source code yourself.
        { MethodType = eStandardFunction }
        { FnFamily = Comment out obsolete }
        { FnGroup = Modernization }
        { SummaryText = Commented out: Use <obsolete removable package> }
        """ }
    Function CommentOutObsoletePackageUse String ByRef sLine String sParameter Returns Boolean
        tTokenizer TokenizerData
        String sCode sPkg sBase
        String[] asRemovable
        Integer iPos

        Get pTokenizer to TokenizerData
        If (TokenizerData.bLineIsReady or TokenizerData.bIsInImage) ;
            Function_Return False
        // Must be a live (non-commented) 'Use ...' / '#include ...' line. _IsUseOrIncludeLine strips the
        // end comment then requires the code to START with 'use '/'#include ', so a leading-'//' line
        // (already commented) reads False here - the guard doubles as the idempotency check.
        If (_IsUseOrIncludeLine(Self, sLine) = False) ;
            Function_Return False
        // Package = the 2nd word of the code part (after Use/#include), basename only (drop any path).
        Get _RemoveEndComment sLine to sCode
        Get _NthWord sCode 2 to sPkg
        If (sPkg = "") ;
            Function_Return False
        Move sPkg to sBase
        Move (Pos("\", sBase)) to iPos
        While (iPos > 0)
            Move (Mid(sBase, Length(sBase), iPos + 1)) to sBase
            Move (Pos("\", sBase)) to iPos
        Loop
        Move (StrSplitToArray(Lowercase(CS_RemovableObsoletePackages), ",")) to asRemovable
        If (SearchArray(Lowercase(Trim(sBase)), asRemovable) = -1) ;
            Function_Return False
        // Comment out the whole statement, preserving indentation, with a note that survives an un-comment.
        Move (TokenizerData.sIndentation + "// " + (Right(sLine, (Length(sLine) - Length(TokenizerData.sIndentation)))) + "   // 4536: obsolete package, safe to remove") to sLine
        Function_Return True
    End_Function

    /* Set_Date_Attribute set the legacy Y2K / epoch date behaviour: sysdate4_State / Date4_State enabled
       4-digit-year storage and epoch_value set the sliding 2-digit-year window. Modern DataFlex stores
       dates 4-digit unconditionally, so these are no-ops; the compiler flags the command obsolete (4533,
       "Use Set_Attribute DF_DATE_FORMAT" - a generic hint, NOT a mechanical swap for these attributes).
       Per Nils' decision we COMMENT the line out (reversible) rather than convert or delete, leaving a
       "no longer needed" note that survives an un-comment as a valid trailing end-comment. Categorised
       Suggest (Review): commenting out epoch_value can change 2-digit-year INPUT interpretation, worth an
       eye. Idempotent - an already-commented line is skipped so a re-run never stacks "// // ...". */
    { Published = True }
    { Description = """
        Comments out the obsolete Set_Date_Attribute command. The date attributes it sets (sysdate4_State, Date4_State and epoch_value) were used for the year 2000 change, and have no effect in modern DataFlex, where dates always have 4-digit years.
        Example: Set_Date_Attribute sysdate4_State to X -> // Set_Date_Attribute sysdate4_State to X // no longer needed
        { MethodType = eStandardFunction }
        { FnFamily = Comment out obsolete }
        { FnGroup = Modernization }
        { ModRecipe = 4533 | command: Set_Date_Attribute | Suggest }
        { SummaryText = Commented out: Set_Date_Attribute (obsolete date attribute) }
        """ }
    Function CommentOutSetDateAttribute String ByRef sLine String sParameter Returns Boolean
        Integer iItem
        String sBody
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Function_Return False
        // Already commented (or a re-run) - do nothing, so we never stack "// // ...".
        If (Left(LTrim(sLine), 2) = "//") ;
            Function_Return False
        Move (SearchArray("Set_Date_Attribute", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        If (iItem = -1) ;
            Function_Return False
        // Comment out the whole statement, preserving indentation; the trailing "no longer needed" note
        // survives an un-comment as a valid end-comment.
        Move (Right(sLine, (Length(sLine) - Length(TokenizerData.sIndentation)))) to sBody
        Move (TokenizerData.sIndentation + "// " + sBody + " // no longer needed") to sLine
        Function_Return True
    End_Function

    // The value guard for the two LIVE attributes of the Y2K triplet (see CommentOutLegacyDateAttributes
    // below - this helper sits ABOVE its header so the meta-tags stay with the Function): the line is
    // redundant only when it is a Set_Attribute of the attribute at asLineTokens[iItem] 'to' the value
    // VdfBase.pkg already sets (sDefault, compared case-blind). A Set to any other value is a deliberate
    // override, a Get_Attribute reads a live value, and an expression or a variable in the value slot is
    // not judged at all - all three answer False and the line stays.
    Function _LegacyDateAttributeIsRedundant tTokenizer TokenizerData Integer iItem String sDefault Returns Boolean
        If (SizeOfArray(TokenizerData.asLineTokens) < (iItem + 3)) ;
            Function_Return False
        If (Lowercase(TokenizerData.asLineTokens[0]) <> "set_attribute") ;
            Function_Return False
        If (Lowercase(TokenizerData.asLineTokens[iItem + 1]) <> "to") ;
            Function_Return False
        Function_Return (Lowercase(TokenizerData.asLineTokens[iItem + 2]) = sDefault)
    End_Function

    /* CommentOutLegacyDateAttributes - the Y2K date triplet the old Studio wrote into every new
       program: DF_SYSDATE_4_STATE, DF_DATE_4_STATE and DF_EPOCH_VALUE. VdfBase.pkg has set all three
       itself since DataFlex 12 (True / True / 30 - "Y2K has come and gone", and the block is still
       there in DF26 and DF27), so a program's own line is redundant only when it REPEATS that.
       DF_SYSDATE_4_STATE is a no-op whatever the line does with it (dates are stored 4-digit
       unconditionally); but DF_DATE_4_STATE still drives the year width of a date-to-string
       conversion and DF_EPOCH_VALUE still decides how a 2-digit year is read, so for those two a Set
       to any other value is a deliberate override and a Get reads a live value - both stay verbatim,
       and the analyzer's dry-run hands such a row to Explain. Was CommentOutSysdate4State until
       2026-09-18, when it grew from the one attribute to the triplet (Nils: "it seems logical that any
       and all of them should be commented out"). Mirrors CommentOutSetDateAttribute: COMMENT the line
       out (reversible + visible) with a note; the symbol is an argument, not a leading command, so it
       is matched as a whole token anywhere on the line. Idempotent - an already-commented line is
       skipped. */
    { Published = True }
    { Description = """
        Comments out the old year-2000 date-attribute lines that the old Studio added to every new program. VdfBase.pkg now sets these attributes itself.
        DF_SYSDATE_4_STATE is always commented out, because it has no effect. DF_DATE_4_STATE is commented out only when it is set to True, and DF_EPOCH_VALUE only when it is set to 30. Any other value was set on purpose, so it is kept, and so is a Get_Attribute of these two attributes.
        Example: Set_Attribute DF_DATE_4_STATE to True -> // Set_Attribute DF_DATE_4_STATE to True // no longer needed - VdfBase.pkg sets this
        { MethodType = eStandardFunction }
        { FnFamily = Comment out obsolete }
        { FnGroup = Modernization }
        { SummaryText = Commented out: legacy Y2K date attributes (VdfBase.pkg sets them) }
        """ }
    Function CommentOutLegacyDateAttributes String ByRef sLine String sParameter Returns Boolean
        Integer iItem
        String sBody
        Boolean bRedundant
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (LineIsNotCode(&TokenizerData)) Function_Return False
        // Already commented (or a re-run) - do nothing, so we never stack "// // ...".
        If (Left(LTrim(sLine), 2) = "//") ;
            Function_Return False
        // DF_SYSDATE_4_STATE: a no-op in any shape, Set or Get.
        Move (SearchArray("DF_SYSDATE_4_STATE", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
        Move (iItem <> -1) to bRedundant
        // DF_DATE_4_STATE: redundant only as 'Set_Attribute DF_DATE_4_STATE to True' (VdfBase's value).
        If (not(bRedundant)) Begin
            Move (SearchArray("DF_DATE_4_STATE", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem <> -1) ;
                Get _LegacyDateAttributeIsRedundant TokenizerData iItem "true" to bRedundant
        End
        // DF_EPOCH_VALUE: redundant only as 'Set_Attribute DF_EPOCH_VALUE to 30' (VdfBase's value).
        If ((not(bRedundant)) and (iItem = -1)) Begin
            Move (SearchArray("DF_EPOCH_VALUE", TokenizerData.asLineTokens, Desktop, RefFunc(DFSTRICMP))) to iItem
            If (iItem <> -1) ;
                Get _LegacyDateAttributeIsRedundant TokenizerData iItem "30" to bRedundant
        End
        If (not(bRedundant)) ;
            Function_Return False
        // Comment out the whole statement, preserving indentation; the trailing note survives an un-comment.
        Move (Right(sLine, (Length(sLine) - Length(TokenizerData.sIndentation)))) to sBody
        Move (TokenizerData.sIndentation + "// " + sBody + " // no longer needed - VdfBase.pkg sets this") to sLine
        Function_Return True
    End_Function

