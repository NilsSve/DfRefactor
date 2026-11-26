import { dev } from './sys/dev.js';

/*
Class:
    df.MobRuleController
Extends:
    Object

This class is the client-side handler of web property rules. While the rules are stored on the 
WebObject itself this class is responsible for enforcing modes and rules. It detects the initial 
mode and listens to the window resize to update the mode when needed. The WebApp class will 
initialize an instance of the class.
    
The web property rules are defined in DataFlex code using the WebSetRule command and send to the 
client as client actions on the WebObject. The WebObject stores them in its oPropRuleStore object so 
that this controller can use them. When a WebObject has rules defined it will register itself on 
this object as mode listener.
    
Revision:
    2014/12/09  (HW, DAW) 
        Initial version.
*/
export class MobRuleController {
    constructor(oWebApp) {
        this._oWebApp = oWebApp;
        this.peMode = -1;
        this.pbActive = true;

        this._aWOs = [];

        this._aModes = [
            { eM: df.modeDesktop, sCSS: "df-ModeDesktop" },
            { eM: df.modeTablet, sCSS: "df-ModeTablet" },
            { eM: df.modeTabletLandscape, sCSS: "df-ModeTabletLandscape" },
            { eM: df.modeTabletPortrait, sCSS: "df-ModeTabletPortrait" },
            { eM: df.modeMobile, sCSS: "df-ModeMobile" },
            { eM: df.modeMobileLandscape, sCSS: "df-ModeMobileLandscape " },
            { eM: df.modeMobilePortrait, sCSS: "df-ModeMobilePortrait" }
        ];

        this.init();
    }

    /* 
    Initialize when the DOM is ready.
    */
    init() {
        this.detectMode();

        df.dom.ready(function () {
            df.dom.on("resize", window, this.onWindowResize, this);
            df.dom.on("orientationchange", document, this.onWindowResize, this);
            this.detectMode();
        }, this);
    }

    /* 
    Clear event handlers when destroying the object.
    
    @private
    */
    destroy() {
        df.dom.off("resize", window, this.onWindowResize, this);
        df.dom.off("orientationchange", document, this.onWindowResize, this);
    }

    /* 
    Called by the WebObject to register itself as mode listener when it gets its first rule.
    
    @param  oWO     The web object.
    */
    regWO(oWO) {
        this._aWOs.push(oWO);
    }

    /* 
    Unregisters a WebObject as mode listener.
    
    @param  oWO     The web object.
    */
    remWO(oWO) {
        const i = this._aWOs.indexOf(oWO);
        if (i >= 0) {
            this._aWOs.splice(i, 1);
        }
    }

    /* 
    Enforces a specific mode.
    
    @param  eMode   The mode constant.
    */
    enforceMode(eMode) {
        const that = this;

        //  Store the mode
        this.peMode = eMode;

        //  Update CSS classes on body element
        df.dom.ready(function () {
            const eMode = (that.pbActive ? that.peMode : 0);
            for (let i = 0; i < that._aModes.length; i++) {
                df.dom.toggleClass(document.body, that._aModes[i].sCSS, that._aModes[i].eM <= eMode);
            }

            that._oWebApp.sizeChanged();
        }, this);

        //  Loop over objects with rules
        for (let i = 0; i < this._aWOs.length; i++) {
            const oWO = this._aWOs[i];

            //  Loop over properties with rules of the object
            for (const sProp in oWO._oPropRuleStore) {
                if (oWO._oPropRuleStore.hasOwnProperty(sProp)) {
                    this.enforceRule(oWO, sProp);
                }
            }
        }
    }

    /* 
    Enforces a property its rules based on the current mode.
    
    @param  oWO     WebObject.
    @param  sProp   Name of the property.
    */
    enforceRule(oWO, sProp) {
        const eMode = (this.pbActive ? this.peMode : 0);

        //  Check if mode set
        if (eMode >= 0) {
            //  Get property rules
            const tDet = oWO._oPropRuleStore[sProp];

            //  Only proceed if not synchronized
            if (!oWO._oSynced[sProp]) {

                //  Store default value
                if (tDet.sDefault === null) {
                    tDet.sDefault = oWO.get(sProp);
                }

                //  Detect which rule to apply (loop over the sorted rules)
                for (let i = 0; i < tDet.aRules.length; i++) {
                    if (tDet.aRules[i].eM <= eMode) {
                        oWO._set(sProp, tDet.aRules[i].sV, true, false);
                        tDet.bActive = true;
                        return;
                    }
                }

                //  If a rule was applied but the current mode doesn't apply a specific rule we reset the original rule.
                if (tDet.bActive) {
                    oWO.set(sProp, tDet.sDefault, true);
                    tDet.bActive = false;
                }
            }
        }
    }

    /* 
    Standard mode detect (works purely on screen size). Will update the mode if it actually changed.
    */
    detectMode() {
        let eMode = df.modeDesktop, iWidth, iHeight, bLandscape;

        dev.detectDevice();
        if (dev.isMobile) {
            eMode = this.detectOrientation();
            bLandscape = (eMode == df.modeMobileLandscape);

            // We need this to determine mobile or tablet.
            iWidth = window.screen.width;
            iHeight = window.screen.height;
        } else {
            //  On desktop browsers we use the screen size as this allows us to do good demo's
            iWidth = df.dom.windowWidth();
            iHeight = df.dom.windowHeight();

            bLandscape = iWidth > iHeight;
        }

        //  Now that we have established dimensions and landscape vs portrait we can us that to guess the device
        if (iWidth < 580 || (bLandscape && iHeight < 420)) {
            eMode = (bLandscape ? df.modeMobileLandscape : df.modeMobilePortrait);
        } else if (iWidth < 1100 || dev.isMobile) {
            eMode = (bLandscape ? df.modeTabletLandscape : df.modeTabletPortrait);
        }


        if (eMode !== this.peMode && this.pbActive) {
            //alert("Detected mode: " + eMode + " Landscape: " + bLandscape + " Screenwidht: " + iWidth + " Screenheight: " + iHeight + " isMobile:  "+ dev.isMobile + " orientation: " + window.orientation);
            this.enforceMode(eMode);
        }

    }

    /*
    In mobile, uses native browser API's to determine the current orientation (landscape or portrait) and returns this as a DF constant for convenience.
    */
    detectOrientation() {
        let dfOrientation = df.modeMobilePortrait; // Default to portrait just in case..

        if (window.screen.orientation) {
            if (window.screen.orientation.type.indexOf("portrait") >= 0) {
                dfOrientation = df.modeMobilePortrait;
            } else if (window.screen.orientation.type.indexOf("landscape") >= 0) {
                dfOrientation = df.modeMobileLandscape;
            }
        } else if (window.orientation) { // Fallback for older browsers, but checking for existence just to be sure as this has been deprecated for a while
            if (window.orientation == 90 || window.orientation == -90) {
                dfOrientation = df.modeMobileLandscape;
            }
        }

        return dfOrientation;
    }

    /*
    Listens to the window resize event and calls the mode detection on resize.
    
    @param  oEvent  See df.events.DomEvent.
    */
    onWindowResize(oEvent) {
        this.detectMode();
    }

    /* 
    Activates the responsive system which means setting pbActive to true and reapplying the current 
    mode.
    */
    activate() {
        if (!this.pbActive) {
            this.pbActive = true;

            this.enforceMode(this.peMode);
        }
    }

    /* 
    Deactivates the responsive system which means setting pbActive to true and reapplying the mode where 
    enforeMode will look at pbActive and use 0 as the mode when deactivated. 
    */
    deactivate() {
        if (this.pbActive) {
            this.pbActive = false;

            this.enforceMode(this.peMode);
        }
    }
}