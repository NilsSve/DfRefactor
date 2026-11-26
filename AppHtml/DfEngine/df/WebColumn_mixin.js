import { WebGrid } from './WebGrid.js';
import { WebList } from './WebList.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumn_mixin
Extends:
    Object
    
This class is used as a mixin for all the different column types. It has the basic column 
functionality and defined the interface to which the List & Grid will be talking. It has basic logic 
for generating the cell content and makes sure the grid redraws when properties are changed. 
    
Revision:
    2011/12/01  (HW, DAW) 
        Initial version.
    2013/08/15  (HW, DAW)
        Refactored into the new mixin system to reduce overhead as more column types will be added.
*/
export const WebColumn_mixin = superclass => class extends superclass {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Assertions
        if (!(oParent && oParent instanceof WebList)) {
            throw new df.Error(999, "WebColumn object '{{0}}' should be placed inside a WebList object. Consider wrapping your column with a list or grid object.", this, [this.getLongName()]);
        }

        //  Properties
        this.prop(df.tBool, "pbGroupable", true);
        this.prop(df.tBool, "pbSortable", false);
        this.prop(df.tBool, "pbValueAsTooltip", true);
        this.prop(df.tBool, "pbAllowHtml", false);
        this.prop(df.tInt, "piWidth", 0);
        this.prop(df.tString, "psCaption", "");

        this.prop(df.tBool, "pbNewLine", false);
        this.prop(df.tInt, "piListColSpan", 1);
        this.prop(df.tInt, "piListRowSpan", 1);

        this.prop(df.tBool, "pbFixedWidth", false);
        this.prop(df.tBool, "pbResizable", true);

        this.prop(df.tBool, "pbHidden", false);
        this.prop(df.tBool, "pbShowCaption", true);
        this.prop(df.tInt, "piPosition", -1);
        this.prop(df.tBool, "pbHideable", true);

        this.prop(df.tInt, "peFooterDataType", df.ciTypeText);
        this.prop(df.tInt, "peFooterAlign", -1);
        this.prop(df.tInt, "piFooterPrecision", 0);
        this.prop(df.tString, "psFooterMask", "");
        this.prop(df.tString, "psFooterValue", "");

        this.addSync("pbHidden");
        this.addSync("piPosition");

        this.prop(df.tBool, "pbEditable", true);

        //  Events
        this.event("OnHeaderClick", df.cCallModeDefault);

        //  @privates
        this._sCellClass = "WebCol";
        this._bCellEdit = true;
        this._iColIndex = 0;    //  Index in data row
        this._iCol = 0;     //  Index in _aColumns of list

        this._bIsColumn = true;
        //  Configure super class
    }

    /*
    Setting psFooterValue requires the footer to be redrawn.
    */
    set_psFooterValue(sVal) {
        if (this.psFooterValue !== sVal) {
            this.psFooterValue = sVal;
            this._oParent._oFooter.updateFooter();
        }
    }

    /*
    Setting psFooterMask requires the footer to be redrawn.
    */
    set_psFooterMask(sVal) {
        if (this.psFooterMask !== sVal) {
            this.psFooterMask = sVal;
            this._oParent._oFooter.updateFooter();
        }
    }

    /*
    Setting piFooterPrecision requires the footer to be redrawn.
    */
    set_piFooterPrecision(iVal) {
        if (this.piFooterPrecision !== iVal) {
            this.piFooterPrecision = iVal;
            this._oParent._oFooter.updateFooter();
        }
    }

    /*
    Setting peFooterAlign requires the footer to be redrawn.
    */
    set_peFooterAlign(eVal) {
        if (this.peFooterAlign !== eVal) {
            this.peFooterAlign = eVal;
            this._oParent._oFooter.updateFooter();
        }
    }

    /*
    Setting peFooterDataType requires the footer to be redrawn.
    */
    set_peFooterDataType(eVal) {
        if (this.peFooterDataType !== eVal) {
            this.peFooterDataType = eVal;
            this._oParent._oFooter.updateFooter();
        }
    }

    /*
    We augment the set_psValue method and pass on the new value to the grid so that it can update the 
    current row its value. The default setter of psValue is also called so when this is the currently 
    edited cell the value is also properly reflected.
    
    @param  sVal    The new value in the server format.
    */
    set_psValue(sVal) {
        super.set_psValue(sVal);

        if (this._oParent instanceof WebGrid) {
            this._oParent.updateCurrentCell(this, sVal);
        }
    }

    /*
    Setting pbRender means that the list should redraw itself completely. 
    
    @param  bVal    The new value of pbRender.
    */
    set_pbRender(bVal, bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;
        const bCS = (this.pbRender !== bVal);

        super.set_pbRender(bVal);

        if (bCS) {
            this.pbRender = bVal;

            this._oParent.rebuildColumnMapper(bRedraw);
        }
    }

    /*
    Setting pbShowCaption means that the list should redraw itself completely. 
    
    @param  bVal    The new value of pbShowCaption.
    */
    set_pbShowCaption(bVal) {
        if (this.pbShowCaption !== bVal) {
            this.pbShowCaption = bVal;

            this._oParent._oHeader.updateHeader();
        }
    }

    /*
    Setting pbHidden means that the list should redraw itself completely. 
    
    @param  bVal    The new value of pbHidden.
    */
    set_pbHidden(bVal, bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        if (this.pbHidden !== bVal) {
            this.pbHidden = bVal;

            this._oParent.rebuildColumnMapper(bRedraw);
        }
    }

    /*
    Setting piPosition means that the list should redraw itself completely. 
    
    @param  bVal    The new value of piPosition.
    */
    set_piPosition(iVal, bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        if (this.piPosition !== iVal) {
            this.piPosition = iVal;

            this._oParent.rebuildColumnMapper(bRedraw);
        }
    }

    /*
    Setting pbHideable means that the list's menu should redraw itself completely. 
    
    @param  bVal    The new value of pbHideable.
    */
    set_pbHideable(bVal) {
        if (this.pbHideable !== bVal) {
            this.pbHideable = bVal;

            this._oParent.triggerRebuildHeaderMenu();
        }
    }

    /*
    Setting pbEditable requires different class properties and should thus be redrawn.
    
    @param bVal Indicates whether the column is editable.
    */
    set_pbEditable(bVal) {
        if (this.pbEditable !== bVal) {
            this.pbEditable = bVal;

            this._oParent.redraw();
        }
    }

    /*
    Setting pbAllowHtml means that the list should redraw itself completely. 
    
    @param  bVal    The new value of pbAllowHtml.
    */
    set_pbAllowHtml(bVal) {
        if (this.pbAllowHtml !== bVal) {
            this.pbAllowHtml = bVal;

            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the changed width so it can redraw itself.
    
    @param  iVal    The new value.
    @private
    */
    set_piWidth(iVal) {
        if (this.piWidth !== iVal) {
            this.piWidth = iVal;

            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the change so that it can redraw itself.
    
    @param  bVal    The new value.
    @private
    */
    set_pbFixedWidth(bVal) {
        if (this.pbFixedWidth !== bVal) {
            this.pbFixedWidth = bVal;
            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the change so that it can redraw itself.
    
    @param  bVal    The new value.
    @private
    */
    set_pbNewLine(bVal) {
        if (this.pbNewLine !== bVal) {
            this.pbNewLine = bVal;
            this._oParent.redraw();
            this._oParent.sizeChanged(true);
        }
    }

    /*
    Setter for psCaption that notifies the list of the new caption and makes it redraw the header.
    
    @param  sVal    The new value.
    */
    set_psCaption(sVal) {
        if (this.psCaption !== sVal) {
            this.psCaption = sVal;
            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid when the CSS Classname changes so it can redraw itself.
    
    @param  sVal    The new value.
    @private
    */
    set_psCSSClass(sVal) {
        const bCS = (this.psCSSClass !== sVal);

        super.set_psCSSClass(sVal);

        if (bCS) {
            this.psCSSClass = sVal;

            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the changed width so it can redraw itself.
    
    @param  iVal    The new value.
    @private
    */
    set_piListColSpan(iVal) {
        if (this.piListColSpan !== iVal) {
            this.piListColSpan = iVal;

            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the changed width so it can redraw itself.
    
    @param  iVal    The new value.
    @private
    */
    set_piListRowSpan(iVal) {
        if (this.piListRowSpan !== iVal) {
            this.piListRowSpan = iVal;

            this._oParent.redraw();
        }
    }

    /* 
    Notifies the list / grid of the change.
    
    @param  bVal    The new value.
    @private
    */
    set_pbVisible(bVal) {
        if (this.set_pbVisible !== bVal) {
            super.set_pbVisible(bVal);

            this.pbVisible = bVal;

            this._oParent.redraw();
        }
    }

    /*
    Augments the applyEnabled and triggers a redraw of the list as the CSS classes of all cells should 
    be updated.
    
    @param  bVal    The new value of pbRender.
    */
    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        this._oParent.redraw();
    }

    /*
    We augment the onKey event handler and call the onKey handler of the grid first so that the grid 
    keys overrule the default form keys (especially ctrl - end & ctrl - home which go to the last & 
    first row instead of doing a find). The grids onKey handler returns true if nothing happened and 
    false if something happened (this confirms with the default event system).
    
    @param  oEvent  The event object.
    */
    onKey(oEvent) {
        if (this._oParent.onKeyDown(oEvent)) {
            super.onKey(oEvent);
        } else {
            oEvent.e.cancelBubble = true;
        }
    }

    /*
    @20.1
    This function is called when the header of the column is constructed.
    It could later be augmented for custom headers.
    */
    headerCSS() {
        return null;
    }

    /*
    @20.1
    This function is called when the header of the column is constructed.
    It could later be augmented for custom headers.
    */
    headerHtml() {
        return (this.psCaption && this.pbShowCaption ? this.psCaption : '&nbsp;');
    }

    /*
    This method determines the HTML that is displayed within a cell. It gets the value as a parameter 
    and uses the column context properties (like masks) to generate the value to display. For default 
    grid columns it simply displays the properly masked value.
    
    @param  tCell   Data object reprecenting the cell data.
    @return The HTML representing the display value.
    */
    cellHtml(sRowId, tCell) {
        let sVal;

        const tVal = df.sys.data.serverToType(tCell.sValue, this.peDataType);
        sVal = this.typeToDisplay(tVal);

        if (!this.pbAllowHtml) {
            sVal = df.dom.encodeHtml(sVal);
        }

        return (sVal !== '' ? sVal : '&nbsp;');
    }

    /* 
    This method is called by the list to format the tooltip value when pbValueAsTooltip is true and no 
    custom tooltip is defined for a cell. It makes sure that the value is shown in the proper format 
    (dates) with masks applied if need.
    
    @param  tCell   Data object reprecenting the cell data.
    @return Properly formatted cell value.
    */
    tooltipValue(tCell) {
        const tVal = df.sys.data.serverToType(tCell.sValue, this.peDataType);
        return this.typeToDisplay(tVal);
    }

    /* 
    Triggered by the List / Grid when a cell of this column is clicked. It doesn't have to be the 
    selected cell yet.
    
    @param  oEvent  Event object.
    @param  sRowId  RowId of the clicked row.
    @param  sVal    Value of the clicked cell.
    
    @param  True if this column handled the click and the list should ignore it (stops the ChangeCurrentRow).
    */
    cellClickBefore(oEvent, sRowId, sVal) {
        return false;
    }

    /* 
    Triggered by the List / Grid when a cell of this column is clicked. This is triggered after the row 
    change but there is no guarantee that the row actually changed.
    
    @param  oEvent  Event object.
    @param  sRowId  RowId of the clicked row.
    @param  sVal    Value of the clicked cell.
    
    @param  True if the column handled the click and the list should not trigger OnRowClick any more.
    */
    cellClickAfter(oEvent, sRowId, sVal) {
        return false;
    }

    /* 
    Triggered by the grid when a cell of this column switches to edit mode. This might be because the 
    cell is now selected but also because it was scrolled of the screen and is now rendered again.
    */
    cellEdit() {

    }

    /* 
    Triggered by the grid when a cell switches from edit mode. This might be because a different cell 
    will be edited but also because a row is scrolled off the screen. 
    */
    cellUnEdit() {

    }

    /* 
    Determines which element should be used to position a tooltip next to. We usually want to get the 
    tooltip at the cell of this column in the selected row.
    
    @return Element to position tooltip next to.
    */
    getTooltipElem() {
        let eElem = this._oParent.getColCell(this);

        if (!eElem) {
            eElem = this._oParent.getColHead(this);
        }

        return eElem;
    }

    /* 
    Determine which element should be used to position error messages next to. This is the same as the 
    tooltip element.
    
    @return Element to position error next to.
    */
    getErrorElem() {
        return this.getTooltipElem();
    }

    selectAndFocus() {
        if (this._oParent instanceof WebGrid) {
            this._oParent.selectCol(this._iCol);
        }

        this.focus();
    }


}