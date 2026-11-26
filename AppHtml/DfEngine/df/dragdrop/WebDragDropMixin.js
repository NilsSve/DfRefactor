import { WebDropZone } from './WebDropZone.js';
import { df } from '../../df.js';
// Usage df.WebControlNameBase = df.mixin("df.WebDragDrop_Mixin", "df.WebBaseControl");

export const WebDragDrop_Mixin = superclass => class extends superclass {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbDragDropEnabled", false);

        // Privates
        this._sRawDragData = "";
        this._aDragDropHelpers = new Set();     // Internal reference to DragDropHelpers this component is registered with - this is a set as we want each helper to only register once
        this._aDropZones = [];                  // Array that stores drop zone elements
        this._aDragActions = new Set();         // Internal reference to the supported drop actions
        this._aDropActions = new Set();         // Internal reference to the supported drop actions

        //  Events
        this.event("OnDragStart", df.cCallModeWait);
        this.event("OnDrop", df.cCallModeDefault);
    }

    addDragDropEventListeners() {
        if (!this._eElem) return;

        df.dom.off("dragstart", this._eElem, this.onDragStart, this);
        df.dom.off("dragend", this._eElem, this.onDragEnd, this);

        if (this._aDragActions.size > 0) {
            df.dom.on("dragstart", this._eElem, this.onDragStart, this);
            df.dom.on("dragend", this._eElem, this.onDragEnd, this);
        }
    }

    registerDragSource(oHelper, eAction) {
        this._aDragDropHelpers.add(oHelper);
        this._aDragActions.add(eAction);

        // Trigger resize to draw draggable elements
        this.resize();

        if (this._eElem) {
            // Also called from afterRender
            this.addDragDropEventListeners();
        }
    }

    registerDropTarget(oHelper, eAction) {
        if (this._aDropActions.size > 0) {
            if (eAction == df.dropActions.WebControl.ciDropOnControl || this._aDropActions.has(df.dropActions.WebControl.ciDropOnControl)) {
                throw new df.Error(999,
                    'Drop Action "DropOnControl" cannot be used in conjunction with other Drop Actions. Ensure only "DropOnControl" or any of the other actions are registered exclusively.',
                    this);
            }
        }

        this._aDragDropHelpers.add(oHelper);
        this._aDropActions.add(eAction);

        // Check if control rendered, if so we can (re-) init all dropzones immediately
        // If not, this is also called from afterRender
        if (this._eElem) {
            this.initDropZones();
        }
    }

    // Convenience function to allow for mapping a different object to the registering helper
    getDragSourceObj() {
        return this;
    }

    // Convenience function to allow for mapping a different object to the registering helper
    getDropTargetObj() {
        return this;
    }
    
    // setDragActions () {
    //     this._aDragActions = this._tActionData;
    // }

    // setDropActions () {
    //     this._aDropActions = this._tActionData;
    // }

    // ===== Initializing drag an drop elements

    // Empty method, implementing controls use this to mark certain areas (elements) in the control as a dropzone
    initDropZones() {
    }

    // Convenience method to add a drop zone
    addDropZone(eZone, oOptControl) {
        if (!oOptControl) {
            oOptControl = this;
        }
        var oDropZone = new df.WebDropZone(eZone, oOptControl);
        this._aDropZones.push(oDropZone);
    }

    removeDropZone(oDropZone) {
        this._aDropZones = this._aDropZones.filter(DropZone => DropZone !== oDropZone);
    }

    removeDropZoneByElem(eZone) {
        this._aDropZones = this._aDropZones.filter(DropZone => DropZone._eZone !== eZone);
    }

    // Empty method, implementing controls use this to mark certain areas (elements) in the control as a draggable
    initDraggableElements() {
    }

    dragDropInit() {
        this._aDropZones = []

        this.addDragDropEventListeners();
        this.initDropZones();
    }

    // ===== Cleanup
    dragDropCleanup() {
    }


    // Drag drop event stubs
    onDragStart(oEv) {
        // oEv.e.preventDefault();
        // oEv.e.stopPropagation();

        var [oDragData, eDragAction] = this.getDragData(oEv, oEv.e.target);

        if (oDragData && eDragAction) {
            oEv.e.stopPropagation();

            // Notify helpers we're starting a drag
            this._aDragDropHelpers.forEach(oHelper => {
                oHelper.onDragStart(oEv, this, oEv.e.target, oDragData, eDragAction);
            });
        }

        // return false;
    }

    onDragEnd(oEv) {
        // Notify helpers we've stopped dragging, regardless of where we ended
        this._aDragDropHelpers.forEach(oHelper => {
            oHelper.onDragEnd(oEv);
        });
    }

    onDrop(oEv, oDropZone, eDropAction) {
        // Notify helpers we're performing a drop
        this._aDragDropHelpers.forEach(oHelper => {
            oHelper.onDrop(oEv, this, oDropZone, eDropAction);
        });
    }

    // This is needed to allow for for example scrolling on dragging over certain sections of the list or expand a folder upon hovering
    onControlDragOver(oEv, oDropZone, eDropElem) {
        // Implement in control
    }

    getDragData(oEv, eElem) {
        // Implement in control
        let oData, eDragAction;

        return [oData, eDragAction];
    }

    getDropData(oDropZone) {
        // Augment at control level
        return [];
    }

    // Highlighting
    highlightDropZones(oHelper) {
        this._aDropZones.forEach(dropZone => {
            dropZone.highlight(oHelper);
        });
    }

    cleanupDropZones() {
        this._aDropZones.forEach(dropZone => {
            dropZone.unhighlight();
            dropZone.removeDropElemInteractions();
        });
    }

    hasData() {
        // Check for data in control
        return false;
    }

    // This returns the element dropped on (determined by the control), as well as the corresponding drop action in array form (to be destructured after returning)
    determineDropCandidate(oEv, aHelpers) {
        let eDropElem, eDropAction;

        return [eDropElem, eDropAction];
    }

    determineDropPosition(oEv, eElem) {
        // Returns df.dropPositions.ciDropOn, ciDropBefore or ciDropAfter
        return df.dropPositions.ciDropUnknown; // unknown
    }

    interactWithDropElem(dropZone, eElem) {
        // default to highlighting
        dropZone.highlightElement(eElem);
    }

    doEmptyInteraction(dropZone) {
        // Implement in control
    }

    isSupportedDragAction(eAction) {
        return this._aDragActions.has(eAction);
    }

    isSupportedDropAction(eAction) {
        return this._aDropActions.has(eAction);
    }

};
