import { WebBaseContainer } from './WebBaseContainer.js';
import { MobRuleController } from './MobRuleController.js';
import { WebBaseView } from './WebBaseView.js';
import { WebBaseUIObject } from './WebBaseUIObject.js';
import { WebModalDialog } from './WebModalDialog.js';
import { WebLabel } from './WebLabel.js';
import { WebButton } from './WebButton.js';
import { WebPanel } from './WebPanel.js';
import { WebIFrame } from './WebIFrame.js';
import { WebHtmlBox } from './WebHtmlBox.js';
import { WebObject } from './WebObject.js';
import { df } from '../df.js';

/*
Class:
    df.BaseApp
Extends:
    df.WebBaseContainer

The shared implementation of apps that is shared between LocalApp and WebApp.
*/

/* global df, sDfPreloadTheme, sDfBuildNr */

export class BaseApp extends WebBaseContainer {
    constructor() {
        super("oWebApp", null);

        this.pbViewApp = false; //  If true this app works with views

        //  Server properties
        this.prop(df.tString, "psTheme", (typeof (sDfPreloadTheme) === "string" && sDfPreloadTheme) || "Df_Web_Creme");
        this.prop(df.tString, "psVersionID", "");

        //  Localization properties
        this.prop(df.tString, "psDecimalSeparator", ",");
        this.prop(df.tString, "psThousandsSeparator", ".");
        this.prop(df.tString, "psDateFormat", "dd/mm/yyyy");
        this.prop(df.tString, "psDateSeparator", "-");
        this.prop(df.tString, "psDateTimeFormat", "dd/mm/yyyy hh:mm:ss");
        this.prop(df.tString, "psTimeFormat", "hh:mm:ss");
        this.prop(df.tString, "psTimeSeparator", ":");
        this.prop(df.tString, "psCurrencySymbol", "$");
        this.prop(df.tInt, "peAlignView", df.ciAlignCenter);

        //  Client Details
        this.prop(df.tInt, "piScreenWidth", screen.width);
        this.prop(df.tInt, "piScreenHeight", screen.height);

        this.prop(df.tInt, "piWindowWidth", 0);
        this.prop(df.tInt, "piWindowHeight", 0);

        this.prop(df.tInt, "peMode", 0);
        this.prop(df.tBool, "pbResponsive", true);
        this.prop(df.tBool, "pbIsMobile", true);

        this.prop(df.tString, "psLocationHash", "");

        this.prop(df.tAdv, "pasBrowserLanguages", null);
        this.prop(df.tInt, "piBrowserTimezoneOffset", 0);

        this.prop(df.tBool, "pbUpdateApplicationTitle", true);
        this.prop(df.tString, "psApplicationTitle", "");

        this.event("OnOrientationChange", df.cCallModeWait);
        this.event("OnResizeWindow", df.cCallModeDefault);

        //  Client-side Events
        this.OnError = new df.events.JSHandler();
        this.OnShowProgress = new df.events.JSHandler();
        this.OnShowWindow = new df.events.JSHandler();
        this.OnHideWindow = new df.events.JSHandler();
        this.OnHideProgress = new df.events.JSHandler();

        // @privates
        this._oPreLoaded = {}; //  Administration of views that are preloaded. Will be filled with arrays of queued actions.

        this._oModeControl = new MobRuleController(this); //  Controller for the mobile modes (web property rules)
        this._oMenuHub = null; //  Hub for menu groups (created on first usage)


        this._aSyncPropCache = []; //  Cache of synchronized property values for objects that aren't loaded yet
        this._aAdvSyncPropCache = []; //  Cache of advanced synchronized properties for objects that aren't loaded yet

        this._oCurrentWindow = null;
        this._oCurrentView = null;
        this._oCurrentObj = null;
        this._aViews = [];
        this._aFocussed = [];

        this._bReady = false;
        this._aLoadQueue = []; //  Queue of functions to be called after initialization
        this._oLoadViewQueue = {}; //  Queue of functions to be called when a view is loaded
        this._aPreLoadViewActions = []; //  Array with queued actions performed on a view that isn't loaded yet 
        this._bInitStarted = false; //  Indicate used by the ready function to see if initialize was already called


        this._bCallTimeout = false; //  Determines if server actions are delayed with a timeout (usually true after initialization)
        this._oPendingCall = null; //  Call waiting to be sent
        this._oSendingCall = null; //  Call currently being sent / processed

        this._eLocked = -1;
        this._aLockwaiters = [];

        this._eStyleSystem = null;
        this._eStyleTheme = null;
        this._eStyleApplication = null;
        this._sRootPath = df.psRootPath || "";

        this._oTranslations = {};

        this._aModalQueue = []; //  Queue of modal dialogs waiting for previous one to close

        this._tResizeTimer = null; //  Timeout set to queue a resize
        this._bSizeChanged = false; //  Switch indicating that a resize is needed after processing the call.
        this._bContainerStretch = false; //  Switch that determines if the webapp should stretch to fill its container or if it should determine its own size
        this._aResponseAttachments = null;
        
        this._bIsBaseApp = true;

        //  Configure super classes
        this._bWrapDiv = true;
        this._sControlClass = "WebApp";

        this._eViewPort = null;

        this.addSync("peMode");
        this.addSync("pbIsMobile");
        this.addSync("piScreenWidth");
        this.addSync("piScreenHeight");
        this.addSync("piWindowWidth");
        this.addSync("piWindowHeight");
        this.addSync("psLocationHash");
        this.addSync("pasBrowserLanguages");
        this.addSync("piBrowserTimezoneOffset");

        this.setActionMode("loadView", df.cCallModeWait);

        this.ready(this.attachGlobalHandlers);

        df.log("DataFlex Web Application Framework " + df.psVersionId);
        df.log("Copyright 2005-2025 Data Access Corporation. All rights reserved."); 

    }

    /* 
    Called after the initial web property values are set and performs non UI related initialization.
    
    @private
    */
    create() {
        super.create();

        //  Activate / deactivate the responsive system
        this.set_pbResponsive(this.pbResponsive);
    }

    //  - - - - - - - - - Rendering - - - - - - - - -


    attachGlobalHandlers() {
        df.dom.on("resize", window, this.onWindowResize, this);
        df.dom.on("scroll", window, this.onScroll, this);
        df.dom.on("orientationchange", window, this.onOrientationChange, this);
        df.dom.on("popstate", window, this.onPopState, this);
        df.dom.on("hashchange", window, this.onHashChange, this);

        //  Update screen height and width as some browsers now that browsers are further initialized
        this.piScreenHeight = screen.height;
        this.piScreenWidth = screen.width;
    }

    /* 
    Augment destroy to destroy the mode controller object and remove global event handlers.
    
    @private
    */
    destroy() {
        df.dom.off("resize", window, this.onWindowResize, this);
        df.dom.off("scroll", window, this.onScroll, this);
        df.dom.off("orientationchange", window, this.onOrientationChange, this);

        super.destroy();

        if (this._oModeControl) {
            this._oModeControl.destroy();
            this._oModeControl = null;
        }

    }

    /*
    Child objects register themselves at their parents. Views are not considered to be regular children.
    
    @private
    */
    addChild(oChild) {
        //  Filter out child components since they are not considered regular children
        if (!(oChild instanceof WebBaseView)) {
            if (oChild.peRegion === df.ciRegionCenter) {
                throw new df.Error(999, "The 'oWebApp' object should not have panels set to the center region, this space is reserved for the WebView.", this, [oChild.getLongName()]);
            }

            super.addChild(oChild);
        } else {
            this._aViews.push(oChild);
        }
    }

    /* 
    Augment the updateEnabled function to notify views of the change in enabled state as well.
    */
    updateEnabled() {

        super.updateEnabled();

        for (let i = 0; i < this._aViews.length; i++) {
            if (this._aViews[i] instanceof WebBaseUIObject) {
                this._aViews[i].updateEnabled();
            }
        }
    }


    /*
    For the BaseApp object the view region is the implicit center panel. Augment placePanels to create 
    the view region element and set it as the center panel. This function can be executed multiple 
    times so we make sure to only touch the DOM if nessecary.
    */
    placePanels() {
        super.placePanels();

        if (this.pbViewApp) {
            if (!this._eViewRegion) {
                this._eViewRegion = df.dom.create('<div class="BaseApp_ViewRegion" style="position: absolute; left: 0px; right: 0px; top: 0px; bottom: 0px"></div>');
            }
            this._eRegionCenter = this._eViewRegion;

            //  Make sure that we insert the viewregion before the clear div created by WebBaseContainer
            if (this._eRegionCenter.parentNode != this._eMainArea || this._eRegionCenter.nextElementSibling != this._eMainArea.lastChild) {
                this._eMainArea.insertBefore(this._eRegionCenter, this._eMainArea.lastChild);
            }
        }
    }

    //  - - - - - - - - - Initialization - - - - - - - - -

    /*
    This method initializes the webapp by making the LoadWebApp call to the server. This will return the 
    definition of the global objects including the webapp itself and the session key. Optionally there 
    can be a startup view returned. After this call is returned the proper CSS is included and we wait 
    for the DOM and the CSS to become finished. Finally the waiting handlers are called (usually 
    displayView or displayApp). 
    
    @private
    */
    initialize(bLoadDefault) {
        this._bInitStarted = true;

        try {
            if (this.checkBrowser()) {
                this.serverAction("LoadWebApp", [df.fromBool(!!bLoadDefault)], null, function (oEvent) {
                    //  Make sure the proper CSS is included
                    this.updateCSS(false);

                    //  Check if DOM is ready
                    df.dom.ready(function () {
                        //  Check is CSS is ready
                        this.testCSS(function () {

                            this._bCallTimeout = true;

                            try {
                                //  Mark ready
                                this._bReady = true;

                                //  Call waiters
                                for (let i = 0; i < this._aLoadQueue.length; i++) {
                                    this._aLoadQueue[i].fHandler.call(this._aLoadQueue[i].oEnv || this);
                                }
                            } catch (oErr) {
                                this.handleError(oErr);
                            }
                        });
                    }, this);
                });
            }
        } catch (oErr) {
            this.handleError(oErr);
        }
    }

    checkBrowser() {
        if (df.sys.isIE && df.sys.iVersion < 11) {
            alert("Unfortunately the browser you are using is not supported by this framework. Please upgrade to a more modern browser.\n\r\n\rThe minimal version required is Internet Explorer 11. We advise to use the latest version of Microsoft Edge, Google Chrome or Mozilla FireFox.");
            return false;
        }

        return true;
    }


    /*
    The method passed to this function will be called when the webapp is initialized. Initialization is 
    an asynchronous process which requires other functionality to wait. Optionally the name of a view 
    can be passed when waiting for a specific view to be synchronized.
    
    The example below waits for the webapp to be synchronized before manipulating global objects.
    @code
    oWebApp.ready(function(){
        oWebApp.oCommandbar.oMenuBar.oDemoMenu.set("pbRender", false);
    });
    @code
    
    The example below waits for the oWebCustomer view to be initialized before manipulating objects 
    inside the view.
    @code
    oWebApp.ready("oWebCustomer", function(){
        oWebApp.oWebCustomer.oTabContainer.oBalancesTabPage.set('pbRender', false);
    });
    @code
    
    @param  sOptView    (optional) Objects name of the view to wait for.
    @param  fHandler    Function that needs to be called when ready.
    @param  sOptEnv     (optional) Environment object when the handler is called.
    */
    ready(sView, fHandler, oOptEnv) {
        if (typeof (sView) === "string") {
            this.ready(function () {
                if (this[sView] instanceof WebBaseView) {
                    fHandler.call(oOptEnv || this);
                } else {
                    if (!this._oLoadViewQueue[sView]) {
                        this._oLoadViewQueue[sView] = {
                            aWaiters: [],
                            bLoading: false
                        };
                    }
                    this._oLoadViewQueue[sView].aWaiters.push({
                        fHandler: fHandler,
                        oEnv: oOptEnv
                    });
                }
            });
        } else {
            oOptEnv = fHandler;
            fHandler = sView;


            if (!this._bReady) {
                this._aLoadQueue.push({
                    fHandler: fHandler,
                    oEnv: oOptEnv
                });
            } else {
                fHandler.call(oOptEnv || this);
            }
        }
    }

    /*
    This method should be called to render the application. It will render the application as soon as 
    the initialization finished to the passed DOM element. The DOM element can be passed as an object 
    reference or as a query selector string (like '#viewport'). Using a query selector string allows to 
    call this method before the DOM is initialized. The application will render itself inside the 
    provided DOM element. 
    
    @code
    var oWebApp = new df.WebApp('WebService.wso');
    oWebApp.displayApp('#viewport');
    
    ...
    
    <div id="viewport"></div>
    @code
    
    @param  oRenderTo   The DOM element to render to (object reference or query selector string).
    */
    displayApp(oRenderTo) {

        if (!this._bInitStarted) {
            this.initialize(true);
        }

        this.ready(function () {
            let eRenderTo;

            try {
                //  Get reference to element
                if (typeof (oRenderTo) === "string") {
                    eRenderTo = df.dom.query(document.body, oRenderTo);
                } else {
                    eRenderTo = oRenderTo;
                }
                if (!eRenderTo) {
                    throw new df.Error(999, "No proper element passed", this);
                }

                this._eViewPort = eRenderTo;

                //  Determine if the renderto element has a defined height
                this._bContainerStretch = !df.sys.gui.isSizedByContent(eRenderTo);

                //  Start rendering the application
                const eContent = this.render();
                this.afterRender();
                eContent.style.visibility = "hidden";
                eRenderTo.appendChild(eContent);
                this.afterShow();
                this.forceResize();
                eContent.style.visibility = "";
            } catch (oErr) {
                this.handleError(oErr);
            }
        });
    }

    /*
    This method should be called to render a single view of the application. It will make sure that the 
    view is or gets loaded and render it to the passed DOM element. The DOM element can be passed as 
    object reference or as a query selector string (like '#viewport'). This method should only be used 
    when rendering a view separate of the rest of the application. The view will render itself inside 
    the provided DOM element. This is the adviced method to integrate a single view inside an existing 
    web page. To show a view within the rendered application please use the showView method.
    
    @code
    var oWebApp = new df.WebApp('WebService.wso');
    oWebApp.displayView('oCustomerView', '#customerdiv');
    
    ...
    
    <div id="customerdiv"></div>
    @code
    
    @param  sView       Name of the view.
    @param  oRenderTo   DOM element to render to (object reference or query selector string).
    */
    displayView(sView, oRenderTo) {
        if (!this._bInitStarted) {
            this.initialize(false);
        }

        this.ready(function () {
            let eRenderTo;

            try {
                //  Get reference to element
                if (typeof (oRenderTo) === "string") {
                    eRenderTo = df.dom.query(document.body, oRenderTo);
                } else {
                    eRenderTo = oRenderTo;
                }
                if (!eRenderTo) {
                    throw new df.Error(999, "No proper element passed", this);
                }
                this._eViewPort = eRenderTo;

                this.serverActionEx({
                    sMethod: "ShowView_FromClient",
                    aParams: [sView, df.fromBool(true)],
                    aViews: [sView],
                    fHandler(oEv) {
                        var oView;

                        oView = this[sView];
                        if (oView && oView instanceof WebBaseView) {
                            oView._show(eRenderTo);
                        }

                    },
                    oHandlerEnv: this
                });
            } catch (oErr) {
                this.handleError(oErr);
            }
        });
    }

    //  - - - - - - - - - View logic - - - - - - - - - - -

    /* 
    Renders the specified view in the center region of the webapp panel. Triggered by the server from 
    the ShowView_Exec procedure.
    
    @param  sView   Web object name of the view.
    @client-action
    */
    renderView(sView) {
        this.ready(function () {
            const oView = this[sView];
            if (!oView) {
                throw new df.Error(999, "Cannot render view '{{0}}' as it is not initialized.", this, [sView]);
            }
            if (!oView._bRendered) {

                if (oView instanceof WebModalDialog) {
                    //  For a dialog the current view becomes the invoker
                    oView.psInvokingView = (this._oCurrentWindow && this._oCurrentWindow._sName) || "";
                    if (oView.psInvokingView) {
                        oView.addSync("psInvokingView");
                    }

                    //  Modal dialogs are queued using the 'modal queue' to prevent them from showing on top of errors or info boxes displayed before the dialog.
                    this.queueModal(function () {
                        oView._show(this._eRegionCenter);
                        this.forceResize();
                    }, this);
                } else {
                    this.hideView(this._oCurrentView, (oView === this._oCurrentView));

                    oView._show(this._eRegionCenter);
                    this.forceResize();

                    this._oCurrentView = oView;
                }
                this._oCurrentWindow = oView;

            }
        });
    }


    /* 
    Shows a view by calling the ShowView_FromClient server action. It makes sure that the view to be 
    shown is synchronized. Can be called from the server when showing a view that is loaded to the \
    client but not synchronized with the call triggering the show.
    
    @param  sView   Web object name of the view.
    @client-action
    */
    showView(sView, sOptCallbackMsg, sOptCallbackObj) {
        const aParams = [sView, df.fromBool(false)];

        if (sOptCallbackMsg) {
            aParams.push(sOptCallbackMsg);
            aParams.push(sOptCallbackObj);
        }

        this.serverActionEx({
            sMethod: "ShowView_FromClient",
            aParams: aParams,
            aViews: [sView]
        });
    }

    /*
    This function closes a view or a dialog. That means that it stops rendering the view and with MDI or 
    a modal dialog it determines which view will be the new current view.
    
    @param  sView   String with the name of the view.
    @param  bOptNoServerEvents  If true no server calls like OnHide will be executed.
    @client-action
    */
    hideView(sView, bOptNoServerEvents) {

        //  Param can be name or object
        const oView = (typeof sView === "string" ? this[sView] : sView);

        //  Make sure we are dealing with a view here
        if (oView instanceof WebBaseView) {
            const oInvoking = oView.getInvoking();
            oView._hide(df.toBool(bOptNoServerEvents));

            if (this._oCurrentWindow === oView) {
                this._oCurrentWindow = null;
            }
            if (this._oCurrentView === oView) {
                this._oCurrentView = null;
            }

            if (oView instanceof WebModalDialog) {
                if (oInvoking) {
                    this._oCurrentWindow = oInvoking;
                }
            }
        }
    }

    /*
    This method loads a view from the server by making an AJAX Call.
    
    @param  sName       The name of the view.
    @param  bPreLoaded  Should only be sent as true if the view has been initialized already. Used by 
                        the server for the pbOverrideStateOnShow logic.
    @param  fHandler    Handler method that is called when the view is loaded.
    @param  oEnv        (Optional) Object used as context when calling the handler method.
    */
    loadView(sName, bPreLoaded, sOptInvoker, fHandler, oEnv) {

        //  Register as preloaded view
        if (bPreLoaded) {
            this._oPreLoaded[sName] = [];
        }

        this.ready(function () {
            //  Load a view
            if (this[sName] && this[sName] instanceof WebBaseView) {
                if (fHandler) {
                    fHandler.call(oEnv || this, this[sName]);
                }
            } else {
                //  Register view loading
                if (!this._oLoadViewQueue[sName]) {
                    this._oLoadViewQueue[sName] = {
                        aWaiters: [],
                        bLoading: false
                    };
                }
                if (this._oLoadViewQueue[sName].bLoading) {
                    return;
                }
                this._oLoadViewQueue[sName].bLoading = true;

                //  Add handler method to waiting queue
                if (fHandler) {
                    this._oLoadViewQueue[sName].aWaiters.push({
                        fHandler: fHandler,
                        oEnv: oEnv
                    });
                }

                //  Fire the loadView action
                const oAction = new df.ServerAction();
                oAction.oWO = this;
                oAction.sAction = "loadView";
                oAction.aParams = [sName, sOptInvoker || "", df.fromBool(bPreLoaded)];

                oAction.eCallMode = df.cCallModeWait;

                oAction.fHandler = function (oEvent) {
                    let tAct;
                    const oView = this[sName];

                    if (df.toBool(oEvent.sReturnValue)) {

                        try {
                            if (oView instanceof WebBaseView) {
                                //  If this is a preloaded view this view is already initialized so there can be queued client actions under _oPreLoaded which we need to execute and then clear
                                if (bPreLoaded && this._oPreLoaded[sName]) {
                                    tAct =  this._oPreLoaded[sName].shift();
                                    while (tAct) {
                                        this.execClientAction(tAct);
                                        tAct =  this._oPreLoaded[sName].shift();
                                    }
                                    delete this._oPreLoaded[sName];
                                }


                                //  Call handlers
                                const aWaiters = this._oLoadViewQueue[sName].aWaiters;
                                for (let i = 0; i < aWaiters.length; i++) {
                                    aWaiters[i].fHandler.call(aWaiters[i].oEnv || this, oView);
                                }

                                //  Remove from registration
                                this._oLoadViewQueue[sName] = null;
                            } else {
                                this._oLoadViewQueue[sName].bLoading = false;
                                throw new df.Error(999, "No view definition received for '{{0}}'", this, [sName]);

                            }
                        } catch (oErr) {
                            this.handleError(oErr);
                        }
                    }
                };
                oAction.oHandlerEnv = this;

                oAction.aViews.push(sOptInvoker || null);
                oAction.aViews.push(sName);

                this.handleAction(oAction);
            }
        }, this);
    }

    /*
    This method unloads a view completely by destroying the associated objects. It will make sure that 
    the view has to be loaded freshly from the server when it is opened the next time.
    
    @param  sView       The object name of the view to unload.
    @param  bDefinition If true then the cached view definition should be removed as well.
    
    @client-action
    */
    unloadView(sView, bDefinition) {

        bDefinition = df.toBool(bDefinition);

        if (this[sView] && this[sView] instanceof WebBaseView) {
            //  Get reference
            const oView = this[sView];

            //  Make sure it is hidden
            if (oView._bRendered) {
                this.hideView(sView, true);
            }

            //  Clear focussed object if inside view
            if (this._oCurrentObj && this._oCurrentObj.getView() === oView) {
                this._oCurrentObj = null;
            }

            //  Destroy
            oView.destroy();

            //  Remove from WebObject children array
            const i = this._aChildren.indexOf(oView);
            if (i >= 0) {
                this._aChildren.splice(i, 1);
            }
        }

        if (bDefinition && this._oWODefStore[sView]) {
            delete this._oWODefStore[sView];
        }
    }

    //  - - - - - - - - - Window logic - - - - - - - - - - -

    /* 
    This method is called by WebBaseUIObject to register that it has received the focus. The name of the 
    focused object is passed to the server during server actions and is sometimes used to determine 
    where to return to the focus to.
    
    @param  oObj    The object that has received the focus.
    @private
    */
    objFocus(oObj) {
        const oWin = oObj.getView();

        //  Update the current window if this object is inside a window. This is needed when using the displayview api, especially with multiple views
        if (oWin && !oWin._bStandalone && oWin._bRendered) {
            this._oCurrentWindow = oWin;
        }

        if (!oWin || oWin._bRendered) {
            this._oCurrentObj = oObj;
        }
    }

    /*  
    This method is called by WebBaseUIObject to register that an object has lost the focus.
    
    @param  oObj    The object that lost the focus.
    @private
    */
    objBlur(oObj) {

    }

    /* 
    This method returns the focus to the object that is known to have focus. The WebMenuItem class uses 
    it to return the focus when a menu item is clicked.
    
    @private
    */
    returnFocus() {
        if (this._oCurrentObj) {
            this._oCurrentObj.conditionalFocus();
        }
    }

    getFocusObjName() {
        if (this._oCurrentObj instanceof WebBaseUIObject && !this._oCurrentObj._bStandalone) {
            return this._oCurrentObj.getLongName();
        }
        return "";
    }

    set_pbMDI(bVal) {
        if (this._eRegionCenter) {
            this._eRegionCenter.style.position = (bVal ? "relative" : "");
        }
    }

    notifyScroll(oWO) {
        this.notifyPosChange(oWO);
    }

    notifyLayoutChange(oWO) {
        this.notifyPosChange(oWO);
    }

    notifyPosChange(oWO) {

    }

    //  - - - - - - - - - Object creation - - - - - - - - - - -

    /*
    Method that creates the instances of the JavaScript objects based on the JSON description. It will 
    walk through the structure and instantiates all the objects. The resulting objects structure will be 
    equal to the nested object structure on the server.
    
    @param  tDef    JSON data objects containing object definitions.
    @private
    */
    initJSON(tDef) {

        function initObj(tDef, oContext) {
            let sP, oObj;

            //  If no name is given it must be the global webapp object
            if (tDef.sType === "df.WebApp") {
                oObj = this;
            } else {
                //  Check for name conflict
                if (!oContext[tDef.sName]) {

                    //  Find constructor
                    const FConstructor = this.getConstructor(tDef.sType, tDef);
                    if (typeof (FConstructor) === "function") {

                        //  Create new instance
                        oContext[tDef.sName] = oObj = new FConstructor(tDef.sName, oContext);
                    } else {
                        throw new df.Error(999, "Could not find class '{{0}}'", this, [tDef.sType]);
                    }
                } else {
                    throw new df.Error(999, "Naming conflict with child object '{{0}}'", this, [tDef.sName]);
                }
            }

            //  Set the published property values
            for (let i = 0; i < tDef.aProps.length; i++) {
                sP = tDef.aProps[i].sN;

                //  Check naming convention
                if (sP.charAt(0) !== "_") {
                    //  Check if not conficting with child object or function
                    if (!oObj[sP] || (typeof (oObj[sP]) !== "object" && typeof (oObj[sP]) !== "function")) {
                        oObj._set(sP, tDef.aProps[i].sV, false, false);
                    } else {
                        throw new df.Error(999, "Naming conflict with property '{{0}}' of object '{{1}}'", this, [sP, tDef.sName]);
                    }
                } else {
                    throw new df.Error(999, "Published property '{{0}}' of object '{{1}}' properties should not start with an '_'", this, [tDef.aProps[i].sV, tDef.sName]);
                }
            }

            //  Set the advanced typed published property values
            if (tDef.aAdvP) {
                for (let i = 0; i < tDef.aAdvP.length; i++) {
                    sP = tDef.aAdvP[i].sN;

                    //  Check naming convention
                    if (sP.charAt(0) !== "_") {
                        if (!oObj[sP] || (typeof (oObj[sP]) !== "object" && typeof (oObj[sP]) !== "function")) {
                            //  Make sure to mark it as advanced (this is used to determine this when sending a call
                            if (!oObj._oTypes[sP]) {
                                oObj._oTypes[sP] = df.tAdv;
                            }

                            //  Actually set the property value
                            oObj._set(sP, tDef.aAdvP[i].tV, false, false);
                        } else {
                            throw new df.Error(999, "Naming conflict with property '{{0}}' of object '{{1}}'", this, [sP, tDef.sName]);
                        }
                    } else {
                        throw new df.Error(999, "Published property '{{0}}' of object '{{1}}' properties should not start with an '_'", this, [tDef.aAdvP[i].sV, tDef.sName]);
                    }
                }
            }

            //  Register the object
            this.newWebObject(oObj, oContext, tDef);

            //  Create children
            for (let i = 0; i < tDef.aObjs.length; i++) {
                initObj.call(this, tDef.aObjs[i], oObj);
            }

            //  Call create
            oObj.create(tDef);

            return oObj;
        }

        return initObj.call(this, tDef, this);
    }

    /*
    Called whenever a new Web Object is created. Registers the Web Object with its parent.
    
    @param  oObj    The newly created web object.
    @param  oParent The parent of the new web object.
    @param  tDef    The JSON definition received from the server.
    */
    newWebObject(oObj, oParent, tDef) {
        //  Register new child control
        if (oParent.addChild && oParent !== oObj) {
            oParent.addChild(oObj);
        }
    }

    getConstructor(sType) {
        return df.sys.ref.getNestedProp(sType);
    }

    findObj(sName) {
        let oObj;

        if (sName === "") {
            return this;
        }

        const aParts = sName.split(/[\. | \$]/);

        oObj = this;
        for (let i = 0; i < aParts.length && oObj; i++) {
            oObj = oObj[aParts[i]];
        }

        return (typeof oObj === "object" && oObj) || null;
    }


    //  - - - - - - - - - Server actions - - - - - - - - - - -

    waitForCall(fFunc, oEnv) {

        if (this._eLocked >= df.cCallModeDefault) {
            for (let i = 0; i < this._aLockwaiters.length; i++) {
                if (this._aLockwaiters[i].fFunc === fFunc && this._aLockwaiters[i].oEnv === oEnv) {
                    return;
                }
            }

            this._aLockwaiters.push({ fFunc: fFunc, oEnv: oEnv });
        } else {
            fFunc.call(oEnv);
        }
    }

    /*
    This function locks a webapp during a call. It generates the locking mask and optionally generates a 
    waiting dialog. Key entry is blocked by intercepting the keydown event at document level. The 
    function can be called multiple times without problems and will upgrade the lock with a waiting 
    dialog when needed.
    
    @param  bWaitDialog     If true a waiting dialog will be shown.
    @param  sWaitMessage    String with message shown in the waiting dialog.
    */
    lock(eCallMode, sWaitMessage) {
        let oDialog;
        const that = this;

        this._eLocked = eCallMode;

        if (document && document.body) {  //  Check if the DOM is ready
            this.lockDisplay();

            // Show wait dialog
            if ((eCallMode >= df.cCallModeProgress) && !this._bLockWait) {
                this._bLockWait = true;
                if (this.OnShowProgress.fire(this, { sMessage: sWaitMessage })) {

                    //  Block the modal queue (due to focus issues)
                    this._aModalQueue.push(this._oLockModalBlock = {
                        fFunc: null,
                        bFinished: false,
                        bDisplayed: true
                    });

                    //  Create waiting dialog
                    this._oLockDialog = oDialog = new WebModalDialog(null, this);
                    oDialog.psCaption = "";
                    oDialog.pbResizable = false;
                    oDialog.pbShowClose = false;
                    oDialog.psCSSClass = "WebMsgBox WebMsgBoxProgress";

                    const oLabel = new WebLabel(null, oDialog);
                    oLabel.psCaption = sWaitMessage || this.getTrans("loading") + "..";
                    oLabel.psCSSClass = "WebMsgBoxProgress";
                    oDialog.addChild(oLabel);

                    oDialog.show();
                    oDialog._oPrevFocus = null; //  Stop dialog from messing with the focus
                }
            }
        }
    }

    /**
     * Unlocks the UI by removing the masking lock. 
     * 
     * Note that this function might be called during a lock to temporary unlock between calls.
     */
    unlockDisplay(){
        if (this._eLockMask) {
            df.gui.hideMask(this._eLockMask);
            this._eLockMask = null;
        }
        if (document && document.body) {  //  Check if the DOM is ready
            df.events.removeDomCaptureListener("keydown", document.body, this.onBlockKey, this);
        }
    }

    /**
     * This function locks the user interface during a call. If this._eLocked is set to cCallModeWait 
     * or higher it will generate the lock mask. 
     * 
     * Note that this function might be called during a lock between requests. 
     */
    lockDisplay(){
        // Lock the webapp
        if (document && document.body && this._eLocked >= df.cCallModeWait) {
            if (!this._eLockMask) {
                this._eLockMask = df.gui.dragMask(true);
                this._eLockMask.showModal();
                
                setTimeout(() => {
                    if(this._eLockMask) this._eLockMask.style.cursor = "wait";
                }, 140);
            }
            df.events.addDomCaptureListener("keydown", document.body, this.onBlockKey, this);
        }
    }

    /* 
    This function unlocks the webapp removing the mask, wait dialog and keydown interception handler. It 
    belongs to the lock function. Note that calling lock multiple times doesn't mean that unlock needs 
    to be called multiple times.
    */
    unlock() {
        let oHandler;

        this._eLocked = -1;

        //  Unlock the webapp
        this.unlockDisplay();
        
        //  Hide the wait dialog
        if (this._bLockWait) {
            this._bLockWait = false;

            this.OnHideProgress.fire(this, {});

            if (this._oLockDialog) {
                this._oLockDialog.hide();
                this._oLockDialog = null;

                // Unblock the modal queue
                this._oLockModalBlock.bFinished = true;
                this.processModal();
            }
        }

        //  Call functions waiting for call to finish processing
        while (oHandler = this._aLockwaiters.pop()) {
            oHandler.fFunc.call(oHandler.oEnv);
        }
    }

    /* 
    Event handler that will cancel the event if the webapp is in locked state. Is used by the lock 
    system to intercept key events at the highest level.
    
    @param  oEvent  Event object (df.events.DOMEvent).
    @private
    */
    onBlockKey(oEvent) {
        if (this._eLocked >= df.cCallModeWait) {
            oEvent.stop();
            return false;
        }
    }

    /* 
    This function initiates the proper handling of an action by creating a call or adding it to an 
    existing call. It will lock the application and initiate the server call process.
    
    @param  oAction     Action object (df.ServerAction).
    @private
    */
    handleAction(oAction) {
        //  Immediately lock the webapp

        this.lock(oAction.eCallMode, oAction.sProcessMessage);

        //  Always add the current view
        oAction.aViews.push(this._oCurrentWindow);

        //  Add action to queue (no actions are ignored any more)
        if (this._oPendingCall) {
            this._oPendingCall.aActions.push(oAction);
            if (this._oPendingCall.eCallMode < oAction.eCallMode) {
                this._oPendingCall.eCallMode = oAction.eCallMode;
            }
        } else {
            this._oPendingCall = new df.ServerCall();

            this._oPendingCall.aActions.push(oAction);
            this._oPendingCall.sFocus = this.getFocusObjName();
            this._oPendingCall.eCallMode = oAction.eCallMode;
        }

        //  Process calls
        this.processCall();
    }

    /*
    Cancels an action based on its name of web object. It will remove all matching actions from the 
    pending call and from the call that is being sent but didn't start processing yet.
    
    @param  oWO     Web object.
    @param  sAction Action name.
    @private
    */
    cancelAction(oWO, sAction) {

        //  For a pending call we remove the entire action if found and cancel the call if empty
        if (this._oPendingCall) {
            const aActions = this._oPendingCall.aActions;

            for (let i = 0; i < aActions.length; i++) {
                if (aActions[i].oWO === oWO && aActions[i].sAction === sAction) {
                    aActions.splice(i, 1);
                    i--;
                }
                if (aActions.length === 0) {
                    this._oPendingCall = null;
                    break;
                }
            }
        }
    }

    /*  
    Determines if a server action is already pending (waiting to be sent) for a specific web object.
    
    @param  oWO     Web Object.
    @param  sAction Action name.
    @return True if the action is pending.
    */
    hasPendingAction(oWO, sAction) {

        if (this._oPendingCall) {
            const aActions = this._oPendingCall.aActions;

            for (let i = 0; i < aActions.length; i++) {
                if (aActions[i].oWO === oWO && aActions[i].sAction === sAction) {
                    return true;
                }
            }
        }

        return false;
    }

    processResponse(tData, oCall) {
        if (tData && tData.r && tData.r.Header && tData.r.asReturnValues) {
            const tResponse = tData.r;

            this._aResponseAttachments = tData.a || [];

            //  Handle header
            this.handleHeader(tResponse.Header);

            //  Call handlers
            if (oCall && oCall.aActions.length === tResponse.asReturnValues.length) {
                const oEvent = new df.events.JSEvent(this);
                for (let i = 0; i < oCall.aActions.length; i++) {
                    oEvent.sReturnValue = tResponse.asReturnValues[i];

                    if (oCall.aActions[i].fHandler) {
                        oCall.aActions[i].fHandler.call(oCall.aActions[i].oHandlerEnv || null, oEvent);
                    }
                }
            }

            this._aResponseAttachments = null;
        } else {
            throw new df.Error(5123, "Unexpected response format.", this);
        }
    }


    /*
    Checks if a pending call is available and can be sent. This happens after a short timeout so that 
    actions can still be added to the pending call from the current execution flow. This method is 
    called after processing a call or when a new action is registered.
    
    @private
    */
    processCall() {

        const process = () => {
            try {
                const oCall = this._oPendingCall;
                if (oCall) {
                    if (!this._oSendingCall) {

                        //  Register as the call currently being sent
                        this._oSendingCall = oCall;

                        this.sendCall(oCall).then(tData => {
                            //  Unlock the display before processing response as lock dialogs interfere with focus
                            this.unlockDisplay();

                            this.processResponse(tData, oCall);
                        }).catch(oErr => {
                            this.handleError(oErr);
                        }).finally(() => {
                            //  Make sure that we always unlock!!!
                            if (!this._oPendingCall) {
                                this.unlock();
                            }else{
                                //  Lock the display again if there is a pending call
                                this.lockDisplay();
                            }
                            this._oSendingCall = null;

                            //  Initiate next call if needed
                            this.processCall();
                        });
                        this._oPendingCall = null;
                    }
                }
            } catch (oErr) {
                //  Make sure that we always unlock!!!
                this.unlock();
                this._oPendingCall = null;
                this._oSendingCall = null;

                this.handleError(oErr);
            }
        }

        if (this._bCallTimeout) {
            if (window.requestIdleCallback) {
                window.requestIdleCallback(process, { timeout: 30 });
            } else {
                window.setTimeout(process, 10);
            }
        } else {
            process();
        }
    }

    assembleRequest(oCall) {
        //  Generate request data
        let aViews = [];
        let aAttachments = [];
        const aActions = [];

        oCall.aActions.forEach(oAction => {
            aActions.push({
                sTarget: oAction.oWO.getLongName(),
                sAction: oAction.sAction,
                aParams: oAction.aParams,
                iAttached: (oAction.tData && aAttachments.push(oAction.tData) || 0)
            });

            aViews = aViews.concat(oAction.aViews);
        });

        //  Assemble request data
        return {
            v: df.psVersionId,
            r: {
                Header: this.getHeader(aViews, oCall.sFocus),
                aActions: aActions
            },
            a: aAttachments
        };
    }

    sendCall(oCall) {
        return new Promise((resolve, reject) => {
            reject(new df.Error(99, "Not implemented"));
        });
    }


    /*
    This core method of the framework is responsible for generating the header of a call that is sent to 
    the server. This header consists of the session key, name of the focused object, DDO definitions per 
    view and the set of synchronized properties. It gets a list of views (or a single view) that 
    determines which views are involved in the call. For each view it will add the DDO definitions and 
    the synchronized properties.  To get the synchronized properties the recursive getSynched method is 
    called.
    
    @param  oView       The view(s) that need to be incorporated. Can be an array of views or a single 
                        view. A view can be passed as a string name or an object reference. May contian 
                        duplicates.
    @param  sFocus      Name of the currently focussed object.
    @private
    */
    getHeader(oView, sFocus) {
        const oDone = {};

        const tHead = {
            sFocus: sFocus,
            aDDOViews: [],
            aSyncProps: [],
            aAdvSyncP: []
        };

        //  Gather global synchronized properties
        this.getSynced(tHead.aSyncProps, tHead.aAdvSyncP);

        function addView(oView) {
            var oViewObj, oInvoking, sViewName;

            //  Try to find the view object
            if (typeof (oView) === "string") {
                oViewObj = this.findObj(oView);
                sViewName = oView;
            } else {
                oViewObj = oView;
                sViewName = oViewObj._sName;
            }

            if (!oDone[sViewName]) {
                oDone[sViewName] = true; //  Make sure that we don't add views twice


                if (oViewObj instanceof WebBaseView) {
                    //  Add invoker view
                    oInvoking = oViewObj.getInvoking();
                    if (oInvoking) {
                        addView.call(this, oInvoking);
                    }

                    //  Get synchonized props
                    oViewObj.getSynced(tHead.aSyncProps, tHead.aAdvSyncP);

                    //  Add DDO details
                    tHead.aDDOViews.push(sViewName);

                } else {
                    //  This means that the view doesn't exist yet so we load synchronized properties from the cache
                    this.getCachedSyncProps(oView, tHead.aSyncProps, tHead.aAdvSyncP);

                    //  With the pbOverrideStateOnShow property it can be that we are loading a view that already has a DDO state
                    tHead.aDDOViews.push(sViewName);
                }
            }
        }

        if (oView instanceof Array) {
            for (let i = 0; i < oView.length; i++) {
                if (oView[i]) {
                    addView.call(this, oView[i]);
                }
            }
        } else if (oView) {
            addView.call(this, oView);
        }

        return tHead;
    }

    /*
    This is one of the most important methods of the framework as it handles the header section received 
    back from the server after a call. This header section can contain object definitions of new 
    objects, updates synchronized properties, updated DDO definitions, client actions that need to be 
    executed and possible errors.
    
    @param  oHeader     The header data.
    @private
    */
    handleHeader(oHeader) {
        //  Execute early client actions
        for (let i = 0; i < oHeader.aActions.length; i++) {
            if (oHeader.aActions[i].eType === df.ctExecEarly) {
                this.execClientAction(oHeader.aActions[i]);
            }
        }

        //  Create objects if a definition has returned
        for (let i = 0; i < oHeader.aObjectDefs.length; i++) {
            this.initJSON(oHeader.aObjectDefs[i]);
        }

        //  Process synchronized properties
        this.handleSyncProps(oHeader.aSyncProps);
        this.handleAdvSyncProps(oHeader.aAdvSyncP);

        //  Call the action methods
        for (let i = 0; i < oHeader.aActions.length; i++) {
            if (oHeader.aActions[i].eType !== df.ctExecEarly) {
                this.execClientAction(oHeader.aActions[i]);
            }
        }
    }

    /* 
    Updates web properties based on the set of web property values provided. It expects the web property 
    values to be provided in the format they are received from the server.
    
    @param  aProps  Array of web property values.
    @private
    */
    handleSyncProps(aProps) {

        //  Loop through objects with synced props
        for (let i = 0; i < aProps.length; i++) {
            const tObj = aProps[i];

            //  Find WebObject
            const oWO = this.findObj(tObj.sO);
            if (oWO) {
                //  Loop through props and set them
                for (let x = 0; x < tObj.aP.length; x++) {
                    oWO._set(tObj.aP[x].sN, tObj.aP[x].sV, true, true);
                }

            } else {
                //  We place it in the cache
                this.cacheSyncProps(tObj);
            }
        }
    }

    /* 
    Updates advanced web properties based on the set of web property values provided. It expects the web 
    property values to be provided in the format they are received from the server.
    
    @param  aProps  Array of web property values.
    @private
    */
    handleAdvSyncProps(aAdvSyncP) {

        //  Store advanced sync props
        for (let i = 0; i < aAdvSyncP.length; i++) {
            const tP = aAdvSyncP[i];
            //  Find WebObject
            const oWO = this.findObj(tP.sO);

            if (oWO) {
                //  Loop through props and set them
                oWO._set(tP.sP, tP.tV, true, true);
            } else {
                //  We place it in the cache
                this.cacheAdvProp(tP);
            }
        }
    }

    /* 
    Executes a single client action based on the passed information.
    
    @param tAct Details of the client-action.
    @private
    */
    execClientAction(tAct) {
        //  Find object and function
        const oWO = this.findObj(tAct.sTarget)
        let sViewName;

        if (oWO) {
            const oFunc = oWO.findFunc(tAct.sName);
            if (typeof oFunc.fFunc === "function") {

                //  Make action data available as property
                if (tAct.iAttached > 0) {
                    if (tAct._tActionData) {  //  If this is a cached action then the attachment is stored in _tActionData (see storeViewLoadAction)
                        oWO._tActionData = tAct._tActionData;
                    } else {
                        oWO._tActionData = this.responseAttachment(tAct.iAttached);
                    }
                }

                //  Call client action
                try {

                    oFunc.fFunc.apply(oFunc.oEnv, tAct.aParams);
                } catch (oErr) {
                    this.handleError(oErr);
                }

                //  Clear action data
                oWO._tActionData = null;

            } else {
                this.handleError(new df.Error(999, "Action method not found '{{0}}' on object '{{1}}'", this, [tAct.sName, tAct.sTarget]));
            }
        } else {
            //  Determine the view name by parsing it out of the full target object
            sViewName = tAct.sTarget;
            if (sViewName.indexOf('.') > 0) {
                sViewName = sViewName.substr(0, sViewName.indexOf('.'));
            }

            //  Queue client actions performed on a view that is "preloaded" (pbOverrideStateOnShow functionality)
            if (this._oPreLoaded[sViewName]) {
                if (tAct.iAttached) {
                    tAct._tActionData = this.responseAttachment(tAct.iAttached);
                }
                this._oPreLoaded[sViewName].push(tAct);
            } else {
                this.handleError(new df.Error(999, "Could not find object '{{0}}'", this, [tAct.sTarget]));
            }
        }

    }


    responseAttachment(iIndex) {
        if (this._aResponseAttachments && this._aResponseAttachments.length > (iIndex - 1)) {
            return this._aResponseAttachments[iIndex - 1];
        }
        throw new df.Error(999, "Invalid response attachment index.", this);
    }

    /*
    This method puts new synchronized property values in the cache. This cache has the same structure as 
    in which the synchronized properties are sent. If properties where already in the cache it will 
    merge them and update to the new value. The cache is allows synchronized properties to be set on 
    views before they are loaded. The synchronized loading of views creates a need for this. This method 
    is called when synchronized properties are received for objects that don't exist.
    
    @param  tObj    The struct / JSON object representing the synchronized properties.
    @private
    */
    cacheSyncProps(tObj) {
        let bFound;

        //  See if we already have this object in cache
        for (let i = 0; i < this._aSyncPropCache.length; i++) {
            if (this._aSyncPropCache[i].sO === tObj.sO) {

                //  Now we need to merge the synced props into the existing cache object
                const tCacheObj = this._aSyncPropCache[i];

                for (let x = 0; x < tObj.aP.length; x++) {
                    bFound = false;

                    for (let y = 0; y < tCacheObj.aP.length && !bFound; y++) {
                        if (tCacheObj.aP[y].sN === tObj.aP[x].sN) {
                            tCacheObj.aP[y].sV = tObj.aP[x].sV;

                            bFound = true;
                        }
                    }
                    if (!bFound) {
                        tCacheObj.aP.push(tObj.aP[x]);
                    }
                }

                return;
            }
        }

        //  Else we can simply add the new object
        this._aSyncPropCache.push(tObj);
    }

    /* 
    This method puts a new advanced synchronized property in the cache. This cache has a flat structure 
    as in which advanced sync props are sent. If the property is already in the cache it will override 
    its value. This cache allows advanced synchronized properties to be set before their view is loaded 
    to the client.
    
    @param  tP      The struct / JSON object representing a single synchronized property..
    @private
    */
    cacheAdvProp(tP) {

        for (let i = 0; i < this._aAdvSyncPropCache.length; i++) {
            if (this._aAdvSyncPropCache[i].sO === tP.sO && this._aAdvSyncPropCache[i].sP === tP.sP) {
                this._aAdvSyncPropCache[i].tV = tP.tV;
                return;
            }
        }

        this._aAdvSyncPropCache.push(tP);
    }

    /*
    This method gets cached synchronized properties for a specific view. It goes through the cache and 
    returns and removes all the synchronized properties for that view. This happens when loading a view 
    and the caching of synchronized properties allows developers to WebSet on views before they are on 
    the client (the ASynchronized loading creates a need for this).
    
    @param  sView       The object name of the view.
    @param  aSyncProps  Reference to the synchronized properties array to which the result is added.
    @private
    */
    getCachedSyncProps(sView, aSyncProps, aAdvSyncP) {
        const sStart = sView + '.';
        const iLen = sStart.length;

        for (let i = 0; i < this._aSyncPropCache.length; i++) {
            //  Check if part of the view
            if (this._aSyncPropCache[i].sO === sView || this._aSyncPropCache[i].sO.substr(0, iLen) === sStart) {
                //  Add to result
                aSyncProps.push(this._aSyncPropCache[i]);

                //  Remove from cache
                this._aSyncPropCache.splice(i, 1);
                i--;
            }
        }

        for (let i = 0; i < this._aAdvSyncPropCache.length; i++) {
            //  Check if part of the view
            if (this._aAdvSyncPropCache[i].sO === sView || this._aAdvSyncPropCache[i].sO.substr(0, iLen) === sStart) {
                aAdvSyncP.push(this._aAdvSyncPropCache[i]);

                //  Remove from cache
                this._aAdvSyncPropCache.splice(i, 1);
                i--;
            }
        }
    }


    // - - - - - - -  Positioning and styling - - - - - - - - 



    set_psTheme(sVal) {
        if (this.psTheme !== sVal) {
            //  Remove the old theme from the body element
            if (document.body) {
                df.dom.removeClass(document.body, this.psTheme);
            }

            this.psTheme = sVal;
            this.updateCSS(true);
        }
    }

    /* 
    Setter for pbResponsive which will activate or deactivate the responsive system. It forwards this 
    call to the separate mode controller object.
    
    @param  bVal    The new value.
    @private
    */
    set_pbResponsive(bVal) {
        if (this._oModeControl) {
            if (bVal) {
                this._oModeControl.activate();
            } else {
                this._oModeControl.deactivate();
            }
        }
    }

    /* 
    Setter for the view alignment. The view is aligned during the resize process so just sending a 
    resize should do the job after the property is updated.
    
    @param  iVal    The new value.
     */
    set_peAlignView(iVal) {
        this.peAlignView = iVal;
        
        if(this._eElem){
            this._eElem.className = this.genClass();
            this.sizeChanged();
        }
    }

    /*
    Add the alignment class to the class names set to the outermost element.

    @private
    */
    genClass() {    
        let sClass = super.genClass();

        switch(this.peAlignView){
            case df.ciAlignCenter:
                sClass += " Web_VwCenter";
                break;
            case df.ciAlignRight:
                sClass += " Web_VwRight";
                break;
            default:
                sClass += " Web_VwLeft";
        }   

        return sClass;
    }

    updateCSS(bResize) {
        let sV;
        const that = this, sTheme = this.psTheme.trim();


        if (!this._eStyleSystem || !this._eStyleTheme || !this._eStyleApplication) {
            //  Determine version GET parameter
            sV = "?v=" + df.psVersionId;
            if (typeof (sDfBuildNr) === "string" && sDfBuildNr) {  //  Add a custom string to the version GET parameter of the URL
                sV += "." + sDfBuildNr;
            }

            //  Get references to existing CSS elements
            const aStyles = df.dom.query(document, "link", true);
            for (let i = 0; i < aStyles.length; i++) {
                if (aStyles[i].href.indexOf("DfEngine/system.css") > 0) {
                    this._eStyleSystem = aStyles[i];
                }
                if (aStyles[i].href.indexOf("CssThemes/") > 0 && aStyles[i].href.indexOf("theme.css") > 0) {
                    this._eStyleTheme = aStyles[i];
                }
                if (aStyles[i].href.indexOf("CssStyle/application.css") > 0) {
                    this._eStyleApplication = aStyles[i];
                }
            }

            //  Create system CSS include if needed
            if (!this._eStyleSystem) {
                this._eStyleSystem = df.dom.createCSSElem(this._sRootPath + "DfEngine/system.css" + sV);

                const eHead = document.head || document.getElementsByTagName("head")[0];
                if (eHead.firstChild) {
                    eHead.insertBefore(this._eStyleSystem, eHead.firstChild);
                } else {
                    eHead.appendChild(this._eStyleSystem);
                }
            }

            //  Create theme CSS include if needed
            if (!this._eStyleTheme) {
                this._eStyleTheme = df.dom.createCSSElem(this._sRootPath + "CssThemes/" + sTheme + "/theme.css" + sV);
                df.dom.insertAfter(this._eStyleTheme, this._eStyleSystem);
                // document.body.appendChild(this._eStyleTheme);
            }

            //  Create application CSS include if needed
            if (!this._eStyleApplication) {
                this._eStyleApplication = df.dom.createCSSElem(this._sRootPath + "CssStyle/application.css" + sV);
                df.dom.insertAfter(this._eStyleApplication, this._eStyleTheme);
            }

            if (document.body) {
                document.body.id = "OWEBAPP";
            }



        }

        //  Set theme classname on the body element
        if (document.body) {
            df.dom.addClass(document.body, this.psTheme);
        }

        //  Update theme path if needed
        if (this._eStyleTheme.href.indexOf(this._sRootPath + "CssThemes/" + sTheme + "/theme.css") < 0) {
            this._eStyleTheme.href = this._sRootPath + "CssThemes/" + sTheme + "/theme.css";
        }

        //  Call resize method after 'CSS Test' has finished
        if (bResize) {
            this.testCSS(function () {
                this.resize();

                setTimeout(function () {
                    try {
                        that.resize();
                    } catch (oErr) {
                        that.handleError(oErr);
                    }
                }, 200);
            });
        }
    }

    /*
    Tests if the CSS is loaded by creating an element with df_load_test ID and waiting to see if it gets a 
    size. It uses an observer to respond as soon as possible but also check with a timer in case the observer 
    somehow does not work.
    
    If no fFailed function is passed then fSuccess will always be called after a longer wait period. If fFailed 
    is passed (in the designer it is) we'll call it after 500ms.
    */
    testCSS(fSuccess, fFailed) {
        let oObserver, iCount = 0, bDone = false;

        const eTest = df.dom.create('<div id="df_load_test" style="position: absolute"></div>');

        const checksize = () => {
            if (!bDone && eTest.clientHeight >= 1) {
                oObserver.disconnect();
                eTest.parentNode.removeChild(eTest);

                bDone = true;
                fSuccess.call(this);
            }
            return bDone;
        };

        oObserver = new ResizeObserver((entries) => {
            checksize();
        });

        oObserver.observe(eTest);
        document.body.appendChild(eTest);

        const timer = () => {
            if (!checksize()) {
                if (fFailed) {
                    fFailed.call(this);
                } else {
                    if (iCount < 50) {
                        iCount++;
                        setTimeout(timer, 50);
                    } else {
                        fSuccess.call(this);
                    }
                }
            }
        }
        setTimeout(timer, 500);
    }

    /* 
    Handles the resize event of the browser window. It triggers the layout systems to recalculate sizes 
    and fires the OnResizeWindow and OnOrientationChange events to the server if needed. A small timeout 
    is used to reduce the number of times this process is performed as browsers might throw the resize
    event very often.
    
    @param  oEvent  Event object (see: df.events.DOMEvent)
    @private
    */
    onWindowResize(oEvent) {
        const that = this;

        if (this._tResizeTimeout) {
            clearTimeout(this._tResizeTimeout);
            this._tResizeTimeout = null;
        }

        this._tResizeTimeout = setTimeout(function () {
            try {
                that._tResizeTimeout = null;
                that.resize();
                that.windowResize();
            } catch (oErr) {
                that.handleError(oErr);
            }
        }, 50);
        // this.resize();

        //  Manually trigger the orientationchange event for internet explorer
        if (this.piScreenHeight === screen.width && this.piScreenWidth === screen.height) {
            if (df.sys.isIE) {
                this.onOrientationChange(oEvent);
            }
        }
    }

    /* 
    Triggers the OnResizeWindow event and notifies the views that they should trigger this event as 
    well.
    
    @private
    */
    windowResize() {

        //  Trigger OnResize events (on window and and views)
        this.fire("OnResizeWindow", [this.get_piWindowWidth(), this.get_piWindowHeight()]);

        for (let i = 0; i < this._aViews.length; i++) {
            this._aViews[i].windowResize(this.get_piWindowWidth(), this.get_piWindowHeight());
        }
    }

    onScroll(oEvent) {
        this.notifyScroll(this);
    }

    prepareSize() {
        const iRes = super.prepareSize();

        this._bStretch = this._bContainerStretch;

        return iRes;
    }

    resize() {
        let iMxVwH;

        //    Call standard resize procedures
        this.resizeHorizontal();
        this.resizeVertical();

        if (this.pbViewApp) {
            //  Determine viewport size
            if (this._eElem) {
                iMxVwH = this._iMiddleHeight - df.sys.gui.getVertBoxDiff(this._eRegionCenter, 0);
            }

            for (let i = 0; i < this._aViews.length; i++) {
                const oView = this._aViews[i];

                //  Views can be rendered without the webapp, so then we use the _eRenderTo element.
                if (!this._eElem && oView._eRenderTo) {
                    iMxVwH = df.dom.clientHeight(oView._eRenderTo) - df.sys.gui.getVertBoxDiff(oView._eRenderTo, 2);
                }


                if (oView._bRendered) {
                    oView.viewResize(iMxVwH);
                }
            }
        }

        this.notifyPosChange(this);

        // df.timeStop("resize", "Finished resizing!");
        //  Turn off size change switch
        this._bSizeChanged = false;
    }



    /* 
    Called by WebBaseUIObject to notify that a resize is needed because of a size change within the 
    control or container. As this usually occurs from within setters it is not uncommon for this to 
    occur multiple times the resize is not performed immediately but when the processing of the current 
    call is completed (using the _bSizeChanged switch). Another resize is performed after a small 
    timeout as there are still some unexplainable cases where a second resize causes a better result 
    than the first.
    
    @param  oSrcWO  The Web Object notifying the size change.
    @private
    */
    objSizeChanged(oSrcWO) {
        const that = this;

        this._bSizeChanged = true;

        if (!this._tResizeTimer) {
            that._tResizeTimer = setTimeout(function () {
                try {
                    that.resize();
                    that._tResizeTimer = null;
                } catch (oErr) {
                    that.handleError(oErr);
                }
            }, 30);
        }
    }

    /* 
    This method is called from the server when a resize needs to be forced somehow. It uses the 
    sizeChanged method which will force a resize after processing the call is finished and sets a timer 
    for a delayed resize.
    
    @client-action
    */
    forceResize() {
        const that = this;

        this.sizeChanged(true);

        setTimeout(function () {
            that.sizeChanged(true);
        }, 60);
    }

    /* 
    Handles the browsers OrientationChange event and triggers the server event. Note that for Internet 
    Explorer this method is called manually.
    
    @param  oEvent  Event object (see: df.events.DOMEvent)
    @private
    */
    onOrientationChange(oEvent) {
        let iOrientation;

        //  Update screen dimensions (these most likely changed!)
        this.piScreenHeight = screen.height;
        this.piScreenWidth = screen.width;

        //  Determine orientation (use own logic if DOM doesn't provide)
        if (typeof window.orientation === "number") {
            iOrientation = window.orientation;
        } else {
            iOrientation = (screen.height > screen.width ? 90 : 0);
        }

        //  Fire event to the server
        this.fire("OnOrientationChange", [iOrientation]);

    }


    // - - - - - - -  Generic framework functions - - - - - - - - 

    /*
    This method shows an info box with a message and a title. It tempolary uses the alert but will use 
    the WebModalDialog later.
    
    @param  sMessage   The message to display.
    @param  sCaption          Text displayed in the title bar.
    
    @client-action
    */
    showInfoBox(sMessage, sCaption) {
        function showInfo(tDetails) {
            var that = this;
            const iWindowWidth = this.get_piWindowWidth();

            const oDialog = new WebModalDialog(null, this);
            oDialog.psCaption = sCaption;
            oDialog.piMinWidth = (iWindowWidth > 420 ? 400 : iWindowWidth - 20);
            oDialog.piMinHeight = 80;   // 150;
            oDialog.psCSSClass = "WebMsgBox WebMsgBoxInfo";
            oDialog.pbScroll = true;

            const iViewArrayPos = this._aViews.length;
            that._aViews.push(oDialog);

            oDialog.OnSubmit.addListener(function (oEvent) {
                oDialog.hide();
            }, this);

            oDialog.OnHide.addListener(function (oEvent) {
                tDetails.bFinished = true;
                setTimeout(function () {
                    try {
                        that.processModal();
                        oDialog.destroy();
                        that._aViews.splice(iViewArrayPos, 1);
                    } catch (oErr) {
                        that.handleError(oErr);
                    }

                }, 20);
            }, this);

            const oContentPnl = new WebPanel(null, oDialog);
            oContentPnl.peRegion = df.ciRegionCenter;

            oDialog.addChild(oContentPnl);

            const oLabel = new WebLabel(null, oDialog);
            oLabel.psCaption = sMessage;
            oLabel.psCSSClass = "WebMsgBox_Text";
            oContentPnl.addChild(oLabel);

            const oButtonPnl = new WebPanel(null, oDialog);
            oButtonPnl.peRegion = df.ciRegionBottom;
            oButtonPnl.piColumnCount = 3;
            oButtonPnl.psCSSClass = "WebMsgBoxOneBtn";

            oDialog.addChild(oButtonPnl);

            const oCloseBtn = new WebButton(null, oDialog);
            oCloseBtn.psCaption = this.getTrans("ok");
            oCloseBtn.piColumnIndex = 2;
            oCloseBtn.pbShowLabel = false;
            oCloseBtn.OnClick.addListener(function (oEvent) {
                oDialog.hide();
            }, this);
            oButtonPnl.addChild(oCloseBtn);


            oDialog.show();

            this.ready(function () {
                oDialog.resize();
                oCloseBtn.focus();
            });
        }

        this._aModalQueue.push({
            fFunc: showInfo,
            bFinished: false,
            bDisplayed: false
        });

        this.processModal();
    }

    /*
    This method shows a message box with a message, title and a set of buttons. After a button is 
    clicked it will fire a server action to the provided object & message to handle the response. It 
    receives the message, title and list of buttons from the server. Note that the message box will be 
    queued in the alert queue so it will wait for other alerts to be closed before displaying. 
    
    @param  sMessage   The message to display.
    @param  sCaption   Text displayed in the title bar.
    
    @client-action
    */
    showMessageBox(sReturnObj, sReturnMsg, sMessage, sCaption, sLabelCSSClass, iDefaultButton) {

        //  Search for return object
        const oReturnObj = this.findObj(sReturnObj);
        if (!oReturnObj) {
            throw new df.Error(999, "Return WebObject not found '{{0}}'", this, [sReturnObj]);
        }

        //  Get reference to action data specifying the buttons
        const aButtons = this._tActionData;
        if (!aButtons) {
            throw new df.Error(999, "No buttons specified", this);
        }

        //  Call the real message box function
        this.showMsgBox(sMessage, sCaption, sLabelCSSClass, aButtons, iDefaultButton, function (iBtn, oDialog) {
            //  Make sure that the action mode for there return call is at least mode wait
            if (oReturnObj.getActionMode(sReturnMsg) < df.cCallModeWait) {
                oReturnObj.setActionMode(sReturnMsg, df.cCallModeWait);
            }

            //  Call the return message
            oReturnObj.serverAction(sReturnMsg, [iBtn], null, function () {
                oDialog.hide();
            });
        });
    }

    showMsgBox(sMessage, sCaption, sLabelCSSClass, aButtons, iDefaultButton, fHandler) {



        function showInfo(tDetails) {
            let oDialog, oLabel,  oContentPnl, oButtonPnl, oDefaultBtn = null, iWindowWidth = this.get_piWindowWidth();

            //  Create dialog with panel
            oDialog = new WebModalDialog(null, this);
            oDialog.psCaption = sCaption;
            oDialog.piMinWidth = (iWindowWidth > 500 ? 480 : iWindowWidth - 20);
            oDialog.piMinHeight = 100;    // 150;
            oDialog.pbShowClose = false;
            oDialog.psCSSClass = ("WebMsgBox " + sLabelCSSClass);
            oDialog.pbScroll = true;

            this._aViews.push(oDialog);

            oDialog.OnHide.addListener(function (oEvent) {
                tDetails.bFinished = true;
                setTimeout(() => {
                    try {
                        this.processModal();
                        oDialog.destroy();
                        let iIndex = this._aViews.indexOf(oDialog);
                        if (iIndex = -1) {
                            this._aViews.splice(iIndex, 1);
                        }
                    } catch (oErr) {
                        this.handleError(oErr);
                    }

                }, 20);

            }, this);

            //  Create content panel with message
            oContentPnl = new WebPanel(null, oDialog);
            oContentPnl.peRegion = df.ciRegionCenter;

            oDialog.addChild(oContentPnl);

            oLabel = new WebLabel(null, oDialog);
            oLabel.psCaption = sMessage;
            oLabel.psCSSClass = "WebMsgBox_Text";
            oContentPnl.addChild(oLabel);

            //  Create button panel
            oButtonPnl = new WebPanel(null, oDialog);
            oButtonPnl.peRegion = df.ciRegionBottom;
            oButtonPnl.piColumnCount = (aButtons.length * 2) + 2;

            // Mobile Adjustments....
            if (df.sys.isMobile) {
                if (aButtons.length === 2) {
                    // if two buttons let them occupy the entire width of the panel
                    oButtonPnl.piColumnCount = (aButtons.length * 2);
                }
                else if (aButtons.length > 2) {
                    oButtonPnl.piColumnCount = 1;
                }
            }

            // Set the panel's CSS class if there is only one button
            if (aButtons.length === 1) {
                oButtonPnl.psCSSClass = "WebMsgBoxOneBtn";
            } else if (aButtons.length === 2) {
                oButtonPnl.psCSSClass = "WebMsgBoxTwoButtons";
            } else {
                oButtonPnl.psCSSClass = "WebMsgBoxButtons";
            }

            oDialog.addChild(oButtonPnl);

            //  Handler executed when a button is clicked
            function handleBtnClick(oEvent) {
                fHandler.call(this, oEvent.oSource._iConfirmId, oDialog);
            }

            //  Generate buttons
            iDefaultButton = parseInt(iDefaultButton, 10);

            for (let i = 0; i < aButtons.length; i++) {
                const oBtn = new WebButton(null, oDialog);
                oBtn.psCaption = aButtons[i];
                oBtn.piColumnIndex = ((i * 2) + 1);
                oBtn.piColumnSpan = 2;
                oBtn.pbShowLabel = false;
                oBtn._iConfirmId = (i + 1);
                oBtn.OnClick.addListener(handleBtnClick);

                // Handle Mobile Adjustments....
                if (df.sys.isMobile) {
                    if (aButtons.length === 2) {
                        // if two buttons let them occupy the entire width of the panel
                        oBtn.piColumnIndex = (i * 2);
                    }
                    else if (aButtons.length > 2) {
                        oBtn.piColumnIndex = 0;
                        oBtn.piColumnSpan = 0;
                    }
                }
                else {
                    if (i === 0) {
                        oBtn.psCSSClass = "WebMsgBoxFirstBtn";
                    }
                    else if (i === (aButtons.length - 1)) {
                        oBtn.psCSSClass = "WebMsgBoxLastBtn";
                    }
                }

                oButtonPnl.addChild(oBtn);

                if (oBtn._iConfirmId === iDefaultButton) {
                    oDefaultBtn = oBtn;
                }
            }

            oDialog.show();

            //  Resize and give focus when application is ready
            this.ready(function () {
                oDialog.resize();
                if (oDefaultBtn) {
                    oDefaultBtn.focus();
                }
            });

        }

        this._aModalQueue.push({
            fFunc: showInfo,
            bFinished: false,
            bDisplayed: false
        });

        this.processModal();
    }

    /* 
    Easy API for showing a WAF Yes No confirmation. It still is asynchronous and the passed handler 
    will be called when finished.
    
    @code
    oWebApp.showYesNo("Sure?", function(bYes){
        alert(bYes);
    } this);
    @code
    
    @param  sMessage    Message shown.
    @param  fHandler    Handler message handling the response (get boolean parameter indicating yes or no).
    @param  oOptEnv     (optional) Environment object for handler function.
    */
    showYesNo(sMessage, fHandler, oOptEnv) {
        this.showMsgBox(sMessage, this.getTrans("confirm"), "WebMsgBoxConfirm", [this.getTrans("yes"), this.getTrans("no")], 0, function (iBtn, oDialog) {
            try {
                if (fHandler) {
                    fHandler.call(oOptEnv || this, (iBtn === 1));
                }
            } catch (oErr) {
                this.handleError(oErr);
            }
            oDialog.hide();
        });
    }

    /*
    This method will process the next item in the modal queue. It starts by removing dialogs marked as 
    finished from the queue. Then it will display the next dialog in the queue (if there is one and it 
    isn't already displayed). The modal queue contains dialogs that need to be displayed modally. We 
    don't want to display them on top of each other and since they are not really modal we will have to 
    queue them. In practice the queue contains methods that will display the dialog.
    */
    processModal() {
        if (this._aModalQueue.length > 0) {
            //  Clear finished alerts from the queue
            while (this._aModalQueue[0] && this._aModalQueue[0].bFinished) {
                this._aModalQueue.shift();
            }

            //  Display next (if needed)
            if (this._aModalQueue.length > 0 && !this._aModalQueue[0].bDisplayed) {
                this._aModalQueue[0].bDisplayed = true;
                this._aModalQueue[0].fFunc.call(this, this._aModalQueue[0]);
            }
        }
    }

    /* 
    Used to queue an action in the modal queue. Note that this action won't be blocking the modal queue 
    once it is finished. Examples of usage are showView, navigateToPage, navigateRefresh and 
    navigateOpenWindow.
    
    @param  fFunc   Function that executes the action.
    @param  oEnv    Environment used to execute the function (this).
    @private
    */
    queueModal(fFunc, oEnv) {
        this._aModalQueue.push({
            fFunc(tDetails) {
                fFunc.call(oEnv || null);

                //  We don't want to hold up other dialogs in the queue
                tDetails.bFinished = true;
                this.processModal();
            },
            bFinished: false,
            bDisplayed: false
        });

        this.processModal();
    }

    /*
    This method writes text to the console of JavaScript debuggers. This can be used for debugging 
    purposes. A singleton method df.log is used to do this which adds timing and checks if the console 
    is available. 
    
    @param  sText   String with text to show on the console.
    @client-action
    */
    log(sText) {
        df.log(sText);
    }

    /*
    This method determines the translation based on a label.
    
    @param  sLbl        The label of the translation.
    @param  bOptNull    If true then null is returned if the translation is not found, else it returns
                        the label wrapped by {{ ... }}.
    @return The translation.
    @private
    */
    getTrans(sLbl, bOptNull) {
        if (this._oTranslations[sLbl]) {
            return this._oTranslations[sLbl];
        }
        if (bOptNull) {
            return null;
        }
        return "{{" + sLbl + "}}";
    }

    /*
    Override because the webapp object is referred to as "".
    */
    getLongName() {
        return "";
    }

    /*
    Override as the webapp object name is not part of the long name.
    @private
    */
    getLongNamePrnt() {
        return "";
    }

    /*
    Initializes the translation system. The translations are delivered as name value pairs and we store 
    them as object properties for quick access. Translations for dates are stored globally because they 
    are also accessed by some of the global date formatting functions in the system library.
    
    @client-action
    @private
    */
    initTranslations() {
        this.initTrans(this._tActionData);
    }

    /* 
    Initializes the translation system based on the array of translations.
    
    @param  aTrans  Array of translations [{ sN : "label", sV : "translation" }].
    @private
    */
    initTrans(aTrans) {
        //  Store tanslations in quick access object
        for (let i = 0; i < aTrans.length; i++) {
            this._oTranslations[aTrans[i].sN] = aTrans[i].sV;
        }

        //  We store the dates globally
        df.lang = {
            monthsLong: [
                this.getTrans("january"),
                this.getTrans("february"),
                this.getTrans("march"),
                this.getTrans("april"),
                this.getTrans("may"),
                this.getTrans("june"),
                this.getTrans("july"),
                this.getTrans("august"),
                this.getTrans("september"),
                this.getTrans("october"),
                this.getTrans("november"),
                this.getTrans("december")
            ],
            monthsShort: [
                this.getTrans("jan"),
                this.getTrans("feb"),
                this.getTrans("mar"),
                this.getTrans("apr"),
                this.getTrans("mayShort"),
                this.getTrans("jun"),
                this.getTrans("jul"),
                this.getTrans("aug"),
                this.getTrans("sep"),
                this.getTrans("oct"),
                this.getTrans("nov"),
                this.getTrans("dec")
            ],
            daysShort: [
                this.getTrans("sun"),
                this.getTrans("mon"),
                this.getTrans("tue"),
                this.getTrans("wed"),
                this.getTrans("thu"),
                this.getTrans("fri"),
                this.getTrans("sat")
            ],
            daysLong: [
                this.getTrans("sunday"),
                this.getTrans("monday"),
                this.getTrans("tuesday"),
                this.getTrans("wednesday"),
                this.getTrans("thursday"),
                this.getTrans("friday"),
                this.getTrans("saturday")
            ]
        };
    }

    // - - - - - - -  Error handling - - - - - - - - 

    showError(iErrNum, iErrLine, sErrText, sCaption, bUserError) {
        //  Create error object and call default handler function
        this.handleError(new df.Error(
            df.toInt(iErrNum),
            sErrText,
            this,
            null,
            null,
            true,
            df.toBool(bUserError),
            sCaption,
            null,
            df.toInt(iErrLine)
        ));
    }


    /*
    df.Error = function Error(iNumber, sText, bOptUsr, oOptSource, oOptTarget, bOptSrv){
        this.iNumber = iNumber;
        this.sText = sText;
        this.bUserError = !!bOptUsr;
        this.oSource = oOptSource || null;
        this.oTarget = oOptTarget || null;
        this.bServer = !!bOptSrv;
        this.iLine = iOptLine;
        this.sDetailHtml = sOptDetailHtml || null;
    }
    */

    /*
    Handles a single error and displays it in a modal dialog unless it is a JavaScript error which it 
    leaves to the JavaScript debuggers. The modal queue is used to make sure that we don't display 
    dialogs on top of each other.
    
    @param  oError  The error object.
    */
    handleError(oError) {
        function displayError(tDetails) {
            let that = this, oLabel, oDetailsBox, sCaption;
            const aDetails = [], iWindowWidth = this.get_piWindowWidth();

            //  Determine title
            if (!oError.bServer) {
                sCaption = oError.sCaption || this.getTrans("error_title_client", true) || "Unhandled Program Error on the client";
            } else {
                sCaption = oError.sCaption || this.getTrans("error_title_server");
            }


            //  Create dialog
            const oDialog = new WebModalDialog(null, this);
            oDialog.psCaption = sCaption;
            oDialog.piMinWidth = (iWindowWidth > 520 ? 500 : iWindowWidth - 20);
            oDialog.piMinHeight = (oError.bUserError ? 80 : 180);    // (oError.bUserError ? 150 : 240);
            oDialog.psCSSClass = (oError.bUserError ? "WebMsgBox WebMsgBoxWarning" : "WebMsgBox WebMsgBoxError");

            const iViewArrayPos = this._aViews.length;
            that._aViews.push(oDialog);

            oDialog.OnSubmit.addListener(function (oEvent) {
                try {
                    oDialog.hide();
                } catch (oErr) {
                    that.handleError(oErr);
                }
            }, this);

            oDialog.OnHide.addListener(function (oEvent) {
                tDetails.bFinished = true;
                setTimeout(function () {
                    try {
                        that.processModal();
                        oDialog.destroy();
                        that._aViews.splice(iViewArrayPos, 1);
                    } catch (oErr) {
                        that.handleError(oErr);
                    }

                }, 20);
            }, this);

            const oContentPnl = new WebPanel(null, oDialog);
            oContentPnl.peRegion = df.ciRegionCenter;

            oDialog.addChild(oContentPnl);

            //  Create label
            oLabel = new WebLabel(null, oContentPnl);
            oLabel.psCaption = oError.sText;
            oLabel.psCSSClass = "WebMsgBox_Text";
            oContentPnl.addChild(oLabel);

            //  Create error details
            if (!oError.bUserError) {
                oLabel = new WebLabel(null, oContentPnl);
                aDetails.push('Error: ', oError.iNumber);

                if (oError.bServer) {
                    if (oError.iLine) {
                        aDetails.push('\nLine:', oError.iLine);
                    }
                } else {
                    if (oError.oSource) {
                        if (oError.oSource instanceof WebObject) {
                            aDetails.push('\nObject:', oError.oSource.getLongName());
                        }
                    }
                }
                oLabel.psCaption = aDetails.join("");
                oContentPnl.addChild(oLabel);

                //  Add details field
                if (oError.sDetailHtml) {
                    oDialog.piMinHeight = 300;
                    oDialog.piHeight = 400;

                    if (oError.sDetailHtml.match(/<body*>|<html*>/gi)) {
                        oDetailsBox = new WebIFrame(null, oContentPnl);
                        oDetailsBox.pbFillHeight = true;
                        oDetailsBox.pbShowLabel = false;
                        oDetailsBox.psCSSClass = "WebErrorDetails";
                        oDetailsBox.setHtmlContent(oError.sDetailHtml);
                        oContentPnl.addChild(oDetailsBox);
                    } else {
                        oDetailsBox = new WebHtmlBox(null, oContentPnl);
                        oDetailsBox.pbFillHeight = true;
                        oDetailsBox.pbShowBox = true;
                        oDetailsBox.pbScroll = true;
                        oDetailsBox.pbShowLabel = false;
                        oDetailsBox.psCSSClass = "WebErrorDetails";
                        oDetailsBox.psHtml = oError.sDetailHtml;

                        oContentPnl.addChild(oDetailsBox);
                    }
                }
            }


            //  Create buttons
            const oButtonPnl = new WebPanel(null, oDialog);
            oButtonPnl.peRegion = df.ciRegionBottom;
            oButtonPnl.piColumnCount = 3;
            oButtonPnl.psCSSClass = "WebMsgBoxOneBtn";

            oDialog.addChild(oButtonPnl);

            const oCloseBtn = new WebButton(null, oDialog);
            oCloseBtn.psCaption = this.getTrans("ok", true) || "OK";
            oCloseBtn.piColumnIndex = 2;
            oCloseBtn.pbShowLabel = false;
            oCloseBtn.OnClick.addListener(function (oEvent) {
                oDialog.hide();
            }, this);
            oButtonPnl.addChild(oCloseBtn);


            oDialog.show();
            this.ready(function () {
                oDialog.resize();
                oCloseBtn.focus();
            });

        }

        //  We only handle our own errors, we throw the others 
        if (oError instanceof df.Error) {

            //  Fire user event for custom display
            if (this.OnError.fire(this, { oError: oError })) {
                //  See if the object has custom error handling (usually DEO's)
                if (oError.oTarget && oError.oTarget.displayError && oError.oTarget.pbRender && oError.oTarget.pbVisible) {
                    oError.oTarget.displayError(oError.iNumber, oError.sText);
                } else {
                    // Queue a special alert
                    this._aModalQueue.push({
                        fFunc: displayError,
                        bFinished: false,
                        bDisplayed: false
                    });
                    this.processModal();
                }
            }
        } else {
            throw oError;
        }
    }


    // - - - - - - -  Generic web functionallity - - - - - - - - 

    /* 
    Updates the title of the page.
    
    @param  sTitle  The new title for the page.
    @client-action
    */
    setPageTitle(sTitle) {
        document.title = sTitle;
    }

    /*
    Lets the browser navigate to a different page. The mode determines if the page is opened in a new 
    window / new tab or the current window.
    
    @param  sUrl    The URL to open.
    @param  eMode   The mode to upen the URL (df.ciOpenNewWindow, df.ciOpenNewTab or 
                    df.ciOpenCurrentWindow).
    
    @client-action
    */
    navigateToPage(sUrl, eMode) {
        this.queueModal(function () {
            eMode = parseInt(eMode, 10); // Convert from string

            if (eMode === df.ciOpenSameWindow) {
                window.location.href = sUrl;
            } else {
                if (eMode === df.ciOpenNewWindow) {
                    window.open(sUrl, '_blank_' + df.dom.piDomCounter++, 'width=700, height=500, resizable=yes');
                } else { // df.ciOpenNewTab
                    window.open(sUrl, '_blank');// +  df.dom.piDomCounter++);
                }
            }
        }, this);
    }

    /*
    Opens a new window that will load the specified URL. Note that popup blockers might block this new window.
    
    @param  sUrl     The URL to open.
    @param  iWidth   The width of the window in pixels.
    @param  iHeight  The height of the window in pixels.
    
    @client-action
    */
    navigateNewWindow(sUrl, iWidth, iHeight) {
        this.queueModal(function () {
            window.open(sUrl, '_blank_' + df.dom.piDomCounter++, 'width=' + iWidth + ', height=' + iHeight + ', resizable=yes, location=yes');
        });
    }

    /*
    Reloads the current page. This is usually done after a logout.
    
    @client-action
    */
    navigateRefresh() {
        this.queueModal(function () {
            window.location.reload();
        });
    }

    /* 
    Pushes an item to the history stack (HTML5 history management). If action data is available it will 
    be added as extra data.
    
    @param  sUrl    The new current URL.
    @param  sTitle  The new page title.
    @client-action    
    */
    historyPushState(sUrl, sTitle) {
        const state = { df: true, vt: this._tActionData };

        if (history && history.pushState) {
            history.pushState(state, (sTitle || null), (sUrl || null));
        }
    }

    /* 
    Replaces the current item on the history stack (HTML5 history management). If action data is 
    available it will be added as extra data.
    
    @param  sUrl    The new current URL.
    @param  sTitle  The new page title.
    @client-action    
    */
    historyReplaceState(sUrl, sTitle) {
        const state = { df: true, vt: this._tActionData };

        if (history && history.replaceState) {
            history.replaceState(state, (sTitle || null), (sUrl || null));
        }
    }

    /* 
    Handles the browser popstate event and triggers the HistoryPopState server action passing on the 
    details. If an extra information object is attached to the event and it appears to be a valuetree 
    then it will pass that as well.
    
    @param  oEvent  DOM Event
    @private
    */
    onPopState(oEvent) {
        const state = oEvent.e.state;
        let vt = null;

        if (state && state.df) {
            if (state.vt && typeof state.vt.v !== "undefined" && state.vt.c) {
                vt = state.vt;
            }
        }
        this.serverAction("HistoryPopState", [document.title, document.location.href], vt);

        oEvent.stop();
    }

    /* 
    Handles the browser OnHashChange event and triggers the LocationHashChange event. Note that if a 
    HistoryPopState just occurred it will be canceled to prevent duplicate reaction.
    
    @param  oEvent  DOM Event
    @private
    */
    onHashChange(oEvent) {
        //  Only send hashchange if this isn't a popstate
        this.cancelServerAction("HistoryPopState");
        this.serverAction("LocationHashChange", [document.location.hash]);
    }


    /* 
    Getter function that reads the current window width.
    
    @return The current window width in (virtual) pixels.
     */
    get_piWindowWidth() {
        return df.dom.windowWidth();
    }

    /* 
    Getter function that reads the current window height.
    
    @return The current window height in (virtual) pixels.
     */
    get_piWindowHeight() {
        return df.dom.windowHeight();
    }

    /* 
    Getter function that reads the current mode directly of the mode controller.
    
    @return Current mode in which we are running.
    */
    get_peMode() {
        if (this._oModeControl) {
            return this._oModeControl.peMode;
        }
    }

    /* 
    Getter function that reads the result of the device detection isMobile check.
    
    @return True if this device is detected as a mobile device.
    */
    get_pbIsMobile() {
        return df.sys.isMobile;
    }

    /*
    Getter function that returns the current location hash (part of the URL behing the hash bang #).
    
    @return Location hash like "Dashboard/Order-1231"
    */
    get_psLocationHash() {
        return window.location.hash;
    }

    /*
    Getter function that determines the current timezone offset in minutes.
    
    @return Time zone offset in minutes (-120 for UTC+2).
    */
    get_piBrowserTimezoneOffset() {
        return new Date().getTimezoneOffset();
    }

    /*
    Getter function that reads the browser language.
    
    @return Browser language string ("en-US" or "nl" or ..).
    */
    get_pasBrowserLanguages = function () {
        const vt = df.sys.vt.serialize(navigator.languages || (navigator.language && [navigator.language]) || ["en-US"]);

        return function () { return vt; };
    }();

    /*
    Returns the 'top layer' element. This is the insertion point for controls like floating panels. 
    Usually this will return document.body, unless a control is located inside a modal dialog.
    */
    topLayer() {
        return document.body;
    }

    /*
    Override since we are webapp.
    */
    getWebApp() {
        return this;
    }
}