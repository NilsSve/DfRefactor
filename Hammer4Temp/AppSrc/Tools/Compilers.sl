Use Dfclient.pkg

Object oCompilers_SL is a dbModalPanel
    Set pbSizeToClientArea to False
    Set Label to "Available Built-In Compilers"
    Set Size to 155 180
    Set Location to 4 4
    Set piMinSize to 155 180

    Object oSelList is a List
        Property Integer Invoking_Object_Id        0
        Set Size to 105 160
        Set Location to 5 5
        Set peAnchors to anAll
        Set piMinSize to 105 160

        Procedure AddLine String sTxt
            Send add_item msg_none sTxt
        End_Procedure

        Procedure Fill
            Integer iCompiler iCompilers
            String  sCreated
            tTHCompiler[] THCompilers
            Send Delete_Data
            Get pTHCompilers of ghoApplication To THCompilers
            Move (SizeOfArray(THCompilers)-1) to iCompilers
            For iCompiler from 0 to iCompilers
                Move "" to sCreated
                If (THCompilers[iCompiler].hoCompiler) Begin
                    Move (" "+_T("(Created)", 1508)) to sCreated
                End
                Send AddLine ("DataFlex" * THCompilers[iCompiler].sVersion + sCreated)
            Loop
        End_Procedure  // Combo_fill_list

        Procedure Ok
            Send Close_Panel
        End_Procedure
        On_Key kEnter   Send Ok
        On_Key KCANCEL  Send Close_Panel
        Procedure mouse_click Integer iPara0
            Send Ok
        End_Procedure

    End_Object    // oSelList

    Procedure popup
        Set Invoking_Object_Id of (oSelList(Self))  to (Focus(Desktop))
        Send Fill to (oSelList(Self))
        Forward Send popup
    End_Procedure

    Object oCancel_bn is a Button
        Set Label to "Cancel"
        Set Location to 114 115
        Set peAnchors to anBottomRight
        Procedure OnClick
            Send Close_Panel
        End_Procedure
    End_Object    // oCancel_bn

    #IFDEF TH_TRANSLATION
    Procedure Translate
        Set Label               to gILanguage[1507]
        Set Label of oCancel_bn to gILanguage[1509]
    End_Procedure
    #ENDIF

    Procedure Activating
        Forward Send Activating
        #IFDEF TH_TRANSLATION
        Send Translate
        #ENDIF
    End_Procedure

End_Object    // LookUp