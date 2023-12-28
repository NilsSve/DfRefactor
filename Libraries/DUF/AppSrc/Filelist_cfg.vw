Use Windows.pkg
Use DFClient.pkg
Use vWin32fh.pkg
Use seq_chnl.pkg

Deferred_View Activate_oFilelist_cfg for ;
Object oFilelist_cfg is a dbView

    Set Border_Style to Border_Thick
    Set Size to 95 296
    Set Location to 2 2
    Set Label to "Filelist_cfg"

    Object oFilelist_fm is a Form
        Set Size to 13 243
        Set Location to 28 24
        Set Label to "Filelist.cfg:"
        Set Label_Col_Offset to 0
        Set Label_Row_Offset to 1
        Set Label_Justification_Mode to JMode_Top
        Set Prompt_Button_Mode to PB_PromptOn

        Procedure Prompt
            String sFileList sPath
            Get psDataPath of (phoWorkspace(ghoApplication)) to sPath
            Get vSelect_File "Fileist.cfg Files (*.cfg)|Filelist.cfg|All Files (*.*)|*.*" "Please select a Filelist.cfg file" sPath to sFileList
            If (sFileList <> "") Begin
                Set Value to sFileList
                Set_Attribute DF_FILELIST_NAME to sFileList
            End
        End_Procedure

        Procedure Activating
            String sFilelist
            Get psFileList of (phoWorkspace(ghoApplication)) to sFilelist
            Set Value to sFilelist
        End_Procedure

    End_Object

    Object oPrintFilelist_btn is a Button
        Set Location to 50 217
        Set Label to "Print Filelist"

        Procedure OnClick
            String sFileList sRootName sLogicalName sDisplayName sPath sOutputName sTable sExt
            Integer iCh
            Handle hTable

            Get Value of oFilelist_fm to sFileList
            Move (Trim(sFileList)) to sFileList
            If (sFileList = "") Begin
                Send Info_Box "You need to select a Filelist.cfg file first"
                Procedure_Return
            End

            Get ParseFolderName sFileList to sPath
            Get vFolderFormat sPath to sPath
            Get ParseFileName sFileList to sOutputName
            Get ParseFileExtension sFileList to sExt
            Move (Replace(sExt, sOutputName, "")) to sOutputName
            Move (sOutputName + "txt")           to sOutputName
            Get Seq_Open_Output_Channel (sPath + sOutputName) to iCh
            If (iCh < 0) Begin
                Close_Output
                Procedure_Return
            End

            Move 0 to hTable
            Writeln channel iCh sFileList
            Writeln channel iCh "[Table No:]            [LogicalName:]        [RootName:]                             [DisplayName:]"
            Writeln channel iCh "==================================================================================================="
            Writeln channel iCh

            Repeat
                Get_Attribute DF_FILE_NEXT_USED of hTable to hTable
                If (hTable > 0) Begin
                    Get_Attribute DF_FILE_LOGICAL_NAME of hTable to sLogicalName
                    Get_Attribute DF_FILE_ROOT_NAME    of hTable to sRootName
                    Get_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayName

                    Get PadLeft (String(hTable))        09 to sTable
                    Get PadLeft (String(sLogicalName)) (27 - Length(sTable))       to sLogicalName
                    Get PadLeft (String(sRootName))    (46 - Length(sLogicalName)) to sRootName
                    Get PadLeft (String(sDisplayName)) (72 - Length(sRootName))    to sDisplayName

                    Writeln channel iCh sTable sRootName sLogicalName sDisplayName
                End
            Until (hTable = 0)
            Close_Output

            Send vShellExecute "open" sOutputName "" sPath
        End_Procedure

        Function PadLeft String sString Integer iLength String sOptChar Returns String
            String sChar

            If (Num_Arguments >= 3) Begin
                Move sOptChar to sChar
            End
            Else Begin
                Move " " to sChar
            End

            While (Length(sString) < iLength)
                Move (sChar + sString) to sString
            Loop

            Function_Return sString
        End_Function

    End_Object

Cd_End_Object
