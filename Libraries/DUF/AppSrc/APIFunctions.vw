Use Windows.pkg
Use DFClient.pkg
Use Dfspnfrm.pkg
Use Dfline.pkg
Use cDbScrollingContainer.pkg
Use cRDCButtonDPI.pkg
Use cDbUpdateFunctionLibrary.pkg

Define CI_Table1_FileNo for 401
Define CI_View1_FileNo  for 402

Activate_View Activate_oAPIFunctions_vw for oAPIFunctions_vw
Object oAPIFunctions_vw is a dbView
    Set Border_Style to Border_Thick
    Set Size to 237 424
    Set Location to 17 2
    Set Label to "API Functions"
    Set pbAutoActivate to True
    Set Icon to "APIFunctions1.ico"

    Property String psTableName ""

    Procedure OnSetFocus
        String sValue
        tSQLConnection SQLConnection

        Get pSQLConnection of ghoSQLConnectionHandler to SQLConnection
        Set Value of oApiDatabase_fm to SQLConnection.sDatabase
        Move (Replace(("PWD=" + SQLConnection.sPassword), SQLConnection.sConnectionString, "PWD=***")) to sValue
        Set Value of oApiConnectionString_fm to sValue
    End_Procedure

    Object oScrollingContainer1 is a cDbScrollingContainer
        Object oScrollingClientArea1 is a cDbScrollingClientArea

            Object oApiFunctions_grp is a Group
                Set Size to 222 402
                Set Location to 6 12
                Set Label to "Tests: Change MS-SQL Database with Database API Functions"
                Set peAnchors to anAll

                Object oApiConnectionString_fm is a Form
                    Set Size to 12 368
                    Set Location to 23 14
                    Set Label to "Current Connection String Settings:"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set peAnchors to anTopLeftRight
                    Set Enabled_State to False
                    Set Label_Row_Offset to 1
                End_Object

                Object oApiDatabase_fm is a Form
                    Set Size to 12 86
                    Set Location to 50 14
                    Set Label to "Database:"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Enabled_State to False
                    Set FontWeight to fw_Bold
//                    Set Label_FontWeight to fw_Bold

                    Procedure Page Integer iPageObject
                        String sValue
                        Get psDatabase of ghoSQLConnectionHandler to sValue
                        Set Value to sValue

                        Forward Send Page iPageObject
                    End_Procedure

                End_Object

                Object oDriverID3_cf is a ComboForm
                    Set Size to 12 91
                    Set Location to 51 121
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Driver ID:"
                    Set Entry_State to False
                    Set Enabled_State to False
                    Set Label_Row_Offset to 1
                    Set Enabled_State to False

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

                Object oDatabaseInfo_tb is a TextBox
                    Set Auto_Size_State to False
                    Set Size to 25 96
                    Set Location to 64 14
                    Set Label to "(Change database on the SQL Connections tabpage)"
                    Set Justification_Mode to JMode_Left
                End_Object

                Object oApiTableName_fm is a Form
                    Set Size to 12 77
                    Set Location to 114 14
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Table Name:"
                    Set Label_Row_Offset to 1
                    Set Value to "NewTable"
                    Procedure OnChange
                        String sValue
                        Get Value to sValue
                        Set psTableName to sValue
                    End_Procedure
                    Send OnChange
                End_Object

                Object oApiAddNewTable_btn is a cRDCButtonDPI
                    Set Size to 12 69
                    Set Location to 114 271
                    Set Label to "Add Table"
                    Set psImage to "ActionAddTable1.ico"

                    Procedure OnClick
                        Boolean bOk
                        Handle hTable
                        String sTableName sDriverID

                        Get Value of oDriverID3_cf to sDriverID
                        Get Value of oApiTableName_fm to sTableName
                        Move (Trim(sTableName)) to sTableName
                        If (sTableName = "") Begin
                            Send Info_Box "You first need to enter a table name."
                            Procedure_Return
                        End

                        Send Cursor_Wait of Cursor_Control
                        Get NextFreeFilelistSlot of ghoDbUpdateFunctionLibrary to hTable
                        Set psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        Get ApiTableCreate of ghoDbUpdateFunctionLibrary hTable sTableName sTableName sTableName True True True to bOk
                        If (bOk = True) Begin
                            Send Info_Box ("Test table" * sTableName * "was successfully created and put in filelist slot:" * String(hTable))
                        End
                        Else Begin
                            Send Cursor_Ready of Cursor_Control
                            Send Info_Box ("Nope, the test table" * sTableName * "could not be created, or does it already exist?") "Error"
                            Procedure_Return
                        End

                    End_Procedure

                End_Object

                Object oApiAddColumn_fm is a Form
                    Set Size to 12 77
                    Set Location to 141 14
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label to "Column Name:"
                    Set Label_Row_Offset to 1
                    Set Value to "NewColumn"
                End_Object

                Object oApiColumnType_cf is a ComboForm
                    Set Size to 12 85
                    Set Location to 141 96
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Label to "Type:"
                    Set Entry_State to False

                    Procedure Combo_Fill_List
                        tColumnType[] ColumnTypeArray
                        Integer iSize iCount

                        Send Delete_Data
                        Get _UtilEnumerateColumnTypes of ghoDbUpdateFunctionLibrary DATAFLEX_ID EN_DbTypeDataFlex to ColumnTypeArray
                        Move (SizeOfArray(ColumnTypeArray)) to iSize
                        Decrement iSize
                        For iCount from 0 to iSize
                            Send Combo_Add_Item ColumnTypeArray[iCount].sSQLType
                        Loop
                        Set Value to ColumnTypeArray[0].sSQLType
                    End_Procedure

                    Procedure OnChange
                        Integer iType iSize iDec
                        tSQLConnection SQLConnection
                        Boolean bFixed

                        Get SelectedType to iType
                        Get pSQLConnection of ghoSQLConnectionHandler to SQLConnection
                        Get UtilColumnTypePrecisionSize of ghoDbUpdateFunctionLibrary DATAFLEX_ID EN_DbTypeDataFlex iType to iSize
                        Get UtilColumnTypePrecisionDec  of ghoDbUpdateFunctionLibrary DATAFLEX_ID EN_DbTypeDataFlex iType to iDec
                        Get UtilColumnTypeFixed         of ghoDbUpdateFunctionLibrary DATAFLEX_ID EN_DbTypeDataFlex iType to bFixed

                        Set Enabled_State of oApiLength_sf   to (bFixed = False)
                        Set Enabled_State of oApiDecimals_sf to (bFixed = False)
                        Set Value         of oApiLength_sf   to iSize
                        If (iDec = 0) Begin
                            Set Value     of oApiDecimals_sf to ""
                        End
                        Else Begin
                            Set Value     of oApiDecimals_sf to iDec
                        End
                        If (bFixed = False) Begin
                            Set Enabled_State of oApiDecimals_sf to (iDec <> 0)
                        End
                    End_Procedure

                    Function SelectedType Returns Integer
                        String sValue
                        Integer iType

                        Get Value to sValue
                        Get UtilColumnTypeToInteger of ghoDbUpdateFunctionLibrary DATAFLEX_ID EN_DbTypeDataFlex sValue to iType

                        Function_Return iType
                    End_Function

                End_Object

                Object oApiLength_sf is a SpinForm
                    Set Label to "Length:"
                    Set Size to 12 35
                    Set Location to 141 186
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Value to "10"
                    Set Maximum_Position to 500
                    Set Minimum_Position to 1
                End_Object

                Object oApiDecimals_sf is a SpinForm
                    Set Label to "Decimals:"
                    Set Size to 12 33
                    Set Location to 141 225
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set Label_Row_Offset to 1
                    Set Value to "0"
                    Set Maximum_Position to 16
                    Set Minimum_Position to 1
                End_Object

                Object oApiAddColumn_btn is a cRDCButtonDPI
                    Set Size to 12 69
                    Set Location to 141 271
                    Set Label to "Add Column"
                    Set psToolTip to "ApiColumnAdd function"
                    Set psImage to "ActionAddColumn1.ico"

                    Procedure OnClick
                        Boolean bOk
                        Handle hTable
                        String sTableName sColumnName sType sDriverID
                        Integer iType iLength iDecimals

                        Get Value of oDriverID3_cf            to sDriverID
                        Get Value of oApiTableName_fm         to sTableName
                        Get Value of oApiAddColumn_fm         to sColumnName
                        Get SelectedType of oApiColumnType_cf to iType
                        Get Value        of oApiLength_sf     to iLength
                        Get Value        of oApiDecimals_sf   to iDecimals

                        Set psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                        Get UtilTableNameToHandle of ghoDbUpdateFunctionLibrary sTableName to hTable
                        If (hTable = 0) Begin
                            Send Info_Box "You first need to create the new table by pressing the 'Create New Table...' button, before you can add a column to it."
                            Procedure_Return
                        End
                        If (sColumnName = "") Begin
                            Send Info_Box "You need to enter a column name"
                            Procedure_Return
                        End

                        Get ApiColumnAdd of ghoDbUpdateFunctionLibrary hTable sColumnName iType iLength iDecimals to bOk
                        If (bOk = True) Begin
                            Send Info_Box ("Column" * sColumnName * sType * String(iLength) + ", was successfully added to" * sTableName * "(at filelist slot:" * String(hTable) + ")")
                        End
                        Else Begin
                            Send Info_Box ("The column could NOT be added. Either column" * sColumnName * "already exists or the current Database is incorrect?")
                            Procedure_Return
                        End

                    End_Procedure

                End_Object

                Object oApiAddTableAndColumns_btn is a cRDCButtonDPI
                    Set Size to 26 77
                    Set Location to 184 14
                    Set Label to "Create 'New' Table with Three Columns"
                    Set MultiLineState to True
                    Set psImage to "ActionAddTable1.ico"

                    Procedure OnClick
                        Boolean bOk
                        Handle hTable
                        String sTableName sDriverID

                        Get Value of oDriverID3_cf to sDriverID
                        Get Value of oApiTableName_fm to sTableName
                        Move (Trim(sTableName)) to sTableName
                        If (sTableName = "") Begin
                            Send Info_Box "You first need to enter a table name."
                            Procedure_Return
                        End

                        Send Cursor_Wait of Cursor_Control
                        Get NextFreeFilelistSlot of ghoDbUpdateFunctionLibrary to hTable

                        Set psDriverID       of ghoDbUpdateFunctionLibrary to sDriverID
                        Get ApiTableCreate   of ghoDbUpdateFunctionLibrary hTable sTableName sTableName sTableName True True True to bOk
                        If (bOk = True) Begin
                            Get ApiColumnAdd of ghoDbUpdateFunctionLibrary hTable "Col1Ascii"   DF_ASCII 10 0 to bOk
                            Get ApiColumnAdd of ghoDbUpdateFunctionLibrary hTable "Col2Date"    DF_DATE   6 0 to bOk
                            Get ApiColumnAdd of ghoDbUpdateFunctionLibrary hTable "Col3Numeric" DF_BCD    6 2 to bOk
                        End
                        Send Cursor_Ready of Cursor_Control

                        If (bOk = True) Begin
                            Send Info_Box ("Test table" * sTableName * "with Columns: 'Col1 ASCII 10', 'Col2 Date' and 'Col3 Numeric 6,2' was successfully created and put in filelist slot:" * String(CI_Table1_FileNo))
                        End
                        Else Begin
                            Send Cursor_Ready of Cursor_Control
                            Send Info_Box ("Nope, the test table" * sTableName * "could not be created") "Error"
                            Procedure_Return
                        End

                    End_Procedure

                End_Object

                Object oApiRemoveTable_btn is a cRDCButtonDPI
                    Set Size to 26 77
                    Set Location to 184 96
                    Set Label to "Remove 'New' Table"
                    Set psImage to "ActionDeleteTable1.ico"
                    Set MultiLineState to True

                    Procedure OnClick
                        Boolean bOk
                        Integer iRetval
                        Handle hTable
                        String sTableName sDriverID

                        Get Value of oDriverID3_cf to sDriverID
                        Get Value of oApiTableName_fm to sTableName
                        Get YesNo_Box ("Are you sure you want to PERMANENTLY DELETE the table named:" * String(sTableName) + "?") to iRetval
                        If (iRetval = MBR_Yes) Begin
                            Send Cursor_Wait of Cursor_Control
                            Set psDriverID of ghoDbUpdateFunctionLibrary to sDriverID
                            Get UtilTableNameToHandle of ghoDbUpdateFunctionLibrary sTableName to hTable
                            Get ApiTableRemove of ghoDbUpdateFunctionLibrary hTable to bOk
                            Send Cursor_Ready of Cursor_Control
                            If (bOk = True) Begin
                                Send Info_Box "Table removed"
                            End
                            Else Begin
                                Send Info_Box "Nope, that didnt' work. Either the table doesn't exist or your rights aren't sufficient."
                            End
                        End
                    End_Procedure

                End_Object

                Object oLineControl1 is a LineControl
                    Set Size to 2 387
                    Set Location to 96 6
                    Set peAnchors to anTopLeftRight
                End_Object

                Object oLineControl2 is a LineControl
                    Set Size to 3 248
                    Set Location to 171 9
                End_Object

                Object oTestError_fm is a Form
                    Set Size to 13 64
                    Set Location to 186 180
                    Set Form_Datatype to 0 
                    On_Key kEnter send KeyAction of oFindErrorText_Btn
                End_Object

Register_Function FetchErrorDescription Integer iError Returns String
                Object oFindErrorText_Btn is a Button
                    Set Size to 13 70
                    Set Location to 186 248
                    Set Label to "Find Error Text"
                
                    Procedure OnClick
                        String sRetval
                        Integer iError 
                        Handle hoLogFile
                        
                        Get phoLogFile of ghoDbUpdateFunctionLibrary to hoLogFile
                        Get Value of oTestError_fm to iError
                        Get FetchErrorDescription of hoLogFile iError to sRetval 
                        Set Value of oErrorText_fm to sRetval    
                    End_Procedure
                
                End_Object

                Object oErrorText_fm is a Form
                    Set Size to 13 213
                    Set Location to 202 180
                End_Object

            End_Object

        End_Object

    End_Object

End_Object
