import { WebDynamicObjectContainer } from "../WebDynamicObjectContainer.js";
import { df } from '../../df.js';

df.tWidgetDef = {
    sName : df.tString,
    iRowIndex : df.tInt,
    iColIndex : df.tInt,
    iRowSpan : df.tInt,
    iColSpan : df.tInt,
    bFillHeight : df.tBool,
    aConfig : [df.tAdv],
    aResponsiveProps : [df.tAdv]
}

df.tContainerDef = {
    sConfigVersionCode : df.tString,
    aWidgets : [df.tWidgetDef]
}

export class WebWidgetContainerInternal extends WebDynamicObjectContainer {

    constructor(sName, oParent){
        super(sName, oParent);

        oParent._oWidgetContainer = this;

        this.prop(df.tBool, "pbDisableInternalDragDropHelper", false);
        this.prop(df.tBool, "pbUseCustomConfigurationStorage", false);
        
        // Event props
        this.prop(df.tBool, "pbServerOnToggleEditMode", false);
        this.prop(df.tBool, "pbServerOnWidgetMoved", false);
        this.prop(df.tBool, "pbServerOnWidgetResized", false);
        
        this.event("OnToggleEditMode", df.cCallModeWait);
        
        this.pbEditMode = oParent.pbEditMode;
        this.pbShowEditButton = oParent.pbShowEditButton;
        this.pbShowEditMenu = oParent.pbShowEditMenu;

        this._aWidgets = [];
        this._aHighlightedCells = [];
        this._eEditMenu;
        this._eEditWrp;
        this._oSelectedWidget = null;
        this._oInternalDragDropHelper = null;
        this._ePlaceHolder;
        this._oCurDragControl = null;
        this._aChildrenSnapShot = [];
        this._bResolvingCollisions = false;
        this._iCurrentHoverCol = -1;
        this._aWidgetDefaultSizes = [];
        this._iRowsActual = -1;
        this._iGhostRows = 0;

        // Configure super classes
        this._sBaseClass = "WebDynamicObjectContainer";
        this._sControlClass = "WebWidgetContainer";
    }

    afterRender () {
        super.afterRender();

        this._oParent._oWidgetContainer = this;

        this.applyProps();

        if(!this._eEditWrp){
            this._eEditWrp = df.dom.create('<div class="WebCon_WebWidgetContainer_Edit_Wrp"></div>');
            this._eContent.appendChild(this._eEditWrp);

            this.set_pbShowEditButton(this.pbShowEditButton);
            this.set_pbShowEditMenu(this.pbShowEditMenu);
        }

        this.drawGridOverlay();

        this.setEditMode(this.pbEditMode);
    }

    set_pbShowEditButton (bVal) {
        const oW = this.getWebApp();

        this.pbShowEditButton = bVal;

        const eEditWrp = this._eEditWrp;
        if(eEditWrp){
            if(bVal){
                if(!this._eToggleEditBtn){
                    this._eToggleEditBtn = df.dom.create(`<span class="WebCon_WebWidgetContainer_Toggle_Edit_Btn WebCon_Icon" title="${oW.getTrans("webwidgetcon_ToggleEdit")}" ${(this.pbEditMode ? 'style="display:none"' : '')} ></span>`);
                    eEditWrp.appendChild(this._eToggleEditBtn);
                    df.events.addDomListener("click", this._eToggleEditBtn, this.toggleEditMode, this);
                }
            }else{
                if(this._eToggleEditBtn){
                    this._eToggleEditBtn.parentNode.removeChild(this._eToggleEditBtn);
                    this._eToggleEditBtn = null;
                }
            }
        }
    }


    set_pbShowEditMenu (bVal) {
        const oW = this.getWebApp();

        this.pbShowEditMenu = bVal;

        const eEditWrp = this._eEditWrp;
        if (eEditWrp){
            if(bVal){
                if(!this._eEditMenu){
                    this._eEditMenu = df.dom.create(`<span class="WebCon_WebWidgetContainer_Edit_Menu" ${(this.pbEditMode ? '': 'style="display:none"')}></span>`);
                    eEditWrp.appendChild(this._eEditMenu);
                    
                    let eResetBtn = df.dom.create(`<span class="WebCon_WebWidgetContainer_Reset_Configuration_Btn WebCon_Icon" title="${oW.getTrans("webwidgetcon_ResetConfig")}"></span>`);
                    this._eEditMenu.appendChild(eResetBtn);
                    df.events.addDomListener("click", eResetBtn, this.resetConfiguration, this);

                    let eSaveEditsBtn = df.dom.create(`<span class="WebCon_WebWidgetContainer_Save_Edits_Btn WebCon_Icon" title="${oW.getTrans("webwidgetcon_SaveEdits")}"></span>`);
                    this._eEditMenu.appendChild(eSaveEditsBtn);
                    df.events.addDomListener("click", eSaveEditsBtn, this.saveConfiguration, this);
                    
                    let eCancelEditsBtn = df.dom.create(`<span class="WebCon_WebWidgetContainer_Cancel_Edits_Btn WebCon_Icon" title="${oW.getTrans("webwidgetcon_CancelEdits")}"></span>`);
                    this._eEditMenu.appendChild(eCancelEditsBtn);
                    df.events.addDomListener("click", eCancelEditsBtn, this.cancelEdits, this);
                }
            }else{
                if(this._eEditMenu){
                    this._eEditMenu.parentNode.removeChild(this._eEditMenu);
                    this._eEditMenu = null;
                }
            }
        }
    }

    create (){
        super.create();
        
        if (!this.pbDisableInternalDragDropHelper) {
            this.initInternalDragDropHelper();
        }
    }

    applyProps () {
        this.pbDisableInternalDragDropHelper    = this._oParent?.pbDisableInternalDragDropHelper;
        this.pbUseCustomConfigurationStorage    = this._oParent?.pbUseCustomConfigurationStorage;
        this.pbServerOnToggleEditMode           = this._oParent?.pbServerOnToggleEditMode;
        this.pbServerOnWidgetMoved              = this._oParent?.pbServerOnWidgetMoved;
        this.pbServerOnWidgetResized            = this._oParent?.pbServerOnWidgetResized;
    }

    // Initializes the internal drag drop helper to be used
    initInternalDragDropHelper () {
        if (this._oInternalDragDropHelper) { return; }

        this._oInternalDragDropHelper = new df.WebWidgetContainerDragDropHelper(this.getLongName()+'int-dragdrop-helper', this);
        
        this._oInternalDragDropHelper.registerDropTarget(this.getLongName(), df.dropActions.WebWidgetContainer.ciDropOnCell);
    } 

    loadDynamicObjects () {
        super.loadDynamicObjects();
    
        for (let i = 0; i < this._aChildren.length; i++) {
            const oChild = this._aChildren[i];
        
            if (oChild instanceof df.WebWidget) {
                oChild.setEditMode(this.pbEditMode);
                if (!this.pbDisableInternalDragDropHelper) {
                    oChild.initInternalDrag(this._oInternalDragDropHelper);
                }
            }
        }

        this.calcRowsActual();
        this.drawGridOverlay();
    }

    loadWidgets  (tConfiguration) {
        this._tActionData = tConfiguration;
        this.loadDynamicObjects();
    }

    calcRowsActual  () {
        this._iRowsActual = this.piRowCount;
        let oChild;

        // Loop through widgets and find the highest row index + span
        for (let i=0; i < this._aChildren.length; i++) {
            oChild = this._aChildren[i];
            if (oChild instanceof df.WebWidget) {
                oChild = this._aChildren[i];
                if ((oChild.piRowIndex + oChild.piRowSpan) > this._iRowsActual) {
                    this._iRowsActual = (oChild.piRowIndex + oChild.piRowSpan);
                }
            }
        }

        return this._iRowsActual;
    }

    registerWidgetDefaultSizes () {
        let aWidgets = this._tActionData;

        for (let i = 0; i < aWidgets.length; i++) {
            this._aWidgetDefaultSizes.push({
                sName : aWidgets[i].sName,
                iRowSpan : aWidgets[i].iRowSpan,
                iColSpan : aWidgets[i].iColSpan
            });
        }
    }

    registerWidget (sObjName) {
        let oWebApp = this.getWebApp();
        let oWidget = oWebApp?.findObj(sObjName);

        if (oWidget) {
            oWidget.setEditMode(this.pbEditMode);

            if (this._oInternalDragDropHelper) {
                oWidget.initInternalDrag(this._oInternalDragDropHelper);
            }

            oWidget.sizeChanged(true);
        }
    }

    findSpotForWidget () {
        const oWidgetDef = this._tActionData;
        let iDefaultRowSpan = 1;
        let iDefaultColSpan = 1;

        for (let i = 0; i < this._aWidgetDefaultSizes.length; i++) {
            let oDef = this._aWidgetDefaultSizes[i];
            if (oDef.sName == oWidgetDef.sName) {
                iDefaultRowSpan = oDef.iRowSpan
                iDefaultColSpan = oDef.iColSpan
            }
        }

        oWidgetDef.iRowSpan = oWidgetDef.iRowSpan > 0 ? oWidgetDef.iRowSpan : iDefaultRowSpan;
        oWidgetDef.iColSpan = oWidgetDef.iColSpan > 0 ? oWidgetDef.iColSpan : iDefaultColSpan;

        let [iRow, iCol] = this.findSpotForWidgetEx(oWidgetDef.iRowSpan, oWidgetDef.iColSpan);

        oWidgetDef.iRowIndex = iRow;
        oWidgetDef.iColIndex = iCol;

        this.serverAction("AppendWidgetEx", [], oWidgetDef, null);
    }

    findSpotForWidgetEx (iRowSpan, iColSpan) {
        let oObjRect = {};

        let aCollisionObjs = [];

        for (let r = 0; r < this._iRowsActual; r++) {
            for (let c = 0; c < (this.piColumnCount - iColSpan); c++) {
                oObjRect = {
                    iRowMin : r,
                    iRowMax : (r + iRowSpan - 1),
                    iColMin : c,
                    iColMax : (c + iColSpan - 1),
                    iRowSpan : iRowSpan,
                    iColSpan : iColSpan
                };

                aCollisionObjs = this.checkForCollisions(oObjRect);

                if (aCollisionObjs.length <= 0) {
                    return [r, c];
                }
            }
        }

        return [this._iRowsActual, 0];
    }

    editWidgetEx (oObj) {
        // Open wizard
        this.serverAction("RequestConfigWizard", [oObj.getLongName()], null, null);
    }

    removeWidget (sObjName) {
        let oWebApp = this.getWebApp();
        let oWidget = oWebApp?.findObj(sObjName);

        if (oWidget) {
            this.removeWidgetEx(oWidget);
        }
    }

    removeWidgetEx (oObj) {
        this.serverAction("RemoveWidget", [oObj._sName], oObj.getWidgetProps());
    }

    saveConfiguration  () {
        // generate configuration...
        let tConfiguration = this.serializeDashboard() || {};

        this.serverAction("ServerOnSaveConfiguration", [], tConfiguration, null, null);

        this.toggleEditMode();
    }

    saveConfigurationToLocalStorage () {
        const oConfig = this._tActionData;

        this.saveConfigurationToLocalStorageEx(oConfig);
    }

    saveConfigurationToLocalStorageEx  (oConfig) {
        if (!df.pbDebugging) {
            try {
                localStorage.setItem(this.getStorageName("dashboard"), JSON.stringify(oConfig));
            } catch (ex) {
                // Ignore
            }
        }
    }

    resetConfiguration () {
        this.serverAction("ResetConfiguration", [], null, null, null);
    }

    // Resets the local configuration by removing the data from storage. Ensures a new default will be loaded
    resetLocalConfiguration () {
        if (!df.pbDebugging) {
            try {
                localStorage.removeItem(this.getStorageName("dashboard"));
            } catch (ex) {
                // Ignore
            }
        }
    }

    // This is used to force invalidate an existing configuration based on a new version key
    invalidateLocalConfiguration () {
        // ToDo: Should we maybe add an (optional paramater?) message here? "Your dashboard configuration has been reset"
        this.resetLocalConfiguration();
    }

    getStorageName  (sPostFix) {
        if (sPostFix && sPostFix.length > 0) {
            return window.location.host + 
            "." + window.location.pathname + 
            "." + this.getLongName() +
            "@" + sPostFix;
        }

        return window.location.host + 
        "." + window.location.pathname + 
        "." + this.getLongName();
    }

    serializeDashboard  () {
        let oDashboardConfig = {
            sConfigVersionCode : this._oParent.psConfigVersionCode,
            aWidgets : []
        };

        for (let i = 0; i < this._aChildren.length; i++) {
            oDashboardConfig.aWidgets.push(this._aChildren[i].getWidgetProps());
        }

        return oDashboardConfig;
    }

    widgetByName (sName){
        return this[sName] || null;
    }  

    loadConfigurationFromLocalStorage (bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        let oConfig = null;

        // if (!df.pbDebugging) {
            const sConfig = localStorage.getItem(this.getStorageName("dashboard"));
            if (sConfig) {
                try {
                    oConfig = JSON.parse(sConfig);
                // eslint-disable-next-line no-unused-vars
                } catch (ex) {
                    if (sConfig) { // Remove invalid cache.
                        localStorage.removeItem(this.getStorageName("dashboard"));
                    }
                    oConfig = null;
                }
            }
        // }

        
        this.serverAction("LoadConfigurationFromLocalStorage", [ df.fromBool(!!oConfig) ], oConfig, null, null);
        

        return oConfig;
    }

    toggleEditMode() {
        this.set_pbEditMode(!this.pbEditMode);
    }

    setEditMode(bVal) {
        for (let i = 0; i < this._aChildren.length; i++) {
            const oChild = this._aChildren[i];
            
            if (oChild instanceof df.WebWidget) {
                oChild.setEditMode(bVal);
            }
        }
        if(this._eToggleEditBtn) this._eToggleEditBtn.style.display = bVal ? 'none' : '';
        if(this._eEditMenu) this._eEditMenu.style.display = bVal ? 'flex' : 'none';

        this.fire("OnToggleEditMode", [df.fromBool(bVal)]);
    }

    cancelEdits () {
        // (re)Load (existing) configuration
        this.serverAction("Reload", [], null, null);
        
        this.toggleEditMode();
    }

    // Grid overlay (for editing)

    drawGridOverlay  () {
        if (this._eGridOverLay) {
            this.destroyGrid();
        }
        
        let oObj = this;

        if (oObj._bPanels) { return false; }

        let oContainerRect = this.getContainerRect(oObj);
        if(!oContainerRect) return;

        let aCols = this.determineColumns(oObj);
        let aRows = this.determineGridOverlayRows(oObj);

        // Now we can use the column and row info to construct our grid overlay
        // We'll create a table and position it absolute, then attach handles later
        // Every row will be a <tr> with a <td> inside for each column
        // We'll use the info in aRows and iColWidth to individually size each column / row inline

        let aHtml = []; // Will be used to build our table html

        aHtml.push('<Table class="WebCon_WebWidgetContainer_GridOverlay" style="display: none; opacity: 0;" data-dfcontainerobj="', oObj._eElem.dataset.dfobj ,'"><tbody>');
        for (let r = 0; r < aRows.length; r++) {
            let sRow = this.genGridRowHtml(r, aRows[r], aCols);

            aHtml.push(sRow);
        }
        aHtml.push('</tbody></table>');

        this._eGridOverLay = df.dom.create(aHtml.join(""));
        this._eContainer.prepend(this._eGridOverLay);

        this._iRowCount = aRows.length;

        return true;
    }

    genGridRowHtml (iRowNum, iRowHeight, aCols, bIsGhostRow) {
        let sRow = '<tr style="height: ' + iRowHeight + 'px; border-bottom: 1px dashed rgba(84, 175, 255, 0.5);'
        if (iRowNum == 0) {
            sRow += 'border-top: 1px dashed rgba(84, 175, 255, 0.5);'
        }
        sRow += '"';
        if (bIsGhostRow) {
            sRow += ' data-dfisghostrow="true"' 
        }
        sRow += '>'

        // Add columns
        let sColTemplate = '';
        for (let c = 0; c < aCols.length; c++) {
            sColTemplate += '<td class="WebCon_WebWidgetContainer_GridOverlay_Cell" data-dfcellid="' + iRowNum + '-' + c + '" style="position: relative; width: ' + (c == 0 ? (aCols[c] - 2) : (aCols[c] - 1)) + 'px; '
            if (c == 0) {
                sColTemplate += 'border-left: 1px dashed rgba(84, 175, 255, 0.5); '
            }
            sColTemplate += 'border-right: 1px dashed rgba(84, 175, 255, 0.5);">'
            sColTemplate += '</td>'
        }

        sRow += sColTemplate + '</tr>';

        return sRow;
    }

    // Determines and returns column count and width for the container
    determineColumns (oObj, oRect) {
        return oObj.determineColumnWidths(); 
    }

    // Determines rows and their respective heights for the container
    // If the container stuff is done properly, we can simply get the rows from the underlying container object...
    // Convenience function for now in case we need to do extra stuff at a later stage
    determineRows (oObj) {
        return oObj.determineRowHeights();
    }

    determineGridOverlayRows  (oObj) {
        let aRows = this.determineRows(oObj);

        if (aRows.length < this._iRowsActual) {
            let sBaseRowHeight = this.genBaseRowHeightString();
            for (let i = aRows.length; i < this._iRowsActual; i++) {
                aRows.push(sBaseRowHeight);
            }
        }

        return aRows;
    }

    redrawGrid () {   
        this._eGridOverLay?.parentNode?.removeChild(this._eGridOverLay);
        this._eGridOverLay = null;


        this.drawGridOverlay(this.oObj);
    }

    destroyGrid () {
        if (this._eGridOverLay) {
            this._eGridOverLay.parentNode.removeChild(this._eGridOverLay);
            this._eGridOverLay = null;
        }
    }

    findParentWidget (oControl) {
        if (oControl instanceof df.WebWidget || oControl instanceof df.WebView) {
            return oControl;
        }

        else {
            return this.findParentWidget(oControl._oParent);
        }
    }

    toggleGrid  () {
        if (this._eGridOverLay) {
            if (this._eGridOverLay.style.display == 'none') {
                this._eGridOverLay.style.display = "table";
                this._bGridVisible = true;
            } else {
                this._eGridOverLay.style.display = 'none';
                this._bGridVisible = false;
            }
        }
    }

    showGrid  (oOptObj) {
        if (this._eGridOverLay) {
            this._eGridOverLay.style.display = "table";
            this._bGridVisible = true;
        }
    }

    hideGrid  () {
        if (this._eGridOverLay) {
            this._eGridOverLay.style.display = "none";
            this._bGridVisible = false;
        }
    }

    getContainerRect (oObj) {
        if(!oObj || !oObj._eContent) return null;
        
        let oContainerRect = df.sys.gui.getBoundRect(oObj._eContent);
        let oStyle = df.sys.gui.getCurrentStyle(oObj._eContent);

        // Remove paddings
        let iLeft = oContainerRect.left + parseFloat(oStyle.paddingLeft);
        let iRight = oContainerRect.right - parseFloat(oStyle.paddingRight);
        let iTop = oContainerRect.top + parseFloat(oStyle.paddingTop);
        let iBottom = oContainerRect.bottom - parseFloat(oStyle.paddingBottom);

        return {
            left: iLeft,
            right: iRight,
            top: iTop,
            bottom: iBottom,
            width: iRight - iLeft,
            height: iBottom - iTop
        }
    }

    refreshOverlay () {
        this.redrawGrid();
    }

    set_pbEditMode (bVal) {
        this.pbEditMode = bVal;
        this.setEditMode(bVal);
        
        this._oParent?.addSync("pbEditMode");
    }

    set_ptContainerDef  (tConfiguration) {
        this.ptContainerDef = tConfiguration;
        this.saveConfigurationToLocalStorage();
    }

    // WidgetContainer only supports Grid
    set_peLayoutType (eVal) {    
        this.peLayoutType =  df.layoutType.ciLayoutTypeGrid;
    }

    // Always return grid
    layoutType (){
        return df.layoutType.ciLayoutTypeGrid;
    }

    // Override since we want to use fixed row heights in the widgetcontainer
    genBaseRowHeightString (iHeight) {
        return ("" + iHeight + "px");
    }


    // Dragdrop

    getDragData  (oEv, eDraggedElem) {
        return [null, null];
    }

    getDropData  (oDropZone, oPosition) {
        let dropData = {
            data : {
                iRow : -1,
                iCol : -1
            },
            action : df.dropActions.WebWidgetContainer.ciDropOnCell
        };

        // returns the cell (row + column)
        const sCellID = (oDropZone._eDropElem && oDropZone._eDropElem.getAttribute("data-dfcellid")) || '';

        let iDropRow, iDropCol;

        
        if (sCellID && sCellID != '') {
            iDropRow = (parseInt(sCellID.split('-')[0]));
            iDropCol = (parseInt(sCellID.split('-')[1]));
        }

        if (this._oWidgetDragInfo) {
            iDropRow = Math.max(0, (iDropRow - this._oWidgetDragInfo.iRowOffset));
            iDropCol = Math.max(0, (iDropCol - this._oWidgetDragInfo.iColOffset));
        }

        dropData.data.iRow = iDropRow;
        dropData.data.iCol = iDropCol;

        let sWidgetName = this.findWidgetNameInDragData(oDropZone._aHelpers[0]._oDragData);
        for (let i = 0; i < this._aWidgetDefaultSizes.length; i++) {
            let oDef = this._aWidgetDefaultSizes[i];
            if (oDef.sName == sWidgetName) {
                dropData.data.iRowSpan = oDef.iRowSpan
                dropData.data.iColSpan = oDef.iColSpan
            }
        }

        return dropData;
    }

    determineGridCell (iX, iY) {
        let aElems = document.elementsFromPoint(iX, iY);

        for (let i = 0; i < aElems.length; i++) {
            if (aElems[i].classList.contains('WebCon_WebWidgetContainer_GridOverlay_Cell')) {
                return aElems[i];
            }
        }

        return null;
    }

    initDropZones  () {
        this._aDropZones = [];
        
        super.initDropZones();

        // Mark grid as valid dropzone??
        if (this.isSupportedDropAction(df.dropActions.WebWidgetContainer.ciDropOnCell)) {
            this.addDropZone(this._eElem, this);
        }
    }

    determineDropCandidate (oEv, aHelpers) {
        // DropOnControl and other drop actions cannot exist within the same control simultaneously
        // It makes sense to check for this first to get it out of the way as it is the simplest check
        if(aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebControl.ciDropOnControl))){
            return [this._eElem, df.dropActions.WebControl.ciDropOnControl] ;
        }

        // Check for ciDropOnCell, no need to continue if it doesn't exist
        if(!aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebWidgetContainer.ciDropOnCell))){
            return [null, null];
        }
        
        // Determine cell
        let eCell = this.determineGridCell(oEv.e.x, oEv.e.y);

        if (eCell) {
            return [eCell, df.dropActions.WebWidgetContainer.ciDropOnCell];
        }

        return [null, null];
    }

    // This is needed to stop the widget from instantly snapping to the mouse cursor.
    initWidgetDrag (oEv, oWidget) {
        this.redrawGrid();
        this.showGrid();
        let eCell = this.determineGridCell(oEv.e.x, oEv.e.y);
        this.hideGrid();
        let [iRow, iCol] = eCell?.dataset.dfcellid.split('-') || [0, 0];

        let iRowOffset = iRow - oWidget.piRowIndex;
        let iColOffset = iCol - oWidget.piColumnIndex;

        this._oWidgetDragInfo = {
            oWidget,
            iRow,
            iCol,
            iRowOffset,
            iColOffset
        }

    }

    highlightDropZones  (oHelper) {
        super.highlightDropZones(oHelper);

        // 'Abusing' this entry point to init some stuff
        this.snapshotChildrenPositions();
        this._iCurrentHoverCol = -1;

        this._oCurDragControl = oHelper._oDragData.oControl;
        
        this.showGrid();
    }

    cleanupDropZones () {
        super.cleanupDropZones();
        
        // 'Abusing' this exit point to reset values
        this._aChildrenSnapShot = [];
        this._iCurrentHoverCol = -1;
        this._ePlaceHolder?.parentNode.removeChild(this._ePlaceHolder);
        this._ePlaceHolder = null;
        this._oCurDragControl = null;
        this._oWidgetDragInfo = null;
        this._bResolvingCollisions = false;
        this.removeGhostRows(0);

        this.hideGrid();
    }


    interactWithDropElem (dropZone, eElem) {
        if (dropZone._eDropAction == df.dropActions.WebControl.ciDropOnControl) {
            dropZone.highlightElement();
        } else {
            // This would normally highlight the hovered cell, but we can use this to determine where we are and what to push - 
            // this marks the entry point of our sexy push logic :)
            dropZone.highlightElement();
            let [iRow, iCol] = eElem.dataset.dfcellid.split('-');
            iRow = parseInt(iRow);
            iCol = parseInt(iCol);

            let oObjRect = {
                iColMin : iCol,
                iColMax : iCol,
                iRowMin : iRow,
                iRowMax : iRow
            };


            // Small optimization to prevent checking on every mouse move (very spammy!), only check when we actually changed row or column
            if (this._iCurrentHoverCol != iCol || this._iCurrentHoverRow != iRow) {
                this.resetPositionsToSnapshot();
                this._iCurrentHoverCol = iCol;
                this._iCurrentHoverRow = iRow

                let oDragControl = dropZone._aHelpers[0]._oDragData.oControl;

                // If obj is widget, use it to create objRect (for collisions and placeholder)
                if (oDragControl instanceof df.WebWidget) {
                    this._oCurDragControl = oDragControl;

                    let iNewRow = Math.max(0, (iRow - this._oWidgetDragInfo.iRowOffset));
                    let iNewCol = Math.max(0, (iCol - this._oWidgetDragInfo.iColOffset));

                    oObjRect.iRowMin = iNewRow;
                    oObjRect.iColMin = iNewCol;

                    oObjRect.iColSpan = oDragControl.piColumnSpan;
                    oObjRect.iRowSpan = oDragControl.piRowSpan;
                    oObjRect.iColMax = (oObjRect.iColMin + (oDragControl.piColumnSpan - 1));
                    oObjRect.iRowMax = (oObjRect.iRowMin + (oDragControl.piRowSpan));

                    oDragControl.piRowIndex = iNewRow;
                    oDragControl.piColumnIndex = iNewCol;
                    this.position();
                } else {
                    let sWidgetName = this.findWidgetNameInDragData(dropZone._aHelpers[0]._oDragData);
                    this.getObjRectFromDefaultSizes(sWidgetName, oObjRect);

                    // Insert placeholder based on objRect
                    if (!this._ePlaceHolder) {
                        let sPlaceholderHtml = '<div class="WebCon_Widget_PlaceHolder" style="border: 1px dotted black; grid-area: ' + (iRow + 1) + ' / ' + (iCol + 1) + ' / span ' + oObjRect.iRowSpan + ' / span ' + oObjRect.iColSpan + ';"></div>';
                        this._ePlaceHolder = df.dom.create(sPlaceholderHtml);
                        this._eContent.appendChild(this._ePlaceHolder);
                    } else {
                        // Update placeholder
                        this._ePlaceHolder.style.gridArea = '' + (iRow + 1) + ' / ' + (iCol + 1) + ' / span ' + oObjRect.iRowSpan + ' / span ' + oObjRect.iColSpan;
                    }
                }
                
                // Check (and potentially resolve) collisions (recursive action)
                this.checkGridBottom(oObjRect);
                this.checkAndResolveCollisions(oObjRect);
            }
        }
    }

    checkGridBottom  (oObjRect) {
        let iCurGhostRows = (this._iGhostRows >= 0) ? this._iGhostRows : 0;
        // If the object spans only 1 row, we want to overflow earlier so we can add an additional row still
        let iRefRow = (oObjRect.iRowSpan > 1) ? oObjRect.iRowMax : (oObjRect.iRowMax + 1);
        let iRowDiff = (iRefRow - (this._iRowsActual + iCurGhostRows));

        if (iRowDiff > 0) {
            this._iGhostRows += iRowDiff;
            this.addGhostRows(iRowDiff);
        } else {
            if (iCurGhostRows > 0) {
                this.removeGhostRows(iRefRow);
            }
        }
    }

    addGhostRows  (iRowsToAdd) {
        let sGhostRowsHtml = '';
        let aCols = this.determineColumns(this);
        let aeRows = df.dom.query(this._eGridOverLay, 'tr', true);
        let iNewRowNum = aeRows.length;
        let iDefaultRowHeight = this.getDefaultRowHeight();

        let eGridoverLayTableBody = df.dom.query(this._eGridOverLay, 'tbody');

        if (eGridoverLayTableBody) {
            for (let i = 0; i < iRowsToAdd; i++) {
                sGhostRowsHtml += this.genGridRowHtml(iNewRowNum, iDefaultRowHeight, aCols, true);
            }
            eGridoverLayTableBody.innerHTML = eGridoverLayTableBody.innerHTML + sGhostRowsHtml;
        }
    }

    removeGhostRows  (iToRow) {
        let aeRows = Array.from(df.dom.query(this._eGridOverLay, 'tr', true));
        let eRow;

        while (aeRows.length > iToRow) {
            eRow = aeRows.pop();
            if (eRow.dataset.dfisghostrow == 'true') {
                eRow.parentNode.removeChild(eRow);
                this._iGhostRows--;
            }
        }
    }

    findWidgetNameInDragData (oDragData) {
        if (oDragData.oControl instanceof df.WebList) {
            // Assume name is in row's rowId
            return oDragData.oData.data.sRowId;
        } else if (oDragData.oControl instanceof df.WebTreeView) {
            // Assume name is in node value
            return oDragData.oData.data.sValue;
        } else {
            // Data should be in string format
            return oDragData.oData.data;
        }
    }

    getObjRectFromDefaultSizes (sWidgetName, oObjRect) {
        for (let i = 0; i < this._aWidgetDefaultSizes.length; i++) {
            let oDef = this._aWidgetDefaultSizes[i];
            if (oDef.sName == sWidgetName) {
                oObjRect.iColSpan = oDef.iColSpan;
                oObjRect.iRowSpan = oDef.iRowSpan;
                oObjRect.iColMax = (oObjRect.iColMin + (oDef.iColSpan - 1));
                oObjRect.iRowMax = (oObjRect.iRowMin + (oDef.iRowSpan));
            }
        }
    }

    snapshotChildrenPositions () {
        for (let i = 0; i < this._aChildren.length; i++) {
            this._aChildrenSnapShot.push(this._aChildren[i].piRowIndex);
        }
    }

    resetPositionsToSnapshot () {
        for (let i = 0; i < this._aChildren.length; i++) {
            this._aChildren[i].piRowIndex = this._aChildrenSnapShot[i];
        }

        this.position();
    }

    // oObjRect = {
    //      iColMin : ...,
    //      iColMax : ...,
    //      iRowMin : ...,
    //      iRowMax : ...
    //  }

    checkForCollisions (oObjRect, oOptRefObj) {
        let aCollisionObjs = [];

        for (let i=0; i < this._aChildren.length; i++) {
            let oChild = this._aChildren[i];  

            if (oChild != this._oCurDragControl && oChild != oOptRefObj && this.isWithinObjRect(oObjRect, oChild)) {
                // Mark for move
                aCollisionObjs.push(oChild);
            }
        }

        return aCollisionObjs;
    }

    checkAndResolveCollisions  (oObjRect, oOptRefObj) {
        let aCollisionObjs = this.checkForCollisions(oObjRect, oOptRefObj)

        let c = 0;
        // Resolve collisions (recursive)
        while (c < aCollisionObjs.length) {
            if (!this._bResolvingCollisions) {
                this.resolveCollision(aCollisionObjs[c], oObjRect);
                c++;
            }
        }
    }

    resolveCollision  (oObj, oCurObjRect) {
        if (!this._bResolvingCollisions) {
            this._bResolvingCollisions = true;
            
            oObj.piRowIndex = oCurObjRect.iRowMax;
            this.position();

            let oObjRect = this.getObjRect(oObj);

            this.checkAndResolveCollisions(oObjRect, oObj);
        }
    }

    position () {
        super.position();

        this._bResolvingCollisions = false;
    }

    getObjRect  (oObj) {
        let oObjRect = {
            iColMin : oObj.piColumnIndex || 0,
            iColMax : (oObj.piColumnIndex + (oObj.piColumnSpan - 1)) || 0,
            iRowMin : oObj.piRowIndex || 0,
            iRowMax : (oObj.piRowIndex + (oObj.piRowSpan)) || 0,
        }

        return oObjRect;
    }

    isWithinObjRect  (oObjRect, oChild) {
        let aObjCols = [];
        let aChildCols = [];
        const iChildColMax = oChild.piColumnIndex + (oChild.piColumnSpan - 1);

        for (let c = oObjRect.iColMin; c <= oObjRect.iColMax; c++) {
            aObjCols.push(c);
        }
    
        for (let c = oChild.piColumnIndex; c <= iChildColMax; c++) {
            aChildCols.push(c);
        }

        if ((this.arrayIntersections(aChildCols, aObjCols)).length > 0) {
            let aObjRows = [];
            let aChildRows = [];
            const iChildRowMax = oChild.piRowIndex + (oChild.piRowSpan - 1);

            for (let r = oObjRect.iRowMin; r <= oObjRect.iRowMax; r++) {
                aObjRows.push(r);
            }
            
            for (let r = oChild.piRowIndex; r <= iChildRowMax; r++) {
                aChildRows.push(r);
            }

            return ((this.arrayIntersections(aChildRows, aObjRows)).length > 0);
        }

        return false;
    }

    // This may seem inefficient, but is actually a O(n) speed operation and faster than checking every edge of our rectangles manually
    arrayIntersections  (a, b) {
        const setA = new Set(a);
        return b.filter(value => setA.has(value));
    }


    highlightGridCell (eCell) {
        for (let i = 0; i < this._aHighlightedCells.length; i++) {
            this._aHighlightedCells[i].style.backgroundColor = 'transparent';
        }

        this._aHighlightedCells = [];

        eCell.style.backgroundColor = 'rgba(84, 175, 255, 0.5)';
        this._aHighlightedCells.push(eCell);
    }

    resize () {
        super.resize();

        if (this._eGridOverLay) {
            this.redrawGrid();
        }
    }

}