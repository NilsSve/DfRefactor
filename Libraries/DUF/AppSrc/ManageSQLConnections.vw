Use DFClient.pkg
Use cCJCommandBarSystem.pkg
Use cCJGrid.pkg
Use cCJGridColumnRowIndicator.pkg
Use cCJGridColumn.pkg
Use cSQLConnectionButton.pkg

Use DatabaseSelection.dg
Use ServerSelection.dg
Use ManageSQLConnections.dg

Activate_View Activate_oSQLMaintainConnection for oSQLMaintainConnection
Object oSQLMaintainConnection is a dbView
    Set Size to 135 538
    Set Location to 2 2
    Set Maximize_Icon to True
    Set Minimize_Icon to False
    Set Border_Style to Border_Thick
    Set View_Mode to Viewmode_Zoom
    Set pbAutoActivate to True
    Set pbAcceptDropFiles to True

    Set phoMainView of ghoApplication to Self
    
    Property Boolean pbEnabled False
    Property Boolean pbNew False
    Property tDataSourceRow[] pTheData

    Function IniFileName Returns String
        String sRetval
        Get InfileName of oSQLConnections_grd to sRetval
        Function_Return sRetval
    End_Function

    Object oGridInfo_tb is a TextBox
        Set Auto_Size_State to False
        Set Size to 9 368
        Set Location to 10 34
        Set Label to "Note: You can drag and drop a connection file on to the grid."
        Set FontItalics to True
        Set peAnchors to anTopLeftRight
        Set Justification_Mode to JMode_Left
    End_Object

    Object oSQLConnections_grd is a cCJGrid
        Set Size to 98 503
        Set Location to 25 19
        Set peAnchors to anAll
        Set pbShowRowFocus to True
        Set pbUseAlternateRowBackgroundColor to True
        Set pbSelectionEnable to True
        Set pbRestoreLayout to True
        Set psLayoutSection to "oSQLConnections_grd"
        Set piLayoutBuild to 13
        Set pbShowFooter to True
        Set pbAllowAppendRow to False
        Set pbAllowEdit to False
        Set pbAllowInsertRow to False
        Set pbAutoAppend to False
        Set pbAutoSave to False
        Set pbEditOnTyping to False
        Set peVisualTheme to xtpGridThemeExplorer
        
        Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
            Set piWidth to 18
        End_Object

        Object oActive_Col is a cCJGridColumn
            Set piWidth to 81
            Set psCaption to "Enabled"
            Set pbCheckbox to True
            Set psToolTip to "Only one connection can be the active one at any time. Press the 'Edit' button or double-click on a row to edit."
        End_Object

        Object oConnectionID_Col is a cCJGridColumn
            Set piWidth to 90
            Set psCaption to "ID"
        End_Object

        Object oDbType_Col is a cCJGridColumn
            Set piWidth to 150
            Set psCaption to "Database Type"
        End_Object

        Object oServer_Col is a cCJGridColumn
            Set piWidth to 138
            Set psCaption to "Server"
        End_Object

        Object oDatabase_Col is a cCJGridColumn
            Set piWidth to 92
            Set psCaption to "Database"
        End_Object

        Object oDriver_Col is a cCJGridColumn
            Set piWidth to 101
            Set psCaption to "Driver ID"
        End_Object

        Object oConnectionString_Col is a cCJGridColumn
            Set piWidth to 372
            Set psCaption to "Connection String"
            Set psTooltip to "The full connection string as read from the connections ini-file. Press the 'Edit' button or double-click on a row to edit."
        End_Object

        // The following columns are all hidden. The only reason they are here is to make the grid data exactly the same
        // as the tSQLConnection data.
        // See the "Should_Save" function
        //
        // "Untouched" connection string column. Needed when passing data between grid and popup dialog as we mask pw in connection string.
        Object oConnectionStringFull_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Connection String (Untouched)"
            Set pbVisible to False   
            Set pbShowInFieldChooser to False
        End_Object

        Object oTrusted_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Trusted"
            Set pbCheckbox to True
            Set pbVisible to False
        End_Object

        Object oUserID_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "UserID"
            Set pbVisible to False
        End_Object

        Object oPassword_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Password"
            Set pbVisible to False
            Set pbShowInFieldChooser to False
        End_Object

        Object oSchema_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Schema"
            Set pbVisible to False
        End_Object

        Object oBaseTableSpace_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Base Table Space"
            Set pbVisible to False
        End_Object

        Object oLongTableSpace_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Long Table Space"
            Set pbVisible to False
        End_Object

        Object oIndexTableSpace_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Index Table Space"
            Set pbVisible to False
        End_Object

        Object oSilentLogin_Col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Silent Login"
            Set pbCheckbox to True
            Set pbVisible to False
        End_Object

//        Object oDisabled_Col is a cCJGridColumn
//            Set piWidth to 50
//            Set psCaption to "Disabled"
//            Set pbVisible to False
//        End_Object

        Object oCJContextMenu is a cCJContextMenu
            Set pbShowPopupBarToolTips of ghoCommandBars to True

            Object oAddMenuItem is a cCJMenuItem
                Set psCaption to "Add"
                Set psTooltip to "Add new connection"
                Set psImage to "ActionAdd1.ico"
                Set psShortcut to "Ctrl+A"
                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send AddItem
                End_Procedure
            End_Object

            Object oEditMenuItem is a cCJMenuItem
                Set psCaption to "Edit"
                Set psTooltip to "Edit existing connection"
                Set psImage to "ActionEdit1.ico"
                Set psShortcut to "Ctrl+E"
                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send EditItem
                End_Procedure
            End_Object

            Object oDeleteMenuItem is a cCJMenuItem
                Set psCaption to "Delete"
                Set psTooltip to "Delete current connection"
                Set psImage to "ActionDelete1.ico"
                Set psShortcut to "Del"
                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send DeleteItem 
                End_Procedure
            End_Object

            Object oSaveMenuItem is a cCJMenuItem
                Set pbControlBeginGroup to True
                Set psCaption to "Save"
                Set psTooltip to "Save changes"
                Set psImage to "ActionSave1.ico" 
                Set psShortcut to "Ctrl+S"
                
                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send SaveIniFile 
                End_Procedure

                Function IsEnabled Returns Boolean
                    Boolean bState
                    Get Should_Save to bState
                    Function_Return (bState = True)
                End_Function
            End_Object

            Object oSaveAsMenuItem is a cCJMenuItem
                Set psCaption to "Save As"
                Set psTooltip to "Save SQL Configuration File As"  
                Set psImage to "ActionSaveAs1.ico"
                
                Procedure OnExecute Variant vCommandBarControl  
                    String sPath sIniFileName sFileName

                    Forward Send OnExecute vCommandBarControl
                    
                    Get psIniFilePath of ghoSQLConnectionHandler to sPath
                    Get psIniFileName of ghoSQLConnectionHandler to sIniFileName
                    Get vSelectSaveFile ".int" "Please enter a file name to save to" sPath sIniFileName to sFileName
                    If (sFileName <> "") Begin
                        Get ParseFolderName sFileName to sPath
                        Get ParseFileName   sFileName to sIniFileName
                        Set psIniFilePath of ghoSQLConnectionHandler to sPath
                        Set psIniFileName of ghoSQLConnectionHandler to sIniFileName
                        Send SaveIniFile  of (phoMainView(ghoApplication))
                    End
                End_Procedure

            End_Object   

            Object oOpenMenuItem is a cCJMenuItem
                Set pbControlBeginGroup to True
                Set psCaption to "Open"
                Set psTooltip to "Open SQL Connection ini-file"
                Set psImage to "ActionOpen1.ico"
                Set psShortcut to "Ctrl+O"
                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send ActivateOpenDialog
                End_Procedure
            End_Object

            Object oRefreshMenuItem is a cCJMenuItem
                Set psCaption to "Refresh"
                Set psTooltip to "Refresh grid (re-read values from ini-file)"
                Set psImage to "ActionRefresh1.ico"
                Set psShortcut to "Ctrl+R"

                Procedure OnExecute Variant vCommandBarControl
                    Forward Send OnExecute vCommandBarControl
                    Send RefreshIniFile
                End_Procedure

                Function IsEnabled Returns Boolean
                    Boolean bSave
                    Get Should_Save to bSave
                    Function_Return (bSave = True)
                End_Function
                
            End_Object

            Set phoContextMenu to Self
        End_Object

        Function Should_Save Returns Boolean
            tDataSourceRow[] TheData1 TheData2
            Handle hoDataSource
            Boolean bShouldSave

            Move True to bShouldSave
            Get pTheData to TheData1
            Get phoDataSource to hoDataSource
            Get DataSource    of hoDataSource to TheData2
            Move (not(IsSameArray(TheData1, TheData2))) to bShouldSave

            Function_Return bShouldSave
        End_Function

        Function HasRecord Returns Boolean
            tDataSourceRow[] TheData
            Handle hoDataSource
            Integer iSize

            Get phoDataSource to hoDataSource
            Get DataSource    of hoDataSource to TheData
            Move (SizeOfArray(TheData)) to iSize

            Function_Return (iSize > 0)
        End_Function

        Procedure ChangeHeaderText
            Handle[] hoPanels
            String sFileName

            Send ChangeStatusRowText ""
            Get IniFileName to sFileName
            // Not sure why, but if the oStatusPane1 was set to "Set piID to sbpIDIdlePane",
            // it wasn't always updated when this message was send. So instead change the
            // text explicitly:
            Get PaneObjects of (phoStatusBar(ghoCommandBars)) to hoPanels
            Set psText of hoPanels[0] to sFileName
        End_Procedure
        
        Function InFileName Returns String
            String sFileName sPath
            Handle ho
            Boolean bChangesExist

            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
            Get psIniFilePath of ho to sPath
            Get psIniFileName of ho to sFileName
            If (sFileName = "") Begin
                Move "" to sPath
            End                 
            Else Begin
                Get Should_Save to bChangesExist
                If (bChangesExist = True) Begin
                    Move (sFileName + "*") to sFileName
                End
            End
            Function_Return (sPath + sFileName)
        End_Function

        Procedure LoadData
            Handle hoDataSource ho
            tDataSourceRow[] TheData
            tDataSourceRow TheRow
            Integer iCount iSize
            tSQLConnection[] SQLConnectionsArray

            Send ChangeHeaderText
            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho

            Get phoDataSource to hoDataSource
            Send Reset of hoDataSource

            Get ReadIniFile to SQLConnectionsArray
            Move (SizeOfArray(SQLConnectionsArray)) to iSize
            Decrement iSize

            // Load data to the grid datasource array
            For iCount from 0 to iSize
                Get MoveSQLConnectionToGridRow SQLConnectionsArray[iCount] to TheRow
                Move TheRow to TheData[iCount]
            Loop

            Set pTheData to TheData

            // Initialize Grid with new data
            Send InitializeData TheData

            Set psFooterText of oConnectionString_Col to ("Number of connections:" * String(iSize +1))
            Send MovetoFirstRow
        End_Procedure    
        
        Procedure ClearData    
            Handle hoDataSource
            tDataSourceRow[] TheData

            Send ChangeHeaderText
            Set pTheData to TheData
            Get phoDataSource to hoDataSource 
            Send InitializeData TheData
        End_Procedure

        // Transfers data between a tSQLConnection struct and a grid data row.
        Function MoveSQLConnectionToGridRow tSQLConnection SQLConnection Returns tDataSourceRow
            tDataSourceRow TheRow
            Integer iDbType
            String sValue

            Move SQLConnection.bEnabled             to TheRow.sValue[piColumnId(oActive_Col(Self))]
            Move SQLConnection.sConnectionID        to TheRow.sValue[piColumnId(oConnectionID_Col(Self))]
            Move SQLConnection.sDriverID            to TheRow.sValue[piColumnId(oDriver_Col(Self))]

            // We only show three asterisks ("***") instead of the password in the grid.
            Move (Replace(("PWD=" + SQLConnection.sPassword), SQLConnection.sConnectionString, "PWD=***")) to sValue
            Move sValue                             to TheRow.sValue[piColumnId(oConnectionString_Col(Self))]

            Move SQLConnection.iDbType to iDbType
            Get SqlUtilDbTypeToString of ghoDbUpdateFunctionLibrary iDbType to sValue
            Move sValue                             to TheRow.sValue[piColumnId(oDbType_Col(Self))]
            Move SQLConnection.sServer              to TheRow.sValue[piColumnId(oServer_Col(Self))]
            Move SQLConnection.sDatabase            to TheRow.sValue[piColumnId(oDatabase_Col(Self))]

            // Hidden columns (to make Should_Save function work)
            Move SQLConnection.sConnectionString    to TheRow.sValue[piColumnId(oConnectionStringFull_Col(Self))] // "Untouched" connection string.
            Move SQLConnection.bTrusted             to TheRow.sValue[piColumnId(oTrusted_Col(Self))]
            Move SQLConnection.sUserID              to TheRow.sValue[piColumnId(oUserID_Col(Self))]
            Move SQLConnection.sPassword            to TheRow.sValue[piColumnId(oPassword_Col(Self))]
            Move SQLConnection.sSchema              to TheRow.sValue[piColumnId(oSchema_Col(Self))]
            Move SQLConnection.sBaseTableSpace      to TheRow.sValue[piColumnId(oBaseTableSpace_Col(Self))]
            Move SQLConnection.sLongTableSpace      to TheRow.sValue[piColumnId(oLongTableSpace_Col(Self))]
            Move SQLConnection.sIndexTableSpace     to TheRow.sValue[piColumnId(oIndexTableSpace_Col(Self))]
            Move SQLConnection.bSilentLogin         to TheRow.sValue[piColumnId(oSilentLogin_Col(Self))]
//            Move SQLConnection.bDisabled            to TheRow.sValue[piColumnId(oDisabled_Col(Self))]

            Function_Return TheRow
        End_Function

        // Transfers data between a grid data row and a tSQLConnection struct.
        Function MoveGridRowToSQLConnection tDataSourceRow TheRow Returns tSQLConnection
            tSQLConnection SQLConnection
            String sValue

            Move TheRow.sValue[piColumnId(oActive_Col(Self))]               to SQLConnection.bEnabled
            Move TheRow.sValue[piColumnId(oConnectionID_Col(Self))]         to SQLConnection.sConnectionID

            Move TheRow.sValue[piColumnId(oDbType_Col(Self))]               to sValue
            Get SqlUtilDbTypeToInteger of ghoDbUpdateFunctionLibrary sValue to SQLConnection.iDbType
            Move TheRow.sValue[piColumnId(oServer_Col(Self))]               to SQLConnection.sServer
            Move TheRow.sValue[piColumnId(oDatabase_Col(Self))]             to SQLConnection.sDatabase
            Move TheRow.sValue[piColumnId(oDriver_Col(Self))]               to SQLConnection.sDriverID

            // Hidden columns (to make Should_Save function work)
            Move TheRow.sValue[piColumnId(oConnectionStringFull_Col(Self))] to SQLConnection.sConnectionString
            Move TheRow.sValue[piColumnId(oTrusted_Col(Self))]              to SQLConnection.bTrusted
            Move TheRow.sValue[piColumnId(oUserID_Col(Self))]               to SQLConnection.sUserID
            Move TheRow.sValue[piColumnId(oPassword_Col(Self))]             to SQLConnection.sPassword
            Move TheRow.sValue[piColumnId(oSchema_Col(Self))]               to SQLConnection.sSchema
            Move TheRow.sValue[piColumnId(oBaseTableSpace_Col(Self))]       to SQLConnection.sBaseTableSpace
            Move TheRow.sValue[piColumnId(oLongTableSpace_Col(Self))]       to SQLConnection.sLongTableSpace
            Move TheRow.sValue[piColumnId(oIndexTableSpace_Col(Self))]      to SQLConnection.sIndexTableSpace
            Move TheRow.sValue[piColumnId(oSilentLogin_Col(Self))]          to SQLConnection.bSilentLogin
//            Move TheRow.sValue[piColumnId(oDisabled_Col(Self))]             to SQLConnection.bDisabled

            Function_Return SQLConnection
        End_Function

        // Called when the grid object is created:
        Procedure Activating
            Forward Send Activating
            Send LoadData
        End_Procedure

        Function CurrentRow Returns Integer
            Handle hoDataSource
            Integer iRow

            Get phoDataSource to hoDataSource
            Get SelectedRow   of hoDataSource to iRow
            Function_Return iRow
        End_Function

        Function CurrentRowData Returns tDataSourceRow
            tDataSourceRow[] TheData
            tDataSourceRow TheRow
            Handle ho hoDataSource
            Integer iRow

            Get phoDataSource  to hoDataSource
            Get DataSource     of hoDataSource to TheData
            Get SelectedRow    of hoDataSource to iRow
            Move TheData[iRow] to TheRow

            Function_Return TheRow
        End_Function

        Procedure OnRowChanged Integer iOldRow Integer iNewSelectedRow
            Integer iRow
            Handle hoDataSource
            tDataSourceRow[] RowData

            Forward Send OnRowChanged iOldRow iNewSelectedRow
            Send ChangeHeaderText

            Get phoDataSource to hoDataSource

            Get SelectedRow of hoDataSource to iRow
            If (iRow <> -1) Begin
                Get DataSource of hoDataSource to RowData
                Set pbEnabled to RowData[iRow].sValue[piColumnid(oActive_Col(Self))]
            End
        End_Procedure

        Procedure OnComRowDblClick Variant llRow Variant llItem
            Forward Send OnComRowDblClick llRow llItem
            Delegate Send EditItem 
        End_Procedure

        Procedure OnEnterKey
            Forward Send OnEnterKey
            Delegate Send EditItem 
        End_Procedure

        Procedure AddConnection tDataSourceRow TheRow
            Integer iSize iCount
            Handle hoDataSource
            tDataSourceRow[] TheData
            Boolean bEnabled

            Get phoDataSource to hoDataSource
            Get DataSource    of hoDataSource to TheData

            Move (SizeOfArray(TheData)) to iSize
            Move (TheRow.sValue[piColumnid(oActive_Col(Self))]) to bEnabled
            If (bEnabled = True) Begin
                // Then bEnabled state have changed; deactivate all current rows.
                For iCount from 0 to (iSize -1)
                    Move False to TheData[iCount].sValue[piColumnId(oActive_Col(Self))]
                Loop
            End

            Move TheRow to TheData[iSize]

            // Initialize Grid with new data
            Send InitializeData TheData True
            Move (SizeOfArray(TheData)) to iSize
            Send MoveToLastRow

            Set psFooterText of oConnectionString_Col to ("Number of connections:" * String(iSize))
        End_Procedure

        Procedure UpdateConnection tDataSourceRow TheRow
            Integer iRow iSize iCount
            Handle hoDataSource
            tDataSourceRow[] TheData
            Boolean bEnabled

            Get phoDataSource to hoDataSource
            Get SelectedRow of hoDataSource to iRow
            If (iRow <> -1) Begin
                Get DataSource of hoDataSource to TheData

                // If bEnabled state has changed; deactivate all rows.
                Move (TheRow.sValue[piColumnId(oActive_Col(Self))]) to bEnabled
                If (bEnabled = True) Begin
                    Move (SizeOfArray(TheData)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Move False to TheData[iCount].sValue[piColumnId(oActive_Col(Self))]
                    Loop
                End

                Move TheRow to TheData[iRow]
            End

            // Initialize Grid with new data
            Send ReInitializeData TheData True
            Move (SizeOfArray(TheData)) to iSize
            Set psFooterText of oConnectionString_Col to ("Number of connections:" * String(iSize))
        End_Procedure

        Procedure RemoveCurrentConnection
            Integer iSize iRow iItem
            Handle hoDataSource
            tDataSourceRow[] TheData

            Move 0 to iItem
            Get phoDataSource to hoDataSource
            Get DataSource of hoDataSource to TheData

            Get SelectedRow of hoDataSource to iRow
            If (iRow = -1) Begin
                Procedure_Return
            End

            Move False to Err
            Send Request_Delete

            Get DataSource of hoDataSource to TheData
            Move (SizeOfArray(TheData)) to iSize
            Set psFooterText of oConnectionString_Col to ("Number of connections:" * String(iSize))
        End_Procedure

        Function IsOneItemActive Returns Boolean
            Handle hoDataSource ho
            tDataSourceRow[] TheData
            Integer iSize iCount
            Boolean bRetval bExists
            String sSection

            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
            Get psIniSectionName of ho to sSection
            Get SectionExists    of ho sSection to bExists

            Get phoDataSource to hoDataSource
            Get DataSource of hoDataSource to TheData

            Move (SizeOfArray(TheData)) to iSize
            If (iSize = 0) Begin
                Function_Return True
            End

            Decrement iSize
            For iCount from 0 to iSize
                If (TheData[iCount].sValue[piColumnId(oActive_Col(Self))] = True) Begin
                    Move True to bRetval
                End
            Loop

            Function_Return bRetval
        End_Function

        Function ReadIniFile Returns tSQLConnection[]
            tSQLConnection[] SQLConnectionsArray
            Handle ho

            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
            Get SQLIniFileReadConnections of ho to SQLConnectionsArray

            Function_Return SQLConnectionsArray
        End_Function

        Procedure WriteIniFile
            Integer iCount iSize iRetval
            Handle hoDataSource ho
            tDataSourceRow[] TheData
            tDataSourceRow TheRow
            tSQLConnection[] SQLConnectionArray
            tSQLConnection SQLConnection
            Boolean bIsOneActive bOK
            String sPath sIniFileName
            
            Get psIniFileName of ghoSQLConnectionHandler to sIniFileName
            If (sIniFileName = "") Begin
                Get vSelectSaveFile ("SQLConnections ini-files (*.ini)|" + CS_SQLIniFileName + "|All Ini Files (*.ini)|*.ini|All Files (*.*)|*.*") "Select a connection ini-file" "" to sIniFileName
                If (sIniFileName <> "") Begin
                    Get ParseFolderName sIniFileName to sPath
                    Set psIniFilePath of ghoSQLConnectionHandler to sPath
                    Get ParseFileName sIniFileName to sIniFileName
                    Set psIniFileName of ghoSQLConnectionHandler to sIniFileName
                End  
                Else Begin
                    Procedure_Return
                End
            End
            
            // 2018-07-14 I don't think this is necessary. In fact it can be quite practical in
            // testing to disable all connections, or if e.g. customer's connections has been tested,
            // that no longer are available locally.
            Get IsOneItemActive to bIsOneActive
//            If (bIsOneActive = False) Begin
//                Send Info_Box "Sorry, you need to set one connection as active before changes can be saved."
//                Procedure_Return
//            End
            If (bIsOneActive = False) Begin
                Get YesNo_Box "Warning, no connection has been set to 'Enabled'. That means that the Database Framework will not read any information from here when initialized.\n\nAre you sure you want to continue to save without any connection Enabled?" to iRetval
                If (iRetval = MBR_No) Begin
                    Procedure_Return
                End
            End

            Move 0 to iCount
            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
            Get phoDataSource to hoDataSource
            Get DataSource of hoDataSource to TheData
            Move (SizeOfArray(TheData)) to iSize
            Decrement iSize

            // Load data from the grid datasource array to SQLConnection array
            For iCount from 0 to iSize
                Move TheData[iCount] to TheRow
                Get MoveGridRowToSQLConnection TheRow to SQLConnection
                Move SQLConnection to SQLConnectionArray[iCount]
            Loop

            Get SQLIniFileWriteConnections of ho SQLConnectionArray to bOK
            If (bOK = False) Begin
                Send ChangeStatusRowText "Sorry, an error occured while saving the file and changes were not saved."
                Procedure_Return
            End

            // Update the view property with the newly saved values. (Used to check if anything has changed)
            Set pTheData to TheData
            Send ChangeHeaderText
            Send ChangeStatusRowText "Ready! File saved."
        End_Procedure

        Procedure OnHeaderClick Integer iCol
            String sPath sFileName
            Handle ho

            Forward Send OnHeaderClick iCol

            Get vSelect_File ("SQLConnections ini-files (*.ini)|" + CS_SQLIniFileName + "|All Ini Files (*.ini)|*.ini|All Files (*.*)|*.*") "Select a connection ini-file" "" to sFileName
            If (sFileName <> "") Begin
                Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
                Get ParseFolderName sFileName to sPath
                Set psIniFilePath of ho to sPath
                Get ParseFileName sFileName to sFileName
                Set psIniFileName of ho to sFilename
                Set pbDFConnId of ho to (sFileName <> CS_SQLIniFileName)
                Send LoadData of oSQLConnections_grd
            End
        End_Procedure

        Procedure OnCreateGridControl 
            Handle hoObject  
            Integer iToolTipStyle      
            Boolean bIsBalloonStyleSupported
            
            Forward Send OnCreateGridControl
    
            Get phoToolTipContext to hoObject
            If (hoObject <> 0) Begin
                Move xtpToolTipStandard to iToolTipStyle    
                // Baloon tooltip style requires IE 5.0 or later, so check if installed.
                // The ComShowTitleAndDescription also requires IE 5.0.
                Get ComIsBalloonStyleSupported of hoObject to bIsBalloonStyleSupported
                If (bIsBalloonStyleSupported = True) Begin
                    Send ComShowTitleAndDescription of hoObject True xtpToolTipIconInfo
                End                                                   
                Set ComStyle             of hoObject to iToolTipStyle
                Set ComShowOfficeBorder  of hoObject to True
                Set ComShowShadow        of hoObject to True
                // Set the max width for a tooltip. 250 just seems to be a good
                // compromise. After 250 pixels the text will wrap to the next line automatically.
                Set ComMaxTipWidth       of hoObject to 250 // In pixels
            End 
        End_Procedure

        // These overrides the grid standar behaviour
        On_Key kSave_Record Send SaveIniFile
        On_Key Key_F5       Send RefreshIniFile
    End_Object

    // Public access methods: (used by menu/toolbar system)
    Procedure ActivateOpenDialog
        Send OnHeaderClick of oSQLConnections_grd 1
    End_Procedure

    Procedure RefreshIniFile
        Boolean bChanged
        Handle ho
        Integer iRetval

        Move (oSQLConnections_grd(Self)) to ho
        Get Should_Save of ho to bChanged
        If (bChanged = True) Begin
            Get YesNo_Box "Changes exists! Press 'Yes' to refresh (changes will be lost)." "Refresh Question" to iRetval
            If (iRetval <> MBR_Yes) Begin
                Procedure_Return
            End
        End
        Send ChangeStatusRowText ""
        Send LoadData of oSQLConnections_grd
    End_Procedure

    Procedure AddItem
        Boolean bChanged bDFConnId
        tSQLConnection SQLConnection
        tDataSourceRow[] TheData
        tDataSourceRow   TheRow
        Handle hoDataSource

        Send ChangeStatusRowText ""
        Get IsDFConnId to bDFConnId
        Move EN_DbTypeMSSQL to SQLConnection.iDbType
        Move MSSQLDRV_ID    to SQLConnection.sDriverID
        Get phoDataSource of oSQLConnections_grd to hoDataSource
        Get DataSource of hoDataSource to TheData
        Send Activate_SQLMaintainConnections_dg of (Client_Id(phoMainPanel(ghoApplication))) (pbNew(Self)) -1 (&SQLConnection) (&bChanged) bDFConnId TheData
        If (bChanged = True) Begin
            Get MoveSQLConnectionToGridRow of oSQLConnections_grd SQLConnection to TheRow
            Send AddConnection of oSQLConnections_grd TheRow
        End
    End_Procedure

    Procedure EditItem
        Boolean bEnabled bChanged bDFConnId
        tSQLConnection SQLConnection
        tDataSourceRow TheRow
        tDataSourceRow[] TheData
        Handle hoDataSource
        Integer iCurrentRow

        Get CurrentRowData of oSQLConnections_grd to TheRow
        Get MoveGridRowToSQLConnection of oSQLConnections_grd TheRow to SQLConnection
        Send ChangeStatusRowText ""
        Get pbEnabled to bEnabled
        Get IsDFConnId to bDFConnId

        Get phoDataSource of oSQLConnections_grd to hoDataSource
        Get DataSource of hoDataSource to TheData
        Get CurrentRow of oSQLConnections_grd to iCurrentRow

        Send Activate_SQLMaintainConnections_dg of (Client_Id(phoMainPanel(ghoApplication))) (pbNew(Self)) iCurrentRow (&SQLConnection) (&bChanged) bDFConnId TheData
        If (bChanged = True) Begin
            Get MoveSQLConnectionToGridRow of oSQLConnections_grd SQLConnection to TheRow
            Send UpdateConnection of oSQLConnections_grd TheRow
        End
    End_Procedure

    Procedure SaveIniFile
        Send ChangeStatusRowText ""
        Send WriteIniFile of oSQLConnections_grd
    End_Procedure

    Procedure ClearIniFile
        Handle ho
        Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
        Set psIniFilePath of ho to ""
        Set psIniFileName of ho to ""
        Set pbDFConnId of ho to False
        Send ClearData of (oSQLConnections_grd(phoMainView(ghoApplication))) 
    End_Procedure   
                
    Procedure DeleteItem
        Send ChangeStatusRowText ""
        Send RemoveCurrentConnection of oSQLConnections_grd
    End_Procedure

    Procedure ExitApplication
        Send Exit_Application of ghoApplication
    End_Procedure
    
    // Other messages used by the view:
    Function IsDFConnId Returns Boolean
        Boolean bDFConnId
        Handle ho
        String sFileName

        Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
        Get psIniFileName of ho to sFileName
        Move (Uppercase(sFileName) = Uppercase(CS_SQLDF19IniFileName)) to bDFConnId
        Set pbDFConnId of ho to bDFConnId

        Function_Return bDFConnId
    End_Function

    Procedure OnFileDropped String sFilename Boolean bLast
        Boolean bHasChange
        Handle ho hoGrid
        Integer iRetval
        String sPath

        Forward Send OnFileDropped sFilename bLast

        If (bLast = True) Begin
            Move (oSQLConnections_grd(Self)) to hoGrid
            Get ParseFolderName sFilename to sPath
            Get ParseFileName   sFilename to sFilename
            If (Uppercase(sFilename) <> Uppercase(CS_SQLIniFileName) and Uppercase(sFilename) <> Uppercase(CS_SQLDF19IniFileName)) Begin
                Send Info_Box ("Sorry, only" * CS_SQLIniFileName * "files can be dropped!")
                Procedure_Return
            End
            Get Should_Save of hoGrid to bHasChange
            If (bHasChange = True) Begin
                Get YesNo_Box "Changes exist! Do you still want to load the new file?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return
                End
            End
            Get phoSQLConnectionIniFile of ghoSQLConnectionHandler to ho
            Set psIniFilePath of ho to sPath
            Set psIniFileName of ho to sFilename
            Send LoadData of oSQLConnections_grd
        End
    End_Procedure

    // This is only being called when there is no SQLConnections.ini file;
    // thus a new active/enabled DFConnection ID needs to be established.
    Procedure ConnectionDoesNotExist
        tSQLConnection SQLConnection
        Boolean bChanged bDFConnId bEnabled
        Handle ho
        tDataSourceRow TheRow
        Handle hoDataSource
        tDataSourceRow[] TheData

        Get IsDFConnId to bDFConnId

        Move (oSQLMaintainConnections_dg(Self)) to ho
        Move True to bEnabled
        Set pbNew to True
        Set pbNew of ho to True

        Get phoDataSource of oSQLConnections_grd to hoDataSource
        Get DataSource of hoDataSource to TheData

        Send Activate_SQLMaintainConnections_dg of (Client_Id(phoMainPanel(ghoApplication))) (pbNew(Self)) -1 (&SQLConnection) (&bChanged) bDFConnId TheData
        If (bChanged = True) Begin
            // We also need to tell the main connection object that we now have
            // created a connection.
            Set pSQLConnection            of ghoSQLConnectionHandler to SQLConnection
            // And add the data to the grid.
            Get MoveSQLConnectionToGridRow of oSQLConnections_grd SQLConnection to TheRow
            Send AddConnection of oSQLConnections_grd TheRow
            // Not new anymore.
            Set pbNew to False
            Set pbNew of ho to False
        End
    End_Procedure

    Procedure ChangeStatusRowText String sText
        Handle[] hoPanels
        Get PaneObjects of (phoStatusBar(ghoCommandBars)) to hoPanels
        Set psText of hoPanels[1] to sText
    End_Procedure

    // On idle handling:
    Object oIdle is a cIdleHandler
        Procedure OnIdle
          Delegate Send OnIdle
        End_Procedure
    End_Object

    Procedure OnIdle
        Handle ho

        Move (oSQLConnections_grd(Self)) to ho
        Send ChangeHeaderText of ho
    End_Procedure

    Procedure Activating
        Handle ho

        Set Maximize_Icon to True
        Set Minimize_Icon to False
        Set Border_Style to Border_Thick
        Set View_Mode to Viewmode_Zoom

        // Note: The following line is essential for the resizing logic
        // to work when starting the program.
        Move (Client_Id(ghoCommandBars)) to ho
        Set Border_Style of ho to Border_ClientEdge

        Set pbEnabled of oIdle to True
    End_Procedure

    Procedure Deactivating
        Set pbEnabled of oIdle to False
        Forward Send Deactivating
    End_Procedure

    Function Verify_Exit_Application Returns Integer
        Integer iRetval
        Boolean bChanged

        Get Should_Save of oSQLConnections_grd to bChanged
        If (bChanged = False) Begin
            Function_Return False
        End
        Else Begin
            Get YesNoCancel_Box "Changes exists. Save changes first?" to iRetval
            If (iRetval = MBR_Cancel) Begin
                Function_Return True
            End
            If (iRetval = MBR_Yes) Begin
                Send SaveIniFile //KeyAction of oSave_btn
                Send Exit_Application
            End
            If (iRetval = MBR_No) Begin
                Function_Return False
            End
        End
        Function_Return True
    End_Function

    On_Key kDelete_Character Send DeleteItem 
    On_Key Key_Ctrl+Key_D    Send DeleteItem 
    On_Key Key_Alt+Key_D     Send DeleteItem 
    On_Key Key_Ctrl+Key_E    Send EditItem   
    On_Key Key_Alt+Key_E     Send EditItem   
    On_Key Key_Ctrl+Key_A    Send AddItem    
    On_Key Key_Alt+Key_A     Send AddItem    
    On_Key Key_F5            Send RefreshIniFile 
    On_Key Key_Ctrl+Key_R    Send RefreshIniFile 
    On_Key Key_Alt+Key_R     Send RefreshIniFile 
    On_Key Key_Ctrl+Key_F5   Send ClearIniFile
    On_Key kSave_Record      Send SaveIniFile    
    On_Key Key_Ctrl+Key_S    Send SaveIniFile    
    On_Key Key_F2            Send SaveIniFile    
    On_Key Key_Ctrl+Key_X    Send ExitApplication
    On_Key Key_Ctrl+Key_O    Send ActivateOpenDialog
    On_Key Key_Alt+Key_O     Send ActivateOpenDialog
    On_Key kCancel           Send None
    On_Key Key_Ctrl+Key_F4   Send None
End_Object
