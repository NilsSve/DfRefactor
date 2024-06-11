# Refactoring Functions

&nbsp;![Image](<lib/NewItem8.png>) **OTHER - ALL FILES**

* # RestylelDDOs

Rename DataDictionary objects to newer Studio standard

&nbsp;

**The new style is:**

Object o\<tablename\>\_DD is a c\<TableName\>DataDictionary

&nbsp;

The DataFlex Studio have a switch so you can keep on using the legacy style name which is

Object o\<tablename\>\_DD is a \<tablename\>\_Datadictionary

&nbsp;

**However before DataFlex version 12, the style was:**

Object \<tableName\>\_DD is a \<tablename\>\_Datadictionary

&nbsp;

This caused tremendous headaches as due to the extra "o" we ended up with name clashes

all over the place. Copying old code into new views/dialogs simply breaks and if your

code base has mixed styles then the compiler will not catch that. This quickly became a code nightmare.

&nbsp;

**This refactoring function allows you to switch between the following code styles:**

&nbsp;

*Change the following code style:*

&nbsp; \<TableName\>\_DD &nbsp; &nbsp; \>\> eDDOldStyle

*To:*

&nbsp;o\<TableName\>\_DD &nbsp; \>\> eDDStudioStyle

