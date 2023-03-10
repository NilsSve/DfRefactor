//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : vdfcr.VW
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: VDF Class Reference
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

// Project Object Structure
//   vdfcr is a dbView
//     Vdfcls_DD is a DataDictionary
//     Vdfprop_DD is a DataDictionary
//     TreeView1 is a TreeView
//       oTreeImageList is a ImageList
//     Grid1 is a Grid
//     Edit1 is a Edit
//     Textbox1 is a Textbox
//     Textbox2 is a Textbox
//     Textbox3 is a Textbox
//     Textbox5 is a Textbox
//     Textbox6 is a Textbox

// Register all objects
Register_Object Edit1
Register_Object Grid1
Register_Object oTreeImageList
Register_Object Textbox1
Register_Object Textbox2
Register_Object Textbox3
Register_Object Textbox5
Register_Object Textbox6
Register_Object TreeView1
Register_Object Vdfcls_DD
Register_Object Vdfprop_DD
Register_Object vdfcr




    Use For_All


    Use DFTreeVw.pkg

    Use VDFCLS.DD
    Use VDFPROP.DD


    ACTIVATE_VIEW Activate_vdfcr FOR vdfcr

    Object vdfcr is a dbView
        Set Label to "Language Quick Reference"
        Set Size to 215 419
        Set Location to 1 3


        Object Vdfcls_DD is a Vdfcls_DataDictionary
        End_Object    // Vdfcls_DD

        Object Vdfprop_DD is a Vdfprop_DataDictionary
            Set DDO_Server to (Vdfcls_DD(self))
            Set Constrain_File to Vdfcls.File_Number
        End_Object    // Vdfprop_DD

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


            Set Size to 192 156
            Set Location to 4 5


            Procedure OnItemChanging Handle hItemNew Handle hItemOld
                Integer iItm
                Forward Send OnItemChanging hItemNew hItemOld
                Get ItemData  Item hItemNew To iItm
                Send Fill_Table to Grid1 iItm
            End_Procedure // OnItemChanging

            Procedure OnCreateTree
                integer hRoot hChld iCItm
                Get RootItem to hRoot
                if (hRoot) Send DoDeleteItem hRoot
                Get AddTreeItem "User Reference" 0 0 0 1 To hRoot
                Get AddTreeItem "Class Reference" hRoot 0 0 1 To hChld
                Set phClassStructure to hChld
                Send AddClassChilds hChld
                Get AddTreeItem "Commands Reference" hRoot 0 0 1 To hChld
                Set phCommandsStructure to hChld
                Get AddTreeItem "Database Reference" hRoot 0 0 1 To hChld
                Set phDatabaseStructure to hChld
                Send AddDBChilds hChld
            End_Procedure

            Procedure AddClassChilds integer hRoot
                integer hChild iRec iRecs
                Get_Attribute DF_FILE_RECORDS_USED of VDFCLS.File_Number to iRecs

                For iRec from 1 to iRecs
                    Clear VDFCLS
                    Move iRec to VDFCLS.RECNUM
                    Find eq VDFCLS by Recnum
                    If ((found)and(VDFCLS.BASE="Y")) Begin
                        Get AddTreeItem (trim(vdfcls.name)) hRoot vdfcls.code 0 1 To hChild
                        Send AddClassTree hChild vdfcls.parent
                    End
                Loop

            End_Procedure

            Procedure AddClassTree integer hRoot number nParent
                integer hChild iRec iRecs
                Get_Attribute DF_FILE_RECORDS_USED of VDFCLS.File_Number to iRecs

                For iRec from 1 to iRecs
                    Clear VDFCLS
                    Move iRec to VDFCLS.RECNUM
                    Find eq VDFCLS by Recnum
                    If ((found) and (vdfcls.code eq nParent)) Begin
                        Get AddTreeItem (trim(vdfcls.name)) hRoot vdfcls.code 0 1 To hChild
                        Send AddClassTree hChild vdfcls.parent
                    End
                Loop

            End_Procedure

            Procedure AddDBChilds integer hRoot
                Integer iFile iCnt hChld
                String sRootname sName
                Moveint 0 To iFile
                Repeat
                    Get_Attribute Df_File_Next_Used     of iFile To iFile
                    If (iFile>0) Begin
                        Get_Attribute Df_File_Root_Name     of iFile To sRootname
                        Get_Attribute DF_FILE_DISPLAY_NAME  of iFile to sName
                        Get AddTreeItem (sRootname+" ("+sName+")") hRoot iFile 0 1 to hChld
                        Send AddDBFields hChld iFile
                    End
                Until iFile Eq 0
            End_Procedure

            Procedure AddDBFields integer hRoot integer iFile
                integer hChld iFld iFlds
                string sFld
                If (iFile) Begin
                    Send Delete_Data

                    Open iFile
                    Get_Attribute DF_FILE_NUMBER_FIELDS of iFile to iFlds
                    For iFld From 0 To iFlds
                        Get_Attribute DF_FIELD_NAME Of iFile iFld to sFld
                        Get AddTreeItem sFld hRoot iFld 0 1 to hChld
                    Loop
                    // Close iFile
                End
            End_Procedure









        End_Object    // TreeView1

        Object Grid1 is a Grid

            Set Select_Mode to No_Select
            Set Scroll_Bar_Visible_State to FALSE
            Set Highlight_Row_state to TRUE


            Set CurrentCellColor to clNavy
            Set CurrentCellTextColor to clWhite
            Set CurrentRowColor to clNavy
            Set CurrentRowTextColor to clWhite
            Set Size to 113 246
            Set Location to 4 164

            Set Line_Width to 3 0

            Set Form_Width    item 0 to 42
            Set Header_Label  item 0 to "Type"

            Set Form_Width    item 1 to 147
            Set Header_Label  item 1 to "Name"

            Set Form_Width    item 2 to 60
            Set Header_Label  item 2 to "Inherit"



            Procedure Fill_Table number nCode
                Number nParent
                integer iCnt bState

                If ((nCode>0)and(bState=0)) Begin
                    Set Dynamic_Update_State To False
                    Send Delete_Data
                    Clear VDFPROP
                    For_All VDFPROP by Index.1
                        Constrain VDFPROP.VDFCLS eq nCode
                        Do
                        If VDFPROP.TYPE eq 1 Send Add_Item 0 "Property"
                        If VDFPROP.TYPE eq 2 Send Add_Item 0 "Procedure"
                        If VDFPROP.TYPE eq 3 Send Add_Item 0 "Function"
                        If VDFPROP.TYPE eq 4 Send Add_Item 0 "Command"
                        If VDFPROP.TYPE eq 5 Send Add_Item 0 "Both"
                        Send Add_Item 0 (Trim(VDFPROP.NAME))
                        Send Add_Item 0 "Self"

                        Get Item_Count to iCnt
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1) to clGreen
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-1) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-1) to clGreen
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-2) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-2) to clGreen
                        Set Entry_State item (iCnt-1)   to false
                        Set Aux_Value   item (iCnt-1)   to VDFPROP.CODE
                        Set Entry_State item (iCnt-1-1) to false
                        Set Aux_Value   item (iCnt-1-1) to VDFPROP.CODE
                        Set Entry_State item (iCnt-1-2) to false
                        Set Aux_Value   item (iCnt-1-2) to VDFPROP.CODE
                    End_For_All
                    Clear VDFCLS
                    Move nCode to VDFCLS.CODE
                    Find eq VDFCLS by Index.3
                    If (found) Begin
                        if ((VDFCLS.MIXIN1<>0)or(VDFCLS.MIXIN2<>0)or(VDFCLS.MIXIN3<>0)or(VDFCLS.MIXIN4<>0)or(VDFCLS.MIXIN5<>0)) Send Add_Mixin_Elements nCode 0
                    End
                    Send AddFromParents nCode
                    Set Dynamic_Update_State To True
                End
            End_Procedure

            Procedure Add_Mixin_Elements number nCode integer iLevel
                Number Mix1 Mix2 Mix3 Mix4 Mix5 Mix6 Mix7 Mix8 Mix9 Mix10 Mix11 Mix12 Mix13 Mix14 Mix15
                String sMix1 sMix2 sMix3 sMix4 sMix5 sMix6 sMix7 sMix8 sMix9 sMix10 sMix11 sMix12 sMix13 sMix14 sMix15
                Clear VDFCLS
                Move nCode to VDFCLS.CODE
                Find eq VDFCLS by Index.3
                If (found) Begin
                    Move VDFCLS.MIXIN1 to Mix1
                    Move VDFCLS.MIXIN2 to Mix2
                    Move VDFCLS.MIXIN3 to Mix3
                    Move VDFCLS.MIXIN4 to Mix4
                    Move VDFCLS.MIXIN5 to Mix5
                    Move VDFCLS.MIXIN6 to Mix6
                    Move VDFCLS.MIXIN7 to Mix7
                    Move VDFCLS.MIXIN8 to Mix8
                    Move VDFCLS.MIXIN9 to Mix9
                    Move VDFCLS.MIXIN10 to Mix10
                    Move VDFCLS.MIXIN11 to Mix11
                    Move VDFCLS.MIXIN12 to Mix12
                    Move VDFCLS.MIXIN13 to Mix13
                    Move VDFCLS.MIXIN14 to Mix14
                    Move VDFCLS.MIXIN15 to Mix15

                    Move VDFCLS.NAME to sMix1
                    Move VDFCLS.NAME to sMix2
                    Move VDFCLS.NAME to sMix3
                    Move VDFCLS.NAME to sMix4
                    Move VDFCLS.NAME to sMix5
                    Move VDFCLS.NAME to sMix6
                    Move VDFCLS.NAME to sMix7
                    Move VDFCLS.NAME to sMix8
                    Move VDFCLS.NAME to sMix9
                    Move VDFCLS.NAME to sMix10
                    Move VDFCLS.NAME to sMix11
                    Move VDFCLS.NAME to sMix12
                    Move VDFCLS.NAME to sMix13
                    Move VDFCLS.NAME to sMix14
                    Move VDFCLS.NAME to sMix15

                    If (MIX1<>0)  Send ProcessMixin MIX1  sMix1 iLevel
                    If (MIX2<>0)  Send ProcessMixin MIX2  sMix2 iLevel
                    If (MIX3<>0)  Send ProcessMixin MIX3  sMix3 iLevel
                    If (MIX4<>0)  Send ProcessMixin MIX4  sMix4 iLevel
                    If (MIX5<>0)  Send ProcessMixin MIX5  sMix5 iLevel
                    If (MIX6<>0)  Send ProcessMixin MIX6  sMix6 iLevel
                    If (MIX7<>0)  Send ProcessMixin MIX7  sMix7 iLevel
                    If (MIX8<>0)  Send ProcessMixin MIX8  sMix8 iLevel
                    If (MIX9<>0)  Send ProcessMixin MIX9  sMix9 iLevel
                    If (MIX10<>0) Send ProcessMixin MIX10 sMix10 iLevel
                    If (MIX11<>0) Send ProcessMixin MIX11 sMix11 iLevel
                    If (MIX12<>0) Send ProcessMixin MIX12 sMix12 iLevel
                    If (MIX13<>0) Send ProcessMixin MIX13 sMix13 iLevel
                    If (MIX14<>0) Send ProcessMixin MIX14 sMix14 iLevel
                    If (MIX15<>0) Send ProcessMixin MIX15 sMix15 iLevel
                End
            End_Procedure

            Procedure ProcessMixin number nCode string sName integer iLevel
                Number nParent
                integer iCnt
                If (nCode>0) Begin
                    Clear VDFPROP
                    For_All VDFPROP by Index.1
                        Constrain VDFPROP.VDFCLS eq nCode
                        Do
                        Move VDFPROP.VDFCLS to VDFCLS.CODE
                        Find eq VDFCLS by index.3
                        If VDFPROP.TYPE eq 1 Send Add_Item 0 "Property"
                        If VDFPROP.TYPE eq 2 Send Add_Item 0 "Procedure"
                        If VDFPROP.TYPE eq 3 Send Add_Item 0 "Function"
                        If VDFPROP.TYPE eq 4 Send Add_Item 0 "Command"
                        If VDFPROP.TYPE eq 5 Send Add_Item 0 "Both"
                        Send Add_Item 0 (Trim(VDFPROP.NAME))
                        if (iLevel) Send Add_Item 0 (sName+", "+Trim(VDFCLS.NAME))
                        Else Send Add_Item 0 (Trim(VDFCLS.NAME))

                        Get Item_Count to iCnt
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1) to clGreen
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-1) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-1) to clGreen
                        If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-2) to clNavy
                        If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-2) to clGreen

                        If (iLevel) Begin
                            Set ItemColor   item (iCnt-1)     to (rgb(229,229,229))
                            Set ItemColor   item (iCnt-1-1)   to (rgb(229,229,229))
                            Set ItemColor   item (iCnt-1-2)   to (rgb(229,229,229))
                        End
                        Else Begin
                            Set ItemColor   item (iCnt-1)     to clWhite
                            Set ItemColor   item (iCnt-1-1)   to clWhite
                            Set ItemColor   item (iCnt-1-2)   to clWhite
                        End

                        Set Entry_State item (iCnt-1)   to false
                        Set Aux_Value   item (iCnt-1)   to VDFPROP.CODE
                        Set Entry_State item (iCnt-1-1) to false
                        Set Aux_Value   item (iCnt-1-1) to VDFPROP.CODE
                        Set Entry_State item (iCnt-1-2) to false
                        Set Aux_Value   item (iCnt-1-2) to VDFPROP.CODE
                    End_For_All
                End
                Clear VDFCLS
                Move nCode to VDFCLS.CODE
                Find eq VDFCLS by Index.3
                If (found) Begin
                    if ((VDFCLS.MIXIN1<>0)or(VDFCLS.MIXIN2<>0)or(VDFCLS.MIXIN3<>0)or(VDFCLS.MIXIN4<>0)or(VDFCLS.MIXIN5<>0)) Send Add_Mixin_Elements nCode 1
                End
            End_Procedure

            Procedure AddFromParents number nCode
                integer iCnt
                Number nPArent
                Clear VDFCLS
                Move nCode to VDFCLS.CODE
                Find eq VDFCLS by Index.3
                If (found) Begin

                    Move VDFCLS.PARENT to nParent

                    While (nParent<>0)

                        Move VDFCLS.PARENT to nParent
                        If (nParent <> 0) Begin
                            Clear VDFPROP
                            For_All VDFPROP by Index.1
                                Constrain VDFPROP.VDFCLS eq nParent
                                Do
                                Move nPArent to VDFCLS.CODE
                                Find eq VDFCLS by index.3
                                If VDFPROP.TYPE eq 1 Send Add_Item 0 "Property"
                                If VDFPROP.TYPE eq 2 Send Add_Item 0 "Procedure"
                                If VDFPROP.TYPE eq 3 Send Add_Item 0 "Function"
                                If VDFPROP.TYPE eq 4 Send Add_Item 0 "Command"
                                If VDFPROP.TYPE eq 5 Send Add_Item 0 "Both"
                                Send Add_Item 0 (Trim(VDFPROP.NAME))
                                Send Add_Item 0 (Trim(VDFCLS.NAME))

                                Get Item_Count to iCnt
                                If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1) to clNavy
                                If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1) to clGreen
                                If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-1) to clNavy
                                If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-1) to clGreen
                                If (VDFPROP.TYPE=1)  Set ItemTextColor item (iCnt-1-2) to clNavy
                                If (VDFPROP.TYPE>1)  Set ItemTextColor item (iCnt-1-2) to clGreen
                                Set ItemColor   item (iCnt-1)   to (rgb(229,229,229))
                                Set Entry_State item (iCnt-1)   to false
                                Set Aux_Value   item (iCnt-1)   to VDFPROP.CODE
                                Set ItemColor   item (iCnt-1-1) to (rgb(229,229,229))
                                Set Entry_State item (iCnt-1-1) to false
                                Set Aux_Value   item (iCnt-1-1) to VDFPROP.CODE
                                Set ItemColor   item (iCnt-1-2) to (rgb(229,229,229))
                                Set Entry_State item (iCnt-1-2) to false
                                Set Aux_Value   item (iCnt-1-2) to VDFPROP.CODE
                            End_For_All

                    Clear VDFCLS
                    Move nParent to VDFCLS.CODE
                    Find eq VDFCLS by Index.3
                    If (found) Begin
                        if ((VDFCLS.MIXIN1<>0)or(VDFCLS.MIXIN2<>0)or(VDFCLS.MIXIN3<>0)or(VDFCLS.MIXIN4<>0)or(VDFCLS.MIXIN5<>0)) Send Add_Mixin_Elements nParent 1
                    End

                            Send AddFromParents nParent
                        End // if parent
                    Loop
                End
            End_Procedure

            //procedure item_change integer fromi integer toi returns integer
            //    local integer rval iData
            //    local string sVal
            //    Get Aux_Value item toi to iData
            //    Move iData to VDFPROP.CODE
            //    Find eq VDFPROP by Index.3
            //    If (found) Begin
            //        Send Delete_Data to Edit1
            //        Set value of Edit1 item 0 to (Trim(VDFPROP.DESCR))
            //    End
            //    forward get msg_item_change fromi toi to rval
            //    procedure_return rval
            //end_procedure







        End_Object    // Grid1

        Object Edit1 is a Edit

            Set Object_Shadow_State To True

            Set Size to 38 246
            Set Location to 158 164



        End_Object    // Edit1

        Object Textbox1 is a Textbox
            Set Label to "Legend:"
            Set Location to 116 164
            Set Size to 10 27
            Set TypeFace to "MS Sans Serif"
        End_Object    // Textbox1

        Object Textbox2 is a Textbox
            Set Auto_Size_State to FALSE
            Set Color to clNavy
            Set Location to 119 194
            Set Size to 7 7
            Set Border_Style to Border_Normal
            Set TypeFace to "MS Sans Serif"
        End_Object    // Textbox2

        Object Textbox3 is a Textbox
            Set Label to "- properties"
            Set Location to 116 203
            Set Size to 10 36
            Set TypeFace to "MS Sans Serif"
        End_Object    // Textbox3

        Object Textbox5 is a Textbox
            Set Auto_Size_State to FALSE
            Set Color to clGreen
            Set Location to 119 242
            Set Size to 7 7
            Set Border_Style to Border_Normal
            Set TypeFace to "MS Sans Serif"
        End_Object    // Textbox5

        Object Textbox6 is a Textbox
            Set Label to "- procedures & functions"
            Set Location to 116 252
            Set Size to 10 73
            Set TypeFace to "MS Sans Serif"
        End_Object    // Textbox6

    End_Object    // vdfcr





