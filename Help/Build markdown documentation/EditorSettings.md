# Scintilla Editor Settings

# ![Image](<lib/NewItem10.png>)

# Colors/Font

Select a Color Theme to be used by the Scintilla Editor - or set individual colors for the editor. You can also select the font by clicking the three dots "..." for the Font control.

&nbsp;

&nbsp;

![Image](<lib/NewItem11.png>)

# Keywords and Operators

Three lists of Scoped Words (Start/End), Keywords and Operators.

Great caution should be taken before making any changes here. It is considered very advanced to make changes here and one needs to understand the implications if done. All of these values are read by the program at startup and stored in string array properties and used by the **Refactoring Engine** while doing all sorts of operations. So making changes here can have profound impact on the refactoring outcome.

However, one thing that could potentially have a positive effect would be to **add a custom made command to the Keyword list.** That would mean that the custom command would be treated (almost) like any other DataFlex command when refactoring.

&nbsp;

&nbsp;

![Image](<lib/NewItem12.png>)

&nbsp;

# Keyboard Key Assignments

Assigns keyboard shortcuts to commands. This program is using the Scintilla Code Editor that is separate from the DataFlex Studio's CodeMax editor. It is here possible to setup the Scintilla editor to work (in most cases) the same as the Studio's editor by assigning key combinations to commands.

&nbsp;

&nbsp;

![Image](<lib/NewItem13.png>)

&nbsp;

# Other Editor Settings

Miscellaneous editor settings. Hover the mouse over each checkbox and read the tooltip to understand what it does.

**Tab Size**. This setting is important for the **EditorReIndent** refactoring function and specifies the number of spaces for each new indentation level. Note: This setting can also be changed from the **Function List** grid, **Parameter** column. Find the **EditorReIndent** function from the list and double-click the **Parameter** column, and select the number of spaces to use when indenting code.
