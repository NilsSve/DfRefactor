DFRefactor - The Automated Refactoring Tool for DataFlex

DFRefactor is a tool written in DataFlex that helps with refactoring of old DataFlex code. It consists of a series of functions to help in the refactoring process. Each refactoring function that can be used to refactor code must be entered to the main function repository; the RefavtorFunctionLibrary.pkg class.
That same function must also be registered with the FuntionMaintenance view.

There are several types of refactoring functions, but in general source is passed to functions one source line at a time. Each function must have an interace of a "String ByRef sSourceLine" and a second optional "String sParameter". All functions must return a Boolean True if the passed source line was changed, else return a False.

It consists of three important programs;
- TestBenchRefactorFunctions.src - A test bench used when developing & testing your own refactoring functions.
- DFUnit_Testrunner.src - A series of unit tests. You need to add several unit tests for each function that you add to the function repository.
- DFRefactor.src - The main refactoring program that is used as soon as all functions has been proven to work as intended.

You need a DataFlex Studio 19.1 or later to compile the source file DFRefactor.src to an executable.