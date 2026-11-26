import { WebMenuItem } from './WebMenuItem.js';
import { WebContextMenu } from './WebContextMenu.js';
import { WebList } from './WebList.js';
import { df } from '../df.js';

/*
Class:
    df.WebMenuColumnBase
Extends:
    df.WebMenuItem

This class represents a base for menuitems to do with the weblist header contextmenu.
It provides interfaces for retrieving the cWebList Object etc.

Revision:
    2023/01/31  (BN, DAW) 
        Initial version.
*/
export class WebMenuColumnBase extends WebMenuItem {
    constructor(sName, oParent) {
        super(sName, oParent);

        // This is needed so that the WebContextMenu will send us an afterRender event.
        this._bProviderRequestAfterRender = true;
    }

    getList() {
        if (this._oList) {
            return this._oList;
        }

        if (!this.getProv()) {
            throw new df.Error(999, "cWebMenuColumnBase could not find it's parent WebContextMenu.", this);
        }
        if (!(this._oProv instanceof WebContextMenu)) {
            throw new df.Error(999, "cWebMenuColumnBase's provider should be a WebContextMenu.", this);
        }
        let oList = this._oProv._oRootControl;
        if (!(oList instanceof WebList)) {
            throw new df.Error(999, "Control-Referece/Parent of cWebMenuColumnBase should be a WebList/WebGrid.", this);
        }
        return this._oList = oList;
    }
};