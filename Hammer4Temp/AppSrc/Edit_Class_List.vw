//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : Edit_Class_List.vw
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: Edit Class List
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

// Project Object Structure
//   Edit_Class_List is a dbView
//     Vdfcls_DD is a DataDictionary
//     The_Table is a dbGrid
//     dbEdit1 is a dbEdit
//     Button1 is a Button
//     ComboForm1 is a ComboForm
//     Button2 is a Button

// Register all objects
Register_Object Button1
Register_Object Button2
Register_Object ComboForm1
Register_Object dbEdit1
Register_Object Edit_Class_List
Register_Object The_Table
Register_Object Vdfcls_DD


Use vWin32fh.pkg

Use dfClient.pkg
Use DataDict.pkg
Use dfTable.pkg
Use dfTxtWin.pkg
Use Windows.pkg
Use dfCmbFrm.pkg

Use VDFCLS.DD


ACTIVATE_VIEW Activate_Edit_Class_List FOR Edit_Class_List

Object Edit_Class_List is a dbView
  Set Label to "Edit Class List"
  Set Location to 2 3
  Set Size to 250 355
    Set Border_Style to Border_Thick
    Set piMinSize to 250 355
    Set Maximize_Icon to True
    Set Minimize_Icon to False


    Object Vdfcls_DD is a Vdfcls_DataDictionary


        Property integer pbDontShowMNS        FALSE

        Procedure OnConstrain
            integer bShow
            Get pbDontShowMNS to bShow
            If (bShow) begin
                Constrain VDFCLS.TYPE ne "M"
                Constrain VDFCLS.TYPE ne "S"
            End
        End_Procedure

    End_Object    // Vdfcls_DD

    Set Main_DD to (Vdfcls_DD(self))
    Set Server to (Vdfcls_DD(self))


    Object The_Table is a dbGrid

        Set allow_insert_add_state to FALSE
        Set allow_top_add_state to FALSE
        Set allow_bottom_add_state to FALSE
        Set GridLine_Mode to GRID_VISIBLE_HORZ
        Set peResizeColumn to rcAll

        Set Main_File to Vdfcls.File_Number
        Set Ordering to 1
        Set Size to 188 345
        Set Location to 5 5
        Set Color to clWhite
        Set CurrentRowColor to clNavy
        Set CurrentRowTextColor to clWhite
        Set CurrentCellColor to clNavy
        Set CurrentCellTextColor to clWhite
        Set Wrap_State to TRUE

        Begin_Row
            Entry_Item ("")
            Entry_Item Vdfcls.Name
            Entry_Item Vdfcls.Bitmap
            Entry_Item Vdfcls.Bitmap24
            Entry_Item Vdfcls.Type
            Entry_Item Vdfcls.Base
        End_Row

        Set Form_Width    item 0 to 12
        Set Header_Label  item 0 to ""

        Set Form_Width    item 1 to 121
        Set Header_Label  item 1 to "Name"

        Set Form_Width    item 2 to 82
        Set Header_Label  item 2 to "Bitmap"

        Set Form_Width    item 3 to 80
        Set Header_Label  item 3 to "Bitmap24"

        Set Form_Width    item 4 to 25
        Set Header_Label  item 4 to "Type"

        Set Form_Width    item 5 to 20
        Set Header_Label  item 5 to "Base"
        Set Column_Checkbox_State  item 5 to True
        Set peAnchors to anAll



        Procedure Request_Delete
            Send Stop_Box "You can't delete records here."
        End_Procedure

        Procedure Entry_Display Integer iFile Integer iType
            integer iItem

            // Send Change_Row_Color

            Get Base_Item to iItem // first item of the current row
            Set Entry_State item iItem to False
            //Set ItemColor   Item iItem to clBtnFace
            Set Entry_State item (iItem+1) to False

            If (VDFCLS.BITMAP<>"") Set Form_Bitmap item iItem to (Trim(VDFCLS.BITMAP))

            Forward Send Entry_Display iFile iType

        End_Procedure // Entry_Display

        Procedure Adjust_Row_Height
            Set Form_Height item 0 to 12
        End_Procedure

        Send Adjust_Row_Height





    End_Object    // The_Table

    Object dbEdit1 is a dbEdit

        Set Enabled_State to False

        Entry_Item Vdfcls.Descr
        Set Size to 32 345
        Set Location to 195 5
        Set peAnchors to anBottomLeftRight



    End_Object    // dbEdit1

    Object Button1 is a Button

        Property String IDE_Classes_File        "IDEClasses.dfc"

        Set Label to "Load Bitmaps"
        Set Size to 14 60
        Set Location to 230 290
        Set peAnchors to anBottomRight


        Procedure OnClick
            Set Dynamic_Update_State of The_Table to FALSE
            Set Dynamic_Update_State of dbEdit1 to FALSE
            Send Load_Class_Bitmaps
            Set Dynamic_Update_State of The_Table to TRUE
            Set Dynamic_Update_State of dbEdit1 to TRUE
            Send Beginning_Of_Data To The_Table
            Send Info_Box "Bitmaps loaded!" "Information"
        End_Procedure // OnClick

        Procedure Load_Class_Bitmaps
            Send Load_Global_Bitmaps
            Send Load_Local_Bitmaps
        End_Procedure

        Procedure Load_Global_Bitmaps
            String sPath sFile sTmp sCls sBMP
            date dToday
            Sysdate4 dToday
            // VDF root dir
            Get IDE_Classes_File to sFile
            get_profile_string "DEFAULTS" "VDFROOTDIR" To sPath
            Get vFolderFormat sPath To sPath
            Move (sPath+"Usr\Global\IdeSrc\"+sFile) to sPath
            Direct_Input sPath
            Direct_Output "LOADBMP.TXT"
            Writeln "================================================================"
            Writeln "Bitmaps Loading Protocol on " dToday
            Writeln "Following Global classes not found:"
            Writeln
            While [not seqeof]
                Readln sCls sBMP sTmp

                If (sBmp<>"") Begin
                    Replace '"' in sCls with ""
                    Replace '"' in sCls with ""
                    Replace '"' in sBMP with ""
                    Replace '"' in sBMP with ""
                    Move (Trim(sCls)) to sCls
                    Move (Trim(sBMP)) to sBMP
                    Send Clear to VDFCLS_DD
                    Move (Uppercase(sCls)) to VDFCLS.NAME
                    Send Find to VDFCLS_DD EQ 1
                    If (found) Begin
                        Reread VDFCLS
                        Move (Uppercase(sBmp)) to VDFCLS.BITMAP24
                        SaveRecord VDFCLS
                        Unlock
                    End
                    Else Writeln sCls
                End


            Loop
            Writeln "================================================================"
            Writeln
            Close_Input
            Close_Output
        End_Procedure

        Procedure Load_Local_Bitmaps
            String sPath sFile sTmp sCls sBMP sWrk
            date dToday
            Sysdate4 dToday
            // VDF root dir
            Get IDE_Classes_File to sFile
            get_profile_string "WORKSPACES" "CURRENTWORKSPACE" To sWrk
            If (sWrk="") Begin
              Get_Profile_String "Workspaces" "Current WorkSpace" To sWrk
            End
            get_profile_string ("WORKSPACES\"+sWrk) "IDESRCPATH" To sPath
            Get vFolderFormat sPath To sPath
            Move (sPath+sFile) to sPath
            Direct_Input sPath
            Append_Output "LOADBMP.TXT"
            Writeln "================================================================"
            Writeln "Bitmaps Loading Protocol on " dToday
            Writeln "Following Local classes not found:"
            Writeln
            While [not seqeof]
                Readln sCls sBMP sTmp

                If (sBmp<>"") Begin
                    Replace '"' in sCls with ""
                    Replace '"' in sCls with ""
                    Replace '"' in sBMP with ""
                    Replace '"' in sBMP with ""
                    Move (Trim(sCls)) to sCls
                    Move (Trim(sBMP)) to sBMP
                    Send Clear to VDFCLS_DD
                    Move (Uppercase(sCls)) to VDFCLS.NAME
                    Send Find to VDFCLS_DD EQ 1
                    If (found) Begin
                        Reread VDFCLS
                        Move (Uppercase(sBmp)) to VDFCLS.BITMAP24
                        SaveRecord VDFCLS
                        Unlock
                    End
                    Else Writeln sCls
                End


            Loop
            Writeln "================================================================"
            Writeln
            Close_Input
            Close_Output
        End_Procedure


    End_Object    // Button1

    Object ComboForm1 is a ComboForm
        Set Size to 13 133
        Set Location to 230 5
        Set Form_Border to 0
        Set peAnchors to anBottomLeft


        Procedure Combo_Fill_List
            Send Combo_Add_Item ""
            Send Combo_Add_Item "Show All"
            Send Combo_Add_Item "Don't show Support Classes"
            Set Entry_State item 0 To FALSE
        End_Procedure

        Procedure OnChange
            String sShow
            Get value item 0 To sShow
            If "Support Classes" in sShow Set pbDontShowMNS of (VDFCLS_DD(Self)) to TRUE
            If "Show All" in sShow Set pbDontShowMNS of (VDFCLS_DD(Self)) to FALSE
            If (sShow="") Set pbDontShowMNS of (VDFCLS_DD(Self)) to FALSE
            Send Rebuild_Constraints to (VDFCLS_DD(Self))
            Send Beginning_Of_Data to The_Table
        End_Procedure



    End_Object    // ComboForm1

    Object Button2 is a Button
        Set Label to "&Compiler"
        Set Location to 230 236
        Set peAnchors to anBottomRight


        Use ASDBC.DG

        Procedure OnClick
            Send PopUp to (oASDBC(Self))
        End_Procedure // OnClick


    End_Object    // Button2

End_Object    // Edit_Class_List

