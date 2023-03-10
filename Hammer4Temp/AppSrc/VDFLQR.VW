//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : VDFLQR.VW
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: VDF Quick Reference
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

// Project Object Structure
//   oQR is a dbView
//     Vdfcls_DD is a DataDictionary
//     Asdb_DD is a DataDictionary
//     TreeView1 is a TreeView
//       oTreeImageList is a ImageList
//     dbGrid1 is a dbGrid
//     dbForm2 is a dbForm
//     Form1 is a Form
//     dbContainer3d1 is a dbContainer3d
//       The_Table is a dbGrid

// Register all objects
Register_Object Asdb_DD
Register_Object dbContainer3d1
Register_Object dbForm2
Register_Object dbGrid1
Register_Object Form1
Register_Object oQR
Register_Object oTreeImageList
Register_Object The_Table
Register_Object TreeView1
Register_Object Vdfcls_DD




Function Element_Type Global integer itype returns string
    If (iTYPE=0)  Function_Return "Undefined"
    If (iTYPE=1)  Function_Return "Property"
    If (iTYPE=2)  Function_Return "Procedure"
    If (iTYPE=3)  Function_Return "Function"
    If (iTYPE=4)  Function_Return "Command"
    If (iTYPE=5)  Function_Return "Both"
    If (iTYPE>5)  Function_Return "Unknown"
End_Function



Use DFTreeVw.pkg

Use VDFCLS.DD
Use ASDB.DD


ACTIVATE_VIEW Activate_oQR FOR oQR

Object oQR is a dbView
    Set Label to "VDF Quick Reference"
    Set Size to 215 420
    Set Location to 1 3


    Object Vdfcls_DD is a Vdfcls_DataDictionary
    End_Object    // Vdfcls_DD

    Object Asdb_DD is a Asdb_DataDictionary
        Set DDO_Server to (Vdfcls_DD(self))
        Set Constrain_File to Vdfcls.File_Number


        Property integer Class_Code        0

        Procedure OnConstrain
            Number nCode
            Get Class_Code to nCode
            If (nCode<>0) Constrain ASDB.VDFCLS eq nCode
        End_Procedure


    End_Object    // Asdb_DD

    Set Main_DD to (Vdfcls_DD(self))
    Set Server to (Vdfcls_DD(self))


    Object TreeView1 is a TreeView

        Property integer phClassStructure           0
        Property integer phCommandsStructure        0
        Property integer phDatabaseStructure        0

        Object oTreeImageList is an ImageList
            Set Bitmap_Size    To 16 16
            Set ImageList_Size To 2  0
            Send ImageList_Add 'openfold.bmp'  //0
            Send ImageList_Add 'closfold.bmp' //1
            Send ImageList_Create // create the ImageList
        End_Object

        Set ImageListObject To (oTreeImageList(self))


        Set Size to 73 253
        Set Location to 2 158


        //Procedure OnItemChanging Handle hItemNew Handle hItemOld
        //    Integer iItm
        //    Forward Send OnItemChanging hItemNew hItemOld
        //    Get ItemData  Item hItemNew To iItm

        //    Set Class_Code of ASDB_DD to iItm
        //    Send Rebuild_Constraints to ASDB_DD
        //    Send Beginning_Of_Data to dbGrid1
        //End_Procedure // OnItemChanging

        //Procedure OnCreateTree
        //    Local integer hRoot hChld iCItm
        //    Get RootItem to hRoot
        //    if (hRoot) Send DoDeleteItem hRoot
        //    Get AddTreeItem "User Reference" 0 0 0 1 To hRoot
        //    Get AddTreeItem "Class Reference" hRoot 0 0 1 To hChld
        //    Set phClassStructure to hChld
        //    Send AddClassChilds hChld
        //    Get AddTreeItem "Commands Reference" hRoot 0 0 1 To hChld
        //    Set phCommandsStructure to hChld
        //    Get AddTreeItem "Database Reference" hRoot 0 0 1 To hChld
        //    Set phDatabaseStructure to hChld
        //    Send AddDBChilds hChld
        //End_Procedure

        //Procedure AddClassChilds integer hRoot
        //    Local integer hChild iRec iRecs
        //    Get_Attribute DF_FILE_RECORDS_USED of VDFCLS.File_Number to iRecs

        //    For iRec from 1 to iRecs
        //        Clear VDFCLS
        //        Move iRec to VDFCLS.RECNUM
        //        Find eq VDFCLS by Recnum
        //        If ((found)and(VDFCLS.BASE="Y")) Begin
        //            Get AddTreeItem (trim(vdfcls.name)) hRoot vdfcls.code 0 1 To hChild
        //            Send AddClassTree hChild vdfcls.parent
        //        End
        //    Loop

        //End_Procedure

        //Procedure AddClassTree integer hRoot number nParent
        //    Local integer hChild iRec iRecs
        //    Get_Attribute DF_FILE_RECORDS_USED of VDFCLS.File_Number to iRecs

        //    For iRec from 1 to iRecs
        //        Clear VDFCLS
        //        Move iRec to VDFCLS.RECNUM
        //        Find eq VDFCLS by Recnum
        //        If ((found) and (vdfcls.code eq nParent)) Begin
        //            Get AddTreeItem (trim(vdfcls.name)) hRoot vdfcls.code 0 1 To hChild
        //            Send AddClassTree hChild vdfcls.parent
        //        End
        //    Loop

        //End_Procedure

        //Procedure AddDBChilds integer hRoot
        //    Local Integer iFile iCnt hChld
        //    Local String sRootname sName
        //    Moveint 0 To iFile
        //    Repeat
        //        Get_Attribute Df_File_Next_Used     of iFile To iFile
        //        If (iFile>0) Begin
        //            Get_Attribute Df_File_Root_Name     of iFile To sRootname
        //            Get_Attribute DF_FILE_DISPLAY_NAME  of iFile to sName
        //            Get AddTreeItem (sRootname+" ("+sName+")") hRoot iFile 0 1 to hChld
        //            Send AddDBFields hChld iFile
        //        End
        //    Until iFile Eq 0
        //End_Procedure

        //Procedure AddDBFields integer hRoot integer iFile
        //    local integer hChld iFld iFlds
        //    local string sFld
        //    If (iFile) Begin
        //        Send Delete_Data

        //        Open iFile
        //        Get_Attribute DF_FILE_NUMBER_FIELDS of iFile to iFlds
        //        For iFld From 0 To iFlds
        //            Get_Attribute DF_FIELD_NAME Of iFile iFld to sFld
        //            Get AddTreeItem sFld hRoot iFld 0 1 to hChld
        //        Loop
        //        // Close iFile
        //    End
        //End_Procedure



    End_Object    // TreeView1

    Object dbGrid1 is a dbGrid

        Set Select_Mode to No_Select
        Set Scroll_Bar_Visible_State to FALSE
        Set Highlight_Row_state to TRUE
        Set Allow_bottom_add_state to False
        Set Allow_insert_add_state to False
        Set Allow_top_add_state to False


        Set Main_File to Asdb.File_Number
        Set Server to (Asdb_DD(self))
        Set Ordering to 3
        Set Size to 82 254
        Set Location to 79 157
        Set CurrentRowColor to clNavy
        Set CurrentRowTextColor to clWhite
        Set CurrentCellColor to clNavy
        Set CurrentCellTextColor to clWhite
        Set Wrap_State to TRUE

        Begin_Row
            Entry_Item (Element_Type(Asdb.Type))
            Entry_Item Asdb.Name
            Entry_Item Asdb.Pclassname
        End_Row

        Set Form_Width    item 0 to 45
        Set Header_Label  item 0 to "Type"

        Set Form_Width    item 1 to 107
        Set Header_Label  item 1 to "Name"

        Set Form_Width    item 2 to 104
        Set Header_Label  item 2 to "Inheritance"



        Procedure Entry_Display Integer iFile Integer iType
            integer iCnt

            Get Item_Count to iCnt

            If (iCnt) Begin
                Get Base_Item to iCnt
                Set Item_Shadow_State item (iCnt)   to false

                If (ASDB.TYPE=1)  Set ItemTextColor item (iCnt) to clNavy
                If (ASDB.TYPE>1)  Set ItemTextColor item (iCnt) to clGreen
                If (ASDB.TYPE=1)  Set ItemTextColor item (iCnt+1) to clNavy
                If (ASDB.TYPE>1)  Set ItemTextColor item (iCnt+1) to clGreen
                If (ASDB.TYPE=1)  Set ItemTextColor item (iCnt+2) to clNavy
                If (ASDB.TYPE>1)  Set ItemTextColor item (iCnt+2) to clGreen

                Set Entry_State  item (iCnt)   to false
                Set Entry_State  item (iCnt+1) to false
                Set Entry_State  item (iCnt+2) to false
            End

            Forward Send Entry_Display iFile iType

        End_Procedure // Entry_Display





    End_Object    // dbGrid1

    Object dbForm2 is a dbForm

        Set Enabled_State to False

        Set Label to "Primary code:"
        Set Size to 13 206
        Set Location to 164 205
        Set Label_Col_Offset to 2
        Set Label_Justification_Mode to jMode_Right



    End_Object    // dbForm2

    Object Form1 is a Form

        Set Enabled_State to False

        Set Label to "Get code:"
        Set Size to 13 206
        Set Location to 182 205
        Set Label_Col_Offset to 2
        Set Label_Justification_Mode to jMode_Right



    End_Object    // Form1

    Object dbContainer3d1 is a dbContainer3d
        Set Border_Style to Border_ClientEdge
        Set Size to 194 150
        Set Location to 2 4
        Set Color to clWhite
        Object The_Table is a dbGrid

            Set allow_insert_add_state to FALSE
            Set allow_top_add_state to FALSE
            Set allow_bottom_add_state to FALSE
            Set GridLine_Mode to GRID_VISIBLE_NONE
            Set Border_Style to Border_None
            Set Header_Visible_State to False

            Set Main_File to Vdfcls.File_Number
            Set Ordering to 1
            Set Size to 191 143
            Set Location to 1 2
            Set Color to clWhite
            Set CurrentRowColor to clNavy
            Set CurrentRowTextColor to clWhite
            Set CurrentCellColor to clNavy
            Set CurrentCellTextColor to clWhite
            Set Wrap_State to TRUE

            Begin_Row
                Entry_Item ("")
                Entry_Item Vdfcls.Name
            End_Row

            Set Form_Width    item 0 to 12
            Set Header_Label  item 0 to ""

            Set Form_Width    item 1 to 121
            Set Header_Label  item 1 to "Name"



            Procedure Request_Delete
                Send Stop_Box "You can't delete records here."
            End_Procedure

            Procedure Entry_Display Integer iFile Integer iType
                integer iClr iItem

                // Send Change_Row_Color

                Get Base_Item to iItem // first item of the current row
                Set Entry_State item iItem to False
                Set Entry_State item (iItem+1) to False

                If (VDFCLS.BITMAP<>"") Set Form_Bitmap item iItem to (Trim(VDFCLS.BITMAP))

                Forward Send Entry_Display iFile iType

            End_Procedure // Entry_Display

            Procedure Adjust_Row_Height
                Set Form_Height item 0 to 11
            End_Procedure

            Send Adjust_Row_Height







        End_Object    // The_Table

    End_Object    // dbContainer3d1





End_Object    // oQR




