//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : oObjectsMethods.SL
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: Objects ans Procedures lookup
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd
Use Dfclient.pkg
Use cLineParser.pkg
Use cEditorEdit.pkg

// Project Object Structure
//   oObjectsMethods is a dbModalPanel
//     oMode is a ComboForm
//     oMethodsType is a RadioGroup
//       Radio2 is a Radio
//       Radio1 is a Radio
//     oObjectList is a Grid
//     oMethodsList is a Grid
//     oParameter is a Group
//       oParameterIDs is a Array
//       oLineParser is a cLineParser
//       oComboForm is a ComboForm
//     oOK_bn is a Button
//     oCancel_bn is a Button

// Register all objects
Register_Object oCancel_bn
Register_Object oComboForm
Register_Object oLineParser
Register_Object oMethodsList
Register_Object oMethodsType
Register_Object oMode
Register_Object oObjectList
Register_Object oObjectsMethods
Register_Object oOK_bn
Register_Object oParameter
Register_Object oParameterIDs
Register_Object Radio1
Register_Object Radio2






    // Can also handle Ranges and expands it.
Class cLineParserEx Is a cLineParser
    Procedure ParseLineEx String sLine Integer iRange
        If iRange Begin
            Move (Trim(sLIne))  To sLine
            Integer iVon iBis iPos iC
            Send Delete_Data
            Move (Pos("-",sLine))                   To iPos
            Move (Left(sLine,iPos-1))               To iVon
            Move (Right(sLine,Length(sLine)-iPos))  To iBis
            For iC From iVon To iBis

                Set value Item (Item_Count(Self))   To iC
            End
        End

        Else Send ParseLine sLine
    End_Procedure
End_Class

Use Asdb_ext.pkg    // SOme interface function for the use with the ASDB database.
Object oObjectsMethods Is a dbModalPanel

    Property tParseVar[]   pParseVars
    Property tParseParam[] pParseParams
    Property String  psReference    ""
    Property String  psLine         ""
    Property String  psStartCode    ""
    Property Handle  phoParserID    0
    Property Integer piLine         0

    Set locate_mode To CENTER_ON_SCREEN
    Set Label To "Creator"
    Set Size To 185 561
    Set Location To 4 5



    Object oMode Is a ComboForm
        Set Size To 13 239
        Set Location To 5 1
        Set Form_Border To 10

        // Combo_Fill_List is called when the list needs filling
        Set Entry_State Item 0  To FALSE
        Set Combo_Sort_State    To FALSE
        Procedure Combo_Fill_List
            // Fill the combo list with Send Combo_Add_Item
            Send Combo_Add_Item "Set"
            Send Combo_Add_Item "Get"
            Send Combo_Add_Item "Send"
            Send Combo_Add_Item "Move"
        End_Procedure  // Combo_fill_list
            // notification of a selection change or edit change
        Procedure OnChange
            String sValue
            Get Value To sValue // the current selected item
            Set psClassFilled  Of (oMethodsList(Self)) To ""
            Set psObjectFilled Of (oMethodsList(Self)) To ""
            Send ReFill        To (oMethodsList(Self))
        End_Procedure  // OnChange

    End_Object    // oMode

    Object oMethodsType Is a RadioGroup
        Set Size To 17 120
        Set Location To 1 242

        Object Radio1 Is a Radio
            Set Label To "&1 Object"
            Set Size To 10 43
            Set Location To 6 5
        End_Object    // Radio1

        Object Radio2 Is a Radio
            Set Label To "&2 Class"
            Set Size To 10 39
            Set Location To 6 52
        End_Object    // Radio2

        Set Current_Radio To 1
        Procedure Notify_Select_State Integer iToItem Integer iFromItem
            Set psClassFilled  Of (oMethodsList(Self)) To ""
            Set psObjectFilled Of (oMethodsList(Self)) To ""
            Send ReFill        To (oMethodsList(Self))
        End_Procedure

        On_Key key_Tab              Send SwitchToObjectList
        On_Key key_shift+key_Tab    Send SwitchToMode
        On_Key kRightArrow          Send SwitchToObjectList
        On_Key kLeftArrow           Send SwitchToMode

        Procedure Next
            Send activate To (oObjectList(Self))
        End_Procedure

    End_Object    // oMethodsType

    Object oObjectList Is a cObjectList
        Set Size To 130 240
        Set Location To 19 0

        Set Line_Width To 1 0

        Set Form_Width    Item 0 To 231
        Set Header_Label  Item 0 To "Objects"

        Set Header_Visible_State To True
        Property tParseObject[]  pListParseObjects
        Property Integer piItemLimit           1

        On_Key kCancel              Send Finish
        On_Key key_F2               Send Ready
        On_Key kEnter               Send Ready
        On_Key kRightArrow          Send SwitchToMethods
        On_Key kLeftArrow           Send SwitchToMethodsType
        On_Key key_Tab              Send SwitchToMethods
        On_Key key_shift+key_Tab    Send SwitchToMethodsType

        Procedure Item_Change Integer iVon Integer iBis
            Integer iRet iRow hoID
            String  sClass sObject
            tParseObject[] ParseObjects
            tParseMethod[] ParseMethods
            Forward Get Msg_Item_Change iVon iBis   To iRet
            Move (iBis/piItemLimit(Self))           To iRow

            Get pListParseObjects to ParseObjects
            If (SizeOfArray(ParseObjects)>0) Move ParseObjects[iRow].sClass To sClass
            Get Value                          Item iRow   To sObject
            If sClass Ne "" Begin
                Move ParseObjects[iRow].pElement To hoID
                Get GetElementList hoID                        To ParseMethods
                Send FillList To (oMethodsList(Self)) sClass sObject True ParseMethods
            End

            Procedure_Return iRet
        End_Procedure

        Procedure AddLine String sTxt
            Send add_item msg_none sTxt
            Set entry_state Item (Item_Count(Self)-1)   To False
        End_Procedure
        Procedure FillList Integer hoParser Integer iLine String sRef
            Integer iC iCur
            String  sCurRef sVal
            tParseObject[] ParseObjects
            Get pParseObjects           of hoParser to ParseObjects
            Set pListParseObjects       to ParseObjects
            Get psReference             To sCurRef
            Set Dynamic_Update_State    To False
            Forward Send FillList hoParser iLine sRef
            Set Dynamic_Update_State    To True
        End_Procedure

    End_Object    // oObjectList

    Object oMethodsList Is a cSearchAndControlGrid
        Set Size To 130 120
        Set Location To 19 242

        Set Line_Width To 1 0

        Set Form_Width    Item 0 To 111
        Set Header_Label  Item 0 To "Methods"

        Set Header_Visible_State To True
        Property Integer piItemLimit           1
        Property String  psObjectName          ""
        Property String  psClassName           ""
        Property String  psObjectFilled        0
        Property String  psClassFilled         ""
        Property Integer piClassCode           0
        Property tParseMethod[] pParseMethodLst



        On_Key kCancel              Send Finish
        On_Key key_F2               Send Ready
        On_Key kEnter               Send Ready
        On_Key kLeftArrow           Send SwitchToObjectList
        On_Key kRightArrow          Send SwitchToParas
        On_Key key_Tab              Send SwitchToParas
        On_Key key_shift+key_tab    Send SwitchToObjectList



            // Item change updates the Parameters
        Procedure Item_Change Integer iVon Integer iBis
            Integer iRet iRow
            String  sProp
            Forward Get Msg_Item_Change iVon iBis   To iRet
            Move (iBis/piItemLimit(Self))           To iRow
            Get value Item iBis                     To sProp
            Send TryToDisplayParameters (piClassCode(Self)) sProp iRow
            Procedure_Return iRet
        End_Procedure
            // Creates the Parameter objects by sending AddParameter to oParameter Container.
        Procedure TryToDisplayParameters Integer iCls String sProp Integer iRow
            Integer iParXt iVon iBis iField iMode iCount iType iParXt_Next
            Integer iC
            Pointer pElement
            String  sParX sLabel
            tParseParam[]  ParseParams
            tParseMethod[] ParseMethods
            Get Current_Radio Of (oMethodsType(Self)) To iMode

            Clear ASDB
            If iMode Eq 1 Begin
                Move iCls                   To ASDB.VDFCls
                Move sProp                  To ASDB.Name
                Find Eq ASDB by Index.1

                If (Found) Begin

                    Send ResetParameter     To (oParameter(Self))
                    Field_Map ASDB.File_Number "Par1t"  To iVon
                    Field_Map ASDB.File_Number "Par5"   To iBis

                    For iField From iVon To iBis
                        Get_Field_Value ASDB.File_Number iField     To iParXt
                        Get_Field_Value ASDB.File_Number (iField+1) To sParX
                        If iField Lt (iBis-1) Get_Field_Value ASDB.File_Number (iField+2) To iParXt_Next
                        Else Move 0                                                       To iParXt_Next
                        If iParXt Eq 0 Break
                        Else Begin
                            Move (ConvertParameterTyp2Str(iParXt,sParX))    To sLabel
                            If AsDb.TYPE Eq ASDB_TYPE_PROPERTY Begin
                                If iParXt_Next Eq 0 Move "to"   To sLabel
                                Else Move "Item"                To sLabel
                            End
                            Send AddParameter To (oParameter(Self)) iParXt sParX sLabel
//                            If AsDb.TYPE Eq ASDB_TYPE_PROPERTY Move iBis    To iField
                        End

                        Increment iField    // 2 field per run - Type, Parameter
                    End

                    Send FinishParameter      To (oParameter(Self))
                End


            End

            If iMode Eq 0 Begin
                Send ResetParameter     To (oParameter(Self))
                Move (Right(Value(Self,iRow),4))                To iRow
                Get pParseMethodLst To ParseMethods
                Move ParseMethods[iRow].iType    To iType
                Move ParseMethods[iRow].pElement To pElement
                Get GetParameterList pElement                   To ParseParams
                Move (SizeOfArray(ParseParams))                 To iCount
                If iCount Le 0 Begin
                  If iType Eq MK_Property Move "to"           To sLabel
                  Send AddParameter To (oParameter(Self)) 0 "String" sLabel
                End
                For iC From 0 To (iCount-1)

                    Move ParseParams[iC].sName                  To sLabel
                    Send AddParameter To (oParameter(Self)) 0 "String" sLabel
                End
                Send FinishParameter To (oParameter(Self))
            End

        End_Procedure
            // Adds one line.
        Procedure AddLine String sTxt
            Send add_item msg_none sTxt
            Set entry_state Item (Item_Count(Self)-1)   To False
        End_Procedure

            // Checks it a Method fits to the current Set,Get,Move,Send mode.
        Function DoesMethodFit Integer iType String sType Integer iFromClass Returns Integer
            If iFromClass Begin // Methods out of the DataBase
                If iType Eq ASDB_TYPE_PROPERTY  If sType In "Get,Set,Move"  Function_Return 1
                If iType Eq ASDB_TYPE_PROCEDURE If sType Eq "Send"          Function_Return 1
                If iType Eq ASDB_TYPE_FUNCTION  If sType In "Get,Move"      Function_Return 1
                If iType Eq ASDB_TYPE_COMMAND                               Function_Return 0
                If iType Eq ASDB_TYPE_BOTH      If sType In "Get,Move,Send" Function_Return 1
            End

            Else Begin          // Methods out of the ObjectDefinition
                If iType Eq MK_PROPERTY     If sType In "Get,Set,Mode"  Function_Return 1
                If iType Eq MK_PROCEDURE    If sType Eq "Send"          Function_Return 1
                If iType Eq MK_FUNCTION     If sType Eq "Get,Move"      Function_Return 1
                If iType Eq MK_SETPROCEDURE If sType In "Set"           Function_Return 1
            End

        End_Function
            // Fills in all Methods etc. for a class or an Object.
        Procedure FillList String sClass String sObject Integer iCalm tParseMethod[] ParseMethods
            Boolean bFound
            Integer iType iElemTyp iC iMode iLineCount iDispRows
            Integer iMethodCount
            String  sType sName
            Send ResetKey
            Get displayable_rows                      To iDispRows
            Get Current_Radio Of (oMethodsType(Self)) To iMode
            Get value Of (oMode(Self))          To sType
            If sType Eq "Get"   Move 1          To iType
            If sType Eq "Set"   Move 1          To iType
            If sType Eq "Send"  Move 3          To iType
            If sType Eq "Move"  Move 4          To iType
            If iMode Eq 1 If sClass  Ne "" If (psClassFilled(Self))  Eq sClass  Procedure_Return
            Else          If sObject Ne "" If (psObjectFilled(Self)) Eq sObject Procedure_Return
            Set pParseMethodLst         To ParseMethods
            Set psClassName             To sClass
            Set psObjectName            To sObject
            If iCalm Set psClassFilled  To ""
            If iCalm Set psObjectFilled To ""
            Set Dynamic_Update_State    To False
            Send Delete_Data
            If iMode Eq 0 Begin
                Move (SizeOfArray(ParseMethods)) To iMethodCount
                Move (SortArray(ParseMethods)) To ParseMethods
                For iC From 0 To (iMethodCount-1)

                    Move ParseMethods[iC].iType To iElemTyp
                    If (DoesMethodFit(Self,iElemTyp,sType,False)) Begin
                        Move ParseMethods[iC].sName To sName
                        Move (Pad(sName,200))   To sName
                        Append sName (Right(Append("0000",iC),4))
                        Increment iLineCount
                        Send AddLine sName iC
                        Move ParseMethods[iC].sClass To sName // ??
                    End

                    If iCalm If iLineCount Ge iDispRows Break
                End

                If (Item_Count(Self)) Ne 0 If Not iCalm Set psObjectFilled To sObject
            End

            If iMode Eq 1 Begin
                Clear VDFCLS
                Move sClass To VDFCLS.Name
                Find Eq VDFCLS by Index.1
                If (Found) Begin
                    Set piClassCode                  To VDFCLS.Code
                    If Not iCalm Set psClassFilled   To sClass
                    Clear ASDB
                    Move VDFCLS.Code    To ASDB.VdfCls
                    Repeat
                        Find Gt ASDB by Index.1
                        Move (Found) To bFound
                        If ASDB.VDFCls Ne VDFCLS.Code Move False to bFound
                        If (bFound) If (DoesMethodFit(Self,ASDB.TYPE,sType,True)) Begin
                            Increment iLineCount
                            Send AddLine ASDB.Name
                        End
                        If iCalm If iLineCount Ge iDispRows Break
                    Until (Not(bFound))
                End
            End
            //set Object_Shadow_State to (Item_Count(Self) eq 0)
            Set Dynamic_Update_State To True
        End_Procedure
            // To show it better that nothin is in the MethodsList.
        Procedure Set Object_Shadow_State Integer iFlag
            Forward Set Object_Shadow_State To iFlag
            Set Color               To (If(iFlag,clltGray,clWindow))
            Set GridLine_Mode       To (If(iFlag,GRID_VISIBLE_BOTH,GRID_VISIBLE_NONE))
        End_Procedure
            // Does a Refill when: Entering, oMode changes, oMethods Type changes.
        Procedure ReFill
            Send FillList (psClassName(Self)) (psObjectName(Self)) False (pParseMethodLst(Self))
        End_Procedure
            // Refill with all, not only the 1st page.
        Procedure Entering
            Forward Send Entering
            Send Refill
        End_Procedure


    End_Object    // oMethodsList

    Object oParameter Is a Group
        Set Size To 148 190
        Set Location To 1 365
        Set Label To "Parameters"

        Define oParameters_StartOffsetY For 10
        Define oParameters_StartOffsetX For 45
        Define oParameters_DistanceY    For 2

        Property Integer piPositionY        oParameters_StartOffsetY

            // Storage for the ParameterObjects.
        Object oParameterIDs Is an Array
        End_Object
            // Parses the Mode and Range parameters.
        Object oLineParser Is a cLineParserEx
            Set psSepCharacter  To "|"
        End_Object
            // Removes All created Parameter Objects.
        Procedure ResetParameter
            Integer iC hoID
            For iC From 0 To (Item_Count(oParameterIDs(Self))-1)

                Get value Of (oParameterIDs(Self)) Item iC  To hoID
                If hoID Begin
                    Send Deactivate             To hoID
                    Send Request_Destroy_Object To hoID
                End

            End

            Send Delete_Data To (oParameterIDs(Self))
            Set piPositionY  To oParameters_StartOffsetY
        End_Procedure
            // Activates the MethodList.
        Procedure SwitchToMethods
            Send activate To (oMethodsList(Self))
        End_Procedure

            // Adds a Parameters.
        Procedure AddParameter Integer iType String sPara String sLabel
            Integer hoID iC iBaseClass iCount
            String  sVal
            tParseParam[] ParseParams
            tParseVar[]   ParseVars
            Move (Trim(sPara))    To sPara


            Object oComboForm Is a ComboForm
                If (Item_Count(oParameterIDs(Self))) Eq 0 On_Key key_shift+key_Tab Send SwitchToMethods
                On_Key kLeftArrow  Send SwitchToMethods
                On_Key kEnter      Send Ready
                On_Key kCancel     Send Finish
                Set size                        To 13 140
                Set Location                    To (piPositionY(Self)) oParameters_StartOffsetX
                Set Label_Col_Offset            To 0
                Set Label_Justification_Mode    To jMode_Right
                Set Combo_Sort_State            To False
                Set Label                       To (Append(sLabel,":"))
                Move Self                       To hoID

                //___Enter_Modes_and_Ranges_to_the_Combo...______________
                If ((iType Eq TYPE_MODE) Or (iType Eq TYPE_RANGE)) Begin
                    Send ParseLineEx  To (oLineParser(Self)) sPara (iType Eq TYPE_RANGE)
                    For iC From 0 To (Item_COunt(oLineParser(Self))-1)

                        Get value Of (oLineParser(Self)) Item iC    To sVal
                        Send Combo_Add_Item To hoID (Trim(sVal))
                    End

                End


                //___Enter_local_Vars_to_the_Combo...____________________
                Get pParseVars To ParseVars
                Move (SizeOfArray(ParseVars)) To iCount
                If (iCount>0) Begin
                    For iC From 0 To (iCount-1)

                        Move ParseVars[iC].sName To sVal
                        Send Combo_Add_Item (Trim(sVal))
                    End

                End

                //___Also_the_Parameters...______________________________
                Get pParseParams To ParseParams
                Move (SizeOfArray(ParseParams)) To iCount
                If (iCount>0) Begin
                    For iC From 0 To (iCount-1)

                        Move ParseParams[iC].sName To sVal
                        Send Combo_Add_Item (Trim(sVal))
                    End

                End

            End_Object


            //___Display_and_add_to_focus...
            Send Add_focus      To hoID Self
            Send Page           To hoID true
            //___Position_Counter..._______________________________________________
            Set piPositionY     To (piPositionY(Self) + 13 + oParameters_DistanceY)
            Set Value Of (oParameterIDs(Self)) Item (Item_Count(oParameterIDs(Self)))   To hoID
        End_Procedure

        Procedure FinishParameter
        End_Procedure

    End_Object    // oParameter

    Object oOK_bn Is a Button
        Set Label To "&OK"
        Set Location To 155 455

        Procedure OnClick
            Send Ready
        End_Procedure

    End_Object    // oOK_bn


    Object oCancel_bn Is a Button
        Set Label To "Cancel"
        Set Location To 155 403

        Procedure OnClick
            Send Finish
        End_Procedure
    End_Object    // oCancel_bn

    Procedure Popup_Group
        Integer hoID hoOL hoParser iLine
        String  sStartCode
        tParseObject[] ParseObjects
        tParseParam[]  ParseParams
        tParseVar[]    ParseVars

        Send OpenTH3DB of ghoApplication VDFCLS.File_Number
        Send OpenTH3DB of ghoApplication ASDB.File_Number

        Get psStartCode                          To sStartCode
        Move (UppercaseFirstLetter(sStartCode))  To sStartCode
        Set value Of (oMode(Self)) Item 0        To sStartCode

        Move (oObjectList(Self))        To hoOL
        Get phoParserID                 To hoParser
        Get piLine                      To iLine

        Get pParseObjects of hoParser   to ParseObjects
        Move (SortArray(ParseObjects))  To ParseObjects
        Set pParseObjects of hoParser   to ParseObjects
        Send FillList                   To hoOL hoParser iLine (psReference(Self))

        Get GetVariablenListFromLine    Of hoParser iLine  To ParseVars
        Set pParseVars                  To ParseVars

        Get GetParameterListFromLine    Of hoParser iLine  To ParseParams
        Set pParseParams                To ParseParams

        Set psClassFilled               Of (oMethodsList(Self)) To ""
        Set psObjectFilled              Of (oMethodsList(Self)) To ""

        Forward Send Popup_Group
        Send Activate To (oMethodsList(Self))
        If (Item_Count(oMethodsList(Self))) Eq 0 Send Activate To (oObjectList(Self))
    End_Procedure

        // ElementList. = alle Procedures,Function, also SubObjects of an Element
    Function GetElementList Pointer pElement Returns tParseMethod[]
        Integer hoParser hoRet
        tParseMethod[] ParseMethods
        Get phoParserID                             To hoParser
        Get GetElementsList Of hoParser pElement    To ParseMethods
        Function_Return ParseMethods
    End_Function

        // Gets all Parameters of a function, procedure.
    Function GetParameterList Pointer pElement Returns tParseParam[]
        Integer hoParser hoRet
        tParseParam[] ParseParams
        Get phoParserID      To hoParser
        Send FillInParameter To hoParser pElement (&ParseParams)
        Function_Return ParseParams
    End_Function

         // Cancel.
    Procedure Finish
        Send Close_Panel
    End_Procedure

    Procedure Close_Panel
      Send CloseTH3DB of ghoApplication VDFCLS.File_Number
      Send CloseTH3DB of ghoApplication ASDB.File_Number
      Forward Send Close_Panel
    End_Procedure

        // Creates the String with the Parameters.
    Function CreateParameterString String sMode Returns String
        Integer iParaCount hoID iC
        String  sParas sTmp
        Get Item_Count Of (oParameterIDs(oParameter(Self))) To iParaCount
        For iC From 0 To (iParaCount-1)
            If iC Eq (iParaCount-1) Begin               // Last Parameter
                If sMode In "Get,Set" Append sParas " to "
                If sMode Eq "Move"    Append sParas ")) to "
            End
            Else Begin                  // Seperator between Parameters
                If sMode Eq "Move"   Append sParas ","
                Else If sParas Ne "" Append sParas " "
            End
            Get value   Of (oParameterIDs(oParameter(Self))) Item iC  To hoID
            Get value   Of hoID                                       To sTmp
            If sMode In "Get,Set" If (Uppercase(Label(hoID))) Eq "ITEM:" Move ("Item "+sTmp)   To sTmp
            Append sParas sTmp
        End
        Function_Return sParas
    End_Function

        // OK.
    Procedure Ready
        String sRef sMethod sMode sCurRef sRet sObj sParas sTmp
        Integer iParaCount iC hoID
        Get psReference                                             To sCurRef
        Get Value Of (oMode(Self)) Item 0                           To sMode
        Get value Of (oObjectList(Self))                            To sRef
        Get Value Of (oMethodsList(Self))                           To sMethod
        Move (Trim(sMethod))                                        To sMethod
        If " " In sMethod Move (Left(sMethod,Pos(" ",sMethod)))     To sMethod

        Move (Trim(sRef))                                           To sRef
        Move (ReduceReference(sRef,sCurRef))                        To sRef
        Move (ReferenceToObject(sRef))                              To sObj
        Move (CreateParameterString(Self,sMode))                    To sParas
        If sMode Eq "Move" Begin
            If (Left(sObj,1)) Eq "(" Begin
                Move (Replace("(",Left(sObj,Length(sObj)-1),""))    To sObj
            End
            Append sRet sMode " (" sMethod "(" sObj sParas
        End
        Else Begin
            Append sRet sMode " " sMethod
            If sObj Ne "" If sObj Ne "Self" Begin
                If sMode Eq "Send"  Append sRet " to "
                Else                Append sRet " of "
                Append sRet sObj
            End
            Append sRet " " sParas
        End
        Set psLine    To sRet
        Send Close_Panel
    End_Procedure

        // Navigation Procedures...
    Procedure SwitchToMethods
        Send activate To (oMethodsList(Self))
    End_Procedure
    Procedure SwitchToObjectList
        Send activate To (oObjectList(Self))
    End_Procedure
    Procedure SwitchToParas
        Send Activate To (oParameter(Self))
    End_Procedure
    Procedure SwitchToMethodsType
        Send activate To (oMethodsType(Self))
    End_Procedure
    Procedure SwitchToMode
        Send activate To (oMode(Self))
    End_Procedure
    Procedure SwitchMethodTypeClass
        Set Current_Radio Of (oMethodsType(Self)) To 1
    End_Procedure
    Procedure SwitchMethodTypeObject
        Set Current_Radio Of (oMethodsType(Self)) To 0
    End_Procedure
    On_Key key_alt+key_1 Send SwitchMethodTypeObject
    On_Key key_alt+key_2 Send SwitchMethodTypeClass

End_Object    // oObjectsMethods


Function GetCreatorLine For Desktop String sCurRef Integer hoParserID Integer iLine String sStartCode Returns String
    Set psLine      Of oObjectsMethods To ""
    Set psReference Of oObjectsMethods To sCurRef
    Set psStartCode Of oObjectsMethods To sStartCode
    Set phoParserID Of oObjectsMethods To hoParserID
    Set piLine      Of oObjectsMethods To iLine
    Send Popup      To oObjectsMethods
    Function_Return (psLine(oObjectsMethods(Self)))
End_Function

