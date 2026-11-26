// ==========================================================================================
// MANUAL DASHBOARD - the manual flow on a board of its own.
//
// WHY IT EXISTS (Nils 2026-08-02): the old Dashboard carries GUIDED and MANUAL side by side in
// one two-column card, and the question of what to do with that split is easier to answer once
// the manual half can be seen standing alone. Both dashboards stay for now; this is the third
// board, not a replacement for either.
//
// IT OWNS NO LOGIC, and that is the point. Every tile comes from ghoTileMarkup (the Workspace and
// Target-version/Function-library pair the other boards paint) and ghoManualBoard (the manual
// column and the two actions behind it that are more than a single Send). This view is a screen:
// a host, some tiles, and a deferred timer that routes clicks. If it were to reach into
// oDashboard_vw for any of that, it would rebuild exactly the coupling three slices of untangling
// removed - inside the thing meant to make retiring that split board possible.
//
// WHAT IS DELIBERATELY ABSENT: the guided column, the stepper, the program combo and Modernization
// progress. Those belong to the guided flow, and a board that offers both is the thing this exists
// to make optional.
// ==========================================================================================
Use cRDCDbView.pkg
Use cFTDeferTimer.pkg
Use cFTDbLocalWebControlHost.pkg
Use RefactorConstants.h.pkg      // the CS_Id* click ids and the markup constants
Use cFTWebHtmlBox.pkg
Use cSysFileDataDictionary.dd
Use cFTLibraryReport.pkg         // ghoLibraryReport - the library data behind the Libraries tile
Use cFTTileMarkup.pkg            // ghoTileMarkup - the shared tiles + the workspace crumb
Use cFTManualBoard.pkg           // ghoManualBoard - the manual column + its two actions
Use cFTBoardActions.pkg          // ghoBoardActions - Compare / Revert, offered by every board

/* This board's ONE own deferred-action code - the automatic package-update scan, on its own tick once
   the board is up. (The crumb's way back to the Start Center was the other, until the page clicks moved
   into the boxes' OnHtmlClick on 2026-10-07.)

   Deliberately not appended to DashboardFT.vw's Enum_List, where the CI_Dash* code this view borrows
   (CI_DashRefreshTiles) is declared. That board is the one the Start Center makes redundant (offering
   the GUIDED|MANUAL split was its remaining job, and that choice happens at the door now), and a
   constant only this view uses should not be a reason its Enum_List has to outlive it. Numbered well
   clear of the enum's 24 sequential values. */
Define CI_MDUpdateScan for 501

Activate_View Activate_oManualDashboard_vw for oManualDashboard_vw
Object oManualDashboard_vw is a cRDCDbView
    Set Border_Style to Border_Thick
    Set Size to 440 450
    Set Location to 2 2
    Set Label to "Manual Dashboard"
    Set Icon to "Manual.ico"   // the toolbar button's picture - the open hand (2026-10-04)
    // Reached from the toolbar only. See the note on the other two boards: pbAutoActivate replays
    // out of phoAutoActivateViews on every panel focus, and Auto_Top_Panel_State pulls focus in
    // from Request_Clear_All's beginning_of_panel - both put a view on screen unasked.
    Set pbAutoActivate to False
    Set Auto_Top_Panel_State to False

    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    /* The board's own deferred work, on a native tick: the repaint that several Activate fires per tab
       switch and a burst of grid ticks coalesce into (CI_DashRefreshTiles), and the automatic package-update
       scan once the board is on screen (CI_MDUpdateScan). The page clicks run in their boxes' OnHtmlClick,
       after the web click has returned (the library's click relay), since 2026-10-07. */
    Object oMDeferTimer is a cFTDeferTimer
        Procedure OnDeferredAction Integer iAction String sParam
            Integer iScanned

            If (iAction = CI_DashRefreshTiles) ;
                Send RefreshAll of (oManualDashboard_vw(Self))
            /* THE AUTOMATIC UPDATE CHECK, on its own tick so the board is already on screen - it
               spawns a process per git dependency and waits on a network. Only the top row
               repaints: a full RefreshAll would re-arm this and loop. */
            If (iAction = CI_MDUpdateScan) Begin
                Move (PublishWorkspaceUpdateScan(psSWSFile(ghoApplication))) to iScanned
                Send PushHtml of (oTile_Setup(oWebHost(oManualDashboard_vw(Self)))) (SetupStatsRowHtml(ghoTileMarkup))
            End
        End_Procedure
    End_Object

    Object oWebHost is a cFTDbLocalWebControlHost
        Set Size to 438 446
        Set Location to 0 2
        Set piColumnCount to 12
        Set peAnchors to anAll

        Set Main_DD to oSysFile_DD
        Set Server  to oSysFile_DD

        /* THE WORKSPACE CRUMB, where the workspace TILE used to be (Nils 2026-08-06). Selecting a
           workspace belongs to the Start Center now (StartCenterFT.vw), so this board gives up the
           banner, the recent chips and the .sws dialog and keeps the one thing it still owes the
           user: which workspace this is, and the way back out of it. Shared markup, so this board
           and the guided trail say it identically. */
        Object oTile_Crumb is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <link rel="stylesheet" href="RDCFlexTron/palette.css">
            <link rel="stylesheet" href="CssStyle/tilemarkup.css">
            <div class="dash-crumb"><span class="dash-crumb-back">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 6l6 6l-6 6"/></svg>Start Center</span><span class="dash-crumb-sep">|</span><span class="dash-crumb-lbl">Current Workspace:</span><span class="dash-crumb-name">Workspace name</span></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (WorkspaceCrumbHtml(ghoTileMarkup))
            End_Procedure

            /* The crumb's way back, after the web click has returned (the library's click relay). The three
               handlers that stood beside it - open the .sws dialog, load a recent by index, remove a recent -
               went with the workspace tile: choosing a workspace is the Start Center's job now, and this board
               renders no control that could reach them. OnWorkspaceLoaded still repaints this board whenever
               a workspace is loaded from anywhere, so nothing is lost by their going. */
            Procedure OnHtmlClick String sId String sParam
                If (sId = "startcenter") ;
                    Send Activate_oStartCenter_vw of (Client_Id(phoMainPanel(ghoApplication)))
            End_Procedure
        End_Object

        // Target DataFlex version + Libraries + Function library, the header row from the shared
        // markup. They share ONE host tile because separate span-6 tiles do not level their heights.
        Object oTile_Setup is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <div class="dash-cols">
                <div class="dash-tile-off">
                    <div class="dash-ico"></div>
                    <div class="dash-txt">
                        <div class="dash-h">Target DataFlex version</div>
                        <div class="dash-p">Load a workspace to see the target</div></div></div>
                <div class="dash-tile-off">
                    <div class="dash-ico">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 4l-8 4l8 4l8 -4l-8 -4 M4 12l8 4l8 -4 M4 16l8 4l8 -4"/></svg></div>
                    <div class="dash-txt">
                        <div class="dash-h">Libraries</div>
                        <div class="dash-p">Load a workspace to see them</div></div></div>
                <div class="dash-stat-off">
                    <div class="dash-label">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 4l-8 4l8 4l8 -4l-8 -4 M4 12l8 4l8 -4 M4 16l8 4l8 -4"/></svg>Function library</div>
                    <div class="dash-p">Load a workspace to see counts</div></div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (HeaderSeedHtml(ghoTileMarkup))
            End_Procedure

            /* Libraries, Compiler Settings and the Function-library figures act, after the web click has
               returned (the library's click relay). The two dialogs are modal, so the board repaints after them
               against whatever the user settled on: ONE Libraries dialog, one click - the read-only report and
               the editor it linked to are the same screen (Nils 2026-08-11); the target version AND the library
               verdicts that depend on it share this board's top tile. The figures are a two-line jump (activate
               Select Functions, then SetFnGroupFilterEx with browse True - inspect the toolbox, no Run button;
               the manual entries clear browse mode again on their way in), the same two lines the Dashboard
               runs. */
            Procedure OnHtmlClick String sId String sParam
                Integer eGroup
                Boolean bLibsOk

                If (sId = "libraries") Begin
                    Get MaintainWorkspaceLibraries "" to bLibsOk
                    Send RefreshAll of (oManualDashboard_vw(Self))
                End
                Else If (sId = CS_IdSetup) Begin
                    Send OpenCompilerSettings of ghoBoardActions
                    Send RefreshAll of (oManualDashboard_vw(Self))
                End
                Else If (sId = CS_IdFnLib or sId = "fnlibmod" or sId = "fnlibu64" ;
                         or sId = "fnlibtidy" or sId = "fnlibother") Begin
                    Case Begin
                        Case (sId = "fnlibmod")
                            Move eFnGroupModernization to eGroup
                            Case Break
                        Case (sId = "fnlibu64")
                            Move eFnGroupUnicode64 to eGroup
                            Case Break
                        Case (sId = "fnlibtidy")
                            Move eFnGroupCleanup to eGroup
                            Case Break
                        Case (sId = "fnlibother")
                            Move eFnGroupOther to eGroup
                            Case Break
                        Case Else
                            Move eFnGroupAll to eGroup
                            Case Break
                    Case End
                    Send Activate_oSelectFunctionsView of (Client_Id(phoMainPanel(ghoApplication)))
                    Send SetFnGroupFilterEx of oSelectFunctionsView eGroup True
                End
            End_Procedure
        End_Object

        // THE MANUAL COLUMN - the reason this board exists. Full width here rather than sharing a
        // row with the guided flow, which is the whole difference being trialled.
        Object oTile_Manual is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. A hand-written sample of the board WITH a workspace loaded, in workspace
            // mode - the flow head, the two launcher tiles, the Queued to run pills (3 folders, 12
            // functions) and the enabled Run Refactoring button - in the shape ManualColumnHtml builds
            // (cFTManualBoard.pkg; the no-workspace seed is only the greyed launcher pair). The runtime
            // content is set in End_Construct_Object below, which the Designer never reads, so the
            // placeholder is never seen at runtime.
            Set psHtml to """
            <div class="dash-manual">
                <div class="dash-flow-head"><span class="dash-flow-name">Manual</span><span class="dash-flow-sub">you pick the folders &amp; functions yourself</span></div>
                <div class="dash-m-tiles">
                    <div class="dash-tile t-single" data-ServerOnClick="single">
                        <div class="dash-ico">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M14 3v4a1 1 0 0 0 1 1h4 M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/></svg></div>
                        <div class="dash-txt">
                            <div class="dash-h">Single file</div>
                            <div class="dash-p">Refactor one source file</div></div></div>
                    <div class="dash-tile t-manual" data-ServerOnClick="manual">
                        <div class="dash-ico">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M3.5 5.5l1.5 1.5l2.5 -2.5 M3.5 11.5l1.5 1.5l2.5 -2.5 M3.5 17.5l1.5 1.5l2.5 -2.5 M11 6l9 0 M11 12l9 0 M11 18l9 0"/></svg></div>
                        <div class="dash-txt">
                            <div class="dash-h">Workspace mode</div>
                            <div class="dash-p">Pick folders &amp; functions</div></div></div></div>
                <div class="dash-queued"><span class="dash-label">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M11 19h-6a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v4 M15 19l2 2l4 -4"/></svg>Queued to run</span>
                    <div class="dash-queued-pills"><span class="dash-sel-pill" data-ServerOnClick="folders"><span class="dash-sel-ico s-fold">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M5 4h4l3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2"/></svg></span><b>3</b> Folders selected</span><span class="dash-sel-pill"
                                data-ServerOnClick="functions"><span class="dash-sel-ico s-func">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 4l-8 4l8 4l8 -4l-8 -4 M4 12l8 4l8 -4 M4 16l8 4l8 -4"/></svg></span><b>12</b> Functions selected</span></div></div>
                <div class="dash-mrun" data-ServerOnClick="startrefactor">
                    <div class="dash-ico">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0 M10 8l6 4l-6 4z"/></svg></div>
                    <div class="dash-mrun-txt"><span>Run Refactoring</span><span class="dash-mrun-flow">Manual</span></div></div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (ManualColumnHtml(ghoManualBoard))
            End_Procedure

            /* The manual column's doors, after the web click has returned (the library's click relay). The two
               that are more than a Send live in ghoManualBoard so both boards run the SAME code - see
               cFTManualBoard.

               SINGLE FILE ENDS IN THE EDITOR (Nils 2026-08-03). It used to come back to this board afterwards
               and repaint the queued card - the 2026-07-13 "dashboard stays the hub" decision, made when landing
               in the editor with no visible next step was the confusing part. That reasoning has expired:
               PickSingleFile now activates the editor BEFORE the open dialog so the file lands in a paged-in
               control, so by the time the dialog closes the user is looking at the file they just asked for -
               and pulling the board back over it takes away the thing they opened. Nothing is lost by not
               repainting here: this view's Activate override arms CI_DashRefreshTiles -> RefreshAll, which
               rebuilds oTile_Manual (the queued card) among the rest, so the board is correct the next time it
               is entered. The grids also broadcast RequestTileRefresh for the split-view case.

               ANALYZE THIS FILE (2026-09-17): the queued card's third pill in single-file mode. The scan worker
               is RunDeepScan on the guided board - it reads single-file mode itself and scans the picked file
               alone - reached by the same broadcast crossing the Test Compile bar's Analyze Source button uses
               (TestCompileFT's oAnalyzeSourceBtn). */
            Procedure OnHtmlClick String sId String sParam
                String sWS

                Get psSWSFile of ghoApplication to sWS
                If (sWS = "") ;
                    Procedure_Return
                If (sId = "single") ;
                    Send PickSingleFile of ghoManualBoard
                Else If (sId = "manual") ;
                    Send OpenManualSetup of ghoManualBoard eFnGroupAll
                Else If (sId = CS_IdSelFolders) ;
                    Send Activate_oSelectFoldersView of (Client_Id(phoMainPanel(ghoApplication)))
                Else If (sId = CS_IdSelFunctions) Begin
                    // ALL groups explicitly: a filter the library tile left must never narrow this count.
                    Send Activate_oSelectFunctionsView of (Client_Id(phoMainPanel(ghoApplication)))
                    Send SetFnGroupFilter of oSelectFunctionsView eFnGroupAll
                End
                Else If (sId = CS_IdSelFile) ;
                    Send Activate_oEditorView_vw of (Client_Id(phoMainPanel(ghoApplication)))
                Else If (sId = CS_IdScanFile) ;
                    Broadcast Send RunDeepScan of (Client_Id(phoMainPanel(ghoApplication)))
                Else If (sId = "startrefactor") ;
                    Send StartRefactoreCode of ghoCommandBars
            End_Procedure
        End_Object

        // The after-a-run utilities, shared markup and shared gates. Read log / other logs /
        // Compare / Revert are flow-agnostic, so this board offers them like the others do.
        Object oTile_Actions is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <div class="dash-action-row"><span class="dash-action-off">Read log</span><span class="dash-action-off">Read other logs (0)</span><span class="dash-action-off">Compare Source</span><span
                class="dash-action-off">Revert (0)</span></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (ActionRowHtml(ghoTileMarkup))
            End_Procedure

            /* All four after the web click has returned (the library's click relay) - until 2026-10-07 the
               first three ran inside it. Compare and Revert run the SHARED implementations (cFTBoardActions) -
               they were inert here until 2026-08-02, which meant two chips that rendered fully enabled and did
               nothing. Revert's dialog is modal, and this board repaints its own action row afterwards: a
               restore moves backups out of the folder, so the Revert count and the Compare gate both go stale. */
            Procedure OnHtmlClick String sId String sParam
                If (sId = CS_IdReadLog) ;
                    Send ShowLogFile of ghoApplication
                Else If (sId = CS_IdReadOtherLogs) ;
                    Send ShowOtherLogFiles of ghoApplication
                Else If (sId = CS_IdCompare) ;
                    Send CompareSource of ghoBoardActions
                Else If (sId = CS_IdUndo) Begin
                    Send RevertFromBackup of ghoBoardActions
                    // Modal, so control is back and no dialog is up: the gates can be re-read now.
                    Send RefreshActionRow of (oManualDashboard_vw(Self))
                    Send FlushWebUI       of (oManualDashboard_vw(Self))
                End
            End_Procedure
        End_Object
    End_Object

    // Just the manual column - what a file pick or a selection change actually moves.
    Procedure RefreshManualColumn
        Send PushHtml of (oTile_Manual(oWebHost(Self))) (ManualColumnHtml(ghoManualBoard))
    End_Procedure

    // Just the utility row - what a Revert actually invalidates.
    Procedure RefreshActionRow
        Send PushHtml of (oTile_Actions(oWebHost(Self))) (ActionRowHtml(ghoTileMarkup))
    End_Procedure

    /* ARM THE AUTOMATIC UPDATE CHECK - once per workspace, and only when an answer is possible.

       Three refusals, each for its own reason:
         no workspace   - nothing to scan.
         switched off   - the preference; default on, see PackageUpdateCheckEnabled.
         already done   - UpdateScanDone is keyed on the workspace, so re-entering this board (which
                          happens on every tab switch) costs nothing, while LOADING a different
                          workspace does arm a fresh scan.

       Arming only queues it. The scan itself waits for the timer, so the board paints first. */
    Procedure ArmPackageUpdateScan
        String sWS

        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Procedure_Return
        If ((PackageUpdateCheckEnabled()) = False) ;
            Procedure_Return
        If ((UpdateScanDone(ghoLibraryReport, sWS)) = True) ;
            Procedure_Return
        Send ArmAction of oMDeferTimer CI_MDUpdateScan
    End_Procedure

    Procedure RefreshAll
        Send UpdateHtml of (oTile_Crumb(oWebHost(Self)))     (WorkspaceCrumbHtml(ghoTileMarkup))
        Send UpdateHtml of (oTile_Setup(oWebHost(Self)))     (SetupStatsRowHtml(ghoTileMarkup))
        Send UpdateHtml of (oTile_Manual(oWebHost(Self)))    (ManualColumnHtml(ghoManualBoard))
        Send ArmPackageUpdateScan
        Send PushHtml of (oTile_Actions(oWebHost(Self)))   (ActionRowHtml(ghoTileMarkup))
    End_Procedure

    Procedure FlushWebUI
        Send CheckUpdateWebUI of (oWebHost(Self))
    End_Procedure

    // Repaint on every entry: folder and function selections change while the user is in the grids,
    // and the queued card is this board's whole readout. Deferred so the several Activate fires per
    // tab switch coalesce into one.
    Procedure Activate Returns Integer
        Integer iRetVal
        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            Send ArmAction of oMDeferTimer CI_DashRefreshTiles
            // Stamp WHICH board is in use, so the Editor's back crumb returns here.
            Set piLastBoardView of ghoApplication to eBoardManual
            // ...and the SURFACE stamp the Select Folders / Select Functions crumbs read.
            Set piLastSurface   of ghoApplication to eBoardManual
        End
        Procedure_Return iRetVal
    End_Procedure

    /* The Folders and Functions grids BROADCAST this on every tick / Select All - and in Split View
       this board is visible WHILE the user works in them, so its queued-to-run pills would otherwise
       sit stale until the next activation. Routed through the same 1ms timer as Activate, so a burst
       of per-row saves coalesces into one repaint. Declared in DFRefactorFT.src. */
    Procedure RequestTileRefresh
        Send ArmAction of oMDeferTimer CI_DashRefreshTiles
    End_Procedure

    // A workspace change anywhere repaints this board too.
    Procedure OnWorkspaceLoaded
        Send RefreshAll
    End_Procedure

//    Procedure Close_Panel
//    End_Procedure
//
End_Object
