﻿/* *** User defined Refactor Functions *** 
  
   This file is empty by default!
   It is for adding "special case" functions that is of no general interest, but rather special 
   to the developer's source code/project.
   
   - On the other hand; to add a function of general interest, add it to the cRefactorFuncLib.pkg instead!
   Then (after it has been registered), export those functions with the TestBench program - FuncionsExportImport.vw
   That will create a Json file that can be send to any developer, but it is highly recommended to email the 
   Json file to: SUPPORT@RDCTOOLS.COM. It will be tested by us and included into the main GitHub respository.
  
   THIS FILE IS USED IN THE oRefactorFuncLib.pkg.
   It is important to understand that any functions defined here will be treated just like any other
   refactoring function of the cRefactorFuncLib repository when the refactoring engine is run.
   Thus, they need to follow the same rules as functions of the cRefactorFuncLib class. See "types" below.
   However, functions entered in this package will not be included in the Export/Import Json file.
  
   *** Important ***
       - Each refactoring function defined here must also be registered!
       - A function is registered by adding meta-data at the top.
       - If the new refactoring function is based on a new class, add a "Use MyNewClass.pkg" to
         the UserDefinedUseStatement.pkg file. For sample usage see: Function RestyleDDOs.
  
   General guide-lines for a refactoring function interface:
  
   There are many types of refactoring functions.
   The function type governs how and when the function is
   called and with what parameters.
  
   Here are the available function types and their expected parameters:
   =====================================================================
    eStandardFunction  - One source line at a time. Params: (&sLine) and sParameter
    eRemoveFunction    - One source line at a time. Params: (&sLine) and sParameter
    eEditorFunction    - One source file as a string array. (Scintilla Editor) Params: (&asCode) and sParameter
    eReportFunction    - One source file as a string array. No source changes! Params: (&asCode) and sParameter
    eOtherFunction     - One source file as a string array will be passed.     Params: (&asCode) and sParameter
    eReportFunctionAll - Makes no source changes!     Params: (&asAllSourceFiles) and sParameter
    eOtherFunctionAll  - All files as a string array. Params: (&asAllSourceFiles) and sParameter

              
    There must be at least *one blank line* between each
    function. This is because the cExportImportFunctions
    logic needs it when scanning source code.

*/

//   Use statement for YOUR USER DEFINED refactoring classes and constants,
//   that are used by the functions below.
Use UserDefinedUseStatement.pkg

/*  Sample function:
      See: oRefactorFuncLib.pkg for meta-tag rules.
      
        {Published=True} 
        { Description = """
            Changes legacy Left command with Left.
            \nExample: Left sVar 5 to sLeft -> Move (Left(sVar, 5)) to sLeft
            { MethodType = eStandardFunction }
            { SummaryText = Changed: 'Left' command to function: 'Left' }
            """ }
        Function ChangeLeftCommandToFunction String ByRef sLine String sParameter Returns Boolean
            Boolean bChanged
            Get SingleCommandSyntaxToFunction (&sLine) CS_Left to bChanged
            Function_Return bChanged
        End_Function   

*/

// *** Add your Functions here: ***

