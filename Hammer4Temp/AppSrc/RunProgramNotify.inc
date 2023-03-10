//TH-Header
//*****************************************************************************************
// Copyright (c)  2001 Michael Kurz
// All rights reserved.
// If you want to use this source in your applications conatct: <MichaelKurz@gmx.at>
//
// $FileName    : RunProgramNotify.inc
// $ProjectName : Codemax
// $Author      : Michael Kurz
// $Created     : 29.05.2001  17:53
//
// Contents:
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Use cRunProgramNotify.pkg

Global_Variable Integer ghoRunProgramNotifyHandler
Object oRunProgramNotifyHandler Is a cRunProgramNotify
    Move Self   To ghoRunProgramNotifyHandler
End_Object
    // Executes a Program and send the iCallBack message to the given dest object when
    // the launched program is finished.
Procedure RunProgramNotify Global String sPrg String sPara Integer iShow Integer iCallBack Integer iDest Integer iHandleCallbackEx
    Integer iRet iHandleCallback
    If NUM_Arguments Ge 6 Move iHandleCallbackEx    To iHandleCallback
    Get RunProgramEx Of ghoRunProgramNotifyHandler sPrg sPara iShow iCallBack iDest iHandleCallback To iRet
End_Procedure


