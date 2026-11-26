import { df } from '../df.js';

/*
Class:
    df.WebListPlaceHolderView

View within the WebList its mini MVC model that shows the placeholder if there is no data shown. It 
listens to the onDataUpdate of the model and onSettingChange of the WebList to determine if it 
should show.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/

export class WebListPlaceHolderView {
    constructor(oList, oModel) {
        this.oL = oList;
        this.oM = oModel;

        this.eElem = null;

        oModel.onDataUpdate.on(this.onDataUpdate, this);
        oList._onSettingChange.on(this.onSettingChange, this);
    }

    genHtml(aHtml) {
        const oL = this.oL;

        aHtml.push('<div class="WebList_PlaceHolder"', (oL.psPlaceHolder && this.oM.aData.length === 0 ? '' : ' style="display: none"'), '>', df.dom.encodeHtml(oL.psPlaceHolder), '</div>');
    }

    afterRender(eList) {
        this.eElem = df.dom.query(eList, "div.WebList_PlaceHolder");
    }


    onDataUpdate(oEv) {
        if (this.oL.psPlaceHolder && this.eElem) {
            this.eElem.style.display = (this.oM.aData.length === 0 ? '' : 'none');
        }
    }

    onSettingChange(oEv) {
        const oL = this.oL;

        if (this.eElem && oEv.sType === "prop" && oEv.sProp === "psPlaceHolder") {
            if (!oL.psPlaceHolder) {
                this.eElem.style.display = "none";
            } else {
                df.dom.setText(this.eElem, oL.psPlaceHolder);
            }
        }
    }


};