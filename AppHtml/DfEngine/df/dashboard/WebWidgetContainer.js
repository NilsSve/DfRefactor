import { WebGroup } from "../WebGroup.js"
import { df } from "../../df.js"

export class WebWidgetContainer extends WebGroup {
    
    constructor(sName, oParent) {
        super(sName, oParent);
        
        // All these props need to be forwarded to the child container
        this.prop(df.tBool, "pbEditMode", false);
        this.prop(df.tBool, "pbDisableInternalDragDropHelper", false);
        this.prop(df.tBool, "pbUseCustomConfigurationStorage", false);

        // Event props
        this.prop(df.tBool, "pbServerOnToggleEditMode", false);
        this.prop(df.tBool, "pbServerOnWidgetMoved", false);
        this.prop(df.tBool, "pbServerOnWidgetResized", false);

        this.prop(df.tBool, "pbShowEditButton", true);
        this.prop(df.tBool, "pbShowEditMenu", true);

        // this.event("OnToggleEditMode", df.cCallModeWait);

        this._oWidgetContainer = null; // Set by child container

        // Configure super classes
        this._sBaseClass = "WebGroup";
        this._sControlClass = "WebWidgetContainer";
    }

    create(){
        super.create();
        this.peLayoutType = df.layoutType.ciLayoutTypeFlow;
    }

    // Todo - prevent creation of non-widgetcontainer class objects
    afterRender () {
        super.afterRender();
    }

    set_pbEditMode (bVal) {
        this._oWidgetContainer?.set_pbEditMode(bVal);
    }

    get_pbEditMode (){
        return this._oWidgetContainer?.pbEditMode || false;
    }

    set_pbShowEditButton (bVal) {
        this.pbShowEditButton = bVal
        this._oWidgetContainer?.set_pbShowEditButton(bVal);
    }

    set_pbShowEditMenu (bVal) {
        this.pbShowEditMenu = bVal
        this._oWidgetContainer?.set_pbShowEditMenu(bVal);
    }

    set_pbDisableInternalDragDropHelper  (bVal) {
        this.pbDisableInternalDragDropHelper = bVal

        this._oWidgetContainer?.set_pbDisableInternalDragDropHelper(bVal);
    }

    set_pbUseCustomConfigurationStorage  (bVal) {
        this.pbUseCustomConfigurationStorage = bVal

        this._oWidgetContainer?.set_pbUseCustomConfigurationStorage(bVal);
    }

    set_pbServerOnToggleEditMode  (bVal) {
        this.pbServerOnToggleEditMode = bVal

        this._oWidgetContainer?.set_pbServerOnToggleEditMode(bVal);
    }

    set_pbServerOnWidgetMoved  (bVal) {
        this.pbServerOnWidgetMoved = bVal

        this._oWidgetContainer?.set_pbServerOnWidgetMoved(bVal);
    }

    set_pbServerOnWidgetResized  (bVal) {
        this.pbServerOnWidgetResized = bVal

        this._oWidgetContainer?.set_pbServerOnWidgetResized(bVal);
    }

    set_piRowCount(iVal) {
        if (this.piRowCount !== iVal) {
            this.piRowCount = iVal;
            this._oWidgetContainer?.set_piRowCount(iVal);

            this.sizeChanged(true);
        }
    }

    set_piColumnCount(iVal) {
        if (this.piColumnCount !== iVal) {
            this.piColumnCount = iVal;
            this._oWidgetContainer?.set_piColumnCount(iVal);

            this.sizeChanged(true);
        }
    }

    set_piDefaultRowHeight(iVal) {
        if (this.piDefaultRowHeight !== iVal) {
            this.piDefaultRowHeight = iVal;
            this._oWidgetContainer?.set_piDefaultRowHeight(iVal);

            this.sizeChanged(true);
        }
    }

    set_psDefaultColumnWidth(sVal) {
        if (this.psDefaultColumnWidth !== sVal) {
            this.psDefaultColumnWidth = sVal;
            this._oWidgetContainer?.set_psDefaultColumnWidth(sVal);

            this.sizeChanged(true);
        }
    }

    set_psRowHeights(sVal) {
        if (this.psRowHeights !== sVal) {
            this.psRowHeights = sVal;
            this._oWidgetContainer?.set_psRowHeights(sVal);

            this.sizeChanged(true);
        }
    }

    set_psColumnWidths(sVal) {
        if (this.psColumnWidths !== sVal) {
            this.psColumnWidths = sVal;
            this._oWidgetContainer?.set_psColumnWidths(sVal);

            this.sizeChanged(true);
        }
    }

    // Drag drop logic, partially forwarded to underlying container

    // Map dragdrop to underlying container
    getDragSourceObj () {
        return this._oWidgetContainer;
    }

    // Map dragdrop to underlying container
    getDropTargetObj () {
        return this._oWidgetContainer;
    }

    getDragData  (oEv, eDraggedElem) {
        // Should this return the dragged widget??
        return this._oWidgetContainer.getDragData(oEv, eDraggedElem);
    }
    
    getDropData  (oDropZone, oPosition) {
        return this._oWidgetContainer.getDropData(oDropZone, oPosition);
    }   

}