import { WebColumn_mixin } from './WebColumn_mixin.js';
import { WebDateForm } from './WebDateForm.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnDate
Mixin:
    df.WebColumn_mixin (df.WebColumnDateBase)
Extends:
    df.WebForm

This is the client-side representation of the cWebColumnDate control.

Revision:
    2013/12/11  (HW, DAW) 
        Initial version.
*/

//  Generate new base class using df.WebColumn_mixin and df.WebDateForm
class WebColumnDateBase extends WebColumn_mixin(WebDateForm) {}

export class WebColumnDate extends WebColumnDateBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Configure super class
        this._sCellClass = "WebCol";
    }

    afterRender() {
        super.afterRender();
    }

    onKey(oEvent) {
        //  Only call base (which calls the list) if the picker is not visible to block cursor up / down handler of the list overruling the date picker
        if (!this._bPickerVisible) {
            super.onKey(oEvent);
        } else if (oEvent.matchKey(df.settings.calendarKeys.close) && this._bPickerVisible) {
            this.hideDatePicker();
            oEvent.stop();
        }
    }
}