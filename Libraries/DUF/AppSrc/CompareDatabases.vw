Use Windows.pkg
Use Dfclient.pkg
Use Cursor.pkg
Use Batchdd.pkg
Use cRDCButton.pkg
Use cDbUpdateFunctionLibrary.pkg
Use DUFStatusPanel.pkg
Use seq_chnl.pkg
Use vWin32fh.pkg
Use cRDCHeaderGroup.pkg
Use cRDCSuggestionIniForm.pkg
Use cSQLCheckBox.pkg
Use cRDCCommandLinkButton.pkg
Use LogFileDialog.dg

Define CS_ReportFileName                for "DUFCompareReport"
Define CS_ReportFileNameExtenstion      for ".txt"
Define CS_ReportDifferenceNote          for "(*)"
Define CS_ReportTableNotFound           for "Table doesn't exist!"
Define CS_ReportFieldNotFound           for "Field doesn't exist!"
Define CS_ReportIndexNotFound           for "Index doesn't exist!"
Define CS_ReportIndexSegmentNotFound    for "Index segment doesn't exist!"
Define CS_ReportIndexNotApplicable      for "N/A"
Define CS_ReportRelationNotFound        for "Relationship doesn't exist!"
Define CS_ReportHeaderUnderWrite        for "===================================================================================="

Define CI_ReportColumn1                 for 17
Define CI_ReportColumn2                 for 65
//Define CI_ReportColumn3                 for 75
//Define CI_ReportColumn4                 for 90

Struct tRelationDiffs
    String sFromFieldsRight
    String sFromFields
    String sToFields
    String sFrom
    String sTo
End_Struct

Global_Variable Integer giDifferenceTables

Activate_View Activate_oCompareDatabases_vw for oCompareDatabases_vw
Object oCompareDatabases_vw is a dbView
    Set Size to 323 490
    Set Label to "Compare"
    Set piMinSize to 89 211
    Set Border_Style To Border_Thick
    Set pbAutoActivate to True
    Set pbAcceptDropFiles to True

    Object oFromFilelist_grp is a cRDCHeaderGroup
        Set Size to 50 462
        Set Location to 8 15
        Set psImage to "FolderLeft1.ico"
        Set Label to "Select FROM Filelist.cfg"
        Set psNote to "The development/latest version of the database"  
        Set psToolTip to "Select the Filelist.cfg file for the development database"

        Object oFilelistPathFrom_fm is a cRDCSuggestionIniForm
            Set Size to 12 413
            Set Location to 29 29
            Set Label_Col_Offset to 0
            Set Label_Row_Offset to 1
            Set Label_Justification_Mode to JMode_Top
            Set Prompt_Button_Mode to PB_PromptOn
            Set peAnchors to anTopLeftRight
            Set psToolTip to "Select the FROM database Filelist.cfg. This should be the development workspace Data folder's Filelist.cfg"
            // This is needed for the toolbar's prompt icon to be active
            Set Prompt_Object to Self

            Procedure Prompt
                String sFileName sPath sFileMask sRetval

                Get Value to sFileName
                Get ParseFolderName sFileName to sPath
                Move "Filelist.cfg files (*.cfg)|*.cfg" to sFileMask
                Get vSelect_File sFileMask "Please select a Filelist.cfg file" sPath to sRetval
                If (sRetval <> "") Begin
                    Set Value to sRetval
                End
            End_Procedure

            Procedure OnChange
                String sValue
                Boolean bOK bCfgFile

                Get Value to sValue
                Get vFilePathExists sValue to bOK
                Move (Lowercase(sValue) contains ".cfg") to bCfgFile
                If (bOK = True and bCfgFile) Begin
                    Get ChangeFilelistPathing of ghoApplication sValue to bOK
                    If (bOK = True) Begin
                        Set psFilelistFrom of ghoApplication to sValue
                    End
                End

            End_Procedure

            On_Key Key_Ctrl+Key_W Send None
            On_Key Key_Ctrl+Key_Q Send None
        End_Object

    End_Object

    Object oToFilelist_grp is a cRDCHeaderGroup
        Set Size to 50 462
        Set Location to 69 15
        Set psImage to "FolderRight1.ico"
        Set Label to "Select TO Filelist.cfg"
        Set psNote to "The customer/current version of the database"   
        Set psToolTip to "Select the Filelist.cfg file for the database that needs to be updated"

        Object oFilelistPathTo_fm is a cRDCSuggestionIniForm
            Set Size to 12 413
            Set Location to 29 28
            Set Label_Col_Offset to 0
            Set Label_Row_Offset to 1
            Set Label_Justification_Mode to JMode_Top
            Set Prompt_Button_Mode to PB_PromptOn
            Set peAnchors to anTopLeftRight
            Set psToolTip to "Select the TO database Filelist.cfg"
            Set Prompt_Object to Self

            Procedure Prompt
                String sFileName sPath sFileMask sRetval

                Get Value to sFileName
                Get ParseFolderName sFileName to sPath
                Move "Filelist.cfg files (*.cfg)|*.cfg" to sFileMask
                Get vSelect_File sFileMask "Please select a Filelist.cfg file" sPath to sRetval
                If (sRetval <> "") Begin
                    Set Value to sRetval
                End
            End_Procedure

            Procedure OnChange
                String sValue sPath sReportName sToday
                Date dToday
                Boolean bOK bCfgFile

                Get Value to sValue
                Get vFilePathExists sValue to bOK
                Move (Lowercase(sValue) contains ".cfg") to bCfgFile
                If (bOK = False or bCfgFile = False) Begin
                    Procedure_Return
                End

                Set psFilelistFrom of ghoApplication to sValue
                Sysdate dToday  
                Move dToday to sToday
                Move (Replaces("/", sToday, "-")) to sToday
                Move (Replaces(".", sToday, "-")) to sToday
                Get Value to sPath
                Get ParseFolderName sPath to sPath
                Get vFolderFormat   sPath to sPath
                Move (sPath + CS_ReportFileName + String(sToday) + CS_ReportFileNameExtenstion) to sReportName
                Set Value of oReportFileName_fm to sReportName
            End_Procedure

            On_Key Key_Ctrl+Key_W Send None
            On_Key Key_Ctrl+Key_Q Send None
        End_Object

    End_Object

    Object oCompareProperties_grp is a cRDCHeaderGroup
        Set Size to 59 462
        Set Location to 130 15
        Set Label to "Configure Database Compare"
        Set psNote to "Select checkboxes to configure the comparison"
        Set psImage to "Settings1.ico" 
        Set psToolTip to "Configure what will be compared"
        
        Object oCompareDate_DataTime_cb is a cSQLCheckBox
            Set Size to 9 123
            Set Location to 28 30
            Set Label to "Check Date/DataTime difference"
            Set psToolTip to "Check Date to DateTime column differences"
            Set Checked_State to False
        End_Object

        Object oCompareIndexAscending_cb is a cSQLCheckBox
            Set Size to 9 134
            Set Location to 28 199
            Set Label to "Check Index Ascending/Descending"
            Set Checked_State to False
            Set psToolTip to "Compare if Index is Ascending/Descending. (In SQL this setting is set for the whole database by selecting a 'Collation', so then checking this per table doesn't make sense)"
        End_Object

        Object oCompareIndexUppercase_cb is a cSQLCheckBox
            Set Size to 9 117
            Set Location to 41 30
            Set Label to "Check Index Lower/Uppercase"
            Set Checked_State to False
            Set psToolTip to "Compare if Index is Uppercase/Lowercase. (In SQL this setting is set for the whole database by selecting a 'Collation', so then checking this per table doesn't make sense)"
        End_Object

        Object oIgnoreFilelistUppercase_cb is a cSQLCheckBox
            Set Size to 9 156
            Set Location to 41 199
            Set Label to "Ignore Filelist Entries Uppercase/Lowercase"
            Set Checked_State to True
            Set psToolTip to "Check Filelist.cfg RootName, LogicalName and DisplayName uppercase/lowercase differences"
        End_Object

    End_Object

    Object oReportFilename_grp is a cRDCHeaderGroup
        Set Size to 51 462
        Set Location to 200 15
        Set psImage to "ActionPrintSave1.ico"
        Set Label to "Report File Name"
        Set psNote to "Output file name"    
        Set psToolTip to "The name of the report file that contains the compare result"
        
        Object oReportFileName_fm is a Form
            Set Size to 12 413
            Set Location to 29 29
            Set Label_Col_Offset to 0
            Set Label_Row_Offset to 1
            Set Label_Justification_Mode to JMode_Top
            Set Prompt_Button_Mode to PB_PromptOn
            Set peAnchors to anTopLeftRight
            Set psToolTip to "The name of the output text file for database differences that will be generated"
            Set Status_Help to "The name of the output text file for database differences that will be generated"
            Set Prompt_Object to Self

            Procedure Prompt
                String sFileName sPath sFileMask sRetval

                Get Value to sFileName
                Get ParseFolderName sFileName to sPath
                Move "Text files (*.txt)|*.txt" to sFileMask
                Get vSelect_File sFileMask "Please select a text file for the report" sPath to sRetval
                If (sRetval <> "") Begin
                    Set Value to sRetval
                End
            End_Procedure

            On_Key Key_Ctrl+Key_W Send None
            On_Key Key_Ctrl+Key_Q Send None
        End_Object

    End_Object

    Procedure MainProcess
        String sFilelistFrom sFilelistTo
        Integer[] iaDifferences
        Integer iSize iRetval hTable
        Boolean bFromExists bToExists
        tAPITableBooleans CompareCheckBoxes
        DateTime dtExecStart dtExecEnd
        TimeSpan tsTotalTime

        Move (CurrentDateTime()) to dtExecStart
        Get Value of oFilelistPathFrom_fm to sFilelistFrom
        Get vFilePathExists sFilelistFrom to bFromExists
        Get Value of oFilelistPathTo_fm   to sFilelistTo
        Get vFilePathExists sFilelistTo   to bToExists

        If (bFromExists = False or bToExists = False) Begin
            Send Info_Box "You first need to select a 'FROM' and a 'TO' Filelist.cfg."
            Procedure_Return
        End

        Move 0 to giDifferenceTables
        Get Checked_State of oCompareDate_DataTime_cb    to CompareCheckBoxes.bCompareDate_DateTime
        Get Checked_State of oCompareIndexAscending_cb   to CompareCheckBoxes.bCompareIndexAscending
        Get Checked_State of oCompareIndexUppercase_cb   to CompareCheckBoxes.bCompareIndexUppercase
        Get Checked_State of oIgnoreFilelistUppercase_cb to CompareCheckBoxes.bCompareFilelistUppercase

        Get CompareAndOutputDiffs sFilelistFrom sFilelistTo CompareCheckBoxes dtExecStart to iaDifferences
        Set piaDifferences of ghoApplication to iaDifferences

        Send Stop_StatusPanel of ghoStatusPanel
        Move (CurrentDateTime()) to dtExecEnd
        Move (dtExecEnd - dtExecStart) to tsTotalTime
        Move (SizeOfArray(iaDifferences)) to iSize

        Case Begin
            Case (iSize = 0)
                Send Info_Box "No differences found. The two databases should be identical."
                Case Break
            Case (iaDifferences[0] >= 1)
                Get YesNo_Box ("Ready! (Time elapsed:" * String(tsTotalTime) + ")\n" + String(iSize) * "Differences found. View the report now?") to iRetval
                If (iRetval = MBR_Yes) Begin
                    Send DoShowReport of oViewReport_Btn
                End
                Case Break
            Case (iaDifferences[0] = -1)
                Send Info_Box "Process interrupted."
                Case Break
            Case (iaDifferences[0] < -1)
                Move iaDifferences[0]  to hTable
                Move (999999 + hTable * -1) to hTable
                Send Info_Box ("Process not complete. Couldn't open table number:" * String(hTable))
                Send DoShowReport of oViewReport_Btn
                Case Break
            Case Else
                Send Info_Box "An unknown error occured. Process interrupted."
        Case End

        Send Activate of oFilelistPathFrom_fm
    End_Procedure

    Function CompareAndOutputDiffs String sFilelistFrom String sFilelistTo tAPITableBooleans CompareCheckBoxes DateTime dtExecStart Returns Integer[]
        Integer iSize iCount iNoOfTablesFrom iNoOfTablesTo iCh
        Boolean bIsSame bFilelistError bUserCancel bOK bCollationDiff bIsEmbedded
        Handle hTable
        String sLogicalName sDatabaseCollationFrom sDatabaseCollationTo sDatabase
        tAPITable[] aFromStructure aToStructure
        tAPITableCompare[] aAPITableCompare
        Integer[] iaDifferences iaDifferencesEmpty 

        Set Message_Text of ghoStatusPanel to ""
        // Set up the pathing correctly for the 'FROM' Filelist.cfg so we can open tables:
        Get ChangeFilelistPathing of ghoApplication sFilelistFrom to bOK
        If (bOK = False) Begin
            Move -1 to iaDifferencesEmpty[0]
            Function_Return iaDifferencesEmpty
        End       
        Get UtilIsAllFilelistEntriesDataFlexTables of ghoDbUpdateFunctionLibrary to bIsEmbedded
        If (bIsEmbedded = False) Begin
            Get psDatabase of ghoDbUpdateFunctionLibrary to sDatabase
            Get SqlDatabaseCollationQuery of ghoDbUpdateFunctionLibrary sDatabase True to sDatabaseCollationFrom
        End 
        Else Begin
            Move "Embedded Database (DataFlex)" to sDatabaseCollationFrom
        End

        Get UtilFilelistNoOfTables of ghoDbUpdateFunctionLibrary to iNoOfTablesFrom
        Set pbVisible   of ghoProgressBar        to True
        Set piPosition  of ghoProgressBar        to 0
        Set piAdvanceBy of ghoProgressBar        to 1
        Set pbVisible   of ghoProgressBarOverall to True
        Set piPosition  of ghoProgressBarOverall to 0
        Set piAdvanceBy of ghoProgressBarOverall to 1
        Set piMaximum   of ghoProgressBarOverall to iNoOfTablesFrom
        
        // *** Fill the 'FROM' structure with data: (1 of 3)
        Get UtilTablesStructArrayFill of ghoDbUpdateFunctionLibrary True True True to aFromStructure
        
        // Process cancelled by user?
        If (aFromStructure[0].bCancel = True) Begin
            Move -1 to iaDifferencesEmpty[0]
            Function_Return iaDifferencesEmpty
        End
        
        // Error while filling struct array (Table could not be opened)?
        If (aFromStructure[0].bError = True) Begin
            Move aFromStructure[0].ApiTableInfo.iTableNumber to hTable
            Move (-999999 - hTable) to iaDifferencesEmpty[0]
            Function_Return iaDifferencesEmpty
        End

        // Set up the pathing correctly for the 'TO' Filelist.cfg so we can open tables from the other workspace:
        Get ChangeFilelistPathing of ghoApplication sFilelistTo to bOK
        If (bOK = False) Begin
            Move -1 to iaDifferencesEmpty[0]
            Function_Return iaDifferencesEmpty
        End

        If (bIsEmbedded = False) Begin
            Get psDatabase of ghoDbUpdateFunctionLibrary to sDatabase
            Get SqlDatabaseCollationQuery of ghoDbUpdateFunctionLibrary sDatabase True to sDatabaseCollationTo
        End 
        Else Begin
            Move "Embedded Database (DataFlex)" to sDatabaseCollationTo
        End

        Get UtilFilelistNoOfTables of ghoDbUpdateFunctionLibrary to iNoOfTablesTo
        Set piMaximum of ghoProgressBarOverall to iNoOfTablesTo
        Set piAdvanceBy of ghoProgressBarOverall to 1

        // *** Fill the 'TO' structure with data: (2 of 3)
        Get UtilTablesStructArrayFill of ghoDbUpdateFunctionLibrary True True False to aToStructure
        // Process cancelled by user?
        If (aToStructure[0].bCancel = True) Begin
            Move -1 to iaDifferencesEmpty[0]
            Function_Return iaDifferencesEmpty
        End
        // Error while filling struct array (Table could not be opened)?
        If (aToStructure[0].bError = True) Begin
            Move aToStructure[0].ApiTableInfo.iTableNumber to hTable
            Move (-999999 - hTable) to iaDifferencesEmpty[0]
//            Function_Return iaDifferencesEmpty
        End

        Set Message_Text of ghoStatusPanel to "Comparing and Writing Differences: (3 of 3)"
        Move 0 to hTable
        Move 0 to iCount
        Get WriteReportHeader sDatabaseCollationFrom sDatabaseCollationTo to iCh

        Get UtilTableCombineFromAndToArrays of ghoDbUpdateFunctionLibrary aFromStructure aToStructure to aAPITableCompare
        Move (SizeOfArray(aAPITableCompare))   to iSize
        Set piMaximum of ghoProgressBar        to iSize
        Set piMaximum of ghoProgressBarOverall to iSize
        Decrement iSize

        For iCount from 0 to iSize
            Move True to bIsSame
            Set piPosition of ghoProgressBarOverall to iCount
            Move aAPITableCompare[iCount].hTable to hTable

            If (aAPITableCompare[iCount].bExistsFrom = True) Begin
                Move aAPITableCompare[iCount].APITableNameInfoCompare.sLogicalNameFrom to sLogicalName
            End
            Else Begin
                Move aAPITableCompare[iCount].APITableNameInfoCompare.sLogicalNameTo   to sLogicalName
            End
            Set Action_Text of ghoStatusPanel to ("Name:" * sLogicalName * String("Number:") * String(hTable))

            Get UtilTableCompare_Ex of ghoDbUpdateFunctionLibrary aAPITableCompare[iCount] CompareCheckBoxes False (&bFilelistError) to bIsSame

            If (bIsSame = False) Begin
                Send MainReport (&aAPITableCompare[iCount]) (&CompareCheckBoxes) iCh
                Move hTable to iaDifferences[SizeOfArray(iaDifferences)]
            End

            Get Check_StatusPanel of ghoStatusPanel to bUserCancel
            If (bUserCancel = True) Begin
                Move -1 to iaDifferencesEmpty[0]
                Function_Return iaDifferencesEmpty
            End
        Loop
        
        Move False to bCollationDiff
        If (Uppercase(sDatabaseCollationFrom) <> Uppercase(sDatabaseCollationTo)) Begin
            Move True to bCollationDiff
        End
        Send WriteReportFooter (SizeOfArray(iaDifferences)) bCollationDiff iCh dtExecStart
        Close DF_ALL DF_PERMANENT

        Function_Return iaDifferences
    End_Function

    Procedure MainReport tAPITableCompare ByRef aAPITableCompare tAPITableBooleans ByRef CompareCheckBoxes Integer iCh
        String sDriverIDFrom sDriverIDTo sLogicalName sFrom sTo
        Handle hTable
        Boolean bCompareDate_DateTime bCompareIndexUppercase bCompareIndexAscending bCompareFilelistUppercase
        Boolean bExistsFrom bExistsTo bIsSQLFrom bIsSQLTo

        Move CompareCheckBoxes.bCompareDate_DateTime     to bCompareDate_DateTime
        Move CompareCheckBoxes.bCompareIndexAscending    to bCompareIndexAscending
        Move CompareCheckBoxes.bCompareIndexUppercase    to bCompareIndexUppercase
        Move CompareCheckBoxes.bCompareFilelistUppercase to bCompareFilelistUppercase

        Move aAPITableCompare.bExistsFrom                            to bExistsFrom
        Move aAPITableCompare.bExistsTo                              to bExistsTo
        Move aAPITableCompare.APITableNameInfoCompare.bIsSQLFrom     to bIsSQLFrom
        Move aAPITableCompare.APITableNameInfoCompare.bIsSQLTo       to bIsSQLTo
        Move aAPITableCompare.APITableNameInfoCompare.sDriverIDFrom  to sDriverIDFrom
        Move aAPITableCompare.APITableNameInfoCompare.sDriverIDTo    to sDriverIDTo
        Move aAPITableCompare.APITableNameInfoCompare.iTableNumber   to hTable

        If (aAPITableCompare.bExistsFrom = True) Begin
            Move aAPITableCompare.APITableNameInfoCompare.sLogicalNameFrom to sLogicalName
        End
        Else Begin
            Move (aAPITableCompare.APITableNameInfoCompare.sLogicalNameTo) to sLogicalName
        End

        Send WriteTableInfoDiff aAPITableCompare.APITableNameInfoCompare bCompareFilelistUppercase iCh
        If (aAPITableCompare.bExistsFrom = True and aAPITableCompare.bExistsTo = True) Begin
            Send WriteColumnDiffs sDriverIDFrom sDriverIDTo hTable sLogicalName bIsSQLFrom bIsSQLTo aAPITableCompare.aAPIColumnsCompare bCompareDate_DateTime iCh
            Send WriteIndexDiffs hTable bIsSQLFrom bIsSQLTo sLogicalName aAPITableCompare.aAPIIndexesCompare bCompareIndexUppercase bCompareIndexAscending iCh
            Send WriteRelationDiffs hTable aAPITableCompare.aAPIRelationsCompare iCh
        End

    End_Procedure

    Function WriteReportHeader String sDatabaseCollationFrom String sDatabaseCollationTo Returns Integer
        Integer iCh
        String sFilelistFrom sFilelistTo sReportName //sDriverIDFrom sDriverIDTo sLogicalName sFrom sTo sRootName sTableName
        DateTime dtCreationTime    

        Get Value of oReportFileName_fm to sReportName
        Get Seq_Open_Output_Channel sReportName to iCh
        If (iCh = DF_SEQ_CHANNEL_ERROR) Begin
            Send Stop_Box "Sorry, couldn't retrieve a free channel number."
            Function_Return 0
        End                   
        
        If (Uppercase(sDatabaseCollationFrom) <> Uppercase(sDatabaseCollationTo)) Begin
            Move (sDatabaseCollationTo * String("(*)")) to sDatabaseCollationTo
        End

        Get Value of oFilelistPathFrom_fm to sFilelistFrom
        Get Value of oFilelistPathTo_fm   to sFilelistTo
        Move (CurrentDateTime()) to dtCreationTime

        Writeln channel iCh CS_ReportHeaderUnderWrite
        Writeln channel iCh CS_DatabaseUpdateFramework
        Writeln channel iCh (" ***  DATABASE DIFFERENCES REPORT  ***")
        Writeln channel iCh ""
        Writeln channel iCh ("      Date & Time Printed       :" * String(dtCreationTime))
        Writeln channel iCh ("      FROM Database Filelist.cfg:" * String(sFilelistFrom))
        Writeln channel iCh ("      TO   Database Filelist.cfg:" * String(sFilelistTo))
        Writeln channel iCh ("      FROM Database Collation   :" * String(sDatabaseCollationFrom))
        Writeln channel iCh ("      TO   Database Collation   :" * String(sDatabaseCollationTo))
        Writeln channel iCh ""
        Writeln channel iCh ("      Note: An asterisk in parenthesis (*) denotes a difference!")
        Writeln channel iCh CS_ReportHeaderUnderWrite
        Writeln channel iCh

        Function_Return iCh
    End_Function

    // Note: The rootname will be first be stripped if it contains any driver id prefix.
    Procedure WriteTableInfoDiff tAPITableNameInfoCompare APITableNameInfoCompare Boolean bCompareFilelistUppercase Integer iCh
        String sLogicalName  sFrom sTo
        Boolean bExistsFrom bExistsTo bIsSame
        Handle hTable

        Get UtilTableInfoCompare of ghoDbUpdateFunctionLibrary bCompareFilelistUppercase APITableNameInfoCompare to bIsSame
        If (bIsSame = True) Begin
            Procedure_Return
        End

        Move APITableNameInfoCompare.iTableNumber to hTable
        Move APITableNameInfoCompare.bExistsFrom  to bExistsFrom
        Move APITableNameInfoCompare.bExistsTo    to bExistsTo
        If (bExistsFrom = True) Begin
            Move APITableNameInfoCompare.sLogicalNameFrom to sLogicalName
        End
        If (bExistsTo = True) Begin
            Move APITableNameInfoCompare.sLogicalNameTo   to sLogicalName
        End

        Writeln channel iCh
        Writeln channel iCh "Table Name Difference(s) Table Number: " hTable " - " sLogicalName
        Writeln channel iCh CS_ReportHeaderUnderWrite

        Move "FROM Database:" to sFrom
        Get MakeStringLength sFrom CI_ReportColumn2 to sFrom
        Move (sFrom + "TO Database:") to sFrom
        Writeln channel iCh sFrom
        Move (Repeat("-", Length(sFrom))) to sFrom
        Writeln channel iCh sFrom

        Move "Logical Name:"                                                to sFrom
        Get MakeStringLength sFrom CI_ReportColumn1                         to sFrom
        If (bExistsFrom = True) Begin
            Move (sFrom + String(APITableNameInfoCompare.sLogicalNameFrom)) to sFrom
        End
        If (bExistsFrom = False) Begin
            Move (sFrom + CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sFrom
        End
        Get MakeStringLength sFrom CI_ReportColumn2                         to sFrom
        If (bExistsTo = True) Begin
            Move APITableNameInfoCompare.sLogicalNameTo                     to sTo
        End
        If (bExistsTo = False) Begin
            Move ""                                                         to sTo
            Move (CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sTo
        End
        Writeln channel iCh sFrom sTo

        Move "Root Name:"                                                   to sFrom
        Get MakeStringLength sFrom CI_ReportColumn1                         to sFrom
        If (bExistsFrom = True) Begin
            Move (sFrom + String(APITableNameInfoCompare.sRootNameFrom))    to sFrom
        End
        If (bExistsFrom = False) Begin
            Move (sFrom + CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sFrom
        End
        Get MakeStringLength sFrom CI_ReportColumn2                         to sFrom
        If (bExistsTo = True) Begin
            Move APITableNameInfoCompare.sRootNameTo                        to sTo
        End
        If (bExistsTo = False) Begin
            Move ""                                                         to sTo
            Move (CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sTo
        End
        Writeln channel iCh sFrom sTo

        Move "Display Name:"                                                to sFrom
        Get MakeStringLength sFrom CI_ReportColumn1                         to sFrom
        If (bExistsFrom = True) Begin
            Move (sFrom + String(APITableNameInfoCompare.sDisplayNameFrom)) to sFrom
        End
        If (bExistsFrom = False) Begin
            Move (sFrom + CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sFrom
        End
        Get MakeStringLength sFrom CI_ReportColumn2                         to sFrom
        If (bExistsTo = True) Begin
            Move APITableNameInfoCompare.sDisplayNameTo                     to sTo
        End
        If (bExistsTo = False) Begin
            Move ""                                                         to sTo
            Move (CS_ReportTableNotFound * String(CS_ReportDifferenceNote)) to sTo
        End
        Writeln channel iCh sFrom sTo

        If (bExistsFrom = False or bExistsTo = False) Begin
            Writeln channel iCh
        End
        Writeln channel iCh
    End_Procedure

    Procedure WriteColumnDiffs String sDriverIDFrom String sDriverIDTo Handle hTable String sLogicalTableName Boolean bIsSQLFrom Boolean bIsSQLTo tAPIColumnCompare[] aAPIColumnCompare Boolean bCompareDate_DateTime Integer iCh
        Integer iSize iCount
        Boolean bIsSame bHeader
        String sFrom sTo sTypeFrom sTypeTo

        Move (SizeOfArray(aAPIColumnCompare)) to iSize
        If (iSize = 0) Begin
            Procedure_Return
        End

        Decrement iSize
        For iCount from 0 to iSize
            Get UtilColumnCompare of ghoDbUpdateFunctionLibrary sDriverIDFrom sDriverIDTo bIsSQLFrom bIsSQLTo aAPIColumnCompare[iCount] bCompareDate_DateTime to bIsSame
            If (bIsSame = False) Begin

                If (bHeader = False) Begin
                    Writeln channel iCh "Field Difference(s) for Table Number: " (String(hTable)) " - " sLogicalTableName
                    Writeln channel iCh CS_ReportHeaderUnderWrite
                    Move "FROM Database:" to sFrom
                    Get MakeStringLength sFrom CI_ReportColumn2 to sFrom
                    Move (sFrom + "TO Database:") to sFrom
                    Writeln channel iCh sFrom
                    Move (Repeat("-", Length(sFrom))) to sFrom
                    Writeln channel iCh sFrom
                    Move True to bHeader
                End

                Get MakeFromString "Field Number:" aAPIColumnCompare[iCount].iFieldNumber (CS_ReportFieldNotFound * CS_ReportDifferenceNote) ;
                                 aAPIColumnCompare[iCount].bExistsFrom to sFrom
                Get MakeToString aAPIColumnCompare[iCount].iFieldNumber "" (CS_ReportFieldNotFound * CS_ReportDifferenceNote) ;
                                 aAPIColumnCompare[iCount].bExistsTo to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Field Name" aAPIColumnCompare[iCount].sFieldNameFrom CS_ReportDifferenceNote aAPIColumnCompare[iCount].bExistsTo to sFrom
                Get MakeToString aAPIColumnCompare[iCount].sFieldNameTo "" CS_ReportDifferenceNote (Uppercase(aAPIColumnCompare[iCount].sFieldNameFrom) = ;
                                 Uppercase(aAPIColumnCompare[iCount].sFieldNameTo)) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Type:" aAPIColumnCompare[iCount].sTypeFrom CS_ReportDifferenceNote aAPIColumnCompare[iCount].bExistsFrom to sFrom
                Get MakeToString aAPIColumnCompare[iCount].sTypeTo "" CS_ReportDifferenceNote (Uppercase(aAPIColumnCompare[iCount].sTypeFrom) = ;
                                 Uppercase(aAPIColumnCompare[iCount].sTypeTo)) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Length:" aAPIColumnCompare[iCount].iLengthFrom CS_ReportDifferenceNote aAPIColumnCompare[iCount].bExistsFrom to sFrom
                Get MakeToString aAPIColumnCompare[iCount].iLengthTo "" CS_ReportDifferenceNote (aAPIColumnCompare[iCount].iLengthFrom = ;
                                 aAPIColumnCompare[iCount].iLengthTo) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Precision:" aAPIColumnCompare[iCount].iPrecisionFrom CS_ReportDifferenceNote aAPIColumnCompare[iCount].bExistsFrom to sFrom
                Get MakeToString aAPIColumnCompare[iCount].iPrecisionTo "" CS_ReportDifferenceNote (aAPIColumnCompare[iCount].iPrecisionFrom = ;
                                 aAPIColumnCompare[iCount].iPrecisionTo) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Default Value:" aAPIColumnCompare[iCount].sDefaultValueFrom CS_ReportDifferenceNote aAPIColumnCompare[iCount].bExistsFrom to sFrom
                Get MakeToString aAPIColumnCompare[iCount].sDefaultValueTo "" CS_ReportDifferenceNote (aAPIColumnCompare[iCount].sDefaultValueFrom = ;
                                 aAPIColumnCompare[iCount].sDefaultValueTo) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Allow NULL:" (If(aAPIColumnCompare[iCount].bAllowNULLFrom = True, "Yes", "No")) CS_ReportDifferenceNote ;
                                 aAPIColumnCompare[iCount].bExistsTo to sFrom
                Get MakeToString (If(aAPIColumnCompare[iCount].bAllowNULLTo = True, "Yes", "No")) "" CS_ReportDifferenceNote ;
                                 aAPIColumnCompare[iCount].bExistsTo to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Identity Field:" (If(aAPIColumnCompare[iCount].iOptionsFrom = C_tAPIColumn_Identity, "Yes", "No")) CS_ReportDifferenceNote ;
                                 aAPIColumnCompare[iCount].bExistsTo to sFrom
                Get MakeToString (If(aAPIColumnCompare[iCount].iOptionsTo = C_tAPIColumn_Identity, "Yes", "No")) "" CS_ReportDifferenceNote ;
                                 aAPIColumnCompare[iCount].bExistsTo to sTo
                Writeln channel iCh sFrom sTo
                Writeln channel iCh
            End
        Loop

        If (bHeader = True) Begin
            Writeln channel iCh ""
        End
    End_Procedure

    Procedure WriteIndexDiffs Handle hTable Boolean bIsSQLTableFrom Boolean bIsSQLTableTo String sLogicalTableName tAPIIndexCompare[] aAPIIndexCompare Boolean bCompareIndexUppercase Boolean bCompareIndexAscending Integer iCh
        Integer iSize iCount iSegmentSizeFrom iSegmentSizeTo iCount2 iSize2 iFieldNumberFrom iFieldNumberTo
        Integer iIndexNumberFrom iIndexNumberTo iPrimaryIndexFrom iPrimaryIndexTo
        tAPIIndexSegment[] aApiIndexSegmentsFrom aApiIndexSegmentsTo aApiIndexSegmentsEmpty
        String sFrom sTo sSQLIndexTypeFrom sSQLIndexTypeTo sSQLIndexNameFrom sSQLIndexNameTo sFieldNameFrom sFieldNameTo
        Boolean bIsSame bIsSQLPrimaryFrom bIsSQLPrimaryTo bIsSQLClusteredFrom bIsSQLClusteredTo bHeader

        Move (SizeOfArray(aAPIIndexCompare)) to iSize
        Decrement iSize

        For iCount from 0 to iSize
            Get UtilIndexCompare of ghoDbUpdateFunctionLibrary bIsSQLTableFrom bIsSQLTableTo aAPIIndexCompare[iCount] bCompareIndexAscending bCompareIndexUppercase to bIsSame
            If (bIsSame = False) Begin
                If (bHeader = False) Begin
                    Writeln channel iCh "Index Difference(s) for Table Number: " (String(hTable)) " - " sLogicalTableName
                    Writeln channel iCh CS_ReportHeaderUnderWrite
                    Move "FROM Database:" to sFrom
                    Get MakeStringLength sFrom CI_ReportColumn2 to sFrom
                    Move (sFrom + "TO Database:") to sFrom
                    Writeln channel iCh sFrom
                    Move (Repeat("-", Length(sFrom))) to sFrom
                    Writeln channel iCh sFrom
                    Move True to bHeader
                End

                // FROM Index:
                If (aAPIIndexCompare[iCount].bExistsFrom = True) Begin
                    Move aAPIIndexCompare[iCount].iIndexNumber              to iIndexNumberFrom
                    Move aAPIIndexCompare[iCount].iPrimaryIndexFrom         to iPrimaryIndexFrom
                    Move aAPIIndexCompare[iCount].sSQLIndexNameFrom         to sSQLIndexNameFrom
                    Move aAPIIndexCompare[iCount].bIsSQLPrimaryKeyFrom      to bIsSQLPrimaryFrom
                    Move aAPIIndexCompare[iCount].bIsSQLClusteredFrom       to bIsSQLClusteredFrom
                    Get UtilIndexTypeToString of ghoDbUpdateFunctionLibrary ;
                         aAPIIndexCompare[iCount].iSQLIndexTypeFrom         to sSQLIndexTypeFrom
                    Move aAPIIndexCompare[iCount].IndexSegmentArrayFrom     to aApiIndexSegmentsFrom
                End
                Else Begin
                    Move -1                                                 to iIndexNumberFrom
                    Move -1                                                 to iPrimaryIndexFrom
                    Move (String(CS_ReportDifferenceNote))                  to sSQLIndexNameFrom
                    Move False                                              to bIsSQLPrimaryFrom
                    Move False                                              to bIsSQLClusteredFrom
                    Move (String(CS_ReportDifferenceNote))                  to sSQLIndexTypeFrom
                    Move aApiIndexSegmentsEmpty                             to aApiIndexSegmentsFrom
                End

                If (aAPIIndexCompare[iCount].bExistsTo = True) Begin
                    Move aAPIIndexCompare[iCount].iIndexNumber              to iIndexNumberTo
                    Move aAPIIndexCompare[iCount].iPrimaryIndexTo           to iPrimaryIndexTo
                    Move aAPIIndexCompare[iCount].sSQLIndexNameTo           to sSQLIndexNameTo
                    Move aAPIIndexCompare[iCount].bIsSQLPrimaryKeyTo        to bIsSQLPrimaryTo
                    Move aAPIIndexCompare[iCount].bIsSQLClusteredTo         to bIsSQLClusteredTo
                    Get UtilIndexTypeToString of ghoDbUpdateFunctionLibrary ;
                        aAPIIndexCompare[iCount].iSQLIndexTypeTo            to sSQLIndexTypeTo
                    Move aAPIIndexCompare[iCount].IndexSegmentArrayTo       to aApiIndexSegmentsTo
                End
                Else Begin
                    Move -1                                                 to iIndexNumberTo
                    Move -1                                                 to iPrimaryIndexTo
                    Move (String(CS_ReportDifferenceNote))                  to sSQLIndexNameTo
                    Move (String(CS_ReportDifferenceNote))                  to bIsSQLPrimaryTo
                    Move (String(CS_ReportDifferenceNote))                  to bIsSQLClusteredTo
                    Move (String(CS_ReportDifferenceNote))                  to sSQLIndexTypeTo
                    Move (String(CS_ReportDifferenceNote))                  to bIsSQLPrimaryTo
                    Move aApiIndexSegmentsEmpty                             to aApiIndexSegmentsTo
                End

                Get MakeFromString "Index Number:" iIndexNumberFrom CS_ReportIndexNotFound (iIndexNumberFrom <> -1) to sFrom
                Get MakeToString iIndexNumberTo "" (CS_ReportIndexNotFound * String(CS_ReportDifferenceNote)) (iIndexNumberTo <> -1) to sTo
                Writeln channel iCh sFrom sTo

                Get MakeFromString "Primary Idx #:" iPrimaryIndexFrom CS_ReportDifferenceNote (iPrimaryIndexFrom <> -1) to sFrom
                Get MakeToString iPrimaryIndexTo "" CS_ReportDifferenceNote (iPrimaryIndexTo <> -1) to sTo
                Writeln channel iCh sFrom sTo

                // SQL Index info:
                If (bIsSqlTableFrom = True and bIsSqlTableTo = True) Begin
                    Get MakeFromString "SQL Name:" sSQLIndexNameFrom CS_ReportDifferenceNote (sSQLIndexNameFrom <> "") to sFrom
                    Get MakeToString sSQLIndexNameTo "" CS_ReportDifferenceNote (iIndexNumberFrom <> -1 and Uppercase(sSQLIndexNameFrom) = Uppercase(sSQLIndexNameTo)) to sTo
                    Writeln channel iCh sFrom sTo

                    Get MakeFromString "SQL Primary:" (If(bIsSQLPrimaryFrom = True, "Yes", "No")) CS_ReportDifferenceNote aAPIIndexCompare[iCount].bExistsFrom to sFrom
                    Get MakeToString (If(bIsSQLPrimaryTo = True, "Yes", "No")) "" CS_ReportDifferenceNote (iIndexNumberFrom <> -1 and bIsSQLPrimaryFrom = bIsSQLPrimaryTo) to sTo
                    Writeln channel iCh sFrom sTo

                    Get MakeFromString "SQL Clustered:" (If(bIsSQLClusteredFrom = True, "Yes", "No")) CS_ReportDifferenceNote aAPIIndexCompare[iCount].bExistsFrom to sFrom
                    Get MakeToString (If(bIsSQLClusteredTo = True, "Yes", "No")) "" CS_ReportDifferenceNote (iIndexNumberFrom <> -1 and bIsSQLClusteredFrom = bIsSQLClusteredTo) to sTo
                    Writeln channel iCh sFrom sTo

                    Get MakeFromString "SQL Type:" sSQLIndexTypeFrom CS_ReportDifferenceNote True to sFrom
                    Get MakeToString sSQLIndexTypeTo "" CS_ReportDifferenceNote True to sTo
                    Writeln channel iCh sFrom sTo
                End

                // Index Segments:
                Move (SizeOfArray(aApiIndexSegmentsFrom)) to iSegmentSizeFrom
                Move (SizeOfArray(aApiIndexSegmentsTo))   to iSegmentSizeTo

                Move (iSegmentSizeFrom max iSegmentSizeTo)  to iSize2
                Decrement iSize2
                If (iSize2 > -1) Begin
                    Writeln channel iCh
                End

                For iCount2 from 0 to iSize2
                    Move "" to sFieldNameFrom
                    Move "" to sFieldNameTo
                    Get MakeStringLength "Field# & Name:" CI_ReportColumn1               to sFrom
                    If (iCount2 < iSegmentSizeFrom) Begin
                        Move aApiIndexSegmentsFrom[iCount2].iFieldNumber                 to iFieldNumberFrom
                        Move (sFrom + String(iFieldNumberFrom))                          to sFrom
                        Move (String(aApiIndexSegmentsFrom[iCount2].sFieldName))         to sFieldNameFrom
                        Move (sFrom * String(sFieldNameFrom))                            to sFrom
                    End
                    Else Begin
                        Move 0                                                           to iFieldNumberFrom
                        Move (sFrom + CS_ReportIndexSegmentNotFound)                     to sFrom
                    End
                    Get MakeStringLength sFrom CI_ReportColumn2                          to sFrom

                    Move ""                                                              to sTo
                    If (iIndexNumberTo <> -1) Begin
                        Move aApiIndexSegmentsTo[iCount2].iFieldNumber                   to iFieldNumberTo
                        Move (String(iFieldNumberTo))                                    to sTo
                        Move (String(aApiIndexSegmentsTo[iCount2].sFieldName))           to sFieldNameTo
                        Move (sTo * String(sFieldNameTo))                                to sTo
                    End
                    If (iFieldNumberFrom <> iFieldNumberTo or Uppercase(sFieldNameFrom) <> Uppercase(sFieldNameTo)) Begin
                        Move (sTo + String(CS_ReportDifferenceNote))                     to sTo
                    End
                    Writeln channel iCh sFrom sTo

                    // Uppercase Index Segment:
                    If (bCompareIndexUppercase = True) Begin
                        Get MakeStringLength "Uppercase:" CI_ReportColumn1                                        to sFrom
                        If (bIsSqlTableFrom = True) Begin
                            Move (sFrom + CS_ReportIndexNotApplicable)                                            to sFrom
                        End
                        Else If (iCount <= iSegmentSizeFrom) Begin
                            Move (sFrom + String(If(aApiIndexSegmentsFrom[iCount2].bUppercase = 1, "Yes","No")))  to sFrom
                        End
                        Get MakeStringLength sFrom CI_ReportColumn2                                               to sFrom
                        Move "" to sTo
                        If (bIsSqlTableFrom = True) Begin
                            Move CS_ReportIndexNotApplicable                                                      to sTo
                        End
                        Else If (iCount <= iSegmentSizeTo) Begin
                            Move (String(If(aApiIndexSegmentsTo[iCount2].bUppercase = 1, "Yes", "No")))           to sTo
                        End
                        Writeln channel iCh sFrom sTo
                    End

                    // Ascending/Descending Index:
                    If (bCompareIndexAscending = True) Begin
                        Get MakeStringLength "Ascending:" CI_ReportColumn1                                        to sFrom
                        If (bIsSqlTableFrom = True) Begin
                            Move (sFrom + CS_ReportIndexNotApplicable)                                            to sFrom
                        End
                        Else If (iCount <= iSegmentSizeFrom) Begin
                            Move (sFrom + String(If(aApiIndexSegmentsFrom[iCount2].bAscending = 1, "Yes", "No"))) to sFrom
                        End
                        Get MakeStringLength sFrom CI_ReportColumn2                                               to sFrom
                        Move "" to sTo
                        If (bIsSqlTableFrom = True) Begin
                            Move CS_ReportIndexNotApplicable                                                      to sTo
                        End
                        Else If (iCount <= iSegmentSizeTo) Begin
                            Move (String(If(aApiIndexSegmentsTo[iCount2].bAscending = 1, "Yes", "No")))           to sTo
                        End
                        Writeln channel iCh sFrom sTo
                    End
                Loop
                Writeln channel iCh ""
            End
        Loop

        If (bHeader = True) Begin
            Writeln channel iCh ""
        End
    End_Procedure

    Procedure WriteRelationDiffs Handle hTable tAPIRelationCompare[] aAPIRelationCompare Integer iCh
        Integer iSizeFrom iSize iCount iRow iItem
        Boolean bExists bIsSame bHeader
        String sFrom sTo sFromFieldsRight sFromFields sToFields sLogicalNameFrom
        tRelationDiffs[] asRelationDiffs


        Move (SizeOfArray(aAPIRelationCompare)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Get UtilRelationCompare of ghoDbUpdateFunctionLibrary hTable aAPIRelationCompare[iCount] to bIsSame
            If (bIsSame = False) Begin
                If (bHeader = False) Begin
                    Move aAPIRelationCompare[iCount].sLogicalNameFrom_From   to sLogicalNameFrom
                    If (sLogicalNameFrom = "") Begin
                        Move aAPIRelationCompare[iCount].sLogicalNameFrom_To to sLogicalNameFrom
                    End
                    Writeln channel iCh ""
                    Writeln channel iCh "Relation Difference(s) for Table Number: " (String(hTable)) " - " sLogicalNameFrom
                    Writeln channel iCh CS_ReportHeaderUnderWrite
                    Move "FROM Database:" to sFrom
                    Get MakeStringLength sFrom CI_ReportColumn2 to sFrom
                    Move (sFrom + "TO Database:") to sFrom
                    Writeln channel iCh sFrom
                    Move (Repeat("-", Length(sFrom))) to sFrom
                    Writeln channel iCh sFrom
                    Move True to bHeader
                End

                // FROM Relation:
                Get MakeStringLength "Table.Field:" CI_ReportColumn1                            to sFrom
                If (aAPIRelationCompare[iCount].bExistsFrom = True) Begin
                    Move (sFrom + String(aAPIRelationCompare[iCount].hTableFrom)   + "." ;
                                + String(aAPIRelationCompare[iCount].iColumnFrom)  * "->")      to sFrom
                    Move (sFrom * String(aAPIRelationCompare[iCount].hTableTo)     + "." ;
                                + String(aAPIRelationCompare[iCount].iColumnTo))                to sFrom
                    Get MakeStringLength sFrom CI_ReportColumn2                                 to sFrom
                    Move (String(aAPIRelationCompare[iCount].sLogicalNameFrom_From) + "." ;
                        + String(aAPIRelationCompare[iCount].sFieldNameFrom_From)   * "->")     to sFromFields
                    Move (String(aAPIRelationCompare[iCount].sLogicalNameTo_From)   + "." ;
                        + String(aAPIRelationCompare[iCount].sFieldNameTo_From))                to sFromFieldsRight
                End
                Else Begin
                    Move (String(CS_ReportRelationNotFound) * String(CS_ReportDifferenceNote))  to sFrom
                    Get MakeStringLength sFrom CI_ReportColumn2                                 to sFrom
                    Move (String(CS_ReportDifferenceNote))                                      to sFromFields
                    Move ""                                                                     to sFromFieldsRight
                    Move iCount                                                                 to iItem
                End
                Move (sFromFields * String(sFromFieldsRight))                                   to sFromFields
                Get MakeStringLength sFromFields CI_ReportColumn2                               to sFromFields

                // TO Relation:
                If (aAPIRelationCompare[iCount].bExistsTo = True) Begin
                    Move (String(aAPIRelationCompare[iCount].hTableFrom)           + "." ;
                        + String(aAPIRelationCompare[iCount].iColumnFrom)          * "->")      to sTo
                    Move (sTo * String(aAPIRelationCompare[iCount].hTableTo)       + "." ;
                        + String(aAPIRelationCompare[iCount].iColumnTo))                        to sTo
                    Move (String(aAPIRelationCompare[iCount].sLogicalNameFrom_To)  + "." ;
                        + String(aAPIRelationCompare[iCount].sFieldNameFrom_To)    * "->")      to sToFields
                    Move (sToFields * String(aAPIRelationCompare[iCount].sLogicalNameTo_To) + "." ;
                        + String(aAPIRelationCompare[iCount].sFieldNameTo_To))                  to sToFields
                End
                Else Begin
                    Move (CS_ReportRelationNotFound * String(CS_ReportDifferenceNote))          to sTo
                    Move (String(CS_ReportDifferenceNote))                                      to sToFields
                End

                Move sFromFieldsRight to asRelationDiffs[iRow].sFromFieldsRight
                Move sFrom to asRelationDiffs[iRow].sFrom
                Move sTo   to asRelationDiffs[iRow].sTo
                Move sFromFields to asRelationDiffs[iRow].sFromFields
                Move sToFields   to asRelationDiffs[iRow].sToFields
                If (iCount < iSize) Begin
                    Increment iRow
                    Move "" to asRelationDiffs[iRow].sFrom
                    Move "" to asRelationDiffs[iRow].sTo
                End
                Else Begin
                    Increment iRow
                End
            End
        Loop

        // We put all relations in an array struct so we can sort it alphatically.
        // This is to show multiple field relations from one table to another next to each other, just as the Studio does.
        Move (SortArray(asRelationDiffs))   to asRelationDiffs
        Move (SizeOfArray(asRelationDiffs)) to iSizeFrom
        Decrement iSizeFrom
        For iCount from 0 to iSizeFrom
            Writeln channel iCh asRelationDiffs[iCount].sFrom       asRelationDiffs[iCount].sTo
            Writeln channel iCh asRelationDiffs[iCount].sFromFields asRelationDiffs[iCount].sToFields
            Writeln channel iCh
        Loop

        If (bHeader = True) Begin
            Writeln channel iCh ""
        End
    End_Procedure

    Procedure WriteReportFooter Integer iSize Boolean bCollationDiff Integer iCh DateTime dtExecStart
        DateTime dtExecEnd
        TimeSpan tsTotalTime

        Move (CurrentDateTime()) to dtExecEnd
        Move (dtExecEnd - dtExecStart) to tsTotalTime

        Writeln channel iCh
        Writeln channel iCh "SUMMARY:  [Total Elapsed Time: " tsTotalTime "]"
        Writeln channel iCh CS_ReportHeaderUnderWrite               
        If (bCollationDiff = False) Begin
            Writeln channel iCh "Number of Tables with differences: " (String(iSize))
        End 
        Else Begin
            If (iSize <> 0) Begin
                Writeln channel iCh "Number of Tables with differences: " (String(iSize))
            End
            Writeln channel iCh "*** IMPORTANT: The SQL collation used for the 'FROM' and 'TO' database are different! ***"
            Writeln channel iCh 
        End
        
        If (iSize = 0) Begin
            Writeln channel iCh "*** No table differences found. All tables should be identical! ***"
        End

        Send Seq_Close_Channel iCh
    End_Procedure

    Function MakeStringLength String sValue Integer iReportColumnPos Returns String
        Move (Pad(sValue, (Length(sValue) + (iReportColumnPos - Length(sValue))))) to sValue

        Function_Return sValue
    End_Function

    Function MakeFromString String sStartText String sText String sMissingText Boolean bExists Returns String
        String sFrom

        Get MakeStringLength sStartText CI_ReportColumn1 to sFrom
        If (bExists = True) Begin
            Move (sFrom + String(sText)) to sFrom
        End
        Else Begin
            Move (sFrom + String(sMissingText)) to sFrom
        End
        Get MakeStringLength sFrom CI_ReportColumn2 to sFrom

        Function_Return sFrom
    End_Function

    Function MakeToString String sStartText String sText String sMissingText Boolean bSame Returns String
        String sTo

        Move (String(sStartText) * String(sText)) to sTo
        If (bSame = False) Begin
            If (sTo <> "-1") Begin
                Move (sTo * String(sMissingText)) to sTo
            End
            Else Begin
                Move (String(sMissingText)) to sTo
            End
        End

        Function_Return sTo
    End_Function

    Function FindArrayItem tAPITable[] aFromStructure tAPITable[] aToStructure Integer iCount Handle ByRef hTable Integer ByRef iItemFrom Integer ByRef iItemTo Returns String
        Integer iSizeFrom iSizeTo
        Handle hTableFrom hTableTo
        String sLogicalName

        Move (SizeOfArray(aFromStructure)) to iSizeFrom
        Move (SizeOfArray(aToStructure))   to iSizeTo

        Move -1 to hTableFrom
        Move -1 to hTableTo
        Move iCount to iItemFrom
        Move iCount to iItemTo

        // The two struct arrays may be different in size (contain different number of items/tables).
        //
        // To avoid "Referenced Array Index Out of Bounds" error.
        If (iCount < iSizeFrom) Begin
            Move aFromStructure[iCount].ApiTableInfo.iTableNumber to hTableFrom
        End
        If (iCount < iSizeTo) Begin
            Move aToStructure[iCount].ApiTableInfo.iTableNumber   to hTableTo
        End
        If (hTableFrom <> -1 and hTableTo <> -1) Begin
            Move (hTableFrom min hTableTo)                to hTable
        End
        Else Begin
            Move (hTableFrom max hTableTo)                to hTable
        End

        If (iCount < iSizeFrom and hTableFrom <= hTableTo) Begin
            Move aFromStructure[iCount].ApiTableInfo.sLogicalName to sLogicalName
            Get FindTableNumber (&aToStructure) hTable to iItemTo
        End

        // If the 'TO' table number is lower than 'FROM'
        Else If (iCount < iSizeTo) Begin
            Move aToStructure[iCount].ApiTableInfo.sLogicalName to sLogicalName
            Get FindTableNumber (&aFromStructure) hTable to iItemFrom
        End
        Else If (iCount = iSizeTo) Begin
            Get FindTableNumber (&aToStructure) hTable to iItemTo
        End

        Function_Return sLogicalName
    End_Function

    Function FindTableNumber tAPITable[] ByRef aTableStructure Handle hTable Returns Integer
        Integer iSize iCount iTable iItem
        tAPITableNameInfo ApiTableNameInfo

        Move -1 to iItem
        Move (SizeOfArray(aTableStructure)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move aTableStructure[iCount].ApiTableInfo to ApiTableNameInfo
            If (ApiTableNameInfo.iTableNumber = hTable) Begin
                Move iCount to iItem
                Move iSize  to iCount // We're done.
            End
        Loop

        Function_Return iItem
    End_Function

    // Pass one tAPIRelation for the FROM database and a struct array with relations for the TO database
    // Returns the item number in the aAPIRelationsTO that equals the FROM relation struct data.
    // If not found returns -1.
//    Function FindEqualRelation tAPIRelation APIRelationFrom tAPIRelation[] aAPIRelationsTO Returns Integer
//        Integer iRetval iSize iCount
//
//        Move -1 to iRetval
//        Move (SizeOfArray(aAPIRelationsTO)) to iSize
//        Decrement iSize
//        For iCount from 0 to iSize
//            If (APIRelationFrom.hTableFrom  = aAPIRelationsTO[iCount].hTableFrom  and ;
//                APIRelationFrom.iColumnFrom = aAPIRelationsTO[iCount].iColumnFrom and ;
//                APIRelationFrom.hTableTo    = aAPIRelationsTO[iCount].hTableTo    and ;
//                APIRelationFrom.iColumnTo   = aAPIRelationsTO[iCount].iColumnTo) Begin
//                    Move iCount to iRetval
//                End
//        Loop
//
//        Function_Return iRetval
//    End_Function

    // Returns a value <> -1 if the passed iIndex was found in the APIIndex struct array.
    // The value returned is the item number, else a -1.
//    Function FindIndexInArray Integer iIndex tAPIIndex[] APIIndex Returns Integer
//        Integer iRetval iSize iCount iCompareIndex
//
//        Move -1 to iRetval
//        Move (SizeOfArray(APIIndex)) to iSize
//        Decrement iSize
//        For iCount from 0 to iSize
//            If (iIndex = APIIndex[iCount].iIndexNumber) Begin
//                Move iCount to iRetval
//            End
//        Loop
//        Function_Return iRetval
//    End_Function

    Procedure Request_Clear
        tSQLConnection Connection
        Integer[] iDifferencesEmpty

        Move DATAFLEX_ID to Connection.sDriverID
        Set pSQLConnection of ghoSQLConnectionHandler to Connection
        Set Value of oFilelistPathFrom_fm   to ""
        Set Value of oFilelistPathTo_fm     to ""
        Set Value of oReportFileName_fm     to ""
        Set psFilelistFrom of ghoApplication to ""
        Set piaDifferences of ghoApplication to iDifferencesEmpty

        Send Activate of oFilelistPathFrom_fm
    End_Procedure

    Object oBusinessProcess is a BusinessProcess
        Set Status_Panel_Id to ghoStatusPanel
        Set Allow_Cancel_State to True
        Set Process_Caption to "The Database Update Framework"
        Set Process_Title to "Comparing Database Structures..."
//        Set Display_Error_State to True // Temp!

        Procedure OnProcess
            Send MainProcess
        End_Procedure

        Procedure Ignore_Error Integer iError
        End_Procedure
        Procedure Trap_Error Integer iError
        End_Procedure

    End_Object

    Object oCompare_btn is a cRDCCommandLinkButton
        Set Size to 36 166
        Set Location to 276 139
        Set Label to "Co&mpare Databases!"
        Set psNote to "Compare the two selected databases."
        Set psImage to "DbCompare1.ico"
        Set Default_State to True
        Set psToolTip to "Start the compare process"
        Set piImageSize to 32 // 48
        Set peAnchors to anBottomRight

        Procedure OnClick
            String sFilelistFrom sFilelistTo
            Integer[] iaDifferences
            Boolean bFromExists bToExists

            Get Value of oFilelistPathFrom_fm to sFilelistFrom
            Get vFilePathExists sFilelistFrom to bFromExists
            Get Value of oFilelistPathTo_fm   to sFilelistTo
            Get vFilePathExists sFilelistTo   to bToExists
            If (bFromExists = False or bToExists = False) Begin
                Send Info_Box "You need to both select a FROM and a TO database Filelist.cfg. Please adjust and try again."
                Procedure_Return
            End

            Send DoProcess of oBusinessProcess
            Send Restore_DF_OPEN_PATH of ghoApplication
        End_Procedure

        Function IsEnabled Returns Boolean
            String sFileListFrom sFileListTo
            Boolean bExists bState

            Get Value of oFilelistPathFrom_fm to sFileListFrom
            Get vFilePathExists sFileListFrom to bExists
            If (bExists = False) Begin
                Function_Return False
            End
            Get Value of oFilelistPathTo_fm to sFileListTo
            Get vFilePathExists sFileListTo to bExists
            Get Enabled_State to bState
            If (bState = False and bExists = False) Begin
                Function_Return False
            End
            Function_Return bExists
        End_Function

    End_Object

    Object oViewReport_Btn is a cRDCCommandLinkButton
        Set Size to 36 77
        Set Location to 276 315
        Set Label to "&Report"
        Set psNote to "View report"
        Set peAnchors to anBottomRight
        Set psImage to "ViewReport1.ico"
        Set psToolTip to "Open the folder where the report was generated. (Ctrl+R)"
        Set piImageSize to 16 //24

        Procedure OnClick
            Send DoShowReport
        End_Procedure
        
        Procedure DoShowReport
            String sReportName
            Get Value of oReportFileName_fm to sReportName
            Send ActivateLogFileDialog of (Client_Id(ghoCommandBars)) sReportName
//            Runprogram Shell Background sReportName
        End_Procedure

        Function IsEnabled Returns Boolean
            String sReportName
            Boolean bExists

            Get Value of oReportFileName_fm to sReportName
            Get vFilePathExists sReportName to bExists
            Function_Return bExists
        End_Function

    End_Object

    Object oTagFilelist_Btn is a cRDCCommandLinkButton
        Set Size to 36 76
        Set Location to 276 402
        Set Label to "&Tag"
        Set psNote to "Tag differences"
        Set peAnchors to anBottomRight
        Set MultiLineState to True
        Set Border_Style to Border_Normal
        Set peImageAlign to Button_ImageList_Align_Center
        Set psImage to "SelectInvert1.ico"
        Set psToolTip to "Tag Tables for the 'FROM' Filelist.cfg with differences - for code generation on the 'Code Generator' view page."
        Set pbAutoEnable to True
        Set piImageSize to 16 // 24

        Procedure OnClick
            String sFileListFrom
            Get Value of oFilelistPathFrom_fm    to sFileListFrom
            Set psFilelistFrom of ghoApplication to sFileListFrom
            Send TagFileNamesForCodeGeneration
        End_Procedure

        Function IsEnabled Returns Boolean
            Integer[] iaDifferences
            Get piaDifferences of ghoApplication to iaDifferences
            Function_Return (SizeOfArray(iaDifferences))
        End_Function

    End_Object

    Procedure OnSetFocus
        If (SizeOfArray(phoActiveUpdates(ghoCommandBars)) <> 0) Begin
            Send Execute of (oCompareDatabases_MenuItem(ghoCommandBars))
        End
    End_Procedure
    
    Procedure OnFileDropped String sFilename Boolean bLast
        String sTest sFileListFrom sFileListTo

        Forward Send OnFileDropped sFilename bLast
        Get Value of oFilelistPathFrom_fm to sFileListFrom
        Get Value of oFilelistPathTo_fm    to sFileListTo
        If (bLast = True) Begin
            Get ParseFileName sFilename to sTest
            If (Uppercase(sTest) <> "FILELIST.CFG") Begin
                Send Info_Box "Sorry, only Filist.cfg files can be dropped here..."
                Procedure_Return
            End                                           
            If (sFileListFrom = "") Begin
                Set Value of oFilelistPathFrom_fm to sFilename
            End 
            Else Begin
                Set Value of oFilelistPathTo_fm to sFilename
            End
                
        End
    End_Procedure

    On_Key Key_Ctrl+Key_M  Send KeyAction of oCompare_btn
    On_Key Key_Ctrl+Key_R  Send KeyAction of oViewReport_Btn
    On_Key Key_Ctrl+Key_T  Send KeyAction of oTagFilelist_Btn
    On_Key kClear          Send Request_Clear
    On_Key kClear_All      Send Request_Clear
    On_Key Key_Ctrl+Key_F4 Send None
End_Object
