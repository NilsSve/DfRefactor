Use Dfclient.pkg
Use cCJGridColumnRowIndicator.pkg
Use cRDCSuggestionsBaseClasses.pkg
//Use cRefactorDbView.pkg
Use cRDCDbView.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCDbForm.pkg
Use cRDCComboForm.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd

Register_Function MyDelete_Confirmation Returns Integer

Activate_View Activate_oSelectFunctions_vw for oSelectFunctions_vw
Object oSelectFunctions_vw is a cRDCDbView
    Set Location to 2 4
    Set Size to 193 635
    Set Label to "Select Functions"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True   
    Set Icon to "FunctionLookup.ico"
    Set Maximize_Icon to True

    Object oSysFile_DD is a cSysFileDataDictionary
        Set No_Delete_State to True
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary  
        
        Procedure OnConstrain
            If (piFunctionType(Self) <> eAllFunctions) Begin
                Constrain Functions.Type eq (piFunctionType(Self))
            End
            Constrain Functions.bPublished eq (True)
        End_Procedure

    End_Object

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oSelectFunctions_grp is a cRDCDbHeaderGroup
        Set Size to 190 637
        Set piMinSize to 107 490
        Set Location to 4 0
        Set Label to "Function List"             
        Set psImage to "FunctionLookup.ico"
        Set psNote to "Space to select. Click to Edit, right-click for grid options."
        Set psToolTip to "Standard refactoring functions are functions that are called once for each source line."
        Set Border_Style to Border_None
        Set peAnchors to anAll

        Object oFunctionSelection_grd is a cRDCDbCJGrid
            Set Size to 159 620
            Set Location to 27 10  
            Set Ordering to 2
            Set pbDbShowInvertSelectionsMenuItem to True
            Set pbDbShowEditMenuItem to False 
            Set pbHeaderPrompts to False
            Set piHScrollStep to 1
            // Need this to load all records in the grid,
            // else the select buttons won't work properly.
            Set pbStaticData to True  
            Set pbEditOnClick to True
            Set pbEditOnKeyNavigation to False
            Set pbShowNonActiveInPlaceButton to False
            Set piLayoutBuild to 6 

            Object oFunctions_ID is a cRDCDbCJGridColumn
                Entry_Item Functions.ID
                Set piWidth to 30
                Set psCaption to "ID"
                Set pbEditable to False
                Set peTextAlignment to xtpAlignmentCenter
            End_Object

            Object oFunctions_Function_Name is a cDbCJGridColumnSuggestionNew //cDbCJGridColumnSuggestion
                Entry_Item Functions.Function_Name
                Set piWidth to 185
                Set psCaption to "Function Name (Suggestion list)"    
                Set psToolTip to "This is a full text suggestion list. You can start typing to search for any keyword and a suggestion list will appear for you to select from."
                Set Status_Help to (psToolTip(Self))
                Set pbFullText to True    
                Set pbAllowRemove to False
                Set phoData_Col to Self 
            End_Object

            Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                Entry_Item Functions.Function_Help
                Set piWidth to 320
                Set peHeaderAlignment to xtpAlignmentCenter
                Set psCaption to "Help Text"
                Set pbEditable to False
                Set pbMultiLine to True
            End_Object
    
            Object oFunctions_Type is a cRDCDbCJGridColumn
                Entry_Item Functions.Type
                Set piWidth to 130
                Set psCaption to "Type"
                Set psToolTip to "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing."
                Set Status_Help to (psToolTip(Self))
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set peTextAlignment to xtpAlignmentCenter
                Set pbComboButton to True
                // pbEditable *must* be set after the pbComboButton setting.
                Set pbEditable to False
                Set pbComboEntryState to False
            End_Object                    

            Object oFunctions_Parameter is a cRDCDbCJGridColumn
                Entry_Item Functions.Parameter
                Set piWidth to 100
                Set psCaption to "Parameter"
                Set psToolTip to "Click for dropdown choices when there is a value. For some functions an extra parameter is passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."
                Set Status_Help to (psToolTip(Self))
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set pbComboButton to True 
                // pbEditable *must* be set after the pbComboButton setting.
                Set pbEditable to True
                Set pbComboEntryState to False 
    
                Procedure ComboFillList
                    String sParameterList
                    String[] asParameters
                    Integer iSize iCount
                    
                    Get Field_Current_Value of (Main_DD(Self)) Field Functions.ParameterValidation to sParameterList
                    If (sParameterList <> "") Begin
                        Set pbComboButton to True
                        Send ComboDeleteData
                        Get StrSplitToArray  sParameterList "," to asParameters
                        Move (SizeOfArray(asParameters)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Send ComboAddItem asParameters[iCount] iCount
                        Loop
                    End
                    Else Begin
                        Set pbComboButton to False
                    End
                End_Procedure

                Procedure OnEntry
                    Send ComboFillList
                End_Procedure 
                
                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get RowValue of oFunctions_ParameterHelp iRow to sText
                    If (sText <> "") Begin
                        Move (Replaces("\r\n", sText, CS_CRLF)) to sText
                        Move (Replaces("\n", sText, CS_CRLF)) to sText
                    End 
                    Else Begin
                        Move "Dropdown with choises on rows that has a value. For some functions an extra parameter is used. You can only select from existing values. Hover the mouse over an item to see all valid values to select from." to sText
                    End
                    Function_Return sText
                End_Function
    
            End_Object

            Object oFunctions_Selected is a cRDCDbCJGridColumn
                Entry_Item Functions.Selected
                Set piWidth to 39
                Set psCaption to "Select"
                Set pbAllowRemove to False
                Set pbCheckbox to True
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set peFooterAlignment to xtpAlignmentCenter
                Set Status_Help to (psToolTip(Self))
                Set phoCheckbox_Col to Self
            End_Object

            Object oFunctions_SummaryText is a cRDCDbCJGridColumn
                Entry_Item Functions.SummaryText
                Set piWidth to 200
                Set psCaption to "Summary Text"
                Set pbEditable to False
                Set pbMultiLine to True
                Set pbVisible to False
            End_Object

            Object oFunctions_ParameterHelp is a cRDCDbCJGridColumn
                Entry_Item Functions.ParameterHelp
                Set piWidth to 150
                Set psCaption to "Parameter Help"
                Set pbVisible to False
                Set pbShowInFieldChooser to False
            End_Object

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

            Procedure LoadData 
                Handle hoDataSource hoServer
                Integer iRows iFile
                tDataSourceRow[] TheData 
                Boolean bFound
                
                Get Server to hoServer
                Get Main_File of hoServer to iFile
                Send Request_Read of hoServer FIRST_RECORD 2
                Move (Found) to bFound
                Get phoDataSource to hoDataSource
                While (bFound)
                    Get CreateDataSourceRow of hoDataSource to TheData[iRows]
                    Increment iRows
                    Send Request_Read of hoServer GT iFile 2
                    Move (Found) to bFound
                Loop
                Send InitializeData TheData 
                Send Reset of hoDataSource
                Send MoveToFirstRow
            End_Procedure

            // For unknown reason the first row in the list is *not* highlighted
            // when the grid is filled. This fixes it.
            Procedure Activating
                Forward Send Activating
                Send LoadData 
            End_Procedure 
            
        End_Object

        Object oSelectAll_btn is a Button
            Set Size to 14 62
            Set Location to 10 238
            Set Label to "Select All"
            Set psImage to "SelectAll.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectAll of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oSelectNone_btn is a Button
            Set Size to 14 62
            Set Location to 10 304
            Set Label to "Select None"
            Set psImage to "SelectNone.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectNone of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oSelectInvert_btn is a Button
            Set Size to 14 74
            Set Location to 10 370
            Set Label to "Invert Selections"
            Set psImage to "SelectInvert.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectInvert of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oConstrainByType_cf is a ComboForm
            Set Size to 14 116
            Set Location to 10 514
            Set peAnchors to anTopRight
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to JMode_Right
            Set Label to "Constrain by Type:"
            Set Entry_State to False
            Set Combo_Sort_State to False
          
            Procedure Combo_Fill_List
                Send Combo_Add_Item CS_AllFunctions
                Send Combo_Add_Item CS_StandardFunction
                Send Combo_Add_Item CS_RemoveFunction
                Send Combo_Add_Item CS_EditorFunction
                Send Combo_Add_Item CS_ReportFunction   
                Send Combo_Add_Item CS_ReportFunctionAll
                Send Combo_Add_Item CS_OtherFunction   
                Send Combo_Add_Item CS_OtherFunctionAll
            End_Procedure
          
            Procedure OnChange
                String sValue                      
                Integer iType
                
                Get Value to sValue
                Case Begin
                    Case (sValue = CS_AllFunctions)
                        Move eAllFunctions to iType
                        Case Break
                    Case (sValue = CS_StandardFunction)
                        Move eStandardFunction to iType
                        Case Break
                    Case (sValue = CS_RemoveFunction)
                        Move eRemoveFunction to iType
                        Case Break                            
                    Case (sValue = CS_EditorFunction)
                        Move eEditorFunction to iType
                        Case Break
                    Case (sValue = CS_ReportFunction)
                        Move eReportFunction to iType
                        Case Break
                    Case (sValue = CS_ReportFunctionAll)
                        Move eReportFunctionAll to iType
                        Case Break
                    Case (sValue = CS_OtherFunction)
                        Move eOtherFunction to iType
                        Case Break
                    Case (sValue = CS_OtherFunctionAll)
                        Move eOtherFunctionAll to iType
                        Case Break
                    Case Else
                Case End
                    
                Set piFunctionType of (Main_DD(Self)) to iType
                Send Rebuild_Constraints of (Main_DD(Self)) 
                Send RefreshDataFromDD of oFunctionSelection_grd 0
            End_Procedure
          
        End_Object

    End_Object

    Set Verify_Delete_msg to (RefFunc(MyDelete_Confirmation))
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    On_Key Key_Escape      Send None
    On_Key Key_Ctrl+Key_S  Send Request_Save
    On_Key Key_F2          Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object
