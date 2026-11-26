import { WebBaseView } from './WebBaseView.js';
import { df } from '../df.js';

/*
Class:
    df.WebView
Extends:
    df.WebBaseView

This class represents a view within in Visual DataFlex Web Application. It inherits from WebWindow 
but it doesn't have the be a floating window. This inheritance structure is chosen because of the 
WebModalDialog class that inherits from WebView and the possible future support of MDI.

The WebView is managed by the df.WebApp class which maintains a set of views. It has support for 
handling a DDO structure and is a scope in the synchronized properties system. This means that only 
synchronized properties from the current view and optionally its invoking view will be synchronized 
within a single call.
    
Revision:
    2011/07/11  (HW, DAW) 
        Initial version.
*/
export class WebView extends WebBaseView {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Web Properties
        this.prop(df.tBool, "pbFillHeight", false);

        //  Configure parents
        this._sControlClass = "WebView";
        this._sBaseClass = "WebInlineView";
        this._bWrapDiv = true;
    }

    /* 
    @private
    */
    wrpOpenHtml(aHtml) {
        //  Wrapper div for positioning of control
        aHtml.push('<div class="WebContainer">');
    }
    
    /* 
    Empty stub allowing sub classes to slip in HTML.
    
    @private
    */
    wrpCloseHtml(aHtml) {
        //  Wrapper div for positioning of control
        aHtml.push('</div>');
    }

    openHtml(aHtml) {
        super.openHtml(aHtml);

        //  Optionally label
        aHtml.push('<div class="WebCon_Inner">');

        aHtml.push('<label class="WebWin_title"', (!this.pbShowCaption ? 'style="display: none"' : ''), '>', df.dom.encodeHtml(this.psCaption), '</label>');

        aHtml.push('<div class="WebCon_ContentWrp">');
    }

    closeHtml(aHtml) {
        super.closeHtml(aHtml);

        aHtml.push('</div></div></div></div>');
    }

    afterRender() {
        //  Get references to generated elements
        this._eInner = df.dom.query(this._eElem, "div.WebCon_Inner");
        this._eContentWrap = df.dom.query(this._eElem, "div.WebCon_ContentWrp");
        this._eLbl = df.dom.query(this._eElem, "label.WebWin_title");

        //  Call super
        super.afterRender();

        this.set_piHeight(this.piHeight);
        this.set_piWidth(this.piWidth);
        this.set_piMaxWidth(this.piMaxWidth);

        this.set_piMinWidth(this.piMinWidth);

        df.events.addDomKeyListener(this._eElem, this.onKey, this);
    }

    _show(eRenderTo) {
        const oWebApp = this.getWebApp();
        const bRender = !this._eElem;

        this.fireEx({
            sEvent: "OnShow"
        });

        //  Render to DOM elements if that didn't happen before
        if (bRender) {
            const eElem = this.render();
            df.dom.addClass(eElem, "WebWin_Hidden");
        }

        //  Insert into the DOM (if needed)
        if (this._eElem.parentNode !== eRenderTo) {
            eRenderTo.appendChild(this._eElem);
            this._eRenderTo = eRenderTo;
        }

        //  Remove "hidden" class
        df.dom.removeClass(this._eElem, "WebWin_Hidden");

        //  We still need to call the afterRender method if we freshly rendered
        if (bRender) {
            this.afterRender();
        }

        //  Make sure sizes are correct and then unhide
        this._bRendered = true;

        //  Trigger afterShow
        this.afterShow();

        this._oCurrentObj = null;

        //  Make sure that this view is the currentwindow and the focus object is inside this view
        if (oWebApp) {
            oWebApp.objFocus(this);
        }

        //  Set a small timeout so the framework will resize controls
        setTimeout(() => {
            if (oWebApp && this._bRendered) {
                //  Give focus to first element
                if (this.pbFocusFirstOnShow && !this._oCurrentObj) {
                    this.conditionalFocus(true);
                }

                //  Add visible CSS class
                df.dom.addClass(this._eElem, "WebWin_Visible");

                //  Fire event
                oWebApp.OnShowWindow.fire(oWebApp, {
                    oWindow: this,
                    eElem: this._eElem,
                    bModal: false
                });
            }
        }, 20);
    }

    _hide(bNoServerEvents) {
        const oWebApp = this.getWebApp();
        let bCanceled = false;

        if (this._bRendered) {
            if (this._bRendered && !bNoServerEvents) {
                this.fire("OnHide", []);
            }

            df.dom.addClass(this._eElem, "WebWin_Hidden");
            df.dom.removeClass(this._eElem, "WebWin_Visible");

            //  Fire webapp event
            if (oWebApp) {
                bCanceled = !oWebApp.OnHideWindow.fire(oWebApp, {
                    oWindow: this,
                    eElem: this._eElem,
                    bModal: false
                });
            }
        }

        this._bRendered = false;
        //  Trigger afterHide
        this.afterHide();

        //  Remove window from DOM
        if (this._bStandalone) {
            //  If the OnHideWindow event was stopped we wait with the removal of the element so an animation or so can be performed, else we do it immediately to not disturb anything
            if (bCanceled) {
                setTimeout(() => {
                    if (this._eElem && this._eElem.parentNode) {
                        this._eElem.parentNode.removeChild(this._eElem);
                    }
                }, 5000);
            } else {
                if (this._eElem && this._eElem.parentNode) {
                    this._eElem.parentNode.removeChild(this._eElem);
                }
            }
        }
    }




    /* 
    Called by the WebApp object to trigger a resize. It gets the maximum available space for views as a 
    parameter. If we are floating we just look at the screen dimensions.
    
    @param  iMaxH   Maximum height determined by the WebApp.
    @private
    */
    viewResize(iMaxH) {
        const oWebApp = this.getWebApp();

        this.prepareSize();

        //  Apply piHeight or maximum if piHeight is to high or not set
        if (this.piHeight > 0 && this.piHeight < iMaxH) {
            this.setOuterHeight(this.piHeight);
        } else if (this._bStretch || (this.pbScroll && oWebApp._eElem)) {
            this.setOuterHeight(iMaxH);
        }

        this.resize();
    }

    /*
    This method determines the height that is lost. For the tab panel this is the space that the buttons 
    take.
    
    @return The amount of pixels that can't be used by the content.
    @private
    */
    getHeightDiff(bOut, bIn, bContentOut, bContentIn) {
        let iHeight = super.getHeightDiff(bOut, bIn, bContentOut, bContentIn);

        if (this._eLbl) {
            if (bContentOut) {
                iHeight += df.sys.gui.getVertBoxDiff(this._eInner, 0);
                iHeight += this._eLbl.offsetHeight;
                iHeight += df.sys.gui.getVertBoxDiff(this._eLbl, 1);

                iHeight += df.sys.gui.getVertBoxDiff(this._eContentWrap, 0);
            }
        }

        return iHeight;
    }


    /* 
    @client-action
    
    Called by the server from the new drill-down system when navigating up multiple levels. In that case 
    the view being navigated too (this view) is not in sync and an extra round trip is needed to finish 
    that operation. Note that we are relying on oWebApp._oCurrentWindow to be pointing to the top view 
    of the view stack so that it is automatically being synchronized as well.
    
    @param  bCancel     Is it a cancel operation or not (passed back to the server).
    @param  bCallback   Is there are callback object (passed back to the server).
    @param  sCallback   Name of the callback object (passed back to the server).
    @private
    */
    navigateBackToHere(bCancel, bCallback, sCallback) {
        this.serverAction("NavigateBackToHere_Callback", [bCancel, bCallback, sCallback], this._tActionData);
    }


    /* 
    Augment destroy to remove view from the view array and to clear its DDO data kept by the WebApp 
    object.
    
    @private
    */
    destroy() {
        const oWebApp =  this.getWebApp();
        let i

        if (oWebApp) {
            //  Remove from views array
            i = oWebApp._aViews.indexOf(this);
            if (i >= 0) {
                oWebApp._aViews.splice(i, 1);
            }
        }

        super.destroy();
    }

    /*
    This method implements the action method that is called from the server. It will close the view.
    */
    closePanel() {
        this.close();
    }

    set_pbFillHeight(bVal) {
        this.pbFillHeight = bVal;
        this.sizeChanged();
    }

    set_piMinWidth(iVal) {
        if (!this.pbFloating) {
            if (this._eSizer) {
                if (iVal > 0) {
                    iVal -= this.getWidthDiff(true, true, false, false);
                    this._eSizer.style.minWidth = iVal + "px";
                } else {
                    this._eSizer.style.minWidth = "";
                }
            }
            this.sizeChanged();
        }

        this.piMinWidth = iVal;
        this.set_piWidth(this.piWidth);
    }

    set_piWidth(iVal) {

        //df.WebWindow.base.set_piWidth.call(this, iVal);
        if (this._eSizer) {
            const iDiff = this.getWidthDiff(true, true, false, false);
            iVal -= iDiff;

            this._eSizer.style.width = (iVal > 0 ? iVal + "px" : "");
        }
        this.sizeChanged();
    }

    set_piMaxWidth(iVal) {
        if (this._eSizer) {
            if (iVal > 0) {
                iVal -= this.getWidthDiff(true, true, false, false);
                this._eSizer.style.maxWidth = iVal + "px";
            } else {
                this._eSizer.style.maxWidth = "";
            }
        }
        this.sizeChanged();
    }


    /*
    Override getWidthDiff to make it ignore the margin of the _eSizer element as that is used to center the view.
    
    @private
    */
    getWidthDiff(bOut, bIn, bContentOut, bContentIn) {
        let iWidth = 0;

        if (bOut && this._eElem) {
            iWidth += df.sys.gui.getHorizBoxDiff(this._eElem, 0);
        }
        if ((bOut || bIn) && this._eContainer) {
            iWidth += df.sys.gui.getHorizBoxDiff(this._eContainer, (bOut && bIn ? 0 : (bOut ? 1 : 2)));
        }
        if ((bIn || bContentOut) && this._eSizer) {
            iWidth += df.sys.gui.getHorizBoxDiff(this._eSizer, (bIn && bContentOut ? 0 : 2));
        }
        if (bContentOut && this._eMainArea) {//  Allow paddings on the main area, even while this space will be below the top panel it still needs to be recognized with
            iWidth += df.sys.gui.getHorizBoxDiff(this._eMainArea, 2);
        }
        if ((bContentOut || bContentIn) && this._eContent) {
            iWidth += df.sys.gui.getHorizBoxDiff(this._eContent, (bContentOut && bContentIn ? 0 : (bContentOut ? 1 : 2)));
        }

        return iWidth;
    }

    resizeHorizontal() {
        this.setOuterWidth(this.piWidth);

        super.resizeHorizontal();
    }


    setOuterHeight(iHeight) {
        if (!this._eContainer) return;

        iHeight -= this.getHeightDiff(true, false, false, false);

        this._eContainer.style.height = (iHeight > 0 ? iHeight + 'px' : '');
    }

    resize() {
        if (!this._bRendered) return;

        this.resizeHorizontal();
        this.resizeVertical();
    }
}