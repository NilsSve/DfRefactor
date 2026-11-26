import { WebBaseContainer } from './WebBaseContainer.js';
import { WebList } from './WebList.js';
import { df } from '../df.js';

/*
Class:
    df.WebListExpandPanel

The expand panel renders an expandable panel inside a list that expands below a row. It can expand 
automatically or manually and can contain any type of control.

Revision:
    2018/01/10  (HW, DAW) 
        Initial version.
*/

df.wleManual = 0;                       // Manual                                  
df.wleOpenOnRowChange = 1;              // Always open on current row              
df.wleOpenOnRowClick = 2;               // Toggle on row click                     
df.wleOpenOnRowClickCloseOnChange = 3;   // Toggle on row click, close on row change
df.wleOpenOnRowDoubleClick = 4;
df.wleOpenOnRowDoubleClickCloseOnChange = 5;

export class WebListExpandPanel extends WebBaseContainer {
    constructor(sName, oPrnt) {
        super(sName, oPrnt);

        this.prop(df.tInt, "peMode", df.wleOpenOnRowClickCloseOnChange);
        this.prop(df.tBool, "pbShowLoading", false);
        this.prop(df.tString, "psExpandedRow", "");
        this.prop(df.tBool, "pbFocusOnShow", true);

        this.event("OnExpand", df.cCallModeDefault);
        this.event("OnCollapse", df.cCallModeDefault);

        this._sExpandedRow = null;
        this._bExpanding = false;
        this.OnAfterExpand = new df.events.JSHandler();

        //  Configure super classes
        this._sControlClass = "WebListExpPnl";
        this._bWrapDiv = true;


        this.addSync("psExpandedRow");

        //  Register on WebList
        if (oPrnt instanceof WebList) {
            this._oL = oPrnt;

            this._oL._onModulesCreated.addListener(this.onModulesCreated, this);
        } else {
            throw new df.Error(999, "WebListExpandPanel object '{{0}}' should be placed inside a WebList object.", this, [this.getLongName()]);
        }
    }

    /* 
    Event triggered by the weblist after the modules (model, view, controller) are created so we can 
    attach our listeners.
    
    @param  oEv     Event object.
    */
    onModulesCreated(oEv) {
        //  Register to receive render events
        this._oL._oBody.onRowsRendered.addListener(this.onRowsRendered, this);

        //  Register to receive click events
        this._oL._oController.onCellClick.addListener(this.onCellClick, this);
        this._oL._oController.onCellDblClick.addListener(this.onCellDblClick, this);

        //  Register to receive row change events
        this._oL._oModel.onRowChange.addListener(this.onRowChange, this);
    }

    /* 
    Event triggered by the list controller object when a cell is clicked. 
    
    @param  oEv     Event object.
    */
    onCellClick(oEv) {
        if (this.peMode == df.wleOpenOnRowClick || this.peMode == df.wleOpenOnRowClickCloseOnChange) {
            if (this._sExpandedRow == oEv.sRowId) {
                this.collapse();
            } else {
                this.expand(oEv.sRowId);
            }
        }
    }

    /* 
    Event triggered by the list controller object when a cell is double clicked. 
    
    @param  oEv     Event object.
    */
    onCellDblClick(oEv) {
        if (this.peMode == df.wleOpenOnRowDoubleClick || this.peMode == df.wleOpenOnRowDoubleClickCloseOnChange) {
            if (this._sExpandedRow == oEv.sRowId) {
                this.collapse();
            } else {
                this.expand(oEv.sRowId);
            }
        }
    }

    /* 
    Handles to the onRowChange event fired by the weblist and depending on peMode it will expand the 
    panel (or not).
    
    Depends on event properties:
        sPrevRowId
        sGotoRowId
    */
    onRowChange(oEv) {
        if (this.peMode == df.wleOpenOnRowChange) {
            if (this._sExpandedRow !== oEv.sGotoRowId) {
                this.expand(oEv.sGotoRowId);
            }
        } else if (this.peMode == df.wleOpenOnRowClickCloseOnChange || this.peMode == df.wleOpenOnRowDoubleClickCloseOnChange) {
            if (this._sExpandedRow !== oEv.sGotoRowId) {
                this.collapse();
            }
        }
    }

    afterRender() {
        super.afterRender();

        df.dom.on("focusin", this._eElem, this.onFocus, this);
        df.dom.on("click", this._eElem, this.onClick, this);

        /* Stop propagation of several events */
        df.dom.on("keydown keypress", this._eElem, function (oEv) {
            oEv.stopPropagation();
        }, this);
    }

    onFocus(oEv) {
        oEv.stop();
    }

    onClick(oEv) {
        oEv.stop();
    }

    /* 
    Collapses the panel. The animation is done using a transition
     cloning the DOM elements (with event handlers and JS 
    refs) because the actual elements might immediately be used by the next expand operation. 
    
    @client-action
    */
    collapse() {
        const oV = this._oL._oBody;
        let eGhost;

        //  Handler for when the animation is finished (cleanup)
        function colTransEnd(oEv) {
            if (eGhost.parentNode) {
                eGhost.parentNode.removeChild(eGhost);
            }

            df.dom.off("transitionend", eGhost, colTransEnd, this);
        }

        if (this._sExpandedRow) {
            this.fire("OnCollapse");

            //  If the panel is visible we make a copy (ghost) that we animate using maxHeight
            if (this._eElem.parentNode) {
                eGhost = this._eElem.cloneNode(true);

                //  Change the names of all input elements to prevent them disturbing the orriginals (radio selected values getting lost)
                df.dom.query(eGhost, "input", true).forEach(function (eEl) {
                    eEl.name = eEl.name + "_1";
                });

                eGhost.style.height = this._eElem.scrollHeight + "px";
                this._eElem.parentNode.insertBefore(eGhost, this._eElem);
                this._eElem.parentNode.removeChild(this._eElem);

                //  Wait two animation frames to be consistent with expanding which might happen at the same time..
                df.dom.animFrame(function () {
                    df.dom.animFrame(function () {
                        df.dom.on("transitionend", eGhost, colTransEnd, this);

                        df.dom.addClass(eGhost, "WebLEP_Hidden");
                        df.dom.removeClass(eGhost, "WebLEP_Visible");
                        eGhost.style.height = "0px";
                    }, this);
                }, this);
            }

            //  Make sure to apply the hidden CSS to the actual panel elem so it is prepared to be reinserted somewhere else
            df.dom.addClass(this._eElem, "WebLEP_Hidden");
            df.dom.removeClass(this._eElem, "WebLEP_Visible");
            // this._eElem.style.height = "1px";

            oV.setExtraRowHeight(this._sExpandedRow, 0);

            this._sExpandedRow = null;

            this.afterHide();
        }
    }

    /*
    Expands the panel on the specified row. It first collapses it if it was already expanded on a 
    different row. Animates using a transition on the height.
    
    @param  sRowId  RowId of the row to expand on.
    @client-action
    */
    expand(sRowId) {
        const oV = this._oL._oBody;
        let ePnl;

        //  Collapse row if needed
        if (this._sExpandedRow) {
            this.collapse();
        }

        //  Handler for when the animation is finished
        function expTransEnd(oEv) {
            ePnl.style.height = null;
            this._bExpanding = false;
            df.dom.off("transitionend", ePnl, expTransEnd, this);
            this.afterShow();
        }

        const eRow = oV.row(sRowId);

        if (eRow) {
            //  Initialize and insert the panel DOM
            if (!this._eElem) {
                this.render();
                df.dom.addClass(this._eElem, "WebLEP_Hidden");
                this._eElem.style.display = "none";     //  Display none first to force browser to do better calcs
                df.dom.insertAfter(this._eElem, eRow);
                this.afterRender();
            } else {
                this._eElem.style.display = "none";     //  Display none first to force browser to do better calcs
                df.dom.insertAfter(this._eElem, eRow);
            }
            ePnl = this._eElem;

            if (this.pbShowLoading) {
                df.dom.addClass(ePnl, "WebCon_Loading");
            }
            this.fire("OnExpand", [sRowId], function (oEv) {
                df.dom.removeClass(ePnl, "WebCon_Loading");
            }, this);

            //  Size
            this.resizeHorizontal();
            this.resizeVertical();

            this._sExpandedRow = sRowId;

            if (this.pbFocusOnShow) {
                this.focus();
            }

            //  First frame we run with element there without height of 0 (display none) so the browser does a better job of calculating positions
            df.dom.animFrame(function () {
                df.dom.on("transitionend", ePnl, expTransEnd, this);

                ePnl.style.height = "0px";
                ePnl.style.display = "";

                //  In the second frame we do the actual calculation
                df.dom.animFrame(function () {
                    var iHeightTo;

                    if (this.piHeight > 0) {
                        iHeightTo = this.piHeight + this.getHeightDiff(false, true, false, false);
                    } else {
                        iHeightTo = ePnl.scrollHeight; // Math.max(this._eContent.offsetHeight + this.getHeightDiff(false, true, true, true), this.piMinHeight);
                    }
                    ePnl.style.height = iHeightTo + "px";

                    df.dom.addClass(ePnl, "WebLEP_Visible");
                    df.dom.removeClass(ePnl, "WebLEP_Hidden");
                    this._bExpanding = true;

                    oV.setExtraRowHeight(sRowId, iHeightTo);
                    oV.scrollToRow(sRowId);
                }, this);
            }, this);
        }
    }

    /* 
    Triggered by the list view when rows are rendered. If a row is expanded we check if that element is 
    still in the DOM, if not we check if the expanded row is checked so we can insert it.
    
    @param  oEv     Event object.
    */
    onRowsRendered(oEv) {
        if (this._sExpandedRow && this._eElem) {
            if (!this._eElem.parentNode) {
                const oV = this._oL._oBody;

                const eRow = oV.row(this._sExpandedRow);

                if (eRow) {
                    df.dom.insertAfter(this._eElem, eRow);
                }
            }
        }
    }

    get_psExpandedRow() {
        return this._sExpandedRow || "";
    }

    resize() {
        this.resizeHorizontal();
        this.resizeVertical();
    }

    setInnerHeight(iHeight) {

        super.setInnerHeight(iHeight);

        /* if(iHeight > 0 && this._bExpanding){
            this._eElem.style.maxHeight = iHeight + "px";
    
        } */
    }
};