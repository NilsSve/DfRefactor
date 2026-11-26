import { BaseApp } from './BaseApp.js';

/*
Class:
    df.LocalApp
Extends:
    df.BaseApp

Used by the cLocalWebControlHost and cLocalWebAppHost classes to display framework controls.
*/
export class LocalApp extends BaseApp {
    constructor(bViewHost) {
        super();

        if (window.chrome.webview) {
            df.dom.on("message", window.chrome.webview, this.onWebMessageReceived, this);
        } else {
            throw new df.Error(999, "LocalApp requires chromium webview message API to function!");
        }

        this._bPanels = bViewHost;
        this.pbViewApp = bViewHost;
    }

    afterRender() {
        super.afterRender();

        this.syncObserver();
    }

    /*
    Observes the document object model to detect changes. If there are it will synchronize the web 
    properties because changes to the DOM potentially mean changes to web properties.
    */
    syncObserver() {
        let bIdle = false;

        const sync = () => {
            bIdle = false;
            this._bCallTimeout = false;
            this.serverAction("SynchronizeProps");
            this._bCallTimeout = true;
        }


        // create a new instance of `MutationObserver` named `observer`,
        // passing it a callback function
        const observer = new MutationObserver(function () {
            if (!bIdle) {
                bIdle = true;
                window.requestIdleCallback(sync);
            }
        });

        // call `observe()` on that MutationObserver instance,
        // passing it the element to observe, and the options object
        observer.observe(this._eElem, {
            subtree: true,
            childList: true,
            attributes: true
        });

        // observe does not catch input changes, so we also listen to the input element (and rely on bubbling)
        df.dom.on("input", this._eElem, function (oEv) {
            if (!bIdle) {
                bIdle = true;
                window.requestIdleCallback(sync);
            }
        }, this);
    }

    /*
    Implements the sending of call to send the call via a webmessage to the host process.
    */
    sendCall(oCall) {
        return oCall.oPromise = new Promise((resolve, reject) => {
            let aAddionalObjects = [];
            oCall.aActions.forEach((oAct) => {
                if (oAct.oPlatformSpecific.aAdditionalObjects) {
                    aAddionalObjects = aAddionalObjects.concat(oAct.oPlatformSpecific.aAdditionalObjects)
                }
            });

            const tReq = this.assembleRequest(oCall);
            oCall._resolve = resolve;
            oCall._reject = reject;

            df.debug("Sending call..");
            df.debug(tReq);

            if (aAddionalObjects.length > 0) {
                window.chrome.webview.postMessageWithAdditionalObjects(tReq, aAddionalObjects);
            } else {
                window.chrome.webview.postMessage(tReq);
            }
        });
    }

    /*
    Handles calls from the host, which are usually in response to a pending call but they 
    can also be triggered by the host.
    */
    onWebMessageReceived(oEvent, bSuccess) {
        const tData = oEvent.e.data;

        if (this._oSendingCall) {
            df.debug("Received response:");
            df.debug(tData);

            this._oSendingCall._resolve(tData);
        } else {
            df.debug("Received host message..");
            df.debug(tData);

            this.processResponse(tData, null);
        }
    }
}