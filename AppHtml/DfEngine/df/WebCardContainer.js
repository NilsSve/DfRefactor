import { WebBaseControl } from './WebBaseControl.js';
import { WebBaseUIObject } from './WebBaseUIObject.js';
import { WebCard } from './WebCard.js';
import { df } from '../df.js';
/*
Class:
    df.WebCardContainer
Extends:
    df.WebBaseControl

This class is the client-side representation of the cWebCardContainer and is responsible for rendering 
this tab dialog. It can only contain cWebTabPage objects as children.
    
Revision:
    2011/10/13  (HW, DAW) 
        Initial version.
    2012/10/02  (HW, DAW)
        Split into WebCardContainer and WebTabContainer.
*/
export class WebCardContainer extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Web Properties
        this.prop(df.tBool, "pbShowBorder", false);
        this.prop(df.tBool, "pbShowCaption", false);
        this.prop(df.tBool, "pbSwipeCards", false);

        this.prop(df.tString, "psCurrentCard", "");
        this.addSync("psCurrentCard");

        //  Events
        this.event("OnCardChange", df.cCallModeWait);

        //@privates
        this._iHeightSet = null;
        this._aCards = [];
        this._eHead = null;
        this._oCurrent = null;
        this._bRendered = false;
        this._bCC = true; //  Used by the designer to filter cardcontainers from tab / accordion containers


        //  Configure super classes
        this._bWrapDiv = true;
        this._bRenderChildren = true;
        this._sControlClass = "WebCardContainer";
        this._sCardClass = "WebCC";
    }

    // - - - - Rendering - - - - 

    openHtml(aHtml) {
        super.openHtml(aHtml);

        this.headHtml(aHtml);

        //  Generate body HTML
        aHtml.push('<div class="', this._sCardClass, '_Body">');
    }

    /*
    Generates the head HTML which includes the tabbuttons. Note that this function is overridden in 
    WebAccordionContainer which does not have a head element with subclasses.
    
    @param  aHtml   String builder array.
    @private
    */
    headHtml(aHtml) {
        //  Generate header HTML
        aHtml.push('<div class="', this._sCardClass, '_Head">');

        for (let i = 0; i < this._aCards.length; i++) {
            this._aCards[i].tabButtonHtml(aHtml);
        }

        aHtml.push('<div style="clear: both"></div></div>');
    }

    closeHtml(aHtml) {
        aHtml.push('</div>');
        aHtml.push('<label class="', this._sCardClass, '_Caption"></label>');


        super.closeHtml(aHtml);
    }

    afterRender() {

        this._eBody = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_Body');
        this._eHead = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_Head');
        //this._eLabelSpacer = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_LabelSpacer');
        this._eLabel = df.dom.query(this._eElem, 'label.' + this._sCardClass + "_Caption");

        //  Get references to the button elements
        const aButtons = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_Head > div.WebTab_Btn', true);

        //  Pass references to the button elements to the corresponding tab pages
        for (let i = 0; i < this._aCards.length; i++) {
            if (i < aButtons.length) {
                this._aCards[i].btnRendered(aButtons[i]);
            }
        }

        super.afterRender();

        if (this.pbSwipeCards) {
            this.set_pbSwipeCards(true);
        }

        //  Display the current tab
        this.showCard(this._oCurrent, true);


        this._bRendered = true;
    }

    set_pbSwipeCards(bVal) {
        if (this._eBody) {
            if (bVal) {
                if (window.PointerEvent) {    //  Microsofts new standard adopted by W3C for touch / mouse & pen events as of IE11
                    df.dom.on("pointerdown", this._eBody, this.onPointerDown, this);
                } else {
                    df.dom.on("touchstart", this._eBody, this.onTouchStart, this);
                }
            } else {
                if (window.PointerEvent) {    //  Microsofts new standard adopted by W3C for touch / mouse & pen events as of IE11
                    df.dom.off("pointerdown", this._eBody, this.onPointerDown, this);
                } else {
                    df.dom.off("touchstart", this._eBody, this.onTouchStart, this);
                }
            }
            df.dom.toggleClass(this._eBody, "WebCC_Swipable", bVal);
        }
    }

    /*
    This event handler handles the touch event on mobile devices. It will scroll list if the touch is a 
    vertical sliding touch.
    
    @param  oEv     Event object (df.events.DOMEvent)
    @private
    */
    onTouchStart(oEv) {
        //  Only respond to single finger swipes
        if (oEv.e.targetTouches.length === 1) {
            this.touchSwipe(false, oEv);
        }
    }

    onPointerDown(oEv) {
        if (oEv.e.pointerType === "pen" || oEv.e.pointerType === "touch") {
            this.touchSwipe(true, oEv);
        }
    }

    // debugCount : 0,

    touchSwipe(bPointer, oEv) {
        let iY, iStartY, iWidth, iDiff, oShowCard = null,
            iStartX, iX, bSwipe = false, bSwipeFixed = false, iIndex = -1, oPrev = null, oNext = null, oCurrent = this._oCurrent, eCur = null, eNext = null, ePrev = null;

        // var iID = this.debugCount++;
        // df.debug(iID + ":touchStart");



        //  Determine next and previous cards
        for (let i = 0; i < this._aCards.length; i++) {
            if (this._aCards[i] === oCurrent) {
                iIndex = i;
            }
            if (this._aCards[i].isActive()) {
                if (iIndex < 0) {
                    oPrev = this._aCards[i];
                } else if (!oNext && iIndex !== i) {
                    oNext = this._aCards[i];
                    break;
                }

            }
        }

        if (!this.pbSwipeCards || !oCurrent || (!oNext && !oPrev)) {
            return;
        }


        iStartX = iX = (bPointer ? oEv.e.clientX : oEv.e.targetTouches[0].pageX);
        iStartY = iY = (bPointer ? oEv.e.clientY : oEv.e.targetTouches[0].pageY);

        //  Handles the move event and recalculates the scrollbar position accordingly
        function touchMove(oEv) {
            let iBehindOffset;

            //  Determine new touch position
            iY = (bPointer ? oEv.e.clientY : oEv.e.targetTouches[0].pageY);
            iX = (bPointer ? oEv.e.clientX : oEv.e.targetTouches[0].pageX);



            //  Switch between horizontal swipe and scroll
            if ((bSwipeFixed && bSwipe) || (!bSwipeFixed && Math.abs(iStartX - iX) > Math.abs(iStartY - iY))) {
                bSwipe = true;

                iDiff = (iX - iStartX);

                //  Initialize current card
                if (!eCur) {
                    eCur = oCurrent._eElem;
                    df.dom.addClass(eCur, "WebC_Swipe");

                    iWidth = eCur.offsetWidth;
                }

                if (iDiff > 0) {
                    //  We are swiping to the right
                    iDiff = Math.min(iWidth, iDiff);

                    //  Is there a previous card?
                    if (oPrev) {
                        //  Initialize swipe
                        if (!ePrev) {
                            //  Clear next card swipe (might have gone to the left first)
                            if (eNext) {
                                df.dom.translateX(eNext, null, false);
                                df.dom.removeClass(eNext, "WebC_SwipeBelow");

                                eNext = null;
                            }

                            //  Render if needed
                            if (!oPrev._eElem) {
                                oPrev.renderCard(false);
                            }
                            ePrev = oPrev._eElem;

                            df.dom.addClass(ePrev, "WebC_SwipeBelow");
                        }

                        //  Calculate position
                        iBehindOffset = -(iWidth * 0.3) + (iDiff * 0.3);
                        // df.debug(iID + " : behind card : " + iBehindOffset);
                        df.dom.translateX(ePrev, iBehindOffset, false);

                        //  Move current card
                        df.dom.translateX(eCur, iDiff, false);
                    } else {
                        //  Do bounce if no previous card
                        iDiff = iDiff * 0.17;
                        df.dom.translateX(eCur, iDiff, false);

                    }
                } else {
                    //  We are swiping to the left
                    iDiff = Math.max(-iWidth, iDiff);

                    //  Is there a next card?
                    if (oNext) {
                        //  Initialize if needed
                        if (!eNext) {
                            //  Clear previous card swipe (might have gone to the right first)
                            if (ePrev) {
                                df.dom.translateX(ePrev, null, false);
                                df.dom.removeClass(ePrev, "WebC_SwipeBelow");
                                ePrev = null;
                            }
                            //  Render if needed
                            if (!oNext._eElem) {
                                oNext.renderCard(false);
                            }
                            eNext = oNext._eElem;

                            df.dom.addClass(eNext, "WebC_SwipeBelow");
                        }
                        //  Calculate positions
                        iBehindOffset = (iWidth) * 0.3 + (iDiff * 0.3); //eNext.offsetWidth * 0.5 * (iDiff * (100 / eNext.offsetWidth));
                        // df.debug(iID + " : behind card : " + iBehindOffset);
                        df.dom.translateX(eNext, iBehindOffset, false);

                        //  Move current card
                        df.dom.translateX(eCur, iDiff, false);
                    } else {
                        //  Do bounce
                        iDiff = iDiff * 0.17;
                        df.dom.translateX(eCur, iDiff, false);
                    }
                }

                //  Stop event to prevent parent objects from responding to it
                oEv.stop();
            }


        }


        function finished() {
            if (oShowCard) {
                this.showCard(oShowCard, false);
            }
            if (ePrev) {
                df.dom.translateX(ePrev, null, false);
                df.dom.removeClass(ePrev, "WebC_SwipeBelow");
            }
            if (eNext) {
                df.dom.translateX(eNext, null, false);
                df.dom.removeClass(eNext, "WebC_SwipeBelow");
            }
            if (eCur) {
                df.dom.translateX(eCur, null, false);
                df.dom.removeClass(eCur, "WebC_Swipe WebC_SwipeLeaving");
            }
        }


        //
        //  Handles the touch end and initiates scroll animations if needed.
        //
        function touchEnd(oEv) {

            if (iDiff > 0) {
                if (oPrev && ePrev) {

                    //  Check if we swiped far enough
                    if (iDiff > (iWidth * 0.4)) {
                        //  Actually change card
                        oShowCard = oPrev;

                        if (iDiff < iWidth) {
                            df.dom.transition(ePrev, "all 200ms", finished, this);
                            df.dom.translateX(ePrev, 0, false);

                            df.dom.transition(eCur, "all 200ms");
                            df.dom.translateX(eCur, iWidth, false);
                            df.dom.addClass(eCur, "WebC_SwipeLeaving");
                        } else {
                            finished.call(this);
                        }
                    } else {
                        if (iDiff < iWidth) {
                            //  Go back
                            df.dom.transition(ePrev, "all 200ms", finished, this);
                            df.dom.translateX(ePrev, (iWidth * 0.3), false);

                            df.dom.transition(eCur, "all 200ms");
                            df.dom.translateX(eCur, 0, false);
                        } else {
                            finished.call(this);
                        }
                    }
                } else if (iDiff !== 0 && eCur) {
                    //  Finish bounce
                    df.dom.translateX(eCur, 0, false);
                }
            } else {
                if (oNext && eNext) {
                    //  Check if we swiped far enought
                    if (-iDiff > (iWidth * 0.4)) {
                        //  Change card
                        oShowCard = oNext;

                        if (-iDiff < iWidth) {
                            df.dom.transition(eNext, "all 200ms", finished, this);
                            df.dom.translateX(eNext, 0, false);

                            df.dom.transition(eCur, "all 200ms");
                            df.dom.translateX(eCur, -iWidth, false);
                            df.dom.addClass(eCur, "WebC_SwipeLeaving");
                        } else {
                            finished.call(this);
                        }
                    } else {
                        if (-iDiff < iWidth) {
                            //  Go back
                            df.dom.transition(eNext, "all 200ms", finished, this);
                            df.dom.translateX(eNext, -(iWidth * 0.3), false);

                            df.dom.transition(eCur, "all 200ms");
                            df.dom.translateX(eCur, 0, false);
                        } else {
                            finished.call(this);
                        }
                    }
                } else if (iDiff !== 0 && eCur) {
                    df.dom.transition(eCur, "all 100ms", finished, this);

                    df.dom.translateX(eCur, 0, false);
                }
            }

            // df.debug(iID + ":" + oEv.sName);
            if (bPointer) {
                df.dom.off("pointerup", window, touchEnd, this);
                df.dom.off("pointercancel", window, touchEnd, this);
                df.dom.off("pointermove", window, touchMove, this);
            } else {
                df.dom.off("touchend", window, touchEnd, this);
                df.dom.off("touchcancel", window, touchEnd, this);
                df.dom.off("touchmove", window, touchMove, this);
            }

        }


        if (bPointer) {
            df.dom.on("pointerup", window, touchEnd, this);
            df.dom.on("pointercancel", window, touchEnd, this);
            df.dom.on("pointermove", window, touchMove, this);
        } else {
            df.dom.on("touchend", window, touchEnd, this);
            df.dom.on("touchcancel", window, touchEnd, this);
            df.dom.on("touchmove", window, touchMove, this);
        }


        setTimeout(function () {
            bSwipeFixed = true;
        }, 300);
    }


    /* 
    Override the renderChildren procedure to determine the initial card (we need to know now) and to 
    optimize by only rendering the cards that are needed.
    
    @param  eRenderTo   DOM element to render children into (not used by current implementation).
    @private
    */
    renderChildren(eRenderTo) {
        let eChild;

        //  Determine initial current card
        if (this.psCurrentCard) {
            this._oCurrent = this.getWebApp().findObj(this.psCurrentCard);
        }

        for (let i = 0; i < this._aCards.length && !this._oCurrent; i++) {
            if (this._aCards[i].isActive()) {
                this._oCurrent = this._aCards[i];
            }
        }

        //  Get reference to wrapping div
        eRenderTo = this._eControl = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_Body');

        if (this.hasDynamicHeight()) {    //  If the height is influenced by the card height we need to render all cards on intiialization
            //  Call children and append them to ourselves
            for (let i = 0; i < this._aChildren.length; i++) {
                const oChild = this._aChildren[i];

                //  Check if we can actually render the object
                if (oChild instanceof WebBaseUIObject) {
                    eChild = oChild.render();

                    if (eChild) {
                        eRenderTo.appendChild(eChild);
                    }
                }
            }
        } else if (this._oCurrent) {   //  If the height is fixed (pbFillHeight / piHeight is set) then we only have to render the current card
            eChild = this._oCurrent.render();

            if (eChild) {
                eRenderTo.appendChild(eChild);
            }
        }
    }

    /* 
    We override this procedure as we do not always render all cards. So we only want to call afterRender 
    on the rendered cards.
    
    @private
    */
    afterRenderChildren() {
        if (this.hasDynamicHeight()) {
            super.afterRenderChildren();
        } else if (this._oCurrent) {
            this._oCurrent.afterRender();
        }

    }

    /* 
    Determines if the card content can influence the height. Is called to see if we need to render all 
    cards on initialization or just the current card.
    
    @return True if the container is sized by the card content.
    @private
    */
    hasDynamicHeight() {
        return (!this.pbFillHeight && this.piHeight <= 0);
    }

    /*
    Augmenting the addChild method to filter out tabs.
    
    @private
    */
    addChild(oChild) {
        if (oChild instanceof WebCard) {
            this._aCards.push(oChild);
        } else if (oChild instanceof WebBaseUIObject) {
            throw new df.Error(999, "WebCardContainer objects cannot have controls as direct children '{{0}}'. Consider placing them within a WebCard.", this, [(oChild.getLongName() || 'oWebApp')]);
        }


        super.addChild(oChild);
    }

    /*
    Override the bubbling afterShow message and only send it to the currently shown card.
    */
    afterShow() {
        this._bShown = true;

        if (this._oCurrent) {
            this._oCurrent.afterShow();
        }
    }

    /*
    Override the bubbling afterHide message and only send it to the currently shown card.
    */
    afterHide() {
        this._bShown = false;

        if (this._oCurrent) {
            this._oCurrent.afterHide();
        }
    }


    // - - - - Sizing  - - - - 

    /*
    This method determines the natural height of the card container. It does this by visiting all the 
    cards and calling their getRequiredHeight method which returns height required by the 
    components inside that card.
    
    @return The natural height needed (based on the highest card).
    */
    getNaturalHeight() {
        let iHeight = 0;

        //  Determine highest tab page
        for (let i = 0; i < this._aCards.length; i++) {
            if (this._aCards[i].pbRender && this._aCards[i]._eElem) {
                const iTab = this._aCards[i].getRequiredHeight();
                if (iTab > iHeight) {
                    iHeight = iTab;
                }
            }
        }

        //  Take the height that we loze
        iHeight += this.getHeightDiff();

        return iHeight;
    }

    /*
    The sizeHeight method is called by the WebBaseContainer and WebBaseControl to size the control. We 
    override the default implementation because the WebCardContainer has special logic when sizing 
    'naturally'. Other controls have the natural size determined by their CSS but the we need to 
    determine it based on the controls embedded inside the WebCards.
    
    @param  iExtHeight  The height determined by the container (-1 means suite yourself).
    @return The height that is actually applied.
    */
    sizeHeight(iExtHeight) {
        let iHeight = -1;

        //  Determine which height to use
        if (this.pbFillHeight) {
            iHeight = iExtHeight;
        } else {
            if (this.piHeight > 0) {
                iHeight = this.piHeight;
            } else {
                iHeight = this.getNaturalHeight();
            }
        }

        //  Respect minimal height
        if (iHeight < this.piMinHeight) {
            iHeight = this.piMinHeight;
        }

        //  Update the height
        this.setHeight(iHeight);

        //  Adjust tab content sizes
        this.resizeCards();

        //  Return the final height
        if (iHeight > 0) {
            return iHeight;
        }
    }

    /*
    Called by the setHeight method, we override it here to make it call into getHeightDiff.
    
    @param  iHeight     The height in pixels.
    */
    getVertHeightDiff() {
        let iResult = 0;

        if (this.peLabelPosition === df.ciLabelTop && this._eLbl) {
            iResult += this._eLbl.offsetHeight;
        }

        iResult += this.getHeightDiff();
        return iResult;
    }

    /*
    The resize method is called when the view / application resizes and during initialization. We call 
    the resize methods of the WebCards.
    
    @private
    */
    resize() {
        if (this._eElem && this._bRendered) {
            this._eBody.scrollTop = 0;
            //  A resize can also mean that the tab page size changed, if pbFillHeight is true sizeHeight will be called by container, if not we force it here!
            if (!this.pbFillHeight) {
                this.sizeHeight(-1);
            } else {
                this.resizeCards();
            }
        }
    }

    /*
    Resizes the tabs, which is called from sizeHeight and the resize function.
    
    @private
    */
    resizeCards() {
        //  Resize the tabpages
        for (let i = 0; i < this._aCards.length; i++) {
            if (this._aCards[i]._eElem) {
                this._aCards[i].resizeHorizontal();
                this._aCards[i].resizeVertical();
            }
        }
    }

    /*
    This method determines the height that is lost. For the tab panel this is the space that the buttons 
    take.
    
    @return The amount of pixels that can't be used by the content.
    @private
    */
    getHeightDiff() {
        let iHeight = 0;

        if (this.pbShowCaption && this._eHead) {
            iHeight += df.sys.gui.getVertBoxDiff(this._eHead, 1);  //  Outside difference
        }

        if (this._eControl) {
            iHeight += df.sys.gui.getVertBoxDiff(this._eControl);
            iHeight += df.sys.gui.getVertBoxDiff(this._eInner);
            iHeight += df.sys.gui.getVertBoxDiff(this._eControlWrp);
        }

        return iHeight;
    }

    /*
    The getMinHeight function is called by the column layout resize system implemented in 
    WebBaseContainer. It determines the minimal height that the control needs to render itself. The 
    WebCardContainer uses the getNaturalHeight method to determine the required height and respects the 
    piMinHeight property.
    
    @return The minimal height needed in pixels.
    */
    getMinHeight() {
        let iHeight = 0;

        if(this.pbFillHeight){
            return this.piMinHeight;
        }
        if(this.piHeight > 0){
            return Math.max(this.piHeight, this.piMinHeight);
            }

        this.resize();
            //  Determine natural height
            iHeight = this.getNaturalHeight();

            //  Respect piMinHeight
            if (iHeight < this.piMinHeight) {
                iHeight = this.piMinHeight;
        }

        return iHeight;
    }


    /* 
    Makes sure that all cards are rendered. 
    
    @private
    */
    renderAllCards() {

        if (this._eControl) {
            for (let i = 0; i < this._aCards.length; i++) {
                if (!this._aCards[i]._eElem) {
                    const eElem = this._aCards[i].render();
                    this._eControl.appendChild(eElem);
                    this._aCards[i].afterRender();
                }
            }
        }
    }

    /* 
    Augment piHeight setter and make sure that all cards are rendered if it is set to 0.
    
    @param  iVal    New value.
    @private
    */
    set_piHeight(iVal) {
        if (iVal <= 0) {
            this.renderAllCards();
        }

        super.set_piHeight(iVal);
    }

    /* 
    Augment pbFillHeight setter and make sure that all cards are rendered if it is set to false.
    
    @param  iVal    New value.
    @private
    */
    set_pbFillHeight(bVal) {
        if (!bVal) {
            this.renderAllCards();
        }

        super.set_pbFillHeight(bVal);
    }


    // - - - - Focus  - - - - 

    /*
    We attach the focus events to the header of the tab container because that is the part that takes 
    the focus.
    
    @private
    */
    attachFocusEvents() {
        //  We are attaching a DOM capture listener so we know when we get the focus
        if (this._eHead) {
            if (window.addEventListener) {
                df.events.addDomCaptureListener("focus", this._eHead, this.onFocus, this);
                df.events.addDomCaptureListener("blur", this._eHead, this.onBlur, this);
            } else {
                df.dom.on("focusin", this._eHead, this.onFocus, this);
                df.dom.on("focusout", this._eHead, this.onBlur, this);
            }
        }
    }

    /*
    Pass the focus on to the children like a container.
    */
    focus(bOptSelect) {

        for (let i = 0; i < this._aChildren.length; i++) {
            if (this._aChildren[i].focus) {
                if (this._aChildren[i].focus(bOptSelect)) {
                    return true;
                }
            }
        }

        return false;
    }

    /* 
    The conditionalFocus only really gives the focus to an element on desktop browsers where on mobile 
    browsers it only registers the object as having the focus without actually giving the focus to the 
    DOM. 
    
    @param  bOptSelect      Select the text in forms if true.
    @return True if the focus is taken.
    */
    conditionalFocus(bOptSelect) {

        for (let i = 0; i < this._aChildren.length; i++) {
            if (this._aChildren[i].conditionalFocus) {
                if (this._aChildren[i].conditionalFocus(bOptSelect)) {
                    return true;
                }
            }
        }

        return false;
    }

    /*
    Make sure that we only forward focus events if we don't already have the focus. Also cancel the blur 
    timeout.
    
    @param  oEvent  Event object.
    @private
    */
    onFocus(oEvent) {
        if (!this._bHasFocus) {
            super.onFocus(oEvent);
        }

        this._bLozingFocus = false;
    }

    /*
    Since the focus can change within the control we only forward the blur after a small timeout. If 
    focus events occur within this timeout we know that the control still has the focus so we don't 
    perform the blur.
    
    @param  oEvent  Event object.
    @private
    */
    onBlur(oEvent) {
        const that = this;
        const superFunction = super.onBlur

        this._bLozingFocus = true;

        setTimeout(function () {
            if (that._bLozingFocus) {
                superFunction.call(that, oEvent);

                that._bLozingFocus = false;
            }
        }, 100);
    }


    // - - - - Generic - - - - 

    /*
    This method loops over the tabs and makes sure all of them are hidden and the right one is shown.
    
    @private
    */
    showCard(oDisplay, bOptFirst) {
        if (this.isEnabled() || bOptFirst) {   // Is the right place to do this thing (should a disabled card container not be able to change cards dynamically?)?
            if (oDisplay && oDisplay.isActive()) {
                //  Fire cardchange event if needed
                if (!bOptFirst && oDisplay !== this._oCurrent) {
                    this.fireCardChange(oDisplay._sName, (this._oCurrent && this._oCurrent._sName) || "");
                }

                //  Visit all tabs showing / hiding them
                if (this._eElem) {
                    for (let i = 0; i < this._aCards.length; i++) {
                        const oTab = this._aCards[i];

                        if (oTab === oDisplay) {
                            oTab._show(!!bOptFirst);

                            if (this._eLabel) {
                                df.dom.setText(this._eLabel, oTab.psCaption);
                            }
                        } else {
                            oTab._hide(!!bOptFirst);
                        }
                    }
                }

                //  Trigger afterHide
                if (!bOptFirst && this._oCurrent) {
                    this._oCurrent.afterHide();
                }

                this._oCurrent = oDisplay;

                //  Trigger afterShow
                if (!bOptFirst) {
                    this._oCurrent.afterShow();
                }

                if (this.getWebApp()) {
                    this.getWebApp().notifyLayoutChange(this);
                }
            }
        }
    }

    fireCardChange(sTo, sFrom) {
        this.fire('OnCardChange', [sTo, sFrom]);
    }

    hideCard(oHide) {
        let oLast = null, bFound = false;
        if (oHide === this._oCurrent) {
            //  Find the next tab to display
            for (let i = 0; i < this._aCards.length; i++) {
                const oTab = this._aCards[i];

                if (oTab.isActive()) {
                    if (bFound) {
                        this.showCard(oTab);
                        return;
                    }
                    oLast = oTab;
                }

                if (oTab === oHide) {
                    bFound = true;
                }
            }

            this.showCard(oLast);
        }
    }

    nextCard() {
        let bFound = false;

        for (let i = 0; i < this._aCards.length; i++) {
            const oTab = this._aCards[i];

            if (!bFound) {
                bFound = (oTab === this._oCurrent);
            } else {
                if (oTab.isActive()) {
                    this.showCard(oTab);
                    return;
                }
            }
        }
    }

    previousCard() {
        let bFound = false;

        for (let i = this._aCards.length - 1; i >= 0; i--) {
            const oTab = this._aCards[i];

            if (!bFound) {
                bFound = (oTab === this._oCurrent);
            } else {
                if (oTab.isActive()) {
                    this.showCard(oTab);
                    return;
                }
            }
        }
    }

    get_psCurrentCard() {
        return (this._oCurrent && this._oCurrent.getLongName()) || "";
    }

    /*
    Augment the genClass function to add classes indicating wether a caption and / or a border is shown.
    
    @private
    */
    genClass() {
        let sClass = super.genClass();

        if (this.pbShowCaption) {
            sClass += " WebCC_HasCaption";
        }
        if (this.pbShowBorder) {
            sClass += " WebCC_HasBorder";
        }

        return sClass;
    }

    set_pbShowBorder(bVal) {
        if (this._eElem) {
            df.dom.toggleClass(this._eElem, "WebCC_HasBorder", bVal);

            this.sizeChanged();
        }
    }

    set_pbShowCaption(bVal) {
        if (this._eElem) {
            df.dom.toggleClass(this._eElem, "WebCC_HasCaption", bVal);

            this.sizeChanged();
        }
    }

    set_psBackgroundColor(sVal) {
        if (this._eLabel) {
            this._eLabel.style.background = sVal || '';
        }
        if (this._eControl) {
            this._eControl.style.background = sVal || '';
        }
    }
};
