import { WebMenuBar } from './WebMenuBar.js';
import { df } from '../df.js';

/*
Class:
    df.WebToolBar
Extends:
    df.WebMenuBar

The WebToolBar is a control that renders a toolbar inside a commandbar. Regular menu items can be 
used within the toolbar that have an icon and / or a caption.
    
Revision:
    2011/09/27  (HW, DAW) 
        Initial version.
    2015/01/20  (HW, DAW)
        Refactored for new style menu system. The rendering logic moved from the WebMenuItem class 
        to the menu classes itself. The WebToolBar now extends the WebMenuBar inheriting its 
        rendering logic. This also means that the WebToolbar now can be positioned as a control.New 
        is support for overflowing into a sub menu.
*/
export class WebToolBar extends WebMenuBar {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbShowCaption", false);
        this.prop(df.tInt, "peAlign", df.ciAlignLeft);
        this.prop(df.tBool, "pbShowIcons", true);
        this.prop(df.tString, "psSubItemCaption", "More..");

        // @privates
        this._eControl = null;

        this._bWrapDiv = true;
        this._sControlClass = "WebToolBar";
    }

    openHtml(aHtml) {
        super.openHtml(aHtml);
    }

    closeHtml(aHtml) {
        super.closeHtml(aHtml);
    }



    afterRender() {
        this._eControl = df.dom.query(this._eElem, "ul");

        super.afterRender();

        this.set_pbShowCaption(this.pbShowCaption);
        this.set_pbShowIcons(this.pbShowIcons);
        this.set_peAlign(this.peAlign);
    }


    refreshMenu() {
        super.refreshMenu();

        this.adjustWidth();
    }

    genMenuHtml(aHtml) {
        super.genMenuHtml(aHtml);

        aHtml.push('<li data-df-item="subitems" class="WebMenuItem WebTlb_SubItems WebTlb_NoFit" style="display: none;"><div><span class="WebItm_Icon">&nbsp;</span><a href="javascript: void(0);" target="_self">', this.psSubItemCaption, '</a></div><ul></ul></li>');
    }

    onMenuClick(oEvent) {
        let eElem;

        super.onMenuClick(oEvent);

        if (!oEvent.bCanceled) {
            eElem = oEvent.getTarget();
            while (eElem && eElem !== this._eElem) {
                if (eElem.hasAttribute("data-df-item")) {
                    //  (HW) FIX FireFox: In case of the action menu menu button the focus goes to the wrong place for FF, force it to go the control element. 
                    this._eControl.focus();


                    if (this._bSubMenuOpened) {
                        this.collapseAll();
                    } else {
                        this.expandSub();
                    }

                    oEvent.stop();
                    return;

                }

                eElem = eElem.parentNode;
            }
        }
    }

    expandSub() {
        let iLeft;

        const eSubBtn = df.dom.query(this._eControl, "li.WebTlb_NoFit");
        const eSubMen = eSubBtn.lastChild;


        if (eSubMen) {
            //  Display submenu
            df.dom.addClass(eSubBtn, "WebItm_Expanded");
            this._bSubMenuOpened = true;


            //  Position sub menu
            const oRect = eSubBtn.getBoundingClientRect();
            iLeft = oRect.left;
            const iViewport = df.sys.gui.getViewportWidth();


            if (iLeft + eSubMen.offsetWidth > iViewport) {
                iLeft = oRect.right - eSubMen.offsetWidth;

                if (iLeft < 0) {
                    iLeft = 5;
                }
            }


            eSubMen.style.top = oRect.bottom + "px";
            eSubMen.style.left = iLeft + "px";



        }
    }

    collapseAll() {

        if (this._bSubMenuOpened) {
            const eSubBtn = df.dom.query(this._eControl, "li.WebTlb_NoFit");
            df.dom.addClass(eSubBtn, "WebItm_Expanded");
            this._bSubMenuOpened = false;
        }

        super.collapseAll();
    }

    adjustWidth() {
        let i;

        if (this._eControl) {
            const iSpace = this._eControlWrp.clientWidth;
            const eSubBtn = df.dom.query(this._eControl, "li.WebTlb_NoFit");

            if (this._eControl.scrollWidth > iSpace) {
                const aItems = df.dom.query(this._eElem, "ul.WebBarRoot > li.WebMenuItem", true);

                if (aItems.length > 1) {
                    const eSubMen = df.dom.query(this._eControl, "li.WebTlb_NoFit > ul");

                    eSubBtn.style.display = "";

                    i = aItems.length - 2;
                    while (this._eControl.scrollWidth > iSpace && i >= 0) {
                        const eItem = aItems[i];
                        eSubMen.appendChild(eItem);
                        i--;

                    }
                }
            } else {
                eSubBtn.style.display = "none";
            }
        }
    }

    resize() {
        const iSpace = this._eControlWrp.clientWidth;

        if (this._iLastResizeSpace !== iSpace) {
            this._iLastResizeSpace = iSpace;
            this.adjustWidth();
        }
    }

    genClass() {
        let sClass = super.genClass();

        sClass += (this._oParent?._bIsCommandBar ? " WebTlb_Command" : " WebTlb_Standalone");

        return sClass;
    }



    /*
    This setter method adds or removes the CSS class that shows caption.
    
    @param  bVal   The new value.
    @private
    */
    set_pbShowCaption(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "WebTlb_HideCaption", !bVal);

            this.refreshMenu();
        }
    }

    /* 
    Shows / hides the icons by adding / removing the HideIcons CSS class based on the new value.
    
    @param  bVal    New value.
    @private
    */
    set_pbShowIcons(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "WebTlb_HideIcons", !bVal);
            this.refreshMenu();
        }
    }

    set_peAlign(eVal) {
        if (this._eControlWrp) {
            this._eControlWrp.style.textAlign = (["left", "center", "right"])[eVal];
        }
    }
};