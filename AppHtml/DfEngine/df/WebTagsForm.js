import { WebBaseSelectionForm } from './WebBaseSelectionForm.js';
import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
import { WebBaseForm } from './WebBaseForm.js';

/*
Class:
    df.WebTagsForm
Extends:
    df.WebBaseSelectionForm

The WebTagsForm is an extension on the selection form. Able to select multiple items. Compositions can be made.

Revision:
    2020/09/25  (HW, DAW)
        Initial version.
*/
export class WebTagsForm extends WebBaseSelectionForm {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "piTagTruncateAt", 60);
        this.prop(df.tBool, "pbTagOnSpace", false);
        this.prop(df.tBool, "pbAllowTagSelection", true);
        this.prop(df.tString, "psSeparator", ",");

        this.event("OnTagClick", df.cCallModeDefault, "privateOnTagClick");
        this.event("OnAddTag", df.cCallModeDefault, "privateOnAddTag");
        this.event("OnRemoveTag", df.cCallModeDefault, "privateOnRemoveTag");

        this._aSelectedSuggestions = [];
        this._sSelectedTag = null;
        this._oSelectedTag = null;
        this._aTagCssClass = {};
    }

    openHtml(aHtml) {
        WebBaseForm.prototype.openHtml.call(this, aHtml);

        aHtml.push('<div class="WebFrm_Wrapper"><div class="WebFrm_PromptSpacer">',
            '<span class="WebDynFrm WebTgf_Placeholder">',
            (this.peLabelPosition != df.ciLabelFloat ? df.dom.encodeAttr(df.dom.encodeHtml(this.psPlaceHolder)) : ''),
            '</span>',
            '<span class="WebDynFrm WebTgfInput" name="',
            this._sName,
            '" id="',
            this._sControlId,
            '" role="textbox" tabindex="0"',
            ' contenteditable="true"></span>');
    }

    closeHtml(aHtml) {
        aHtml.push('</div><span class="WebFrm_Prompt"></span></div>');

        WebBaseForm.prototype.closeHtml.call(this, aHtml);
    }

    setPlaceHolderVisibility(bVisible) {
        this.setVisibility(this._ePlaceHolder, bVisible);
    }

    setInputVisibility(bVisible) {
        this.setVisibility(this._eControl, bVisible);
    }

    setVisibility(hElem, bVisible) {
        hElem.style.display = (!bVisible ? "none" : "");
    }

    getVisibility(hElem) {
        return hElem.style.display != "none";
    }

    focusInputField() {
        if (this.pbReadOnly || !this.isEnabled()) {
            return;
        }

        if (this._aSelectedSuggestions.length === 0 || this.getVisibility(this._ePlaceHolder)) {
            this.setPlaceHolderVisibility(false);
        }


        // IE Fix: reset the focus to the input field.
        const that = this;
        if (!this._tFocus) {
            this._tFocus = setTimeout(function () {
                if (!that._tFocus) return;
                that._eControl.focus();
                that._tFocus = null;
            }, 1);
        }
    }

    blurInputField() {
        this._tFocus = null;
        if ((this._eControl.value.length === 0 && this._aSelectedSuggestions.length === 0) ||
            this.getVisibility(this._ePlaceHolder)) {
            this.setPlaceHolderVisibility(true);
        }
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
        this._ePlaceHolder = df.dom.query(this._eElem, ".WebTgf_Placeholder");

        /* 
        For the WebTagsform we use a dynamic input field.
        To make this growing we use a span, we need to add a couple of properties to make it function as such.
        Using these function we pass for the BaseDEO api's.
        */
        const that = this;
        this._eControl = this._eControl = df.dom.query(this._eInputBox, ".WebTgfInput");
        Object.defineProperty(this._eControl, "value", {
            get() { return that._eControl.innerText; },
            set(val) { that._eControl.innerText = val; }
        });
        Object.defineProperty(this._eControl, "keypress", {
            get() { return that._eControl.keydown; },
            set(val) { that._eControl.keydown = val; }
        });
        this._eControl.select = function () { that._eControl.focus(); };

        df.dom.on("focusin", this._eInputBox, this.focusInputField, this);
        df.dom.on("click", this._eInputBox, this.focusInputField, this);
        df.dom.on("blur", this._eControl, this.blurInputField, this);
        this.blurInputField();

        this._ePrompt = df.dom.query(this._eElem, "div.WebFrm_Wrapper span.WebFrm_Prompt");
        this._eWrap = df.dom.query(this._eElem, "div.WebFrm_Wrapper");

        WebBaseForm.prototype.afterRender.call(this);

        //  Attach event handlers
        df.dom.on("click", this._ePrompt, this.onPromptClick, this);

        //  Set properties
        this.set_pbPromptButton(this.pbPromptButton);

        // Insert.
        df.dom.addClass(this._eElem, "WebSelectionForm");
        const eTopLayer = this.topLayer() || document.body;
        eTopLayer.appendChild(this._eSuggestions);
        // Setup event handlers.
        df.dom.on("keyup", this._eControl, this.onSuggestKey, this);
        df.dom.on("click", this._eSuggestions, this.onSuggestClick, this);
        df.dom.on("click", this._eInputBox, this.inputBoxOnClick, this);
        df.dom.on("resize", window, this.onWindowResize, this);

        df.dom.addClass(this._eElem, "WebTagsForm");

        // If the values are pre-set implement them now.
        if (this.aSelectionCache) this.setCachedTags();

        df.dom.on("click", this._eInputBox, this.removeTagSelection, this);

        this.set_pbReadOnly(this.pbReadOnly);
        this.set_pbEnabled(this.isEnabled());

        this.validateAsSeparator(this.psSeparator);

        this.dragDropInit();
    }

    set_pbEnabled(bVal) {
        let bChanged = bVal !== this.isEnabled();
        super.set_pbEnabled(bVal);
        if (bChanged) this.setControlValue(this.getControlValue());
    }

    validateAsSeparator(sVal) {
        if (sVal.length !== 1) {
            throw new df.Error(871, "Invalid psSeparator; requires length of just one character.");
        }
        return true;
    }

    set_psSeparator(sVal) {
        if (sVal !== this.psSeparator && this.validateAsSeparator(sVal)) {
            this.psSeparator = sVal;
        }
    }

    set_pbReadOnly(bVal) {
        let bChanged = bVal !== this.pbReadOnly;
        super.set_pbReadOnly(bVal);
        if (bChanged) this.setControlValue(this.getControlValue());
    }

    removeTagSelection() {
        if (this._sSelectedTag && this._oSelectedTag) {
            df.dom.removeClass(this._oSelectedTag, "WebTgf_Focus");
        }
        this._sSelectedTag = null;
        this._oSelectedTag = null;
    }

    setTagSelection(tRow) {
        this.removeTagSelection();
        this._sSelectedTag = tRow;
        this._oSelectedTag = df.dom.query(this._eInputBox, ".WebTgf_Tag[data-dfrowid='" + this._sSelectedTag.aValues[0].replaceAll("'", "\\'") + "']");
        df.dom.addClass(this._oSelectedTag, "WebTgf_Focus");
    }

    /*
    Get the value from the inputfield.
    */
    getSearchValue() {
        let sValue = this._eControl.value;
        return (this.pbCapslock ? sValue.toUpperCase() : sValue);
    }

    /*
    Called by the baseDEO, it serializes the selected tag datasets.

    @private
    */
    getControlValue() {
        let aData = [];
        let sEscapedSeperator = "\\" + this.psSeparator;

        for (let i = 0; i < this._aSelectedSuggestions.length; i++) {
            if (!this._aSelectedSuggestions[i].control) {
                aData.push(this._aSelectedSuggestions[i].aValues[0].replaceAll(this.psSeparator, sEscapedSeperator));
            }
        }
        return aData.join(this.psSeparator);
    }

    parseSelectionValues(sList) {
        let aList = [];

        /*
        iIndex = The found end index of a string; which is an operator thus +1.
        iLastIndex = The last found iIndex.
        iBegin = The last begin of a string; commonly iIndex+1.
        */
        let iIndex = -1, iLastIndex = -1, iBegin = 0;
        while ((iIndex = sList.indexOf(this.psSeparator, iLastIndex + 1)) >= 0) {
            let bEven = true;
            let j = iIndex;
            // Check if the operator is escaped.
            while (--j >= 0 && sList.charAt(j) === '\\') {
                bEven = !bEven;
            }

            // If its even it means its not escaped.
            if (bEven) {
                let sValue = sList.substr(iBegin, iIndex - iBegin);
                sValue = sValue.replaceAll("\\" + this.psSeparator, this.psSeparator).trim();
                if (sValue.length > 0) {
                    aList.push(sValue);
                    iBegin = iIndex + 1;
                }
            }

            iLastIndex = iIndex;
        }

        // Do the last one too.
        let sValue = sList.substr(iBegin, sList.length - iBegin);
        sValue = sValue.replaceAll("\\" + this.psSeparator, this.psSeparator).trim();
        if (sValue.length > 0) aList.push(sValue);

        return aList;
    }

    /*
    Called by the baseDEO, it de-serializes the selected tag datasets and adds them one-by-one.

    @private
    */
    setControlValue(sVal) {
        this.aSelectionCache = this.parseSelectionValues(sVal);

        if (this._eInputBox) this.setCachedTags();
    }

    suggestHandle(sVal, bLast) {
        super.suggestHandle(sVal, bLast);
        if (this._aSuggestRows.length - this._aSelectedSuggestions.length < this.piPageSize && !this._bLastItemOnServer && this.pbPaged) {
            this.handleMoreButton();
        }
    }

    /*
    Intermediate event during handling of incoming lists.
    Currently adding control rows.
    */
    AddControlSuggestions(aList) {
        let iAdded = aList.length;
        let sValue = this.getSearchValue().trim();
        if (!this._bLastItemOnServer && this.pbPaged && aList.length > 0 && !this.pbAllData) aList.push({ control: true, sRowId: "more", aValues: ["(" + this.psShowMoreText + ")"], sCssClassName: "Sugg_ControlSuggestion" });
        let bShow = true;
        if (this._aShownSuggestions) bShow = !(this._aShownSuggestions.length > 0 && this._aShownSuggestions[0].aValues[0] == sValue);

        if (bShow) bShow = this.getSelectedSuggestionId(sValue) < 0;

        if (bShow && this.pbAllowCreate && sValue.length > 0) aList.push({ control: true, sRowId: "create", aValues: ["(" + this.psCreateNewItemText + (sValue.length > 0 ? " '" + sValue + "'" : "") + ")"], sCssClassName: "Sugg_ControlSuggestion" });

        return aList.length - iAdded;
    }

    afterSuggestRefine(sFilter) {
        if (this._aShownSuggestions.length - this._TotalOfControlRows - this._aSelectedSuggestions.length < this.piPageSize && !this._bLastItemOnServer && this.pbPaged) {
            this.handleMoreButton();
        }
    }

    // If a dd already a value in it the setControlValue is called before the render was completed.
    // Caching is thus required.
    setCachedTags() {
        this.clearTags();
        for (let i = 0; i < this.aSelectionCache.length; i++) {
            this.addTag({
                sRowId: i.toString(),
                aValues: [this.aSelectionCache[i]],
                sCssClassName: ""
            });
        }
        this.setPlaceHolderVisibility(this._eControl.value.length === 0 && this.aSelectionCache.length == 0);
        this.updateTypeVal();
    }

    /*
    This is a function to truncate the text in a tag. Based on spaces as well as the value itself.
    */
    truncate(sValue, iMaximumLength, bUseBoundary) {
        if (sValue.length <= iMaximumLength) return sValue;
        if (iMaximumLength == 0) return sValue;
        let subString = sValue.substr(0, iMaximumLength);
        return ((bUseBoundary && subString.lastIndexOf(" ") != -1)
            ? subString.substr(0, subString.lastIndexOf(" "))
            : subString) + "&hellip;";
    }

    /*
    Is called by the server, this puts a css classname on the value using a hashet.
    Afterwards a rerender is called thus causing the class to be applied.
    */
    setTagCssClass(sTag, sCssClass) {
        this._aTagCssClass[sTag] = " " + sCssClass.trim();
        this.updateTypeVal();
        this.refreshDisplay(this._tValue);
    }

    /*
    Selects the item by sending a call to the server with the selected suggestion details.
    */
    suggestSelect() {
        if (this._oSelectedSuggestion && !this._oSelectedSuggestion.control) {
            let tRow = this.findSuggestionByValue(this._oSelectedSuggestion.aValues[0]);
            if (tRow) {
                this.addTag(tRow);
                this.fireEx({
                    sEvent: "OnAddTag",
                    tActionData: tRow,
                    oEnv: this
                });
                this.updateTypeVal();
                this.focusInputField();
                this._eControl.value = "";
                this.suggestHide();
                return;
            }
        }
        super.suggestSelect();
        this.focusInputField();
    }

    extraFilterOnHandle(aList) {
        // Filter out all selected values.
        this._aSelectedSuggestions.forEach(function (tRow) {
            for (let i = 0; i < aList.length; i++)
                if ((aList[i].aValues[0] == tRow.aValues[0]))
                    aList.splice(i--, 1);
        });
        return aList;
    }

    /*
    Used to add a selectiontag to the view.
    
    @private
    */
    addTag(tRow) {
        // Push the tRow onto the selection stack.
        this._aSelectedSuggestions.push(tRow);
        // A SetControlValue clears the focus, re-enable it
        let bHasFocus = false;
        if (this._sSelectedTag && this.isEnabled())
            if (this._sSelectedTag.aValues[0] == tRow.aValues[0])
                bHasFocus = true;

        // Create the element.
        var tag_elem = df.dom.create(
            '<div class="WebTgf_Tag' + ((bHasFocus) ? " WebTgf_Focus" : "") + (this._aTagCssClass[tRow.aValues[0]] ? this._aTagCssClass[tRow.aValues[0]] : "") + '" data-dfrowid="' + df.dom.encodeAttr(tRow.aValues[0]) + '"' + (this.pbDragDropEnabled && this.isSupportedDragAction(df.dragActions.WebTagsForm.ciDragTag) ? ' draggable="true"' : '') + '> \
                <span class="WebTgf_Text">' + df.dom.encodeHtml(this.truncate(tRow.aValues[0], this.piTagTruncateAt, false)) + '</span>' +
            (this.isEnabled() && !this.pbReadOnly ? '<span class="WebTgf_CloseTag">x</span> ' : '') +
            '</div>'
        );

        // Insert the element into the DOM.
        let oTag = this._eInputBox.insertBefore(tag_elem, this._eControl);

        if (bHasFocus) this._oSelectedTag = tag_elem;

        df.dom.on("mousedown", oTag, function (oEvent) {
            if (window.getSelection().type == "Range") return;
            // Find valid targets either the tag itself or the close button.
            let target = oEvent.getTarget();
            while (!target.classList.contains("WebTgf_Tag") && !target.classList.contains("WebTgf_CloseTag"))
                target = target.parentNode;

            if (!this.isEnabled()) return;

            // If the close button was clicked.
            if (target.classList.contains("WebTgf_CloseTag") && !this.pbReadOnly) {
                target = target.parentNode;

                this.removeTag(target.getAttribute("data-dfrowid"));
                this.blurInputField();

                // Deselect the if a selection was made using the keyboard since the numbers won't correspond.
                this.removeTagSelection();
            } else if (target.classList.contains("WebTgf_Tag")) {
                let iIndex = this.getSelectedSuggestionId(target.getAttribute("data-dfrowid"));
                if (iIndex < 0)
                    throw new df.Error(999, "Could not refind the clicked tag.");

                // remove previous selection.
                this.removeTagSelection();

                if (this.pbAllowTagSelection) {
                    this.setTagSelection(this._aSelectedSuggestions[iIndex]);
                    this.focus();
                }

                this.fireEx({
                    sEvent: "OnTagClick",
                    tActionData: this._aSelectedSuggestions[iIndex],
                    oEnv: this
                });
            }
        }, this);

        // For suggestionmode additional items are needed +1
        if (this.pbSuggestions) this._iAdditionalItems++;

        this.sizeChanged();
    }

    /*
    Clears the webtags
    */
    clearTags() {
        const that = this;
        this._aSelectedSuggestions = [];
        if (this._eInputBox) {
            this._eInputBox.querySelectorAll(".WebTgf_Tag").forEach(function (oTag) {
                that._eInputBox.removeChild(oTag);
            });
        }
        // For suggestionmode additional items back to 0;
        this._iAdditionalItems = 0;
    }

    /*
    Given the sValue it will remove the tag from the selected list.
    @private
    */
    removeTag(sValue) {
        let oRow = df.dom.query(this._eInputBox, ".WebTgf_Tag[data-dfrowid='" + sValue.replaceAll("'", "\\'") + "']");
        if (oRow) {
            let iIndex = this.getSelectedSuggestionId(sValue);
            let tRow = this._aSelectedSuggestions[iIndex];

            this._aSelectedSuggestions.splice(iIndex, 1);
            oRow.parentNode.removeChild(oRow);
            this.updateTypeVal();
            this.fireEx({
                sEvent: "OnRemoveTag",
                tActionData: tRow,
                oEnv: this
            });

            this.sizeChanged();
        }
        if (this._bSuggestVisible) this.suggestHide();

        if (this.pbSuggestions) this._iAdditionalItems--;
        this.suggestLoad();
    }

    /*
    Find a suggestion by sValue in the selected suggestions.
    returns index.
    @private
    */
    getSelectedSuggestionId(sValue) {
        for (let i = 0; i < this._aSelectedSuggestions.length; i++) {
            if (this._aSelectedSuggestions[i].aValues[0] == sValue) {
                return i;
            }
        }
        return -1;
    }

    /* 
    Augments the key handler and implements the key operations.
     
    NOTE: The WebColumnSuggestion has its own onKey handler!
     
    additions over base: Backspace/delete, left/right arrow keys for navigation through tags.
     
    @param  oEvent  Event object (see df.events.DOMEvent).
    @private
    */
    onKey(oEvent) {
        function setCaretPosition(el, pos) {
            const range = document.createRange();
            const sel = window.getSelection();
            if (el.childNodes.length == 0) return;
            range.setStart(el.childNodes[0], pos);
            range.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range);
        }

        function getCaretPosition(editableDiv) {
            let caretPos = 0,
                range;
            if (window.getSelection) {
                const sel = window.getSelection();
                if (sel.rangeCount) {
                    range = sel.getRangeAt(0);
                    if (range.commonAncestorContainer.parentNode == editableDiv) {
                        caretPos = range.endOffset;
                    }
                }
            } else if (document.selection && document.selection.createRange) {
                range = document.selection.createRange();
                if (range.parentElement() == editableDiv) {
                    var tempEl = document.createElement("span");
                    editableDiv.insertBefore(tempEl, editableDiv.firstChild);
                    var tempRange = range.duplicate();
                    tempRange.moveToElementText(tempEl);
                    tempRange.setEndPoint("EndToEnd", range);
                    caretPos = tempRange.text.length;
                }
            }
            return caretPos;
        }

        // Check if the key is not an auto-html-entity.
        if (oEvent.e.ctrlKey) {
            switch (oEvent.e.keyCode) {
                case 66: //ctrl+B or ctrl+b
                case 98:
                case 73: //ctrl+I or ctrl+i
                case 105:
                case 85: //ctrl+U or ctrl+u
                case 117:
                    oEvent.stop();
                    return false;
            }
        }

        // Check if it is not a html beginning entity.
        if ([
            '<',
            '>',
            "'",
            '/'
        ].indexOf(oEvent.e.key) > -1) {
            oEvent.stop();
            this._eControl.value += oEvent.e.key;
            setCaretPosition(this._eControl, this._eControl.value.length);
            return;
        }

        const oKeys = df.settings.suggestionKeys;

        if (this.isEnabled() && !this.pbReadOnly)
            switch (oEvent.e.key) {
                case "Enter":
                    if (!this._bSuggestVisible) {
                        oEvent.stop();
                        return;
                    }
                    if (oEvent.e.shiftKey) this._oSelectedSuggestion = null;
                    this.suggestSelect();
                    oEvent.stop();
                    break;
                case " ":
                case "Spacebar":
                    if (!this.pbTagOnSpace || oEvent.e.ctrlKey)
                        break;
                    this.suggestSelect();
                    oEvent.stop();
                    break;
            }

        super.onKey(oEvent);

        if (!oEvent.bCanceled || this.pbReadOnly) {
            // Handle focus using keys, oEvent.stop() is called in base.
            if ((oEvent.e.key == "ArrowLeft" || oEvent.e.key == "Left") && this.pbAllowTagSelection) {
                if (this._aSelectedSuggestions.length <= 0) return;
                if (this._sSelectedTag) {
                    let i = this.getSelectedSuggestionId(this._sSelectedTag.aValues[0]);
                    this.removeTagSelection();
                    if (i > 0) i--;
                    else {
                        this.removeTagSelection();
                        this._eControl.focus();
                        setCaretPosition(this._eControl, this.getSearchValue().length);
                        oEvent.stop();
                        return;
                    }
                    this.setTagSelection(this._aSelectedSuggestions[i]);
                    oEvent.stop();
                }
                else if (getCaretPosition(this._eControl) == 0) {
                    this.setTagSelection(this._aSelectedSuggestions[this._aSelectedSuggestions.length - 1]);
                    oEvent.stop();
                }
            }
            else if ((oEvent.e.key == "ArrowRight" || oEvent.e.key == "Right") && this.pbAllowTagSelection) {
                if (this._aSelectedSuggestions.length <= 0) return;
                if (this._sSelectedTag) {
                    let i = this.getSelectedSuggestionId(this._sSelectedTag.aValues[0]);
                    this.removeTagSelection();
                    if (i >= this._aSelectedSuggestions.length - 1) {
                        this.removeTagSelection();
                        this._eControl.focus();
                        setCaretPosition(this._eControl, 0);
                        oEvent.stop();
                        return;
                    }
                    else i++;
                    this.setTagSelection(this._aSelectedSuggestions[i]);
                    oEvent.stop();
                }
                else if (getCaretPosition(this._eControl) == this.getSearchValue().length) {
                    this.setTagSelection(this._aSelectedSuggestions[0]);
                    oEvent.stop();
                }
            } else if (this.isEnabled() && !this.pbReadOnly && (oEvent.e.key == "Backspace" || oEvent.e.key == "Delete") && (this.getSearchValue().length == 0 || this._sSelectedTag) && this.pbAllowTagSelection) {
                if (this._sSelectedTag) {
                    this.removeTag(this._sSelectedTag.aValues[0]);
                    this.removeTagSelection();
                } else if (this._aSelectedSuggestions.length > 0) {
                    this.setTagSelection(this._aSelectedSuggestions[this._aSelectedSuggestions.length - 1]);
                }

                oEvent.stop();
            }
            else { // unkown key (Typing)
                this.removeTagSelection();
            }

            //  Make sure force display doesn't change value
            if (oEvent.matchKey(oKeys.forceDisplay)) {
                oEvent.stop();
            }
        }
    }

    createTag() {
        let tRow = this._tActionData;
        if (tRow.aValues[0] == -1) {
            tRow.aValues[0] = this._aSelectedSuggestions.length.toString();
        }
        if (this.getSelectedSuggestionId(tRow.aValues[0]) != -1) throw new df.Error(871, "Id already in use.");
        this.addTag(tRow);
        this.fireEx({
            sEvent: "OnAddTag",
            tActionData: tRow,
            oEnv: this
        });
        this.updateTypeVal();
        this.suggestDoLoad(this.getSearchValue());
        this.suggestHide();
    }

    afterBlur() {
        if (this._sSelectedTag) {
            const that = this;
            if (!this._tUnselectTag) {
                this._tUnselectTag = setTimeout(function () {
                    that._tUnselectTag = null;

                    if (!that._bHasFocus) {
                        df.dom.removeClass(that._oSelectedTag, "WebTgf_Focus");
                        that._sSelectedTag = null;
                        that._oSelectedTag = null;
                    }
                }, 500);
            }
        }
    }

    // WebUIContext

    determineSelectorForWebUIContext(eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextTagsFormTag:
                return ".WebTgf_Tag[data-dfrowid]";
        }
        return null;
    }

    retrieveValueFromWebUIContext(eElem, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextTagsFormTag: {
                if (!eElem.hasAttribute('data-dfrowid'))
                    break;
                return eElem.getAttribute('data-dfrowid')
            }
        }
        return null;
    }

    // === Drag & Drop ===

    getDragData(oEv, eDraggedElem) {
        try {
            let sTagText = eDraggedElem.getAttribute("data-dfrowid");
            return [{ data: sTagText }, df.dragActions.WebTagsForm.ciDragTag]
        } catch (err) {
            // This can happen if the drag action is not supported, we don't want a nasty error if so.
            console.error("Attempt to perform unsupported drag action");
            return [null, null];
        }
    }

    getDropData(oDropZone, oPosition) {
        if (oDropZone && oDropZone._eDropElem) {
            const eTextElem = (df.dom.query(oDropZone._eDropElem, '.WebTgf_Text'));
            let sTagText = '';
            if (eTextElem) {
                sTagText = eTextElem.innerText;
            }

            const dropData = {
                data: sTagText,
                action: df.dropActions.WebTagsForm.ciDropOnInput
            }

            return dropData;
        }
        return null;
    }

    initDraggableElements() {
        // Done whenever a tag is added (draggble="true" attribute in addTag html)
    }

    initDropZones() {
        this._aDropZones = [];

        super.initDropZones();

        if (this.isSupportedDropAction(df.dropActions.WebTagsForm.ciDropOnInput)) {
            // Mark input as drop zone
            const eZone = (df.dom.query(this._eElem, '.WebFrm_Wrapper'));
            this.addDropZone(eZone);
        }
    }

    determineDropCandidate(oEv, aHelpers) {
        // DropOnControl and other drop actions cannot exist within the same control simultaneously
        // It makes sense to check for this first to get it out of the way as it is the simplest check
        if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebControl.ciDropOnControl))) {
            return [this._eElem, df.dropActions.WebControl.ciDropOnControl];
        }

        // Check for DropOnInput
        if (!aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebTagsForm.ciDropOnInput))) {
            return [null, null];
        }

        const eElem = document.elementFromPoint(oEv.e.clientX, oEv.e.clientY);
        let eTag = eElem?.closest('.WebTgf_Tag');

        if (!eTag) {
            const aElems = df.dom.query(this._eElem, '.WebTgf_Tag', true);
            eTag = aElems.length > 0 && aElems[(aElems.length - 1)] || null;
        }

        if (eTag) {
            if (eTag.hasAttribute('data-dfdropplaceholder')) {
                if (eTag.previousElementSibling?.hasAttribute("data-dfrowid")) {
                    eTag = eTag.previousElementSibling;
                } else if (eTag.nextElementSibling?.hasAttribute("data-dfrowid")) {
                    eTag = eTag.nextElementSibling;
                }
            }
            if (eTag) {
                return [eTag, df.dropActions.WebTagsForm.ciDropOnInput];
            }
        }
        return [null, null];
    }

    determineDropPosition(oEv, eElem) {
        const oRect = df.sys.gui.getBoundRect(eElem);
        // We want to check if we are more to the left or to the right of the hovered tag
        const iMid = (oRect.right - (oRect.width / 2));
        if (oEv.e.clientX >= iMid) {
            return df.dropPositions.ciDropAfter;
        } else {
            return df.dropPositions.ciDropBefore;
        }
    }

    interactWithDropElem(dropZone, eElem) {
        if (dropZone._eDropAction == df.dropActions.WebControl.ciDropOnControl) {
            dropZone.highlightElement();
        } else {
            let eTempElem = document.createElement('div');
            eTempElem.innerHTML = '<span class="WebTgf_Text">DROP</span><span class="WebTgf_CloseTag">x</span> '; // ToDo: Translate?
            df.dom.addClass(eTempElem, 'WebTgf_Tag WebTgf_DropPlaceHolder');
            eTempElem.setAttribute('data-dfrowid', 'empty_placeholder');
            dropZone.insertElement(eTempElem, eElem);
        }
    }

    doEmptyInteraction(dropZone) {
        if (this.isSupportedDropAction(df.dropActions.WebTagsForm.ciDropOnInput)) {
            let eTempElem = document.createElement('div');
            eTempElem.innerHTML = '<span class="WebTgf_Text">DROP</span><span class="WebTgf_CloseTag">x</span> '; // ToDo: Translate?
            df.dom.addClass(eTempElem, 'WebTgf_Tag WebTgf_DropPlaceHolder');
            const eTargetElem = (df.dom.query(this._eElem, '.WebFrm_PromptSpacer'));
            dropZone.insertElement(eTempElem, eTargetElem);

            return df.dropActions.WebTagsForm.ciDropOnInput;
        } else if (this.isSupportedDropAction(df.dropActions.WebControl.ciDropOnControl)) {
            dropZone.highlightElement();
            return df.dropActions.WebControl.ciDropOnControl;
        }

        return null;
    }

    hasData() {
        return (this.get('psValue') != '');
    }
}