import { WebToolBar } from './WebToolBar.js';
import { df } from '../df.js';
/*
Class:
    df.WebActionBar
Extends:
    df.WebToolBar

The WebActionBar is a specialized version of the toolbar that has specialized logic for placing 
items in the submenu. This works using the peActionDisplay property available on cWebMenuItem. This 
property can be set to adMenu, adActionBar and adBoth controlling if an menu item is placed directly 
in the actionbar, in the submenu or in both (default). This is used by the action toolbar in the 
header for drilldown style web applications. On overflow items set to adBoth are removed from the 
action bar first and after that it moves adActionBar items to the menu if really needed.
    
Revision:
    2015/01/20  (HW, DAW)
*/
export class WebActionBar extends WebToolBar {
    constructor(sName, oParent) {
        super(sName, oParent)

        this._sControlClass += " WebActionBar";
    }

    /* 
    Override the function responsible for rendering the root level menu. We change it so that items are 
    placed in the actionbar itself or in the menu (or both) based on peActionDisplay.
    
    @param  aHtml   Array string builder.
    @private    
    */
    genMenuHtml(aHtml) {
        let tItm, bMenu = false;
        const aMenu = this.getMenu();

        for (let i = 0; i < aMenu.length; i++) {
            tItm = aMenu[i];

            if (!tItm.sCSSClass) {
                tItm.sCSSClass = "WebDefaultMenuItem";
            }

            if (tItm.eActionDisplay === df.adBoth || tItm.eActionDisplay === df.adActionBar) {
                this.genItemHtml(aHtml, tItm, true);
            }

            bMenu = bMenu || tItm.eActionDisplay === df.adBoth || tItm.eActionDisplay === df.adMenu;
        }

        aHtml.push('<li data-df-item="subitems" class="WebMenuItem WebTlb_SubItems WebTlb_NoFit"', (bMenu ? '' : ' style="display: none;"'), '><div><span class="WebItm_Icon">&nbsp;</span><a href="javascript: void(0);" target="_self">', this.psSubItemCaption, '</a></div><ul>');

        if (bMenu) {
            for (let i = 0; i < aMenu.length; i++) {
                tItm = aMenu[i];

                if (tItm.eActionDisplay === df.adBoth || tItm.eActionDisplay === df.adMenu) {
                    this.genItemHtml(aHtml, tItm, true);
                }
            }
        }

        aHtml.push('</ul></li>');
    }

    /* 
    We override adjustWidth which is called from the WebToolBar class when the size or the menu changed. 
    Based on the available space we move overflowing items to the submenu. This is done in two passes 
    where the first only removes items that are both in the action bar and in the menu and then it moves 
    actionbar only items to the menu.
    
    @private
    */
    adjustWidth() {
        let aItems, eItem, i;

        if (this._eControl) {
            const iSpace = this._eControlWrp.clientWidth;

            if (this._eControl.scrollWidth > iSpace) {
                aItems = df.dom.query(this._eElem, "ul.WebBarRoot > li.WebMenuItem", true);

                if (aItems.length > 1) {


                    //  Loop over items and first remove items also available in the menu
                    i = aItems.length - 2;
                    while (this._eControl.scrollWidth > iSpace && i >= 0) {
                        eItem = aItems[i];
                        if (eItem.hasAttribute("data-df-path")) {
                            const tItem = this.getItemByPath(eItem.getAttribute("data-df-path"));

                            if (tItem.eActionDisplay === df.adBoth) {
                                eItem.parentNode.removeChild(eItem);
                            }
                        }
                        i--;
                    }

                    //  If needed do a second pass to move actionbar only items to the menu
                    if (this._eControl.scrollWidth > iSpace) {
                        const eSubMen = df.dom.query(this._eControl, "li.WebTlb_NoFit > ul");
                        aItems = df.dom.query(this._eElem, "ul.WebBarRoot > li.WebMenuItem", true);

                        i = aItems.length - 2;
                        while (this._eControl.scrollWidth > iSpace && i >= 0) {
                            eItem = aItems[i];
                            eSubMen.appendChild(eItem);
                            i--;
                        }
                    }

                    const eSubBtn = df.dom.query(this._eControl, "li.WebTlb_NoFit");
                    eSubBtn.style.display = "";
                }
            }
        }
    }

    /* 
    Augment collapseAll with the logic to remove the mask that might have been created for mobile 
    devices.
    */
    collapseAll() {
        if (this._eMask) {
            df.dom.off("click", this._eMask, this.onMaskTouch, this);
            this._eMask.parentNode.removeChild(this._eMask);
            this._eMask = null;
        }

        super.collapseAll();
    }

    /* 
    Augment the expandItem function and insert the mask if there is actually something to expand.
    
    @param  tItem       Menu item.
    */
    expandItem(tItem) {
        if (tItem && tItem.aChildren.length > 0) {
            this.showMask();
        }

        super.expandItem(tItem);
    }

    /* 
    Augment the expandSub function and insert the mask. This function is called when the submenu is 
    shown.
    */
    expandSub() {
        this.showMask();

        super.expandSub();
    }

    /* 
    Inserts a mask for for mobile that intercepts the a click behind the menu.
    */
    showMask() {
        if (df.sys.isMobile) {
            this._eMask = df.dom.create('<div class="WebMenu_Mask">&nbsp;</div>');

            this._eElem.insertBefore(this._eMask, this._eElem.firstChild);
            //document.body.appendChild(this._eMask);
            df.dom.on("click", this._eMask, this.onMaskTouch, this);
        }
    }

    /* 
    Handles the click on the mask and collapses all expanded menu's.
    
    @param  oEvent  See df.events.DOMEvent.
    */
    onMaskTouch(oEvent) {
        this.collapseAll();

        oEvent.stop();
    }

}