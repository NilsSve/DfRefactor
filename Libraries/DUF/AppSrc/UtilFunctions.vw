
Use Windows.pkg
Use DFClient.pkg
Use Dfline.pkg
Use cDbScrollingContainer.pkg
Use cRDCButtonDPI.pkg
Use cDbUpdateFunctionLibrary.pkg
Use Dftreevw.pkg
Use Working.pkg
Use DUFStatusPanel.pkg
Use cCharTranslate.pkg

Struct tFilelistDUF
    Integer iFileNumber
    String sLogicalName
    String sRootName
    String sDisplayName
End_Struct

Activate_View Activate_oUtilFunctions_vw for oUtilFunctions_vw
Object oUtilFunctions_vw is a dbView
    Set Border_Style to Border_Thick
    Set Size to 291 428
    Set Location to 2 1
    Set Label to "Utility Functions"
    Set pbAutoActivate to True
    Set Icon to "TestTools1.ico"
    Set pbAcceptDropFiles to True

    Object oScrollingContainer1 is a cDbScrollingContainer
        Object oScrollingClientArea1 is a cDbScrollingClientArea

            Object oSQL_grp is a Group
                Set Size to 88 402
                Set Location to 7 12
                Set Label to "Run SQL Database Scripts Embedded as Resources"
                Set peAnchors to anTopLeftRight

                Object oCreateOrderEntry_btn is a cRDCButtonDPI
                    Set Size to 14 219
                    Set Location to 13 13
                    Set Label to "Create New SQL Database [OrderEntry] Complete with Data"
                    Set psToolTip to "Creates the full Order Entry Sample database from the DataFlex samples complete with data with the name: [OrderEntry]"
                    Set psImage to "ActionCreateDatabase1.ico"

                    Procedure OnClick
                        String sInfoText sDriverID
                        Boolean bOK
                        TimeSpan tsTotalQueryTime
                        Integer iRetval

                        // The default path for the include_resource command is the Data folder. So anything else needs a pathing.
                        // Note: The file name and the resource name (the 'as' part) needs to be exactly the same.
                        SQLIncludeScriptFile ..\Scripts\CreateOrderEntry.sql as CreateOrderEntry.sql
                        Get YesNo_Box "This will run the 'CreateOrderEntry.sql' script from the 'Script' workspace folder which will create the [OrderEntry] database from the DataFlex samples for Microsoft SQL Server, complete with data. If it exists it will first be dropped, then re-created and populated with new data. Continue?" to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End

                        Get psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        If (sDriverID <> MSSQLDRV_ID) Begin
                            Send Info_Box "You need to have a Microsoft SQL Server connection active for this to work. Please adjust and try again."
                            Procedure_Return
                        End

                        Send StartWorkingMessage "Executing SQL Script. Please wait..."
                        Get SqlUtilExecuteResource of ghoDbUpdateFunctionLibrary "CreateOrderEntry.sql" MSSQLDRV_ID False to bOK
                        Send StopWorkingMessage

                        If (bOK = True) Begin
                            Get ptsTotalQueryTime of ghoDbUpdateFunctionLibrary to tsTotalQueryTime
                            Move ("Success! DataFlex Order Entry Sample Database was created as [OrderEntry]. Time elapsed:" * String(tsTotalQueryTime)) to sInfoText
                        End

                        Else Begin
                            Send _UtilShowErrorList of ghoDbUpdateFunctionLibrary
                            Move ("Nope, that didn't work. There was a problem running the script.\n\n" + "See Notepad for details...") to sInfoText
                        End

                        Send Info_Box sInfoText
                    End_Procedure

                End_Object

                Object oCreateNorthWind_btn is a cRDCButtonDPI
                    Set Size to 14 219
                    Set Location to 33 13
                    Set Label to "Create New SQL Database [NorthWind] Complete with Data"
                    Set psToolTip to "Creates the full NorthWind Sample database from the DataFlex samples complete with data with the name: [NorthWind]"
                    Set psImage to "ActionCreateDatabase1.ico"

                    Procedure OnClick
                        String sInfoText sDriverID
                        Boolean bOK
                        TimeSpan tsTotalQueryTime
                        Integer iRetval

                        // The default path for the include_resource command is the Data folder. So anything else needs a pathing.
                        // Note: The file name and the resource name (the 'as' part) needs to be exactly the same.
                        SQLIncludeScriptFile ..\Scripts\CreateNorthWindDatabase.sql as CreateNorthWindDatabase.sql

                        Get YesNo_Box "This will run the 'CreateNorthWindDatabase.sql' script from the 'Script' workspace folder and it will create the [NorthWind] sample database in Microsoft SQL Server, complete with data. If it exists it will first be dropped, then re-created and populated with new data. Continue?" to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End

                        Get psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        If (sDriverID <> MSSQLDRV_ID) Begin
                            Send Info_Box "You need to have a Microsoft SQL Server connection active for this to work. Please adjust and try again."
                            Procedure_Return
                        End

                        Send StartWorkingMessage "Executing SQL Script. Please wait..."
                        Get SqlUtilExecuteResource of ghoDbUpdateFunctionLibrary "CreateNorthWindDatabase.sql" MSSQLDRV_ID False to bOK
                        Send StopWorkingMessage

                        If (bOK = True) Begin
                            Get ptsTotalQueryTime of ghoDbUpdateFunctionLibrary to tsTotalQueryTime
                            Move ("Success! The Northwind Sample Database was created as [NorthWind]. Time elapsed:" * String(tsTotalQueryTime)) to sInfoText
                        End

                        Else Begin
                            Send _UtilShowErrorList of ghoDbUpdateFunctionLibrary
                            Move ("Nope, that didn't work. There was a problem running the script.\n\n" + "See Notepad for details...") to sInfoText
                        End

                        Send Info_Box sInfoText
                    End_Procedure

                End_Object

                Object oCreateFullChinookDatabase_btn is a cRDCButtonDPI
                    Set Size to 14 219
                    Set Location to 53 13
                    Set Label to "Create New SQL Database [Chinook] Complete with Data"
                    Set psToolTip to "Creates the Chinook demo database complete with data in Microsoft SQL Server. Note: If it exists it will first be dropped then recreated. Note: These scripts were part of Data Access Europe's '' training class."
                    Set psImage to "ActionCreateDatabase1.ico"

                    Procedure OnClick
                        String sInfoText sDriverID
                        Boolean bOK
                        TimeSpan tsTotalQueryTime
                        Integer iRetval

                        // The default path for the include_resource command is the Data folder. So anything else needs a pathing.
                        // Note: The file name and the resource name (the 'as' part) needs to be exactly the same.
                        SQLIncludeScriptFile ..\Scripts\CreateChinookDatabase.sql as CreateChinookDatabase.sql

                        Get YesNo_Box "This will run the 'CreateChinookDatabase.sql' script from the 'Script' workspace folder which will create the [Chinook] sample database complete with data. If it exists it will first be dropped, then re-created and populated with new data.\n\nContinue?" to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End
                        Get psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        If (sDriverID <> MSSQLDRV_ID) Begin
                            Send Info_Box "You need to have a Microsoft SQL Server connection active for this to work. Please adjust and try again."
                            Procedure_Return
                        End

                        Send StartWorkingMessage "Executing SQL Script. Please wait..."

                        Get SqlUtilExecuteResource of ghoDbUpdateFunctionLibrary "CreateChinookDatabase.sql" MSSQLDRV_ID False to bOK

                        Send StopWorkingMessage
                        If (bOK = True) Begin
                            Get ptsTotalQueryTime of ghoDbUpdateFunctionLibrary to tsTotalQueryTime
                            Move ("Success! The script was run OK. Time elapsed:" * String(tsTotalQueryTime)) to sInfoText
                        End

                        Else Begin
                            Send _UtilShowErrorList of ghoDbUpdateFunctionLibrary
                            Move ("Nope, that didn't work. There was a problem running the script.\n\n" + "See Notepad for details...") to sInfoText
                        End

                        Send Info_Box sInfoText
                    End_Procedure

                End_Object

                Object oInfo_tb is a TextBox
                    Set Auto_Size_State to False
                    Set Size to 25 158
                    Set Location to 53 238
                    Set Label to "Note: The Chinook script was provided by Data Access Europe as part of their 'Web Touch Training' course."
                    Set Justification_Mode to JMode_Left
                    Set peAnchors to anTopLeftRight
                End_Object

        //  This will choke the computer so don't try it!
        //        Object oCreateAdventureWorksDatabase_btn is a cRDCButtonDPI
        //            Set Size to 14 312
        //            Set Location to 97 45
        //            Set Label to "Create [AdventureWorks] Database and Populate with Data"
        //            Set psToolTip to "Creates the Adenture Works database complete with data in Microsoft SQL Server. Note: If it exists it will first be dropped then recreated."
        //
        //            Procedure OnClick
        //                String sInfoText
        //                Boolean bOK
        //                TimeSpan tsTotalQueryTime
        //                Integer iRetval
        //
        //                // The default path for the include_resource command is the Data folder. So anything else needs a pathing.
        //                // Note: The file name and the resource name (the 'as' part) needs to be exactly the same.
        ////                SQLIncludeScriptFile ..\Scripts\CreateAdventureWorks.sql as CreateAdventureWorks.sql
        //Procedure_Return
        //                Get YesNo_Box "This will create the [AdventurWorks] sample database complete with data. If it exists it will first be dropped, then re-created and populated with new data.\n\nContinue?" to iRetval
        //                If (iRetval <> MBR_Yes) Begin
        //                    Procedure_Return
        //                End
        //
        //                Send StartWorkingMessage "Executing SQL Script. Please wait..."
        //                Get SqlUtilExecuteResource of ghoDbUpdateFunctionLibrary "CreateAdventureWorks.sql" MSSQLDRV_ID False to bOK
        //                Send StopWorkingMessage
        //
        //                If (bOK = True) Begin
        //                    Get ptsTotalQueryTime of ghoDbUpdateFunctionLibrary to tsTotalQueryTime
        //                    Move ("Success! The script was run OK. Time elapsed:" * String(tsTotalQueryTime)) to sInfoText
        //                End
        //
        //                Else Begin
        //                    Send _UtilShowErrorList of ghoDbUpdateFunctionLibrary
        //                    Move ("Nope, that didn't work. There was a problem running the script.\n\n" + "See Notepad for details...") to sInfoText
        //                End
        //
        //                Send Info_Box sInfoText
        //            End_Procedure
        //
        //        End_Object

            End_Object

            Object oChangeIntFiles_grp is a Group
                Set Size to 65 402
                Set Location to 102 12
                Set Label to "Change Old .int files to use Connection ID's"
                Set peAnchors to anTopLeftRight

                Object oSelectDataPath_fm is a Form
                    Set Size to 12 300
                    Set Location to 22 13
                    Set Label to "Select path to a Data folder with .int files (Select one '.int' file):"
                    Set Label_Col_Offset to 0
                    Set Label_Row_Offset to 1
                    Set Label_Justification_Mode to JMode_Top

                    // This is very strange but for some reason the tooltip is _not_ displayed if PB_PromptOn is set...
        //            Set Prompt_Button_Mode to PB_PromptOn
                    Set psToolTip to "You can use this if you have .int files that currently have content like; 'SERVER=xxx; DATABASE=yyy' et.al. and you need to change them to use a connection ID like; 'SERVER_NAME DFCONNID=MyConnID'"
                    Set peAnchors to anTopLeftRight

                    Procedure Prompt
                        String sPath sFileMask sRetval

                        Get psDataPathFirstPart to sPath
                        Move "Database intermediate files (*.int)|*.int" to sFileMask
                        Get vSelect_File sFileMask "Please select an .int file from the data folder" sPath to sRetval
                        If (sRetval <> "") Begin
                            Get ParseFolderName sRetval to sPath
                            If (Right(sPath, 1) ="\") Begin
                                Move (Left(sPath, Length(sPath) -1)) to sPath
                            End
                            Set Value to sPath
                        End
                    End_Procedure

                    // Returns the first datapath found in the psDataPath property.
                    // The returned path always ends with a "\"
                    Function psDataPathFirstPart Returns String
                        String sDataPath
                        Integer iCount

                        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
                        Get CountOfPaths of (phoWorkspace(ghoApplication)) sDataPath to iCount
                        If (iCount > 1) Begin
                            Get PathAtIndex of (phoWorkspace(ghoApplication)) sDataPath 1 to sDataPath
                        End
                        If (sDataPath <> "") Begin
                            Get vFolderFormat sDataPath to sDataPath
                        End

                        Function_Return sDataPath
                    End_Function

                End_Object

                Object oSelectFolder_btn is a cRDCButtonDPI
                    Set Size to 13 73
                    Set Location to 22 320
                    Set Label to "Select Folder"
                    Set psToolTip to "Please select an .int file from the data folder"
                    Set peAnchors to anTopRight
                    Set psImage to "ActionOpen1.ico"

                    Procedure OnClick
                        Send Prompt to oSelectDataPath_fm
                    End_Procedure

                End_Object

                Object oConnectionID_fm is a Form
                    Set Size to 13 111
                    Set Location to 38 202
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set Label to "Change to DFConnID:"
                    Set psToolTip to "Please enter your Connection ID (DFCONNID=) that should replace the SERVER_NAME settings for all .int files in the selected folder."
                    Set peAnchors to anTopRight
                End_Object

                Object oChangeAllIntFiles_btn is a cRDCButtonDPI
                    Set Size to 13 68
                    Set Location to 38 320
                    Set Label to "GO !"
                    Set psToolTip to "Changes or updates all .int files in the selected folder - except for DAW driver .int files (MSSQL_DRV.int, DB2_DRV.int & ODBC_DRV.int) - to use 'SERVER_NAME DFCONNID=xxx'"
                    Set FontWeight to fw_Bold
                    Set peAnchors to anTopRight

                    Procedure OnClick
                        String sDataPath sConnectionID
                        Boolean bExists bActive
                        Integer iRetval

                        Get Value of oSelectDataPath_fm to sDataPath
                        Get vFolderExists sDataPath to bExists
                        If (bExists = False) Begin
                            Send Info_Box ("The data folder doesn't exist!\n" + sDataPath)
                            Procedure_Return
                        End
                        Get Value of oConnectionID_fm to sConnectionID
                        Move (Trim(sConnectionID)) to sConnectionID
                        If (sConnectionID = "") Begin
                            Send Info_Box "You need to specify a Connection_ID to use for the .int files."
                            Procedure_Return
                        End

                        Get YesNo_Box ("Do you want to change all .int files in folder:\n" + sDataPath + "\n\nTo use 'DFCONNID=" + sConnectionID +"' ?") to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End
                        Get YesNo_Box "All '.CCH' files will first be deleted. Continue?" to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End

                        Get vDeleteFile (sDataPath + "\*.cch") to iRetval
                        If (iRetval <> 0) Begin
                            Send Info_Box "Could not delete .cch files!"
                            Procedure_Return
                        End

                        Send Initialize_StatusPanel of ghoStatusPanel "The Database Update Framework" "Changing Connection ID's in .int files" ""
                        Send Start_StatusPanel of ghoStatusPanel
                        Send SqlUtilChangeIntFilesToConnectionIDs of ghoDbUpdateFunctionLibrary sDataPath sConnectionID True

                        Get Active_State of ghoStatusPanel to bActive
                        If (bActive = False) Begin
                            Send Info_Box "Process interupted..."
                        End
                        Else Begin
                            Send Stop_StatusPanel of ghoStatusPanel
                            Send Info_Box "Ready! All .int files changed."
                        End
                    End_Procedure

                End_Object

            End_Object

            Object oRemoveFilelistDriverIDs_grp is a Group
                Set Size to 59 402
                Set Location to 171 12
                Set Label to "Remove Database Identifications from Filelist.cfg"
                Set peAnchors to anTopLeftRight
//                Set TextColor to clGreen
//
//                Procedure Page Integer iPage
//                    Integer ia iz
//                    Forward Send Page iPage
//                    Move 0 to iz
//                    Move (AddressOf(iz)) to ia
//                    Move (SetWindowTheme(Window_Handle(Self),ia,ia)) to iPage
//                End_Procedure

                Object oFilelistPath_fm is a Form
                    Set Size to 13 299
                    Set Location to 22 13
                    Set Label to "Path and Filelist.cfg Name:"
                    Set Label_Col_Offset to 0
                    Set Label_Row_Offset to 1
                    Set Label_Justification_Mode to JMode_Top

                    // This is very strange but for some reason the tooltip is _not_ displayed if PB_PromptOn is set...
        //            Set Prompt_Button_Mode to PB_PromptOn
                    Set psToolTip to "You can use this if you have entries in a Filelist.cfg with driver prefixes like 'MSSQLDRV;Customer' and you need to remove them all."
                    Set peAnchors to anTopLeftRight

                    Procedure Prompt
                        String sFileName sPath sFileMask sRetval

                        Get Value to sFileName
                        Get ParseFolderName sFileName to sPath
                        Move "Filelist.cfg files (*.cfg)|*.cfg" to sFileMask
                        Get vSelect_File sFileMask "Please select a Filelist.cft file" sPath to sRetval
                        If (sRetval <> "") Begin
                            Set Value to sRetval
                            Set_Attribute DF_FILELIST_NAME to sRetval
                        End
                    End_Procedure

                    Procedure OnCreate
                        String sFilelist
                        Get_Attribute DF_FILELIST_NAME to sFilelist
                        Set Value to sFilelist
                    End_Procedure
                    Send OnCreate

                End_Object

                Object oSelectFilelist_btn is a cRDCButtonDPI
                    Set Size to 13 73
                    Set Location to 22 319
                    Set Label to "Select Filelist.cfg"
                    Set psToolTip to "Please select a Filelist.cfg file to be changed"
                    Set peAnchors to anTopRight

                    Procedure OnClick
                        Send Prompt to oFilelistPath_fm
                    End_Procedure

                End_Object

                Object oInfo_tb is a TextBox
                    Set Size to 9 207
                    Set Location to 40 138
                    Set Label to "Remove database driver identifications from Filelist.cfg:"
                    Set peAnchors to anTopRight
                End_Object

                Object oChangeFilelist_btn is a cRDCButtonDPI
                    Set Size to 13 68
                    Set Location to 38 319
                    Set Label to "GO !"
                    Set FontWeight to fw_Bold
                    Set peAnchors to anTopRight
                    Set psToolTip to 'Removes all database driver identificatins from Filelist.cfg, such as: "MSSQLDRV:MyTable"'

                    Procedure OnClick
                        String sFileList
                        Integer iRetval iCount
                        Boolean bExits

                        Get Value of oFilelistPath_fm to sFileList
                        Get vFilePathExists sFileList to bExits
                        If (bExits = False) Begin
                            Send Info_Box ("Sorry, the Filelist.cfg does not exist;\n" + sFileList)
                            Procedure_Return
                        End

                        Get YesNo_Box ("Are you sure you want to remove all driver identifications for the following Filelist.cfg?\n" + sFileList) to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End
                        Send Cursor_Wait of Cursor_Control

                        Get SqlUtilFilelistRemoveDriverInfo of ghoDbUpdateFunctionLibrary sFileList to iCount

                        Send Cursor_Ready of Cursor_Control
                        If (iCount <> 0) Begin
                            Send Info_Box ("Ready!" * String(iCount) * "Filelist.cfg entries adjusted.")
                        End
                        Else Begin
                            Send Info_Box "Ready. No driver based Filelist entries found."
                        End

                    End_Procedure

                End_Object

            End_Object

            Object oOutput_grp is a Group
                Set Size to 47 402
                Set Location to 234 12
                Set Label to "Print sekected Filelist.cfg as a Text file"
                Set peAnchors to anTopLeftRight

                Object oOutput_rg is a RadioGroup
                    Set Location to 18 13
                    Set Size to 25 288
                    Set Label to "Filelist Output Order"

                    Object oRadio1 is a Radio
                        Set Label to "Filelist Number"
                        Set Size to 10 61
                        Set Location to 10 7
                    End_Object

                    Object oRadio2 is a Radio
                        Set Label to "Logical Name"
                        Set Size to 10 61
                        Set Location to 10 77
                    End_Object

                    Object oRadio3 is a Radio
                        Set Label to "Root Name"
                        Set Size to 10 61
                        Set Location to 10 147
                    End_Object

                    Object oRadio4 is a Radio
                        Set Label to "Display Name"
                        Set Size to 10 62
                        Set Location to 10 213
                    End_Object

                    Procedure Notify_Select_State Integer iToItem Integer iFromItem
                        Forward Send Notify_Select_State iToItem iFromItem
                        Set piSortOrder of oPrintFilelist_btn to iToItem
                    End_Procedure

                End_Object
                
                Object oPrintFilelist_btn is a cRDCButtonDPI
                    Set Size to 13 78
                    Set Location to 26 315
                    Set Label to "Print to Filelist.txt"
                    Set psToolTip to "Writes the content of Filelist.cfg to a textfile and shows the textfile in the editor program asociated with *.txt files."
                    Set psImage to "ActionDocument1.ico"

                    Property Integer piSortOrder 0 // Property gets set by the radio group object.

                    // Custom array sort function.
                    // iSortOrder = 0 -> Filelist number order
                    // iSortOrder = 1 -> Logical name order
                    // iSortOrder = 2 -> Root name order
                    // iSortOrder = 3 -> Display name order
                    Function CompareSortFilelist tFilelistDUF FilelistDUF1 tFilelistDUF FilelistDUF2 Returns Integer
                        Integer iSortOrder

                        Get piSortOrder to iSortOrder

                        Case Begin
                            Case (iSortOrder = 0)
                                If (FilelistDUF1.iFileNumber  > FilelistDUF2.iFileNumber) Begin
                                    Function_Return (GT)
                                End
                                If (FilelistDUF1.iFileNumber  < FilelistDUF2.iFileNumber) Begin
                                    Function_Return (LT)
                                End
                                Function_Return (EQ)
                            Case (iSortOrder = 1)
                                If (Uppercase(FilelistDUF1.sLogicalName) > Uppercase(FilelistDUF2.sLogicalName)) Begin
                                    Function_Return (GT)
                                End
                                If (Uppercase(FilelistDUF1.sLogicalName) < Uppercase(FilelistDUF2.sLogicalName)) Begin
                                    Function_Return (LT)
                                End
                                Function_Return (EQ)
                            Case (iSortOrder = 2)
                                If (Uppercase(FilelistDUF1.sRootName)    > Uppercase(FilelistDUF2.sRootName)) Begin
                                    Function_Return (GT)
                                End
                                If (Uppercase(FilelistDUF1.sRootName)    < Uppercase(FilelistDUF2.sRootName)) Begin
                                    Function_Return (LT)
                                End
                                Function_Return (EQ)
                            Case (iSortOrder = 3)
                                If (Uppercase(FilelistDUF1.sDisplayName) > Uppercase(FilelistDUF2.sDisplayName)) Begin
                                    Function_Return (GT)
                                End
                                If (Uppercase(FilelistDUF1.sDisplayName) < Uppercase(FilelistDUF2.sDisplayName)) Begin
                                    Function_Return (LT)
                                End
                                Function_Return (EQ)
                        Case End

                    End_Function

                    Procedure OnClick
                        String sFileList sRootName sLogicalName sDisplayName sPath sOutputName sTable sExt
                        Integer iCh iCount iSize
                        Handle hTable
                        tFilelistDUF[] FilelistDUFArray FilelistDUFSorted

                        Get Value of oFilelistPath_fm to sFileList
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
                            Procedure_Return
                        End

                        Move 0 to hTable
                        Writeln channel iCh sFileList
                        Writeln channel iCh "[Table No:]            [LogicalName:]        [RootName:]                             [DisplayName:]"
                        Writeln channel iCh "==================================================================================================="
                        Writeln channel iCh

                        Move 0 to iCount
                        Repeat
                            Get_Attribute DF_FILE_NEXT_USED of hTable to hTable
                            If (hTable > 0) Begin
                                Move hTable                                  to FilelistDUFArray[iCount].iFileNumber
                                Get_Attribute DF_FILE_LOGICAL_NAME of hTable to FilelistDUFArray[iCount].sLogicalName
                                Get_Attribute DF_FILE_ROOT_NAME    of hTable to FilelistDUFArray[iCount].sRootName
                                Get_Attribute DF_FILE_DISPLAY_NAME of hTable to FilelistDUFArray[iCount].sDisplayName
                                Increment iCount
                            End
                        Until (hTable = 0)

                        Move (SortArray(FilelistDUFArray, Self, (RefFunc(CompareSortFilelist)))) to FilelistDUFSorted
                        Move (SizeOfArray(FilelistDUFSorted)) to iSize
                        Decrement iSize

                        For iCount from 0 to iSize
                            Move FilelistDUFSorted[iCount].iFileNumber  to hTable
                            Move FilelistDUFSorted[iCount].sLogicalName to sLogicalName
                            Move FilelistDUFSorted[iCount].sRootName    to sRootName
                            Move FilelistDUFSorted[iCount].sDisplayName to sDisplayName

                            Get PadLeft (String(hTable))        09 to sTable
                            Get PadLeft (String(sLogicalName)) (27 - Length(sTable))       to sLogicalName
                            Get PadLeft (String(sRootName))    (46 - Length(sLogicalName)) to sRootName
                            Get PadLeft (String(sDisplayName)) (72 - Length(sRootName))    to sDisplayName

                            Writeln channel iCh sTable (Utf8ToAnsi(sRootName)) (Utf8ToAnsi(sLogicalName)) (Utf8ToAnsi(sDisplayName))
                        Loop

                        Writeln channel iCh "==================================================================================================="
                        Writeln channel iCh "Total Number of Tables in Filelist.cfg: " (iSize + 1)
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
            End_Object

        End_Object

    End_Object

    Procedure OnFileDropped String sFilename Boolean bLast
        String sTest
        Forward Send OnFileDropped sFilename bLast
        If (bLast = True) Begin
            Get ParseFileName sFilename to sTest
            If (Uppercase(sTest) <> "FILELIST.CFG") Begin
                Send Info_Box "Sorry, only Filist.cfg files can be dropped here..."
                Procedure_Return
            End
            Set Value of oFilelistPath_fm to sFilename
        End
    End_Procedure

End_Object
