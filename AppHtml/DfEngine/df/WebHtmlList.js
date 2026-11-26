import { WebList } from './WebList.js';
import { WebListView } from './WebListView.js';
import { WebListController } from './WebListController.js';
import { WebListRowModel } from './WebListRowModel.js';
import { WebListModel } from './WebListModel.js';
import { df } from '../df.js';

/*
Class:
    df.WebHtmlList
Extends:
    df.WebList

This class is a customizable version of the WebList that can be customized using HTML templates. 
Note that it does not support headers, sorting and that sort of stuff. It is just meant for 
displaying lists of data in customizable format while still enjoying the ease of automatic data 
binding on the server.

To do this we had to subclass the WebListRowModel, the WebListView and the WebList itself.
    
Revision:
    2020/02/27  (HW, DAW) 
        Initial version.
*/


/*
Subclass WebListRowModel to augment HTML generation for the row.
*/
export class WebHtmlListRowModel extends WebListRowModel {
    constructor(oList, oModel) {
        super(oList, oModel);

        this.rRegEx = /{{([a-zA-Z0-9_\-]*)}}/g;
    }

    /*
    Called to generate the HTML for a single row. Uses the regex to search for markers and replaces 
    them with column values calling cellHtml on the columns.
    
    @param  tRow    Struct with row data.
    @param  aHtml   Array string builder for output.
    @param  bZebra  True of odd rows, false for even.
    */
    rowHtml(tRow, aHtml, bZebra) {
        const oL = this.oL, that = this;

        aHtml.push(oL._sHtmlTemplate.replace(this.rRegEx, function (sMatch, sP1) {
            if (sP1 == "dfrowid") {
                return tRow.sRowId;
            }
            if (sP1 == "isDraggable") {
                return (oL.pbDragDropEnabled && (oL.isSupportedDragAction(df.dragActions.WebList.ciDragRow)) ? 'true' : 'false');
            }
            const oCol = oL._oColMap[sP1];
            if (oCol) {
                return that.cellHtml(oCol, tRow, tRow.aCells[oCol._iColIndex]);
            }
            return sMatch;
        }));
    }
}

/*
Subclass WebListView to add psHtmlBefore, psHtmlAfter and OnElemClick logic.
*/
export class WebHtmlListView extends WebListView {

    /*
    Called to generate the HTML for the table. Augmented to isnert psHtmlBefore and psHtmlAfter.
    
    @param  aHtml   Array used as string builder.
    */
    tableHtml(aHtml) {
        aHtml.push(this.oL.psHtmlBefore);
        super.tableHtml(aHtml);
        aHtml.push(this.oL.psHtmlAfter);
    }

    /* 
    This function handles the click event on the list table. It determines which row and which column is 
    clicked. It will trigger the cellClick on the column object and change row if needed.
    
    @param  oEvent  Event object.
    @private
    */
    onTableClick(oEv) {
        const iCol = -1, that = this;
        let eElem = oEv.getTarget(), sRowId = null, sElemClick = null, bRowClick = true;

        //  Check enabled state
        if (!this.oL.isEnabled() || this.bCancelClick) {
            return;
        }

        //  We need to determine if and which row was clicked so we start at the clicked element and move up untill we find the row
        while (eElem.parentNode && eElem !== this.eBody && !sRowId) {
            if (eElem.hasAttribute("data-ServerOnElemClick")) {
                sElemClick = eElem.getAttribute("data-ServerOnElemClick");
            }

            //  Check if we found the tr element and if it is part of the table
            if (eElem.hasAttribute("data-dfisrow")) {
                sRowId = eElem.getAttribute("data-dfrowid");
            }
            eElem = eElem.parentNode;
        }

        //  Fire element click
        if (sElemClick) {
            bRowClick = this.oL.fire("OnElemClick", [sRowId || "", sElemClick]);
        }

        //  Trigger regular cell click
        if (bRowClick && sRowId) {
            //  Trigger cell click
            if (this.oC.cellClick(oEv, sRowId, iCol)) {
                this._bPreventSubmit = true;
                setTimeout(function () {
                    that.bPreventSubmit = false;
                }, 250);
                oEv.stop();
            }
        }
    }

    /*
    No partial update supported..
    */
    refreshCell(sRowId, oCol) {
        this.refreshDisplay();
    }

    /*
    No partial update supported..
    */
    refreshRow(sRowId, sNewRowId) {
        this.refreshDisplay();
    }

}

/*
The actual WebHtmlList subclass of WebList using the changed MVC components above.
*/
export class WebHtmlList extends WebList {
    constructor(oParent, sName) {
        super(oParent, sName);

        this.prop(df.tString, "psHtmlBefore", "");
        this.prop(df.tString, "psHtmlTemplate", "");
        this.prop(df.tString, "psHtmlAfter", "");
        this.prop(df.tInt, "peDropPosDetectionMode", 0);

        this._oColMap = {};
        this._sHtmlTemplate; // This is used as an internal reference to build the RowHtml

        this.event("OnElemClick", df.cCallModeWait);

        this._sControlClass = "WebHtmlList";
    }

    /* 
    Initialize the HTML template.
    */
    create() {
        this._sHtmlTemplate = this.initTemplate(this.psHtmlTemplate);

        super.create();
    }

    /*
    Override modules.
    */
    createTouchHandler() {
        return null;
    }

    createPlaceHolder() {
        return null;
    }

    createHeaderView() {
        return null;
    }

    createRowModel() {
        return new WebHtmlListRowModel(this, this._oModel);
    }

    createView() {
        return new WebHtmlListView(this, this._oModel, this._oController);
    }

    createController() {
        return new WebListController(this, this._oModel);
    }

    createModel() {
        return new WebListModel(this);
    }

    /*
    Override to do nothing.
    */
    focusHtml(aHtml){
    }

    /*
    Augmented to intercept the column objects and build a column map used to find columns by their name.
    
    @param  oChild  New child object.
    */
    addChild(oChild) {
        super.addChild(oChild);

        if (oChild._bIsColumn) {
            this._oColMap[oChild._sName] = oChild;
        }
    }

    /*
    Initializes a template by injecting data-dfisrow and data-df-rowid attributes into the outermost element.
    
    @param  sTemplate   The HTML template for a row.
    @return Altered template with necessary attributes.
    @private
    */
    initTemplate(sTemplate) {
        return sTemplate.replace(/<\/?\w+/i, (sMatch) => {
            return sMatch + ' data-dfisrow="true" data-dfrowid="{{dfrowid}}" draggable="{{isDraggable}}"';
        });
    }

    /*
    Client action to update the template without making psHtmlTemplate a synchronized property.
    
    @client-action
    */
    updateTemplate(sNewTemplate) {
        this.set_psHtmlTemplate(sNewTemplate);
    }

    /*
    Setters for web properties.
    */
    set_psHtmlTemplate(sVal) {
        this._sHtmlTemplate = this.initTemplate(sVal);
        this.redraw();
    }

    set_psHtmlBefore(sVal) {
        this.psHtmlBefore = sVal;
        this.redraw();
    }

    set_psHtmlAfter(sVal) {
        this.psHtmlAfter = sVal;
        this.redraw();
    }

    determineDropPosition(oEv, eElem) {
        if (this.peDropPosDetectionMode == 0) {
            return this.determineDropPosVertical(oEv, eElem);
        } else {
            return this.determineDropPosHorizontal(oEv, eElem);
        }
    }

    determineDropPosVertical(oEv, eElem) {
        const oRect = df.sys.gui.getBoundRect(eElem);
        // We want to check if we are more to the top or to the bottom of the hovered row
        const iMid = (oRect.bottom - (oRect.height / 2));
        if (oEv.e.clientY >= iMid) {
            return df.dropPositions.ciDropAfter;
        } else {
            return df.dropPositions.ciDropBefore;
        }
    }

    determineDropPosHorizontal(oEv, eElem) {
        const oRect = df.sys.gui.getBoundRect(eElem);
        // We want to check if we are more to the top or to the bottom of the hovered row
        const iMid = (oRect.right - (oRect.width / 2));
        if (oEv.e.clientX >= iMid) {
            return df.dropPositions.ciDropAfter;
        } else {
            return df.dropPositions.ciDropBefore;
        }
    }

    interactWithDropElem(dropZone, eElem) {
        if (dropZone._eDropAction == df.dropActions.WebControl.ciDropOnControl) {
            // console.log('droponcontrol');
            dropZone.highlightElement();
        } else {
            // console.log('droplistrow');
            let eTempElem = df.dom.create(this._sHtmlTemplate.replace(this._oRowRenderer.rRegEx, function (sMatch, sP1) {
                if (sP1 == "dfrowid") {
                    return 'empty_placeholder';
                }
                if (sP1 == "isDraggable") {
                    return 'false';
                }
                return "";
            }));

            df.dom.addClass(eTempElem, 'DfDragDrop_PlaceHolder');
            eTempElem.appendChild(df.dom.create('<div class="DfDragDrop_PlaceHolder_Overlay"></div>'));

            dropZone.insertElement(eTempElem, eElem);
        }
    }

}