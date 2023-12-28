//****************************************************************************
// $Module type: Include file
// $Module name: cSQLConnectionIniFile.inc
//
// $Author     : Nils Svedmyr, RDC Tools International.
// Copyright (c) 2012 RDC Tools International
// E-mail      : support@rdctools.com
// Web-site    : http://www.rdctools.com
//
// Created     : 2017-01-18 @ 13:04 (Military date format - Year-Month-Day)
//
// Note        : Header file with constant declarations for the cSQLConnectionIniFile class.
//
// The code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// This is free software; you can redistribute it and/or modify it under the terms of the
// GNU Lesser General Public License - see the "GNU Lesser General Public License.txt"
// in the help folder for more details.
//
Use Winkern.pkg
Use cIniFile.pkg
Use cCryptographerEx.pkg
Use Base64Functions.pkg
Use MSSqldrv.pkg
Use db2_drv.pkg
Use odbc_drv.pkg
Use DFBtrDrv.pkg
Use vWin32fh.pkg

Use DUFLanguageConstants.inc

#IFNDEF DATAFLEX_ID
    Define DATAFLEX_ID for "DATAFLEX"
#ENDIF  

// Create a new PSQL identifier for the Btrieve driver.
#IFNDEF PSQLDRV_ID
    Define PSQLDRV_ID for "DFBTRDRV"
#ENDIF

// SQL Back-ends (iSQLDbType in the tSQLKeywords struct).
// They can have slightly different SQL keywords.
// Note: If a new type is added to the list,
//       the struct array xxx must be adjusted
//       so that it is filled with all SQL
//       keywords for that new type.
Enum_List  
    #IFNDEF EN_DbTypeDataFlex
        Define EN_DbTypeDataFlex   for 0
    #ENDIF
    #IFNDEF EN_DbTypeMSSQL   
        Define EN_DbTypeMSSQL      for 1
    #ENDIF
    #IFNDEF EN_DbTypeMySQL   
        Define EN_DbTypeMySQL      for 2
    #ENDIF
    #IFNDEF EN_DbTypeOracle  
        Define EN_DbTypeOracle     for 3
    #ENDIF
    #IFNDEF EN_DbTypeDB2     
        Define EN_DbTypeDB2        for 4
    #ENDIF
    #IFNDEF EN_DbTypePostgre 
        Define EN_DbTypePostgre    for 5
    #ENDIF
    #IFNDEF EN_DbTypePervasive 
        Define EN_DbTypePervasive  for 6
    #ENDIF
End_Enum_List

// We need to have our "own" constants for the standard DataFlex data types.
// These can be used with SQL functions such as e.g. SQLColumnAdd, instead
// of using one of the driver specific integer constants such as e.g. "SQL_VARCHAR".
Define CS_DbTypeDataFlex    for "DataFlex Embedded"
Define CS_DbTypeMSSQL       for "Microsoft SQL Server"
Define CS_DbTypeMySQL       for "MySQL"
Define CS_DbTypeOracle      for "Oracle"
Define CS_DbTypeDB2         for "IBM DB2"
Define CS_DbTypePostgre     for "PostgreSQL"
Define CS_DbTypePervasive   for "Pervasive.SQL (Btrieve)"

#IFNDEF MS_ENHANCED_PROV
    Define MS_ENHANCED_PROV for "Microsoft Enhanced Cryptographic Provider v1.0"
#ENDIF

// SQLConnection.ini constants:
#IFNDEF CS_SQLConnectionIDText
    Define CS_SQLConnectionIDText       for "DFConnectionId"
#ENDIF

Define CS_SQLIniFileName                for "SQLConnections.ini"
Define CS_SQLDF19IniFileName            for "DFConnId.ini"
Define CS_SQLIniConnectionSection       for "SQL Connections" // Obsolete!
Define CS_SQLIniSectionName             for "Connection"
Define CS_SQLODBCIniSectionName         for "ODBC"

// DF 19 ini-file settings:
Define CS_SQLIniConnectionIdKeyword     for "Id"
Define CS_SQLIniDriverKeyword           for "Driver"
Define CS_SQLIniConnectionKeyWord       for "Connection"
Define CS_SQLIniUIDKeyword              for "UID"
Define CS_SQLIniPWDKeyword              for "PWD"
Define CS_SQLIniDFPWDKeyword            for "DFPWD"
Define CS_SQLIniServerKeyword           for "SERVER"
Define CS_SQLIniDSNKeyword              for "DSN"
Define CS_SQLIniFileDSNKeyword          for "FILEDSN"
Define CS_SQLIniDatabaseKeyword         for "DATABASE"
Define CS_SQLIniTrustedKeyword          for "Trusted_Connection" 
Define CS_SQLIniDisabledKeyword         for "Disabled"

// Database Update Framework extended settings:
Define CS_SQLIniDbTypeKeyword           for "DbType"
Define CS_SQLIniSchemaKeyword           for "Schema"
Define CS_SQLIniBaseTableSpaceKeyword   for "Base Table Space"
Define CS_SQLIniLongTableSpaceKeyword   for "Long Table Space"
Define CS_SQLIniIndexTableSpaceKeyword  for "Index Table Space"
Define CS_SQLIniSilentLoginKeyword      for "Silent Login"
Define CS_SQLIniDisabledKeyword         for "Disabled"      // For compatability with DF19.

Define CS_SQLIniConnectionPWD           for "PWD"
Define CS_SQLIniConnectionYes           for "Yes"
Define CS_SQLIniConnectionNo            for "No"

Struct tSQLConnection
    Boolean bEnabled                // 1. There can only be one active/enabled connection at a time.
    String sConnectionID            // 2. The name of the connection ID.
    Integer iDbType                 // 3. Database type; "MS-SQL Server", "DB2", "Oracle", "MySQL", "PostgreSQL"
    String sDriverID                // 4. Name of the driver. E.g. MSSQLDRV, DB2_DRV, ODBC_DRV or PSQLDRV_ID.
    String sServer                  // 5. SQL Server/DSN/ODBC source name. (In DF19 this is the "sString" member of the tConnection struct.)
    String sDatabase                // 6. SQL Database
    String sConnectionString        // 7. Full connection string as is needed by e.g. the login command.
    Boolean bTrusted                // 8. Trusted connection (then is UID & PWD not used)
    String sUserID                  // 9. User ID
    String sPassword                // 10. Password
    String sSchema                  // 11. DB2 (and perhaps ODBC specific)
    String sBaseTableSpace          // 12. DB2 specific
    String sLongTableSpace          // 13. DB2 specific
    String sIndexTableSpace         // 14. DB2 specific
    Boolean bSilentLogin            // 15. True=Silent login. (i.e. don't show Database login dialog if database login to fails). Same as driver "Options" parameter.
    Boolean bError                  // 16. Set to true on error.
    Boolean bDAWConnection          // 17. True if a DFConnId.ini file (from DAW) has been used instead of a DUF SQLConnections.ini file.
End_Struct
