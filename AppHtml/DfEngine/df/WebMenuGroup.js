import { WebMenuProvider_mixin } from './WebBaseMenu.js';
import { WebObject } from './WebObject.js';

/* 
Class:
    df.WebMenuGroup
Extends:
    df.WebObject
Mixins:
    df.WebMenuProvider_mixin

This class represents the WebMenuGroup which is a provider class for the menu system. This means 
that it providers menu items to listeners of the menu system that render the menu. The WebMenuGroup 
is only a provider so it doesn�t render anything and is used to place menu�s in a separate place as 
where they are rendered. It has special logic so that if it is placed inside a view it will 
deactivate itself (unregister from the menu hub) if the view is not visible.

Revisions:
    2015/01/16  HW (DAW)
        Created the initial version.
*/
class WebBaseMenuGroup extends WebMenuProvider_mixin(WebObject) { } //df.mixin("df.WebMenuProvider_mixin", "df.WebObject");

export class WebMenuGroup extends WebBaseMenuGroup {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this._bActive = false;
    }

    /* 
    During creation we determine if we are inside a view, if so we register ourself as listeners to 
    OnShow and OnHide allowing the group to activate / deactivate itself with the view. Else we forward 
    we activate immediately.
    
    @private
    */
    create() {
        //  Check if we are in a view, if so we listen to its OnShow and OnHide events, else we just start it
        const oView = this.getView();
        if (oView) {
            oView.OnShow.addListener(this.showView, this);
            oView.OnHide.addListener(this.hideView, this);
        } else {
            this._bActive = true;
            super.create();
        }
    }


    /* 
    Handles the OnShow event of the view. We activate ourselves as provider to the menu grouphub to 
    update the listeners with our menu items.
    
    @param  oEvent      Event object (df.events.JSEvent).
    */
    showView(oEvent) {
        this._bActive = true;

        if (this.psGroupName) {
            this.getHub().addProvider(this.psGroupName, this);
        }
    }


    /*
    Handles the OnHide event of the view. We deactivate by unregistering as provider for the menu 
    grouphub.
    
    @param  oEvent      Event object (df.events.JSEvent).
    */
    hideView(oEvent) {
        this._bActive = false;

        if (this.psGroupName) {
            this.getHub().remProvider(this.psGroupName, this);
        }
    }

    /* 
    Intercepts the set of the psGroupName and only forwards if we are active making sure that it doesn't 
    register while it shouldn't.
    
    @param  sVal    The new value.
    */
    set_psGroupName(sVal) {
        if (this._bActive) {
            super.set_psGroupName(sVal);
        }
    }
}