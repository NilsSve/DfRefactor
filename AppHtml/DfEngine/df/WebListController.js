import { WebModalDialog } from './WebModalDialog.js';
import { WebButton } from './WebButton.js';
import { WebForm } from './WebForm.js';
import { WebPanel } from './WebPanel.js';
import { df } from '../df.js';

/*
Class:
    WebListController

The controller class for the WebList its mini MVC model. Handles actions from the view and the 
server and executes operations like rowchange, refresh and sorting.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
export class WebListController{


constructor(oList, oModel){
    this.oL = oList;
    this.oM = oModel;
    
    this.iRowChangeCount = 0;
    
    this.onCellClick = new df.events.JSHandler();
    this.onCellDblClick = new df.events.JSHandler();
    this.onAfterCellClick = new df.events.JSHandler();

    oList._onKeyDown.addListener(this.keyDown, this);
}

/* 
Handles the click on a cell inside the list. Triggers click events on the column object and changes 
the current row.

@param  oEv             DOM Event object.
@param  sRowId          RowId of the clicked row.
@param  iCol            Column that is clicked.    
@param  bNoRowChange    Whether to not change the row.
*/
cellClick(oEv, sRowId, iCol, bNoRowChange){
    const oL = this.oL, oM = this.oM;
    let iColIndex, sColVal = "";
    
    oL._bHasFocus = true;
    const iRow = oM.rowIndexByRowId(sRowId);
            
    if(iRow >= 0){
        
        if(iCol >= 0){
            iColIndex = oL._aColumns[iCol]._iColIndex;
            sColVal = oM.aData[iRow].aCells[iColIndex].sValue;
        }
        
        //  Notify column of (before)click
        if(iCol >= 0){
            if(oL._aColumns[iCol].cellClickBefore(oEv, sRowId, sColVal)){
                return false;
            }
        }
        
        //  Perform the rowchange
        if (!bNoRowChange)
            this.selectRow("row", iRow);
        
        //  Notify column of (after)click
        if(iCol >= 0){
            if(oL._aColumns[iCol].cellClickAfter(oEv, sRowId, sColVal)){
                oL.focus();
                return false;
            }
        }

        //  Inform other modules of the cell click
        if(this.fireRowClick(sRowId, iCol)){
            return true;
        }
    }
    
    return false;
}

fireRowClick(sRowId, iCol){
   
    //  Inform other modules of the cell click
    this.onCellClick.fire(this, { 
        sRowId : sRowId, 
        iCol : iCol
    });

    //  Fire the actual OnRowClick event
    const bHandled = this.oL.fire("OnRowClick", [ sRowId, iCol !== null ? iCol : -1 ], function(oEv){
        //  Inform other modules of the cell click finish
        this.onAfterCellClick.fire(this, { 
            sRowId : sRowId, 
            iCol : iCol
        });
    }, this);

    return bHandled;
}


/*
Handles the double click on a cell and informs modules of this event.

@param  oEv     DOM Event object.
@param  sRowId  RowId of the clicked row.
@param  iCol    Column that is clicked.  
*/
cellDblClick(oEv, sRowId, iCol){
    //  Inform other modules of the cell double click
    return !this.onCellDblClick.fire(this, { 
        sRowId : sRowId, 
        iCol : iCol
    });
}


/* 
Handles the click on a column header. Triggers the OnHeaderClick event and changes the sorting if 
needed.

@param  oEv     DOM event object.
@param  iCol    Column index.
*/
headClick(oEv, iCol){
    const oL = this.oL, oCol = oL._aColumns[iCol];
    let bRes = false;
    
    if(oCol){
        if(oCol.fire("OnHeaderClick")){
            bRes = true;
        }else{
            if(oL.pbColumnSortable){
                if(oCol.pbSortable){
                    //  Update the sortcolumn property
                    if(oL.piSortColumn === iCol){
                        this.changeSorting(iCol, !oL.pbReverseOrdering);
                    }else{
                        this.changeSorting(iCol, false);
                    }
                    bRes = true;
                }
            }
        }    
    }
    
    oL.focus();
    return bRes;
}

/* 
Handles the double click on a column header. Does nothing (augmented by the designer).

@param  oEv     DOM Event object.
@param  iCol    Column index.
*/
headDblClick(oEv, iCol){
    return false;
}


/*
This method changes the sorting order to the supplied column and direction. It will update 
piSortColumn and pbReverseOrdering properties and send ChangeSorting to the server. The header is 
also updated.

@param  iCol        Column number to sort on.
@param  bReverse    If true the order will be reversed.
*/
changeSorting(iCol, bReverse){
    const oL = this.oL, iPrevCol = oL.piSortColumn, bPrevReverse = oL.pbReverseOrdering;
    
    oL.addSync('piSortColumn');
    oL.addSync('pbReverseOrdering');
    
    oL.piSortColumn = iCol;
    oL.pbReverseOrdering = bReverse;
    
    oL._onSettingChange.fire(this, {
        sType : "sorting"
    });
    
    //  Notify the server for paged data loading
    if(this.oM.bPaged){
        oL.serverAction("ChangeSorting", [ iCol, bReverse, iPrevCol, bPrevReverse ]);
    }
}


/*
Handles the keypress event and will initiate the auto search if needed. The keypress is used because 
we need the character code and are not interested in special keys anyway. 

@param  oEv  The event object.
@private
*/
keyPress(oEv){
    const oL = this.oL;
    
     //  Check enabled state
    if(!oL.isEnabled()){
        return;
    }
    
    //  Auto search
    if(oL.pbAutoSearch && oL.piSortColumn >= 0 && !this.bNoSearch && oL.hasFocus()){
        const iChar = oEv.getCharCode();
        
        //  Check if we where really typing a character (33 is the first sensible character in the ASCII table that should popup the search)
        if(iChar > 32 && !oEv.isSpecialKey()){ // && (iKey === 0 || (iKey > 48 && iKey < 123)) 

            let sChar = String.fromCharCode(oEv.getCharCode());
            
            //  Filter character based on data type (this is done pretty raw)
            if(oL._aColumns[oL.piSortColumn].peDataType === df.ciTypeBCD){
                if(("0123456789,.-").indexOf(sChar) < 0){
                    sChar = "";
                }
            }else if(oL._aColumns[oL.piSortColumn].peDataType === df.ciTypeDate){
                if(("0123456789-").indexOf(sChar) < 0){
                    sChar = "";
                }
            }
            
            //  Display search dialog
            this.showSearch(sChar);
            
            oEv.stop();
            return false;
        }
    }
    
    return true;
}

/*
This function performs an incremental search on the column that the list is currently sorted on. In 
case of a static list (pbDataAware is false or peDbGridType is not gtAutomatic) it will perform the 
search completely on the client and select the row. The search on the client is performed as a 
binary search for optimal performance. If piSortColumn is not set nothing will be done.

@param sSearch   The search string.


@client-action
*/
search(sSearch){
    const oM = this.oM, oL = this.oL, aData = oM.aData;
    let fComp, iLow = 0, iHigh = aData.length - 1, iMid, iRes, iRow = null;
    
    const bRev = oL.pbReverseOrdering;
    const iCol = oL._aColumns[oL.piSortColumn]._iColIndex;
    
    if(iCol < 0){
        return;
    }
    
    if(!this.oM.bPaged){
        //  Determine comparison function
        if(oL._aColumns[iCol].peDataType === df.ciTypeText){
            //  For text we do a case insensitive comparison of the first characters
            fComp = function(sVal1, sVal2){
                sVal1 = sVal1.substr(0, sVal2.length).toLowerCase();
               
                return sVal1.localeCompare(sVal2);
            };
            
            sSearch = sSearch.toLowerCase();
        }else{
            fComp = df.sys.data.compareFunction(oL._aColumns[iCol].peDataType);
        }
        
        //  Debugging
        // var fPrevComp = fComp, iCount = 0;
        // fComp = function(sVal1, sVal2){
            // var iRes = fPrevComp(sVal1, sVal2);
            
            // df.debug("Comparing: sVal1='" + sVal1 + "', sVal2='" + sVal2 + "', iRes=" + iRes + ", iLow=" + iLow + ", iMid=" + iMid + ", iHigh=" + iHigh); 
            
            // iCount++;
            
            // return iRes;
        // };
        
        //  Do a binary search
        while(iLow < iHigh){
            iMid = Math.floor((iLow + iHigh) / 2);
            iRes = fComp(aData[iMid].aCells[iCol].sValue, sSearch);
            iRes = (bRev ? -iRes : iRes);
            
            if(iRes < 0){
                iLow = iMid + 1;
            }else if(iRes > 0){
                iHigh = iMid - 1;
            }else{
                iRow = iMid;
                break;
            }
        }
        
        if(iRes === 0){
            //  We want the first full hit
            if(iRow > 0){
                iRes = fComp(aData[iRow - 1].aCells[iCol].sValue, sSearch);
                iRes = (bRev ? -iRes : iRes);
                
                while(iRes === 0 && iRow > 0){
                    iRow--;
                    if(iRow > 0){
                        iRes = fComp(aData[iRow - 1].aCells[iCol].sValue, sSearch);
                    }
                }
            }
        }else{
            //  If we didn't find a full hit and iMid is outside range we assume that the range is right
            if(iMid < iLow){
                iRow = iLow;
            }else if(iMid > iLow){
                iRow = iHigh;
            }else{
                iRow = iMid;
            }
        }
    
        //  Move to the row
        this.moveToRow(iRow);
    }else{
        //  For automatic data aware grids we send the search action to the server
        oL.serverAction("OnSearch", [ sSearch ]);
    }
}

/*
This function displays the search dialog for doing an incremental search on the list. It creates a 
dialog that has an input form and data settings are based on the current sort column.

@param sOptSearch   The search string.

@client-action
*/
showSearch(sOptSearch){
    const oL = this.oL, iWindowWidth = df.dom.windowWidth(), iCol = oL.piSortColumn;
    
    if(iCol < 0){
        return;
    }
    
    //  Create dialog with panel
    const oDialog = new WebModalDialog(null, oL);
    oDialog.psCaption = oL.getWebApp().getTrans("search") + ": " + oL._aColumns[iCol].psCaption;
    oDialog.pbShowClose = true;
    oDialog.pbDDHotKeys = false;
    oDialog.pbResizable = false;
    oDialog.piMinWidth = (iWindowWidth > 390 ? 370 : iWindowWidth - 20);
    oDialog.psCSSClass = "WebMsgBox";
    
    //  Create input form
    const oContentPnl = new WebPanel(null, oDialog);
    oContentPnl.peRegion = df.ciRegionCenter;

    oDialog.addChild(oContentPnl);

    const oForm = new WebForm(null, oDialog);
    oForm.psLabel = "";
    oForm.pbShowLabel = false;
    oForm.psValue     = sOptSearch || "";
    oForm.peDataType  = oL._aColumns[iCol].peDataType;
    oForm.psMask      = oL._aColumns[iCol].psMask;
    oForm.piPrecision = oL._aColumns[iCol].piPrecision;
    oForm.piMaxLength = oL._aColumns[iCol].piMaxLength;
    oForm.pbCapslock  = oL._aColumns[iCol].pbCapslock;
    oForm.peAlign     = df.ciAlignLeft;

    oContentPnl.addChild(oForm);
    
    // Create close button
    const oButtonPnl = new WebPanel(null, oDialog);
    oButtonPnl.peRegion = df.ciRegionBottom;
    oButtonPnl.piColumnCount = 3;
    oButtonPnl.psCSSClass = "WebMsgBoxOneBtn";

    oDialog.addChild(oButtonPnl);
    
    const oOKBtn = new WebButton(null, oDialog);
    oOKBtn.psCaption = oL.getWebApp().getTrans("ok");
    oOKBtn.piColumnIndex = 1;
    oOKBtn.pbShowLabel = false;
    oOKBtn.OnClick.addListener(function(oEv){
        oDialog.fire('OnSubmit');
    }, this);

    oButtonPnl.addChild(oOKBtn);
    
    const oCancelBtn = new WebButton(null, oDialog);
    oCancelBtn.psCaption = oL.getWebApp().getTrans("cancel");
    oCancelBtn.piColumnIndex = 2;
    oCancelBtn.pbShowLabel = false;
    oCancelBtn.OnClick.addListener(function(oEv){
        oDialog.hide();
    }, this);

    oButtonPnl.addChild(oCancelBtn);
    
    //  Add submit listener
    oDialog.OnSubmit.addListener(function(oEv){
        const sVal = oForm.get("psValue");
        oDialog.hide();
               
        oL.objFocus();
        
        this.search(sVal);
        
        if(oL._eFocus){
            oL._eFocus.focus();
        }
    }, this);
    
    oDialog.show();
    
    //  For date types we explicitly give the focus and set the form value because else it will complete the date before the field when the focus
    if(oForm.peDataType === df.ciTypeDate || oForm.peDataType === df.ciTypeDateTime || oForm.peDataType === df.ciTypeTime){
        oForm.focus();
        if(sOptSearch){
            oForm.setControlValue(sOptSearch);
        }
    }
    if(!df.sys.isMobile){
        df.dom.setCaretPosition(oForm._eControl, oForm._eControl.value.length);
    }
}

/*
This method handles the keypress event and initiates the actions bound to it. The 
df.settings.listKeys define the exact key code's / combinations for the different actions.

@param  oEv  The event object.
@return False if we did handle the event and performed an action, true if we didn't do anything.
*/
keyDown(oJSEvent){
    const oL = this.oL, that = this;
    const oEv = oJSEvent.oDOMEvent;
    
    if(!oL._bHasFocus && !oL._eKeyBuddy){
        return;
    }
    
    if(oEv.matchKey(df.settings.listKeys.scrollUp)){ 
        this.moveUpRow();
    }else if(oEv.matchKey(df.settings.listKeys.scrollDown)){ 
        this.moveDownRow();
    }else if(oEv.matchKey(df.settings.listKeys.scrollPageUp)){ 
        this.movePageUp();
    }else if(oEv.matchKey(df.settings.listKeys.scrollPageDown)){ 
        this.movePageDown();
    }else if(oEv.matchKey(df.settings.listKeys.scrollTop)){ 
        this.moveToFirstRow();
    }else if(oEv.matchKey(df.settings.listKeys.scrollBottom)){ 
        this.moveToLastRow();
    }else if(oEv.matchKey(df.settings.listKeys.leftSwipeBtns) && oL._oTouchHandler && oL._oTouchHandler.showSwipeLeft()){
    }else if(oEv.matchKey(df.settings.listKeys.rightSwipeBtns) && oL._oTouchHandler && oL._oTouchHandler.showSwipeRight()){
     
    }else if(oEv.matchKey(df.settings.formKeys.submit)){ 
        //  The OnRowClick event is also fired on enter and overrides the OnSubmit if it is handled.
        if(this.oM.sCurrentRowId){
            //  Inform other modules of the cell click
            if(this.fireRowClick(this.oM.sCurrentRowId, null)){
                oEv.stop();
                return false;
            }
        }
        return true;
    }else{
        return true;
    }
    
    //  Temporary block search on key press (stopping onKeyDown doesn't cancel onKeyPress in firefox)
    this.bNoSearch = true;
    setTimeout(function(){
        that.bNoSearch = false;
    }, 50);
    
    oEv.stop();
    return false;
}

handleData(listData, sType, sStartRowId, bFirst, bLast){
    this.oM.handleData(listData, sType, sStartRowId, bFirst, bLast);
    
    if(!this.pbDataAware){
        this.updateColumnsFromCache(sType === "page");
    }
}

setCurrentRowId(sRowId){
    this.oM.setCurrentRowId(sRowId);
}

updateRow(sRowId, tRow, bMergeRow){
    this.oM.updateRow(sRowId, tRow, bMergeRow);
}

updateCell(oCol, sVal){
    this.oM.updateCell(oCol, sVal);
}

removeRow(sRowId){
    const oM = this.oM
    let bRowChange = false, iPrevRow;
    
    if(oM.sCurrentRowId === sRowId){
        bRowChange = true;
        iPrevRow = oM.iCurrentRow;
        
        oM.sCurrentRowId = "";
        oM.iCurrentRow = -1;
    }
    
    oM.removeRow(sRowId);
    
    if(bRowChange){
        if(iPrevRow < oM.aData.length){
            this.selectRow("row", iPrevRow);
        }else if(iPrevRow > 0){
            this.selectRow("row", iPrevRow - 1);
        }else{
            this.appendNewRow();
        }
    }
}

appendRow(tRow){
    this.oM.appendRow(tRow);
}

insertBefore(sBeforeRowId, tRow){
    this.oM.insertBefore(sBeforeRowId, tRow);
}

insertAfter(sAfterRowId, tRow){
    this.oM.insertAfter(sAfterRowId, tRow);
}

/*
@param  sGotoRow    String describing the row that will be selected ("new", "first", "last", "row").
@param  iRow        When sGotoRow indicates "row" then this is the cache row number to select.
*/
selectRow(sGotoRow, iRow, fOptHandler, tOptSelectRowData){
    const oL = this.oL, oM = this.oM, sPrevRowId = oM.sCurrentRowId;
    let bContinue = true, sTargetRowId = "", tSelectRowData = tOptSelectRowData || null;
    
    
    
    //  Make sure there are no outstanding ChangeCurrentRow calls
    oL.cancelServerAction("ChangeCurrentRow");
    
    //  Determine if row change is needed & translate specific row nr into rowid
    if(sGotoRow === "row"){
        sTargetRowId = oM.rowIdByRowIndex(iRow);
        bContinue = (sTargetRowId !== null && sTargetRowId !== sPrevRowId);
        
        //  For non data-aware grids / lists we send a copy of the row we are going to as action data to the server
        if(!oL.pbDataAware){
            tSelectRowData = oM.aData[iRow];
        }
    }
    
    const oOptions = {
        sPrevRowId : oM.sCurrentRowId,
        iPrevRowIndex : oM.iCurrentRow,
        sGotoRow : sTargetRowId,
        iGotoRowIndex : iRow
    };
    
    //  Update counter and remember number in local variable
    this.iRowChangeCount++;
    const iRowChange = this.iRowChangeCount;
    
    function handleRowChange(bResult){
        //  Check if row change is overtaken by another row change
        var bOverridden = (iRowChange !== this.iRowChangeCount);
        
        oOptions.bSuccess = df.toBool(bResult);
        oM.onAfterRowChange.fire(oM, oOptions);
        
        if(oL.pbOfflineEditing || df.toBool(bResult)){
            //  We do this so that handlers that scroll the screen are executed before we add the class
            if(fOptHandler){
                fOptHandler.call(this, true, bOverridden);
            }
        }else{
            fOptHandler.call(this, false, bOverridden);
        }
    }
    
    if(bContinue){
        oM.onBeforeRowChange.fire(oM, oOptions);
        
        if(!oL.pbOfflineEditing){
            //  Set handler function so it can be called as client-action
            this.handleRowChange = handleRowChange;
            oL.serverAction("ChangeCurrentRow", [ sGotoRow, sTargetRowId ], (tSelectRowData && oL.serializeRows([ tSelectRowData ])) || null);
        }else{
            //  When working offline we manually load the row into the columns and set it as current
            if(sGotoRow === "row"){
                this.setCurrentRowId(sTargetRowId);
                
                this.updateColumnsFromCache(true);
            }
                        
            handleRowChange.call(this);
        }
    }else{
        if(fOptHandler){
            fOptHandler.call(this, false);
        }
    }
}

/* 
This function is called from the server after a rowchange initiated by the client. It is replaced at 
runtime with a function inside a closure holding the context needed to handle the rowchange.

@param  bResult     True if the rowchange is succesfull. 
*/
handleRowChange(bResult){
    //  Empty placeholder
}

/*
This method updates the column DEO objects with the data in the cache for the current row. It does 
nothing if pbNonDataAware is false. It will reset the changed-states if bResetChange is true.

@param  bResetChange    If true the changed-state is reset.
@private
*/
updateColumnsFromCache(bResetChange){
    const oL = this.oL, oM = this.oM;
    
    //  Update the column value's
    if(!oL.pbDataAware){
        const iRow = oM.rowIndexByRowId(oM.sCurrentRowId);
        
        if(iRow >= 0){
            for(let iCol = 0; iCol < oL._aColumns.length; iCol++){
                oL._aColumns[iCol].set('psValue', oM.aData[iRow].aCells[oL._aColumns[iCol]._iColIndex].sValue);
                if(bResetChange){
                    oL._aColumns[iCol].set('pbChanged', false);
                }
            }
        }
    }
}

triggerCacheUpdate(iTopRow, iLastRow){
    const oM = this.oM;
    
    if(oM.bPaged){
        if(!oM.bLast){
            if(oM.aData.length - iLastRow < oM.iPrefCacheOffset){
                this.loadCachePage("next");
            }
        }
        if(!oM.bFirst){
            // df.debug("iTopRow: " + iTopRow + " < oM.iPrefCacheOffset: " + oM.iPrefCacheOffset);
            if(iTopRow < oM.iPrefCacheOffset ){
                this.loadCachePage("prev");
            }
        }
    }
}


loadCachePage(sType, fOptHandler, oOptEnv){
    const oL = this.oL, oM = this.oM;
    let sStartRowId = "";
    
    if(this.bLoading){
        return;
    }
    this.bLoading = true;
    
     // Determine start rowid
    if(sType === "next"){
        if(oM.aData.length){
            sStartRowId = oM.aData[oM.aData.length - 1].sRowId;
        }
    }else if(sType === "prev"){
        if(oM.aData.length){
            sStartRowId = oM.aData[0].sRowId;
        }
    }else{
        this._bNoRender = true;
    }
    
    // Create action
    oL.serverAction("LoadDataPage", [ sType, sStartRowId ], null, function(oEv){
        this.bLoading = false;
        
        if(!oEv.bError){
            if(fOptHandler){
                fOptHandler.call(oOptEnv || this);
            }
        }
    }, this);
}

/*
@client-action
*/
processDataSet(eOperation){
    const oM = this.oM, oL = this.oL;

    oL.serverAction("HandleProcessDataSet", [ eOperation, oM.iCurrentRow ], oL.serializeRows(oM.aData));
}

/*
Scrolls to the first record and selects it. It is called by the keyboard handler or from the server. 
In case of a static grid it will directly call the selectRow function to select the first row, for a 
non-static grid (pbDataAware is true or peDbGridType is not gtAutomatic) it will always refresh the 
cache by loading the first page of records. Note that when pbOfflineEditing is true we need to load 
the first cache page before changing rows.

@client-action
*/
moveToFirstRow(){
    const oM = this.oM, oL = this.oL;
    
    const fSelect = function(){
        if(oM.aData.length > 0){
            this.selectRow("row", 0);
        }else{
            this.appendNewRow();
        }        
    };
    
    if(!oM.bPaged){
        fSelect.call(this);
    }else{
        if(oL.pbOfflineEditing || (oM.iCurrentRow === 0 && oM.sCurrentRowId === "")){
            this.loadCachePage("first", function(){
                fSelect.call(this);
            });
        }else{
            this.selectRow("first", -1);
        }
    }
}

/*
Scrolls to the last record and selects it. It is called by the keyboard handler or from the server. 
In case of a static grid it will directly call the selectRow function to select the last row, for a 
non-static grid (pbDataAware is true or peDbGridType is not gtAutomatic) it will always refresh the 
cache by loading the last page of records. Note that when pbOfflineEditing is true we need to load 
the last cache page before changing rows.

@client-action
*/
moveToLastRow(){
    const oM = this.oM, oL = this.oL;
    
    const fSelect = function(){
        if(oM.aData.length > 0){
            this.selectRow("row", oM.aData.length - 1);
        }else{
            this.appendNewRow();
        }   
    };
    
    if(!oM.bPaged){
        fSelect.call(this);
    }else{
        if(oL.pbOfflineEditing || (oM.iCurrentRow === 0 && oM.sCurrentRowId === "")){
            this.loadCachePage("last", function(){
                fSelect.call(this);
            });
        }else{
            this.selectRow("last", -1);
        }
    }
}

/*
This method selects the next row available in the cache and returns true if successful. It is called 
by the key handler or the server.

@return True if a next row is available.
@client-action
*/
moveDownRow(){
    const oM = this.oM;
    
    if(oM.iCurrentRow >= 0 && oM.iCurrentRow < oM.aData.length - 1){
        this.selectRow("row", (oM.iCurrentRow + 1));
        
        return true;
    }
    
    return false;
}

/*
This method selects the previous row available in the cache and returns true if successful. It is 
called by the key handler or the server.

@return True if a previous row is available.
@client-action
*/
moveUpRow(){
    const oM = this.oM;

    if(oM.iCurrentRow > 0){
        this.selectRow("row", (oM.iCurrentRow - 1));
    }
}

/*
This method performs a page down which means that it select the record one page down in the cache 
and scrolls to it. A page in this context means the amount of rows that fit inside the grid view. It 
is called by the key handler or the server.

@client-action
*/
movePageDown(){
    const oM = this.oM;
    
    let iRow = Math.round(oM.iCurrentRow + this.oL._oBody.getViewSize() - 1);
    if(iRow >= oM.aData.length){
        iRow = oM.aData.length - 1;
    }
    
    this.selectRow("row", iRow);
}

/*
This method performs a page up which means that it select the record one page up in the cache and 
scrolls to it. A page in this context means the amount of rows that fit inside the grid view. It is 
called by the key handler or the server.

@client-action
*/
movePageUp(){
    const oM = this.oM;
    
    let iRow = Math.round(oM.iCurrentRow - this.oL._oBody.getViewSize() + 1);
    if(iRow < 0){
        iRow = 0;
    }
    
    this.selectRow("row", iRow);
}

/*
This method moves to a specific row based on its row index.

@client-action
*/
moveToRow(iRowIndex){
    //  Since this method can be called from the server the parameter might still be a string
    iRowIndex = parseInt(iRowIndex, 10);

    if(iRowIndex >= 0 && iRowIndex < this.oM.aData.length){
        this.selectRow("row", iRowIndex);
    }
}

/*
This method moves to a specific row based on its unique row ID.

@client-action
*/
moveToRowByID(sRowId){
    const iRowIndex = this.oM.rowIndexByRowId(sRowId);
    
    if(iRowIndex >= 0){
        this.moveToRow(iRowIndex);
    }
}

appendNewRow(){
    
}

}