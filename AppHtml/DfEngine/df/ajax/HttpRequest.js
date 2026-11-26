import { df } from '../../df.js';
import { events } from '../events.js';

/*
Name:
    df.ajax.HttpRequest
Type:
    Prototype
    
Wrapper of the XmlHttpRequest object that allows easy usage for generic HTTP requests. Includes 
framework event handling and error checking.
    
Revisions:
    2008/01/15  Restructured into the new namespacing system with the new 
    notation. Moved the soap functionallity to the SoapCall prototype to 
    simplify the usage. (HW, DAE)
    2006/04/24  Upgraded the object with the inline method trick for the 
    onreadystatechange event so the buggy ugly global array sollution isn't 
    necessary any more. (HW, DAE)
    2005/08/15  Created the first version using the array to reference back to 
    object sending the call. (HW, DAE)
*/


/*
A basic wrapper for the XmlHttpRequest object. It contains basic functionality 
for sending a HttpRequest using the XmlHttpRequest object. Performs first error 
checks and fires a onFinished event if finished. 

Usage example:
@code
function requestTestData(){
    var oRequest = new df.ajax.HttpRequest("TestData.txt", null);
    oRequest.onFinished.addListener(handleTestData);
    oRequest.send(true);
}
function handleTestData(oEvent){
    alert(oEvent.sResponseText);
}
@code
*/
export class HttpRequest {

    static states = {
        REQUEST_STATE_UNITIALIZED  : 0,
        REQUEST_STATE_LOADING      : 1,
        REQUEST_STATE_LOADED       : 2,
        REQUEST_STATE_INTERACTIVE  : 3,
        REQUEST_STATE_COMPLETE     : 4
    }


    /*
    Constructor creating the properties and initializing them with the given 
    attributes.

    @param  sUrl    The requested URL.
    @param  sData   (optional) String with post data.
    */
    constructor(sUrl, sData, oSource) {
        if (sData === undefined) {
            sData = null;
        }
        //  Public
        /*
        The URL to which the request is send. Might be relative to the URL of the
        page.
        */
        this.sUrl = sUrl;
        /*
        Controls if the withCredentials option is used which enables cookies for cross domain calls.
        */
        this.pbWithCredentials = false;
        /*
        If not null this string is send as POST data with the request.
        */
        this.sData = sData;
        /*
        Determines wether the request is send synchronous or asynchronously.
        */
        this.bAsynchronous = true;

        /*
        If set then the Content-Type is validated against this value.
        */
        this.sExpectedContentType = null;

        //  Events
        /*
        Called after the response is received. The event object has the
        sResponseText and the oResponseXml properties that contain the response
        text and XML.
        
        @prop oResponseXml  Reference to the XML DOM that contains the response.
        @prop sResponseText String with the response text.
        */
        this.onFinished = new events.JSHandler();
        /*
        Called if an error occured. The event object has the oError object that
        contains the error object. If the event is stopped the error is not given
        to the error handling system.
        
        @prop oError    Reference to the error object.
        */
        this.onError = new events.JSHandler();

        // @privates
        this.onClose = new events.JSHandler();

        this.oLoader = null;
        this.oSource = oSource || null;
        this.bSilent = false;
    }

    /*
    Sends the AJAX request. If the response is received and after error checking 
    the onFinished event is fired.
    
    Note that Asynchronous calls might not be send directly because the AJAX 
    Library by default limits the amount of concurrent calls.
    
    @param  bAsynchronous   If true the request is made asynchronously.
    */
    send(bAsynchronous) {
        var that = this, sData;

        if (typeof bAsynchronous === "boolean") {
            this.bAsynchronous = bAsynchronous;
        }

        this.oLoader = new XMLHttpRequest(); //df.sys.xml.getXMLRequestObject();
        sData = this.getData();

        //  If asynchronousattach onreadystatechange function (if synchronous it
        //  is called mannualy)
        if (this.bAsynchronous) {
            this.oLoader.onreadystatechange = function () {
                that.onReadyStateChange();
            };
        }

        //  Open connection, set headers, send request
        try {
            this.oLoader.open((sData) ? "POST" : "GET", this.getRequestUrl(), this.bAsynchronous);
            this.oLoader.withCredentials = this.pbWithCredentials;
            this.setHeaders(this.oLoader);
            this.oLoader.send(sData);
        } catch (oErr) {
            throw new df.Error(5121, "The application was unable to communicate with the server.", this);
        }

        //  If synchronous request call readyStateChange manually (IE won't do 
        //  it)
        if (!this.bAsynchronous) {
            this.onReadyStateChange();
        }
    }

    /*
    Called if the readystate of the XmlRequest object changes when the request is 
    send asynchrone. If the request is send synchrone this method is called 
    manually. The method checks the readyState of the XmlRequest object, calls the 
    checkErrors method and fires the onFinished even.
    
    @private
    */
    onReadyStateChange() {
        // var oRequest = this;

        try {
            if (this.oLoader.readyState === HttpRequest.states.REQUEST_STATE_COMPLETE) {
                if (this.oLoader.status > 0) {    //  Scary check but it prevents firefox from throwing the could not parse XML error on page load
                    this.onClose.fire(this);

                    this.checkErrors();

                    this.onFinished.fire(this, this.getFinishedDetails());
                } else {
                    throw new df.Error(5121, "The application was unable to communicate with the server.", this);
                }
            }
        } catch (e) {
            if (!this.bSilent) {
                df.handleError(e, this);
            }
            this.onError.fire(this, { oError: e });
        }



    }

    /*
    Creates the event object that is fired with the onFinished event.
    
    @private
    @return Object with onFinished event information.
    */
    getFinishedDetails() {
        return { oResponseXml: this.getResponseXml(), sResponseText: this.getResponseText() };
    }

    /*
    Checks if any errors occurred while sending the request using its status 
    property.
    
    @param  bSkip500    (optional) If true no error is given on status 500 (some 
                        subclasses can give more detailed information on this error)
    @private
    */
    checkErrors(bSkip500) {
        //  TODO: Handle HTTP 404 (page not found), 301 (redirect), 302 (redirect)...

        if (this.oLoader.status >= 300 && (!bSkip500 || this.oLoader.status !== 500)) {
            var sDetailHtml = this.oLoader.responseText;

            throw new df.Error(5120, "Received HTTP error '{{0}} {{1}}' while loading URL '{{2}}'.", this, [this.oLoader.status, this.oLoader.statusText, this.getRequestUrl()], sDetailHtml);// aDetails.join(""));
        }

        if (this.oLoader.status == 200 && this.sExpectedContentType) {
            let sResponseContentType = this.oLoader.getResponseHeader("Content-Type") || "";

            if (sResponseContentType.indexOf(';')) {
                sResponseContentType = sResponseContentType.substring(0, sResponseContentType.indexOf(';'));
            }

            if (sResponseContentType.trim().toLowerCase() != this.sExpectedContentType.toLowerCase()) {
                throw new df.Error(5124, "Invalid response for HTTP request, content-type mismatch.", this, [], `Received content-type header '${sResponseContentType}' while expecting '${this.sExpectedContentType}'.`);// aDetails.join(""));
            }


        }
    }

    /*
    Sets the "custom" headers for the call. Currently empty, we might add custom 
    header functionality tot the HttpRequest later.
    
    @param  oLoader Reference to the XmlHttpRequest object.
    @private
    */
    setHeaders(oLoader) {

    }

    /*
    @return The URL to which the request is send.
    */
    getRequestUrl() {
        return this.sUrl;
    }

    /*
    @return The XML document containing the response XML (null if not valid XML).
    */
    getResponseXml() {
        return this.oLoader.responseXML;
    }

    /*
    @return String containing the response text.
    */
    getResponseText() {
        return this.oLoader.responseText;
    }

    /*
    @return The this.sData string, used to make it overloadable.
    @private
    */
    getData() {
        return this.sData;
    }

    /*
    Cancels the request. Note that cancelling requests is dangerous! You don't know 
    exactly if the server will still handle the request or not. Never use this on 
    requests that manipulate data!
    */
    cancel() {
        if (this.oLoader !== null) {
            this.onClose.fire(this);

            this.oLoader.onreadystatechange = function () { };
            this.oLoader.abort();
            this.oLoader = null;
        }

        this.onFinished.aListener = [];
    }

    /*
    This method clears the loader object of the call to prevent memory leaking. It 
    is called automatically by the handling methods of the call after a timeout of a 
    second.
    */
    destroy() {
        try {
            if (this.bAsynchronous && this.oLoader && this.oLoader.onreadystatechange) {
                this.oLoader.onreadstatechange = null;
            }
        } catch (oErr) {

        }
        this.oLoader = null;
    }

    getWebApp() {
        if (this.oSource && this.oSource.getWebApp) {
            return this.oSource.getWebApp();
        }

        return null;
    }
}