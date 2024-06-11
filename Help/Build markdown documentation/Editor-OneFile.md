# Refactoring Functions

**&nbsp;** ![Image](<lib/Editor.png>) **EDITOR - ONE FILE**

**Editor functions are all performed within the Scintilla editor view.**

* # EditorReIndent

Re-indents a source file. You can change the Tab Size for the number of spaces to use (Indent Size) from the **Function List** - **Parameter** column or 'Editor Settings (Alt+D)' dialog.

*NOTE: This is a Scintilla editor library function and will slow down the refactoring process. It is performed in the **Editor View,** which is loaded automatically when needed.*

### Example:

&nbsp; &nbsp; Use POTEXT.DD

&nbsp; &nbsp; Use ARTSUB.DD

&nbsp;

&nbsp; &nbsp; &nbsp; DEFERRED\_VIEW Activate\_Art2Auto FOR ;

&nbsp; &nbsp; &nbsp; Object Art2Auto is a DbView

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp; Procedure Activating

&nbsp;&nbsp; &nbsp; &nbsp; Forward send Activating

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Set Value of oform2 to Comp.Mps\_PoodAddr

&nbsp;Set Value of oform3 to Comp.Mps\_PopHeadtyp

&nbsp; &nbsp; &nbsp; &nbsp; End\_Procedure

### Would with a tab-size of 4 be changed into:

Use POTEXT.DD

Use ARTSUB.DD

&nbsp;

DEFERRED\_VIEW Activate\_Art2Auto FOR ;

&nbsp; &nbsp; &nbsp; &nbsp; Object Art2Auto is a DbView

&nbsp;

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Procedure Activating

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Forward send Activating

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Set Value of oform2 to Comp.Mps\_PoodAddr

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Set Value of oform3 to Comp.Mps\_PopHeadtyp

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; End\_Procedure

* # EditorNormalizeCase

Changes the DataFlex Keywords case. Refactoring Editor function. It adjust the case of all scoped and keywords to match the casing as defined in the language configuration.

&nbsp;

*NOTE: You can change keyword spellings from the 'Editor Settings (Alt+D)' dialog to match your personal preferences.*&nbsp;

*This is a Scintilla editor library function and will slow down the refactoring process.*

### Example:

procedure OnClick

&nbsp; &nbsp; &nbsp; &nbsp; integer iRec

&nbsp; &nbsp; &nbsp; &nbsp; number nOheadOno

&nbsp; &nbsp; &nbsp; &nbsp; date dDate

&nbsp; &nbsp; &nbsp; &nbsp; get file\_field\_current\_value of Caltrans\_DD)) File\_Field Caltrans.Recnum to iRec

&nbsp; &nbsp; &nbsp; &nbsp; get file\_field\_current\_value of Caltrans\_DD&nbsp; File\_Field Caltrans.PoHead\_Ono&nbsp; to nOheadOno

&nbsp; &nbsp; &nbsp; &nbsp; get file\_field\_current\_value of Calcum\_D &nbsp; &nbsp; File\_Field Calcum.Date&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; to dDate

&nbsp; &nbsp; &nbsp; &nbsp; if (nOheadOno = 0) begin

If (iRec \<\> 0) Begin

### Will be changed into into:

Procedure OnClick

&nbsp; &nbsp; &nbsp; &nbsp; Integer iRec

&nbsp; &nbsp; &nbsp; &nbsp; Number nOheadOno

&nbsp; &nbsp; &nbsp; &nbsp; Date dDate

&nbsp; &nbsp; &nbsp; &nbsp; Get File\_Field\_Current\_Value of Caltrans\_DD)) File\_Field Caltrans.Recnum to iRec

&nbsp; &nbsp; &nbsp; &nbsp; Get File\_Field\_Current\_Value of Caltrans\_DD &nbsp; File\_Field Caltrans.Pohead\_Ono&nbsp; to nOheadOno

&nbsp; &nbsp; &nbsp; &nbsp; Get File\_Field\_Current\_Value of Calcum\_D&nbsp; &nbsp; &nbsp; File\_Field Calcum.Date&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; to ddate

&nbsp; &nbsp; &nbsp; &nbsp; If (nOheadOno = 0) Begin

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; If (iRec \<\> 0) Begin

