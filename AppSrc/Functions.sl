// Functions.sl
// Functions Lookup List

Use Windows.pkg
Use DFClient.pkg
Use cDbCJGridPromptList.pkg
Use cDbCJGridColumn.pkg
Use RefactorConstants.inc
Use cFunctionsDataDictionary.dd

CD_Popup_Object oFunctions_sl is a dbModalPanel
    Set Location to 5 5
    Set Size to 134 269
    Set Label To "Functions Lookup List"
    Set Border_Style to Border_Thick
    Set Minimize_Icon to False

    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oSelList is a cDbCJGridPromptList
        Set Size to 105 259
        Set Location to 5 5
        Set pbAllowColumnRemove to False
        Set psLayoutSection to "oFunctions_sl_oSelList"
        Set pbUseAlternateRowBackgroundColor to True
        Set piAlternateRowBackgroundColor to clAlternateRowBgColor   
        Set pbShowRowFocus to True
        Set pbUseFocusCellRectangle to True
        Set pbShadeSortColumn to False
        Set pbAutoServer to False
        Set piSelectedRowBackColor to clActiveRow
        Set piHighlightBackColor   to clActiveRow
        Set piCaptionBackColor     to clProgramIconBg
        Set piCaptionForeColor     to clWhite   
        Set peVisualTheme to xtpGridThemeVisualStudio2012Light //xtpGridThemeVisualStudio2017
        Set peAnchors to anAll

        Object oFunctions_ID is a cDbCJGridColumn
            Entry_Item Functions.ID
            Set piWidth to 31
            Set psCaption to "ID"
        End_Object 

        Object oFunctions_Function_Name is a cDbCJGridColumn
            Entry_Item Functions.Function_Name
            Set piWidth to 284
            Set psCaption to "Function Name"
        End_Object 

        Object oFunctions_Type is a cDbCJGridColumn
            Entry_Item Functions.Type
            Set piWidth to 200
            Set psCaption to "Type"
            Set pbComboButton to True
        End_Object

    End_Object 

    Object oOk_bn is a Button
        Set Label to "&Ok"
        Set Location to 115 106
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send OK of oSelList
        End_Procedure

    End_Object 

    Object oCancel_bn is a Button
        Set Label to "&Cancel"
        Set Location to 115 160
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send Cancel of oSelList
        End_Procedure

    End_Object 

    Object oSearch_bn is a Button
        Set Label to "&Search..."
        Set Location to 115 214
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send Search of oSelList
        End_Procedure

    End_Object 

    Procedure Activating
        Set Icon to "FunctionLibrary.ico"
    End_Procedure

    On_Key Key_Alt+Key_O Send KeyAction of oOk_bn
    On_Key Key_Alt+Key_C Send KeyAction of oCancel_bn
    On_Key Key_Alt+Key_S Send KeyAction of oSearch_bn
Cd_End_Object
