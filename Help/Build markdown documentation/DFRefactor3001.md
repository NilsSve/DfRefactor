# Version 3.0.0.1

* Added tooltip support for the cRDCHeaderGroup class.
* Changed the tooltip style of the whole application to use balloon style. This includes the addition of a new message: DoChangeTooltipFormat for the ghoCJCommandbarSystem object.
* Changed the ActionBackup.ico icon as the old was indicating a cloud backup.
* Finished the work with the BackupFiles dialog. Can be used to move back source files from the backup folder structure to their original place. The dialog will overwrite the source file with the backed up file copy and no checking is done on file dates or if they already exists.
* Made the directory separator to a constant string CS\_DirSeparator and changed all DFRefactor workspace code to use it.
* Added new class cRDCCJSelectionGrid that as the name suggests a class to be used for displaying data and to make selections from. Used by the "Select Folders" on the RefactorView, the DeleteWorkspaceHistory.dg and the BackupFiles.dg.
* Added new "Current Workspace Backup Files" dialog. It contains all the backup files made by the tool for the current workspace. The idea is that the files selected gets copied back to their original position and then deleted, when the "Move Files" button is pressed.
* Changed the "inner working loop" for the tool. Due to historical reasons it had become to difficult to follow. The change was to first collect all involved folders, then to collect all files for all of those folders into one struct array. Then the work is performed on that struct array, file-by-file.
* Added "Set peVisualTheme to xtpReportThemeVisualStudio2012Light" to grids. This makes selected items checkboxes appear in bold "text".
* Changed the cRDCCheckbox class so it is possible to click the "info" bitmap to the right of the checkbox, as it is was part of the checkbox object itself.
* Added property to the cRDCCheckbox class, pbCreateInfoItem. The default = True and means that an info text object is added to the right of the checkbox with an "ActionInfo.bmp" image. When the mouse is hovered over it the tooltip text will be shown, but no tooltip is shown over the checkbox. Much like how many web-controls works. Set pbCreateInfoItem to False to use the standard checkbox tooltip behavior.
* Added properties to the cRDCHeaderGroup class to easily change the header text size. Set pbUseLargeFontHeight to True to use 12 points for the text. The default = False and means the text used will be 10 points.
* Changed the toolbars so that both the workspace and source file is shown without the path. Instead the paths are shown as tooltips. This made it possible to join the first two rows of toolbars into one.
* Moved the tab-pages to show at the left hand side instead of at the top to allow for more vertical screen space.
* Added a setting to the Program Settings panel to change the icon size used in the toolbars.
* Added sorting to the Theme toolbar combo.
* Added a third column for the refactoring functions to use more of the vertical screen estate.
* Fixed a bug in cRemoveUnusedLocals.pkg reported by Martin Arvidsson when there was an end comment on a variable declaration line.
* Fixed a bug when a file was dropped on the RefactorView.vw.
* Updated the DFRefactor.chm with images for the programs new look \& feel.
* Fixed a bug with the cRemoveUnusedLocals class where it would fail when there was a comment on a variable declaration line and no variables was used in the code. Then the line wasn't removed from code resulting in a compile error.
* Fixed a bug with drag \& drop on the RefactorView.vw.
