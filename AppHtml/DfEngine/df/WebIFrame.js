import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebIFrame
Extends:
    df.WebBaseControl

This is the client-side representation of the cWebIFrame class. It is capable of rendering an IFrame 
using the IFrame element. The psUrl property allows to set and update the URL being shown within the 
IFrame. Its main usage will be to display reports and other external components within a dataflex 
web applications.
    
Revision:
    2012/12/17  (HW, DAW) 
        Initial version.
*/
export class WebIFrame extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Public properties
        this.prop(df.tString, "psUrl", "");

        this.prop(df.tBool, "pbShowBorder", true);

        this.event("OnLocationChange", df.cCallModeDefault);

        //  Private properties
        this._eWrapper = null;
        this._sContentHtml = null;

        this._sControlClass = "WebIFrame";
    }

    /*
    Augments the openHtml method to generate the HTML for rendering the IFrame.
    
    @param  aHtml   Array string builder to add HTML to.
    @private
    */
    openHtml(aHtml) {

        super.openHtml(aHtml);

        const sName = "df_webiframe_" + df.dom.piDomCounter++;

        aHtml.push('<div class="WebIFrm_Wrp"><iframe name="', sName, '" scrolling="auto" frameborder="no"></iframe></div>');
    }

    /*
    Augments the afterRender method to get references to the generated elements and execute setter 
    methods to further initialize the control.
    
    @private
    */
    afterRender() {
        this._eControl = df.dom.query(this._eElem, "iframe");
        this._eWrapper = df.dom.query(this._eElem, "div.WebIFrm_Wrp");

        super.afterRender();

        df.dom.on("load", this._eControl, this.onFrameLoad, this);

        this.set_pbShowBorder(this.pbShowBorder);
        this.set_psUrl(this.psUrl);

        if (this._sContentHtml != null) {
            this.writeHtmlContent();
        }
    }

    /*
    Handles the OnChange event of the iframe element. This fires when the location changes. It will 
    trigger the OnLocationChange if the url has changed. The psUrl property value will be updated.
    
    @param  oEv     Event object (df.events.DomEvent)
    */
    onFrameLoad(oEv) {
        const sNewLoc = this._eControl.contentWindow.location.href;

        if (sNewLoc && this.psUrl !== sNewLoc) {
            this.psUrl = sNewLoc;
            this.addSync("psUrl");

            this.fire("OnLocationChange", [sNewLoc]);
        }
    }

    /*
    Setter method for the psUrl property. Updating this property will navigate the iframe to this URL.
    
    @param  sVal    The new value.
    */
    set_psUrl(sVal) {
        if (this._eControl) {
            this._eControl.src = sVal;
        }
    }

    /*
    This method determines if the iframe is shown with a border and background. It does this by removing 
    or adding the "WebIFrm_Box" CSS class.
    
    @param  bVal    The new value.
    */
    set_pbShowBorder(bVal) {
        if (this._eWrapper) {
            df.dom.toggleClass(this._eWrapper, "WebIFrm_Box", bVal);
        }
    }

    /*
    Override the setHeight method with a custom implementation for this IFrame. It sets the height of the wrapper so that the IFrame element can have a height of 100%. The pixel calculation is also adjusted for this.
    
    @param  iHeight     The height in pixels.
    @param  bSense      If false the size is expected to not be the final size.
    */
    setHeight(iHeight, bSense) {
        if (this._eControl) {
            //  If a negative value is given we should size 'naturally'
            if (iHeight > 0) {
                iHeight -= this.getVertHeightDiff();

                iHeight = (iHeight < 0 ? 0 : iHeight);  //  FIX: IE8 doesn't handle negative values real well and this seems to happen somehow

                //  Set the height
                this._eWrapper.style.height = iHeight + "px";
            } else {
                this._eWrapper.style.height = "80px";
            }

        }
    }

    /*
    We override this method because the form has an extra wrapper of which the Box Difference needs to 
    be taken into account.
    
    @private
    */
    getVertHeightDiff() {
        let iResult = super.getVertHeightDiff();
        iResult += df.sys.gui.getVertBoxDiff(this._eWrapper);
        return iResult;
    }



    /* 
    Sets the HTML content of the IFrame. Used by the WebApp class for error display.
    
    @param  sHtml   HTML to display inside the iframe.
    */
    setHtmlContent(sHtml) {
        this._sContentHtml = sHtml;

        this.writeHtmlContent();
    }

    /* 
    Updates the content of the iframe with the HTML received in setHtmlContent.
    */
    writeHtmlContent() {
        if (this._eControl) {
            this._eControl.contentWindow.document.open('text/htmlreplace');
            this._eControl.contentWindow.document.write(this._sContentHtml);
            this._eControl.contentWindow.document.close();
        }
    }
}