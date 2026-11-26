import { WebColumn_mixin  } from './WebColumn_mixin.js';
import { WebTagsForm } from './WebTagsForm.js';
import { df } from '../df.js';
/*
Class:
    df.WebColumnTags
Mixin:
    df.WebColumn_mixin (df.WebColumnTagsBase)
Extends:
    df.WebTagsForm
    
Revision:
    2022/07/17  (BN, DAW) 
        Initial version.
*/

//  Generate new base class using mixin and WebTagsForm
class WebColumnTagsBase extends WebColumn_mixin(WebTagsForm) { } //df.mixin("df.WebColumn_mixin", "df.WebTagsForm");

export class WebColumnTags extends WebColumnTagsBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Configure super class
        this._sCellClass = "WebTagsColumn WebTagsForm WebColTags";

        this.prop(df.tInt, "peWordBreak", df.wbWrap);
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

        const aSelection = this.parseSelectionValues(tCell.sValue);
        for (let i = 0; i < aSelection.length; i++) {
            aHtml.push('<div class="WebTgf_Tag">');

            aHtml.push('<span class="WebTgf_Text ', df.classWordBreak(this.peWordBreak), '">', df.dom.encodeHtml(this.truncate(aSelection[i], this.piTagTruncateAt, false)), '</span>');

            aHtml.push('</div>');
        }

        return aHtml.join('');
    }

    tooltipValue(tCell) {
        return this.parseSelectionValues(tCell.sValue).join(', ');
    }

    set_peWordBreak(iVal) {
        if (this.peWordBreak !== iVal) {
            this._oParent.redraw();
        }
    }

}