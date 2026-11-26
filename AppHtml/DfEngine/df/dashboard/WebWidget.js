import { WebGroup } from "../WebGroup.js"
import { df } from '../../df.js';

export class WebWidget extends WebGroup {

    constructor(sName, oParent) {
        //  Forward Send
        super(sName, oParent);

        this.prop(df.tString,     'psDynamicWidgetId',    '');
        this.prop(df.tString,     'psWidgetName',         '');
        this.prop(df.tBool,       'pbAllowResize',        true);
        this.prop(df.tBool,       'pbConfigurable',       false);

        // Configure super classes
        this._sBaseClass = "WebGroup";
        this._sControlClass = "WebWidget";
        
        // privates
        this._bEditMode = false;

        this._eSelTop;
        this._eSelLeft;
        this._eSelBottom;
        this._eSelRight;
        this._eDragMove;
        this._eResizeHandle;
        this._eRemoveBtn;

        this._oInternalDragDropHelper = null;
    };

    getWidgetProps  () {
        return  {
            sName : this.psWidgetName,
            sDynId : this.psDynamicWidgetId,
            iRowIndex : this.piRowIndex,
            iColIndex : this.piColumnIndex,
            iRowSpan : this.piRowSpan,
            iColSpan : this.piColumnSpan,
            bFillHeight : this.pbFillHeight,
            aConfig : this.getCurrentConfiguration(),
            aResponsiveProps : []
        }
    }

    initInternalDrag (oHelper) {
        this._oInternalDragDropHelper = oHelper;
        this._oInternalDragDropHelper.registerDragSource(this.getLongName(), df.dragActions.WebWidgetContainer.ciDragWidget);
    } 

    getCurrentConfiguration () {
        return [];
    }

    setEditMode (bEdit) {
        this._bEditMode = bEdit;

        if (this._bEditMode) {
            this.showEditBox();
        } else {
            this.hideEditBox();
        }
    }


    showEditBox () {
        if(!this._eEditBox){
            const oW = this.getWebApp();
            
            let aHtml = [];
            let eBox;
            
            aHtml.push('<div class="WebCon_WebWidget_Edit_Box" data-dfwidgetid="' + this.psDynamicWidgetId + '" style="display: none"' + ((this._oInternalDragDropHelper || this.pbDragDropEnabled) ? ' draggable="true"' : '') + '>');
            aHtml.push('    <div class="WebCon_WebWidget_Top_Btns_Wrp">');
            aHtml.push('        <span class="WebCon_WebWidget_Drag_Indicator WebCon_Icon"  title="', oW.getTrans("webwidget_Drag"), '"></span>');
            aHtml.push('        <span class="WebCon_WebWidget_Edit_Btns_Wrp">');
            aHtml.push('            <span class="WebCon_WebWidget_Edit_Btn_Wrp"><span class="WebCon_WebWidget_Function_Btn WebCon_WebWidget_Edit_Btn WebCon_Icon" title="', oW.getTrans("webwidget_Config"), '"></span></span>');
            aHtml.push('            <span class="WebCon_WebWidget_Edit_Btn_Wrp"><span class="WebCon_WebWidget_Function_Btn WebCon_WebWidget_Remove_Btn WebCon_Icon" title="', oW.getTrans("webwidget_Remove"), '"></span></span>');
            aHtml.push('        </span>');
            aHtml.push('    </div>');
            aHtml.push('    <div class="WebCon_WebWidget_Bottom_Btns_Wrp">');
            aHtml.push('        <span class="WebCon_WebWidget_ResizeHandle_Wrp">')
            aHtml.push('            <span class="WebCon_WebWidget_Function_Btn WebCon_WebWidget_ResizeHandle WebCon_Icon"  title="', oW.getTrans("webwidget_Resize"), '"></span>');
            aHtml.push('        </span>');
            aHtml.push('    </div>');
            aHtml.push('</div>');
            
            this._eEditBox = eBox = df.dom.create(aHtml.join(''));
            this._eResizeHandle = df.dom.query(eBox, 'span.WebCon_WebWidget_ResizeHandle');
            this._eEditBtn = df.dom.query(eBox, 'span.WebCon_WebWidget_Edit_Btn');
            this._eRemoveBtn = df.dom.query(eBox, 'span.WebCon_WebWidget_Remove_Btn');
            
            df.events.addDomListener("mousedown", this._eResizeHandle, this.onWidgetResize, this);
            df.events.addDomListener("click", this._eEditBtn, this.onEditClick, this);
            df.events.addDomListener("click", this._eRemoveBtn, this.onRemoveClick, this);
            
            this._eElem.appendChild(eBox);
            
            if (!this.pbConfigurable) {
                this._eEditBtn.style.display = 'none';
            }
        }

        this.repositionEditBox();
    }

    repositionEditBox (){
        if (this._eEditBox) {
            if (this._eElem) {
                this.positionEditBox(df.sys.gui.getBoundRect(this._eContainer));
            } else {
                this._eSel.style.display = "none";
            }
        }
        
    }

    positionEditBox (oRect){
        this._eEditBox.style.display = "";
        this._eEditBox.style.width = Math.round(oRect.width) + 'px';
        this._eEditBox.style.height = Math.round(oRect.height) + 'px';

        if (this.pbAllowResize) {
            this._eResizeHandle.style.display = 'inline-block';
        } else {
            this._eResizeHandle.style.display = 'none';
        }
    }

    onEditClick (oEv) {
        if(this.pbConfigurable){
            this.editWidget()
        }
    }

    editWidget () {
        if (this._oParent?.editWidgetEx) {
            this._oParent.editWidgetEx(this);
        }
    }

    onRemoveClick (oEv) {
        this.removeWidget();
    }

    removeWidget () {
        if (this._oParent?.removeWidgetEx) {
            this._oParent.removeWidgetEx(this);
        }
    }

    calcResizeRows (iMouseY) {
        // get content bottom
        let iBottom = this._oParent._eContent.getBoundingClientRect().bottom;
        let iDefaultHeight = this._oParent.getDefaultRowHeight();
        let iDiff = (iMouseY - iBottom);

        if (iDiff > 0) {
            let iRowsToAdd = Math.ceil((iDiff / iDefaultHeight));
            this._oParent.addGhostRows(iRowsToAdd);
        } else if (iDiff < 0) {
            // This doesn't feel too great (jerky), but ghost rows are removed upon completing the resize and 
            // the experience feels better that way so for now we should probably just leave it like that..

            // let iRowsToremove = Math.floor((Math.abs(iDiff) / iDefaultHeight));
            // this._oParent.removeGhostRows(iRowsToremove);
        }
    }

    onWidgetResize (oEv) {
        var eElem, iRow, iCol, iStartRowIndex, iStartColIndex, iNewColSpan, iNewRowSpan, eMask, oObjParentContainer, oObj = this;
        var aCells = [], eCell;

        eElem = this._eElem;
        oObjParentContainer = this._oParent;
        this._oParent.snapshotChildrenPositions();

        if (oObjParentContainer && !oObjParentContainer.isGridLayout()) { return false; }

        // Select parent to show grid
        if (!oObjParentContainer._eGridOverLay) {
            if (!oObjParentContainer.drawGridOverlay()) { 
                return false; 
            }
        } 
        oObjParentContainer.showGrid(); 
        

        var aPointElems  = document.elementsFromPoint(oEv.getMouseX(), oEv.getMouseY());
        for (let e=0; e < aPointElems.length; e++) {
            if (aPointElems[e].classList.contains("WebCon_WebWidgetContainer_GridOverlay_Cell") ) {
                eCell = aPointElems[e];
                break;
            }
        }

        if(eCell){
            iStartRowIndex = determineRow(oObj, eCell);
            iStartColIndex = determineColumn(oObj, eCell);
        }else{
            iStartRowIndex = (oObj.piRowIndex > -1) ? oObj.piRowIndex : 0;
            iStartColIndex = (oObj.piColumnIndex > -1) ? oObj.piColumnIndex : 0;
        }

        this.bAutoRepos = false;

        // eMask = oObjParentContainer._eContainer;
        eMask = this.getWebApp()._eViewPort;
        if (!eMask) { return; }
        eMask.style.cursor = this._eEditBox.style.cursor = "nwse-resize";  
        

        function onResize(oEv) {
            let aPointElems;

            this.calcResizeRows(oEv.getMouseY());

            aPointElems  = document.elementsFromPoint(oEv.getMouseX(), oEv.getMouseY());
            for (let e=0; e < aPointElems.length; e++) {
                if (aPointElems[e].classList.contains("WebCon_WebWidgetContainer_GridOverlay_Cell") ) {
                    eCell = aPointElems[e];
                    break;
                }
            }

            if (eCell) {
                let sCellID = eCell.dataset.dfcellid;
                iRow = (parseInt(sCellID.split('-')[0]));
                iCol = (parseInt(sCellID.split('-')[1]));
                iNewRowSpan = iRow - iStartRowIndex + 1;
                iNewColSpan = iCol - iStartColIndex + 1;
            }


            let bColChanged = (iNewColSpan && (oObj.piColumnSpan !== iNewColSpan));
            let bRowChanged = (iNewRowSpan && (oObj.piRowSpan !== iNewRowSpan));

            if (bColChanged) {
                oObj.piColumnSpan = iNewColSpan;
            }
            if (bRowChanged) {
                oObj.piRowSpan = iNewRowSpan;
            }

            if (bColChanged || bRowChanged) {
                this._oParent.resetPositionsToSnapshot();
                let oRect = this._oParent.getObjRect(oObj)
                
                this._oParent.checkAndResolveCollisions(oRect, oObj);
                this._oParent.position();
            }
        }

        function onStopResize(oEv){
            df.events.removeDomListener("mouseup", eMask, onStopResize, this);
            df.events.removeDomListener("mouseup", window, onStopResize, this);
            df.events.removeDomListener("mousemove", eMask, onResize, this);

            if (oObjParentContainer && oObjParentContainer instanceof df.WebWidgetContainerInternal) {
                oObjParentContainer._eGridOverLay.style.cursor = 'default';
                
                oObjParentContainer.redrawGrid();

                oObjParentContainer.fire("ServerOnWidgetResized", JSON.stringify(this.getWidgetProps));
            }

            this.sizeChanged(true);
            
            eMask = this.getWebApp()._eViewPort;
            if (!eMask) { return; }
            eMask.style.cursor = "default";
            this._eEditBox.style.cursor = "grabbing";  
            oObjParentContainer.hideGrid(); 
        }

        function determineRow(oObj, eCell) {
            let iRowSpan = 1;

            if (oObj.piRowIndex > -1) { 
                return oObj.piRowIndex;
            }

            let sCellID = eCell.dataset.dfcellid;
            let iCellRow = (parseInt(sCellID.split('-')[0]));
            
            if (oObj.piRowSpan <= 0) {
                iRowSpan = 1;
            } else {
                iRowSpan = oObj.piRowSpan;
            }

            let iStartRow = iCellRow - (iRowSpan - 1);

            return iStartRow;
        }

        function determineColumn(oObj, eCell) {
            let iColSpan = 1;

            if (oObj.piColumnIndex > -1) { 
                return oObj.piColumnIndex;
            }

            let sCellID = eCell.dataset.dfcellid;
            let iCellCol = (parseInt(sCellID.split('-')[1]));

            if (oObj.piColumnSpan <= 0) {
                iColSpan = 1;
            } else {
                iColSpan = oObj.piColumnSpan;
            }

            let iStartCol = iCellCol - (iColSpan - 1);

            return iStartCol;
        }

        function clearHighlightedCells() {
            for (let iCell = 0; iCell < aCells.length; iCell++) {
                if (aCells[iCell]) {
                    aCells[iCell].style.backgroundColor = 'transparent';
                }
            }

            aCells = [];
        }

        df.events.addDomListener("mousemove", eMask, onResize, this);
        df.events.addDomListener("mouseup", window, onStopResize, this);
        df.events.addDomListener("mouseup", eMask, onStopResize, this);
            
        oEv.stop();
    }

    getDragData  (oEv, eDraggedElem) {
        let oData = {
            sControlName : this.getLongName(),
            WidgetProps : this.getWidgetProps()
        }

        this._oParent.initWidgetDrag(oEv, this);
        
        return [oData, df.dragActions.WebWidgetContainer.ciDragWidget]
    }

    moveWidget (iRow, iCol) {
        if (this.piRowIndex != iRow) {
            this.set_piRowIndex(iRow);
        }

        if (this.piColumnIndex != iCol) {
            this.set_piColumnIndex(iCol);
        }
    }

    getParentContainer  (eStartElem) {
        let oObjParentContainer;
        let eElem = eStartElem;
        let oWebApp = this.getWebApp();

        if (!oWebApp) { return; }

        while(eElem && eElem !== document && (!(oObjParentContainer && oObjParentContainer._bIsContainer) || (oObjParentContainer == this.oObj))){
            if(eElem.hasAttribute("data-dfobj")){
                oObjParentContainer = oWebApp.findObj(eElem.getAttribute("data-dfobj"));
            }
            eElem = eElem.parentNode;
        }

        return oObjParentContainer;
    }

    hideEditBox () {
        if (this._eEditBox) {
            this._eEditBox.parentNode.removeChild(this._eEditBox);
            this._eEditBox = null;
        }
    }

    createObserver (){
        if(!this._eElem || this._oObserver) return;

        this._oObserver = new ResizeObserver((entries) => {
            let nHeight = entries[0]?.contentRect.height;
            if (!nHeight){
                nHeight = this._eElem.getBoundingClientRect()?.height || 0;
            }
            this.sizeHeight(nHeight);

            // Whenever the size changes, reposition existing editbox (if shown)
            this.repositionEditBox();
        });

        this._oObserver.observe(this._eElem);

        this._oMutationObserver = new MutationObserver((mutationList) => {
            this.repositionEditBox();
        });

        this._oMutationObserver.observe(this._eElem, {
            attributes : true,
            attributeFilter: ["style"],
            attributeOldValue: true,});
    }

}