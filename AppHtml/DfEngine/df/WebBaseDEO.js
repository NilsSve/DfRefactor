import { WebBaseControl } from './WebBaseControl.js';

/*
Class:
    df.WebBaseDEO
Extends:
    df.WebBaseControl

This class is the client-side representation of the WebBaseDEO class that has most of the Data Entry 
Object logic.
    
Revision:
    2011/07/16  (HW, DAW) 
        Initial version.
*/
/* global df */

/*
This class adds most Data Entry Object logic to the inheritance tree. It contains a lot of the 
validation functionality and has support for masking & input filtering.
*/
export class WebBaseDEO extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psValue", "");
        this.prop(df.tBool, "pbChanged", false);

        this.prop(df.tInt, "peDataType", df.ciTypeText);
        this.prop(df.tInt, "piPrecision", 0);
        this.prop(df.tInt, "piMaxLength", 0);
        this.prop(df.tBool, "pbCapslock", false);
        this.prop(df.tBool, "pbRequired", false);
        this.prop(df.tBool, "pbLimitDateRange", true)

        this.prop(df.tInt, "peAlign", -1);
        this.prop(df.tString, "psMask", "");

        //  Events
        this.event("OnAutoFind", df.cCallModeDefault);
        this.event("OnChange", df.cCallModeDefault);
        this.event("OnValidate", df.cCallModeDefault);

        //@privates
        this._tValue = null;
        this._sOrigValue = "";
        this._sPrevChangeVal = null;
        this._bValueInvalid = false;    // Indicates if the field value is invalid and shouldn't be sent to the server (if true psValue returns the origional value instead of the displayed value)

        this._bMasks = true;
        this._oMask = null;

        this._bAutoFind = false;
        this._bReplaceDecSepp = false; //  Used by filterNumeric (keypress) that the decimal separator needs to be corrected by enhanceNumeric (keyup).

        this._oErrorBalloon = null;
        this._aErrors = []; //  Array of errors shown in the format { iNumber : df.tInt, sText : df.tString }





        // this.setActionMode("Request_Save", df.cCallModeWait);
        // this.setActionMode("Request_Delete", df.cCallModeWait);
        //  Always mark psValue & pbChanged as synchronized properties
        this.addSync("psValue");
        this.addSync("pbChanged");
    }

    /*
    This method is called after the control is rendered and provides an opportunity to further 
    initialize the DOM elements.
    
    @private
    */
    afterRender() {
        this._bRendering = true;

        super.afterRender();

        //  Set property value to apply them to to the DOM
        var sVal = this.psValue;
        this.set_peDataType(this.peDataType);
        this.set_psValue(sVal);
        this.set_pbCapslock(this.pbCapslock);
        this.set_peAlign(this.peAlign);
        this.set_pbRequired(this.pbRequired);

        df.dom.enableTextSelection(this._eControlWrp);

        //  Attach listener
        if (this._eControl) {
            df.dom.on("change", this._eControl, this.onChange, this);
            df.events.addDomKeyListener(this._eControl, this.onKey, this);

            df.dom.enableTextSelection(this._eControl);
        }

        this.updateErrorDisp();
        this._bRendering = false;
    }

    /* 
    Augment destroy to destroy the error balloon that might have been created.
    
    @private
    */
    destroy() {
        if (this._oErrorBalloon) {
            this._oErrorBalloon.destroy();
            this._oErrorBalloon = null;
        }
        if (this._oMask) {
            this._oMask.detach();
            this._oMask = null;
        }

        super.destroy();
    }

    /*
    This method is called to attach the focus event handlers. These can be attached differently for the 
    different controls. For data entry objects they are attached pretty straight forward to the control 
    element.
    
    @private
    */
    attachFocusEvents() {
        //  We use a simpler focus detection on the control
        if (this._eControl) {
            df.dom.on("focus", this._eControl, this.onFocus, this);
            df.dom.on("blur", this._eControl, this.onBlur, this);
        }
    }

    /* 
    Augments applyEnabled to set the disabled and tabindex attributes of the control element.
    
    @param  bVal    The enabled state.
    */
    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eControl) {
            this._eControl.disabled = !bVal;
            df.dom.setTabIndex(this._eControl, (bVal ? 0 : -1));
        }
    }


    // - - - - - - Server API - - - - - -

    /*
    This getter determines the changed state. It will first look at the pbChanged property (which can be 
    set to true by user interface events). If pbChanged was false it will also compare the original 
    value with current value.
    */
    get_pbChanged() {
        if (!this.pbChanged && this._eElem) {
            this.updateTypeVal();
        }

        return this.pbChanged || this._sOrigValue !== this.getServerVal();
    }

    /*
    This setter updates the current value of the component. It will first update the internal typed 
    values and then update the displayed value according to the proper masking rules.
    
    @param  sVal    The new value.
    */
    set_psValue(sVal) {
        // this._sOrigValue = sVal;

        //  Set the type specific value
        this._tValue = df.sys.data.serverToType(sVal, this.peDataType);
        this.psValue = sVal;

        // this.tValue = toTypeVal(sVal);
        this._sPrevChangeVal = this._sOrigValue = this.getServerVal();

        //  Update the displayed value
        this.refreshDisplay(this._tValue);

        //  If a new value is set we assume that errors don't apply any more
        if (!this._bRendering) {
            this.hideAllControlErrors();
        }
    }

    /*
    This getter returns the current value in the 'server format'. First it updates the current value 
    according to the current value inside the control then it gets it in the 'server format' using the 
    getServerVal method.
    */
    get_psValue() {
        //  Update the type specific value from the DOM
        if (this._eElem) {
            this.updateTypeVal();
        }

        //  Return the 'server' value
        if (this._bValueInvalid) {
            return this._sOrigValue;
        }

        return this.getServerVal();
    }

    /*
    This setter changes the data type. It will attach the event handlers for the input filters and apply 
    the CSS class for the markup of the type.
    
    @param  iVal    The new value.
    */
    set_peDataType(iVal, bSvr) {
        let sValue;

        if (this._eControl) {

            //  Preserve value & changed-state
            if (bSvr) {
                sValue = this.get_psValue();
            }
            // this.pbChanged = this.get_pbChanged();

            //  Make sure the new data type is properly applied
            this.peDataType = iVal;
            this.initMask();

            //  Update the displayed value with the new data type
            if (bSvr) {
                this.set_psValue(sValue);
            }

            //  Set CSS class based on data type
            df.dom.removeClass(this._eControl, "dfData_BCD dfData_Date dfDate_Text");
            if (iVal === df.ciTypeBCD) {
                df.dom.addClass(this._eControl, "dfData_BCD");
            } else if (iVal === df.ciTypeDate) {
                df.dom.addClass(this._eControl, "dfData_Date");
            } else {
                df.dom.addClass(this._eControl, "dfData_Text");
            }
        }

    }

    /*
    This setter updates the used mask. It makes sure that the new mask is properly initialized and tries 
    to keep the value correct by calling updateTypeVal and refreshDisplay before and after the change.
    
    @param  sVal    The new mask.
    */
    set_psMask(sVal) {
        //  Make sure the current value is correct using the 'old mask'
        this.updateTypeVal();
        this.psMask = sVal;
        this.initMask();

        //  Update the displayed value with the new mask
        this.refreshDisplay(this._tValue);
    }

    set_pbCapslock(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "Web_Uppercase", bVal);
            //        this._eControl.style.textTransform = (bVal ? "uppercase" : "");
        }
    }

    /*
    This setters adds css styling to the input field if its required. Adds a red asterix to the side of the form.

    @param bVal true or false depending on if the field is required
    */
    set_pbRequired(bVal) {
        if (this._eElem) {
            df.dom.toggleClass(this._eElem, "Web_FieldRequired", bVal);
        }
    }

    set_peAlign(eVal) {
        if (this._eControl) {
            this._eControl.style.textAlign = df.sys.gui.cssTextAlign(eVal);
        }
    }

    // - - - - - - Data type logic - - - - - -

    /*
    This method updates the displayed value. It does this based on the type specific value and uses 
    typeToDisplay to markup the value.
    
    @param  tVal    The new value in the type specific format.
    @private
    */
    refreshDisplay(tVal) {

        if (this._eElem) {
            const sVal = this.typeToDisplay(tVal);
            this.setControlValue(sVal);
        }
    }

    /*
    !!! Use only for backwards compatibility !!!
    !!! Please see df.sys.data.serverToType  !!!
    
    This method determines the type specific value with a new value which is usually received from the 
    server. The value is supplied in the 'server format' and is parsed into the private type specific 
    value.
    
    @param  sVal    The new value provided in the 'server format'.
    @return The type specific value (date object or number).
    @private
    */
    serverToType(sVal) {
        return df.sys.data.serverToType(sVal, this.peDataType);
    }

    /*
    !!! Use only for backwards compatibility !!!
    !!! Please see df.sys.data.typeToDisplay  !!!
    
    This method converts a type specific value to a display value.
    
    @param  tVal    Value in type specific format (number or date object).
    @return String with the display value.
    */
    typeToDisplay(tVal) {
        return df.sys.data.typeToDisplay(tVal, this.peDataType, this.getWebApp(),
            this._bHasFocus, this.psMask, this.piPrecision);
    }

    dateFormat() {
        return this.getWebApp().psDateFormat;
    }

    dateTimeFormat() {
        return this.getWebApp().psDateTimeFormat;
    }

    timeFormat() {
        return this.getWebApp().psTimeFormat;
    }

    dateSep() {
        return this.getWebApp().psDateSeparator;
    }

    decSep() {
        return this.getWebApp().psDecimalSeparator;
    }

    thousSep() {
        return this.getWebApp().psThousandsSeparator;
    }

    timeSep() {
        return this.getWebApp().psTimeSeparator;
    }

    /*
    This method updates the value properties from the user interface. It uses the getControlValue method 
    to get the value from the user interface (usually the DOM). If a numeric or date mask is applied 
    then it doesn't update since those are not changed. The type specific properties (_nValue and 
    _dValue) are also updated.
    
    @private
    */
    updateTypeVal() {
        let sVal = this.getControlValue();

        if (this.pbCapslock) {
            sVal = sVal.toUpperCase();
        }

        this._bValueInvalid = false;

        if (this.peDataType === df.ciTypeText && this.psMask) {    //  Window mask is always read from the DOM
            //  Read the value and remove the mask characters
            this.psValue = this._tValue = this.clearWinMask(sVal);
        } else if (this._bHasFocus || !this.psMask) {      //  The value is not updated when masked value is shown (exept window mask)
            this.psValue = sVal;

            //  Parse to the typed value if needed.
            if (this.peDataType === df.ciTypeBCD) {
                this._tValue = df.sys.data.stringToNum(sVal, this.decSep(), this.thousSep());
                if (isNaN(this._tValue)) {
                    this._tValue = 0;
                }
            } else if (this.peDataType === df.ciTypeDate) {
                this._tValue = df.sys.data.stringToDate(sVal, this.dateFormat(), this.dateSep());
                this._bValueInvalid = !this.validateDateRange(this._tValue);
            } else if (this.peDataType === df.ciTypeDateTime) {
                this._tValue = df.sys.data.stringToDate(sVal, this.dateTimeFormat(), this.dateSep(), this.timeSep());
            } else if (this.peDataType === df.ciTypeTime) {
                this._tValue = df.sys.data.stringToDate(sVal, this.timeFormat(), this.dateSep(), this.timeSep());
            } else {
                this._tValue = sVal;
            }
        }
    }

    /*
    Validates if the date to fits into the DataFlex Date Type. 

    @param dDate    Date object.
    @return True if valid, false if invalid.
    */
    validateDateRange(dDate) {
        if (dDate && this.pbLimitDateRange) {
            return (dDate.getFullYear() <= 2500 && dDate.getFullYear() >= 1);
        }

        return true;
    }


    /*
    This method returns the current format as a string in the server format. It uses the type specific 
    properties (_nValue and _dValue) or psValue as the current value.
     
    @return The current value in server format.
    @private
    */
    getServerVal() {
        if (this._tValue !== null) {
            if (this.peDataType === df.ciTypeBCD) {
                return this._tValue.toString(); //df.sys.data.numToString(this._tValue, ".", this.piPrecision);
            }
            if (this.peDataType === df.ciTypeDate) {
                return (this._tValue instanceof Date && df.sys.data.dateToString(this._tValue, "yyyy/mm/dd", "-")) || "";
            }
            if (this.peDataType === df.ciTypeDateTime) {
                return (this._tValue instanceof Date && df.sys.data.dateToString(this._tValue, "yyyy/mm/ddThh:mm:ss.fff", "-", ":")) || "";
            }
            if (this.peDataType === df.ciTypeTime) {
                return (this._tValue instanceof Date && df.sys.data.dateToString(this._tValue, "hh:mm:ss", "-", ":")) || "";
            }
        }

        return this.psValue;
    }

    /*
    This method reads the current value from the user interface. It will be overridden by the different 
    type of Data Entry Objects. The default implementation reads the value property of the control DOM 
    element.
     
    @return The currently displayed value.
    @private
    */
    getControlValue() {
        if (this._eControl) {
            return this._eControl.value;
        }

        return this.psValue;
    }

    /*
    This method sets a value to the user interface. It will be overridden by the different type of Data 
    Entry Objects. The default implementation sets the value property of the control DOM element.
     
    @param  sVal    The new value to display.
    */
    setControlValue(sVal) {
        if (this._eControl && this._eControl.value !== sVal) {
            this._eControl.value = sVal;
        }
    }


    // - - - - - - Window masks - - - - - - 

    /*
    This method initializes the window mask system. It will attach the listeners (after removing them 
    first so a clean situation exists after changing from a window mask to another mask). The mask 
    characters are analyzed and an array of describing objects is created. That array is used for quick 
    access by the filterWinMask and correctWinMask method.
     
    @private
    */
    initMask() {
        if (this._bMasks && this._eControl) {
            if (this._oMask) {
                this._oMask.detach();
                this._oMask = null;
            }

            if (this.peDataType === df.ciTypeBCD) {
                this._oMask = this.genNumMask();
            } else if (this.peDataType === df.ciTypeDate || this.peDataType === df.ciTypeDateTime || this.peDataType === df.ciTypeTime) {
                //aMask = this.genDateMask(this.peDataType);
                this._oMask = this.genDateMask(this.peDataType);
            } else if (this.peDataType === df.ciTypeText && this.psMask) {
                this._oMask = this.genWinMask(this.psMask);
            }
        }
    }

    // - - - - Masking event handlers - - - -

    /*
    Windows mask handling (custom masks set via psMask).
     
    The stages:
    -   Intialization
        It gathers all details and parses the mask into the aMask array.
    -   Parsing (during key handling)
        It parses the value according to the aMask array and stores the details in that same array.
    -   Filtering (onKeyDown)
        It looks at the parsed data to determine if a keypress is allowed.
    -   Correction (onInput)
        It looks at the parsed data and adjusts the value to become legal.
     
    Some (older) browsers only support keydown and some (mobile) browser only support onInput. The 
    logic works fine with both or just one or the other.
     
    @return Object with control functions (detach, clearVal).
    */
    genWinMask(sMask) {
        const that = this, aMask = [];

        //  Fill character information array for quick access (also take in account the "\" exception) which is used only by the filterWinMask
        for (let i = 0; i < sMask.length; i++) {
            const sChar = sMask.charAt(i);

            if (sChar === "\\" && i + 1 < this.sMask.length && (sMask.charAt(i + 1) === "#" || sMask.charAt(i + 1) === "@" || sMask.charAt(i + 1) === "!" || sMask.charAt(i + 1) === "*")) {
                i++;
                aMask.push({ bEnter: false, bNumeric: false, bAlpha: false, bPunct: false, sChar: sMask.charAt(i + 1) });
            } else {
                aMask.push({
                    bEnter: (sChar === "#" || sChar === "@" || sChar === "!" || sChar === "*"),
                    bNumeric: (sChar === "#" || sChar === "*"),
                    bAlpha: (sChar === "@" || sChar === "*"),
                    bPunct: (sChar === "!" || sChar === "*"),
                    sChar: sChar
                });
            }
        }

        /*
        Adds/skips mask characters if the caret is located before them. It cancels 
        characters that are not allowed at that position.
        */
        function filterWinMask(oEv) {
            let iPos, iNewPos, sValue;

            if (oEv.isKeyPrintable()) {
                const sOrig = sValue = this._eControl.value;
                const oSel = df.dom.getSelection(this._eControl);
                iPos = oSel.start;
                const sChar = oEv.key();

                //  Emulate how the value will look when the selection is replaced
                if (oSel.length > 0) {
                    sValue = sValue.substr(0, oSel.start) + sValue.substr(oSel.end);
                }

                //  Skip no enter characters (add them if they aren't already there)
                iNewPos = iPos;
                while (iNewPos < aMask.length && !aMask[iNewPos].bEnter) {
                    if (sValue.length <= iNewPos) {
                        sValue = sValue + aMask[iNewPos].sChar;
                    }
                    iNewPos++;
                }

                if (sValue !== sOrig) {
                    this._eControl.value = sValue;
                }

                //  Set the new caret position if it is moved
                if (iPos !== iNewPos && iNewPos < aMask.length) {
                    df.dom.setCaretPosition(this._eControl, iNewPos);
                    iPos = iNewPos;
                }

                //  Check if character allowed by mask
                if (iPos >= aMask.length || !df.sys.data.acceptWinMaskChar(sChar, aMask[iPos].sChar)) {
                    oEv.stop();
                }
            }
        }
        df.dom.on("keydown", this._eControl, filterWinMask, this);

        /*
        Corrects the value according to the mask. It tries to preserve the caret 
        position and only updates if the value needs to.
        */
        function correctWinMask(oEv) {
            let iMaskPos = 0, sNew = "", iAdded = 0;
            const sOrig = this._eControl.value;

            //  Loop over 
            for (let iPos = 0; iPos < sOrig.length && iMaskPos < aMask.length; iPos++) {
                const sChar = sOrig.charAt(iPos);

                if (aMask[iMaskPos].bEnter) {
                    if (df.sys.data.acceptWinMaskChar(sChar, aMask[iMaskPos].sChar)) {
                        sNew += sChar;
                        iMaskPos++;
                    }
                } else {
                    sNew += aMask[iMaskPos].sChar;
                    iMaskPos++;
                }
            }

            if (oEv.inputIsInsert()) {
                while (iMaskPos < aMask.length && !aMask[iMaskPos].bEnter) {
                    sNew += aMask[iMaskPos].sChar;
                    iMaskPos++;
                    iAdded++;
                }
            }
            //  If the correct value is different than the current value update the value (and try to preserve the caret position)
            if (sNew !== this._eControl.value) {
                const iPos = df.dom.getCaretPosition(this._eControl);
                this._eControl.value = sNew;
                df.dom.setCaretPosition(this._eControl, iPos + iAdded);
            }
        }
        df.dom.on("input", this._eControl, correctWinMask, this);

        return {
            clearVal(sVal) {
                let i = 0, sResult = "";

                while (i < sVal.length && i < aMask.length) {
                    if (aMask[i].bEnter || sVal.charAt(i) !== aMask[i].sChar) {
                        sResult += sVal.charAt(i);
                    }

                    i++;
                }

                return sResult;
            },
            detach() {
                if (that._eControl) {
                    df.dom.off("keydown", that._eControl, filterWinMask, that);
                    df.dom.off("input", that._eControl, correctWinMask, that);
                }
            }
        }
    }


    /*
    Clears the windows mask from the value by removing the mask characters. If the
    value doesn't match the mask the value might be returned incomplete.
     
    @param  sVal  Value to apply the mask on.
    @return Clean value to store in the database.
     
    @private
    */
    clearWinMask(sVal) {
        if (this._oMask) {
            return this._oMask.clearVal(sVal);
        }
        return sVal;
    }

    /*
    Date masking logic which includes date, datetime and time masking.
     
    The stages:
    -   Intialization (when field receives focus)
        It gathers all details and parses the format into the aFormat array.
    -   Parsing (during key handling)
        It parses the value according to the aFormat array and stores the details in that same array.
    -   Filtering (onKeyDown)
        It looks at the parsed data to determine if a keypress is allowed.
    -   Correction (onInput)
        It looks at the parsed data and adjusts the value to become legal.
     
    Some (older) browsers only support keydown and some (mobile) browser only support onInput. The 
    logic works fine with both or just one or the other.
     
    @return Object with control functions (detach).
    */
    genDateMask(eDataType) {
        let aFormat, regex = null;
        const that = this;

        //  Gather data and parse the mask into format and regex
        function updateFormat() {
            let sFormat;

            if (eDataType === df.ciTypeDateTime) {
                sFormat = this.dateTimeFormat();
            } else if (eDataType === df.ciTypeTime) {
                sFormat = this.timeFormat();
            } else {
                sFormat = this.dateFormat();
            }
            const sDateSepp = this.dateSep();
            const sTimeSepp = this.timeSep();

            // Split format and value into blocks
            const asFormat = sFormat.match(/([^mdyhsf]+)|([mdyhsf]+)/gi) || [];

            let sRegex = "";
            aFormat = [];
            asFormat.forEach(function (sPart) {
                let oNew = { oNext: null, bVal: true };
                switch (sPart.toLowerCase()) {
                    case "yyyy":
                        oNew.iMax = 4;
                        sRegex += "(\\d{1,4})?";
                        break;
                    case "dd":
                    case "mm":
                    case "yy":
                    case "hh":
                    case "ss":
                        oNew.iMax = 2;
                        sRegex += "(\\d{1,2})?";
                        break;
                    case "fff":
                        oNew.iMax = 3;
                        sRegex += "(\\d{1,3})?";
                        break;
                    default:
                        oNew.bVal = false;
                        oNew.sText = sPart.replace("/", sDateSepp).replace(":", sTimeSepp);
                        oNew.iMax = oNew.sText.length;
                        sRegex += "(\\D{1" + (oNew.iMax > 1 ? "," + oNew.iMax : "") + "})?";
                }
                if (aFormat.length) {
                    aFormat[aFormat.length - 1].oNext = oNew;
                }
                aFormat.push(oNew)
            });

            regex = new RegExp(sRegex, "");
        }
        updateFormat.call(this);

        df.dom.on("focus", this._eControl, updateFormat, this);

        //  Parses value according to aFormat, storing details in aFormat as well
        function parseValue(sValue) {
            const match = regex.exec(sValue);
            // console.log(match);
            let iOffset = 0;
            let bDirty = false;

            aFormat.forEach(function (oPart, iIndex) {
                oPart.iStart = iOffset;
                oPart.sVal = match[iIndex + 1] || "";
                if (oPart.sVal) {
                    iOffset += oPart.sVal.length;
                    oPart.bFound = true;
                } else {
                    bDirty = true;
                    oPart.bFound = false;
                }
                oPart.bDirty = bDirty;
                oPart.iEnd = iOffset;
                oPart.bAdd = false;
            });


            // console.log(aFormat);
            // console.log(`Result dec=${iDecimals} dirty=${bDirty} separators=${iSeparators}.`);
        }


        //  Filter key events (keydown)
        function filterDate(oEv) {
            if (oEv.isKeyPrintable()) {
                //  Gather details
                let bAllow = false, iMoveCarret = 0;
                const sChar = oEv.key();
                const oSel = df.dom.getSelection(this._eControl);
                const iCarret = oSel.start;
                const bNum = (("0123456789").indexOf(sChar) !== -1);
                let sValue = this._eControl.value;

                //  Emulate how the value will look when the selection is replaced
                if (oSel.length > 0) {
                    sValue = sValue.substr(0, oSel.start) + sValue.substr(oSel.end);
                }

                const bAppend = iCarret == sValue.length;

                parseValue(sValue);

                //  Find carret pos part
                let oCP = aFormat[0];
                while (oCP.oNext && oCP.iEnd < iCarret) {
                    oCP = oCP.oNext;
                }

                //console.log(oCP);

                if (bAppend) {
                    if (bNum) {
                        if (oCP.bVal && oCP.sVal.length < oCP.iMax) {     //  check for space in current value
                            bAllow = true;
                        } else {                                          //  move to next value  (if possible)
                            oCP = oCP.oNext;
                            while (oCP && !oCP.bVal) {
                                oCP.bAdd = !oCP.bFound;
                                oCP = oCP.oNext;
                            }
                            bAllow = oCP && oCP.bVal;
                        }
                    } else {
                        if (oCP.bVal && oCP.sVal.length > 0 && oCP.oNext) {       //  validate current value
                            oCP = oCP.oNext;                                    //  see if next separator matches
                            if (!oCP.bVal && oCP.sText.charAt(0) == sChar) {
                                bAllow = true;
                            }
                        }
                    }
                } else {
                    if (bNum) {
                        if (oCP.bVal) {
                            if (oCP.sVal.length < oCP.iMax) {
                                bAllow = true;
                            }
                        } else if (oCP.iEnd == iCarret && oCP.oNext) {
                            oCP = oCP.oNext;
                            bAllow = (oCP.bVal && oCP.sVal.length < oCP.iMax);
                        } else if (oCP.bDirty) {
                            bAllow = true;
                        }
                    } else {  //  Inserting non numeric
                        if (oCP.bVal) { // We are inside a value
                            //  That value is valid
                            if (oCP.sVal.length > 0 && iCarret - oCP.iStart > 0 && iCarret - oCP.iStart <= oCP.iMax && oCP.oNext) {
                                oCP = oCP.oNext;
                                if (!oCP.bVal && oCP.sText.charAt(0) == sChar) {
                                    if (!oCP.bFound) {
                                        bAllow = true;
                                    } else {
                                        let oNext = oCP.oNext;
                                        while (oNext) {
                                            if (!oNext.bVal && !oNext.bFound && oNext.sText == oCP.sText) {
                                                bAllow = true;
                                            }
                                            oNext = oNext.oNext;
                                        }
                                    }

                                }
                            }
                        }

                    }
                }

                if (aFormat.reduce(function (bVal, oPart) { return bVal || oPart.bAdd; }, false)) {
                    let sNewVal = "";
                    aFormat.forEach(function (oPart) {
                        if (oPart.bVal) {
                            sNewVal += oPart.sVal;
                        } else if (oPart.bFound || oPart.bAdd) {
                            sNewVal += oPart.sText;
                            iMoveCarret += oPart.sText.length - oPart.sVal.length;
                        }
                    })
                    this._eControl.value = sNewVal;
                }

                if (iMoveCarret) {
                    df.dom.setCaretPosition(this._eControl, iCarret + iMoveCarret);
                }

                if (!bAllow) {
                    oEv.stop();
                }
            }
        }
        df.dom.on("keydown", this._eControl, filterDate, this);

        //  Correct value after input (onInput)
        function correctDate(oEv) {
            //  Gather details

            if (oEv.inputIsInsert()) {


                let iMoveCarret = 0;
                const oSel = df.dom.getSelection(this._eControl);
                const iCarret = oSel.start;
                const sValue = this._eControl.value;

                parseValue(sValue);

                let sNewVal = "";
                aFormat.forEach(function (oPart) {
                    if (oPart.bVal) {
                        sNewVal += oPart.sVal;
                    } else if (oPart.bFound || (oPart.oNext && oPart.oNext.bFound)) {
                        sNewVal += oPart.sText;
                        iMoveCarret += oPart.sText.length - oPart.sVal.length;
                    }
                });

                if (sNewVal !== sValue) {
                    this._eControl.value = sNewVal;
                    //console.log(`correctDate update '${sValue}' => '${sNewVal}' :${iCarret} += ${iMoveCarret} `);

                    df.dom.setCaretPosition(this._eControl, iCarret + iMoveCarret);
                }
            }
        }
        df.dom.on("input", this._eControl, correctDate, this);

        return {
            detach() {
                if (that._eControl) {
                    df.dom.off("keydown", that._eControl, filterDate, that);
                    df.dom.off("input", that._eControl, correctDate, that);
                    df.dom.off("focus", that._eControl, updateFormat, that);
                }
            }
        }
    }

    /*
    Numeric masking logic.
     
    The stages:
    -   Intialization (when field receives focus)
        It gathers all details.
    -   Parsing (during key handling)
        It parses the value into separate variables (bNegative, sNum, bSeparator, sDecimals)
    -   Filtering (onKeyDown)
        It looks at the parsed data to determine if a keypress is allowed.
    -   Correction (onInput)
        It looks at the parsed data and adjusts the value to become legal.
     
    Some (older) browsers only support keydown and some (mobile) browser only support onInput. The 
    logic works fine with both or just one or the other.
     
    @return Object with control functions (detach).
    */
    genNumMask() {
        let sDecSepp, sDecSepparators, iLength, iPrecision;
        const that = this;

        //  Initialize quick access variables
        function updateFormat() {
            sDecSepp = this.decSep();
            sDecSepparators = sDecSepp + ".,"; //   Make sure that , and . are always accepted as decimal character
            iPrecision = this.piPrecision;
            iLength = this.piMaxLength - this.piPrecision;
        }
        updateFormat.call(this);
        df.dom.on("focus", this._eControl, updateFormat, this);

        //  Parsed values
        let bNegative, sNum, bHasDecSep, iDecSepOffset, sDec;

        function parseValue(sValue) {
            bNegative = false;
            sNum = "";
            bHasDecSep = false;
            iDecSepOffset = 0;
            sDec = "";

            for (let iOffset = 0; iOffset < sValue.length; iOffset++) {
                const sChar = sValue.charAt(iOffset);
                const bNum = (("0123456789").indexOf(sChar) !== -1);

                if (bNum) {
                    if (!bHasDecSep && sNum.length < iLength) {
                        sNum += sChar
                    } else if (iPrecision > 0 && sDec.length < iPrecision) {  //  Deliberately keep decimals without separator so that it won't correct a missing separator (which would prevent moving them)
                        sDec += sChar;
                    }
                } else if (sChar == "-") {
                    bNegative = true;
                } else if (sDecSepparators.indexOf(sChar) != -1) {
                    if (iPrecision > 0) {
                        bHasDecSep = true;
                        iDecSepOffset = iOffset
                    }
                }
            }
        }

        //  Filters key input (keydown)
        function filterNumeric(oEv) {
            if (oEv.isKeyPrintable()) {
                //  Gather details
                let bAllow = false, bAdjust = false, iMoveCarret = 0;
                const sChar = oEv.key();
                const oSel = df.dom.getSelection(this._eControl);
                const iCarret = oSel.start;
                const bNum = (("0123456789").indexOf(sChar) !== -1);
                const sOrig = this._eControl.value;
                let sValue = sOrig;

                //  Emulate how the value will look when the selection is replaced
                if (oSel.length > 0) {
                    sValue = sValue.substr(0, oSel.start) + sValue.substr(oSel.end);
                }

                const bAppend = iCarret == sValue.length;

                parseValue(sValue);

                if (bNum) {
                    if (!bHasDecSep || iCarret <= iDecSepOffset) {
                        if (sNum.length < iLength) {
                            if (bNegative && iCarret == 0) {
                                iMoveCarret += 1;
                            }
                            bAllow = true;
                        } else if (bAppend && !bHasDecSep && iPrecision > 0) {
                            bHasDecSep = true;
                            bAdjust = true;
                            iMoveCarret += 1;
                            bAllow = true;
                        }
                    } else {
                        if (sDec.length < iPrecision) {
                            bAllow = true;
                        }
                    }
                } else if (sChar == "-") {
                    if (iCarret == 0) {
                        if (!bNegative) {
                            bAllow = true;
                        } else {
                            iMoveCarret += 1;
                        }
                    }
                } else if (sDecSepparators.indexOf(sChar) != -1) {
                    if (!bHasDecSep && iPrecision > 0) {
                        bAllow = true;
                    }
                }

                if (bAdjust) {
                    sValue = (bNegative ? "-" : "") + sNum + (bHasDecSep ? sDecSepp : "") + sDec;
                    if (sOrig != sValue) {
                        this._eControl.value = sValue;
                    }
                }

                if (iMoveCarret || bAdjust) {
                    df.dom.setCaretPosition(this._eControl, iCarret + iMoveCarret);
                }

                if (!bAllow) {
                    oEv.stop();
                }
            }
        }
        df.dom.on("keydown", this._eControl, filterNumeric, this);

        //  Corrects value after input (onInput)
        function correctNumeric(oEv) {
            //  Gather details
            const oSel = df.dom.getSelection(this._eControl);
            const iCarret = oSel.start;
            const sValue = this._eControl.value;

            //  Parse
            parseValue(sValue);

            //  Reassemble
            let sNewVal = (bNegative ? "-" : "") + sNum + (bHasDecSep ? sDecSepp : "") + sDec;

            if (sNewVal !== sValue) {
                this._eControl.value = sNewVal;
                // console.log("correctNumeric update '" + sValue + "' => '" + sNewVal + "+' :" + iCarret + "");
                df.dom.setCaretPosition(this._eControl, iCarret);
            }
        }
        df.dom.on("input", this._eControl, correctNumeric, this);

        return {
            detach() {
                if (that._eControl) {
                    df.dom.off("keydown", that._eControl, filterNumeric, that);
                    df.dom.off("input", that._eControl, correctNumeric, that);
                    df.dom.off("focus", that._eControl, updateFormat, that);
                }
            }
        }
    }


    /*
    This method performs the validations that are needed. It performs some client-side validations and \
    will trigger the server-side validation by firing the OnValidate event.
     
    @return True if no validation errors occurred. Note that server-side validatione errors are 
                triggered later.
    */
    validate() {
        let bResult = true, sVal;

        if (this.pbRequired) {
            sVal = this.get_psValue();

            if ((this.peDataType === df.ciTypeBCD && parseFloat(sVal) === 0.0) || sVal === "") {
                bResult = false;
                this.showControlError(13, this.getWebApp().getTrans("err_entry_required"));
            } else {
                this.hideControlError(13);
            }
        }

        if (this.peDataType === df.ciTypeDate) {
            this.updateTypeVal();
            if (!this.validateDateRange(this._tValue)) {
                bResult = false;
                this.showControlError(16, this.getWebApp().getTrans("err_enter_valid_date"));
            } else {
                this.hideControlError(16);
            }
        }


        if (bResult) {
            //  Make sure that OnChange is fired before OnValidate
            this.fireChange();
            this.fireAutoFind();

            this.fire("OnValidate", [], function (oEvent) {
                if (oEvent.bServer) {
                    //  If handled on the server this means ASynchronous so we have to put the focus back manually if a problem occurred
                    if (oEvent.sReturnValue === "0") {
                        if (this.selectAndFocus) {
                            this.selectAndFocus();
                        } else {
                            this.focus();
                        }
                    } else {
                        this.hideAllControlErrors();
                    }
                } else {
                    //  If handled on the client we can make bResult false if event stopped to cancel moving out of the field
                    if (oEvent.bCanceled) {
                        bResult = false;
                    }
                }
            });
        }

        return bResult;
    }


    // - - - - - - Event handling - - - - - -

    /*
    This method handles the onKey event and performs the various actions like finds, saves & deletes. It 
    also initiates the validations when tabbing out of the field.
     
    @param oEvent   The event object.
    */
    onKey(oEvent) {
        if (oEvent.matchKey(df.settings.formKeys.tabOut)) {
            if (!this.validate()) {
                oEvent.stop();
            }
        }
    }

    /*
    Augments the onFocus event listener and calls the refreshDisplay method after forwarding the onFocus 
    event. This will make sure that the value will be displayed in the proper edit format.
     
    @param  oEvent   Event object.
    @private
    */
    updateFocus(bFocus) {
        super.updateFocus(bFocus);

        if (!bFocus) {
            this.updateTypeVal();

            this.fireAutoFind();
        }

        this.refreshDisplay(this._tValue);
    }

    /*
    This method checks if the value is changed and if so it will trigger the OnChange event.
    */
    fireChange() {
        //  Check the new value
        this.updateTypeVal();
        const sNewVal = this.getServerVal();

        //  Only fire events if it changed
        if (this._sPrevChangeVal !== sNewVal) {
            this.pbChanged = true;

            //  Remember the value
            const sOldVal = this._sPrevChangeVal;
            this._sPrevChangeVal = sNewVal;
            
            //  Fire events (OnSelectedChange on every radio and OnSelect on the selected one)
            this.fire('OnChange', [sNewVal, sOldVal]);

            this._bAutoFind = true;

        }
    }

    /*
    This method fires the autofind event when needed. The fireChanged method updates a Boolean when the 
    value is changed telling us that we need to do an autofind. We reset the Boolean so that we don't do 
    an autofind too often. The autofind is called from the blur event and the validation method because 
    it should fire on the blur but before OnValidate.
    */
    fireAutoFind() {
        if (this._bAutoFind) {
            //  Fire autofind event
            this.fire('OnAutoFind');

            this._bAutoFind = false;
        }
    }

    /*
    Augments the onBlur event and calls the updateTypeVal to update the value properties before 
    forwarding the onBlur. The refreshDisplay method is called after the onBlur to display the properly 
    masked value.
     
    @param  oEvent   Event object.
    @private
    */
    onChange(oEvent) {
        this.fireChange();
    }

    // - - - - - - Error handling - - - - - -

    /* 
    Displays an error in a info balloon next to the control. As multiple errors can be active at the 
    same time an array of errors is maintained and updated. Will also apply the WebError class to the 
    control.
     
    @param  iErrNum     Error ID.
    @param  sErrText    Error description / text.
    @client-action
    */
    showControlError(iErrNum, sErrText) {

        iErrNum = parseInt(iErrNum, 10);

        for (let i = 0; i < this._aErrors.length; i++) {
            if (this._aErrors[i].iNumber === iErrNum) {
                this._aErrors[i].sText = sErrText;
                this.updateErrorDisp();
                return;
            }
        }

        this._aErrors.push({
            iNumber: iErrNum,
            sText: sErrText
        });

        this.updateErrorDisp();
    }

    /* 
    Hides a specific error displayed using showControlError. Removes the error from the administration 
    and updates the display.
     
    @param  iErrNum   Error ID.
    @client-action
    */
    hideControlError(iErrNum) {

        iErrNum = df.toInt(iErrNum);

        for (let i = 0; i < this._aErrors.length; i++) {
            if (this._aErrors[i].iNumber === iErrNum) {
                this._aErrors.splice(i, 1);

                this.updateErrorDisp();
                break;
            }
        }
    }

    /* 
    Hides all errors by clearing the administration and hiding the error balloon.
     
    @client-action
    */
    hideAllControlErrors() {
        this._aErrors = [];
        this.updateErrorDisp();
    }

    /* 
    Updates the error display according to the _aErrors administration. Will show / hide the info 
    balloon and add / remove the "WebError" CSS class.
     
    @private
    */
    updateErrorDisp() {
        const aHtml = [];

        if (this._aErrors.length > 0) {
            this.makeVisible();

            //  Generate errors html
            for (let i = 0; i < this._aErrors.length; i++) {
                if (i > 0) {
                    aHtml.push('<br>');
                }
                aHtml.push(this._aErrors[i].sText);
            }

            //  Create tooltip if needed
            if (!this._oErrorBalloon) {
                this._oErrorBalloon = new df.InfoBalloon(this, "WebErrorTooltip", aHtml.join(''));
            } else {
                //  Update & show tooltip
                this._oErrorBalloon.psMessage = aHtml.join('');
                this._oErrorBalloon.update();
            }
            this._oErrorBalloon.show();


            if (this.getErrorElem()) {
                df.dom.addClass(this.getErrorElem(), "WebError");
            }

            this.focus();
        } else {
            //  Hide tooltip if needed
            if (this._oErrorBalloon) {
                this._oErrorBalloon.hide();

                df.dom.removeClass(this.getErrorElem(), "WebError");
            }
        }
    }

    /* 
    Used by the showControlError logic to determine on which element the "WebError" class needs to be 
    applied. Can be overridden by sub-classes.
     
    @private
    */
    getErrorElem() {
        return this._eElem;
    }

    /* 
    Augment the resize method to make sure that the error balloon is resized / repositioned when needed.
     
    @private
    */
    resize() {
        super.resize();

        if (this._oErrorBalloon) {
            this._oErrorBalloon.resize();
        }
    }

}