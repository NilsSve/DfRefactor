Use Cursor.pkg
Use dfLine.pkg
Use cCJCommandBarSystem.pkg
Use cDbCJGridColumnSuggestion.pkg
Use cRDCCJGridColumnSuggestion.pkg
Use DFEnChk.pkg
Use dfTabDlg.pkg

Use cRefactorDbView.pkg
Use cRDCDbCJGrid.pkg  
Use cRDCDbCJGridColumn.pkg
Use cRDCCJSelectionGrid.pkg
Use cRDCDbComboForm.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbSpinForm.pkg
Use cRDCButton.pkg
Use cRDCForm.pkg
 
Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd
Use cFolderSelHeaDataDictionary.dd
Use cFolderSelDtlDataDictionary.dd
Use cdbCJGridColumn.pkg
Use Windows.pkg

Enum_List
    Integer Ico_Folders
    Integer Ico_Functions
End_Enum_List

Object oImageList is a cImageList32
    Set piMaxImages to 2
    Set piImageHeight to 24
    Set piImageWidth to 24
    Procedure OnCreate
        Get AddImage "Folder.ico"          to Ico_Folders
        Get AddImage "FunctionLibrary.ico" to Ico_Functions
    End_Procedure
End_Object                                 

Register_Procedure RefreshSelectionUpdate
Register_Procedure ActivateProcess

Activate_View Activate_oRefactorView for oRefactorView
Object oRefactorView is a cRefactorDbView
    Set Location to 1 0
    Set Size to 315 654
    Set Label to "Selections"
    Set Icon to "DFRefactor.ico"
    Set pbAcceptDropFiles to True
    Set Auto_Clear_DEO_State to False  
    Set Auto_Top_Panel_State to False
    Set phoRefactorView of ghoApplication to Self   
    
    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    Object oFolderSelHea_DD is a cFolderSelHeaDataDictionary
        Set phoFolderSelHeaDD of ghoApplication to Self  
    End_Object

    Object oFolderSelDtl_DD is a cFolderSelDtlDataDictionary
        Set DDO_Server to oFolderSelHea_DD
        Set Constrain_File to FolderSelHea.File_Number
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary  
        
        // In this view we are also interested in saving the system file,
        // when the oCountSourceLines_cb object is changed.
        // So relay save message here.
        Procedure Request_Save
            SaveRecord SysFile
            Forward Send Request_Save
        End_Procedure
        
        Procedure OnConstrain
            If (piFunctionType(Self) <> eAll_Functions) Begin
                Constrain Functions.Type eq (piFunctionType(Self))
            End
        End_Procedure

    End_Object

    Procedure Request_Save
        Send Request_Save of oFunctions_DD
    End_Procedure
    
    Set Main_DD to oFunctions_DD
    Set Server to oFunctions_DD
                                    
    Object oMain_TabDialog is a dbTabDialog
        Set Size to 241 653
        Set piMinSize to 140 510
        Set Location to 0 -2
        Set Rotate_Mode to RM_Rotate
        Set peAnchors to anAll
        Set Auto_Clear_DEO_State to False  
        Set Auto_Top_Panel_State to False
        Set phoImageList to oImageList
        Set Default_Tab to -1

        Object oSelectFunctions_tp is a dbTabPage
            Set Label to "Select Functions"

            Object oSelectFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 219 655
                Set piMinSize to 126 490
                Set Location to 4 0
                Set Label to "Function List"             
                Set psImage to "FunctionLookup.ico"
                Set psNote to "Select functions. Right click grid for options."
                Set psToolTip to "Standard refactoring functions are functions that are called once for each source line."
                Set Border_Style to Border_None
                Set peAnchors to anAll
                Set piImageIndex to Ico_Functions

                Object oFunctionSelection_grd is a cRDCDbCJGrid
                    Set Size to 204 636
                    Set Location to 27 9
                    Set Ordering to 5
                    Set piLayoutBuild to 4
                    Set pbHeaderReorders to True
                    Set pbHeaderTogglesDirection to True
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to False
                    Set pbAllowInsertRow to False
                    Set pbAutoAppend to False
                    Set pbDbShowInvertSelectionsMenuItem to True     
                    // Need this to load all records in the grid,
                    // else the select buttons won't work.
                    Set pbStaticData to True
                        
                    Object oFunctions_ID is a cRDCDbCJGridColumn
                        Entry_Item Functions.ID
                        Set piWidth to 35
                        Set psCaption to "ID"
                        Set pbEditable to False
                        Set peTextAlignment to xtpAlignmentCenter
                    End_Object

                    Object oFunctions_Function_Name is a cDbCJGridColumnSuggestion
                        Entry_Item Functions.Function_Name
                        Set piWidth to 291
                        Set psCaption to "Function Name (Suggestion list)"    
                        Set pbFullText to True    
                        Set psToolTip to "This is a full text suggestion list. You can start typing to search for any keyword and a suggestion list will appear for you to select from."
                        Set Status_Help to (psToolTip(Self))
                        // NOTE: The phoData_Col property must be set for the checkbox selections to work!
                        Set phoData_Col to Self   
                        Set pbAllowRemove to False
                        
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Set Status_Help to sText
                            Function_Return sText
                        End_Function
            
                    End_Object

                    Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Description
                        Set piWidth to 397
                        Set psCaption to "Description"
                        Set pbEditable to False
                        Set psToolTip to "A short description of whate the refactoring function does. Hover the mouse over a function row to see more help on what it does."
                        Set Status_Help to (psToolTip(Self))
            
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Set Status_Help to sText
                            Function_Return sText
                        End_Function
            
                    End_Object

                    Object oFunctions_Type is a cRDCDbCJGridColumn
                        Entry_Item Functions.Type
                        Set piWidth to 154
                        Set psCaption to "Type"
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set pbComboButton to True
                        // pbEditable *must* be set after the pbComboButton setting.
                        Set pbEditable to False
                        Set psToolTip to "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing."
                        Set Status_Help to (psToolTip(Self))
            
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Move "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing." to sText
                            Set Status_Help to sText
                            Function_Return sText
                        End_Function
            
                    End_Object                    

                    Object oFunctions_Parameter is a cRDCDbCJGridColumn
                        Entry_Item Functions.Parameter
                        Set piWidth to 74
                        Set psCaption to "Parameter"
                        Set pbComboButton to True  
                        Set pbComboEntryState to False
                        Set psToolTip to "For some functions an extra parameter can be passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."
                        Set Status_Help to (psToolTip(Self))
            
                        Procedure OnEntry
                            Send ComboFillList
                        End_Procedure
                        
                        Procedure ComboFillList
                            String sParameterList
                            String[] asParameters
                            Integer iSize iCount
                            
                            Send ComboDeleteData
                            Get Field_Current_Value of (Server(Self)) Field Functions.ParameterValidation to sParameterList
                            If (sParameterList <> "") Begin
                                Get StrSplitToArray  sParameterList "," to asParameters
                                Move (SizeOfArray(asParameters)) to iSize
                                Decrement iSize
                                For iCount from 0 to iSize
                                    Send ComboAddItem asParameters[iCount] iCount
                                Loop
                            End
                        End_Procedure
            
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_ParameterHelp iRow to sText
                            Move (Replaces("\n", sText, CS_CRLF)) to sText
                            Set Status_Help to sText
                            Function_Return sText
                        End_Function
            
                    End_Object

                    Object oFunctions_ParameterHelp is a cRDCDbCJGridColumn
                        Entry_Item Functions.ParameterHelp
                        Set piWidth to 200
                        Set psCaption to "Parameter Help"
                        Set pbVisible to False
                        Set Status_Help to (psToolTip(Self))
                    End_Object

                    Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Help
                        Set piWidth to 221
                        Set psCaption to "Help"
                        Set pbVisible to False
                        Set Status_Help to (psToolTip(Self))
                    End_Object
            
                    Object oFunctions_Selected is a cRDCDbCJGridColumn
                        Entry_Item Functions.Selected
                        Set piWidth to 45
                        Set psCaption to "Select"
                        Set pbCheckbox to True
                        Set phoCheckbox_Col to Self
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set peFooterAlignment to  xtpAlignmentCenter
                        Set Status_Help to (psToolTip(Self))
            
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Set Status_Help to sText
                            Function_Return sText
                        End_Function
            
                    End_Object

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
                        Get Field_Changed_State of (Main_DD(Self)) Field Functions.Function_Name to bChange
                        If (bChange = True) Begin
                            Send ResetSelectedRow of hoDataSource
                            Move False to bSave
                        End
                        Function_Return bSave
                    End_Procedure
                    
                    On_Key Key_Ctrl+Key_F5 Send ActivateProcess
                End_Object

                Object oSelectAll_btn is a Button
                    Set Size to 14 62
                    Set Location to 9 261
                    Set Label to "Select All"
                    Set psImage to "SelectAll.ico"   
                    Set psToolTip to "(Ctrl+A)"
                    Set peAnchors to anTopRight
                    Procedure OnClick
                        Send SelectAll of oFunctionSelection_grd
                    End_Procedure
                End_Object

                Object oSelectNone_btn is a Button
                    Set Size to 14 62
                    Set Location to 9 327
                    Set Label to "Select None"
                    Set psImage to "SelectNone.ico"
                    Set psToolTip to "(Ctrl+N)"
                    Set peAnchors to anTopRight
                    Procedure OnClick
                        Send SelectNone of oFunctionSelection_grd
                    End_Procedure
                End_Object

                Object oSelectInvert_btn is a Button
                    Set Size to 14 74
                    Set Location to 9 393
                    Set Label to "Invert Selections"
                    Set psImage to "SelectInvert.ico"
                    Set psToolTip to "(Ctrl+I)"
                    Set peAnchors to anTopRight
                    Procedure OnClick
                        Send SelectInvert of oFunctionSelection_grd
                    End_Procedure
                End_Object

                Object oConstrainByType_cf is a ComboForm
                    Set Size to 14 99
                    Set Location to 9 546
                    Set peAnchors to anTopRight
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set Label to "Constrain by Type:"
                    Set Entry_State to False
                    Set Combo_Sort_State to False
                  
                    Procedure Combo_Fill_List
                        Send Combo_Add_Item CS_All_Functions
                        Send Combo_Add_Item CS_Standard_Function
                        Send Combo_Add_Item CS_Remove_Function
                        Send Combo_Add_Item CS_Editor_Function
                        Send Combo_Add_Item CS_Report_Function   
                        Send Combo_Add_Item CS_Report_FunctionAll
                        Send Combo_Add_Item CS_Other_Function   
                        Send Combo_Add_Item CS_Other_FunctionAll
                    End_Procedure
                  
                    Procedure OnChange
                        String sValue                      
                        Integer iType
                        
                        Get Value to sValue
                        Case Begin
                            Case (sValue = CS_All_Functions)
                                Move eAll_Functions to iType
                                Case Break
                            Case (sValue = CS_Standard_Function)
                                Move eStandard_Function to iType
                                Case Break
                            Case (sValue = CS_Remove_Function)
                                Move eRemove_Function to iType
                                Case Break                            
                            Case (sValue = CS_Editor_Function)
                                Move eEditor_Function to iType
                                Case Break
                            Case (sValue = CS_Report_Function)
                                Move eReport_Function to iType
                                Case Break
                            Case (sValue = CS_Report_FunctionAll)
                                Move eReport_FunctionAll to iType
                                Case Break
                            Case (sValue = CS_Other_Function)
                                Move eOther_Function to iType
                                Case Break
                            Case (sValue = CS_Other_FunctionAll)
                                Move eOther_FunctionAll to iType
                                Case Break
                            Case Else
                        Case End
                            
                        Set piFunctionType of (Main_DD(Self)) to iType
                        Send Rebuild_Constraints of (Main_DD(Self)) 
                        Send RefreshDataFromDD of oFunctionSelection_grd 0
                    End_Procedure
                  
                End_Object
    
                Procedure OnFileDropped String sFilename Boolean bLast
                    Delegate Send OnFileDropped sFilename bLast
                End_Procedure

            End_Object
                    
            Procedure OnFileDropped String sFilename Boolean bLast
                Delegate Send OnFileDropped sFilename bLast
            End_Procedure

        End_Object
        
        Object oDbFolders_tp is a dbTabPage
            Set Label to "Select Folders"
            Set piImageIndex to Ico_Folders
            Set pbAcceptDropFiles to True
    
            Object oDbSourceFolders_grp is a cRDCDbHeaderGroup
                Set Location to 4 0
                Set Size to 233 634
                Set Label to "Folders List"
                Set psImage to "Folder.ico"
                Set psNote to "Select Folders. Right click grid for options"
                Set psToolTip to "You can add a folder with drag and drop from Windows Explorer, or by using the right-click mouse menu."
                Set peAnchors to anAll
                Set Border_Style to Border_None
                Set piMinSize to 126 490

                Object oDbFolders_grd is a cRDCDbCJGrid
                    Set Server to oFolderSelDtl_DD
                    Set Size to 204 621
                    Set Location to 27 9
                    Set Ordering to 2
                    Set piLayoutBuild to 4
                    Set pbHeaderReorders to True
                    Set pbHeaderTogglesDirection to True
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to True
                    Set pbAllowInsertRow to True
                    Set pbAutoAppend to False
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
                    
                    On_Key Key_F2           Send Request_Save 
                    On_Key Key_Ctrl+Key_S   Send Request_Save
                    On_Key Key_Delete       Send Request_Delete
                    On_Key Key_Shift+Key_F2 Send Request_Delete 
                    On_Key Key_Ctrl+Key_F5  Send ActivateProcess
                End_Object

                Object oSelectAll_btn is a Button
                    Set Size to 14 62
                    Set Location to 9 255
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
                    Set Location to 9 321
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
                    Set Location to 9 387
                    Set Label to "Invert Selections"
                    Set psImage to "SelectInvert.ico"
                    Set psToolTip to "(Ctrl+I)"
                    Set peAnchors to anTopRight
                    Procedure OnClick
                        Send SelectInvert of oDbFolders_grd
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

        End_Object
    
        Procedure UpdateEnabledState
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Set Enabled_State to (sSWSFile <> "")  
        End_Procedure   
        
        Procedure OnFileDropped String sFilename Boolean bLast
            Delegate Send OnFileDropped sFilename bLast
        End_Procedure

    End_Object
                
    Procedure UpdateEnabledState
        String sSWSFile
        Get psSWSFile of ghoApplication to sSWSFile
        Set Enabled_State to (sSWSFile <> "")
        Send Activate of oFunctionSelection_grd
    End_Procedure

    Object oFileFilters_grp is a cRDCDbHeaderGroup
        Set Size to 66 260
        Set Location to 246 6
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
//            Entry_Item SysFile.FileExtensionFilter
//            Set Server to oSysFile_DD
            Set Size to 12 250
            Set Location to 30 4
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
                If (bChanged = True) Begin
                    Set Field_Changed_Value of (oSysfile_DD(phoRefactorView(ghoApplication))) Field SysFile.FileExtensionFilter to sVal
                    Set Field_Changed_State of (oSysfile_DD(phoRefactorView(ghoApplication))) Field SysFile.FileExtensionFilter to True
                    Set Changed_State of (oSysfile_DD(phoRefactorView(ghoApplication)))  to True
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

    Object oRunNow_grp is a cRDCDbHeaderGroup
        Set Size to 66 377
        Set Location to 246 270
        Set piMinSize to 48 367
        Set psLabel to "Refactor Code"
        Set psNote to "Apply functions for selected folders and filter" 
        Set psToolTip to "Calls the selected functions for the matching selected folders and file extensions."
        Set psImage to "DFRefactor.ico"
        Set peAnchors to anBottomLeftRight
        Set pbUseLargeFontHeight to True

        Object oNoOfSelectedFunctions_fm is a cRDCDbForm
            Set Size to 13 32
            Set Location to 32 179
            Set Label_Justification_Mode to JMode_Right
            Set Label to "Selected Functions:"
            Set psToolTip to "Total number of functions selected."
            Set Label_FontWeight to fw_Bold
            Set FontWeight to fw_Bold              
            Set Label_Col_Offset to 0
            Set Enabled_State to False
            Set Form_Justification_Mode to Form_DisplayRight
            Set Form_Border to Border_None
            Set peAnchors to anBottomLeft    
        End_Object

        Object oNoOfSelectedFolders_fm is a cRDCDbForm
            Set Size to 13 32
            Set Location to 45 179
            Set Label_Justification_Mode to JMode_Right
            Set Label to "Selected Folders:"
            Set psToolTip to "Total number of folders selected."
            Set Enabled_State to False
            Set Label_FontWeight to fw_Bold
            Set Label_Col_Offset to 0
            Set FontWeight to fw_Bold  
            Set Enabled_State to False
            Set Form_Justification_Mode to Form_DisplayRight
            Set Form_Border to Border_None
            Set peAnchors to anBottomLeft

            // This will show/hide the control:
            Function IsEnabled Returns Boolean
                Boolean bEnabled bWorkspaceMode
                String sSWSFile
                Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
                Get psSWSFile       of ghoApplication to sSWSFile
                Move (bWorkspaceMode = True and sSWSFile <> "") to bEnabled
                Set Visible_State to bEnabled
                Function_Return bEnabled
            End_Function

        End_Object

        Object oCountSourceLines_cb is a dbCheckBox
            Entry_Item SysFile.bCountSourceLines
            Set Server to oSysFile_DD
            Set Location to 17 216
            Set Size to 8 109
            Set Label to "Count Source Lines (only)"   
//            Set FontWeight to fw_Bold
            Set peAnchors to anBottomLeft 
            Set psToolTip to (String("This function will tell you how large your workspace is by counting the number of 'real' source lines for all selected folders and file extensions.") + String(CS_CR) + String("Note: It will skip blank or comments lines, and it will not count files generated by the Studio from COM components.") + String(CS_CR) + String(CS_CR) + String("This function needs be run in solitude, all other functions will be ignored."))

            Procedure OnChange
                Set Enabled_State of oReadOnly_cb to (Checked_State(Self) = False)
            End_Procedure

        End_Object

        Object oReadOnly_cb is a dbCheckbox
            Entry_Item SysFile.bReadOnly
            Set Server to oSysFile_DD
            Set Location to 17 318
            Set Size to 8 109
            Set Label to "Read Only"
            Set peAnchors to anBottomLeft
            Set psToolTip to "If checked, no changes to the source code will be made - only shows statistics."

            Procedure OnChange
                Set Enabled_State of oCountSourceLines_cb to (Checked_State(Self) = False)
            End_Procedure

        End_Object

        Object oSelectedIdleHandler is a cIdleHandler
            Set pbEnabled to True
            Procedure OnIdle
                Integer iSelectedFuncs iTotalFuncs iSelectedFolders iTotalFolders
                Handle hoDD
                
                Send Request_Save of oSysFile_DD
                Move SysFile.SelectedFunctionTotal to iSelectedFuncs
                Get TotalNoOfFunctions of (Main_DD(Self)) to iTotalFuncs
                Set Value of oNoOfSelectedFunctions_fm to (String(iSelectedFuncs) * "(" + String(iTotalFuncs) + ")")
                
                Move (oFolderSelHea_DD(Self)) to hoDD
                Get TotalSelectedFolders of hoDD to iSelectedFolders
                Get TotalFolders         of hoDD to iTotalFolders
                Set Value of oNoOfSelectedFolders_fm to (String(iSelectedFolders) * "(" + String(iTotalFolders) + ")")
            End_Procedure
                
        End_Object

        Object oExecute_btn is a cRDCButton
            Set Size to 30 98
            Set Location to 29 215
            Set Label to "Start &Refactoring!" //"&Refactor Code Now!"
            Set psToolTip to "Start processing the selected refactoring functions. If 'Workspace' mode has been selected from the toolbar all source files that matches the 'File Extensions Filter' will be processed. Else the operations will take place on a single file only. (Alt+R or Ctrl+R)"
            Set pbAutoEnable to True
            Set Default_State to True
            Set Form_FontWeight to FW_BOLD
            Set psImage to "Start.ico"
            Set piImageMarginLeft to 7
            Set piImageSize to 32
            Set peAnchors to anBottomLeft

            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                // Note: We use Form_FontWeight instead of FontWeight to _not_ make the object larger
                // because of the bold font.
                Set Form_FontWeight to FW_BOLD
            End_Procedure

            Procedure OnClick  
                Send RefactoreCode
            End_Procedure

            Function IsEnabled Returns Boolean
                Boolean bEnabled bWorkspaceMode
                String sFileName sSWSFile sHomePath
                Integer iSelectedFunctions iFolders 
                Boolean bExists bUseDDO  
                tFolderData[] asSavedFolders

                Get pbWorkspaceMode         of ghoApplication to bWorkspaceMode
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

                If (bEnabled = True and bWorkspaceMode = True) Begin
                    Get TotalSelectedFolders of (phoFolderSelHeaDD(ghoApplication)) to iFolders
                    Move (iFolders <> 0) to bEnabled
                End          
                If (bEnabled = False) Begin
                    Get Field_Current_Value of oSysFile_DD Field SysFile.bCountSourceLines to bEnabled
                End

                Function_Return bEnabled
            End_Function

        End_Object

        Procedure UpdateEnabledState
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Set Enabled_State to (sSWSFile <> "")
        End_Procedure

        Object oStartCompareProgram_btn is a cRDCButton
            Set Size to 30 54
            Set Location to 29 317
            Set Label to "Co&mpare Code"
            Set peAnchors to anBottomLeft
            Set psImage to "Compare.ico"
            Set piImageSize to 24
            Set psToolTip to "Starts the selected compare program and passes the two source files (Ctrl+M). It automatically saves the source files first."
            Set MultiLineState to True
        
            Procedure OnClick
                String sCompareApp
                Boolean bWorkspaceMode
                Get psFileCompareApp of ghoApplication to sCompareApp
                Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
                If (bWorkspaceMode = True) Begin
                    Send ComparePaths of ghoApplication sCompareApp
                End
                Else Begin
                    Send CompareFiles of ghoApplication sCompareApp
                End
            End_Procedure
    
            Function IsEnabled Returns Boolean
                Boolean bIsEnabled
                Get IsEnabled of (oCompare_MenuItem(ghoCommandBars)) to bIsEnabled
                Function_Return bIsEnabled
            End_Function

        End_Object

    End_Object

    Procedure MAIN_FUNCTION_CALL // ***
    End_Procedure
    //
    Procedure RefactoreCode
        Handle hoEditor 
        tRefactorFiles RefactorFiles 
        String sFileFilter
        
        Move False to Err
        Send Request_Save_No_Clear of oSysFile_DD
        Get CollectFileData of ghoApplication (oFolderSelDtl_DD(Self)) to RefactorFiles
        Get phoEditor of ghoApplication to hoEditor
        If (Err = True) Begin
            Procedure_Return
        End

        // Start the Engine!
        Send StartEngine of ghoRefactorEngine RefactorFiles hoEditor
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

    Procedure Close_Panel
    End_Procedure

    Procedure OnSetFocus
        Set piActiveView of ghoApplication to CI_CleanupSource Self
    End_Procedure

    Procedure OnWorkspaceLoaded
        Integer iSelectedFolders  
        Handle hoFolderSelHeaDD
        Boolean bExists bOK
        String sHomePath sUserName sWorkspaceHome
        tFolderData[] asSavedFolders
        
        Get psWorkspaceHomePath  of ghoApplication to sWorkspaceHome
        If (sWorkspaceHome = "") Begin
            Procedure_Return
        End

        Get phoFolderSelHeaDD of ghoApplication to hoFolderSelHeaDD        
        Get SaveNewHeaderAndChildRecords of hoFolderSelHeaDD sWorkspaceHome to bOK 
        Send Request_Assign of hoFolderSelHeaDD 
        Move FolderSelHea.ID to FolderSelDtl.FolderSelHeaID
        Move FolderSelHea.WorkspaceHomeFolder to FolderSelDtl.FolderName
        Send Find of oFolderSelDtl_DD GE Index.1
        Send OnChange of oCountSourceLines_cb
        
        // Weird voodoo.
        // After a workspace has been opened, the enabled_state should also
        // be set to true, but it isn't until the mouse is hovered(!) over the grid.
        // This extra enabled_state fixes it.
        Set Enabled_State of oFunctionSelection_grd to True
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
            If (Focus(Desktop) <> oDbFolders_grd) Begin
                Send Request_Next_Tab of oMain_TabDialog 1
            End
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
                Send AddWorkSpaceFileToRegistry of ghoApplication sFileFolderName
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
