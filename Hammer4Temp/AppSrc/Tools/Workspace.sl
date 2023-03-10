//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : Workspace.SL
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: WorkSpace Selector
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Use cWorkSpacePanel.pkg
Use vWin32fh.pkg
Use cWorkSpaceSortArray.pkg
Use cWorkspaceList.pkg
Use cLineControl.pkg
Use Tools\WorkSpaceInfo.DG

Cd_Popup_Object oWorkSpace is a cWorkspacePanel
    Set Label to "Select Workspace..."
    Set Location to 4 8
    Set Size to 240 230
    Set Border_Style to Border_Thick
    Set piMinSize to 240 230

    Object oVDFVersion                  is a ComboForm
        Set Label                       to "VDF &Version:"
        Set Size                        to 13 50
        Set Location                    to 4 50
        Set Form_Border                 to 0
        Set Label_Col_Offset            to 2
        Set Label_Justification_Mode    to jMode_Right
        Set entry_state item 0          to False
        Set combo_sort_state            to False // **WvA: 28-10-2004 Display VDF10 below VDF9

        On_Key kCancel Send Request_Cancel

        Object oVDFVersionArray is a cWorkSpaceSortArray
            Set pbCheckRuntimeInstalled to True
        End_Object // oVDFVersionArray

        //
        // Enumerate the registry keys to get a list of all the installed VDF revisions.
        Procedure Combo_Fill_List
            Integer hoArray
            Integer iLoop
            String  sValue
            Move (oVdfVersionArray(Self)) to hoArray
            If (hoArray) Begin
                Send LoadArray of hoArray
                If (Item_Count(hoArray)=0) Begin
                    // There's a bug that sometimes the array doesn't get filled when calling it the first time.. calling it again
                    // fixes this.. no logical explanation at all.. but it works.
                    Send LoadArray of hoArray
                End
                Move 0 to iLoop
                While (iLoop<Item_count(hoArray))
                    Get VDFversion of hoArray item iLoop to sValue
                    Send Combo_Add_Item sValue
                    Increment iLoop
                Loop
            End
            //@ Set value Item 0 To (Combo_Value(Self,Combo_Item_Count(Self)-1))
            If (psVDFRegistryVersion(ghoEditorProperties)) Ne "" Begin
                Set value to (psVDFRegistryVersion(ghoEditorProperties))
            End
            Else Begin
                // 31.05.2005 RRS
                // See//@ Change by Raveen to eradicate the "file workspaces.ini could not be opened" error for uninstalled VDF versions.
                Set value item 0 to (Combo_Value(Self,Combo_Item_Count(Self)-1))
            End
        End_Procedure // Combo_Fill_List

        // Set the property pnVersion
        // Fill the workspace list
        Procedure onChange
            String  sCrntVersion
            String  sVer
            String  sSelectedTag
            Integer iCurrent
            Integer iCount
            Number nVer

            If (focus(Self) <> Self) Procedure_Return
            Get psVersion to sCrntVersion
            Get value to sVer
            Get piCurrentItem of oWorkspaceList to iCurrent
            Get WorkSpaceTag  of ghoWorkspaceHandlerEx iCurrent to sSelectedTag
            Set psVersion to sVer
            Send FillList to (oWorkspaceList(Self))
            Get StringVdfVersionToNum of ghoWorkspaceHandlerEx sVer to nVer
            If (nVer<120) Begin
                Set Enabled_State of (oBrowse_bn(Self)) to False
            End
            Else Begin
                Set Enabled_State of (oBrowse_bn(Self)) to True
            End
            Get Item_Count of (oWorkspaceList(Self)) to iCount
            If (iCount>0) Begin
                If (Enabled_State(oInfo_bn(Self))=False) Begin
                    Set Enabled_State of (oInfo_bn(Self))   to True
                    Set Enabled_State of (oSelect_bn(Self)) to True
                End
            End
            Else Begin
                Set Enabled_State of (oInfo_bn(Self)) to False
                Set Enabled_State of (oSelect_bn(Self)) to False
            End
        End_Procedure
        
        Function SelectedVersion Returns Number
            String sVersion
            Number nVer
            Get value To sVersion
            Get StringVdfVersionToNum of ghoWorkspaceHandlerEx sVersion to nVer
            Function_Return nVer
        End_Function

        Procedure Previous
            Send Activate to (oClose_bn(Self))
        End_Procedure // Previous

    End_Object    // oVDFVersion

    Object oDisplay_fm is a ComboForm
        Set Size to 12 70
        Set Location to 4 155
        Set Form_Border to 0
        Set Label_Justification_Mode to jMode_Right
        Set Combo_Sort_State to False
        Set entry_state item 0 to False
        Set Label to "Display:"
        Set Label_Col_Offset to 2
        Set peAnchors to anTopLeftRight
        On_Key kCancel Send Request_Cancel

        Define CS_WSDISP_DESCRIPTION for "Description"
        Define CS_WSDISP_KEY         for "Key"
        Define CS_WSDISP_BOTH        for "Both"

        Procedure Combo_Fill_List
            Send Combo_Add_Item CS_WSDISP_DESCRIPTION
            Send Combo_Add_Item CS_WSDISP_KEY
            Send Combo_Add_Item CS_WSDISP_BOTH
        End_Procedure  // Combo_fill_list

        // notification of a selection change or edit change
        Procedure OnChange
            String  sValue
            Integer iOldDisplayMode iNewDisplayMode
            String sODesc sOKey
            If (focus(Self) <> Self) Procedure_Return
            Move (_T(CS_WSDISP_DESCRIPTION, 749))  to sODesc
            Move (_T(CS_WSDISP_KEY, 750))          to sOKey
            Get pcDisplayWSList to iOldDisplayMode
            Get Value to sValue // the current selected item
            Case Begin
                Case (sValue = sODesc)
                    Move ctWSDisplayDescription to iNewDisplayMode
                    Case Break
                Case (sValue = sOKey)
                    Move ctWSDisplayKey         to iNewDisplayMode
                    Case Break
                Case Else
                    Move ctWSDisplayBoth        to iNewDisplayMode
            Case End
            If (iOldDisplayMode <> iNewDisplayMode) Begin
                Set pcDisplayWSList to iNewDisplayMode
                Send FillList to (oWorkspaceList(Self))
            End
        End_Procedure  // OnChange

        Procedure Next
            Send activate to (oWorkspaceList(Self))
        End_Procedure

    End_Object    // oDisplay_fm

    Object oWorkspaceList is a cWorkspaceList
        Set Size to 190 220
        Set Location to 28 5
        Set peAnchors to anAll

        On_Key kCancel Send Request_Cancel
        On_Key kEnter  Send Enter

        Procedure Enter
            Send Select
        End_Procedure

        Procedure Mouse_Click
            Send Enter
        End_Procedure

        // **WvA 27-6-2003 Added Dynamic Update State logic
        Procedure FillList
            String  sCur sVer
            Integer hKeyWrkSpc
            Number  nVer
            Integer bExists
            Integer iWrk iWorkspaceCount iDisplayMode
            String  sVDF sVDFRoot sWSName sWSPath sWStag sLine
            String  sMessage

            Get psVersion to sVer
            Get pcDisplayWSList to iDisplayMode
            // Clear the list control
            Send Delete_Data
            Get CurrentWorkspace sVer to sCur
            Send DoSetLabel sCur
            Send DoEnumerateWorkspaces to ghoWorkspaceHandlerEx sVer
            Get WorkspaceCount of ghoWorkspaceHandlerEx to iWorkspaceCount
            If iWorkSpaceCount Ge 0 Begin
                Set Dynamic_Update_State to False
                For iWrk from 0 to (iWorkSpaceCount - 1)
                    Get WorkSpaceName  of ghoWorkspaceHandlerEx item iWrk to sWSName
                    Get WorkSpaceTag   of ghoWorkspaceHandlerEx item iWrk to sWSTag
                    Get WorkSpacePath  of ghoWorkspaceHandlerEx item iWrk to sWSPath
                    If (Trim(sWSTag) = sCur) Begin
                        Set piCurrentItem to (Item_Count(Self))
                    End
                    Case Begin
                        Case (iDisplayMode = ctWSDisplayDescription)
                            Send Add_Item MSG_None sWSName
                            Case Break
                        Case (iDisplayMode = ctWSDisplayKey)
                            Send Add_Item MSG_None sWSTag
                            Case Break
                        Case Else
                            Send Add_Item MSG_None (sWSName+"   -   [ "+sWSTag+" ]")
                    Case End
                Loop
                Set Dynamic_Update_State to True
            End
            Set Current_Item to (piCurrentItem(Self))
        End_Procedure // FillList

    End_Object    // oWorkspaceList

    Object oLineControl1 is a cLineControl
        Set Size to 2 220
        Set Location to 22 5
        Set peAnchors to anTopLeftRight
    End_Object    // oLineControl1

    Object oInfo_bn is a Button
        Set Label to "&Info..."
        Set Location to 221 6
        Set peAnchors to anBottomRight
        On_Key kCancel Send Request_Cancel
        Procedure OnClick
            Send Request_Info
        End_Procedure // OnClick
    End_Object    // oInfo_bn

    Object oBrowse_bn is a Button
        Set Label to "&Browse..."
        Set Location to 221 62
        Set peAnchors to anBottomRight
        On_Key kCancel Send Request_Cancel
        Procedure OnClick
            Send Request_Browse
        End_Procedure // OnClick
    End_Object    // oBrowse_bn

    Object oSelect_bn is a Button
        Set Label to "&Select"
        Set Location to 221 118
        Set Default_State to True
        Set peAnchors to anBottomRight
        On_Key kCancel Send Request_Cancel
        Procedure OnClick
            Send Select
        End_Procedure // OnClick
    End_Object    // oSelect_bn

    Object oClose_bn is a Button
        Set Label to "&Close"
        Set Location to 221 174
        Set peAnchors to anBottomRight
        On_Key kCancel Send Request_Cancel
        Procedure OnClick
            Send Request_Cancel
        End_Procedure // OnClick
    End_Object    // oClose_bn

    On_Key KEY_ALT+KEY_V Send Activate to oVDFVersion
    On_Key Key_Alt+Key_D Send Activate to oDisplay_fm
    On_Key Key_Alt+Key_I Send Request_Info //Activate To oInfo_bn
    On_Key Key_Alt+Key_S Send Activate to oSelect_bn
    On_Key Key_Alt+Key_C Send Activate to oClose_bn

    Procedure DoSetLabel String sWrkSpcTag
        String sLabel
        If (sWrkSpcTag<>"") Begin
            Move sWrkSpcTag to sLabel
            If (Pos(".sws",Lowercase(sLabel))<>0) Begin
                Get DeriveDescriptionFromStudioFile of ghoWorkspaceHandlerEx sLabel to sLabel
            End
            #IFDEF TH_TRANSLATION
            Move (Replace("%1", gILanguage[756], sLabel)) to sLabel
            #ELSE
            Move ("Select Workspace - ["+sLabel+"]") to sLabel
            #ENDIF
        End
        Else Begin
            Move (_T("Select Workspace...", 757)) to sLabel
        End
        Set Label to sLabel
    End_Procedure // DoSetLabel

    //
    // Returns the currently selected workspace tag and
    // sets the psCurrentWorkspace property
    //
    Function CurrentWorkspace String sVer Returns String
        String sCur
        Get fsCurrentWorkspace of ghoWorkspaceHandlerEx sVer   to sCur
        Set psCurrentWorkSpace to sCur
        Function_Return sCur
    End_Function // CurrentWorkspace

    // Selects the Workspace passed in sWrkSpcTag
    //
    // - Updates the Current Workspace tag in the registry with what we selected (sWrkSpcTag)
    // - Sets our global VDFVersion property
    // - Updates all the Currentxxxxxxx properties in the workspace handler
    //     and changes the Open_Path
    // - Saves the Editor properties
    Procedure SelectCurrentWorkSpace String sWrkSpcTag
        String sKey sVer
        Get psVersion to sVer
        // Update the Current workspace TaG in the registry
        Send ChangeCurrentWorkspace of ghoWorkSpaceHandlerEx sWrkSpcTag sVer
        Set psVDFVersion      of ghoWorkSpaceHandlerEx   to sVer
        Send doLoadVDFVersionInfo to ghoWorkSpaceHandlerEx
        // Set the global VDF Version equal to our selection
        Set VDFVersion      of Desktop to sVer
        Send DoSetOpenPath  to ghoWorkSpaceHandlerEx sWrkSpcTag
        Send LoadNonEmbeddedDriverAutoLoginPrompt of ghoWorkSpaceHandlerEx
        Send SaveIni        to ghoEditorProperties // Save it here because the SmartDosBox needs the info.
    End_Procedure // SelectCurrentWorkSpace


      // Perform the actual selection
    Procedure Select
        Integer iChanged iOk
        Integer iCurrent
        Integer iPerfCount
        String  sWrkSpc sDir
        String  sWSName sWSPath sVer
        Number  nVer

        Get pnVersion to nVer
        Get psVersion to sVer
        Move (Current_Item(oWorkspaceList(Self))) to iCurrent
        Get WorkspaceTag  of ghoWorkSpaceHandlerEx  item iCurrent to sWrkSpc
        Get WorkspaceName of ghoWorkSpaceHandlerEx  item iCurrent to sWSName
        Get WorkspacePath of ghoWorkSpaceHandlerEx  item iCurrent to sWSPath

        Set psBufferWsTag      of ghoWorkSpaceHandlerEx to sWrkSpc
        // psversion == psbuffervdfversion
        //Set psBufferVdfVersion Of ghoWorkSpaceHandlerEx To sVer
        Set psBufferWsName     of ghoWorkSpaceHandlerEx to sWSName
        Set psBufferHome       of ghoWorkSpaceHandlerEx to sWSPath

        // Changed to support Reopen of Files based on Workspace
        // 18.05.01 Bernhard
        Get StartPerfcounter of ghoApplication CPC_ChangeWorkspace sWSName To iPerfCount
        Get RequestChangeWorkspace of desktop sWrkSpc to iChanged
        If iChanged Begin
            Send AddRecentWorkspace to ghoEditorProperties sWrkSpc sWSName sVer
            Send SaveIni            to ghoEditorProperties
            Send SelectCurrentWorkSpace sWrkSpc
            Get  CurrentAppSrcPath of ghoWorkSpaceHandlerEx to sDir
            Send SelectWorkingDirectory sDir
            // Somehow the login popup dialog won't work from within this
            // modal panel, so ending up calling it later after this panel has
            // been destroyed.
            //// Added 17.05.01 Bernhard
            //Send OnWorkSpaceChanged
            Set pbWorkspaceChanged of ghoApplication to True
        End
        Send StopPerfCounter of ghoApplication iPerfCount
        Send Close_Panel
    End_Procedure  // Select

    Procedure WorkSpaceInfoCallBack Integer iObj
        String sVer sNewKey sWrkSpc sName sDir sPath sVal
        Integer iOk iCurrent
        String sWSName sWSPath
        Get psVersion to sVer
        Move (Current_Item(oWorkspaceList(Self))) to iCurrent
        Get WorkspaceTag    of ghoWorkSpaceHandlerEx  item iCurrent to sWrkSpc
        Get WorkspaceName   of ghoWorkSpaceHandlerEx  item iCurrent to sWSName
        Get WorkspacePath   of ghoWorkSpaceHandlerEx  item iCurrent to sWSPath
        Set psBufferWsTag      of ghoWorkSpaceHandlerEx to sWrkSpc
        Set psBufferWsName     of ghoWorkSpaceHandlerEx to sWSName
        Set psBufferHome       of ghoWorkSpaceHandlerEx to sWSPath

        Get DoReadApplicationWorkspace of ghoWorkSpaceHandlerEx sWrkSpc sVer sWSPath True to iOK
        If (not(iOk)) Begin
            Error 350 (_T("Failed to read the data for the Application's workspace", 758))
        End
    End_Procedure // WorkSpaceInfoCallBack

    // Popup the workspace info dialog
    Procedure Request_Info
        Send Popup to (oWorkSpaceInfo(Self))
    End_Procedure

    Procedure Request_Browse
        String  sFileTypes
        String  sCaptionText
        String  sInitFolder
        String  sFile
        String  sStudio
        String  sVdfRootDir
        Number  nVer
        Boolean bExists

        Move (_T("Select a workspace to register", 760)) to sCaptionText
        Move (_T("Workspaces files|*.sws;*.ws|Studio Workspace files|*.sws|All files|*.*", 761)) to sFileTypes
        Get LastWorkspaceFolder of ghoWorkSpaceHandlerEx to sInitFolder

        Get vSelect_File sFileTypes sCaptionText sInitFolder to sFile
        If (sFile<>"") Begin
            Get psVdfRootDir Of ghoWorkSpaceHandlerEx To sVdfRootDir
            Get SelectedVersion Of oVDFVersion To nVer
            If (nVer<200) Begin
              Move (sVdfRootDir+"Bin\Studio.exe") To sStudio
            End
            Else Begin
              Move (sVdfRootDir+"Bin64\Studio.exe") To sStudio
            End
            Get vFilePathExists sStudio to bExists
            If (bExists) Begin
                Runprogram Wait (sStudio+' -x"'+sFile+'"')
                // refresh list after exiting the studio
                Send FillList to (oWorkspaceList(Self))
            End
            Else Begin
                Send Info_box (_T("Unable to locate the Visual DataFlex Studio to register this workspace.", 759))
            End
        End
    End_Procedure // Request_Browse

    #IFDEF TH_TRANSLATION
    Procedure Translate
        // Dialog Label
        Set Label                           to gILanguage[746]
        Set Label of oVDFVersion            to gILanguage[747]
        // Combo "Diplay"
        Set Label               of oDisplay_fm to gILanguage[748]
        Send Combo_Delete_Data  to oDisplay_fm
        Send Combo_Add_Item     to oDisplay_fm gILanguage[749]
        Send Combo_Add_Item     to oDisplay_fm gILanguage[750]
        Send Combo_Add_Item     to oDisplay_fm gILanguage[751]
        // Buttons
        Set Label of oInfo_bn               to gILanguage[752]
        Set Label of oBrowse_bn             to gILanguage[753]
        Set Label of oSelect_bn             to gILanguage[754]
        Set Label of oClose_bn              to gILanguage[755]
    End_Procedure
    #ENDIF

    Procedure Popup_Group
        String sVersion
        #IFDEF TH_TRANSLATION
        Send Translate
        #ENDIF
        Forward Send Popup_Group
        Get psVDFVersion of ghoWorkSpaceHandlerEx to sVersion
        Set value Of (oVDFVersion(Self)) To sVersion
        Send Activate   to (oWorkspaceList(Self))
    End_Procedure

Cd_End_Object    // oWorkSpace

