import { WebColumn_mixin } from './WebColumn_mixin.js';
import { WebForm } from './WebForm.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumn
Mixin:
    df.WebColumn_mixin (df.WebColumnBase)
Extends:
    df.WebForm

This is the client-side representation of the cWebColumn control. The cWebColumn control is 
the default column for the cWebList & cWebGrid controls and should only be used as a nested object 
for those classes. It extends the input form and adds the functionality needed to let it function 
within the grid or list.
    
Revision:
    2011/12/01  (HW, DAW) 
        Initial version.
    2013/08/15  (HW, DAW)
        Rewrote to use df.WebColumn_mixin.
*/

//  Generate new base class using df.WebColumn_mixin and df.WebForm
export class WebColumnBase extends WebColumn_mixin(WebForm) {}


export class WebColumn extends WebColumnBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "peWordBreak", df.wbNone);
        this.prop(df.tInt, "peVerticalAlign", df.ciVerticalAlignCenter);
        

        //  Configure super class
        //this._sCellClass = "WebCol";
    }

    create() {
        this.updateCssClass(false);
    }

    /* 
    Augments the cellHtml function with support for the pbPassword property.
    
    @param  tCell   Struct with cell data.
    @return HTML content of the cell &bull;&bull; for passwords.
    */
    cellHtml(sRowId, tCell) {
        if (this.pbPassword) {
            return tCell.sValue.replace(/./g, "&bull;");
        } else {
            return super.cellHtml(sRowId, tCell);
        }
    }

    tooltipValue(tCell) {
        if (this.pbPassword) {
            return tCell.sValue.replace(/./g, "&bull;");
        } else {
            return super.tooltipValue(tCell);
        }

    }

    set_peWordBreak(iVal) {
        if (this.peWordBreak !== iVal) {
            this.peWordBreak = iVal
            this.updateCssClass(true);
        }
    }

    set_peVerticalAlign(iVal) {
        if (this.peVerticalAlign !== iVal) {
            this.peVerticalAlign = iVal
            this.updateCssClass(true);
        }
    }

    updateCssClass(bRedraw) {
        this._sCellClass = "WebCol " + df.classWordBreak(this.peWordBreak) + " " + df.classVerticalAlign(this.peVerticalAlign);
        
        //Redraw the weblist if we change properties through a webset
        if (bRedraw) this._oParent.redraw();
    }

}