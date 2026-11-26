import { WebBaseSelectionForm } from './WebBaseSelectionForm.js';
import { df } from '../df.js';

/*
Class:
    df.WebSelectionForm
Extends:
    df.WebBaseSelectionForm

Implementation of the web suggestion form that is capable of showing a list of suggestions while 
typing. These suggestions can come from a variety of sources which is mainly determined on the 
server.

Revision:
    2020/09/25  (HW, DAW)
        Initial version.
*/
export class WebSelectionForm extends WebBaseSelectionForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.event("OnSelect", df.cCallModeDefault, "privateOnSelect");
    }

    openHtml(aHtml) {
        // OpenHtml of the WebBaseSelectionForm.
        super.openHtml(aHtml);
    }

    afterRender() {
        // AfterRender of the WebBaseSelectionForm.
        super.afterRender();
    }   

    suggestSelect() {
        if (this._oSelectedSuggestion && !this._oSelectedSuggestion.control) {
            let tRow = this.findSuggestionByValue(this._oSelectedSuggestion.aValues[0]);
            if (tRow) {
                this.set_psValue(tRow.aValues[0]);
                this.fireEx({
                    sEvent: "OnSelect",
                    tActionData: [tRow],
                    oEnv: this
                });
                this.suggestHide();
                return;
            }
        }
        super.suggestSelect();
    }
    
}