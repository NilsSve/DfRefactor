import { WebMenuItem } from './WebMenuItem.js';
import { df } from '../df.js';

/*
Class:
    df.WebMenuItemCheckbox
Extends:
    df.WebMenuItem

This class represents a static menu item. These menu item doesn’t have any rendering logic which is 
in the menu classes. Through a system with a menu hub, menu listeners and menu providers the menu 
classes know which items it needs to render. This item contains a pbChecked property and through proxy is rendered.
    
Revision:
    2021/10/13  (BN, DAW)
        Initial Version.
*/

export class WebMenuItemCheckbox extends WebMenuItem {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tBool, "pbChecked", false);
        this.addSync("pbChecked");
    }

    /* 
    Called by a menu engine when this menu item is clicked. It triggers the OnClick event and if needed 
    performs a load view (psLoadViewOnClick).
    */
    itemClick(tItem, fReturn, oEnv) {
        if (tItem.hRef) {
            tItem.hRef.set_pbChecked(!tItem.hRef.isChecked());
        }
        return super.itemClick(tItem, fReturn, oEnv);
    }

    /*
    This function returns whether the object is checked.
    Do mind that this does not keep in mind the fact,
    That if the object does not have the property it always indicates false.
    */
    isChecked() {
        return this.pbChecked === true;
    }

    //  - - - Setters - - - 

    /*
    This setter method updates the DOM with the new checked state for a cWebMenuCheckbox.
    
    @param  bVal   The new value.
    @private
    */
    set_pbChecked(bVal) {
        this.pbChecked = bVal;
        this.notifyChange();
    }

}