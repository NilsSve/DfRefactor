import { WebCard } from './WebCard.js';
/*
Class:
    df.WebTabPage
Extends:
    df.WebCard

This class represents a page within a tab container. The main functionality is available in the 
WebCard class. The tab page is a container that contains controls and its tab button is rendered by 
the tab container.
    
Revision:
    2011/10/13  (HW, DAW) 
        Initial version.
    2012/10/02  (HW, DAW)
        Split into WebCard and WebTabPage.
*/
export class WebTabPage extends WebCard {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Configure super classes
        this._sControlClass = "WebTabPage";
        this._bCC = true; //  Used by the designer to filter cardcontainers from tab / accordion containers
    }
}