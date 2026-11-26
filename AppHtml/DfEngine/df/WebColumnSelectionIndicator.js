import { WebColumnCheckbox } from './WebColumnCheckbox.js';
import { WebGrid } from './WebGrid.js';
import { WebMuliSelectList } from './WebMultiSelectList.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnSelectionIndicator
Extends:
    df.WebColumnCheckbox

This is an extention on the WebList to allow for multi-selection of rows.
    
Revision:
    2022/07/06  (BN, DAW) 
        Initial version.
*/

export class WebColumnSelectionIndicator extends WebColumnCheckbox {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbSelectAllCheckbox", false);

        //  Configure super class
        this._sCellClass = "WebColumnSelectionIndicator WebColCheckbox";
        this._sControlClass = "WebColumnSelectionIndicator WebCheckbox WebCheckboxColumn";

        this._bIsMultiSelectCapable = true;
        this._bAllCheckedCheckbox = false;
    }

    setAllSelectedCheckbox(bValue) {
        if (bValue !== this._bAllCheckedCheckbox) {
            this._bAllCheckedCheckbox = bValue;

            this.updateHeader();
        }
    }

    create() {
        if (!(this._oParent instanceof WebMuliSelectList)) {
            throw new df.Error(999, "The parent of the a cWebColumnSelectionIndicator should be a cWebMultiSelectList.");
        }
        return super.create();
    }

    /*
    @20.1
    This function is called when the header of the column is constructed.
    It could later be augmented for custom headers.
    */
    headerCSS() {
        return this.pbSelectAllCheckbox ? "WebCheckbox WebCheckboxColumn" : null;
    }

    /*
    @20.1
    This function is called when the header of the column is constructed.
    It could later be augmented for custom headers.
    */
    headerHtml() {
        if (this.pbSelectAllCheckbox) {
            return '<input class="WebMultiSelectList_SelectAllBox" type="checkbox"' + (this._oParent._oController.areAllRowsSelected() ? 'checked="checked"' : '') + ' tabindex="-1"><span class="WebMultiSelectList_SelectAllBox WebCB_Fake"></span>';
        } else {
            return super.headerHtml();
        }
    }

    /*
    This method determines the HTML that is displayed within a cell. It gets the value as a parameter 
    and uses the column context properties (like masks) to generate the value to display. For default 
    grid columns it simply displays the properly masked value.
    
    @param  tCell   Data object reprecenting the cell data.
    @return The HTML representing the display value.
    */
    cellHtml(sRowId, tCell) {
        const aHtml = [];

        aHtml.push('<div class="', this.genClass(), '"><div class="WebCon_Inner"><div><input type="checkbox"');

        if (this._oParent.isRowIdSelected(sRowId)) {
            aHtml.push(' onclick="this.checked = true" checked="checked"');
        } else {
            aHtml.push(' onclick="this.checked = false"');
        }

        if (!this.isEnabled()) {
            aHtml.push(' disabled="disabled"');
        }
        if (!(this._oParent instanceof WebGrid)) {
            aHtml.push(' tabindex="-1"');
        }

        aHtml.push('><span class="WebCB_Fake"></span></div></div></div>');

        return aHtml.join('');
    }

    set_pbSelectAllCheckbox(bSelectAllCheckbox) {
        if (this.pbSelectAllCheckbox !== bSelectAllCheckbox) {
            this.pbSelectAllCheckbox = bSelectAllCheckbox;
            this._oParent._oHeader.updateHeader();
        }
    }
}