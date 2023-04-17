Use DFClient
Use cCJGridColumnRowIndicator.pkg
Use cRDCDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCDbForm.pkg
Use cRDCComboForm.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd
Use cdbCJGridColumn.pkg
Use Windows.pkg

ACTIVATE_VIEW Activate_oMaintainFunctions FOR oMaintainFunctions
Object oMaintainFunctions is a dbView
    Set Location to 2 4
    Set Size to 143 591
    Set Label to "Functions List"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True
    Set Maximize_Icon to True

    Object oSysFile_DD is a cSysFileDataDictionary
        Set No_Delete_State to True
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary  
        Set No_Delete_State to True
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oInfo_tb is a TextBox
        Set Size to 10 275
        Set Location to 8 34
        Set Label to "List of Functions in the database. Double-Click a row to Edit, Right-Click for options"
        Set FontWeight to fw_Bold
    End_Object

    Object oFunctionSelection_grd is a cRDCDbCJGrid
        Set Size to 125 578
        Set Location to 26 7
        Set Ordering to 5
        Set piLayoutBuild to 3
        Set pbHeaderReorders to True
        Set pbHeaderTogglesDirection to True
        Set pbAllowAppendRow to False
        Set pbAllowDeleteRow to False
        Set pbAllowInsertRow to False
        Set pbAutoAppend to False

//        Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
//            Set piWidth to 17
//        End_Object

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
            Set pbEditable to False
        End_Object                    

        Object oFunctions_Parameter is a cDbCJGridColumn
            Entry_Item Functions.Parameter
            Set piWidth to 65
            Set psCaption to "Option"  
            Set psToolTip to "For some functions an extra parameter setting can be passed. You can only change existing values. Hover the mouse over a value to see valid values to be selected from."
            Set pbEditable to False

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
            Integer iFunctionID
            Forward Send OnComRowDblClick llRow llItem
            Get Field_Current_Value of oFunctions_DD Field Functions.ID to iFunctionID
            Delegate Send ActivateFunctionsView iFunctionID
        End_Procedure

    End_Object

    // To enable Ctrl+MouseWheel in the grid to change font size.
    Procedure OnWmMouseWheel Integer wParam Integer lParam
       Integer iKeys iClicks iX iY iCONTROL
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
        
    Object oSysFile_TotFunctionsSelected is a cRDCDbForm
        Entry_Item SysFile.SelectedFunctionTotal
        Set Server to oSysFile_DD
        Set Location to 7 486
        Set Size to 12 15
        Set Label to "Selected Functions:"
        Set Enabled_State to False
        Set peAnchors to anNone
        Set Label_Col_Offset to 0
    End_Object

    Object oGridFontSize_cf is a cRDCComboForm
        Set Size to 13 32
        Set Location to 7 370
        Set Label to "Grid font size"
        Set psToolTip to "Sets the font size for grids"
        Set Label_Col_Offset to 2
        Set Label_Justification_Mode to JMode_Right
        Set Entry_State to False
        Set Combo_Sort_State to False

        Procedure Combo_Fill_List
            Integer iSize

            Send Combo_Add_Item "6"
            Send Combo_Add_Item "7"
            Send Combo_Add_Item "8"
            Send Combo_Add_Item "9"
            Send Combo_Add_Item "10"
            Send Combo_Add_Item "11"
            Send Combo_Add_Item "12"
            Send Combo_Add_Item "13"
            Send Combo_Add_Item "14"
            Send Combo_Add_Item "15"
            Send Combo_Add_Item "16"

            Get ReadString of ghoApplication CS_Settings CS_GridFontSize 8 to iSize
            Set Value to iSize
        End_Procedure

        Procedure OnChange     
            Integer iSize
            Get Value to iSize
            Send WriteString of ghoApplication CS_Settings CS_GridFontSize iSize
            Broadcast Recursive Send DoChangeFontSize of (Client_Id(ghoCommandBars))
        End_Procedure

    End_Object

    Procedure ScaleFont Integer iDirection    // from control + mouse wheel in container object
        Integer iSize jSize kSize iSup iInf iDef
        Handle hoPaintManager hoFont
        Variant vFont
        
        Move 3 to iInf      //max size
        Move 18 to iSup     //min size
        Move 8 to iDef      //default
        Boolean blimite
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
        End
        Send Destroy to hoFont 
        Send ComRedraw  
        Send WriteString of ghoApplication CS_Settings CS_GridFontSize iSize
    End_Procedure 

    Procedure Close_Panel
    End_Procedure

    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    On_Key Key_Escape Send None
    On_Key Key_Ctrl+Key_S Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object 
