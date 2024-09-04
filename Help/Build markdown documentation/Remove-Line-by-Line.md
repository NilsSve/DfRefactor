# Refactoring Functions

**&nbsp;**![Image](<lib/Remove.png>) **REMOVE - LINE BY LINE**

* # RemoveOldStudioMarkers

Removes old //AB IDE markers.

### Example:

//AB/ Object&nbsp; &nbsp; // prj

//AB/ End\_Object&nbsp; &nbsp; // prj

&nbsp;

//AB-StoreStart

Procedure Prompt\_Callback integer hSL

&nbsp; &nbsp; &nbsp; &nbsp; Set Initial\_Column of hSL to 0

End\_Procedure

//AB-StoreEnd

### Will be changed into:

Object&nbsp; &nbsp; // prj

End\_Object&nbsp; &nbsp; // prj

&nbsp;

Procedure Prompt\_Callback integer hSL

&nbsp; &nbsp; &nbsp; &nbsp; Set Initial\_Column of hSL to 0

End\_Procedure

* # RemoveProjectObjectStructure

Removes the Project Object Structure comments at the top of source files. It also removes Register\_Object for those same objects.&nbsp;

It is smart enough to only remove Register\_Object lines for objects that are part of the Project Object Structure.

### Example:

// Project Object Structure

// &nbsp; BATCH is a dbView

// &nbsp; &nbsp; Ac\_DD is a DataDictionary

// &nbsp; &nbsp; Art\_DD is a DataDictionary

// &nbsp; &nbsp; Artdisc\_DD is a DataDictionary

// &nbsp; &nbsp; Artgrp\_DD is a DataDictionary

// &nbsp; &nbsp; Cashhdr\_DD is a DataDictionary

// &nbsp; &nbsp; Cashline\_DD is a DataDictionary

// &nbsp; &nbsp; Cashlst\_DD is a DataDictionary

// &nbsp; &nbsp; Container1 is a dbContainer3d

&nbsp;

Register\_Object BATCH

Register\_Object Ac\_DD

Register\_Object Art\_DD

Register\_Object Artdisc\_DD

Register\_Object Artgrp\_DD

Register\_Object Cashhdr\_DD

Register\_Object Cashline\_DD

Register\_Object Cashlst\_DD

Register\_Object Container1

### Will be changed into:

(Blank)

All those lines will simply be removed as they are no longer needed.

* # RemoveSansSerif

Removes hard coded: MS Sans Serif fonts if present.&nbsp;

With more recent versions of DataFlex fonts are handled much better than before and these font settings usually makes the application look strange.

* # RemoveStudioGeneratedComments

&nbsp; &nbsp; Removes studio generated comments lines.

### Example:

Removes Studio generated comments, such as:

// fires when the button is clicked

//OnChange is called on every changed character

// Visual DataFlex xx.x Client Size Adjuster

// Visual DataFlex xx.x Migration Utility,

