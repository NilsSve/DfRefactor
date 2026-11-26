import { WebBaseMenu } from './WebBaseMenu.js';
import { WebFloatingPanel } from './WebFloatingPanel.js';
import { WebMenuList } from './WebMenuList.js';
import { df } from '../df.js';

/*
Class:
    df.WebMenuButton
Extends:
    df.WebBaseMenu

Control that renders a button (or an anchor) which on click shows a floating panel that shows a menu 
using the WebMenuList.

Revisions:
    2015/01/15, HW (DAW)
        Initial version.
*/
export class WebMenuButton extends WebBaseMenu {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tBool, "pbRenderAsAnchor", true);
        this.prop(df.tBool, "pbHideOnBlur", true);
        this.prop(df.tString, "psCaption", "");
        this.prop(df.tInt, "piMenuWidth", 300);
        this.prop(df.tInt, "piMenuHeight", 0);
        this.prop(df.tString, "psMenuCSSClass", "");
        this.prop(df.tString, "psMenuRootCaption", "");
        this.prop(df.tBool, "pbMenuShowCaption", true);
        this.prop(df.tBool, "pbMenuShowIcons", false);
        this.prop(df.tString, "psGroupName", "");
        this.prop(df.tBool, "pbOpenOnRoot", false);

        this.pbShowLabel = false;

        this._oPnl = null;
        this._oMenuList = null;

        this._sRealgroupName = "";

        this._bIsMenu = true;
        this._bJSSizing = false;
        this._sControlClass = "WebMenuButton";
    }

    create() {
        //  The menu button uses the menu group system internally so it generates a custom menu group name if none is specified.
        this._sRealgroupName = this.psGroupName;

        if (!this.psGroupName) {
            this.psGroupName = "_WebMenuButtonGrp_" + df.dom.genDomId().toString();
        }

        super.create();
    }


    openHtml(aHtml) {
        if (!this.pbRenderAsAnchor) {
            this._sControlClass += " WebButton";
        } else {
            this._sControlClass = "WebMenuAnchor";
        }

        super.openHtml(aHtml);

        if (this.pbRenderAsAnchor) {
            aHtml.push('<a id="', this._sControlId, '" href="javascript:void(0);" target="_self"', (!this.isEnabled() ? ' tabindex="-1"' : ''), '>', df.dom.encodeHtml(this.psCaption), '</a>');
        } else {
            aHtml.push('<button id="', this._sControlId, '"', (!this.isEnabled() ? ' disabled="disabled"' : ''), '>', df.dom.encodeHtml(this.psCaption), '</button>');
        }
    }

    /*
    This method is called after the HTML is added to the DOM and provides a hook for doing additional implementation. It gets references to the DOM elements, adds event handlers and executes setters t
    
    @private
    */
    afterRender() {
        //  Get references
        this._eControl = df.dom.query(this._eElem, "button, a");


        super.afterRender();

        //  Attach listeners
        df.dom.on("click", this._eControl, this.onBtnClick, this);
        df.events.addDomKeyListener(this._eElem, this.onKey, this);
    }


    /*
    Event handler for the OnClick event of the button. 
    
    @param  oEvent  Event object (df.events.DOMEvent).
    @private
    */
    onBtnClick(oEvent) {
        if (this.isEnabled()) {
            if (this._oPnl && this._oPnl.pbVisible) {
                this.hideMenu();
            } else {
                this.showMenu();
            }
            oEvent.stop();
        }
    }

    /* 
    Shows the menu by showing the floating panel.
    */
    showMenu() {

        if (!this._oPnl) {    // Create the WebFloatingPanel and WebMenuList controls if they don't exist yet
            const oPnl = this._oPnl = new WebFloatingPanel(null, this);
            oPnl.psFloatByControl = this.getLongName();
            oPnl.piWidth = this.piMenuWidth || 150;
            oPnl.piColumnCount = 1;
            oPnl.psCSSClass = "WebMBPanel " + this.psMenuCSSClass;
            oPnl.pbHideOnBlur = this.pbHideOnBlur;
            oPnl.piHeight = this.piMenuHeight;
            oPnl.create();

            const oMnu = this._oMenuList = new WebMenuList(null, this);
            oMnu._oMenuBtn = this;
            oMnu.psGroupName = this.psGroupName;
            oMnu.pbFillHeight = (this.piMenuHeight > 0);
            oMnu.pbShowCaption = this.pbMenuShowCaption;
            oMnu.pbShowIcons = this.pbMenuShowIcons;
            oMnu.psRootCaption = this.psMenuRootCaption;
            oMnu.pbAllowHtml = this.pbAllowHtml;
            oMnu.create();

            oPnl.addChild(oMnu);

            const ePnl = oPnl.render();
            if (ePnl) {
                this._eElem.parentNode.insertBefore(ePnl, this._eElem);
            }
            oPnl.afterRender();
            oPnl.resizeHorizontal();
            oPnl.resizeVertical();
        } else if (this.pbOpenOnRoot) {
            this._oMenuList.collapseAll();
        }

        this._oPnl.show();
    }

    /* 
    Hides the menu by hiding the floating panel.
    */
    hideMenu() {
        this._oPnl.hide();
    }

    /* 
    @client-action
    */
    collapseAll() {
        this._oMenuList?.collapseAll();
    }

    /* 
    @client-action
    */
    levelUp() {
        this._oMenuList?.levelUp();
    }

    /*
    Setter method for psCaption which is the text shown on the button.
    
    @param  sVal    The new value.
    */
    set_psCaption(sVal) {
        if (this._eControl) {
            df.dom.setText(this._eControl, sVal);
            this.sizeChanged();
        }
    }

    /* 
    Augment the setter for the psGroupName as the WebMenuButton uses the menu group system internally. 
    It makes sure that it either uses the supplied group name or it uses an internally generated 
    groupname if the new value is empty.
    
    @param  sVal    The new value
    @private
    */
    set_psGroupName(sVal) {
        this._sRealgroupName = sVal;

        //  The menu button uses the menu group system internally so it generates a custom menu group name if none is specified.
        if (!sVal) {
            sVal = this.psGroupName = "_WebMenuButtonGrp_" + df.dom.genDomId().toString();
        }
        if (this._oMenuList) {
            this._oMenuList.set("psGroupName", sVal);
        }
        super.set_psGroupName(sVal);

        return false;   //  Make sure that set doesn't alter the value
    }

    /* 
    Override the psGroupName logic hiding the internal usage of the group logic.
    
    @private
    */
    get_psGroupName() {
        //  Override to return the real name
        return this._sRealgroupName;
    }

    set_pbMenuShowCaption(bVal) {
        if (this._oMenuList) {
            this._oMenuList.set("pbShowCaption", bVal);
        }
    }

    set_pbMenuShowIcons(bVal) {
        if (this._oMenuList) {
            this._oMenuList.set("pbShowIcons", bVal);
        }
    }

    set_psMenuRootCaption(bVal) {
        if (this._oMenuList) {
            this._oMenuList.set("psRootCaption", bVal);
        }
    }

    set_psMenuCSSClass(sVal) {
        if (this._oPnl) {
            this._oPnl.set("psCSSClass", "WebMBPanel " + sVal);
        }
    }

    set_piMenuWidth(iVal) {
        if (this._oPnl) {
            this._oPnl.set("piWidth", iVal);
        }
    }

    set_piMenuHeight(iVal) {
        if (this._oPnl) {
            this._oMenuList.set("pbFillHeight", (iVal > 0));
            this._oPnl.set("piHeight", iVal);
        }
    }

    set_pbHideOnBlur(iVal) {
        if (this._oPnl) {
            this._oPnl.set("pbHideOnBlur", iVal);
        }
    }

    set_pbAllowHtml(iVal) {
        if (this._oMenuList) {
            this._oMenuList.set("pbAllowHtml", iVal);
        }
    }

    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eControl) {
            this._eControl.disabled = !bVal;
        }
    }

    /*
    Handles the onKey event and makes sure that it doesn't propagate the enter key to stop the onsubmit 
    event of the view / dialog.
    
    @param  oEvent  Event object (see: df.events.DOMEvent).
    @private
    */
    onKey(oEvent) {
        //  Make sure that the OnSubmit doesn't fire by canceling the propagation (but leaving the default behavior, OnClick intact)
        if (oEvent.matchKey(df.settings.formKeys.submit)) {
            oEvent.stopPropagation();
        }
    }

    resize() {
        if (this._oPnl) {
            this._oPnl.resize();
        }
    }

    /* 
    Augment destroy to also destroy standalone controls used by the button.
    
    @private
    */
    destroy() {
        if (this._oPnl) {
            this._oPnl.destroy();
        }

        super.destroy();
    }
}