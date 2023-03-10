//TH-Header
//*****************************************************************************************
// Copyright (c)  2002 Michael Kurz
// All rights reserved.
//
// $FileName    : DependencyConf.SL
// $ProjectName : Codemax
// $Authors     : Michael Kurz, Sergey V. Natarov
// $Created     : 06.02.2002  20:38
// $Updated     : 10.05.2017  08:12
//
// Contents:
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Use DFAllEnt.pkg
Use Windows.pkg

Object oDependencyConf is a dbModalPanel

    Set pbSizeToClientArea to False
    Set Label to "Configure dependency scanner"
    Set Size to 200 260
    Set Location to 15 11
    Set piMinSize To 200 260

    Property String  psFile          ""
    Property Integer piHasDependency 0

    Object oExtentions is a Form
        Set Label to "Extentions"
        Set Size to 13 170
        Set Location to 10 75
        Set Label_Col_Offset to 0
        Set Label_Justification_Mode to jMode_Right
        Set peAnchors to anTopLeftRight
    End_Object    // oExtentions

    Object oFolders is a Grid
        Set Size to 77 240
        Set Location to 26 5
        Set Line_Width to 1 0
        Set Form_Width 0 to 235
        Set Header_Label  item 0 to "Folders"
        Set peAnchors to anAll
    End_Object    // oFolders

    Object oOK_bn is a Button
        Set Label to "Ok"
        Set Location to 159 142
        Set peAnchors to anBottomRight
        Procedure OnClick
            Send DoOk
        End_Procedure
    End_Object    // oOK_bn

    Object oCancel_bn is a Button
        Set Label to "Cancel"
        Set Location to 159 196
        Set peAnchors to anBottomRight
        Procedure OnClick
            Send DoCancel
        End_Procedure
    End_Object    // oCancel_bn

    Object oMode is a RadioGroup
        Set Label to "Output to"
        Set Size to 50 77
        Set Location to 104 6
        Set peAnchors to anBottomLeft
        Object Radio1 is a Radio
            Set Label to "Textfile"
            Set Size to 10 39
            Set Location to 10 5
        End_Object    // Radio1
        Object Radio2 is a Radio
            Set Label to "Batchfile"
            Set Size to 10 44
            Set Location to 21 5
        End_Object    // Radio2
        Object Radio3 is a Radio
            Set Label to "Clipboard"
            Set Size to 10 46
            Set Location to 33 5
        End_Object    // Radio1
        Procedure Notify_Select_State integer iToItem integer iFromItem
            Set Object_Shadow_State of (oTxtFileName(Self))     to (iToItem ne 0)
            Set Object_Shadow_State of (oBatchtFileName(Self))   to (iToItem ne 1)
        End_Procedure
    End_Object    // RadioGroup1

    Object oGroup1 is a Group
        Set Size to 50 159
        Set Location to 104 87
        Set peAnchors to anBottomLeftRight
        Object oTxtFileName is a Form
            Set Size to 13 150
            Set Location to 10 5
            Set peAnchors to anTopLeftRight
        End_Object    // oTxtFileName
        Object oBatchtFileName is a Form
            Set Size to 13 150
            Set Location to 26 5
            Set object_shadow_state  to True
            Set peAnchors to anTopLeftRight
        End_Object    // oBatchtFileName
    End_Object

    Procedure DoRead string sFile
        integer iC
        string sLine
        Send Delete_Data to (oFolders(Self))
        Direct_Input sFile
        ReadLn sLine
        Set value of (oExtentions(Self)) item 0     to sLine
        ReadLn sLine
        Set Current_Radio of (oMode(Self))          to sLine
        ReadLn sLine
        Set value of (oTxtFileName(Self)) item 0    to sLine
        ReadLn sLine
        Set value of (oBatchtFileName(Self)) item 0 to sLine
        Repeat
            ReadLn sLine
            If (Not(SEQEOF)) Send Add_Item to (oFolders(Self)) Msg_None sLine
        Until (SEQEOF)
        Close_Input
        For iC from 0 to 10
            Send Add_Item to (oFolders(Self)) Msg_None ""
        End
    End_Procedure
    Procedure DoWrite string sFile
        integer iC
        string  sVal
        Direct_Output sFile
        WriteLn (Value(oExtentions(Self),0))
        WriteLn (Current_Radio(oMode(Self)))
        WriteLn (Value(oTxtFileName(Self),0))
        WriteLn (Value(oBatchtFileName(Self),0))
        For iC from 0 to (Item_Count(oFolders(Self))-1)
            get value of (oFolders(Self)) item iC to sVal
            If sVal ne "" WriteLn sVal
        End
        Close_Output
    End_Procedure

    Procedure popup_group
        Forward Send popup_group
        Send DoRead (psFile(Self))
    End_Procedure

    Procedure DoCancel
        Send Close_Panel
    End_Procedure
    Procedure DoOk
        Send DoWrite (psFile(Self))
        Set piHasDependency to True
        Send Close_Panel
    End_Procedure
    Set locate_mode  to CENTER_ON_SCREEN

    #IFDEF TH_TRANSLATION
    Procedure Translate
        Set Label                           to gILanguage[926]
        Set Label           of oExtentions  to gILanguage[927]
        Set Header_Label    of oFolders 0   to gILanguage[928]
        Set Label           of oOK_bn       to gILanguage[929]
        Set Label           of oCancel_bn   to gILanguage[930]
        Set Label           of oMode        to gILanguage[931]
        Set Label of (Radio1(oMode(Self)))  to gILanguage[932]
        Set Label of (Radio2(oMode(Self)))  to gILanguage[933]
        Set Label of (Radio3(oMode(Self)))  to gILanguage[934]
    End_Procedure
    #ENDIF

    Procedure Activating
        Forward Send Activating
        #IFDEF TH_TRANSLATION
        Send Translate
        #ENDIF
    End_Procedure

End_Object    // oDependencyConf


Function DependencyConfig string sFile returns integer
    Set psFile          of oDependencyConf to sFile
    Set piHasDependency of oDependencyConf to 0
    Send Popup          to oDependencyConf
    Function_Return (piHasDependency(oDependencyConf(Self)))
End_Function