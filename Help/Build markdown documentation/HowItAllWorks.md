# How It All Works

The **Refactoring Engine** (cRefactorEngine) is responsible for processing source code. When starting a new refactoring session, it receives a struct containing a selection of refactoring functions, source files, and other settings.

&nbsp;

Here's how it operates:

&nbsp;

**&#49;. Function Lookup:** The refactoring Engine uses the **Functions data table** to identify selected functions. It then calls these functions from the **cRefactorFuncLib** code repository. This repository is based on the **cBasicFuncLib** class and includes a series of system refactoring helper functions.

&nbsp;

**&#50;. Refactoring Types:** The data passed to the refactoring function depends on the specific **refactoring type.**&nbsp;

[](<Standard-Line-by-Line>)

[**Standard** (Line-by-line)](<Standard-Line-by-Line>)**:**

* &nbsp;
  * This type of refactoring changes the source code based on the description of the selected function.
  * The Refactoring Engine calls the chosen refactoring functions sequentially, one source line at a time. This gradual transformation helps improve the code.

[](<Remove-Line-by-Line>)

[**Remove** (Line-by-line)](<Remove-Line-by-Line>):

* &nbsp;
  * Focused on removing unused features from the code that are no longer needed.

[](<Editor-OneFile>)

[**Editor** (One File)](<Editor-OneFile>):

* &nbsp;
  * Concentrates on organizing the source code to enhance readability.

&nbsp;

[**Report** (One File)](<Report-OneFile>):

* &nbsp;
  * Identifies anomalies in the source code and generates a list of affected source files.
  * No actual code changes are made.

&nbsp;

[**Report** (All Files)](<Report-AllFiles>):

* &nbsp;
  * Similar to the previous type but operates on all selected files.
  * Again, no code modifications occur.

&nbsp;

[**Other** (One File)](<Other-OneFile>):

* &nbsp;
  * Expects a complete source file represented as a string array.

&nbsp;

[**Other** (All Files)](<Other-AllFiles>):

* &nbsp;
  * Requires a string array containing all file names, including their full paths.

&nbsp;

**&#51;. Adding New Functions:**

* &nbsp;
  * When adding a new refactoring function, the corresponding code must be added to the **cRefactoringFuncLib class**.
  * Next, the function needs to be registered in the Functions database table using the **TestBench Program**.
  * It's highly advisable to create **unit tests** for new function in the **oUnit\_Tests.pkg** file. Running these test via the **TestBench toolbar** ensures that everything works smoothly.

&nbsp;

**&#52;. Function Parameters:**

All functions can accept two parameters (though the second one is optional)

* &nbsp;
  * The first parameter always contains **source code** in some form.
  * The second optional parameter corresponds to the information found in the **Parameter** column of the **Function List grid**.

&nbsp;

**&#53;. Refactoring Engine Log Files**

* &nbsp;
  * After a refactoring session completes, the **Refactoring Engine** collects data about the run and adds it to the **Log file**. Additionally some functions generate specific log files. For example, the **ReportUnusedSourceFiles** refactoring function creates an additional log file. All such log files are collected in the **Other Log files dialog**.
  * The **Refactor Engine,** based on the **cBusinessProcess** class, suppresses error during its operation. However, if any errors occur while the engine runs, they are saved to the **StatLog database table**. You can be view these errors by clicking the toolbar button [**Refactor Engine Error Log**](<Toolbars>).

&nbsp;

&nbsp;

&nbsp;

*"We **offer to create new refactoring functions** for any **customer code base.** Our services come at a **very reasonable fee**. We **provide a 60% discount** on our normal fee when you request us to add more functions that will be **made available in the public domain.** This means that **anybody can use those functions** with the **DFRefactor project**."*

&nbsp;

*"We also specialize in **bringing whole software projects up to date** from legacy code. Such development will of course be **under strict confidentiality**, and **we will not share any part of your private code with anybody else**. If you are interested please see the contact details on the [**Feedback***](<Feedback>) *help page."*
