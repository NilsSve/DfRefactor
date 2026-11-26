import { WebDragDropHelper } from "../dragdrop/WebDragDropHelper.js";

export class WebWidgetContainerDragDropHelper extends WebDragDropHelper {

    constructor(sName, oParent){
        super(sName, oParent);
    }

    onDrop(oEv, oSourceDfObj, oDropZone) {
        const oDragData = this._oDragData;
        
        if (oDragData && oDropZone && this.supportsDropAction(oDropZone._oControl, oDropZone._eDropAction) ) {
            const oDropData = oDropZone.getDropData();

            // Send OnDrop serveraction
            var oDragDropData = {
                DragData : this._oDragData.oData,
                DropData : oDropData
            }

            this.getWebApp()?.findObj(oDragDropData.DragData.sControlName)?.moveWidget(oDropData.data.iRow, oDropData.data.iCol);

            oDropZone._oControl.fire("ServerOnWidgetMoved", [oDragDropData.DragData.sControlName, oDropData.data.iRow, oDropData.data.iCol]);
        }

        this.onDragEnd(oEv);
    }

}