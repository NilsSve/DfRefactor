Use Cursor.pkg
Use dfLine.pkg
Use cCJCommandBarSystem.pkg
//Use cDbCJGridColumnSuggestion.pkg
Use cRDCSuggestionsBaseClasses.pkg
Use DFEnChk.pkg
Use dfTabDlg.pkg

//Use cRefactorDbView.pkg
Use cRDCDbView.pkg
Use cRDCDbCJGrid.pkg  
Use cRDCDbCJGridColumn.pkg
Use cRDCDbComboForm.pkg
Use RefactorConstants.h.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbSpinForm.pkg
Use cRDCButton.pkg
Use cRDCForm.pkg
Use TestCompile.dg

Use cSysFileDataDictionary.dd
//Use cFunctionsDataDictionary.dd
Use cFolderSelHeaDataDictionary.dd
Use cFolderSelDtlDataDictionary.dd

Register_Procedure RefreshSelectionUpdate
Register_Procedure ActivateProcess

Activate_View Activate_oSelectFoldersView for oSelectFoldersView
Object oSelectFoldersView is a cRDCDbView
    Set Location to 1 0
    Set Size to 239 638
    Set Label to "Select Folders"
//    Set psToolTip to "Select Source Folders"
    Set Icon to "Folder.ico"
    Set pbAcceptDropFiles to True
    Set Auto_Clear_DEO_State to False  
    Set Auto_Top_Panel_State to False
    Set phoFoldersView of ghoApplication to Self   
    
    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    Object oFolderSelHea_DD is a cFolderSelHeaDataDictionary
        Set phoFolderSelHeaDD of ghoApplication to Self  
    End_Object

    Object oFolderSelDtl_DD is a cFolderSelDtlDataDictionary
        Set DDO_Server to oFolderSelHea_DD
        Set Constrain_File to FolderSelHea.File_Number

        Procedure Relate_Main_File
            String[] asFolders asEmpty
            Integer iIDa iIDb
            Get pasCmdLineSetSelectedFolders of ghoApplication to asFolders
            If (SizeOfArray(asFolders) = 0) Begin
                Procedure_Return
            End
            Forward Send Relate_Main_File
            Get Field_Current_Value Field FolderSelDtl.FolderSelHeaID to iIDa
            Get Field_Current_Value Field FolderSelDtl.ID             to iIDb
            If (iIDa <> 0 and iIDb <> 0) Begin
                Send CmdLineSetSelectedFolders asFolders 
                // Reset ghoApplication property to only update database once on startup.
                Set pasCmdLineSetSelectedFolders of ghoApplication to asEmpty
            End
        End_Procedure
    End_Object

    Set Main_DD to oFolderSelDtl_DD
    Set Server to oFolderSelDtl_DD
                                    
    Object oDbSourceFolders_grp is a cRDCDbHeaderGroup
        Set Location to 4 0
        Set Size to 185 634
        Set Label to "Folders List"
        Set psImage to "Folder.ico"
        Set psNote to "Select Folders. Right click grid for options"
        Set psToolTip to "You can add a folder with drag and drop from Windows Explorer, or by using the right-click mouse menu."
        Set peAnchors to anAll
        Set Border_Style to Border_None
        Set piMinSize to 126 490

        Object oDbFolders_grd is a cRDCDbCJGrid
            Set Server to oFolderSelDtl_DD
            Set Size to 157 620
            Set Location to 27 10
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
            
            On_Key Key_F2           Send Request_Save 
            On_Key Key_Ctrl+Key_S   Send Request_Save
            On_Key Key_Delete       Send Request_Delete
            On_Key Key_Shift+Key_F2 Send Request_Delete 
            On_Key Key_Ctrl+Key_F5  Send ActivateProcess
        End_Object

        // Controls whether folder scanning (on workspace open and via
        // Re-scan) follows the workspace's library (.sws) references and
        // includes their source folders. Persisted across sessions; both
        // the on-open scan and the Re-scan button honor it.
        Object oIncludeLibFolders_cb is a CheckBox
            Set Size to 12 170
            Set Location to 12 449
            Set Label to "Include library folders"
            Set Status_Help to "When ticked, scanning for folders also follows the workspace's library (.sws) references and includes their source folders. Untick to scan only the selected workspace."
            Set peAnchors to anTopRight
            Set Checked_State to True

            Procedure End_Construct_Object
                String sVal
                Forward Send End_Construct_Object
                Get ReadString of ghoApplication CS_Settings CS_IncludeLibFoldersKey "1" to sVal
                Set Checked_State to (sVal <> "0")
            End_Procedure

            Procedure OnChange
                Boolean bChecked
                String sVal
                Get Checked_State to bChecked
                Move "0" to sVal
                If (bChecked = True) ;
                    Move "1" to sVal
                Send WriteString of ghoApplication CS_Settings CS_IncludeLibFoldersKey sVal
            End_Procedure
        End_Object

        Object oSelectSubtree_btn is a Button
            Set Size to 14 80
            Set Location to 10 150
            Set Label to "Select Subtree"
            Set psImage to "SelectAll.ico"
            Set psToolTip to "Select the currently-focused folder and ALL of its sub-folders. Handy for deep library trees - enable a whole subtree in one click instead of ticking each folder."
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectFocusedSubtree of oDbFolders_grd
            End_Procedure
        End_Object

        Object oSelectAll_btn is a Button
            Set Size to 14 62
            Set Location to 10 238
            Set Label to "Select All"
            Set psImage to "SelectAll.ico"
            Set psToolTip to "(Ctrl+A)"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectAll of oDbFolders_grd
            End_Procedure
        End_Object 
        
        Object oSelectNone_btn is a Button
            Set Size to 14 62
            Set Location to 10 304
            Set Label to "Select None"
            Set psImage to "SelectNone.ico"
            Set psToolTip to "(Ctrl+N)"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectNone of oDbFolders_grd
            End_Procedure
        End_Object

        Object oSelectInvert_btn is a Button
            Set Size to 14 74
            Set Location to 10 370
            Set Label to "Invert Selections"
            Set psImage to "SelectInvert.ico"
            Set psToolTip to "(Ctrl+I)"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectInvert of oDbFolders_grd
            End_Procedure
        End_Object

        // Re-scans the workspace for source folders. With "Include
        // library folders" ticked it merges in the library folders (.sws
        // [Libraries] / aDependencies); unticked it removes them. The
        // workspace's own + manually added folders are kept either way.
        Object oRescanFolders_btn is a Button
            Set Size to 14 52
            Set Location to 10 539
            Set Label to "Re-scan"
            Set psToolTip to "Re-scan the workspace for source folders, following library (.sws) references, and add any newly found folders. Existing folders and their selections are kept."
            Set psImage to "Refresh.ico"
            Set peAnchors to anTopRight 
            
            Procedure OnClick
                Integer iNew
                Handle hoFolderSelHeaDD
                String sMsg
                Boolean bLibInclude
                Get phoFolderSelHeaDD of ghoApplication to hoFolderSelHeaDD
                Get Checked_State of oIncludeLibFolders_cb to bLibInclude
                Get RefreshFolderRecords of hoFolderSelHeaDD bLibInclude to iNew
                // Reload the folders grid (mirror OnWorkspaceLoaded).
                Send Request_Assign of hoFolderSelHeaDD
                Move FolderSelHea.ID to FolderSelDtl.FolderSelHeaID
                Move FolderSelHea.WorkspaceHomeFolder to FolderSelDtl.FolderName
                Send Find of oFolderSelDtl_DD GE Index.1
                Send RefreshDataFromDD of oDbFolders_grd 0
                If (iNew > 0) Begin
                    Move (String(iNew) * "folder(s) added to the list.") to sMsg
                End
                Else If (iNew < 0) Begin
                    Move (String(0 - iNew) * "library folder(s) removed from the list.") to sMsg
                End
                Else Begin
                    Move "No changes to the folder list." to sMsg
                End
                Send Info_Box sMsg "Re-scan Folders"
            End_Procedure
        End_Object

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

Register_Object oFunctionSelection_grd
    Procedure UpdateEnabledState
        String sSWSFile
        Get psSWSFile of ghoApplication to sSWSFile
        Set Enabled_State to (sSWSFile <> "")
        Send Activate of oFunctionSelection_grd
    End_Procedure

    Object oFileFilters_grp is a cRDCDbHeaderGroup
        Set Size to 37 260
        Set Location to 199 6
        Set psLabel to "File Filter"
        Set psNote to "File Extensions Filter"
        Set psToolTip to "Select file extensions filter. Each extension must start with a wildcard character and a dot (*.) and file extensions must be separated with a semicolon (;)"
        Set psImage to "FileExtensions.ico"
        Set peAnchors to anBottomLeft

        Procedure UpdateEnabledState
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Set Enabled_State to (sSWSFile <> "")
        End_Procedure

        // Note: We can't set the entry to "SysFile.FileExtensionFilter", because
        // DataFlex does not handle datadictonary system file fields well.
        // In fact what happens is that is not possible to edit the comboform, other
        // than selecting an existing value from the list.
        // We therefore handle the saving/editing of the comboform manually.
        Object oFileNameFilters_cf is a cRDCDbComboForm
            // Entry_Item SysFile.FileExtensionFilter
            // Set Server to oSysFile_DD
            Set Size to 12 250
            Set Location to 19 4
            Set psToolTip to "Select file extensions filter. Each extension must start with a wildcard character and a dot (*.) and file extensions must be separated with a semicolon (;)"
            Set Status_Help to (psToolTip(Self))
            Set Combo_Sort_State to False
            Set pbAutoEnable to True
            Set peAnchors to anTopLeftRight
            Set Form_Border to 0
            Set Label_Justification_Mode to JMode_Top
            Set Label_Col_Offset to 0

            Property Integer piMaxUserFilters 8

            Procedure Combo_Fill_List
                String sDFExtensions sDFVersion
                Integer iMajorVersion iMinorVersion iCount iSize
                String[] asUserExtensions

                Forward Send Combo_Fill_List
                Move FMAC_VERSION  to iMajorVersion
                Move FMAC_REVISION to iMinorVersion
                Move (String(iMajorVersion) + "." + String(iMinorVersion)) to sDFVersion
                Get StudioFileExtensions of ghoApplication sDFVersion to sDFExtensions

                Send Combo_Add_Item CS_StdExtensions
                Send Combo_Add_Item CS_DFAndTemplExt
                Send Combo_Add_Item CS_PkgIncExt
                Send Combo_Add_Item CS_SrcPkgExt

                If (sDFExtensions <> String(cx_RegKeyDFKeyDoesNotExist)) Begin
                    Send Combo_Add_Item sDFExtensions
                End

                Get UserSavedExtensions to asUserExtensions
                Move (SizeOfArray(asUserExtensions)) to iSize
                Decrement iSize
                For iCount from 0 to iSize
                    Send Combo_Add_Item (Trim(asUserExtensions[iCount]))
                Loop

                Set Value to (Trim(SysFile.FileExtensionFilter))
            End_Procedure

            Function UserSavedExtensions Returns String[]
                String[] asUserExtensions
                String sExt
                Integer iCount iSize

                Get piMaxUserFilters to iSize
                For iCount from 0 to iSize
                    Get ReadString  of ghoApplication CS_Settings (CS_DFExtensionsKey + String(iCount)) "" to sExt
                    If (sExt <> "") Begin
                        Move sExt to asUserExtensions[SizeOfArray(asUserExtensions)]
                    End
                Loop

                Function_Return asUserExtensions
            End_Function

            Procedure OnChange
                String sVal
                Boolean bChanged
                
                Get Value to sVal
                Move (sVal <> Trim(SysFile.FileExtensionFilter)) to bChanged 
                // ToDo: This needs to be changed after the function/folder view split:
                If (bChanged = True) Begin
//                    Set Field_Changed_Value of (oSysfile_DD(phoRefactorView(ghoApplication))) Field SysFile.FileExtensionFilter to sVal
//                    Set Field_Changed_State of (oSysfile_DD(phoRefactorView(ghoApplication))) Field SysFile.FileExtensionFilter to True
//                    Set Changed_State of (oSysfile_DD(phoRefactorView(ghoApplication)))  to True
                End
            End_Procedure  

            Function DEOInformation Handle ByRef hoServer Boolean ByRef bHasRecord Boolean ByRef bChanged Boolean ByRef bHasIndex Returns Boolean
                Get Changed_State to bChanged
                Function_Return True
            End_Function
            
            // Note: Can't save new extensions entered by user with the
            // OnChange event, as it would save character by character.
            Procedure OnExitObject
                Send Request_Save
            End_Procedure

            Procedure Request_Save
                String sDFExtensions sDFVersion sNewExt
                Integer iMajorVersion iMinorVersion iCount iSize iMaxUserFilters iItem
                String[] asUserExtensions
                Boolean bExists

                Move FMAC_VERSION  to iMajorVersion
                Move FMAC_REVISION to iMinorVersion
                Move (String(iMajorVersion) + "." + String(iMinorVersion)) to sDFVersion
                Get StudioFileExtensions of ghoApplication sDFVersion to sDFExtensions

                Get piMaxUserFilters to iSize
                Get Value to sNewExt
                
                Reread SysFile
                    Move sNewExt to SysFile.FileExtensionFilter
                    SaveRecord SysFile
                Unlock
                
                If (sNewExt <> CS_StdExtensions and ;
                    sNewExt <> CS_DFAndTemplExt and ;
                    sNewExt <> CS_PkgIncExt and ;
                    sNewExt <> CS_SrcPkgExt and ;
                    sNewExt <> sDFExtensions) Begin

                    Get IsExtensionInRegistry sNewExt to bExists

                    If (bExists = False) Begin
                        Get UserSavedExtensions to asUserExtensions
                        // Push the new item on top of the list
                        Send WriteString of ghoApplication CS_Settings (CS_DFExtensionsKey + String("0")) sNewExt
                        Get piMaxUserFilters to iMaxUserFilters
                        Move (SizeOfArray(asUserExtensions)) to iSize
                        Move (iMaxUserFilters min iSize) to iSize
                        Decrement iSize
                        Move 0 to iItem
                        For iCount from 0 to iSize
                            Send WriteString of ghoApplication CS_Settings (CS_DFExtensionsKey + String(iCount + 1)) asUserExtensions[iItem]
                            Increment iItem
                        Loop
                        Get piMaxUserFilters to iSize
                        Move iSize to iCount // Get out of loop
                    End
                End
            End_Procedure

            Function IsExtensionInRegistry String sExt Returns Boolean
                Boolean bExists
                String[] asUserExtensions
                Integer iCount iSize

                Move False to bExists
                Get UserSavedExtensions to asUserExtensions
                Move (SizeOfArray(asUserExtensions)) to iSize
                Decrement iSize
                For iCount from 0 to iSize
                    If (Lowercase(asUserExtensions[iCount]) = Lowercase(sExt)) Begin
                        Move True to bExists
                        Move iSize to iCount // We're done.
                    End
                Loop
                Function_Return bExists
            End_Function

            Function IsEnabled Returns Boolean
                Boolean bEnabled bWorkspaceMode
                String sFileName sSWSFile sHomePath
                Integer iSelectedFunctions iFolders 
                Handle hoFolderSelHeaDD
                Boolean bExists bUseDDO  
                tFolderData[] asSavedFolders

                Get pbWorkspaceMode         of ghoApplication to bWorkspaceMode
                If (bWorkspaceMode = False) Begin
                    Function_Return False
                End
                Get psSWSFile               of ghoApplication to sSWSFile
                Get psCurrentSourceFileName of ghoApplication to sFileName

                If (bWorkspaceMode = True) Begin
                    Move (sSWSFile <> "") to bEnabled
                End
                Else Begin
                    Move (sFileName <> "") to bEnabled
                End

                If (bEnabled = True) Begin
                    Move (SysFile.SelectedFunctionTotal > 0) to bEnabled
                End

                If (bEnabled = True) Begin
                    Get TotalFolders of (phoFolderSelHeaDD(ghoApplication)) to iFolders
                    Move (iFolders <> 0) to bEnabled
                End          
                If (bEnabled = False) Begin
                    Get Field_Current_Value of oSysFile_DD Field SysFile.bCountSourceLines to bEnabled
                End

                Function_Return bEnabled
            End_Function
            
            
            On_Key Key_Ctrl+Key_S Send OnExitObject
            On_Key Key_F2         Send OnExitObject
        End_Object

    End_Object

//    Procedure RefactoreCode
//        Handle hoEditor 
//        tRefactorFiles RefactorFiles 
//        String sFileFilter
//        
//        Move False to Err
//        Send Request_Save_No_Clear of oSysFile_DD
//        Get CollectFileData of ghoApplication (oFolderSelDtl_DD(Self)) to RefactorFiles
//        Get phoEditor of ghoApplication to hoEditor
//        If (Err = True) Begin
//            Procedure_Return
//        End
//
//        // Start the Engine!
//        Set peRunOrigin of ghoEngine to eRunManual
//        Send StartEngine of ghoEngine RefactorFiles hoEditor
//    End_Procedure

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

    Procedure Close_Panel
    End_Procedure

    // ToDo: What should the piActivateView be set to?
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
        Handle hoFolderSelHeaDD hoDD
        Boolean bExists bOK bLibInclude
        String sHomePath sUserName sWorkspaceHome sValue
        tFolderData[] asSavedFolders
        
        Get psWorkspaceHomePath  of ghoApplication to sWorkspaceHome
        If (sWorkspaceHome = "") Begin
            Procedure_Return
        End

        Get phoFolderSelHeaDD of ghoApplication to hoFolderSelHeaDD        
        Get Checked_State of oIncludeLibFolders_cb to bLibInclude
        Get SaveNewHeaderAndChildRecords of hoFolderSelHeaDD sWorkspaceHome bLibInclude to bOK 
        Send Request_Assign of hoFolderSelHeaDD 
        Move FolderSelHea.ID to FolderSelDtl.FolderSelHeaID
        Move FolderSelHea.WorkspaceHomeFolder to FolderSelDtl.FolderName
        Send Find of oFolderSelDtl_DD GE Index.1
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
                Send DisplayWorkspaceItem of (oWorkspaceSelector_Menuitem(ghoCommandBars)) sFileFolderName
            End
        End
        Else Begin
            Send Info_Box "Only on file can be dropped on the view at a time. The last will be used."
        End
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle 
            Broadcast Recursive Send UpdateEnabledState of (Parent(Self))
        End_Procedure
    End_Object

End_Object
