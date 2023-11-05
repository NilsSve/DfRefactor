Use Dfclient.pkg
Use cCJGridColumnRowIndicator.pkg
Use cRDCDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCDbForm.pkg
Use cRDCComboForm.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd

Register_Function MyDelete_Confirmation Returns Integer

ACTIVATE_VIEW Activate_oMaintainFunctions FOR oMaintainFunctions
Object oMaintainFunctions is a dbView
    Set Location to 2 4
    Set Size to 140 589
    Set Label to "Functions List"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True
    Set Maximize_Icon to True

    Object oSysFile_DD is a cSysFileDataDictionary
        Set No_Delete_State to True
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary  
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oInfo1_tb is a TextBox
        Set Auto_Size_State to False
        Set Size to 11 335
        Set Location to 4 9
        Set Label to "List of available refactoring functions:"
        Set FontWeight to fw_Bold
        Set FontPointHeight to 10
    End_Object

    Object oInfo2_tb is a TextBox
        Set Size to 10 160
        Set Location to 6 187
        Set Label to "- Space to select. Double-Click to Edit, right-click for grid options."
    End_Object

    Object oFunctionSelection_grd is a cRDCDbCJGrid
        Set Size to 120 578
        Set Location to 17 6
        Set Ordering to 5
        Set piLayoutBuild to 3
        Set pbHeaderReorders to True
        Set pbHeaderTogglesDirection to True
        Set pbAllowAppendRow to False
        Set pbAllowInsertRow to False
        Set pbAutoAppend to False
        Set Verify_Delete_msg to (RefFunc(MyDelete_Confirmation))

        Object oFunctions_ID is a cRDCDbCJGridColumn
            Entry_Item Functions.ID
            Set piWidth to 41
            Set psCaption to "ID"
            Set pbEditable to False
            Set pbEditable to False
        End_Object

        Object oFunctions_Function_Name is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Name
            Set piWidth to 205
            Set psCaption to "Function Name"    
            Set phoData_Col to Self
            Set pbEditable to False
        End_Object

        Object oFunctions_Function_Description is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Description
            Set piWidth to 204
            Set psCaption to "Function Description"
            Set pbMultiLine to True
            Set pbEditable to False
        End_Object

        Object oFunctions_Function_Help is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Help
            Set piWidth to 310
            Set psCaption to "Function Help"
            Set pbMultiLine to True
            Set pbEditable to False
        End_Object

        Object oFunctions_Type is a cRDCDbCJGridColumn
            Entry_Item Functions.Type
            Set piWidth to 86
            Set psCaption to "Type"
            Set peHeaderAlignment to xtpAlignmentCenter  
            Set pbComboButton to True
            // pbEditable *must* be set after the pbComboButton setting.
            Set pbEditable to False
            Set psToolTip to "The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full pathing."
        End_Object                    

        Object oFunctions_Parameter is a cDbCJGridColumn
            Entry_Item Functions.Parameter
            Set piWidth to 65
            Set psCaption to "Option"  
            Set pbComboButton to True  
            Set pbComboEntryState to False
            Set psToolTip to "For some functions an extra parameter setting can be passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."

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
                Function_Return sText
            End_Function

        End_Object

        Object oFunctions_ParameterHelp is a cDbCJGridColumn
            Entry_Item Functions.ParameterHelp
            Set piWidth to 200
            Set psCaption to "Parameter Help"
            Set pbVisible to False
            Set pbEditable to False
        End_Object

        Object oFunctions_Selected is a cRDCDbCJGridColumn
            Entry_Item Functions.Selected
            Set piWidth to 42
            Set psCaption to "Select"
            Set pbCheckbox to True
            Set peHeaderAlignment to xtpAlignmentCenter  
            Set phoCheckbox_Col to Self
        End_Object

        Procedure Refresh Integer eMode
            Forward Send Refresh eMode
            Set Value of oSysFile_TotFunctionsSelected to SysFile.SelectedFunctionTotal
        End_Procedure

        Procedure OnComRowDblClick Variant llRow Variant llItem
            Integer iFunctionID iSelectedCol iParameterCol
            Get piColumnId of oFunctions_Parameter to iParameterCol
            Get SelectedColumn to iSelectedCol
            If (iSelectedCol = iParameterCol) Begin
                Procedure_Return
            End
            Forward Send OnComRowDblClick llRow llItem   
            Get Field_Current_Value of oFunctions_DD Field Functions.ID to iFunctionID
            Delegate Send ActivateFunctionsView iFunctionID
        End_Procedure

        Procedure ScaleFont Integer iDirection    // from control + mouse wheel in container object
            Integer iSize jSize kSize iSup iInf iDef
            Handle hoPaintManager hoFont
            Boolean blimite
            Variant vFont
            
            Move 3 to iInf      //max size
            Move 18 to iSup     //min size
            Move 8 to iDef      //default
            Get phoReportPaintManager to hoPaintManager
            If (IsComObjectCreated (hoPaintManager) = False) Begin
                Procedure_Return
            End
            Get Create (RefClass(cComStdFont)) to hoFont
            Get ComTextFont of hoPaintManager to vFont
            Set pvComObject of hoFont to vFont
            If (iDirection = 0) Begin
                Set ComSize of hoFont to iDef
            End
            Else Begin
               Get ComSize of hoFont to iSize
               Move iSize to jSize
               Repeat
                    Move (If(iDirection > 0, jSize + 1, jSize - 1)) to jSize
                    Move (If(iDirection > 0, If(jSize > iSup, True, False), If(jSize < iInf, True, False))) to blimite
                    If (not(blimite)) Begin       
                       Set ComSize of hoFont to jSize
                       Get ComSize of hoFont to kSize
                    End
               Until (iSize <> kSize or blimite)    
               Move kSize to iSize
            End
            Send Destroy to hoFont 
            Send ComRedraw  
            Send WriteString of ghoApplication CS_Settings CS_GridFontSize iSize
        End_Procedure 
        
        Procedure SelectAll
            Send SelectAll of (Server(Self))
            Send RefreshSelectionUpdate
        End_Procedure

        Procedure SelectNone
            Send DeSelectAll of (Server(Self))
            Send RefreshSelectionUpdate
        End_Procedure 
        
        // This is so the "Delete" button in the toolbar is disabled, as we
        // do not allow deletion in this view.
        Function DEO_Object Returns Boolean
            Function_Return False
        End_Function
        
        On_Key Key_Ctrl+Key_A Send SelectAll
        On_Key Key_Ctrl+Key_N Send SelectNone
    End_Object

    Object oSysFile_TotFunctionsSelected is a cRDCDbForm
        Entry_Item SysFile.SelectedFunctionTotal
        Set Server to oSysFile_DD
        Set Location to 3 546
        Set Size to 12 13
        Set Label to "Selected:"
        Set Enabled_State to False
        Set Label_Col_Offset to 0
        Set FontWeight to fw_Bold
        Set FontPointHeight to 10
        Set peAnchors to anTopRight
        Set Label_FontWeight to fw_Bold
    End_Object

    // To enable Ctrl+MouseWheel in the grid to change font size.
    Procedure OnWmMouseWheel Integer wParam Integer lParam
       Integer iKeys iClicks iX iY iCONTROL iSize
       Short iDelta     // Short signed integer
       Boolean bok 
       Handle hoGrid
       
       Move 0 to iDelta
       Move (Low(wParam)) to iKeys           // any keys down when pressed
       Move (MemCopy(AddressOf(iDelta),AddressOf(wParam)+2,2)) to bok
       // C_WHEELDATA is 120 as defined by MS as the delta to react to. Once click is usually 120
       Move (iDelta/C_WHEELDELTA) to iClicks // Number of clicks to react to
       Move (Low(lParam)) to iX  // cursor position
       Move (Hi(lParam)) to iY   

       Move (oFunctionSelection_grd(Self)) to hoGrid
       Move (iKeys iand MK_CONTROL ) to iCONTROL  //$008
       If (iCONTROL) Begin
            Send ScaleFont of hoGrid iClicks
       End

       // Tell windows that we've handled the event.    
       Set Windows_Override_State to True    
    End_Procedure
        
    // Automatically save any changes when leaving this view.
    Procedure Exiting_Scope Handle hoNewScope Returns Integer
        Integer iRetVal
        Boolean bHasChange
        Get Should_Save of (Main_DD(Self)) to bHasChange
        If (bHasChange = True) Begin
            Send Request_Save
        End
        Forward Get msg_Exiting_Scope hoNewScope to iRetVal
        Procedure_Return iRetVal
    End_Procedure

    Procedure Close_Panel
    End_Procedure
    
    Function MyDelete_Confirmation Returns Integer
        Send Info_Box "You are not allowd to delete records here."
        Function_Return 1    
    End_Function
    
    Set Verify_Delete_msg to (RefFunc(MyDelete_Confirmation))
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    On_Key Key_Escape      Send None
    On_Key Key_Ctrl+Key_S  Send Request_Save
    On_Key Key_F2          Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object 
