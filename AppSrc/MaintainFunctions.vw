// C:\Projects\DF18\DfRefactor\AppSrc\MaintainFunctions.vw
// Maintain Functions
//

Use DFClient.pkg
Use DFEntry.pkg
Use DFEnChk.pkg
Use cCJGridColumnRowIndicator.pkg

Use cRDCDbCJGrid.pkg
Use cRDCDbCJGridColumn.pkg
Use cRDCComboForm.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd
Use cdbCJGridColumn.pkg

ACTIVATE_VIEW Activate_oMaintainFunctions FOR oMaintainFunctions
Object oMaintainFunctions is a dbView
    Set Location to 2 4
    Set Size to 143 591
    Set Label to "Maintain Functions - Grid"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True
    Set Maximize_Icon to True

    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oGridFontSize_cf is a cRDCComboForm
        Set Size to 13 54
        Set Location to 4 54
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

    Object oFunction_grd is a cRDCDbCJGrid
        Set Size to 125 578
        Set Location to 26 7
        Set peAnchors to anAll
        Set Ordering to 5
        Set piLayoutBuild to 5

        Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
            Set piWidth to 17
        End_Object

        Object oFunctions_ID is a cRDCDbCJGridColumn
            Entry_Item Functions.ID
            Set piWidth to 30
            Set psCaption to "ID"
            Set pbEditable to False
        End_Object

        Object oFunctions_Function_Name is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Name
            Set piWidth to 147
            Set psCaption to "Function Name"    
            Delegate Set phoData_Col to Self
        End_Object

        Object oFunctions_Function_Description is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Description
            Set piWidth to 147
            Set psCaption to "Function Description"
            Set pbMultiLine to True
        End_Object

        Object oFunctions_Function_Summary is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Summary
            Set piWidth to 183
            Set psCaption to "Function Summary"
            Set pbMultiLine to True
        End_Object

        Object oFunctions_Function_Help is a cRDCDbCJGridColumn
            Entry_Item Functions.Function_Help
            Set piWidth to 252
            Set psCaption to "Function Help"
            Set pbMultiLine to True
        End_Object

        Object oFunctions_Type is a cRDCDbCJGridColumn
            Entry_Item Functions.Type
            Set piWidth to 82
            Set psCaption to "Type"
            Set peHeaderAlignment to xtpAlignmentCenter
            Set peTextAlignment to xtpAlignmentCenter
            Set pbComboButton to True
        End_Object                    

//        Object oFunctions_bWriteProtected is a cDbCJGridColumn
//            Entry_Item Functions.bWriteProtected
//            Set piWidth to 21
//            Set psCaption to "Prot."
//            Set peTextAlignment to xtpAlignmentCenter
//            Set pbCheckbox to True
//            Set Visible_State to False
//        End_Object

        Object oFunctions_eSourceMode is a cDbCJGridColumn
            Entry_Item Functions.eSourceMode
            Set psToolTip to "Line-by-line exectutes for each source line. Whole Source File is feed the whole file, and All Source Files is feed with an array with all selected files. Normally a line-by-line approach is used."
            Set piWidth to 85
            Set psCaption to "Source Mode"
            Set peHeaderAlignment to xtpAlignmentCenter  
            Set pbComboButton to True
        End_Object

    End_Object

End_Object 
