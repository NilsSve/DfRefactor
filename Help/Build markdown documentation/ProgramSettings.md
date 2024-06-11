# Program Settings

![Image](<lib/NewItem9.png>)

&nbsp;

*Note: Hover the mouse over any information symbol with a round ring around it, to read additional information about a control.*

# Backup Files Setting

Backup files will be created in: \<workspace name\>\\DFRefactor Backup\\...

Number of days before overwriting Backup files. Backup files will be created in backup folders \<workspace name\>\\DFRefactor Backup\\..

This is the setting for **number of days for the overwrite cycle**.

After x number of days the files in the backup folder gets overwritten by new refactored files. Good for when applying one or a few functions at a time, as you then don't want the original to get overwritten by the next selection of refactoring function(s).

&nbsp;

***Important Note: It is the users sole responsibility to check in source code with a version control program and/or make backup of all files that are going to be processes, prior starting any refactoring work. Even if the program has logic for making backup files, things can still go wrong and the writer of this software makes absolutely no guarantees that the build-in backup strategy always works as needed. Therefor the user should make a habit of checking in/backing up source code before even starting this program.***

# StarZen's DataFlex Source Explorer

This tool needs to be downloaded and installed separately and there's a link in the group that opens a download page for the tool. The tool will help you further examine and analyze your code.

# Compare Tool

This tool needs to be downloaded and installed separately and there are three separate suggestions for comparison tools to select from. The links opens a download page for each tool. The tool will help you compare code before \& after a refactoring to see exactly what has been done.

# Visual Settings

Various visual program settings. If you have the source code to this program there is an additional setting that can be made - Selecting a theme for the program. By uncommenting the following line near the top of the DFRefactor.src file;

**//Define CI\_ShowBlingStuff**

A theme combo box will then appear in the toolbar, for you to select various themes from. Please note that the grid size does not apply to selection lists. The rest of the controls should be self explanatory.

# Refactor Engine Settings

Handles how the refactoring engine starts and ends. The Refactor Engine is where the inner workings of the refactoring process takes place, after the Start Refactoring button has been pressed. Before each run an info\_box is displayed that shows the number of functions and folders selected, and warns the user to check in source code to a version control software, prior starting the refactoring process. This step can be optionally skipped if the Show start question is unchecked. After the refactoring process has ended the log file with a summary on what work has been done on the source code, is displayed automatically in a dialog. This step can be optionally skipped. To view the log file at any time, click the View Logfile in the toolbar. *It is strongly suggested to leave both these check boxes ticked.*

&nbsp;

# DataFlex Studio Integration

DataFlex Studio Integration. Adds this tool to the Studio's 'Tools' menu for easy access. Note that if you normally work with another DataFlex version then what this program is compiled with, you can still add this tool to e.g. the DataFlex Studio 20.0.
