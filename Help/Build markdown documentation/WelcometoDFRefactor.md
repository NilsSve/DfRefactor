# Welcome to DFRefactor 2024

![Image](<lib/DFRefactor72x7273.png>)

**DFRefactor - An Automated Refactoring Tool for DataFlex**

&nbsp;

DFRefactor is a powerful **tool** written in DataFlex and is **free of cost**. The tool **assists with refactoring legacy DataFlex code**. It specifically targets code that uses syntax no longer supported or encouraged. If you’re unfamiliar with the concept, **refactoring involves improving the structure and readability of existing code without altering its external behavior**. See also: [What Is Refactoring](<WhatIsRefactoring>).

&nbsp;

*Note: There is an on-line version of the local .chm help text and it can be found [here*](<https://www.rdctools.com/HTMLHelpDFRefactor/DFRefactor.html> "target=\"\_blank\"")*.*

### Here are the key components of DFRefactor:

&#49;. **Main Program (DFRefactor):**

* &nbsp;

  * &nbsp;

    * &nbsp;
      * \- This is the primary tool that most users and developers will interact with. It performs automated refactoring tasks on your DataFlex code base.
      * \- After running a refactoring session, you can compare the code before and after the changes. Set up a comparison tool in the Program Properties dialog for this purpose.

&nbsp;

&#50;. **TestBench (For advanced users):**

* &nbsp;

  * &nbsp;

    * &nbsp;
      * \- Designed for advanced users. The TestBench assists in developing new refactoring functions.
      * \- It works with a single test file containing various legacy code snippets. You can compile the refactoring file to verify that the changes yield the expected results.

&nbsp;

**&#51;. DFUnit\_TestRunner (For advanced users):**

* &nbsp;

  * &nbsp;

    * &nbsp;
      * \- This component focuses on unit testing for DataFlex
      * \- A suite of unit tests has been set up to specifically test the cRefactorFuncLib (and its parent class, cBasicFuncLib). These tests ensure that any modifications to these classes do not break existing functionality.
      * \- Originally developed by Ola Eldöy, it was further enhanced by Bram NijenKamp.and customized tweaked for this project.

&nbsp;

*NOTE: More functions will be added gradually, and it is a good idea to check the GitHub repository from time to time at: [*https://github.com/NilsSve/DfRefactor](<https://github.com/NilsSve/DfRefactor>)

&nbsp;

*Any issues or bug reporting should be done at our GitHub location. Either use the [**Issues***](<https://github.com/NilsSve/DfRefactor/issues>) *menu to report/view known bugs and/or use the [**Discussions***](<https://github.com/NilsSve/DfRefactor/discussions>) *to enter suggestions.*

[](<http://www.vdf-guidance.com> "target=\"\_blank\"")

*"We **offer to create new refactoring functions** for any **customer code base.** Our services come at a **very reasonable fee**. We **provide a 60% discount** on our normal fee when you request us to add more functions that will be **made available in the public domain.** This means that **anybody can use those functions** with the **DFRefactor project**."*

&nbsp;

*"We also specialize in **bringing whole software projects up to date** from legacy code. Such development will of course be **under strict confidentiality**, and **we will not share any part of your private code with anybody else**. If you are interested please see the contact details on the [**Feedback***](<Feedback>) *help page."*

## &nbsp;

## &#50;024 Overhauled version created by:

**Nils Svedmyr, RDC Tools International, Sweden**

&nbsp;

*Testing Team:*

&nbsp;- Sture Andersen, Sture Aps, Denmark

&nbsp;- Yannick Lucassen, Data Access Europe, The Netherlands

&nbsp;- Marco Kuipers, 28 IT, Australia

&nbsp;- Anderson Rodrigues, 2WA, Brazil

&nbsp;- Samuel Pizarro, Brazil

&nbsp;- Raveen Sundram, Excellent Software Ltd, New Zealand

&nbsp;- Michael Mullan, Danes Bridge Enterprises, USA

## Original version created by:

**Nils Svedmyr**

&nbsp;

*With the help from:*

\- Wil Van Antwerpen, Antwise, The Netherlands. *Instrumental for giving help with the Scintilla editor implementation.*

\- Sean Bamforth

\- Allan Kim Eriksen

\- Chris Spenser

\- Bob Worsley

\- Marcia Booth

