import { WebGridView, WebGridScrollingView } from './WebGridView.js';
import { WebGridModel, WebGridPagedModel } from './WebGridModel.js';
import { WebGridController } from './WebGridController.js';
import { WebList } from './WebList.js';	
import { df } from '../df.js';

/*
Class:
    df.WebGrid
Extends:
    df.WebList

This is the client-side representation of the cWebGrid control. It extends the cWebList control with 
edit functionality. Editing means that the selected cell value is replaced with an edit control 
(usually an input element). The nested column object is responsible for creating the DOM elements 
for editing, the grid is only responsible for adding it to the DOM and removing it from the DOM. 
Saving is usually done automatically by the server when the ChangeCurrentRow event is fired on the 
server.
    
Revision:
    2011/12/15  (HW, DAW) 
        Initial version.
*/
export class WebGrid extends WebList {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbAllowInsertRow", true);
        this.prop(df.tBool, "pbAllowAppendRow", true);
        this.prop(df.tInt, "piCurrentColumn", 0);


        //  Configure super classes
        this.pbAutoSearch = false;

        this.addSync("piCurrentColumn");
        this._bRenderChildren = true;
        this._sControlClass = "WebGrid";

    }

    createView() {
        if (this.pbScroll) {

            return new WebGridScrollingView(this, this._oModel, this._oController);
        } else {
            return new WebGridView(this, this._oModel, this._oController);
        }
    }

    createController() {
        return new WebGridController(this, this._oModel);
    }

    createModel() {
        if (this.peDbGridType === df.gtAllData || this.peDbGridType === df.gtManual || !this.pbDataAware || !this.pbScroll) {
            return new WebGridModel(this);
        } else {
            return new WebGridPagedModel(this);
        }
    }


    /*
    Implementation of the renderChildren method that makes sure that the grid columns render themselves. 
    The DOM elements of the columns are not inserted into the DOM yet. They are used later when a cell 
    is edited.
    */
    renderChildren() {
        const oM = this._oModel;
        let oVisCol = null, oSelCol = null;

        for (let i = 0; i < this._aColumns.length; i++) {
            this._aColumns[i].pbShowLabel = false;
            this._aColumns[i].render();
            this._aColumns[i].afterRender();

            //  Determine the initial column
            if (oVisCol == null && this._aColumns[i].pbRender) {
                oVisCol = this._aColumns[i];
            }
            if (oSelCol == null && this._aColumns[i].pbRender && this._aColumns[i].isEnabled()) {
                oSelCol = this._aColumns[i];
            }
        }

        //  Set the initial column (unless the application specified a specific column)
        if (oM.iCurrentColumn < 0) {
            if (oSelCol) {
                oM.iCurrentColumn = oSelCol._iCol;
            } else if (oVisCol) {
                oM.iCurrentColumn = oVisCol._iCol;
            } else {
                oM.iCurrentColumn = 0;
            }
        }
    }


    applyEnabled(bVal) {
        //  Skip WebList and go into WebControl since _eFocus never has tabindex for grid
        super.applyEnabled(bVal);
    }

    // - - - - Server API - - - - 
    /*
    This method selects the previous column that is enabled and visible. If the first column is selected 
    it moves to the previous row.
    
    @client-action
    */
    prevCol() {
        this._oController.prevCol();
    }

    /*
    This method selects the next column that is enabled and visible. If the last column is selected it 
    moves to the next row.
    
    @client-action
    */
    nextCol() {
        this._oController.nextCol();
    }

    /*
    This method selects a specific column. 
    
    @param  iCol    The index of the column to select.
    @client-action
    */
    selectCol(iCol) {
        this._oController.selectCol(iCol);
    }

    /*
    This method inserts a new row above the currently selected row. If inserting a new row is not 
    allowed (pbAllowInsertRow) it will try to append a new row (at the end of the grid).
    
    @return True if insert or append is allowed.
    @client-action
    */
    insertNewRow() {
        return this._oController.insertNewRow();
    }

    /*
    This method appends a new row at the end of the grid if pbAllowAppendRow is true.
    
    @return True if append is allowed.
    @client-action
    */
    appendNewRow() {
        return this._oController.appendNewRow();
    }

    clearRow(sRowId) {
        return this._oController.clearRow(sRowId);
    }

    /* 
    Getter method for piCurrentColumn.
    */
    get_piCurrentColumn() {
        return this._oModel.iCurrentColumn;
    }

    set_piCurrentColumn(iVal) {
        this._oController.selectCol(iVal);
    }

    // - - - - - - - Focus - - - - - - -

    attachFocusEvents() {
        //  Set the tabIndex of the focus holder negative so that we can tab in and out of the grid
        this._eFocus.tabIndex = -1;

        super.attachFocusEvents();
    }

    /*
    We override the focus method and we pass the focus the edit element. If the edit element is not 
    rendered we give the focus to the focus holder.
    
    @return True if the List can take the focus.
    */
    focus() {
        if (this._bFocusAble && this.isEnabled() && this._eFocus) {
            //  Try to give the focus to the edit cell if it is visible
            if (!this._oBody.focus()) {
                //  If the column couldn't take the focus we pass it to the focus holder
                this._eFocus.focus();
                this.objFocus();
            }

            return true;
        }

        return false;
    }

}