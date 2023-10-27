DFRefactor - The Automated Refactoring Tool for DataFlex

_Click the "<> Code" button and either;
- Select "Open with GitHub Desktop". This is the preferred method. (The GitHub software can be downloaded from: https://desktop.github.com/) The main advantage of using the GitHub Desktop client is that you will get instent notifications if something has changed in the main repository, so you can fetch again (refresh your workspace).
- Or you can select the "Download zip file"
- Then unpack the DataDistrib.zip file to the Data folder and the AppSrcManifestFiles.zip to the AppSrc folder.
- You should now be able to open the workspace in the DataFlex Studio from version 19.0 and up.

DFRefactor is a tool written in DataFlex and helps with refactoring of old DataFlex code. To refactor source code, just select the wanted/needed functions and press "Start Refactoring". The code for all refactoring functions must be added to the main function repository; the RefactorFuncLib.pkg class. In addition all functions must be registered with the FuntionMaintenance view, to a database table.

There are several types of refactoring functions, but in general source is passed to functions in a line-by-line fashion. Every refactoring function must have an interace of a "String ByRef sSourceLine" and a second optional "String sParameter". They must als return a Boolean True if the passed source line was changed.

The workspace consists of three important programs;
- TestBench.src - A test bench used when developing & testing your own refactoring functions.
- DFUnit_Testrunner.src - A series of unit tests. You need to add several unit tests for every new refactoring function that is to be added to the function repository.
- DFRefactor.src - The main refactoring program that can be used after all functions has been proven to work as intended.

You need a DataFlex Studio 19.0 or later.
