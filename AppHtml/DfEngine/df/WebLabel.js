import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';

/* 
Class:
    df.WebLabel
Extends:
    df.WebBaseControl

The WebLabel is a simple control that shows a piece of text. Compared to the HTML box it isn't 
created to support HTML / rich text but is implemented for developers that don't want to use the 
label integrated into controls.

Revisions:
    2012/03/03  (HW, DAW)
        Initial version.
*/
export class WebLabel extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Properties
        this.prop(df.tString, "psCaption", "");
        this.prop(df.tInt, "peAlign", 0);
        this.prop(df.tBool, "pbShowBorder", false);
        this.prop(df.tInt, "peWordBreak", df.wbPreWrap);

        //  Configure super classes
        this.pbShowLabel = false;

        //  @privates
        this._bFocusAble = false;
        this._sControlClass = "WebLabel";
    }

    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebLabel_content ', df.classWordBreak(this.peWordBreak), '">&nbsp;</div>');
    }

    closeHtml(aHtml) {
        super.closeHtml(aHtml);
    }

    afterRender() {
        this._eControl = df.dom.query(this._eElem, "div.WebLabel_content");

        super.afterRender();

        this.set_peAlign(this.peAlign);
        this.set_psCaption(this.psCaption);
        this.set_pbShowBorder(this.pbShowBorder);
    }

    set_psCaption(sVal) {
        if (this._eControl) {
            df.dom.setText(this._eControl, sVal);

            if (sVal !== this.psCaption) {
                this.sizeChanged();
            }
        }
    }

    set_peWordBreak(iVal) {
        if (this._eControl) {
            df._eControl.className = "WebLabel_content " + df.classWordBreak(iVal);
        }
    }

    set_pbShowBorder(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "WebLabel_border", bVal);

            if (this.pbShowBorder !== bVal) {
                this.sizeChanged();
            }
        }
    }

    set_peAlign(iVal) {
        if (this._eControl) {
            this._eControl.style.textAlign = (iVal === df.ciAlignLeft ? "left" : (iVal === df.ciAlignCenter ? "center" : (iVal === df.ciAlignRight ? "right" : "")));
        }
    }
}