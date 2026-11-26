import { WebForm } from './WebForm.js';
/*
Class:
    df.WebBaseSelectionForm
Extends:
    df.WebForm

This is the base class for the: cWebSelectionForm and the cWebTagsForm.

Revision:
    2020/09/25  (HW, DAW)
        Initial version.
*/
export class WebBaseSelectionForm extends WebForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbCaseSensitive", false);
        this.prop(df.tBool, "pbFullText", false);
        this.prop(df.tInt, "piPageSize", 15);
        this.prop(df.tInt, "piStartAtChar", 2);
        this.prop(df.tInt, "piPopupWidth", 0);
        this.prop(df.tString, "psShowMoreText", "Show more...");
        this.prop(df.tString, "psCreateNewItemText", "Create new item");
        this.prop(df.tBool, "pbSourceIsValidationTable", false);
        this.prop(df.tInt, "piMinimumItemLength", 2);
        this.prop(df.tBool, "pbAllowCreate", false);
        this.prop(df.tInt, "piTypeTimeout", 20);

        this.prop(df.tBool, "pbAllData", false);
        this.prop(df.tBool, "pbSuggestions", false);
        this.prop(df.tBool, "pbPaged", false);

        this._eSuggestions = null;
        this._bForceDisplay = false;
        this._tRepos = null;
        this._aSuggestRows = [];
        this._aShownSuggestions = [];
        this._oSelectedSuggestion = null;
        this._iMaxCells = 1;
        this._bFirstFetch = true;
        this._TotalOfControlRows = 0;
        this._ShowNextHandle = false;

        this._iPage = 0;
        this._iAdditionalItems = 0;
        this._oPrevItem = null;
    }

    afterRender() {
        // Create elem.
        this._eSuggestions = df.dom.create('<div class="WebBaseSelectionForm WebSuggestions' +
            ((this.psCSSClass.length > 0) ? " " + this.psCSSClass : '') + ' WebSug_Hidden"><div class="WebSug_Content"></div></div>');
        this._eSugContent = df.dom.query(this._eSuggestions, "div.WebSug_Content");
        this._eSugSuggestions = df.dom.create('<div class="WebSug_Suggestions"></div>');
        this._eSugControls = df.dom.create('<div class="WebSug_Controls"></div>');

        this._eSugContent.appendChild(this._eSugSuggestions);
        this._eSugContent.appendChild(this._eSugControls);

        this._eInputBox = df.dom.query(this._eElem, ".WebFrm_PromptSpacer");
        this._eControl = df.dom.query(this._eInputBox, "input");

        super.afterRender();

        // Insert.
        df.dom.addClass(this._eElem, "WebSelectionForm");

        const eTopLayer = this.topLayer() || document.body;
        eTopLayer.appendChild(this._eSuggestions);

        // Setup event handlers.
        df.dom.on("keyup", this._eControl, this.onSuggestKey, this);
        df.dom.on("click", this._eSuggestions, this.onSuggestClick, this);
        df.dom.on("click", this._eInputBox, this.inputBoxOnClick, this);
        df.dom.on("resize", window, this.onWindowResize, this);

        this.set_pbReadOnly(this.pbReadOnly);
        this.set_pbEnabled(this.isEnabled());
    }

    /*
    Get the value from the inputfield.
    */
    getSearchValue() {
        if (this.pbReadOnly) return "";
        return (this.pbCapslock ? this.getServerVal().toUpperCase() : this.getServerVal());
    }

    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eControl && !(this.pbReadOnly && bVal)) {
            this._eControl.contentEditable = bVal;
        }
    }

    set_pbReadOnly(bVal) {
        this.pbReadOnly = bVal;
        if (this._eControl && !(!this.pbReadOnly && !this.isEnabled())) {
            this._eControl.contentEditable = !this.pbReadOnly;
        }
        this.set_pbPromptButton(this.pbPromptButton && !bVal);
    }

    /*
    Due to CSS styling the whole form isn't stretched in contrast to the tags.
    This function is called if clicked whithin the whitespace of the inputbox, and the focus will still go to the inputfield.

    @private
    */
    inputBoxOnClick(oEvent) {
        if (window.getSelection().type != "Range" && this.isEnabled()) {
            this._eControl.focus();
            oEvent.stop();
        }
    }

    /*
    Selects the item by sending a call to the server with the selected suggestion details.
    */
    suggestSelect() {
        const sValue = this.getSearchValue().trim();
        if (this._oSelectedSuggestion && this._oSelectedSuggestion.control) {
            switch (this._oSelectedSuggestion.sRowId) {
                case "more":
                    this.handleMoreButton();
                    this.suggestMove(-1);
                    return;
                case "create":
                    if (this.isEnabled() && this.pbAllowCreate && sValue.length >= this.piMinimumItemLength) {
                        this.serverAction("CreateNewByValue", [sValue], null, null);
                    }
                    else {
                        return;
                    }
                    break;
            }
        }
        else if (this.isEnabled() && this.pbAllowCreate == 1 && sValue.length >= this.piMinimumItemLength) {
            this.serverAction("CreateNewByValue", [sValue], null, null);
        }
        this._eControl.value = "";
        this.suggestHide();
    }

    handleMoreButton() {
        if (this._bLastItemOnServer) return;
        if (!this._bMoreRequested) {
            this._bMoreRequested = true;
            if (this.pbPaged) this._iPage++;
            this.suggestLoad();
        }
    }

    /* 
    Handles the click event of the suggestionlist.
    
    @param  oEvent  Event object (see df.events.DOMEvent).
    @private
    */
    onSuggestClick(oEvent) {
        let oElem = oEvent.getTarget();

        while (oElem.tagName !== "TR" && oElem.parentNode && oElem !== this._eSugContent) {
            oElem = oElem.parentNode;
        }
        if (oElem.hasAttribute("data-dfrowid")) {
            let oRow = this._aShownSuggestions[parseInt(oElem.getAttribute("data-dfrowid"))];
            if (oRow) {
                this.suggestHightlight(oRow);
                this.suggestSelect();
                this.focus();
            }
        }
    }

    /*
    This method updates the suggestion list according to the current field value. It will initiate the 
    loading of values from the server, refinement on the client and will hide the list if needed.
    */
    suggestUpdate() {
        this.updateTypeVal();
        const sVal = this.getSearchValue().trim();

        if (sVal !== this._sSuggestPrevVal || this._bForceDisplay) {
            this._sSuggestPrevVal = sVal;
            if (sVal.length >= this.piStartAtChar || this._bForceDisplay) {
                if (this._bSuggestVisible) {
                    if (this._sSuggestBaseVal) {
                        if (sVal.substr(0, this._sSuggestBaseVal.length) == this._sSuggestBaseVal) {
                            this.suggestRefine(sVal);
                            return;
                        }
                    }
                }
                this.suggestDisplay();
                this.suggestLoad();
            }
            else if (this._bSuggestVisible) {
                this.suggestHide();
            }
        }
    }

    clientFilter(aList, callbackOnLoop) {
        const aFiltered = [];
        const sCurVal = this.getSearchValue();
        const oRegEx = new RegExp(df.sys.data.escapeRegExp(sCurVal), (this.pbCaseSensitive || this.pbCapslock ? '' : 'i'));

        for (let i = 0; i < aList.length; i++) {
            if (aList[i].control) {
                aFiltered.push(aList[i]);
                continue;
            }
            for (let x = 0; x < aList[i].aValues.length; x++) {
                if (this.pbFullText) {
                    if (oRegEx.test(aList[i].aValues[x])) {
                        aFiltered.push(aList[i]);
                        if (callbackOnLoop) callbackOnLoop(aList[i]);
                        break;
                    }
                } else {
                    if (this.pbCaseSensitive || this.pbCapslock) {
                        if (aList[i].aValues[x].indexOf(sCurVal) == 0) {
                            aFiltered.push(aList[i]);
                            if (callbackOnLoop) callbackOnLoop(aList[i]);
                            break;
                        }
                    } else {
                        if (aList[i].aValues[x].toLowerCase().indexOf(sCurVal.toLowerCase()) == 0) {
                            aFiltered.push(aList[i]);
                            if (callbackOnLoop) callbackOnLoop(aList[i]);
                            break;
                        }
                    }
                }
            }
        }

        return this.extraFilterOnHandle ? this.extraFilterOnHandle(aFiltered) : aFiltered;
    }

    /*
    This method is called by the server when new suggestions are loaded. This is usually triggered by 
    the FindSuggestions server call. It will process the suggestions and update the display. The 
    suggestions are sent as action data (in the value tree format).
    
    @param  sVal    The search value.
    @client-action
    */
    suggestHandle(sVal, bLast) {
        const that = this;
        this._bFirstFetch = false;
        this._bMoreRequested = false;

        this._bLastItemOnServer = bLast == 1;

        let sCurVal, bRefine;
        // Load and deserialize suggestions from the action data.
        const aList = this._tActionData;

        // Get the current control value.
        this.updateTypeVal();
        if (this._eControl) sCurVal = this.getSearchValue();

        // Check if the value didn't change during the call.
        if (sCurVal !== sVal) {
            if (sCurVal.substr(0, sVal) == sVal)
                bRefine = true;
            else return;
        }

        this._iMaxCells = 0;
        for (let i = 0; i < aList.length; i++) {
            if (aList[i].aValues.length > this._iMaxCells) this._iMaxCells++;
        }

        // Update suggestion administration.
        this._sSuggestBaseVal = sVal;
        if (this._iPage > 0 && this.pbPaged) {
            this._aSuggestRows = this._aSuggestRows.concat(aList);
        }
        else {
            this._aSuggestRows = aList;
        }

        this._oPrevItem = this._aSuggestRows[this._aSuggestRows.length - 1];

        // Select the first if not found.
        var bFound;
        let aSelectables = this.clientFilter(this._aSuggestRows, function (tRow) {
            bFound = (bFound || (that._oSelectedSuggestion && tRow.aValues[0] == that._oSelectedSuggestion.aValues[0]));
        });

        if (!bFound)
            this._oSelectedSuggestion = (this._aShownSuggestions.length > 0 ? this._aShownSuggestions[0] : null);

        this._TotalOfControlRows = this.AddControlSuggestions(aSelectables);

        let iIndex = -1;
        if (this._oSelectedSuggestion) iIndex = this.findIndexByValue(this._oSelectedSuggestion.aValues[0], aSelectables);
        if (iIndex < 0) {
            this._oSelectedSuggestion = (aSelectables.length > 0 ? aSelectables[0] : null);
        } else {
            this._oSelectedSuggestion = aSelectables[iIndex];
        }

        // Update the display.
        if (bRefine)
            this.suggestRefine(sCurVal);
        else
            this.suggestRender(sVal);

        if (this._ShowNextHandle) {
            this._ShowNextHandle = false;
            this.showSuggestions();
        }
    }

    /*
    Intermediate event during handling of incoming lists.
    Currently adding control rows.
    */
    AddControlSuggestions(aList) {
        const iAdded = aList.length;
        const sValue = this.getSearchValue().trim();
        if (!this._bLastItemOnServer && this.pbPaged && aList.length > 0 && !this.pbAllData) aList.push({ control: true, sRowId: "more", aValues: ["(" + this.psShowMoreText + ")"], sCssClassName: "Sugg_ControlSuggestion" });
        let bShow = true;
        if (this._aShownSuggestions) bShow = !(this._aShownSuggestions.length > 0 && this._aShownSuggestions[0].aValues[0] == sValue);
        if (bShow && this.pbAllowCreate && sValue.length > 0) aList.push({ control: true, sRowId: "create", aValues: ["(" + this.psCreateNewItemText + (sValue.length > 0 ? " \"" + df.dom.encodeAttr(df.dom.encodeHtml(sValue)) + "\"" : "") + ")"], sCssClassName: "Sugg_ControlSuggestion" });

        return aList.length - iAdded;
    }

    /* 
    Updates the displayed suggestion list.
    
    @param  sSearch     The current search value.
    */
    suggestRender(sSearch) {
        if (!this._eSuggestions) return;

        let sLowerSearch, iLen, oRegEx;
        //  Prepare highlight searches
        if (this.pbFullText) {
            oRegEx = new RegExp(df.sys.data.escapeRegExp(sSearch), (this.pbCaseSensitive || this.pbCapslock ? 'g' : 'gi'));
        } else {
            sLowerSearch = sSearch.toLowerCase();
            iLen = sSearch.length;
        }

        const that = this;
        function renderSuggestion(iIndex, oSuggestion, aHtml) {
            function makeBold(sMatch) {
                return '<b>' + sMatch + '</b>';
            }

            let x = 0;
            aHtml.push('<tr data-dfrowid="',
                iIndex,
                '" class="WebSug_Suggestion ',
                oSuggestion.sCssClassName,
                (that._oSelectedSuggestion && oSuggestion.aValues[0] == that._oSelectedSuggestion.aValues[0] ? ' WebSug_Selected' : ''),
                '">');

            for (x = 0; x < oSuggestion.aValues.length; x++) {
                const sVal = df.dom.encodeHtml(oSuggestion.aValues[x]);

                aHtml.push('<td>');

                // Check whether its a custom row of the control.
                if (oSuggestion.control) {
                    aHtml.push(sVal);
                } else {
                    // Do highlighting
                    if (!that.pbSourceIsValidationTable || x == 0) {
                        if (that.pbFullText) {
                            // Perform a find and replace to highlight keyword(s)
                            aHtml.push(sVal.replace(oRegEx, makeBold));
                        } else {
                            if (sVal.length > 0 && sVal.substr(0, iLen).toLowerCase() == sLowerSearch) {
                                aHtml.push('<b>', sVal.substr(0, iLen), '</b>', sVal.substr(iLen));
                            } else {
                                aHtml.push(sVal);
                            }
                        }
                    } else {
                        aHtml.push(sVal);
                    }
                }

                aHtml.push('</td>');
            }
            while (x++ < that._iMaxCells) {
                aHtml.push('<td></td>');
            }

            aHtml.push('</tr>');
        }

        // Used for the caching of control rows.
        const aControls = [];
        this._aShownSuggestions = this.clientFilter(this._aSuggestRows);
        // Add the control suggestion 
        this._TotalOfControlRows = this.AddControlSuggestions(this._aShownSuggestions);

        //  Generate result table
        const aSuggestionsTable = [];
        aSuggestionsTable.push('<table>');
        const iMaxLength = (this.pbSuggestions ? ((this._aShownSuggestions.length < this.piPageSize) ? this._aShownSuggestions.length : this.piPageSize) : this._aShownSuggestions.length);

        for (let i = 0; i < iMaxLength; i++) {
            // Check if it is a control row and skip
            if (this._aShownSuggestions[i].control) {
                aControls.push({ iIndex: i, oObj: this._aShownSuggestions[i] });
                continue;
            }

            renderSuggestion(i, this._aShownSuggestions[i], aSuggestionsTable);
        }
        aSuggestionsTable.push('</table>');

        // Add the controls to a seperate table.
        const aControlsTable = [];
        aControlsTable.push('<table>')
        for (let i = 0; i < this._TotalOfControlRows; i++) {
            renderSuggestion(aControls[i].iIndex, aControls[i].oObj, aControlsTable);
        }
        aControlsTable.push('</table>');

        this._eSugSuggestions.innerHTML = aSuggestionsTable.join("");
        this._eSugControls.innerHTML = aControlsTable.join("");
        this.suggestPosition();
    }

    /* 
    This method performs the client-side filtering / refinement using the search value. It will go over 
    the available suggestions and remove the items that do not apply the filter. If we were starting 
    with the maximum amount of suggestions it will trigger suggestLoad to reload from the server as 
    there might be more matches.
    
    @param  sSearch     The search string.
    */
    suggestRefine(sFilter) {
        const that = this;
        let bFound = false;
        this._aShownSuggestions = this.clientFilter(this._aSuggestRows, function (tRow) {
            bFound = (bFound || (that._oSelectedSuggestion && tRow.aValues[0] == that._oSelectedSuggestion.aValues[0]));
        });
        if (!bFound)
            this._oSelectedSuggestion = (this._aShownSuggestions.length > 0 ? this._aShownSuggestions[0] : null);

        this.suggestRender(sFilter);
        if (this._bSuggestVisible) this.suggestDisplay();
        this.afterSuggestRefine();
    }

    afterSuggestRefine(sFilter) {
        if (this._aShownSuggestions.length - this._TotalOfControlRows < this.piPageSize && !this._bLastItemOnServer && this.pbPaged) {
            this.handleMoreButton();
        }
    }

    /* 
    Moves the selection suggestion up or down.
    
    @param  iDir    Direction (-1 goes one up and 1 goes one down).
    @private
    */
    suggestMove(iDir) {
        const aList = this._aShownSuggestions = this.clientFilter(this._aSuggestRows);

        this._TotalOfControlRows = this.AddControlSuggestions(aList);

        if (this._oSelectedSuggestion) {
            let i = this.findIndexByValue(this._oSelectedSuggestion.aValues[0], aList) + iDir;
            if (i >= aList.length) i = 0;
            else if (i < 0) i = aList.length - 1;

            this.suggestHightlight(aList[i]);
        }
        else
            this.suggestHightlight(aList.length > 0 ? aList[0] : null);
    }

    /*
    Highlights the specified suggestion in the list by applying the WebSug_Selected CSS Classname to its 
    tr DOM element.
    
    @param  oSelectedSuggestion, Suggestion to be selected.
    @private
    */
    suggestHightlight(oSelectedSuggestion) {
        let bFound;

        this._oSelectedSuggestion = oSelectedSuggestion;

        this._aShownSuggestions = this.clientFilter(this._aSuggestRows);
        this._TotalOfControlRows = this.AddControlSuggestions(this._aShownSuggestions);
        for (let i = 0; i < this._aShownSuggestions.length; i++) {
            bFound = (this._oSelectedSuggestion && this._aShownSuggestions[i].aValues[0] == this._oSelectedSuggestion.aValues[0]);
            if (bFound) break;
        }
        if (!bFound)
            this._oSelectedSuggestion = (this._aShownSuggestions.length > 0 ? this._aShownSuggestions[0] : null);

        this.updateTypeVal();
        this.suggestRender(this.getSearchValue());
        const eElem = df.dom.query(this._eSugSuggestions, "tr.WebSug_Selected");
        if (eElem) {
            const iTop = df.sys.gui.getAbsoluteOffset(eElem).top;
            const iBottom = iTop + eElem.offsetHeight;

            if (iTop - this._eSugSuggestions.scrollTop < 0) {
                this._eSugSuggestions.scrollTop = iTop;
            } else if (iBottom > this._eSugSuggestions.clientHeight + this._eSugSuggestions.scrollTop) {
                this._eSugSuggestions.scrollTop = iBottom - this._eSugSuggestions.clientHeight;
            }
        }
    }

    /*
    Finds the RowId in the suggestion list.
    
    @param sValue
    @retval Either of type tRow or null.
    @private
    */
    findSuggestionByValue(sValue) {
        const iIndex = this.findIndexByValue(sValue, this._aSuggestRows);
        return ((iIndex != -1) ? this._aSuggestRows[iIndex] : null);
    }

    /*
    Finds the index of the row in the passed list.
    
    @param sValue
    @param The list to search in.
    @retval Either the correct index or -1 if not found.
    @private
    */
    findIndexByValue(sValue, aList) {
        for (let i = 0; i < aList.length; i++)
            if (aList[i].aValues[0] == sValue)
                return i;
        return -1;
    }

    /* 
    Handles the keyup event and performs the force display if needed.
    
    @param  oEvent  Event object (see df.events.DOMEvent);
    @private
    */
    onSuggestKey(oEvent) {
        const oKeys = df.settings.suggestionKeys, iKey = oEvent.getKeyCode();

        if (!this.isEnabled() || this.pbReadOnly) {
            oEvent.stop();
            return;
        }

        if (oEvent.matchKey(oKeys.forceDisplay)) {
            this._bForceDisplay = true;
            if (!this._bSuggestVisible) {
                this.suggestDisplay();
            }
            oEvent.stop();
        }

        if (this._bSuggestVisible || this.getSearchValue().length > 0) {
            this.suggestUpdate();
        } else {
            if (!oEvent.isSpecialKey() && (iKey < 112 || iKey > 127)) { //  Explicitly filter out function keys (to prevent responding to finds)
                this.suggestUpdate();
            }
        }
        this._bForceDisplay = false;
    }

    /* 
    This method displays the loading symbol and sets a small timeout that will perform the loading call. 
    This timeout gives the user a chance to continue typing.
    
    @private
    */
    suggestLoad(overrideDoLoad) {
        const that = this;

        // For overriding the load in pbAllData-Mode.
        if (overrideDoLoad) {
            this._overrideDoLoad = overrideDoLoad;
            this.invalidateCache();
        }

        df.dom.addClass(this._eSuggestions, "WebSug_Loading");

        if (this._eElem)
            df.dom.addClass(this._eElem, "WebSug_Loading");

        if (!this._tSuggestUpdate) {
            this._tSuggestUpdate = setTimeout(function () {
                that._tSuggestUpdate = null;

                that.updateTypeVal();
                that.suggestDoLoad(that.getSearchValue());
                if (that._bSuggestVisible) that.suggestDisplay();
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
        // pbAllData needs to load all rows so with no filter.
        if (this.pbAllData) {
            sVal = "";
        }

        if (!this.pbAllData || this._aSuggestRows.length === 0 || this._overrideDoLoad) {
            this._overrideDoLoad = false; // Unset override either way; if we need to check it costs extra.
            if (!this._bSuggestLoading && this.isEnabled()) {
                this._bSuggestLoading = true;

                // Instantiate the finding of suggestions with the input value from the inputbox.
                this.serverAction("FindSuggestions", [sVal, this._iPage, this._iAdditionalItems], this._oPrevItem, function () {
                    this._bSuggestLoading = false;

                    // If the value changed, re-search for the suggestions.
                    // Otherwise remove the loading CSS.
                    if (this._sSuggestNextLoad) {
                        this.suggestDoLoad(this._sSuggestNextLoad);
                        this._sSuggestNextLoad = null;
                    } else {
                        if (this._eSuggestions)
                            df.dom.removeClass(this._eSuggestions, "WebSug_Loading");

                        if (this._eElem)
                            df.dom.removeClass(this._eElem, "WebSug_Loading");

                        if (this._bSuggestVisible) this.suggestDisplay();
                    }

                }, this);
            }
            else
                this._sSuggestNextLoad = sVal;
        }
        else
            this.suggestHightlight(this._oSelectedSuggestion);
    }

    /* 
    This method displays the suggestion box by setting the proper CSS Classnames.
    */
    suggestDisplay() {
        // Avoid display if content is 0.
        const hSuggestionsBody = df.dom.query(this._eSugSuggestions, "tbody");
        const hControlsBody = df.dom.query(this._eSugControls, "tbody");
        if (hSuggestionsBody) {
            if (hSuggestionsBody.childNodes.length == 0 && hControlsBody.childNodes.length == 0) {
                this.suggestHide();
                return;
            }
        }
        else if (!this._bFirstFetch) {
            // It might be that there are controls thus check for that first, if there are continue.
            // For example the Create.
            let bReturn = true;
            if (hControlsBody) {
                if (hControlsBody.childNodes.length > 0) bReturn = false;
            }
            if (bReturn) {
                this.suggestHide();
                this._ShowNextHandle = true;
                return;
            }
        }

        if (this.isEnabled()) {
            df.dom.addClass(this._eSuggestions, "WebSug_Visible");
            df.dom.removeClass(this._eSuggestions, "WebSug_Hidden");

            let iHeight = 0;
            if (hSuggestionsBody) {

                let iMax = (hSuggestionsBody.childNodes.length > this.piPageSize ? this.piPageSize : hSuggestionsBody.childNodes.length);
                if (iMax > 0) {
                    let oBounds = df.sys.gui.getBoundRect(hSuggestionsBody.childNodes[0]);
                    iHeight = oBounds.height * iMax;
                } else {
                    // It might be that there are controls thus check for that first, if there are continue.
                    // For example the Create.
                    let bReturn = true;
                    if (hControlsBody) {
                        if (hControlsBody.childNodes.length > 0) bReturn = false;
                    }
                    if (bReturn) {
                        this.suggestHide();
                        return;
                    }
                }
            }
            this._eSugSuggestions.style.height = iHeight + "px";

            this.suggestPosition();
            this.suggestHightlight(this._oSelectedSuggestion);

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
                const iOffsetLeft = oRect.left;

                if (oRect.left + (this.piPopupWidth > 0 ? this.piPopupWidth : oRect.width) > window.innerWidth) {
                    iOffsetLeft = window.innerWidth - (this.piPopupWidth > 0 ? this.piPopupWidth : oRect.width);
                }

                //  Set position
                eSugg.style.top = iOffsetTop + "px";
                eSugg.style.left = iOffsetLeft + "px";

                eSugg.style.width = (this.piPopupWidth > 0 ? this.piPopupWidth : oRect.width) + "px";

                if (oRect.bottom + this._eSugSuggestions.clientHeight > window.innerHeight)
                    eSugg.style.top = (oRect.top - this._eSuggestions.clientHeight) + "px";
            }
            else
                eSugg.style.display = "none";
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

            this._oSelectedSuggestion = null;
        }

        this.updateTypeVal();
        this._sSuggestPrevVal = this.getSearchValue();
        this._bSuggestVisible = false;
        this._bForceDisplay = false;
    }

    invalidateCache() {
        if (!this.pbAllData) {
            this._iPage = 0;
            this._bLastItemOnServer = false;
        }
    }

    /* 
    Enforces the display and loading of suggestions. Designed to be used from the server or as event 
    handler on psClientOnPrompt.
    
    @client-action
    */
    showSuggestions() {
        this._bForceDisplay = true;
        this.suggestDisplay();
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

        if (!this.isEnabled() || this.pbReadOnly) {
            oEvent.stop();
            return;
        }

        if (!oEvent.bCanceled) super.onKey(oEvent);
        if (!oEvent.bCanceled) {
            if (oEvent.matchKey(oKeys.escape) && this._bSuggestVisible) {
                this.suggestHide();
            } else if (oEvent.matchKey(oKeys.select)) {
                this.suggestSelect();
                oEvent.stop();
            } else if (oEvent.matchKey(oKeys.moveUp)) {
                if (!this._bSuggestVisible) this.showSuggestions();
                this.suggestMove(-1);
                oEvent.stop();
            } else if (oEvent.matchKey(oKeys.moveDown)) {
                if (!this._bSuggestVisible) this.showSuggestions();
                this.suggestMove(1);
                oEvent.stop();
            } else {
                this.invalidateCache();

                // Fixes a bug in which a first character might come up with no suggestions.
                // We need to invalidate the cache afterwards and thus re-lookup suggestions for an empty value.
                if ((oEvent.matchKey(oKeys.backSpace) || oEvent.matchKey(oKeys.delete)) && this.getSearchValue().length <= 1) {
                    this.suggestLoad();
                }
            }

            //  Make sure force display doesn't change value
            if (oEvent.matchKey(oKeys.forceDisplay)) {
                oEvent.stop();
            }
        }
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
                if (that._bSuggestVisible) that.suggestPosition();
                that._tRepos = null;
            }, 40);
        }

        if (this._bSuggestVisible) this.suggestPosition();
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

            if (that.afterBlur) that.afterBlur();
        }, 500);
    }

    onPromptClick(oEvent) {
        if (this.isEnabled() && !this.pbReadOnly) {
            //  Tell webapp object that we have the focus but do not give ourselve the actual focus (prevent Mobile Keyboard flashing)
            this.objFocus();

            // Former suggestionsform behaviour don't behave like a combo.
            if (this.firePrompt()) {
                oEvent.stopPropagation();
            } else {
                //  If the prompt button doesn't do anything we still need to give ourself the real focus
                this.focus();

                if (!this._bSuggestVisible)
                    this.showSuggestions();
                else
                    this.suggestHide();
            }
        }
    }

}