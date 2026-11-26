import { WebForm } from './WebForm.js';
import { df } from '../df.js';

/*
Class:
    df.WebSuggestionForm
Extends:
    df.WebForm

Implementation of the web suggestion form that is capable of showing a list of suggestions while 
typing. These suggestions can come from a variety of sources which is mainly determined on the 
server.

Revision:
    2013/10/12  (HW, DAW) 
        Initial version.
*/
export class WebSuggestionForm extends WebForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psPopupCSSClass", "");

        this.prop(df.tInt, "peSuggestionMode", df.smFind);
        this.prop(df.tBool, "pbCaseSensitive", false);
        this.prop(df.tBool, "pbAllowForce", true);
        this.prop(df.tBool, "pbFullText", false);
        this.prop(df.tBool, "pbHighlight", true);
        this.prop(df.tBool, "pbShowResults", true);
        this.prop(df.tInt, "piMaxResults", 15);
        this.prop(df.tInt, "piStartAtChar", 2);
        this.prop(df.tInt, "piSuggestionWidth", 0);

        this.prop(df.tBool, "pbClientRefinement", true);

        this.prop(df.tInt, "piPopupTimeout", 50);
        this.prop(df.tInt, "piTypeTimeout", 20);

        this.event("OnHideSuggestions", df.cCallModeDefault);

        this._eSuggestions = null;
        this._bForceDisplay = false;
        this._tRepos = null;
        this._aScrollListeners = null;

        this._sSelectedId = null;
    }

    /* 
    Augment openHtml to insert hidden suggestion list div elements.
    
    @param  aHtml   String builder array.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        //aHtml.push('<div class="WebSuggestions WebSug_Hidden"><div class="WebSug_Content"></div><div>'); 
    }

    /* 
    Augment afterRender to initialize suggestionlist (find elements, attach listeners).
    
    @private
    */
    afterRender() {
        //this._eSuggestions = df.dom.query(this._eElem, "div.WebSuggestions");
        //this._eSugContent = df.dom.query(this._eElem, "div.WebSug_Content");

        super.afterRender();

        df.dom.on("keyup", this._eControl, this.onSuggestKey, this);

    }

    initDOM() {
        //  Create elem
        this._eSuggestions = df.dom.create('<div class="WebSuggestions WebSug_Hidden ' + this.psPopupCSSClass + '"><div class="WebSug_Content"></div><div>');
        this._eSugContent = df.dom.query(this._eSuggestions, "div.WebSug_Content");

        //  Insert
        const eViewPort = this.topLayer() || document.body;
        eViewPort.appendChild(this._eSuggestions);

        df.dom.on("click", this._eSuggestions, this.onSuggestClick, this);
    }

    /*
    This method updates the suggestion list according to the current field value. It will initiate the 
    loading of values from the server, refinement on the client and will hide the list if needed.
    */
    suggestUpdate() {
        const that = this;

        this.updateTypeVal();
        const sVal = this.getServerVal();

        if (sVal !== this._sSuggestPrevVal || this._bForceDisplay) {
            this._sSuggestPrevVal = sVal;

            if (sVal.length >= this.piStartAtChar || this._bForceDisplay) {
                if (this._bSuggestVisible) {
                    if (this.pbClientRefinement && this._sSuggestBaseVal) {
                        if (sVal.substr(0, this._sSuggestBaseVal.length) === this._sSuggestBaseVal) {
                            this.suggestRefine(sVal);
                            return;
                        }
                    }
                } else {
                    if (!this._tSuggestDisplay) {
                        this._tSuggestDisplay = setTimeout(function () {
                            that._tSuggestDisplay = null;
                            that.suggestDisplay();
                        }, this.piPopupTimeout);
                    }
                }


                this.suggestLoad();
            } else if (this._bSuggestVisible) {
                this.suggestHide();
            }

        }
    }


    /* 
    This method displays the loading symbol and sets a small timeout that will perform the loading call. 
    This timeout gives the user a chance to continue typing.
    
    @private
    */
    suggestLoad() {
        const that = this;

        if (this.pbShowResults) {
            if (!this._eSuggestions) {
                this.initDOM();
            }

            df.dom.addClass(this._eSuggestions, "WebSug_Loading");
        }
        if (this._eElem) {
            df.dom.addClass(this._eElem, "WebSug_Loading");
        }

        if (!this._tSuggestUpdate) {
            this._tSuggestUpdate = setTimeout(function () {
                that._tSuggestUpdate = null;

                that.updateTypeVal();
                that.suggestDoLoad(that.getServerVal());
            }, this.piTypeTimeout);
        }
    }


    /* 
    This method sends the server call that will load new suggestions. This method sends the server call 
    that will load new suggestions. If a call is already being performed it will wait until that call is 
    finished before sending a new call.
    
    @param  sVal    The search value.
    @private
    */
    suggestDoLoad(sVal) {
        if (!this._bSuggestLoading) {
            this._bSuggestLoading = true;

            this.serverAction("FindSuggestions", [sVal], null, function () {
                this._bSuggestLoading = false;

                if (this._sSuggestNextLoad) {
                    this.suggestDoLoad(this._sSuggestNextLoad);
                    this._sSuggestNextLoad = null;
                } else {
                    if (this._eSuggestions) {
                        df.dom.removeClass(this._eSuggestions, "WebSug_Loading");
                    }
                    if (this._eElem) {
                        df.dom.removeClass(this._eElem, "WebSug_Loading");
                    }
                }

            }, this);
        } else {
            this._sSuggestNextLoad = sVal;
        }
    }

    /*
    This method is called by the server when new suggestions are loaded. This is usually triggered by 
    the FindSuggestions server call. It will process the suggestions and update the display. The 
    suggestions are sent as action data (in the value tree format).
    
    @param  sVal    The search value.
    @client-action
    */
    suggestHandle(sVal) {
        let bFound = false, bRefine;

        //  Load and deserialize suggestions from the action data
        const aList = this._tActionData;

        //  Get the current control value
        this.updateTypeVal();
        const sCurVal = this.getServerVal();

        //  Check if the value didn't change during the call
        if (sCurVal !== sVal) {
            if (this.pbClientRefinement && sCurVal.substr(0, sVal) === sVal) {
                bRefine = true;
            } else {
                return;
            }
        }

        //  Update suggestion administration
        this._sSuggestBaseVal = sVal;
        this._aSuggestBase = this._aSuggestRows = aList;

        //  Refind the selected value value
        for (let i = 0; i < aList.length; i++) {
            if (aList[i].sRowId === this._sSelectedId) {
                bFound = true;
            }
        }
        //  Select the first if not found
        if (!bFound) {
            this._sSelectedId = (aList.length > 0 ? aList[0].sRowId : null);
        }

        //  Update the display
        if (bRefine) {
            this.suggestRefine(sCurVal);
        } else {
            this.suggestRender(sVal);
        }
    }


    /* 
    This method displays the suggestion box by setting the proper CSS Classnames.
    */
    suggestDisplay() {
        if (this.isEnabled()) {
            if (this.pbShowResults) {
                if (!this._eSuggestions) {
                    this.initDOM();
                }

                if (!this._aSuggestRows) {
                    this._eSugContent.innerHTML = "";
                }

                this.suggestPosition();

                df.dom.addClass(this._eSuggestions, "WebSug_Visible");
                df.dom.removeClass(this._eSuggestions, "WebSug_Hidden");

                this.suggestPosition();

                df.dom.on("resize", window, this.onWindowResize, this);
                this._aScrollListeners = df.sys.gui.addScrollListeners(this._eWrap, this.onWindowResize, this);
            }
            this._bSuggestVisible = true;
        }
    }

    /*
    This method calculates the position of the suggestions. It positions the suggestions absolute below 
    the wrapper element of the form. If there is no space below the form it will try to position it 
    above.
    
    @private
    */
    suggestPosition() {

        const eSugg = this._eSuggestions;
        const eTarget = this._eWrap; //  The element to position next

        if (eSugg && eTarget) {
            if (df.sys.gui.isOnScreen(eTarget)) {
                eSugg.style.display = "";

                //  Determine position of target (the form)
                const oRect = df.sys.gui.getBoundRect(eTarget);

                //  Calculate top position
                const iOffsetTop = oRect.bottom; // oRect.top + oRect.height;

                //  Calculate left position
                let iOffsetLeft = oRect.left;

                if (oRect.left + (this.piSuggestionWidth > 0 ? this.piSuggestionWidth : oRect.width) > window.innerWidth) {
                    iOffsetLeft = window.innerWidth - (this.piSuggestionWidth > 0 ? this.piSuggestionWidth : oRect.width);
                }

                //  Set position
                eSugg.style.top = iOffsetTop + "px";
                eSugg.style.left = iOffsetLeft + "px";
                eSugg.style.width = (this.piSuggestionWidth > 0 ? this.piSuggestionWidth : oRect.width) + "px";

                if (oRect.bottom + this._eSugContent.clientHeight > window.innerHeight) {
                    this._eSuggestions.style.bottom = "0px";
                } else {
                    this._eSuggestions.style.bottom = "";
                }
            } else {
                eSugg.style.display = "none";
            }
        }
    }

    /* 
    This method hides the suggestion list. It clears all timers and the suggestion administration. 
    Hiding is done by changing the CSS Classnames.
    */
    suggestHide() {
        if (this._eSuggestions) {
            df.dom.addClass(this._eSuggestions, "WebSug_Hidden");
            df.dom.removeClass(this._eSuggestions, "WebSug_Visible");

            if (this._tSuggestDisplay) {
                clearTimeout(this._tSuggestDisplay);
                this._tSuggestDisplay = null;
            }
            if (this._tSuggestUpdate) {
                clearTimeout(this._tSuggestUpdate);
                this._tSuggestUpdate = null;
            }

            this.updateTypeVal();
            this._sSuggestPrevVal = this.getServerVal();

            df.dom.off("resize", window, this.onWindowResize, this);
            if (this._aScrollListeners) {
                df.sys.gui.removeScrollListeners(this._aScrollListeners, this);
            }

            this._aSuggestRows = null;
            this._sSelectedId = null;
        }
        this.fire("OnHideSuggestions", []);

        this._bSuggestVisible = false;
        this._bForceDisplay = false;

    }


    /* 
    Updates the displayed suggestion list.
    
    @param  sSearch     The current search value.
    */
    suggestRender(sSearch) {
        let sLowerSearch, iLen, oRegEx;
        const aHtml = []
        const aList = this._aSuggestRows

        function makeBold(sMatch) {
            return '<b>' + sMatch + '</b>';
        }

        if (this._eSuggestions) {
            //  Prepare highlight searches
            if (this.pbHighlight) {
                if (this.pbFullText) {
                    oRegEx = new RegExp(df.sys.data.escapeRegExp(sSearch), (this.pbCaseSensitive ? 'g' : 'gi'));
                } else {
                    sLowerSearch = sSearch.toLowerCase();
                    iLen = sSearch.length;
                }
            }


            //  Generate result table
            aHtml.push('<table>');

            for (let i = 0; i < aList.length; i++) {
                aHtml.push('<tr data-suggestnr="', i, '" class="WebSug_Suggestion ', (aList[i].sRowId === this._sSelectedId ? 'WebSug_Selected' : ''), '">');

                for (let x = 0; x < aList[i].aValues.length; x++) {
                    const sVal = aList[i].aValues[x];

                    aHtml.push('<td>');

                    //  Do highlighting
                    if (this.pbHighlight && (this.peSuggestionMode !== df.smValidationTable || x === 0)) {
                        if (this.pbFullText) {
                            //  Perform a find and replace to highlight keyword(s)
                            aHtml.push(sVal.replace(oRegEx, makeBold));
                        } else {
                            if (sVal.substr(0, iLen).toLowerCase() === sLowerSearch) {
                                aHtml.push('<b>', sVal.substr(0, iLen), '</b>', sVal.substr(iLen));
                            } else {
                                aHtml.push(sVal);
                            }
                        }
                    } else {
                        aHtml.push(sVal);
                    }

                    aHtml.push('</td>');
                }

                aHtml.push('</tr>');
            }

            aHtml.push('</table>');

            this._eSugContent.innerHTML = aHtml.join("");
            this.suggestPosition();
        }
    }
    /* 
    This method performs the client-side filtering / refinement using the search value. It will go over 
    the available suggestions and remove the items that do not apply the filter. If we were starting 
    with the maximum amount of suggestions it will trigger suggestLoad to reload from the server as 
    there might be more matches.
    
    @param  sSearch     The search string.
    */
    suggestRefine(sSearch) {
        let bServer = true, bFound = false;
        const aList = [];
        const aBase = this._aSuggestBase

        if (this.pbFullText) {
            const oRegEx = new RegExp(df.sys.data.escapeRegExp(sSearch), (this.pbCaseSensitive ? '' : 'i'));

            for (let i = 0; i < aBase.length; i++) {
                for (let x = 0; x < (this.peSuggestionMode !== df.smValidationTable ? aBase[i].aValues.length : 1); x++) {
                    if (oRegEx.test(aBase[i].aValues[x])) {
                        aList.push(aBase[i]);

                        bFound = (bFound || aBase[i].sRowId === this._sSelectedId);
                        break;
                    }
                }
            }

            this._aSuggestRows = aList;

            this.suggestRender(sSearch);
            if (aBase.length >= this.piMaxResults && aList.length < this.piMaxResults) {
                this.suggestLoad();
            }

        } else {
            const sLowVal = sSearch.toLowerCase();
            const iLen = sSearch.length;

            for (let i = 0; i < aBase.length; i++) {
                if ((!this.pbCaseSensitive && aBase[i].aValues[0].substr(0, iLen).toLowerCase() === sLowVal) ||
                    (this.pbCaseSensitive && aBase[i].aValues[0].substr(0, iLen) === sSearch)) {

                    aList.push(aBase[i]);

                    bFound = (bFound || aBase[i].sRowId === this._sSelectedId);
                } else if (aList.length > 0) {
                    bServer = (this.peDataType === df.ciTypeBCD);
                }
            }

            this._aSuggestRows = aList;

            //  Determine selected id
            if (!bFound) {
                this._sSelectedId = (aList.length > 0 ? aList[0].sRowId : null);
            }

            this.suggestRender(sSearch);
            if (aBase.length >= this.piMaxResults && bServer && sSearch !== this._sSuggestBaseVal) {
                this.suggestLoad();
            }
        }
    }

    /*
    Selects the item by sending a call to the server with the selected suggestion details.
    */
    suggestSelect() {
        let tRow = null;
        const aList = this._aSuggestRows;

        if (this._sSelectedId) {
            for (let i = 0; i < aList.length; i++) {
                if (aList[i].sRowId === this._sSelectedId) {
                    tRow = aList[i];
                    break;
                }
            }

            if (tRow) {
                this.updateTypeVal();

                this.serverAction("SelectSuggestion", [this.getServerVal()], [tRow], function (oEvent) {
                    this.suggestHide();
                });
            }
        }
    }

    /* 
    Moves the selection suggestion up or down.
    
    @param  iDir    Direction (-1 goes one up and 1 goes one down).
    @private
    */
    suggestMove(iDir) {
        let i
        const aList = this._aSuggestRows;

        if (this._sSelectedId) {
            for (i = 0; i < aList.length; i++) {
                if (aList[i].sRowId === this._sSelectedId) {
                    break;
                }
            }

            i = i + iDir;

            i = (i >= 0 ? (i < aList.length ? i : aList.length - 1) : 0);

            this.suggestHightlight(aList[i].sRowId);
        } else {
            this.suggestHightlight(aList.length > 0 ? aList[0].sRowId : null);
        }
    }

    /*
    Highlights the specified suggestion in the list by applying the WebSug_Selected CSS Classname to its 
    tr DOM element.
    
    @param  sId     ID of suggestion.
    @private
    */
    suggestHightlight(sId) {
        this._sSelectedId = sId;

        this.updateTypeVal();
        this.suggestRender(this.getServerVal());

        const eElem = df.dom.query(this._eSugContent, "tr.WebSug_Selected");

        if (eElem) {
            const iTop = df.sys.gui.getAbsoluteOffset(eElem).top;
            const iBottom = iTop + eElem.offsetHeight;

            if (iTop - this._eSuggestions.scrollTop < 0) {
                this._eSuggestions.scrollTop = iTop;
            } else if (iBottom > this._eSuggestions.clientHeight + this._eSuggestions.scrollTop) {
                this._eSuggestions.scrollTop = iBottom - this._eSuggestions.clientHeight;
            }
        }


    }

    /* 
    Handles the click event of the suggestionlist.
    
    @param  oEvent  Event object (see df.events.DOMEvent).
    @private
    */
    onSuggestClick(oEvent) {
        let eElem = oEvent.getTarget();

        while (eElem.tagName !== "TR" && eElem.parentNode && eElem !== this._eSugContent) {
            eElem = eElem.parentNode;
        }

        if (eElem.hasAttribute("data-suggestnr")) {
            const iRow = parseInt(eElem.getAttribute("data-suggestnr"), 10);

            if (this._aSuggestRows[iRow]) {
                this.suggestHightlight(this._aSuggestRows[iRow].sRowId);
                this.suggestSelect();
                this.focus();
            }
        }
    }

    /* 
    Enforces the display and loading of suggestions. Designed to be used from the server or as event 
    handler on psClientOnPrompt.
    
    @client-action
    */
    showSuggestions() {
        this._bForceDisplay = true;

        if (!this._bSuggestVisible) {
            this.suggestDisplay();
        }
        this.suggestUpdate();
        this.focus();
    }


    /* 
    Augments the key handler and implements the key operations.
    
    NOTE: The WebColumnSuggestion has its own onKey handler!
    
    @param  oEvent  Event object (see df.events.DOMEvent).
    @private
    */
    onKey(oEvent) {
        const oKeys = df.settings.suggestionKeys;

        super.onKey(oEvent);

        if (!oEvent.bCanceled) {
            if (this._bSuggestVisible && this.pbShowResults) {
                if (oEvent.matchKey(oKeys.escape)) {
                    this.suggestHide();
                    // oEvent.stop();
                } else if (oEvent.matchKey(oKeys.select)) {
                    this.suggestSelect();
                    oEvent.stop();
                } else if (oEvent.matchKey(oKeys.moveUp)) {
                    this.suggestMove(-1);
                    oEvent.stop();
                } else if (oEvent.matchKey(oKeys.moveDown)) {
                    this.suggestMove(1);
                    oEvent.stop();
                }
            }

            //  Make sure force display doesn't change value
            if (oEvent.matchKey(oKeys.forceDisplay) && this.pbAllowForce) {
                oEvent.stop();
            }
        }
    }

    /* 
    Handles the keyup event and performs the force display if needed. 
    
    TODO: Not sure why we do this in keyup but there must be a good reason!
    
    @param  oEvent  Event object (see df.events.DOMEvent);
    @private
    */
    onSuggestKey(oEvent) {
        const oKeys = df.settings.suggestionKeys, iKey = oEvent.getKeyCode();
        // df.WebSuggestionForm.base.onKey.call(this, oEvent);

        if (oEvent.matchKey(oKeys.forceDisplay) && this.pbAllowForce) {
            this._bForceDisplay = true;
            if (!this._bSuggestVisible) {
                this.suggestDisplay();
            }
            oEvent.stop();
        }

        if (this._bSuggestVisible) {
            this.suggestUpdate();
        } else {
            if (!oEvent.isSpecialKey() && (iKey < 112 || iKey > 127)) { //  Explicitly filter out function keys (to prevent responding to finds)
                this.suggestUpdate();
            }
        }
        this._bForceDisplay = false;
    }

    /* 
    Listener of the window resize and scroll events. Triggers a reposition action and repeats that after 
    a small timeout.
    
    @param  oEvent  DOM Event object (see: df.events.DOMEvent)
    @private
    */
    onWindowResize(oEvent) {
        const that = this;

        if (!this._tRepos) {
            setTimeout(function () {
                that.suggestPosition();
                that._tRepos = null;
            }, 40);
        }

        this.suggestPosition();
    }

    /* 
    Augment the blur event and hide the suggestion list.
    
    @param  oEvent  Event object (see df.events.DOMEvent);
    @private
    */
    onBlur(oEvent) {
        const that = this;

        super.onBlur(oEvent);

        if (this._tSugBlurTimeout) {
            clearTimeout(this._tSugBlurTimeout);
            this._tSugBlurTimeout = null;
        }

        this._tSugBlurTimeout = setTimeout(function () {
            if (!that._bHasFocus) {
                that.suggestHide();
            }
        }, 500);
    }

    /*
    Setter that updates the CSS class on the DOM element if it was rendered.
    */
    set_psPopupCSSClass(sVal) {
        if (this._eSuggestions) {
            this._eSuggestions.className = "WebSuggestions " + (this._bSuggestVisible ? "WebSug_Visible" : "WebSug_Hidden") + sVal;
        }
    }
}