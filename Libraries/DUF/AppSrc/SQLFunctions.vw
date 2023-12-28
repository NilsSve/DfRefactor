Use Windows.pkg
Use DFClient.pkg
Use Dfspnfrm.pkg
Use cDbScrollingContainer.pkg
Use cRDCButtonDPI.pkg
Use cDbUpdateFunctionLibrary.pkg
Use SQLDatabaseBackup.dg

Activate_View Activate_oSQLFunctions_vw for oSQLFunctions_vw
Object oSQLFunctions_vw is a dbView
    Set Border_Style to Border_Thick
    Set Size to 260 426
    Set Location to -4 2
    Set Label to "Functions"
    Set pbAutoActivate to True
    Set Icon to "Sql1.ico"

    Procedure OnSetFocus
        String sValue
        tSQLConnection SQLConnection

        Get pSQLConnection of ghoSQLConnectionHandler to SQLConnection
        Set Value of oSQLDatabase_fm to SQLConnection.sDatabase
        Move (Replace(("PWD=" + SQLConnection.sPassword), SQLConnection.sConnectionString, "PWD=***")) to sValue
        Set Value of oSQLConnectionString_fm to sValue
    End_Procedure

    Object oScrollingContainer1 is a cDbScrollingContainer
        Object oScrollingClientArea1 is a cDbScrollingClientArea

            Object oSQLFunctionTests_grp is a Group
                Set Size to 243 402
                Set Location to 7 12
                Set Label to "Tests: Change SQL Database with Specialized SQL Functions"
                Set peAnchors to anAll

                Object oSQLConnectionString_fm is a Form
                    Set Size to 12 375
                    Set Location to 23 14
                    Set Label to "Current Connection String Settings:"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set peAnchors to anTopLeftRight
                    Set Enabled_State to False
                    Set Label_Row_Offset to 1
                End_Object

                Object oSQLDatabase_fm is a Form
                    Set Size to 12 86
                    Set Location to 50 14
                    Set Label to "Database:"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set FontWeight to fw_Bold
                    Set Enabled_State to False
                End_Object

                Object oDriverID2_cf is a ComboForm
                    Set Size to 12 91
                    Set Location to 50 121
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Driver ID:"
                    Set Entry_State to False
                    Set Enabled_State to False
                    Set Label_Row_Offset to 1

                    Procedure Combo_Fill_List
                        Send Combo_Add_Item MSSQLDRV_ID
                        Send Combo_Add_Item DB2_DRV_ID
                        Send Combo_Add_Item ODBC_DRV_ID
                    End_Procedure

                    Procedure Refresh
                        String sValue

                        Get psDriverID of ghoSQLConnectionHandler to sValue
                        Set Value to sValue
                    End_Procedure

                End_Object

                Object oBackupSQLDatabase_btn is a cRDCButtonDPI
                    Set Size to 12 109
                    Set Location to 50 220
                    Set Label to "Backup MS-SQL Database"
                    Set psImage to "DbBackup1.ico"

                    Procedure OnClick
                        Boolean bOK

                        // SQLDatabaseBackup dialog:
                        Get MakeSQLDatabaseBackup to bOK

                        If (bOK = True) Begin
                            Send Info_Box "The backup of the database was successful!"
                        End
                        Else Begin
                            Send Info_Box "The database was not backup up"
                        End
                    End_Procedure

                End_Object

                Object oDatabaseInfo_tb is a TextBox
                    Set Auto_Size_State to False
                    Set Size to 25 96
                    Set Location to 64 14
                    Set Label to "(Change database on the SQL Connections tabpage)"
                    Set Justification_Mode to JMode_Left
                End_Object

                Object oSQLInfo_tb is a TextBox
                    Set Auto_Size_State to False
                    Set Size to 37 270
                    Set Location to 76 118
                    Set Label to "Note: The DataFlex database API is NOT used here. Instead all is done with specialized embedded SQL (ESQL) funtions from the cDbUpdateFunctionLibrary. This is because an API 'Structure_End' command could drop and rebuild the whole table (!). That can take a long time..."
                    Set Justification_Mode to JMode_Left
                End_Object

                Object oSQLTableName_cf is a ComboForm
                    Set Size to 12 96
                    Set Location to 106 14
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Select Table:"
                    Set Label_Row_Offset to 1
                    Set Entry_State to False

                    Procedure OnDropDown
                        Send DoCombo_Fill_List
                    End_Procedure

                    Procedure OnCloseUp
                        Send Delete_Data of oSQLColumnName_cf
                    End_Procedure

                    Procedure DoCombo_Fill_List
                        String[] sTablesArray
                        String sDriverID
                        Integer iCount iSize

                        Send Delete_Data
                        Get Value of oDriverID2_cf to sDriverID
                        Get _SqlUtilEnumerateTables of ghoDbUpdateFunctionLibrary sDriverID to sTablesArray
                        Move (SizeOfArray(sTablesArray)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Send Combo_Add_Item sTablesArray[iCount]
                        Loop
                    End_Procedure

                    // DataFlex bug. It has been here as long as I can remember and _never_ seems to be fixed :-(
                    // Augmented Value function.
                    // We need to use Wincombo_x messages. Probably due to sync reasons.
                    // When e.g. OnCloseUp is fired the data_value still holds the old value.
                    Function Value Integer iItem Returns String
                        String sValue
                        Get WinCombo_Current_Item to iItem
                        Get WinCombo_Value iItem  to sValue
                        Function_Return sValue
                    End_Function

                End_Object

                Object oSQLColumnName_cf is a ComboForm
                    Set Size to 12 96
                    Set Location to 134 14
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Select Column:"
                    Set Label_Row_Offset to 1
                    Set Entry_State to False

                    Procedure DoCombo_Fill_List
                        String[] sColumnsArray
                        String sTableName sDriverID
                        Integer iCount iSize

                        Send Delete_Data
                        Get Value of oDriverID2_cf    to sDriverID
                        Get Value of oSQLTableName_cf to sTableName
                        Get _SqlUtilEnumerateColumns of ghoDbUpdateFunctionLibrary sDriverID sTableName to sColumnsArray
                        Move (SizeOfArray(sColumnsArray)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Send Combo_Add_Item sColumnsArray[iCount]
                        Loop
                        If (iSize > 1) Begin
                            Set Current_Item to 1
                        End
                    End_Procedure

                    Procedure OnDropDown
                        Send DoCombo_Fill_List
                    End_Procedure
                End_Object

                Object oSQLRenameColumnTo_fm is a Form
                    Set Size to 12 96
                    Set Location to 134 116
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Rename Column To:"
                    Set Label_Row_Offset to 1
                    Set Value to "NewColumnName"
                End_Object

                Object oSQLRenameColumn_btn is a cRDCButtonDPI
                    Set Size to 12 69
                    Set Location to 134 220
                    Set Label to "Rename Column"
                    Set psToolTip to "Test of SQLColumnRename function"
                    Set MultiLineState to True

                    Procedure OnClick
                        Boolean bOk
                        Handle hTable
                        String sTableName sColumnName sNewColumnName sDriverID

                        Get Value of oSQLTableName_cf to sTableName
                        If (sTableName = "") Begin
                            Send Info_Box "You need to select a table first..."
                            Procedure_Return
                        End
                        Get Value of oSQLColumnName_cf to sColumnName
                        If (Uppercase(sColumnName) = "RECNUM" or sColumnName = "") Begin
                            Send Info_Box "You need to select a column (and 'RECNUM' cannot be used)"
                            Procedure_Return
                        End
                        Get Value of oSQLRenameColumnTo_fm to sNewColumnName
                        If (Trim(sNewColumnName) = "") Begin
                            Send Info_Box "You need to enter a column name to rename to..."
                            Procedure_Return
                        End

                        Get NextFreeFilelistSlot of ghoDbUpdateFunctionLibrary to hTable
                        If (hTable = 0) Begin
                            Send Info_Box "Sorry, no free fileslot in filelist.cfg could be found. Cannot continue changing table."
                            Procedure_Return
                        End

                        Get Value of oDriverID2_cf to sDriverID
                        Set psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        Get SqlColumnRenameByTableName of ghoDbUpdateFunctionLibrary sTableName sColumnName sNewColumnName to bOk
                        If (bOk = True) Begin
                            // Better delete the combo values after a successful rename as it looks odd to show the old column name...
                            Send Delete_Data of oSQLColumnName_cf
                            Send Info_Box ("Column" * sColumnName + ", was successfully renamed to" * sNewColumnName * "for table:" * sTableName)
                        End
                        Else Begin
                            Send Info_Box "Nope, that didn't work..."
                        End

                    End_Procedure

                End_Object

                Object oSQLRemoveColumn_btn is a cRDCButtonDPI
                    Set Size to 12 91
                    Set Location to 134 297
                    Set Label to "Drop Column"
                    Set psToolTip to "Test of SQLColumnRemove function"
                    Set psImage to "DeleteColumn1.ico"

                    Procedure OnClick
                        Boolean bOk
                        String sTableName sColumnName sDriverID
                        Integer iRetval

                        Get Value of oDriverID2_cf              to sDriverID
                        Get Value of oSQLTableName_cf           to sTableName
                        Get Value of oSQLColumnName_cf          to sColumnName

                        If (sTableName = "" or sColumnName = "") Begin
                            Send Info_Box "You first need to select a table and a column."
                            Procedure_Return
                        End

                        Get YesNo_Box ("This will remove (drop) the column named:" * sColumnName * "from table:" * sTableName + ". Are you sure?") to iRetval
                        If (iRetval <> MBR_Yes) Begin
                            Procedure_Return
                        End

                        Get SqlColumnRemoveByTableName of ghoDbUpdateFunctionLibrary sTableName sColumnName to bOk

                        If (bOk = True) Begin
                            // Better delete the combo values after a successful operation as it looks odd to show the old column name...
                            Send Delete_Data of oSQLColumnName_cf
                            Send Info_Box ("Column" * sColumnName + ", was successfully removed")
                        End
                        Else Begin
                            Send Info_Box ("The column could NOT be removed. Either the column" * sColumnName * "doesn't exists or the current Database is incorrect?")
                            Procedure_Return
                        End

                    End_Procedure

                End_Object

                Object oSQLAddColumnName_fm is a Form
                    Set Size to 12 96
                    Set Location to 177 14
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Column Name:"
                    Set Label_Row_Offset to 1
                    Set Value to "NewColumn"
                End_Object

                Object oSQLColumnType_cf is a ComboForm
                    Set Size to 12 96
                    Set Location to 177 116
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Label to "Type:"
                    Set Entry_State to False

                    Procedure Combo_Fill_List
                        tColumnType[] ColumnTypeArray
                        Integer iSize iCount iDbType
                        String sDriverID

                        Send Delete_Data
                        Get Value of oDriverID2_cf to sDriverID
                        Get piDbType of ghoDbUpdateFunctionLibrary to iDbType
                        Get _UtilEnumerateColumnTypes of ghoDbUpdateFunctionLibrary sDriverID iDbType to ColumnTypeArray
                        Move (SizeOfArray(ColumnTypeArray)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Send Combo_Add_Item ColumnTypeArray[iCount].sSQLType
                        Loop
                        If (iSize > 0) Begin
                            Set Value to ColumnTypeArray[0].sSQLType
                        End
                    End_Procedure

                    Procedure OnChange
                        Integer iType iSize iDec
                        tSQLConnection SQLConnection
                        Boolean bFixed

                        Get SelectedType to iType
                        Get pSQLConnection of ghoSQLConnectionHandler to SQLConnection
                        Get UtilColumnTypePrecisionSize of ghoDbUpdateFunctionLibrary SQLConnection.sDriverID SQLConnection.iDbType iType to iSize
                        Get UtilColumnTypePrecisionDec  of ghoDbUpdateFunctionLibrary SQLConnection.sDriverID SQLConnection.iDbType iType to iDec
                        Get UtilColumnTypeFixed         of ghoDbUpdateFunctionLibrary SQLConnection.sDriverID SQLConnection.iDbType iType to bFixed

                        Set Enabled_State of oSQLLength_sf   to (bFixed = False)
                        Set Enabled_State of oSQLDecimals_sf to (bFixed = False)
                        Set Value         of oSQLLength_sf   to iSize
                        If (iDec = 0) Begin
                            Set Value     of oSQLDecimals_sf to ""
                        End
                        Else Begin
                            Set Value     of oSQLDecimals_sf to iDec
                        End
                        If (bFixed = False) Begin
                            Set Enabled_State of oSQLDecimals_sf to (iDec <> 0)
                        End
                    End_Procedure

                    Function SelectedType Returns Integer
                        String sValue sDriverID
                        Integer iType iDbType

                        Get Value to sValue
                        Get psDriverID of ghoSQLConnectionHandler to sDriverID
                        Get piDbType   of ghoSQLConnectionHandler to iDbType
                        Get UtilColumnTypeToInteger of ghoDbUpdateFunctionLibrary sDriverID iDbType sValue to iType

                        Function_Return iType
                    End_Function

                End_Object

                Object oSQLAddColumn_btn is a cRDCButtonDPI
                    Set Size to 12 69
                    Set Location to 177 220
                    Set Label to "Add Column"
                    Set psToolTip to "Test of SQLColumnAdd function"
                    Set psImage to "AddColumn1.ico"

                    Procedure OnClick
                        Boolean bOk bInitialize
                        Handle hTable
                        String sTableName sColumnName sType sColumnValue sDriverID
                        Integer iType iLength iDecimals

                        Get Value of oDriverID2_cf              to sDriverID
                        Get Value of oSQLTableName_cf           to sTableName
                        Get Value of oSQLAddColumnName_fm       to sColumnName
                        Get SelectedType  of oSQLColumnType_cf  to iType
                        Get Value         of oSQLColumnType_cf  to sType
                        Get Checked_State of oSQLInitializeColumnValue_cb to bInitialize
                        Get Value         of oSQLColumnValue_fm to sColumnValue
                        Get Value         of oSQLLength_sf      to iLength
                        Get Value         of oSQLDecimals_sf    to iDecimals

                        If (sTableName <> "") Begin
                            Get UtilTableNameToHandle of ghoDbUpdateFunctionLibrary sTableName to hTable
                            If (hTable = 0) Begin
                                Get NextFreeFilelistSlot of ghoDbUpdateFunctionLibrary to hTable
                            End
                        End
                        If (hTable = 0) Begin
                            Send Info_Box "You first need to select a table before you can add a column to it."
                            Procedure_Return
                        End
                        If (sColumnName = "") Begin
                            Send Info_Box "You need to enter a column name"
                            Procedure_Return
                        End

                        Get SqlColumnAddByTableName of ghoDbUpdateFunctionLibrary sTableName sColumnName iType iLength iDecimals bInitialize sColumnValue to bOk

                        If (bOk = True) Begin
                            Send Info_Box ("New column" * sColumnName * sType * String(iLength) + ", was successfully added to" * sTableName)
                        End
                        Else Begin
                            Send Info_Box ("The column could NOT be added. Either column" * sColumnName * "already exists or the current Database is incorrect?")
                            Procedure_Return
                        End

                    End_Procedure

                End_Object

//                Object oTest_btn is a cRDCButtonDPI
//                    Set Size to 13 92
//                    Set Location to 177 298
//                    Set Label to "Test SQL script button"
//
//                    Procedure OnClick
//                        Boolean bOK
//                        String sTableName sColumnName
//
//                        Get Value of oSQLTableName_cf      to sTableName
//                        Get Value of oSQLAddColumnName_fm  to sColumnName
////                        Get SqlUtilDefaultConstraintsMSSQL of ghoDbUpdateFunctionLibrary sTableName sColumnName to bOK
//
//                    End_Procedure
//
//                End_Object

                Object oSQLLength_sf is a SpinForm
                    Set Label to "Length:"
                    Set Size to 12 40
                    Set Location to 202 16
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Value to "10"
                    Set Maximum_Position to 500
                    Set Minimum_Position to 1
                End_Object

                Object oSQLDecimals_sf is a SpinForm
                    Set Label to "Decimals:"
                    Set Size to 12 33
                    Set Location to 202 60
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Value to "0"
                    Set Maximum_Position to 16
                    Set Minimum_Position to 1
                End_Object

                Object oSQLInitializeColumnValue_cb is a CheckBox
                    Set Size to 12 85
                    Set Location to 202 116
                    Set Label to "Initialize Column Value"

                    Procedure OnChange
                        Boolean bChecked

                        Get Checked_State to bChecked
                        Set Enabled_State of oSQLColumnValue_fm to bChecked
                    End_Procedure

                End_Object

                Object oSQLColumnValue_fm is a Form
                    Set Size to 12 96
                    Set Location to 218 116
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set Label to "Column Value"
                    Set psToolTip to "When a new column is added the new column can be initialized with a value for all existing records."
                    Set Enabled_State to False
                End_Object

                Object oEnumRelations_btn is a cRDCButtonDPI
                    Set Size to 12 91
                    Set Location to 116 297
                    Set Label to "Test Enum SQL Relations"

                    Procedure OnClick
                        tSQLRelation[] SQLRelationArray
                        String sTableName sDriverID
                        Integer iSize iCount

                        Get Value of oDriverID2_cf to sDriverID
                        Get Value of oSQLTableName_cf to sTableName
                        Get _SqlUtilEnumerateRelations of ghoDbUpdateFunctionLibrary sTableName sDriverID to SQLRelationArray
                        Move (SizeOfArray(SQLRelationArray)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Showln "Tablename.FieldName = " SQLRelationArray[iCount].sFileName "." SQLRelationArray[iCount].sFieldName " Number: " SQLRelationArray[iCount].iFileNumber "." SQLRelationArray[iCount].iFieldNumber
                        Loop
                        If (iSize < 1) Begin
                            Send Info_Box ("No SQL Foreign keys found for table:" * sTableName)
                        End

                    End_Procedure

                End_Object

                Object oEnumerateLoggedInUsers is a cRDCButtonDPI
                    Set Size to 12 101
                    Set Location to 177 297
                    Set Label to "Enumerate Logged In Users"

                    Procedure OnClick
                        tSQLLoggedInUser[] SQLLoggedInUser
                        String sDriverID sDatabase
                        Integer iSize iCount

                        Get psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        Get psDatabase of ghoDbUpdateFunctionLibrary to sDatabase
                        Get SqlUtilEnumerateLoggedInUsers of ghoDbUpdateFunctionLibrary sDriverID sDatabase to SQLLoggedInUser
                        Move (SizeOfArray(SQLLoggedInUser)) to iSize
                        Decrement iSize

                        Showln "SQL User Name" " and Program:"
                        For iCount from 0 to iSize
                            Showln SQLLoggedInUser[iCount].sUser " " SQLLoggedInUser[iCount].sProgram
                        Loop
                    End_Procedure

                End_Object

                Object oEnumerateTablesAndViews is a cRDCButtonDPI
                    Set Size to 12 101
                    Set Location to 193 297
                    Set Label to "Is Table or View?"

                    Procedure OnClick
                        String sDriverID sTableName
                        Handle hTable
                        Boolean bViewTableType

                        Get psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        Get Value of oSQLTableName_cf to sTableName
                        Get UtilTableNameToHandle of ghoDbUpdateFunctionLibrary sTableName to hTable
                        If (hTable = 0) Begin
                            Procedure_Return
                        End
                        Get SQLUtilTableIsViewType of ghoDbUpdateFunctionLibrary sDriverID hTable to bViewTableType
                        Send Info_Box ("The table" * sTableName * "is a" * If(bViewTableType = True, "View Table Type", "Standard Table (not view)"))
                    End_Procedure

                End_Object

            End_Object

        End_Object

    End_Object

End_Object
