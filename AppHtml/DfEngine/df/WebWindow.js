import { df } from '../df.js';
import { WebBaseView } from './WebBaseView.js';
import { WebBaseControl } from './WebBaseControl.js';

/*
Class:
    df.WebWindow
Extends:
    df.WebBaseView

This class contains the functionality to render a floating modal window. Non modal window support 
was never exposed as part of the product and is now removed.
    
Revision:
    2023/05/17  (HW, DAW)
        Refactored into real dialog element.
    2011/07/11  (HW, DAW) 
        Initial version.
*/
export class WebWindow extends WebBaseView {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbResizable", true);
        this.prop(df.tBool, "pbShowClose", true);

        this.prop(df.tInt, "piLeft", 0);
        this.prop(df.tInt, "piTop", 0);

        //  Privates
        this._bHasLeft = false;
        this._bHasTop = false;

        this._eMask = null;
        this._oPrevFocus = null;
        this.pbModal = false;

        //  Configure super classes
        this._bWrapDiv = false;
        this._sBaseClass = "WebWindow";
    }

    create() {
        this._bHasLeft = (this.piLeft > 0);
        this._bHasTop = (this.piTop > 0);
    }

    genClass() {
        this._sBaseClass = "WebWindow" + (this.pbResizable ? " WebWin_Resizable" : "");
        return super.genClass();
    }

    openHtml(aHtml) {
        //  Manually generate wrapper div (due to inheritance structure)
        aHtml.push('<dialog class="', this.genClass(), '"');
        if (this.psHtmlId) {
            aHtml.push(' id="', this.psHtmlId, '"');
        }

        //  Insert the object name so the HTML element can be traced back to the right object
        aHtml.push(' data-dfobj="', this.getLongName(), '"');

        aHtml.push(' style=" ', (this.pbRender ? '' : 'display: none;'), (this.pbVisible ? '' : 'visibility: hidden;'), 'top:10px;"');
        aHtml.push('>');


        aHtml.push(
            '<div class="WebWin_top_l">',
            '<div class="WebWin_top_r">',
            '<div class="WebWin_top_c">',
            '</div>',
            '</div>',
            '</div>',
            '<div class="WebWin_main_l">',
            '<div class="WebWin_main_r">',
            '<div class="WebWin_header">',
            '<div class="WebWin_header_r">',
            '<div class="WebWin_header_c">');
        aHtml.push('             <label class="WebWin_title"', (!this.pbShowCaption ? 'style="display: none"' : ''), '>', df.dom.encodeHtml(this.psCaption), '</label>');
        aHtml.push('<div class="WebWin_controls">');


        aHtml.push('<div class="WebWin_close" tabindex="0"', (this.pbShowClose ? '' : ' style="display:none"'), '></div>');


        aHtml.push(
            '</div>',
            '<div style="clear: both;"></div>',
            '</div>',
            '</div>',
            '</div>',

            '<div class="WebWin_main_c">',
            '<div class="WebContainer">'
        );

        super.openHtml(aHtml);

    }

    closeHtml(aHtml) {
        super.closeHtml(aHtml);

        aHtml.push('</div>',
            '</div>',
            '</div>',
            '</div>',
            '<div class="WebWin_bottom_l">',
            '<div class="WebWin_bottom_r">',
            '<div class="WebWin_bottom_c">',
            '</div>',
            '<div class="WebWin_resizer">',
            '</div>',
            '</div>',
            '</dialog>');
    }

    afterRender() {
        //  Get references to generated elements
        this._eLbl = df.dom.query(this._eElem, "label.WebWin_title");

        this._eHeader = df.dom.query(this._eElem, "div.WebWin_header");
        this._eHeaderContent = df.dom.query(this._eElem, "div.WebWin_header_c");
        this._eControlWrap = df.dom.query(this._eElem, "div.WebWin_main_c");
        this._eMainRight = df.dom.query(this._eElem, "div.WebWin_main_r");
        this._eMainLeft = df.dom.query(this._eElem, "div.WebWin_main_l");
        this._eTopLeft = df.dom.query(this._eElem, "div.WebWin_top_l");
        this._eTopRight = df.dom.query(this._eElem, "div.WebWin_top_r");
        this._eTopContent = df.dom.query(this._eElem, "div.WebWin_top_c");
        this._eBottomLeft = df.dom.query(this._eElem, "div.WebWin_bottom_l");
        this._eBottomRight = df.dom.query(this._eElem, "div.WebWin_bottom_r");
        this._eResizer = df.dom.query(this._eElem, "div.WebWin_resizer");
        this._eBottomContent = df.dom.query(this._eElem, "div.WebWin_bottom_c");
        this._eCloseBtn = df.dom.query(this._eElem, "div.WebWin_close");

        //  Call super
        super.afterRender();

        this.set_piHeight(this.piHeight);
        this.set_piWidth(this.piWidth);

        //  Attach events

        // We need to prevent the default behavior of the cancel event to prevent the dialog from closing.
        // Note that because chromium does not allow canceling cancel on the second escape press we also 
        // cancel the keydown event, and then it only comes here if the focus is outside the dialog so we 
        // put it back in so the next escape gets cancelled again.
        df.dom.on("cancel", this._eElem, function (oEvent) { 
            this.focus();
            oEvent.stop();
        }, this);

        //  Drag
        df.dom.on("mousedown", this._eHeader, this.onStartDrag, this);

        //  Resizable
        df.dom.on("mousedown", this._eMainRight, this.onStartResize, this);
        df.dom.on("mousedown", this._eMainLeft, this.onStartResize, this);
        df.dom.on("mousedown", this._eTopLeft, this.onStartResize, this);
        df.dom.on("mousedown", this._eBottomLeft, this.onStartResize, this);

        //  Buttons
        df.dom.on("mousedown", this._eCloseBtn, function (oEvent) { oEvent.stop(); }, this);
        df.dom.on("click", this._eCloseBtn, this.onCloseClick, this);

        //  Sizing
        if (this._bStandalone) {
            df.dom.on("resize", window, this.onWindowResize, this);
        }

        df.events.addDomKeyListener(this._eElem, this.onKey, this);
    }



    _show(eRenderTo) {
        const bRender = !this._eElem;
        const oWebApp = this.getWebApp();

        this.fireEx({
            sEvent: "OnShow"
        });

        //  Render to DOM elements if that didn't happen before
        if (bRender) {
            const eElem = this.render();
            df.dom.addClass(eElem, "WebWin_Hidden");
        }

        //  Insert as first child (hidden)

        //  When modal we assume that we should give back the focus so we remember where the focus was
        this._oPrevFocus = oWebApp._oCurrentObj;

        if (this._eElem.parentNode) {
            this._eElem.parentNode.removeChild(this._eElem);
        }


        //  Insert into the DOM 
        this._eRenderTo = eRenderTo = eRenderTo || oWebApp?._eViewPort || document.body;
        eRenderTo.appendChild(this._eElem);

        //  Remove "hidden" class
        df.dom.removeClass(this._eElem, "WebWin_Hidden");
        if (this.pbModal) {
            this._eElem.showModal();
        } else {
            this._eElem.show();
        }

        //  We still need to call the afterRender method if we freshly rendered
        if (bRender) {
            this.afterRender();
        }

        //  Make sure sizes are correct and then unhide
        this._bRendered = true;

        //  Calculate start position (centered) for floating windows, resizing of views must always be initiated by the webapp
        if (this.pbFloating) {
            this.resize();
            this.centerWindow();
        }

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

                //  Add visible CSS class
                df.dom.addClass(this._eElem, "WebWin_Visible");

                //  Give focus to first element
                if (this.pbFocusFirstOnShow && !this._oCurrentObj) {
                    this.conditionalFocus(true);
                }

                //  Some browsers do not trigger onFocus when opening a dialog
                const eElem = document.activeElement.closest("[data-dfobj]");
                if (eElem) {
                    const oControl = this.getWebApp().findObj(eElem.dataset.dfobj);
                    if (oControl instanceof WebBaseControl) {
                        oControl.updateFocus(true);
                    }
                }

                //  Fire event
                oWebApp.OnShowWindow.fire(oWebApp, {
                    oWindow: this,
                    eElem: this._eElem,
                    bModal: this.pbModal
                });
            }
        }, 20);
    }

    _hide(bNoServerEvents) {
        const oWebApp = this.getWebApp();
        let bCanceled = false;

        if (this._bRendered) {
            if (!bNoServerEvents) {
                this.fire("OnHide", []);
            }

            //  Restore the focus, this is done by returning the focus to the invoking view, if this is a standalone window that will be the current window
            const oInvoking = this.getInvoking() || oWebApp._oCurrentWindow;  //  
            if (oInvoking) {
                oInvoking.returnFocus();
            } else if (this._oPrevFocus) { //  If there is no invoking view there might be specific object that should receive the focus.
                this._oPrevFocus.conditionalFocus();
            }

            this._eRenderTo = null;

            this._eElem.close();
            df.dom.addClass(this._eElem, "WebWin_Hidden");
            df.dom.removeClass(this._eElem, "WebWin_Visible");

            //  Fire webapp event
            if (oWebApp) {
                bCanceled = !oWebApp.OnHideWindow.fire(oWebApp, {
                    oWindow: this,
                    eElem: this._eElem,
                    bModal: this.pbModal
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

    /* - - - - - - - - - Public API - - - - - - - - - - */

    set_pbResizable(bVal) {
        if (!this._eElem) return;

        df.dom.toggleClass(this._eElem, "WebWin_Resizable", bVal);
    }

    set_pbShowClose(bVal) {
        if (!this._eCloseBtn) return;

        this._eCloseBtn.style.display = (bVal ? '' : 'none');
    }

    set_piWidth(iVal) {
        let sWidth;

        iVal = (iVal > this.piMinWidth ? iVal : this.piMinWidth);
        this.piWidth = iVal;

        sWidth = (iVal > 0 ? parseInt(iVal, 10) + 'px' : '');

        if (this._eControlWrap) {
            this._eControlWrap.style.width = sWidth;
            this._eHeader.style.width = sWidth;

            if (this._eElem && iVal > 0) {
                this.setOuterWidth(iVal);
            }
        }
    }

    set_piHeight(iVal) {
        super.set_piHeight(iVal);

        if (this._eElem && iVal > 0) {
            this.setOuterHeight(iVal);
        }
    }

    set_piTop(iVal) {
        this._bHasTop = true;

        if (this._eElem) {
            this._eElem.style.top = parseInt(iVal, 10) + 'px';
        }
    }

    set_piLeft(iVal) {
        this._bHasLeft = true;

        if (this._eElem) {
            this._eElem.style.left = parseInt(iVal, 10) + 'px';
        }
    }

    /* - - - - - - - - Resizing & Dragging - - - - - - - */

    createGhost() {
        let eGhost, eGhostContent, eGhostHeader, oSize, aHtml = [], sOrigId;

        //  Generate HTML
        sOrigId = this.psHtmlId;
        this.psHtmlId = "";

        this._bWrapDiv = false;
        this.openHtml(aHtml);
        this.closeHtml(aHtml);
        this._bWrapDiv = true;

        this.psHtmlId = sOrigId;

        //  Create ghost

        eGhost = df.dom.create(aHtml.join(''));
        eGhost.className = this.genClass() + " WebWin_ghost";
        this._eElem.parentNode.appendChild(eGhost);
        //eGhost.innerHTML = aHtml.join('');
        df.dom.disableTextSelection(eGhost);

        //  Set ghost content properties
        eGhostContent = df.dom.query(eGhost, ".WebWin_main_c");
        eGhostHeader = df.dom.query(eGhost, ".WebWin_header");
        oSize = df.sys.gui.getSize(this._eControlWrap);
        eGhostHeader.style.width = oSize.width + 'px';
        eGhostContent.style.width = oSize.width + 'px';
        eGhostContent.style.height = oSize.height + 'px';
        eGhost.style.top = this.piTop + 'px';
        eGhost.style.left = this.piLeft + 'px';
        eGhost.showModal();
        return eGhost;
    }

    onStartDrag(oEvent) {
        let eGhost, oSize, iTopLim, iLeftLim, iDragOffsetTop, iDragOffsetLeft;

        if (!this.isEnabled()) {
            return;

        }
        //  Get drag offset
        iDragOffsetTop = oEvent.getMouseY() - this.piTop;
        iDragOffsetLeft = oEvent.getMouseX() - this.piLeft;

        //  Determine size, we take in account that some designs have the close button sticking out
        oSize = df.sys.gui.getSize(this._eElem);
        if (this._eCloseBtn) {
            if (this._eCloseBtn.offsetLeft + this._eCloseBtn.offsetWidth > oSize.width) {
                oSize.width = this._eCloseBtn.offsetLeft + this._eCloseBtn.offsetWidth;
            }
        }

        iLeftLim = this.getViewportWidth() - oSize.width - 1;
        iTopLim = this.getViewportHeight() - oSize.height - 1;

        //  Create ghost and mask
        eGhost = this.createGhost();
        this._eElem.classList.add("Web_Moving");

        const eMask = df.gui.dragMask();
        eMask.style.cursor = "move";


        function onDrag(oEvent) {
            this.piTop = oEvent.getMouseY() - iDragOffsetTop;
            this.piLeft = oEvent.getMouseX() - iDragOffsetLeft;

            this.piTop = (this.piTop <= 0 ? 1 : (this.piTop >= iTopLim ? iTopLim : this.piTop));
            this.piLeft = (this.piLeft <= 0 ? 1 : (this.piLeft >= iLeftLim ? iLeftLim : this.piLeft));

            eGhost.style.top = this.piTop + 'px';
            eGhost.style.left = this.piLeft + 'px';
        }

        function onStopDrag(oEvent) {
            df.dom.off("mouseup", eMask, onStopDrag, this);
            df.dom.off("mouseup", window, onStopDrag, this);
            //df.dom.off("mouseout", eMask, onStopDrag, this);
            df.dom.off("mousemove", eMask, onDrag, this);

            df.gui.hideMask(eMask);
            if (eGhost) {
                this._eElem.parentNode.removeChild(eGhost);
            }

            this._eElem.style.top = this.piTop + 'px';
            this._eElem.style.left = this.piLeft + 'px';
            this._eElem.classList.remove("Web_Moving");

            this.resize();
        }

        //  Add eventlisteners
        df.dom.on("mouseup", eMask, onStopDrag, this);
        df.dom.on("mouseup", window, onStopDrag, this);
        //df.dom.on("mouseout", eMask, onStopDrag, this);
        df.dom.on("mousemove", eMask, onDrag, this);
    }

    onStartResize(oEvent) {
        if (this.pbResizable && this.isEnabled()) {
            const eTar = oEvent.getTarget();

            if (eTar === this._eMainRight) {
                this.resizeDrag(oEvent, true, false, false, false, "e-resize");
                oEvent.stop();
            } else if (eTar === this._eMainLeft) {
                this.resizeDrag(oEvent, true, true, false, false, "e-resize");
                oEvent.stop();
            } else if (eTar === this._eTopRight) {
                this.resizeDrag(oEvent, true, false, true, true, "ne-resize");
                oEvent.stop();
            } else if (eTar === this._eTopLeft) {
                this.resizeDrag(oEvent, true, true, true, true, "nw-resize");
                oEvent.stop();
            } else if (eTar === this._eTopContent) {
                this.resizeDrag(oEvent, false, false, true, true, "n-resize");
                oEvent.stop();
            } else if (eTar === this._eBottomRight || eTar === this._eResizer) {
                this.resizeDrag(oEvent, true, false, true, false, "nw-resize");
                oEvent.stop();
            } else if (eTar === this._eBottomLeft) {
                this.resizeDrag(oEvent, true, true, true, false, "ne-resize");
                oEvent.stop();
            } else if (eTar === this._eBottomContent) {
                this.resizeDrag(oEvent, false, false, true, false, "n-resize");
                oEvent.stop();
            }
        }
    }

    resizeDrag(oEvent, bWidth, bLeft, bHeight, bTop, sCursor) {
        let eGhost, eGhostContent, eGhostHeader, oSize, iStartWidth, iStartLeft, iStartMouseX, iStartHeight, iStartMouseY, iStartTop, iMarginRight = 0, aHiddenPlugins;



        oSize = df.sys.gui.getSize(this._eControlWrap);
        iStartWidth = oSize.width;
        iStartMouseX = oEvent.getMouseX();
        iStartLeft = this.piLeft;

        iStartHeight = oSize.height;
        iStartMouseY = oEvent.getMouseY();
        iStartTop = this.piTop;

        this.piHeight = (this.piHeight > 0 ? this.piHeight : this._eControlWrap.clientHeight);

        //  Some designs have the close button sticking out, we need to take a margin for those designs to prevent scrollbars
        if (this._eCloseBtn) {
            if (this._eCloseBtn.offsetLeft + this._eCloseBtn.offsetWidth > oSize.width) {
                iMarginRight = (this._eCloseBtn.offsetLeft + this._eCloseBtn.offsetWidth) - oSize.width;
            }
        }

        //  Create ghost and dragmask
        eGhost = this.createGhost();
        eGhostContent = df.dom.query(eGhost, ".WebWin_main_c");
        eGhostHeader = df.dom.query(eGhost, ".WebWin_header");
        this._eElem.classList.add("Web_Resizing");

        const eMask = df.gui.dragMask();
        eMask.style.cursor = sCursor;

        function onResize(oEvent) {


            if (bWidth) {
                if (bLeft) {
                    this.piWidth = iStartWidth - (oEvent.getMouseX() - iStartMouseX);
                    this.piWidth = (this.piWidth > this.piMinWidth ? this.piWidth : this.piMinWidth);
                    this.piLeft = iStartLeft - (this.piWidth - iStartWidth);
                } else {
                    this.piWidth = iStartWidth + (oEvent.getMouseX() - iStartMouseX);
                    this.piWidth = (this.piWidth > this.piMinWidth ? this.piWidth : this.piMinWidth);

                    //  Resprect the right margin
                    if (this.piWidth + this.piLeft > this.getViewportWidth() - iMarginRight) {
                        this.piWidth = this.getViewportWidth() - iMarginRight - this.piLeft;
                    }
                }


                eGhost.style.left = this.piLeft + "px";
                eGhostContent.style.width = this.piWidth + "px";
                eGhostHeader.style.width = this.piWidth + "px";
            }
            if (bHeight) {
                if (bTop) {
                    this.piHeight = iStartHeight - (oEvent.getMouseY() - iStartMouseY);
                    this.piHeight = (this.piHeight > this.piMinHeight ? this.piHeight : this.piMinHeight);
                    this.piTop = iStartTop - (this.piHeight - iStartHeight);
                } else {
                    this.piHeight = iStartHeight + (oEvent.getMouseY() - iStartMouseY);
                    this.piHeight = (this.piHeight > this.piMinHeight ? this.piHeight : this.piMinHeight);
                }


                eGhost.style.top = this.piTop + "px";
                eGhostContent.style.height = this.piHeight + "px";
            }
        }


        function onStopResize(oEvent) {
            df.dom.off("mouseup", eMask, onStopResize, this);
            df.dom.off("mouseup", window, onStopResize, this);
            df.dom.off("mousemove", eMask, onResize, this);

            df.gui.hideMask(eMask);
            if (eGhost) {
                this._eElem.parentNode.removeChild(eGhost);
            }

            if (aHiddenPlugins) {
                df.sys.gui.restorePlugins(aHiddenPlugins);
            }

            this._eControlWrap.style.width = this.piWidth + "px";
            this._eHeader.style.width = this.piWidth + "px";
            this._eElem.style.left = this.piLeft + "px";
            this._eElem.style.top = this.piTop + "px";
            this._eElem.classList.remove("Web_Resizing");
            this.setOuterHeight(this.piHeight);
            this.resize();
        }

        df.dom.on("mousemove", eMask, onResize, this);
        df.dom.on("mouseup", window, onStopResize, this);
        df.dom.on("mouseup", eMask, onStopResize, this);
    }

    /* - - - - - - - - Supportive - - - - - - - */



    getViewportElem() {
        if (this.pbFloating && this.pbModal) {
            return document.body;
        }
        return this._eRenderTo;
    }

    blur() {

    }

    /*
    Closes the dialog is pbShowClose is set to true.
    */
    doClose() {
        if (this.pbShowClose) {
            this.hide();
        }
    }

    resize() {
        if (!this._bRendered) return;

        //  We have to 'fix' the size for a floating dialog else it won't behave well if the window is 
        //  resized. This is only done once when no width & height is set.
        if (this._eControlWrap && !this.piHeight && !this.piWidth) {
            this.piHeight = df.dom.clientHeight(this._eControlWrap);
            this.piWidth = df.dom.clientWidth(this._eControlWrap);

            this._eControlWrap.style.width = this.piWidth + "px";
            this._eHeader.style.width = this.piWidth + "px";
            this._eControlWrap.style.height = this.piHeight + "px";
        }

        this.resizeHorizontal();
        this.resizeVertical();
    }

    setOuterHeight(iHeight) {
        if (iHeight > 0) {
            this._eControlWrap.style.height = iHeight + 'px';

            iHeight -= this.getHeightDiff(true, true, false, false);

            this._eContainer.style.height = iHeight + 'px';
        } else {
            this._eControlWrap.style.height = '';
            this._eContainer.style.height = '';
        }
    }


    /* 
    Called by the WebApp object to trigger a resize. It gets the maximum available space for views as a 
    parameter. If we are floating we just look at the screen dimensions.
    
    @param  iMaxH   Maximum height determined by the WebApp.
    @private
    */
    viewResize(iMaxH) {
        let iDiff, iHeight;

        this.prepareSize();


        //  For dialogs take the ehader and footer into account
        iDiff = df.dom.offsetHeight(this._eHeader) + df.dom.offsetHeight(this._eBottomLeft);

        //  Dialogs are only limited by the screen / window size
        iMaxH = df.dom.windowHeight() - 20;

        //  If piHeight is 0 we use the 'wanted' / 'natural' height, else we use piHeight itself
        if (this.piHeight <= 0) {
            iHeight = this._iWantedHeight;
        } else {
            iHeight = this.piHeight;
        }

        //  Apply the height
        if (iHeight > 0 && iHeight + iDiff < iMaxH) {
            this.setOuterHeight(iHeight);
        } else {
            this.setOuterHeight(iMaxH - iDiff);
        }

        this.resize();

    }

    /*
    Determines the available width for moving and resizing the window.
    
    @return Viewport width in pixels.
    */
    getViewportWidth() {
        return df.sys.gui.getViewportWidth();
    }

    /*
    Determines the available height for moving and resizing the window.
    
    @return Viewport width in pixels.
    */
    getViewportHeight() {
        return df.sys.gui.getViewportHeight();
    }

    /*
    This method handles the onclick event of the close button. It calls the doClose method has the logic for handling a close initiated by the client.
    
    @param  oEvent  The event object with event details.
    @private
    */
    onCloseClick(oEvent) {
        if (this.isEnabled()) {
            this.doClose();
        }
    }

    /*
    This method handles the keypress event of the window. It will initiate actions that belong to the pressed key if needed.
    
    @param  oEvent  The event object with event details.
    @private
    */
    onKey(oEvent) {
        if (oEvent.matchKey(df.settings.formKeys.escape)) {
            this.doClose();
            oEvent.stop();
        } else {
            super.onKey(oEvent);
        }
    }

    onWindowResize(oEvent) {
        this.centerWindow();
    }

    centerWindow() {
        if (this._bRendered && this._eElem) {
            if (!this._bHasTop) {
                this.piTop = this.getViewportHeight() / 2 - (this._eElem.clientHeight || this.piHeight) / 2;

                if (df.sys.isMobile) {
                    this.piTop = this.piTop * 0.65;
                }

                this.piTop = (this.piTop > 0 ? this.piTop : 0);
            }
            if (!this._bHasLeft) {
                this.piLeft = this.getViewportWidth() / 2 - (this._eElem.clientWidth || this.piWidth) / 2;

                this.piLeft = (this.piLeft > 0 ? this.piLeft : 0);
            }
            this._eElem.style.top = parseInt(this.piTop, 10) + 'px';
            this._eElem.style.left = parseInt(this.piLeft, 10) + 'px';
        }
    }

}