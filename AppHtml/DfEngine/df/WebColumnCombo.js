import { WebColumn_mixin } from './WebColumn_mixin.js';
import { WebCombo } from './WebCombo.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnCombo
Mixin:
    df.WebColumn_mixin (df.WebColumnComboBase)
Extends:
    df.WebCombo


    
Revision:
    2012/01/18  (HW, DAW) 
        Initial version.
*/

//  Generate new base class using mixin and WebCombo
class WebColumnComboBase extends WebColumn_mixin(WebCombo) {}

export class WebColumnCombo extends WebColumnComboBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Configure super class
        this._sCellClass = "WebColCombo";
    }

    /*
    Triggered after rendering and attached event handles to the DOM.
    
    @private
    */
    afterRender() {
        super.afterRender();
    }



    /*
    This method determines the HTML that is displayed within a cell. It gets the value as a parameter 
    and uses the column context properties (like masks) to generate the value to display. For default 
    grid columns it simply displays the properly masked value.
    
    @param  tCell   Data object reprecenting the cell data.
    @return The HTML representing the display value.
    */
    cellHtml(sRowId, tCell) {
        let sVal = tCell.sValue;

        if (this._aValues) {
            for (let i = 0; i < this._aValues.length; i++) {
                if (this._aValues[i].sValue === sVal) {
                    return (!this.pbAllowHtml ? df.dom.encodeHtml(this._aValues[i].sDescription) : this._aValues[i].sDescription);
                }
            }
        }

        const tVal = df.sys.data.serverToType(sVal, this.peDataType);
        sVal = this.typeToDisplay(tVal);

        if (!this.pbAllowHtml) {
            sVal = df.dom.encodeHtml(sVal);
        }

        return (sVal !== '' ? sVal : '&nbsp;');
    }

    /*
    Augments the key handler and makes sure that in firefox the combo doesn't change when changing rows.
    
    @param  oEvent  The event object.
    @return True.
    @private
    */
    onKey(oEvent) {
        const that = this;

        super.onKey(oEvent);

        //  Fix for FireFox where we temporary disable the control to make sure that the value does not change when changing rows.
        if (df.sys.isMoz) {
            if (oEvent.matchKey(df.settings.listKeys.scrollUp) || oEvent.matchKey(df.settings.listKeys.scrollDown)) {
                this._eControl.disabled = true;

                setTimeout(function () {
                    that._eControl.disabled = !that.isEnabled();
                }, 20);
            }
        }
    }
}