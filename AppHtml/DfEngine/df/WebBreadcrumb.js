import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebBreadcrumb
Extends:
    df.WebBaseControl

This is the client-side representation of the WebBreadcrumb class. It generates the HTML for the ul 
element that wraps the li elements of each crumb. The CSS (class: WebBreadcrumb) Determines how the 
breadcrumb is shown and how the items will look.
    
Revision:
    2015/01/04  (JVH, DAW) 
        Initial version.
*/

export class WebBreadcrumb extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        // Web Properties
        this.prop(df.tInt, "peBreadcrumbStyle", df.cCrumbHorizontal);

        // @privates
        this._eControl = null;
        this._eList = null; // root <ul> element
        this._eCaption = null; // <div> element used to display the current view's caption when peBreadcrumbStyle is Drop Down
        this._eMask = null; // mask element shown behind the dropdown menu
        this._aItems = []; // array of handles for each breadcrumb item wrapper <li> element
        this._bRedraw = false;
        this._bDropDownExpanded = false; // tracks whether the drop down breadcrumb is shown or hidden
        this._tHideTimeout = null; // handle to a timeout object that is used to hide the dropdown breadcrumb list

        this._bWrapDiv = true; // generate a wrapper <div>
        this._sControlClass = "WebBreadcrumb"; // CSS Class
    }
    /*
    This method generates the wrapping HTML of the breadcrumb.
    
    @param  aHtml   Stringbuilder array to which the HTML can be added.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
            aHtml.push('<div class="WebCrumbs_Body WebCrumbs_Horiz" tabindex="-1">');
        }
        else {
            aHtml.push('<div class="WebCrumbs_Body WebCrumbs_DropDown" tabindex="-1">');
        }
    }

    /*
    This method generates the HTML that closes the wrapping elements of the breadcrumb.
    
    @param  aHtml   Stringbuilder array to which the HTML can be added.
    @private
    */
    closeHtml(aHtml) {
        aHtml.push('</div>');
        super.closeHtml(aHtml);
    }

    /*
    This method gathers references to the HTML elements and attaches DOM listeners.
    
    @private
    */
    afterRender() {
        //  Get references
        this._eControl = df.dom.query(this._eElem, 'div.WebCrumbs_Body');

        super.afterRender();

        //  Attach event listeners
        df.dom.on("click", this._eControl, this.onBodyClick, this);

        //  Render the initial list
        this.redraw();
    }

    // - - - - - - - - - - - - - - - - - - - - - - -
    // Property Setters & Getters- - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - -

    // peBreadcrumbStyle

    set_peBreadcrumbStyle(eVal) {
        if (this._eControl) {
            if (this.peBreadcrumbStyle !== eVal) {
                this.peBreadcrumbStyle = eVal;
                this.redraw();
            }
        }
    }


    // - - - - - - - - - - - - - - 
    // Public API- - - - - - - - -
    // - - - - - - - - - - - - - - 

    /*
    This method refreshes the breadcrumb with the items encoded in the action data. The action data is a 
    two dimensional array that is used for sending 'complex data' with client actions.
    
    @client-action
    */
    refresh() {
        const aItems = this._tActionData;

        this.clear();  //  Clear current breadcrumb

        for (let i = 0; i < aItems.length; i++) {
            //  append
            this.append(aItems[i]);
        }

        //  Redraw
        this.redraw();
    }

    // - - - - - - - - - - - - - - - 
    // Events- - - - - - - - - - - - 
    // - - - - - - - - - - - - - - - 

    /*
    This method handles the onclick event of the body. It first determines which item is clicked 
    then makes a server call to navigate to the selected item.
    
    @param  oEvent  The event object (see: df.events.DOMEvent).
    @private
    */
    onBodyClick(oEvent) {
        let sViewName = "", eElem = oEvent.getTarget(), bStop = false, bDropDown = false;

        if (this.isEnabled()) {
            // if necessary, cancel the timeout that is intended to hide the dropdown
            if (this._tHideTimeout) {
                clearTimeout(this._tHideTimeout);
                this._tHideTimeout = null;
            }

            // Bubble up in the DOM finding the Node ID and checking if text or tree is clicked
            while (eElem && !bStop && eElem !== this._eElem) {

                // be careful! indexOf will successed to find a class that is
                // a superset of the name we are searching for (e.g. "WebCrumb_ItemHeader")
                // This would caue an infinite loop
                if (eElem.className.indexOf("WebCrumb_Item") >= 0) {
                    // list item <li> (all but the last list item)
                    sViewName = eElem.getAttribute("data-dfview-name");

                    if (sViewName) {
                        this.doSelect(sViewName);
                    }

                    bStop = true;
                }
                else if (eElem.className.indexOf("WebCrumb_DropDownBtn") >= 0) {
                    // Drop down button click
                    this.showDropDown();
                    bDropDown = true;
                    bStop = true;
                }
                else {
                    // Bubble up            
                    eElem = eElem.parentNode;
                }
            }

            // Test if we need to hide the drop down breadcrumb
            if (this._bDropDownExpanded && !bDropDown) {
                this.hideDropDown();
            }

            if (bStop) {
                oEvent.stop();
            }
        }
    }


    /*
    We will test if the DropDown needs to be hidden
    */
    onBlur(oEvent) {
        const that = this;

        super.onBlur(oEvent);

        if (this._bDropDownExpanded) {
            // Create a timer event to hide the dropdown. This ensures that
            // the drop-down element's OnClick event will fire if it is pending.        
            if (this._tHideTimeout) {
                clearTimeout(this._tHideTimeout);
            }
            this._tHideTimeout = setTimeout(function () {
                that._tHideTimeout = null;
                that.hideDropDown();
            }, 150);
        }
    }

    /* 
    Handles the click event of the mask shown behind the dropdown style breadcrumb. It hides the 
    dropdown immediately.
    
    @param  oEvent  Event object (see df.events.DOMEvent).
    */
    onMaskTouch(oEvent) {
        this.hideDropDown();
        oEvent.stop();
    }

    /*
    This method will select the view that is passed. Called by OnClick
    
    @param  sViewName - object name of the view
    */
    doSelect(sViewName) {
        // We send serverAction directly instead of going through the full this.fire interface.
        // The server call is not optional so we can bypass the need for the pbServerOnSelect and
        // psClientOnSelect interface
        this.serverAction("OnSelect", [sViewName]);
    }



    // - - - - - - - - - - - - - - - - - - - - - - - -
    // Drop Down Handler for Drop Down breadcrumb
    // - - - - - - - - - - - - - - - - - - - - - - - -

    /* 
    Displays the Drop Down Breadcrumb
    */
    showDropDown() {
        // Only drop down if there are 2 or more items in the list
        if (this._eList && this._aItems.length > 1) {
            df.dom.addClass(this._eList, "WebCrumbs_Expanded");
            this._bDropDownExpanded = true;

            if (df.sys.isMobile) {
                this._eMask = df.dom.create('<div class="WebMenu_Mask">&nbsp;</div>');

                this._eElem.insertBefore(this._eMask, this._eElem.firstChild);
                df.dom.on("click", this._eMask, this.onMaskTouch, this);
            }

        }
    }

    /* 
    Hides the Drop Down Breadcrumb
    */
    hideDropDown() {
        if (this._eList) {
            df.dom.removeClass(this._eList, "WebCrumbs_Expanded");
            this._bDropDownExpanded = false;

            if (this._eMask) {
                df.dom.off("click", this._eMask, this.onMaskTouch, this);
                this._eMask.parentNode.removeChild(this._eMask);
                this._eMask = null;
            }

        }
    }




    // - - - - - - - - - - - - - - - - - - - - - - - - 
    // resize handler methods for horizontal breadcrumb
    // - - - - - - - - - - - - - - - - - - - - - - - - 

    /*
    Handle truncating the horizontal breadcrumb.
    
    Params:
        oEvent  The event object which fired this function.
    */
    resize(oEvent) {

        // Only dynamically resize items for horizontal breadcrumb    
        if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
            if (this._eList && this._eList.hasChildNodes()) {
                const aElements = df.dom.query(this._eList, "li div.WebCrumb_Caption", true);
                this.resetWidths(aElements);
                this.adjustWidths();
            }
        }
    }


    /* private: This method resets (clears) the inline width style of all 
    <div class="WebCrumb_Caption"> elements to auto.
    The set of elements is passed in the aDivs parameter 
    */
    resetWidths(aDivs) {
        for (let i = 0; i < aDivs.length; i++) {
            aDivs[i].style.width = "auto";
            aDivs[i].removeAttribute("title");   // remove the tooltip
        }
    }


    /* Helper function:
    This method returns the total offsetWidth of the passed array of elements.
    */
    sumElementWidths(aElements) {
        let iSumWidth = 0;

        // iterate the child elements
        for (let i = 0; i < aElements.length; i++) {
            iSumWidth = iSumWidth + aElements[i].offsetWidth;
        }

        return iSumWidth;
    }


    /*
    Private: This method is used for truncating horizontal list items when there is overflow.
    It is designed to reduce the width of the passed li elements evenly until either:
    1. The sum of the passed element widths is less or equal to the passed target width, or
    2. All of the passed li elements have hit their minimum width of 20px.
    
    returns 0 if the target width was reached, otherwise it returns the number of remaining pixels
    to reach the target width.
    */
    reduceWidthsToTarget_li(aListItems, iTargetWidth) {
        let eDiv = null,
            iWidth, iRemainder = 0,
            sWidth;

        if (aListItems.length === 0) {
            return 0;
        }

        // pass 1: get the expected reduction per item, try to set the width to that
        // reduced value. If some items could not be fully reduced (already at minimum)
        // then we will calculate how much extra width remains.
        const iSumWidth = this.sumElementWidths(aListItems);
        const iDiffTotal = iSumWidth - iTargetWidth;

        if (iDiffTotal <= 0) {
            return 0;    // nothing to do (should not happen)
        }

        const iDiffPerItem = Math.ceil(iDiffTotal / aListItems.length);

        // iterate the <li> elements
        for (let i = 0; i < aListItems.length; i++) {
            // get the inner <div class="WebCrumb_Caption">
            eDiv = df.dom.query(aListItems[i], "div.WebCrumb_Caption", false);

            iWidth = eDiv.offsetWidth - iDiffPerItem;    // get the width we want (including padding & border)
            iWidth = iWidth - df.sys.gui.getHorizBoxDiff(eDiv, 0);  // subtract the padding & border

            if (iWidth < 15) {
                eDiv.style.width = "15px";
                iRemainder = iRemainder + 15 - iWidth;
            }
            else {
                sWidth = iWidth.toString() + "px";
                eDiv.style.width = sWidth;
            }

            // give the div a tooltip
            const sTip = df.dom.getText(eDiv);
            if (sTip) {
                eDiv.setAttribute("title", sTip);
            }
        }

        // pass 2: try to get rid of the remainder
        for (let i = 0; i < aListItems.length && iRemainder > 0; i++) {
            // get the inner <div class="WebCrumb_Caption">
            eDiv = df.dom.query(aListItems[i], "div.WebCrumb_Caption", false);

            if (eDiv.offsetWidth > 15) {
                iRemainder = iRemainder + 15 - eDiv.offsetWidth;
                eDiv.style.width = "15px";
            }
        }

        // if there is still any remainder then that value
        if (iRemainder > 0) {
            return iRemainder;
        }
        return 0;
    }


    /*
    This method tests that the width of the control does not exceed the available space.
    If it is too wide then we will trim back the number of characters in each caption
    until it does fit or the caption is empty.
    */
    adjustWidths() {
        let iTarget, iRemainder, aListItems;

        if (this._eList && this._eList.hasChildNodes()) {
            // compare the current ul element width with the total width of the child li elements...
            const iSumChildWidths = this.sumElementWidths(df.dom.query(this._eList, "li", true));

            if (this._eList.clientWidth < iSumChildWidths) {
                // first we will try to trim the widths of all but the last 
                // list item <li> element
                aListItems = this._eList.getElementsByClassName("WebCrumb_Item");

                if (aListItems.length > 0) {
                    iTarget = this._eList.clientWidth - this._eList.lastChild.offsetWidth;
                    iRemainder = this.reduceWidthsToTarget_li(aListItems, iTarget);
                }
                else {
                    iRemainder = this._eList.lastChild.offsetWidth - this._eList.clientWidth;
                }

                // If there is any remaining width then we will take it out of the
                // last (current) list item
                if (iRemainder > 0) {
                    aListItems = this._eList.getElementsByClassName("WebCurrentCrumb");
                    iTarget = this._eList.lastChild.offsetWidth - iRemainder - 2;
                    iRemainder = this.reduceWidthsToTarget_li(aListItems, iTarget);
                }
            }
        }
    }


    // - - - - - - - - - - - - - - - -
    // DOM Creation Methods- - - - - -
    // - - - - - - - - - - - - - - - -

    /*
    The item will be appended the breadcrumb based on its settings. The display won't be updated so 
    the refresh method should be called.
    
    @param  tItem
    */
    append(tItem) {
        this._aItems.push(tItem);
    }

    /*
    All the items will be removed from the breadcrumb. The display is updated.
    */
    clear() {
        if (this._eList) {
            this._eList.innerHTML = "";        // remove the <li> list
        }
        else {
            if (this._eControl) {
                this._eList = this.constructList();       // create the list <ul> element
                this._eControl.appendChild(this._eList);  // add it to the DOM
            }
        }

        this._aItems = [];
    }

    /*
    Updates the display based on the internal items. Newly inserted items
    will be displayed correctly.
    */
    redraw() {
        const aItems = this._aItems, aHtml = [];

        if (this._eControl) {
            this._bRedraw = true;

            // Hide the horizontal breadcrumb if it only has 0 or 1 items
            //        if (this.peBreadcrumbStyle == df.cCrumbHorizontal && aItems.length < 2) {
            //            df.dom.addClass(this._eControl, "WebCrumbs_Hide");
            //        }
            //        else {
            //            df.dom.removeClass(this._eControl, "WebCrumbs_Hide");
            //        }

            // Set the Breadcrumb Style CSS class
            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                df.dom.removeClass(this._eControl, "WebCrumbs_DropDown");
                df.dom.addClass(this._eControl, "WebCrumbs_Horiz");
            } else {
                df.dom.removeClass(this._eControl, "WebCrumbs_Horiz");
                df.dom.addClass(this._eControl, "WebCrumbs_DropDown");
            }

            // If drop down then create a caption div otherwise remove it
            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                if (this._eCaption) {
                    // destroy the caption div
                    this._eControl.removeChild(this._eCaption);
                    this._eCaption = null;
                }
            }
            // if peBreadcrumbStyle = df.cCrumbCaption or df.cCrumbDropDown
            else {
                if (!this._eCaption) {
                    // create the caption div
                    const eDiv = document.createElement("div");
                    df.dom.addClass(eDiv, "WebCrumb_Caption");

                    this._eControl.appendChild(eDiv);  // add it to the DOM
                    this._eCaption = eDiv;             // save a reference                
                }

                // update the caption with the current view's name
                if (aItems.length) {
                    if (aItems[aItems.length - 1].sHeadCaption.trim() === "") {
                        // do not allow "" caption
                        aHtml.push("&nbsp;");
                    }
                    else {
                        const sCaption = aItems[aItems.length - 1].sHeadCaption.trim();  // the arrow CSS is sensitive to trailing spaces!
                        aHtml.push(df.dom.encodeHtml(sCaption));
                    }

                    this._eCaption.innerHTML = aHtml.join("");
                }
                else {
                    this._eCaption.innerHTML = '&nbsp;';
                }

                // if there is a list of more than one item then show the dropdown button
                if (aItems.length > 1 && this.peBreadcrumbStyle === df.cCrumbDropDown) {
                    df.dom.addClass(this._eCaption, "WebCrumb_DropDownBtn");
                }
                else {
                    df.dom.removeClass(this._eCaption, "WebCrumb_DropDownBtn");
                }
            }

            // Create or Reset the list
            if (this._eList) {
                this._eList.innerHTML = "";        // remove the <li> list
            }
            else if (this.peBreadcrumbStyle !== df.cCrumbCaption) {
                this._eList = this.constructList();       // create the list <ul> element
                this._eControl.appendChild(this._eList);  // add the list to the DOM 
            }

            if (this.peBreadcrumbStyle !== df.cCrumbCaption) {
                this.constructItems(aItems);        // create the <li> list item elements
            }

            this._bRedraw = false;
        }
    }

    /*
    Constructs a list element <ul>.
    
    @private
    */
    constructList() {
        const eList = document.createElement("ul");
        eList.setAttribute("class", "WebCrumbs");

        return eList;
    }

    /*
    Generates the DOM elements for the given list of nodes on the given table.
    
    @param  aNodes  Array with nodes.
    @param  eTable  Table element.
    @private
    */
    constructItems(aItems) {
        let bCurrent = false, sLine = "";
        const aHtml = [];

        // - - - breadcrumb list - - -
        // <li><div><div>Caption 1<div></div></li>
        // <li><div><div>Caption 2<div></div></li>
        //
        // build the list item <li> elements as a stringlist.

        // If there are no items than build a dummy one
        if (aItems.length === 0) {
            aHtml.push('<li class="WebCurrentCrumb">');

            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                aHtml.push('<div tabindex="-1">');
            }

            aHtml.push('<div class="WebCrumb_Caption" tabindex="-1">');
            aHtml.push("&nbsp;");
            aHtml.push('</div>');

            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                // close the arrow div
                aHtml.push('</div>');
            }
            aHtml.push('</li>');
        }

        for (let iItem = 0; iItem < aItems.length; iItem++) {
            if (iItem === aItems.length - 1) {
                bCurrent = true;   // bCurrent is true for the last <li> element
            }

            if (bCurrent) {
                sLine = '<li class="WebCurrentCrumb"';
            }
            else {
                // All items except the current one will have this class.
                // Among other things, this determines whether the item will 
                // process a mouse click. This class name must not be used by 
                // any non list item <li> elements because we search for it 
                // while bubbling up in the onClick handler
                sLine = '<li class="WebCrumb_Item"';
            }

            // store the view name (for future reference)
            sLine = sLine + ' data-dfview-name="' + aItems[iItem].sViewName + '">';

            // assemble <li> & inner <div><div>
            aHtml.push(sLine);

            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                // build the arrow for horizontal breadcrumbs
                if (bCurrent) {
                    aHtml.push('<div tabindex="-1">');
                }
                else {
                    aHtml.push('<div class="WebCrumb_Arrow" tabindex="-1">');
                }
            }

            // build the caption
            aHtml.push('<div class="WebCrumb_Caption" tabindex="-1">');

            if (aItems[iItem].sCrumbCaption.trim() === "") {
                // do not allow "" caption
                aHtml.push("&nbsp;");
            }
            else {
                aHtml.push(df.dom.encodeHtml(aItems[iItem].sCrumbCaption)); // the crumb's caption
            }
            aHtml.push('</div>');

            if (this.peBreadcrumbStyle === df.cCrumbHorizontal) {
                // close the arrow div
                aHtml.push('</div>');
            }

            aHtml.push('</li>');
        }
        // insert the list item <li> elements
        this._eList.innerHTML = aHtml.join("");
    }
}