import { df } from '../df.js';

/*
Class:
    df.WebObject
Extends:
    Object

This class is the core of the new web application framework. It represents a Visual DataFlex Web 
Object on the client. It has the core functionality to support synchronized properties, getters, 
setters, server actions and the object tree structure as we know it in Visual DataFlex. It will be 
created and managed by the df.WebApp class. All classes represented as server-side web objects in 
Visual DataFlex will inherit from this class.
    
Revision:
    2011/06/26  (HW, DAW) 
        Initial version.
*/
export class WebObject {
    constructor(sName, oParent) {

        this._sName = sName;
        this._oParent = oParent || null;

        this._oTypes = {}; //  Stores the property types used for automatic type conversion.
        this._oSynced = {}; //  Stores which properties are being synchronized.
        this._aChildren = []; //  Array of child web objects.


        this._oServerActionModes = {};
        this._oServerWaitMsg = {};

        this._tActionData = null; //  Will contain custom data (two dimensional string array) if a client-action contains data
        this._oPropRuleStore = null; //  Will store the property rules for mobile solutions

        this._bStandalone = !sName; //  If true this object isn't bound to a server-side object and not part of the tree

        this._oWebApp = null; //  Optimization: will contain reference to the webapp object
        this._oView = null; //  Optimization: will contain reference to wrapping view object

        this._bIsWO = true; //  Used to identify initialized web objects
        this._bIsDynamic = false; // Client side flag to indicate if this object was dynamically created (by the WebDynamicObjectContainer)
    }

    /*
    This function is called after the web object is created and the web properties have received their 
    initial values. It can be implemented to do initialization based on the web property values before 
    the rendering process starts.
    */
    create(tDef) {

    }

    /* 
    Called to destroy a web object. We destroy child web objects as well and clear the standard 
    references from and to the parent element.
    
    @private
    */
    destroy() {
        let oWO;

        //  Unregister from web property store
        if (this._oPropRuleStore) {
            this.getWebApp()._oModeControl.remWO(this);
        }

        //  Destroy children
        while (oWO = this._aChildren.pop()) {
            oWO.destroy();
        }

        //  Clear references between parent
        this._oWebApp = null;
        this._oView = null;

        if (this._oParent) {
            delete this._oParent[this._sName];
        }
        this._oParent = null;
    }

    /*
    Called to register a direct child.
    
    @private
    */
    addChild(oChild) {
        this._aChildren.push(oChild);
    }

    /*
    This method defines a property on the current object. It will create the regular JavaScript 
    property, set its initial value and it will store its type. The property type will be used for data 
    conversions when values are received from the server (as a string).
    
    @code
    this.prop(df.tString, "psHtml", "");
    this.prop(df.tInt, "piMaxLength", 0);
    this.prop(df.tBool, "pbFillHeight", false);
    @code
    
    @param  eType   The property type (df.tString, df.tInt, df.tBool, ..).
    @param  sName   Name of the property.
    @param  sVal    Intial value of the property.
    */
    prop(eType, sName, sVal) {
        this[sName] = sVal;

        this._oTypes[sName] = eType;
    }

    /*
    This method converts values received from the server to the local JavaScript type. For example a 
    df.tBool value "1" becomes true and "0" or "-1" becomes false.
    
    @param  val     The value (usually of type string).
    @param  eType   The value type to convert to (df.tString, df.tInt, df.tBool, ..).
    */
    toLocalType(val, eType) {
        switch (eType) {
            case df.tString:
                return val;
            case df.tBool:
                return df.toBool(val);
            case df.tInt:
                return df.toInt(val);
            case df.tNumber:
                return df.toNumber(val);
            case df.tAdv:
                return val;
            default:
                return val;
        }
    }

    /* 
    This method converts local values to the type / format expected by the server. This means that they 
    are converted to strings and a Boolean for example becomes "1" or "0". 
    
    @param  val     The value in the local type.
    @param  eType   The value type to convert to (df.tString, df.tInt, df.tBool, ..).
    */
    toServerType(val, eType) {
        switch (eType) {
            case df.tString:
                if (typeof val === "string") {
                    return val;
                }
                if (val) {
                    return val.toString();
                }
                return "";
            case df.tBool:
                return df.fromBool(val);
            case df.tNumber:
                return df.fromNumber(val);
            case df.tAdv:
                return val;
            default:
                if (val !== null) {
                    return val.toString();
                } else {
                    return val;
                }
        }
    }

    /*
    This method gets a property value. If a getter method is defined (get_<propname>) then this function 
    will be called else it will return the value of the actual property.
    
    @param  sProp       The name of the property.
    @returns    The value of the property (in its actual type).
    */
    get(sProp) {
        //  Use getter if available
        if (this['get_' + sProp]) {
            return this['get_' + sProp]();
        }
        return this[sProp];
    }

    /*
    This method sets a property value. If a setter function is defined it will call that 
    (set_<propname>) with the value. The real property will be set after the setter is called. If a 
    property is not synchronized yet it will be marked as synchronized unless bOptNoSync is passed as 
    true. Note that the value is not converted so it needs to be provided in the proper type.
    
    @param  sProp       The name of the property.
    @param  val         The value of the property (in its actual type).
    @param  bOptNoSync  (optional) If true the property will not become a synchronized property by setting it.
    */
    set(sProp, val, bOptNoSync) {
        let bRes;

        //  Call setter if available
        if (this['set_' + sProp]) {
            bRes = this['set_' + sProp](val);
        }

        //  Set real property if available
        if (this[sProp] !== undefined && bRes !== false) {
            this[sProp] = val;
        }

        //  Mark as synchronized
        if (bOptNoSync !== true) {
            this.addSync(sProp);
        }
    }

    /*
    This method is used when the value is set from the server. If it is called for a synchronized 
    property then the setter will need to be executed and the property needs to be marked as 
    synchronized while that doesn't happen for an initial value. The extra parameters control this. It 
    also passes an extra Boolean parameter to the setter indicating that it is called from the server. 
    Some setters might use this to behave slightly different.
    
    @param  sProp       The name of the property.
    @param  val         The value of the property (in its actual type).
    @param  bSetter     If true the setter is executed if available.
    @param  bSync       If true the property is marked as synchronized.
    @private
    */
    _set(sProp, val, bSetter, bSync) {
        //  Cast value to type if known
        if (this._oTypes[sProp]) {
            val = this.toLocalType(val, this._oTypes[sProp]);
        }

        //  Call setter if available
        if (bSetter) {
            if (this['set_' + sProp]) {
                this['set_' + sProp](val, true);
            }
        }

        //  Always set real value
        this[sProp] = val;

        if (bSync) {
            this.addSync(sProp);
        }
    }

    /*
    This method marks a property as synchronized property.
    
    @param  sProp       The name of the property.
    @private
    */
    addSync(sProp) {
        if (!this._oSynced.hasOwnProperty(sProp)) {
            this._oSynced[sProp] = true;
        }
    }

    /*
    This method removes a property from the synchronized list so it won't be synchronized any more.
    
    @param  sProp       The name of the property.
    @private
    */
    unSync(sProp) {
        if (this._oSynced.hasOwnProperty(sProp)) {
            delete this._oSynced[sProp];
        }
    }

    /*
    This method gathers the synchronized properties for this Web Object.
    
    @param  aObjs   Reference to the array of synchronized property objects to which the properties are added.
    @param  aAdvProps   Reference to the array in which the advanced sync props are gathered.
    @private
    */
    getSynced(aObjs, aAdvProps) {
        let val
        const aProps = [], sObj = this.getLongName();

        //  Gather synchronized properties
        for (const sProp in this._oSynced) {
            if (this._oSynced.hasOwnProperty(sProp)) {
                val = this.get(sProp);

                if (this._oTypes[sProp]) {
                    val = this.toServerType(val, this._oTypes[sProp]);
                }
                if (val === undefined) {
                    val = null;
                }

                //  Switch between advanced and local synchronized properties
                if (this._oTypes[sProp] === df.tAdv) {
                    aAdvProps.push({
                        sO: sObj,
                        sP: sProp,
                        tV: val
                    });
                } else {
                    aProps.push({
                        sN: sProp,
                        sV: val
                    });
                }
            }
        }

        //  If synced props where found we add it to the list with wrappers
        if (aProps.length > 0) {
            aObjs.push({
                sO: sObj,
                aP: aProps
            });
        }

        //  Move into children
        for (let i = 0; i < this._aChildren.length; i++) {
            if (!this._aChildren[i]._bStandalone) {
                this._aChildren[i].getSynced(aObjs, aAdvProps);
            }
        }
    }

    /*
    Function that generates the full name like "oWebApp.oCustomerView.oCustomer_Name".
    
    @returns String with the full name.
    */
    getLongName() {
        if (this._oParent) {
            return this._oParent.getLongNamePrnt(this) + this._sName;
        }
        return this._sName;
    }

    /*
    Recurses up to the parent, used by getLongName();. Can be augmented to change the separator (like dynamic container does).
    
    @private
    */
    getLongNamePrnt() {
        return this.getLongName() + ".";
    }

    /*
    @returns The WebApp object to which this web object belongs.
    @private
    */
    getWebApp() {
        if (this._oWebApp) {
            return this._oWebApp;
        }

        this._oWebApp = (this._oParent && this._oParent.getWebApp && this._oParent.getWebApp()) || null;

        return this._oWebApp;
    }

    /*
    @returns The WebView object to which this web object belongs.
    @private
    */
    getView() {
        if (this._oView) {
            return this._oView;
        }

        this._oView = (this._oParent && this._oParent.getView && this._oParent.getView()) || null;

        return this._oView;
    }

    /*
    @returns The depth of the object as seen from the view it is located in.
    @private
    */
    getObjectLevel() {
        const oView = this.getView();
        let iLevel = 0, oObj = this;

        while (oObj !== oView) {
            oObj = oObj._oParent;
            iLevel++;
        }

        return iLevel;
    }

    /*
    This method calls a server method on the server. It will perform all necessary synchronizations. 
    Note that the method on the server should be defined inside the corresponding object and needs to be 
    published using WebPublish.
    
    @param  sMethod    Name of the method that needs to be called.
    @param  aOptParams  Array with the parameters (as primitive types).
    @param  fOptHandler  (optional) Method that needs to be called when the AJAX call is finished.
    @param  oOptEnv   (optional) Object that is used as the context when the handler is called.
    */
    serverAction(sMethod, aOptParams, tOptData, fOptHandler, oOptEnv) {
        this.serverActionEx({
            sMethod: sMethod,
            aParams: aOptParams || [],
            tData: tOptData || null,
            fHandler: fOptHandler,
            oHandlerEnv: oOptEnv
        });
    }

    /*
    Extended version of serverAction where parameters are passed in using a configuration object. It 
    allows more options to be provided.
    
    {
        sMethod : "..",         // Name the of the server-side method
        aParams: ["..", ".."],  // Array with parameters
        tData : [ .. ],         // Action data (value tree)
        fHandler : ..,          // Reference to a handler function when finished
        oHandlerEnv : ..,       // Reference to environment object when handler function is called
        aViews : [ .. ]         // Array of views that need to be synchronized, is extended with the 
                                   view to which the object belongs. Can contain object references and 
                                   string view names.
    }
    
    @param oConf    Configuration object with details for the calls. See example above.
    */
    serverActionEx(oConf) {
        let sMethod;
        const oAction = new df.ServerAction();

        //  Configure action
        oAction.oWO = this;
        oAction.sAction = sMethod = oConf.sMethod;
        oAction.aParams = oConf.aParams || [];
        oAction.tData = oConf.tData || null;
        oAction.fHandler = oConf.fHandler || null;
        oAction.oHandlerEnv = oConf.oHandlerEnv || this;
        oAction.aViews = oConf.aViews || [];
        oAction.oPlatformSpecific = oConf.oPlatformSpecific || {};

        //  Add current view
        const oView = this.getView();
        if (oView) {
            oAction.aViews.push(oView);
        }

        //  Determine call mode
        if (oConf.eCallMode) {
            oAction.eCallMode = oConf.eCallMode;
        } else {
            oAction.eCallMode = this._oServerActionModes[sMethod.toLowerCase()] || df.cCallModeDefault;
            if (oAction.eCallMode === df.cCallModeProgress && this._oServerWaitMsg[sMethod.toLowerCase()]) {
                oAction.sProcessMessage = this._oServerWaitMsg[sMethod.toLowerCase()];
            }
        }

        //  Pass on to webapp object
        this.getWebApp().handleAction(oAction);
    }

    /* 
    Cancels a server action (if it isn't already sent).
    
    @param  sMethod     The name of the server method that is being called.
    */
    cancelServerAction(sMethod) {
        this.getWebApp().cancelAction(this, sMethod);
    }

    /* 
    Determines if a server action is pending (waiting to be sent to the server).
    
    @param  sMethod     Name of the server action.
    @return True if the action is pending.
    */
    hasPendingServerAction(sMethod) {
        return this.getWebApp().hasPendingAction(this, sMethod);
    }

    /* 
    This client action is called when an extra round-trip is needed. This is usually done to update the 
    UI before performing an operation that needs more time. The first parameter is the name of the 
    published procedure on the server handling the call-back where the other parameters are passed back 
    together with the action data.
    
    @param  sFunction   Name of the server action to call back to.
    @param  [1-17]      Are sent back to the server as parameters.
    
    @client-action
    */
    callBack(sFunction) {
        const aParams = [];

        for (let i = 1; i < arguments.length; i++) {
            aParams.push(arguments[i]);
        }

        this.serverAction(sFunction, aParams, this._tActionData);
    }


    /*
    This method registers the call mode for when server action occurs. It stores the mode combined with 
    the name of the method so that the serverAction method knows in which mode a call should be send. 
    
    Supported modes are:
    cCallModeDefault - The request is sent asynchronously, the user interface still responds and other 
    calls can be made/registered while it happens.
    cCallModeWait - The request is sent asynchronously but no other calls can be registered during 
    the call and the user interface will become unresponsive. A waiting cursor is shown.
    cCallModeProgress - The request is sent asynchronously but no other calls can be registered during 
    the call and a modal progress dialog will be shown.
    
    @param  sMethod      Name of the server action (like 'OnClick' or 'Request_Find').
    @param  eMode        The call mode.
    
    @client-action
    */
    setActionMode(sMethod, eMode, sOptWaitMessage) {
        if (eMode) {
            this._oServerActionModes[sMethod.toLowerCase()] = df.toInt(eMode);

            if (sOptWaitMessage) {
                this._oServerWaitMsg[sMethod.toLowerCase()] = sOptWaitMessage;
            }
        } else {
            throw new df.Error(999, "Assertion: Invalid server-action mode '{{0}}' for message '{{1}}'", this, [eMode, sMethod]);
        }
    }

    getActionMode(sMethod) {
        return this._oServerActionModes[sMethod.toLowerCase()] || df.cCallModeDefault;
    }

    /*
    This method is used to declare events and replaces the separate declaration of the properties. It 
    automatically defines the 'pbServer..' and 'psClient..' properties and creates the client-side event 
    object.
    
    @param  sName       Name of the event (like 'OnClick')
    @param  eOptMode    The call mode (see setActionMode).
    */
    event(sName, eOptMode, sOptServerName) {
        this.setActionMode(sName, (arguments.length > 1 ? eOptMode : df.cCallModeDefault));

        this[sName] = new df.events.JSHandler(sOptServerName || sName);

        this.prop(df.tBool, "pbServer" + sName, false);
        this.prop(df.tString, "psClient" + sName, "");
    }

    /*
    This method fires an event by calling its client-side and server-side handlers. It will first call 
    the global JavaScript method defined as the property psClientOnEvent. Then it calls the advanced 
    client-side handlers in the OnEvent object. If pbServerOnEvent is set to true then it will call the 
    server. If psLoadViewOnEvent property set then it will display this view. If it is not loaded it 
    will load this by calling the server-side event.
    
    @param  sName       Name of the event.
    @param  aOptParams  Optional array with parameters passed to the event handler.
    @param  fOptHandler Optional handler function called after the event is handled (eventually after the server call).
    @param  oOptEnv     Optional environment object for the fOptHandler function (the current WO is used if nothing is passed).
    @return True if an event handler is being called.
    */
    fire(sName, aOptParams, fOptHandler, oOptEnv) {
        return this.fireEx({
            sEvent: sName,
            aParams: aOptParams,
            fHandler: fOptHandler,
            oEnv: oOptEnv
        });
    }

    /* 
    Extended version of fire which takes a configuration object as parameter. 
    
    this.fireEx({
        sEvent : "OnSomething",
        aParams : [ .. ],
        fHandler : func..,
        oEnv : this,
        aViews : [ .. ],
        bSkipClient : false,
        bSkipServer : false,
        tActionData : null,
        sAltServerName : null
    }
    */
    fireEx(oConf) {
        let bResult = false, bASync = false, oJsHandler = null;

        //df.debug('Event: ' + sName + " " + df.sys.json.stringify(aOptParams || []) + " on " + this.getLongName() + "  (Call mode: " + this._oServerActionModes[sName.toLowerCase()] + " )");

        const sName = oConf.sEvent;

        if (!sName) {
            throw new df.Error(999, "Event name missing in fireEx.", this);
        }

        if (!oConf.aParams || !(oConf.aParams instanceof Array)) {
            oConf.aParams = [];
        }

        //  Create event object
        const oEvent = new df.events.JSEvent(this, {
            aParams: oConf.aParams,
            oConf: oConf,
            bClient: false,
            bServer: false,
            sReturnVal: null,
            aViews: oConf.aView || []
        });

        //  Search for & call global event listener
        if (this['psClient' + sName] && !oConf.bSkipClient) {
            const oFunc = this.findFunc(this['psClient' + sName]);
            if (typeof oFunc.fFunc === 'function') {
                oEvent.bClient = bResult = true;
                try {
                    if (oFunc.fFunc.call(oFunc.oEnv, oEvent) === false) {
                        oEvent.stop();
                    }
                } catch (oError) {
                    this.getWebApp().handleError(oError);
                }
            } else {
                this.getWebApp().handleError(new df.Error(999, "Event handler function '{{0}}' set as 'psClient{{1}}' not found.", this, [this['psClient' + sName], sName]));
            }
        }

        //  Search for advanced client-side handler
        if (!oEvent.bCanceled) {
            if (this[sName] instanceof df.events.JSHandler) {
                oJsHandler = this[sName];
                //  Determine if there are clients
                oEvent.bClient = bResult = (bResult || oJsHandler.aListeners.length > 0);
                oJsHandler.fire(this, oEvent);
            }
        }

        //  Call the server
        if (!oEvent.bCanceled) {
            var sServerName = oConf.sAltServerName || (oJsHandler && oJsHandler.sServerName) || sName;

            if (this['pbServer' + sName] && df.toBool(this['pbServer' + sName]) && !oConf.bSkipServer) {
                bResult = true;
                bASync = true;

                //  Perform server call
                this.serverAction(sServerName, oConf.aParams, oConf.tActionData || null, function (oActEvent) {
                    //  Set results
                    oEvent.sReturnValue = oActEvent.sReturnValue;
                    oEvent.bServer = true;

                    //  Call the handler
                    if (oConf.fHandler) {
                        oConf.fHandler.call(oConf.oEnv || this, oEvent);
                    }
                }, this);
            }
        }

        //  Call the handler
        if (!bASync) {
            if (oConf.fHandler) {
                oConf.fHandler.call(oConf.oEnv || this, oEvent);
            }
        }

        return bResult;
    }

    /*
    Inserts a new child after the passed existing child.
    */
    insertChild(oChild, iIndex) {
        this._aChildren.splice(iIndex, 0, oChild);
    }

    /*
    Renders the given child. 
    
    If eOptChild is passed as a parameter, this function will not freshly 
    render the oChild object, but rather used the passed DOM element.
    */
    renderChild(oChild, eOptChild) {
        // Subclasses of cWebObject class will implement this method
    }

    /*
    Removes the child from the parent's list of children.
    */
    removeChild(oChild) {
        const iIndex = this._aChildren.indexOf(oChild);
        if (iIndex !== -1) {
            this._aChildren.splice(iIndex, 1);
        }
        if(this[oChild._sName]){
            delete this[oChild._sName];
        }
    }

    /*
    Unrenders the given child.
    */
    unrenderChild(oChild) {
        // Subclasses of cWebObject class will implement this method
    }

    /* 
    Called by the server for each rule (or when a rule changes at runtime). It stores the rule in the 
    property rule store (_oPropRuleStore).
    
    @param  sProp   Name of the property.
    @param  eMode   The mode constant (integer).
    @param  sValue  Value for the rule.
    @client-action
    */
    propRule(sProp, eMode, sValue) {
        const oWebApp = this.getWebApp();
        let bFound = false;

        eMode = df.toInt(eMode);

        //  Create the rule store and register with the mode controller
        if (!this._oPropRuleStore) {
            this._oPropRuleStore = {};

            if (oWebApp._oModeControl) {
                oWebApp._oModeControl.regWO(this);
            } else {
                throw new df.Error(999, "Mobile mode controller not available!", this);
            }
        }

        if (!this._oPropRuleStore[sProp]) {
            //  Create property entry when needed
            this._oPropRuleStore[sProp] = {
                sDefault: null,
                aRules: [],
                bActive: false
            };
        } else {
            //  Check and update for existing rule
            for (let i = 0; i < this._oPropRuleStore[sProp].aRules.length; i++) {
                if (this._oPropRuleStore[sProp].aRules[i].eM === eMode) {
                    bFound = true;
                    this._oPropRuleStore[sProp].aRules[i].sV = sValue;
                }
            }

        }

        //  If no existing property was found we need to add the rule
        if (!bFound) {
            this._oPropRuleStore[sProp].aRules.push({
                eM: eMode,
                sV: sValue
            });

            //  Sort the rules by the mode for quick applying
            this._oPropRuleStore[sProp].aRules.sort(function (a, b) {
                return b.eM - a.eM;
            });
        }


        //  Signal the mode controller so that it can apply the changed rules
        oWebApp._oModeControl.enforceRule(this, sProp);
    }

    /* 
    This is the standardized way of finding functions to execute on client actions and psClient... events. 
    It gets passed the function name as a string and it will return a reference to that function and the 
    object it found it on. Dot notation is allowed to find the object on which the function is executed 
    where this and window are supported to explicitly search in the local (the current web object) or 
    global scope. If window or this is not used as the first identifier it will automatically try to 
    find the function locally first and if not available there it will look for it globally.
    
    Examples:
    "myFunction"         -> Returns the function with the name "myFunction" on the the current object. If 
                            not found it will return the global function with name "myFunction".
    "this.myFunction"    -> Only searches for "myFunction" on the current object.  
    "window.myFunction"  -> Only searches for "myFunction" on the global (window) object.
    "oObj.myFunction"    -> Searches for the function on the oObj property of the current object, if 
                            oObj is not available locally it searches for a global oObj object.
    "window.oObj.oObj2.myFunction" -> Searches for the function on the oObj2 
                                      property of the global oObj object.
    
    @param  sFunc   String containing the function path.
    @return An object with both the function (fFunc) and the object where it is found on (oEnv) where 
            fFunc will be null or undefined if not found. { fFunc : <function>, oEnv : <environment> }
    */
    findFunc(sFunc) {
        let fFunc = null, oCur = null;
        if (sFunc) {

            //  Split into parts
            const aParts = sFunc.split(".");

            //  Go over objects in the string
            while (aParts.length > 1) {
                const sCur = aParts.shift();

                if (!oCur) {
                    //  At first level window and this are supported to explicitly determine local or global
                    if (sCur === "window") {
                        oCur = window;
                    } else if (sCur === "this") {
                        oCur = this;
                    } else {
                        //  If not explicitly defined we first look locally
                        if (typeof (this[sCur]) === "object") {
                            oCur = this[sCur];
                        } else {
                            const oGlob = df.sys.ref.getGlobalObj();  //  If window is used we assume that window is the global object but here we establish that dynamically
                            if (typeof (oGlob[sCur]) === "object") {
                                oCur = oGlob[sCur];
                            }
                        }
                    }
                } else {
                    oCur = oCur[sCur];
                }
            }

            //  Find the function
            const sCur = aParts[0];
            if (oCur) {   //  If an object was specified we look in there
                fFunc = oCur[sCur];
            } else if (typeof (this[sCur]) === "function") {    //  Else we first look locally
                fFunc = this[sCur];
                oCur = this;
            } else {
                const oGlob = df.sys.ref.getGlobalObj();  //  If window is used we assume that window is the global object but here we establish that dynamically
                if (typeof (oGlob[sCur]) === "function") {  //  Then we look at the global scope
                    fFunc = oGlob[sCur];
                    oCur = oGlob;
                }
            }
        }

        return { fFunc: fFunc, oEnv: oCur };
    }

    /* 
    Checks if the passed web object is a parent of this web object.
    
    @param  oPrnt   Web object to search.
    @return True if the passed web object is a parent of this. 
    */
    isParent(oPrnt) {
        let oObj = this;

        while (oObj) {
            if (oObj == oPrnt) {
                return true;
            }
            oObj = oObj._oParent;
        }

        return false;
    }
};