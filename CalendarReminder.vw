Use dfallent.pkg
Use ESCLASS.INC
Use Windows.pkg
Use cPP7ReportControl.pkg
Use dfBitmap.pkg
Use dftimer.pkg
//Use Codejock.Calendar.v15.1.2.pkg
//Use cComCalendar.pkg
Use SigCjW_Calendar.pkg

Register_Object oButton04
Activate_View Activate_oCalendarReminder for oCalendarReminder
Object oCalendarReminder is a dbView0

    Set Border_Style to Border_Normal
    Set Size to 192 338
    Set Location to 2 2
    Set Icon to "Bell.ico"
    Set Label to "Påminnelser"
    Set peAnchors to anAll
    Set Verify_Data_Loss_Msg to 0
    Set Verify_Exit_Msg      to 0
    
    Property Handle[] phoEvents
    Property Handle phoDialogs
    Property Variant[] pvReminders
    Property Handle phoReminders
    Property Handle phoCalendarObject
    
    If (not(Regd0002.FALT20)) Begin //if all views full screen, don't do below!
        Set pbSizeToClientArea to False
        Set piMaxSize to 192 338
        Set Auto_Top_View_State to True
    End
    Set view_access_name to "REMINDER"
    Set Default_Action_Button to oButton04

    Object oReminderContextMenu is a cCJContextMenu
        Property String psID
        Property Number pnNr
        Object oppnakoppladvyMenuItem is a cCJMenuItem0
            Set psCaption to "Öppna kopplad vy"
            Set psTooltip to "Öppna kopplad vy"
            Procedure OnExecute Variant vCommandBarControl
                Boolean bOK
                Get fOpenView (psID(Self)) (pnNr(Self)) to bOK
            End_Procedure
        End_Object

        Procedure OnPopupInit Variant vCommandBarControl Handle hoCommandBarControls
            If (psID(Self) = "") Set pbEnabled of oppnakoppladvyMenuItem to False
            Else Set pbEnabled of oppnakoppladvyMenuItem to True
            Forward Send OnPopupInit vCommandBarControl hoCommandBarControls
        End_Procedure
        
    End_Object

    Object oGrid1 is a Grid
        Set Location to 38 3
        Set Size to 87 329
        Set Line_Width to 4 0 
        Set Form_Width 0 to 12
        Set Header_Label  0 to ""
        
        Set Form_Width 1 to 211
        Set Header_Label  1 to "Ämne"
        
        Set Form_Width 2 to 88
        Set Header_Label  2 to "Förfaller om"

        Set Form_Width 3 to 0
        Set Header_Label  3 to ""
        
//        Set Form_Width 4 to 0
//        Set Header_Label 4 to ""
//        
//        Set Form_Width 5 to 0
//        Set Header_Label 5 to ""

        Set GridLine_Mode to Grid_Visible_None
        Set Resize_Column_State to False
        Set Select_Mode to Single_Select
        Set CurrentRowColor to clHighlight
        Set Highlight_Row_State to True
        Set Horz_Scroll_Bar_Visible_State to False
        Set CurrentCellColor to clHighlight
        Set Floating_Menu_Object to oReminderContextMenu
        Set peAnchors to anAll

        Procedure Mouse_Click Integer iWindowNumber Integer iPosition
            Forward Send Mouse_Click iWindowNumber iPosition
            Send pOpenEvent
        End_Procedure
    
        Function fGetSnoozeValue String sSnoozeValue Returns Integer
            Integer iRetVal
            If (sSnoozeValue = "0 minuter") Move 0 to iRetVal
            If (sSnoozeValue = "1 minut") Move 1 to iRetVal
            If (sSnoozeValue = "5 minuter") Move 5 to iRetVal
            If (sSnoozeValue = "10 minuter") Move 10 to iRetVal
            If (sSnoozeValue = "15 minuter") Move 15 to iRetVal
            If (sSnoozeValue = "30 minuter") Move 30 to iRetVal
            If (sSnoozeValue = "1 timme") Move 60 to iRetVal
            If (sSnoozeValue = "2 timmar") Move 120 to iRetVal
            If (sSnoozeValue = "4 timmar") Move 240 to iRetVal
            If (sSnoozeValue = "0,5 dagar") Move 720 to iRetVal
            If (sSnoozeValue = "1 dag") Move 1440 to iRetVal
            If (sSnoozeValue = "2 dagar") Move 2880 to iRetVal
            If (sSnoozeValue = "3 dagar") Move 4320 to iRetVal
            If (sSnoozeValue = "4 dagar") Move 5760 to iRetVal
            If (sSnoozeValue = "1 vecka") Move 10080 to iRetVal
            If (sSnoozeValue = "2 veckor") Move 20160 to iRetVal
            Function_Return iRetVal
        End_Function
        
        Procedure pSnoozeEvent
            Integer iItem iSnoozeValue iArrayPos
            Handle hoReminder 
            String sSnoozeValue
            Boolean bSnoozed
            Variant[] vReminders
            Variant vReminder
            
            Get Value of oDbComboForm01 to sSnoozeValue
            Get fGetSnoozeValue sSnoozeValue to iSnoozeValue

            Get Current_Item to iItem
            Move (iItem /4 * 4) to iItem //current item is divided with no of colums and multiplied with the same
            Get Value of oGrid1 (iItem + 3) to iArrayPos
            
            Get pvReminders to vReminders
            Move vReminders[iArrayPos] to vReminder
            Get Create (RefClass(cSigCjComCalendarReminder)) to hoReminder
            Set pvComObject of hoReminder to vReminder
            
            Get ComSnooze of hoReminder iSnoozeValue to bSnoozed
        End_Procedure
        
        Procedure pOpenEvent
            Integer iArrayPos
            Handle[] hoEvents 
            Handle hoClient hoEvent 
            String sId sRowId
            RowID riRowId
            Boolean bFound bVisible bOk
            Variant vEvent
            
            Get Client_Id to hoClient            
            Integer iItem
            Get Current_Item of oGrid1 to iItem
            Move (iItem /4 * 4) to iItem //current item is divided with no of colums and multiplied with the same to get base item
            Get Value of oGrid1 (iItem + 3) to iArrayPos
            Get phoEvents to hoEvents
            Move hoEvents[iArrayPos] to hoEvent
            Get ComId of hoEvent to sID
            Get ComEventVisible of hoEvent to bVisible
            If (not(bVisible)) Begin
//                Clear REGD0400
//                Move sID to REGD0400.ID
//                Find eq REGD0400 by Index.1
//                If (Found) Begin
//                    Move REGD0400.TASKROWID to sRowId
//                    Move (DeserializeRowID(trim(sRowId))) to riRowId
//                    Move (FindByRowID(REGD0410.File_Number, riRowId)) to bFound
//                    If (bFound) Begin
//                        #IFNDEF TEST
//                        Send Activate_oREGB0410 of hoClient
//                        #ENDIF
//                    End
//                End
            End
            Else Begin
                Get pvComObject of hoEvent to vEvent
                Get ComShowEditEvent of (phoDialogs(Self)) vEvent to bOk // built in dialog
            End
        End_Procedure
        
        Procedure pDismissEvent
            Integer iArrayPos iItem iRowsFirstItem
            Handle hoReminder
            Boolean bDismissed
            Variant[] vReminders
            Variant vReminder
            Get Current_Item of oGrid1 to iItem
            Move (iItem /4 * 4) to iItem 
            Get Value of oGrid1 (iItem + 3) to iArrayPos
            Get pvReminders to vReminders
            Move vReminders[iArrayPos] to vReminder
            Get Create (RefClass(cSigCjComCalendarReminder)) to hoReminder
            Set pvComObject of hoReminder to vReminder
            Get ComDismiss of hoReminder to bDismissed
        End_Procedure

        Procedure pDismissAllEvents
            Send ComDismissAll of (phoReminders(Self))
            Send Close_Panel
        End_Procedure

        Procedure Item_Change Integer iFromItem Integer iToItem Returns Integer
            Integer iRetVal
            Forward Get msg_Item_Change iFromItem iToItem to iRetVal
            If (iToItem <> iFromItem) Send pAddLabels iToItem    
            Procedure_Return iRetVal
        End_Procedure

        Procedure Mouse_Down2 Integer iWindowNumber Integer iPosition
            String sID
            Boolean bVisible
            Handle[] hoEvents
            Handle hoEvent
            Integer iArrayPos iItem
            Get phoEvents to hoEvents
            If (SizeOfArray(hoEvents) > 0) Begin
                Get Current_Item to iItem
                Move (iItem /4 * 4) to iItem //current item is divided with no of colums and multiplied with the same
                Get Value of oGrid1 (iItem + 3) to iArrayPos
                Move hoEvents[iArrayPos] to hoEvent
                Get ComId of hoEvent to sID
                Get ComEventVisible of hoEvent to bVisible
//                If (bVisible) Begin 
//                    Set psID of oReminderContextMenu to ""
//                    Set pnNr of oReminderContextMenu to 0
//                End
//                Else Begin
                    Clear REGD0400
                    Move sID to REGD0400.ID
                    Find eq REGD0400 by Index.1
                    If (Found) Begin
                        RowID riRowId
                        Boolean bOK
                        Move (DeserializeRowID(trim(REGD0400.TASKROWID))) to riRowId
                        Move (FindByRowID(REGD0410.File_Number, riRowId)) to bOK
                        If (bOK) Begin
                            Set psID of oReminderContextMenu to REGD0410.ID
                            Set pnNr of oReminderContextMenu to REGD0410.NR
                        End
                    End
//                End
            End
            Forward Send Mouse_Down2 iWindowNumber iPosition
        End_Procedure
        On_Key Key_Enter Send pOpenEvent
    End_Object

    Object oButton04 is a Button0
        Set Size to 14 67
        Set Location to 159 265
        Set Label to "Viloläge"
        Set peAnchors to anBottomLeft
        //AB-StoreStart
        Procedure OnClick
            Send pSnoozeEvent of oGrid1
        End_Procedure // OnClick
        //AB-StoreEnd
    End_Object

    Object oButton02 is a Button0
        Set Size to 14 67
        Set Location to 129 196
        Set Label to "Öppna"
        Set peAnchors to anBottomRight
        //AB-StoreStart
        Procedure OnClick
            Send pOpenEvent of oGrid1
        End_Procedure // OnClick
        //AB-StoreEnd
    End_Object

    Object oButton03 is a Button0
        Set Size to 14 67
        Set Location to 129 265
        Set Label to "Stäng"
        Set peAnchors to anBottomRight
        //AB-StoreStart
        Procedure OnClick
            Send pDismissEvent of oGrid1
        End_Procedure // OnClick
        //AB-StoreEnd
    End_Object

//    Object oGrid1 is a cSigCJReportControl//cPP7ReportControl
//        Set Size to 102 330
//        Set Location to 24 3
//        Set peDb_Type to eRC_db_Text
//        Set pbActive_Track to True
//        Set pbPX_Save_Layout to True
//        Set psPX_Tag to (Label(Parent(Self)))
//        Set pbShowGroupBox to False
//
//        Procedure OnDefine_Columns
//            Send Add_Report_Column "Check"              20  eRC_Integer   eRC_CheckBox "" ""
//            Send Add_Report_Column "Ämne"               120 eRC_String    eRC_Standard "" ""      
//            Send Add_Report_Column "Förfaller om"       60  eRC_String    eRC_Standard "" ""      
//            Send Add_Report_Column "Event"              0   eRC_String    eRC_Standard "" ""
//            Send Add_Report_Column "ID"                 0   eRC_String    eRC_Standard "" ""      
//            Send Add_Report_Column "Lopnr"              0   eRC_Integer   eRC_Standard "" ""          
//        End_Procedure
//
//        Procedure OnPrepare_RowData //pAddRemindersToGrid
//            Handle hoCalendar hoEvent 
//            Handle[] hoEvents
//            Boolean bVisible bEOF
//            String sCaption sID
//            String sTime
//            Integer iNoOfEvents i
//            Get phoCalendar to hoCalendar
//            Get phoEvents to hoEvents
//            Move (SizeOfArray(hoEvents)) to iNoOfEvents
//            For i from 0 to (iNoOfEvents-1)
//                Move hoEvents[i] to hoEvent
//                Get ComEventVisible of hoEvent to bVisible
//                Get ComSubject of hoEvent to sCaption
//                Get ComReminderMinutesBeforeStart of hoEvent to sTime
//                Get ComId of hoEvent to sID
//                //fill the grid with info
//    //            If (bVisible) Send Add_Item of oGrid1 msg_none "V"
//    //            Else Send Add_Item of oGrid1 msg_none "I"
//    //            Send Add_Item of oGrid1 Msg_None sCaption
//    //            Send Add_Item of oGrid1 Msg_None sTime
//    //            Send Add_Item of oGrid1 Msg_None hoEvent
//    //            Send Add_Item of oGrid1 msg_none sID
//    //            Send Add_Item of oGrid1 msg_none i
//               Send Add_Item_Data bVisible
//               Send Add_Item_Data sCaption
//               Send Add_Item_Data sTime
//               Send Add_Item_Data hoEvent
//               Send Add_Item_Data sID 
//               Send Add_Item_Data i
//               If (i = (iNoOfEvents-1)) Move True to bEOF
//               If (bEOF) Break
//            Loop
//            If (bEOF) Set pbEOF to True
//        End_Procedure
//    
//    End_Object

    Object oButton01 is a Button0
        Set Size to 14 67
        Set Location to 129 3
        Set Label to "Stäng alla"
        Set peAnchors to anBottomLeft
        //AB-StoreStart
        Procedure OnClick
            Send pDismissAllEvents of oGrid1            
        End_Procedure // OnClick
        //AB-StoreEnd
    End_Object

    Object oDbComboForm01 is a ComboForm0
        Set Size to 13 259
        Set Location to 159 3
        Set combo_sort_state to False
        Set peAnchors to anBottomLeft
        Set Entry_State to False
        Procedure Combo_Fill_List
            Send Combo_Add_Item "0 minuter"
            Send Combo_Add_Item "1 minut"
            Send Combo_Add_Item "5 minuter"
            Send Combo_Add_Item "10 minuter"
            Send Combo_Add_Item "15 minuter"
            Send Combo_Add_Item "30 minuter"
            Send Combo_Add_Item "1 timme"
            Send Combo_Add_Item "2 timmar"
            Send Combo_Add_Item "4 timmar"
            Send Combo_Add_Item "0,5 dagar"
            Send Combo_Add_Item "1 dag"
            Send Combo_Add_Item "2 dagar"
            Send Combo_Add_Item "3 dagar"
            Send Combo_Add_Item "4 dagar"
            Send Combo_Add_Item "1 vecka"
            Send Combo_Add_Item "2 veckor"
        End_Procedure

        Procedure Activating
            Forward Send Activating
            String sValue
            Get Combo_Value 2 to sValue            
            Set Value to sValue
        End_Procedure
    End_Object

    Object oTextbox01 is a Textbox0
        Set Size to 10 275
        Set Location to 148 3
        Set Label to "Klicka på Viloläge för att bli påmind igen om: "
        Set peAnchors to anBottomLeft
    End_Object

    Object oTextbox02 is a Textbox0
        Set Size to 10 111
        Set Location to 3 23
        Set Label to "Det finns inga påminnelser att visa "
    End_Object

    Object oTextBox1 is a TextBox
        Set Size to 10 50
        Set Location to 13 23
    End_Object

    Object oTextBox2 is a TextBox0
        Set Size to 10 50
        Set Location to 23 23
    End_Object

    Object oBitmapContainer1 is a BitmapContainer
        Set Size to 16 16
        Set Location to 0 2
        Set Bitmap_Style to Bitmap_Center
        Set Border_Style to Border_None
        Set Transparent_State to True
    End_Object

//    Object oDFTimer1 is a DFTimer
//        Set TimeOut to 120000 //60000 //every second minute
//        Procedure OnTimer Integer wParam Integer lParam
//            //Send pAddRemindersToGrid
//            Send OnComReminders of (phoCalendarObject(Self)) OLExtpCalendarRemindersFire Nothing
//            Forward Send OnTimer wParam lParam
//        End_Procedure
//    
//    End_Object

    Procedure pAddLabels Integer iItem
        Integer iArrayPos
        Handle[] hoEvents
        Handle hoEvent
        String sCaption sLocation sFileName
        DateTime dtStartTime
        Boolean bVisible
        
        Get phoEvents to hoEvents
        If (SizeOfArray(hoEvents) > 0) Begin
            Move (iItem /4 * 4) to iItem 
            Get Value of oGrid1 (iItem + 3) to iArrayPos
            Set Enabled_State of oButton01 to True
            Set Enabled_State of oButton02 to True
            Set Enabled_State of oButton03 to True
            Set Enabled_State of oButton04 to True
            Set Enabled_State of oDbComboForm01 to True
            Move hoEvents[iArrayPos] to hoEvent
            Get ComSubject of hoEvent to sCaption
            Get ComStartTime of hoEvent to dtStartTime 
            Get ComLocation of hoEvent to sLocation
            Get ComEventVisible of hoEvent to bVisible
            If (sCaption <> "") Begin 
                Set FontWeight of oTextbox02 to 1000
                Set Label of oTextbox02 to (sCaption + " ")
            End
            Else Set Label of oTextbox02 to ""
            If (String(dtStartTime) <> "") Set Label of oTextBox1 to ("Starttid: " + String(dtStartTime)) 
            Else Set Label of oTextBox1 to ""
            If (sLocation <> "") Set Label of oTextBox2 to ("Plats: " + sLocation) 
            Else Set Label of oTextBox2 to ""
            Get psBitmapPath of (phoWorkspace(ghoApplication)) to sFileName
            If (bVisible) Set Bitmap of oBitmapContainer1 to (sFileName + "\kalender(1).bmp") 
            Else If (not(bVisible)) Set Bitmap of oBitmapContainer1 to (sFileName + "\success(5).bmp") 
        End
        Else Begin
            Set Bitmap of oBitmapContainer1 to ""
            Set FontWeight of oTextbox02 to 500
            Set Label of oTextbox02 to "Det finns inga påminnelser att visa"
            Set Label of oTextBox1 to ""
            Set Label of oTextBox2 to ""
            Set Enabled_State of oButton01 to False
            Set Enabled_State of oButton02 to False
            Set Enabled_State of oButton03 to False
            Set Enabled_State of oButton04 to False
            Set Enabled_State of oDbComboForm01 to False
        End
    End_Procedure
    
    Function fGetReminderText TimeSpan tsTime Boolean bNegative Returns String
        String sRetVal
        Integer iHour iMinutes iDays
        Number nDays 
        Move (SpanMinutes(tsTime)) to iMinutes
        Move (SpanHours(tsTime)) to iHour
        Move (SpanDays(tsTime)) to nDays
        //minutes
        If (iMinutes = 0) Move ("Nu") to sRetVal
        If (bNegative) Begin 
            If (iMinutes > 0) Move (String(iMinutes) + " minuter försenat") to sRetVal
            If (iMinutes = 1) Move (String(iMinutes) + " minut försenat") to sRetVal
        End
        Else Move (String(iMinutes) + " minuter") to sRetVal
        //hours
        If (iHour <> 0) Begin
            If (bNegative) Begin
                If (iHour > 0) Move (String(iHour) + " timmar försenat") to sRetVal
                If (iHour = 1) Move (String(iHour) + " timme försenat") to sRetVal
            End
            Else Begin
                If (iHour > 0) Move (String(iHour) + " timmar") to sRetVal
                If (iHour = 1) Move (String(iHour) + " timme") to sRetVal
            End
        End
        //days
        If (nDays <> 0) Begin
            If (bNegative) Begin
                If (nDays > 0) Move (String(nDays) + " dagar försenat") to sRetVal
                If (nDays = 1) Move (String(nDays) + " dag försenat") to sRetVal
            End
            Else Begin
                If (nDays > 0) Move (String(nDays) + " dagar") to sRetVal
                If (nDays = 1) Move (String(nDays) + " dag") to sRetVal
            End
        End
        //weeks
        If (nDays >= 7) Begin
            Move nDays to iDays
            Move (iDays / 7) to nDays
            If (bNegative) Begin
                If (nDays = 1) Move (String(nDays) + " vecka försenat") to sRetVal
                Else Move (String(nDays) + " veckor försenat") to sRetVal
            End
            Else Begin
                If (nDays = 1) Move (String(nDays) + " vecka") to sRetVal
                Else Move (String(nDays) + " veckor") to sRetVal            
            End
        End
        Function_Return sRetVal
    End_Function
    
    Procedure pAddRemindersToGrid
        Handle hoEvent 
        Handle[] hoEvents
        Boolean bVisible bEOF bNegative
        String sCaption sID sFileName
        String sTime sReminderLabel sLocation
        Integer iNoOfEvents i
        DateTime dtStartTime dtCurrentDateTime
        TimeSpan tsTime        

        Send Delete_Data of oGrid1
        Get phoEvents to hoEvents
        Move (SizeOfArray(hoEvents)) to iNoOfEvents
        If (iNoOfEvents > 0) Begin 
            If (iNoOfEvents = 1) Move " påminnelse" to sReminderLabel 
            Else Move " påminnelser" to sReminderLabel
            Set Label to (String(iNoOfEvents) + sReminderLabel)
        End
        Else Set Label to "Påminnelser"
        For i from 0 to (iNoOfEvents-1)
            Move hoEvents[i] to hoEvent
            Get ComEventVisible of hoEvent to bVisible
            Get ComSubject of hoEvent to sCaption
            Get ComStartTime of hoEvent to dtStartTime
            Move (CurrentDateTime()) to dtCurrentDateTime
            If (IsNullDateTime(dtStartTime)) Move dtCurrentDateTime to dtStartTime
            Move (dtCurrentDateTime - dtStartTime) to tsTime
            If (dtCurrentDateTime < dtStartTime) Move False to bNegative
            Else Move True to bNegative
            Get fGetReminderText tsTime bNegative to sTime
            Get ComId of hoEvent to sID
            Get ComLocation of hoEvent to sLocation
            //fill the grid with info
            Get psBitmapPath of (phoWorkspace(ghoApplication)) to sFileName
            If (bVisible) Move (sFileName + "\kalender(1).bmp") to sFileName
            Else If (not(bVisible)) Move (sFileName + "\success(5).bmp") to sFileName 
            Send Add_Item of oGrid1 msg_none ""
            Set Form_Bitmap of oGrid1 (Item_Count(oGrid1(Self))-1) to sFileName
            Set Entry_State of oGrid1 (Item_Count(oGrid1(Self))-1) to False
            Send Add_Item of oGrid1 Msg_None sCaption
            Set Entry_State of oGrid1 (Item_Count(oGrid1(Self))-1) to False
            Send Add_Item of oGrid1 Msg_None sTime
            Set Entry_State of oGrid1 (Item_Count(oGrid1(Self))-1) to False
            Send Add_Item of oGrid1 msg_none i
            Set Entry_State of oGrid1 (Item_Count(oGrid1(Self))-1) to False
        Loop
        Send pAddLabels 0
    End_Procedure

    Procedure activating
        Forward Send activating
        Send pAddRemindersToGrid
//        Set Timer_Active_State of oDFTimer1 to True
    End_Procedure

    Procedure closing_view
        Forward Send closing_view
//        Set Timer_Active_State of oDFTimer1 to False
    End_Procedure
End_Object
