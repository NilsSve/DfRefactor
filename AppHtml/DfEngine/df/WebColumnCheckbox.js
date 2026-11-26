import { WebColumn_mixin } from './WebColumn_mixin.js';
import { WebCheckbox } from './WebCheckbox.js';
import { WebGrid } from './WebGrid.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnCheckbox
Mixin:
    df.WebColumn_mixin (df.WebColumnCheckboxBase)
Extends:
    df.WebCheckbox

Class representing the checkbox column that renders a checkbox in each cell instead of the textual 
value.
    
Revision:
    2012/01/23  (HW, DAW) 
        Initial version.
    2013/08/15  (HW, DAW)
        Rewrote to use mixin.
*/

//  Generate new base class using mixin and WebCheckbox
class WebColumnCheckboxBase extends WebColumn_mixin(WebCheckbox) {}

export class WebColumnCheckbox extends WebColumnCheckboxBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this._sTick = null;

        //  Configure super class
        this._sCellClass = "WebColCheckbox";
        this._sControlClass = "WebCheckbox WebCheckboxColumn";
    }

    /* 
    Augments the cellClick to make sure that the checkbox will be ticked when it is selected shortly 
    after this event. A timeout is used to reset the switch controlling this.
    
    @param  oEvent  Event object.
    @param  sRowId  RowId of the clicked row.
    @param  sVal    Value of the clicked cell.
    
    @param  True if this column handled the click and the list should ignore it (stops the ChangeCurrentRow).
    */
    cellClickBefore(oEvent, sRowId, sVal) {
        const eTarget = oEvent.getTarget();

        super.cellClickBefore(oEvent, sRowId, sVal);

        //  Make sure that the checkbox gets ticked if we switch to edit mode within a second
        if (!df.dom.isParent(eTarget, this._eElem) && (eTarget.tagName === "INPUT" || eTarget.tagName === "SPAN")) {
            this._sTick = sRowId;
        }
    }

    /* 
    Augments the cellClickAfter and checks if the checkbox needs to be ticked (if this occurs shortly after 
    cellClick). This needs to be done so that clicking checkboxes in rows that are not currently 
    selected also works.
    */
    cellClickAfter(oEv, sRowId, sColVal) {
        super.cellClickAfter(oEv, sRowId, sColVal);

        //  Tick the checkbox if it was just clicked
        if (this._sTick) {

            //  We wait for the call to finish as this might called from the setter of psCurrentRowId and psValue might still get set afterwards (and we don't want that as it would revert the change)
            this.getWebApp().waitForCall(function () {
                this._bIgnoreOnChange = false;
                if (this._sTick === this._oParent.currentRowId()) {
                    this.tick();
                    this._sTick = null;
                }
                this._bIgnoreOnChange = true;
            }, this);
        }
    }

    /*
    This method determines the HTML that is displayed within a cell. It gets the value as a parameter 
    and uses the column context properties (like masks) to generate the value to display. For default 
    grid columns it simply displays the properly masked value.
    
    @param  tCell   Data object reprecenting the cell data.
    @return The HTML representing the display value.
    */
    cellHtml(sRowId, tCell) {
        const aHtml = [];

        aHtml.push('<div class="', this.genClass(), '"><div class="WebCon_Inner"><div><input type="checkbox"');

        if (tCell.sValue === this.psChecked) {
            aHtml.push(' onclick="this.checked = true" checked="checked"');
        } else {
            aHtml.push(' onclick="this.checked = false"');
        }

        if (!this.isEnabled()) {
            aHtml.push(' disabled="disabled"');
        }
        if (!(this._oParent instanceof WebGrid)) {
            aHtml.push(' tabindex="-1"');
        }

        aHtml.push('><span class="WebCB_Fake"></span></div></div></div>');

        return aHtml.join('');
    }
}