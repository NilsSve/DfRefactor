import { dom } from '../dom.js';
import { dev } from './dev.js';
/*
Functionality to create graphical components.
*/
export const gui = {

    /*
    Finds all the child elements of the given element that can be focussed and
    disables the tabindex by setting a negative value.
    
    @param  eParent    DOM element to search.
    */
    disableTabIndexes(eParent) {
        const aElems = df.dom.query(eParent, df.dom.cFocusSelector, true);

        for (let iElem = 0; iElem < aElems.length; iElem++) {
            const eElem = aElems[iElem];

            if (eElem.getAttribute("data-dfOrigTabIndex") === null) {
                eElem.setAttribute("data-dfTabIndexCount", 1);
                eElem.setAttribute("data-dfOrigTabIndex", eElem.tabIndex);
                eElem.tabIndex = "-1";
            } else {
                eElem.setAttribute("data-dfTabIndexCount", parseInt(eElem.getAttribute("data-dfTabIndexCount"), 10) + 1);
            }
        }
    },

    /*
    Finds all the child elements of the given element that can contain tabs and
    restores their tabindex (if it is modified by by the disableTabIndex method).
    
    @param   eParent    DOM element to search.
    */
    restoreTabIndexes(eParent) {
        const aElems = df.dom.query(eParent, df.dom.cFocusSelector, true);

        for (let iElem = 0; iElem < aElems.length; iElem++) {
            const eElem = aElems[iElem];
            if (parseInt(eElem.getAttribute("data-dfTabIndexCount"), 10) !== null) {
                if (eElem.getAttribute("data-dfTabIndexCount") <= 1) {
                    eElem.tabIndex = eElem.getAttribute("data-dfOrigTabIndex");
                    eElem.removeAttribute("data-dfOrigTabIndex");
                    eElem.removeAttribute("data-dfTabIndexCount");
                } else {
                    eElem.setAttribute("data-dfTabIndexCount", parseInt(eElem.getAttribute("data-dfTabIndexCount"), 10) - 1);
                }
            }
        }
    },

    /*
    Hides plugins inside the element in Internet Explorer by removing them from the document object 
    model. Internet Explorer has problems doing that by itself.  It will return an array with 
    information which can be used to restore the elements into the DOM. 
    
    @param  eElem    The element to search.
    @return Array with details for restorePlugins.
    */
    hidePlugins(eElem) {
        const aHidden = [];

        //  Only for Internet Explorer
        if (dev.isIE) {
            //  Find problematic elements
            const aElems = df.dom.query(eElem, "iframe, object, embed", true);

            for (let i = 0; i < aElems.length; i++) {
                eElem = aElems[i];

                //  Check if not already hidden
                if (eElem.getAttribute("data-df-hiddenplugin") !== "yes") {

                    //  Remember
                    aHidden.push(eElem);

                    //  Hide
                    eElem.style.display = "none";

                    //  Mark as already hidden
                    eElem.setAttribute("data-df-hiddenplugin", "yes");
                }
            }
        }

        return aHidden;
    },

    /*
    Restores plugin elements that are hidden by hidePlugins. It inserts the elements back into the DOM 
    based on the passed details.
    
    @param  aHidden     Details of the hidden elements as it is returned by hidePlugins.
    */
    restorePlugins(aHidden) {

        for (let i = 0; i < aHidden.length; i++) {
            //  Display
            aHidden[i].style.display = "";

            //  Unmark
            aHidden[i].removeAttribute("data-df-hiddenplugin");
        }
    },


    /*
    Bubbles up in the dom measuring the total offsets until the next absolute
    (or fixed) positioned element in the DOM. This is are values that can be used
    as the style.left and style.top to position an absolute (or fixed) element on
    the same position.
    
    @param  eElement The object to get offset(s) from.
    @return Object { top : 500, left : 500 } with the offset values.
    */
    getAbsoluteOffset(eElement) {
        const oReturn = { left: 0, top: 0 };
        let bFirst = true;

        if (eElement.offsetParent) {
            while (eElement && (bFirst || gui.getCurrentStyle(eElement).position !== "absolute") && gui.getCurrentStyle(eElement).position !== "fixed" && gui.getCurrentStyle(eElement).position !== "relative") {
                bFirst = false;
                oReturn.top += eElement.offsetTop;
                oReturn.left += eElement.offsetLeft;
                eElement = eElement.offsetParent;
            }
        } else if (eElement.y) {
            oReturn.left += eElement.x;
            oReturn.top += eElement.y;
        }

        return oReturn;

    },

    /*
    @return The full display width (of the frame / window).
    */
    getViewportHeight() {
        if (window.innerHeight !== undefined) {
            return window.innerHeight;
        }

        if (document.compatMode === "CSS1Compat") {
            return document.documentElement.clientHeight;
        }
        if (document.body) {
            return document.body.clientHeight;
        }
        return null;
    },

    /*
    @return The full display height (of the frame / window).
    */
    getViewportWidth() {
        if (document.compatMode === 'CSS1Compat') {
            return document.documentElement.clientWidth;
        }
        if (document.body) {
            return document.body.clientWidth;
        }
        if (window.innerWidth !== undefined) {
            return window.innerWidth;
        }

        return null;
    },

    /*
    Determines the 'real size' of the element.
    
    @return Object with width and height property.
    */
    getSize(eElem) {
        if (dev.isIE || dev.isWebkit) {
            return { width: eElem.offsetWidth, height: eElem.offsetHeight };
        }
        const oStyle = gui.getCurrentStyle(eElem);
        return { width: parseInt(oStyle.getPropertyValue("width"), 10), height: parseInt(oStyle.getPropertyValue("height"), 10) };
    },


    /*
    Returns the current or computed style of the DOM element.
    
    @param  eElem    Reference to a DOM element.
    @return The browsers current style element.
    */
    getCurrentStyle(eElem) {
        return (typeof (window.getComputedStyle) === "function" ? window.getComputedStyle(eElem, null) : eElem.currentStyle);
    },


    /*
    Calculates the vertical space consumed by margin, padding and border by querying the browser its 
    calculated css values. Several combinations of padding, margin and border values are available as 
    different modes.
    
    0 = all (padding + margin + border)
    1 = outside (margin + border) 
    2 = inside (padding) 
    3 = outside border box (margin only)
    
    @param  iOptType    (optional) The mode to use, if not provided mode 0 is used.
    @return The total number of pixels consumed by the specified parts of the box model.
    */
    getVertBoxDiff(eElem, iOptType) {
        let iDiff = 0; 
        const oStyle = gui.getCurrentStyle(eElem);

        iOptType = iOptType || 0;

        if (iOptType === 0 || iOptType === 1 || iOptType === 3) {
            iDiff += parseFloat(oStyle.marginTop) || 0;
        }
        if (iOptType === 0 || iOptType === 1) {
            iDiff += parseFloat(oStyle.borderTopWidth) || 0;
        }
        if (iOptType === 0 || iOptType === 2) {
            iDiff += parseFloat(oStyle.paddingTop) || 0;
        }

        if (iOptType === 0 || iOptType === 1 || iOptType === 3) {
            iDiff += parseFloat(oStyle.marginBottom) || 0;
        }
        if (iOptType === 0 || iOptType === 1) {
            iDiff += parseFloat(oStyle.borderBottomWidth) || 0;
        }
        if (iOptType === 0 || iOptType === 2) {
            iDiff += parseFloat(oStyle.paddingBottom) || 0;
        }

        return iDiff;
    },

    /*
    Calculates the horizontal space consumed by margin, padding and border by querying the browser its 
    calculated css values. Several combinations of padding, margin and border values are available as 
    different modes.
    
    0 = all (padding + margin + border)
    1 = outside (margin + border) 
    2 = inside (padding) 
    3 = outside border box (margin only)
    
    @param  iOptType    (optional) The mode to use, if not provided mode 0 is used.
    @return The total number of pixels consumed by the specified parts of the box model.
    */
    getHorizBoxDiff(eElem, iOptType) {
        let iDiff = 0;
        const oStyle = gui.getCurrentStyle(eElem);

        iOptType = iOptType || 0;

        if (iOptType === 0 || iOptType === 1 || iOptType === 3) {
            iDiff += parseFloat(oStyle.marginLeft) || 0;
        }
        if (iOptType === 0 || iOptType === 1) {
            iDiff += parseFloat(oStyle.borderLeftWidth) || 0;
        }
        if (iOptType === 0 || iOptType === 2) {
            iDiff += parseFloat(oStyle.paddingLeft) || 0;
        }

        if (iOptType === 0 || iOptType === 1 || iOptType === 3) {
            iDiff += parseFloat(oStyle.marginRight) || 0;
        }
        if (iOptType === 0 || iOptType === 1) {
            iDiff += parseFloat(oStyle.borderRightWidth) || 0;
        }
        if (iOptType === 0 || iOptType === 2) {
            iDiff += parseFloat(oStyle.paddingRight) || 0;
        }

        return iDiff;
    },

    /* 
    This function tests if the element is sized by its content. It determines this by adding a temporary 
    element and if the size changes we know the element is sized by its content.
    
    @param  eElem   DOM Element.
    @return True if the element its size is determined by its content.
    */
    isSizedByContent(eElem) {
        const iCH = eElem.clientHeight;

        eElem.appendChild(df.dom.create('<div style="width: 100%; height: 20px;">&nbsp</div>'));

        const bRes = (iCH !== eElem.clientHeight);

        eElem.removeChild(eElem.lastChild);

        return bRes;
    },

    /* 
    Cross browser method for getting a boundingclientrect object.
    
    @param  eElem   The DOM element.
    @return Bounding rectangle object { top:x, right:x, bottom:x, left:x, width:x, height:x }.
    */
    getBoundRect(eElem) {
        const oR = eElem.getBoundingClientRect();

        if (typeof oR.width !== 'number') {  //  Internet Explorer 8 doesn't support width & height
            return {
                top: oR.top,
                right: oR.right,
                bottom: oR.bottom,
                left: oR.left,
                width: oR.right - oR.left,
                height: oR.bottom - oR.top
            };
        }

        return oR;
    },

    /* 
    Copies the values of a ClientRect into a JavaScript Object. This makes the properties writable so 
    they can be used for translations.
    
    @param  oR  ClientRect object.
    @return JavaScript Object.
    */
    rectToObj(oR) {
        return {
            top: oR.top,
            right: oR.right,
            bottom: oR.bottom,
            left: oR.left,
            width: oR.width,
            height: oR.height
        };
    },

    /* 
    Returns the properly prefixed name for setting CSS transformations. As optimization a closure is 
    used in which the result is cached.
    
    @return String with the browser dependent property name for transform.
    */
    getTransformProp: (function () {
        let sPrefix = null;

        function getTrans() {
            const aPre = ['transform', 'WebkitTransform', 'MozTransform', 'OTransform', 'msTransform'];
            for (let i = 0; i < aPre.length; i++) {
                if (document.createElement('div').style[aPre[i]] !== undefined) {
                    return aPre[i];
                }
            }
            return false;
        }

        return function () {
            if (sPrefix === null) {
                sPrefix = getTrans();
            }

            return sPrefix;
        };
    }()),

    /*
    Sets the CSS class of the body element with a class name that indicates the used
    browser. The used classnames are df-ie, df-safari, df-chrome, df-opera,
    df-mozilla for the different browsers. For internet explorer the extra
    classnames df-ie6, df-ie7, df-ie8 are also attached. Browsers using the
    webkit engine (like chrome and safari) also get the df-webkit class.
    
    The function is called automatically after loading. It uses the is.. and
    dev.iVersion indicators to determine browser versions.
    */
    initCSS() {
        let aC, sB = document.body.className;

        //  Check if classnames are already applied to the body, if so filter out the device classes and fill array with existing classnames
        if (sB) {
            sB = sB.replace(/\bdf-ie*|df-safari|df-chrome|df-opera|df-mozilla|df-webkit|df-mobile\b/g, "").trim();
            aC = sB.split(' ');
        } else {
            aC = [];
        }

        //  Determine browser classes to add
        if (dev.isIE) {
            aC.push("df-ie");

            aC.push(dev.iVersion <= 6 ? " df-ie6" : " df-ie" + dev.iVersion); //  For IE we also add version specific classes
        } else if (dev.isSafari) {
            aC.push("df-safari");
        } else if (dev.isChrome) {
            aC.push("df-chrome");
        } else if (dev.isOpera) {
            aC.push("df-opera");
        } else if (dev.isMoz) {
            aC.push("df-mozilla");
        }

        //  WebKit engine gets its own class
        if (dev.isWebkit) {
            aC.push("df-webkit");
        }

        //  Mobile devices get the mobile class
        if (dev.isMobile) {
            aC.push("df-mobile");
        }

        //  Apply the changed classname
        document.body.className = aC.join(" ");
    },

    /* 
    Checks if the element is on the screen by looking at the scrollbar positions. It doesn't check if 
    the the element (or one of its parent elements) are visible or not. 
    
    TODO: Extend with support for horizontal scrolling.
    TODO: Check what happens if one of the parents was made invisible using display or visibility.
    
    @param  eElem    DOM Element.
    */
    isOnScreen(el) {
        let rect = el.getBoundingClientRect(); 
        const top = rect.top, height = rect.height, left = rect.left, width = rect.width;

        el = el.offsetParent;

        while (el && el != document.body) {
            rect = el.getBoundingClientRect();
            if (top > rect.bottom) {
                return false;
            }

            if (left > rect.right) {
                return false;
            }


            // Check if the element is out of view due to a container scrolling
            if ((top + height) <= rect.top) {
                return false;
            }

            if (left + width <= rect.left) {
                return false;
            }

            el = el.offsetParent;
        }

        // Check its within the document viewport
        return top <= document.documentElement.clientHeight;
    },

    /*
    Checks if the element is fully on screen, if the element falls partially offscreen at anypoint this
    function will return false
    */
    isElementFullyOnScreen(el) {
        const rect = el.getBoundingClientRect();

        return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
            rect.right <= (window.innerWidth || document.documentElement.clientWidth)
        );

    },


    /* 
    Attaches event handlers to all parent elements that can scroll. Because scroll events don't bubble 
    this is the only way to find out if an element is moving on the screen because of a scroll event.
    
    @param  eElem       DOM element.
    @param  fListen     Event handler function.
    @param  oEnv        Environment object used for the event handler.
    
    @return     Array of DOM elements used by removeScrollListeners to clean out the event handler.
    */
    addScrollListeners(eElem, fListen, oEnv) {
        const aElems = [];

        while (eElem) {
            //if(eElem.scrollHeight > eElem.offsetHeight || eElem.scrollWidth > eElem.offsetWidth){
            aElems.push(eElem);
            df.dom.on("scroll", eElem, fListen, oEnv);
            //}
            eElem = eElem.offsetParent;
        }

        return aElems;
    },

    /* 
    Removes the event handlers attached by addScrollListeners based on the passed array.
    
    @return     Array of DOM elements created by addScrollListeners.
    */
    removeScrollListeners(aElems, fListen, oEnv) {
        let eElem;

        while (eElem = aElems.shift()) {
            df.dom.off("scroll", eElem, fListen, oEnv);
        }
    },


    cssTextAlign(eAlign) {
        switch (eAlign) {
            case df.ciAlignLeft:
                return "left";
            case df.ciAlignCenter:
                return "center";
            case df.ciAlignRight:
                return "right";
        }

        return "";
    }

}

