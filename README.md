# DFRefactor - An Automated Refactoring Tool for DataFlex

It is highly recommended to download/install the GitHub Desktop app as it will make your work so much easier. It can be downloaed via this link: https://desktop.github.com/download/​
Then click the "<> Code" button and select "Open with GitHub Desktop". It will install the full repository at your selected download location.
**Note: Do not select the "Download ZIP"**, as GitHub will not include libraries that are used by the workspace and you need to manually download them, quirky!

DFRefactor is a powerful, free tool written in DataFlex that assists in refactoring legacy DataFlex code. It specifically targets code that uses syntax that is no longer supported or encouraged. Refactoring involves improving the structure and readability of existing code without altering its external behavior.

- The only supported versions of DataFlex Studio are the latest two: currently, DataFlex 2024 and 2025. While this means that you need one of these two versions installed to compile and run the refactoring programs, it doesn't prevent you from using the tool on projects or workspaces created with earlier DataFlex versions. An older version of the tool, compatible with versions prior to 2023, is available as a separate branch. However, please note that this branch is not maintained, so you would need to use it at your own risk.

To refactor source code with DFRefactor, simply select the desired functions and click "Start Refactoring" for the chosen workspace.

All refactoring functions must be added to the main function repository, contained within the `oRefactorFuncLib.pkg` object. Additionally, functions must be registered using the meta-tag: `{ Published = True }` above the function declaration. Other meta-tags are also required—please follow the instructions at the top of the function library object.

There are various types of refactoring functions; generally, the source code is processed line by line. Every refactoring function must have the interface of a "String ByRef sLine" and an additional optional parameter "String sParameter." It should also return a Boolean value of True if the supplied source line was changed.

The workspace consists of three important programs:
- **TestBench.src**: A test bench used for developing and testing your custom refactoring functions.
- **DFUnit_Testrunner.src**: A series of unit tests. You will need to add several unit tests for each new refactoring function included in the function repository.
- **DFRefactor.src**: The main refactoring program that can be utilized once all functions have been tested and confirmed to work as intended.

You will need DataFlex Studio version 24.0 or later to use DFRefactor effectively.

![This is a sample of the DFRefactor.src program:](Bitmaps/DFRefactor.png)

![This is a sample of the DFRefactorTestBench.src program:](Bitmaps/DFRefactorTestBench.png)
