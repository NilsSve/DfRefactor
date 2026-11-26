import { WebObject  } from './WebObject.js';
import { df } from '../df.js';

/*
Class:
    df.WebTimer
Extends:
    df.WebObject

This class contains a simple timer object that allows developers to easily build user interfaces 
that have to refresh regularly. It works a lot like the windows DfTimer class but with this 
framework the timer has to run on the client and call the server.
    
Revision:
    2012/11/30  (HW, DAW) 
        Initial version.
*/
export class WebTimer extends WebObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Public API
        this.prop(df.tBool, "pbAutoStart", true);
        this.prop(df.tBool, "pbAutoStop", true);
        this.prop(df.tInt, "piInterval", 2000);
        this.prop(df.tBool, "pbRunning", false);
        this.prop(df.tBool, "pbWaitForCall", true);

        this.event("OnTimer", df.cCallModeDefault);

        //  Privates
        this._tInterval = null;
        this._tTimeout = null;
        this._oView = null;

        this.addSync("pbRunning");
    }

    /*
    This method initializes the timer. It attaches event listeners to the view object for automatic 
    starting / stopping or starts the timer right away.
    
    @private
    */
    create() {
        super.create();

        //  Check if we are in a view, if so we listen to its OnShow and OnHide events, else we just start it
        this._oView = this.getView();
        if (this._oView) {
            this._oView.OnShow.on(this.showView, this);
            this._oView.OnHide.on(this.hideView, this);
        } else {
            if (this.pbAutoStart) {
                this.pbRunning = true;
                this.trigger();
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
    This method fires the OnTimer event to the server when it is triggered. It will call the trigger 
    method when finished to control the next timeout.
    
    @private
    */
    timer() {
        if (this.pbRunning) {
            this.fire("OnTimer", [], function () {
                this.trigger();
            });
        }
    }

    /*
    This method is the central method of this timer and it sets / clears the timeout or interval. 
    
    @private
    */
    trigger() {
        const that = this;

        if (this.pbRunning) {
            if (this.pbWaitForCall) {
                if (this._tInterval) {
                    clearInterval(this._tInterval);
                    this._tInterval = null;
                }
                if (this._tTimeout) {
                    clearTimeout(this._tTimeout);
                }

                this._tTimeout = setTimeout(function () {
                    that.timer();
                }, this.piInterval);
            } else if (!this._tInterval) {
                this._tInterval = setInterval(function () {
                    that.timer();
                }, this.piInterval);
            }
        } else {
            if (this._tInterval) {
                clearInterval(this._tInterval);
                this._tInterval = null;
            }
            if (this._tTimeout) {
                clearTimeout(this._tTimeout);
                this._tTimeout = null;
            }
        }
    }

    /*
    This setter method for pbRunning starts / stops the timer. It updates the property an calls the 
    trigger method to make sure that the timer is started or stopped.
    
    @param bVal     The new value.
    */
    set_pbRunning(bVal) {
        this.pbRunning = bVal;

        this.trigger();
    }

    /*
    This setter method piInterval updates the timeout between the calls. If we are using the setInterval 
    API we need to clear the current interval. We then call the trigger method to make sure the new 
    timeout / interval is properly set.
    
    @param iVal     The new value.
    */
    set_piInterval(iVal) {
        if (this.piInterval !== iVal) {
            this.piInterval = iVal;

            if (this._tInterval) {
                clearInterval(this._tInterval);
                this._tInterval = null;
            }

            this.trigger();
        }
    }

    /*
    Setter method for pbWaitForCall that updates the intervals used by calling the trigger method.
    
    @param  bVal    The new value.
    */
    set_pbWaitForCall(bVal) {
        this.pbWaitForCall = bVal;

        this.trigger();
    }

    /*
    This method handles the OnShow event of the view which starts the timer if needed.
    
    @param  oEvent  Event object.
    @private
    */
    showView(oEvent) {
        if (this.pbAutoStart) {
            this.pbRunning = true;
            this.trigger();
        }
    }

    /*
    This method handles the OnHide event of the view which stops the timer if needed.
    
    @param  oEvent  Event object.
    @private
    */
    hideView(oEvent) {
        if (this.pbAutoStop) {
            this.pbRunning = false;
            this.trigger();
        }
    }
}