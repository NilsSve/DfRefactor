//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : Class_Explorer.vw
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: Class Explorer
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Use proppage.dg
Function Element_Type Global Integer itype Returns String
    If (iTYPE=0)  Function_Return "Undefined"
    If (iTYPE=1)  Function_Return "Property"
    If (iTYPE=2)  Function_Return "Procedure"
    If (iTYPE=3)  Function_Return "Function"
    If (iTYPE=4)  Function_Return "Command"
    If (iTYPE=5)  Function_Return "Both"
    If (iTYPE>5)  Function_Return "Unknown"
End_Function
//#DEFINE IS$HAMMER$TOOL 1

Use vdfcls.dd
Use ASDB.DD

Activate_View Activate_Class_Explorer for Class_Explorer
Object Class_Explorer Is a dbView

    Set pbSizeToClientArea to False
    Property Integer piEditView        0
    Property Integer piEditLine        0
    Property Integer piEditCol         0

    Set Border_Style To Border_Thick
    Set Maximize_Icon To TRUE
    Set Label To "Class Explorer"
    Set Size to 225 326
    Set Location to 3 4
    Set piMinSize to 225 326

    Object Vdfcls_DD Is a Vdfcls_datadictionary
        Procedure onConstrain
            Constrain VDFCLS.BASE Eq "Y"
        End_Procedure
    End_Object    // Vdfcls_DD

    Object Asdb_DD Is a Asdb_DataDictionary
        Set DDO_Server To (Vdfcls_DD(Self))
        Set Constrain_File To Vdfcls.File_Number
    End_Object    // Asdb_DD

    Set Main_DD To (Vdfcls_DD(Self))
    Set Server To (Vdfcls_DD(Self))

    Object dbContainer3d2 Is a dbContainer3d
        Set Size To 70 133
        Set Location To 2 3
        Set Color To clWhite
        Set Border_Style To Border_ClientEdge
        Object The_Table Is a dbGrid

            Set Read_Only_State To True
            Set allow_insert_add_state To FALSE
            Set allow_top_add_state To FALSE
            Set allow_bottom_add_state To FALSE
            Set GridLine_Mode To GRID_VISIBLE_NONE
            Set Border_Style To Border_None
            Set Header_Visible_State To False
            Set Scroll_Bar_Visible_State To False

            On_Key Key_Enter Send switch To dbGrid1

            Use agt.dg
            On_Key Key_Alt+Key_T Send pCall

            Procedure pCall
                Send PopUp To oAGTD VDFCLS.FILE_NUMBER
            End_Procedure

            Set Main_File To Vdfcls.File_Number
            Set Ordering To 1
            Set Size To 65 127
            Set Location To 2 2
            Set Color To clWhite
            Set CurrentRowColor To clLtGray
            Set CurrentRowTextColor To clWhite
            Set CurrentCellColor To clLtGray
            Set CurrentCellTextColor To clWhite
            Set Highlight_Row_state To FALSE
            Set Wrap_State To TRUE

            Begin_Row
                Entry_Item ("")
                Entry_Item Vdfcls.Name
            End_Row

            Set Form_Width    Item 0 To 13
            Set Header_Label  Item 0 To ""

            Set Form_Width    Item 1 To 106
            Set Header_Label  Item 1 To "Name"



            Procedure OnKillFocus
                Integer iItm
                Get Current_Item To iItm
                Set ItemColor Item iItm To clLtGray
            End_Procedure

            Procedure OnSetFocus
                Integer iItm
                Get Current_Item To iItm
                Set ItemColor Item iItm To clWhite
            End_Procedure

            Procedure Request_Delete
                Send Stop_Box "You can't delete records here."
            End_Procedure

            Procedure Entry_Display Integer iFile Integer iType
                Integer iItem

                // Send Change_Row_Color

                Get Base_Item To iItem // first item of the current row
                Set Entry_State Item iItem To False
                Set Entry_State Item (iItem+1) To False

                If (VDFCLS.BITMAP<>"") Set Form_Bitmap Item iItem To (Trim(VDFCLS.BITMAP))

                Forward Send Entry_Display iFile iType

            End_Procedure // Entry_Display

            Procedure Adjust_Row_Height
                Set Form_Height Item 0 To 12
            End_Procedure

            Send Adjust_Row_Height

        End_Object    // The_Table

    End_Object    // dbContainer3d2

    Object dbGrid1 Is a dbGrid

        Property Integer peResizeColumn        4
        Property Integer piResizeColumn        1
        Property Integer piLastResizedColumn         0

        Set Select_Mode To No_Select
        Set Scroll_Bar_Visible_State To FALSE
        Set Highlight_Row_state To TRUE
        Set Allow_bottom_add_state To False
        Set Allow_insert_add_state To False
        Set Allow_top_add_state To False
        Set Read_Only_State To True
        Set peResizeColumn to rcAll

        Set Main_File To Asdb.File_Number
        Set Server To (Asdb_DD(Self))
        Set Ordering To 3
        Set Size to 83 310
        Set Location to 75 3
        Set Color To clWhite
        Set CurrentRowColor To clNavy
        Set CurrentRowTextColor To clWhite
        Set CurrentCellColor To clNavy
        Set CurrentCellTextColor To clWhite
        Set Wrap_State To TRUE

        Begin_Row
            Entry_Item (Element_Type(Asdb.Type))
            Entry_Item Asdb.Name
            Entry_Item Asdb.Pclassname
        End_Row

        Set Form_Width    Item 0 To 45
        Set Header_Label  Item 0 To "Type"

        Set Form_Width    Item 1 To 136
        Set Header_Label  Item 1 To "Name"

        Set Form_Width    Item 2 To 135
        Set Header_Label  Item 2 To "Inheritance"
        Set peAnchors to anAll



        Procedure Entry_Display Integer iFile Integer iType
            Integer iCnt

            Get Item_Count To iCnt

            If (iCnt) Begin
                Get Base_Item To iCnt
                Set Item_Shadow_State Item (iCnt)   To false

                If (ASDB.Type=1)  Set ItemTextColor Item (iCnt) To clNavy
                If (ASDB.Type>1)  Set ItemTextColor Item (iCnt) To clGreen

                If (ASDB.PCLASS=0)  Set ItemColor Item (iCnt) To clWhite
                Else Set ItemColor Item (iCnt) To (rgb(230,230,230))

                If (ASDB.Type=1)  Set ItemTextColor Item (iCnt+1) To clNavy
                If (ASDB.Type>1)  Set ItemTextColor Item (iCnt+1) To clGreen

                If (ASDB.PCLASS=0)  Set ItemColor Item (iCnt+1) To clWhite
                Else Set ItemColor Item (iCnt+1) To (rgb(230,230,230))

                If (ASDB.Type=1)  Set ItemTextColor Item (iCnt+2) To clNavy
                If (ASDB.Type>1)  Set ItemTextColor Item (iCnt+2) To clGreen

                If (ASDB.PCLASS=0)  Set ItemColor Item (iCnt+2) To clWhite
                Else Set ItemColor Item (iCnt+2) To (rgb(230,230,230))

                Set Entry_State  Item (iCnt)   To false
                Set Entry_State  Item (iCnt+1) To false
                Set Entry_State  Item (iCnt+2) To false
            End
            Send Update_Label To Class_Explorer (Trim(VDFCLS.NAME))
            Send ShowCode To Form1
            Forward Send Entry_Display iFile iType

        End_Procedure // Entry_Display

        Procedure Set line_width Integer iCols Integer iRows
            // This fixes the problem of resize lists and then displaying
            // the wrong Number Of lines...
            Forward Set line_width To iCols (displayable_rows(Self))
        End_Procedure

    End_Object    // dbGrid1

    Object Form1 Is a Form

        Property Integer piLabelGuiLocationY           0
        Property Integer piLabelGuiLocationX           0

        Set Enabled_State To False


        Set Size To 13 257
        Set Location to 188 3
        Set Label_Col_Offset To 2
        Set Label_Justification_Mode To jMode_Right
        Set peAnchors to anBottomLeftRight


        Procedure ShowCode
            String sCode
            Get fCodeSource To sCode
            Set Value Item 0 To (Trim(sCode))
        End_Procedure

        Function fCodeSource Returns String
            String sCode sParam sRet
            If (Trim(ASDB.SETCODE)<>"") Begin
                Get Process_Template ASDB.SETCODE To sCode
                Function_Return sCode
            End
            Else Begin
                If ((ASDB.Type=1)And(Trim(ASDB.GETCODE)<>"")) Begin
                    Get Process_Template ASDB.GETCODE To sCode
                    Function_Return sCode
                End
                If (ASDB.Type=2) Begin
                    Get Proc_Params To sParam
                    Function_Return ("Send "+Trim(ASDB.NAME)+" "+sParam)
                End
                If (ASDB.Type=3) Begin
                    Get Proc_Params To sParam
                    Get Proc_Ret    To sRet
                    If (Trim(ASDB.GETCODE)="") Function_Return ("Get "+Trim(ASDB.NAME)+" "+sParam+" to "+sRet)
                    Else Begin
                        Get Process_Template ASDB.GETCODE To sCode
                        Function_Return sCode
                    End
                End
            End
        End_Procedure

        Function Process_Template String sTempl Returns String
            String sPT
            Get Parse_Param 1 To sPT
            Replace "{Par1}" In sTempl with sPT
            Get Parse_Param 2 To sPT
            Replace "{Par2}" In sTempl with sPT
            Get Parse_Param 3 To sPT
            Replace "{Par3}" In sTempl with sPT
            Get Parse_Param 4 To sPT
            Replace "{Par4}" In sTempl with sPT
            Get Parse_Param 5 To sPT
            Replace "{Par5}" In sTempl with sPT
            Function_Return sTempl
        End_Function

        Function Proc_Params Returns String
            String sParam sPT sPT1 sPT2 sPT3 sPT4 sPT5
            Move "" To sParam
            Move "" To sPT

            If (ASDB.PAR1T<>0) Get Parse_Param 1 To sPT1
            If (sPT1<>"") Move (sPT+sPT1) To sPT
            If (ASDB.PAR2T<>0) Get Parse_Param 2 To sPT2
            If (sPT2<>"") Move (sPT+" "+sPT2) To sPT
            If (ASDB.PAR3T<>0) Get Parse_Param 3 To sPT3
            If (sPT3<>"") Move (sPT+" "+sPT3) To sPT
            If (ASDB.PAR4T<>0) Get Parse_Param 4 To sPT4
            If (sPT4<>"") Move (sPT+" "+sPT4) To sPT
            If (ASDB.PAR5T<>0) Get Parse_Param 5 To sPT5
            If (sPT5<>"") Move (sPT+" "+sPT5) To sPT
            Function_Return sPT
        End_Function

        Function Proc_Ret Returns String
            String sRet sPrfx
            Move "SomeValue" To sRet
            If (ASDB.PAR1T=8) Begin
                If (Trim(ASDB.PAR1)<>"") Begin
                    Move (Left(ASDB.PAR1,1)) To sPrfx
                    Move (sPrfx+"Var1") To sRet
                End
            End
            If (ASDB.PAR2T=8) Begin
                If (Trim(ASDB.PAR2)<>"") Begin
                    Move (Left(ASDB.PAR2,1)) To sPrfx
                    Move (sPrfx+"Var2") To sRet
                End
            End
            If (ASDB.PAR3T=8) Begin
                If (Trim(ASDB.PAR3)<>"") Begin
                    Move (Left(ASDB.PAR3,1)) To sPrfx
                    Move (sPrfx+"Var3") To sRet
                End
            End
            If (ASDB.PAR4T=8) Begin
                If (Trim(ASDB.PAR4)<>"") Begin
                    Move (Left(ASDB.PAR4,1)) To sPrfx
                    Move (sPrfx+"Var4") To sRet
                End
            End
            If (ASDB.PAR5T=8) Begin
                If (Trim(ASDB.PAR5)<>"") Begin
                    Move (Left(ASDB.PAR5,1)) To sPrfx
                    Move (sPrfx+"Var5") To sRet
                End
            End
            Function_Return sRet
        End_Function

        Function Parse_Param Number nPar Returns String
            String sRet
            Move "" To sRet
            If (nPar=1) Begin
                If ((ASDB.PAR1T=1)And(ASDB.PAR1="integer")) Move "iVar1"    To sRet
                If ((ASDB.PAR1T=1)And(ASDB.PAR1="string"))  Move "sVar1"    To sRet
                If ((ASDB.PAR1T=1)And(ASDB.PAR1="number"))  Move "nVar1"    To sRet
                If (ASDB.PAR1T=2)                           Move "iCls"     To sRet
                If (ASDB.PAR1T=3)                           Move "iObj"     To sRet
                If ((ASDB.PAR1T=4)And(length(Trim(ASDB.PAR1))<=10)) Move ("{"+Trim(ASDB.PAR1)+"}")  To sRet
                If ((ASDB.PAR1T=4)And(length(Trim(ASDB.PAR1))>10)) Move "{Mode}"   To sRet
                If (ASDB.PAR1T=5)                           Move ("{"+Trim(ASDB.PAR1)+"}")  To sRet
                If (ASDB.PAR1T=6)                           Move "iMsg"     To sRet
                If (ASDB.PAR1T=7)                           Move "iGet"     To sRet
                If (ASDB.PAR1T=8)                           Move ""         To sRet
                If (ASDB.PAR1T=9)                           Move "iWinMsg"  To sRet
                If (ASDB.PAR1T=10)                          Move "iFile"    To sRet
                If (ASDB.PAR1T=11)                          Move "iField"   To sRet
                If (ASDB.PAR1T=12)                          Move "iFileField" To sRet
                If (ASDB.PAR1T=13)                          Move "ImageNum" To sRet
            End
            If (nPar=2) Begin
                If ((ASDB.PAR2T=1)And(ASDB.PAR2="integer")) Move "iVar2"    To sRet
                If ((ASDB.PAR2T=1)And(ASDB.PAR2="string"))  Move "sVar2"    To sRet
                If ((ASDB.PAR2T=1)And(ASDB.PAR2="number"))  Move "nVar2"    To sRet
                If (ASDB.PAR2T=2)                           Move "iCls"     To sRet
                If (ASDB.PAR2T=3)                           Move "iObj"     To sRet
                If ((ASDB.PAR2T=4)And(length(Trim(ASDB.PAR2))<=10)) ;
                                                            Move ("{"+Trim(ASDB.PAR2)+"}")  To sRet
                If ((ASDB.PAR2T=4)And(length(Trim(ASDB.PAR2))>10)) Move "{Mode}"   To sRet
                If (ASDB.PAR2T=5)                           Move ("{"+Trim(ASDB.PAR2)+"}")  To sRet
                If (ASDB.PAR2T=6)                           Move "iMsg"     To sRet
                If (ASDB.PAR2T=7)                           Move "iGet"     To sRet
                If (ASDB.PAR2T=8)                           Move ""         To sRet
                If (ASDB.PAR2T=9)                           Move "iWinMsg"  To sRet
                If (ASDB.PAR2T=10)                          Move "iFile"    To sRet
                If (ASDB.PAR2T=11)                          Move "iField"   To sRet
                If (ASDB.PAR2T=12)                          Move "iFileField" To sRet
                If (ASDB.PAR2T=13)                          Move "ImageNum" To sRet
            End
            If (nPar=3) Begin
                If ((ASDB.PAR3T=1)And(ASDB.PAR3="integer")) Move "iVar3"    To sRet
                If ((ASDB.PAR3T=1)And(ASDB.PAR3="string"))  Move "sVar3"    To sRet
                If ((ASDB.PAR3T=1)And(ASDB.PAR3="number"))  Move "nVar3"    To sRet
                If (ASDB.PAR3T=2)                           Move "iCls"     To sRet
                If (ASDB.PAR3T=3)                           Move "iObj"     To sRet
                If ((ASDB.PAR3T=4)And(length(Trim(ASDB.PAR3))<=10)) ;
                                                            Move ("{"+Trim(ASDB.PAR3)+"}")  To sRet
                If ((ASDB.PAR3T=4)And(length(Trim(ASDB.PAR3))>10)) Move "{Mode}"   To sRet
                If (ASDB.PAR3T=5)                           Move ("{"+Trim(ASDB.PAR3)+"}")  To sRet
                If (ASDB.PAR3T=6)                           Move "iMsg"     To sRet
                If (ASDB.PAR3T=7)                           Move "iGet"     To sRet
                If (ASDB.PAR3T=8)                           Move ""         To sRet
                If (ASDB.PAR3T=9)                           Move "iWinMsg"  To sRet
                If (ASDB.PAR3T=10)                          Move "iFile"    To sRet
                If (ASDB.PAR3T=11)                          Move "iField"   To sRet
                If (ASDB.PAR3T=12)                          Move "iFileField" To sRet
                If (ASDB.PAR3T=13)                          Move "ImageNum" To sRet
            End
            If (nPar=4) Begin
                If ((ASDB.PAR4T=1)And(ASDB.PAR4="integer")) Move "iVar4"    To sRet
                If ((ASDB.PAR4T=1)And(ASDB.PAR4="string"))  Move "sVar4"    To sRet
                If ((ASDB.PAR4T=1)And(ASDB.PAR4="number"))  Move "nVar4"    To sRet
                If (ASDB.PAR4T=2)                           Move "iCls"     To sRet
                If (ASDB.PAR4T=3)                           Move "iObj"     To sRet
                If ((ASDB.PAR4T=4)And(length(Trim(ASDB.PAR4))<=10)) ;
                                                            Move ("{"+Trim(ASDB.PAR4)+"}")  To sRet
                If ((ASDB.PAR1T=4)And(length(Trim(ASDB.PAR4))>10)) Move "{Mode}"   To sRet
                If (ASDB.PAR4T=5)                           Move ("{"+Trim(ASDB.PAR4)+"}")  To sRet
                If (ASDB.PAR4T=6)                           Move "iMsg"     To sRet
                If (ASDB.PAR4T=7)                           Move "iGet"     To sRet
                If (ASDB.PAR4T=8)                           Move ""         To sRet
                If (ASDB.PAR4T=9)                           Move "iWinMsg"  To sRet
                If (ASDB.PAR4T=10)                          Move "iFile"    To sRet
                If (ASDB.PAR4T=11)                          Move "iField"   To sRet
                If (ASDB.PAR4T=12)                          Move "iFileField" To sRet
                If (ASDB.PAR4T=13)                          Move "ImageNum" To sRet
            End
            If (nPar=5) Begin
                If ((ASDB.PAR5T=1)And(ASDB.PAR5="integer")) Move "iVar5"    To sRet
                If ((ASDB.PAR5T=1)And(ASDB.PAR5="string"))  Move "sVar5"    To sRet
                If ((ASDB.PAR5T=1)And(ASDB.PAR5="number"))  Move "nVar5"    To sRet
                If (ASDB.PAR5T=2)                           Move "iCls"     To sRet
                If (ASDB.PAR5T=3)                           Move "iObj"     To sRet
                If ((ASDB.PAR5T=4)And(length(Trim(ASDB.PAR5))<=10)) ;
                                                            Move ("{"+Trim(ASDB.PAR5)+"}")  To sRet
                If ((ASDB.PAR5T=4)And(length(Trim(ASDB.PAR5))>10)) Move "{Mode}"   To sRet
                If (ASDB.PAR5T=5)                           Move ("{"+Trim(ASDB.PAR5)+"}")  To sRet
                If (ASDB.PAR5T=6)                           Move "iMsg"     To sRet
                If (ASDB.PAR5T=7)                           Move "iGet"     To sRet
                If (ASDB.PAR5T=8)                           Move ""         To sRet
                If (ASDB.PAR5T=9)                           Move "iWinMsg"  To sRet
                If (ASDB.PAR5T=10)                          Move "iFile"    To sRet
                If (ASDB.PAR5T=11)                          Move "iField"   To sRet
                If (ASDB.PAR5T=12)                          Move "iFileField" To sRet
                If (ASDB.PAR5T=13)                          Move "ImageNum" To sRet
            End
            Function_Return sRet
        End_Function

        Function fNumOfParameters Returns Integer
            Integer iRet
            Move 0 To iRet
            If ((ASDB.PAR1T>0)And(ASDB.PAR1T<>8)) Increment iRet
            If ((ASDB.PAR2T>0)And(ASDB.PAR2T<>8)) Increment iRet
            If ((ASDB.PAR3T>0)And(ASDB.PAR3T<>8)) Increment iRet
            If ((ASDB.PAR4T>0)And(ASDB.PAR4T<>8)) Increment iRet
            If ((ASDB.PAR5T>0)And(ASDB.PAR5T<>8)) Increment iRet
            Function_Return iRet
        End_Function

    End_Object    // Form1

    Object dbEdit1 Is a dbEdit
        Set Enabled_State To False
        Entry_Item Vdfcls.Descr
        Set Size to 70 175
        Set Location To 2 138
        Set Border_Style to Border_StaticEdge
        Set peAnchors to anTopLeftRight
    End_Object    // dbEdit1

    Object dbEdit2 Is a dbEdit
        Set Enabled_State To False
        Entry_Item Asdb.Name
        Set Server To (Asdb_DD(Self))
        Set Size to 25 310
        Set Location to 160 3
        Set peAnchors to anBottomLeftRight
    End_Object    // dbEdit2

#IFDEF Is$HAMMER$TOOL
    Object Button1 Is a Button

        Set Enabled_State To True

        Set Label To "&Add"
        Set Location to 188 264
        Set peAnchors to anBottomRight


        Procedure OnClick
            Integer hoID iLine iCol
            String  sSrc
            Delegate Get piEditView To hoID

            Send PopUp To (oPP(Self)) (Trim(VDFCLS.NAME)) VDFCLS.CODE
            Get psSource Of (oPP(Self)) To sSrc

            Delegate Get piEditLine To iLine
            Delegate Get piEditCol  To iCol

            Send InsertTextAtPosition To (oEdit(hoID)) iLine iCol sSrc
        End_Procedure // OnClick

    End_Object    // Button1
#ENDIF


    // **WvA: 7-5-2002
    // I had to disable this part of the code in order to compile the vdfcls program.
    // The code below only works if this view is part of the hammer itself, not if
    // the view is part of a standalone program.
    // Uncomment the constant in the top of this view to deactivate the compiler directive
    // below so that this code again activated.
    #IFDEF Is$HAMMER$TOOL
    Procedure Activate
        Integer hoID iEd iLine iCol iZ
        Get piEditView To iEd
        If (Not(iEd)) Begin
            Move (Focus(Desktop))         To hoID
            If (hoID) Begin
                Get GetEditViewID Of hoID     To hoID
                Set piEditView  To hoID

                // Cursor Position
                Get piSelEndLine  Of (oEdit(hoID)) To iLine
                Get piSelEndCol   Of (oEdit(hoID)) To iCol

                Set piEditLine To iLine
                Set piEditCol  To iCol

                Delegate Get piViewsZoomed  To iZ
                If iZ Set view_mode To viewmode_zoom
            End
        End
        Forward Send Activate
    End_Procedure
    #ENDIF

    Procedure Close_Panel
        Set piEditView To 0
        Forward Send Close_Panel
    End_Procedure

    Procedure Update_Label String sCls
        Set Label To ("Class Explorer - ("+sCls+")")
    End_Procedure

    Procedure CloseFile
    End_Procedure
    Procedure CreateEditorEntry
    End_Procedure

End_Object    // Class_Explorer


