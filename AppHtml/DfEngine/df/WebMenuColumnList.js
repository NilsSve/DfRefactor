import { WebMenuColumnBase } from './WebMenuColumnBase.js';
import { WebMenuItemCheckbox } from './WebMenuItemCheckbox.js';
import { df } from '../df.js';

/*
Class:
    df.WebMenuColumnList
Extends:
    df.WebMenuColumnBase

This menu item can only be used when in a Context menu and attached to a cWebList.
It retrieves the columns and renders them to be hidden and/or shown.
    
Revision:
    2023/01/31  (BN, DAW) 
        Initial version.
*/
export class WebMenuColumnList extends WebMenuColumnBase {
    constructor(sName, oParent) {
        super(sName, oParent);

        this._iAddedColums = 0;
    }

    /* 
    Initializes the modules that make the WebList component.
    */
    afterRender() {
        super.afterRender();

        let oL = this.getList();
        if (!oL) {
            throw new df.Error(999, "WebMenuColumnList could not find it's WebList.", this);
        }

        this.refreshColumnList();
        oL._oHeader?.registerMenuColumnList(this);
    }

    refreshColumnList() {
        if (this._iAddedColums) {
            while (this._iAddedColums) {
                this._aChildren[0].destroy();
                this._aChildren.splice(0, 1);
                this._iAddedColums--;
            }
        }

        const oL = this.getList();
        if (!oL) {
            throw new df.Error(999, "WebMenuColumnList could not find it's WebList.", this);
        }
        let iColumnCount = oL._aColumns.length;
        for (let i = 0; i < iColumnCount; i++) {
            if (!oL._aColumns[i].pbRender || oL._aColumns[i].psCaption.length === 0) continue;

            let oItem = new WebMenuItemCheckbox(null, this);
            oItem.psCaption = oL._aColumns[i].psCaption;
            oItem.pbChecked = oL._aColumns[i].pbHidden == false;
            oItem.pbEnabled = oL._aColumns[i].pbHideable;
            oItem._oColumnRef = oL._aColumns[i];
            oItem.create();

            oItem.OnClick.on(function (oEv) {
                if (!this._oColumnRef.pbHideable) {
                    oEv.stop();
                    return;
                }

                let aFilteredVisible = oL._aColumns.filter(function (oCol) {
                    return oCol.pbRender && !oCol.pbHidden && oCol.psCaption.length !== 0;
                });

                if (aFilteredVisible.length <= 1) {
                    // We want atleast one visible column. Undo hide.
                    this.set_pbChecked(true);
                    this._oColumnRef.set_pbHidden(false);
                } else {
                    // Set the checked state and hidden state tot the opposite.
                    this.set_pbChecked(!this._oColumnRef.pbHidden);
                    this._oColumnRef.set_pbHidden(!this._oColumnRef.pbHidden);
                }

                oL.triggerLayoutChange(this._oColumnRef);

                oEv.stop();
            }, oItem);

            // Add it to the WebObjects
            this._aChildren.splice(this._iAddedColums++, 0, oItem);
        }

        this.getProv().refreshMenu();
    }

    addChild(oChild) {
        super.addChild(oChild);
        this.getProv().refreshMenu();
    }
}
df.WebMenuColumnList = WebMenuColumnList;