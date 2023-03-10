//TH-Header
//*****************************************************************************************
// Copyright (c)  2014  KURANT Project
// All rights reserved.
//
// $FileName    : Classes_and_properties.vw
// $ProjectName : The Hammer 2.0
// $Authors     : Wil van Antwerpen, Michael Kurz, Sergey V. Natarov
// $Created     : 01.25.2014  01:08
// $Type        : LGPL
//
// Contents: Classes and properties
//
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

// Project Object Structure
//   Classes_and_properties is a dbView
//     Vdfcls_DD is a DataDictionary
//     Vdfprop_DD is a DataDictionary
//     Container1 is a dbContainer3d
//       Vdfcls_Name is a dbForm
//       Vdfcls_Parent is a dbForm
//       dbEdit1 is a dbEdit
//       Vdfcls_Code is a dbForm
//       Form1 is a Form
//       Textbox1 is a Textbox
//       Vdfcls_Mixin1 is a dbForm
//       Vdfcls_Mixin2 is a dbForm
//       Vdfcls_Mixin3 is a dbForm
//       Vdfcls_Mixin4 is a dbForm
//       Vdfcls_Mixin5 is a dbForm
//       Vdfcls_Mixin6 is a dbForm
//       Vdfcls_Mixin7 is a dbForm
//       Vdfcls_Mixin8 is a dbForm
//       Vdfcls_Mixin9 is a dbForm
//       Vdfcls_Mixin10 is a dbForm
//       Vdfcls_Mixin11 is a dbForm
//       Vdfcls_Mixin12 is a dbForm
//       Vdfcls_Mixin13 is a dbForm
//       Vdfcls_Mixin14 is a dbForm
//       Vdfcls_Mixin15 is a dbForm
//       Vdfcls_Bitmap is a dbForm
//       Vdfcls_Type is a dbComboForm
//       Vdfcls_Base is a dbCheckBox
//     The_Table is a dbGrid
//     Vdfprop_Getcode is a dbForm
//     Vdfprop_Setcode is a dbForm
//     dbEdit2 is a dbEdit

// Register all objects
Register_Object Classes_and_properties
Register_Object Container1
Register_Object dbEdit1
Register_Object dbEdit2
Register_Object Form1
Register_Object Textbox1
Register_Object The_Table
Register_Object Vdfcls_Base
Register_Object Vdfcls_Bitmap
Register_Object Vdfcls_Code
Register_Object Vdfcls_DD
Register_Object Vdfcls_Mixin1
Register_Object Vdfcls_Mixin10
Register_Object Vdfcls_Mixin11
Register_Object Vdfcls_Mixin12
Register_Object Vdfcls_Mixin13
Register_Object Vdfcls_Mixin14
Register_Object Vdfcls_Mixin15
Register_Object Vdfcls_Mixin2
Register_Object Vdfcls_Mixin3
Register_Object Vdfcls_Mixin4
Register_Object Vdfcls_Mixin5
Register_Object Vdfcls_Mixin6
Register_Object Vdfcls_Mixin7
Register_Object Vdfcls_Mixin8
Register_Object Vdfcls_Mixin9
Register_Object Vdfcls_Name
Register_Object Vdfcls_Parent
Register_Object Vdfcls_Type
Register_Object Vdfprop_DD
Register_Object Vdfprop_Getcode
Register_Object Vdfprop_Setcode




Use parents.sl
// **WvA
Use VDFPRNT.DD



Use VDFCLS.DD
Use VDFPROP.DD


ACTIVATE_VIEW Activate_Classes_and_properties FOR Classes_and_properties

Object Classes_and_properties is a dbView
    Set Label to "Classes and properties"
    Set Size to 265 510
    Set Location to 2 9
    Set Border_Style to Border_Thick
    Set Maximize_Icon to True
    Set piMinSize to 265 510


    Object Vdfcls_DD is a Vdfcls_DataDictionary
    End_Object    // Vdfcls_DD

    Object Vdfprop_DD is a Vdfprop_DataDictionary
        Set DDO_Server to (Vdfcls_DD(self))
        Set Constrain_File to Vdfcls.File_Number
    End_Object    // Vdfprop_DD

    Set Main_DD to (Vdfcls_DD(self))
    Set Server to (Vdfcls_DD(self))


    Object Container1 is a dbContainer3d
        Set Size to 97 501
        Set Location to 5 5
        Set peAnchors to anTopLeftRight
        Object Vdfcls_Name is a dbForm
            Entry_Item Vdfcls.Name
            Set Label to "Class Name:"
            Set Size to 13 244
            Set Location to 4 65
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to jMode_Right
            Set peAnchors to anTopLeftRight
        End_Object    // Vdfcls_Name

        Object Vdfcls_Parent is a dbForm
            Entry_Item Vdfcls.Parent
            Set Label to "Derivative from:"
            Set Size to 13 52
            Set Location to 21 65
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to jMode_Right
            Set Prompt_Button_Mode to pb_PromptOn


            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure

            Procedure Entry_Display integer i1 integer i2
                Forward send entry_display i1 i2
                Send Update_Value to Form1 (Value(Self,0))
            End_Procedure

            Procedure OnChange
                Send Update_Value to Form1 (Value(Self,0))
            End_Procedure

        End_Object    // Vdfcls_Parent

        Object dbEdit1 is a dbEdit
            Entry_Item Vdfcls.Descr
            Set Size to 31 289
            Set Location to 38 65
            Set peAnchors to anAll
        End_Object    // dbEdit1

        Object Vdfcls_Code is a dbForm

            Set Object_Shadow_State To True

            Entry_Item Vdfcls.Code
            Set Size to 13 39
            Set Location to 4 314
            Set peAnchors to anBottomRight



        End_Object    // Vdfcls_Code

        Object Form1 is a Form

            Set Enabled_State to False

            Set Size to 13 233
            Set Location to 21 120
            Set peAnchors to anTopLeftRight

            // *WvA: Is already opened by the use VDFPRNT.DD in the topcode of the program
            //Open VDFPRNT

            Procedure Update_Value integer iCode
                Clear VDFPRNT
                Move iCode to VDFPRNT.CODE
                Find EQ VDFPRNT by index.3
                If (found) Set Value item 0 to VDFPRNT.NAME
                Else Set Value item 0 to "*Unknown *"
            End_Procedure


        End_Object    // Form1

        Object Textbox1 is a Textbox
            Set Label to "Mixin Classes:"
            Set Location to 6 365
            Set Size to 10 45
            Set TypeFace to "MS Sans Serif"
            Set peAnchors to anTopRight
        End_Object    // Textbox1

        Object Vdfcls_Mixin1 is a dbForm
            Entry_Item Vdfcls.Mixin1
            Set Size to 13 36
            Set Location to 21 365
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight


            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin1

        Object Vdfcls_Mixin2 is a dbForm
            Entry_Item Vdfcls.Mixin2
            Set Size to 13 36
            Set Location to 34 365
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin2

        Object Vdfcls_Mixin3 is a dbForm
            Entry_Item Vdfcls.Mixin3
            Set Size to 13 36
            Set Location to 47 365
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin3

        Object Vdfcls_Mixin4 is a dbForm
            Entry_Item Vdfcls.Mixin4
            Set Size to 13 36
            Set Location to 60 365
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin4

        Object Vdfcls_Mixin5 is a dbForm
            Entry_Item Vdfcls.Mixin5
            Set Size to 13 36
            Set Location to 73 365
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin5

        Object Vdfcls_Mixin6 is a dbForm
            Entry_Item Vdfcls.Mixin6
            Set Size to 13 36
            Set Location to 21 407
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight


            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin6

        Object Vdfcls_Mixin7 is a dbForm
            Entry_Item Vdfcls.Mixin7
            Set Size to 13 36
            Set Location to 34 407
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin7

        Object Vdfcls_Mixin8 is a dbForm
            Entry_Item Vdfcls.Mixin8
            Set Size to 13 36
            Set Location to 47 407
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin8

        Object Vdfcls_Mixin9 is a dbForm
            Entry_Item Vdfcls.Mixin9
            Set Size to 13 36
            Set Location to 60 407
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin9

        Object Vdfcls_Mixin10 is a dbForm
            Entry_Item Vdfcls.Mixin10
            Set Size to 13 36
            Set Location to 73 407
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin10

        Object Vdfcls_Mixin11 is a dbForm
            Entry_Item Vdfcls.Mixin11
            Set Size to 13 36
            Set Location to 21 450
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight


            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin11

        Object Vdfcls_Mixin12 is a dbForm
            Entry_Item Vdfcls.Mixin12
            Set Size to 13 36
            Set Location to 34 450
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin12

        Object Vdfcls_Mixin13 is a dbForm
            Entry_Item Vdfcls.Mixin13
            Set Size to 13 36
            Set Location to 47 450
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin13

        Object Vdfcls_Mixin14 is a dbForm
            Entry_Item Vdfcls.Mixin14
            Set Size to 13 36
            Set Location to 60 450
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin14

        Object Vdfcls_Mixin15 is a dbForm
            Entry_Item Vdfcls.Mixin15
            Set Size to 13 36
            Set Location to 73 450
            Set Prompt_Button_Mode to pb_PromptOn
            Set peAnchors to anTopRight




            Procedure Prompt
                Send Popup To (oPL(Self))
            End_Procedure



        End_Object    // Vdfcls_Mixin15

        Object Vdfcls_Bitmap is a dbForm
            Entry_Item Vdfcls.Bitmap
            Set Label to "Bitmap:"
            Set Size to 13 89
            Set Location to 72 65
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to jMode_Right
            Set peAnchors to anBottomLeftRight
        End_Object    // Vdfcls_Bitmap

        Object Vdfcls_Type is a dbComboForm
            Entry_Item Vdfcls.Type
            Set Label to "Type:"
            Set Size to 13 79
            Set Location to 72 178
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to jMode_Right
            Set peAnchors to anBottomRight
        End_Object    // Vdfcls_Type

        Object Vdfcls_Base is a dbCheckBox
            Entry_Item Vdfcls.Base
            Set Label to "For using in applications"
            Set Size to 10 92
            Set Location to 74 265
            Set peAnchors to anBottomRight
        End_Object    // Vdfcls_Base

    End_Object    // Container1

    Object The_Table is a dbGrid
        Set Main_File to Vdfprop.File_Number
        Set Server to (Vdfprop_DD(self))
        Set Ordering to 1
        Set Size to 92 501
        Set Location to 106 5
        Set Wrap_State to True
        Set peResizeColumn to rcAll

        Begin_Row
            Entry_Item Vdfprop.Type
            Entry_Item Vdfprop.Name
            Entry_Item Vdfprop.Descr
            Entry_Item Vdfprop.Getcode
            Entry_Item Vdfprop.Setcode
            Entry_Item Vdfprop.Par1t
            Entry_Item Vdfprop.Par1
            Entry_Item Vdfprop.Par2t
            Entry_Item Vdfprop.Par2
            Entry_Item Vdfprop.Par3t
            Entry_Item Vdfprop.Par3
        End_Row

        Set Form_Width    item 0 to 12
        Set Header_Label  item 0 to "Type"

        Set Form_Width    item 1 to 91
        Set Header_Label  item 1 to "Name"

        Set Form_Width    item 2 to 39
        Set Header_Label  item 2 to "Descr"

        Set Form_Width    item 3 to 36
        Set Header_Label  item 3 to "Getcode"

        Set Form_Width    item 4 to 119
        Set Header_Label  item 4 to "Setcode"

        Set Form_Width    item 5 to 12
        Set Header_Label  item 5 to "Par1t"

        Set Form_Width    item 6 to 55
        Set Header_Label  item 6 to "Par1"

        Set Form_Width    item 7 to 12
        Set Header_Label  item 7 to "Par2t"

        Set Form_Width    item 8 to 55
        Set Header_Label  item 8 to "Par2"

        Set Form_Width    item 9 to 12
        Set Header_Label  item 9 to "Par3t"

        Set Form_Width    item 10 to 53
        Set Header_Label  item 10 to "Par3"
        Set peAnchors to anAll

    End_Object    // The_Table

    Object Vdfprop_Getcode is a dbForm

        Set Object_Shadow_State To True

        Entry_Item Vdfprop.Getcode
        Set Server to (Vdfprop_DD(self))
        Set Label to "Getcode:"
        Set Size to 13 331
        Set Location to 230 65
        Set peAnchors to anBottomLeftRight



    End_Object    // Vdfprop_Getcode

    Object Vdfprop_Setcode is a dbForm

        Set Object_Shadow_State To True

        Entry_Item Vdfprop.Setcode
        Set Server to (Vdfprop_DD(self))
        Set Label to "Setcode:"
        Set Size to 13 331
        Set Location to 246 65
        Set peAnchors to anBottomLeftRight



    End_Object    // Vdfprop_Setcode

    Object dbEdit2 is a dbEdit

        Set Object_Shadow_State To True

        Entry_Item Vdfprop.Descr
        Set Server to (Vdfprop_DD(self))
        Set Size to 25 501
        Set Location to 201 5
        Set peAnchors to anBottomLeftRight



    End_Object    // dbEdit2

End_Object    // Classes_and_properties




