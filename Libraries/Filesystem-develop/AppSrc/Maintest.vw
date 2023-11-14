Use Windows.pkg
Use DFClient.pkg

Activate_View Activate_oMaintest for oMaintest
Object oMaintest is a dbView

    Set Border_Style to Border_Thick
    Set Size to 268 539
    Set Location to 12 30
    Set Label to "Maintest"
    Set pbAutoActivate to True

    Object oTestFile is a Form
        Set Size to 12 173
        Set Location to 7 86
        Set Label to "File:"
        
        Procedure Activating
            Forward Send Activating
            Set Value to "D:\FileTest\Test æøåÆØÅ.txt"
        End_Procedure
    
    End_Object

    Object oTestPath is a Form
        Set Size to 12 173
        Set Location to 24 86
        Set Label to "Path:"
        
        Procedure Activating
            Forward Send Activating
            Set Value to "D:\FileTest;c:\Windows\Temp"
        End_Procedure
    
    End_Object

    Object oTestDir is a Form
        Set Size to 12 173
        Set Location to 9 358
        Set Label to "Directory:"
        
        Procedure Activating
            Forward Send Activating
            Set Value to "D:\FileTest\Testdir med æøå"
        End_Procedure
    
    End_Object

    Object ogrpBinary is a Group
        Set Size to 100 329
        Set Location to 47 15
        Set Label to "Binary file methods"

        Object oCreateTextFile is a Button
            Set Size to 14 58
            Set Location to 18 11
            Set Label to "Create text file"
        
            // fires when the button is clicked
            Procedure OnClick
                Send CreateTextFile
            End_Procedure
        
        End_Object
        
        Object oButton1 is a Button
            Set Size to 14 58
            Set Location to 18 80
            Set Label to "Read text file"
        
            // fires when the button is clicked
            Procedure OnClick
                Send ReadTextFile
            End_Procedure
        
        End_Object
        
        Object oGetFileSize is a Button
            Set Size to 14 58
            Set Location to 38 11
            Set Label to "Get file size"
        
            // fires when the button is clicked
            Procedure OnClick
                Send GetFileSize
            End_Procedure
        
        End_Object

        Object oWriteBinaryHex is a Button
            Set Size to 14 58
            Set Location to 58 11
            Set Label to "Write hex"
        
            // fires when the button is clicked
            Procedure OnClick
                Send WriteHex
            End_Procedure
        
        End_Object

        Object oCopy is a Button
            Set Size to 14 58
            Set Location to 38 80
            Set Label to "Copy"
        
            // fires when the button is clicked
            Procedure OnClick
                Send BinaryCopy
            End_Procedure
        
        End_Object

        Object oReadData is a Button
            Set Size to 14 58
            Set Location to 18 145
            Set Label to "Read data file"
        
            // fires when the button is clicked
            Procedure OnClick
                Send ReadDataFile
            End_Procedure
        
        End_Object

        Object oWriteBinaryLN is a Button
            Set Size to 14 58
            Set Location to 58 80
            Set Label to "Write LN"
        
            // fires when the button is clicked
            Procedure OnClick
                Send WriteFileLN
            End_Procedure
        
        End_Object

        Object oReadDataUntilMatch is a Button
            Set Size to 14 104
            Set Location to 18 211
            Set Label to "Read data file until match"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoReadDataFileUntilMach
            End_Procedure
        
        End_Object

        Object oReadTextUntilMatch is a Button
            Set Size to 14 104
            Set Location to 34 211
            Set Label to "Read text file until match"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoReadTextFileUntilMatch
            End_Procedure
        
        End_Object

        Object oReadBinaryLN is a Button
            Set Size to 14 58
            Set Location to 58 145
            Set Label to "Read LN"
        
            // fires when the button is clicked
            Procedure OnClick
                Send ReadFileLN
            End_Procedure
        
        End_Object
    End_Object

    Object ogrpFile is a Group
        Set Size to 117 327
        Set Location to 148 15
        Set Label to "File methods"

        Object oButton2 is a Button
            Set Location to 18 14
            Set Label to "File exist"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileExist
            End_Procedure
        
        End_Object

        Object oSearchfilebn is a Button
            Set Location to 18 70
            Set Label to "Search file"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoSearchFile
            End_Procedure
        
        End_Object

        Object oSearchfilerecursivebn is a Button
            Set Size to 14 77
            Set Location to 18 123
            Set Label to "Search file recursive"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoSearchFileRecursive
            End_Procedure
        
        End_Object

        Object oDeleteFilebn is a Button
            Set Location to 38 14
            Set Label to "File delete"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileDelete
            End_Procedure
        
        End_Object

        Object oMovefilebn is a Button
            Set Location to 38 70
            Set Label to "File move"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileMove
            End_Procedure
        
        End_Object

        Object oCopyfilebn is a Button
            Set Location to 38 123
            Set Label to "File copy"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileCopy
            End_Procedure
        
        End_Object

        Object oFilesizebn is a Button
            Set Location to 55 14
            Set Label to "File size"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileSize
            End_Procedure
        
        End_Object

        Object oFiledatebn is a Button
            Set Location to 55 70
            Set Label to "File date"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileDate
            End_Procedure
        
        End_Object

        Object oFileversionbn is a Button
            Set Location to 55 123
            Set Label to "File version"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileVersion
            End_Procedure
        
        End_Object

        Object oFileReadOnlybn is a Button
            Set Location to 72 14
            Set Label to "File read only"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileReadOnly
            End_Procedure
        
        End_Object

        Object oFileExtbn is a Button
            Set Location to 72 71
            Set Label to "File extention"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileExtention
            End_Procedure
        
        End_Object

        Object oFileExtbn is a Button
            Set Location to 72 71
            Set Label to "File extention"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileExtention
            End_Procedure
        
        End_Object

        Object oFileIconbn is a Button
            Set Location to 72 124
            Set Label to "File icon"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileIcon
            End_Procedure
        
        End_Object

        Object oFilenamepathbn is a Button
            Set Size to 14 73
            Set Location to 91 14
            Set Label to "File name and path"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileNameAndPath
            End_Procedure
        
        End_Object

        Object oFullPathbn is a Button
            Set Size to 14 73
            Set Location to 91 91
            Set Label to "File full path name"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileFullPathName
            End_Procedure
        
        End_Object

        Object oListOfFilesbn is a Button
            Set Size to 14 77
            Set Location to 18 204
            Set Label to "List of files"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoListOfFiles
            End_Procedure
        
        End_Object

        Object oTempPathbn is a Button
            Set Location to 38 199
            Set Label to "Temp path"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileTempPath
            End_Procedure
        
        End_Object

        Object oTempFileNamebn is a Button
            Set Size to 14 59
            Set Location to 38 253
            Set Label to "Temp file name"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileTempFileName
            End_Procedure
        
        End_Object

        Object oPreservedFilenamebn is a Button
            Set Size to 14 86
            Set Location to 91 167
            Set Label to "File  preserved file name"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFilePreservedFileName
            End_Procedure
        
        End_Object
    End_Object

    Object oDirgroup is a Group
        Set Size to 100 166
        Set Location to 47 351
        Set Label to "Directory methods"

        Object oDirCreatebn is a Button
            Set Size to 14 68
            Set Location to 17 12
            Set Label to "Directory create"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoDirCreate
            End_Procedure
        
        End_Object

        Object oDirRemovebn is a Button
            Set Size to 14 68
            Set Location to 17 87
            Set Label to "Directory remove"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoDirRemove
            End_Procedure
        
        End_Object

        Object oDirRemoveRecursivebn is a Button
            Set Size to 14 115
            Set Location to 36 12
            Set Label to "Directory remove recursive"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoDirRemoveRecursive
            End_Procedure
        
        End_Object

        Object oDirIsEmptybn is a Button
            Set Size to 14 68
            Set Location to 54 12
            Set Label to "Directory is empty"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoDirIsEmpty
            End_Procedure
        
        End_Object

        Object oDirCreateExbn is a Button
            Set Size to 14 128
            Set Location to 72 12
            Set Label to "Directory create missing directories"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoDirCreateEx
            End_Procedure
        
        End_Object
    End_Object

    Object ogrpHeper is a Group
        Set Size to 117 174
        Set Location to 148 351
        Set Label to "Helper methods"

        Object oAddFolderbn is a Button
            Set Size to 14 75
            Set Location to 12 9
            Set Label to "Add folder seperator"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoAddFolderSeperator
            End_Procedure
        
        End_Object

        Object oRemoveFolderbn is a Button
            Set Size to 14 84
            Set Location to 12 87
            Set Label to "Remove folder seperator"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoRemoveFolderSeperator
            End_Procedure
        
        End_Object

        Object oValidFileName is a Button
            Set Size to 14 75
            Set Location to 31 9
            Set Label to "Valid file name"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoValidFileName
            End_Procedure
        
        End_Object

        Object oDumpFile is a Button
            Set Size to 14 58
            Set Location to 50 8
            Set Label to "Dump file"
        
            // fires when the button is clicked
            Procedure OnClick
                Send CreateTextFile
            End_Procedure
        
        End_Object

        Object oCheckFileInUsebn is a Button
            Set Size to 14 75
            Set Location to 69 8
            Set Label to "Check file in use"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoCheckFileInUse
            End_Procedure
        
        End_Object

        Object oFileSizeInKB is a Button
            Set Size to 14 75
            Set Location to 87 8
            Set Label to "File size in KB"
        
            // fires when the button is clicked
            Procedure OnClick
                Send DoFileSizeInKB
            End_Procedure
        
        End_Object
    End_Object

    // Binary file
    Procedure CreateTextFile
        String sFile
        Get Value of oTestFile to sFile
        Send DoDumpString of oFilesystem "Text with æøåÆØÅ." sFile
    End_Procedure
    
    Procedure ReadTextFile
        String sFile sText
        Integer iFilenumber
        Boolean bOk
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Get BinaryFileReadText of oFilesystem iFilenumber to sText
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
            If (SizeOfString(sText) < 1000) Begin
                Send Info_Box sText
            End
        End
    End_Procedure
    
    Procedure ReadDataFile
        String sFile
        Integer iFilenumber iFileSize iBytesRead
        Boolean bOk
        UChar[] ucaData
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Get BinaryFileSize of oFilesystem iFilenumber to iFileSize
            Get BinaryFileReadUChar of oFilesystem iFilenumber iFileSize (&ucaData) to iBytesRead
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
            Send Info_Box (SFormat("Bytes read: %1", iBytesRead))
        End
    End_Procedure

    Procedure DoReadDataFileUntilMach
        String sFile
        Integer iFilenumber iBytesRead
        Boolean bOk bEndOfFile
        UChar[] ucaData ucaSearch
        Get Value of oTestFile to sFile
        Move (StringToUCharArray("æøå")) to ucaSearch
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Repeat
                Get BinaryFileReadUCharUntilMatch of oFilesystem iFilenumber ucaSearch (&ucaData) (&bEndOfFile) to iBytesRead
                Send Info_Box (SFormat("Bytes read including match: %1", iBytesRead))
            Until (bEndOfFile)
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    Procedure DoReadTextFileUntilMatch
        String sFile sSearch sTextRead
        Integer iFilenumber
        Boolean bOk bEndOfFile
        Get Value of oTestFile to sFile
        Move "æøå" to sSearch
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Repeat
                Get BinaryFileReadTextUntilMatch of oFilesystem iFilenumber sSearch (&bEndOfFile) to sTextRead
                Send Info_Box (SFormat("Text including match: %1", sTextRead))
            Until (bEndOfFile)
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure
    
    Procedure ReadFileLN
        String sFile sTextRead
        Integer iFilenumber
        Boolean bOk bEndOfFile bEndOfLine
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Repeat
                Get BinaryFileReadLN of oFilesystem iFilenumber (&sTextRead) (&bEndOfFile) to bEndOfLine
                Send Info_Box (SFormat("Text including match: %1", sTextRead))
            Until (bEndOfFile)
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    Procedure GetFileSize
        String sFile
        Integer iFilenumber
        Boolean bOk
        BigInt biFileSize
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Get BinaryFileSize of oFilesystem iFilenumber to biFileSize
            Send Info_Box biFileSize
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    Procedure WriteHex
        String sFile sHex sData
        Integer iFilenumber
        Short siValue
        Boolean bOk
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile False True to bOk
        If (bOk) Begin
            For siValue from 0 to 255
                Get ShortToHex of oFilesystem siValue to sHex
                Move (sData + Right(sHex, 2)) to sData
            Loop
            Get BinaryFileWriteHex of oFilesystem iFilenumber (&sData) to bOk
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    Procedure WriteFileLN
        String sFile sText
        Integer iFilenumber
        Short siValue
        Boolean bOk
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile False True to bOk
        If (bOk) Begin
            Move "This is a text with æøåÆØÅ that is ended with cr_lf." to sText
            Get BinaryFileWriteLN of oFilesystem iFilenumber sText to bOk
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    Procedure BinaryCopy
        String sFile
        Integer iFilenumber iBytesRead iFilenumber2
        Boolean bOk
        UChar[] uaData
        Get Value of oTestFile to sFile
        Get BinaryFileNextFilenumber of oFilesystem to iFilenumber
        Get BinaryFileOpen of oFilesystem iFilenumber sFile to bOk
        If (bOk) Begin
            Get BinaryFileNextFilenumber of oFilesystem to iFilenumber2
            Get BinaryFileOpen of oFilesystem iFilenumber2 (sFile+".copy") False True to bOk
            If (bOk) Begin
                Repeat
                    Get BinaryFileReadUChar of oFilesystem iFilenumber FS_BUFFERSIZE (&uaData) to iBytesRead
                    Get BinaryFileWriteUChar of oFilesystem iFilenumber2 (&uaData) to bOk
                Until (iBytesRead = 0)
                Get BinaryFileClose of oFilesystem iFilenumber2 to bOk
            End
            Get BinaryFileClose of oFilesystem iFilenumber to bOk
        End
    End_Procedure

    // File methods
    Procedure DoFileExist
        String sValue
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileExists of oFilesystem sValue to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "found", "not found")))
    End_Procedure
    
    Procedure DoSearchFile
        String sValue
        Boolean bOk
        tsSearchResult[] lsaResult
        Get Value of oTestFile to sValue
        Get FileSearch of oFilesystem sValue to lsaResult
        Send Info_Box (SFormat("Found: %1", SizeOfArray(lsaResult)))
    End_Procedure

    Procedure DoSearchFileRecursive
        String sValue
        Boolean bOk
        tsSearchResult[] lsaResult
        Get Value of oTestFile to sValue
        Get FileSearchRecursive of oFilesystem sValue to lsaResult
        Send Info_Box (SFormat("Found: %1", SizeOfArray(lsaResult)))
    End_Procedure

    Procedure DoFileDelete
        String sValue
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileDelete of oFilesystem sValue 3 to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "deleted", "not deleted")))
    End_Procedure
    
    Procedure DoFileMove
        String sValue
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileMove of oFilesystem sValue (sValue + ".copy") 3 to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "moved", "not moved")))
    End_Procedure

    Procedure DoFileCopy
        String sValue
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileCopy of oFilesystem sValue (sValue + ".copy") True 3 to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "copied", "not copied")))
    End_Procedure

    Procedure DoFileSize
        String sValue
        BigInt biFileSize
        Get Value of oTestFile to sValue
        Get FileSize of oFilesystem sValue to biFileSize
        Send Info_Box (SFormat("Result: %1", biFileSize))
    End_Procedure    

    Procedure DoFileDate
        String sValue
        Date dDate
        Get Value of oTestFile to sValue
        Get FileDate of oFilesystem sValue to dDate
        Send Info_Box (SFormat("Result: %1", dDate))
    End_Procedure    

    Procedure DoFileVersion
        String sValue
        tsFileVersionInfo lsFileversion
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileVersion of oFilesystem sValue (&lsFileversion) to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "ok", "not ok")))
    End_Procedure    
    
    Procedure DoFileReadOnly
        String sValue
        Boolean bReadOnly
        Get Value of oTestFile to sValue
        Get FileReadOnly of oFilesystem sValue to bReadOnly
        Send Info_Box (SFormat("Result: %1", If(bReadOnly, "read only", "write enabled")))
        Set FileReadOnly of oFilesystem sValue to (not(bReadOnly))
        Get FileReadOnly of oFilesystem sValue to bReadOnly
        Send Info_Box (SFormat("Changed to: %1", If(bReadOnly, "read only", "write enabled")))
    End_Procedure

    Procedure DoFileExtention
        String sValue sExtention
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileExtention of oFilesystem sValue to sExtention
        Send Info_Box (SFormat("Extention: %1", sExtention))
    End_Procedure    
    
    Procedure DoFileIcon
        String sValue 
        Boolean bOk
        Handle hIcon
        Get Value of oTestFile to sValue
        Get FileIcon of oFilesystem sValue to hIcon
        Send Info_Box (SFormat("Icon handle: %1", hIcon))
        If (hIcon) Begin
            Send DestroyFileIcon of oFilesystem hIcon
        End
    End_Procedure    

    Procedure DoFileNameAndPath
        String sValue sName sPath
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FileName of oFilesystem sValue to sName
        Get FilePath of oFilesystem sValue to sPath
        Send Info_Box (SFormat("File name: %1\nFile path: %2", sName, sPath))
    End_Procedure    

    Procedure DoFileFullPathName
        String sValue sFullPath
        Boolean bOk
        Get Value of oTestFile to sValue
        Get FullPathName of oFilesystem sValue to sFullPath
        Send Info_Box (SFormat("Full path name: %1", sFullPath))
    End_Procedure    

    Procedure DoListOfFiles
        String sValue sPath
        Boolean bOk
        String[] saList
        Get Value of oTestFile to sValue
        Get Value of oTestPath to sPath
        Get ListOfFiles of oFilesystem sPath sValue to saList
        Send Info_Box (SFormat("Found: %1", SizeOfArray(saList)))
    End_Procedure
    
    Procedure DoFileTempPath
        String sTempPath
        Get FileTempPath of oFilesystem to sTempPath
        Send Info_Box sTempPath
    End_Procedure

    Procedure DoFileTempFileName
        String sTempPath sTempFileName
        Get FileTempPath of oFilesystem to sTempPath
        Get FileTempFileName of oFilesystem sTempPath "fs" to sTempFileName
        Send Info_Box (SFormat("Temp path: %1 \nTemp file name: %2", sTempPath, sTempFileName))
    End_Procedure

    Procedure DoFilePreservedFileName
        String sValue sPreserved
        Get Value of oTestFile to sValue
        Get FilePreservedFilename of oFilesystem sValue to sPreserved
        Send Info_Box (SFormat("Value: %1 \nPreserved: %2", sValue, sPreserved))
    End_Procedure
    
    // Directory methods
    Procedure DoDirCreate
        String sValue
        Boolean bOk
        Get Value of oTestDir to sValue
        Get DirectoryCreate of oFilesystem sValue to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "created", "not created")))
    End_Procedure

    Procedure DoDirCreateEx
        String sValue
        Boolean bOk
        Get Value of oTestDir to sValue
        Get DirectoryCreateEx of oFilesystem sValue to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "created or existed already", "not created")))
    End_Procedure

    Procedure DoDirRemove
        String sValue
        Boolean bOk
        Get Value of oTestDir to sValue
        Get DirectoryRemove of oFilesystem sValue to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "removed", "not removed")))
    End_Procedure

    Procedure DoDirRemoveRecursive
        String sValue
        Boolean bOk
        Get Value of oTestDir to sValue
        Get DirectoryRemoveRecursive of oFilesystem sValue to bOk
        Send Info_Box (SFormat("Result: %1", If(bOk, "removed", "not removed")))
    End_Procedure

    Procedure DoDirIsEmpty
        String sValue
        Boolean bEmpty
        Get Value of oTestDir to sValue
        Get DirectoryIsEmpty of oFilesystem sValue to bEmpty
        Send Info_Box (SFormat("Result: %1", If(bEmpty, "empty", "not empty")))
    End_Procedure

    // Helper methods
    Procedure DoAddFolderSeperator
        String sValue
        Get Value of oTestDir to sValue
        Get AddFolderSeperator of oFilesystem sValue to sValue
        Set Value of oTestDir to sValue
    End_Procedure
    
    Procedure DoRemoveFolderSeperator
        String sValue
        Get Value of oTestDir to sValue
        Get RemoveFolderSeperator of oFilesystem sValue to sValue
        Set Value of oTestDir to sValue
    End_Procedure

    Procedure DoValidFileName
        String sBefore sAfter
        Move "Some file name with *invalid* characters æøåÆØÅ.abc" to sBefore
        Get ValidFileName of oFilesystem sBefore "_" to sAfter
        Send Info_Box (SFormat("Before: %1 \nAfter: %2", sBefore, sAfter))
    End_Procedure

    Procedure DoCheckFileInUse
        String sValue
        Boolean bFileInUse
        Get Value of oTestFile to sValue
        Get CheckForFileInUse of oFilesystem sValue to bFileInUse
        Send Info_Box (SFormat("Result: %1", If(bFileInUse, "file in use", "file is not in use")))
    End_Procedure

    Procedure DoFileSizeInKB
        String sValue sKB
        BigInt biFileSize
        Get Value of oTestFile to sValue
        Get FileSize of oFilesystem sValue to biFileSize
        Get FileSizeInKB of oFilesystem biFileSize to sKB
        Send Info_Box (SFormat("The file size for %1 is %2 and rounded to %3.", sValue, biFileSize, sKB))
    End_Procedure
    
End_Object
