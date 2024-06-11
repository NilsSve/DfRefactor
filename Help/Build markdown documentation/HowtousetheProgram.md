# How to use the program

*The opening screen is used with the **Get Started** to select a \*.sws workspace file to open. Or by using the **Open Recent** list to select**s**from previously selected workspaces:*

&nbsp;

![Image](<lib/NewItem14.png>)

&nbsp;

# &#49;. Select Workspace

The opening screen can be used to **Get Started** and select a \*.sws workspace file to be opened. Or by using the **Open Recent** list to select from previously opened workspaces. Note that you can right-click the **Open Recent** objects to show a context menu and e.g. remove items no longer of interest. The list is a FIFO list (First-In-First-Out) of 10 items, meaning that each new opened workspace is pushed on top of the list, until the list has reached the max size, at which point the very first added item will be dropped.

&nbsp;

![Image](<lib/NewItem.png>)

&nbsp;

The same can be achieved from within the DFRefactor program. Click the **Open Workspace File** button to select a ***.sws** file* (*you can select any .sws file from a workspace, as the version doesn't matter*). Alternatively you can click the down arrow of the combo form button, to select from a list of previously opened workspaces. You can also drag \& drop a ***\*.sws*** file to the DFRefactor from Windows Explorer.

&nbsp;

The full path to the selected .sws workspace file will be displayed when you hover the mouse over the control and in the status bar, or when the drop down button has been clicked. This is to save space in the toolbar.

&nbsp;

**Selected Folders.** If it is the first time you open the workspace all subfolders from the Home folder will be collected and shown in the tab-page Selected Folders. Select the folders of interest and/or remove/add folders. All selections and folder changes made are automatically saved to the database. The grid has a right-click context menu to help with this work.

&nbsp;

***Note: Even if only a single file is to be worked on, the backup logic needs to have a selected workspace to have somewhere to create backup folders and files to.***

&nbsp;

# &#50;. Workspace or File Mode

The refactoring process can take place on either a series of source files, or a single file only. You can select the mode by selecting either of the **Workspace** or **Single File** radio buttons in the toolbar.

&nbsp;

![Image](<lib/NewItem1.png>)

&nbsp;

If only a single file should be worked on, click the **Open Source File** button that is placed on top of the **Workspace/File** radio buttons. The Workspace/File mode will then automatically change to **File** mode.

# &#51;. Select Refactoring Functions

Select the check boxes for the Refactoring Functions List of choice. There are 5 sorts of Refactoring Functions:

&nbsp;

**Standard**: &nbsp; &nbsp; Changes the source code according to the description of selected function.

**Remove**: &nbsp; &nbsp; Changes the source code focusing removing unused features that are no longer needed.

**Editor**: &nbsp; &nbsp; Changes the source code focusing on organizing the code and making it more readable.

**Report**: &nbsp; &nbsp; Does not make changes to the source code. It only reports anomalies in the source code and writes out a list of affected source files.

**Other:** &nbsp; &nbsp; Expects a full file as a string array, or a string array with file names.

&nbsp;

![Image](<lib/Function Selection.png>)

&nbsp;

**See [Refactoring Functions**](<RefactoringFunctions>) **for details about each function.**

&nbsp;

Use the **selections buttons** for multi-select functions, or space bar to select a single function. Note that there is also a right-mouse click context menu to use for various actions in the grid.

&nbsp;

The Function Name column is a suggestion list. Thus it is possible to start typing any part of a function name to see a list of matches, to be selected from/jumped to.

&nbsp;

**Constrain Functions**

Constrain the function type to be displayed in the grid - for easier overview. Select type from the drop-down combo form.

&nbsp;

**Type column**

The function type rules how data is feed to the function. For 'Standard' and 'Remove' functions one source line at a time are send. To others either a full source file as a string array is passed, or the last option is to pass all selected files as a string array with full path.

For more info on the Type column, see [**Refactoring Functions**](<RefactoringFunctions>)&nbsp;

&nbsp;

**Parameter column**

For some functions an extra parameter can be passed. You can only select from existing values. Hover the mouse over a value to see valid values to be selected from. Double-click on any cell with a **Parameter** value and make a selection from the drop-down combo form.

&nbsp;

**Select Column**

Checkbox column for selecting which functions should be used for the next refactoring session.

&nbsp;

# &#52;. Source Code Folders

If the **Workspace** mode has been selected you need to specify which folders should be included in the refactoring process. You can select folders from the list with the space bar. You can also right click the grid and then from the popup menu select the option to toggle the select state and add or delete a grid folder. It is also possible to drag \& drop a folder to the program from Windows Explorer.

&nbsp;

*Note: The grid will be unavailable if the **File** mode has been selected because then only one source file will take part in the refactoring process.*

&nbsp;

![Image](<lib/Folder Selection.png>)

# &#53;. File Extensions Filter

Select a collection of file extensions from the drop down, or enter your own file extensions.

Every source file which has one of the selected extensions in all of the selected folders and all their subfolders will take part in the refactoring process. It is also possible to enter other file wild card combinations. Press Ctrl+S to save any new combination.

&nbsp;

![Image](<lib/File Extensions.png>)

# &#54;. Start Refactoring

**Important\! Prior running any routine you *should ALWAYS have made a backup of source code, and/or have checked in all changes to a version control program. There is no guarantee that everything goes according to plan once the Start Refactoring button has been pressed. It is the users responsibility to have your source code properly checked in and/or backed up.***&nbsp;

&nbsp;

The DFRefactor tool has backup logic built-in. (See also the **Program Properties** dialog), but you should also make sure you have taken the above safety measurements. *The tool creates a 'DFRefactor Backup' folder in the workspace home (root) folder. It then creates a series of sub folders to match the selected folders and sub folders that is to be worked on.*

&nbsp;

![Image](<lib/NewItem2.png>)

&nbsp;

***Important:** If you hit the **Start Refactoring** button twice, the original backed up source file **will not be overwritten** with the one you just changed. The backup logic will not overwrite the backup copy **for a period of fourteen days** from the initial back up. **This value can be changed in Program Properties**. If you run the tool again with the same workspace selected **after those days have passed, new backup copies will be created, overwriting what is in the backup folder(s)**.*

&nbsp;

Click the **Start Refactoring** button in the lower right corner of the Refactoring view to begin the process. Note that some of the refactoring processes can take quite some time, but just sit back, relax, pour yourself a cup of coffee and wait until the work has finished.

&nbsp;

**Count Source Lines (only)** if checked, none of the selected functions from the function list will be used. Instead, all that is done, is to count number of source line for all files that satisfy the selected **File Filter and Folders.** All blank and commented out lines, together with any Studio generated ActiveX/OCS code will be skipped during this process. All other source lines will be counted.

&nbsp;

**Read Only** if checked, all selected functions will be called and the summary report (log file) will show how many occurrences for reach selected function will take place if it is not checked. This is to give the user an idea on how many changes are going to be made to the source code, without actually making any changes.&nbsp;

&nbsp;

**Compare Code** If a comparison tool has been specified in the **Program Settings** dialog, clicking this button after a refactoring will bring up the comparison tool program to show all differences between the original and refactored source code.

&nbsp;

# &#55;. Compare Code

*After a refactoring has been performed - and if a tool has been setup with the Program Properties panel - a comparison can be made between the original and refactored code.*

