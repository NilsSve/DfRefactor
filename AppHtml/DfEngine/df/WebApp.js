import { JSONCall } from './ajax/JSONCall.js';
import { BaseApp } from './BaseApp.js';


/*
Class:
    df.WebApp
Extends:
    df.BaseApp

This class is the main class of the DataFlex Engine that has the logic for loading application 
definitions of the server and creation of the Web Objects. An instance of this class should be 
created for every application within the page. It will act as the main API to initialize and render 
web applications and views. A lot of global logic like error handling and server actions are 
implemented in this class.

It inherits from df.WebBaseContainer because it can contain and manage visual controls (panels and 
mainly views). Views are a special case when rendering since they render to the center panel area by 
default.

@code
var oWebApp = new df.WebApp("WebService.wso");

oWebApp.displayApp("#viewport");
@code
The example above shows how to create a webapp object that will communicate with the 
'WebService.wso' web-service and it will render to the '#viewport' element within the page. This 
renders the entire webapp including global panels en menu's.

@code
var oWebApp = new df.WebApp("WebService.wso");

oWebApp.displayView("oOrderView", "#viewport");
@code
The example above shows how to create a webapp object but only render a single view.
*/
export class WebApp extends BaseApp {
    constructor(sOptWebService) {
        super();

        this.psWebService = sOptWebService || "WebServiceDispatcher.wso";
        this.pbXHRWithCredentials = false;

        this._bPanels = true;

        this.pbViewApp = true;
    }

    sendCall(oCall) {
        return new Promise((resolve, reject) => {
            //  Create & send the call
            let oRequest = new JSONCall("CallAction", this.assembleRequest(oCall), this.psWebService, this);
            oRequest.pbWithCredentials = this.pbXHRWithCredentials;
            oRequest.bSilent = true;
            oRequest.onFinished.addListener(function (oEvent) {
                try {
                    //  Parse response
                    let tData = oEvent.oSource.getResponseValue();

                    resolve(tData);
                } catch (oErr) {
                    reject(oErr);
                }
            }, this);

            oRequest.onError.addListener(function (oEvent) {
                reject(oEvent.oError);
            }, this);
            try {
                oRequest.send(true);
            } catch (oErr) {
                reject(oErr);
            }
        });
    }



    position() {

    }


}