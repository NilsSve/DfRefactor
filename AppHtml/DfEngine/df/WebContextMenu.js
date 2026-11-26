import { WebFloatingPanel } from './WebFloatingPanel.js';
import { WebMenuList } from './WebMenuList.js';
import { WebMenuItem } from './WebMenuItem.js';
import { WebMenuItemCheckbox } from './WebMenuItemCheckbox.js';
import { df } from '../df.js';
/*
Class:
    df.WebContextMenu
Extends:
    df.WebFloatingPanel

This class represents a context menu that comes in place of the default context menu.
It can be filled like any cWebMenuList/CommandBar and uses a floating panel underneath.
    
Revision:
    2021/10/13  (BN, DAW)
        Initial Version.
*/

export class WebContextMenu extends WebFloatingPanel {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "piMaxHeight", 500);

        this.prop(df.tString, "psControlName", "");
        this.prop(df.tString, "psContextCSSSelector", "");

        this.prop(df.tInt, "peContext", df.WebUIContext.WebUIContextCustom);
        this.prop(df.tString, "psContextValue", "");
        this.prop(df.tBool, "pbChildScopes", false);
        this.prop(df.tString, "psContextScopeName", "");

        // WebBaseMenu_Mixin.
        this.prop(df.tBool, "pbAllowHtml");
        this.prop(df.tString, "psGroupName");
        this.prop(df.tBool, "pbShowIcons", false);

        this.event("OnContextMenuOpen", df.cCallModeDefault, "privateOnContextMenuOpen");
        this.event("OnItemClick");

        // private FloatingPanel corrections.
        this.pePosition = df.fpFloatFixed;
        this.piWidth = 200;
        this.piHeight = -1;
        this.piColumnCount = 1;
        this.pbHideOnEscape = true;

        // make sure we are seen as a MenuProvider (though a proxy).
        this._bIsMenuProv = true;

        this._oRootControl = null; // Reference to the scope we are attached to.
        this._bRendered = false; // A check to see whether we are actually rendered or not.
        this._oMenu = null; // Is the handle to the generated cWebMenuList.
        this._oChildrenCache = []; // Nessesary cache for the proxying of webchildren.
    }

    set_psControlName(sControlName, bForceInit) {
        if (this.psControlName !== sControlName || bForceInit) {
            this.unbind();

            this.psControlName = sControlName;

            if (this.psControlName === "window") {
                this._oRootControl = { _eElem: document.documentElement };
            } else if (this.psControlName.length > 0) {
                this._oRootControl = this.getWebApp().findObj(this.psControlName);
            } else {
                this._oRootControl = this.getWebApp();
            }

            if (!this._oRootControl)
                throw new df.Error(999, "WebContextMenu could not find the Scope/Control.");

            this.bind();
        }
    }

    set_peContext(eContext) {
        if (this.peContext !== eContext) {
            this.unbind();

            this.peContext = eContext;

            this.bind();
        }
    }

    set_psContextCSSSelector(sContextCSSSelector) {
        // Only update if the peContext is set to custom.
        if (this.psContextCSSSelector !== sContextCSSSelector &&
            this.peContext === df.WebUIContext.WebUIContextCustom) {
            this.unbind();

            this.psContextCSSSelector = sContextCSSSelector;

            this.bind();
        }
    }

    ////////////////////////////////////////////////////////////////
    // cWebBaseMenu_Mixin Proxies //////////////////////////////////
    ////////////////////////////////////////////////////////////////

    set_pbShowIcons(bVal) {
        this._oMenu?.set_pbShowIcons(this.pbShowIcons = bVal);
    }

    set_psGroupName(sVal) {
        this._oMenu?.set_psGroupName(this.psGroupName = sVal);
    }

    set_pbAllowHtml(bVal) {
        this._oMenu?.set_pbAllowHtml(this.pbAllowHtml = bVal);
    }

    refresh() {
        if (this._oMenu) {
            this._oMenu._tActionData = this._tActionData;
            this._oMenu.refresh();
            this._oMenu._tActionData = null;
        }
    }

    updateItem(sId, bOverwriteSubs) {
        if (this._oMenu) {
            this._oMenu._tActionData = this._tActionData;
            this._oMenu.updateItem(sId, bOverwriteSubs);
            this._oMenu._tActionData = null;
        }
    }

    insertItem(sParentId) {
        if (this._oMenu) {
            this._oMenu._tActionData = this._tActionData;
            this._oMenu.insertItem(sParentId);
            this._oMenu._tActionData = null;
        }
    }

    removeItem(sId) {
        this._oMenu?.removeItem(sId);
    }

    notifyChange() {
        this._oMenu?.notifyChange();
    }

    // Clears the menu cache and rerenders it.
    refreshMenu() {
        if (this._oMenu) {
            this._oMenu._aMenu = null;
            this._oMenu.refreshMenu();
        }
    }

    collapseAll() {
        this._oMenu?.collapseAll();
    }

    // Interface by the cWebMenuList that makes the floating panel hide after a click inside.
    hideMenu() {
        df.events.removeDomCaptureListener("click", document, this.onClickGeneral, this);
        df.events.removeDomCaptureListener("contextmenu", document, this.hideMenu, this);
        this.hide();
    }

    ////////////////////////////////////////////////////////////////

    create() {
        // Set the psControlName to the default value.
        this.set_psControlName(this.psControlName, true);

        // Let's create our weblist.
        this._oMenu = new WebMenuList("MenuList", this);
        this._oMenu.objFocus = function () { // Please don't touch me!!!
            return;
        };
        this._oMenu._oMenuBtn = this;
        this._oMenu.pbShowCaption = false;
        this._oMenu.pbShowBackItem = true;
        this._oMenu.pbShowIcons = this.pbShowIcons;

        const that = this;
        this._oMenu.getMenuHeight = function (eElem) {
            let iHeight = df.dom.offsetHeight(eElem.firstChild);

            iHeight += df.sys.gui.getVertBoxDiff(eElem);

            return iHeight <= that.piMaxHeight ? iHeight : that.piMaxHeight;
        };

        // The behaviour of a menu click should be slightly altered.
        // After a click has been performed we should change the menu again to the root instead of keeping the current sublist.

        // Cache the original base function.
        this._fMenuBaseClick = this._oMenu.onMenuClick;
        this._oMenu.onMenuClick = function (oEvent) {
            that._fMenuBaseClick.apply(this, arguments);

            let tItem, eElem = oEvent.getTarget();

            if (!eElem) return;

            // Determine the clicked element by bubbling up the DOM structure
            while (!tItem && eElem && eElem !== this._eElem && eElem.hasAttribute) {
                if (eElem.hasAttribute("data-df-path")) {
                    tItem = this.getItemByPath(eElem.getAttribute("data-df-path"));
                    if (tItem && tItem.bEnabled && tItem.aChildren.length === 0) {
                        if (!(tItem.hRef instanceof WebMenuItemCheckbox)) {
                            this._oMenuBtn.hideMenu();
                        }

                        that.fire("OnItemClick", [tItem.sId, tItem.sCaption]);
                    }
                    return;
                }

                eElem = eElem.parentNode;
            }
        };

        this._oMenu._hContextMenu = this;

        this._oMenu.create();

        // Unload cache.
        while (this._oChildrenCache.length) {
            this._oMenu.addChild(this._oChildrenCache[0]);
            this._oChildrenCache.splice(0, 1);
        }

        super.addChild(this._oMenu);
        super.create();
    }

    privateStopEvent(oEv) {
        oEv.stop();
    }

    destroy() {
        if (this._bRendered) {
            df.dom.off("contextmenu", this._eElem, this.privateStopEvent, this);
        }
        this.unbind();
        super.destroy();
    }

    // Let's add the context menu class.
    genClass() {
        const aClasses = ["WebContextMenu", super.genClass()];
        return aClasses.join(" ");
    }

    afterRender() {
        this._bRendered = true;

        super.afterRender();

        df.dom.on("contextmenu", this._eElem, this.privateStopEvent, this);

        // Create a context menu for the desired object and create a null-handler for a right click on self.
        this.bind();
    }

    afterRenderChildren() {
        // Normally a child does not get an afterRender in a MenuList.
        // Some MenuItems like the WebMenuColumn* do need a ping on whether they might something.
        // We check a _bProviderRequestAfterRender to send an afterRender.
        super.afterRenderChildren();

        if (this._oMenu && this._oMenu._aChildren) {
            for (let i = 0; i < this._oMenu._aChildren.length; i++) {
                const oChild = this._oMenu._aChildren[i];

                //  Check if we can actually render the object
                if (oChild._bProviderRequestAfterRender) {
                    oChild.afterRender();
                }
            }
        }
    }

    // Checks whether the Scope is accessable on the DOM.
    isRootControlReady() {
        return this._oRootControl && this._oRootControl._eElem;
    }

    // Fires after the scope has been rendered.
    afterRenderRootControl() {
        this.rebind();
    }

    bind() {
        // We won't bind if the scope element is not available yet.
        if (!this.isRootControlReady()) {
            this._hRootControlAfterRender = this._oRootControl?.OnAfterRender;
            this._hRootControlAfterRender?.on(this.afterRenderRootControl, this);
            return;
        }

        // Safety net for the root element and whether it is rendered.
        // We need to do this since a set on the context properties causes a rebind(). This might happen before render.
        if (!this._oRootControl || !this._oRootControl._eElem) {
            if (!this._hRootControlAfterRender)
                throw new df.Error(999, "WebContextMenu could not find an element for the RootControl.");
            return;
        }

        // The weblist modifies for example the contents of the menu.
        // As such we cannot allow childScopes.
        if (this.pbChildScopes && !df.WebUIContext.isChildScopeCompatible(this.peContext)) {
            throw new df.Error(999, "WebContextMenu cannot use pbChildScopes with this peContext.");
        }

        // If the peContext is not custom we try to determine the css selector.
        this.useCSSSelectorOfObject(this._oRootControl, this.pbChildScopes);

        if (this._oRootControl.bindHandlerForWebUIContext && this.pbChildScopes) {
            if (!this._oRootControl.bindHandlerForWebUIContext(this, this.peContext)) {
                throw new df.Error(999, "WebContextMenu's assinged control does not allow binding with the current peContext.");
            }
        }

        // Attach
        df.dom.on("contextmenu", this._oRootControl._eElem, this.onContextMenuOpen, this);
    }

    useCSSSelectorOfObject(oObj, noError) {
        // Skip if custom.
        if (this.peContext === df.WebUIContext.WebUIContextCustom) {
            return true;
        }

        if (!oObj.determineSelectorForWebUIContext) {
            if (noError) return false;
            throw new df.Error(999, "WebContextMenu could not contact the assigned control since it does not support the required interface.");
        }

        let sCSSSelector = oObj.determineSelectorForWebUIContext(this.peContext);
        if (sCSSSelector === null || sCSSSelector === undefined) {
            if (noError) return false;
            throw new df.Error(999, "WebContextMenu's assinged control does not support the desired peContext.");
        }

        this.psContextCSSSelector = sCSSSelector;
        this.addSync("psContextCSSSelector");
        return true;
    }

    unbind() {
        // If we are still looking for an afterRender on the scope, we have not attached yet.
        if (this._hRootControlAfterRender) {
            this._hRootControlAfterRender.off(this.afterRenderRootControl, this);
            this._hRootControlAfterRender = null;
        }

        // Safety net for the root element and whether it is rendered.
        // We need to do this since a set on the context properties causes a rebind(). This might happen before render.
        if (!this._oRootControl || !this._oRootControl._eElem) {
            if (this._bRendered)
                throw new df.Error(999, "WebContextMenu could not find a element for the RootControl.");
            return;
        }

        if (this._oRootControl.unbindHandlerForWebUIContext && this.pbChildScopes) {
            if (!this._oRootControl.unbindHandlerForWebUIContext(this, this.peContext)) {
                console.warn("WebContextMenu's assinged control does not allow unbinding with the current peContext.");
            }
        }

        // Detach if they have a event handler.
        df.dom.off("contextmenu", this._oRootControl._eElem, this.onContextMenuOpen, this);
        df.events.removeDomCaptureListener("click", document, this.onClickGeneral, this);
        df.events.removeDomCaptureListener("contextmenu", document, this.hideMenu, this);

        this.hideMenu();
    }

    rebind() {
        this.unbind();
        this.bind();
    }

    // Proxy the addChild (cWebObject) to a new list. These are later added to the generated cWebMenuList.
    addChild(oChild) {
        if (!(oChild instanceof WebMenuItem)) throw new df.Error(999, "WebMenuContext only supports menu items/checkboxes (" + oChild.getLongName() + ").");

        if (this._oMenu) {
            this._oMenu.addChild(oChild);
        } else {
            this._oChildrenCache.push(oChild);
        }
    }

    getVisibleChildCount() {
        let iCount = 0;
        if (this._oMenu && this._oMenu._aChildren) {
            for (let i = 0; i < this._oMenu._aChildren.length; i++) {
                if (this._oMenu._aChildren[i].pbRender && this._oMenu._aChildren[i].pbVisible) {
                    iCount++;
                }
            }
        }
        for (let i = 0; i < this._oChildrenCache.length; i++) {
            if (this._oMenu._aChildren[i].pbRender && this._oMenu._aChildren[i].pbVisible) {
                iCount++;
            }
        }
        if (this._oMenu?._aDynamicMenu) {
            iCount += this._oMenu._aDynamicMenu.length;
        }
        return iCount;
    }

    /* 
    Handles the OnShow event of the view and makes sure the floating panel is displayed if it should.
    If we are not yet rendered it means we are attached to a control that is not a base of the WebContainer_mixin.
    Thus we render ourselves.

    We also rebind since views are cached and we are unbound in the OnHide.

    @param  oEvent  Event object.
    @private
    */
    showView(oEvent) {
        super.showView(oEvent);

        this.rebind();
    }

    /* 
    Handles the OnHide event of the view and makes sure the panel is hidden.
    If we hide our view we need to unbind since we have lost focus and don't want to trigger anything elsewhere.

    @param  oEvent  Event object.
    @private
    */
    hideView(oEvent) {
        super.hideView(oEvent);

        this.unbind();
    }

    show() {
        if (this.isEnabled()) {
            this.pbVisible = true;

            if (this._bViewVisible) {
                this.doShow();
            }
        }
    }

    isVisible() {
        return this.pbVisible === true;
    }

    // When the menu is opened a click in general should make the menu hide.
    // Whether it is a button or something else entirely.
    onClickGeneral(oEv) {
        if (this._eElem.contains(oEv.getTarget())) {
            return;
        }
        df.events.removeDomCaptureListener("click", document, this.onClickGeneral, this);
        df.events.removeDomCaptureListener("contextmenu", document, this.hideMenu, this);
        this.hideMenu();
    }

    // If the menu is enabled we open.
    // We attach a general click event and open at the clicked location.
    onContextMenuOpen(oEvent) {
        if (!this._bRendered) {
            this.render();
            this.afterRender();
        }

        // Grab the element from the click.
        let eElem = document.elementFromPoint(oEvent.e.clientX, oEvent.e.clientY);

        let oTargetContext = this._oRootControl;

        // We first find the forwarded scope if available.
        if (this.pbChildScopes) {
            let eTargetControl = eElem;

            // From there go up to find the first control (in which case it came from that control).
            while (!eTargetControl.hasAttribute("data-dfobj") && eTargetControl != this._oRootControl._eElem) {
                if (!eTargetControl.parentNode || !eTargetControl.parentNode.hasAttribute) {
                    throw new df.Error(999, "WebContextMenu could not find a TargetScope control element.");
                }
                eTargetControl = eTargetControl.parentNode;
            }

            oTargetContext = this.getWebApp()?.findObj(eTargetControl.getAttribute("data-dfobj"));
            if (!oTargetContext) {
                throw new df.Error(999, "WebContextMenu could not find a TargetScope control.");
            }

            // Check whether we have an aware control.
            // If not we bail.
            if (!this.useCSSSelectorOfObject(oTargetContext, true)) {
                return;
            }
        }

        // If we trigger for all elements then that's fine too.
        let bFound = this.psContextCSSSelector.length === 0;

        // As long as we are in the root context and the object is not found we keep looking for the 
        // Context Query.
        while (eElem && eElem.matches &&
            eElem !== this._oRootControl._eElem &&
            !bFound) {

            bFound = eElem.matches(this.psContextCSSSelector);

            if (bFound) break;

            eElem = eElem.parentNode;
        }

        this.psContextScopeName = oTargetContext.getLongName();
        this.addSync("psContextScopeName");

        let bValid = oTargetContext.verifyElementForWebUIContext ?
            oTargetContext.verifyElementForWebUIContext(eElem, this.peContext) :
            true;

        if (this.isEnabled() && bFound && bValid && this.getVisibleChildCount()) {
            oEvent.stop();

            this.psContextValue = "";

            // First we get the desired data; since it might change with layoutChanges.
            if (oTargetContext.retrieveValueFromWebUIContext && this.peContext > df.WebUIContext.WebUIContextCustom) {
                let vValue = oTargetContext.retrieveValueFromWebUIContext(eElem, this.peContext);

                // Something is corrupted if the value is null or undefined.
                // Might be cause of DOM corruption or someone with a custom control.
                if (vValue === null || vValue === undefined)
                    throw new df.Error(999, "WebContextMenu's assinged control does not support the desired peContext or we passed the wrong element.");

                // If the returned value is an object with strinify it to json.
                // Otherwise call the toString
                if (vValue.toString) {
                    this.psContextValue = vValue.toString();
                } else if (vValue instanceof Object) {
                    this.psContextValue = JSON.stringify(vValue);
                } else {
                    throw new df.Error(999, "WebContextMenu could not convert the determined Value returned by the assigned control.");
                }
            }
            this.addSync("psContextValue");

            df.events.addDomCaptureListener("click", document, this.onClickGeneral, this);
            df.events.addDomCaptureListener("contextmenu", document, this.hideMenu, this);

            this.fire("OnContextMenuOpen", [], function (oServerEvent) {
                if (oServerEvent.sReturnValue === "1") return;

                // Reset the menu path and regenerate it.
                this._oMenu._sCurrentMenu = "";
                this.refreshMenu();

                // Set intial X & Y
                this.piLeft = oEvent.e.clientX;
                this.piTop = oEvent.e.clientY;
                this.show(); // Show it before we can calculate the height.

                // Get the rectangle
                const oRect = df.sys.gui.getBoundRect(this._oMenu._eCurrentMenu);

                if (oRect.right > window.innerWidth && // Check whether it fits on the left side of the cursor as to mimic windows.
                    window.innerWidth - oRect.left <= oRect.width) {
                    this.piLeft = oRect.left - oRect.width;
                } else if (oRect.right > window.innerWidth) { // Just put it were it should be available.
                    this.piLeft = window.innerWidth - oRect.width;
                }

                if (oRect.bottom > window.innerHeight && // Check whether it fits on top of the cursor as to mimic windows.
                    window.innerHeight - oRect.top >= oRect.height) {
                    this.piTop = oRect.top - oRect.height;
                } else if (oRect.bottom > window.innerHeight) { // Just put it were it should be available.
                    this.piTop = window.innerHeight - oRect.height;
                }

                this.positionPnl();
            });
        }
    }

    doHide(bNoPos, sReason) {
        const oWebApp = this.getWebApp();

        if (this._tPositionInterval) {
            clearInterval(this._tPositionInterval);
            this._tPositionInterval = null;
        }


        df.dom.addClass(this._eElem, "WebFP_Hidden");
        df.dom.removeClass(this._eElem, "WebFP_Visible");

        if (!bNoPos) {
            this.positionPnl();
        }

        this.afterHide();

        //  Remove mobile mask that might have been created
        if (this._eMask) {
            df.dom.off("click", this._eMask, this.onMaskTouch, this);
            this._eMask.parentNode.removeChild(this._eMask);
            this._eMask = null;
        }

        //  Detach blur listener from floatby control
        if (this._eBlurBuddy) {
            df.events.removeDomCaptureListener("blur", this._eBlurBuddy, this.onCaptureBlur, this);
        }

        if (this.pePosition === df.fpFloatLeftSqueezeWebApp) {
            if (oWebApp && oWebApp._eElem) {
                oWebApp._eElem.style.marginLeft = "0px";
            }
        }

        this.fire("OnHide", [sReason]);

        if (!this.pbVisible && this._eElem) {
            this._eElem.style.display = "none";
            this._bVisible = false;
        }
    }

    enable(bOptState) {
        this.pbEnabled = bOptState !== null ? bOptState : true;
    }

    disable() {
        this.pbEnabled = false;
    }

    // Creates a new WebMenuItem with the provided caption and adds it to the menu.
    createMenuItem(sCaption) {
        const oItem = new WebMenuItem(null, this);
        oItem.psCaption = sCaption;
        oItem.create();
        return oItem;
    }

    // Creates a new WebMenuItem with Checkbox and the provided caption and adds it to the menu.
    createCheckedMenuItem(sCaption, bChecked, bOptEnabled) {
        const oItem = new WebMenuItemCheckbox(null, this);
        oItem.psCaption = sCaption;
        oItem.pbChecked = bChecked;
        if (arguments.length > 2) {
            oItem.pbEnabled = bOptEnabled;
        }
        oItem.create();
        return oItem;
    }
}