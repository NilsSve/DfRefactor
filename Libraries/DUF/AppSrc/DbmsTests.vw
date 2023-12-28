Use Windows.pkg
Use Dfclient.pkg
Use Cursor.pkg
Use dfSpnFrm.pkg
Use cDbUpdateFunctionLibrary.pkg
Use Working.pkg
Use dfLine.pkg
Use DatabaseSelection.dg
Use ServerSelection.dg

Define CI_Table1_FileNo for 401
Define CI_View1_FileNo  for 402

Activate_View Activate_oDbmsTests for oDbmsTests
Object oDbmsTests is a dbView
    Set Size to 296 441
    Set Location to 2 2
    Set Label to "DBMS Tests - Test of the cDbUpdateFunctionLibrary Library"
    Set pbAutoActivate to True
    Set Border_Style to Border_Thick
    Set pbAcceptDropFiles to True
    Set Maximize_Icon to True

    Object oTabDialog is a TabDialog
        Set Size to 288 429
        Set Location to 3 5
        Set peAnchors to anAll





    End_Object


End_Object
