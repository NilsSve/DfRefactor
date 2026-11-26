import { WebListController } from './WebListController.js';
import { df } from '../df.js';

/*
Class:
    df.WebMuliSelectListController
Extends:
    df.WebListController

This is an extention on the WebList to allow for multi-selection of rows.
    
Revision:
    2022/07/06  (BN, DAW) 
        Initial version.
*/
export class WebMultiSelectListController extends WebListController{

    constructor(oList, oModel) {
        super(oList, oModel);

        this._bAllChecked = false;
        this._iBeginRange = -1;
    }


    /*
    This method handles the keypress event and initiates the actions bound to it. The 
    df.settings.listKeys define the exact key code's / combinations for the different actions.
    
    @param  oJsEv  The JSevent object, oDOMEvent contains the actual key event.
    @return False if we did handle the event and performed an action, true if we didn't do anything.
    */
    keyDown(oJsEv) {
        const oEv = oJsEv.oDOMEvent;
        let oL = this.oL, oM = this.oM;

        if (!oL._bHasFocus) {
            return;
        }

        if (!oL.pbKeyboardSelection) {
            oEv.stop();
            return;
        }

        if (oEv.matchKey(df.settings.listKeys.select)) {
            this.toggleCurrentRow();

            oEv.stop();
            return false;
        } else if (oEv.matchKey(df.settings.listKeys.selectAll)) {
            this.toggleSelectAll();

            oEv.stop();
            return false;
        } else if (oEv.matchKey(df.settings.listKeys.deSelectAll)) {
            this.clearSelection();

            oEv.stop();
            return false;
        }

        if (oEv.matchKey(df.settings.listKeys.scrollUp) ||
            oEv.matchKey(df.settings.listKeys.scrollDown) ||
            oEv.matchKey(df.settings.listKeys.scrollPageUp) ||
            oEv.matchKey(df.settings.listKeys.scrollPageDown) ||
            oEv.matchKey(df.settings.listKeys.scrollTop) ||
            oEv.matchKey(df.settings.listKeys.scrollBottom)) {
            // Make row change first
            let bReturn = super.keyDown(oJsEv);

            if (oL.pbSelectionByRow) {
                this.clearSelection();
                this.setCurrentRow(true);
            }
            this._iBeginRange = -1;

            return bReturn;
        } else if (oEv.matchKey(df.settings.listKeys.scrollRangeUp)) {
            if (this._iBeginRange === -1)
                this._iBeginRange = oM.iCurrentRow;

            this.clearSelection();
            this.moveUpRow();

            for (let i = Math.min(oM.iCurrentRow, this._iBeginRange); i <= Math.max(oM.iCurrentRow, this._iBeginRange); i++) {
                let sSubRowId = oM.rowIdByRowIndex(i);
                if (sSubRowId) {
                    this.setSelection(sSubRowId, true); //!< force selection.
                }
            }

            oEv.stop();
            return false;
        } else if (oEv.matchKey(df.settings.listKeys.scrollRangeDown)) {
            if (this._iBeginRange === -1)
                this._iBeginRange = oM.iCurrentRow;

            this.clearSelection();
            this.moveDownRow();

            for (let i = Math.min(oM.iCurrentRow, this._iBeginRange); i <= Math.max(oM.iCurrentRow, this._iBeginRange); i++) {
                let sSubRowId = oM.rowIdByRowIndex(i);
                if (sSubRowId) {
                    this.setSelection(sSubRowId, true); //!< force selection.
                }
            }

            oEv.stop();
            return false;
        }

        return super.keyDown(oJsEv)
    }

    /* 
    Handles the click on a cell inside the list. Triggers click events on the column object and changes 
    the current row.
 
    @param  oEv     DOM Event object.
    @param  sRowId  RowId of the clicked row.
    @param  iCol    Column that is clicked.  
    @param  bNoRowChange    Whether to not change the row.  
    */
    cellClick(oEv, sRowId, iCol, bNoRowChange) {
        let oL = this.oL, oM = this.oM;
        let iRow = oM.rowIndexByRowId(sRowId);
        let bNoChangeRow = bNoRowChange ? true : false;

        if (sRowId !== "empty") {
            if (oL.pbKeyboardSelection && oEv.e.ctrlKey) {
                this.toggleSelectionOfRow(sRowId);
            } else if (oL.pbKeyboardSelection && oEv.e.shiftKey) {
                this.clearSelection();

                let i = this._iBeginRange = this._iBeginRange !== -1 ? this._iBeginRange : oM.iCurrentRow;
                let downWards = iRow >= i;
                let iDiff = downWards ? 1 : -1;

                this.selectRow("row", iRow);

                // We go one further as the while loop will stop after the last selected.
                iRow += iDiff;

                while (i !== iRow) {
                    let sSubRowId = oM.rowIdByRowIndex(i);
                    if (sSubRowId) {
                        this.setSelection(sSubRowId, true); //!< force selection.
                    }
                    i += iDiff;
                }

                bNoChangeRow = true;
            } else if (oL.pbSelectionByRow) {
                this.clearSelection();
                if (iRow >= 0) {
                    this.setSelection(sRowId, true); //!< force selection.
                }
            } else if (iCol >= 0 && oL._aColumns[iCol]._bIsMultiSelectCapable) {
                this.setSelection(sRowId, !oL.isRowIdSelected(sRowId));
            }
        }

        let bReturn = super.cellClick(oEv, sRowId, iCol, bNoChangeRow);

        if (!bNoChangeRow) {
            this._iBeginRange = -1;
        }

        oEv.stop();

        return bReturn;
    }

    /* 
    Handles the click on a column header. Triggers the OnHeaderClick event and changes the sorting if 
    needed.
    
    @param  oEv     DOM event object.
    @param  iCol    Column index.
    */
    headClick(oEv, iCol) {
        let oL = this.oL, oCol = oL._aColumns[iCol];

        if (oCol && oCol._bIsMultiSelectCapable) {
            let eTarget = oEv.getTarget();

            if (eTarget.classList.contains('WebCB_Fake')) {
                this.toggleSelectAll();

                oEv.stop();
                return false;
            }
        }

        return super.headClick(oEv, iCol);;
    }

    toggleSelectAll() {
        if (!this._bAllChecked) {
            this.selectAll();
        } else {
            this.clearSelection();
        }

        this._iBeginRange = -1;
    }

    setAllSelectedCheckboxState(bAllSelected, bRedraw = true) {
        let oH = this.oL._oHeader;

        this._bAllChecked = bAllSelected;

        if (bRedraw) oH.updateHeader();
    }

    areAllRowsSelected() {
        return this._bAllChecked;
    }

    toggleCurrentRow() {
        const oM = this.oM;

        if (oM.sCurrentRowId) {
            if (oM.sCurrentRowId.length > 0) {
                this.toggleSelectionOfRow(oM.sCurrentRowId);
            }
        }
    }

    setCurrentRow(bSelected) {
        const oM = this.oM;

        if (oM.sCurrentRowId) {
            if (oM.sCurrentRowId.length > 0) {
                this.setSelection(oM.sCurrentRowId, bSelected);
            }
        }
    }

    toggleSelectionOfRow(sRowId, optNoThrowEvents) {
        const oL = this.oL, oM = this.oM;

        let iIndex = oL._paSelectedRowIds.findIndex(_sRowId => _sRowId === sRowId);
        if (iIndex >= 0) {
            oL._paSelectedRowIds.splice(iIndex, 1);
            if (!optNoThrowEvents)
                this.fireSelectionEvent("OnDeSelectRow", oM.rowByRowId(sRowId));
            oL._oBody.refreshRow(sRowId, sRowId);
        } else {
            oL._paSelectedRowIds.push(sRowId);
            if (!optNoThrowEvents)
                this.fireSelectionEvent("OnSelectRow", oM.rowByRowId(sRowId));
            oL._oBody.refreshRow(sRowId, sRowId);
        }

        this.setAllSelectedCheckboxState(false);
    }

    isCurrentRowSelected() {
        const oL = this.oL, oM = this.oM;
        if (!oM.sCurrentRowId || oM.sCurrentRowId.length <= 0)
            return false;

        return oL._paSelectedRowIds.findIndex(_sRowId => _sRowId === oM.sCurrentRowId) >= 0;
    }

    setSelection(sRowId, bValue, optNoThrowEvents) {
        const oL = this.oL, oM = this.oM;

        let iIndex = oL._paSelectedRowIds.findIndex(_sRowId => _sRowId === sRowId);
        if (bValue && iIndex == -1) {
            oL._paSelectedRowIds.push(sRowId);
            if (!optNoThrowEvents)
                this.fireSelectionEvent("OnSelectRow", oM.rowByRowId(sRowId));
            oL._oBody.refreshRow(sRowId, sRowId);
        } else if (!bValue && iIndex >= 0) {
            oL._paSelectedRowIds.splice(iIndex, 1);
            if (!optNoThrowEvents)
                this.fireSelectionEvent("OnDeSelectRow", oM.rowByRowId(sRowId));
            oL._oBody.refreshRow(sRowId, sRowId);
        }

        this.setAllSelectedCheckboxState(false);
    }

    selectAll() {
        let oL = this.oL, oM = this.oM;

        oL._paSelectedRowIds = [];

        for (let i = 0; i < oM.aData.length; i++) {
            oL._paSelectedRowIds.push(oM.aData[i].sRowId)
            oL._oBody.refreshRow(oM.aData[i].sRowId, oM.aData[i].sRowId);
        }

        this.setAllSelectedCheckboxState(true);
        this.fireSelectionEvent("OnSelectAllRows");
    }

    clearSelection() {
        let oL = this.oL, aCache = oL._paSelectedRowIds.slice();

        oL._paSelectedRowIds = [];

        for (let i = 0; i < aCache.length; i++) {
            oL._oBody.refreshRow(aCache[i], aCache[i]);
        }

        this.setAllSelectedCheckboxState(false);
        this.fireSelectionEvent("OnDeSelectAllRows");
    }

    fireSelectionEvent(sEvent, tNullableRow) {
        let oL = this.oL;

        const eSelectionEvents = {
            C_WEBLIST_MULTI_SELECT_NULL: 0,
            C_WEBLIST_MULTI_SELECT_SINGLE: 1,
            C_WEBLIST_MULTI_DESELECT_SINGLE: 2,
            C_WEBLIST_MULTI_SELECT_ALL: 3,
            C_WEBLIST_MULTI_DESELECT_ALL: 4
        }

        let eEventType = eSelectionEvents.C_WEBLIST_MULTI_SELECT_NULL;
        switch (sEvent) {
            case "OnSelectRow":
                eEventType = eSelectionEvents.C_WEBLIST_MULTI_SELECT_SINGLE;
                if (tNullableRow === undefined || tNullableRow === null) return;
                break;
            case "OnDeSelectRow":
                eEventType = eSelectionEvents.C_WEBLIST_MULTI_DESELECT_SINGLE;
                if (tNullableRow === undefined || tNullableRow === null) return;
                break;
            case "OnSelectAllRows":
                eEventType = eSelectionEvents.C_WEBLIST_MULTI_SELECT_ALL;
                break;
            case "OnDeSelectAllRows":
                eEventType = eSelectionEvents.C_WEBLIST_MULTI_DESELECT_ALL;
                break;
            default:
                throw new df.Error(999, "Invalid selection Event");
        }

        oL.addSync("paSelectedRowIds");

        oL.fireEx({
            sEvent: sEvent,
            aParams: [eEventType],
            tActionData: tNullableRow,
            sAltServerName: "privateOnSelectEvent"
        });
    }
}