import { WebListModel } from './WebListModel.js';
import { df } from '../df.js';

/*
Class:
    WebListPagedModel
Extends:
    WebListModel

Extends the model of the WebList its mini MVC system with logic for paged data loading.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/


export class WebListPagedModel extends WebListModel{

constructor(oList){
    super(oList);
    
    this.bFirst = false;
    this.bLast = false;
    this.bPaged = true;
    
    this.iPrefCacheOffset = 25;    //  The preferred amount of rows in the cache above and below the rendered rows

}

handleData(listData, sType, sStartRowId, bFirst, bLast){
    const oOptions = { sType : "", iOffsetChange : 0, sUpdateRowId : "" };

    if(listData && (!Array.isArray(listData.aRows) || !Array.isArray(listData.aGroupHeaders) || !Array.isArray(listData.aGroups))){
        throw new df.Error(999, "Invalid data structure for weblist data.");
    }
        
    this.onBeforeDataUpdate.fire(this);
    
    
    
    if(sType === "page"){
        //  Update cache
        this.aData = listData.aRows;
        this.bLast = bLast;
        this.bFirst = bFirst;
        
        //    Refind current row
        this.prepDisplay();
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
        
        //    Always select row if there is a row
        if(this.iCurrentRow < 0 && bLast && bFirst){
            if(this.aData.length > 0){
                this.iCurrentRow = 0;
                this.sCurrentRowId = this.aData[0].sRowId;
            }
        }
        
        oOptions.sType = "full";
    }
    
    
    if(sType === "first"){
        //  Update cache
        this.aData = listData.aRows;
        this.bLast = bLast;
        this.bFirst = bFirst;
                            
        //    Refind current row
        this.prepDisplay();
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
        
        oOptions.sType = "full";
    }
    
    if(sType === "last"){
        //  Update cache
        listData.aRows.reverse();
        this.aData = listData.aRows;
        this.bLast = bLast;
        this.bFirst = bFirst;
        
        //  Update display
        this.prepDisplay();
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
        
        oOptions.sType = "full";

    }
    
    if(sType === "next"){
        //  Update cache
        this.aData = this.aData.concat(listData.aRows);
        this.bLast = bLast;
        
        oOptions.sType = "next";

        this.prepDisplay();
    }
    
    if(sType === "prev"){
        //  Update cache
        listData.aRows.reverse();
        this.aData = listData.aRows.concat(this.aData);
        this.bFirst = bFirst;
        
        oOptions.iOffsetChange = listData.aRows.length;
        oOptions.sType = "prev";
        
        this.prepDisplay();
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
    }
    
    this.onDataUpdate.fire(this, oOptions);
}

/**
 * Determines if the passed row is the first row in the set.
 * 
 * @param {Object} tRow 
 * @returns True if this is the first row.
 */
 isFirst(tRow){
    return (this.bFirst && this.aData[0] == tRow);
}

/**
 * Determines if the passed row is the last row in the set.
 * 
 * @param {Object} tRow 
 * @returns True if this is the last row.
 */
isLast(tRow){
    return (this.bLast && this.aData[this.aData.length - 1] == tRow);
}


updateSorting(){
    //  With paged lists the sorting is always done on the server
}


sortData(){
    //    Sorting data always happens on the server when paging data
}

}

