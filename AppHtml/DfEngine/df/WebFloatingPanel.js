import { WebBaseContainer } from './WebBaseContainer.js';
import { df } from '../df.js';
/* 
Class:
    df.WebFloatingPanel
Extends:
    df.WebBaseContainer
    
A copy of the WebFloatingPanel that is extended with several features including a pePosition 
property allowing it to be positioned in multiple ways.

The WebFloatingPanel is a private class of the framework being used internally. This extended 
version is a step towards making it a public class in future revisions.

Revision:
    2016/05/24 (HW, DAE)
 */

//  Values for pePosition
df.fpFloatByControl = 1;
df.fpFloatLeftSqueezeWebApp = 2;
df.fpFloatLeftPushWebApp = 3;
df.fpFloatFixed = 4;
df.fpFloatAbsolute = 5;

export class WebFloatingPanel extends WebBaseContainer {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tInt, "piWidth", 0);
        this.prop(df.tInt, "piHeight", 0);

        this.prop(df.tInt, "piTop", -1);
        this.prop(df.tInt, "piLeft", -1);
        this.prop(df.tInt, "piBottom", -1);
        this.prop(df.tInt, "piRight", -1);

        this.prop(df.tInt, "piContentWidth", 0);

        this.prop(df.tString, "psFloatByControl", "");
        this.prop(df.tBool, "pbHideOnBlur", false);
        this.prop(df.tBool, "pbHideOnEscape", false);
        this.prop(df.tBool, "pbFocusOnShow", false);

        this.prop(df.tInt, "pePosition", df.fpFloatByControl);
        this.prop(df.tBool, "pbShrinkIfNoSpace", false);
        this.prop(df.tBool, "pbNaturalWidth", false);

        this.event("OnHide");

        this._eMask = null;

        this.pbScroll = false;
        this.pbVisible = false;
        this._bViewVisible = false;
        this._bWrapDiv = false;
        this._bVisible = false; //  Keeps track of actually being visible (outside of close animation)

        this._bFloating = true;
        this._sControlClass = "WebFlPnl";
    }

    /* 
    Pre rendering initialization.
    
    @private
    */
    create() {
        //  Check if we are in a view, if so we listen to its OnShow and OnHide events, else we just start it
        const oView = this.getView();
        if (oView) {
            oView.OnAfterShow.on(this.showView, this);
            oView.OnAfterHide.on(this.hideView, this);
            this._bViewVisible = oView._bShown;
        } else {
            this._bViewVisible = true;
        }

        super.create();
    }

    /*
    DF20.1 We forgot to remove the afterShow and afterHide event listener.
    
    @private
    */
    destroy() {
        const oView = this.getView();
        if (oView) {
            oView.OnAfterShow.off(this.showView, this);
            oView.OnAfterHide.off(this.hideView, this);
        }

        super.destroy();
    }

    /* 
    Augment the rendering and insert the element at root level. Don't return the element since the 
    parent shouldn't insert it.
    
    @private
    */
    render() {
        const eElem = super.render();

        const eParent = this.topLayer() || document.body;
        eParent.appendChild(eElem);

        return null;
    }

    /*
    Augment genClass to add extra classes depending on configuration.
    
    @return String with CSS classnames for outermost div (space separated).
    @private
    */
    genClass() {
        const aClasses = [super.genClass()];

        if (this.pePosition === df.fpFloatByControl) {
            aClasses.push('WebFP_ArrowTop');
            aClasses.push('WebFP_FloatBy');
        }
        if (this.pePosition === df.fpFloatLeftSqueezeWebApp || this.pePosition === df.fpFloatLeftPushWebApp) {
            aClasses.push("WebFP_FloatLeft");
        }

        if (!this.pbVisible) {
            aClasses.push("WebFP_Hidden");
        } else {
            aClasses.push("WebFP_Visible");
        }

        if (this.piContentWidth > 0) {
            aClasses.push("WebFP_FixedContentWidth");
        }

        return aClasses.join(" ");
    }

    /* 
    Generate opening HTML.
    
    @param  aHtml   Stringbuilder array.
    @private
    */
    openHtml(aHtml) {
        aHtml.push('<div class="', this.genClass(), '" style="display: none"');
        if (this.psHtmlId) {
            aHtml.push(' id="', this.psHtmlId, '"');
        }

        //  Insert the object name so the HTML element can be traced back to the right object
        aHtml.push(' data-dfobj="', this.getLongName(), '"');

        aHtml.push(' tabindex="0" style=" ', (this.pbRender ? '' : 'display: none;'), '"'); //'visibility: hidden;"');
        aHtml.push('>');
        aHtml.push('<div tabindex="', (this.pbHideOnBlur ? '0' : '-1'), '" class="WebFP_FocusCatcher"></div>');
        aHtml.push('<div class="WebContainer">');

        super.openHtml(aHtml);

    }

    /* 
    Generate closing HTML.
    
    @param  aHtml   Stringbuilder array.
    @private
    */
    closeHtml(aHtml) {
        super.closeHtml(aHtml);
        aHtml.push('</div>');
        aHtml.push('<div tabindex="', (this.pbHideOnBlur ? '0' : '-1'), '" class="WebFP_FocusCatcher"></div>');
        aHtml.push('<div class="WebFP_Arrow"></div>');
        aHtml.push('</div>');


    }

    /* 
    Post rendering initialization. Get references, add dom listeners and show the panel if needed.
    
    @private
    */
    afterRender() {
        this._eArrow = df.dom.query(this._eElem, "div.WebFP_Arrow");
        this._aFocusCatchers = df.dom.query(this._eElem, "div.WebFP_FocusCatcher", true);

        super.afterRender();

        df.events.addDomCaptureListener("focus", this._eElem, this.onCaptureFocus, this);
        df.events.addDomCaptureListener("blur", this._eElem, this.onCaptureBlur, this);
        df.events.addDomKeyListener(this._eElem, this.onKey, this);
        df.dom.on("focus", this._aFocusCatchers, this.onCatchFocus, this);

        if (this.piContentWidth > 0) {
            this._eSizer.style.width = this.piContentWidth + 'px';
        }

        if (this.pbVisible && this._bViewVisible) {
            this.show();
        } else {
            this.positionPnl();
        }

    }


    /* 
    Shows the floating panel by changing pbVisible to true.
    */
    show() {

        this.pbVisible = true;

        this.addSync("pbVisible");

        if (this._bViewVisible) {
            this.doShow();
        }
    }

    /* 
    Shows the panel by manipulating the DOM and making sure it gets positioned properly.
    
    @private
    */
    doShow() {
        const that = this;

        this._bVisible = true;
        this._eElem.style.display = "";

        //  Make sure we are the last child in the container..
        if (this._eElem.parentNode.lastChild !== this._eElem) {
            this._eElem.parentNode.appendChild(this._eElem);
        }


        //  Generate a mask to intercept clicks outside to hide the menu (mobile only)
        if (this.pbHideOnBlur && df.sys.isMobile || this.pePosition === df.fpFloatLeftPushWebApp) {
            if (!this._eMask) {
                this._eMask = df.dom.create('<div class="WebMenu_Mask">&nbsp;</div>');

                this._eElem.parentNode.insertBefore(this._eMask, this._eElem);
                df.dom.on("click", this._eMask, this.onMaskTouch, this);
            }
        }

        //  Add blur listener for hide on blur to the floatbycontrol
        if (this.pePosition === df.fpFloatByControl) {
            const oObj = this.getWebApp().findObj(this.psFloatByControl);
            if (oObj && oObj._eElem) {
                this._eBlurBuddy = oObj._eElem;
                df.events.addDomCaptureListener("blur", oObj._eElem, this.onCaptureBlur, this);
            }
        }

        //this._eElem.style.visibility = "";

        this.positionPnl();

        this.afterShow();

        if (this._tHideBlurTimeout) {
            // df.debug("Bur timeout cleared because of show");
            clearTimeout(this._tHideBlurTimeout);
            this._tHideBlurTimeout = null;
        }


        df.dom.removeClass(that._eElem, "WebFP_Hidden");
        df.dom.addClass(that._eElem, "WebFP_Visible");

        setTimeout(function () {
            if (that._eElem) {
                that.positionPnl();
                if (that.pbFocusOnShow) {
                    if (!that.focus()) {
                        that._eElem.focus();
                    }
                }
            }
        }, 20);

        if (this.pePosition === df.fpFloatByControl) {
            this._tPositionInterval = setInterval(function () {
                that.positionPnl();
            }, 500);
        }
    }


    getFloatByRefElem() {
        let eRef = null;

        const oObj = this.getWebApp().findObj(this.psFloatByControl);

        if (oObj) {
            eRef = oObj._eElem;
            if (oObj.getTooltipElem) {
                eRef = oObj.getTooltipElem() || eRef;
            }
        }

        return eRef;
    }


    /* 
    Main positioning logic of the floating panel. Called on resize and on events like showing and 
    hiding.
    */
    positionPnl() {
        let oRect, iTop = 0, iLeft = 0, iRight = -1, iArrow = 0, iHeight, iActualHeight, bTop = true;

        if (this._bVisible && this._eElem) {
            const oWebApp = this.getWebApp();

            let iWidth = this.piWidth;
            iHeight = this.piHeight;

            const iScreenWidth = df.dom.windowWidth();
            const iScreenHeight = df.dom.windowHeight();

            //  Determine height to work with
            iActualHeight = this._eElem.offsetHeight;
            if (iHeight > iActualHeight) {
                iActualHeight = iHeight;

            }

            const iActualWidth = this._eElem.offsetWidth;

            if (this.pePosition === df.fpFloatByControl) {
                const eRef = this.getFloatByRefElem();
                const oRect = df.sys.gui.getBoundRect(eRef);
                if (this.psFloatByControl) {  //  Position relative to a control (usually below the control)
                    if (eRef) {
                        if (iWidth <= 0 && !this.pbNaturalWidth) {
                            iWidth = oRect.width;
                        }

                        iTop = oRect.bottom;
                        // df.debug("oRect.left:" + oRect.left + " oRect.width:" + oRect.width + " this.piWidth:" + this.piWidth);
                        iLeft = oRect.left + (oRect.width / 2) - ((this.pbNaturalWidth ? iActualWidth : iWidth) / 2);

                        if (iLeft < 5) {
                            iLeft = 5;
                        }

                        //  Position Arrow
                        iArrow = oRect.left + oRect.width / 2 - iLeft;

                        if (!oRect.top && !oRect.left && !oRect.width && !oRect.height) {
                            return;
                        }
                    } else {
                        iTop = this.piTop;
                        iLeft = this.piLeft;
                    }


                }


                if (iWidth > (iScreenWidth - 20)) {
                    iWidth = iScreenWidth - 20;
                }

                if (iLeft + iWidth > iScreenWidth) {
                    iLeft = -1;
                    iRight = 10;

                    //  Position Arrow
                    iArrow = iWidth - ((iScreenWidth - oRect.right) + oRect.width / 2 - iRight);
                }

                if (iTop + iActualHeight > iScreenHeight) {
                    if (!this.pbShrinkIfNoSpace) {
                        if (oRect) {
                            iTop = Math.max(0, oRect.top - iActualHeight);
                            bTop = false;
                        }
                    }

                    if (iTop + iHeight > iScreenHeight) {
                        if (iHeight > 0) {
                            iHeight = iScreenHeight - iTop - 30;
                            //(iScreenHeight - iTop > 0 ? iScreenHeight - iTop : 0);
                        } else {
                            iTop = (iScreenHeight - iHeight > 0 ? iScreenHeight - iHeight : 0);
                        }
                    }
                }

                this._eElem.style.top = iTop + "px";

                this._eElem.style.left = (iLeft >= 0 ? iLeft + "px" : "");
                this._eElem.style.right = (iRight >= 0 ? iRight + "px" : "");

                this._eArrow.style.left = iArrow + "px";

                this.setOuterWidth(iWidth);
                if (iHeight > 0) {
                    this._eContainer.style.height = iHeight + "px";
                    this._eElem.style.maxHeight = "";
                } else {
                    iHeight = iScreenHeight - iTop - 30;// - this.getHeightDiff(true, false, false, false);
                    this._eContainer.style.height = "";
                    this._eElem.style.maxHeight = iHeight + "px";
                }

                df.dom.toggleClass(this._eElem, "WebFP_ArrowTop", bTop);
                df.dom.toggleClass(this._eElem, "WebFP_ArrowBottom", !bTop);
            }

            if (this.pePosition === df.fpFloatLeftSqueezeWebApp || this.pePosition === df.fpFloatLeftPushWebApp) {
                this._eElem.style.top = (df.Designer ? "17px" : "0px");
                this._eElem.style.left = "0px";
                this._eElem.style.bottom = "0px";
                this._eElem.style.position = "fixed";
                this._eContainer.style.height = "100%";

                this.setOuterWidth(this.pbVisible && this.pbRender ? this.piWidth : 0);
                if (oWebApp && oWebApp._eElem) {
                    if (this.pePosition === df.fpFloatLeftSqueezeWebApp) {
                        oWebApp._eElem.style.marginLeft = (this.pbVisible && this.pbRender ? this.piWidth : 0) + "px";
                    } else {
                        oWebApp._eElem.parentNode.style.overflow = "hidden"; // This could cause trouble (works for trucks!)
                        oWebApp._eElem.style.transform = "translateX(" + (this.pbVisible && this.pbRender ? this.piWidth : 0) + "px)";
                    }
                }
            }

            if (this.pePosition === df.fpFloatFixed) {
                this._eElem.style.top = (this.piTop >= 0 ? this.piTop + "px" : "");
                this._eElem.style.left = (this.piLeft >= 0 ? this.piLeft + "px" : "");
                this._eElem.style.bottom = (this.piBottom >= 0 ? this.piBottom + "px" : "");
                this._eElem.style.right = (this.piRight >= 0 ? this.piRight + "px" : "");

                if (iWidth >= 0) {
                    if (this.pbShrinkIfNoSpace && ((iWidth + Math.max(this.piLeft, 0) + Math.max(this.piRight, 0)) > iScreenWidth)) {
                        iWidth = iScreenWidth - Math.max(this.piLeft, 0) - Math.max(this.piRight, 0);
                    }

                    this.setOuterWidth(iWidth);
                }

                if (iHeight >= 0 || (this.piBottom >= 0 && this.piTop >= 0)) {
                    this._eContainer.style.height = "100%";
                }

                if (iHeight >= 0) {
                    if (this.pbShrinkIfNoSpace && ((iHeight + Math.max(this.piTop, 0) + Math.max(this.piBottom, 0)) > iScreenHeight)) {
                        iHeight = iScreenHeight - Math.max(this.piTop, 0) - Math.max(this.piBottom, 0);
                    }

                    this._eElem.style.height = iHeight + "px";
                    this._eElem.style.maxHeight = "";
                }
            }
        } else {
            //  If not visible we reset all sizing properties so the first resize on show goes in clean
            if (this._eElem) {
                this._eElem.style.top = "0px";
                this._eElem.style.left = "0px";
                this._eElem.style.bottom = "";
                this._eElem.style.right = "";
                this._eElem.style.height = "";
                this._eElem.style.maxHeight = "";
            }
        }

        //  Call standard resize procedures
        this.resizeHorizontal();
        super.resizeVertical(); //  Directly call super to prevent recursive loop

    }

    /* 
    Augment setInnerHeight to make sure the container element size is leading.
    
    @param  iHeight The height to apply.
    @private
    */
    setInnerHeight(iHeight) {
        //  ToDo: This is probably not the best way of doing this as the case where a scrollbar would actually be needed might be ruined by this
        if (iHeight > df.dom.clientHeight(this._eContainer)) {
            iHeight = df.dom.clientHeight(this._eContainer);
        }

        super.setInnerHeight(iHeight);

    }

    /* 
    Augment setter of piHeight and reposition panel.
    
    @param  iVal    New value.
    */
    set_piHeight(iVal) {
        super.set_piHeight(iVal);

        if (this._eElem) {
            this.piHeight = iVal;

            this.positionPnl();
        }
    }

    /* 
    Updates the width of the floating panel.
    
    @param  iVal    New value.
    */
    set_piWidth(iVal) {
        const oWebApp = this.getWebApp();

        if (this._eElem) {
            this.setOuterWidth(iVal);

            if (this.pePosition === df.fpFloatLeftSqueezeWebApp) {
                if (this.pbVisible && this.pbRender && oWebApp && oWebApp._eElem) {
                    oWebApp._eElem.style.marginLeft = iVal + "px";
                }
            }
        }
    }

    /* 
    Hides / shows the panel responding to pbVisible.
    
    @param  bVal    New value.
    */
    set_pbVisible(bVal) {
        if (this._eElem && this.pbVisible !== bVal) {
            if (bVal) {
                this.show();
            } else {
                this.hide(false, "manual");
            }
        }
    }

    /* 
    Hides / shows the panel if the combination of pbRender and pbVisible are true.
    
    @param  bVal    New value.
    */
    set_pbRender(bVal) {
        if (this._eElem && this.pbRender !== bVal) {
            super.set_pbRender(bVal);

            this.pbRender = bVal;

            if (bVal && this.pbVisible) {
                this.show();
            } else {
                this.hide(false, "manual");
            }
        }
    }


    /* 
    Updates the way the floating panel is positioned.
    
    @param  iVal    New positioning mode.
    */
    set_pePosition(iVal) {
        
        if (this._eElem && this.pePosition !== iVal) {

            const oWebApp = this.getWebApp();

            if (oWebApp && oWebApp._eElem) {
                if (iVal !== df.fpFloatLeftSqueezeWebApp && this.pePosition === df.fpFloatLeftSqueezeWebApp) {
                    oWebApp._eElem.style.marginLeft = "";
                }

                if (iVal !== df.fpFloatLeftPushWebApp && this.pePosition === df.fpFloatLeftPushWebApp) {
                    oWebApp._eElem.parentNode.style.overflow = ""; // This could cause trouble (works for trucks!)
                    oWebApp._eElem.style.transform = "";

                    if (this._eMask) {
                        df.dom.off("click", this._eMask, this.onMaskTouch, this);
                        this._eMask.parentNode.removeChild(this._eMask);
                        this._eMask = null;
                    }
                }
            }

            this.pePosition = iVal;

            this.positionPnl();
        }
    }

    set_piContentWidth(iVal) {
        if (this._eContainer) {
            this._eSizer.style.width = iVal + "px";
            df.dom.toggleClass(this._eElem, "WebFP_FixedContentWidth", iVal > 0);
        }
    }

    set_pbHideOnBlur(bVal) {
        if (this._aFocusCatchers) {
            this._aFocusCatchers.forEach(function (eEl) {
                df.dom.setTabIndex(eEl, (bVal ? 0 : -1));
            });
        }
    }

    /* 
    Hides the panel by setting pbVisible to false.
    
    @param  bNoPos  If true the panel is not repositioned before hiding.
    */
    hide(bNoPos, sReason) {
        this.pbVisible = false;

        this.addSync("pbVisible");

        this.doHide(bNoPos, sReason || "manual");
    }

    /* 
    Hides the panel by manipulating the DOM.
    
    @param  bNoPos  If true the panel is not repositioned before hiding.
    @private
    */
    doHide(bNoPos, sReason) {
        const that = this, oWebApp = this.getWebApp();

        if (this._tPositionInterval) {
            clearInterval(this._tPositionInterval);
            this._tPositionInterval = null;
        }


        df.dom.addClass(that._eElem, "WebFP_Hidden");
        df.dom.removeClass(that._eElem, "WebFP_Visible");

        if (!bNoPos) {
            this.positionPnl();
        }

        this.afterHide();

        //  Remove mobile mask that might have been created
        if (this._eMask) {
            df.dom.off("click", this._eMask, this.onMaskTouch, this);
            this._eMask.parentNode.removeChild(this._eMask);
            this._eMask = null;
        }

        //  Detach blur listener from floatby control
        if (this._eBlurBuddy) {
            df.events.removeDomCaptureListener("blur", this._eBlurBuddy, this.onCaptureBlur, this);
        }

        if (this.pePosition === df.fpFloatLeftSqueezeWebApp) {
            if (oWebApp && oWebApp._eElem) {
                oWebApp._eElem.style.marginLeft = "0px";
            }
        }

        this.fire("OnHide", [sReason]);

        setTimeout(function () {
            if (!that.pbVisible && that._eElem) {
                that._eElem.style.display = "none";
                that._bVisible = false;
            }

        }, 1500);

    }


    /* 
    Handles the OnShow event of the view and makes sure the floating panel is displayed if it should.
    
    @param  oEvent  Event object.
    @private
    */
    showView(oEvent) {
        this._bViewVisible = true;

        if (this.pbVisible && this._eElem) {
            this.doShow();
        }
    }

    /* 
    Handles the OnHide event of the view and makes sure the panel is hidden.
    
    @param  oEvent  Event object.
    @private
     */
    hideView(oEvent) {
        this._bViewVisible = false;

        if (this.pbVisible) {
            this.doHide(true, "auto_view");
        }
    }

    /* 
    Captures the focus event so we know the focus is inside the floating panel.
    
    @param  oEvent  Event object.
    @private
    */
    onCaptureFocus(oEvent) {
        if (this._tHideBlurTimeout) {
            clearTimeout(this._tHideBlurTimeout);
            this._tHideBlurTimeout = null;
        }
    }

    /* 
    Captures the blur event so we know the focus is changing and unless we get a focus event soon we 
    know we lost the focus and hide if needed.
    
    @param  oEvent  Event object.
    @private
    */
    onCaptureBlur(oEvent) {
        const that = this;

        if (this._tHideBlurTimeout) {
            clearTimeout(this._tHideBlurTimeout);
        }

        this._tHideBlurTimeout = setTimeout(function () {
            if (that.pbHideOnBlur) {
                that.hide(true, "auto_blur");
            }
            that._tHideBlurTimeout = null;

        }, 150);
    }


    /* 
    Handles the click on the mask behind the floating panel and hides the panel.
    
    @param  oEvent  See df.events.DOMEvent.
    @private
    */
    onMaskTouch(oEvent) {
        if (this.pbHideOnBlur) {
            this.hide(false, "auto_blur");
        }
    }

    /* 
    Augment the vertical resize and reposition the panel.
    
    @private
    */
    resizeVertical() {
        this.positionPnl();
        super.resizeVertical();
    }

    /* 
    Implement resize and reposition the panel.
    
    @private
    */
    resize() {
        if (this._eElem) {
            this.positionPnl();
        }
    }

    onKey(oEv) {
        if (oEv.matchKey(df.settings.calendarKeys.close) && this._bVisible) {
            this.hide(true, "auto_escape");
            oEv.stop();
        }
    }

    onCatchFocus(oEv) {
        if (this.pbHideOnBlur) {
            this.hide(false, "auto_tabout");
        }
    }
}