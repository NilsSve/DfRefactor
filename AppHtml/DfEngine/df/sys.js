/*
Name:
sys
Type:
    Library(object)

Revisions:
    2005/09/01  Created the initial version with a basic set of browser
    independent functions. (HW, DAE)

    2006/11/05  Restructured into dom, events, data, gui categories. (HW, DAE)

    2007/12/14  Converted into 2.0 structure. It is now called sys and the
    events functionallity is moved to a separate df.events version. (HW, DAE)

*/
/* global df */
/*
An important part of the Visual DataFlex AJAX Library is the layer that is build
between the browser and the engine. Its main goal is to straighten out the
differences between the supported browsers. It contains a lot of functionality
that cover the various parts of client side web development.
*/

import { json } from './sys/json.js';
import { vt } from './sys/vt.js';
import { gui } from './sys/gui.js';
import { dom } from './dom.js';
import { dev } from './sys/dev.js'

export const sys = {
    json : json,
    vt : vt,
    gui : gui,
    dev : dev,

    /*
    If true the browser is supposed to be safari or part of the safari family.
    */
    isSafari: dev.isSafari,
    /*
    True if the browser seems to be Google Chrome.
    */
    isChrome: dev.isChrome,
    /*
    True if the browser seems to be Opera.
    */
    isOpera: dev.isOpera,
    /*
    If true the browser is supposed to be part of the mozilla family (usually
    FireFox).
    */
    isMoz: dev.isMoz,
    /*
    True if the browser seems to be Internet Explorer. Also true if we where not
    able to detect the browser type properly (if browser unknown threat it as IE
    policy).
    */
    isIE: dev.isIE,
    /* 
    True if the browser seems to be Microsoft Edge.
    */
    isEdge: dev.isEdge,
    /*
    True if the WebKit layout engine is used (Safari & Chrome).
    */
    isWebkit: dev.isWebkit,

    isMobile: dev.isMobile,
    isIOS: dev.isIOS,

    /*
    Indicates the browser version.
    */
    iVersion: dev.iVersion,

    /*
    The reflection library contains functionality related to prototypes, objects
    and functions. Some of this functionality is closely related to the Visual DataFlex
    AJAX Library and might not work on objects from outside the library.
    */
    ref: {

        /*
        Determines the object type using "typeof" and for objects it tries to determine
        the constructorname.
        
        @param  oObject     Reference to the object of which the type should be determined.
        @return The type of the object ("object", "function", "array", "undefined", ..).
        */
        getType(oObject) {
            let sType = typeof (oObject);

            if (sType === "object") {
                if (oObject === null || oObject === undefined) {
                    sType = "null";
                } else if (oObject.constructor === Array) {
                    sType = "array";
                } else if (oObject.constructor === Date) {
                    sType = "date";
                } else {
                    sType = this.getConstructorName(oObject);
                }
            }

            return sType;
        },

        /*
        It tries to determine the name of the constructor of the object. If the
        constructor is not found "object" is returned.
        
        @param  oObject     Reference to the object of which we want to determine the
                constructor name.
        @return String with the constructorname ("object" if not found).
        */
        getConstructorName(oObject) {
            let sName = this.getMethodName(oObject.constructor);

            if (sName === "") {
                sName = "object";
            }

            return sName;
        },

        /*
        Determines the name of the given function by converting the function its string
        definition.
        
        @param  fFunction   Reference to the function.
        @return Name of the function ("unknownType" if not able to determine).
        */
        getMethodName(fFunction) {

            try {
                const sString = fFunction.toString();
                return sString.substring(sString.indexOf("function") + 8, sString.indexOf('(')).replace(/ /g, '');
            } catch (e) {
                return "";
            }
        },

        /*
        Determines the global scope object. Within browsers this usually is the window
        object.
        
        @return Reference to the global scope object.
        */
        getGlobalObj() {
            return window;
        },

        /*
        Finds the (nested) object property by a path string (like "df.core.List")
        without using an eval. Always starts at the global object.
        
        @param  sPath   Path to the property (like "df.core.List").
        @return The property (null if not found).
        */
        getNestedProp(sPath) {
            let oProp;

            //  Split into parts
            const aParts = sPath.split(".");

            //  We start our search at the global object
            oProp = this.getGlobalObj();

            //  Loop through parts and object properties
            for (let iPart = 0; iPart < aParts.length; iPart++) {
                if (typeof oProp === "object" && oProp !== null) {
                    oProp = oProp[aParts[iPart]];
                } else {
                    return null;
                }
            }

            return oProp;
        },

        /*
        Sets the (nested) object property by a path string (like "df.core.List") without using eval. Always starts at the global object.
        @param sPath    Path to the property (like "df.core.List").
        @param oValue   The value to set.

        @return  True if the property was set.
        */
        setNestedProp(sPath, oValue) {
            let oProp;

            //  Split into parts
            const aParts = sPath.split(".");

            //  We start our search at the global object
            oProp = this.getGlobalObj();

            //  Loop through parts and object properties
            for (let iPart = 0; iPart < aParts.length - 1; iPart++) {
                if (typeof oProp === "object" && oProp !== null) {
                    oProp = oProp[aParts[iPart]];
                } else {
                    return false;
                }
            }

            oProp[aParts[aParts.length - 1]] = oValue;

            return true;
        }

    },

    /*
    The math library contains functionality to perform calculations.
    */
    math: {
        /*
        Fills out the given number with zero's until it has the required amount of digits.
        
        @param  iNum    Number to convert.
        @param  iDigits Number of digits.
        @return String with the number outfilled with zero's.
        */
        padZero(iNum, iDigits) {
            let sResult = iNum.toString();

            while (sResult.length < iDigits) {
                sResult = "0" + sResult;
            }

            return sResult;
        },

        isNumeric(n) {
            return !isNaN(parseFloat(n)) && isFinite(n);
        }

    },

    /*
    Functionality for data conversions and other data related functions.
    */
    data: {

        /*
        Parses a string into a number using the correct thousands and decimal separator.
        
        @param  sVal            String containing the number to parse.
        @param  sDecSep        The decimal separator used.
        @param  sOptThousSepp   (optional) The thousands separator used.
        @return Number.
        
        */
        stringToNum(sVal, sDecSep, sOptThousSepp) {
            return sVal && parseFloat(sVal.replace(sOptThousSepp || "", "").replace(sDecSep, "."));
        },

        /*
        This method converts a numeric value to a string using the decimal separator that is configured.
        
        @param  nVal        The numeric value.
        @param  sDecSep     The decimal separator used.
        @param  iPrecision  Number of decimals.
        @return The string with the number.
        @private
        */
        numToString(nVal, sDecSep, iPrecision) {
            let aVal, sVal;

            //  Make sure that we have a number
            nVal = nVal || 0.0;

            //  Parse to string
            sVal = nVal.toString().replace(".", sDecSep);

            //  Format
            if (iPrecision > 0) {
                aVal = sVal.split(sDecSep);

                if (aVal.length < 2) {
                    aVal[1] = "";
                }
                aVal[1] = (aVal[1] + "0000000000000000000").substr(0, iPrecision);

                sVal = aVal[0] + sDecSep + aVal[1];
            }


            return sVal;
        },

        /*
        Applies the date mask on the date.
        
        @param  dValue          The date object.
        @param  sMask           The mask string.
        @param  sDateSeparator  Separator character that will be used in the date mask.
        @return String with the masked data.
        */
        applyDateMask(dValue, sMask, sDateSeparator, sOptTimeSeparator) {
            let bMinute = false;

            return sMask.replace(/(m{1,4}|d{1,4}|yyyy|yy|\/|hh|ss|fff|f|\:)/gi, function (sValue, iPos) {

                switch (sValue.toLowerCase()) {
                    case "m":
                        bMinute = true;
                        return dValue.getMonth() + 1;
                    case "mm":
                        if (bMinute) {
                            bMinute = false;
                            return sys.math.padZero(dValue.getMinutes(), 2);
                        }
                        bMinute = true;
                        return sys.math.padZero(dValue.getMonth() + 1, 2);
                    case "mmm":
                        bMinute = true;
                        return sys.string.copyCase(df.lang.monthsShort[dValue.getMonth()], sValue);
                    case "mmmm":
                        bMinute = true;
                        return sys.string.copyCase(df.lang.monthsLong[dValue.getMonth()], sValue);

                    case "d":
                        bMinute = false;
                        return dValue.getDate();
                    case "dd":
                        bMinute = false;
                        return sys.math.padZero(dValue.getDate(), 2);
                    case "ddd":
                        bMinute = false;
                        return sys.string.copyCase(df.lang.daysShort[dValue.getDay()], sValue);
                    case "dddd":
                        bMinute = false;
                        return sys.string.copyCase(df.lang.daysLong[dValue.getDay()], sValue);

                    case "yy":
                        bMinute = false;
                        return sys.math.padZero(dValue.getFullYear() % 100, 2);
                    case "yyyy":
                        bMinute = false;
                        return sys.math.padZero(dValue.getFullYear(), 4);

                    case "/":
                        bMinute = false;
                        return sDateSeparator;

                    case "hh":
                        bMinute = true;
                        return sys.math.padZero(dValue.getHours(), 2);
                    case "ss":
                        bMinute = true;
                        return sys.math.padZero(dValue.getSeconds(), 2);
                    case "f":
                        bMinute = true;
                        return dValue.getMilliseconds();
                    case "fff":
                        bMinute = true;
                        return sys.math.padZero(dValue.getMilliseconds(), 3);
                    case ":":
                        bMinute = true;
                        return sOptTimeSeparator || ":";
                }

                return sValue;
            });
        },

        /*
        This method applies a numeric mask to a number. 
        
        @param  nValue      Value as a number.
        @param  sMask       The mask string.
        @param  sDecSep     The decimal separator to use.
        @param  sThousSep   The thousands separator to use.
        @param  sCurSym     The currency symbol to use.
        @return The string containing the masked number.
        */
        applyNumMask(nValue, sMask, sDecSep, sThousSep, sCurSym) {
            let aParts, aResult = [], sChar, bEscape, iChar, iNumChar, iCount, sBefore, sDecimals,
                sMaskBefore, sMaskDecimals = null, sValue, iMaskBefore = 0, iMaskDecimals = 0,
                bThousands = false, bBefore = true;

            // Replace &curren;
            sMask = sMask.replace(/&curren;/g, sCurSym);

            //  Zero suppress (indicated by the "Z" as first mask character)
            if (sMask.charAt(0) === "Z") {
                if (nValue === 0.0) {
                    return "";
                }
                sMask = sMask.substr(1);
            }

            //  Determine which mask to use :D
            aParts = sMask.split(";");
            if (nValue < 0.0) {
                if (aParts.length > 1) {
                    sMask = aParts[1];
                } else {
                    sMask = "-" + aParts[0];
                }
            } else {
                sMask = aParts[0];
            }

            //  Split into before and and after decimal separator
            aParts = sMask.split(".");
            sMaskBefore = aParts[0];
            if (aParts.length > 1) {
                sMaskDecimals = aParts[1];
            }


            //  Pre process mask
            for (iChar = 0; iChar < sMask.length; iChar++) {
                switch (sMask.charAt(iChar)) {
                    case "\\":
                        iChar++;
                        break;
                    case "#":
                    case "0":
                        if (bBefore) {
                            if (iMaskBefore >= 0) {
                                iMaskBefore++;
                            }
                        } else {
                            if (iMaskDecimals >= 0) {
                                iMaskDecimals++;
                            }
                        }
                        break;
                    case "*":
                        if (bBefore) {
                            iMaskBefore = -1;
                        } else {
                            iMaskDecimals = -1;
                        }
                        break;
                    case ",":
                        bThousands = true;
                        break;
                    case ".":
                        bBefore = false;
                        break;
                }
            }

            //  Convert number into string with number before and numbers after
            if (iMaskDecimals >= 0) {
                nValue = nValue.toFixed(iMaskDecimals);
            }
            sValue = (nValue === 0.0 ? "" : String(nValue));
            aParts = sValue.split(".");
            sBefore = aParts[0];
            if (aParts.length > 1) {
                sDecimals = aParts[1];
            } else {
                sDecimals = "";
            }
            if (sBefore.charAt(0) === "-") {
                sBefore = sBefore.substr(1);
            }

            //  BEFORE DECIMAL SEPARATOR
            iChar = sMaskBefore.length - 1;
            iNumChar = sBefore.length - 1;
            iCount = 0;
            while (iChar >= 0) {
                sChar = sMaskBefore.charAt(iChar);
                bEscape = (iChar > 0 && sMaskBefore.charAt(iChar - 1) === "\\");

                if (!bEscape && (sChar === "#" || sChar === "*" || sChar === "0")) {
                    while (iNumChar >= 0 || sChar === "0") {
                        //  Append thousands separator if needed
                        if (iCount >= 3) {
                            iCount = 0;
                            if (bThousands) {
                                aResult.unshift(sThousSep);
                            }
                        }

                        //  Append number
                        aResult.unshift((iNumChar >= 0 ? sBefore.charAt(iNumChar) : "0"));
                        iNumChar--;
                        iCount++;

                        //  Break out for non repeative characters
                        if (sChar === "#" || sChar === "0") {
                            break;
                        }
                    }
                } else {
                    // if(sChar === "$" && !bEscape){
                    // sChar = sCurSym;
                    // }
                    if ((sChar !== "," && sChar !== "\\") || bEscape) {
                        aResult.unshift(sChar);
                    }
                }
                iChar--;
            }

            //  AFTER DECIMAL SEPARATOR
            if (sMaskDecimals !== null) {

                let aAfter = [];

                iNumChar = 0;
                for (iChar = 0; iChar < sMaskDecimals.length; iChar++) {
                    sChar = sMaskDecimals.charAt(iChar);
                    bEscape = (iChar > 0 && sMaskBefore.charAt(iChar - 1) === "\\");


                    if (!bEscape && (sChar === "#" || sChar === "*" || sChar === "0")) {
                        while (iNumChar < sDecimals.length || sChar === "0") {
                            //  Append number
                            aAfter.push((iNumChar >= 0 ? sDecimals.charAt(iNumChar) : "0"));
                            iNumChar++;

                            //  Break out for non repeative characters
                            if (sChar === "#" || sChar === "0") {
                                break;
                            }
                        }
                    } else {
                        // if(sChar === "$" && !bEscape){
                        // sChar = sCurSym;
                        // }
                        if (sChar !== "\\" || bEscape) {
                            aAfter.push(sChar);
                        }
                    }
                }

                if (aAfter.length) {
                    aResult.push(sDecSep, aAfter.join(""));
                }
            }

            return aResult.join("");
        },

        /*
        Applies the windows mask the to the value by adding the mask characters. If 
        the value doesn't matches the mask the value isn't completely displayed.
        
        Params:
            sValue  Value to apply the mask on.
        Returns:
            Masked value.
        */
        applyWinMask(sValue, sMask) {
            var iChar = 0, iValChar = 0, bFound;
            const aResult = [];

            if (sValue === "") {
                return "";
            }
            if (sMask === "") {
                return sValue;
            }

            while (iChar < sMask.length) {
                const sChar = sMask.charAt(iChar);

                if (sChar === "\\" && sMask.length > (iChar + 1)) {
                    aResult.push(sMask.charAt(iChar + 1));
                } else {
                    if (sChar === "#" || sChar === "@" || sChar === "!" || sChar === "*") {
                        bFound = false;
                        while (iValChar < sValue.length && !bFound) {
                            if (this.acceptWinMaskChar(sValue.charAt(iValChar), sChar)) {
                                aResult.push(sValue.charAt(iValChar));
                                bFound = true;
                            }
                            iValChar++;
                        }
                        if (!bFound) {
                            break;
                        }
                    } else {
                        //  Append mask display character
                        aResult.push(sChar);
                    }
                }
                iChar++;
            }

            return aResult.join("");
        },

        /*
        Checks if the given character is allowed at the given position for windows 
        masks.
        
        Params:
            sChar   Character to check.
            iPos    Position to check. 
        Returns:
            True if the character is allowed at the given position.
        
        @private
        */
        acceptWinMaskChar(sValChar, sChar) {
            return ((sChar === "#" && sValChar.match(/[0-9]/)) ||
                (sChar === "@" && sValChar.match(/[a-zA-Z]/)) ||
                (sChar === "!" && sValChar.match(/[^a-zA-Z0-9]/)) ||
                sChar === "*");
        },

        /*
        Parses a date or datetime string into a date object.
        
        @param  sValue          String date (that confirms the format).
        @param  sFormat         Date format (basic date format).
        @return Date object representing the date (returns null if no value given).
        */
        stringToDate(sValue, sFormat) {
            let bMinute = false, iDate = 0, iMonth = 0, iYear = 0, iHour = 0, iSecond = 0, iMinute = 0, iFraction = 0, dResult;
            const dToday = new Date();

            //  Empty string return null.
            if (sValue.trim() === "") {
                return null;
            }

            //  Parse the values into an array
            const aValues = sValue.split(/[^0-9]+/gi);

            //  Parse the format into an array
            const aFormat = sFormat.split(/[^mdyhmsf]+/gi);

            //  Loop over values and put into the right variable
            for (let i = 0; i < aValues.length; i++) {
                const sV = aValues[i];
                switch (aFormat[i]) {
                    case "d":
                    case "dd":
                        iDate = parseInt(sV, 10);
                        bMinute = false;
                        break;
                    case "m":
                        iMonth = parseInt(sV, 10);
                        bMinute = true;
                        break;
                    case "mm":
                        if (bMinute) {
                            iMinute = parseInt(sV, 10);
                        } else {
                            iMonth = parseInt(sV, 10);
                        }
                        break;
                    case "yy":
                    case "yyyy":
                        iYear = parseInt(sV, 10);
                        if (sV.length === 2) {
                            iYear = (iYear > 50 ? iYear + 1900 : iYear + 2000);
                        } else if (sV.length === 0) {
                            iYear = dToday.getFullYear();
                        }
                        bMinute = false;
                        break;
                    case "hh":
                        iHour = parseInt(sV, 10);
                        bMinute = true;
                        break;
                    case "ss":
                        iSecond = parseInt(sV, 10);
                        bMinute = true;
                        break;
                    case "f":
                    case "fff":
                        iFraction = parseInt(sV, 10);
                        break;
                }
            }

            //  Validate values
            if (!iYear) {
                iYear = dToday.getFullYear();
            } else {
                iYear = (iYear > 0 ? (iYear < 9999 ? iYear : 9999) : 0);
            }
            if (!iMonth) {
                iMonth = dToday.getMonth();
            } else {
                iMonth = (iMonth > 0 ? (iMonth <= 12 ? iMonth - 1 : 11) : 0);
            }
            if (!iDate) {
                iDate = dToday.getDate();
            } else {
                iDate = (iDate > 0 ? (iDate <= 32 ? iDate : 31) : 1);
            }

            iHour = (iHour > 0 ? (iHour <= 23 ? iHour : (iHour === 24 ? 0 : 23)) : 0);
            iMinute = (iMinute > 0 ? (iMinute < 60 ? iMinute : 59) : 0);
            iSecond = (iSecond > 0 ? (iSecond < 60 ? iSecond : 59) : 0);
            iFraction = (iFraction > 0 ? (iFraction < 999 ? iFraction : 999) : 0);

            //  Set the determined values to the new data object, decrement if to high
            dResult = new Date(iYear, iMonth, iDate, iHour, iMinute, iSecond, iFraction);
            while (dResult.getMonth() !== iMonth) {
                iDate--;
                dResult = new Date(iYear, iMonth, iDate, iHour, iMinute, iSecond, iFraction);
            }

            return dResult;
        },

        /*
        Generates a string for the given date using the given format.
        
        @param  dValue      Data object.
        @param  sFormat     Date format (basic date format).
        @return String representing the given date.
        */
        dateToString(dValue, sFormat, sDateSeparator) {
            return this.applyDateMask(dValue, sFormat, sDateSeparator || "/");
        },

        /*
        Determines the week number of the given date object.
        
        @param  dDate   Date object.
        @return The week number.
        */
        dateToWeek(dDate) {
            const date = new Date(dDate.getTime());

            date.setHours(0, 0, 0, 0);
            // Thursday in current week decides the year.
            date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7);
            // January 4 is always in week 1.
            const week1 = new Date(date.getFullYear(), 0, 4);
            // Adjust to Thursday in week 1 and count number of weeks from date to week1.
            return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
        },

        /*
        Loops through the array and removes all items that match the given object.
        
        @param  aArray  Reference to the array.
        @param  oObj    Object reference or value to remove.
        */
        removeFromArray(aArray, oObj) {

            for (let i = 0; i < aArray.length; i++) {
                if (aArray[i] === oObj) {
                    aArray.splice(i, 1);
                }
            }
        },

        /*
        Expression used by the format method.
        
        @private
        */
        formatRegExp: /\{\{([0-9a-zA-Z]+)\}\}/gi,
        /*
        Formats a string based on a past object or array. Markers {{prop}} will be replaced with properties 
        from the passed object or array. 
        
        @code
        sStr = sys.data.format('Hi {{name}}!', { name : 'John' }); // sStr will contain 'Hi John!'
        sStr = sys.data.format('The {{0}} and {{1}}!', [ 'first', 'second' ]); // sStr will contain 'The first and second'
        @code
        
        @param  sStr    String containing markers to replace.
        @param  oReps   Object or array containing properties to replace markers with.
        @return Formatted string.
        */
        format(sStr, oReps) {
            const reps = oReps || {};


            return sStr.replace(this.formatRegExp, function (str, p1, offset, s) {
                if (reps.hasOwnProperty(p1)) {
                    return reps[p1];
                }
                return str;
            });
        },

        /*
        Properly formats a data size in the appropriate unit (like 131 kB or 15.4 MB or 900 GB).
        
        @param  iBytes      The data size in bytes.
        @return String containing the formatted size.
        */
        markupDataSize(iBytes) {
            let nVal;

            if (iBytes < 1024) {
                return iBytes + " B";
            }

            //  kilobytes
            nVal = iBytes / 1024;
            if (nVal < 2048) {
                return Math.round(nVal) + " kB";
            }

            //   megabytes
            nVal = nVal / 1024;
            if (nVal < 2048) {
                if (nVal < 100) {
                    return ((Math.round(nVal) * 10) / 10) + " MB";
                }
                return Math.round(nVal) + " MB";
            }

            //  gigabytes
            nVal = nVal / 1024;
            if (nVal < 2048) {
                if (nVal < 100) {
                    return ((Math.round(nVal) * 10) / 10) + " GB";
                }
                return Math.round(nVal) + " GB";
            }

            //  terabyte
            nVal = nVal / 1024;
            if (nVal < 2048) {
                if (nVal < 100) {
                    return ((Math.round(nVal) * 10) / 10) + " TB";
                }
                return Math.round(nVal) + " TB";
            }

            //  petabyte
            nVal = nVal / 1024;
            if (nVal < 100) {
                return ((Math.round(nVal) * 10) / 10) + " PB";
            }
            return Math.round(nVal) + " PB";

        },

        /* 
        Escapes a string for safe usage within a regular expression.
        
        @param  sStr    The string to escape.
        @return Escaped string.
        */
        escapeRegExp(sStr) {
            return sStr.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
        },

        /*
        Comparison function used by the sortData function that compares text columns.
        
        @param  sVal1   First string value.
        @param  sVal2   Second string value.
        @return Negative number if sVal1 < sVal2, positive for sVal1 > sVal2 and 0 when equal.
        
        @private
        */
        compareText(sVal1, sVal2) {
            return sVal1.localeCompare(sVal2);
        },
        compareRevText(sVal1, sVal2) {
            return -(sVal1.localeCompare(sVal2));
        },


        /*
        Comparison function used by the sortData function that compares numeric columns.
        
        @param  sVal1   First string value.
        @param  sVal2   Second string value.
        @return -1 if sVal1 < sVal2, 1 if sVal1 > sVal2 and 0 when equal.
        
        @private
        */
        compareBCD(sVal1, sVal2) {
            return parseFloat(sVal1) - parseFloat(sVal2);
        },
        compareRevBCD(sVal1, sVal2) {
            return -(parseFloat(sVal1) - parseFloat(sVal2));
        },


        /*
        Comparison function used by the sortData function that compares date columns.
        
        @param  sVal1   First string value.
        @param  sVal2   Second string value.
        @return -1 if sVal1 < sVal2, 1 if sVal1 >= sVal2.
        
        @private
        */
        compareDate(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "yyyy/mm/dd", "-") < sys.data.stringToDate(sVal2, "yyyy/mm/dd", "-") ? -1 : 1;
        },
        compareRevDate(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "yyyy/mm/dd", "-") < sys.data.stringToDate(sVal2, "yyyy/mm/dd", "-") ? 1 : -1;
        },



        /*
        Comparison function used by the sortData function that compares date columns.
        
        @param  sVal1   First string value.
        @param  sVal2   Second string value.
        @return -1 if sVal1 < sVal2, 1 if sVal1 >= sVal2.
        
        @private
        */
        compareDateTime(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "yyyy/mm/ddThh:mm:ss.fff", "-") < sys.data.stringToDate(sVal2, "yyyy/mm/ddThh:mm:ss.fff", "-") ? -1 : 1;
        },
        compareRevDateTime(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "yyyy/mm/ddThh:mm:ss.fff", "-") < sys.data.stringToDate(sVal2, "yyyy/mm/ddThh:mm:ss.fff", "-") ? 1 : -1;
        },



        /*
        Comparison function used by the sortData function that compares date columns.
        
        @param  sVal1   First string value.
        @param  sVal2   Second string value.
        @return -1 if sVal1 < sVal2, 1 if sVal1 >= sVal2.
        
        @private
        */
        compareTime(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "hh:mm:ss", "-") < sys.data.stringToDate(sVal2, "hh:mm:ss", "-") ? -1 : 1;
        },
        compareRevTime(sVal1, sVal2) {
            if (sVal1 == sVal2) return 0;
            return sys.data.stringToDate(sVal1, "hh:mm:ss", "-") < sys.data.stringToDate(sVal2, "hh:mm:ss", "-") ? 1 : -1;
        },


        /* 
        Returns the right comparison function based on the passed data type (ciTypeBCD, ciTypeDate, ..).
        
        @param  eDataType   Integer indicating the data type.
        @return Function that properly compares both type for usage within sorting algoritms (can be passed 
                to Array.sort).
        */
        compareFunction(eDataType, bRev) {
            switch (eDataType) {
                case df.ciTypeBCD:
                    return (bRev ? this.compareRevBCD : this.compareBCD);
                case df.ciTypeDate:
                    return (bRev ? this.compareRevDate : this.compareDate);
                case df.ciTypeDateTime:
                    return (bRev ? this.compareRevDateTime : this.compareDateTime);
                case df.ciTypeTime:
                    return (bRev ? this.compareRevTime : this.compareTime);
                default:
                    return (bRev ? this.compareRevText : this.compareText);
            }
        },

        /*
        This method determines the type specific value with a new value which is usually received from the 
        server. The value is supplied in the 'server format' and is parsed into the private type specific 
        value.
        
        @param  sVal     The new value provided in the 'server format'.
        @param eDataType The datatype that sVal needs to be converted to.
        @return The type specific value (date object or number).
        @private
        */
        serverToType(sVal, eDataType) {
            let tVal = sVal;

            if (eDataType === df.ciTypeBCD) {
                tVal = sys.data.stringToNum(sVal, ".");
            } else if (eDataType === df.ciTypeDate) {
                tVal = sys.data.stringToDate(sVal, "yyyy/mm/dd", "-");
            } else if (eDataType === df.ciTypeDateTime) {
                tVal = sys.data.stringToDate(sVal, "yyyy/mm/ddThh:mm:ss.fff");
            } else if (eDataType === df.ciTypeTime) {
                tVal = sys.data.stringToDate(sVal, "hh:mm:ss");
            }

            return tVal;
        },

        /*
        This method converts a type specific value to a display value.
        
        @param  tVal        Value in type specific format (number or date object).
        @param  eDataType   Indicates the type to convert the value to.
        @param  oWebApp     Indicates the webapp context for fetching locale.
        @param  bInputMask  Indicates whether the applied mask should be the one used in edit/input mode (focus).
        @param  sMask       Indicates the mask to apply to the value.
        @param  iPrecision  Indicates the precision of double (e.g. 1.234) if no mask is applied.
        
        @return String with the display value.
        */
        typeToDisplay(tVal, eDataType, oWebApp, bInputMask, sMask, iPrecision) {
            let sVal = tVal;

            if (!bInputMask && sMask && eDataType !== df.ciTypeText) {    //  If the field doesn't have the focus we need to apply a mask
                if (eDataType === df.ciTypeDate || eDataType === df.ciTypeDateTime || eDataType === df.ciTypeTime) { // Date mask
                    sVal = (tVal && sys.data.applyDateMask(tVal, sMask, oWebApp.psDateSeparator, oWebApp.psTimeSeparator)) || "";
                } else if (eDataType === df.ciTypeBCD) { // Numeric mask
                    sVal = (tVal !== null && sys.data.applyNumMask(tVal || 0.0, sMask, oWebApp.psDecimalSeparator, oWebApp.psThousandsSeparator, oWebApp.psCurrencySymbol)) || "";
                }
            } else if (sMask && eDataType === df.ciTypeText) {  //  Window mask
                sVal = sys.data.applyWinMask(sVal, sMask);
            } else {  //  No mask
                if (tVal !== "") {    // Leave blank value alone
                    if (eDataType === df.ciTypeBCD) {   //  Plain number
                        sVal = (tVal !== null && sys.data.numToString(tVal, oWebApp.psDecimalSeparator, iPrecision));
                    } else if (eDataType === df.ciTypeDate) {   //  Plain date
                        sVal = (tVal && sys.data.dateToString(tVal, oWebApp.psDateFormat, oWebApp.psDateSeparator, oWebApp.psTimeSeparator)) || "";
                    } else if (eDataType === df.ciTypeDateTime) {   //  Plain date time
                        sVal = (tVal && sys.data.dateToString(tVal, oWebApp.psDateTimeFormat, oWebApp.psDateSeparator, oWebApp.psTimeSeparator)) || "";
                    } else if (eDataType === df.ciTypeTime) {   //  Plain time
                        sVal = (tVal && sys.data.dateToString(tVal, oWebApp.psTimeFormat, oWebApp.psDateSeparator, oWebApp.psTimeSeparator)) || "";
                    }
                }
            }

            return sVal;
        }

    },

    /*
    Functions that ease the access of cookies.
    */
    cookie: {

        /*
        Places a cookie.
        
        @param  sVar            Name of cookie variable.
        @param  sValue            Value of cookie variable.
        @param  iExpires        Determines when the cookie expires in hours from right now.
        @param  sOptPath        Optional path for which the cookie should be stored. Use '/' for the entire 
                                domain.
        */
        set(sVar, sValue, iExpires, sOptPath) {
            const date = new Date();
            let sParams = "";

            if (iExpires) {
                date.setHours(date.getHours() + iExpires);
                sParams += "; expires=" + date.toGMTString();
            }

            if (sOptPath) {
                sParams += "; path=" + sOptPath;
            }

            document.cookie = sVar + "=" + sValue + sParams;
        },

        /*
        Removes cookie by expiring.
        
        @param  sVar    Name of cookie variable.
        */
        del(sVar) {
            const date = new Date();

            date.setTime(date.getTime() - 1);

            document.cookie = sVar + "=; expires=" + date.toGMTString();
        },

        /*
        Fetches cookie value.
        
        @param  sVar        Name of cookie variable.
        @param  sDefault    Variable to return when not found.
        @return Value of the cookie variable (sDefault if not found).
        */
        get(sVar, sDefault) {
            let sResult = null;

            if (document.cookie) {
                const aVars = document.cookie.split(';');

                for (let iVar = 0; iVar < aVars.length && sResult === null; iVar++) {
                    const aVar = aVars[iVar].split('=');

                    if (aVar.length > 1) {
                        if (aVar[0].trim() === sVar.trim()) {
                            sResult = aVar[1];
                        }
                    }
                }
            }

            if (sResult !== null) {
                return sResult;
            }
            return sDefault;
        }


    },



    /*
    Library object that contains several string functions that seem to be missing
    the in the ECMAScript standard.
    */
    string: {

        /*
        Removes spaces before and after the given string.
        
        @param  sString        String to trim.
        @return Trimmed string.
        @deprecated
        */
        trim(sString) {
            return sString.trim();
        },

        /*
        Removes spaces before the given string.
        
        @param  sString    String to trim.
        @return Trimmed string.
        */
        ltrim(sString) {
            return sString.replace(/^\s+/, "");
        },

        /*
        Removes spaces after the given string.
        
        @param  sString    String to trim.
        @return Trimmed string.
        */
        rtrim(sString) {
            return sString.replace(/\s+$/, "");
        },

        /*
        Modifies the casing of the value string according to the sample string.
        
        @param  sValue  String of which the casing is adjusted.
        @param  sSample String determining the casing.
        @return String with the modified casing.
        */
        copyCase(sValue, sSample) {
            let sResult = "";

            for (let iChar = 0; iChar < sValue.length; iChar++) {
                const bUpper = (iChar < sSample.length ? sSample.charAt(iChar) === sSample.charAt(iChar).toUpperCase() : bUpper);

                sResult += (bUpper ? sValue.charAt(iChar).toUpperCase() : sValue.charAt(iChar).toLowerCase());
            }

            return sResult;
        },
    },

    /* 
    Determines if the HTML5 input type is supported by creating a test DOM element. It caches the 
    responses to keep the performance high on multiple requests.
    
    @param  sType   The HTML5 input type ("date", "number", "email").
    */
    supportHtml5Input: (function () {
        const oCache = {};

        return function test(sType) {
            let eElem;

            if (typeof oCache[sType] === "boolean") {
                return oCache[sType];
            }
            eElem = document.createElement("input");
            eElem.setAttribute("type", sType);

            oCache[sType] = (eElem.type === sType);
            return oCache[sType];
        };
    }()),

   

};




//  - - - - Add missing JavaScript features for older browsers - - - - 

// <=IE11 Array.find
if (!Array.prototype.find) {
    Array.prototype.find = function (callback) {
        if (this === null) {
            throw new TypeError('Array.prototype.find called on null or undefined');
        } else if (typeof callback !== 'function') {
            throw new TypeError('callback must be a function');
        }
        const list = Object(this);
        // Makes sures is always has an positive integer as length.
        const length = list.length >>> 0;
        const thisArg = arguments[1];
        for (let i = 0; i < length; i++) {
            const element = list[i];
            if (callback.call(thisArg, element, i, list)) {
                return element;
            }
        }
    };
}

//  Polyfull for NodeList forEach (IE11)
if (window.NodeList && !NodeList.prototype.forEach) {
    NodeList.prototype.forEach = function (callback, thisArg) {
        thisArg = thisArg || window;
        for (let i = 0; i < this.length; i++) {
            callback.call(thisArg, this[i], i, this);
        }
    };
}

//  Polyfill for Object.values (IE)
if (!Object.values) {
    Object.values = function values(obj) {
        const vals = [];
        for (var key in obj) {
            if (obj.hasOwnProperty(key) && obj.propertyIsEnumerable(key)) {
                vals.push(obj[key]);
            }
        }
        return vals;
    };
}

// <=IE11 does not have a replaceAll; allocate it here.
if (!String.prototype.replaceAll) {
    String.prototype.replaceAll = function (search, replacement) {
        return this.split(search).join(replacement);
    };
}

// <=IE11 matches
if (!Element.prototype.matches) {
    Element.prototype.matches =
        Element.prototype.msMatchesSelector ||
        Element.prototype.webkitMatchesSelector;
}

// <=IE11 closest
if (!Element.prototype.closest) {
    Element.prototype.closest = function (s) {
        let el = this;

        do {
            if (Element.prototype.matches.call(el, s)) return el;
            el = el.parentElement || el.parentNode;
        } while (el !== null && el.nodeType === 1);
        return null;
    };
}

