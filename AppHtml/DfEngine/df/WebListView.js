import { WebListModel } from './WebListModel.js';
import { df } from '../df.js';
/*
Class:
    WebListView

The simple non scrolling body view for the WebList its mini MVC model. It simply renders all rows 
without a scollbar.
    
Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
export class WebListView {

    constructor(oList, oModel, oController) {
        this.oL = oList;
        this.oM = oModel;
        this.oC = oController;
        this.oR = oList._oRowRenderer;

        this.bPreventSubmit = false;    //  If true the double click will not triger the onsubmit. This is used by OnTableClick to explicitly prevent the OnSubmit if OnRowClick is fired.
        this.bCancelClick = false;      //  If true clicks are ignored

        this.bScroll = false;

        this.onRowsRendered = new df.events.JSHandler();

        oModel.onDataUpdate.on(this.onDataUpdate, this);
        oModel.onRowChange.on(this.onRowChange, this);
        oList._onSettingChange.on(this.onSettingChange, this);
        oController.onCellClick.on(this.onCellClick, this);
        oController.onAfterCellClick.on(this.onAfterCellClick, this);
    }

    genHtml(aHtml) {

        aHtml.push('<div class="WebList_BodyWrp">');
        aHtml.push('<div class="WebList_Body', (this.oL.pbShowSelected ? ' WebList_ShowSelected' : ''), '">');

        this.tableHtml(aHtml);

        aHtml.push('</div></div>');

    }

    afterRender(eList) {
        this.eRowContainer = this.eBody = df.dom.query(eList, "div.WebList_Body");
        this.eBodyWrp = df.dom.query(eList, "div.WebList_BodyWrp");

        df.dom.addClass(this.oL._eControl, (this.bScroll ? 'WebList_Scrolling' : 'WebList_NoScrolling'));

        df.events.addDomListener("click", this.eBody, this.onTableClick, this);
        df.events.addDomListener("dblclick", this.eBody, this.onTableDblClick, this);

        //  Notify other modules of the rendering of rows (genHtml generates rows right away)
        this.onRowsRendered.fire(this);
    }

    /**
     * Generates HTML for the group header (by appending it to the aHtml array.)
     * 
     * @param {Integer} iGroupHeaderIndex Index of the group header.
     * @param {Array} aHtml String builder array.
     * @param {Integer} iItemIndex Index in the aDisplay array of the model.
     */
    groupHeaderHtml(aHtml, iGroupHeaderIndex, iItemIndex) {
        const oM = this.oM;

        if (iGroupHeaderIndex >= 0 && oM.aGroupHeaders[iGroupHeaderIndex]) {
            const tHead = oM.aGroupHeaders[iGroupHeaderIndex];
            const tGroup = oM.aGroups[tHead.iGroupIndex];

            //  Generate previous header first
            aHtml.push(`<div class="WebList_GroupHeader Web_Level${tHead.iGroupIndex} ${iItemIndex == 0? "Web_First" : ""}" data-dfgrphead="${iGroupHeaderIndex}" data-dfitem="${iItemIndex}">`);
            if (tGroup.sLabel) {
                aHtml.push(`<span class=WebList_GroupHeader_Name>${tGroup.sLabel}</span>`);
            }
            if (tHead.sItem) {
                aHtml.push(`<span class="WebList_GroupHeader_Item">${tHead.sItem}</span> `);
            }
            if (tHead.sTotal) {
                aHtml.push(`<span class="WebList_GroupHeader_Total">${tHead.sTotal}</span> `);
            } else if (tHead.iItems > 0) {
                aHtml.push(`<span class="WebList_GroupHeader_Items">${tHead.iItems}</span> `);
            }

            if(this.oL.pbGroupsCollapsible){
                if(tHead.bCollapsed){
                    aHtml.push(`<span class="WebList_GroupHeader_ToggleBtn"><i class="WebList_GroupHeader_IconExpand"></i></span>`);
                }else{
                    aHtml.push(`<span class="WebList_GroupHeader_ToggleBtn"><i class="WebList_GroupHeader_IconCollapse"></i></span>`);
                }
            }

            aHtml.push('</div>');


        }
    }

    itemHtml(aHtml, iIndex){
        const oM = this.oM, tItem = oM.aDisplay[iIndex];

        if(!tItem) return;

        switch(tItem.eType){
            case WebListModel.displayTypes.row:
                {
                    const tRow = oM.aData[tItem.iIndex];
                    this.oR.rowHtml(tRow, aHtml, (iIndex % 2==0), oM.aGroups.length, oM.isFirst(tRow), oM.isLast(tRow), iIndex);
                }
                break;
            case WebListModel.displayTypes.header:
                this.groupHeaderHtml(aHtml, tItem.iIndex, iIndex);
                break;
        }
    }

    tableHtml(aHtml) {
        this.oM.aDisplay.forEach((tItem, iIndex) => {
            this.itemHtml(aHtml, iIndex);
        });
    }

    refreshDisplay() {
        const aHtml = [];

        if (this.eRowContainer) {
            this.tableHtml(aHtml);

            this.eRowContainer.innerHTML = aHtml.join("");

            //  Notify other modules
            this.onRowsRendered.fire(this);

            //  Trigger a resize on surrounding controls
            this.oL.sizeChanged(false);
        }
    }

    refreshRow(sRowId, sNewRowId) {
        let oM = this.oM;
        const aHtml = [];

        //  Lookup row details
        const iRow = oM.rowIndexByRowId(sNewRowId);
        const eRow = this.row(sRowId);
        if (iRow >= 0 && eRow) {
            const iIndex = eRow.dataset.dfitem;

            //  Create new row
            this.itemHtml(aHtml, iIndex);
            
            const eNewRow = df.dom.create(aHtml);
            eRow.parentNode.replaceChild(eNewRow, eRow);
        }
    }

    refreshCell(sRowId, oCol) {
        const oM = this.oM;

        const eCell = this.cell(sRowId, oCol._iCol);
        const iRow = oM.rowIndexByRowId(sRowId);
        if (eCell && iRow >= 0) {
            eCell.innerHTML = this.oR.cellHtml(oCol, this.oM.aData[iRow], this.oM.aData[iRow].aCells[oCol._iColIndex]);
        }
    }

    onDataUpdate(oEv) {


        if (oEv.sType === "row") {
            this.refreshRow(oEv.sUpdateRowId, oEv.sNewRowId);
        } if (oEv.sType === "cell") {
            this.refreshCell(oEv.sUpdateRowId, oEv.oCol);
        } else {
            this.refreshDisplay();
        }
    }

    onRowChange(oEv) {

        if (this.eBody) {
            //  First check if group is collapsed, expanding the group will redraw so then we don't have to update the DOM
            if(!this.oL._oGrouping.makeCurrentRowVisible()){
                if (oEv.sPrevRowId) {
                    const ePrevRow = this.row(oEv.sPrevRowId);
                    if (ePrevRow) {
                        df.dom.removeClass(ePrevRow, "WebList_Selected");
                    }
                }
                
                const eRow = this.row(oEv.sGotoRowId);
                if (eRow) {
                    df.dom.addClass(eRow, "WebList_Selected");
                }
            }
        }
    }

    onSettingChange(oEv) {
        const oL = this.oL;

        if (oEv.sType === "redraw") {
            this.refreshDisplay();
        } else if (oEv.sType === "prop") {
            switch (oEv.sProp) {
                case "pbShowSelected":
                    if (this.eBody) {
                        df.dom.toggleClass(this.eBody, "WebList_ShowSelected", oL.pbShowSelected);
                    }
                    break;
            }
        }
    }

    /**
     * Searches the specified element inside this.eRowContainer but makes sure it is not part of a 
     * nested list (inside an expand panel for example).
     * 
     * @param {String} sSelector CSS Query Selector
     * @returns The first element matching the selector that is not wrapped by another WebList_Body element.
     */
    containerElem(sSelector){
        const aElems = this.eRowContainer?.querySelectorAll(sSelector);

        if(aElems){
            for(const eElem of aElems){
                if(eElem.closest('div.WebList_Body') == this.eRowContainer){
                    return eElem;
                }
            }
        }

        return null;
    }

    /* 
    Returns the DOM element for a specific row (based on the rowid). Null if not found (might not be rendered).
    */
    row(sRowId) {
        return this.containerElem('table.WebList_Row[data-dfrowid="' + sRowId + '"]');
    }

    /*
    Returns the DOM element for the specified group header index. Null if not found.
    */
    groupHeader(iGroupHeaderIndex) {
        return this.containerElem('div.WebList_GroupHeader[data-dfgrphead="' + iGroupHeaderIndex + '"]');
    }
    
    /*
    Returns the DOM element for the current row.
    */
    currentRowElem() {
        return this.row(this.oM.sCurrentRowId);
    }

    item(iItemIndex){
        return this.containerElem('[data-dfitem="' + iItemIndex + '"]');
    }

    /*
    Determines the rowid and column index by looking at the DOM structure. Used from event handler functions.
    
    @param  eElem   DOM element inside a cell / row.
    @return Object with details.
    */
    determineCell(eElem) {
        var oRes = {
            iCol: -1,
            sRowId: null,
            iHeaderIndex: -1,
            eSwipeBtn: null,
            bHeaderToggle: false
        };

        
        while (eElem && eElem.parentNode && eElem !== this.eRowContainer && !oRes.sRowId) {
            if (eElem.tagName === "TD" && eElem.hasAttribute("data-dfcol")) {
                oRes.iCol = parseInt(eElem.getAttribute("data-dfcol"), 10);
            } else if (eElem.tagName === "TD" && eElem.hasAttribute("data-dfswbtn")) {
                //  This is a bit of a shortcut but we talk to to the touch handler in person
                oRes.eSwipeBtn = eElem;
            } else if (eElem.tagName === "TABLE" && eElem.hasAttribute("data-dfisrow")) {
                oRes.sRowId = eElem.getAttribute("data-dfrowid");
            } else if(eElem.matches("div.WebList_GroupHeader[data-dfgrphead]")){
                oRes.iHeaderIndex = parseInt(eElem.dataset.dfgrphead, 10);
            } else if(eElem.matches("span.WebList_GroupHeader_ToggleBtn")){
                oRes.bHeaderToggle = true;
            }
            eElem = eElem.parentNode;
        }


        return oRes;
    }


    /* 
    This function handles the click event on the list table. It determines which row and which column is 
    clicked. It will trigger the cellClick on the column object and change row if needed.
    
    @param  oEvent  Event object.
    @private
    */
    onTableClick(oEv) {
        const that = this;

        //  Check enabled state
        if (!this.oL.isEnabled() || this.bCancelClick) {
            return;
        }

        //  Determine which cell is clicked
        const oCDtl = this.determineCell(oEv.getTarget());

        //  Perform operations
        if (oCDtl.eSwipeBtn) {
            //  This is a bit of a shortcut as we have special swipe button logic here
            this.oL._oTouchHandler.swipeBtnClick(oEv, oCDtl.eSwipeBtn);
        } else if (oCDtl.sRowId !== null) {
            //  The default cell click
            if (this.oC.cellClick(oEv, oCDtl.sRowId, oCDtl.iCol)) {
                this._bPreventSubmit = true;
                setTimeout(function () {
                    that.bPreventSubmit = false;
                }, 250);
                oEv.stop();
            }
        } else if(oCDtl.iHeaderIndex >= 0 && oCDtl.bHeaderToggle){
            this.oL._oGrouping.toggleGroupHeader(oCDtl.iHeaderIndex);
        }
    }

    /*
    Handles the double click event on the list table. It will notify the controller of this event and 
    directly fires the submit if needed.
    
    @param  oEv     DOM Event object.
    */
    onTableDblClick(oEv) {

        //  Check enabled state
        if (!this.oL.isEnabled()) {
            return;
        }

        const oCDtl = this.determineCell(oEv.getTarget());

        if (oCDtl.sRowId !== null) {
            //  The default cell click
            if (this.oC.cellDblClick(oEv, oCDtl.sRowId, oCDtl.iCol)) {
                oEv.stop();
                return;
            }
        }

        // Fire submit
        if (!this.bPreventSubmit) {
            this.oL.fireSubmit();
        }
    }


    /* 
    Handles the cellclick event from the controller to visualize the click.
    */
    onCellClick(oEv) {
        const that = this;

        this.bHitDone = false;
        this.eHitElem = this.row(oEv.sRowId);
        df.dom.addClass(this.eHitElem, df.CssHit);
        this.tHitTimer = setTimeout(function () {
            if (that.bHitDone) {
                df.dom.removeClass(that.eHitElem, df.CssHit);
            }
            that.tHitTimer = null;
        }, df.hitTimeout);
    }


    onAfterCellClick(oEv) {
        if (!this.tHitTimer) {
            df.dom.removeClass(this.eHitElem, df.CssHit);
        }
        this.bHitDone = true;
    }

    /*
    Empty stub used by subclasses. A non scrollable view ignores heights that are set but grows according to its content.
    
    @param  iHeight     Height in pixels.
    */
    setHeight(iHeight) {

    }

    /* 
    Finds the cell element for the specified row and column.
    
    @param  sRowId    RowId for which we want the cell element.
    @param  iCol    Column number for the cell.
    @return DOM element (TD) for the column (null if not found / available).
    */
    cell(sRowId, iCol) {
        return (this.eRowContainer && df.dom.query(this.eRowContainer, "table[data-dfrowid='" + sRowId + "'] td[data-dfcol='" + iCol + "']")) || null;
    }

    /* 
    Returns the cell for provided column in the current row.
    
    @param  oCol    Column object.
    @return DOM element for the current cell (null if not available).
    */
    colCell(oCol) {
        return this.cell(this.oM.sCurrentRowId, oCol._iCol);
    }

    colCellByIndex(iCol) {
        return this.cell(this.oM.sCurrentRowId, iCol);
    }

    /* 
    Used by the WebListHeaderView to align headers with scrollbar.
    */
    scrollbarWidth() {
        return 0;
    }

    /* 
    Used by WebListController to determine page size for page up and page down.
    */
    getViewSize() {
        return 10;
    }

    fullwidth() {
        return (this.eBody && this.eBody.clientWidth) || 0;
    }

    /*
    Empty stub used by subclasses.
    */
    setExtraRowHeight(sRowId, iExtra) {

    }

    /*
    Empty stub used by subclasses.
    */
    getExtraRowHeight(sRowId) {
        return 0;
    }

    /*
    Empty stub used by subclasses.
    */
    scrollToRow(sRowID) {

    }

}
