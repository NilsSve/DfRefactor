import { WebCardContainer } from './WebCardContainer.js';
/* 
Class:
    df.WebAccordionContainer
Extends:
    df.WebCardContainer

Accordion control that based on card container technology. It supports multiple modes with 
pbMultiOpen, pbAutoHeight and pbOpenFirst. The df.WebAccordionCard implements the card interface.

Revision:
    2016/10/06  (HW, DAW)
        Refactored into df.WebAccordionContainer.
    2016/06/27  (HW, DAW)
        Migrated to DataFlex 18.2 with support for the deferred card rendering and isEnabled.
    2015/09/29  (HW, DAW)
        Initial version.
*/
/* global df */

export class WebAccordionContainer extends WebCardContainer {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tBool, "pbOpenFirst", true);
        this.prop(df.tBool, "pbAutoHeight", true);
        this.prop(df.tBool, "pbMultiOpen", false);

        //  Configure super classes
        this._sControlClass = "WebAccordion";
        this._sCardClass = "WebAC";
        this._bCC = false; //  Used by the designer to filter cardcontainers from tab / accordion containers
    }

    /*
    Override since we don't want a header with tab buttons to be generated.
    
    @param  aHtml   String builder array.
    @private
    */
    headHtml(aHtml) {

    }

    afterRender() {
        const that = this;

        super.afterRender();

        df.dom.on("transitionend", this._eElem, this.onTransEnd, this);

        this.openCardsAfterRender();

        setTimeout(function () {
            df.dom.addClass(that._eElem, "WebAc_Rendered");
        }, 100);

    }

    openCardsAfterRender() {

        if (this.pbMultiOpen) {
            for (let i = 0; i < this._aCards.length; i++) {
                const oTab = this._aCards[i];
                if (oTab.pbExpanded || oTab._bExpanded) {
                    this.showCard(oTab, false);
                }
            }
        }
    }

    renderChildren(eContainer) {
        let eRenderTo, bDynamic = this.hasDynamicHeight();

        //  Determine initial current card
        if (this.pbOpenFirst) {
            if (this.psCurrentCard) {
                this._oCurrent = this.getWebApp().findObj(this.psCurrentCard);
            }

            for (let i = 0; i < this._aCards.length && !this._oCurrent; i++) {
                if (this._aCards[i].isActive()) {
                    this._oCurrent = this._aCards[i];
                }
            }
        }

        eRenderTo = this._eControl = df.dom.query(this._eElem, 'div.' + this._sCardClass + '_Body');

        for (let i = 0; i < this._aCards.length; i++) {
            //  Generate and append button
            const aHtml = [];
            this._aCards[i].tabButtonHtml(aHtml);
            const eButton = df.dom.create(aHtml.join(""));
            eRenderTo.appendChild(eButton);
            this._aCards[i].btnRendered(eButton);
            // this._aCards[i]._eBtn = eButton;

            if (bDynamic || this._aCards[i] === this._oCurrent) {
                const eTab = this._aCards[i].render();
                eRenderTo.appendChild(eTab);
            }
        }
    }

    showCard(oDisplay, bOptFirst) {
        const that = this;

        if (this.isEnabled() || bOptFirst) {
            if (this.pbMultiOpen) {
                if (oDisplay && !bOptFirst) {
                    oDisplay._bExpanded = true;
                    oDisplay._show();
                    oDisplay.afterShow();
                }
            } else {
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

                                df.dom.setText(this._eLabel, oTab.psCaption);
                            } else {
                                oTab._hide(!!bOptFirst);
                            }
                        }
                    }

                    //  Trigger afterHide
                    if (!this.pbMultiOpen) {
                        if (!bOptFirst && this._oCurrent) {
                            this._oCurrent.afterHide();
                        }
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


            if (!this.pbFillHeight && (!this.pbAutoHeight || this.pbMultiOpen)) {
                this.sizeChanged(true);

                setTimeout(function () {
                    that.sizeChanged(true);
                }, 1000);
            }
        }
    }

    /* 
    Override renderAllCards to make sure that the card elements are placed as next sibling of the tab 
    buttons.
    
    @private
    */
    renderAllCards() {

        for (let i = 0; i < this._aCards.length; i++) {
            const oCard = this._aCards[i];
            if (!oCard._eElem) {
                const eElem = oCard.render();
                if (!oCard._eBtn) {
                    throw new df.Error(999, "Assertion: Accordion card should have a button element!");
                } else {
                    if (oCard._eBtn.nextSibling) {
                        oCard._eBtn.parentNode.insertBefore(eElem, oCard._eBtn.nextSibling);
                    } else {
                        oCard._eBtn.parentNode.appendChild(eElem);
                    }
                }
                oCard.afterRender();
            }
        }
    }

    /*
    
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
            }
        }

        //  Respect minimal height
        if (iHeight < this.piMinHeight) {
            iHeight = this.piMinHeight;
        }

        //  Update the height
        this.setHeight(iHeight);

        //  Return the final height
        if (iHeight > 0) {
            return iHeight;
        }
    }

    setHeight(iHeight) {
        super.setHeight(iHeight);

        if (this.pbFillHeight && this._oCurrent) {
            this._oCurrent._eElem.style.height = this.getCardHeight(this._oCurrent) + "px";
        }
    }

    getCardHeight(oCard, iNaturalHeight) {
        let iHeight;

        if (this.pbAutoHeight || this.pbFillHeight) {
            if (this.piHeight > 0 || this.pbFillHeight) {
                iHeight = df.dom.clientHeight(this._eControl);

                iHeight -= df.sys.gui.getVertBoxDiff(this._eControl, 2);

                for (var i = 0; i < this._aCards.length; i++) {
                    if (this._aCards[i]._eBtn) {
                        iHeight -= this._aCards[i]._eBtn.offsetHeight;
                    }
                }

                return iHeight;
            } else {
                return this.getNaturalHeight() - this.getHeightDiff();
            }
        } else {
            return (oCard && df.dom.clientHeight(oCard._eSizer)) || 0;
        }

    }

    attachFocusEvents() {

    }

    resize() {
        let iCardHeight = 0;

        if (this._eElem && this._bRendered) {
            if (this.pbAutoHeight || this.pbFillHeight) {
                iCardHeight = this.getCardHeight(null);
            }

            //  Resize the tabpages
            for (let i = 0; i < this._aCards.length; i++) {
                if (this._aCards[i]._eElem) {
                    if (iCardHeight > 0) {
                        this._aCards[i]._eContainer.style.height = iCardHeight + "px";
                    } else {
                        this._aCards[i]._eContainer.style.height = "";
                    }

                    this._aCards[i].resizeHorizontal();
                    this._aCards[i].resizeVertical();
                }
            }

            //  A resize can also mean that the tab page size changed, if pbFillHeight is true sizeHeight will be called by container, if not we force it here!
            if (!this.pbFillHeight) {
                this.sizeHeight(-1);
            }
        }
    }

    /* 
    On transitionend (which triggers after the transition for opening / closing a card finishes) we will 
    trigger a resize.
    
    @param  oEv     DOM Event object.
    @private
    */
    onTransEnd(oEv) {
        this.sizeChanged(true);
    }

    set_pbMultiOpen(bVal) {
        this.pbMultiOpen = bVal;

        if (!bVal) {
            for (let i = 0; i < this._aCards.length; i++) {
                this._aCards[i]._bExpanded = false;
            }

            //  Make sure that only one card will be shown
            if (this._oCurrent) {
                this.showCard(this._oCurrent);
            }
        }
    }

    set_pbAutoHeight(bVal) {
        if (this.pbAutoHeight !== bVal) {
            this.pbAutoHeight = bVal;

            this.triggerCardResize(!bVal);
        }
    }

    set_pbFillHeight(bVal) {
        if (this.pbFillHeight !== bVal) {
            super.set_pbFillHeight(bVal);

            this.triggerCardResize(!bVal);
        }
    }

    /* 
    Triggers the cards to resize themselves and clears innerHeights that might have been set. This is 
    used when dynamically changing pbAutoHeight and pbFillHeight.
    
    #param  bClearInnerHeight       If true the innerheight of the cards will be reset.
    @private
    */
    triggerCardResize(bClearInnerHeight) {

        //  Clear the innerheight that is set by the WebBaseContainer resizeVertical
        if (bClearInnerHeight) {
            for (let i = 0; i < this._aCards.length; i++) {
                this._aCards[i].setInnerHeight(0);
            }
        }

        //  Reopen the cards to enforce proper height recalculation
        if (this.pbMultiOpen) {
            for (let i = 0; i < this._aCards.length; i++) {
                if (this._aCards[i]._bExpanded) {
                    this._aCards[i]._show();
                }
            }
        } else {
            if (this._oCurrent) {
                this.showCard(this._oCurrent);
            }
        }

        this.sizeChanged(true);
    }
};