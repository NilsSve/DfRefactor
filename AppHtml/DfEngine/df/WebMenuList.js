import { WebBaseMenu } from './WebBaseMenu.js';
import { WebMenuItemCheckbox } from './WebMenuItemCheckbox.js';
import { df } from '../df.js';

/* 
Class:
    df.WebMenuList
Extends:
    df.WebBaseMenu
    
This menu class represents a mobile style menu inspired on IOS style menu�s. It behaves as a multi 
level list with submenu�s sliding in from the right. It can be positioned like a control and is used 
by the WebMenuButton class to display its menu. Most menu logic is (being a menu provider / 
listener) is inherited from df.WebBaseMenu.

Revisions:
    2014/09/05  Initial version (HW, DAW).
    2015/01/19  Refactored into new model with menu providers and listeners. Removed the menu 
                crawler and changed base class from WebBaseControl to WebBaseMenu. This makes the 
                WebMenuList compatible with the other refactored menu classes allowing menu groups
                to be used. (HW, DAW)
*/
export class WebMenuList extends WebBaseMenu {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tString, "psRootCaption", "");
        this.prop(df.tBool, "pbShowCaption", true);
        this.prop(df.tBool, "pbShowBackItem", true);
        this.prop(df.tBool, "pbShowIcons", false);

        // @privates
        this._sCurrentMenu = "";
        this._eCurrentMenu = null;
        this._oMenuBtn = null;

        //  Configure base classes
        this._bIsMenuListener = true;

        this.pbShowLabel = false;
        this._bRenderChildren = false;
        this._sControlClass = "WebMenuList";
    }

    /* 
    Generates the static wrapping HTML and includes the initial root level menu.
    
    @param  aHtml   Array used as string builder.
    @private
    */
    openHtml(aHtml) {

        super.openHtml(aHtml);

        aHtml.push('<div class="WebMenuWrp" tabindex="0">',
            '<div class="WebML_Title"', (this.pbShowCaption ? '' : ' style="display: none"'), '>',
            '<span class="WebML_Caption">', this.psRootCaption, '</span>',
            '</div>',
            '<div class="WebML_Panel', (this.pbShowIcons ? ' WebML_ShowIcons' : ''), '">',
            '<div class="WebML_Mnu WebML_Root WebML_Current" data-dfmenu-path="">');

        const aMenu = this.getMenu();

        this.genMenuHtml(aHtml, aMenu, false);


        aHtml.push('</div>',
            '</div>');

    }

    /* 
    Closes the wrapping HTML elements.
    
    @param  aHtml   Array used as string builder.
    @private
    */
    closeHtml(aHtml) {
        aHtml.push('</div>');

        super.closeHtml(aHtml);

    }

    /* 
    Called after the HTML is inserted into the DOM during the initial render process. We make sure here 
    that we get references to the important elements and attach event listeners.
    
    @private
    */
    afterRender() {
        let ePnl;

        //  Get references
        this._eControl = df.dom.query(this._eElem, "div.WebMenuWrp");
        this._eMenuPanel = ePnl = df.dom.query(this._eElem, "div.WebML_Panel");
        this._eMenuTitle = df.dom.query(this._eElem, "div.WebML_Title");
        this._eMenuCaption = df.dom.query(this._eElem, "span.WebML_Caption");
        const eMnu = this._eCurrentMenu = df.dom.query(ePnl, "div.WebML_Mnu");

        //  Forward send
        super.afterRender();

        //  Add event handlers
        df.dom.on("click", ePnl, this.onMenuClick, this);

        //  Perform initial sizing if sizing based on its content
        if (this.piHeight <= 0 && !this.pbFillHeight) {
            df.dom.animFrame(function () {
                if (eMnu.firstChild) {
                    ePnl.style.height = this.getMenuHeight(this._eCurrentMenu) + "px";

                    this.sizeChanged();
                }
            }, this);
        }

        this.notifyMenuRendered(this.getMenu());
    }

    /* 
    Generates the HTML for a single level of the menu.
    
    @param  aHtml   (byref) String builder array.
    @param  aMenu   Array with the menu items.
    @param  bSub    If true a back button will be generated.
    */
    genMenuHtml(aHtml, aMenu, bSub) {

        aHtml.push('<ul>');


        //  Generate back button
        if (bSub && this.pbShowBackItem) {
            aHtml.push('<li class="WebML_Item WebML_Back" data-df-path="go-back"><a href="javascript:void(0);" target="_self">', this.getWebApp().getTrans("back"), '</a></li>');
        }

        //  Loop over items
        for (let i = 0; i < aMenu.length; i++) {
            const tItem = aMenu[i];

            //  Determine classnames
            const aClasses = ["WebML_Item", tItem.sCSSClass, (tItem.bEnabled ? df.CssEnabled : df.CssDisabled)];
            if (tItem.aChildren.length > 0) {
                aClasses.push("WebML_HasSub");
            }

            //  Generate group divider
            if (tItem.bBeginGroup) {
                aHtml.push('<li class="WebML_Divider">', (tItem.sGroupCaption || ""), '</li>');
            }

            //  Generate item elements
            this.genItemHtml(aHtml, tItem, false);
            //aHtml.push('<li data-df-path="', tItem._sPath, '" class="', aClasses.join(" "), '"><a href="#">', tItem.sCaption , '</a></li>');
        }

        aHtml.push('</ul>');
    }

    /* 
    Handles click events on the menu. It determines which element is clicked and performs the right 
    action (drill-down / go back) and triggers the click action on the item handler.
    
    @param  oEvent  DOM Event (see: df.events.DOMEvent).
    @private
    */
    onMenuClick(oEvent) {
        let tItem, eElem = oEvent.getTarget(), eMnu 
        const that = this;

        //  Determine the clicked element by bubbling up the DOM structure
        while (!tItem && eElem && eElem !== this._eElem) {
            if (eElem.hasAttribute("data-df-path")) {
                const sID = eElem.getAttribute("data-df-path");

                if (sID === "go-back") {
                    //  If go back button is clicked we go one level up
                    this.levelUp();
                    oEvent.stop();
                    return;
                }
                tItem = this.getItemByPath(sID);
            } else {
                eElem = eElem.parentNode;
            }
        }

        if (tItem) {
            if (tItem.bEnabled) {
                if (tItem.aChildren.length > 0) {
                    //  Perform drilldown

                    //  Get reference to the menu DOM element
                    eMnu = df.dom.query(this._eMenuPanel, 'div.WebML_Mnu[data-dfmenu-path="' + tItem._sPath + '"]');
                    if (!eMnu) {
                        //  Generate a new menu element if it wasn't created yet
                        const aHtml = [];
                        aHtml.push('<div class="WebML_Mnu WebML_HiddenSub" data-dfmenu-path="', tItem._sPath, '">');
                        this.genMenuHtml(aHtml, tItem.aChildren, true);
                        aHtml.push('</div>');
                        eMnu = df.dom.create(aHtml.join(""));

                        this._eMenuPanel.appendChild(eMnu);

                        this.notifyMenuRendered(tItem.aChildren, eMnu);
                    }

                    const ePrnt = this._eCurrentMenu;

                    //  Update caption
                    df.dom.setText(this._eMenuCaption, tItem.sCaption);

                    //  Change CSS classes after a timeout (animation doesn't work properly on newly generated elements)

                    setTimeout(function fTimeout() {
                        if (ePrnt) {
                            df.dom.addClass(ePrnt, "WebML_HiddenParent");
                            df.dom.removeClass(ePrnt, "WebML_Current");
                        }
                        df.dom.addClass(eMnu, "WebML_Current");
                        df.dom.removeClass(eMnu, "WebML_HiddenSub");

                        that.OnUiUpdate.fire(this, { bUiDriven: true });
                        that.updateMenuSize();
                    }, 20);

                    //  Update administration
                    this._sCurrentMenu = tItem._sPath;
                    this._eCurrentMenu = eMnu;

                }

                //  Trigger click event on the item its handler
                tItem._oHandler.itemClick(tItem, function (bExec) {
                    if (bExec && this._oMenuBtn && !(tItem.hRef instanceof WebMenuItemCheckbox) && !tItem.aChildren.length) {
                        this._oMenuBtn.hideMenu();
                    }
                }, this);

            }
            oEvent.stop();
        }
    }

    /* 
    Expands a specific item.
    
    @param  tItem   Menun item.       
    */
    expandItem(tItem) {
        if (tItem.aChildren.length > 0) {
            this._sCurrentMenu = tItem._sPath;
        } else {
            this._sCurrentMenu = "";
        }
        this.refreshMenu();

        this.OnUiUpdate.fire(this, { bUiDriven: true });
    }

    /* 
    Makes sure a specific item is visible by expanding its parent or showing the root. This is used by 
    the designer.
    
    @param  tItem   Menu item.
    */
    showItem(tItem) {
        const tParent = this.getItemByPath(tItem._sPath.substr(0, tItem._sPath.lastIndexOf(".")));

        if (tParent) {
            this.expandItem(tParent);
        } else {
            this._sCurrentMenu = "";
            this.refreshMenu();
        }

        if(this._oMenuBtn){
            this._oMenuBtn.showMenu();
        }
    }

    /*
    @client-action
    */
    collapseAll() {
        this._sCurrentMenu = "";
        this.refreshMenu();

        this.OnUiUpdate.fire(this, { bUiDriven: true });
    }

    /* 
    Navigates one level up in the menu structure. It makes sure that the menu slides in from the level.
    
    @client-action
    */
    levelUp() {
        var eMnu, tItem = null, aMenu;
        const that = this;

        if (this._sCurrentMenu) {
            //  Determine where to go based on the current menu id (if the current menu item is not found we go back to the root)
            if (this._sCurrentMenu.indexOf(".") > 0) {
                this._sCurrentMenu = this._sCurrentMenu.substr(0, this._sCurrentMenu.lastIndexOf("."));
                tItem = this.getItemByPath(this._sCurrentMenu);
            }
            if (tItem) {
                aMenu = tItem.aChildren;
            } else {
                this._sCurrentMenu = "";
                aMenu = this.getMenu();
            }

            //  Get reference to the menu its DOM element
            eMnu = df.dom.query(this._eMenuPanel, 'div.WebML_Mnu[data-dfmenu-path="' + this._sCurrentMenu + '"]');
            if (!eMnu) {
                //  Generate menu elements if unavailable
                const aHtml = [];
                aHtml.push('<div class="WebML_Mnu WebML_HiddenParent', (aMenu === this.getMenu() ? ' WebML_Root' : ''), '" data-dfmenu-path="', this._sCurrentMenu, '">');
                this.genMenuHtml(aHtml, aMenu, !!this._sCurrentMenu);
                aHtml.push('</div>');
                eMnu = df.dom.create(aHtml.join(""));

                this._eMenuPanel.appendChild(eMnu);

                this.notifyMenuRendered(aMenu, eMnu);
            }

            const eSub = this._eCurrentMenu;

            //  Update caption
            if (tItem) {
                df.dom.setText(this._eMenuCaption, tItem.sCaption);
            } else {
                df.dom.setText(this._eMenuCaption, this.psRootCaption);
            }

            //  Update CSS classes after timeout (timeout is needed for smooth animation)
            setTimeout(function fTimeout() {
                if (eSub) {
                    df.dom.addClass(eSub, "WebML_HiddenSub");
                    df.dom.removeClass(eSub, "WebML_Current");
                }
                df.dom.addClass(eMnu, "WebML_Current");
                df.dom.removeClass(eMnu, "WebML_HiddenParent");
                that.OnUiUpdate.fire(this, { bUiDriven: true });
                that.updateMenuSize();
            }, 20);

            this._eCurrentMenu = eMnu;

        }
    }


    /* 
    Is called by the WebBaseMenu class when the menu needs to update itself (something changed regarding 
    the menu its content).
    */
    refreshMenu() {
        let tItem, aMenu, eMnu;
        const aHtml = [];

        if (this._eMenuPanel) {
            //  Determine if our current menu still exists (go back to root if not)
            if (this._sCurrentMenu) {
                tItem = this.getItemByPath(this._sCurrentMenu);
            }

            if (tItem) {
                aMenu = tItem.aChildren;
            } else {
                this._sCurrentMenu = "";
                aMenu = this.getMenu();
            }

            //  Generate menu elements (we throw away all old menu elements by setting innerHTML)
            aHtml.push('<div class="WebML_Mnu WebML_Current', (aMenu === this.getMenu() ? ' WebML_Root' : ''), '" data-dfmenu-path="', this._sCurrentMenu, '">');
            this.genMenuHtml(aHtml, aMenu, !!this._sCurrentMenu);
            aHtml.push('</div>');

            //  Determine if we had focus
            const bHadFocus = this._eElem.contains(document.activeElement);

            this._eMenuPanel.innerHTML = aHtml.join("");
            eMnu = this._eMenuPanel.firstChild;

            this.notifyMenuRendered(aMenu, eMnu);

            //  Update caption
            if (tItem) {
                df.dom.setText(this._eMenuCaption, tItem.sCaption);
            } else {
                df.dom.setText(this._eMenuCaption, this.psRootCaption);
            }

            this._eCurrentMenu = eMnu;
            this.updateMenuSize();

            //  Restore the focus if we had it
            if (bHadFocus) {
                this._eControl.focus();
            }
        }
    }

    /* 
    Called when the menu is changing / has changed and updates the size of the control if needed.
    
    @private
    */
    updateMenuSize(bNoSizeChanged) {

        if (!this.pbFillHeight && this.piHeight <= 0 && this._eCurrentMenu) {
            const iHeight = this.getMenuHeight(this._eCurrentMenu);

            this._eMenuPanel.style.height = iHeight + "px";
            if (!bNoSizeChanged) {
                this.sizeChanged();
            }

            df.dom.animFrame(function () {
                var iNewHeight;
                if (this._eCurrentMenu) {
                    iNewHeight = this.getMenuHeight(this._eCurrentMenu);

                    if (iNewHeight !== iHeight) {
                        this._eMenuPanel.style.height = iNewHeight + "px";

                        this.sizeChanged();
                    }
                }
            }, this);
        }
    }

    /* 
    Implements the setHeight (part of the WebBaseControl API) and updates the height if needed.
    
    @param  iHeight     The height that the outermost div should get.
    @private
    */
    setHeight(iHeight) {
        if (this._eMenuPanel) {

            df.dom.toggleClass(this._eMenuPanel, "WebML_NoScollRoot", (iHeight <= 0));

            if (iHeight <= 0 && this._eCurrentMenu) {
                this._eMenuPanel.style.height = this.getMenuHeight(this._eCurrentMenu) + "px";
            } else {

                //  The list has a hard-coded minimum of 80px
                if (iHeight <= 80) {
                    iHeight = 80;
                }

                iHeight -= this.getVertHeightDiff();
                iHeight = (iHeight < 0 ? 0 : iHeight);  //  FIX: IE8 doesn't handle negative values real well and this seems to happen somehow

                //  Set the height on the grid body
                this._eMenuPanel.style.height = iHeight + "px";
            }
        }
    }

    /*
    We override this method because the form has an extra wrapper of which the Box Difference needs to 
    be taken into account.
    
    @private
    */
    getVertHeightDiff() {
        let iResult = super.getVertHeightDiff();
        iResult += df.dom.offsetHeight(this._eMenuTitle);
        iResult += df.sys.gui.getVertBoxDiff(this._eMenuPanel);
        return iResult;
    }


    /* 
    Determines the height of a specific menu element.
    
    @param  eElem   DOM element for a menu.
    */
    getMenuHeight(eElem) {
        let iHeight = df.dom.offsetHeight(eElem.firstChild);

        iHeight += df.sys.gui.getVertBoxDiff(eElem);

        return iHeight;
    }

    /* 
    Always update the menu height on resize as it might also mean that we where hidden before.
    */
    resize() {
        this.updateMenuSize(true);

        super.resize();
    }

    /* 
    Shows / hides the icons by adding / removing the ShowIcons CSS class based on the new value.
    
    @param  bVal    New value.
    @private
    */
    set_pbShowIcons(bVal) {
        if (this._eMenuPanel) {
            df.dom.toggleClass(this._eMenuPanel, "WebML_ShowIcons", bVal);
        }
    }

    set_psRootCaption(sVal) {
        this.psRootCaption = sVal;
        this.refreshMenu();
    }

    set_pbShowBackItem(bVal) {
        this.pbShowBackItem = bVal;
        this.refreshMenu();
    }

    set_pbShowCaption(bVal) {
        if (this._eMenuTitle) {
            this._eMenuTitle.style.display = (bVal ? "" : "none");
        }
    }
}