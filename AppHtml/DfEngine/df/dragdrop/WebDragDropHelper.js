import { WebObject } from '../WebObject.js';
import { df } from '../../df.js';

export class WebDragDropHelper extends WebObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Events
        this.event("OnHelperReady", df.cCallModeWait);

        // Internals
        this._aSources = []; // { oControl : objectRef, aActions : [] }
        this._aTargets = []; // { oControl : objectRef, aActions : [] }
        this._oDragData = null; // Will store information about the drag upon a drag start
                                // Format :
                                // { 
                                //  oControl : <Control that started the drag>,
                                //  eElem : <Element that started the drag>,
                                //  oData : <Data for this drag>,
                                //  eType : <Type of drag that was performed>
                                // }
        this._bInitializedDrag = false; // Flag to mark if this helper initialized the drag (to prevent invalid OnDrop events from firing)
        this._bAcceptAllDrops = false;
        this._oDragObj = null; // Object that is currently being dragged ( {item: ... , element: "<div ..>"})
    }

    isDropAllowed() {
        if(this._bAcceptAllDrops === true) {
            return true;
        }

        return this._bInitializedDrag;
    }

    create() {
        super.create();

        this.fire("OnHelperReady");
    }

    registerDragSource(sObjName, sAction) {
        let oObj = this.getWebApp().findObj(sObjName);
        let bExists = false;

        if (oObj) {
            // Optionally map to different object than caller
            oObj = oObj.getDragSourceObj();
        }

        if(!oObj){
            throw new df.Error(999, "Could not find drag source object '{{0}}'.", this, [ sObjName ]);
        }

        // Check if object exists
        for (let i = 0; i < this._aSources.length; i++) {
            let curSource = this._aSources[i];
            if (curSource.oControl == oObj) {
                // Add the action
                curSource.aActions.push(parseInt(sAction));
                bExists = true;
            }
        }

        // If it doesn't exist, add a new object
        if (!bExists) {
            const newSource = {
                oControl: oObj,
                aActions: [parseInt(sAction)]
            }
            this._aSources.push(newSource);
        }

        // this._aSources.add(oObj);

        // Register helper at source
        oObj.registerDragSource(this, parseInt(sAction));
    }

    registerDropTarget(sObjName, sAction) {
        let oObj = this.getWebApp().findObj(sObjName);
        let bExists = false;

        if (oObj) {
            // Optionally map to different object than caller
            oObj = oObj.getDropTargetObj();
        }        

        if(!oObj){
            throw new df.Error(999, "Could not find drop target object '{{0}}'.", this, [ sObjName ]);
        }

        // Check if object exists
        for (let i = 0; i < this._aTargets.length; i++) {
            let curTarget = this._aTargets[i];
            if (curTarget.oControl == oObj) {
                // Add the action
                curTarget.aActions.push(parseInt(sAction));
                bExists = true;
            }
        }

        // If it doesn't exist, add a new object
        if (!bExists) {
            const newTarget = {
                oControl: oObj,
                aActions: [parseInt(sAction)]
            }
            this._aTargets.push(newTarget);
        }

        // Register helper at target
        oObj.registerDropTarget(this, parseInt(sAction));
        // oObj.initDropZones();
    }

    highlightDropZones() {
        this._aTargets.forEach(oTarget => {
            oTarget.oControl.highlightDropZones(this);
        });
    }

    onDragStart(oEv, oDragObj, eElem, oDragData, eAction) {
        // Only highlight if this helper is responsible for handling the drag from the source, otherwise stop here
        if (oDragData && this.supportsDragAction(oDragObj, eAction)) {
            this._oDragData = {
                oControl: oDragObj,
                eElem: eElem,
                oData: oDragData
            }

            this._bInitializedDrag = true;
            this.highlightDropZones();
        } else {
            return false;
        }
    }

    onDragEnd(oEv) {
        if (this.isDropAllowed()) {
            this.cleanupHelper();
            df.dragdrop.stopDropZones();
        }
    }

    cleanupHelper() {
        this._aTargets.forEach(oTarget => {
            oTarget.oControl.cleanupDropZones();
        });
        this._oDragData = null;

        this._bInitializedDrag = false;
    }

    onDrop(oEv, oSourceDfObj, oDropZone) {
        const oDragData = this._oDragData;
        
        if (oDragData && oDropZone && this.supportsDropAction(oDropZone._oControl, oDropZone._eDropAction) && this.isDropAllowed()) {
            const oDropData = oDropZone.getDropData();

            // Send OnDrop serveraction
            var oDragDropData = {
                DragData : this._oDragData?.oData || null,
                DropData: oDropData
            }

            this.serverAction("Drop", [this._oDragData?.oControl?.getLongName() || "", oDropZone._oControl.getLongName(), oDropZone._eDropPosition], oDragDropData);
        }

        this.onDragEnd(oEv);
    }

    onDragOver() {
        // HTML5 Expects this to be there for dragdrop to function correctly, but an empty stub will suffice
    }

    destroyDragObj() {
        this._oDragObj.destroy();
        this._oDragObj = null;
    }

    supportsDragAction(oControl, eAction) {
        for (let i = 0; i < this._aSources.length; i++) {
            let curSource = this._aSources[i];
            if (curSource.oControl == oControl) {
                for (let j = 0; j < curSource.aActions.length; j++) {
                    if (curSource.aActions[j] == eAction) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    supportsDropAction(oControl, eAction) {
        for (let i = 0; i < this._aTargets.length; i++) {
            let curTarget = this._aTargets[i];
            if (curTarget.oControl == oControl) {
                for (let j = 0; j < curTarget.aActions.length; j++) {
                    if (curTarget.aActions[j] == eAction) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
};

/*
Local WebDragDropHelper that redirects drag start (highlight) and drag end (cleanup) calls to 
DataFlex. This allows multiple helpers to be joined together to allow drag 'n drop between multiple 
local control hosts.
*/
export class LocalWebDragDropProxy extends WebDragDropHelper {
    constructor(sName, oParent) {
        super(sName, oParent);
        this._bAcceptAllDrops = true;
    }

    /*
    Override and send server action. Immediately include drag data.
    */
    highlightDropZones() {
        this.serverAction("HighlightDropZones", [this._oDragData.oControl.getLongName()],  { "DragData" : this._oDragData.oData });
    }

    /*
    Do the actual actual highlight triggered from the server.

    @client-action
    */
    doHighlightDropZones() {
        //  Set dummy drag data to 'activate' drop logic for this helper.
        this._oDragData = {
            oControl : null,
            eElem : null,
            oData : null
        }
        this._aTargets.forEach(oTarget => {
            oTarget.oControl.highlightDropZones(this);
        });
    }

    /*
    Override and and send to the server.
    */
    cleanupHelper(){
        this.serverAction("CleanupHelper");
    }

    /*
    Do the actual cleanup triggered from the server.

    @client-action
    */
    doCleanupHelper() {
        this._aTargets.forEach(oTarget => {
            oTarget.oControl.cleanupDropZones();
        });
        this._oDragData = null;
    }

}