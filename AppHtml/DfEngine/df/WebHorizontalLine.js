import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebHorizontalLine
Extends:
    df.WebBaseControl

This is the client-side representation of the cWebHorizontalLine class. 
    
Revision:
    2012/08/30  (HW, DAW) 
        Initial version.
*/
export class WebHorizontalLine extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this._sControlClass = "WebHorizontalLine";
        this._bFocusAble = false;
    }

    /*
    This method augments the html generation and adds the div.WebHorizontalLine_Spacer element.
    
    @param  aHtml   String builder array containing html.
    
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<hr/>');
    }

    /*
    This method augments the html generation and closes the div.WebHorizontalLine_Spacer element.
    
    @param  aHtml   String builder array containing html.
    
    @private
    */
    closeHtml(aHtml) {


        super.closeHtml(aHtml);
    }

    /*
    This method is called after rendering and is used the get references to DOM elements, attach event 
    listeners and do other initialization.
    
    @private
    */
    afterRender() {
        this._eControl = df.dom.query(this._eElem, "hr");

        super.afterRender();
    }

    /*
    Override the setter for psBackgroundColor because <hr elements behave different in different 
    browsers. If we want the line to show the background color we need to set both color and
    backgroundColor because some browsers use one and others use the other.
    
    @param  sVal    The new background color.
    */
    set_psBackgroundColor(sVal) {
        if (this._eControl) {
            this._eControl.style.backgroundColor = sVal || '';
            this._eControl.style.color = sVal || '';
            //this._eControl.style.backgroundImage = (sVal ? 'none' :'');
        }
    }
}