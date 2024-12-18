Use Dfclient.pkg
Use cCJGridColumnRowIndicator.pkg
Use cDbCJGridColumnSuggestion.pkg

Use cRefactorDbView.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCDbForm.pkg
Use cRDCComboForm.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd

Register_Function MyDelete_Confirmation Returns Integer

Activate_View Activate_oSelectFunctions_vw for oSelectFunctions_vw
Object oSelectFunctions_vw is a cRefactorDbView
    Set Location to 2 4
    Set Size to 110 635
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
            If (piFunctionType(Self) <> eAll_Functions) Begin
                Constrain Functions.Type eq (piFunctionType(Self))
            End
        End_Procedure

    End_Object

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oSelectFunctions_grp is a cRDCDbHeaderGroup
        Set Size to 107 637
        Set piMinSize to 107 490
        Set Location to 4 0
        Set Label to "Function List"             
        Set psImage to "FunctionLookup.ico"
        Set psNote to "Space to select. Double-Click to Edit, right-click for grid options."
        Set psToolTip to "Standard refactoring functions are functions that are called once for each source line."
        Set Border_Style to Border_None
        Set peAnchors to anTopBottom

        Object oFunctionSelection_grd is a cRDCDbCJGrid
            Set Size to 76 620
            Set Location to 27 10
            Set Ordering to 5
            Set pbDbShowInvertSelectionsMenuItem to True
            Set pbDbShowEditMenuItem to True
            Set pbStaticData to True
            Set pbHeaderPrompts to False
                
            Object oFunctions_ID is a cRDCDbCJGridColumn
                Entry_Item Functions.ID
                Set piWidth to 30
                Set psCaption to "ID"
                Set pbEditable to False
                Set peTextAlignment to xtpAlignmentCenter
            End_Object

            Object oFunctions_Function_Name is a cDbCJGridColumnSuggestion
                Entry_Item Functions.Function_Name
                Set piWidth to 285
                Set psCaption to "Function Name (Suggestion list)"    
                Set pbFullText to True    
                Set psToolTip to "This is a full text suggestion list. You can start typing to search for any keyword and a suggestion list will appear for you to select from."
                Set Status_Help to (psToolTip(Self))
                Set phoData_Col to Self   
                Set pbAllowRemove to False
                
                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get RowValue of oFunctions_Function_Help iRow to sText
                    Function_Return sText
                End_Function
    
            End_Object

            Object oFunctions_Function_Description is a cRDCDbCJGridColumn
                Entry_Item Functions.Function_Description
                Set piWidth to 340
                Set psCaption to "Description"
                Set pbEditable to False
                Set psToolTip to "A short description of whate the refactoring function does. Hover the mouse over a function row to see more help on what it does."
    
                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Get RowValue of oFunctions_Function_Help iRow to sText
                    Function_Return sText
                End_Function
    
            End_Object

            Object oFunctions_Type is a cRDCDbCJGridColumn
                Entry_Item Functions.Type
                Set piWidth to 170
                Set psCaption to "Type"
                Set peHeaderAlignment to xtpAlignmentCenter  
                Set pbComboButton to True
                // pbEditable *must* be set after the pbComboButton setting.
                Set pbEditable to False
                Set psToolTip to "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing."
    
                Function OnGetTooltip Integer iRow String sValue String sText Returns String
                    Move "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing." to sText
                    Function_Return sText
                End_Function
    
            End_Object                    

            Object oFunctions_Parameter is a cRDCDbCJGridColumn //cDbCJGridColumn
                Entry_Item Functions.Parameter
                Set piWidth to 100
                Set psCaption to "Parameter" "Option"
                Set pbComboButton to True  
                Set pbComboEntryState to False
                Set psToolTip to "Double-click for dropdown choices when there is a value. For some functions an extra parameter is passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."
    
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
                    If (sText <> "") Begin
                        Move (Replaces("\n", sText, CS_CRLF)) to sText
                        Move ("Double-click for dropdown choises." * String(sText)) to sText
                    End 
                    Else Begin
                        Move "Double-click for dropdown choises on rows that has a value. For some functions an extra parameter is used. You can only select from existing values. Hover the mouse over a value to see valid values to be selected from." to sText
                    End
                    Function_Return sText
                End_Function
    
            End_Object

            Object oFunctions_ParameterHelp is a cRDCDbCJGridColumn //cDbCJGridColumn
                Entry_Item Functions.ParameterHelp
                Set piWidth to 200
                Set psCaption to "Parameter Help"
                Set pbVisible to False
            End_Object

            Object oFunctions_Function_Help is a cRDCDbCJGridColumn
                Entry_Item Functions.Function_Help
                Set piWidth to 221
                Set psCaption to "Help"
                Set pbVisible to False
            End_Object
    
            Object oFunctions_Selected is a cRDCDbCJGridColumn
                Entry_Item Functions.Selected
                Set piWidth to 39
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
            
            Procedure Request_Edit
                Integer iFunctionID iSelectedCol iParameterCol
                Get piColumnId of oFunctions_Parameter to iParameterCol
                Get SelectedColumn to iSelectedCol
                If (iSelectedCol = iParameterCol) Begin
                    Procedure_Return
                End
                Get Field_Current_Value of oFunctions_DD Field Functions.ID to iFunctionID
                Delegate Send ActivateFunctionsView iFunctionID
            End_Procedure
                    
            // Augment to also show # of functions in the "ID" footer
            Procedure DoSetCheckboxFooterText
                Integer iItems
                Forward Send DoSetCheckboxFooterText
                Get ItemCount to iItems
                Set psFooterText of oFunctions_ID  to ("#" * String(iItems))
            End_Procedure
                    
        End_Object

        Object oSelectAll_btn is a Button
            Set Size to 14 62
            Set Location to 10 255
            Set Label to "Select All"
            Set psImage to "SelectAll.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectAll of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oSelectNone_btn is a Button
            Set Size to 14 62
            Set Location to 10 321
            Set Label to "Select None"
            Set psImage to "SelectNone.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectNone of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oSelectInvert_btn is a Button
            Set Size to 14 74
            Set Location to 10 387
            Set Label to "Invert Selections"
            Set psImage to "SelectInvert.ico"
            Set peAnchors to anTopRight
            Procedure OnClick
                Send SelectInvert of oFunctionSelection_grd
            End_Procedure
        End_Object

        Object oConstrainByType_cf is a ComboForm
            Set Size to 14 99
            Set Location to 10 531
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

    End_Object
                    
    Set Verify_Delete_msg to (RefFunc(MyDelete_Confirmation))
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    On_Key Key_Escape      Send None
    On_Key Key_Ctrl+Key_S  Send Request_Save
    On_Key Key_F2          Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object
