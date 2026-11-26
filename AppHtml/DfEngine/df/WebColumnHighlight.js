import { WebColumnBase } from './WebColumn.js';
import { df } from '../df.js';
/* 
Class:
    df.WebColumnHighlight
Extends:
    df.WebColumn_mixin(df.WebForm)

Special column class that is able to highlight search phrases. It does this by altering cell values 
with a <span class="WebHighlight">..</span> wrapping each keyword. This allows the CSS to highlight 
the keyword.

Revision:
    2016/05/25  (HW, DAE)
*/

export class WebColumnHighlight extends WebColumnBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psHighlightCSSClass", "WebHighlight");

        this.prop(df.tString, "psHighlight", "");
        this.prop(df.tBool, "pbFullText", true);
        this.prop(df.tBool, "pbSeparateWords", true);
        this.prop(df.tBool, "pbCaseSensitive", false);

        this._oRegEx = null;
    }

    /* 
    Augments the cellHtml function with support for the pbPassword property.
    
    @param  tCell   Struct with cell data.
    @return HTML content of the cell &bull;&bull; for passwords.
    */
    cellHtml(sRowId, tCell) {
        let sVal; 
        const sCssClass = this.psHighlightCSSClass;

        const tVal = df.sys.data.serverToType(tCell.sValue, this.peDataType);
        sVal = this.typeToDisplay(tVal);

        if (!this.pbAllowHtml) {
            sVal = df.dom.encodeHtml(sVal);
        }

        if (this.psHighlight) {
            const oRegEx = this.getRegEx();

            sVal = sVal.replace(oRegEx, function (match) {
                return '<span class="' + sCssClass + '">' + match + '</span>';
            });
        }

        return (sVal !== '' ? sVal : '&nbsp;');
    }

    set_psHighlight(sVal) {
        if (this.psHighlight !== sVal) {
            this.psHighlight = sVal;
            this._oRegEx = null;
            //  this._oParent.redraw(); // We are not doing a list redraw because it causes a duplicate redraw in most cases. It does mean that to apply a new highlight you have to refresh the list yourself.
        }
    }

    set_psHighlightCSSClass(sVal) {
        this.psHighlightCSSClass = sVal;

        this._oParent.redraw();
    }

    set_pbFullText(bVal) {
        this.pbFullText = bVal;
        this._oRegEx = null;
        this._oParent.redraw();
    }

    set_pbSeparateWords(bVal) {
        this.pbSeparateWords = bVal;
        this._oRegEx = null;
        this._oParent.redraw();
    }

    set_pbCaseSensitive(bVal) {
        this.pbCaseSensitive = bVal;
        this._oRegEx = null;
        this._oParent.redraw();
    }

    getRegEx() {
        let aHighlights, sRegex, sMod;

        if (!this._oRegEx) {
            if (this.pbSeparateWords) {
                aHighlights = this.psHighlight.split(" ");
            } else {
                aHighlights = [this.psHighlight];
            }

            for (let i = 0; i < aHighlights.length; i++) {
                aHighlights[i] = df.sys.data.escapeRegExp(aHighlights[i]);
            }
            sRegex = "(" + aHighlights.join("|") + ")";

            if (!this.pbFullText) {
                sRegex = "^" + sRegex;
            }

            sMod = "g";
            if (!this.pbCaseSensitive) {
                sMod += "i";
            }

            this._oRegEx = new RegExp(sRegex, sMod);
        }

        return this._oRegEx;
    }
}