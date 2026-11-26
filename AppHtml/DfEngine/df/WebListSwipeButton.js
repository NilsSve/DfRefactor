import { WebBaseUIObject } from './WebBaseUIObject.js';
import { df } from '../df.js';
/*
Class:
    df.WebListSwipeButton
Extends:
    df.WebBaseUIObject

Swipe button inside a WebList. It is threated by the list as a column but it isn't really a column. 
The WebList class itself implements the rendering.
    
Revision:
    2017/01/18  (HW, DAW) 
        Initial version.
*/

export class WebListSwipeButton extends WebBaseUIObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psCaption", "");
        this.prop(df.tInt, "piWidth", 50);
        this.prop(df.tBool, "pbPositionLeft", false);
        this.prop(df.tBool, "pbDynamic", false);
        this.prop(df.tBool, "pbAllowHtml", false);

        this.event("OnClick", df.cCallModeWait);

        this._iColIndex = 0;
        this._bIsSwipeButton = true;
    }

    isVisible(tCell) {
        return this.pbRender && this.pbVisible && (!this.pbDynamic || df.toBool(tCell.aOptions[0]));
    }

    btnHtml(tCell) {
        let sV = "";
        if (this.pbDynamic) {
            sV = tCell.sValue;
        } else {
            sV = this.psCaption;
        }

        if (!this.pbAllowHtml) {
            sV = df.dom.encodeHtml(sV);
        }

        return sV;
    }

    /* 
    Triggered by the List / Grid when a cell of this column is clicked. Checks if a button is clicked 
    and if so it will fire the OnClick event.
    
    @param  oEvent  Event object.
    @param  sRowId  RowId of the clicked row.
    */
    btnClick(oEv, sRowId, fHandler, oEnv) {
        this.fire("OnClick", [sRowId], fHandler, oEnv);

        return true;
    }
};
