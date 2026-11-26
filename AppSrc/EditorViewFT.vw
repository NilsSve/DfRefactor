Use Windows.pkg
Use cRefactorApplication.pkg
Use cRefactorDbView.pkg
Use cRefactorScintillaEditor.pkg
Use RefactorConstants.h.pkg      // the CS_Id* click ids and the markup constants
Use cRefactorEditorSettings.pkg
Use vWin32fh.pkg
Use cFunctionsDataDictionary.dd
Use dfClient.pkg
Use FTAllWebControlClasses.pkg   // FT: cFTWebButton - Compare and the Compile pane toggle; cFTWebHtmlBox - the crumb
Use cFTGridHost.pkg              // FT: the top bar's host - a grid of 8 px columns (RDCFlexTron)
Use FTDashIcons.pkg        // DashIcon - the back-crumb chevron. A global function has to be DEFINED
Use FTMarkupBuilders.pkg         // the HTML vocabulary - OpenHtml, IconLabel, the builders
Use FTThemeColors.pkg            // FTWebBg / FTCJTheme - the FT palette
Use cEncodingHelpers.pkg         // rfHtmlEscape and the encoding helpers
                           // above its caller, and DFRefactorFT.src Uses this AFTER this view.

Activate_View Activate_oEditorView_vw for oEditorView_vw
Object oEditorView_vw is a cRefactorDbView
    Set Size to 255 492
    Set Label to "Editor"
    Set Icon to "EditorView.ico"
    Set pbAutoActivate to False
    Set pbAcceptDropFiles to True

    Set phoEditorView of ghoApplication to Self

    // The editor's top bar: the back crumb and the loaded file's path, then two buttons at the right -
    // [Compare] [Show/Hide Compile pane]. The toggle flips the Modernize dock group (Test Compile + Compiler
    // Output + ModAnalyzer) - same action as Ctrl+M; its Show/Hide label tracks the dock's shown/hidden state
    // via the idle handler below (so it stays correct even after a Close from the dock). Compare (Nils
    // 2026-07-05) diffs the file LOADED IN THE EDITOR against its backed-up original: an Analyzer / Compiler
    // Output double-click lands the refactored file here, so the before/after check is one click instead of
    // a trip to the dashboard's Compare (which, in workspace mode, diffs the whole folder trees).

    // The Compare button's action, run from its OnButtonClick - after the web click, since the worker can pop
    // an Info_Box, a modal, which faults inside a web click. It reads psCodeFile - the editor's OWN record of
    // what is loaded, updated by EVERY load path (the Open dialog, a dropped file, an Analyzer / Compiler
    // Output jump) - NOT psCurrentSourceFileName, which the jump paths do not touch, so the mode-aware toolbar
    // Compare would diff a stale file here. The pairing + all user feedback lives in the shared
    // CompareFileWithBackup (cRefactorApplication).
    Procedure CompareEditorFile
        String sCompareApp sFile
        Handle hoEditor
        Get phoEditor of ghoApplication to hoEditor
        If (hoEditor = 0) ;
            Procedure_Return
        Get psCodeFile of hoEditor to sFile
        Get psFileCompareApp of ghoApplication to sCompareApp
        Send CompareFileWithBackup of ghoApplication sCompareApp sFile
    End_Procedure

    /* THE TOP BAR (framework buttons since 2026-09-30): the back crumb and the loaded file's path at the left,
       as markup - a cFTWebHtmlBox in column 0, which takes the rest of the width - then Compare and Show/Hide
       Compile pane, framework buttons (cFTWebButton, RDCFlexTron) on the same grid host of 8 px columns. The
       crumb is navigation, not a button, so it stays markup; its work runs in OnHtmlClick, after the web click has
       returned (the library's click relay). Spans fit the captions (Compare ~91 px, Show Compile pane ~149, Hide
       Compile pane ~145, measured 2026-09-30); the toggle's fits both, so flipping it moves nothing.

       Compare is live only when the loaded file HAS a backup (pbGateHasBackup - the cached gate the idle
       handler below maintains, so a click can never land in the no-backup Info_Box; that text lives in the
       shut button's tooltip instead - Nils 2026-07-05), and its tooltip says what would enable it: a file
       loaded, or a backup of this one. Both buttons run their work in OnButtonClick, after the web click has
       returned (the library's click relay): the compare can pop an Info_Box, and the toggle shows or hides
       the dock group. */
    Object oModernizeToggleHost is a cFTGridHost
        Set Size to 20 483
        Set Location to 3 4
        Set peAnchors to anTopLeftRight
        Set piColumnCount to 34         // column 0, then Compare's 13 and the toggle's 20
        Set psColumnWidths to "0/1fr"   // column 0 - the crumb and the file - takes the extra width

        // What the bar last showed (see oModernizeToggleIdle): piLastBarState packs the three flags and
        // psBarKey the board and the file the markup names; both start at values no tick produces.
        Property Integer piLastBarState -1
        Property String  psBarKey ""
        // The Compare gate CACHE: pbGateHasBackup = a backup exists for psGateFile, the file it was
        // last computed for. IsBackupFile hits the DISK (one exact-path probe under the current
        // drive-encoded scheme; a recursive backup-tree walk only as the legacy-layout fallback), so
        // the idle recomputes it ONLY when the loaded file changes - never per tick. The view's
        // RefreshAfterRun resets psGateFile to a sentinel so the next tick re-probes: a run may have
        // just CREATED the backup of the file sitting in the editor.
        Property String  psGateFile ""
        Property Boolean pbGateHasBackup False

        /* A path as HTML TEXT - same tiny escape as MaintainLibrariesFT's, for the same reason:
           "R&D" is an ordinary folder name and an unescaped & silently truncates what follows.
           Above EditorBarHtml because that is its caller (define-above, as ever). */
        Function Esc String sText Returns String
            Function_Return (rfHtmlEscape(sText))
        End_Function

        // The markup half of the bar: the back crumb, then the file in the editor - none without one.
        Function EditorBarHtml String sFile Returns String
            String sHtml sBackCls sBackLbl sLeaf
            Integer iBoard iPos

            Move (CssLink("editorview")) to sHtml
            Move (sHtml + (DivOpen("mtbar"))) to sHtml
            // Mirrors the crumb's OnHtmlClick Case on piLastBoardView, which the click runs: manual is
            // mint and says so, the cockpit keeps the plain "Dashboard", and eBoardGuided - plus the
            // fallback, the guided trail being the default surface - is amber.
            Get piLastBoardView of ghoApplication to iBoard
            Move "mtback" to sBackCls
            If (iBoard = eBoardManual) Begin
                Move "mtback mtback-m" to sBackCls
                Move "Manual Dashboard" to sBackLbl
            End
            Else If (iBoard = eBoardCockpit) Begin
                Move "Dashboard" to sBackLbl
            End
            Else Begin
                Move "Guided Dashboard" to sBackLbl
            End
            Move (sHtml + (ClickableHtml("div", (sBackCls), "board", "", ((DashIcon(CS_GlyphChevron)) + sBackLbl), ('Back to the ' + Lowercase(sBackLbl) + ' you were working on.')))) to sHtml
            // The name only when there IS one - an empty span would still take its auto margin.
            If (Trim(sFile) <> "") Begin
                /* THE WHOLE PATH, like the program header (Nils 2026-08-15: "It needs to show the
                   full path" - a leaf alone cannot say WHICH wslibrary.pkg is open when a machine
                   holds several copies of a library). The folder part stays muted and the leaf
                   brightens, so the eye still lands on the file inside the longer string. */
                Move sFile to sLeaf
                Move (RightPos("\", sLeaf)) to iPos
                If (iPos > 0) ;
                    Move (Right(sLeaf, (Length(sLeaf) - iPos))) to sLeaf
                Move (sHtml + (DivOpenTip("mtfile", sFile)) ;
                    + (Esc(Self, Left(sFile, (Length(sFile) - Length(sLeaf))))) ;
                    + (BoldText(sLeaf)) + CS_DivEnd) to sHtml
            End
            Move (sHtml + CS_DivEnd) to sHtml
            Function_Return sHtml
        End_Function

        Object oEditorBar_htm is a cFTWebHtmlBox
            Set piColumnSpan to 1
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. It is the string the runtime seeds (dumped by the cFTWebHtmlBox design
            // dump, no workspace loaded); the runtime expression sits in End_Construct_Object below.
            Set psHtml to """
            <link rel="stylesheet" href="CssStyle/editorview.css">
            <div class="mtbar">
                <div class="mtback" data-ServerOnClick="board" title="Back to the guided dashboard you were working on.">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6l-6 6"/></svg>Guided Dashboard</div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (EditorBarHtml(Self, ""))
            End_Procedure

            /* The crumb is the one click here - the buttons beside it are framework buttons. Its work runs here,
               after the web click has returned (the library's click relay): activating a view tears down the
               WebView2 host that is still running the click - err 4410. */
            Procedure OnHtmlClick String sId String sParam
                Integer iBoard
                If (sId <> "board") ;
                    Procedure_Return
                Get piLastBoardView of ghoApplication to iBoard
                Case Begin
                    Case (iBoard = eBoardManual)
                        Send Activate_oManualDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Case Break
                    Case (iBoard = eBoardCockpit)
                        Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Case Break
                    Case Else
                        // eBoardGuided, and the fallback: the guided trail is the default surface.
                        Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                Case End
            End_Procedure
        End_Object

        Object oCompareBtn is a cFTWebButton
            Set piColumnIndex to 1
            Set piColumnSpan to 13
            Set psCaption to "Compare"
            Set psCSSClass to "ftbtn ftg-compare"
            // Shut until the idle handler's first tick says whether the file in the editor has a backup.
            Set pbEnabled to False
            Set psToolTip to "Open a source file first - e.g. double-click a Modernization Analyzer or Compiler Output row - and Compare diffs it against its backed-up original."

            Procedure OnButtonClick
                Send CompareEditorFile of oEditorView_vw
            End_Procedure
        End_Object

        Object oCompilePaneBtn is a cFTWebButton
            Set piColumnIndex to 14
            Set piColumnSpan to 20
            Set psCaption to "Show Compile pane"
            Set psCSSClass to "ftbtn ftg-compilepane"
            Set psToolTip to "(Ctrl+M) Show or hide the Compile dock (Test Compile + Compiler Output + Modernization Analyzer)."

            Procedure OnButtonClick
                Send ToggleModernizePanel of oEditorView_vw
            End_Procedure
        End_Object

        /* Keeps the bar true to what it shows: the crumb names the board it returns to, the path is the file
           in the editor, Compare is live only when that file has a backup, and the toggle says Show or Hide by
           whether the Compile dock is wanted - right even after a Close from the dock itself. The steady-state
           tick is cheap property reads only; the DISK probe (IsBackupFile) runs solely when the loaded file
           CHANGED - or when RefreshAfterRun invalidated the cache after a run. Something is pushed only when
           a fact changed: piLastBarState packs the three flags (bit 1 = wanted, bit 2 = file, bit 4 = backup)
           and psBarKey the board and the file, so the FIRST tick sets everything. Before the bar's page has
           called home the Sets alone are what its init serves (UpdateHtml folds into Set psHtml then). Below
           the buttons, because it names them - an object is known only below its definition. */
        Object oModernizeToggleIdle is a cIdleHandler
            Set pbEnabled to True
            Procedure OnIdle
                Boolean bWanted bHaveFile bHasBackup
                Integer iState iBoard
                String sFile sBackup sKey sTip sLabel
                Handle hoEditor hoHost

                Move (Parent(Self)) to hoHost
                Get pbModernizePanelWanted of ghoApplication to bWanted
                Get phoEditor of ghoApplication to hoEditor
                Move "" to sFile
                If (hoEditor <> 0) ;
                    Get psCodeFile of hoEditor to sFile
                Move (sFile <> "") to bHaveFile
                If (sFile <> psGateFile(hoHost)) Begin
                    Move "" to sBackup
                    If (bHaveFile) ;
                        Get IsBackupFile of ghoApplication sFile to sBackup
                    Set pbGateHasBackup of hoHost to (sBackup <> "")
                    Set psGateFile      of hoHost to sFile
                End
                Get pbGateHasBackup of hoHost to bHasBackup
                Move (If(bWanted, 1, 0) + If(bHaveFile, 2, 0) + If(bHasBackup, 4, 0)) to iState
                Get piLastBoardView of ghoApplication to iBoard
                Move (String(iBoard) + "|" + sFile) to sKey
                If ((iState = piLastBarState(hoHost)) and (sKey = psBarKey(hoHost))) ;
                    Procedure_Return
                Set piLastBarState of hoHost to iState
                If (sKey <> psBarKey(hoHost)) Begin
                    Set psBarKey of hoHost to sKey
                    Send UpdateHtml of (oEditorBar_htm(hoHost)) (EditorBarHtml(hoHost, sFile))
                End
                If (bHasBackup) ;
                    Move "Compare the file in the editor with its backed-up original (the version saved before a refactoring run changed it), in the external file-compare tool." to sTip
                Else If (bHaveFile) ;
                    Move "No backup of this file exists yet - backups are created when a refactoring run changes the file. Once one exists, Compare diffs the editor file against it." to sTip
                Else ;
                    Move "Open a source file first - e.g. double-click a Modernization Analyzer or Compiler Output row - and Compare diffs it against its backed-up original." to sTip
                // The SAME words the main toolbar uses for the same toggle - "Show/Hide Compile pane"
                // (DFRefactorFT.src). Two names for one control is two controls as far as the reader is
                // concerned, and the toolbar is the one that was already right (Nils 2026-08-22).
                If (bWanted) ;
                    Move "Hide Compile pane" to sLabel
                Else ;
                    Move "Show Compile pane" to sLabel
                Send UpdateEnabled of (oCompareBtn(hoHost)) bHasBackup
                Send UpdateToolTip of (oCompareBtn(hoHost)) sTip
                Send UpdateCaption of (oCompilePaneBtn(hoHost)) sLabel
                If (not(pbInitWebApp(hoHost))) ;
                    Send CheckUpdateWebUI of hoHost
            End_Procedure
        End_Object
    End_Object

    // Just so the cursor has a focusable object to go to.
//    Object oDbInvisible_fm is a Form
//        Set Size to 13 25
//        Set Location to 8 120
//        Set Visible_State to False
//    End_Object

    Object oEditorDockHost is a Container3d
        // nhPublic puts this editor region into the public docking neighborhood so the bottom
        // CompilerOutput dock resizes against the editor (drag its top edge) instead of
        // overlapping it. Plain containers default to nhNo (no docking participation); this
        // mirrors the nhPublic editor panes in RefactorTestBench.vw.
        Set peNeighborhood to nhPublic
        Set Border_Style to Border_None
        // Starts at 24, immediately BELOW oModernizeToggleHost (row 3 + 20 units high = ends at 23).
        // It used to start at 20 and so overlapped the bar's last 3 units - the editor itself was
        // never the problem (it sits 4 units in, at absolute 24), but this container's own
        // background painted over the bottom of the toggle buttons (Nils 2026-08-13: "it cuts off
        // the bottom part of the buttons"). The 4-unit inset moved out here, so the editor keeps
        // its exact position and the bar keeps all 20 of its units - the same height every other
        // FT button bar uses for 24px chips.
        Set Location to 24 4
        Set Size to 229 486
        Set peAnchors to anAll

        Object oEditor_edt is a cRefactorScintillaEditor
            Set Size to 229 483
            Set Location to 0 0
            Set peAnchors to anAll
            Set Enabled_State to False

            // View property.
            Delegate Set phoEditor to Self
            Set phoEditor of ghoApplication to Self

            Property Boolean piInSetFocus False

            // We con't care about potential data loss here.
            Function pbShouldSave Returns Boolean
                Function_Return False
            End_Function

            // Note: We need this "intermediate" procedure because the phoMainPanel property
            //       is zero when the program starts - which generates a runtime error.
            Procedure SwitchNextView
                Send Switch_Next_View of (Client_Id(phoMainPanel(ghoApplication)))
            End_Procedure

            Object oIdleHandler is a cIdleHandler 
                Procedure OnIdle
                    String sSWSFile
                    Get psSWSFile of ghoApplication to sSWSFile
                    Set Enabled_State to (sSWSFile <> "")   
                    // Make the editor not visible, because else it is possible to click inside it
                    // even when no workspace has been selected.
                    // The oDbInvisible_fm object above takes care of the focusable necessity.
                    Set Visible_State to (sSWSFile <> "")
                End_Procedure
            End_Object

            Procedure Activating
                Forward Send Activating
                Set pbEnabled of oIdleHandler to True
            End_Procedure

            Procedure Deactivating
                Set pbEnabled of oIdleHandler to False
                Forward Send Deactivating 
            End_Procedure

            // This short-cut key will keep the UI consistent, as the editor was "grabbing" this
            // key combination and did nothing, but everywhere else it flips through the views/tab-pages.
            On_Key Key_Ctrl+Key_Tab Send SwitchNextView
            On_Key Key_Ctrl+Key_S   Send Request_Save
        End_Object
    End_Object

    Procedure OnSetFocus
        Set piActiveView of ghoApplication to CI_CodeIndenter Self
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle
            String sSWSFile  
            Boolean bEnabled
            Get psSWSFile of ghoApplication to sSWSFile
            Move (sSWSFile <> "") to bEnabled
            Set Enabled_State to bEnabled
            Broadcast Recursive Set Enabled_State of (Parent(Self)) to bEnabled
        End_Procedure
    End_Object

    Procedure Activate_View Returns Integer
        String sSourceFilename   

        Forward Send Activate_View
        Get psCurrentSourceFileName of ghoApplication to sSourceFilename
        If (sSourceFilename <> "") Begin
            Send OnFileNameUpdate of ghoApplication sSourceFilename
            Send Top_of_Panel
        End
    End_Procedure

    // Ctrl+M / the toggle button: show or hide the Modernize dock group. We are ON the editor view here, so the
    // SHOW uses the dock-only path (no view switch). HIDE clears the user-wants flag so the dock will NOT
    // auto-restore when returning to this view. (The flag lives in DFRefactorFT.src; the procs in TestCompileFT.dg.)
    Procedure ToggleModernizePanel
        Boolean bWanted
        Get pbModernizePanelWanted of ghoApplication to bWanted
        If (bWanted) Begin
            Set pbModernizePanelWanted of ghoApplication to False
            Send CloseTestCompileDialog of (Client_Id(ghoCommandBars))
        End
        Else Begin
            Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        End
    End_Procedure

    // Run-completion hook (the engine Broadcasts RefreshAfterRun to the MDI views when a run finishes -
    // same route the dashboard uses): the run may have just CREATED the backup of the file sitting in
    // the editor, so invalidate the Compare gate cache; the next idle tick re-probes and Compare
    // lights without the file having to be reloaded. The sentinel can never equal a real path (nor ""),
    // so the re-probe is guaranteed.
    Procedure RefreshAfterRun
        Set psGateFile of (oModernizeToggleHost(Self)) to "*stale*"
    End_Procedure

    // Restore-on-return: msg_Activate is the event reliably raised on a tab/view switch (Activating fires only
    // once; Activate_View only on an explicit Send). If the Modernize dock was up when the user left for another
    // view (which auto-hid it via the non-editor views' one-shot), bring it back. ShowTestCompileDockOnly is
    // idempotent, so the several Activate fires per switch are harmless and there is no re-entrancy loop.
    Procedure Activate Returns Integer
        Integer iRetVal
        Boolean bWanted
        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            Get pbModernizePanelWanted of ghoApplication to bWanted
            If (bWanted) ;
                Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        End
        Procedure_Return iRetVal
    End_Procedure


    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        // Define the save procedure for the editor object.
        Send DefineOnKey of (phoEditor(ghoApplication)) CMD_FileSaveAll msg_Request_Save
        // FlexTron-only dark tint (FlexTron FT copy; production uses the un-suffixed file). Unlike the grid views this
        // is TARGETED, not a recursive broadcast: colour the view client area, the info text box and the
        // editor's dock-host FRAME to clDarkViewBg, but leave the Scintilla editor pane alone - it paints
        // itself via its own colorer (ScintillaParameters), so a Set Color on it could fight that.
        //
        Set Color of Self            to (FTViewBg())
        Set Color of oEditorDockHost to (FTViewBg())
    End_Procedure
    
    // We con't care about potential data loss here, it is more annoying to be reminded of it...
    Function pbShouldSave Returns Boolean
        Function_Return False
    End_Function

    // F5 from the editor: save the buffer, surface the Test Compile dock, and run the SAME Compile the
    // panel's Compile/Stop button does. DoCompileToggle (TestCompileFT.dg) was factored out expressly so an
    // "F5 On_Key" could invoke it - but the panel's own F5 only fires when the PANEL has focus, and while you
    // edit here focus is in the Scintilla OCX. So this view bridges it: save first (a compile reads the file
    // off DISK), show the dock (surfaces the output + publishes phoTestCompileFT), then toggle the compile on
    // that panel. DoCompileToggle STARTS a compile when idle and STOPS a running one, so a second F5 cancels.
    Procedure StartCompiler
        Handle hoPanel
        Send Request_Save of (phoEditor(ghoApplication))
        Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        Get phoTestCompileFT of ghoApplication to hoPanel
        If (hoPanel <> 0) ;
            Send DoCompileToggle of hoPanel
    End_Procedure

    // Ctrl+M toggles the Modernize dock. A VIEW-level On_Key fires only while focus is in THIS view (it bubbles
    // up from the editor OCX, which does not handle Ctrl+M) - so the toggle is inert on every other view, the
    // "do nothing off-view" behavior. The global Ctrl+M=Compare accelerator was removed (Compare keeps Alt+M).
    On_Key Key_Ctrl+Key_M Send ToggleModernizePanel
    // Ctrl+F5 from the editor: the Analyzer over the LATEST compile output - the panel's Analyze
    // step (StartAnalyze), surfaced the same way F5 surfaces the compile (Nils 2026-08-16). No save
    // first: Analyze reads the .prn/.err the last compile wrote, not the buffer. StartAnalyze itself
    // ignores a re-entrant press (pbAnalyzing) and says so when nothing was compiled yet.
    Procedure StartAnalyzer
        Handle hoPanel hoStatusBar
        String sPath

        Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        Get phoTestCompileFT of ghoApplication to hoPanel
        If (hoPanel = 0) ;
            Procedure_Return
        // Nothing compiled yet -> StartAnalyze returns silently, which from a key press reads as
        // dead. Say so where the eye already is.
        Get psErrFilePath of hoPanel to sPath
        If (sPath = "") ;
            Get psPrnFilePath of hoPanel to sPath
        If (sPath = "") Begin
            Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
            If (hoStatusBar <> 0) ;
                Set StatusText of hoStatusBar to "Nothing to analyze yet - press F5 to compile first."
            Procedure_Return
        End
        Send StartAnalyze of hoPanel
    End_Procedure
    On_Key Key_Ctrl+Key_F5 Send StartAnalyzer
    On_Key Key_F5 Send StartCompiler
End_Object
