//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : Parents.SL
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: Parents List
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Use VDFCLS.DD

Object oPL is a dbModalPanel
    Set Label to "Parents List"
    Set Size to 244 291
    Set Location to 3 5
    Set piMinSize to 244 291

    Object Vdfcls_DD is a Vdfcls_DataDictionary
    End_Object    // Vdfcls_DD

    Set Main_DD to (Vdfcls_DD(self))
    Set Server to (Vdfcls_DD(self))


    Object oSelList is a dbList

        Set auto_export_state to false
        Set export_item_state to true
        Set auto_column_state to false
        Set export_column to 1

        Set Main_File to Vdfcls.File_Number
        Set Ordering to 1
        Set Size to 159 280
        Set Location to 6 6

        Begin_Row
            Entry_Item Vdfcls.Name
            Entry_Item Vdfcls.Code
        End_Row

        Set Form_Width 0 to 224
        Set Header_Label  item 0 to "Name"

        Set Form_Width 1 to 52
        Set Header_Label  item 1 to "Code"
        Set peAnchors to anAll

    End_Object    // oSelList

    Object oOK_bn is a Button
        Set Label to "&OK"
        Set Location to 223 127
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send OK To oSelList
        End_Procedure

    End_Object    // oOK_bn

    Object oCancel_bn is a Button
        Set Label to "&Cancel"
        Set Location to 223 181
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send Cancel To oSelList
        End_Procedure

    End_Object    // oCancel_bn

    Object oSearch_bn is a Button
        Set Label to "&Search..."
        Set Location to 223 237
        Set peAnchors to anBottomRight

        Procedure OnClick
            Send Search To oSelList
        End_Procedure

    End_Object    // oSearch_bn

    Object dbEdit1 is a dbEdit

        Set Object_Shadow_State To True

        Entry_Item Vdfcls.Descr
        Set Size to 49 280
        Set Location to 170 6
        Set peAnchors to anBottomLeftRight

    End_Object    // dbEdit1


    On_Key Key_Alt+Key_O Send KeyAction To oOk_bn
    On_Key Key_Alt+Key_C Send KeyAction To oCancel_bn
    On_Key Key_Alt+Key_S Send KeyAction To oSearch_bn

End_Object    // oPL

