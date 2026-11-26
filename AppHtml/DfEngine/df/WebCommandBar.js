import { WebBaseUIObject } from './WebBaseUIObject.js';
import { WebMenuBar } from './WebMenuBar.js';
import { WebToolBar } from './WebToolBar.js';
import { df } from '../df.js';

export class WebCommandBar extends WebBaseUIObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "peRegion", df.ciRegionTop);

        // @privates
        this._eSizer = null;
        this._bIsCommandBar = true;

        //  Configure super classes
        this._bWrapDiv = true;
        this._bRenderChildren = true;
        this._sControlClass = "WebCommandBar";
    }

    addChild(oChild) {
        if (oChild instanceof WebMenuBar || oChild instanceof WebToolBar) {
            super.addChild(oChild);
        } else {
            throw new df.Error(5201, "Invalid object structure: WebCommandBar can only contain WebMenuBar or WebToolBar objects.", this);
        }
    }

    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebCmd_Sizer">');
    }
    closeHtml(aHtml) {
        aHtml.push('</div>');

        super.closeHtml(aHtml);
    }


    renderChildren(eContainer) {
        let eToolWrap;

        this._eSizer = df.dom.query(this._eElem, "div.WebCmd_Sizer");

        //  Call children and append them to ourselves
        for (let i = 0; i < this._aChildren.length; i++) {
            const oChild = this._aChildren[i];

            //  Check if we can actually render the object
            if (oChild instanceof WebBaseUIObject) {
                const eChild = oChild.render();

                if (oChild instanceof WebToolBar) {
                    if (!eToolWrap) {
                        eToolWrap = df.dom.create('<div class="WebCmd_ToolWrap"></div>');
                        this._eSizer.appendChild(eToolWrap);
                    }
                    eToolWrap.appendChild(eChild);
                } else {
                    eToolWrap = null;
                    this._eSizer.appendChild(eChild);
                }
            }
        }


        //this._eSizer.appendChild(df.dom.create('<div style="clear: both"></div>'));
    }

    prepareSize() {
        this._bStretch = false;

        if (this._eSizer) {
            this._iWantedHeight = this._eSizer.scrollHeight; // Changed to scrollheight for IE issue
        }

        return this._iWantedHeight;
    }

    setOuterHeight(iHeight) {
        if (this._eElem) {
            this._eElem.style.height = iHeight + "px";
        }
    }


}