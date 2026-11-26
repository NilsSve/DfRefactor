import { WebMenuColumnBase  } from './WebMenuColumnBase.js';
import { df } from '../df.js';

/*
Class:
    df.WebMenuColumnRestorer
Extends:
    df.WebMenuColumnBase

This class provides basic behaviour for restoring a columnlayout on click.
It is only supposed to be used in context with a cWeblist.
    
Revision:
    2023/01/31  (BN, DAW) 
        Initial version.
*/
export class WebMenuColumnRestorer extends WebMenuColumnBase {
    constructor(sName, oParent) {
        super(sName, oParent);
    }

    /* 
    Initializes the modules that make the WebList component.
    */
    afterRender() {
        super.afterRender();

        let oL = this.getList();
        if (!oL) {
            throw new df.Error(999, "WebMenuColumnRestorer could not find it's WebList.", this);
        }
        oL._oHeader?.registerMenuColumnRestorer(this);
    }

    itemClick(tItem, fReturn, oEnv) {
        let oL = this.getList();
        if (!oL) {
            throw new df.Error(999, "WebMenuColumnList could not find it's WebList.", this);
        }
        oL.triggerRestoreColumnLayout(this);
        return super.itemClick(tItem, fReturn, oEnv);
    }

    addChild() {
        throw new df.Error(999, "a cWebMenuColumnRestorer is not supposed to have children.", this);
    }
};