/*
Name:
    df.dom
Type:
    Library (object)

This library contains a generic layer of methods that perform Document Object Model (DOM) 
manipulations in a browser independent manner. It also extends the browser API with functionality 
that makes it easier to work with the DOM.
    
Revisions:
    2011/08/10 (HW, DAW)
        Initial version splitted from the df.sys library.
*/
import { gui } from './sys/gui.js';
import { events } from './events.js';


export const dom = {

    /*
    Selector string for usage with df.dom.query that gives all elements that can have the focus.
    
    @private
    */
    cFocusSelector: 'a, button, textarea, input, iframe, select, *[tabindex]',

    /* 
    Counter for unique DOM ID's.
    
    @private
    */
    piDomCounter: 0,

    /* 
    Shorthand API for adding DOM listeners. Can attach multiple listeners to multiple elements if arrays 
    are passed.
    
    @param  eElem   DOM element (or array of DOM elements)
    @param  sEvent  Name of the handled DOM event (or array / space separated string)
    @param  fHan    Handler function.
    @param  oEnv    Environment object (what this will point to when handler is called).
    */
    on(sEvent, eElem, fHan, oEnv) {
        let aEv;

        if (eElem instanceof Array || eElem instanceof NodeList) {
            eElem.forEach(function (eItem) {
                this.on(sEvent, eItem, fHan, oEnv);
            }, this);
            return;
        }

        if (sEvent instanceof Array) {
            aEv = sEvent;
        } else {
            aEv = sEvent.split(' ');
        }

        aEv.forEach(function (sItem) {
            events.addDomListener(sItem, eElem, fHan, oEnv);
        });
    },

    /* 
    Shorthand API for removind DOM listeners. Can remove multiple listeners of multiple elements at once.
    
    @param  eElem   DOM element (or array of DOM elements)
    @param  sEvent  Name of the handled DOM event (or array / space separated string)
    @param  fHan    Handler function.
    @param  oEnv    Environment object (what this will point to when handler is called).
    */
    off(sEvent, eElem, fHan, oEnv) {
        let aEv;

        if (eElem instanceof Array) {
            eElem.forEach(function (eItem) {
                this.off(eItem, sEvent, fHan, oEnv);
            }, this);
            return;
        }

        if (sEvent instanceof Array) {
            aEv = sEvent;
        } else {
            aEv = sEvent.split(' ');
        }

        aEv.forEach(function (sItem) {
            events.removeDomListener(sItem, eElem, fHan, oEnv);
        });
    },

    /* 
    Shorthand API for clearing all DOM listeners on an element.
    
    @param  eElem       DOM Element (or array of DOM elements).
    @param  bRecursive  If true it will also clear handlers of child elements.
    */
    clear(eElem, bRecursive) {
        if (eElem instanceof Array) {
            eElem.forEach(function (eItem) {
                this.clear(eItem, bRecursive);
            }, this);
            return;
        }

        events.clearDomListeners(eElem, bRecursive);
    },

    /* 
    Generates a unique ID using a counter. These unique ID's can be used by controls whenever a 
    generated id is necessary.
    
    @return String with unique ID.
    */
    genDomId() {
        return "_df_" + this.piDomCounter++;
    },

    /*
    Adds one or more classes to the elements className. Make sure the added classes 
    aren't already applied.
    
    @param  eElem   The element.
    @param  sClass  Space separated list of CSS class names.
    */
    addClass(eElem, sClass) {
        let sClassName, bFound = false;

        if (!eElem) return;

        if (eElem.className) {
            const aClasses = (sClass || "").split(/\s+/);
            sClassName = " " + eElem.className + " ";
            for (let i = 0; i < aClasses.length; i++) {
                if (sClassName.indexOf(" " + aClasses[i] + " ") < 0) {
                    sClassName += " " + aClasses[i];
                    bFound = true;
                }
            }
            if (bFound) {
                eElem.className = sClassName.trim();
            }
        } else {
            eElem.className = sClass;
        }
    },

    /*
    Removes one or more classes from the elements className.
    
    @param  eElem   The element.
    @param  sClass  Space separated list of CSS class names.
    */
    removeClass(eElem, sClass) {
        let sClassName, bFound = false;

        if (!eElem) return;

        if (eElem.className) {
            sClass = " " + sClass + " ";
            const aClasses = eElem.className.split(/\s+/);
            sClassName = "";
            for (let i = 0; i < aClasses.length; i++) {
                if (sClass.indexOf(" " + aClasses[i] + " ") < 0) {
                    sClassName += " " + aClasses[i];
                    bFound = true;
                }
            }
            if (bFound) {
                eElem.className = sClassName.trim();
            }
        }
    },

    toggleClass(eElem, sClass, bVal) {
        if (bVal) {
            this.addClass(eElem, sClass);
        } else {
            this.removeClass(eElem, sClass);
        }
    },

    createCSSElem(sFile) {
        const eStyle = document.createElement('link');
        eStyle.rel = 'stylesheet';
        eStyle.type = 'text/css';
        eStyle.href = sFile;

        return eStyle;
    },

    /**
     * Determines if one sibbling is located before another.
     * 
     * @param {DOM Element} eElem1 
     * @param {DOM Element} eElem2 
     * @returns True is the elements are sibblings and eElem1 is located before eElem2.
     */
    isBefore(eElem1, eElem2) {
        if (eElem2.parentNode === eElem1.parentNode) {
            for (let cur = eElem1.previousSibling; cur; cur = cur.previousSibling) {
                if (cur === eElem2) return true
            }
        }
        return false;
    },

    /*
    Sets the text / content of the element.
    
    @param  eElem    DOM Element.
    @param  sValue      The new text.
    */
    setText(eElem, sValue) {
        if (sValue === " ") {
            eElem.innerHTML = "&nbsp;";
        } else {
            //  Replace \n\r with newline (note that we only add the newline character and not the carriage return because WebKit will add a two newlines)
            sValue = sValue.toString().replace(/\\n\\r/gi, '\n');

            //  Set the innerText property
            if ("innerText" in eElem) {   //  Use ".. in .." syntax so it doesn't actually query the DOM element (performance)
                eElem.innerText = sValue;
            } else {
                eElem.textContent = sValue;
            }
        }
    },

    /*
    Gets the text / content of the element.
    
    @param  eElem    DOM Element.
    @return The content text.
    */
    getText(eElem) {
        if (eElem.innerText !== undefined) {
            return eElem.innerText;
        }

        return eElem.textContent;
    },

    /*
    This is a browser independent method to fetch the outerHTML of a DOM element. If the browser doesn't 
    support the outerHTML property the method will generate a temporary element and use the innerHTML 
    attribute.
    
    @param  eElem   Reference to a DOM element.
    @return The outerHTML of the element (null if not available).
    */
    getOuterHTML(eElem) {

        if (eElem.outerHTML) {
            return eElem.outerHTML;
        }
        if (eElem.parentNode) {
            const eParent = eElem.parentNode;
            const eFake = document.createElement(eParent.tagName);

            eFake.appendChild(eElem);
            const sHTML = eFake.innerHTML;
            eParent.appendChild(eElem);

            return sHTML;
        }
        return null;
    },

    /*
    Makes an exact clone of the given element and its sub element. It uses the 
    cloneNode method of the DOM but goes through the structure to "repair" the 
    flaws of the cloneNode method.
    
    @param  eOrig   The element to clone.
    @return Clone of the element (and its children).
    */
    deepClone(eOrig) {
        let fChecker;

        const eClone = eOrig.cloneNode(true);

        fChecker = function (eClone, eOrig) {
            var iChild;

            if (eClone.tagName === "SELECT" || eClone.tagName === "TEXTAREA") {
                eClone.value = eOrig.value;
            }

            for (iChild = 0; iChild < eClone.childNodes.length; iChild++) {
                if (eClone.childNodes[iChild].nodeType !== 3 && eClone.childNodes[iChild].nodeType !== 8) {
                    fChecker(eClone.childNodes[iChild], eOrig.childNodes[iChild]);
                }
            }
        };

        fChecker(eClone, eOrig);

        return eClone;
    },

    /*
    Replaces the node with the new one.
    
    @param  eOrig   DOM Node to be replaced.
    @param  eNew    New DOM node.
    */
    swapNodes(eOrig, eNew) {
        if (eOrig) {
            if (eNew) {
                if (eOrig.replaceNode !== undefined) {
                    eOrig.replaceNode(eNew);
                } else {
                    eOrig.parentNode.replaceChild(eNew, eOrig);
                }
            }
        }
    },

    /*
    Inserts the new element into the DOM after the given element.
    
    @param eNewElement  The new element to insert.
    @param eElem     The element to insert after.
    */
    insertAfter(eNewElement, eElem) {
        if (eElem.nextSibling !== null) {
            eElem.parentNode.insertBefore(eNewElement, eElem.nextSibling);
        } else {
            eElem.parentNode.appendChild(eNewElement);
        }
    },

    /*
    Recursive function that checks if the searched element is a parent of the
    start element.
    
    @param  eStart  Start element.
    @param  eSearch Searched element.
    @return True if the searched element is a parent.
    */
    isParent(eStart, eSearch) {
        if (eStart === null) {
            return false;
        }
        if (eStart === eSearch) {
            return true;
        }
        if (eStart.parentNode !== undefined) {
            return this.isParent(eStart.parentNode, eSearch);
        }
        return false;
    },

    /*
    Returns the a parent object (or itself) with the requested tagname
    
    @param  eElem       Element where to startt the search.
    @param  sTagName    Tagname of searched object.
    @return First parent with the given tagname (null if not found).
    */
    searchParent(eElem, sTagName) {
        sTagName = sTagName.toUpperCase();

        if (eElem.tagName === sTagName) {
            return eElem;
        }
        if (eElem.parentNode !== undefined && eElem !== document) {
            return this.searchParent(eElem.parentNode, sTagName);
        }
        return null;
    },

    /*
    Gives the focus to the given element. It has a try catch block because some
    browsers tend to throw strange errors here. It also calls the setActive method
    if it is available.
    
    @param  eElem    Reference to the DOM element that should receive the focus.
    @param  bSelect     If true the content of the element will also be selected.
    */
    focus(eElem, bSelect) {
        try {
            eElem.focus();
            if (bSelect && eElem.select) {
                eElem.select();
            }

            if (typeof (eElem.setActive) === "function") {
                eElem.setActive();
            }
        } catch (err) {
            //ignore focus error
        }


    },

    /*
    Tries to determine the current caret position of the text field.
    
    @param  eField  Reference to the field DOM element.
    @return The caret position (0 if not found).
    */
    getCaretPosition(eField) {
        return this.getSelection(eField).start;
    },

    /*
    Determines the length of the selection.
    
    @param  eField  Reference to a DOM element (usually a input type="text").
    @return Length of the selection (0 if no selection).
    @deprecated
    */
    getSelectionLength(eField) {
        return this.getSelection(eField).length;
    },

    /* 
    Determines the text selection within the DOM element (usually an input type=text or textarea). An 
    object with the details of the selection will be returned. This allows input filters and masks to 
    easily use this information.
    
    @param  eField  Reference to a DOM element.
    @return Object with selection details: { start: 4, end: 7, length: 3 }
    */
    getSelection(eField) {
        let iStart = 0, iEnd = 0;

        //  Use simple selectionStart and selectionEnd when available
        if ("selectionStart" in eField && (/text|password|search|tel|url/).test(eField.type)) {   //  Use ".. in .." syntax so it doesn't actually query the DOM element (performance)
            iStart = eField.selectionStart;
            iEnd = eField.selectionEnd;

        } else if (document.selection) {   // Internet Explorer 8 Support
            try {
                const oRange = document.selection.createRange();

                if (oRange && oRange.parentElement() === eField) {
                    const iLen = eField.value.length;
                    const sNormalizedValue = eField.value.replace(/\r\n/g, "\n");

                    // Create a working TextRange that lives only in the input
                    const oTextInputRange = eField.createTextRange();
                    oTextInputRange.moveToBookmark(oRange.getBookmark());

                    // Check if the start and end of the selection are at the very end
                    // of the input, since moveStart/moveEnd doesn't return what we want
                    // in those cases
                    const oEndRange = eField.createTextRange();
                    oEndRange.collapse(false);

                    if (oTextInputRange.compareEndPoints("StartToEnd", oEndRange) > -1) {
                        iStart = iEnd = iLen;
                    } else {
                        iStart = -oTextInputRange.moveStart("character", -iLen);
                        iStart += sNormalizedValue.slice(0, iStart).split("\n").length - 1;

                        if (oTextInputRange.compareEndPoints("EndToEnd", oEndRange) > -1) {
                            iEnd = iLen;
                        } else {
                            iEnd = -oTextInputRange.moveEnd("character", -iLen);
                            iEnd += sNormalizedValue.slice(0, iEnd).split("\n").length - 1;
                        }
                    }
                }



            } catch (e) {

            }
        }
        return {
            start: iStart,
            end: iEnd,
            length: iEnd - iStart
        };
    },

    /*
    Changes the caret position of the text field to the given position.
    
    @param  eField  Reference to the field.
    @param  iCaretPos   The new caret position.
    */
    setCaretPosition(eField, iCaretPos) {
        try {
            // IE Support
            if (document.selection) {

                // Set focus on the element
                eField.focus();

                // Create empty selection range
                const oSel = document.selection.createRange();

                // Move selection start and end to 0 position
                oSel.moveStart('character', -eField.value.length);
                oSel.moveEnd('character', -eField.value.length);

                // Move selection start and end to desired position
                oSel.moveStart('character', iCaretPos);
                oSel.select();
            } else if (((/text|password|search|tel|url/).test(eField.type) && eField.selectionStart) || eField.selectionStart === 0) { // Firefox support
                eField.selectionStart = iCaretPos;
                eField.selectionEnd = iCaretPos;
                eField.focus();
            }
        } catch (e) {

        }
    },

    /*
    Gives the focus to the first focusable child element that can receive the
    focus. Is a recursive method that loops through the DOM.
    
    @param  eElem    Reference to the DOM element.
    @return First child element that can receive the focus.
    */
    getFirstFocusChild(eElem) {
        const aElems = this.query(eElem, this.cFocusSelector, true);

        for (let i = 0; i < aElems.length; i++) {
            if (aElems[i].tabIndex >= 0 && aElems[i].type !== "hidden") {
                return aElems[i];
            }
        }

        return null;
    },

    /*
    This methods loops through the child elements of the DOM element and calls the 
    worker method for each child element. Using this method will reduce the amount 
    of code in the components and keep all checks on a single place. If the worker 
    method returns false the next children won't be processed any more.
    
    @param  eElem    Reference to the element.
    @param  fWorker     Method to call for each child.
    @param  oEnv        (optional) Environment object used when calling the worker.
    @return False if worker stopped processing the children.
    */
    visit(eElem, fWorker, oEnv) {

        //  Go into children
        if (eElem.childNodes) {
            for (let iChild = 0; iChild < eElem.childNodes.length; iChild++) {
                if (eElem.childNodes[iChild].nodeType !== 3 && eElem.childNodes[iChild].nodeType !== 8) {
                    if (fWorker.call(oEnv || this, eElem.childNodes[iChild]) === false) {
                        return false;
                    }
                }
            }
        }

        return true;
    },

    /*
    Disables the textselection for the element.
    
    @param  eElem    Reference to DOM element.
    */
    disableTextSelection(eElem) {
        // eElement.onselectstart = function() {
        // return false;
        // };
        eElem.unselectable = "on";
        eElem.style.MozUserSelect = "none";
        eElem.style.webkitUserSelect = "none";
    },

    /*
    Disables the textselection for the element.
    
    @param  eElem    Reference to DOM element.
    */
    enableTextSelection(eElem) {
        // eElement.onselectstart = function() {
        // return false;
        // };
        eElem.unselectable = "off";
        eElem.style.MozUserSelect = "text";
        eElem.style.webkitUserSelect = "text";
    },

    /*
    The passed method will be called as soon as the browser has finished initializing the Document 
    Object Model (DOM) and is ready for manipulation. If the DOM was already initialized the method will 
    be called right away. The sample code below shows how to make sure that a piece of code is executed 
    after the DOM is ready.
    
    @code
    df.dom.ready(function(){
        //  Code executed after DOM initialization
        document.getElementById("mydiv").innerHTML = "<b>Browser is finished!</b>";
    });
    @code
    
    @param  fWorker     Function that will be executed after the DOM is ready.
    @param  oEnv        Environment object used when calling the worker function.
    
    */
    ready(fWorker, oEnv) {
        function call() {
            fWorker.call(oEnv);

            //  Cleanup
            if (window.addEventListener) { // W3C
                window.removeEventListener("load", call, false);
            } else { // IE
                window.detachEvent("onload", call);
            }
        }

        if (document.readyState === "complete") {
            call();
        } else {
            //  Attach the listener
            if (window.addEventListener) { // W3C
                window.addEventListener("load", call, false);
            } else { // IE
                window.attachEvent("onload", call);
            }
        }
    },

    /* 
    This function converts a string of HTML into DOM elements. It creates a temporary div element of 
    which the innerHTML is set to let the browser parse the HTML. The outermost element is returned (the 
    first if there are multiple elements at root level).
    
    @return Wrapping DOM element.
    */
    create(sHtml) {
        const eWrapper = document.createElement("div");

        eWrapper.innerHTML = (Array.isArray(sHtml) ? sHtml.join("") : sHtml);

        return eWrapper.firstChild;
    },

    /* 
    This function searches the DOM based on a selector query. The selector query is comparable to CSS 
    selectors. It searches inside the element passed as the first parameter. Depending on bOptMulti it 
    will return the first match or an array with all matches. It uses the querySelector API from the 
    browser.
    
    @param  eElem       The element to search.
    @param  sSelect     The selector string.
    @param  bOptMulti   (optional) If true an array will be returned)
    
    @return The first matched element or if bOptMulti is true an array with all matched elements.
    */
    query(eElem, sSelect, bOptMulti) {
        if (!bOptMulti && eElem.querySelector) {
            return eElem.querySelector(sSelect);
        }
        if (eElem.querySelectorAll) {
            const aRes = eElem.querySelectorAll(sSelect);

            if (bOptMulti) {
                return aRes;
            }
            return (aRes.length > 0 ? aRes[0] : null);
        }
        /* Note: We could use Sizzle Selector library to support Internet Explorer 7 here
        
        var aRes = Sizzle(sSelect, eElem);
        
        if(bOptMulti){
            return aRes;
        }else{
            return (aRes.length > 0 ? aRes[0] : null);
        }*/
        throw new df.Error(999, "This browser doesn't support querySelectorAll");
    },

    /* 
    Sets the translateY transformation on the passed element. Makes sure to use the right browser 
    specific prefix and supports a fallback to setting the top style. Note that the fallback requires 
    the element to be displayed using position absolute in order to work.
    
    @param  eElem   DOM Element.
    @param  iY      Y offset in pixels.
    @param  bTopFB  If true the CSS top will be set for unsupportive browsers.
    @return True if succeeded.
    */
    translateY(eElem, iY, bTopFB) {
        const sPre = gui.getTransformProp();

        if (sPre) {
            eElem.style[sPre] = 'translateY(' + iY + 'px)';

            return true;
        }
        if (bTopFB) {
            eElem.style.top = iY + 'px';

            return true;
        }

        return false;
    },

    /* 
    Sets the translateX transformation on the passed element. Makes sure to use the right browser 
    specific prefix and supports a fallback to setting the top style. Note that the fallback requires 
    the element to be displayed using position absolute in order to work.
    
    @param  eElem   DOM Element.
    @param  iX      Y offset in pixels.
    @param  bTopFB  If true the CSS top will be set for unsupportive browsers.
    @return True if succeeded.
    */
    translateX(eElem, iX, bLeftFB) {
        const sPre = gui.getTransformProp();

        if (sPre) {
            if (iX !== null) {
                eElem.style[sPre] = 'translateX(' + iX + 'px)';
            } else {
                eElem.style[sPre] = '';
            }

            return true;
        }
        if (bLeftFB) {
            if (iX !== null) {
                eElem.style.left = iX + 'px';
            } else {
                eElem.style.left = '';
            }

            return true;
        }

        return false;
    },

    /* 
    Helper function for performing a single transition. The passed transition is set on the DOM element 
    and removed once it is finished. One can also pass a function to be executed after the transition. 
    Use this function before making a change to the dom to animate that change and know when it is 
    finished.
    
    @param  eElem           DOM Element.
    @param  sTransition     CSS transition string (like 'all 200ms').
    @param  fFinish         Handler function called after animation.
    @param  oEnv            Environment object to which this will point when the handler is called.
    */
    transition(eElem, sTransition, fFinish, oEnv) {
        function transEnd(oEv) {
            this.off("transitionend", eElem, transEnd, this);
            eElem.style.transition = "";

            if (fFinish) {
                fFinish.call(oEnv || this);
            }
        }

        //  We can safely use transactionend since all browsers that support swiping support it.. :)
        this.on("transitionend", eElem, transEnd, this);
        eElem.style.transition = sTransition;
    },

    /*
    Encodes special HTML characters so the string can safely be send in an XML message or displayed as 
    source in the page.
    
    @param  sValue  String containing HTML code.
    @return String containing the encoded HTML.
    */
    encodeHtml(sValue) {
        return (sValue || "").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    },

    /* 
    Encodes the quote inside attribute strings so that invalid values never break out of their 
    attribute.
    
    @param  sValue  String containing an attribute value in html.
    @return String containing encoded attribute value.
    */
    encodeAttr(sValue) {
        return (sValue || "").replace(/\"/g, '&quot;');
    },

    /* 
    Determines the current window width.
    
    @return Current window width in (virtual) pixels.
     */
    windowWidth() {
        return Math.max(
            (document.body && Math.max(
                document.body.scrollWidth,
                document.body.offsetWidth
            )) || 0,
            (document.documentElement && Math.max(
                document.documentElement.scrollWidth,
                document.documentElement.offsetWidth,
                document.documentElement.clientWidth
            )) || 0
        );
    },

    /* 
    Determines the current window height.
    
    @return Current window height in (virtual) pixels.
     */
    windowHeight() {
        return Math.max(
            (document.body && Math.max(
                document.body.scrollHeight,
                document.body.offsetHeight
            )) || 0,
            (document.documentElement && Math.max(
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight,
                document.documentElement.clientHeight
            )) || 0
        );
    },

    animFrame(fCallback, oEnv) {
        if (window.requestAnimationFrame) {
            window.requestAnimationFrame(function aniFrmCallback() {
                fCallback.call(oEnv || this);
            });
        } else {
            setTimeout(function aniFrmCallback() {
                fCallback.call(oEnv || this);
            }, 40);
        }
    },

    /*
    Returns the offsetHeight for a DOM element. The offsetHeight is the full height of the element 
    including borders margins & paddings. 
    
    Note that this method includes the fraction and does not round like the offsetHeight property!
    */
    offsetHeight(eElem) {
        return eElem?.getBoundingClientRect().height || 0;
    },

    /*
    Returns the clientHeight for a DOM element. The clientHeight is the height of the element without 
    margin and border. The clientHeight does include the padding. 
    
    Note that this method includes the fraction and does not round like the clientHeight property!
    */
    clientHeight(eElem) {
        return this.offsetHeight(eElem) - ((eElem?.offsetHeight || 0) - (eElem?.clientHeight || 0));
    },

    /*
    Returns the offsetWidth for a DOM element. The offsetWidth is the full width of the element 
    including borders margins & paddings. 
    
    Note that this method includes the fraction and does not round like the offsetWidth property!
    */
    offsetWidth(eElem) {
        return eElem?.getBoundingClientRect().width || 0;
    },

    /*
    Returns the clientWidth for a DOM element. The clientWidth is the height of the element without 
    margin and border. The clientWidth does include the padding. 
    
    Note that this method includes the fraction and does not round like the clientWidth property!
    */
    clientWidth(eElem) {
        return this.offsetWidth(eElem) - ((eElem?.offsetWidth || 0) - (eElem?.clientWidth || 0));
    },

    /*
    Updates the tabIndex of the element but takes the gui.restoreTabIndexes fake modality hack 
    into account. So it will only set the actual tabIndex directly if the tabIndex is not disabled by 
    the fake modality logic.
    */
    setTabIndex(eElem, iVal) {
        if (eElem.hasAttribute("data-dfOrigTabIndex") && parseInt(eElem.getAttribute("data-dfTabIndexCount"), 10) > 0) {
            eElem.setAttribute("data-dfOrigTabIndex", iVal);
        } else {
            eElem.tabIndex = iVal;
        }
    }

};

//  Make sure that the autoInit function after the DOM is initialized (Which can be in the future but also can be right now)
dom.ready(gui.initCSS, window);