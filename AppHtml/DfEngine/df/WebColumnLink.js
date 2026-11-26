import { WebBaseDEO } from './WebBaseDEO.js';
import { WebColumn_mixin } from './WebColumn_mixin.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnLink
Mixin:
    df.WebColumn_mixin (df.WebColumnLinkBase)
Extends:
    df.WebBaseDEO

Implementation of the link column that renders a link instead of the value of which the OnClick can
be handled on the server.
    
Revision:
    2013/07/12  (HW, DAW) 
        Initial version.
*/

//  Generate base class that uses the WebColumn_mixin and WebBaseDEO.
class WebColumnLinkBase extends WebColumn_mixin(WebBaseDEO) {}

/* 
WebColumnLink class that adds an OnClick event fired when a cell is clicked. It also renders like a 
link (blue, underline, cursor hand).
*/
export class WebColumnLink extends WebColumnLinkBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.event("OnClick", df.cCallModeWait); //  Keep this as default because usually there will be a OnRowChange right behind it


        //  Configure super classes
        this._sControlClass = "WebColLink";
        this._sCellClass = "WebColLink WebWrp_None";
        this._bCellEdit = false;
    }

    /* 
    Augment openHtml to render the anchor that will be displayed when the cell is selected (so it acts
    as the control).
    
    @param  aHtml   String builder array to add HTML to.
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<a href="javascript:void(0);" target="_self">');
    }

    /*
    Augment closeHtml to render the anchor.
    
    @param  aHtml   String builder array to add HTML to.
    */
    closeHtml(aHtml) {
        aHtml.push('</a>');

        super.closeHtml(aHtml);
    }

    /* 
    Augment the afterRender function to get a reference to our anchor that acts as the control.
    */
    afterRender() {
        this._eControl = df.dom.query(this._eElem, "a");

        super.afterRender();
    }

    // - - - - - - - - - DEO Implemnetation - - - - - - - - - 
    /*
    This method reads the current value from the user interface. It will be overridden by the different 
    type of Data Entry Objects. The default implementation reads the value property of the control DOM 
    element.
    
    @return The currently displayed value.
    @private
    */
    getControlValue() {
        return this.psValue;
    }

    // - - - - - - - - - WebColumn Stuff - - - - - - - - - - -

    /* 
    Override the cellClick to trigger the OnClick if an achor is clicked.
    
    @param  oEvent  Event object.
    @param  sRowId  RowId of the clicked row.
    @param  sVal    Value of the clicked cell.
    
    @param  True if this column handled the click and the list should ignore it (stops the ChangeCurrentRow).
    */
    cellClickAfter(oEvent, sRowId, sVal) {
        if (oEvent.getTarget().tagName === "A" && this.isEnabled()) {
            this.fire("OnClick", [sRowId, sVal]);

            return true;
        }

        return false;
    }

    /*
    Augment the cellHtml to add the anchor element.
    
    @param  tCell   Data object reprecenting the cell data.
    @return The HTML representing the display value.
    */

    cellHtml(sRowId, tCell) {
        let sVal = super.cellHtml(sRowId, tCell);

        if (sVal === "&nbsp;") {
            sVal = ""; //Make sure we pass a empty string if nothing is in the cell.
        }

        return ('<a href="javascript:void(0);" target="_self">' + sVal + '</a>');
    }


    /*
    We augment the onKey event handler and call the onKey handler of the grid first so that the grid 
    keys overrule the default form keys (especially ctrl � end & ctrl � home which go to the last & 
    first row instead of doing a find). The grids onKey handler returns true if nothing happened and 
    false if something happened (this confirms with the default event system).
    
    @param  oEvent  The event object.
    */
    onKey(oEvent) {
        oEvent.e.cancelBubble = true;

        if (oEvent.matchKey(df.settings.formKeys.submit)) {
            this.cellClick(oEvent, this._oParent.currentRowId(), this.psValue);
        } else {
            super.onKey(oEvent);
        }
    }


}