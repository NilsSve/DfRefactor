import { WebListController } from './WebListController.js';
import { df } from '../df.js';
/*
Class:
    WebGridController
Extends:
    WebListController

Extends the controller class of the WebList with grid functionality. It handles changes of the 
current column, inserting and appending new rows and has special logic for syncing the column values 
with the buffer.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
export class WebGridController extends WebListController{

constructor(oList, oModel){
    super(oList, oModel);
    
    this.iChangeToCol = null;
    this.bNewRow = false;
    this.tNewRow = null;
    
    this.iNewCount = 0;
}

/* 
Augments the selectRow with logic for new rows, column changes and it stores the newly selected row 
data (for clear).
*/
selectRow(sGotoRow, iRow, fOptHandler, tOptSelectRowData){
    const oL = this.oL, oV = this.oL._oBody || {};
    
    if(!oL.pbDataAware){
        this.updateCacheFromColumns();
    }
    
    /*
    DF201 - WebGrid OnChange bug.
    If a column is in edit mode and we use validate to check the columns and save changes if we tab to the next.
    This wasn't done when using the arrow keys.
    */
    if (oV.oEditCol && oV.oEditCol.validate) {
        // Check if the new value !== the original value with empty new rows.
        if (oV.oEditCol.get("pbChanged") && !oV.oEditCol.validate()) {
            return false; // cancel the row move.
        }
    }

    super.selectRow(sGotoRow, iRow, function(bSuccess, bOverridden){
        var oM = this.oM, iNewRow, iPrevCol;
        
        //  Apply col change if still planned
        if(this.iChangeToCol !== null && this.iChangeToCol !== oM.iCurrentColumn){
            iPrevCol = oM.iCurrentColumn;
            oM.iCurrentColumn = this.iChangeToCol;
            
            oM.onColChange.fire(this, {
                bRowChange : bSuccess,          //  If the row change was not 'succesfull' we are not inside a row change and the views should just update
                iGotoCol : this.iChangeToCol,
                iPrevCol : iPrevCol
            });
        }
        this.iChangeToCol = null;
        
        
        if(bSuccess && oM.aData[iRow]){
            //  Store orrigional values for clearing
            this.tOrigRow = df.sys.json.parse(df.sys.json.stringify(oM.aData[iRow]));
        }
        
        //  Remove new row if it wasn't changed (didn't get a rowid)
        if(bSuccess && this.bNewRow){
            iNewRow = oM.rowIndexByRowId("");
            if(iNewRow >= 0){
                oM.aData.splice(iNewRow, 1);
                oM.prepDisplay();
                //    Refind current row
                oM.iCurrentRow = oM.rowIndexByRowId(oM.sCurrentRowId);
                oM.onDataUpdate.fire(this, {
                    sType :"remrow",
                    sRowId : "",
                    iRowIndex : iNewRow
                });
            }
            
            this.bNewRow = false;
        }
        
        if(fOptHandler){
            fOptHandler.call(this, bSuccess, bOverridden);
        }
    }, tOptSelectRowData);
}

/* 
Augments processDataSet and makes sure update the data in the buffer with the column values.
*/
processDataSet(eOperation){
    this.updateCacheFromColumns();
    
    super.processDataSet( eOperation);
}

/*
This method writes back the changes made in the column DEO's to the cache. This is only done when 
pbNonDataAware is true and the column DEO's have been filled from the cache before.

@private
*/
updateCacheFromColumns(){
    const oM = this.oM, oL = this.oL, iRow = oM.iCurrentRow;
    let tUpdateRow = null, bChanged = false;

    //  Update the column value's
    if(!oL.pbDataAware){
        if(iRow >= 0){
            for(let iCol = 0; iCol < oL._aColumns.length; iCol++){
                const oCol = oL._aColumns[iCol];
                if(oCol.get('pbChanged')){
                    if(!tUpdateRow){
                        tUpdateRow = JSON.parse(JSON.stringify(oM.aData[iRow]));
                    }
                    
                    const sVal = oCol.get('psValue');
                    bChanged = bChanged || tUpdateRow.aCells[oCol._iColIndex].sValue !== sVal;
                    tUpdateRow.aCells[oCol._iColIndex].sValue = sVal;
                }
            }
            
            //  If this is a new row and values have been changed then we generate a 'unique' id
            if(tUpdateRow && (bChanged || tUpdateRow.sRowId === "")){
                if(tUpdateRow.sRowId === ""){
                    tUpdateRow.sRowId = "new_" + (this.iNewCount++);
                }
                oM.updateRow(oM.sCurrentRowId, tUpdateRow);
            }
        }
    }
}

updateRow(sRowId, tRow, bMergeRow){
    if(this.bNewRow && sRowId === "" && tRow.sRowId === ""){
        tRow.sRowId = "new_" + (this.iNewCount++);
    }
    
    super.updateRow( sRowId, tRow, bMergeRow);
}

updateCell(oCol, sVal){
    if(this.tNewRow && this.oM.sCurrentRowId === ""){
        //  Update the new row waiting to be inserted
        this.tNewRow.aCells[oCol._iColIndex].sValue = sVal;
    }else{
        super.updateCell( oCol, sVal);
    }
    
}

handleData(aRows, sType, sStartRowId, bFirst, bLast){
    super.handleData(aRows, sType, sStartRowId, bFirst, bLast);
    
    if(this.oM.aData.length === 0){
        this.appendNewRow();
    }
}

createNewRow(){
    const oL = this.oL;
    
    const tNewRow = {
        sRowId : "",
        sCssClassName : "",
        aCells : [],
        iGroupHeaderIndex : -1
    };
    
    for(let i = 0; i < oL._aColumns.length; i++){
        tNewRow.aCells[oL._aColumns[i]._iColIndex] = { 
            sValue : ( oL._aColumns[i].peDataType === df.ciTypeBCD ? "0" : "" ),
            sTooltip : "",
            sCssClassName : "",
            aOptions : []
        };
    }
    
    return tNewRow;
}

/*
This method appends a new row at the end of the grid if pbAllowAppendRow is true.

@return True if append is allowed.
@client-action
*/
appendNewRow(){
    const oL = this.oL, oM = this.oM
    let tNewRow;
    
    if(oL.pbAllowAppendRow){
        this.tNewRow = tNewRow = this.createNewRow();
        
        this.selectRow("new", -1, function(bSuccess, bOverridden){
            if(bSuccess){
                this.bNewRow = true;
                oM.aData.push(tNewRow);
                if(oM.sCurrentRowId !== tNewRow.sRowId){
                    this.setCurrentRowId(tNewRow.sRowId);
                }else{
                    oM.iCurrentRow = oM.rowIndexByRowId(tNewRow.sRowId);
                }
                oM.prepDisplay();
                oM.onDataUpdate.fire(this, {
                    sType : "newrow",
                    sRowId : tNewRow.sRowId,
                    iRowIndex : oM.aData.length - 1
                });
                
                if(oL.pbOfflineEditing){
                    this.updateColumnsFromCache(true);
                }
            }
            
            this.tNewRow = null;
        }, (!oL.pbDataAware ? tNewRow : null));
        return true;
    }
    return false;
}

/*
This method inserts a new row above the currently selected row. If inserting a new row is not 
allowed (pbAllowInsertRow) it will try to append a new row (at the end of the grid).

@return True if insert or append is allowed.
@client-action
*/
insertNewRow(){
    const oL = this.oL, oM = this.oM, iRow = oM.iCurrentRow;
    let tNewRow;
    
    if(oL.pbAllowInsertRow){
        this.tNewRow = tNewRow = this.createNewRow();
        
        this.selectRow("new", -1, function(bSuccess, bOverridden){
            if(bSuccess){
                this.bNewRow = true;
                
                oM.aData.splice(iRow, 0, tNewRow);
                
                if(oM.sCurrentRowId !== tNewRow.sRowId){
                    this.setCurrentRowId(tNewRow.sRowId);
                }else{
                    oM.iCurrentRow = oM.rowIndexByRowId(tNewRow.sRowId);
                }
                oM.prepDisplay();
                oM.onDataUpdate.fire(this, {
                    sType : "newrow",
                    sRowId : tNewRow.sRowId,
                    iRowIndex : oM.iCurrentRow
                });
                
                if(oL.pbOfflineEditing){
                    this.updateColumnsFromCache(true);
                }
                
                this.tNewRow = null;
            }
        }, (!oL.pbDataAware ? tNewRow : null));
        return true;
    }
    
    return this.appendNewRow();
}

/* 
Imitates a clearRow for a non data aware grid where it basically goes back to the orrigional row in 
the buffer. Only works for the currently selected row.

@param  sRowId  The rowid to clear.
*/
clearRow(sRowId){
    const oM = this.oM, oL = this.oL;
    let oCol;

    if(sRowId === oM.sCurrentRowId){
        const iRow = oM.iCurrentRow;
            
        if(iRow >= 0){
            for(let iCol = 0; iCol < oL._aColumns.length; iCol++){
                oCol = oL._aColumns[iCol];
                if(oCol.get('pbChanged')){
                    oCol.set('psValue', (this.tOrigRow && this.tOrigRow.aCells[oCol._iColIndex].sValue) || "");
                    oCol.set('pbChanged', false);
                }
            }
        }
    }
}


setCurrentRowId(sRowId){
    const oM = this.oM;
    
    //  Apply col change if planned
    if(sRowId !== oM.sCurrentRowId && this.iChangeToCol !== null && this.iChangeToCol !== oM.iCurrentColumn){
        const iPrevCol = oM.iCurrentColumn;
        oM.iCurrentColumn = this.iChangeToCol;
        
        oM.onColChange.fire(this, {
            bRowChange : true,
            iGotoCol : this.iChangeToCol,
            iPrevCol : iPrevCol
        });
        
        this.iChangeToCol = null;
    }
    
    super.setCurrentRowId( sRowId);
}

cellClick(oEv, sRowId, iCol){
    const oM = this.oM, oL = this.oL;
    
    if(iCol >= 0 && iCol !== oM.iCurrentColumn &&
        oL._aColumns[iCol].pbEditable){
        this.iChangeToCol = iCol;
    }
    if(sRowId === "empty"){
        this.appendNewRow();
    }
    
    super.cellClick( oEv, sRowId, iCol);
}


/*
This method selects the previous column that is enabled and visible. If the first column is selected 
it moves to the previous row.

@client-action
*/
prevCol(){
    const oM = this.oM, oL = this.oL;
    let iCol, bPrevRow = false;
    
    //  Determine next available column
    iCol = oM.iCurrentColumn;

    for (let i = 0; i < oL._aColumnMapper.length; i++) {
        if (oL._aColumnMapper[i]._iCol === iCol) {
            iCol = i;
            break;
        }
    }

    do{
        iCol--;
        //  If we get passed the first column we move to the previous row
        if(iCol < 0){
            if(bPrevRow){
                break;
            }
            bPrevRow = true;
            iCol = oL._aColumnMapper.length - 1;
        }
    }while(!oL._aColumnMapper[iCol].isEnabled() || !oL._aColumnMapper[iCol].pbEditable || !oL._aColumnMapper[iCol].pbRender || oL._aColumnMapper[iCol].pbHidden || !oL._aColumnMapper[iCol].pbVisible);
    
    iCol = oL._aColumnMapper[iCol]._iCol;
    
    if(bPrevRow){
        if(oM.iCurrentRow > 0){
            this.iChangeToCol = iCol;
            this.selectRow("row", (oM.iCurrentRow - 1));
            
            return true;
        }
    }else if(iCol !== oM.iCurrentColumn){
        const iPrevCol = oM.iCurrentColumn;
        oM.iCurrentColumn = iCol;
        
        oM.onColChange.fire(this, {
            bRowChange : bPrevRow,
            iGotoCol : iCol,
            iPrevCol : iPrevCol
        });
        
        return true;
    }

    
    return false;
}

/*
This method selects the next column that is enabled and visible. If the last column is selected it 
moves to the next row.

@client-action
*/
nextCol(){
    const oL = this.oL, oM = this.oM;
    let iCol, bNextRow;
    
    //  Determine next available column
    iCol = oM.iCurrentColumn;

    for (let i = 0; i < oL._aColumnMapper.length; i++) {
        if (oL._aColumnMapper[i]._iCol === iCol) {
            iCol = i;
            break;
        }
    }

    if(!oL._aColumnMapper[iCol].isEnabled() || (oL._aColumnMapper[iCol].validate && oL._aColumnMapper[iCol].validate())){
    
        do{
            iCol++;
            //  If we get passed the first column we move to the next row
            if(iCol >= oL._aColumnMapper.length){
                if(bNextRow){
                    break;
                }
                bNextRow = true;
                iCol = 0;
            }
        }while(!oL._aColumnMapper[iCol].isEnabled() || !oL._aColumnMapper[iCol].pbEditable || !oL._aColumnMapper[iCol].pbRender || oL._aColumnMapper[iCol].pbHidden || !oL._aColumnMapper[iCol].pbVisible);
        
        iCol = oL._aColumnMapper[iCol]._iCol;

        if(bNextRow){
            this.iChangeToCol = iCol;
            
            if(oM.iCurrentRow < oM.aData.length - 1){
                this.selectRow("row", oM.iCurrentRow + 1);
                
                return true;
            }else{
                return this.appendNewRow();
            }
        }else if(iCol !== oM.iCurrentColumn){
            const iPrevCol = oM.iCurrentColumn;
            oM.iCurrentColumn = iCol;
            
            oM.onColChange.fire(this, {
                bRowChange : false,
                iGotoCol : iCol,
                iPrevCol : iPrevCol
            });
            
            return true;
        }
    }
    
    return true;
}

/*
This method selects a specific column. 

@param  iCol    The index of the column to select.
@client-action
*/
selectCol(iCol){
    const oM = this.oM, oL = this.oL;
    
    if(iCol >= 0 && iCol < oL._aColumns.length && oL._aColumns[iCol].pbRender){
        const iPrevCol = oM.iCurrentColumn;
        oM.iCurrentColumn = iCol;
        
        oM.onColChange.fire(this, {
            bRowChange : false,
            iGotoCol : iCol,
            iPrevCol : iPrevCol
        });
    }
}

/*
This method augments the WebList onKeyDown method with the next & previous column functionality. 

@param  oEv  The event object.
@return False if we did handle the event and performed an action, true if we didn't do anything.
@private
*/
keyDown(oJSEvent){
    const oEv = oJSEvent.oDOMEvent;

    if(oEv.matchKey(df.settings.gridKeys.prevCol)){ 
        if(this.prevCol()){
            oEv.stop();
            return false;
        }
    }else if(oEv.matchKey(df.settings.gridKeys.nextCol)){ 
        if(this.nextCol()){
            oEv.stop();
            return false;
        }
    }else if(oEv.matchKey(df.settings.gridKeys.newRow)){ 
        if(this.insertNewRow()){
            oEv.stop();
            return false;
        }
    }else{
        return super.keyDown(oJSEvent);
    }
    
    return true;
}

/*
Augments the moveDownRow function and inserts a new row if no next row was available.

@client-action
*/
moveDownRow(){
    if(!super.moveDownRow.call(this)){
        if(!this.oM.bPaged || this.oM.bLast){
            return this.appendNewRow();
        }
        
        return false;
    }
    return true;
}

    
}

