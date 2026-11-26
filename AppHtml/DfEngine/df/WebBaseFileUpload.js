import { HttpRequest } from './ajax/HttpRequest.js';
import { WebBaseUIObject } from './WebBaseUIObject.js';
import { WebBaseControl } from './WebBaseControl.js';
import { WebPanel } from './WebPanel.js';
import { WebModalDialog } from './WebModalDialog.js';
import { WebLabel } from './WebLabel.js';
import { WebProgressBar } from './WebProgressBar.js';
import { WebButton } from './WebButton.js';
import { WebSpacer } from './WebSpacer.js';
import { LocalApp } from './LocalApp.js';
import { df } from '../df.js';
/*
Class:
    df.WebBaseFileUpload
Extends:
    df.WebBaseControl

This class contains the core implementation of file upload using HTML5 with a fallback to HTML4. Its 
subclasses provide the different UI and API options that can be used by the developer. This class 
contains the implementation of the progress dialog (that can be turned on / off using pbShowDialog) 
which can be overridden by implementing the different display� methods. The class supports 
multi-file uploads for HTML5 browsers and drag & drop support. The drag & drop support works using 
the global namespace df.dragdrop that is implemented in this file. If further drag & drop support 
will be implemented within the framework this namespace will need to be expanded and moved to a 
generic library file.
    
Revision:
    2012/12/18  (HW, DAW) 
        Initial version.
    2013/09/10  (HW, DAW)
        Refactored from WebFileUploader into WebBaseFileUpload with WebFileUploadForm and 
        WebFileUploadButton sub-classes.
    2021/10/19  (HR, DAW)
        Added logic to support WebDragDropFileHelper (registering and calls)
*/
/*global df */


/*  
The dragdrop library provides a generic implementation to support drag and drop. It currently only 
supports dropping and has a pretty generic interface. Controls can add themselves as drop handlers 
using df.dragdrop.addHandler and remove themselves using df.dragdrop.remHandler. If something is 
dragged onto the screen the getDropDetails method is called on the control. The control should 
return an object with drop details in the following format:
{
    sDropContent : "",          //  Text displayed inside the dropzone
    sDropClass : "",            //  Extra CSS Classname for the dropzone
    oRect : BoundingClientRect  //  Bounding Rectangle to position the dropzone
}

If null is returned the control is ignored and will not get a drop zone. For all other handler 
controls a dropzone is displayed. If the user drops on one of these dropzones the handleDrop method 
is called on the control.
*/
df.dragdrop = (function dragdrop() {
    var aHandlers = [], aZones = [], bInDrag = false, iEnterCount = 0, tResizeInt;
    var aHelpers = new Set();

    function initDropZones() {
        if (bInDrag) {
            return;
        }

        //  Generate dropzones
        aHandlers.forEach(function (oHandler) {
            var eZone, oDropDetails = oHandler.getDropDetails();

            if (oDropDetails) {
                eZone = df.dom.create('<div data-dropzone="yes" class="WebDropZone ' + oDropDetails.sDropClass + '"><div>' + oDropDetails.sDropContent + '</div></div>');
                eZone.style.width = oDropDetails.oRect.width + "px";
                eZone.style.height = oDropDetails.oRect.height + "px";
                eZone.style.left = oDropDetails.oRect.left + "px";
                eZone.style.top = oDropDetails.oRect.top + "px";
                oDropDetails.eZoneParent.appendChild(eZone);

                aZones.push({
                    oObj: oHandler,
                    oDetails: oDropDetails,
                    eZone: eZone
                });

            }
        });

        tResizeInt = setInterval(repositionDropZones, 300);
        bInDrag = true;
    }

    function repositionDropZones() {
        aZones.forEach(function (oZone) {
            var oDropDetails = oZone.oDetails = oZone.oObj.getDropDetails();
            oZone.eZone.style.width = oDropDetails.oRect.width + "px";
            oZone.eZone.style.height = oDropDetails.oRect.height + "px";
            oZone.eZone.style.left = oDropDetails.oRect.left + "px";
            oZone.eZone.style.top = oDropDetails.oRect.top + "px";
        });
    }

    function stopDropZones() {
        if (!bInDrag) {
            return;
        }

        //  Remove & destroy drop zones
        aZones.forEach(function (oZone) {
            oZone.eZone.parentNode.removeChild(oZone.eZone);
            oZone.eZone = null;
        });
        aHelpers.forEach(function (oHelper) {
            oHelper.cleanupHelper();
        });
        aZones = [];
        bInDrag = false;
        iEnterCount = 0;

        clearInterval(tResizeInt);
    }

    function onWindowEnter(oEvent) {
        iEnterCount++;
        if (!bInDrag) {
            if (containsFiles(oEvent.e)) {
                initDropZones();
                aHelpers.forEach(oHelper => {
                    oHelper.onFileDrag(oEvent);
                });
            }
        }
        bInDrag = true;

        // console.log("onWindowEnter(" + iEnterCount + ")");
        oEvent.stop();
    }

    function onWindowOver(oEvent) {
        var eElem = oEvent.getTarget();
        while (eElem && eElem !== document.body) {
            if (eElem.hasAttribute("data-dropzone")) {
                oEvent.e.dataTransfer.dropEffect = "copy";
                oEvent.stop();
                return;
            }
            eElem = eElem.parentNode;
        }

        // console.log("onWindowOver");
        oEvent.e.dataTransfer.dropEffect = "none";

        oEvent.stop();

    }

    function onWindowDrop(oEvent) {
        var eElem = oEvent.getTarget();

        while (eElem && eElem !== document.body) {
            if (eElem.hasAttribute("data-dropzone")) {
                break;
            }
            eElem = eElem.parentNode;
        }

        //  Notify drop receiver
        if (eElem) {
            aZones.forEach(function (oZone) {
                if (oZone.eZone === eElem) {
                    oZone.oObj.handleDrop(oEvent);
                    stopDropZones();
                    oEvent.stop();
                    return false;
                }
            });
        }

        // console.log("onWindowDrop");
    }


    function onWindowLeave(oEvent) {
        iEnterCount--;
        if (iEnterCount <= 0) {
            stopDropZones();
            iEnterCount = 0;
        }
        // console.log("onWindowLeave(" + iEnterCount + ")");

    }

    function containsFiles(event) {
        if (event.dataTransfer.types) {
            for (var i = 0; i < event.dataTransfer.types.length; i++) {
                if (event.dataTransfer.types[i] == "Files") {
                    return true;
                }
            }
        }
        return false;
    }

    df.dom.ready(function () {
        df.dom.on("dragenter", document, onWindowEnter, window);
        df.dom.on("dragover", document, onWindowOver, window);
        df.dom.on("drop", document, onWindowDrop, window);
        df.dom.on("dragleave", document, onWindowLeave, window);
    }, window);

    return {
        addHandler(oObj) {
            aHandlers.push(oObj);
        },

        remHandler(oObj) {
            var i;

            while ((i = aHandlers.indexOf(oObj)) >= 0) {
                aHandlers.splice(i, 1);
            }
        },

        registerHelper(oHelper) {
            aHelpers.add(oHelper);
        },

        removeHelper(oHelper) {
            aHelpers.remove(oHelper);
        },

        containsFiles,
        stopDropZones
    }

})();


/* 
The big worker function with the upload logic. Extracted out of the class so it can be used by 
other controls as well. Extra advantage is the usage of local variables inside the closure.

The oOpts parameter is used too pass in the details and also contains the status while uploading 
and has references to the functions showing the status.
*/
df.uploadFiles = function uploadFile(oOpts) {
    var i, fEmpty, aFiles, oWO, aRows = [], bCanceled, bUploading = true, oCurRec;

    aFiles = oOpts.aFiles;
    oWO = oOpts.oWO;

    oOpts.iTotal = 0;
    oOpts.iLoaded = 0;

    fEmpty = function () { };
    oOpts.displayStartWorking = oOpts.displayStartWorking || fEmpty;
    oOpts.displayProgress = oOpts.displayProgress || fEmpty;
    oOpts.displayFinishWorking = oOpts.displayFinishWorking || fEmpty;
    oOpts.displayFinished = oOpts.displayFinished || fEmpty;

    /* 
    Actual uploader function doing the HTML5 upload.
    */
    function uploadFileHtml5(oFile, iFile, fFinished) {
        oOpts.displayProgress.call(oWO, iFile, aFiles.length, 0, oFile.oFile.size, oOpts.iLoaded, oOpts.iTotal);

        if (oWO.getWebApp() instanceof LocalApp && window.chrome?.webview?.postMessageWithAdditionalObjects) {
            //  If we are in FlexTron file upload is handled by passing the file object to WebView2 using postMessageWithAdditionalObjects
            oWO.serverActionEx({
                sMethod: "DoHandleLocalFileUpload",
                aParams: [oFile.sResourceId],
                tData: null,
                fHandler: () => {
                    oOpts.iLoaded += oFile.oFile.size;
                    oOpts.displayProgress.call(oWO, iFile, aFiles.length, oFile.oFile.size, oFile.oFile.size, oOpts.iLoaded, oOpts.iTotal);
                    oFile.bFinished = true;
                    fFinished(true);
                },
                oHandlerEnv: null,
                oPlatformSpecific: {
                    aAdditionalObjects: [oFile.oFile]
                }
            });
        } else {
            // Regular HTML5 file upload
            let oData, oReq;
            //  Prepare request
            oCurRec = oReq = new XMLHttpRequest();

            oReq.upload.addEventListener('progress', function (ev) {
                var iTotal = oOpts.iLoaded + ev.loaded;

                iTotal = (iTotal < oOpts.iTotal ? iTotal : oOpts.iTotal);
                oOpts.displayProgress.call(oWO, iFile, aFiles.length, ev.loaded, ev.total, iTotal, oOpts.iTotal);
            }, false);

            oReq.onreadystatechange = function (ev) {
                try {
                    if (oReq.readyState === HttpRequest.states.REQUEST_STATE_COMPLETE) {
                        if (!bCanceled) {
                            if (oReq.status === 201) {
                                oFile.bFinished = true;
                                oOpts.iLoaded += oFile.oFile.size;
                                fFinished(true);
                                oReq.onreadystatechange = null;
                            } else {
                                //  Throw errorr
                                throw new df.Error(999, "Received HTTP error '{{0}} {{1}}' while uploading file.", this, [oReq.status, oReq.statusText], oReq.responseText);
                            }
                        }

                        oReq = null;
                    }
                } catch (oErr) {
                    //  Fix control state..
                    fFinished(false);

                    //  Handle error
                    oWO.getWebApp().handleError(oErr);

                    oReq = null;
                }

            };
            oReq.open('POST', oWO.psUploadUrl, true);

            oData = new FormData();
            oData.append('hash', oFile.sResourceId);
            oData.append('v', 'html5');
            oData.append('file', oFile.oFile);
            oReq.send(oData);
        }
    }

    /*
    Initiates uploading the of the next file in the list.
    */
    function uploadFilesHtml5() {
        var i, bLast = true, oFile = null, iIndex;

        if (bCanceled) {
            return;
        }

        //  Determine next file to upload and check if that is the last file
        for (i = 0; i < aFiles.length; i++) {
            if (!aFiles[i].bFinished) {
                if (!oFile) {
                    oFile = aFiles[i];
                    iIndex = i;
                } else {
                    bLast = false;
                    break;
                }
            }
        }

        uploadFileHtml5(oFile, iIndex, function (bSuccess) {
            var i;


            if (bSuccess) {
                if (bLast) {
                    oOpts.displayFinishWorking.call(oWO);
                }

                if (oWO.pbNotifyIndividualFile) {
                    oWO.serverAction("DoFileFinished", [oFile.oFile.name, oFile.sResourceId], null, function (oEvent) {
                        oFile.sFinishedResult = oEvent.sReturnValue;    //  This is used by the froala editor
                        if (!bLast) {
                            uploadFilesHtml5();
                        }
                    }, oWO);
                } else {
                    if (bLast) {
                        for (i = 0; i < aFiles.length; i++) {
                            oWO.serverAction("DoFileFinished", [aFiles[i].oFile.name, aFiles[i].sResourceId], null, function (oEvent) {
                                oFile.sFinishedResult = oEvent.sReturnValue;    //  This is used by the froala editor
                            });
                        }
                    } else {
                        uploadFilesHtml5();
                    }
                }

                if (bLast) {
                    oWO.fire("OnUploadFinished", [], function (oEvent) {
                        oOpts.displayFinished.call(oWO, true);
                        bUploading = false;

                        if (oOpts.finished) {
                            oOpts.finished.call(oWO, true, aFiles);
                        }
                    });
                    oWO.processUpload = null;

                }
            } else {
                if (oWO._eControl) {
                    oWO._eControl.value = "";
                }
                oOpts.displayFinished.call(oWO, false);
                bUploading = false;
            }
        });
    }

    /* 
    Cancels the upload.
    */
    oOpts.cancel = function () {
        bCanceled = true;

        aFiles = [];

        if (oCurRec) {
            oCurRec.abort();
        }

        oOpts.displayFinished.call(oWO, false);
        bUploading = false;
    };

    var fUploadCallback = function (oEv) {
        var i, aRows = JSON.parse(oEv.sReturnValue);

        //  Get resource id's out of action data
        for (i = 0; i < aRows.length; i++) {
            if (aRows[i].length >= 2 && aFiles[aRows[i][0]]) {
                aFiles[aRows[i][0]].sResourceId = aRows[i][1];
            } else {
                throw new df.Error(999, "Received invalid resource id from the server.", this);
            }
        }

        //  Filter out cancelled files & init stats
        oOpts.iTotal = 0;
        oOpts.iLoaded = 0;
        for (i = 0; i < aFiles.length; i++) {
            if (!aFiles[i].sResourceId) {
                aFiles.splice(i, 1);
                i--;
            } else {
                oOpts.iTotal += aFiles[i].oFile.size;
            }
        }

        if (aFiles.length > 0) {
            bCanceled = false;

            uploadFilesHtml5();
        } else {
            oOpts.displayFinished.call(oWO, false);
            bUploading = false;
        }
    }

    //  Initialization of the files array
    if (aFiles && aFiles.length > 0) {
        for (i = 0; i < aFiles.length; i++) {
            const oCurFile = aFiles[i].oFile;
            aRows.push([
                i,
                (oCurFile.name || "Unknown"),
                (oCurFile.size || 0),
                (oCurFile.type || "Unknown")
            ]);

            oOpts.iTotal += oCurFile.size || 0;
        }

        oOpts.displayStartWorking.call(oWO);

        // Call control to init upload call on server (controls can have their own implementation for this)
        oWO.doStartUpload(fUploadCallback, aRows);
    } else {
        throw new df.Error(999, "No file details found to start upload.", this);
    }
};

/* 
File upload function with file upload dialog UI.
*/
df.uploadFilesProgressDialog = function (oOpts) {
    var oDialog, oMainPnl, oLbl, oFileLbl, oRemLbl, oSpacer, oTotalPrg, oFilePrg, oBtnPnl, oCancelBtn, oWO;

    oWO = oOpts.oWO;
    let sFilesTrans = oWO.getWebApp().getTrans("files");
    let sFileTrans = oWO.getWebApp().getTrans("file");

    function onCancel(oEvent) {
        oOpts.cancel();
    }

    /* 
    Displays the dialog and controls.
    */
    oOpts.displayStartWorking = function () {
        var iWindowWidth = df.dom.windowWidth()

        oDialog = new WebModalDialog(null, oWO);
        oDialog.psCaption = oWO.getWebApp().getTrans("file_cap_uploading");
        oDialog.pbShowClose = this.pbAllowCancel;
        oDialog.piMinWidth = (iWindowWidth > 520 ? 500 : iWindowWidth - 20);
        oDialog.OnEscape.addListener(onCancel, this);

        oMainPnl = new WebPanel(null, oDialog);
        oMainPnl.peRegion = df.ciRegionCenter;
        oMainPnl.piColumnCount = 10;
        oDialog.addChild(oMainPnl);

        oLbl = new WebLabel(null, oMainPnl);
        oLbl.psCaption = sFileTrans + ":";
        oLbl.piColumnSpan = 2;
        oLbl.peAlign = df.ciAlignRight;
        oMainPnl.addChild(oLbl);

        oFileLbl = new WebLabel(null, oMainPnl);
        oFileLbl.psCaption = "...";
        oFileLbl.piColumnSpan = 0;
        oFileLbl.piColumnIndex = 2;
        oMainPnl.addChild(oFileLbl);

        oLbl = new WebLabel(null, oMainPnl);
        oLbl.psCaption = oWO.getWebApp().getTrans("file_remain") + ":";
        oLbl.piColumnSpan = 2;
        oLbl.peAlign = df.ciAlignRight;
        oMainPnl.addChild(oLbl);

        oRemLbl = new WebLabel(null, oMainPnl);
        oRemLbl.psCaption = oOpts.aFiles.length + " " + sFilesTrans + " (" + df.sys.data.markupDataSize(oOpts.iTotal) + ")";
        oRemLbl.piColumnSpan = 0;
        oRemLbl.piColumnIndex = 2;
        oMainPnl.addChild(oRemLbl);

        oSpacer = new WebSpacer(null, oMainPnl);
        oMainPnl.addChild(oSpacer);

        if (oWO.pbMultiFile) {
            oTotalPrg = new WebProgressBar(null, oMainPnl);
            oTotalPrg.piMaxValue = (oOpts.iTotal > 0 ? oOpts.iTotal : oOpts.aFiles.length);
            oMainPnl.addChild(oTotalPrg);
        }

        oFilePrg = new WebProgressBar(null, oMainPnl);
        oMainPnl.addChild(oFilePrg);

        if (oWO.pbAllowCancel) {
            oBtnPnl = new WebPanel(null, oDialog);
            oBtnPnl.peRegion = df.ciRegionBottom;
            oBtnPnl.piColumnCount = 12;
            oDialog.addChild(oBtnPnl);

            oCancelBtn = new WebButton(null, oBtnPnl);
            oCancelBtn.psCaption = oWO.getWebApp().getTrans("cancel");
            oCancelBtn.piColumnIndex = 9;
            oCancelBtn.piColumnSpan = 3;
            oCancelBtn.OnClick.addListener(onCancel, this);
            oBtnPnl.addChild(oCancelBtn);
        }

        oDialog.show();

        oWO.getWebApp().ready(function () {
            oDialog.resize();
            if (oCancelBtn) {
                oCancelBtn.focus();
            }
        });
    };

    /* 
    Updates the displayed progress with the provided details.
    */
    oOpts.displayProgress = function (iFile, iFiles, iFileLoaded, iFileTotal, iTotalLoaded, iTotal) {
        oFileLbl.set("psCaption", (oOpts.aFiles[iFile] && oOpts.aFiles[iFile].oFile && oOpts.aFiles[iFile].oFile.name) || "");

        let iRem = iFiles - (iFile + 1);
        let iBytesRem = iTotal - iTotalLoaded;

        oRemLbl.set("psCaption", (iRem > 0 ? (iRem.toString() + " " + sFilesTrans + " (" + df.sys.data.markupDataSize(iBytesRem) + ")") : df.sys.data.markupDataSize(iBytesRem)));

        if (oWO.pbMultiFile) {
            oTotalPrg.set("piMaxValue", iTotal);
            oTotalPrg.set("piValue", iTotalLoaded);
        }


        oFilePrg.set("piMaxValue", iFileTotal);
        oFilePrg.set("piValue", iFileLoaded);
    };

    /* 
    Displays 100%.
    */
    oOpts.displayFinishWorking = function () {
        oFilePrg.set("piValue", oFilePrg.get("piMaxValue"));

        if (oWO.pbMultiFile) {
            oTotalPrg.set("piValue", oTotalPrg.get("piMaxValue"));
        }
        oRemLbl.set("psCaption", "0 KB");
    };

    /* 
    Hides the dialog
    */
    oOpts.displayFinished = function (bSuccess) {
        if (oDialog) {
            oDialog.hide();
            oDialog.destroy();
            oDialog.OnEscape.removeListener(onCancel, this);

            if (oCancelBtn) {
                oCancelBtn.OnClick.removeListener(onCancel, this);
            }

            oDialog = null;
        }
    };




    // Call actual upload logic
    df.uploadFiles(oOpts);
};

// Mixin to be used in WebBaseFileUpload and WebDragDropHelper to add file upload logic
export const WebFileUpload_Mixin = superclass => class extends superclass {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbShowDialog", true);
        this.prop(df.tBool, "pbCapture", false);
        this.prop(df.tString, "psAccept", "");

        //  Events
        this.event("OnUploadFinished", df.cCallModeWait);
    }

    /*
    Initializes an array of File objects, it seeds the internal data structure, triggers an update of 
    display and if needed it starts the upload.
    
    @param  aFiles  FileList array of File objects.
    */
    initFiles(aFiles) {
        var i;

        if (this._bUploading) {
            return;
        }

        this._aFiles = [];

        //  Seed internal data structure
        for (i = 0; i < aFiles.length && (this.pbMultiFile || this._aFiles.length < 1); i++) {
            if (this.validate(aFiles[i])) {
                this._aFiles.push({
                    bFinished: false,
                    sResourceId: null,
                    oFile: aFiles[i]
                });
            }
        }

        if (this._aFiles.length > 0) {
            this.displaySelectedFileDetails();

            //  Start processing if needed
            if (this.pbAutoStart) {
                this.startUpload();
            }
        }
    }

    /* 
    Validates the file name against psAccept if psAccept is set. It checks the extension or the mime 
    type manually.
    
    @param  oFile   HTML5 file object.
    @return True if the file is valid according to psAccept.
    */
    validate(oFile) {
        var aAllowed, i, sAccept, aMime, aFileMime, bExt = false;
        if (this.psAccept) {
            aAllowed = this.psAccept.toLowerCase().split(",");

            for (i = 0; i < aAllowed.length; i++) {
                sAccept = aAllowed[i].trim();

                if (sAccept.charAt(0) === ".") { // This is an extension
                    if (oFile.name.substr(oFile.name.lastIndexOf("."), sAccept.length).toLowerCase() === sAccept) {
                        return true;
                    }

                    bExt = true;
                } else {
                    if (oFile.type) {
                        aMime = sAccept.split("/");
                        aFileMime = oFile.type.split("/");

                        if (aMime.length > 1 && aFileMime.length > 1 && (aMime[0] === aFileMime[0] || aMime[0] === "*") && (aMime[1] === aFileMime[1] || aMime[1] === "*")) {
                            return true;
                        }
                    }
                }
            }

            //  Make sure that we accept the file if only a mime type filter is set while no mime type is available
            if (!oFile.type && !bExt) {
                return true;
            }
            return false;
        }

        return true;
    }

    /*
    Starts the upload of the selected files.
    
    @client-action
    */
    startUpload() {
        var oOpts = {
            oWO: this,
            aFiles: this._aFiles,
            finished(bSuccess, aFiles) {
                //  Clear file upload control to make sure it will trigger the onchange the next time
                if (this._eInput) {
                    this._eInput.value = "";
                }
            },

            displayStartWorking: this.displayStartWorking,
            displayProgress: this.displayProgress,
            displayFinishWorking: this.displayFinishWorking,
            displayFinished: this.displayFinished
        };

        if (this.pbShowDialog) {
            df.uploadFilesProgressDialog(oOpts);
        } else {
            df.uploadFiles(oOpts);
        }
    }

    // Calls server side upload logic,
    // This is the default implementation, which can be modified to tailor specific classes needs
    // The server side function should always return an array containing the fileIndex and upload key (aka: asResults = [index][fileIndex, key])
    doStartUpload(fCallBack, aRows) {
        //  Send call to initialize upload
        this.serverAction("DoStartUpload", [], df.sys.vt.serialize(aRows), fCallBack);
    }

    /* 
    Replaced by upload logic inside closure!
    
    @client-action
    */
    processUpload() {

    }

    displaySelectedFileDetails() {

    }

    displayStartWorking() {

    }

    displayProgress(iFile, iFiles, iFileLoaded, iFileTotal, iTotalLoaded, iTotal) {

    }

    displayFinishWorking() {

    }

    displayFinished(bSuccess) {

    }

    set_psAccept(sVal) {
        if (this._eInput) {
            this._eInput.accept = sVal;
        }
    }

    set_pbCapture(bVal) {
        if (this._eInput) {
            this._eInput.capture = bVal;
        }
    }
};

// Create base class for WebBaseFileUpload with WebFileUpload Mixin
class WebFileUploadBase extends WebFileUpload_Mixin(WebBaseControl) {} 

export class WebBaseFileUpload extends WebFileUploadBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbMultiFile", false);
        this.prop(df.tBool, "pbAutoStart", true);
        this.prop(df.tBool, "pbAllowCancel", true);
        this.prop(df.tBool, "pbNotifyIndividualFile", false);
        // this.prop(df.tBool, "pbShowDialog", true);
        // this.prop(df.tBool, "pbCapture", false);
        this.prop(df.tString, "psDropZoneObjName", "");

        // this.prop(df.tString, "psAccept", "");
        this._oDragArea = null;
        this._eDragArea = null;

        // this.event("OnUploadFinished", df.cCallModeWait);
    }

    /*
    Generates hidden file upload element that is used for file selection.
    
    @param  aHtml   HTML string builder array.
    */
    fileHtml(aHtml) {
        aHtml.push('<div style="display: none">');
        aHtml.push('<input type="file" name="', this._sName,
            '" id="', this._sControlId, '"',
            (this.pbMultiFile ? ' multiple' : ''),
            ' accept="', this.psAccept, '"',
            (this.pbCapture ? ' capture' : ''),
            '>');
        aHtml.push('</div>');

    }

    /*
    After the HTML is inserted into the DOM we get references and attach event listenrs.
    */
    afterRender() {
        this._eInput = df.dom.query(this._eElem, 'input[type="file"]');

        super.afterRender();

        df.dom.on("change", this._eInput, this.onFileChange, this);
    }

    /*
    Shows the file selection dialog by calling click on the input type=file. It first checks if the 
    browser supports HTML5 file upload.
    */
    selectFiles() {
        if (!(window.File && window.FileList && window.FileReader)) {
            throw new df.Error(999, "HTML5 Upload is not supported by this browser.", this);
        }

        this._eInput.click();
    }

    /*
    When the control is shown we register ourselves as drop handler.
    */
    afterShow() {
        super.afterShow();

        df.dragdrop.addHandler(this);
    }

    /*
    When the control is hidden we unregister ourselves as drop handler.
    */
    afterHide() {
        super.afterHide();

        df.dragdrop.remHandler(this);
    }

    /*
    Called by the drag 'n drop system to get details on the drop area.
    */
    getDropDetails() {
        var oDropObj, eDropElem, oWebApp = this.getWebApp();

        if (this.isEnabled()) {
            oDropObj = oWebApp.findObj(this.psDropZoneObjName);

            if (oDropObj instanceof WebBaseUIObject) {
                if (oDropObj === oWebApp) {
                    eDropElem = document.body;
                } else {
                    eDropElem = oDropObj._eElem;
                }

                if (eDropElem) {
                    return {
                        sDropContent: this.getWebApp().getTrans("file_drop"),
                        sDropClass: "",
                        oRect : eDropElem.getBoundingClientRect(),
                        eZoneParent : (eDropElem.closest("dialog") || document.body)
                    };
                }
            }
        }
        return null;
    }

    /*
    Called by the drag 'n drop system to handle a drop.
    */
    handleDrop(oEvent) {
        var aFiles;

        aFiles = (oEvent.e.dataTransfer && oEvent.e.dataTransfer.files) || null;
        if (aFiles && aFiles.length > 0) {
            oEvent.stop();
            this.initFiles(aFiles);
        }
    }

    /*
    Handles the onchange event of the input type=file element and initializes selected files.
    */
    onFileChange(oEvent) {
        var sFileName;

        //  Check if selected and get file from control
        if (this._eInput.files.length > 0) {
            this.initFiles(this._eInput.files);
        }

        oEvent.stop();
    }
};
