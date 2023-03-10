Use cRefactorDbView.pkg
Use cCommandLinkButton.pkg
Use Cursor.pkg
Use dfLine.pkg
Use cDbSplitterContainer.pkg
Use cCJCommandBarSystem.pkg

Use cRDCDbCJGrid.pkg  
Use cRDCDbCJGridColumn.pkg
Use cRDCCJSelectionGrid.pkg
Use cRDCButtonDPI.pkg
Use cRDCDbComboForm.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbSpinForm.pkg
Use cRDCCommandLinkButton.pkg
Use cRefactorCheckbox.pkg
Use cRDCSlideButton.pkg
Use cRDCCheckbox.pkg
Use cRefactorTextbox.pkg

Use cFunctionsDataDictionary.dd
Use cSysFileDataDictionary.dd

Activate_View Activate_oRefactorView For oRefactorView
Object oRefactorView is a cRefactorDbView
    Set Size to 299 521
    Set Label to "Refactoring Selections"
    Set Icon to "DFRefactor.ico"
    Set pbAcceptDropFiles to True
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    Set phoRefactorView of ghoApplication to Self

    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    Object oFunctionsStandard_DD is a cFunctionsDataDictionary  
        Procedure OnConstrain
            Constrain Functions.Type eq eAll_Functions
        End_Procedure
    End_Object

    Object oFunctionsEditor_DD is a cFunctionsDataDictionary
        Procedure OnConstrain
            Constrain Functions.Type eq eEditor_Function
        End_Procedure
    End_Object

    Object oFunctionsReport_DD is a cFunctionsDataDictionary
        Procedure OnConstrain
            Constrain Functions.Type eq eReport_Function
        End_Procedure
    End_Object

    Object oFunctionsNull_DD is a cFunctionsDataDictionary
        Procedure OnConstrain
            Constrain Functions.Type eq CI_Null_Line_Function
        End_Procedure
    End_Object

    Set Main_DD to oFunctionsStandard_DD
    Set Server to oFunctionsStandard_DD

    Object oSplitterContainer is a cDbSplitterContainer
        Set pbSplitVertical to False
        Set piSplitterLocation to 151
        Set pbAcceptDropFiles to True
        Set peFixedPanel to fpFixLastPanel

        Procedure OnFileDropped String sFilename Boolean bLast
            Delegate Send OnFileDropped sFilename bLast
        End_Procedure

        Object oSplitterContainerChild1 is a cDbSplitterContainerChild
            Set pbAcceptDropFiles to True

            Procedure OnFileDropped String sFilename Boolean bLast
                Delegate Send OnFileDropped sFilename bLast
            End_Procedure

            Object oStandardFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 147 248
                Set piMinSize to 147 248
                Set Location to 0 0
                Set Label to "Standard Functions"             
                Set psImage to "FunctionLibrary.ico"
                Set psNote to "Select refactoring functions to freshen up your source code"
                Set psToolTip to "Standard refactoring functions."
                Set Border_Style to Border_None
                Set peAnchors to anAll

                Object oFunctionStandardSelection_grd is a cRDCDbCJGrid
                    Set Server to oFunctionsStandard_DD
                    Set Size to 128 234
                    Set Location to 27 6
                    Set Ordering to 2
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to False
                    Set pbAllowInsertRow to False
                    Set pbAutoAppend to False
                    Set pbEditOnTyping to False
                    Set piLayoutBuild to 4
            
                    Procedure Activating
                        Forward Send Activating  
                        Send DoChangeFontSize
                    End_Procedure

                    Object oFunctions_Function_Name is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Name
                        Set piWidth to 171
                        Set psCaption to "Function Name"
                        Set pbEditable to False   
                        
                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Description
                        Set piWidth to 172
                        Set psCaption to "Function Description"
                        Set pbEditable to False

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object

                    Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Help
                        Set piWidth to 221
                        Set psCaption to "Function Help"
                        Set pbVisible to False
                    End_Object

                    Object oFunctions_Selected is a cRDCDbCJGridColumn
                        Entry_Item Functions.Selected
                        Set piWidth to 47
                        Set psCaption to "Select"
                        Set pbCheckbox to True
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set phoCheckbox_Col to Self
                        Set peFooterAlignment to  xtpAlignmentCenter

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Procedure Refresh Integer eMode
                        Integer iChecked
                        Forward Send Refresh eMode
                        Set Value of oNoOfSelectedFunctions2_fm to SysFile.TotFunctionsSelected
                    End_Procedure
                    
                End_Object

//                Object oSelectAll_btn is a Button
//                    Set Size to 14 56
//                    Set Location to 8 126
//                    Set Label to 'Select All'
//                    Set peAnchors to anTopRight 
//                    Set psImage to "SelectAll.ico"
//                
//                    Procedure OnClick
//                        Handle hoDD
//                        Get Main_DD to hoDD
//                        Send SelectAll of hoDD
//                        Send Request_Assign of hoDD
//                        Send Refind_Records of hoDD
//                    End_Procedure
//                
//                End_Object
//            
//                Object oDeselectAll_btn is a Button
//                    Set Size to 14 56
//                    Set Location to 8 185
//                    Set Label to 'Deselect All'
//                    Set peAnchors to anTopRight
//                    Set psImage to "SelectNone.ico"
//                
//                    Procedure OnClick
//                        Handle hoDD
//                        Get Main_DD to hoDD
//                        Send DeSelectAll of hoDD
//                        Send Request_Assign of hoDD
//                        Send Refind_Records of hoDD
//                    End_Procedure
//                
//                End_Object

            End_Object
                    
            Object oEditorFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 80 262
                Set Location to 1 254
                Set Label to "Editor Functions"
                Set psImage to "Editor.ico"
                Set psToolTip to "These refactoring functions are all using the build in Scintilla editor to do their work. For various reasons this also makes these functions much slower than the other refactoring functions."
                Set Border_Style to Border_None
                Set psNote to "Uses the Refactoring Editor (separate tabview)"
                Set peAnchors to anTopRight

                Object oFunctionEditorSelection_grd is a cRDCDbCJGrid
                    Set Server to oFunctionsEditor_DD
                    Set Size to 52 250
                    Set Location to 27 7
                    Set Ordering to 2
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to False
                    Set pbAllowInsertRow to False
                    Set pbAutoAppend to False
                    Set pbEditOnTyping to False
                    Set pbShowFooter to True
                    Set piLayoutBuild to 3
            
                    Object oFunctions_Function_Name is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Name
                        Set piWidth to 362
                        Set psCaption to "Function Name"

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Description
                        Set piWidth to 172
                        Set psCaption to "Function Description"
                        Set pbEditable to False

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object

                    Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Help
                        Set piWidth to 221
                        Set psCaption to "Function Help"
                        Set pbVisible to False
                    End_Object
            
                    Object oFunctions_Selected is a cRDCDbCJGridColumn
                        Entry_Item Functions.Selected
                        Set piWidth to 55
                        Set psCaption to "Select"
                        Set pbCheckbox to True
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set phoCheckbox_Col to Self

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Procedure Refresh Integer eMode
                        Integer iChecked
                        Forward Send Refresh eMode
                        Set Value of oNoOfSelectedFunctions2_fm to SysFile.TotFunctionsSelected
                    End_Procedure
                    
                End_Object

            End_Object

            Object oReportFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 86 262
                Set piMinSize to 55 219
                Set Location to 84 254
                Set Label to "Report Functions"
                Set psImage to "Report.ico"
                Set psNote to "Makes no source code changes"
                Set psToolTip to "These refactoring functions only reports info about the selected source code without making any changes."
                Set Border_Style to Border_None
                Set peAnchors to anTopRight

                Object oFunctionReportSelection_grd is a cRDCDbCJGrid
                    Set Server to oFunctionsReport_DD
                    Set Size to 52 250
                    Set Location to 27 7
                    Set Ordering to 2
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to False
                    Set pbAllowInsertRow to False
                    Set pbAutoAppend to False
                    Set pbEditOnTyping to False
                    Set pbShowFooter to True
                    Set piLayoutBuild to 3  
            
                    Object oFunctions_Function_Name is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Name
                        Set piWidth to 362
                        Set psCaption to "Function Name"

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Description
                        Set piWidth to 172
                        Set psCaption to "Function Description"
                        Set pbEditable to False

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object

                    Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Help
                        Set piWidth to 221
                        Set psCaption to "Function Help"
                        Set pbVisible to False
                    End_Object
            
                    Object oFunctions_Selected is a cRDCDbCJGridColumn
                        Entry_Item Functions.Selected
                        Set piWidth to 55
                        Set psCaption to "Select"
                        Set pbCheckbox to True
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set phoCheckbox_Col to Self

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Procedure Refresh Integer eMode
                        Integer iChecked
                        Forward Send Refresh eMode
                        Set Value of oNoOfSelectedFunctions2_fm to SysFile.TotFunctionsSelected
                    End_Procedure
                    
                End_Object

            End_Object

            Object oNULFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 55 262
                Set piMinSize to 55 219
                Set Location to 168 254
                Set Label to "Remove Lines Functions"
                Set psImage to "Remove.ico"
                Set psNote to "Will eventually delete a line"
                Set psToolTip to "These refactoring functions decides if a line should be removed or not."
                Set Border_Style to Border_None
                Set peAnchors to anTopBottomRight

                Object oFunctionNULSelection_grd is a cRDCDbCJGrid
                    Set Server to oFunctionsNull_DD
                    Set Size to 26 250
                    Set Location to 27 7
                    Set Ordering to 2
                    Set pbAllowAppendRow to False
                    Set pbAllowDeleteRow to False
                    Set pbAllowInsertRow to False
                    Set pbAutoAppend to False
                    Set pbEditOnTyping to False
                    Set pbShowFooter to True
                    Set piLayoutBuild to 3
            
                    Object oFunctions_Function_Name is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Name
                        Set piWidth to 362
                        Set psCaption to "Function Name"

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Description
                        Set piWidth to 172
                        Set psCaption to "Function Description"
                        Set pbEditable to False

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object

                    Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                        Entry_Item Functions.Function_Help
                        Set piWidth to 221
                        Set psCaption to "Function Help"
                        Set pbVisible to False
                    End_Object
            
                    Object oFunctions_Selected is a cRDCDbCJGridColumn
                        Entry_Item Functions.Selected
                        Set piWidth to 55
                        Set psCaption to "Select"
                        Set pbCheckbox to True
                        Set peHeaderAlignment to xtpAlignmentCenter  
                        Set phoCheckbox_Col to Self

                        Function OnGetTooltip Integer iRow String sValue String sText Returns String
                            Get RowValue of oFunctions_Function_Help iRow to sText
                            Function_Return sText
                        End_Function

                    End_Object
            
                    Procedure Refresh Integer eMode
                        Integer iChecked
                        Forward Send Refresh eMode
                        Set Value of oNoOfSelectedFunctions2_fm to SysFile.TotFunctionsSelected
                    End_Procedure
                    
                End_Object

            End_Object

        End_Object

        Object oSplitterContainerChild2 is a cDbSplitterContainerChild
            Set pbAcceptDropFiles to True

            Procedure OnFileDropped String sFilename Boolean bLast
                Delegate Send OnFileDropped sFilename bLast
            End_Procedure

            Object oSplitterContainer1 is a cDbSplitterContainer
                Set piSplitterLocation to 251
                Set peFixedPanel to fpFixLastPanel

                Procedure OnFileDropped String sFilename Boolean bLast
                    Delegate Send OnFileDropped sFilename bLast
                End_Procedure

                Object oSplitterContainerChild3 is a cDbSplitterContainerChild

                    Procedure OnFileDropped String sFilename Boolean bLast
                        Delegate Send OnFileDropped sFilename bLast
                    End_Procedure

                    Object oSourceFolders_grp is a cRDCDbHeaderGroup
                        Set Size to 140 244
                        Set Label to "Source Code Folders"
                        Set psImage to "Folder.ico"
                        Set psNote to "Right click grid for options"
                        Set psToolTip to "You can add a folder with drag and drop from Windows Explorer, or by using the right-click mouse menu."
                        Set peAnchors to anAll
                        Set Border_Style to Border_None

                        Object oFolders_grd is a cRDCCJSelectionGrid
                            Set Size to 83 226
                            Set Location to 27 13
                            Set psNoItemsText to "No Workspace selected yet..."
                            Set pbShowAddFolderMenuItem to True
                            Set pbShowRemoveFolderMenuItem to True

                            Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
                                Set piWidth to 14
                            End_Object

                            Object oFoldername_Col is a cCJGridColumn
                                // NOTE: This must be set here!
                                Set phoData_Col to Self
                                Set piWidth to 363
                                Set psCaption to "Folder Name"
                                Set psToolTip to "The process will run on all files that match the 'File Extensions Filter' comboform for the selected folders and all subfolders"
                                Set pbEditable to False
                                Set psFooterText to "No of Folders Selected:"

                                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                                    Move "The process will run on all files that match the 'File Extensions Filter' comboform for the selected folders and all subfolders" to sText
                                    Function_Return sText
                                End_Function

                            End_Object

                            // This column is created automatically by the cRDCCJGrid class.
                            // Object oCheckbox_Col is a cCJGridColumn
                            // End_Object

                            Procedure LoadData
                                String sHomePath sFolderName sDefaultFolders
                                String[] asNoFolderList asStartFolder asFolderArray asDefaultFolders
                                Handle hoDataSource
                                tDataSourceRow[] TheData TheDataEmpty
                                Integer iSize iRow iCount iFolderCol iCheckBoxCol iDefaultFolders iFolder
                                Boolean bChecked

                                If (not(IsComObjectCreated(Self))) Begin
                                    Procedure_Return
                                End

                                Get psWorkspaceHomePath of ghoApplication to sHomePath
                                If (sHomePath = "") Begin
                                    Procedure_Return
                                End

                                Send Cursor_Wait of Cursor_Control
                                Get vFolderFormat sHomePath to sHomePath
                                Move sHomePath to asStartFolder[0]
                                Get AllSourceFolders of ghoApplication asStartFolder to asFolderArray
                                Move (SizeOfArray(asFolderArray)) to iSize
                                If (iSize = 0) Begin
                                    Send Cursor_Ready of Cursor_Control
                                    Procedure_Return
                                End
                                Decrement iSize

                                Move 0 to iCount
                                Get phoDataSource to hoDataSource
                                Get DataSource of hoDataSource to TheData
                                Move TheDataEmpty to TheData
                                Get piColumnId of (phoData_Col(Self))     to iFolderCol
                                Get piColumnId of (phoCheckbox_Col(Self)) to iCheckBoxCol
                                Get NoFolderListAsArray of ghoApplication False to asNoFolderList

                                Move CS_DefaultSourceFolders to sDefaultFolders
                                Move (Lowercase(sDefaultFolders)) to sDefaultFolders
                                Move (StrSplitToArray(sDefaultFolders, "|")) to asDefaultFolders
                                Move (SizeOfArray(asDefaultFolders)) to iDefaultFolders
                                Decrement iDefaultFolders

                                Move 0 to iRow
                                For iCount from 0 to iSize
                                    Move asFolderArray[iCount] to sFolderName
                                    Move sFolderName to TheData[iRow].sValue[iFolderCol]
                                    Get IsFolderInDefaultsFolderList of ghoApplication sFolderName to bChecked
                                    Move bChecked to TheData[iRow].sValue[iCheckBoxCol]
                                    Increment iRow
                                Loop

                                If (iRow <> 0) Begin
                                    Send ReInitializeData TheData False
                                    Send MoveToFirstRow
                                End
                                Else Begin
                                    Send InitializeData TheDataEmpty
                                End
                                Get CheckedItems to iCount
                                Set psFooterText of oFoldername_Col  to ("Selected Items:" * String(iCount) * "of" * String(iSize + 1))
                                Send Cursor_Ready of Cursor_Control
                            End_Procedure

                            Procedure UpdateEnabledState
                                Boolean bWorkspaceMode
                                Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
                                Set Enabled_State to bWorkspaceMode
                            End_Procedure

                            On_Key kClear Send ActivateProcess
                        End_Object

                        Object oFileNameFilters_cf is a cRDCDbComboForm 
                            Entry_Item SysFile.FileExtensionFilter
                            Set Server to oSysFile_DD
                            Set Size to 12 226
                            Set Location to 124 13
                            Set Label to "File Extensions Filter"
//                            Set psToolTip to "When the 'Workspace' toolbar button is selected and the 'Start Process!' button is pushed, all the file extensions listed here will be processed for the currently selected Workspace (but not any libraries it may contain/use)."
                            Set psToolTip to "Each extension must start with a wildcard character and a dot (*.) and file extensions must be separated with a semicolon (;)"
                            Set Status_Help to (psToolTip(Self))
                            Set Label_Col_Offset to 0
                            Set Label_Justification_Mode to JMode_Top
                            Set peAnchors to anBottomLeftRight
                            Set Label_Row_Offset to 1
                            Set Combo_Sort_State to False
                            Set pbAutoEnable to True
                            Set peAnchors to anBottomLeftRight

                            Property Integer piMaxUserFilters 8

                            Procedure Combo_Fill_List
                                String sVDFExtensions sVDFVersion
                                Integer iMajorVersion iMinorVersion iCount iSize
                                String[] asUserExtensions

                                Forward Send Combo_Fill_List
                                Move FMAC_VERSION  to iMajorVersion
                                Move FMAC_REVISION to iMinorVersion
                                Move (String(iMajorVersion) + "." + String(iMinorVersion)) to sVDFVersion
                                Get StudioFileExtensions of ghoApplication sVDFVersion to sVDFExtensions

                                Send Combo_Add_Item CS_StdExtensions
                                Send Combo_Add_Item CS_VDFAndTemplExt
                                Send Combo_Add_Item CS_PkgIncExt
                                Send Combo_Add_Item CS_SrcPkgExt

                                If (sVDFExtensions <> String(cx_RegKeyVDFKeyDoesNotExist)) Begin
                                    Send Combo_Add_Item sVDFExtensions
                                End

                                Get UserSavedExtensions to asUserExtensions
                                Move (SizeOfArray(asUserExtensions)) to iSize
                                Decrement iSize
                                For iCount from 0 to iSize
                                    Send Combo_Add_Item asUserExtensions[iCount]
                                Loop

                                Set Value to CS_StdExtensions
                            End_Procedure

                            Function UserSavedExtensions Returns String[]
                                String[] asUserExtensions
                                String sExt
                                Integer iCount iSize

                                Get piMaxUserFilters to iSize
                                For iCount from 0 to iSize
                                    Get ReadString  of ghoApplication CS_Settings (CS_VdfExtensionsKey + String(iCount)) "" to sExt
                                    If (sExt <> "") Begin
                                        Move sExt to asUserExtensions[SizeOfArray(asUserExtensions)]
                                    End
                                Loop

                                Function_Return asUserExtensions
                            End_Function

                            // Note: Can't save new extensions entered by user with the
                            // OnChange event, as it would save character per character.
                            Procedure OnExitObject
                                String sVDFExtensions sVDFVersion sNewExt
                                Integer iMajorVersion iMinorVersion iCount iSize iMaxUserFilters iItem
                                String[] asUserExtensions
                                Boolean bExists

                                Move FMAC_VERSION  to iMajorVersion
                                Move FMAC_REVISION to iMinorVersion
                                Move (String(iMajorVersion) + "." + String(iMinorVersion)) to sVDFVersion
                                Get StudioFileExtensions of ghoApplication sVDFVersion to sVDFExtensions

                                Get piMaxUserFilters to iSize
                                Get Value to sNewExt
                                If (sNewExt <> CS_StdExtensions and ;
                                    sNewExt <> CS_VDFAndTemplExt and ;
                                    sNewExt <> CS_PkgIncExt and ;
                                    sNewExt <> CS_SrcPkgExt and ;
                                    sNewExt <> sVDFExtensions) Begin

                                    Get IsExtensionInRegistry sNewExt to bExists

                                    If (bExists = False) Begin
                                        Get UserSavedExtensions to asUserExtensions
                                        // Push the new item on top of the list
                                        Send WriteString of ghoApplication CS_Settings (CS_VdfExtensionsKey + String("0")) sNewExt
                                        Get piMaxUserFilters to iMaxUserFilters
                                        Move (SizeOfArray(asUserExtensions)) to iSize
                                        Move (iMaxUserFilters min iSize) to iSize
                                        Decrement iSize
                                        Move 0 to iItem
                                        For iCount from 0 to iSize
                                            Send WriteString of ghoApplication CS_Settings (CS_VdfExtensionsKey + String(iCount + 1)) asUserExtensions[iItem]
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
                                Boolean bWorkspaceMode
                                Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
                                Function_Return bWorkspaceMode
                            End_Function

                        End_Object

                    End_Object

                End_Object

                Object oSplitterContainerChild4 is a cDbSplitterContainerChild

                    Object oSettings_grp is a cRDCDbHeaderGroup
                        Set Size to 90 263
                        Set Label to "Other Function Settings"
                        Set psImage to "Process.ico"
                        Set psNote to "Settings for 'Split in line', 'Reindent' and 'Remove blank lines'"
                        Set psToolTip to "Each extension must start with a wildcard character and a dot (*.) and file extensions must be separated with a semicolon (;)"
                        Set Border_Style to Border_None

                        Object oMaxBlankLines_sf is a cRDCDbSpinForm
                            Entry_Item SysFile.MaxBlankLines
                            Set Server to oSysFile_DD
                            Set Size to 13 27
                            Set Location to 53 213
                            Set Label to "Max blank lines"
                            Set Label_Col_Offset to 2
                            Set Label_Justification_Mode to JMode_Right
                            Set psToolTip to "Select the maximum number of consecutive blank lines that is allowed in a source file. If more empty lines are encountered, they will be removed."
                            Set Maximum_Position to 6
                            Set Minimum_Position to 1

                            Procedure OnChange
                                Integer iMaxBlankLineSize iMinValue iMaxValue
                                Boolean bChanged
                                
                                Get Minimum_Position to iMinValue
                                Get Maximum_Position to iMaxValue
                                Get Value to iMaxBlankLineSize   
                                Get Changed_State to bChanged
                                If (bChanged = True) Begin
                                    Send Request_Save of oSysFile_DD
                                End
                            End_Procedure

                        End_Object

                        Object oSplitBy_rgp is a dbRadioGroup
                            Entry_Item SysFile.SplitInFileMode
                            Set Server to oSysFile_DD
                            Set Location to 31 6
                            Set Size to 54 137
                            Set Label to "Split 'If' line to:"

                            Object oRadio0 is a Radio
                                Set Label to CS_SplitInFileBeginEnd
                                Set Size to 10 119
                                Set Location to 13 5
                                Set psToolTip to "Break the if/else line by adding a begin / end block"
                            End_Object

                            Object oRadio1 is a Radio
                                Set Label to CS_SplitBySpaceSemiColumn
                                Set Size to 10 119
                                Set Location to 26 5
                                Set psToolTip to "Break the if/else line with a space followed by a semicolon"
                            End_Object

                            Object oRadio2 is a Radio
                                Set Label to CS_SplitBySpaceSemiColumnSpace
                                Set Size to 10 119
                                Set Location to 38 5
                                Set psToolTip to "Break the if/else line with a semicolon"
                            End_Object

                        End_Object

                        Object oTabSize_sf is a cRDCDbSpinForm
                            Entry_Item SysFile.TabSize
                            Set Server to oSysFile_DD
                            Set Size to 13 27
                            Set Location to 35 213
                            Set Label to "Tab Size"
                            Set Label_Col_Offset to 2
                            Set Label_Justification_Mode to JMode_Right
                            Set psToolTip to "Select the indent size you want to use when indenting code and when breaking a line on rewriting a single line to multiple lines. It is the same value that can be set on the Editor Settings dialog tab size."
                            Set peAnchors to anTopRight
        
                            Procedure OnChange       
                                Boolean bChanged
                                Integer iTabSize
                                Get Value to iTabSize
                                Set piTabSize of (phoEditor(ghoApplication)) to iTabSize
                                Get Changed_State to bChanged
                                If (bChanged = True) Begin
                                    Send Request_Save of oSysFile_DD
                                End
                            End_Procedure
        
                        End_Object
                            
                    End_Object

                    Object oRunNow_grp is a cRDCDbHeaderGroup
                        Set Size to 47 263
                        Set Location to 93 0
                        Set psLabel to "Process Selections"
                        Set psNote to "Process selected refactoring functions" 
                        Set psToolTip to "Process selected refactoring functions for the source code matching the selected folders and file extensions."
                        Set psImage to "Start.ico"
                        Set peAnchors to anBottomLeftRight
                        Set Border_Style to Border_Normal
                        Set pbUseLargeFontHeight to True

                        Object oExecute_btn is a  cRDCButton
                            Set Size to 20 59
                            Set Location to 21 188
                            Set Label to "&Run Now!"
                            Set psToolTip to "Start processing the selected refactoring functions. If 'Workspace' mode has been selected from the toolbar all source files that matches the 'File Extensions Filter' will be processed. Else the operations will take place on a single file only. (Alt+R or Ctrl+R)"
                            Set MultiLineState to True
                            Set psImage to "RunProgram.ico"
                            Set pbAutoEnable to True
                            Set peAnchors to anBottomRight
                            Set Default_State to True
                            Set piImageMarginLeft to 7
                            Set piImageSize to 24

                            Procedure End_Construct_Object
                                Forward Send End_Construct_Object
                                Set FontPointHeight to 10
                                Set FontWeight to fw_Bold
                            End_Procedure

                            Procedure OnClick  
                                Send Request_Save of oSysFile_DD
                                Send Request_Save
                                Send Process
                            End_Procedure

                            Function IsEnabled Returns Boolean
                                Boolean bEnabled bWorkspaceMode
                                String sFileName sSWSFile
                                Integer iSelectedFunctions iFolders

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
                                    Move (SysFile.TotFunctionsSelected > 0) to bEnabled
                                End

                                If (bEnabled = True) Begin
                                    Get CheckedItems of oFolders_grd to iFolders
                                    Move (iFolders <> 0) to bEnabled
                                End

                                Function_Return bEnabled
                            End_Function

                        End_Object

                        Object oNoOfSelectedFunctions2_fm is a cRDCDbForm
                            Entry_Item SysFile.TotFunctionsSelected
                            Set Server to oSysFile_DD
                            Set Size to 13 15
                            Set Location to 27 167
                            Set Label_Justification_Mode to JMode_Right
                            Set Label to "Tot No of Functions Selected"
                            Set psToolTip to "Total number of functions selected."
                            Set Enabled_State to False
                            Set peAnchors to anBottomRight
                            Set Label_FontWeight to fw_Bold
                            Set Label_Col_Offset to 3
                            Set FontWeight to fw_Bold
                        End_Object

                    End_Object

                End_Object

            End_Object

        End_Object

    End_Object

    // At least one action should have been selected.
    // Also checks that spinform values are correct.
    Function IsValidActions Returns Boolean
        Boolean bOK
        Integer iTabSize iSelectedFunctions iMaxLines iMinLines
        tRefactorActions RefactorActions

        Get SelectedFunctions to iSelectedFunctions
        Move (iSelectedFunctions > 0) to bOK

        If (bOK = False) Begin
            Send Info_Box "You should at least check ONE action/function for the process to run."
            Function_Return False
        End

        Get Minimum_Position of oMaxBlankLines_sf to iMinLines
        Get Maximum_Position of oMaxBlankLines_sf to iMaxLines

        If (SysFile.MaxBlankLines < iMinLines or SysFile.MaxBlankLines > iMaxLines) Begin
            Send Info_Box ("The number of blank lines needs to be between" * String(iMinLines) * String("and") * String(iMaxLines))
            Move False to bOK
        End
        Else If (RefactorActions.bRemoveBlankLines = True and RefactorActions.Settings.iMaxBlankLines < iMinLines or RefactorActions.Settings.iMaxBlankLines > iMaxLines) Begin
            Send Info_Box ("The value for maximum number of consequitive blank lines needs to be between" * String(iMinLines)  * "and" * String(iMaxLines) + ".")
            Move False to bOK
        End

        Function_Return bOK
    End_Function

    // Does error checking then switches to the oEditorView and calls its main_process.
    Procedure Process
        String  sFileName sPath sFileFilter
        Boolean bFolderExists bFileExists bOK bWorkspaceMode
        Integer iFolders iRetval

        Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
        If (bWorkspaceMode = True) Begin
            Get CheckedItems of oFolders_grd to iFolders
            If (iFolders = 0) Begin
                Send Info_Box "You need to select at least one folder."
                Procedure_Return
            End
        End

        Get IsValidActions to bOk
        If (bOk = False) Begin
            Procedure_Return
        End

        If (bWorkspaceMode = True) Begin
            Get psHomePath of ghoApplication to sPath
            Get vFolderExists sPath to bFolderExists
            If (bFolderExists = False) Begin
                Send Stop_Box "Workspace directory does not exist" "Process Halted"
                Procedure_Return
            End
            If (SizeOfArray(RefactorActions.Settings.asFolderNames) = 0) Begin
                Send Stop_Box "You need to select at least one folder. Please adjust and try again."
                Procedure_Return
            End
            Move (Trim(SysFile.FileExtensionFilter)) to sFileFilter
            If (not(sFileFilter contains "." and (not(sFileFilter contains "*") or not(sFileFilter contains "?")))) Begin
                Send Stop_Box "You need to select at least one file name extenstion. Please adjust and try again"
                Procedure_Return
            End
        End
        Else If (bWorkspaceMode = False) Begin
            Get psCurrentSourceFileName of ghoApplication to sFileName
            Get FileExists of ghoFileSystem sFileName DIRMODE_FILES_ONLY to bFileExists
            If (bFileExists = False) Begin
                Send Stop_Box "File does not exists" "Process Halted"
                Procedure_Return
            End
        End                                                 
        
        If (RefactorActions.bCountNumberOfLines = True) Begin
            Get YesNo_Box "The Function 'Line Counting' needs to be run in solitude! All other functions will be ignored. Continue?" to iRetval
            If (iRetval <> MBR_Yes) Begin
                Procedure_Return
            End
        End

        // *** Call the Main Process ***
        Send MAIN_PROCESS of (phoEditorView(ghoApplication))
    End_Procedure

    Function pbShouldSave Returns Boolean
        Function_Return (Changed_State(Self))
    End_Function

    Procedure Request_Clear
        Set Changed_State to False
    End_Procedure

    Procedure Request_Clear_All
        Set Changed_State to False
        Send Request_Clear_All of oFolders_grd
    End_Procedure

    Procedure Close_Panel
    End_Procedure

    Procedure OnSetFocus
//        Integer iTabSize
        Set piActiveView of ghoApplication to CI_CleanupSource Self
//        Get piTabSize of ghoEditorProperties to iTabSize
        Set Value of oTabSize_sf to SysFile.TabSize
//        Set Value of oNoOfSelectedFunctions_fm  to SysFile.TotFunctionsSelected
        Set Value of oNoOfSelectedFunctions2_fm to SysFile.TotFunctionsSelected  
//        Set Value of oMaxBlankLines_sf          to SysFile.MaxBlankLines
    End_Procedure

    Procedure WorkspaceLoaded
        Send LoadData of oFolders_grd
    End_Procedure

    // Allow a source file, .sws file or a folder to be dropped on the view:
    Procedure OnFileDropped String sFileFolderName Boolean bLast
        String sFileExt
        Boolean bFile bFolder bSWSFile

        Forward Send OnFileDropped sFileFolderName bLast

        // Try to find out if a file or a folder name
        // was dropped on the view:
        If (bLast = True) Begin
            Get ParseFileExtension sFileFolderName to sFileExt
            Move (Lowercase(sFileExt)) to sFileExt
            Move (sFileExt = "")    to bFolder
            Move (sFileExt = "sws") to bSWSFile
            Move (bSWSFile = False and bFolder = False) to bFile
            If (bFile = True) Begin
                Send UpdateSourceFileNameDisplay of ghoApplication sFileFolderName
                Set pbWorkspaceMode of ghoApplication to False
            End
            Else If (bSWSFile = True) Begin
                Send UpdateWorkspaceSelectorDisplay of ghoApplication sFileFolderName
                Set pbWorkspaceMode of ghoApplication to True
            End
            Else If (bFolder = True) Begin
                Send AddItem of oFolders_grd sFileFolderName
            End
        End
        Else Begin
            Send Info_Box "Only one file, folder or .sws project can be dropped on the view at a time. The last will be used."
        End
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Set Enabled_State to (sSWSFile <> "")
            Send UpdateEnabledState of oFolders_grd
        End_Procedure
    End_Object

    Procedure ToggleActionButton
//        Send KeyAction of oToggle_btn
    End_Procedure

    On_Key Key_Alt+Key_G  Send ToggleActionButton
    On_Key Key_Ctrl+Key_G Send ToggleActionButton
End_Object
