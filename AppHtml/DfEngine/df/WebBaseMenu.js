import { WebBaseControl } from './WebBaseControl.js';
import { WebMenuItem } from './WebMenuItem.js';
import { WebMenuItemCheckbox } from './WebMenuItemCheckbox.js';
import { df } from '../df.js';
/*
Class:
    df.WebBaseMenu
Extends:
    df.WebBaseControl
Mixins:
    df.WebMenuProvider_mixin

This is the core of the menu system which consists of menu providers and menu listeners. A central
singleton object called the GroupHub is responsible for the communication of data between the
providers and the listeners. These work in groups based on unique names (psGroupName). A menu
provider is responsible for maintaining menu elements which can be sub web objects of that provider
or dynamically provided. It communicates changes through the GroupHub to the menu listeners that
only know the menu as an abstract object tree. The listeners are responsible for rendering the menu.

Most menu classes are both listener and provider and if no groupname is set they will work
standalone. The df.WebMenuProvider_mixin is the core of this logic and actually implements both the
listener and the provider interface where subclasses control if they are listeners or providers
using properties. A group can have multiple listeners and multiple providers. The WebMenuGroup is a
special class that is only a menu provider allowing a menu to be defined in a different place than
it is rendered. For example inside a view. If a group is placed inside a view it will deactivate
itself if the view is not displayed changing the menu at runtime. Providers also send updates
through the hub if changes are made to the menu structure.

Revisions:
    2015/01/15, HW (DAW)
        Initial version.
*/
/* global df */

export const WebMenuProvider_mixin = superclass => class extends superclass {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbAllowHtml");
        this.prop(df.tString, "psGroupName");

        this.OnUiUpdate = new df.events.JSHandler();

        this._aMenu = null; //  If we are also a menu renderer (most classes are renderer and provider as well) this holds the received menu

        this._aDynamicMenu = null;
        this._bIsMenuProv = true;
        this._bIsMenuListener = false;
    }

    create() {
        super.create();

        if (this.psGroupName) {
            this.getHub().addProvider(this.psGroupName, this);

            if (this._bIsMenuListener) {
                this.getHub().addListener(this.psGroupName, this);
            }
        }
    }

    destroy() {
        //  Properly unregister from grouphub as the group can still be used
        if (this.psGroupName) {
            if (this._bIsMenuListener) {
                this.getHub().remListener(this.psGroupName, this);
            }

            this.getHub().remProvider(this.psGroupName, this);
        }

        super.destroy();
    }

    groupCollect(aData) {
        return this.genMenuData(aData);
    }

    groupUpdate(aData) {
        this._aMenu = aData;

        this.updatePaths();

        this.refreshMenu();
    }

    genMenuData(aData) {
        //  Add dynamic data if available
        if (this._aDynamicMenu) {
            const aMen = this._aDynamicMenu;
            for (let i = 0; i < aMen.length; i++) {
                aMen[i]._oHandler = this;

                aData.push(aMen[i]);
            }
        }

        //  Recursively visit children
        function visit(oParent, aItems) {

            for (let i = 0; i < oParent._aChildren.length; i++) {
                const oItem = oParent._aChildren[i];

                if (oItem instanceof WebMenuItem && oItem.visible()) {
                    const tItem = {
                        sId: "",

                        hRef: oItem,

                        sCaption: oItem.psCaption,
                        sTooltip: oItem.psToolTip,
                        sGroupCaption: oItem.psGroupCaption,

                        bEnabled: oItem.isEnabled(),
                        sCSSClass: oItem.cssClass(),
                        sHtmlId: oItem.psHtmlId,

                        bBeginGroup: oItem.pbBeginGroup,
                        sImage: oItem.psImage,

                        eCheckbox: (oItem instanceof WebMenuItemCheckbox ? (oItem.isChecked() ? 1 : -1) : 0),

                        sTextColor: oItem.psTextColor,
                        sBackgroundColor: oItem.psBackgroundColor,

                        eActionDisplay: oItem.peActionDisplay,

                        aChildren: [],

                        _bCustomRender: oItem.customRender(),
                        _oHandler: oItem
                    };
                    aItems.push(tItem);

                    visit(oItem, tItem.aChildren);
                }
            }
        }


        visit(this, aData);
    }

    set_psGroupName(sVal) {
        if (this.psGroupName) {
            this.getHub().remProvider(this.psGroupName, this);
        }

        this.getHub().addProvider(this.psGroupName, this);
    }

    set_pbAllowHtml(bVal) {
        this.pbAllowHtml = bVal;

        this.refreshMenu();
    }

    /*
    @client-action
    */
    refresh() {
        const aMenu = this._tActionData;

        for (let i = 0; i < aMenu.length; i++) {
            this.initDynamic(aMenu[i]);
        }

        this._aDynamicMenu = aMenu;

        this.notifyChange();
    }

    itemClick(tItem, fReturn, oEnv) {
        if (tItem.aChildren.length > 0) {
            fReturn.call(oEnv, false);
            return false;
        } else {
            return this.fire('OnItemClick', [tItem.sId, tItem.sCaption], function (oEvent) {
                fReturn.call(oEnv, (oEvent.bClient || oEvent.bServer));
            });
        }
    }

    updateItem(sId, bOverwriteSubs) {
        const tNew = this._tActionData;
        const tCur = this.getItemById(sId);

        if (tCur) {
            tCur.sId = tNew.sId;

            tCur.sCaption = tNew.sCaption;
            tCur.sTooltip = tNew.sToolTip;
            tCur.sGroupCaption = tNew.sGroupCaption;

            tCur.bEnabled = tNew.bEnabled;
            tCur.sCSSClass = tNew.sCSSClass;
            tCur.sHtmlId = tNew.sHtmlId;

            tCur.bBeginGroup = tNew.bBeginGroup;
            tCur.sImage = tNew.sImage;

            tCur.eCheckbox = tNew.eCheckbox;

            tCur.sTextColor = tNew.sTextColor;
            tCur.sBackgroundColor = tNew.sBackgroundColor;

            tCur.eActionDisplay = tNew.eActionDisplay;

            if (df.toBool(bOverwriteSubs)) {
                tCur.aChildren = tNew.aChildren;
                this.initDynamic(tCur);
            }

            this.notifyChange();
        }
    }

    insertItem(sParentId) {
        const tNew = this._tActionData;
        const tParent = this.getItemById(sParentId);

        if (tParent) {
            this.initDynamic(tNew);
            tParent.aChildren.push(tNew);

            this.notifyChange();
        }
    }

    removeItem(sId) {
        function find(aMen) {
            for (let i = 0; i < aMen.length; i++) {
                if (aMen[i].sId === sId) {
                    aMen.splice(i, 1);
                    return true;
                }

                if (find(aMen[i].aChildren)) {
                    return true;
                }
            }

            return false;
        }

        if (find(this._aDynamicMenu)) {
            this.notifyChange();
        }

    }

    /* 
    
    @private
    */
    initDynamic(tItem) {
        tItem._oHandler = this;

        for (let i = 0; i < tItem.aChildren.length; i++) {
            this.initDynamic(tItem.aChildren[i]);
        }

    }



    /*
    Called by menuitems when they change.
    
    */
    notifyChange() {
        this.getWebApp().waitForCall(this.performUpdate, this);
    }

    /* 
    Augment updateEnabled and make sure that the menu gets refreshed.
    */
    updateEnabled() {
        super.updateEnabled();

        this.notifyChange();
    }

    performUpdate() {
        this._aMenu = null;

        if (this.psGroupName) {
            this.getHub().updateGroup(this.psGroupName);
        } else {
            this.refreshMenu();
        }

        this.OnUiUpdate.fire(this, { bUiDriven: false });
    }

    getMenu() {
        if (!this._aMenu) {
            this._aMenu = [];

            if (!this.psGroupName || !this._bIsMenuListener) {
                this.genMenuData(this._aMenu);
                this.updatePaths();
            }
        }

        return this._aMenu;
    }

    getItemByPath(sPath) {
        let tItem = null, aMen = this.getMenu();

        const aPath = sPath.split(".");

        for (let i = 0; i < aPath.length; i++) {
            if (aMen[aPath[i]]) {
                tItem = aMen[aPath[i]];
                aMen = tItem.aChildren;
            } else {
                tItem = null;
            }
        }

        return tItem;
    }

    getItemById(sId) {
        function find(aMen) {
            for (let i = 0; i < aMen.length; i++) {
                if (aMen[i].sId === sId) {
                    return aMen[i];
                }
                const oSub = find(aMen[i].aChildren);
                if (oSub) {
                    return oSub;
                }
            }

            return null;
        }

        return find(this.getMenu());
    }

    getItemByHandler(oObj) {
        function find(aMen) {

            for (let i = 0; i < aMen.length; i++) {
                if (aMen[i]._oHandler === oObj) {
                    return aMen[i];
                }

                const oRes = find(aMen[i].aChildren);
                if (oRes) {
                    return oRes;
                }
            }

            return null;
        }

        return find(this.getMenu());
    }

    getItemElemByPath(sPath) {
        return (this._eControl && df.dom.query(this._eControl, 'li[data-df-path="' + sPath + '"]')) || null;
    }

    /* 
    @return DOM element for a specific handler (menu item) if it can be found or NULL if not.
    */
    getItemElemByHandler(oObj) {
        const tItm = this.getItemByHandler(oObj);

        if (tItm) {
            return this.getItemElemByPath(tItm._sPath);
        }

        return null;
    }

    genItemHtml(aHtml, tItem, bSub) {
        let sTooltip;

        const aClassNames = ['WebMenuItem', tItem.sCSSClass, (tItem.bEnabled ? df.CssEnabled : df.CssDisabled)];
        if (tItem.aChildren.length > 0) {
            aClassNames.push('WebItm_HasSub');
        }
        if (tItem.bBeginGroup) {
            aClassNames.push('WebItm_BgnGroup');
        }
        if (tItem.sImage) {
            aClassNames.push('WebItm_HasIcon');
        }
        if (tItem.eCheckbox < 0 || tItem.eCheckbox > 0) {
            aClassNames.push('WebItm_HasCheckbox');
        }

        aHtml.push('<li class="', df.dom.encodeAttr(aClassNames.join(" ")), '" data-df-path="', tItem._sPath, '"');

        if (tItem.sHtmlId) {
            aHtml.push(' id="', df.dom.encodeAttr(tItem.sHtmlId), '"');
        }
        if (tItem.sBackgroundColor || tItem.sTextColor) {
            aHtml.push(' style="');

            if (tItem.sTextColor) {
                aHtml.push('color: ', df.dom.encodeAttr(tItem.sTextColor), ';');
            }
            if (tItem.sBackgroundColor) {
                aHtml.push('background-color: ', df.dom.encodeAttr(tItem.sBackgroundColor), ';');
            }
            aHtml.push('"');
        }


        aHtml.push('>');

        if (tItem._bCustomRender) {
            tItem._oHandler.itemHtml(aHtml);
        } else {


            //  Replace the first occurence of & (which is used to indicate keyboard shortcuts in windows)
            tItem.sCaption = tItem.sCaption.replace("&", "");

            if (!this.pbShowLabel && tItem._sPath.indexOf(".") < 0) {
                sTooltip = tItem.sTooltip || df.dom.encodeHtml(tItem.sCaption);
            } else {
                sTooltip = tItem.sTooltip;
            }

            aHtml.push('<div title="', df.dom.encodeAttr(sTooltip), '">');

            //  Add image if needed
            if (tItem.sImage) {
                aHtml.push('<span class="WebItm_Icon" style="background-image: url(' + "'" + df.dom.encodeAttr(tItem.sImage) + "'" + ');">&nbsp;</span>');
            } else {
                aHtml.push('<span class="WebItm_Icon">&nbsp;</span>');
            }

            if (tItem.eCheckbox < 0) {
                aHtml.push('<input class="WebItm_CheckBox" type="checkbox"></input>');
            } else if (tItem.eCheckbox > 0) {
                aHtml.push('<input class="WebItm_CheckBox" type="checkbox" checked></input>');
            }

            //  Generate the caption
            aHtml.push('<a tabindex="-1" href="javascript: void(0);" target="_self">', (this.pbAllowHtml ? tItem.sCaption : df.dom.encodeHtml(tItem.sCaption)), '</a></div>');

            //  Generate sub elements if needed
            if (bSub && tItem.aChildren.length > 0) {
                aHtml.push('<ul>');

                for (let i = 0; i < tItem.aChildren.length; i++) {
                    this.genItemHtml(aHtml, tItem.aChildren[i], bSub);
                }

                aHtml.push('</ul>');
            }
        }
        aHtml.push('</li>');
    }

    updatePaths() {

        //  Generate unique ID's for every menu item
        function genID(tItem, sPath) {

            tItem._sPath = sPath;

            for (let i = 0; i < tItem.aChildren.length; i++) {
                genID(tItem.aChildren[i], sPath + "." + i.toString());
            }
        }

        for (let i = 0; i < this._aMenu.length; i++) {
            genID(this._aMenu[i], i.toString());
        }
    }

    refreshMenu() {
        //  Empty stub: Implemented by subclasses
    }

    expandItem(tItem) {
        //  Empty stub: Implemented by subclasses
    }

    /* 
    Called by the designer to show a menu item. By default calls expandItem but some menu systems 
    override it.
    
    @param      tItem   The menu item struct.
    @private
    */
    showItem(tItem) {
        this.expandItem(tItem);
    }

    getHub() {
        const oWA = this.getWebApp();

        if (oWA) {
            if (!oWA._oMenuHub) {
                oWA._oMenuHub = new df.GroupHub();
            }

            return oWA._oMenuHub;
        }

        return null;
    }

    /**
     * Calles itemRendered on the passed menu items (if they use custom rendering).
     * 
     * @param {Array} aItems Menu items to be notified.
     * @param {DOM element} eMnu  DOM element for the menu
     */
    notifyMenuRendered(aItems, eMnu) {
        aItems.forEach(tItem => {
            if (tItem._bCustomRender) {
                tItem._oHandler.itemRendered(this.getItemElemByPath(tItem._sPath));
            }
        });
    }
};

export class WebBaseMenu extends WebMenuProvider_mixin(WebBaseControl) {}

