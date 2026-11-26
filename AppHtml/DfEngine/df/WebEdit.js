import { WebBaseForm } from './WebBaseForm.js';
import { df } from '../df.js';
/*
Class:
    df.WebEdit
Extends:
    df.WebBaseForm

This is the client-side representation of the WebEdit class. It generates the HTML for the input 
element and possibly a prompt button.
    
Revision:
    2011/10/12  (HW, DAW) 
        Initial version.
*/
/*
This class is the implementation of the client-side part of the WebEdit data entry object. It can 
render itself to HTML and implements the published properties from the server. It has special prompt 
button functionality.
*/
export class WebEdit extends WebBaseForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbStopOnSubmit", true);
        this.prop(df.tString, "psPlaceHolder", "");

        // @privates
        this._eWrap = null;
        this._ePrompt = null;

        //  Configure super classes
        this._sControlClass = "WebEdit";
        this._bJSSizing = false;
    }

    /*
    This method generates the HTML for input element. The input element has two wrappers for styling it 
    and making space for the prompt button. The HTML for the prompt button is available by default and 
    is made visible when needed.
    
    @param  aHtml   String builder array to which HTML can be added.
    
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebFrm_Wrapper"><textarea name="', this._sName, '"',
            ' autocomplete="', df.dom.encodeAttr(this.psAutoComplete), '"',
            (this.peLabelPosition != df.ciLabelFloat ? (' placeholder="' + df.dom.encodeAttr(this.psPlaceHolder) + '" ') : ''),
            (!this.isEnabled() ? ' disabled="disabled" tabindex="-1"' : ''),
            '></textarea></div>');
    }

    /*
    This method is called after rendering and gets references, attaches event handlers and sets property 
    values.
    
    @private
    */
    afterRender() {
        //  Get references
        this._eControl = df.dom.query(this._eElem, "div.WebFrm_Wrapper textarea");
        this._eWrap = df.dom.query(this._eElem, "div.WebFrm_Wrapper");

        super.afterRender();

        df.events.addDomKeyListener(this._eElem, this.onKey, this);
    }

    /*
    This setter sets the background color of the field. The background color is applied to the wrapper 
    div element.
    
    @param  sVal    The bew value.
    @private
    */
    set_psBackgroundColor(sVal) {
        if (this._eWrap) {
            this._eWrap.style.background = sVal || '';
        }
    }

    /* 
    Sets the placeholder using the HTML5 placeholder attribute (only works on IE10 and higher).
    
    @param  sVal    The new value.
    */
    set_psPlaceHolder(sVal) {
        if (this._eControl && this.peLabelPosition != df.ciLabelFloat) {
            this._eControl.placeholder = sVal;
        }
    }

    /*
    Override the getter of pbChanged to make sure that line feeds don't cause pbChanged to become true. 
    The textarea DOM element converts all line-feeds & cariage returns into single line feed characters 
    without the user actually making a change. So we make the same change before doing the comparison.
    */
    get_pbChanged() {
        let sComp = this._sOrigValue;

        if (this.pbChanged) {
            return true;
        }

        if (this._eElem) {
            this.updateTypeVal();

            sComp = sComp.replace(/\r\n|\r/g, '\n');
        }

        return sComp !== this.getServerVal();

        //  HW: Test code to be deleted after fix is confirmed..
        // var bRes = sComp !== this.getServerVal();

        // sComp = sComp.replace(/\r/g, "[LF]");
        // sComp = sComp.replace(/\n/g, "[CR]");

        // var sV = this.getServerVal();

        // sV = sV.replace(/\r/g, "[LF]");
        // sV = sV.replace(/\n/g, "[CR]");

        // console.log("Result: " + bRes + "\r\nOrig:  '" + sComp + "' \r\n Value: '" + sV + "'");

        // return bRes;
    }


    /*
    We override this method because the form has an extra wrapper of which the Box Difference needs to 
    be taken into account.
    
    @private
    */
    getVertHeightDiff() {
        let iResult = super.getVertHeightDiff();

        iResult += df.sys.gui.getVertBoxDiff(this._eWrap);

        if (df.sys.isChrome) {   //  Strange extra pixels in chrome :S
            iResult++;
            iResult++;
        }

        return iResult;
    }


    /*
    Handles the onKey event and makes sure that it doesn't propagate the enter key if pbStopOnSubmit is 
    true to stop the onsubmit event of the view / dialog.
    
    @param  oEvent  Event object (see: df.events.DOMEvent).
    @private
    */
    onKey(oEvent) {
        //  Make sure that the OnSubmit doesn't fire by canceling the propagation (but leaving the default behavior, OnClick intact)
        if (oEvent.matchKey(df.settings.formKeys.submit) && this.pbStopOnSubmit) {
            oEvent.stopPropagation();
        } else {
            super.onKey(oEvent);
        }
    }


}