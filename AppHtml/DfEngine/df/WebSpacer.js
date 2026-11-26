import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';

/*
Class:
    df.WebSpacer
Extends:
    df.WebBaseControl

This is the client-side representation of the cWebSpacer class. The WebSpacer control is meant to 
add whitespace to between controls in the column layout flow. While this could be done with other 
controls this is the official supported way to do it.
    
Revision:
    2012/08/30  (HW, DAW) 
        Initial version.
*/
export class WebSpacer extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "piHeight", 0);
        this.prop(df.tInt, "piMinHeight", 0);

        this._sControlClass = "WebSpacer";
        this._bFocusAble = false;
    }

    /*
    This method augments the html generation and adds the div.WebSpacer_Spacer element.
    
    @param  aHtml   String builder array containing html.
    
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebSpacer_Spacer">');
    }

    /*
    This method augments the html generation and closes the div.WebSpacer_Spacer element.
    
    @param  aHtml   String builder array containing html.
    
    @private
    */
    closeHtml(aHtml) {
        aHtml.push('</div>');

        super.closeHtml(aHtml);
    }

    /*
    This method is called after rendering and is used the get references to DOM elements, attach event 
    listeners and do other initialization.
    
    @private
    */
    afterRender() {
        this._eControl = df.dom.query(this._eElem, "div.WebSpacer_Spacer");

        super.afterRender();
    }
}