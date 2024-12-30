DFRefactor - The Automated Refactoring Tool for DataFlex

_Click the "<> Code" button and either;
- Select "Open with GitHub Desktop". This is the preferred method. (The GitHub software can be downloaded from: https://desktop.github.com/) The main advantage of using the GitHub Desktop client is that you will get instent notifications if something has changed in the main repository, so you can fetch again (refresh your workspace).
- Or you can select the "Download zip file"
- Note that if you are *not* using an English collating sequence file (DF_Collate.cfg), all tables needs to be reindexed before usage. An automatic mechanism is triggered if another collate.cfg is being used. BUT it is important to understand that when the question to start reindexing of tables is displayed, you first need to shut down the Studio (or close the DFRefactor workspace) so that CodeMast/CodeType tables, usually kept open by the Studio, can be reindexed.
- The only DataFlex Studio version supported are the latest two. At current that means DataFlex 2024 and 2025. That doesn't mean that the program can't be used for projects/workspaces on earlier DataFlex versions. All this means is that one of the last two DataFlex Studio's needs to be installed to compile and run these refactoring programs. An older version of the tool that can be used with earlier DataFlex versions than 2023 is available as a separate branch. However, this branch is not maintained so you would be on your own to use it.

DFRefactor is a tool written in DataFlex and helps with refactoring of old DataFlex code. To refactor source code, just select the wanted/needed functions and press "Start Refactoring". The code for all refactoring functions must be added to the main function repository; the RefactorFuncLib.pkg class. In addition all functions must be registered with the FuntionMaintenance view, to a database table.

There are several types of refactoring functions, but in general source is passed to functions in a line-by-line fashion. Every refactoring function must have an interace of a "String ByRef sSourceLine" and a second optional "String sParameter". They must als return a Boolean True if the passed source line was changed.

The workspace consists of three important programs;
- TestBench.src - A test bench used when developing & testing your own refactoring functions.
- DFUnit_Testrunner.src - A series of unit tests. You need to add several unit tests for every new refactoring function that is to be added to the function repository.
- DFRefactor.src - The main refactoring program that can be used after all functions has been proven to work as intended.

You need a DataFlex Studio 24.0 or later.
