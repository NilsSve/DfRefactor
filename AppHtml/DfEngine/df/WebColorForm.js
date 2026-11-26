import { WebForm } from './WebForm.js';
import { WebColorPicker } from './WebColorPicker.js';
import { WebFloatingPanel } from './WebFloatingPanel.js';
import { df } from '../df.js';

/*
Class:
    df.WebColorForm
Extends:
    df.WebForm

This is the popup version of the cWebColorPicker which inherits from cWebForm and extends the 
cWebForm with options to display the color picker in a floating panel. It also displays a box 
showing the color.
    
Revision:
    2016/06/16  (HW, DAW) 
        Initial version.
*/

export class WebColorForm extends WebForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "piPickWidth", 300);
        this.prop(df.tInt, "piPickHeight", 250);
        this.prop(df.tInt, "piPaletteItemsPerRow", 8);
        this.prop(df.tInt, "peColorFormat", df.colorFormatHex);
        this.prop(df.tBool, "pbColorBackground", false);
        this.prop(df.tBool, "pbAutoShow", false);

        //  Configure super classes
        this.pbPromptButton = true;

        this._sControlClass = "WebForm WebColorForm";
    }

    afterRender() {
        super.afterRender();

        df.dom.toggleClass(this._eWrap, "WebCF_ShowBox", !this.pbColorBackground);

        this._eColorBox = df.dom.create('<div class="WebCF_Box"></div>');
        this._eWrap.insertBefore(this._eColorBox, this._eWrap.firstChild);

        df.dom.on("click", this._eColorBox, this.onColorClick, this);

        this.refreshDisplay(this._tValue);
    }

    initPicker() {
        const oPnl = this._oFloatingPanel = new WebFloatingPanel(null, this);
        oPnl.psFloatByControl = this.getLongName();
        oPnl.piWidth = this.piPickWidth;
        oPnl.piHeight = this.piPickHeight;
        oPnl.piColumnCount = 1;
        oPnl.pbHideOnBlur = true;
        oPnl.pbFocusOnShow = true;
        oPnl.pbHideOnEscape = true;
        oPnl.psCSSClass = "NoWhitespace Shadow WebColorForm_FlPnl";
        oPnl.OnHide.addListener(this.onPanelClose, this);
        oPnl.create();

        const oPicker = this._oColorPicker = new WebColorPicker(null, this);
        oPicker.psValue = this.getServerVal();
        oPicker.piColumnSpan = 0;
        oPicker.pbFillHeight = true;
        oPicker.pbShowLabel = false;
        oPicker.pbShowColorBar = false;
        oPicker.peColorFormat = this.peColorFormat;
        oPicker.psCSSClass = "WebColorPicker_Form";
        oPicker.piPaletteItemsPerRow = this.piPaletteItemsPerRow;
        oPicker.OnRealtimeChange.addListener(this.onPickerChange, this);
        oPicker.OnEnter.addListener(this.onPickerEnter, this);
        oPicker.create();

        oPnl.addChild(oPicker);
    }

    /* 
    Augment destroy to destroy the date picker as well.
    
    @private
    */
    destroy() {
        if (this._oFloatingPanel) {
            this._oFloatingPanel.destroy();
        }
        super.destroy();
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

    firePrompt() {
        this.showPicker();
    }

    showPicker() {
        if (!this._oFloatingPanel) {
            this.initPicker();
        }
        if (!this._oFloatingPanel._eElem) {
            this.renderPicker();
        }
        this._oColorPicker.set("psValue", this.getServerVal());
        this._oFloatingPanel.show();
    }

    onColorClick(oEvent) {
        if (this.isEnabled()) {
            this.showPicker();
        }
    }

    onPickerChange(oEvent) {
        this._tValue = oEvent.sColor;
        this.refreshDisplay(oEvent.sColor);
    }

    onPickerEnter(oEvent) {
        //var sPrevColor = this.getServerVal();

        this._tValue = oEvent.sColor;
        this.refreshDisplay(oEvent.sColor);

        this._oFloatingPanel.hide();
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

    onPickerClose(oEvent) {
        this._oFloatingPanel.hide();

    }

    set_pbColorBackground(bVal) {
        this.set_psBackgroundColor((bVal ? this.getServerVal() : ""));

        if (this._eWrap) {
            df.dom.toggleClass(this._eWrap, "WebCF_ShowBox", !bVal);
        }
    }

    setControlValue(sVal) {
        super.setControlValue(sVal);

        if (this.pbColorBackground) {
            this.set_psBackgroundColor(sVal);
        }
        if (this._eColorBox) {
            this._eColorBox.style.backgroundColor = sVal;
        }
    }

    set_piPickHeight(iVal) {
        if (this._oFloatingPanel) {
            this._oFloatingPanel.set("piHeight", iVal);
        }
    }

    set_piPickWidth(iVal) {
        if (this._oFloatingPanel) {
            this._oFloatingPanel.set("piWidth", iVal);
        }
    }

    set_piPaletteItemsPerRow(iVal) {
        if (this._oColorPicker) {
            this._oColorPicker.set("piPaletteItemsPerRow", iVal);
        }
    }

    /* 
    Called to add a single color to the color palette. Updates the palette if we've already rendered.
    
    @param  sColor          Color in hex or rgb string format.
    @param  sDescription    Text shown as title on the element.
    
    @client-action
    */
    addPaletteItem(sColor, sDescription) {
        if (!this._oFloatingPanel) {
            this.initPicker();
        }

        //  Pass on to color picker
        this._oColorPicker.addPaletteItem(sColor, sDescription);
    }

    /* 
    Called to refresh the entire color palette at once. Colors are sent as action data (array of 
    tWebColorPaletteItem items).
    
    @client-action
    */
    updatePalette() {
        if (!this._oFloatingPanel) {
            this.initPicker();
        }

        //  Pass on to color picker including action data.
        this._oColorPicker._tActionData = this._tActionData;
        this._oColorPicker.updatePalette();
        this._oColorPicker._tActionData = null;
    }

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