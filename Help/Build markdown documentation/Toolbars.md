# Toolbars

![Image](<lib/NewItem.png>)

# Open Workspace/Current Workspace button (Alt+W)

Click on the **Open Workspace** button (folder icon) next to **Select Workspace** and select an \**.sws* workspace file. Alternatively, you can press the down-arrow of the split button to select a previously opened workspace.

&nbsp;

*Note: The interface has been changed and the path is not shown any more to the right of the control. Instead you can hover the mouse over the file name and the full path will be displayed. This was made to save space.*

# Refactor Mode Radio button (Alt+F toggles between the two modes)

The tool can work in one of two modes. If the **File** radio button is selected, all work is done on a single selected source file. If the **Workspace** radio is selected all actions will be done on all workspace source files that matches the **File extensions to parse** drop down list from the Refactoring view (below the grid) and for all selected folders in the grid above it.

&nbsp;

![Image](<lib/NewItem1.png>)

&nbsp;

Note: The path is not shown. Instead you can hover the mouse over the file name and the full path will be displayed as a tooltip and in the status bar.

# Save Changes button (Ctrl+S or F2)

Save changes made (if source file changes has been made in the editor).

# Clear button (Ctrl+F5)

This clears both the selection of the workspace and the file, if one has been opened.

# Undo Editor Changes (Ctrl+Z)

Undo the last editor change.

# Redo Editor Changes (Ctrl+Y)

Redo the last editor change.

&nbsp;

# ![Image](<lib/NewItem3.png>)

# Start Refactoring

**Refactor code with the selected functions for the selected folders and File Filter - or if Mode: Single File - the selected file.**

# Compare Tool button

Click to start the file comparison tool. This is an external program you need to have installed. You set up which program to use with the **Program Settings** button.

# Show Log File (Alt+L)

The statistics text that is shown in the dialog after you have clicked the **Start Refactoring button** is saved to the DFRefactoringLogfile.txt log file. It is saved in the workspace **DFRefactor Backup** sub folder.

# Other Log Files

A few refactoring functions uses their own log files. Each of those will be displayed here - if any.

# Refactor Engine Error Log

The refactoring engine is were refactoring is taking place and is called when the **Start Refactoring button** is pressed. The work is performed in by the engine in a business process. If errors happens, all errors are redirected to the Engine Error Log table, This is to not interrupt the running process.

# Undo refactoring

Undo process of refactoring actions. Dialog that moves files from the 'DFRefactor Backup' subfolder structure to their original folders. (Alt+U)

# Open Containing Folder button

This will open Windows Explorer for the selected workspace. If a file has been opened, it will be highlighted in Windows Explorer.

&nbsp;

![Image](<lib/NewItem4.png>)

# Starzen's DataFlex Source Explorer button

This is - just like the **Compare Tool** button, an external program that needs to be installed separately. You set it up from the **Program Settings** dialog.

&nbsp;

![Image](<lib/NewItem5.png>)

# Program Settings button

Pops up the **Program Settings** dialog where you can set various program settings.

# Editor Settings button

Pops up the **Editor Settings** dialog where you can set all sorts of properties for the **Scintilla** **editor** that is used by the **Editor view.**

&nbsp;

![Image](<lib/NewItem6.png>)

# Theme Selector drop down

Use it to select a visual theme that changes the look \& feel of the program.

# Snap shot

Make a screen dump of the selected view as a .bmp image to the **Capture** sub-folder.

# ![Image](<lib/NewItem7.png>)

# About button

Displays a popup dialog with info about the program, including version and a list of the author and people that were helpful during the development of this project.

# Help button

That would be this button. Note that there is also an [on-line help](<http://www.rdctools.com/HTMLHelpDFRefactor/DFRefactor%20-%20Automated%20Code%20Refactoring%20for%20DataFlex.html> "target=\"\_blank\"") available and it might be more recent than this help file.

# Exit button

Ends the program.

