import { WebForm } from './WebForm.js';
import { WebModalDialog } from './WebModalDialog.js';
import { WebFloatingPanel } from './WebFloatingPanel.js';
import { WebDatePicker } from './WebDatePicker.js';
import { df } from '../df.js';

/*
Class:
    df.WebDateForm
Extends:
    df.WebForm

This class is the client-side representation of the cWebDateForm and renders a form with a date 
picker button as the prompt button. It uses the df.DatePicker class to render the actual date 
picker.
    
Revision:
    2012/03/16  (HW, DAW) 
        Initial version.
*/

// - - - Control API - - -
/*
Augment the afterRender method that is called when the DOM elements are created. We use it to 
instantiate the DatePicker object and to let that render itself (hidden). We also inject the focus 
holder Anchor element.

@private
*/
export class WebDateForm extends WebForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbShowWeekNr", true);
        this.prop(df.tBool, "pbShowToday", true);
        this.prop(df.tInt, "piStartWeekAt", 1);
        this.prop(df.tBool, "pbAutoShow", false);
        this.prop(df.tBool, "pbModal", false);

        this.prop(df.tBool, "pbHtml5NativeOnMobile", true);

        //  Configure super classes
        this.pbPromptButton = true;

        // @privates
        this._ePickerWrp = null;
        this._eFocus = null;
        this._bPickerVisible = false;
        this._bSkipAutoShow = false;
        this._bShowWait = false;
        this._iWidth = 0;
        this._iHeight = 0;
        this._tOnChange = null;

        this._sControlClass = "WebForm WebDateForm";

        this._eParentRef = null;
    }

    afterRender() {
        super.afterRender();

        //  Create hidden focus element (used while the picker is shown)
        //this._eFocus = df.dom.create('<div class="WebDateForm_FocusHolder" tabindex="-1" style="display: none; position: absolute; width: 1px; height: 1px;"></div>');
        // this._eWrap.appendChild(this._eFocus);

        //df.dom.on("focus", this._eFocus, this.onPickFocus, this);
        //df.dom.on("blur", this._eFocus, this.onPickBlur, this);

        //  On mobile devices we create a hidden date field to trick the browser into using the native date picker
        if (this.pbHtml5NativeOnMobile && df.sys.isMobile && df.sys.supportHtml5Input("date")) {
            this._ePrompt.innerHTML = '<div class="WebDF_HiddenDate"><input type="date"></div>';

            this._eHtml5HiddenDate = df.dom.query(this._ePrompt, "input");

            df.dom.on("change", this._eHtml5HiddenDate, this.html5OnChange, this);
            df.dom.on("input", this._eHtml5HiddenDate, this.html5OnChange, this);
        }
    }

    /* 
    Augment destroy to destroy the date picker as well.
    
    @private
    */
    destroy() {
        if (this._oFloatingPanel) {
            this._oFloatingPanel.destroy();
            this._oFloatingPanel = null;
            this._oPicker = null;
        }
        super.destroy();
    }

    // - - - Server API - - -
    set_pbShowWeekNr(bVal) {
        if (this._oPicker) {
            this._oPicker.set("pbShowWeekNr", bVal);
        }
    }

    set_pbShowToday(bVal) {
        if (this._oPicker) {
            this._oPicker.set("pbShowToday", bVal);
        }
    }

    set_piStartWeekAt(iVal) {
        if (this._oPicker) {
            this._oPicker.set("piStartWeekAt", iVal);
        }
    }

    // - - - Implementation - - -

    /*
    Augment setControlValue to also update the hidden date field when it is used.
    
    @param  sVal    New value.
    */
    setControlValue(sVal) {
        super.setControlValue(sVal);

        //  Also update the hidden date field as updating it when opening it is too late for IOS
        if (this._eHtml5HiddenDate) {
            this._eHtml5HiddenDate.value = (this._tValue && df.sys.data.dateToString(this._tValue, "yyyy/mm/dd", "-")) || "";
        }
    }

    /* 
    Handles the onchange and oninput events from the hidden <input type=date form and updates the form 
    its value with this new date.
    
    @param  oEvent  Event object (see: df.events.DOMEvent)
    @private
    */
    html5OnChange(oEvent) {
        const that = this;

        this._tValue = df.sys.data.stringToDate(this._eHtml5HiddenDate.value, "yyyy-mm-dd", "-");

        //  Update the displayed value
        this.refreshDisplay(this._tValue);

        if (this._tOnChange) {
            clearTimeout(this._tOnChange);
        }
        this._tOnChange = setTimeout(function () {
            that.fireChange();
            that._tOnChange = null;
        }, 150);
    }

    /*
    Initializes the picker components (floating panel and date picker).
    */
    initPicker() {
        let oPicker, oPnl;

        if (this.pbModal) {
            oPnl = this._oFloatingPanel = this.createModalDialog();
        } else {
            oPnl = this._oFloatingPanel = this.createPanel();
        }

        this.configurePanel(oPnl);
        oPnl.create();

        this._oPicker = oPicker = this.createDatePicker();

        this.configureDatePicker(oPicker);
        oPicker.create();

        oPnl.addChild(oPicker);
    }

    /*
    @returns New panel instance used to display the date picker in.
    */
    createPanel() {
        return new WebFloatingPanel(null, this);
    }

    createModalDialog() {
        return new WebModalDialog(null, this);
    }

    /*
    Sets the properties of the floating panel and attach the event handlers.
    
    @param oPnl The new panel to configure.
    */
    configurePanel(oPnl) {
        oPnl.psFloatByControl = this.getLongName();
        oPnl.piColumnCount = 1;
        oPnl.pbHideOnBlur = true;
        oPnl.pbFocusOnShow = true;
        oPnl.pbHideOnEscape = true;
        oPnl.pbNaturalWidth = true;
        oPnl.psCSSClass = "NoWhitespace Shadow WebDateForm_FlPnl";
        oPnl.OnHide.addListener(this.onPanelClose, this);
    }

    /*
    @returns New instance of the WebDatePicker.
    */
    createDatePicker() {
        return new WebDatePicker(null, this);
    }

    /*
    Sets the properties on the date picker and attaches event handlers.
    
    @param oPicker  The datepicker to configure.
    */
    configureDatePicker(oPicker) {
        //  Standard config
        oPicker.pbShowLabel = false;
        oPicker.psValue = this.getServerVal();
        oPicker.piColumnSpan = 0;
        oPicker.pbShowWeekNr = this.pbShowWeekNr;
        oPicker.pbShowToday = this.pbShowToday;
        oPicker.piStartWeekAt = this.piStartWeekAt;
        oPicker.psMask = this.getWebApp().psDateFormat;

        oPicker.psCSSClass = "WebDatePicker_Form NoWhitespace";
        oPicker.OnRealtimeChange.addListener(this.onPickerChange, this);
        oPicker.OnEnter.addListener(this.onPickerEnter, this);
    }

    renderPicker() {
        const oPnl = this._oFloatingPanel;

        const ePnl = oPnl.render();
        if (ePnl) {
            this._eElem.parentNode.insertBefore(ePnl, this._eElem);
        }
        oPnl.afterRender();
        oPnl.resizeHorizontal();
        oPnl.resizeVertical();

    }


    showPicker() {
        if (!this._oFloatingPanel) {
            this.initPicker();
        }
        if (!this._oFloatingPanel._eElem) {
            this.renderPicker();
        }
        this._oPicker._bBuddyActive = true;
        this._oPicker.set("psValue", this.getServerVal());
        this._oFloatingPanel.show();

        //Float the modal dialog next to the WebDateForm
        if (this.pbModal) {
            this._oFloatingPanel.floatByControl();
        }

        this._bPickerVisible = true;
    }


    /*
    This method hides the date picker by removing the 'WebDF_WrapVisible' class so that a CSS3 
    transformation can be used.
    */
    hideDatePicker(bOptNoFocus) {
        this._bPickerVisible = false;
        if (this._oFloatingPanel) {
            this._oPicker._bBuddyActive = false;
            this._oFloatingPanel.hide();
        }
    }

    /*
    This method overrides the firePrompt method and makes it display the calendar. We don't fire the 
    OnPrompt event at all anymore.
    
    @private
    */
    firePrompt() {
        if (this.isEnabled() && !this.pbReadOnly) {
            //  If an hiden HTML5 date field is used we don't need to show the date picker but we need to update that field with the right value
            if (this._eHtml5HiddenDate) {
                this.updateTypeVal();

                if (this._tValue) {
                    this._eHtml5HiddenDate.value = df.sys.data.dateToString(this._tValue, "yyyy/mm/dd", "-");
                } else {
                    this._eHtml5HiddenDate.value = "";
                }

                return true;
            }

            this.showPicker();
            //this.focus();

            return true;
        }
    }


    onPickerChange(oEvent) {
        this._tValue = oEvent.dValue;
        this.refreshDisplay(oEvent.dValue);
    }

    onPickerEnter(oEvent) {
        if (this.peDataType === df.ciTypeDate || this.peDataType === df.ciTypeDateTime) {
            this._tValue = oEvent.dValue;
            this.refreshDisplay(this._tValue);
        }

        this.hideDatePicker();
        this.focus();
        this.fireChange();
    }


    onPanelClose(oEvent) {
        const sReason = oEvent.aParams[0];

        this.fireChange();

        if (sReason !== "auto_blur") {
            this._bSkipAutoShow = true;
            this.focus();
        }
    }

    // - - - - - - - Focus - - - - - - -


    /*
    This method augments the onFocus event of the display field and handles two different scenarios. If 
    the date picker is visible then this means that the user manually passed the focus to the input 
    field. In that case we hide the date picker. If the date picker is not visible then we might need to 
    show the date picker if pbAutoShow is true. The _bSkipAutoShow property can be set to true to 
    prevent recursive loops. 
    
    @param  oEvent  Event object (see: df.events.DOMEvent).
    */
    onFocus(oEvent) {
        super.onFocus(oEvent);

        if (this.pbAutoShow && this.isEnabled() && !this.pbReadOnly && !this._bSkipAutoShow) {
            this.showPicker();
        }

        this._bSkipAutoShow = false;
    }
}