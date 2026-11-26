import { WebDragDrop_Mixin } from './dragdrop/WebDragDropMixin.js';
import { WebObject } from './WebObject.js';
import { df } from '../df.js';
/*
Class:
    df.WebBaseUIObject
Extends:
    df.WebObject

The WebBaseUIObject is a central class in the inheritance structure of the webapp framework. It 
defines the interface/API for all objects having a user interface. All control classes inherit this 
interface. There is a standardized API for initializing the control by generating the HTML and later 
on attaching the events. Central methods are openHtml, closeHtml, render and afterRender. Properties 
that are standard for all controls are psCSSClass, psHtmlId, pbVisible, pbRender and pbEnabled.
    
Revision:
    2011/07/02  (HW, DAW) 
        Initial version.
*/

// Inherit DragDrop functionality
const WebBaseUIObjectBase = class WebBaseUIObject extends WebDragDrop_Mixin(WebObject) { }

export class WebBaseUIObject extends WebBaseUIObjectBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Public properties for all UI Objects
        this.prop(df.tString, "psCSSClass", "");
        this.prop(df.tString, "psHtmlId", "");

        this.prop(df.tString, "psTextColor", "");
        this.prop(df.tString, "psBackgroundColor", "");

        this.prop(df.tBool, "pbRender", true);
        this.prop(df.tBool, "pbVisible", true);
        this.prop(df.tBool, "pbEnabled", true);

        this.event("OnRender", df.cCallModeDefault);

        this.OnAfterRender = new df.events.JSHandler();
        this.OnAfterShow = new df.events.JSHandler();
        this.OnAfterHide = new df.events.JSHandler();

        //@privates
        this._eElem = null; //  Outermost DOM element

        this._bWrapDiv = false; //  Enables generation of the wrapping DIV element
        this._bRenderChildren = false; //  Enables rendering of child components (some controls support children)

        this._bFocusAble = false; //  Determines if this control is capable of having the focus

        this._sControlClass = ""; //  CSS Class of the final control class
        this._sBaseClass = "WebUIObj"; //  CSS Class of the 'base' class

        this._aKeyHandlers = [];

        this._bShown = false;

    }

    // - - - - - - - Rendering API - - - - - - -

    /*
    This function is responsible for generating the opening HTML during initialization. It is called by 
    the framework and an array is passed as string builder. It will add its HTML to this string. The 
    closeHtml function is responsible for closing the opened HTML tags. It is common practice that sub 
    classes add their HTML before or after doing a forward send.
    
    @param aHtml     Array that is used as string builder.
    */
    openHtml(aHtml) {
        if (this._bWrapDiv) {
            aHtml.push('<div class="', this.genClass(), '"');
            if (this.psHtmlId) {
                aHtml.push(' id="', this.psHtmlId, '"');
            }

            //  Insert the object name so the HTML element can be traced back to the right object
            aHtml.push(' data-dfobj="', this.getLongName(), '"');

            aHtml.push(' tabindex="-1" style=" ', (this.pbRender ? '' : 'display: none;'), (this.pbVisible ? '' : 'visibility: hidden;'), '"');
            aHtml.push('>');
        }

    }

    /*
    This function is responsible for generating the HTML that closes the elements that are left open by 
    the openHtml function. It is common practice that sub classes add their HTML before or after doing a 
    forward send.
    
    @param aHtml     Array that is used as string builder.
    */
    closeHtml(aHtml) {
        if (this._bWrapDiv) {
            aHtml.push('</div>');
        }
    }

    /*
    Main function of the rendering process. It calls openHtml, closeHtml and genets the DOM elements for 
    them. If needed it will call renderChildren to render nested controls.
    
    @return Reference to the outermost DOM element.
    */
    render() {
        const aHtml = [];

        this.openHtml(aHtml);
        this.closeHtml(aHtml);

        this._eElem = df.dom.create(aHtml.join(""));

        this.getRef();

        if (this._bRenderChildren) {
            this.renderChildren();
        }

        return this._eElem;
    }

    /* 
    This function is part of the rendering process and is called after the DOM elements are created and 
    before the child elements are rendering itself. Its purpose is to get references to DOM elements 
    without nesting issues.
    */
    getRef() {

    }

    /*
    This function is part of the initialization process and is called after the DOM elements are 
    created. Its main purpose is to get the needed references to the DOM elements, attach focus events 
    and do further initialization (call setters for example). Most of the subclasses will augment this 
    method for their initialization. If needed it calls the afterRenderChildren method to initialize 
    nested controls.
    */
    afterRender() {
        if (this._bRenderChildren) {
            this.afterRenderChildren();
        }

        //  Add key listener if handlers are registered
        if (this._aKeyHandlers.length > 0) {
            df.dom.on("keydown", this._eElem, this.onKeyDownHandler, this);
        }

        this.fire("OnRender");

        this.attachFocusEvents();

        //  Apply properties
        this.set_psTextColor(this.psTextColor);
        if (this.psBackgroundColor) {
            this.set_psBackgroundColor(this.psBackgroundColor);
        }

        this.dragDropInit();

        this.OnAfterRender.fire(this);
    }

    /* 
    Destroy the DOM elements and remove all DOM Event handlers to prevent memory leaks.
    
    @private
    */
    destroy() {
        super.destroy();

        if (this._eElem) {
            df.dom.clear(this._eElem, true);
            if (this._eElem.parentNode) {
                this._eElem.parentNode.removeChild(this._eElem);
            }
        }
        this._eElem = null;
    }


    /*
    This function is called after this control is shown. It recursively calls its children if 
    _bRenderChildren is true. It is triggered by the webapp, views, card container and the pbRender 
    setter. It is meant to be augmented by controls when they need to execute special code when this 
    happens.
    */
    afterShow() {
        this._bShown = true;
        this.OnAfterShow.fire(this);

        if (this._bRenderChildren) {
            for (let i = 0; i < this._aChildren.length; i++) {
                if (this._aChildren[i] instanceof WebBaseUIObject && this._aChildren[i].pbRender) {
                    this._aChildren[i].afterShow();
                }
            }
        }
    }

    /*
    This function is called after this control is hidden. It recursively calls its children if 
    _bRenderChildren is true. It is triggered by the webapp, views, card container and the pbRender 
    setter. It is meant to be augmented by controls when they need to execute special code when this 
    happens.
    */
    afterHide() {

        this._bShown = false;
        this.OnAfterHide.fire(this);

        if (this._bRenderChildren) {
            for (let i = 0; i < this._aChildren.length; i++) {
                if (this._aChildren[i] instanceof WebBaseUIObject && this._aChildren[i].pbRender) {
                    this._aChildren[i].afterHide();
                }
            }
        }
    }


    attachFocusEvents() {

    }

    renderChildren(eContainer) {
        eContainer = eContainer || this._eElem;

        //  Call children and append them to ourselves
        for (let i = 0; i < this._aChildren.length; i++) {
            const oChild = this._aChildren[i];

            //  Check if we can actually render the object
            if (oChild instanceof WebBaseUIObject) {
                const eChild = oChild.render();

                if (eChild) {
                    eContainer.appendChild(eChild);
                }
            }
        }

    }

    afterRenderChildren() {
        //  Call children
        for (let i = 0; i < this._aChildren.length; i++) {
            if (this._aChildren[i] instanceof WebBaseUIObject) {
                this._aChildren[i].afterRender();
            }
        }
    }

    /* 
    Determines if the UI object is active which means that it is visible and enabled. The previewer will 
    override this function to enable functionality inside the previewer.  
    
    @return True if the UI object is active.
    @private
    */
    isActive() {
        return this.pbRender && this.pbVisible && this.isEnabled();
    }

    /* 
    Determines if the UI Object is enabled. As controls inside disabled containers should disable as 
    well it also looks at the enabled state of the parents. 
    
    @return True if the control is enabled.
    */
    isEnabled() {
        if (!this.pbEnabled) {
            return false;
        } else if (this._oParent instanceof WebBaseUIObject) {
            return this._oParent.isEnabled();
        }

        return true;
    }

    /* 
    Updates the enabled state of the control. It makes sure the right enabled state is applied and it 
    notifies child controls to update their enabled state.
    */
    updateEnabled() {

        this.applyEnabled(this.isEnabled());

        if (this._bRenderChildren) {
            for (let i = 0; i < this._aChildren.length; i++) {
                if (this._aChildren[i] instanceof WebBaseUIObject) {
                    this._aChildren[i].updateEnabled();
                }
            }
        }
    }

    /* 
    Applies the current enabled state by setting / removing the "Web_Enabled" and "Web_Disabled" CSS 
    classes. Subclasses will augment this function to properly disable the specific controls.
    
    @param  bVal    The enabled state.
    */
    applyEnabled(bVal) {
        // df.debug("applyEnabled called on: (" + df.sys.ref.getConstructorName(this) + ") " + this.getLongName());
        if (this._eElem) {
            df.dom.toggleClass(this._eElem, df.CssDisabled, !bVal);
            df.dom.toggleClass(this._eElem, df.CssEnabled, bVal);
        }
    }

    /*
    This method generates the CSS classname that is applied to the outermost DOM element of this 
    control. It combines _sBaseClass, _sControlClass, psCSSClass and pbEnabled. Subclasses that want to 
    add more CSS classes will augment this method. It is called during initialization and when the 
    psCSSClass is set.
    
    Note: Changes made here should also be made in WebAppPreviewer.js!
    
    @return String containing the CSS Classes.
    @private
    */
    genClass() {
        return this._sBaseClass + " " + this._sControlClass + " " + (this.isEnabled() ? df.CssEnabled : df.CssDisabled) + (this.psCSSClass ? " " + this.psCSSClass : "");
    }

    // - - - - - - - Setters & Getters - - - - - - -

    set_psTextColor(sVal) {
        if (this._eElem) {
            this._eElem.style.color = sVal || '';
        }
    }

    set_psBackgroundColor(sVal) {
        if (this._eElem) {
            this._eElem.style.background = sVal || '';
        }
    }

    set_pbVisible(bVal) {
        if (this._eElem) {
            this._eElem.style.visibility = (bVal ? '' : 'hidden');
        }
    }

    set_pbRender(bVal) {
        if (this._eElem) {
            this._eElem.style.display = (bVal ? '' : 'none');

            if (this.pbRender !== bVal) {
                this.pbRender = bVal;

                //  Trigger after hide / show
                if (this.pbRender) {
                    this.afterShow();
                } else {
                    this.afterHide();
                }

                //  The parent panel to recalculate its sizes
                this.sizeChanged(true);
            }
        }
    }

    /* 
    Setter of pbEnabled which updates the enabled state (only if it actually changed).
    
    @param  bVal    New value.
    */
    set_pbEnabled(bVal) {
        if (bVal !== this.pbEnabled) {
            this.pbEnabled = bVal;

            this.updateEnabled();
        }
    }

    set_psCSSClass(sVal) {
        this.psCSSClass = sVal;

        if (this._eElem) {
            this._eElem.className = this.genClass();
        }
    }

    set_psHtmlId(sVal) {
        if (this._eElem) {
            this._eElem.id = sVal;
        }
    }

    // - - - - - - - Supportive - - - - - - -

    /* 
    Registers a key handler for the provided key combination. The key handlers are stored in an array 
    and are accessed when a key event occurs. An array of messages that need to be triggered on the 
    server is stored with the key information.
    
    @param  sServerMsg  String message name of server-side handler message.
    @param  iKeyCode    Integer key code (event.keyCode).
    @param  bShift      Idicates if shift needs to be pressed.
    @param  bAlt        Indicates if alt needs to be pressed.
    @param  bCtrl       Indicates if ctrl needs to be pressed.
    
    @client-action
    */
    addKeyHandler(sServerMsg, iKeyCode, bShift, bAlt, bCtrl) {

        //  Convert to JS type
        iKeyCode = df.toInt(iKeyCode);
        bShift = df.toBool(bShift);
        bAlt = df.toBool(bAlt);
        bCtrl = df.toBool(bCtrl);

        //  Check if no key handler is defined for this key
        const oKH = this.findKeyHandler(iKeyCode, bShift, bAlt, bCtrl);

        if (oKH) {
            //  Add to existing handler if message isn't already registered
            for (let i = 0; i < oKH.aMsg.length; i++) {
                if (oKH.aMsg[i] === sServerMsg) {
                    return;
                }
            }

            oKH.aMsg.push(sServerMsg);
        } else {
            //  Add key handler if not already added
            if (this._aKeyHandlers.length === 0 && this._eElem) {
                df.dom.on("keydown", this._eElem, this.onKeyDownHandler, this);
            }

            //  Register new key handler
            this._aKeyHandlers.push({
                iKey: iKeyCode,
                aMsg: [sServerMsg],
                bShift: bShift,
                bAlt: bAlt,
                bCtrl: bCtrl
            });
        }
    }

    /* 
    Removes a registered key handler based on the details used when it is added. 
    
    @param  sServerMsg  String message name of server-side handler message.
    @param  iKeyCode    Integer key code (event.keyCode).
    @param  bShift      Idicates if shift needs to be pressed.
    @param  bAlt        Indicates if alt needs to be pressed.
    @param  bCtrl       Indicates if ctrl needs to be pressed.
    
    @client-action
    */
    removeKeyHandler(sServerMsg, iKeyCode, bShift, bAlt, bCtrl) {

        //  Convert to JS types
        iKeyCode = df.toInt(iKeyCode);
        bShift = df.toBool(bShift);
        bAlt = df.toBool(bAlt);
        bCtrl = df.toBool(bCtrl);

        //  Search key handler
        const oKH = this.findKeyHandler(iKeyCode, bShift, bAlt, bCtrl);

        if (oKH) {
            //  Remove message
            for (let i = 0; i < oKH.aMsg.length; i++) {
                if (oKH.aMsg[i] === sServerMsg) {
                    oKH.aMsg.splice(i, 1);
                    i--;
                }
            }

            //  Remove entire handler no more messages
            if (!oKH.aMsg.length) {
                this._aKeyHandlers.slice(oKH.iIndex, 1);
            }
        }

        //  Remove DOM handler if no more handlers
        if (this._aKeyHandlers.length === 0 && this._eElem) {
            df.dom.off("keydown", this._eElem, this.onKeyDownHandler, this);
        }
    }

    /* 
    Searches the array of key handlers for a specific key and returns the handler object. It adds an 
    extra property iIndex to the object that contains the array index of the key handler.
    
    @param  iKeyCode    Integer key code (event.keyCode).
    @param  bShift      Idicates if shift needs to be pressed.
    @param  bAlt        Indicates if alt needs to be pressed.
    @param  bCtrl       Indicates if ctrl needs to be pressed.
    
    @return Key handler object (null if none found).
    @private
    */
    findKeyHandler(iKeyCode, bShift, bAlt, bCtrl, iIndexOut) {

        //  Loop all handlers to find specific handler
        for (let i = 0; i < this._aKeyHandlers.length; i++) {
            const oH = this._aKeyHandlers[i];

            if (oH.iKey === iKeyCode && oH.bShift === bShift && oH.bAlt === bAlt && oH.bCtrl === bCtrl) {
                oH.iIndex = i;

                return oH;
            }
        }

        return null;
    }

    /* 
    Event handler for the onkey event. It searches for a key handler and if found it triggers the server 
    actions that belong to it. 
    
    @param  oEvent  Event object.
    */
    onKeyDownHandler(oEvent) {

        //  Search handler
        const oKH = this.findKeyHandler(oEvent.getKeyCode(), oEvent.getShiftKey(), oEvent.getAltKey(), oEvent.getCtrlKey());

        if (oKH) {
            // Trigger validate on the focussed object before triggering the key handler (if this is a
            // different object than the focussed object). Validate will fire OnChange and autofind if
            // nessecary. This prevents those events from triggering after a view change that this key 
            // action could trigger.
            if (this.getWebApp()._oCurrentObj && this.getWebApp()._oCurrentObj != this && this.getWebApp()._oCurrentObj.validate) {
                this.getWebApp()._oCurrentObj.validate();
            }

            //  Perform server actions if found
            for (let i = 0; i < oKH.aMsg.length; i++) {
                this.serverAction(oKH.aMsg[i], [oKH.iKey, df.fromBool(oKH.bShift), df.fromBool(oKH.bAlt), df.fromBool(oKH.bCtrl)]);
            }
            oEvent.stop();
        }
    }

    /*
    This method is called by the server to pass the focus to this control.
    
    @client-action
    */
    svrFocus() {
        const oW = this.getWebApp();
        if (oW) {
            oW.ready(()=>{
                this.focus();
            }, this);
        }else{
            this.focus();
        }
    }

    updateFocus(bFocus) {
        if (bFocus) {
            this.objFocus();
        } else {
            this.getWebApp()?.objBlur(this);
        }
    }

    onFocus(oEvent) {
        this.updateFocus(true);
    }

    onBlur(oEvent) {
        this.updateFocus(false);
    }

    /* 
    Registers this ui object as having the focus at the view and the webapp.
    
    @private
    */
    objFocus() {
        const oV = this.getView(), oW = this.getWebApp();
        if (oV) {
            oV.objFocus(this);
        }
        if (oW) {
            oW.objFocus(this);
        }
    }

    /* 
    Gives the focus to the control. It will give the focus to the DOM element. This function is 
    overridden in sub classes if a different element actually holds the focus.
    
    @return     True if the object successfully takes the focus (false if not enabled or focusable).
    @private
    */
    focus(bOptSelect) {
        if (this._bFocusAble && this.isEnabled() && this._eElem && this._eElem.focus) {
            this._eElem.focus();

            this.objFocus();
            return true;
        }

        return false;
    }

    /* 
    The conditionalFocus only really gives the focus to an element on desktop browsers where on mobile 
    browsers it only registers the object as having the focus without actually giving the focus to the 
    DOM. It is used when the framework itself passes the focus to a control to prevent the on-screen 
    keyboard from popping up.
    
    @param  bOptSelect      Select the text in forms if true.
    @return True if the focus is taken.
    */
    conditionalFocus(bOptSelect) {
        if (!df.sys.isMobile) {
            return this.focus(bOptSelect);
        }
        if (this._bFocusAble && this.isEnabled()) {
            this.objFocus();

            return true;
        }
        return false;
    }

    /*
    Scrolls the main element of this UI object into the view. Relies on the scrollIntoView of browsers.
    
    @param  bAlignToTop     Tries to align the top element to the top of the view.
    @client-action
    */
    scrollIntoView(bAlignToTop) {
        if (this._eElem) {
            this._eElem.scrollIntoView(df.toBool(bAlignToTop));
        }
    }

    /*
    This function passes the focus to the next control. The next control is the next focussable sibling. 
    If not available it will go to the parent and try to focus thats next focusable sibling. Note that 
    this can be different the regular tab order. Used by pbAutoTab of cWebForm.
    
    @param  bOptSelect  Select the text in forms if true.
    @return True if the focus is taken by a next control.
    */
    focusNext(bOptSelect) {
        let oC = this, oP;

        //  Go up in the structure untill we find a sibling that takes the focus
        while ((oP = oC._oParent)) {

            for (let i = oP._aChildren.indexOf(oC) + 1; i > 0 && i < oP._aChildren.length; i++) {
                if (oP._aChildren[i].focus(bOptSelect)) {
                    return true;
                }
            }
            oC = oP;
        }
    }

    /*
    This method is called by setters or by child controls when the size has changes which mean that 
    everything might need to resize. We try to resize from the parent down but if no parent is available 
    we start at this level.
    
    @param  bPosition   True if the column layout positioning is affected by the size change and needs 
                        recalculation.
    @private
    */
    sizeChanged(bPosition) {
        const oWebApp = this.getWebApp();
        let oObj = this;

        if (bPosition) {
            //  Set switch to trigger a position resize
            if (this._oParent && this._oParent._bIsContainer) {
                this._oParent._bPositionChanged = true;
            }
            if (this._bIsContainer) {
                this._bPositionChanged = true;
            }
        }

        if (oWebApp) {
            oWebApp.objSizeChanged(this);
            oWebApp.notifyLayoutChange(this);
        } else {
            //  Find view or webapp (we always want to start a resize there)
            while (oObj._oParent && !(oObj._bIsView || oObj._bIsBaseApp)) {
                oObj = oObj._oParent;
            }

            if (oObj && oObj.resize) {
                oObj.resize();
            }
        }
    }

    fireSubmit() {
        return (this._oParent && this._oParent.fireSubmit && this._oParent.fireSubmit());
    }


    /* 
    Makes sure that the control is visible by going up in the object structure looking for controls 
    that can hide the current control (like WebCards / WebTabPages).
    
    @private
    */
    makeVisible() {
        this._oParent?.makeVisible?.();
    }

    /*
    This function returns a CSS selector for the given df.WebUIContext.
    
    Any contexthandler, using this function, is able to request the selector.
    The control can deduplicate the selector to make sure a change is reflected everywhere.
    
    @param eContext     A value repesented in df.WebUIContext
    
    @returns Either [null] if it is not a valid context for this control, or a string with the CSS selector.
    */
    determineSelectorForWebUIContext(eContext) {
        return null;
    }

    /*
    This function returns either to true or false to verify whether the element is valid.
    
    Some controls don't use any different css selectors. As such we have to verify it by a referenced object.
    For example this is the case in the treeView and the bFolder member.
    
    After the match is made we verify with this function whether it is a valid choice.
    Otherwise we simply cancel the contextOpen.
    
    @param eElem The supposed valid element.
    @param eContext The context it should be valid for.
    
    @returns Either true or false to make it a valid element.
    */
    verifyElementForWebUIContext(eElem, eContext) {
        return true;
    }

    /*
    This function retrieves the represented value from a WebUIContext.
    
    Any contexthandler, using this function, is able to request the data from an element given its df.WebUIContext.
    
    @param eElem        The element to get the context from.
    @param eContext     The context wished to retrieve from the passed element.
    
    @returns Either [null] if the element is not valid for the df.WebUIContext, any type of value.
    */
    retrieveValueFromWebUIContext(eElem, eContext) {
        return null;
    }

    // Drag drop

    getDropData(oDropZone, oPosition) {
        if (oDropZone && oDropZone._eDropElem) {
            const dropData = {
                data: (this.getControlValue && this.getControlValue()) || "",
                action: df.dropActions.WebTagsForm.ciDropOnControl
            }

            return dropData;
        }
        return null;
    }

    initDropZones() {
        if (this.isSupportedDropAction(df.dropActions.WebControl.ciDropOnControl)) {
            // mark entire elem as dropzone
            this.addDropZone(this._eElem);
        }
    }

    determineDropCandidate(oEv, aHelpers) {
        if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebControl.ciDropOnControl))) {
            return [this._eElem, df.dropActions.WebControl.ciDropOnControl];
        }

        return [null, null];
    }

    determineDropPosition(oEv, eElem) {
        // Returns df.dropPositions.ciDropOn, ciDropBefore or ciDropAfter
        return df.dropPositions.ciDropOn; // unknown
    }

    // We want to highlight the entire drop zone here, might have to change this a bit to make it more visible
    interactWithDropElem(dropZone, eElem) {
        dropZone.highlightElement();
    }

    // Should not be possible, but let's provide some default interaction just in case
    doEmptyInteraction(dropZone) {
        dropZone.highlightElement();

        return df.dropActions.WebTagsForm.ciDropOnControl;
    }

    // We simply always want to return true to control the drop so that there is never an empty interaction
    hasData() {
        return true;
    }

    /*
    Returns the 'top layer' element. This is the insertion point for controls like floating panels. 
    Usually this will return document.body, unless a control is located inside a modal dialog.
    */
    topLayer() {
        return this._oParent?.topLayer?.() || null;
    }

    /**
     * Determines the layout type for this container. If peLayoutType is set to ltInherit it will look at 
     * its parent container.
     * 
     * @returns The layout type (constant df.layoutType).
     */
    layoutType() {
        return this._oParent?.layoutType?.() || df.layoutType.ciLayoutTypeFlow;
    }
}