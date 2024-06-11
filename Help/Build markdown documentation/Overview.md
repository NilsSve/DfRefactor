# Overview

# Programs

**\- DFRefactor** is the main program and the only program expected to be used by most users/developers. After a refactoring session has been run it is possible to compare the before and after result, after a comparison tool has been setup on the Program Properties dialog.

&nbsp;

**\- TestBench** - for advanced users only. It was developed to assist when developing new refactoring functions. Works with a single test file containing various legacy code snippets. The refactored file can be compiled to check that the result is "OK".

&nbsp;

**\- DFUnit\_TestRunner** - for advanced users only. Unit testing for DataFlex. A series of unit tests that has been setup to test the cRefactorFuncLib (and its parent class cBasicFuncLib). Whenever anything is changed within those two classes these tests are meant to make sure that something wasn't broken with that change. It is used in conjunction with the TestBench program. The foundation for this was originally developed by Ola Eldöy and further enhanced enhanced by Bram NijenKamp. It was then tweaked for this project.

&nbsp;

# In Brief - How to use DFRefactor

* # To be able to refactor your code you need to select a workspace by selecting an \*.sws file. This is needed for the program's backup logic.

&nbsp;&nbsp; &nbsp; &nbsp;

* Decide if the refactoring process should take place on a single file or the whole workspace. You do that by clicking one of the **Workspace** or **File** mode radio buttons.

&nbsp;&nbsp; &nbsp; &nbsp;

* If the **Workspace** mode was selected, select which source code folders should participate in the refactoring process. Do that by selecting folders in the **Source Code Folders** group. You can select file name extensions to be worked on, with the **File Extensions Filter** drop down list.

&nbsp;

* Select Refactoring Functions by selecting/unselecting the checkboxes.
* Select Folders. Select the folders containing source code to be processed.
* File Filter. Select file filter for file extensions for files to be processed.

&nbsp;

* Click the **Program Settings** toolbar button to control how the program will operate.

&nbsp;

* Click the **Editor Settings** toolbar button to change how the Scintilla editor of the **Editor** view operates. The most important settings are the font and tab-size to be used during refactoring and how you would like the DataFlex keywords to be upper/lower cased.

&nbsp;

* Click the **Start Refactoring** button.

&nbsp;

**For more details, see: [How to use the Program**](<HowtousetheProgram>)**.**

&nbsp;

*Note: When the **Start Refactoring** button is clicked and if one or more functions of type **Editor - One File** has been selected , the **Editor** tab page gets activated. This is because the Scintilla code editor, used for those functions, is an OCX component and must to be paged and active to be able to do its job.*

