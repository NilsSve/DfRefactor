import { WebObject } from './WebObject.js';
import { df } from '../df.js';
/*
Class:
    df.WebGeoLocation
Extends:
    df.WebObject

A simple wrapper for the navigator.geolocation API. It makes
    
Revision:
    2017/07/26  (HW, DAW) 
        Initial version.
    2020/03/04  (HW, DAW)
        Merged into the framework.
*/
export class WebGeoLocation extends WebObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Enables position tracking / watching
        this.prop(df.tBool, "pbTracking", false);
        this.prop(df.tBool, "pbAutoStart", true);
        this.prop(df.tBool, "pbAutoStop", true);

        //  Properties representing latest position
        this.prop(df.tNum, "pnLatitude", 0.0);
        this.prop(df.tNum, "pnLongitude", 0.0);
        this.prop(df.tNum, "pnAccuracy", 0.0);
        this.prop(df.tNum, "pnSpeed", 0.0);
        this.prop(df.tNum, "pnHeading", 0.0);

        //  Configuration options
        this.prop(df.tBool, "pbEnableHighAccuracy", false);
        this.prop(df.tInt, "piMaxTimeout", 0);
        this.prop(df.tInt, "piMinTimeout", 200);
        this.prop(df.tInt, "piMaxAge", 0);

        //  Events for tracking
        this.event("OnLocationChange", df.cCallModeDefault);
        this.event("OnError", df.cCallModeDefault);

        //  Mark position props as synchronized
        this.addSync("pnLatitude");
        this.addSync("pnLongitude");
        this.addSync("pnAccuracy");
        this.addSync("pnSpeed");
        this.addSync("pnHeading");

        // @privates
        this._iWatchId = null;
        this._oView = null;
        this._iLocChTime = 0;
        this._iLocChTimer = null;
    }

    /*
    Initialization.
    
    @private
    */
    create() {
        super.create();

        this.set_pbTracking(this.pbTracking);   //  If tracking is on we simply enable

        //  Check if we are in a view, if so we listen to its OnShow and OnHide events, else we just start it
        this._oView = this.getView();
        if (this._oView) {
            this._oView.OnShow.on(this.showView, this);
            this._oView.OnHide.on(this.hideView, this);
        } else {
            if (this.pbAutoStart) {
                this.set("pbTracking", false);
            }
        }
    }

    /*
    Cleanup.
    
    @private
    */
    destroy() {
        super.destroy();

        if (this._oView) {
            this._oView.OnShow.off(this.showView, this);
            this._oView.OnHide.off(this.hideView, this);
        }
    }


    /*
    This method handles the OnShow event of the view which starts the timer if needed.
    
    @param  oEvent  Event object.
    @private
    */
    showView(oEvent) {
        if (this.pbAutoStart) {
            this.set("pbTracking", true);
        }
    }

    /*
    This method handles the OnHide event of the view which stops the timer if needed.
    
    @param  oEvent  Event object.
    @private
    */
    hideView(oEvent) {
        if (this.pbAutoStop) {
            this.set("pbTracking", false);
        }
    }


    /*
    Performs a single getCurrentPosition to query the location once. Performs a callback with the result.
    
    @param  sCallbackMsg    Serveraction to which callback is sent.
    @param  sCallbackObj    Name of callback WO (if none this is used).
    @client-action
    */
    queryLocation(sCallbackMsg, sCallbackObj) {
        const that = this;

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(function (position) {
                that.updateProps(position);

                that.serverAction("QueryLocation_Callback", [sCallbackMsg, sCallbackObj, 0, df.fromNumber(that.pnLatitude), df.fromNumber(that.pnLongitude), df.fromNumber(that.pnAccuracy), df.fromNumber(that.pnSpeed), df.fromNumber(that.pnHeading)]);
            },
                function (locationerror) {
                    that.serverAction("QueryLocation_Callback", [sCallbackMsg, sCallbackObj, locationerror.code, "0", "0", "0", "0", "0"]);
                    that.fire("OnError", [locationerror.code, locationerror.message]);
                }, this.geoOptions());
        }
    }

    /*
    Updates position properties based on a GeolocationPosition object.
    
    @param  position    GeolocationPosition object.
    @private
    */
    updateProps(position) {
        this.pnLatitude = position.coords.latitude;
        this.pnLongitude = position.coords.longitude;
        this.pnAccuracy = position.coords.accuracy || 0;
        this.pnSpeed = position.coords.speed || 0;
        this.pnHeading = position.coords.heading || 0;
    }

    /*
    Fires the actual server OnLocationChange event.
    
    @private
    */
    fireLocationChange() {
        this.fireEx({
            sEvent: "OnLocationChange",
            aParams: [df.fromNumber(this.pnLatitude), df.fromNumber(this.pnLongitude), df.fromNumber(this.pnAccuracy), df.fromNumber(this.pnSpeed), df.fromNumber(this.pnHeading)],
            oEnv: this,
            sAltServerName: "TriggerLocationChange"
        });

        this._iLocChTime = (new Date()).getTime();
    }

    /*
    Tracker callback function that fires OnLocationChange after updating position properties.
    
    @param  position    GeolocationPosition object.
    @private
    */
    trackPosition(position) {
        const that = this;

        this.updateProps(position);

        const iDiff = (new Date()).getTime() - this._iLocChTime;
        if (this.piMaxTimeout > 0 && iDiff < this.piMaxTimeout) {
            if (!this._iLocChTimer) {
                this._iLocChTimer = setTimeout(function () {
                    that.fireLocationChange();
                    this._iLocChTimer = null;
                }, iDiff);
            }
        } else {
            that.fireLocationChange();
        }
    }

    /*
    Setter for pbTracking that enables or clears watchPosition based on the value.
    
    @param  bVal    New value.
    */
    set_pbTracking(bVal) {
        const that = this;

        if (bVal !== (this._iWatchId !== null)) {
            if (bVal) {
                if (navigator.geolocation) {
                    this._iWatchId = navigator.geolocation.watchPosition(function (position) {
                        that.trackPosition(position);
                    }, function (locationerror) {
                        that.fire("OnError", [locationerror.code, locationerror.message]);
                    }, this.geoOptions());
                }
            } else {
                if (navigator.geolocation && this._iWatchId !== null) {
                    navigator.geolocation.clearWatch(this._iWatchId);
                }

                this._iWatchId = null;
            }

        }
    }

    /*
    Creates a PositionOptions object based on configuration properties.
    
    @private
    */
    geoOptions() {
        return {
            enableHighAccuracy: this.pbEnableHighAccuracy,
            maximumAge: (this.piMaxAge > 0 ? this.piMaxAge : Infinity),
            timeout: (this.piMaxTimeout > 0 ? this.piMaxTimeout : Infinity)
        };
    }


}