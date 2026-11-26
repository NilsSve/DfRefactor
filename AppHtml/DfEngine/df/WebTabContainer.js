import { WebCardContainer } from './WebCardContainer.js';
import { WebTabPage } from './WebTabPage.js';
import { WebBaseUIObject } from './WebBaseUIObject.js';
import { df } from '../df.js';

/*
Class:
    df.WebTabContainer
Extends:
    df.WebCardContainer

This class represents the tab container control. The WebCardContainer contains the main 
implementation of the WebTabContainer only different styles are applied.
    
Revision:
    2012/10/02  (HW, DAW)
        Split into WebCardContainer and WebTabContainer.
*/
export class WebTabContainer extends WebCardContainer {
    constructor(sName, oParent) {
        super(sName, oParent);


        // @privates
        //  Configure super classes
        this._sControlClass = "WebTabContainer";
        this._sCardClass = "WebTbc";
        this._bCC = false; //  Used by the designer to filter cardcontainers from tab / accordion containers
    }

    openHtml(aHtml) {
        this.pbShowCaption = false;
        this.pbShowBorder = false;

        super.openHtml(aHtml);
    }

    addChild(oChild) {
        if (oChild instanceof WebBaseUIObject && !(oChild instanceof WebTabPage)) {
            throw new df.Error(999, "WebTabContainer objects cannot have controls as direct children '{{0}}'. Consider placing them within a WebTabPage.", this, [(oChild.getLongName() || 'oWebApp')]);
        }

        super.addChild(oChild);
    }

    set_pbShowCaption(bVal) {

    }

    set_pbShowBorder(bVal) {

    }


    /*
    This method determines the height that is lost. For the tab panel this is the space that the buttons 
    take.
    
    @return The amount of pixels that can't be used by the content.
    @private
    */
    getHeightDiff() {
        let iHeight = 0;

        if (this._eHead) {
            iHeight += df.dom.clientHeight(this._eHead);
            iHeight += df.sys.gui.getVertBoxDiff(this._eHead, 1);  //  Outside difference
        }

        if (this.pbShowCaption && this._eLabelSpacer) {
            iHeight += df.dom.clientHeight(this._eLabelSpacer);
            iHeight += df.sys.gui.getVertBoxDiff(this._eHead, 1);  //  Outside difference
        }


        if (this._eControl) {
            iHeight += df.sys.gui.getVertBoxDiff(this._eControl);
            iHeight += df.sys.gui.getVertBoxDiff(this._eInner);
            iHeight += df.sys.gui.getVertBoxDiff(this._eControlWrp);
        }

        return iHeight;
    }

    // - - - - Focus  - - - - 

    /*
    Overrides the focus method and passes the focus to the first active tab button, if there is no 
    active tab button we return false to indicate that it can't take the focus.
    */
    focus() {
        let oTab;

        if (this._bFocusAble && this.isEnabled() && this._eElem) {
            for (let i = 0; i < this._aCards.length; i++) {
                oTab = this._aCards[i];


                if (oTab.isActive() && oTab._eBtn) {
                    try {
                        oTab._eBtn.focus();
                    } catch (oErr) {

                    }

                    this.objFocus();
                    return true;
                }
            }
        }

        return false;
    }
}