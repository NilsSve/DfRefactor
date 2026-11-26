import { WebBaseDEO } from './WebBaseDEO.js';
import { df } from '../df.js';
/*
Class:
    df.WebCombo
Extends:
    df.WebBaseDEO

This is the client-side representation of the WebCombo class. It displays a combo form data entry 
object. The CSS (class: WebCombo) defines the looks. The combo form is wrapped in an extra wrapper 
div that allows a custom border to be added.
    
Revision:
    2011/10/06  (HW, DAW) 
        Initial version.
*/

/*
Use this class to display a combo form on a view. 
*/
export class WebCombo extends WebBaseDEO {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "peSortItems", df.csUnsorted);

        // @privates
        this._bFilled = false;
        this._sControlClass = "WebCombo";
        this._aValues = null;

        this._bDeferedSet = false; //  Set to true if the value is set to an item unavailable in the list indicating that OnFill should try to select the orrigional psValue. This fixes the issue where WebSet psValue overtakes a Refill.
    }

    /*
    This method generates the html for the combo and the wrapper div.
    
    @param  aHtml   Stringbuilder array to which the HTML can be added.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebFrm_Wrapper"><select name="', this._sName, '" id="', this._sControlId, '"', (!this.isEnabled() ? ' disabled="disabled" tabindex="-1"' : ''), '></select></div>');
    }

    /*
    This method gathers references to the HTML elements.
    
    @private
    */
    afterRender() {
        this._eControl = df.dom.query(this._eElem, "div.WebFrm_Wrapper > select");
        this._eWrap = df.dom.query(this._eElem, "div.WebFrm_Wrapper");

        super.afterRender();

        df.dom.on("click", this._eControl, this.onClick, this);

        this.updateList(this.psValue);
    }

    /*
    This method fills the list of items with the items received as action data. It has to decode the 
    action data from the array of rows with values into value & description objects. Then it will update 
    the rendered list with this new data.
    
    @client-action
    */
    fill() {
        //  Update the values list
        this._aValues = this._tActionData;

        this.sortList();
        this.updateList(this._sPrevChangeVal);  //  We use _sPrevChangeVal because it is updated by OnChange and set_psValue, so it always has the right value
    }

    /* 
    Sorts the list of combo items based on the peSortItems property which determines if the sorting is 
    performed on the value or on the description. If sorting on the value the peDataType is used to 
    determine the right comparison mode.
    
    @private
    */
    sortList() {

        if (this.peSortItems === df.csValue) {
            //  Sort on value, use the proper comparison function based on the data type
            const fCompare = df.sys.data.compareFunction(this.peDataType);
            this._aValues.sort(function (a, b) {
                return fCompare(a.sValue, b.sValue);
            });
        } else if (this.peSortItems === df.csDescription) {
            //  Sort on the description
            this._aValues.sort(function (a, b) {
                return df.sys.data.compareText(a.sDescription, b.sDescription);
            });
        }
    }

    /*
    This method refills the list according to the this._aValues array of items.
    
    @private
    */
    updateList(sValue) {
        const aValues = this._aValues;

        if (this._eControl && aValues) {
            //df.debug(this._sName + " updateList with " + aValues.length + " items!");


            //  Clear the list
            while (this._eControl.options.length > 0) {
                this._eControl.remove(0);
            }

            //  Fill the list
            for (let i = 0; i < aValues.length; i++) {
                const eOpt = new Option(aValues[i].sDescription, aValues[i].sValue);
                this._eControl.options[this._eControl.options.length] = eOpt; //.add(eOpt);

                //  Set as selected if needed
                if (aValues[i].sValue === sValue) {
                    eOpt.selected = true;
                }
            }

            //  Remember that we filled
            this._bFilled = true;
        }
    }

    /*
    This method overrides the getter of the psValue property and makes sure that the control value is 
    not used when the combo doesn't have its items yet.
    
    @private
    */
    getControlValue() {
        if (this._eControl && this._bFilled) {
            return this._eControl.value;
        }

        return this.psValue;
    }

    /* 
    Overrides the setControlValue of WebBaseDEO and updates the _bDeferedSet indicator if we could not 
    set the value (it was not in the list) indicating that a refill should update to the psValue.
    
    @param  sVal    New value to display.
    @private
    */
    setControlValue(sVal) {
        if (this._eControl && this._bFilled) {
            this._eControl.value = sVal;

            this._bDeferedSet = this._eControl.value !== sVal;
        } else {
            this._bDeferedSet = true;
        }
    }

    /* 
    Augment the fireChange to set the _bDeferedSet indicator back to false as the value is now change 
    by the user.
    
    @private
    */
    fireChange() {
        this._bDeferedSet = false;

        super.fireChange();
    }

    /*
    Override the default pbCapslock functionallity which sets the CSS text transform. We don't want that 
    for the combo.
    */
    set_pbCapslock(bVal) {

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
    Event handler for the click event that triggers the check for the onchange event.
    
    @param  oEvent  Event details object.
    @private
    */
    onClick(oEvent) {
        this.fireChange();
    }



    updateFocus(bFocus) {
        super.updateFocus(bFocus);

        //Only float the label if peLabelPosition is lpFloat
        if (this.peLabelPosition === df.ciLabelFloat) {
            this.floatLabel(bFocus);
        }

    }

    onLblClick(oEvent) {
        super.onLblClick(oEvent);

        if (this._bHasFocus) {
            /*
            When the label is clicked the select element doesn't actually get a signal to show the picker.
            To fix this we manually call the showPicker function.
            */
            try {
                this._eControl.showPicker();
            } catch (error) {
                //Empty catch block just so we dont get errors in the console
            }
        }
    }

    //Float the label
    floatLabel(bFocus) {
        if (this.getControlValue() != '' || (bFocus & this.isEnabled())) {
            if (this._eLbl != null) {
                df.dom.addClass(this._eLbl, "WebCon_Float");
                df.dom.removeClass(this._eLbl, "WebCon_Unfloat");
            }
        }
        else {
            if (this._eLbl != null) {
                df.dom.addClass(this._eLbl, "WebCon_Unfloat");
                df.dom.removeClass(this._eLbl, "WebCon_Float");
            }
        }
    }

    /*
    Augments the event handler for the keypress event and triggers the check for the onchange event.
    
    @param  oEvent  Event details object.
    @private
    */
    onKey(oEvent) {
        const that = this;

        super.onKey(oEvent);

        if (this.peLabelPosition === df.ciLabelFloat) {
            this.floatLabel(true);
        }

        //  TODO: Find a cleaner way to trigger onChange..
        setTimeout(function () {
            that.fireChange();
        }, 10);
    }
}