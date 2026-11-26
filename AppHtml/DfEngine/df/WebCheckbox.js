import { WebBaseDEO } from './WebBaseDEO.js';
import { df } from '../df.js';
/*
Class:
    df.WebCheckbox
Extends:
    df.WebBaseDEO

This is the client-side representation of the cWebCheckbox class. It displays a checkbox using the 
<input type="checkbox" element.
    
Revision:
    2012/01/09  (HW, DAW) 
        Initial version.
*/
export class WebCheckbox extends WebBaseDEO {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psChecked", "1");
        this.prop(df.tString, "psUnchecked", "0");
        this.prop(df.tString, "psCaption", "");

        this.pbServerOnChange = false;
        this.psClientOnChange = "";

        // @privates
        this._eCaption = null;

        //  Configure super classes
        this._sControlClass = "WebCheckbox";
    }

    /*
    Augments openHtml and adds the checkbox element.
    
    @param  aHtml   Array string builder to add HTML to.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<input type="checkbox" id="', this._sControlId, '"', (!this.isEnabled() ? ' disabled="disabled" tabindex="-1"' : ''), '><span class="WebCB_Fake"></span><label class="WebCheckbox_Caption" for="', this._sControlId, '"></label>');
        if (this._oParent?._bIsContainer && this._oParent?.isFlowLayout()) {
            aHtml.push('<div style="clear: both"></div>');
        }
    }

    /*
    Augments afterRender to get a reference to the DOM element.
    
    @private
    */
    afterRender() {
        //  Get references
        this._eControl = df.dom.query(this._eElem, "input");
        this._eCaption = df.dom.query(this._eElem, "label.WebCheckbox_Caption");
        this._eFakeBox = df.dom.query(this._eElem, ".WebCB_Fake");

        this.set_psCaption(this.psCaption);

        //  Call super
        super.afterRender();

        df.dom.on("click", this._eControl, this.onClick, this);
        df.dom.on("click", this._eFakeBox, this.onFakeClick, this);
    }

    /*
    This method is called by the WebBaseDEO logic when the value needs to be read from the user 
    interface. The checkbox overrides the default behavior and returns psChecked or psUnchecked 
    depending on the state of the checkbox element.
    
    @return The currently displayed value.
    @private
    */
    getControlValue() {
        if (this._eControl) {
            if (this._eControl.checked) {
                return this.psChecked;
            }
            return this.psUnchecked;
        }

        return this.psValue;
    }

    /*
    This method is called by the WebBaseDEO logic when the user interface needs to be updated with a new 
    value. When sVal is equal to psChecked we display the checkbox as checked.
    
    @param  sVal    The new value to display.
    */
    setControlValue(sVal) {
        if (this._eControl) {
            this._eControl.checked = (sVal === this.psChecked);
        }
    }

    /*
    Augment the setter for psValue and store the new current vale for the OnChange check. We execute 
    get_psValue here because the checkbox can change the value when it is set.
    
    @param  sVal    The new value.
    */
    set_psValue(sVal) {
        super.set_psValue(sVal);

        //  FIX: Initial value issue
        this._sPrevChangeVal = this.get_psValue();
    }

    /*
    Update the DOM with the new caption. If the caption really changed we trigger a resize using sizeChanged.
    
    @param  sVal    The new value.
    */
    set_psCaption(sVal) {
        if (this._eCaption) {
            df.dom.setText(this._eCaption, sVal);

            if (this.psCaption !== sVal) {
                this.sizeChanged();
            }
        }
    }

    /*
    Overrides setter for psTextColor so the color is set on the caption.
    
    @param  sVal    The new value.
    @private
    */
    set_psTextColor(sVal) {
        if (this._eCaption) {
            this._eCaption.style.color = sVal || '';
        }
    }

    /*
    Augments the psTooltip with fakebox element support.
    
    @param  sVal    The new tooltip.
    @private
    */
    set_psToolTip(sVal) {
        super.set_psToolTip(sVal);
        if (this._eFakeBox) {
            this._eFakeBox.title = sVal;
        }
        if (this._eCaption) {
            this._eCaption.title = sVal;
        }
    }


    /*
    This function inverts the value if the control is enabled. Is called by the grid.
    */
    tick() {
        if (this._eControl && this.isEnabled()) {
            this._eControl.checked = !this._eControl.checked;

            this.fireChange();
        }
    }

    /*
    Event handler for the click event that triggers the check for the onchange event.
    
    @param  oEvent  Event details object.
    @private
    */
    onClick(oEvent) {
        this.fireChange();
    }

    /* 
    Handles the click on the fake click element. Ticks the checkbox, gives it the focus and fires the 
    OnChange.
    
    @param  oEvent  Event details object.
    @private
    */
    onFakeClick(oEvent) {
        if (this.isEnabled()) {
            this.tick();
            this.focus();

            this.fireChange();
        }
    }
}