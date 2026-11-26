import { WebWindow } from './WebWindow.js';
import { df } from '../df.js';

/*
Class:
    df.WebModalDialog
Extends:
    df.WebWindow

The modal dialog is basically a floating view that is modal. It is rendered as a window. The logic 
for making it floating and modal is in the WebWindow class so we keep the possibility to support MDI 
at some point in the future. Special functionality for the 'invoking view' is available in the class 
which is needed for the chained scope system.

Revision:
    2011/09/01  (HW, DAW) 
        Initial version.
*/
export class WebModalDialog extends WebWindow {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.event("OnEscape", df.cCallModeWait);

        this.pbFloating = true;
        this.pbModal = true;
        this.pbScroll = false;
        this.psFloatByControl = null;
    }

    /*
    This method will fire the OnEscape event. If this event is not handled it will close the dialog if 
    pbShowClose is true.
    */
    doClose() {
        if (!this.fire('OnEscape')) {
            super.doClose();
        }
    }

    /*
    Positions the modal dialog next to the object that is referenced in psFloatByControl.
    */
    floatByControl() {
        const oObj = this.getWebApp().findObj(this.psFloatByControl);
        const boundRect = df.sys.gui.getBoundRect(oObj._eElem);
        let oldPiTop, oldPiLeft;

        oldPiLeft = this.piLeft;
        oldPiTop = this.piTop;

        this.piTop = boundRect.bottom;
        this.piLeft = boundRect.left;

        //Attempt to float the modal dialog under the control
        this._eElem.style.top = this.piTop + "px";
        this._eElem.style.left = this.piLeft + "px";

        //If the modal dialog falls even slightly offscreen, default it back to the center of the screen
        if (!df.sys.gui.isElementFullyOnScreen(this._eElem)) {
            this.piTop = oldPiTop;
            this.piLeft = oldPiLeft;
            this._eElem.style.top = oldPiTop + "px";
            this._eElem.style.left = oldPiLeft + "px";
        };

    }

    /*
    Returns the 'top layer' element. This is the insertion point for controls like floating panels. 
    Usually this will return document.body, but for modal dialogs this is the dialog element, else 
    the floating panel would show behind the the dialog.
    */
    topLayer() {
        return this._eElem;
    }
}