Use Dfclient.pkg
Use cCJGridColumnRowIndicator.pkg
Use RefactorConstants.h.pkg      // the CS_Glyph* / CS_Ico* icon names
Use cRDCSuggestionsBaseClasses.pkg
Use cRDCDbView.pkg
Use cRDCDbHeaderGroup.pkg
Use cFTDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cFunctionParameterColumn.pkg // the Parameter column: the in-cell combo per row, the REQUIRED tooltip
Use cNeverPickMenuItem.pkg       // the grid's right-click "Never pick this function for me"
Use cRDCDbForm.pkg
Use cRDCComboForm.pkg
Use FTAllWebControlClasses.pkg   // FT: cFTWebButton + cFTWebCombo - the action bar's row 1; cFTWebHtmlBox - the crumb
Use cFTGridHost.pkg              // FT: the action bar's host - a grid of 8 px columns (RDCFlexTron)
Use cFTDeferTimer.pkg            // oRunBtnDeferTimer: coalesces the context-aware Run-button repaint

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd
Use FTMarkupBuilders.pkg         // the HTML vocabulary - OpenHtml, IconLabel, the builders
Use FTDashIcons.pkg              // DashIcon - the inline SVG glyphs
Use FTThemeColors.pkg            // FTWebBg / FTCJTheme - the FT palette
Use cFTTileMarkup.pkg            // ghoTileMarkup - the workspace crumb

// The Parameter column names these two, which are defined after it in the grid.
Register_Object oFunctions_ParameterHelp
Register_Object oFunctions_ParameterValidation
Register_Function MyDelete_Confirmation Returns Integer

// Handle of the Run-button coalescing timer (oRunBtnDeferTimer, declared far below). The Functions DD's
// Update - which fires on every selection tick - arms it by this GLOBAL rather than a forward object
// reference (the timer sits after the web action bar it repaints). Set in the timer's End_Construct_Object.
Global_Variable Handle ghoRunBtnTimer

Activate_View Activate_oSelectFunctionsView for oSelectFunctionsView
Object oSelectFunctionsView is a cRDCDbView
    Set Location to 2 4
    Set Size to 185 636
    Set Label to "Select Functions"
    Set Icon to "Functions.ico"
    Set Auto_Clear_DEO_State to False  
    Set Auto_Top_Panel_State to False
    Set phoFunctionView of ghoApplication to Self   

    Object oSysFile_DD is a cSysFileDataDictionary
        Set No_Delete_State to True
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary  
        
        // FT: dashboard pre-filter by FnGroup. eFnGroupAll = no group constraint (Manual tile); a real
        // group value (e.g. eFnGroupCleanup, the Cleanup tile) constrains to that group. Mirrors
        // piFunctionType; set via the view's SetFnGroupFilter.
        Property Integer piFnGroupFilter eFnGroupAll

        // BROWSE mode (Nils 2026-07-17): True when the view was entered from the dashboard's
        // Function-library tile - a CATALOG look at the toolbox, so the Run Refactoring button
        // hides entirely (RunTailHtml). Ticking still works (the selection is global); a run
        // starts from the Manual flow, whose entries (SetFnGroupFilter's legacy signature)
        // clear this again.
        Property Boolean pbBrowseMode False

        Procedure OnConstrain
            If (piFunctionType(Self) <> eAllFunctions) Begin
                Constrain Functions.Type eq (piFunctionType(Self))
            End
            If (piFnGroupFilter(Self) <> eFnGroupAll) Begin
                // PURE group constraint - the group's rows only (Nils 2026-07-16 evening). A
                // (group OR selected) variant briefly shipped the same day so the LegacyApp2 leak's
                // stray ticks could be seen, but it POLLUTED the Tidy Up view with the user's own
                // Modernization selections - REVERTED by Nils's call: the filtered view shows its
                // group, period. The honesty now lives elsewhere: plan runs restore the user's
                // selection (no silent strays anymore), and the Run Refactoring button / dashboard
                // pill always show the TRUE total across all groups - a cross-group mismatch is
                // visible right where Run is clicked.
                Constrain Functions.FnGroup eq (piFnGroupFilter(Self))
            End
            Constrain Functions.bPublished eq (True)
        End_Procedure

        Procedure Request_Clear
        End_Procedure

        // FT: nudge the dashboard's "Selected" tile whenever the selection changes. Every tick AND every
        // Select All/None/Invert flows through here (the grid does a per-row Request_Save), so this single
        // chokepoint covers them all. The nudge only arms the dashboard's coalescing timer, so a 65-row
        // Select All collapses into one tile refresh. No-op unless the FT dashboard view is loaded.
        Procedure Update
            Forward Send Update
            Broadcast Send RequestTileRefresh of (Client_Id(phoMainPanel(ghoApplication)))
            // Also repaint the in-view context-aware Run button (muted <-> lit + count). Coalesced via its
            // 1ms timer, so a 65-row Select All collapses to ONE WebView2 push instead of 65. Armed by
            // global handle - the timer is declared below the web action bar it repaints.
            If (ghoRunBtnTimer <> 0) ;
                Send Arm of ghoRunBtnTimer
        End_Procedure

    End_Object

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oDbFunctions_grp is a dbGroup
        Set Location to 4 0
        Set Size to 185 634
        Set Border_Style to Border_None
        Set piMinSize to 126 490
        Set peAnchors to anAll

        Object oFunctionSelection_grd is a cFTDbCJGrid
            Set Server to oFunctions_DD
            // 154 -> 130 at y 25 -> 49: the action bar grew a crumb row above it (see there).
            // The grid BOTTOM is unchanged at 179, so nothing below it moved.
            Set Size to 130 620
            Set Location to 49 10
            Set peAnchors to anAll
            Set Ordering to 2
            Set pbDbShowInvertSelectionsMenuItem to True
            Set pbEditOnClick to True
            Set pbEditOnKeyNavigation to False
            Set pbHeaderPrompts to False
            Set pbDbShowEditMenuItem to False 
            Set pbAllowDeleteRow to False
            Set pbStaticData to True  
            Set pbAllowInsertRow to False
            Set pbAllowAppendRow to False
            Set pbShowNonActiveInPlaceButton to False
            // Need this to load all records in the grid,
            // else the select buttons won't work.
            Set pbStaticData to True
            Set pbShadeSortColumn to True

            Object oFunctions_ID is a cRDCDbCJGridColumn
                Entry_Item Functions.ID
                Set piWidth to 30
                Set psCaption to "ID"
                Set pbEditable to False
                Set peTextAlignment to xtpAlignmentCenter
            End_Object

            Object oFunctions_Function_Name is a cDbCJGridColumnSuggestionNew
                Entry_Item Functions.Function_Name
                Set piWidth to 180
                Set psCaption to "Function Name (Suggestion list)"    
                Set psToolTip to "This is a full text suggestion list. You can start typing to search for any keyword and a suggestion list will appear for you to select from."
                Set Status_Help to (psToolTip(Self))
                Set pbFullText to True    
                Set pbAllowRemove to False
                Set phoData_Col to Self 

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get RowValue of oFunctions_Function_Help iRow to sText
                    If (sText <> "") Begin
                        Move (Replaces("\r\n", sText, C_NewLine)) to sText
                        Move (Replaces("\n", sText, C_NewLine)) to sText
                    End
                    Function_Return sText
                End_Function
            
            End_Object

            Object oFunctions_SummaryText is a cRDCDbCJGridColumn
                Entry_Item Functions.SummaryText
                Set piWidth to 200
                Set psCaption to "Summary Text"
                Set pbEditable to False
                Set pbMultiLine to True

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get RowValue of oFunctions_Function_Help iRow to sText
                    If (sText <> "") Begin
                        Move (Replaces("\r\n", sText, C_NewLine)) to sText
                        Move (Replaces("\n", sText, C_NewLine)) to sText
                    End
                    Function_Return sText
                End_Function
            
            End_Object

            Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                Entry_Item Functions.Function_Help
                Set piWidth to 320
                Set peHeaderAlignment to xtpAlignmentCenter
                Set psCaption to "Help Text"
                Set pbEditable to False
                Set pbMultiLine to True
                Set pbVisible to False
            End_Object
    
            Object oFunctions_Type is a cRDCDbCJGridColumn
                Entry_Item Functions.Type
                Set piWidth to 130
                Set psCaption to "Type"
                Set psToolTip to "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing. See: Help for further info."
                Set Status_Help to (psToolTip(Self))
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set peTextAlignment to xtpAlignmentCenter
                Set pbComboButton to True
                // pbEditable *must* be set after the pbComboButton setting.
                Set pbEditable to False
                Set pbComboEntryState to False

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get psToolTip to sText
                    Function_Return sText
                End_Function
            
            End_Object                    

            Object oFunctions_FnGroup is a cRDCDbCJGridColumn
                Entry_Item Functions.FnGroup
                Set piWidth to 100
                Set psCaption to "Group"
                Set psToolTip to "The functional group this refactoring belongs to: Modernization (brings legacy code up to current DataFlex), x64 + Unicode (64-bit/Unicode migration readiness), Tidy Up (tidies or removes), or Other. Set via the function's { FnGroup } meta-tag."
                Set Status_Help to (psToolTip(Self))
                Set peHeaderAlignment to xtpAlignmentCenter
                Set peTextAlignment to xtpAlignmentCenter
                Set pbComboButton to True
                // pbEditable *must* be set after the pbComboButton setting.
                Set pbEditable to False
                Set pbComboEntryState to False

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get psToolTip to sText
                    Function_Return sText
                End_Function

            End_Object

            Object oFunctions_Parameter is a cFunctionParameterColumn
                Entry_Item Functions.Parameter
                Set piWidth to 122
                Set psToolTip to "Click for dropdown choices when there is a value. For some functions an extra parameter is passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."
                Set Status_Help to (psToolTip(Self))

                // The grid's columns the class reads: the values list, the row's help, the name (for REQUIRED).
                Function ParameterValidationColumn Returns Handle
                    Function_Return (oFunctions_ParameterValidation(Self))
                End_Function

                Function ParameterHelpColumn Returns Handle
                    Function_Return (oFunctions_ParameterHelp(Self))
                End_Function

                Function FunctionNameColumn Returns Handle
                    Function_Return (oFunctions_Function_Name(Self))
                End_Function
            End_Object

            Object oFunctions_Selected is a cRDCDbCJGridColumn
                Entry_Item Functions.Selected
                Set piWidth to 25
                Set psCaption to "Select" 
                Set psToolTip to "Select functions that should be part of the next refactoring, when the 'Start Refactoring' button is clicked."
                Set pbAllowRemove to False
                Set pbCheckbox to True
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set peFooterAlignment to xtpAlignmentCenter
                Set Status_Help to (psToolTip(Self))
                Set phoCheckbox_Col to Self

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get psToolTip to sText
                    Function_Return sText
                End_Function
            
            End_Object

            /* NEVER PICKED FOR ME - the user's own exclusions, shown per row and changed from the
               row's right-click menu (cNeverPickMenuItem.pkg has the story).
               Calculated, not a table field: the list is a per-user setting. */
            Object oFunctions_NeverPick is a cRDCDbCJGridColumn
                Set piWidth to 70
                Set psCaption to "Never pick"
                Set psToolTip to "Ticked: this function does not run - not from a refactoring plan, not by Select All, not even when ticked. Tick it here or from the row's right-click menu; untick it to let the function run again."
                Set pbCheckbox to True
                Set peHeaderAlignment to xtpAlignmentCenter
                Set Status_Help to (psToolTip(Self))

                /* THE CLICK IS THE SWITCH (Nils 2026-09-23: "not possible to select any items in the
                   Never pick column - the mouse tick does nothing"). The column was read-only with the
                   right-click menu as its only switch, which is not what a checkbox promises. Editable,
                   the checkbox takes the click (and the space bar), the grid toggles the row's value
                   and calls OnEndEdit with it - and that is where the list is written. Nothing is
                   bound, so the row save has nothing of this column's to store. */
                Procedure OnEndEdit String sOldValue String sNewValue
                    String sFn
                    Get SelectedRowValue of (phoData_Col(Self)) to sFn
                    Delegate Send SetNeverPick (Trim(sFn)) (sNewValue = psCheckboxTrue(Self))
                End_Procedure

                Procedure OnSetCalculatedValue String ByRef sValue
                    Move (If((IsNeverPickFunction(ghoApplication, Trim(Functions.Function_Name))), "1", "0")) to sValue
                End_Procedure

                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get psToolTip to sText
                    Function_Return sText
                End_Function
            End_Object

            Object oFunctions_ParameterHelp is a cRDCDbCJGridColumn
                Entry_Item Functions.ParameterHelp
                Set piWidth to 150
                Set psCaption to "Parameter Help"
                Set pbVisible to False
                Set pbShowInFieldChooser to False
            End_Object

            // Hidden: the Parameter combo reads its list from here, per row (ComboFillListForRow).
            Object oFunctions_ParameterValidation is a cRDCDbCJGridColumn
                Entry_Item Functions.ParameterValidation
                Set piWidth to 150
                Set psCaption to "Parameter Validation"
                Set pbVisible to False
                Set pbShowInFieldChooser to False
            End_Object

            // Save the Parameter combo edit immediately (see cFTDbCJGrid.OnComValueChanged) so a
            // change followed by an immediate "Start refactoring" is not lost. The Select checkbox is
            // auto-saved via the grid's phoCheckbox_Col (oFunctions_Selected).
            Set phoSaveOnChangeColumn to oFunctions_Parameter

            // The Parameter combo's list follows the ROW, not the cell entry - see ComboFillListForRow.
            // The row's "Never pick" switch joins the grid's right-click menu (2026-09-23).
            Procedure End_Construct_Object
                Handle hoMenu hoItem
                Forward Send End_Construct_Object
                Get phoContextMenu to hoMenu
                If (hoMenu <> 0) ;
                    Get Create of hoMenu (RefClass(cNeverPickMenuItem)) to hoItem
            End_Procedure

            // Select All leaves the "never pick" functions unticked (2026-09-23).
            Function IsSelectableItem String sDataVal Returns Boolean
                Function_Return (IsNeverPickFunction(ghoApplication, Trim(sDataVal)) = False)
            End_Function

            /* THE SWITCH, from the column's checkbox and from the row's right-click menu (2026-10-06). The
               list is written, and a function put on it loses its tick: a never-pick function does not run
               (cRefactorEngine._SkipForNeverPick), so a tick on it would promise something untrue. The
               untick goes through the DD, as Select None does, and the counts the dashboard's Selected tile
               reads are recounted. The row is re-read from the DD so both columns show it - from the menu
               at once, from the checkbox after its edit has ended (the 1 ms timer below). */
            Procedure SetNeverPick String sFn Boolean bNever
                String[] asOne
                Integer iRow

                Send SetNeverPickFunction of ghoApplication sFn bNever
                If (bNever = True) Begin
                    Move sFn to asOne[0]
                    Send UnSelectRecordsFromStringArray of oFunctions_DD asOne
                    Send ResetSysFile of oFunctions_DD
                    Broadcast Send RequestTileRefresh of (Client_Id(phoMainPanel(ghoApplication)))
                    If (ghoRunBtnTimer <> 0) ;
                        Send Arm of ghoRunBtnTimer
                End
                Get SelectedRow of (phoDataSource(Self)) to iRow
                Set piRow of (oNeverPickRowTimer(oSelectFunctionsView(Self))) to iRow
                Send Arm of (oNeverPickRowTimer(oSelectFunctionsView(Self)))
            End_Procedure

            Procedure OnRowChanged Integer iOldRow Integer iNewSelectedRow
                Forward Send OnRowChanged iOldRow iNewSelectedRow
                Send ComboFillListForRow of oFunctions_Parameter iNewSelectedRow
            End_Procedure

            // The Functions.Function_Name column is a cDbCJGridColumnSuggestion
            // That class has a bug were it is possible to enter something in
            // the suggestion form that is not in the list, click outside the
            // current cell (edit object) and that data will be changed(!)
            // The logic below guards against the data value gets changed.
            Function CanSaveRow Returns Boolean
                Boolean bSave bChange
                
                Move True to bSave
                Get Field_Changed_State of (Main_DD(Self)) Field Functions.Function_Name to bChange
                If (bChange = True) Begin
                    Send ResetSelectedRow of (phoDataSource(Self))
                    Move False to bSave
                End
                Function_Return bSave
            End_Procedure
            
            Procedure Request_Clear
            End_Procedure
    
            
            // The function edit view has been removed.
            Procedure Request_Edit
            End_Procedure
                    
            // Augment to also show # of functions in the "ID" footer
            Procedure DoSetCheckboxFooterText
                Integer iItems
                Forward Send DoSetCheckboxFooterText
                Get ItemCount to iItems
                Set psFooterText of oFunctions_ID  to ("#" * String(iItems))
            End_Procedure

            // For unknown reason the first row in the list is *not* highlighted
            // when the grid is filled. This fixes it.
            Procedure Activating
                Forward Send Activating
            End_Procedure 
            
        End_Object

        /* THE ACTION BAR (framework buttons since 2026-09-30): two rows on a grid host of 8 px columns. Row 0 is
           the crumb, across the whole width - markup, because it is navigation: the way back, and the amber Run
           Refactoring with its count, the run's forward step. Row 1 is Select All / Select None / Invert,
           framework buttons (cFTWebButton, RDCFlexTron), then the Constrain by Type combo; column 83 takes the
           rest of the width. The buttons work on the grid INSIDE the click, as the chips did - an OnClick
           override, then Forward: the grid op is quick, and a grid read from the click relay's timer faults.
           Spans fit the captions (Select All ~91 px, Select None ~107, Invert ~73), and the combo its label and
           its longest item, "eReportFunctionAll - All Files" (measured 2026-09-30); the row is 672 px, inside
           the host at the view's smallest (484 units, ~726 px). */
        Object oWebActionBar is a cFTGridHost
            Set Location to 3 4
            // 46 units: TWO rows - the crumb, then the buttons and the combo. The grid below moved down by
            // the same 24 and gave up that much height, exactly as on Select Folders.
            Set Size to 46 628
            Set peAnchors to anTopLeftRight
            Set piColumnCount to 84         // Select All's 13, Select None's 15, Invert's 11, the combo's 44, then column 83
            Set psColumnWidths to "83/1fr"  // column 83 takes the extra width

            /* THE RUN, AS THE BREADCRUMB'S FORWARD STEP (Nils 2026-08-06: make it "like the select
               folders 'Select functions'"). The trail now reads the same on every screen:

                 Start Center -> Select Folders -> Select Functions -> Run Refactoring

               A LINK RATHER THAN A BUTTON IS SAFE HERE, and that was worth checking before doing
               it: StartRefactoreCode does not write anything directly - cRefactorEngine's
               StartWarning pops a YesNo listing the function count and target, DEFAULTING TO No
               (MB_DEFBUTTON2), and only MBR_Yes proceeds. So this opens a confirmed flow, not an
               immediate rewrite of the workspace. (bShowStartQuestion can suppress it, but nothing
               in the UI sets that - it is the batch-mode path.)

               The COUNT survives the restyle, because it was the informative half of the old
               button: "12 functions selected" told you what a run would do. Group-filtered views
               still count only their own group and say so by name.

               Returns "" - no forward step at all - in browse mode or with nothing selected, the
               same rule Select Folders uses. That replaces the old muted "select functions to run"
               chip: a breadcrumb step that cannot be taken should be absent, not greyed. */
            Function RunTailHtml Returns String
                String  sCount sWord sGroup
                Integer iSel eGroup
                Boolean bBrowse

                // BROWSE MODE (the Function-library tile): the view is a CATALOG - no run step.
                Get pbBrowseMode of oFunctions_DD to bBrowse
                If (bBrowse = True) ;
                    Function_Return ""
                Get piFnGroupFilter of oFunctions_DD to eGroup
                If (eGroup <> eFnGroupAll) Begin
                    Get TotalNoSelectedPerGroup of oFunctions_DD eGroup to iSel
                    Get FnGroupText of ghoFuncLib eGroup to sGroup
                    Move (sGroup + ' ') to sGroup
                End
                Else ;
                    Move SysFile.SelectedFunctionTotal to iSel
                If (iSel = 0) ;
                    Function_Return ""
                If (iSel = 1) ;
                    Move "function" to sWord
                Else ;
                    Move "functions" to sWord
                Move (String(iSel) + ' ' + sGroup + sWord) to sCount
                /* A BUTTON, not a forward crumb (Nils 2026-08-22). It used to wear .dash-crumb-fwd, which
                       reads as "the next place" - but this one does not go anywhere, it STARTS THE RUN, and
                       dressing an action as navigation is the same hidden-affordance complaint the chips were
                       given real chrome for. It now takes the Editor's top-right treatment, .mtbtn, which
                       buttons.css already styles as part of the same family, and the play glyph the Manual
                       board's own Run Refactoring tile uses - so the two ways into a run look alike.
                       The chevron went with the crumb: a button says what it does, it does not point. */
                    Function_Return ((BarButtonHtml("mtbtn amber sf-run", "run", "", ((DashIcon(CS_GlyphPlaycircleline)) + (BoldText("Run Refactoring"))), "Start the refactoring run. The engine asks once more - naming the files and the function count - before anything is written.", True)) + (SpanOpen("dash-crumb-cnt")) + sCount + CS_SpanEnd)
            End_Function

            // Same flat-bar treatment as Select Folders: the shared crumb, plus this view's own
            // html,body overflow rule (every tile in a cLocalWebControlHost needs its own - the
            // shared builder cannot carry it without breaking the boards' scrolling host).
            Function CrumbBarHtml Returns String
                String sHtml
                // ...SURFACE-rooted (Nils 2026-08-09): reached from the Start Center, from Select
                // Folders' forward step, and from all three boards - so "back" is where the user
                // stepped in from, not a fixed screen.
                Get WorkspaceCrumbSurfaceTailHtml of ghoTileMarkup (RunTailHtml(Self)) to sHtml
                Move (sHtml + CS_PaletteCssLink + CS_PageFitCssLink + CssLink("selectfunctions")) to sHtml
                Function_Return sHtml
            End_Function

            Object oWebCrumb_htm is a cFTWebHtmlBox
                Set piColumnSpan  to 84       // row 0, the whole width
                // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
                // psHtml it can parse. It is the string the runtime seeds (dumped by the cFTWebHtmlBox design
                // dump, no workspace loaded); the runtime expression sits in End_Construct_Object below.
                Set psHtml to """
                <link rel="stylesheet" href="RDCFlexTron/palette.css">
                <link rel="stylesheet" href="RDCFlexTron/buttons.css">
                <link rel="stylesheet" href="RDCFlexTron/bars.css">
                <link rel="stylesheet" href="CssStyle/tilemarkup.css">
                <div class="dash-crumb"><span class="dash-crumb-back" data-ServerOnClick="startcenter" title="Back to the Start Center, to open another workspace or to switch between the guided and manual dashboards.">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M9 6l6 6l-6 6"/></svg>Start Center</span><span class="dash-crumb-sep">|</span><span class="dash-crumb-none">No workspace loaded</span>
                    <div class="mtbtn amber sf-run" data-ServerOnClick="run" title="Start the refactoring run. The engine asks once more - naming the files and the function count - before anything is written.">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0 M10 8l6 4l-6 4z"/></svg><b>Run Refactoring</b></div><span class="dash-crumb-cnt">3 functions</span></div>
                <link rel="stylesheet" href="RDCFlexTron/palette.css">
                <link rel="stylesheet" href="RDCFlexTron/buttons.css">
                <link rel="stylesheet" href="RDCFlexTron/bars.css">
                <link rel="stylesheet" href="RDCFlexTron/pagefit.css">
                <link rel="stylesheet" href="CssStyle/selectfunctions.css">
                """

                // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
                Procedure End_Construct_Object
                    Forward Send End_Construct_Object
                    Set psHtml to (CrumbBarHtml(Self))
                End_Procedure
                Procedure OnClick String sId String sParam
                    Boolean bWsMode bGuidedRun
                    Integer iEditorFuncs eGroup iSurface
                    String[] asGroupSel asPrevSel

                    If (sId = "startcenter") Begin
                        Send Activate_oStartCenter_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Procedure_Return
                    End
                    // The crumb root when it names a BOARD - the surface the user stepped in from.
                    // Same ladder the Editor's crumb runs.
                    If (sId = "crumbroot") Begin
                        Get piLastSurface of ghoApplication to iSurface
                        Case Begin
                            Case (iSurface = eBoardManual)
                                Send Activate_oManualDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                                Case Break
                            Case (iSurface = eBoardCockpit)
                                Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                                Case Break
                            Case Else
                                // eBoardGuided, and the fallback: the trail is the default surface.
                                Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Case End
                        Procedure_Return
                    End
                    If (sId = "run") Begin
                        // Before StartRefactoreCode spins up the status panel, land on the view the engine will
                        // actually use (Nils 2026-07-13). The Editor is relevant for a SINGLE-FILE run (the engine
                        // reloads the loaded file's result - cRefactorEngine ~552) OR when editor-type functions are
                        // selected (they transform the editor content - cRefactorEngine ~837). ONLY a WORKSPACE run
                        // with NO editor functions has nothing to show there -> land on the Dashboard instead.
                        // Count editor functions with the authoritative live SCAN (TotalNoSelectedPerType) - NOT the
                        // SysFile.SelectedeEditorFunction counter, which DRIFTS upward (AdjustSelected adds on every
                        // per-row save and the per-type counters are uncapped): it read 10 with only 2 editor
                        // functions in the library and wrongly forced the editor here (Nils 2026-07-13).
                        Get pbWorkspaceMode of ghoApplication to bWsMode
                        Get TotalNoSelectedPerType of oFunctions_DD eEditorFunction to iEditorFuncs
                        /* ...and if the GUIDED TRAIL sent the user here, land on the TRAIL, not the
                           dashboard (Nils 2026-07-29: "the Dashboard view is activated (not WIP)").
                           This choice predates the trail, so "the view the engine will use" could only
                           mean the dashboard for a workspace run - but a run reached through the
                           trail's Tidy Up footer belongs to the trail, and being dropped on the old
                           cockpit mid-flow is the same losing-your-place complaint the trail exists to
                           fix. The flag is the trail's own one-shot, consumed by the post-run handoff. */
                        Get pbGuidedTidyUpRun of ghoApplication to bGuidedRun
                        If (bWsMode = True and iEditorFuncs = 0) Begin
                            If (bGuidedRun = True) ;
                                Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                            Else ;
                                Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        End
                        Else Begin
                            Send Activate_oEditorView_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        End
                        // GROUP-SCOPED RUN (Nils 2026-07-16, the last piece of the LegacyApp2 saga): from a
                        // group-filtered view this button promised e.g. "1 Tidy Up function selected", so
                        // the run must execute ONLY that group's ticks - the engine's start question said
                        // "8 functions" because the user's other-group selections (a deliberate Manual-flow
                        // set) rode along. Same transient narrow/restore as a plan run (StartAutoSelect):
                        // snapshot the standing selection, select the group's ticks only, run, restore -
                        // the user's cross-group selection is untouched afterwards (No on the start
                        // question or a cancelled run included). The unfiltered view runs ALL selected,
                        // matching its own cross-group count.
                        Get piFnGroupFilter of oFunctions_DD to eGroup
                        If (eGroup <> eFnGroupAll) Begin
                            Get SelectedPublishedFunctionNames         of oFunctions_DD to asPrevSel
                            Get SelectedPublishedFunctionNamesPerGroup of oFunctions_DD eGroup to asGroupSel
                            Send UnSelectAllRecords of oFunctions_DD
                            Send SelectRecordsFromStringArray of oFunctions_DD asGroupSel
                            Send StartRefactoreCode of ghoCommandBars
                            Send UnSelectAllRecords of oFunctions_DD
                            Send SelectRecordsFromStringArray of oFunctions_DD asPrevSel
                            Send ResetSysFile of oFunctions_DD
                            Send RefreshDataFromDD of oFunctionSelection_grd 0
                            If (ghoRunBtnTimer <> 0) ;
                                Send Arm of ghoRunBtnTimer
                        End
                        Else Begin
                            Send StartRefactoreCode of ghoCommandBars
                        End
                    End
                End_Procedure
            End_Object

            Object oSelectAllBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 0
                Set piColumnSpan to 13
                Set psCaption to "Select All"
                Set psCSSClass to "ftbtn ftg-selectall"

                Procedure OnClick
                    Send SelectAll of oFunctionSelection_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oSelectNoneBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 13
                Set piColumnSpan to 15
                Set psCaption to "Select None"
                Set psCSSClass to "ftbtn ftg-selectnone"

                Procedure OnClick
                    Send SelectNone of oFunctionSelection_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oInvertBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 28
                Set piColumnSpan to 11
                Set psCaption to "Invert"
                Set psCSSClass to "ftbtn ftg-invert"

                Procedure OnClick
                    Send SelectInvert of oFunctionSelection_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oWebConstrainByType_cmb is a cFTWebCombo
                Set piRowIndex to 1
                Set piColumnIndex to 39
                Set piColumnSpan  to 44       // the 130 px label and the longest item's 207 px, with the margins
                Set psLabel to "Constrain by Type:"
                Set peLabelAlign to alignRight
                Set peSortItems to csUnsorted     // keep the fill order
                Set pbServerOnChange to True       // REQUIRED for the server OnChange to fire

                // Fixed list (no DD bind): FillFromDDO no-ops with no Server set, so OnFill is the
                // sole source. sValue = sDescription = the CS_* text, so OnChange matches on it below.
                Procedure OnFill
                    Send AddComboItem CS_AllFunctions      CS_AllFunctions
                    Send AddComboItem CS_StandardFunction  CS_StandardFunction
                    Send AddComboItem CS_RemoveFunction    CS_RemoveFunction
                    Send AddComboItem CS_EditorFunction    CS_EditorFunction
                    Send AddComboItem CS_ReportFunction    CS_ReportFunction
                    Send AddComboItem CS_ReportFunctionAll CS_ReportFunctionAll
                    Send AddComboItem CS_OtherFunction     CS_OtherFunction
                    Send AddComboItem CS_OtherFunctionAll  CS_OtherFunctionAll
                End_Procedure

                Procedure OnChange String sNewValue String sOldValue
                    Integer iType

                    Case Begin
                        Case (sNewValue = CS_AllFunctions)
                            Move eAllFunctions to iType
                            Case Break
                        Case (sNewValue = CS_StandardFunction)
                            Move eStandardFunction to iType
                            Case Break
                        Case (sNewValue = CS_RemoveFunction)
                            Move eRemoveFunction to iType
                            Case Break
                        Case (sNewValue = CS_EditorFunction)
                            Move eEditorFunction to iType
                            Case Break
                        Case (sNewValue = CS_ReportFunction)
                            Move eReportFunction to iType
                            Case Break
                        Case (sNewValue = CS_ReportFunctionAll)
                            Move eReportFunctionAll to iType
                            Case Break
                        Case (sNewValue = CS_OtherFunction)
                            Move eOtherFunction to iType
                            Case Break
                        Case (sNewValue = CS_OtherFunctionAll)
                            Move eOtherFunctionAll to iType
                            Case Break
                        Case Else
                    Case End

                    Set piFunctionType of oFunctions_DD to iType
                    Send Rebuild_Constraints of oFunctions_DD
                    Send RefreshDataFromDD of oFunctionSelection_grd 0
                End_Procedure
            End_Object


        End_Object
        
    End_Object

    // Coalescing timer for the in-view Run button: the Functions DD's Update arms it on every selection
    // tick (via ghoRunBtnTimer), and this 1ms one-shot repaints the button ONCE - so a 65-row Select All
    // collapses to a single WebView2 push instead of 65. Dual-path OnDeferredAction: pre-mount uses Set psHtml
    // (the host flushes it at mount), post-mount uses UpdateHtml + CheckUpdateWebUI (Set psHtml alone won't
    // flush a realized box - see BackupFilesFT.dg). A cFTDeferTimer, like the dashboard's oChkDeferTimer.
    Object oRunBtnDeferTimer is a cFTDeferTimer
        Procedure End_Construct_Object
            Forward Send End_Construct_Object
            Move Self to ghoRunBtnTimer
        End_Procedure
        Procedure OnDeferredAction Integer iAction String sParam
            String sHtml

            // The whole crumb now, not a separate button: the run IS the crumb's forward step, so
            // the count lives inside the same fragment as the back link.
            Get CrumbBarHtml of oWebActionBar to sHtml
            // Always keep the property fresh, so ANY host reflush (mount, resize, re-show) paints the current
            // count - this is what carries a cold first-mount. When already realized, ALSO push live (a
            // Set psHtml alone will not flush a mounted box - see BackupFilesFT.dg).
            Set psHtml of oWebCrumb_htm to sHtml
            // Push live ONLY once the bar's web app has called home: pbInitWebApp is True until the
            // page's df.LocalApp makes its first server call (the framework flips it in
            // FinishWebObjectInitialize). IsComObjectCreated alone is NOT readiness - the browser
            // COM exists long before the page's JS app does, and WebView2 throttles HIDDEN windows:
            // in the tile / campaign-exit flow this view mounts BEHIND the Folders view, so an
            // UpdateHtml client action pushed pre-init hit an uninitialized page and the whole bar
            // rendered the framework's "Unhandled Program Error on the Client" banner instead of
            // the Run button (one flaky cold-start 2026-07-16; deterministic via the campaign-exit
            // offer 2026-07-19 - the analyzer dock's WebView2 load stalls the hidden mount every
            // time). Skipping the push pre-init loses nothing: the page's init sync serves the
            // psHtml set above, and every view entry re-arms this timer (Activate).
            If (IsComObjectCreated(oWebCrumb_htm) and pbInitWebApp(oWebActionBar) = False) Begin
                Send PushHtml of oWebCrumb_htm sHtml
            End
        End_Procedure
    End_Object

    // Re-reads one grid row from the DD after a never-pick switch (SetNeverPick on the grid), once the
    // checkbox edit that caused it has ended - inside OnEndEdit the row is still being edited.
    Object oNeverPickRowTimer is a cFTDeferTimer
        Property Integer piRow -1
        Procedure OnDeferredAction Integer iAction String sParam
            Integer iRow
            Get piRow to iRow
            If (iRow >= 0) ;
                Send RefreshDataFromDD of (oFunctionSelection_grd(oDbFunctions_grp(oSelectFunctionsView(Self)))) iRow
        End_Procedure
    End_Object

    // Repaint the Run button on view entry: the selection count may reflect a workspace loaded while we
    // were away (or a selection changed outside this view). Deferred + dual-path so it's correct even on a
    // cold WebView2 mount. Mirrors DashboardFT's Activate.
    Procedure Activate Returns Integer
        Integer iRetVal
        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            If (ghoRunBtnTimer <> 0) ;
                Send Arm of ghoRunBtnTimer
        End
        Procedure_Return iRetVal
    End_Procedure

    // FT: pre-filter the grid by FnGroup - the dashboard's Manual tile sends eFnGroupAll (no group
    // constraint), the Cleanup tile sends eFnGroupCleanup, right after activating this view. Mirrors the
    // Constrain-by-Type combo: set the DD filter, re-apply constraints, reload the grid.
    // Full entry point: group filter + BROWSE mode in one call. bBrowse True = the Function-library
    // tile's catalog look (no Run button); False = a run-flow entry (Run button shows). The legacy
    // single-param SetFnGroupFilter below maps to False, so every pre-existing caller stays a
    // run-flow entry without touching it.
    Procedure SetFnGroupFilterEx Integer eGroup Boolean bBrowse
        Set pbBrowseMode    of oFunctions_DD to bBrowse
        Set piFnGroupFilter of oFunctions_DD to eGroup
        Send Rebuild_Constraints of oFunctions_DD
        Send RefreshDataFromDD of oFunctionSelection_grd 0
        // The Run button's count BASIS (or its visibility) just changed - repaint it through the
        // coalescing timer (realization-safe dual path, same as every other arm).
        If (ghoRunBtnTimer <> 0) ;
            Send Arm of ghoRunBtnTimer
    End_Procedure

    Procedure SetFnGroupFilter Integer eGroup
        Send SetFnGroupFilterEx eGroup False
    End_Procedure

    // Land the view with exactly ONE named function ticked and everything else cleared - used by the
    // guided handoffs that route the user to run a specific report (the return-mismatch nudge, and
    // the "manual work remaining" summary). The group filter is opened to ALL so the function is visible
    // and the Run button counts it (1), and browse mode is cleared so the Run button shows. Any prior
    // manual tick set is replaced - these handoffs fire when the user has chosen to run this one thing.
    Procedure SelectSingleFunction String sFnName
        String[] asOne
        Move sFnName to asOne[0]
        Set pbBrowseMode    of oFunctions_DD to False
        Set piFnGroupFilter of oFunctions_DD to eFnGroupAll
        Send Rebuild_Constraints of oFunctions_DD
        Send UnSelectAllRecords of oFunctions_DD
        Send SelectRecordsFromStringArray of oFunctions_DD asOne
        Send RefreshDataFromDD of oFunctionSelection_grd 0
        If (ghoRunBtnTimer <> 0) ;
            Send Arm of ghoRunBtnTimer
    End_Procedure

    Procedure Request_Clear
        Set Changed_State to False
        Forward Send Request_Clear
    End_Procedure

    Procedure Request_Clear_All
        Set Changed_State to False
        Forward Send Request_Clear_All
    End_Procedure

    Function pbShouldSave Returns Boolean
        Function_Return (Changed_State(Self))
    End_Function

    // Need to refind records if request_clear has been send.
    Procedure OnWorkspaceLoaded
        String sWorkspaceHome
        
        Get psWorkspaceHomePath  of ghoApplication to sWorkspaceHome
        If (sWorkspaceHome = "") Begin
            Procedure_Return
        End

        Send Find of oFunctions_DD GE Index.1
    End_Procedure
    
    Procedure DoFreshGrids
        If (IsComObjectCreated(oDbFolders_grd)) Begin
            Send Find of oFunctions_DD GE Index.1
            Send RefreshDataFromDD of oFunctionSelection_grd 0
        End
    End_Procedure
    
    // FlexTron-only dark tint (FlexTron FT copy; production uses the un-suffixed file). The dark CodeJock theme
    // skins the chrome but NOT the native control client areas, so once this view's subtree is built,
    // cascade clDarkViewBg/clDarkThemeText down it (pattern drafted in TestBench.src:468, scoped to Self).
    //
    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        Broadcast Recursive Set Color     of Self to (FTViewBg())
        Broadcast Recursive Set TextColor of Self to (FTThemeInk())
        // The web action-bar host renders its own var(--dfr-bg-page, #262624) (clDarkWebBg) content; re-assert its gutter colour
        // AFTER the recursive cascade above (which would otherwise paint it the lighter clDarkViewBg).
        Set Color of oWebActionBar to (FTWebBg())
    End_Procedure

    Set Verify_Delete_msg to (RefFunc(MyDelete_Confirmation))
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    On_Key Key_Escape      Send None
    On_Key Key_Ctrl+Key_S  Send Request_Save
    On_Key Key_F2          Send Request_Save
End_Object
