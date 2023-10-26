DFRefactor - The Automated Refactoring Tool for DataFlex

_Click the "<> Code" button and either select "Open with GitHub Desktop", which is the preferred method, (The GitHub software can be downloaded from: https://desktop.github.com/)
- or you can select the "Download zip file" and after unpacking also unpack the DataDistrib.zip file to the Data folder and the AppSrcManifestFiles.zip to the AppSrc folder.
- You should now be able to open the workspace in the DataFlex Studio from version 19.0 and up.
- The main advantage of using the GitHub Desktop client is that you get instent notification if something has changed in the main repository, so you can fetch again (refresh your workspace).

DFRefactor is a tool written in DataFlex that helps with refactoring of old DataFlex code. It consists of a series of functions to help in the refactoring process. Each refactoring function that can be used to refactor code must be entered to the main function repository; the RefavtorFunctionLibrary.pkg class.
That same function must also be registered with the FuntionMaintenance view.

There are several types of refactoring functions, but in general source is passed to functions one source line at a time. Each function must have an interace of a "String ByRef sSourceLine" and a second optional "String sParameter". All functions must return a Boolean True if the passed source line was changed, else return a False.

It consists of three important programs;
- TestBenchRefactorFunctions.src - A test bench used when developing & testing your own refactoring functions.
- DFUnit_Testrunner.src - A series of unit tests. You need to add several unit tests for each function that you add to the function repository.
- DFRefactor.src - The main refactoring program that is used as soon as all functions has been proven to work as intended.

You need a DataFlex Studio 19.1 or later to compile the source file DFRefactor.src to an executable.
