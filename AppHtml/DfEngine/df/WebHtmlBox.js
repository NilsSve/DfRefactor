import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebHtmlBox
Extends:
    df.WebBaseControl

This is the client-side representation of the WebHtmlBox class. The WebHtmlBox control can be used 
to insert a random piece of HTML into the system. It tries to put the HTML inside the control 
rendering flow. This means that it will squeeze itself into the column layout. It can have a dynamic 
or a static height and scrollbars and / or a border.
    
Revision:
    2012/06/18  (HW, DAW) 
        Initial version.
*/
export class WebHtmlBox extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbScroll", true);
        this.prop(df.tString, "psHtml", "");
        this.prop(df.tBool, "pbShowBorder", false);

        //  Events
        this.event("OnClick", df.cCallModeWait);

        //  @privates
        //  Configure super classes
        this._sControlClass = "WebHtmlBox";
        this._bFocusAble = false;
    }

    /*
    This method augments the html generation and adds the div.WebHtml_Wrp element.
    
    @param  aHtml   String builder array containing html.
    
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebHtml_Wrp">');
    }

    /*
    This method augments the html generation and closes the div.WebHtml_Wrp element.
    
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
        this._eControl = df.dom.query(this._eElem, "div.WebHtml_Wrp");

        super.afterRender();

        this.set_piHeight(this.piHeight);
        this.set_pbShowBorder(this.pbShowBorder);

        df.dom.on("click", this._eControl, this.onHtmlClick, this);

        this.updateHtml(this.psHtml);
    }

    // - - - - - - Public API - - - - - -

    /*
    Updates the HTML that is shown inside the box. It doesn't perform any checking and if not rendered 
    yet it will update psHtml so that it will be set when rendering.
    
    @param  sHtml   String with HTML.
    @client-action
    */
    updateHtml(sHtml) {
        this.psHtml = sHtml;

        if (this._eControl) {
            this._eControl.innerHTML = this.psHtml;

            this.sizeChanged();
        }
    }

    /*
    Updates the HTML that is shown inside the box. 
    
    It doesn't perform any checking and if not rendered 
    yet it will update psHtml so that it will be set when rendering.
    
    @param  sHtml   String with HTML.
    @client-action
    */
    appendHtml(sHtml) {
        this.psHtml += sHtml;

        if (this._eControl) {
            this._eControl.innerHTML = this.psHtml;

            this.sizeChanged();
        }
    }

    /*
    Updates the HTML that is shown inside the box. It doesn't perform any checking and if not rendered 
    yet it will update psHtml so that it will be set when rendering.
    
    @param  sHtml   String with HTML.
    @client-action
    */
    prependHtml(sHtml) {
        this.psHtml = sHtml + this.psHtml;

        if (this._eControl) {
            this._eControl.innerHTML = this.psHtml;

            this.sizeChanged();
        }
    }

    /* 
    Updates the HTML that is shown inside the box based on an array passed from the server. It 
    concatenates the array and calls updateHtml.
    
    @client-action
    */
    updateHtmlArray() {
        const aArray = df.sys.vt.deserialize(this._tActionData, [df.tString]);

        this.updateHtml(aArray.join(""));
    }

    /*
    The setter of pbScroll enables or disabled the scrollbar. Note that no vertical scrollbar will be 
    displayed unless the a fixed height is set. A fixed height means that piHeight is set or 
    pbFillHeight is true. 
    
    @param  bVal    The new value.
    */
    set_pbScroll(bVal) {
        if (this._eControl) {
            this._eControl.style.overflowY = (this.pbFillHeight || this.piHeight > 0 ? (bVal ? "auto" : "hidden") : "visible");    // There should be a fixed height else setting this makes no sense
            this._eControl.style.overflowX = (bVal ? "auto" : "");
        }
    }

    /*
    This method determines if the image is shown with a border and background. It does this by removing 
    or adding the "WebHtml_Box" CSS class.
    
    @param  bVal    The new value.
    */
    set_pbShowBorder(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "WebHtml_Box", bVal);
        }
    }

    /*
    
    @param  iVal    The new value.
    */
    set_piHeight(iVal) {
        if (this._eControl) {
            super.set_piHeight(iVal);

            //  Update pbScroll since it depends on piHeight
            this.piHeight = iVal;
            this.set_pbScroll(this.pbScroll);
        }
    }

    set_psHtml(sVal) {
        this.updateHtml(sVal);
    }

    // - - - - - - Rendering - - - - - -

    set_pbFillHeight(bVal) {
        super.set_pbFillHeight(bVal);

        this.pbFillHeight = bVal;
        this.set_pbScroll(this.pbScroll);
    }

    // - - - - - - Supportive - - - - - -
    /*
    This method handles the onclick event on the div containing the HTML. It will determine which child 
    element was actually clicked and then bubble up in the structure to see if a data-serverOnClick 
    attribute was set to define a onclick handler. If it finds one it will fire the OnClick event with 
    the value of data-serverOnClick and data-OnClickParam as parameters.
    
    @param  oEvent  The event object with event details.
    @private
    */
    onHtmlClick(oEvent) {
        let eElem = oEvent.getTarget();

        while (eElem && eElem !== this._eControl) {
            if (eElem.getAttribute('data-ServerOnClick')) {
                this.fire('OnClick', [eElem.getAttribute('data-ServerOnClick'), (eElem.getAttribute('data-OnClickParam') || "")]);
            }
            eElem = eElem.parentNode;
        }
    }


}