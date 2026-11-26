Use Cursor.pkg
Use dfLine.pkg
Use cCJCommandBarSystem.pkg
Use cRDCSuggestionsBaseClasses.pkg
Use DFEnChk.pkg
Use dfTabDlg.pkg

Use cRDCDbView.pkg
Use cFTDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCDbComboForm.pkg
Use RefactorConstants.h.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbSpinForm.pkg
Use cRDCButton.pkg
Use cRDCForm.pkg
Use FTAllWebControlClasses.pkg   // FT: cFTWebButton + cFTWebCombo - the action bar's row 1; cFTWebHtmlBox - the crumb, the toggle
Use cFTGridHost.pkg              // FT: the action bar's host - a grid of 8 px columns (RDCFlexTron)
Use cFTDeferTimer.pkg            // coalesces the Continue button's repaint - see oFoldersDeferTimer
Use FTPageIsUp.pkg               // FTHostPageIsUp - can the action bar's page take a live push now? (RDCFlexTron)
Use FTInputBox.dg                // FTInputBox - the extension filter's "Add a filter..." asks for one in it (RDCFlexTron)
Use TestCompileFT.dg

Use cSysFileDataDictionary.dd
Use cFolderSelHeaDataDictionary.dd
Use cFolderSelDtlDataDictionary.dd
Use FTMarkupBuilders.pkg         // the HTML vocabulary - OpenHtml, IconLabel, the builders
Use FTDashIcons.pkg              // DashIcon - the inline SVG glyphs
Use FTThemeColors.pkg            // FTWebBg / FTCJTheme - the FT palette
Use cFTTileMarkup.pkg            // ghoTileMarkup - the workspace crumb

Register_Procedure RefreshSelectionUpdate
Register_Procedure ActivateProcess

Activate_View Activate_oSelectFoldersView for oSelectFoldersView
Object oSelectFoldersView is a cRDCDbView
    Set Location to 1 0
    Set Size to 178 638
    Set Label to "Select Folders"
    Set Icon to "Folder.ico"
    Set pbAcceptDropFiles to True
    Set Auto_Clear_DEO_State to False  
    Set Auto_Top_Panel_State to False
    Set phoFoldersView of ghoApplication to Self   
    
    Object oSysFile_DD is a cSysFileDataDictionary
        Set No_Delete_State to True
    End_Object

    Object oFolderSelHea_DD is a cFolderSelHeaDataDictionary
        Set phoFolderSelHeaDD of ghoApplication to Self  
    End_Object

    Object oFolderSelDtl_DD is a cFolderSelDtlDataDictionary
        Set DDO_Server to oFolderSelHea_DD
        Set Constrain_File to FolderSelHea.File_Number

        // Flush the cmd-line folder seed (/folders flag or the CmdLine INI [Folders] section) into the
        // FolderSelDtl table the first time this DD relates with the workspace DDs current. Keyed off
        // pasCmdLineFolders - NOT the pasSelectedFolders live cache - so ordinary interactive saves
        // (a checkbox tick, Select All) never re-run the cmd-line marking (which mis-resolved deep
        // paths and faulted err-28 duplicate creates). The Forward always runs: relating is what
        // keeps FolderSelHeaID correct on saved rows.
        Procedure Relate_Main_File
            String[] asFolders asEmpty
            Integer iIDa iIDb

            Forward Send Relate_Main_File
            Get pasCmdLineFolders of ghoApplication to asFolders
            If (SizeOfArray(asFolders) = 0) Begin
                Procedure_Return
            End
            Get Field_Current_Value Field FolderSelDtl.FolderSelHeaID to iIDa
            Get Field_Current_Value Field FolderSelDtl.ID             to iIDb
            If (iIDa <> 0 and iIDb <> 0) Begin
                Send MarkCmdLineSetSelectedFolders asFolders
                // Consume the one-shot seed, and drop the live cache so the next reader
                // re-syncs it from the now-updated table.
                Set pasCmdLineFolders  of ghoApplication to asEmpty
                Set pasSelectedFolders of ghoApplication to asEmpty
            End
        End_Procedure

        // FT: nudge the dashboard's "Selected" tile whenever the folder selection changes. Every tick AND
        // every Select All/None/Invert flows through here (the grid does a per-row Request_Save), so this
        // single chokepoint covers them all. The nudge only arms the dashboard's coalescing timer, so a bulk
        // select collapses into one tile refresh. No-op unless the FT dashboard view is loaded.
        Procedure Update
            Forward Send Update
            Broadcast Send RequestTileRefresh of (Client_Id(phoMainPanel(ghoApplication)))
            // ...and this view's own Continue button, which appears/disappears with the selection
            // count. Same chokepoint, same reason: every tick and every Select All row lands here.
            Delegate Send ArmContinueRefresh
        End_Procedure

    End_Object

    Set Main_DD to oFolderSelDtl_DD
    Set Server to oFolderSelDtl_DD
                                    
    /* Coalesces the Continue button's repaint. A Select All is one Request_Save PER ROW, and each
       one reaches oFolderSelDtl_DD.Update - so without this a 40-folder workspace would push 40
       WebView2 updates for a control that can only be in two states. The 1ms one-shot collapses the
       burst into a single paint, the same idiom as SelectFunctionsFT's oRunBtnDeferTimer and the
       boards' own deferred refreshes.

       ArmContinueRefresh sits on the VIEW so the DD can reach it with a plain Delegate (its parent
       chain ends here), rather than needing a global handle. */
    Object oFoldersDeferTimer is a cFTDeferTimer
        Procedure OnDeferredAction Integer iAction String sParam
            // A Send, so it resolves globally even though RefreshContinue is declared further down.
            Send RefreshContinue of (oDbSourceFolders_grp(oSelectFoldersView(Self)))
        End_Procedure
    End_Object

    Procedure ArmContinueRefresh
        Send Arm of oFoldersDeferTimer
    End_Procedure

    /* "Add a filter..." in the extension filter (oWebFileFilter_cf) asks for one in a box, and a box shown
       from inside the combo's web event faults (4410): the pick arms this, and one tick later the box shows. */
    Object oFileFilterDeferTimer is a cFTDeferTimer
        Procedure OnDeferredAction Integer iAction String sParam
            // The combo is declared further down, hence the path.
            Send AskForFileFilter of (oWebFileFilter_cf(oWebActionBar(oDbSourceFolders_grp(oSelectFoldersView(Self)))))
        End_Procedure
    End_Object

    /* REPAINT THE CRUMB ON ARRIVAL (Nils 2026-08-09: "any chance to do the same for the Select
       Folders view?").

       The crumb's root names the surface the user came FROM - and this view had no Activate at all,
       so the fragment kept whatever root it was last painted with. On the Start Center -> board ->
       here route that was the stale "Start Center", the very thing the root was changed to stop
       saying. Select Functions never showed the bug, but not because it was written more carefully:
       its Run-count timer happens to rebuild the WHOLE crumb on entry, so the root came along for
       the ride.

       The other two repaint triggers do not cover this. RefreshContinue fires on folder-selection
       changes and on workspace load - both of which can happen while this view is nowhere near the
       screen - and neither is "the user just walked in from somewhere else".

       Through the existing 1ms arm rather than painting inline: on a cold entry the host may not
       have called home yet, and while cFTWebHtmlBox.UpdateHtml folds a pre-init push into psHtml,
       RefreshContinue's CheckUpdateWebUI companion has no such gate. Re-arming on view entry so a
       skipped push self-heals is what every other FT surface does. */
    Procedure Activate Returns Integer
        Integer iRetVal
        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            Send ArmContinueRefresh
        End
        Procedure_Return iRetVal
    End_Procedure

    Object oDbSourceFolders_grp is a dbGroup
        Set Location to 4 0
        Set Size to 185 634
        Set Border_Style to Border_None
        Set piMinSize to 126 490
        Set peAnchors to anAll

        Object oDbFolders_grd is a cFTDbCJGrid
            Set Server to oFolderSelDtl_DD
            // 154 -> 130 tall at y 25 -> 49: the action bar grew a crumb row above it (see there).
            // The grid's BOTTOM is unchanged at 179, so nothing below it moved.
            Set Size to 130 620
            Set Location to 49 10
            Set Ordering to 2
            Set piLayoutBuild to 5
            Set pbAllowDeleteRow to True
            Set pbAllowInsertRow to True
            Set pbDbShowAddFolderMenuItem to True
            Set pbDbOpenContainingFolderMenuItem to True
            Set pbDbShowRemoveItemMenuItem to True  
            Set pbDbShowInvertSelectionsMenuItem to True
            
            Set Verify_Delete_msg to (RefFunc(No_Confirmation))
            // Need this to load all records in the grid,
            // else the select buttons won't work.
            Set pbStaticData to True
            
            Object oFolderSelDtl_ID is a cRDCDbCJGridColumn
                Entry_Item FolderSelDtl.ID
                Set piWidth to 35
                Set psCaption to "ID"
                Set pbEditable to False
                Set peTextAlignment to xtpAlignmentCenter
            End_Object

            Object oDbFoldername_Col is a cDbCJGridColumnSuggestion
                Entry_Item FolderSelDtl.FolderName
                Set piWidth to 797
                Set psCaption to "Folder Name"
                Set psToolTip to "The process will run on all files that match the 'File Extensions Filter' comboform for the selected folders and all subfolders"
                Set psFooterText to "No of Folders Selected:"
                // NOTE: The phoData_Col property must be set for the checkbox selections to work!
                Set phoData_Col to Self
                Set pbFullText to True    
                Set pbAllowRemove to False

            End_Object
            
            Object oFolder_Selected is a cRDCDbCJGridColumn
                Entry_Item FolderSelDtl.bSelected
                Set piWidth to 45
                Set psCaption to "Select"
                Set pbCheckbox to True
                Set phoCheckbox_Col to Self
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set peFooterAlignment to  xtpAlignmentCenter
            End_Object

            Function IsFolderName String sFolderName tFolderData[] asSavedFolders Returns Boolean
                Integer iRow
                tFolderData FolderDataName
                Move sFolderName to FolderDataName.sFolderName
                Move (SearchArray(FolderDataName, asSavedFolders)) to iRow
                Function_Return (iRow <> -1)
            End_Function 
            
            Procedure Refresh Integer eMode
                String[] asFolders
                Forward Send Refresh eMode  
                If (psSWSFile(ghoapplication) <> "") Begin
                    Get SelectedFolders of (Server(Self)) to asFolders
                    Set pasSelectedFolders of ghoApplication to asFolders
                End
            End_Procedure
            
            // The Functions.Function_Name column is a cDbCJGridColumnSuggestion
            // That class has a bug were it is possible to enter something in
            // the suggestion form that is not in the list, click outside the
            // current cell (edit object) and that data will be changed(!)
            // The logic below guards against the data value gets changed.
            Function CanSaveRow Returns Boolean
                Handle hoDataSource
                Boolean bSave bChange
                
                Move True to bSave
                Get phoDataSource to hoDataSource
                Get Field_Changed_State of (oFolderSelDtl_DD(Self)) Field FolderSelDtl.FolderName to bChange
                If (bChange = True) Begin
                    Send ResetSelectedRow of hoDataSource
                    Move False to bSave
                End
                Function_Return bSave
            End_Procedure

            // Select the focused folder and all its sub-folders in one go
            // (the "Select Subtree" button). Bulk-selects via the DD, then
            // reloads the grid so the new checkbox states show.
            Procedure SelectFocusedSubtree
                Integer iNewly
                Get SelectFolderSubtree of (Server(Self)) to iNewly
                If (iNewly > 0) ;
                    Send RefreshDataFromDD of Self 0
            End_Procedure
            
            Procedure Request_Clear
            End_Procedure
    
    
            On_Key Key_F2           Send Request_Save 
            On_Key Key_Ctrl+Key_S   Send Request_Save
            On_Key Key_Delete       Send Request_Delete
            On_Key Key_Shift+Key_F2 Send Request_Delete 
            On_Key Key_Ctrl+Key_F5  Send ActivateProcess
        End_Object

        /* THE ACTION BAR (framework buttons since 2026-09-30): two rows on a grid host of 8 px columns. Row 0 is
           the crumb, across the whole width - markup, because it is navigation: the way back, and the forward
           step to Select Functions. Row 1 is the file-extension filter combo, then Select All / Select None /
           Invert / Select Subtree / Re-scan, framework buttons (cFTWebButton, RDCFlexTron), then the "Include
           libraries" toggle - markup, a toggle rather than a button - in column 90, which takes the rest of the
           width. The select buttons work on the grid INSIDE the click, as the chips did (an OnClick override,
           then Forward): the grid op is quick, and a grid read from the click relay's timer faults. Re-scan
           runs after the click (OnButtonClick) - it ends in a message box.

           THE FIXED COLUMNS FIT THE SMALLEST BAR: the filter and the five buttons are 720 px (spans fit the
           captions - Select All ~91 px, Select None ~107, Invert ~73, Select Subtree ~119, Re-scan ~84, measured
           2026-09-30), and the bar is 484 units (~726 px) at the group's piMinSize. That matters for the crumb:
           it spans every column, so fixed columns wider than the bar would cut off its right end - the forward
           step. The toggle gives way instead: it has its whole width from ~850 px, and only the narrowest bar
           clips it. */
        Object oWebActionBar is a cFTGridHost
            Set Location to 3 4
            // 46 units: TWO rows - the crumb, then the filter, the buttons and the toggle. The grid below moved
            // down by the same 24 and gave up that much height (Nils 2026-08-06).
            Set Size to 46 628
            Set peAnchors to anTopLeftRight
            Set piColumnCount to 91         // the filter's 22, the buttons' 13, 15, 11, 17 and 12, then column 90
            Set psColumnWidths to "90/1fr"  // column 90 - the toggle - takes the extra width

            /* THE WORKSPACE CRUMB - the way back to the Start Center (Nils 2026-08-06).

               This view can now be reached WITHOUT asking for it: opening or copying a workspace
               that ends up with no folders selected sends the user straight here. Its only forward
               exit is Continue, which goes to Select Functions - the MANUAL wizard - so someone
               heading for the guided lane had no route back at all except the toolbar.

               Same shared builder the two boards paint, so all three name the workspace and offer
               the way out identically. It spans all 91 columns deliberately: it is row 0, the whole
               width, above the filter, the buttons and the toggle.

               Activates directly from the web OnClick, exactly like the Continue button in this
               same host - no deferral timer here (this view has never had one). */
            /* THE SCROLLBAR FIX, and why it lives HERE rather than in the shared builder.

               Every tile in this host opens with html,body{margin:0;padding:0;height:100%;
               overflow:hidden} - the chip strip's did, and the Continue button did. Without
               it the fragment is taller than its row and the box grows a vertical scrollbar, which
               is exactly what appeared on both bands (Nils 2026-08-06).

               WorkspaceCrumbHtml cannot carry that rule: the two BOARDS host it in a page that has
               to scroll, and application.css already fights to keep overflow-y:auto alive there
               (#viewport:has([class*="dash-"])). A shared overflow:hidden would break the thing it
               is shared with.

               So the view appends its own override AFTER the shared markup - later rules win - and
               takes the card flat while it is at it: inside a toolbar row the crumb is a bar, not a
               card, so the 6px margin and the border only cost height and read as a box inside a
               box. The COLOURS stay the shared ones, so it is still recognisably the same control. */
            /* ONE BREADCRUMB, BOTH DIRECTIONS (Nils 2026-08-06: "make it a bread crumb, like the
               Start Center one"). Back on the left, forward on the right, one row, one tile, one
               handler - instead of a link at one end and a filled teal button at the other.

               The forward step is named, not verbed. "Start Center" says where back goes, so the
               other end says where forward goes: SELECT FUNCTIONS. That is what makes it a
               breadcrumb rather than a link and a command sharing a strip. (It read "Continue"
               until now - say the word and the caption comes back; only this one string changes.)

               IT IS ABSENT WITH NO FOLDERS SELECTED - the derived rule from before, unchanged: the
               Start Center sends the user here on exactly that condition, so the zero is the
               signal, and Select Functions' Run refuses to start without folders anyway. Tick one
               and the step appears. */
            Function CrumbBarHtml Returns String
                String sHtml sTail
                Integer iSel
                Get TotalSelectedFolders of (phoFolderSelHeaDD(ghoApplication)) to iSel
                Move "" to sTail
                If (iSel > 0) ;
                    Move ((ClickableHtml("span", "dash-crumb-fwd", "continue", "", ('Select Functions' + (DashIcon(CS_GlyphChevron))), "On to Select Functions, where the refactoring run is started."))) to sTail
                // ...SURFACE-rooted (Nils 2026-08-09): this view is reached from the Start Center AND
                // from any of the three boards, so "back" is wherever the user stepped in from.
                Get WorkspaceCrumbSurfaceTailHtml of ghoTileMarkup sTail to sHtml
                Move (sHtml + CS_PaletteCssLink + CS_PageFitCssLink + CssLink("selectfolders")) to sHtml
                Function_Return sHtml
            End_Function

            Object oWebCrumb_htm is a cFTWebHtmlBox
                Set piColumnSpan  to 91       // row 0, the whole width
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
                        <path d="M9 6l6 6l-6 6"/></svg>Start Center</span><span class="dash-crumb-sep">|</span><span class="dash-crumb-none">No workspace loaded</span></div>
                <link rel="stylesheet" href="RDCFlexTron/palette.css">
                <link rel="stylesheet" href="RDCFlexTron/buttons.css">
                <link rel="stylesheet" href="RDCFlexTron/bars.css">
                <link rel="stylesheet" href="RDCFlexTron/pagefit.css">
                <link rel="stylesheet" href="CssStyle/selectfolders.css">
                """

                // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
                Procedure End_Construct_Object
                    Forward Send End_Construct_Object
                    Set psHtml to (CrumbBarHtml(Self))
                End_Procedure
                Procedure OnClick String sId String sParam
                    Integer iSurface

                    If (sId = "startcenter") ;
                        Send Activate_oStartCenter_vw of (Client_Id(phoMainPanel(ghoApplication)))
                    // The crumb root when it names a BOARD - the surface the user stepped in from.
                    // Same ladder the Editor's crumb runs; direct activation, no defer timer, as the
                    // forward step below does.
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
                    End
                    If (sId = "continue") Begin
                        // Being in the Folders view - and stepping forward - is unambiguously WORKSPACE
                        // mode (only the Single File button sets single-file mode). Re-assert it so a
                        // stale flag from an earlier single-file run cannot make the engine reload and
                        // activate the editor on this run.
                        Set pbWorkspaceMode of ghoApplication to True
                        Send Activate_oSelectFunctionsView of (Client_Id(phoMainPanel(ghoApplication)))
                    End
                End_Procedure
            End_Object


            /* FILE-EXTENSION FILTER. A cWebCombo is a <select>: it lists, it takes no typing. The list is
               GRANULAR - the standard/DF extension SETS plus each *.ext they hold on its own, so a pick is a
               broad set or a single extension - and the filter in use is always in it, wherever it came from
               (a command line sets it too): a <select> cannot show a value it does not list. OnChange saves
               the pick to SysFile.FileExtensionFilter; OnWorkspaceLoaded Refills so the current filter shows.

               ADD A FILTER (Nils 2026-10-14: "It must be possible to add a new extension"). The native combo
               this replaced was editable; the pick-only list of 2026-06-16 left no way to type one. The
               list's last item now asks for one in a box (AskForFileFilter): a filter typed there becomes
               the filter, goes on top of the user's list (RememberFilter) and stays pickable. */
            Object oWebFileFilter_cf is a cFTWebCombo
                Set piRowIndex to 1
                Set piColumnIndex to 0
                Set piColumnSpan  to 22       // 176 px: the 45 px label and a 121 px field - a pick shows its start
                Set psLabel to "Filter:"
                Set psToolTip to "File extensions filter. Pick a standard set or a single extension - or Add a filter... at the bottom of the list to type one. Each starts with *. and they are separated by ;"
                Set peSortItems to csUnsorted
                Set pbServerOnChange to True
                // No psLabelColor - see the note in CompilerSetupFT. The other three cFTWebCombo
                // instances never set it and take their colour from FtCompact, as this one now does.
                Set peLabelAlign to alignRight
                Set piLabelOffset to 45

                // The last item's value: no filter, as no file extension holds a "<".
                Property String psAddItemValue "<add>"
                // The user's list is the settings DFExtension0 to DFExtension<this> - the classic view's too.
                Property Integer piMaxUserFilters 8

                // The items, in order: the broad SETS (each a full "*.a;*.b;..." filter) - the standard ones,
                // the Studio's and the user's list - then each *.ext they hold on its own, and last the filter
                // in use when none of those is it. No item twice, case aside.
                Function FilterItems Returns String[]
                    String sDFExtensions sDFVersion sPart
                    Integer iMajorVersion iMinorVersion iCount iSize iPart iPartSize
                    String[] asSets asUserExtensions asParts asItems asSeen

                    Move FMAC_VERSION  to iMajorVersion
                    Move FMAC_REVISION to iMinorVersion
                    Move (String(iMajorVersion) + "." + String(iMinorVersion)) to sDFVersion
                    Get StudioFileExtensions of ghoApplication sDFVersion to sDFExtensions

                    Move CS_StdExtensions to asSets[-1]
                    Move CS_DFAndTemplExt to asSets[-1]
                    Move CS_PkgIncExt     to asSets[-1]
                    Move CS_SrcPkgExt     to asSets[-1]
                    If (sDFExtensions <> String(cx_RegKeyDFKeyDoesNotExist)) ;
                        Move sDFExtensions to asSets[-1]
                    Get UserSavedExtensions to asUserExtensions
                    Move (SizeOfArray(asUserExtensions)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Move (Trim(asUserExtensions[iCount])) to asSets[-1]
                    Loop

                    // Each SET as an item.
                    Move (SizeOfArray(asSets)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Move asSets[iCount] to sPart
                        If (sPart <> "" and (SearchArray(Lowercase(sPart), asSeen)) = -1) Begin
                            Move sPart to asItems[-1]
                            Move (Lowercase(sPart)) to asSeen[-1]
                        End
                    Loop
                    // Each extension the sets hold, as an item of its own.
                    For iCount from 0 to iSize
                        Get StrSplitToArray asSets[iCount] ";" to asParts
                        Move (SizeOfArray(asParts)) to iPartSize
                        Decrement iPartSize
                        For iPart from 0 to iPartSize
                            Move (Trim(asParts[iPart])) to sPart
                            If (sPart <> "" and (SearchArray(Lowercase(sPart), asSeen)) = -1) Begin
                                Move sPart to asItems[-1]
                                Move (Lowercase(sPart)) to asSeen[-1]
                            End
                        Loop
                    Loop
                    // The filter in use.
                    Move (Trim(SysFile.FileExtensionFilter)) to sPart
                    If (sPart <> "" and (SearchArray(Lowercase(sPart), asSeen)) = -1) ;
                        Move sPart to asItems[-1]

                    Function_Return asItems
                End_Function

                // With no Server set, OnFill is the sole source (FillFromDDO no-ops).
                Procedure OnFill
                    String[] asItems
                    Integer iCount iSize

                    Get FilterItems to asItems
                    Move (SizeOfArray(asItems)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Send AddComboItem asItems[iCount] asItems[iCount]
                    Loop
                    Send AddComboItem (psAddItemValue(Self)) "Add a filter..."

                    // Select the current filter (FilterItems lists it).
                    Set psValue to (Trim(SysFile.FileExtensionFilter))
                End_Procedure

                // OnChange fires on a pick (not per keystroke), so the pick is saved straight to SysFile - all
                // but "Add a filter...", which asks for one in a box: one tick later (oFileFilterDeferTimer).
                Procedure OnChange String sNewValue String sOldValue
                    If (sNewValue = psAddItemValue(Self)) Begin
                        Send Arm of oFileFilterDeferTimer
                        Procedure_Return
                    End
                    Send SaveFilter sNewValue
                End_Procedure

                Procedure SaveFilter String sFilter
                    Reread SysFile
                        Move sFilter to SysFile.FileExtensionFilter
                        SaveRecord SysFile
                    Unlock
                End_Procedure

                /* "Add a filter..." was picked, a tick ago: what to add, in a box. A filter typed there is the
                   filter from now on and goes on top of the user's list. Then the combo shows the filter - the
                   new one, or the one before for a box closed without one; until then it shows "Add a filter...". */
                Procedure AskForFileFilter
                    String sTyped sFilter sBody
                    Boolean bAdd
                    Handle hoHost

                    Move "" to sTyped
                    Move (HelpParagraph("One or more file extensions, separated by a semicolon - for example " + (CodeText("*.pkg")) + " or " + (CodeText("*.src;*.pkg;*.inc")) + ".")) to sBody
                    Move (sBody + (HelpParagraph("The filter is used from now on, and is kept in the list."))) to sBody
                    Get FTInputBox "Add a file filter" sBody "Filter:" (&sTyped) "Add" "Cancel" to bAdd
                    If (bAdd and (Trim(sTyped) <> "")) Begin
                        Get NormalizedFilter sTyped to sFilter
                        If (sFilter = "") Begin
                            Send FTInfoBox ("Nothing was added: " + Trim(sTyped) + " holds no file extension. Type extensions like *.pkg, separated by a semicolon.") "Add a file filter"
                        End
                        Else Begin
                            // The list first: it leaves out a filter it lists already, and the one in use is listed.
                            Send RememberFilter sFilter
                            Send SaveFilter sFilter
                        End
                    End

                    // A page that is not up shows the filter when it loads: every page fills its combos itself.
                    Get Host to hoHost
                    If (FTHostPageIsUp(hoHost)) Begin
                        Send Refill
                        WebSet psValue to (Trim(SysFile.FileExtensionFilter))
                        Send CheckUpdateWebUI of hoHost
                    End
                End_Procedure

                // What was typed, as a filter: "pkg", ".pkg", "*.PKG", "*.src; *.pkg" and "src, pkg" read as
                // "*.pkg" and "*.src;*.pkg" - lower case, *. before each name, no spaces, nothing twice. A part
                // with a character no file extension has (a dot inside it, a wildcard, a path) is left out;
                // "" when nothing is left.
                Function NormalizedFilter String sTyped Returns String
                    String sPart sChar
                    String[] asParts asDone
                    Integer iPart iPartSize iChar iLength
                    Boolean bValid

                    Move (Lowercase(sTyped)) to sTyped
                    Move (Replaces(",", sTyped, ";")) to sTyped
                    Move (Replaces(" ", sTyped, ";")) to sTyped
                    Get StrSplitToArray sTyped ";" to asParts
                    Move (SizeOfArray(asParts)) to iPartSize
                    Decrement iPartSize
                    For iPart from 0 to iPartSize
                        Move (Trim(asParts[iPart])) to sPart
                        While (Left(sPart, 1) = "*" or Left(sPart, 1) = ".")
                            Move (Right(sPart, Length(sPart) - 1)) to sPart
                        Loop
                        Move (sPart <> "") to bValid
                        Move (Length(sPart)) to iLength
                        For iChar from 1 to iLength
                            Move (Mid(sPart, 1, iChar)) to sChar
                            If (Pos(sChar, '.*?/\:"<>|') > 0) ;
                                Move False to bValid
                        Loop
                        If (bValid and (SearchArray("*." + sPart, asDone)) = -1) ;
                            Move ("*." + sPart) to asDone[-1]
                    Loop

                    Function_Return (StrJoinFromArray(asDone, ";"))
                End_Function

                // A new filter goes on top of the user's list and the oldest falls off its end. One the combo
                // lists already is not added again.
                Procedure RememberFilter String sFilter
                    String sExt
                    String[] asItems asUserExtensions
                    Integer iCount iSize iMax

                    Get FilterItems to asItems
                    Move (SizeOfArray(asItems)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        If (Lowercase(asItems[iCount]) = Lowercase(sFilter)) ;
                            Procedure_Return
                    Loop

                    Get UserSavedExtensions to asUserExtensions
                    Move (SizeOfArray(asUserExtensions)) to iSize
                    Get piMaxUserFilters to iMax
                    Send WriteString of ghoApplication CS_Settings (CS_DFExtensionsKey + "0") sFilter
                    // Every key down to the last, a blank one too - so no filter is left behind twice.
                    For iCount from 1 to iMax
                        Move "" to sExt
                        If (iCount <= iSize) ;
                            Move asUserExtensions[iCount - 1] to sExt
                        Send WriteString of ghoApplication CS_Settings (CS_DFExtensionsKey + String(iCount)) sExt
                    Loop
                End_Procedure

                // The user's list: up to nine filters (from the old editable combo, and from Add a filter...).
                Function UserSavedExtensions Returns String[]
                    String[] asUserExtensions
                    String sExt
                    Integer iCount iMax
                    Get piMaxUserFilters to iMax
                    For iCount from 0 to iMax
                        Get ReadString of ghoApplication CS_Settings (CS_DFExtensionsKey + String(iCount)) "" to sExt
                        If (sExt <> "") ;
                            Move sExt to asUserExtensions[-1]
                    Loop
                    Function_Return asUserExtensions
                End_Function

                Procedure Request_Clear
                End_Procedure
            End_Object

            Object oSelectAllBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 22
                Set piColumnSpan to 13
                Set psCaption to "Select All"
                Set psCSSClass to "ftbtn ftg-selectall"

                Procedure OnClick
                    Send SelectAll of oDbFolders_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oSelectNoneBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 35
                Set piColumnSpan to 15
                Set psCaption to "Select None"
                Set psCSSClass to "ftbtn ftg-selectnone"

                Procedure OnClick
                    Send SelectNone of oDbFolders_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oInvertBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 50
                Set piColumnSpan to 11
                Set psCaption to "Invert"
                Set psCSSClass to "ftbtn ftg-invert"

                Procedure OnClick
                    Send SelectInvert of oDbFolders_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oSelectSubtreeBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 61
                Set piColumnSpan to 17
                Set psCaption to "Select Subtree"
                Set psCSSClass to "ftbtn ftg-hierarchy"

                Procedure OnClick
                    Send SelectFocusedSubtree of oDbFolders_grd
                    Forward Send OnClick
                End_Procedure
            End_Object

            Object oRescanBtn is a cFTWebButton
                Set piRowIndex to 1
                Set piColumnIndex to 78
                Set piColumnSpan to 12
                Set psCaption to "Re-scan"
                Set psCSSClass to "ftbtn ftg-refresh"

                Procedure OnButtonClick
                    Send DoRescanFolders of oSelectFoldersView
                End_Procedure
            End_Object

            /* "Include libraries" - the setting CS_IncludeLibFoldersKey, which Re-scan and a workspace load read.
               A toggle, not a button, so it stays markup - the chip strip's box, unchanged - in column 90, the
               stretching column: the part of the bar that gives way when the view is narrow. */
            Function IncludeLibToggleHtml Returns String
                String sOn sVal
                Get ReadString of ghoApplication CS_Settings CS_IncludeLibFoldersKey "1" to sVal
                If (sVal <> "0") ;
                    Move " on" to sOn
                Else ;
                    Move "" to sOn
                Function_Return ((CssLink("selectfolders")) + (ClickableHtml("div", "sfchk", "includelib", "", ((SpanOpen(("sfbox" + sOn))) + CS_SpanEnd + 'Include libraries'), "When ticked, scanning for folders also follows the workspace library (.sws) references and includes their source folders. Untick to scan only the selected workspace.")))
            End_Function

            Object oIncludeLib_htm is a cFTWebHtmlBox
                Set piRowIndex to 1
                Set piColumnIndex to 90
                Set piColumnSpan  to 1
                // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
                // psHtml it can parse. It is the string the runtime seeds (dumped by the cFTWebHtmlBox design
                // dump, no workspace loaded); the runtime expression sits in End_Construct_Object below.
                Set psHtml to """
                <link rel="stylesheet" href="CssStyle/selectfolders.css">
                <div class="sfchk" data-ServerOnClick="includelib"
                    title="When ticked, scanning for folders also follows the workspace library (.sws) references and includes their source folders. Untick to scan only the selected
                    workspace."><span class="sfbox on"></span>Include libraries</div>
                """

                // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
                Procedure End_Construct_Object
                    Forward Send End_Construct_Object
                    Set psHtml to (IncludeLibToggleHtml(Self))
                End_Procedure

                Procedure OnClick String sId String sParam
                    String sVal
                    If (sId = "includelib") Begin
                        Get ReadString of ghoApplication CS_Settings CS_IncludeLibFoldersKey "1" to sVal
                        Move (If(sVal = "0", "1", "0")) to sVal
                        Send WriteString of ghoApplication CS_Settings CS_IncludeLibFoldersKey sVal
                        Send PushHtml of Self (IncludeLibToggleHtml(Self))
                    End
                End_Procedure
            End_Object

        End_Object

        /* Below the action bar ON PURPOSE. CrumbBarHtml is an object-level function on
           oWebActionBar, and a function-style call needs that definition already parsed - unlike a
           Send, which resolves globally across the compile. Declared above it, this was error 4328
           ("Undefined symbol in argument"). The timer above reaches this by Send for that reason.

           Repaints the WHOLE crumb, because the forward step is part of it now - there is no
           separate button left to refresh. */
        Procedure RefreshContinue
            Send PushHtml of (oWebCrumb_htm(oWebActionBar(Self))) (CrumbBarHtml(oWebActionBar(Self)))
        End_Procedure

        Procedure UpdateEnabledState
            Boolean bWorkspaceMode
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
            Set Enabled_State to (bWorkspaceMode = True and sSWSFile <> "")
        End_Procedure

        Procedure OnFileDropped String sFilename Boolean bLast
            Delegate Send OnFileDropped sFilename bLast
        End_Procedure

    End_Object

    Procedure OnFileDropped String sFilename Boolean bLast
        Delegate Send OnFileDropped sFilename bLast
    End_Procedure

    Procedure UpdateEnabledState
        String sSWSFile
        Get psSWSFile of ghoApplication to sSWSFile
        Set Enabled_State to (sSWSFile <> "")  
    End_Procedure   
    
    Procedure OnFileDropped String sFilename Boolean bLast
        Delegate Send OnFileDropped sFilename bLast
    End_Procedure

    Function pbShouldSave Returns Boolean
        Function_Return (Changed_State(Self))
    End_Function

    Procedure Request_Clear
        Set Changed_State to False
        Forward Send Request_Clear
    End_Procedure

    Procedure Request_Clear_All
        Set Changed_State to False
        Forward Send Request_Clear_All
    End_Procedure

    Procedure OnSetFocus
        Set piActiveView of ghoApplication to CI_CleanupSource Self
    End_Procedure

    Procedure DoFreshGrids
        If (IsComObjectCreated(oDbFolders_grd)) Begin
            Send RefreshDataFromDD of oDbFolders_grd 0
        End
    End_Procedure
    
    Procedure OnWorkspaceLoaded
        Integer iSelectedFolders  
        Handle hoFolderSelHeaDD hoDD hoHost
        Boolean bExists bOK bLibInclude
        String sHomePath sUserName sWorkspaceHome sValue
        tFolderData[] asSavedFolders
        
        Get psWorkspaceHomePath  of ghoApplication to sWorkspaceHome
        If (sWorkspaceHome = "") Begin
            Procedure_Return
        End

        Get phoFolderSelHeaDD of ghoApplication to hoFolderSelHeaDD
        Get ReadString of ghoApplication CS_Settings CS_IncludeLibFoldersKey "1" to sValue
        Move (sValue <> "0") to bLibInclude
        Get SaveNewHeaderAndChildRecords of hoFolderSelHeaDD sWorkspaceHome bLibInclude to bOK
        Send Request_Assign of hoFolderSelHeaDD
        Move FolderSelHea.ID to FolderSelDtl.FolderSelHeaID
        Move FolderSelHea.WorkspaceHomeFolder to FolderSelDtl.FolderName
        Send Find of oFolderSelDtl_DD GE Index.1
        // Only to a page that is up (2026-10-12). Refill always queues a "fill" for the client, and one sent
        // while this view is not on screen - the usual case, see below - goes out with the view's next page,
        // before that page has built the combo: "Could not find object", error 999 (DashboardFT's PrimeCombo
        // has the story). A page that loads fills its combos itself.
        Get Host of oWebFileFilter_cf to hoHost
        If (FTHostPageIsUp(hoHost)) ;
            Send Refill of oWebFileFilter_cf
        // The crumb names the loaded workspace, so it goes stale the moment one changes - including
        // while this view is nowhere near the screen, which is the usual case (the Start Center is
        // where workspaces are opened). Broadcast to every view, so this is the one place it can be
        // caught for certain.
        // CrumbBarHtml, not the shared builder direct - this view's crumb carries the forward step
        // and the flat-bar overrides, and repainting with the plain one would drop both.
        Send RefreshContinue of oDbSourceFolders_grp
    End_Procedure

    // Allow a source file, .sws file or a folder to be dropped on the view:
    Procedure OnFileDropped String sFileFolderName Boolean bLast
        String sFileExt
        Boolean bFile bFolder bSWSFile

        Forward Send OnFileDropped sFileFolderName bLast
        // We only deal with the last dropped file/folder if more than one was dropped.
        If (bLast = False) Begin
            Procedure_Return
        End
        
        // Try to find out if a file or a folder name was dropped on the view:
        Get ParseFileExtension sFileFolderName to sFileExt
        Move (Lowercase(sFileExt)) to sFileExt
        Move (sFileExt = "")    to bFolder
        Move (sFileExt = "sws") to bSWSFile
        Move (bSWSFile = False and bFolder = False) to bFile
        
        If (bFolder = True) Begin  
            Send Activate of oDbFolders_grd
            Send AddItem of oDbFolders_grd sFileFolderName
            Procedure_Return
        End
        Else If (bLast = True) Begin
            If (bFile = True) Begin
                Send OnFileNameUpdate of ghoApplication sFileFolderName
                Set pbWorkspaceMode of ghoApplication to False
            End
            If (bSWSFile = True) Begin
                Send UpdateWorkSpaceFileToRegistry  of ghoApplication sFileFolderName
                Send UpdateWorkspaceSelectorDisplay of ghoApplication sFileFolderName
            End
        End
        Else Begin
            Send FTInfoBox "Only on file can be dropped on the view at a time. The last will be used."
        End
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle
            Broadcast Recursive Send UpdateEnabledState of (Parent(Self))
        End_Procedure
    End_Object

    // Re-scan the workspace source folders - the Re-scan button's OnButtonClick, after the web click (it ends in
    // a message box). Reads the Include-library-folders SETTING, which the toggle beside the buttons writes.
    Procedure DoRescanFolders
        Integer iNew
        Handle hoFolderSelHeaDD
        String sMsg
        Boolean bLibInclude
        String sVal

        Get phoFolderSelHeaDD of ghoApplication to hoFolderSelHeaDD
        Get ReadString of ghoApplication CS_Settings CS_IncludeLibFoldersKey "1" to sVal
        Move (sVal <> "0") to bLibInclude
        Get RefreshFolderRecords of hoFolderSelHeaDD bLibInclude to iNew
        Send Request_Assign of hoFolderSelHeaDD
        Move FolderSelHea.ID to FolderSelDtl.FolderSelHeaID
        Move FolderSelHea.WorkspaceHomeFolder to FolderSelDtl.FolderName
        Send Find of oFolderSelDtl_DD GE Index.1
        Send RefreshDataFromDD of oDbFolders_grd 0
        If (iNew > 0) Begin
            Move (String(iNew) * "folder(s) added to the list.") to sMsg
        End
        Else If (iNew < 0) Begin
            // Library folders (checkbox unticked) or system folders an older scan had listed - a
            // DfPkg package checkout, since 2026-08-18 excluded like the framework folders.
            Move (String(0 - iNew) * "folder(s) removed from the list (library folders, or system folders such as a DfPkg package checkout).") to sMsg
        End
        Else Begin
            Move "No changes to the folder list." to sMsg
        End
        Send FTInfoBox sMsg "Re-scan Folders"
    End_Procedure
    
    // FlexTron-only dark tint (FlexTron FT copy; production uses the un-suffixed file). The dark CodeJock theme
    // skins the chrome but NOT the native control client areas, so once this view's subtree is built,
    // cascade clDarkViewBg/clDarkThemeText down it (the pattern drafted in TestBench.src:468, scoped
    // to Self instead of the whole UI).
    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        Broadcast Recursive Set Color     of Self to (FTViewBg())
        Broadcast Recursive Set TextColor of Self to (FTThemeInk())
        // The web action-bar host renders its own var(--dfr-bg-page, #262624) (clDarkWebBg) content; re-assert its gutter colour
        // AFTER the recursive cascade above (which would otherwise paint it the lighter clDarkViewBg).
        Set Color of oWebActionBar to (FTWebBg())
    End_Procedure

    Procedure Request_Clear
    End_Procedure
    
End_Object
