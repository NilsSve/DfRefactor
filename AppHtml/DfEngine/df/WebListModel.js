import { df } from '../df.js';
/*
Class:
    WebListModel

The model for the WebList its mini MVC system. It stores the data and and triggers onDataUpdate when 
needed to notify the view of changes. It contains logic for sorting the data.

Struct tWebCell
    String sValue
    String sTooltip
    String sCssClassName
    String[] aOptions
End_Struct

Struct tWebRow
    String sRowId
    String sCssClassName
    tWebCell[] aCells
    Integer iGroupHeaderIndex
End_Struct

Struct tWebGroupConfig
    Integer iColumnId
    String sLabel
    Boolean bReverse
End_Struct

Struct tWebGroupHeader
    Integer iGroupIndex
    Integer iParentHeaderIndex
    String sItem
    Integer iItems
    String sTotal    
End_Struct


Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
export class WebListModel{

static displayTypes = {
    row : 1,
    header : 2,
    custom : 3
}

constructor(oList){
    this.oL = oList;
    this.bPaged = false;
    
    this.sCurrentRowId = oList.psCurrentRowId;
    this.iCurrentRow = -1;

    this.aDisplay = [];         // Lineair list of display items, which are either rows or group headers. This is what the WebListView iterates to display. 
    
    this.aData = [];            // The actual list data (rows)
    this.aGroupHeaders = [];    // The grouping headers
    this.aGroups = [];          // The defined groups (which columns are being grouped)

    this.bIsGrouped = false;    // Indicates if the data is currently being grouped

    
    this.onDataUpdate = new df.events.JSHandler();
    this.onBeforeDataUpdate = new df.events.JSHandler();
    
    this.onBeforeRowChange = new df.events.JSHandler();
    this.onRowChange = new df.events.JSHandler();
    this.onAfterRowChange = new df.events.JSHandler();
    
    oList._onSettingChange.on(this.onSettingChange, this);
}

/**
 * Fills the aDisplay list by looping over the data and the groups.
 */
prepDisplay(){
    const aHiddenGroups = [];

    const groupHead = (iHeaderIndex, iRowIndex) => {
        const tHeader = this.aGroupHeaders[iHeaderIndex];

        if(tHeader.iParentHeaderIndex >= 0){
            groupHead(tHeader.iParentHeaderIndex, iRowIndex);
        }
        
        if(aHiddenGroups.length > 0){
            if(aHiddenGroups[aHiddenGroups.length - 1] < tHeader.iGroupIndex) return;
            aHiddenGroups.pop();
        }
        if(tHeader.bCollapsed){
            aHiddenGroups.push(tHeader.iGroupIndex);
        }

        tHeader._iItemIndex = this.aDisplay.push({
            eType : WebListModel.displayTypes.header,
            iIndex : iHeaderIndex
        }) - 1;

    };

    this.aDisplay = [];
    this.aGroupHeaders.forEach(tHeader => tHeader._iItemIndex = null);

    this.aData.forEach((tRow, iIndex) => {
        tRow._iItemIndex = null;

        if(tRow.iGroupHeaderIndex >= 0 && this.bIsGrouped) groupHead(tRow.iGroupHeaderIndex, iIndex);

        if(aHiddenGroups.length == 0){
            tRow._iItemIndex = this.aDisplay.push({
                eType : WebListModel.displayTypes.row,
                iIndex : iIndex
            }) - 1;
        }
    });
}

/**
 * This is called when new data is received from the server.
 * 
 * @param {tWebListData} listData   New list data.
 */
handleData(listData){
    const oL = this.oL;
    if(listData && (!Array.isArray(listData.aRows) || !Array.isArray(listData.aGroupHeaders) || !Array.isArray(listData.aGroups))){
        throw new df.Error(999, "Invalid data structure for weblist data.", this);
    }
    if(listData && listData.aRows.length > 0 && listData.aRows[0].aCells.length < (oL._aColumns.length + oL._aSwipeBtns.length)){
        //  Assertion
        throw new df.Error(999, "List data is not containing enough columns ({{0}} / {{1}}).", oL, [listData.aRows[0].aCells.length, (oL._aColumns.length + oL._aSwipeBtns.length)]);
    }

    this.onBeforeDataUpdate.fire(this);
    
    if(listData){   //  handleData is also called when the grouping or sorting changes in which case listData is null
        this.aData =  listData.aRows;
        if(this.oL.peGrouping == df.grpCustom){
            this.aGroupHeaders = listData.aGroupHeaders;
            this.aGroups = listData.aGroups;
            this.bIsGrouped = (this.aGroups.length > 0); // This makes sure no client-side sorting is done
        }
    }
    
    if(this.bIsGrouped){
        //  Apply grouping
        this.groupData();
    }else{
        //    Sort data (if needed)
        this.sortData();
    }

    this.prepDisplay();
    
    //    Refind current row
    this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
    
    //    Always select row if there is a row
    if(this.iCurrentRow < 0 && this.aData.length > 0){
        this.iCurrentRow = 0;
        this.sCurrentRowId = this.aData[0].sRowId;
    }
    
    this.onDataUpdate.fire(this, { sType : "full" });
}

/**
 * Determines if the passed row is the first row in the set.
 * 
 * @param {Object} tRow 
 * @returns True if this is the first row.
 */
isFirst(tRow){
    return (this.aData[0] == tRow);
}

/**
 * Determines if the passed row is the last row in the set.
 * 
 * @param {Object} tRow 
 * @returns True if this is the last row.
 */
isLast(tRow){
    return (this.aData[this.aData.length - 1] == tRow);
}
 
/**
 * Forwards grouping request to the grouping controller where the actual grouping algorithm is implemented.
 */
groupData(){
    this.oL._oGrouping?.groupData();
}

/**
 * Sorts the data if piSortColumn is set on the WebList.
 * 
 * @returns True if sorting was applied.
 */
sortData(){
    const oL = this.oL;
    
    //   Find comparison functions
    if(oL.piSortColumn >= 0 && oL._aColumns[oL.piSortColumn]){
        let aSortCols = [], aCmpFuncs = [];

        if(oL.piSortColumn >= 0 && aSortCols.indexOf(oL.piSortColumn) == -1){
            aSortCols.push(oL.piSortColumn);
            aCmpFuncs.push(df.sys.data.compareFunction(oL._aColumns[oL.piSortColumn].peDataType, oL.pbReverseOrdering));
        }
        oL._aColumns.forEach((col, index )=> {
            if(aSortCols.indexOf(index) == -1){
                aSortCols.push(index);
                aCmpFuncs.push(df.sys.data.compareFunction(col.peDataType, oL.pbReverseOrdering))
            }
        });

        this.customSortData(aSortCols, aCmpFuncs);
        
        return true;
    }
    
    return false;
}

/**
 * Implementation of client-side data sorting used by sortData and by the WebListGroupingController.
 * 
 * @param {Array} aCols     List of columns to sort on (in order of priority).
 * @param {Array} aCmpFuncs Sort function to use for each column (must match aCols).
 */
customSortData(aCols, aCmpFuncs){
    this.aData.sort((row1, row2) =>{
        for(let i = 0; i < aCols.length; i++){
            const iCol = aCols[i];
            const iRes = aCmpFuncs[i](row1.aCells[iCol].sValue, row2.aCells[iCol].sValue);
            if (iRes != 0) return iRes;
        }
        return 0;
    });
}

rowIndexByRowId(sRowId){
    return this.aData.findIndex(tRow => tRow.sRowId == sRowId);
}

rowIdByRowIndex(iRowIndex){
    return (this.aData[iRowIndex] ? this.aData[iRowIndex].sRowId : null);
}

rowByRowIndex (iRowIndex) {
    return this.aData[iRowIndex];
}

rowByRowId (sRowId){
    return this.aData.find(tRow => tRow.sRowId == sRowId) || null;
}

rowIndexToItemIndex (iRow){
    if(this.aData[iRow] && this.aData[iRow]._iItemIndex != null) return  this.aData[iRow]._iItemIndex;

    return -1;
}

setCurrentRowId(sRowId){
    if(this.sCurrentRowId !== sRowId){
        const oOptions = {
            sPrevRowId : this.sCurrentRowId,
            iPrevRowIndex : this.iCurrentRow,
            sGotoRowId : sRowId,
            iGotoRowIndex : this.rowIndexByRowId(sRowId)
        };

        this.sCurrentRowId = oOptions.sGotoRowId;
        this.iCurrentRow = oOptions.iGotoRowIndex;

        this.onRowChange.fire(this, oOptions);
    }
}

updateRow(sRowId, tRow, bMergeRow){
    const iRow = this.rowIndexByRowId(sRowId);
    if(iRow >= 0){
        this.onBeforeDataUpdate.fire(this);
        
        if(bMergeRow){  
            //  Merge the new row data into the old row, always update rowid and cell values, other details are only updated if they are provided.
            //  For non data aware grids this will be the default provided by the server.
            const origRow = this.aData[iRow];
            origRow.sRowId = tRow.sRowId;
            if(tRow.sCssClassName) tRow.sCssClassName;
            tRow.aCells.forEach((newCell, iCell) => {
                const origCell = this.aData[iRow].aCells[iCell];
                origCell.sValue = newCell.sValue;
                if(newCell.sTooltip) origCell.sTooltip = newCell.sTooltip;
                if(newCell.sCssClassName) origCell.sCssClassName = newCell.sCssClassName;
                if(newCell.aOptions.length) origCell.aOptions = newCell.aOptions;
            })    
        }else{
            this.aData[iRow] = tRow;
        }
        
        //  If we are changing the current row we should also update sCurrentRowId, appendNewRow will handle the case where this shouldn't happen (tab from new row into another new row)
        //    Note that sometimes (cell save example) the sCurrentRowId already contains the new rowid.
        if(this.sCurrentRowId === sRowId || this.sCurrentRowId === tRow.sRowId){
            this.sCurrentRowId = tRow.sRowId;
            this.iCurrentRow = iRow;
        }
        
        //this.sortData();    // This would cause issues, if the ordering changes we need a full refresh
        
        this.onDataUpdate.fire(this, { sType : "row",  sUpdateRowId : sRowId, sNewRowId : tRow.sRowId });
    }
}


removeRow(sRowId){
    const iRow = this.rowIndexByRowId(sRowId);
    if(iRow >= 0){
        if(this.iCurrentRow > iRow){
            this.iCurrentRow--;
        }
        
        this.aData.splice(iRow, 1);
        this.prepDisplay();

        this.onDataUpdate.fire(this, {
            sType :"remrow",
            sRowId : sRowId,
            iRowIndex : iRow
        });
    }
}

appendRow(tRow){
    //  Insert at the end
    this.aData.push(tRow);
    
    if(this.sortData()){
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
    }
    this.prepDisplay();
    this.onDataUpdate.fire(this, {
        sType :"newrow",
        sRowId : tRow.sRowId
    });
}

insertBefore(sBeforeRowId, tRow){
    let iBefore = this.rowIndexByRowId(sBeforeRowId);
    
    if(iBefore < 0){
        iBefore = this.aData.length;
    }
    if(iBefore <= this.iCurrentRow){
        this.iCurrentRow++;
    }
     
    this.aData.splice(iBefore, 0, tRow);
     
    if(this.sortData()){
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
    }
    this.prepDisplay();
    this.onDataUpdate.fire(this, {
        sType :"newrow",
        sRowId : tRow.sRowId
    });  
}

insertAfter(sAfterRowId, tRow){
    const iAfter = this.rowIndexByRowId(sAfterRowId);

    
    if(iAfter < 0 || iAfter + 1== this.aData.length){
        this.appendRow(tRow);
    }else{
        this.insertBefore(this.aData[iAfter + 1].sRowId, tRow);
    }
}

updateCell(oCol, sVal){
    if(this.iCurrentRow >= 0){
        this.onBeforeDataUpdate.fire(this);
        
        this.aData[this.iCurrentRow].aCells[oCol._iColIndex].sValue = sVal;
        //this.sortData();    // This would cause issues, if the ordering changes we need a full refresh
        
        this.onDataUpdate.fire(this, { 
            sType : "cell", 
            sUpdateRowId : this.sCurrentRowId, 
            oCol : oCol
        });
    }
}

updateCellByRowId(sRowId, oCol, sVal){
    const iRowIndex = this.rowIndexByRowId(sRowId);

    if (iRowIndex >= 0){
        this.onBeforeDataUpdate.fire(this);
        
        this.aData[iRowIndex].aCells[oCol._iColIndex].sValue = sVal;
        
        this.onDataUpdate.fire(this, { 
            sType : "cell", 
            sUpdateRowId : sRowId, 
            oCol : oCol
        });
    }
}

updateSorting(){
    const oL = this.oL;
    
    if(!this.bPaged && oL.piSortColumn >= 0){
        this.handleData(null, "page", "", true, true);
    }
}

updateGrouping(){
    var oL = this.oL;
    
    if(!this.bPaged && oL.peGrouping != df.grpDisabled){
        this.handleData(null, "page", "", true, true);
    }
}

onSettingChange(oEv){
    if(oEv.sType === "prop"){
        switch(oEv.sProp){
            case "piSortColumn":
            case "pbReverseOrdering":
                this.updateSorting();
                break;
        }
    }else if(oEv.sType === "sorting"){
        this.updateSorting();
    }else if(oEv.sType === "grouping"){
        this.updateGrouping();
    }
}

}