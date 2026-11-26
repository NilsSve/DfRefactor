import { WebListPagedModel } from './WebListPagedModel.js';
import { WebListModel } from './WebListModel.js';
import { df } from '../df.js';

/*
Mixin:
    df.WebGridModel_mixin
Used by:
    df.WebGridModel (df.WebListModel)
    df.WebGridPagedModel (df.WebListPagedModel)

Extends the list model classes with the logic to maintain the current column on top of the current 
row needed by the Grid as it works with a specific edit cell.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
const WebGridModel_mixin = superclass =>
    class extends superclass {

define_WebGridModel_mixin(oList){
    this.iCurrentColumn = oList.piCurrentColumn;
    
    this.onColChange = new df.events.JSHandler();
}

appendRow(tRow){
    //  Check if last row is a new row
    if(this.aData.length > 0 && this.aData[this.aData.length - 1].sRowId === ""){
        //  Insert before the new row
        this.aData.splice(this.aData.length - 1, 0, tRow);
        this.iCurrentRow++;
    }else{
        //  Insert at the end
        this.aData.push(tRow);
    }
    
    if(this.sortData()){
        this.iCurrentRow = this.rowIndexByRowId(this.sCurrentRowId);
    }
    this.prepDisplay();
    this.onDataUpdate.fire(this, {
        sType :"newrow",
        sRowId : tRow.sRowId
    });
}

}

// df.WebGridModel = df.mixin("df.WebGridModel_mixin", "df.WebListModel");
export class WebGridModel extends WebGridModel_mixin(WebListModel) {
    constructor(oList){
        super(oList);
        this.define_WebGridModel_mixin(oList);
    }
}

// df.WebGridPagedModel = df.mixin("df.WebGridModel_mixin", "df.WebListPagedModel");
export class WebGridPagedModel extends WebGridModel_mixin(WebListPagedModel) {
    constructor(oList){
        super(oList);
        this.define_WebGridModel_mixin(oList);
    }
}

