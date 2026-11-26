import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebButton
Extends:
    df.WebBaseControl

This class is the client-side implementation of the cWebButton. It renders a button using the 
<button html element. The OnClick is usually implemented on the server. Special support is available 
for showing a waiting dialog when the call is being sent (pbShowWaitDialog and pbWaitMessage).
    
Revision:
    2011/08/02  (HW, DAW) 
        Initial version.
*/
export class WebButton extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Web Properties
        this.prop(df.tString, "psCaption", "");
        this.prop(df.tString, "psTextColor", "");
        this.prop(df.tString, "psWaitMessage", "");
        this.prop(df.tBool, "pbShowWaitDialog", false);
        this.prop(df.tInt, "peAlign", -1);

        //  Events
        this.event("OnClick", df.cCallModeWait);



        //  Configure super classes
        this.pbShowLabel = false;

        // @privates
        this._sControlClass = "WebButton";
        this._bJSSizing = false;
    }

    create() {
        super.create();

        this.set_pbShowWaitDialog(this.pbShowWaitDialog);
    }

    /*
    This method generates the HTML for the button.
    
    @param  aHtml   Array used as string builder for the HTML.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<button id="', this._sControlId, '"', (!this.isEnabled() ? ' disabled="disabled"' : ''));
        if (this.peAlign >= 0) {
            aHtml.push(' style="text-align: ', df.sys.gui.cssTextAlign(this.peAlign), '"');
        }
        aHtml.push('>', df.dom.encodeHtml(this.psCaption), '</button>');
    }

    /*
    This method is called after the HTML is added to the DOM and provides a hook for doing additional implementation. It gets references to the DOM elements, adds event handlers and executes setters t
    
    @private
    */
    afterRender() {
        //  Get references
        this._eControl = df.dom.query(this._eElem, "button");

        super.afterRender();

        //  Attach listeners
        df.dom.on("click", this._eControl, this.onBtnClick, this);
        df.events.addDomKeyListener(this._eElem, this.onKey, this);
    }

    /*
    Event handler for the OnClick event of the button. It fires the OnClick event of the framework which 
    is usually handled on the server.
    
    @param  oEvent  Event object (df.events.DOMEvent).
    @private
    */
    onBtnClick(oEvent) {
        let tTimer = null, bDone = false;
        const eElem = this._eElem;

        if (this.isEnabled()) {
            df.dom.addClass(eElem, df.CssHit);
            tTimer = setTimeout(function () {
                if (bDone) {
                    df.dom.removeClass(eElem, df.CssHit);
                }
                tTimer = null;
            }, df.hitTimeout);

            this.fire('OnClick', [], function (oEvent) {
                //  Determine if a view needs to be loaded
                if (!oEvent.bCanceled) {
                    if (this.psLoadViewOnClick) {
                        this.getWebApp().showView(this.psLoadViewOnClick, false);
                    }
                }

                if (!tTimer) {
                    df.dom.removeClass(eElem, df.CssHit);
                }
                bDone = true;
            });
            oEvent.stop();
        }
    }

    /*
    Augments the applyEnabled method to disable the button by setting the disabled attribute of the 
    button HTML element.
    
    @param  bVal    The new value.
    */
    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eControl) {
            this._eControl.disabled = !bVal;
        }
    }

    /*
    Setter method for psCaption which is the text shown on the button.
    
    @param  sVal    The new value.
    */
    set_psCaption(sVal) {
        if (this._eControl) {
            df.dom.setText(this._eControl, sVal);

            this.sizeChanged();
        }
    }

    /*
    The setter method for pbShowWaitDialog which changes the action mode of the 'OnClick' from 
    df.cCallModeWait to df.cCalModeProgress so that the framework will display the waiting dialog 
    during the server call.
    
    @param  bVal    The new value.
    */
    set_pbShowWaitDialog(bVal) {
        this.setActionMode("OnClick", (bVal ? df.cCallModeProgress : df.cCallModeWait), this.psWaitMessage);
    }

    /* 
    Ther setter method for psWaitMessage which updates the action mode of the OnClick server call with 
    the new wait message.
    
    @param  sVal    The new value.
    */
    set_psWaitMessage(sVal) {
        this.setActionMode("OnClick", (this.pbShowWaitDialog ? df.cCallModeProgress : df.cCallModeWait), sVal);
    }

    /*
    Handles the onKey event and makes sure that it doesn't propagate the enter key to stop the onsubmit 
    event of the view / dialog.
    
    @param  oEvent  Event object (see: df.events.DOMEvent).
    @private
    */
    onKey(oEvent) {
        //  Make sure that the OnSubmit doesn't fire by canceling the propagation (but leaving the default behavior, OnClick intact)
        if (oEvent.matchKey(df.settings.formKeys.submit)) {
            oEvent.stopPropagation();
        }
    }

    set_peAlign(eVal) {
        if (this._eControl) {
            this._eControl.style.textAlign = df.sys.gui.cssTextAlign(eVal);
        }
    }
}