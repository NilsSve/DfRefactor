// CodeJockRefactorFunctions.inc
//
// The CODEJOCK CONTROL family of refactoring functions, #Include'd into the oRefactorFuncLib
// object so they read and compile exactly as if they were written there.
//
// All seven move a legacy DataFlex control onto its CodeJock replacement: Grid and List to
// cCJGrid, dbGrid to cDbCJGrid, dbList to cDbCJGridPromptList, the obsolete cCJReport* classes
// back to the Grid ones DF23 renamed them to, DFCreate_Menu to CodeJock command bars, and the
// FloatingPopupMenu right-click menu to cCJContextMenu.
//
// They belong together because they share the same hazards, and those hazards are in the
// class: the column/property translation, the constructor placement rule, and the xtpGrid* /
// xtpReport* constant renames all live in cGridToCJGridBase and its subclasses. A change to
// one of these usually means reading the others.
//
// Nothing about a function changes by living here: its { Published } / { Description }
// meta-tags travel with it, which is what MetaTagCheck, FunctionHelpGen and the Export /
// Import round-trip all read. Export reads the whole #Include set; Import refuses to write a
// function that lives here and says so (cExportImportFunctions.IncludedFileDefining).

    /* ChangeCodeJockReportToGrid - the EVIDENCE for the exclusions. The user-facing half of this
       comment moved into the { Description } on 2026-08-23, where the generated help can reach it;
       what is left is the inventory behind the one-line prefix rule stated there.

       ComReport* is DataFlex/Crystal Reports, not CodeJock: ComReportTitle, ComReportSource,
       ComReportTemplate, ComReportName, ComReportAuthor, ComReportSubject, ComReportComments,
       ComReportAlerts, ComReportObjects, ComReportSourceError, ComReportFormatStyle. Identical in
       20.1 and 26.0, with no ComGrid* counterpart - renaming them would break working code. They
       are excluded by construction: the match requires a CodeJock prefix, and "Com" is not one.
       The same protection covers Report.pkg, CrystalReport.pkg, Dfreport.pkg, cBasicReport,
       cAutoWebReport, WinReport/cWinReport2 and application names like psReportName.

       Renaming a customer subclass is ACCEPTED rather than overlooked: cCJReport / xtpReport are
       vendor namespaces, and a subclass is normally named for the application, so only the BASE
       matches and only the base is rewritten - which is the wanted result.

       TWO RECIPES BECAUSE THE MIGRATION IS NOT ALWAYS FOUND WHOLE (2026-08-30). Both discovery
       lanes - the 4313 recipe below and the Deep Scan rule - originally keyed on the PACKAGE name,
       so a workspace already sitting on the modern base class, whose only residue was a CONSTANT,
       was invisible to both: nothing in it mentions cCJReportControl, and the compiler does not
       name the package either. An unresolved constant is reported as "4306 Forward reference not
       resolved MSG_XTPREPORTTHEME..." - a message number that had no recipe at all, so the build
       broke on a line this function has always known how to rewrite. Hence the second recipe,
       keyed on XTPREPORT, and the eDSTokenPrefix scan rule beside it. */
    { Published = True }
    { Description = """
        Renames the CodeJock names that DataFlex 23.0 changed from 'Report' to 'Grid', when cCJReportControl.pkg became cCJGridControl.pkg.
        The Use line, the class names and the xtpReport/XTPReport constants are renamed together. The old names are defined only in OldcCJReportControl.pkg, so they must all be changed at the same time.
        Examples:
        - Use cCJReportControl.pkg -> Use cCJGridControl.pkg
        - Class cMyGrid is a cCJReportControl -> ... is a cCJGridControl
        - Set piTheme to xtpReportThemeNone -> Set piTheme to xtpGridThemeNone
        Only names with the CodeJock prefix are matched, so DataFlex's own Report classes and the ComReport* properties are never changed.
        OldcCJReportControl.pkg itself is not changed. It still defines all the old names, so a Use of it still compiles, with the obsolete-package warning 4536. Converting the Use line without the names, or the names without the Use line, would break the code, so this function converts both on every line, and never changes the one file that defines the old names.
        A workspace class whose name starts with cCJReport or xtpReport is renamed too. Only the base class is matched, so in 'Class cMyGrid is a cCJReportControl' the base class is renamed and the class's own name is kept.
        { MethodType = eStandardFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4313 | cCJReportControl | AutoFix }
        { ModRecipe = 4306 | XTPREPORT | AutoFix }
        { SummaryText = Renamed CodeJock Report symbols to their Grid names }
        """ }
    Function ChangeCodeJockReportToGrid String ByRef sLine String sParameter Returns Boolean
        Boolean bChanged
        Integer iItem iSize
        String  sToken sNew sResult
        tTokenizer TokenizerData

        Get pTokenizer to TokenizerData
        If (TokenizerData.bLineIsReady = True or TokenizerData.bIsInCommand = True or ;
            TokenizerData.bIsInImage = True) Begin
            Function_Return False
        End

        Move False to bChanged
        /* Driven off the TOKENS rather than the raw line: the tokenizer has already taken comments
           and string literals out, so a name mentioned in a comment or inside a literal cannot be
           rewritten here. */
        Move (SizeOfArray(TokenizerData.asLineTokens)) to iSize
        Decrement iSize
        For iItem from 0 to iSize
            Move TokenizerData.asLineTokens[iItem] to sToken
            Get CodeJockGridNameFor sToken to sNew
            If (sNew <> "") Begin
                Get ReplaceLineToken TokenizerData sLine sToken sNew to sResult
                If (sResult <> "") Begin
                    Move sResult to sLine
                    Move True to bChanged
                End
            End
        Loop

        Function_Return bChanged
    End_Function

    /* The MENU fragments of a run - every file but a .src that holds a legacy menu block - each
       resolved to the programs that pull it in, as the disk stands BEFORE the run writes anything:
       "<lowercased leaf>|<program path>" rows, one per program. asMenuFrags comes back with those
       fragments' lowercased paths, reached or not, so the walk can tell a menu nobody pulls in (said
       in the run notes) from a file with no menu at all (nothing for this converter).
       BY CONTENT, NOT EXTENSION (2026-09-11): the test was .mn / .mnu / .inc, so a pulldown kept in a
       .pkg was never resolved - and an .inc with no menu in it sent every program that Used it
       through the converter. Each fragment is read once here, and the folder's Use map is built once
       per folder rather than once per fragment. */
    Function _CJFragmentProgramMap String[] ByRef asFiles String[] ByRef asMenuFrags Returns String[]
        String[] asOut asProgs asCode asUseMap
        String sFile sLeaf
        Integer i iLast j jLast iStart iEnd
        Boolean bMenu bMapBuilt

        Move False to bMapBuilt
        Move (SizeOfArray(asFiles) - 1) to iLast
        For i from 0 to iLast
            Move (Trim(asFiles[i])) to sFile
            If (Lowercase(Right(sFile, 4)) <> ".src") Begin
                Move (rfReadEncodedFileAsStringArray(sFile)) to asCode
                Get _CJFindMenuBlock of ghoFuncLib (&asCode) 0 (&iStart) (&iEnd) to bMenu
                If (bMenu = True) Begin
                    Move (Lowercase(sFile)) to asMenuFrags[SizeOfArray(asMenuFrags)]
                    // The programs of the run's folders and the workspace's, read once at the first menu file - not
                    // only the menu file's own folder (2026-11-01, _CJMenuUseMapForFiles).
                    If (bMapBuilt = False) Begin
                        Get _CJMenuUseMapForFiles of ghoFuncLib asFiles "" to asUseMap
                        Move True to bMapBuilt
                    End
                    Move (Lowercase(ExtractFileName(sFile))) to sLeaf
                    Get _CJProgramsPullingIn of ghoFuncLib sLeaf (&asUseMap) 0 to asProgs
                    Move (SizeOfArray(asProgs) - 1) to jLast
                    For j from 0 to jLast
                        Move (sLeaf + "|" + asProgs[j]) to asOut[SizeOfArray(asOut)]
                    Loop
                End
            End
        Loop
        Function_Return asOut
    End_Function

    // The programs a fragment leaf resolved to, off the pre-run map.
    Function _CJFragmentProgramsFromMap String sLeaf String[] ByRef asMap Returns String[]
        String[] asOut
        String sKey
        Integer i iLast iLen

        Move (Lowercase(Trim(sLeaf)) + "|") to sKey
        Move (Length(sKey)) to iLen
        Move (SizeOfArray(asMap) - 1) to iLast
        For i from 0 to iLast
            If (Left(asMap[i], iLen) = sKey) ;
                Move (Right(asMap[i], (Length(asMap[i]) - iLen))) to asOut[SizeOfArray(asOut)]
        Loop
        Function_Return asOut
    End_Function

    /* One program through the converter, with the outcome in the run notes: converted (how many
       menu items), an EMPTY menu retired, or LEFT UNCONVERTED with the reason - the user's own
       procedures, no place to put the menu, nothing the emitter could read. Returns 1 when the
       program changed, 0 otherwise - so the function's total is PROGRAMS, which is what the engine's
       "N file(s) Refactored" line has always claimed it was (the first live run said "1202 file(s)"
       for 20 programs' worth of menu items).
       bBackupFirst is True exactly when the program was reached through a FRAGMENT - it was not in
       the engine's list, so nothing backed it up. For such a program, finding no block at all is a
       reason too: the fragment was the whole point of the visit (2026-09-11: three files passed,
       "0 file(s) Refactored", and not one run note). A .src handed in with no menu is a program
       with no menu, and stays quiet. */
    Function _CJConvertOneProgram String sFile Boolean bBackupFirst Returns Integer
        String sLeaf sFirst sOmitted sDecline sKept
        Integer iItems iProcs iShipped

        Move (ExtractFileName(sFile)) to sLeaf
        Get _CJConvertProgramFile of ghoFuncLib sFile bBackupFirst to iItems
        If (iItems > 0) Begin
            Get piCJShippedOmitted of ghoFuncLib to iShipped
            Move "" to sOmitted
            If (iShipped > 0) ;
                Move (" " + String(iShipped) + " line(s) of the shipped *_PM.inc fragments' own code (their OnInitMenu shadowing, #warning) were omitted - the cCJ* items carry that behaviour.") to sOmitted
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "ChangeDFCreateMenuToCodeJock" (sLeaf + ": " + String(iItems) + " menu item(s) -> CodeJock command bars." + sOmitted)
            Function_Return 1
        End
        If (pbCJEmptyMenu(ghoFuncLib) = True) Begin
            If (ghoStatusLog <> 0) ;
                Send AddRunNote "ChangeDFCreateMenuToCodeJock" (sLeaf + ": its legacy menu is EMPTY - commented out, with no CodeJock menu bar in its place (there is nothing to put in one).")
            Function_Return 1
        End
        Get piCJUserProcs of ghoFuncLib to iProcs
        Move "" to sKept
        If (pbCJLegacyMenuKept(ghoFuncLib) = True) ;
            Move " Until then 'Use Dfdeomnu.pkg' (obsolete, still shipped; it brings Dfmenu.pkg) keeps the legacy menu compiling as it is - it was added to the program." to sKept
        If (iProcs > 0 and ghoStatusLog <> 0) Begin
            Get psCJFirstUserProc of ghoFuncLib to sFirst
            Send AddRunNote "ChangeDFCreateMenuToCodeJock" ("LEFT UNCONVERTED " + sLeaf + ": its menu block carries " + String(iProcs) + " hand-written Procedure/Function declaration(s) other than OnInitMenu (first: " + sFirst + ") that the converter cannot translate - commenting them out would drop that behaviour in silence. Port them to the CodeJock objects by hand first, then run again." + sKept)
        End
        Else If (iProcs = 0 and ghoStatusLog <> 0) Begin
            Get psCJDecline of ghoFuncLib to sDecline
            If (sDecline = "" and bBackupFirst = True) ;
                Move "it pulls a menu fragment in, but not where the converter reads a menu - inside its own DFCreate_Menu block, or through a Use of a .mn / .mnu file" to sDecline
            If (sDecline <> "") ;
                Send AddRunNote "ChangeDFCreateMenuToCodeJock" ("LEFT UNCONVERTED " + sLeaf + ": " + sDecline + "." + sKept)
        End
        Function_Return 0
    End_Function

/* The legacy pull-down menu system -> CodeJock command bars.

   SCOPE, and why it is this narrow (Nils 2026-08-11). Only a .src is WRITTEN. Measured over the
   DF18/DF19 trees, 1,394 DFCreate_Menu blocks live in .src (906), .mn (231), .inc (185), .pkg (58)
   and a handful of .vw/.dg - but a menu is only meaningful where the Panel is, and the Panel is in
   the program file. The fragments are READ and inlined instead (see _CJExpandMenuIncludes), because
   a legacy Main_Menu is mostly #INCLUDE lines: converting only what is physically in the .src would
   emit a menu bar carrying one pulldown and leave File/Navigate/Window/Help legacy.

   ORDER-INDEPENDENT ON PURPOSE. A run executes its functions alphabetically, so this one runs
   BEFORE RefactorWorkspaceTocApplication and cannot assume the modern shell exists. It finds its own
   anchor: an existing cCJCommandBarSystem to nest inside, else the client area, bringing the system
   with it. Both orders converge on the same shape.

   The user-facing half of this note (what it deliberately does not do, and the order / re-run
   guarantee) now lives in the { Description }, which is what the manual is generated from. */
    { Published = True }
    { Description = """
        Converts the legacy DFCreate_Menu / On_Item pull-down menus to a CodeJock menu bar.
        Standard DEO menu items become the cCJ* classes that come with DataFlex, with their own translated captions. The program's own items become cCJMenuItem objects whose OnExecute sends the same message.
        Menu files included with #INCLUDE are copied into the program, from the program's folder or from the Pkg folder of the target DataFlex installation (File_pm.inc, Navi_pm.inc ...). If you select a menu file itself (a .mn or .mnu file, or an .inc or .pkg file with a pull-down menu), the program that includes it is converted; the menu file is never changed.
        A pull-down menu's OnInitMenu becomes the menu's OnPopupInit: Shadow_State Item N becomes the opposite of pbEnabled of the Nth item, Select_State becomes pbChecked, and the rest is copied as it is. A separator, or an item number that is not a fixed number, is left with a TODO line. An included file that contains only methods stays an #Include inside the menu bar object.
        The legacy menu is commented out, never deleted; an empty menu does not get a menu bar. The function finds where to add the menu bar itself (an existing cCJCommandBarSystem, or else the client area), so it can run before or after the conversion of the application window, and running it a second time changes nothing.
        Not converted: a program whose menu contains other procedures or functions of its own is left unchanged and named in the run notes. A menu file that no program includes is reported, not converted. Shortcut key texts are kept as comments, not set up as shortcut keys.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { SummaryText = Refactored: DFCreate_Menu -> CodeJock command bars }
        """ }

    Function ChangeDFCreateMenuToCodeJock String[] ByRef asFiles String sParameter Returns Integer
        String[] asIncluders asDone asFragVia asMenuFrags asConverted
        String sFile sExt sProg sVia sNot
        Integer iFile iFileLast iChanged iTotal iInc iIncLast
        Boolean bPanel bCancel

        Move 0 to iTotal
        Move (SizeOfArray(asFiles) - 1) to iFileLast
        If (iFileLast < 0) ;
            Function_Return 0
        Move (Active_State(ghoStatusPanel)) to bPanel
        Move False to bCancel
        // Every MENU fragment in the list, resolved to its programs BEFORE the first write (see the
        // fragment branch below): "<lowercased leaf>|<program>" rows, and the fragments themselves.
        Get _CJFragmentProgramMap (&asFiles) (&asMenuFrags) to asFragVia
        For iFile from 0 to iFileLast
            If (bCancel = False) Begin
                Move asFiles[iFile] to sFile
                If (bPanel = True) Begin
                    Set Caption_Text   of ghoStatusPanel to ("File No:" * String(iFile + 1) * "of:" * String(iFileLast + 1))
                    Set Title_Text     of ghoStatusPanel to "Converting menus:"
                    Set TableName_Text of ghoStatusPanel to sFile
                    Send DoAdvanceTot of ghoStatusPanel
                End
                // A menu belongs where the Panel is. Fragments are READ from here (see the header),
                // never written, so the engine's per-file backup covers everything this touches.
                // Extension by tail-compare: a program file converts; a MENU FILE (.mn / .mnu -
                // LegacyApp keeps the whole block there, "Use LegacyApp_5.mn", and the scan flags it)
                // resolves to the program(s) that pull it in, and those convert (Nils 2026-09-04:
                // 19 files passed, 16 of them .mn, 0 refactored). A program is converted once per
                // run however many ways it is reached.
                // ANY FILE BUT A PROGRAM that holds a legacy menu is a fragment (2026-09-11): the test
                // was .mn / .mnu / .inc by extension, and a .pkg handed in fell through every branch -
                // "0 file(s) Refactored", not a word why. A file with no menu block is nothing for this
                // converter and passes quietly (_CJFragmentProgramMap sorted them, before any write).
                Move (Lowercase(Right(Trim(sFile), 4))) to sExt
                If (sExt = ".src") Begin
                    If (SearchArray(Lowercase(sFile), asDone) = -1) Begin
                        Move (Lowercase(sFile)) to asDone[SizeOfArray(asDone)]
                        Get _CJConvertOneProgram sFile False to iChanged
                        Move (iTotal + iChanged) to iTotal
                        If (iChanged > 0) ;
                            Move (Lowercase(sFile)) to asConverted[SizeOfArray(asConverted)]
                    End
                End
                Else If (SearchArray(Lowercase(Trim(sFile)), asMenuFrags) <> -1) Begin
                    /* A fragment - a menu file, or a pulldown .inc a menu file #includes - resolves
                       through the chain to the program(s) at its top (_CJProgramsPullingIn). READ
                       OFF THE PRE-RUN MAP, not the disk as it stands: converting ORDER.SRC comments
                       its "Use Order.mn", so HELP_APP.inc - handed in next - then read as pulled in
                       by nobody and was logged SKIPPED, seconds after it had been converted through
                       that very program (Nils 2026-09-04). asFragVia is that map, built once below
                       before anything is written. */
                    Get _CJFragmentProgramsFromMap (ExtractFileName(sFile)) (&asFragVia) to asIncluders
                    Move (SizeOfArray(asIncluders) - 1) to iIncLast
                    If (iIncLast < 0 and ghoStatusLog <> 0) ;
                        Send AddRunNote "ChangeDFCreateMenuToCodeJock" ("SKIPPED " + (ExtractFileName(sFile)) + " - no program pulls this menu fragment in (directly, or through a menu file that a program uses), so there is no program to place the CodeJock menu in. A fragment is never converted in place.")
                    Move "" to sVia
                    Move "" to sNot
                    For iInc from 0 to iIncLast
                        Move asIncluders[iInc] to sProg
                        If (SearchArray(Lowercase(sProg), asDone) = -1) Begin
                            Move (Lowercase(sProg)) to asDone[SizeOfArray(asDone)]
                            Get _CJConvertOneProgram sProg True to iChanged
                            Move (iTotal + iChanged) to iTotal
                            If (iChanged > 0) ;
                                Move (Lowercase(sProg)) to asConverted[SizeOfArray(asConverted)]
                        End
                        // Already through the converter this run: say whether it converted (2026-11-01) - a program
                        // that changed nothing was reported as "converted with it".
                        Else If (SearchArray(Lowercase(sProg), asConverted) <> -1) ;
                            Move (sVia + (If((sVia = ""), "", ", ")) + (ExtractFileName(sProg))) to sVia
                        Else ;
                            Move (sNot + (If((sNot = ""), "", ", ")) + (ExtractFileName(sProg))) to sNot
                    Loop
                    If (sVia <> "" and ghoStatusLog <> 0) ;
                        Send AddRunNote "ChangeDFCreateMenuToCodeJock" ((ExtractFileName(sFile)) + ": reached through " + sVia + ", converted with it in this run.")
                    If (sNot <> "" and ghoStatusLog <> 0) ;
                        Send AddRunNote "ChangeDFCreateMenuToCodeJock" ((ExtractFileName(sFile)) + ": pulled in by " + sNot + ", which this run did not convert - their own notes say why.")
                End
                // Mid-run cancel: poll the safe accessor (NEVER Cancel_Check - it consumes the signal).
                Get pbUserCancelRequested of ghoEngine to bCancel
            End
        Loop
        If (bPanel = True) ;
            Set Title_Text of ghoStatusPanel to ""
        Function_Return iTotal
    End_Function

    /* FloatingPopupMenu / dbFloatingPopupMenu -> cCJContextMenu (2026-09-13). The grammar, the
       dispatch rule, what a dbFloatingPopupMenu inherits and why the object keeps its name are
       measured and written up on the pure core in cRefactorFuncLib.pkg (_CJPopupBlockToContextMenu
       and _CJConvertPopupMenusInFile). This wrapper is the run notes: one line per object converted,
       one per object refused with its reason, and - once per file - what the converted menu needs
       at run time. The engine writes the file on the ACTUAL change, so a refusal marker lands even
       when nothing converted, and the count stays what it says: objects converted.
       What the { Description } has no room for: a program without a cCJCommandBarSystem gets
       "Context menu not attached to commandbars" when the converted menu pops (ChangeDFCreateMenuToCodeJock
       and RefactorWorkspaceTocApplication both bring one - the run notes say so); the ten inherited
       DEO items keep the absolute indexes the legacy object used, so a Shadow_State on them translates
       too; a legacy accelerator is carried as a comment, never bound. */
    { Published = True }
    { Description = """
        Converts a FloatingPopupMenu or dbFloatingPopupMenu object (the legacy right-click menu) to a cCJContextMenu, with one item object for each menu item.
        The object keeps its name, so every 'Set Floating_Menu_Object to (x(Current_Object))' and 'Send Popup to (x(Current_Object))' line still works.
        On_Item and Add_Item lines become item objects; a line that continues with ';' is read as a whole. A standard message (Prompt, Request_Save ...) becomes the cCJ* class that comes with DataFlex, with its own translated caption. The program's own message becomes a cCJMenuItem that sends it to the object with the focus, as the legacy menu did, or to the target named after 'to'.
        A Property declaration is kept, and a Set Aux_Value line is commented out with a note. Msg_None becomes pbControlBeginGroup on the next item, and Status_Help becomes psToolTip.
        For a dbFloatingPopupMenu, its ten inherited items come first, as the standard DEO classes. A Popup procedure in the object is kept, with 'Set Shadow_State Item N' changed to pbEnabled of the Nth item.
        The legacy object is commented out below the new one, never deleted, and the Use lines that the item classes need are added.
        Not converted, each with a comment that gives the reason: any other procedure or function of its own, an If statement around the items, an object inside the menu, or a caption that is an expression. A subclass is converted by ConvertPopupMenuSubclassToCodeJock instead.
        The converted menu needs the program's cCJCommandBarSystem when it runs.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { ModRecipe = 4537 | class: FLOATINGPOPUPMENU | AutoFix }
        { ModRecipe = 4537 | class: DBFLOATINGPOPUPMENU | AutoFix }
        { SummaryText = Refactored: FloatingPopupMenu -> cCJContextMenu }
        """ }
    Function ChangeFloatingPopupMenuToCodeJock String[] ByRef asCode String sParameter Returns Integer
        String[] asDone asRefused
        String sFile sName sWhat
        Integer iCount i iBar

        Get _CJConvertPopupMenusInFile of ghoFuncLib (&asCode) (&asDone) (&asRefused) to iCount
        If (ghoStatusLog = 0) ;
            Function_Return iCount
        Move "" to sFile
        If (ghoEngine <> 0) ;
            Get psCurrentSourceFileName of ghoEngine to sFile
        Move (ExtractFileName(sFile)) to sFile
        If (Trim(sFile) <> "") ;
            Move (Trim(sFile) + ": ") to sFile
        For i from 0 to (SizeOfArray(asDone) - 1)
            Move (Pos("|", asDone[i])) to iBar
            Move (Left(asDone[i], (iBar - 1))) to sName
            Move (Mid(asDone[i], (Length(asDone[i]) - iBar), (iBar + 1))) to sWhat
            Send AddRunNote "ChangeFloatingPopupMenuToCodeJock" (sFile + sName + " -> cCJContextMenu, " + sWhat + " item object(s); the legacy object is commented out below it.")
        Loop
        For i from 0 to (SizeOfArray(asRefused) - 1)
            Move (Pos("|", asRefused[i])) to iBar
            Move (Left(asRefused[i], (iBar - 1))) to sName
            Move (Mid(asRefused[i], (Length(asRefused[i]) - iBar), (iBar + 1))) to sWhat
            Send AddRunNote "ChangeFloatingPopupMenuToCodeJock" (sFile + "LEFT UNCONVERTED " + sName + " - " + sWhat + ". A marker above the object says the same; clear that and run again, or port it to cCJContextMenu by hand.")
        Loop
        If (iCount > 0) ;
            Send AddRunNote "ChangeFloatingPopupMenuToCodeJock" (sFile + "a converted context menu attaches to the program's cCJCommandBarSystem when it pops; a program without one raises 'Context menu not attached to commandbars' there. ChangeDFCreateMenuToCodeJock and RefactorWorkspaceTocApplication both bring one.")
        Function_Return iCount
    End_Function

    /* ConvertPopupMenuSubclassToCodeJock (2026-10-05): a workspace SUBCLASS of FloatingPopupMenu, converted
       in place. Asked for on the one popup row a workspace had left after its plan run (Nils: "Couldn't we
       provide a refactoring function for FloatingPopupMenu ...?") - an empty subclass, created at run time
       and filled through Add_Item, which ChangeFloatingPopupMenuToCodeJock above has no item list to read
       from. What the class keeps, where an item's message goes, what is refused and why no marker is
       written are on the pure core in cRefactorFuncLib.pkg (_CJPopupClassToContextMenu and its neighbours).
       This wrapper is the run notes.
       REVIEW, never Auto-fix (the DS 9229 rule): the class file cannot show which OTHER FloatingPopupMenu
       messages some code sends to the menu, and those fail when they run, not when they compile - so a
       person looks before this runs. The compiler reports nothing on a subclass line, so there is no
       { ModRecipe } to carry: the scan's row is the only one, and it asks the core for its verdict. */
    { Published = True }
    { Description = """
        Converts a workspace subclass of FloatingPopupMenu (the legacy right-click menu) to a subclass of cCJContextMenu: Class MyPopup is a FloatingPopupMenu becomes Class MyPopup is a cCJContextMenu.
        - The class gets its own Add_Item and Item_Count. Code that fills the menu while the program runs (Send Add_Item of hoMenu ...) and code that shows it (Send Popup) are not changed.
        - A small item class, MyPopupItem, is added above the class. Add_Item creates one item object for each call. A selected item sends its message to the object that has the focus, as the legacy menu did; the function ItemMessageTarget in the class is where you change that.
        - An Add_Item with Msg_None and no text was a separator: the next item starts a new group.
        - Use cCJCommandBarSystem.pkg is added when the file does not already have it.
        The class is converted only when it contains nothing but Construct_Object and End_Construct_Object with Add_Item and Property lines. A class that contains more is not changed, and the run notes explain why.
        Not converted: any other FloatingPopupMenu message that the code sends to the menu (Delete_Data, Shadow_State, Aux_Value ...). Such a line still compiles, but fails when it runs, so look for these lines yourself. This is why the function is listed for review and is not selected automatically.
        A dbFloatingPopupMenu subclass is not converted. The menu needs the program's cCJCommandBarSystem when it runs.
        { MethodType = eOtherFunction }
        { FnGroup = Modernization }
        { SummaryText = Converted in place: FloatingPopupMenu subclass -> cCJContextMenu }
        """ }
    Function ConvertPopupMenuSubclassToCodeJock String[] ByRef asCode String sParameter Returns Integer
        String[] asDone asRefused
        String  sFile sName sWhat
        Integer iCount i iBar

        Get _CJConvertPopupClassesInFile of ghoFuncLib (&asCode) (&asDone) (&asRefused) to iCount
        If (ghoStatusLog = 0) ;
            Function_Return iCount
        Move "" to sFile
        If (ghoEngine <> 0) ;
            Get psCurrentSourceFileName of ghoEngine to sFile
        Move (ExtractFileName(sFile)) to sFile
        If (Trim(sFile) <> "") ;
            Move (Trim(sFile) + ": ") to sFile
        For i from 0 to (SizeOfArray(asDone) - 1)
            Move asDone[i] to sName
            Send AddRunNote "ConvertPopupMenuSubclassToCodeJock" (sFile + sName + " is a cCJContextMenu now. It answers Add_Item and Item_Count itself, through the new item class " + sName + "Item above it, so the code that fills and shows the menu was not changed. NOT carried: any other FloatingPopupMenu message that code sends to this menu (Delete_Data, Shadow_State, Aux_Value...) - such a line compiles and fails when it runs, so search for it by hand. A chosen item sends its message to the object that has the focus, as before; ItemMessageTarget in " + sName + " is the place to change that.")
        Loop
        For i from 0 to (SizeOfArray(asRefused) - 1)
            Move (Pos("|", asRefused[i])) to iBar
            Move (Left(asRefused[i], (iBar - 1))) to sName
            Move (Mid(asRefused[i], (Length(asRefused[i]) - iBar), (iBar + 1))) to sWhat
            Send AddRunNote "ConvertPopupMenuSubclassToCodeJock" (sFile + "LEFT AS IT IS: " + sName + " - " + sWhat + ". Nothing was written; port the class to cCJContextMenu by hand.")
        Loop
        If (iCount > 0) ;
            Send AddRunNote "ConvertPopupMenuSubclassToCodeJock" (sFile + "a converted context menu attaches to the program's cCJCommandBarSystem when it pops; a program without one raises 'Context menu not attached to commandbars' there. ChangeDFCreateMenuToCodeJock and RefactorWorkspaceTocApplication both bring one.")
        Function_Return iCount
    End_Function

    /* RefactorDbGridTocDbCJGrid - the transform list now lives in the { Description }, where the
       generated help can reach it (restored 2026-08-23: the limit that forced it out here was
       believed to be ~1024, and is actually ~2215).
       The v54 ERROR routes (4345/4328 U_DBGRID + 4298 BEGIN_ROW/END_ROW) cover the workspace where
       dbGrid no longer resolves at all - the same warning-vs-error gap as the WinPrint v52 routes. */
    { Published = True }
    { Description = """
        Converts legacy DbGrid objects to a CodeJock grid class, with one column object for each column.
        The function's parameter is 'OldGridClass,NewGridClass[,NewColumnClass]'. When it is empty, only DbGrid objects are converted, to cDbCJGrid and cDbCJGridColumn, and objects of workspace subclasses are not changed.
        For each DbGrid object found, only the code of that object is changed, never the rest of the file:
        - The class is changed to the new grid class.
        - The Begin_Row / Entry_Item list becomes one column object for each column.
        - Set Form_Width Item N to W becomes Set piWidth to W on each column.
        - Set Header_Label Item N to "L" becomes Set psCaption to "L" on each column.
        - Grid properties that only the legacy grid has are removed: Main_File, Wrap_State, peResizeColumn and psColumnsID.
        - The standard Entry_Display procedure is removed.
        - Everything else (other Set lines, objects inside the grid) is kept unchanged.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { ModRecipe = 4537 | class: DBGRID | AutoFix }
        { ModRecipe = 4533 | Begin_Row | Suggest }
        { ModRecipe = 4345 | U_DBGRID | Suggest }
        { ModRecipe = 4328 | U_DBGRID | Suggest }
        { ModRecipe = 4298 | BEGIN_ROW | Suggest }
        { ModRecipe = 4298 | END_ROW | Suggest }
        { EnumList = "ANY" }
        { ParamHelp = Leave EMPTY to convert the plain DbGrid objects to cDbCJGrid with cDbCJGridColumn columns. Objects of workspace subclasses of DbGrid stay as they are: a plain cDbCJGrid would lose what a subclass adds, so port the subclass first. Then name ONE class to convert only that class, as three comma separated class names;
        \nMyDbGrid - Workspace subclass of DbGrid,
        \nMycDbCJGrid - Workspace subclass of cDbCJGrid,
        \nMycDbCJGridColumn - Workspace subclass of cDbCJGridColumn }
        { SummaryText = Refactored: DbGrid -> cDbCJGrid }
        """ }
    Function RefactorDbGridTocDbCJGrid String[] ByRef asFiles String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        If (SizeOfArray(asFiles) = 0) Begin
            Function_Return 0
        End

        Get Create (RefClass(cDbGridTocDbCJGrid)) to ho
        If (ho = 0) Begin
            Error "Could not create cDbGridTocDbCJGrid object. (Function: RefactorDbGridTocDbCJGrid)"
            Function_Return 0
        End

        Get TransformDbGridTocDbCJGrid of ho asFiles sParameter to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* These comments were moved here from the { Description } meta tag, as it 
       seems that the DataFlex metatag buffer was overflowed(?), leading to an unsuccessful compilation.
      
        - Translates dbList selection properties to their cDbCJGridPromptList
          equivalent (each with a TODO note where the mapping is approximate):
            Auto_Server_State -> pbAutoServer, Auto_Column_State -> pbAutoColumn,
            Popup_Search_State / Find_Search_State -> pbAutoSearch,
            Export_Item_State -> peUpdateMode (umPromptValue/umPromptRelational).
            Auto_Export_State / Auto_Index_State / Move_Value_Out_State /
            Auto_Shadow_State / Auto_Label_State -> TODO comment only.

        - SUBCLASSES (e.g. a project's own dbList0 / cMyDbList): an EMPTY parameter converts base
          dbList objects only - a subclass object stays as it is, because a plain cDbCJGridPromptList
          would lose what the subclass adds (Nils 2026-10-03 - see cGridToCJGridBase.SubclassToLeave).
          Port the subclass first, then pass it as the OldListClass with the ported class as the
          target: "dbList0,cMyCJPromptList,cDbCJGridColumn". An explicit OldListClass is an EXACT
          match, so that run converts ONLY the named class. Detection is deliberately opt-in per
          class: this is a code-MUTATING class swap, and blindly converting a subclass mis-converts
          behaviour the subclass adds. (Nils' call 2026-07-03, and again 2026-10-03.)
    */
    /* The transform list now lives in the { Description }, where the generated help can reach it
       (restored 2026-08-23: the limit that forced it out here was believed to be ~1024, and is
       actually ~2215).
       The v54 ERROR routes (4345/4328 U_DBLIST + 4298 BEGIN_ROW/END_ROW) cover the workspace where
       dbList no longer resolves at all - the same warning-vs-error gap as the WinPrint v52 routes. */
    { Published = True }
    { Description = """
        Converts legacy dbList selection lists to cDbCJGridPromptList prompt lists.
        The function's parameter is 'OldListClass,NewGridClass[,NewColumnClass]'. When it is empty, only dbList objects are converted, to cDbCJGridPromptList and cDbCJGridColumn, and objects of workspace subclasses are not changed.
        For each dbList object found, only the code of that object is changed, never the rest of the file:
        - The class is changed to the new prompt-list class.
        - The Begin_Row / Entry_Item list becomes one column object for each column.
        - Set Form_Width Item N to W becomes Set piWidth to W on each column.
        - Set Header_Label Item N to "L" becomes Set psCaption to "L" on each column.
        - A TODO comment is added once, saying that the object that opens the list needs a Prompt_Callback procedure (the peUpdateMode pattern).
        - The dbModalPanel around the list, and the object that opens it, are not changed.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { EnumList = "ANY" }
        { ModRecipe = 4537 | class: DBLIST | AutoFix }
        { ModRecipe = 4533 | Begin_Row | Suggest }
        { ModRecipe = 4345 | U_DBLIST | Suggest }
        { ModRecipe = 4328 | U_DBLIST | Suggest }
        { ModRecipe = 4298 | BEGIN_ROW | Suggest }
        { ModRecipe = 4298 | END_ROW | Suggest }
        { ParamHelp = Leave EMPTY to convert the plain dbList objects to cDbCJGridPromptList with cDbCJGridColumn columns. Objects of workspace subclasses of dbList stay as they are: a plain cDbCJGridPromptList would lose what a subclass adds, so port the subclass first. Then name ONE class to convert only that class, as three comma separated class names;
        \nMyDbList - Workspace subclass of DbList,
        \nMycDbCJGridPromptList - Workspace subclass of cDbCJGridPromptList,
        \nMycDbCJGridColumn - Workspace subclass of cDbCJGridColumn }
        { SummaryText = Refactored: dbList -> cDbCJGridPromptList }
        """ }
    Function RefactorDbListTocDbCJGridPromptList String[] ByRef asFiles String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        If (SizeOfArray(asFiles) = 0) Begin
            Function_Return 0
        End

        Get Create (RefClass(cDbListTocDbCJGridPromptList)) to ho
        If (ho = 0) Begin
            Error "Could not create cDbListTocDbCJGridPromptList object. (Function: RefactorDbListTocDbCJGridPromptList)"
            Function_Return 0
        End

        Get TransformDbListTocDbCJGridPromptList of ho asFiles sParameter to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* These comments were moved here from the { Description } meta tag, as it 
       seems that the DataFlex metatag buffer was overflowed(?), leading to an unsuccessful compilation.
     
       - Translates known properties to their cCJGrid equivalents, e.g.:
          Set peResizeColumn          ->  Set pbAllowColumnResize
          Set Prompt_Button_Mode      ->  Set pbHeaderPrompts
          Set Allow_Top_Add_State     ->  Set pbAllowAppendRow
          Set Allow_Bottom_Add_State  ->  Set pbAllowAppendRow
          Set Allow_Insert_Add_State  ->  Set pbAllowInsertRow
          Set Auto_Save_State         ->  Set pbAutoSave
          Set No_Create_State         ->  Set pbAllowAppendRow + Set pbAllowInsertRow (inverted)
          Set No_Delete_State         ->  Set pbAllowDeleteRow (inverted)
          Set Read_Only_State         ->  Set pbReadOnly
          Set CurrentRowColor         ->  Set piHighlightBackColor
          Set CurrentCellColor        ->  Set piFocusCellBackColor
          Set CurrentRowTextColor     ->  Set piHighlightForeColor
          Set CurrentCellTextColor    ->  Set piFocusCellForeColor
    */
    { Published = True }
    { Description = """
        Converts legacy Grid objects that are not connected to a database to a CodeJock grid class.
        For each Grid object found in the selected files, only the code of that object is changed, never the rest of the file:
        - Known properties are changed to their cCJGrid equivalents, and the class is changed to the new grid class.
        - Grid properties that only the legacy grid has are removed: Wrap_State, peResizeColumn and psColumnsID.
        - The Entry_Display procedure is commented out. Colour settings found in it are converted and placed above the commented-out procedure.
        - Methods that only the legacy grid has are commented out, with a TODO comment.
        - The columns oCol1..oColN are created from the object's own Set Form_Width and Set Header_Label lines. A grid without columns, which fills itself, is not changed, and a note says so.
        The function's parameter is a list of 2 or 3 class names, separated by commas: OldGridClass,NewGridClass[,NewGridColumnClass]
        Example: "cMyGrid,cCJGrid,cCJGridColumn"
        When the parameter is empty, plain Grid objects are converted to the standard DataFlex classes cCJGrid and cCJGridColumn, and objects of workspace Grid subclasses are not changed.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { ModRecipe = 4537 | class: GRID | AutoFix }
        { EnumList = "ANY" }
        { ParamHelp = Leave EMPTY to convert the plain Grid objects to cCJGrid with cCJGridColumn columns. Objects of workspace subclasses of Grid stay as they are: a plain cCJGrid would lose what a subclass adds, so port the subclass first. Then name ONE class to convert only that class, as three comma separated class names;
        \nMyGrid - Workspace subclass of Grid,
        \nMycCJGrid - Workspace subclass of cCJGrid,
        \nMycCJGridColumn - Workspace subclass of cCJGridColumn }
        { SummaryText = Refactored: Grid -> cCJGrid }
        """ }
    Function RefactorGridToCJGrid String[] ByRef asFiles String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        If (SizeOfArray(asFiles) = 0) Begin
            Function_Return 0
        End

        Get Create (RefClass(cGridToCJGrid)) to ho
        If (ho = 0) Begin
            Error "Could not create cGridToCJGrid object. (Function: RefactorGridToCJGrid)"
            Function_Return 0
        End

        Get TransformGridToCJGrid of ho asFiles sParameter to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* cListToCJGrid: legacy non-data-aware List (single-column item list) -> cCJGrid. It SUBCLASSES
       the Grid->cCJGrid engine (cGridToCJGrid), so a List filled programmatically (a method calling
       Send Add_Item, with Send Delete_Data / Set Dynamic_Update_State / Set Current_Item) has its
       BODY converted like a Grid's: each Send Add_Item becomes a TheData row, Current_Item / Value /
       Mouse_Click handlers convert. The fill method KEEPS its original name + parameters (a List's
       fill is called from OTHER objects, Send <name> of oList <data>, so renaming it to LoadData or
       dropping the param would break those callers) and gets NO Activating stub (the external caller
       drives the fill). A List filled STATICALLY via Item_List / On_Item "text" instead gets a
       GENERATED Procedure LoadData built from those prompts + an Activating stub (a non-None On_Item
       message -> an OnRowChange TODO). On top of the Grid engine this class: injects ONE cCJGridColumn
       (oCol1 - a List has no Form_Width), hides the header (single column), PRESERVES bare Send
       statements inside custom event procedures (OnChange, Mouse_Up, ...) that the Grid engine would
       otherwise comment out as fill artifacts, and DROPS the redundant 'If (Item_count) Set
       Current_item' cursor idiom (Send MoveToFirstRow already selects the first row).
    */
    { Published = True }
    { Description = """
        Converts a legacy List (a list of items in one column) to a cCJGrid object, with one cCJGridColumn whose header is hidden.
        A method that fills the list with Send Add_Item keeps its name and parameters, because other objects call it, and each Add_Item in it becomes a row of the grid's data. A fixed Item_List / On_Item block becomes a LoadData procedure, which is called when the grid is activated.
        Event procedures of the object itself, such as OnChange and Mouse_Up, are kept.
        The function's parameter is a list of 2 or 3 class names, separated by commas: OldListClass,NewGridClass[,NewGridColumnClass]
        When the parameter is empty, plain List objects are converted to the standard cCJGrid and cCJGridColumn, and objects of workspace List subclasses are not changed.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { ModRecipe = 4537 | class: LIST | AutoFix }
        { EnumList = "ANY" }
        { ParamHelp = Leave EMPTY to convert the plain List objects to cCJGrid with cCJGridColumn columns. Objects of workspace subclasses of List stay as they are: a plain cCJGrid would lose what a subclass adds, so port the subclass first. Then name ONE class to convert only that class, as three comma separated class names;
        \nMyList - Workspace subclass of List,
        \nMycCJGrid - Workspace subclass of cCJGrid,
        \nMycCJGridColumn - Workspace subclass of cCJGridColumn }
        { SummaryText = Refactored: List -> cCJGrid }
        """ }
    Function RefactorListToCJGrid String[] ByRef asFiles String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        If (SizeOfArray(asFiles) = 0) Begin
            Function_Return 0
        End

        Get Create (RefClass(cListToCJGrid)) to ho
        If (ho = 0) Begin
            Error "Could not create cListToCJGrid object. (Function: RefactorListToCJGrid)"
            Function_Return 0
        End

        Get TransformListToCJGrid of ho asFiles sParameter to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* ConvertGridSubclassToCodeJock: a workspace's OWN subclass of a legacy grid, converted IN PLACE together
       with every object of it (design 2026-10-03, built 2026-10-04). The four converters above leave such
       objects as they are - a plain CodeJock grid would lose what the subclass adds - and this is the way on.
       The engine is cGridSubclassPorter.pkg; the block at its top says what is ported and how, and why the
       run is all or nothing. */
    { Published = True }
    { Description = """
        Converts the workspace's subclasses of the legacy grids, together with every object of each subclass: Class MyDbGrid is a dbGrid becomes Class MyDbGrid is a cDbCJGrid, and its objects keep their class name.
        - This function runs the three grid converters itself, on the objects: RefactorDbGridTocDbCJGrid for a dbGrid subclass, RefactorDbListTocDbCJGridPromptList for a dbList subclass, and RefactorGridToCJGrid for a Grid subclass. You do not need to select those three, and their parameters are not used: this function tells each of them which class it converts.
        - dbGrid becomes cDbCJGrid, dbList becomes cDbCJGridPromptList and Grid becomes cCJGrid, and the Use line of the package is changed to match.
        - The class's header label and help text settings (Set Header_Label, Status_Help) move to a new column class in the same package, MyDbGridColumn.
        - A class is converted together with all of its objects, or not at all. A class that cannot be converted is not changed, and the run notes explain why.
        { MethodType = eOtherFunctionAll }
        { FnGroup = Modernization }
        { EnumList = "ANY" }
        { ParamHelp = Leave it empty to convert every grid subclass the selected files declare. To convert one class only, give its name, e.g. MyDbGrid. The parameters of RefactorDbGridTocDbCJGrid, RefactorDbListTocDbCJGridPromptList and RefactorGridToCJGrid are not used here. }
        { SummaryText = Converted in place: a grid subclass and its objects }
        """ }
    Function ConvertGridSubclassToCodeJock String[] ByRef asFiles String sParameter Returns Integer
        Handle  ho
        Integer iRetval

        If (SizeOfArray(asFiles) = 0) Begin
            Function_Return 0
        End

        Get Create (RefClass(cGridSubclassPorter)) to ho
        If (ho = 0) Begin
            Error "Could not create cGridSubclassPorter object. (Function: ConvertGridSubclassToCodeJock)"
            Function_Return 0
        End

        Get ConvertSubclass of ho asFiles sParameter to iRetval
        Send Destroy of ho
        Function_Return iRetval
    End_Function

    /* Can the grid subclass sClass, declared in sClassFile, be converted in place by the function above? ""
       when it can; otherwise why not (cGridSubclassPorter.SubclassVerdict has the questions). The Deep Scan
       asks this once per learned subclass and Check, with the class declarations it learned - asNames /
       asSupers / asDeclFiles, parallel - so a row offers the conversion only where the run will make it.
       Here because the scanner cannot Use the converters: they Use the analyzer. */
    Function GridSubclassWhyNot String sClass String sClassFile String[] ByRef asNames String[] ByRef asSupers String[] ByRef asDeclFiles Returns String
        String[] asLines
        String   sWhy
        Handle   ho

        Get Create (RefClass(cGridSubclassPorter)) to ho
        If (ho = 0) ;
            Function_Return "the converter could not be created"
        Move (rfReadEncodedFileAsStringArray(sClassFile)) to asLines
        Get SubclassVerdict of ho (&asLines) sClass (&asNames) (&asSupers) (&asDeclFiles) to sWhy
        Send Destroy of ho
        Function_Return sWhy
    End_Function

