# Refactoring Functions

**&nbsp;**![Image](<lib/LineByLine.png>) **STANDARD - LINE BY LINE**

# One source line at a time is passed to these functions.

* # ChangeCalcToMoveStatement

Replaces obsolete commands with the Move command.

&nbsp;

" Calc, MoveInt, MoveReal, MoveNum, MoveStr " -\> " Move "

### Example:

Calc(iVar + 2) to iMyVar

MoveStr "New Label" to sMyVar

### Will be changed into into:

Move (iVar + 2) to iMyVar

Move "New Label" to sMyVar

* # ChangeCurrent\_ObjectToSelf

&nbsp; &nbsp; Replaces the legacy keyword Current\_Object with Self.

### &nbsp; &nbsp; Example:

Procedure RunReport

Send RunReport to (oMainReport(Current\_Object))

End\_Procedure

### Will be changed into:

Procedure RunReport

Send RunReport to (oMainReport(Self))

End\_Procedure

* # ChangeDfTrueDfFalse

&nbsp; &nbsp; Replaces legacy "DFTrue" and "DFFalse" to True or False respectively.

* # ChangeGetAddress

&nbsp; &nbsp; Replaces legacy GetAddress command with function AddressOf().

* # ChangeInsertCommandToFunction

Changes the legacy Insert command with the function Insert().

### &nbsp; &nbsp; Examples:

Insert "," In sText At 2' --\> 'Move (Insert(",", sText, 2)) to sText'

If sOne Eq "A" Insert "B" in sOne at 2' --\> ' If sOne Eq "A" Move (Insert("B", sOne, 2)) to sOne'

* # ChangeInToContains

&nbsp; &nbsp; Replace IN command to Contains operator.

### *&nbsp;* &nbsp; Example:

String sSub sAlphabet

Move "abcdefgijklmnopqrstuvwxyz" to sAlphabet

Move "abc" to sSub

If sSub in sAlphabet Send Info\_Box sSub "Part of Alphabet"

### &nbsp; &nbsp; Will be changed into:

String sSub sAlphabet

Move "abcdefgijklmnopqrstuvwxyz" to sAlphabet

Move "abc" to sSub

If (sAlphabet Contains sSub) Begin

Send Info\_Box sSub "Part Of Alphabet"

End

* # ChangeLegacyIndicators

Changes legacy square brackets found indicators; \[Found\] {FindErr\] to expressions; (Found) or (Not(Found)) Known limitations: Can handle max two booleans within the one square bracket pair.

### &nbsp; &nbsp; Examples:

\[Select\] Indicate Select as Windowindex Eq Fieldindex --\> Move (WindowInex = FieldIndex) to Select

\[Found\] and \[FindErr\] indicator statements.

\[Found\] Command -\> e.g. If Found Command

While \[Not Found\] &nbsp; -\> e.g. While (Not(Found))

\[Found\|Not Found\|FindErr\|Not FindErr\] While &nbsp; -\> e.g. While (Not(Found)) &nbsp;

\[Found\] Indicate Found as Invoice.CustNum eq Customer.Number -\> If (Found) Move (Invoice.CustNum eq Customer.Number) to Found

If \[Not Found\] Reread hTable -\> If (Not(Found)) Reread hTable&nbsp; &nbsp; &nbsp;

\[~Found\] begin -\> If (Not(Found)) Begin&nbsp; &nbsp; &nbsp;

\[Found ~Found\] Begin -\> If (Found and Not(Found)) Begin

* # ChangeLegacyOperators

&nbsp; &nbsp; Changes the Legacy Operators.

&nbsp;&nbsp; &nbsp;

&nbsp; &nbsp; " *LT, LE, EQ, NE, GT, GE* " *-\>* " *\<, \<=, =, \<\>, \>, \>=* "

### *&nbsp;* &nbsp; Example:

Integer iA iB

If (iA Eq iB) Begin

&nbsp; &nbsp; Procedure\_Return

End

### &nbsp; &nbsp; Will be changed into:

Integer iA iB

If (iA = iB) Begin

&nbsp; &nbsp; Procedure\_Return

End

* # ChangeLegacyShadow\_State

&nbsp; &nbsp; Changes Shadow\_State and Object\_Shadow\_State to Enabled\_State.

### *&nbsp;* &nbsp; Examples:

Set Shadow\_State \[of oObject\] to True" -\> "Set Enabled\_State \[of oObject\] to False

Set Object\_Shadow\_State \[of oObject\] to True" -\> "Set Enabled\_State \[of oObject\] to False

* # ChangeLengthCommandToFunction

&nbsp; &nbsp; Changes Length command to function Length().

### *&nbsp;* &nbsp; Example:

String sRiches

Integer iLength

Move "great, vast" to sRiches

Length sRiches to iLengths

### &nbsp; &nbsp; Will be changed into:

String sRiches

Integer iLengths

Move "Great, Vast" to sRiches

Move (Length(sRiches)) to iLengths

* # ChangePosCommandToFunction

&nbsp; &nbsp; Changes the Pos command to function Pos().

### *&nbsp;* &nbsp; Example:

String sWhole

Integer iPos

Move "abcdefgh" to sWhole

Pos "def" in sWhole to iPos

### &nbsp; &nbsp; Will be changed into:

String sWhole

Integer iPos

Move "abcdefgh" to sWhole

Move (Pos("def", sWhole)) to iPos

* # ChangeReplaceCommandToFunction

&nbsp; &nbsp; Changes the Replace command to function Replace().

### *&nbsp;* &nbsp; Example:

String sSentence

Move "We will be in town for two weeks." to sSentence

Replace "two weeks" in sSentence with "one week"

### &nbsp; &nbsp; Will be changed into:

String sSentence

Move "We will be in town for two weeks." to sSentence

Move (Replace("two weeks", sSentence, "one week.") to sSentence

* # ChangeSysdate4

&nbsp; &nbsp; Changes Sysdate4 command to function Sysdate().

### *&nbsp;* &nbsp; Example:

Sysdate4 -\> Sysdate, as the SysDate4 command is obsolete.

* # ChangeTrimCommandToFunction

&nbsp; &nbsp; Changes Trim command to function Trim().

### *&nbsp;* &nbsp; Example:

Trim sVal to sVal -\> Move (Trim(sVal)) to sVal

* # ChangeUClassToRefClass

Replaces Get Create U\_ClassName with Get Create (RefClass(ClassName)).

### Example:

Get Create U\_Array to hoArray

### Will be changed into:

Get Create (RefClass(Array) to hoArray

* # ChangeZeroStringCommandToFunction

&nbsp; &nbsp; Changes ZeroString command to function ZeroString().

### Example:

ZeroString iLength to sParameter' --\> 'Move (ZeroString(iLength)) to sParameter'

* # RemoveEndComments

Remove comments after End\_Class/End\_Object/End\_Function/End\_Procedure.

### Example:

Procedure MyNewProcedure String sText

Send Update

End\_Procedure //MyProcedure

### &nbsp; &nbsp; Will be changed into:

&nbsp;&nbsp; &nbsp; &nbsp; Procedure MyNewProcedure String sText

Send Update

End\_Procedure

* # RemoveLocalKeyword

Removes the legacy keyword Local from variable declaration lines in functions and procedures.

### Example:

Procedure Activate Returns Integer

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Local Integer iRetval iOk

### &nbsp; &nbsp; Will be changed into:

&nbsp;&nbsp; &nbsp; &nbsp; Procedure Activate Returns Integer

&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Integer iRetval iOk

* # RemovePropertyPrivate

Removes the keyword Private from property declarations.&nbsp;

&nbsp;

*Note: In some rare cases you might need to tweak your code if it is removed.*&nbsp;

### Example:

Property String pSelStart1 Private ""

Property String pSelStop1&nbsp; Private ""

### Will be changed into:

Property String pSelStart1 ""

Property String pSelStop1&nbsp; ""

* # RemovePropertyPublic

Removes the keyword: Public from property declarations.

### Example:

Property String pSelStart1 Public ""

Property String pSelStop1&nbsp; Public ""

### &nbsp; &nbsp; Will be changed into:

Property String pSelStart1 ""

Property String pSelStop1&nbsp; ""

* # RemoveTrailingSpaces

Removes spaces at the end of a line.

* # SplitInlineIfElseLine

Restructures single If () Begin Else code lines to multiple lines. The settings below can be selected from the **Function List** - **Parameter** column for the SplitInlineIfElseLine row. Double-click the Parameter column and select the correct parameter from the drop-down.

&nbsp;

**CI\_SplitBySpaceAndSemicolon:** &nbsp; &nbsp; Will break the line **with a space** followed by a semi colon.&nbsp;

**CI\_SplitBySemicolon:** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Will break the line **with no space** followed by a semi colon.&nbsp;

**CI\_SplitToBeginEndBlock:** &nbsp; &nbsp; &nbsp; &nbsp; Will break the line by adding a Begin / End block.&nbsp;

&nbsp;

The tab size setting governs how many spaces should be used when indenting the code block.

Changing the tab size changes how the Scintilla editor (Editor view) makes indents and can be changed from the **Function List**'s **Parameter** column for the **Editor Indent** refactoring function. The same setting can be found on the **Editor Properties** dialog.

### Example:

If (iRetval = 0) Procedure\_Return

### Will be replaced to:

### First Option - CI\_SplitBySemicolon:

If (iRetval = 0);

&nbsp; &nbsp; &nbsp; &nbsp; Procedure\_Return

### Second Option CI\_SplitBySpaceAndSemicolon:

If (iRetval = 0) ; // Space before the ";" character

&nbsp; &nbsp; &nbsp; &nbsp; Procedure\_Return

### Third Option -CI\_SplitToBeginEndBlock:

If (iRetval = 0) Begin

&nbsp; &nbsp; &nbsp; &nbsp; Procedure\_Return

End

