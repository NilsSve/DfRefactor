# Version 3.2.1.0

* Changed all ModalPanels to cRDCModalPanel.pkg. This class automatically adds a status panel row at the bottom of the dialog and makes Status\_Help messages work as they do on all other panels. It also makes all panels resizable. So all anchors were adjusted for this. It also fixes a bug in DataFlex when setting the Icon property.
* Added the word "File" in front of the status\_panel message: "No: xx of xx" to make it clear that it ain't lines but files that are counted.
* Added automatic status\_help from the psToolTip, if no status\_help has been specified.
* Added a "Standard Functions" header group and re-arranged the RefactorView.vw a bit to make it better balanced.
* New Report.ico for the Report Functions group.
* New comboform workspace selector. Bigger icons for the checkbox slider.
* Updating license with a note about the artwork.
* New psProduct title. Changed from: "Automated Code Refactoring for DataFlex" to "Automated Source Code Refactoring for DataFlex". It just looks better. Note though that this also means the saved workspaces is now under another registry item. If necessary one can start Regedt32 and change the old key name to the new to keep ones history items.
* Changed CS\_ValidLeftCharacters in cRemoveUnusedLocals.pkg to include the EOL character.
* RefactorView.vw. Changed the UI a bit. Amongst the changes were to move the "Tab Size" up to the right, because it is actually used for all indentation - not just for If/Else/Begin constructs.
* Updated the cRDCHeaderGroup.pkg to use a info bmp at the end of the control to indicate if there's a tooltip. New icons and bitmap.
* Changed compound rows to use Begin/End
* Pegged Libraries to fixed revisions in time, so that updates on those libraries don't break our code here.
* Fixed a few issues with the Unused Variables logic:

\- Two dimensional arrays are now checked as well for all basic DataFlex types.

\- CS\_ValidLeftCharacters was missing an "=" character

\- RetrieveFirstWord method had a copy \& paste error, it should have acted on variable sFirstWord, not sLine

\- Testing for where a method ends is now done via the IsMethodEnd function, so that it is more robust.

\- Extended the test file for array declarations that have spaces in them.

* Added reindent test file as suggested by Mike from Starzen.
* Fixed issues with the unused variable refactor option as reported by Peter Bragg.

Also added a number of examples that I have used for testing.

The following issues have been resolved:

\- If the method declaration is declared over multiple lines then removes parameters from that (see UnusedVarsTestMethodDeclareBrokenLine.pkg)

\- If the developer uses a array declaration where he/she inserts a space between variable type and array declaration (see UnusedVars-SpaceArrays.pkg)

\- If the source has variables with overlapping names, such as iSpace and iSpaces (see UnusedVars-PartialVariableNames.pkg)

* Merging Marco's DfUnit tests

Merging Marco's implementation with RegEx on ChangeInToContains

Fixed function ChangeUClassToRefClass as it broke after DfRefactor had been run on itself. Added extra protections for this in the function as it did not anticipate the "run on itself" scenario.

However, the regex logic has been disabled until a separate dialog gets implemented for it.

* Replaced the info\_box after the main process has ended with the log file dialog.
* Fixed an issue where the logic would not remove a variable that partly matched a variable type. E.g. variable "sH" was not removed because the logic matched it up with variable type "Short".
* Fixing unused local var logic.
* New SciLexer.dll, adds code collapse support for Type / End\_Type. The main reason for that is that this is used for the reindent logic and as such it now gets properly indented instead of all left aligned.
* Added "All Files" option to the open file selector and changed the logic to remember the path of the previously opened file. This so that if you did not open a file within the AppSrc folder that it will open again on the last path used.
* Fixed bug #131 "CM images, do not remove blank lines"
* Fixed case sensitive bugs for the functions ReplaceCalcToMoveStatement and IsKeywordInLine as reported by Michael Mullan.
* Removed the Sleep command and instead introduced the WaitForFileToGetWritten message that will wait for the newly written file to be released by Windows. Also added the number of lines of the source file to the status\_panel. This is to inform the user how big the file currently working on is, as it otherwise may look like the program has hung or something.
* Fixed a bug in the DfAbout.pkg. For some reasons a line had been commented out, leaving the compile date logic not to work for DF versions below 19.1.
* Adjusted the width of the cRDCSlideButton.pkg as it was to narrow making it to "clip" the text at the right-hand side of the object.
* Set the "Run Now\!" button's default state to True.
