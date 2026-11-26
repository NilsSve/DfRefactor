import { WebBaseContainer } from './WebBaseContainer.js';
import { WebCardContainer } from './WebCardContainer.js';
import { df } from '../df.js';
/*
Class:
    df.WebCard
Extends:
    df.WebBaseContainer

This class is the client-side representation of the cWebCard and is responsible for rendering the 
tab page. It works closely together with the WebTabPanel. The WebCard acts as a container and it 
inherits this functionality from the WebBaseContainer class.
    
Revision:
    2011/10/13  (HW, DAW) 
        Initial version.
    2012/10/02  (HW, DAW)
        Split into WebCard and WebTabPage.
*/
export class WebCard extends WebBaseContainer {
    constructor(sName, oParent) {
        super(sName, oParent);
        //  Assertions
        if (!(oParent && oParent instanceof WebCardContainer)) {
            throw new df.Error(999, "WebCard object '{{0}}' should be placed inside a WebCardContainer object. Consider wrapping your card with a card container.", this, [this.getLongName()]);
        }

        //  Web Properties
        this.prop(df.tString, "psCaption", "");
        this.prop(df.tString, "psBtnCSSClass", ""); // Note that this property is defined on cWebTabPage


        //  Events
        this.event("OnShow", df.cCallModeDefault);
        this.event("OnHide", df.cCallModeDefault);

        //@privates
        this._eBtn = null;
        this._eLbl = null;
        this._bCurrent = false;
        this._bCC = true; //  Used by the designer to filter cardcontainers from tab / accordion containers


        //  Configure super classes
        this._sControlClass = "WebCard";
        this._bWrapDiv = true;
    }

    // - - - - - Rendering - - - - -

    /*
    This method is called by the WebTabPanel to generate the HTML for the button representing this tab 
    page.
    
    @param  aHtml   Array string builder to add the HTML to.
    @private
    */
    tabButtonHtml(aHtml) {
        aHtml.push('<div class="WebTab_Btn ', (this.isEnabled() ? df.CssEnabled : df.CssDisabled), ' ', this.psBtnCSSClass, '" style="', (!this.pbRender || !this.pbVisible ? 'display: none;' : ''), '" ', (!this.isEnabled() ? 'tabindex="-1"' : 'tabindex="0"'), '><span><label>', df.dom.encodeHtml(this.psCaption), '</label></span></div>');
    }

    /*
    Augments the afterRender method to get references to DOM elements, attach event handlers and call 
    setters.
    
    @private
    */
    afterRender() {
        super.afterRender();

        //  Remove "display none" added by parent class if pbRender = false
        this._eElem.style.display = '';
    }

    /* 
    Called by the card container when the tab button is rendered. Adds event handlers.
    
    @param  eBtn    Button DOM element.
    @private
    */
    btnRendered(eBtn) {
        this._eBtn = eBtn;

        this._eLbl = df.dom.query(this._eBtn, 'span > label'); //   WebTabPanel assings the _eBtn already
        df.dom.on("click", this._eBtn, this.onBtnClick, this);
        df.dom.on("click", this._eLbl, this.onBtnClick, this);
        df.events.addDomKeyListener(this._eBtn, this.onBtnKey, this);
    }

    attachFocusEvents() {
        //  We are attaching a DOM capture listener so we know when we get the focus
        if (window.addEventListener) {
            df.events.addDomCaptureListener("focus", this._eBtn, this.onBtnFocus, this);
            df.events.addDomCaptureListener("blur", this._eBtn, this.onBtnBlur, this);
        } else {
            df.dom.on("focusin", this._eBtn, this.onBtnFocus, this);
            df.dom.on("focusout", this._eBtn, this.onBtnBlur, this);
        }
    }

    prepareSize() {
        const iResult = super.prepareSize();

        this._bStretch = true;

        return iResult;
    }

    // - - - - - Internal - - - - -

    /*
    This event handler handles the click event of the tab button. 
    
    @param  
    */
    onBtnClick(oEvent) {
        if (this.isEnabled()) {
            this.show();
            oEvent.stop();
        }
    }


    /*
    Handles the keypress event of the hidden focus anchor. Compares the event 
    details to the oKeyActions and executes the action if a match is found.
    
    @param  oEvent  Event object.
    @private
    */
    onBtnKey(oEvent) {
        if (this.isEnabled()) {

            if (oEvent.matchKey(df.settings.tabKeys.enter)) {
                this.show();
                oEvent.stop();
            }
        }
    }

    onBtnFocus(oEvent) {
        df.dom.addClass(this._eBtn, "WebTab_Focus");
    }

    onBtnBlur(oEvent) {
        df.dom.removeClass(this._eBtn, "WebTab_Focus");
    }

    /*
    This method is called by the WebTabPanel to hide this tab page. Note that switching a tab always 
    causes this method to be called regardless whether it was already hidden.
    
    @param  bFirst  True if this method is called during initialization.
    @private
    */
    _hide(bFirst) {
        if (this._eElem) {
            this._eElem.style.visibility = "hidden";
            df.dom.removeClass(this._eBtn, "WebTab_Current");
        }

        if (!bFirst && this._bCurrent) {
            this.fire('OnHide');
        }

        this._bCurrent = false;
    }

    /*
    This method is called by the WebTabPanel to show this tab page.
    
    @param  bFirst  True if this method is called during initialization.
    @private
    */
    _show(bFirst) {
        if (!this._eElem) {
            this.renderCard(true);
        } else {
            if (this._eElem.parentNode.firstChild && this._eElem !== this._eElem.parentNode.firstChild) {
                this._eElem.parentNode.insertBefore(this._eElem, this._eElem.parentNode.firstChild);
            }
        }

        this._eElem.style.visibility = "inherit";
        df.dom.addClass(this._eBtn, "WebTab_Current");


        if (!bFirst && !this._bCurrent) {
            this.fire('OnShow');
        }
        this._bCurrent = true;
    }

    renderCard(bFirstElem) {
        //  We render the card if it wasn't rendered yet
        const eElem = this.render();
        if (bFirstElem && this._oParent._eControl.firstChild) {
            this._oParent._eControl.insertBefore(eElem, this._oParent._eControl.firstChild);
        } else {
            this._oParent._eControl.appendChild(eElem);
        }

        this.afterRender();

        this.resizeHorizontal();
        this.resizeVertical();
        this._oParent?.sizeChanged();

    }

    /*
    This method shows this tabpage which might cause other tabpages to hide.
    */
    show() {
        if (this.isActive()) {
            this._oParent.showCard(this);
        }
    }

    /* 
    Augments applyEnabled to update the CSS class and tabIndex of the tab button element.
    
    @param  bVal    The enabled state.
    */
    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eBtn) {
            df.dom.toggleClass(this._eBtn, df.CssDisabled, !bVal);
            df.dom.toggleClass(this._eBtn, df.CssEnabled, bVal);
            df.dom.setTabIndex(this._eLbl, (bVal ? 0 : -1));
        }
    }

    /*
    Augment to show the current tab / card.
    */
    makeVisible() {
        this.show();

        super.makeVisible();
    }

    // - - - - - Setters - - - - -

    set_psCaption(sVal) {
        if (this._eLbl) {
            //  Update the card container label
            if (this._oParent._oCurrent === this && this._oParent._eLabel) {
                df.dom.setText(this._oParent._eLabel, sVal);
            }

            //  Update the tab button label
            df.dom.setText(this._eLbl, sVal);
        }
    }

    set_pbVisible(bVal) {
        if (this._eBtn) {
            this._eBtn.style.display = (bVal && this.pbRender ? '' : 'none');

            //  Update property because it will be used by hideCard and showCard
            this.pbVisible = bVal;

            //  Wait for all processing to be done and then make sure that we end up with a 'valid' situation
            this.getWebApp().waitForCall(function () {
                if (!bVal) {
                    if (this._bCurrent) {
                        this._oParent.hideCard(this);
                    }
                } else {
                    if (!this._oParent._oCurrent) {
                        this._oParent.showCard(this);
                    }
                }

                this.getWebApp().forceResize();
            }, this);
        }
    }

    set_pbRender(bVal) {
        if (this._eBtn) {
            this._eBtn.style.display = (bVal && this.pbVisible ? '' : 'none');

            if (this.pbRender !== bVal) {
                //  Update property because it will be used by hideCard and showCard
                this.pbRender = bVal;

                //  Wait for all processing to be done and then make sure that we end up with a 'valid' situation
                this.getWebApp().waitForCall(function () {
                    if (!bVal) {
                        if (this._bCurrent) {
                            this._oParent.hideCard(this);
                        }
                    } else {
                        if (!this._oParent._oCurrent) {
                            this._oParent.showCard(this);
                        }
                    }

                    this.getWebApp().forceResize();
                }, this);
            }
        }
    }

    set_psTextColor(sVal) {
        if (this._eLbl) {
            this._eLbl.style.color = sVal || '';
        }

        super.set_psTextColor(sVal);
    }

    set_psBackgroundColor(sVal) {
        if (this._eBtn) {
            this._eBtn.style.background = sVal || '';
        }

        super.set_psBackgroundColor(sVal);
    }

    set_psBtnCSSClass(sVal) {
        if (this._eBtn && this.psBtnCSSClass !== sVal) {
            df.dom.removeClass(this._eBtn, this.psBtnCSSClass);
            df.dom.addClass(this._eBtn, sVal);
        }
    }
}