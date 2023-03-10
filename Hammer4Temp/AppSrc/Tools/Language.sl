Use DFClient.pkg

Object oLanguage_SL is a dbModalPanel
    Set pbSizeToClientArea to False
    Set Label to "Languages"
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
            Integer iCount iC
            String  sStr
            Send Delete_Data
            Send AddLine "C/C++"
            Send AddLine "Basic"
            Send AddLine "Java"
            Send AddLine "Pascal"
            Send AddLine "SQL"
            Send AddLine "HTML"
            Send AddLine "XML"
            Send AddLine "Javascript"
            Send AddLine "CSharp"
            Send AddLine "Go"
            Send AddLine "Swift"
            Send AddLine "Text"
            Send AddLine "Ini"
            Get psLanguages.Count of ghoEditorProperties to iCount
            For iC from 0 to (iCount-1)
                Get psLanguages of ghoEditorProperties item iC  to sStr
                Send AddLine sStr
            End
        End_Procedure  // Combo_fill_list

        Procedure Ok
            Integer hoID
            String sVal
            Get value item (Current_Item(Self)) to sVal
            Get Invoking_Object_Id              to hoID
            If hoID Set value of hoID to sVal
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

    Object oOK_bn is a Button
        Set Label to "Ok"
        Set Location to 114 61
        Set peAnchors to anBottomRight
        Procedure OnClick
            Send OK to oSelList
        End_Procedure
    End_Object    // oOK_bn

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
        Set Label               to gILanguage[1498]
        Set Label of oOK_bn     to gILanguage[1499]
        Set Label of oCancel_bn to gILanguage[1500]
    End_Procedure
    #ENDIF

    Procedure Activating
        Forward Send Activating
        #IFDEF TH_TRANSLATION
        Send Translate
        #ENDIF
    End_Procedure

End_Object    // LookUp