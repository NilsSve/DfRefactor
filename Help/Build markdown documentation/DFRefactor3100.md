# Version 3.1.0.0

* Upgraded the version number to 3.1 as we now have merged the two SVN version control branches to one (DfRefactor)
* Run the tool on itself. More specifically the RefactorView.vw as it needed reindentation.
* Adjusted the width of the cRDCSlideButton.pkg as it was to narrow making it to "clip" the text at the right-hand side of the object.
* Fixed a bug in the DfAbout.pkg. For some reasons a line had been commented out, leaving the compile date logic not to work for DF versions below 19.1
* Major update (and bug fixes) for the cUnusedSourceFiles.pkg. The work also included optimization on how source files are read into memory by the program. This is now much faster and made a huge impact on the performance.
* After the introduction of the horizontal \& vertical (lower part of the RefactorView), the screen had to many frames. Therefor all frames for the cRDCHeaderGroups were removed. This results in a better visual experience and better use of the screen estate. Moved some of the \*.ico files to their respective Library folder.
* Added a vertical splitter for the lower part of the RefactorView.
* A new class was created that replaces the checkboxes for the RefactorView, named cRDCSlideButton. In the Studio it looks like a checkbox but when run the control looks like a "sliding button" found in many Web applications. The class has some issues , but works sufficiently well.
* The coloring for the clBlueGrey \& clBlueGreyLight was wrong. A purple color had sneaked in by mistake. This also lead to that some icons had the wrong color.
* Changed the cRDCComboForm.pkg to use an auto width size for the drop-down list depending on the width of the text.
* Added shortcuts to the cRDCCJSelectionGrid.pkg right-click menu.
* Made the DFAbout library to be "minimal"
* The change to display folders and subfolders in the "Select Folders" grid called for another change. Since we have tried to keep the height of the application as small as possible to allow Wil and others who are using low screen resolutions, to view all refactoring functions without the need to scroll the top part up and down, a horizontal splitter was needed between the top and bottom part of the RefactorView. This makes it possible to use the splitter to display more than a few rows of the "Select Folders" grid if a larger resolution is being used. This has now been implemented.
* Added a cursor wait while the Select Folders grid is filled with data.
* Added a context (right-click) menu to the cRDCCJSelectionGrid class to select, add and remove grid items. The menu always has four items; Toggle Current Item, Select All, Select None and Invert Selection. With the two properties pbShowAddFolderMenuItem and pbShowRemoveFolderMenuItem set to True, two more items can be displayed; Add Folder and Remove Item From Grid.
* Changed the logic for the "Select Folders" on the RefactorView view, to show the full path for all folders *and* subfolders for the selected workspace. This makes it possible to select subfolders to be involved in the refactoring process. This also had a deep impact on how folders and files were collected, so those routines had to be changed as well, and was also made more robust (no more "if x contains y"). It also fixes a bug that only manifested itself when there was a dot (.) in the folder name like e.g. "MyWorkspace2.0\\AppSrc".
* The Add Folder button was removed and replaced by a right-click grid menu. The "Select Folders" group is now also the bottom container that has anchors set to bottom-left-right, as it needs to be resized to show full folder paths.
* Added a dialog for showing the log file (LogFileDialog.dg)
* Added a new toolbar button for the UnusedSourceFiles dialog.
* Added a new dialog "UnusedSourceFiles.dg" that is filled with source files never used, if the "Unused source files" routine was selected. The dialog makes it easy to move one or more of them to the backup area.
* Added a new setting to the ProgramSetup.dg dialog. A new combobox was added to set the selected row color for the cRDCCJSelectionGrid class. This is the same as the cCJGrid piSelectedRowBackColor property. By default set to clBlueGreyLight, but that can be a bit difficult to read, so it is now configurable. The cRDCCJSelectionGrid class was changed accordingly.
* Added logic to the Function ProcessFile to move the backup file back to its original place if unchanged.
