# Refactoring Functions

&nbsp;![Image](<lib/NewItem8.png>) **OTHER - ONE FILE**

&nbsp;

A string array with a full source file is passed to these functions.

* # RemoveMultipleBlankLines

Removes consecutive blank Lines. The Max Blank Lines lines can be selected from the drop down list of the **Parameter** column of the **Function List** for the **RemoveMultipleBlankLines** row/function.

&nbsp;

*NOTE: The Refactor Engine does not distinguish between objects and methods, so the same max blank lines are enforced equally in the refactored source code.*

### Example:

// &nbsp; &nbsp; order by name;

&nbsp; &nbsp; Use Windows.pkg

&nbsp; &nbsp; Use MSSQLDRV.pkg

&nbsp; &nbsp; Use SQL.pkg

&nbsp;&nbsp; &nbsp;

&nbsp;

&nbsp;

&nbsp; &nbsp; Set Border\_Style to Border\_Thick

&nbsp; &nbsp; Set Label to "Chapter 3 Sample (Microsoft SQL)"

&nbsp; &nbsp; Set Location to 2 2

&nbsp; &nbsp; Set Size to 172 299

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp; &nbsp; Object oResults is a cTextEdit

&nbsp;

### Will be changed into into this if the Max Blank Lines has been set to "1":

&nbsp; &nbsp; // &nbsp; &nbsp; order by name;

&nbsp; &nbsp; Use Windows.pkg

&nbsp; &nbsp; Use MSSQLDRV.pkg

&nbsp; &nbsp; Use SQL.pkg

&nbsp;&nbsp; &nbsp;

&nbsp; &nbsp; Set Border\_Style to Border\_Thick

&nbsp; &nbsp; Set Label to "Chapter 3 Sample (Microsoft SQL)"

&nbsp; &nbsp; Set Location to 2 2

&nbsp; &nbsp; Set Size to 172 299

&nbsp;&nbsp; &nbsp;

&nbsp; &nbsp; Object oResults is a cTextEdit

&nbsp;

* # RemoveUnusedLocals

Removes variables declarations from functions and procedures that aren't being used. A limitation is that it does **not** remove unused struct variables.
