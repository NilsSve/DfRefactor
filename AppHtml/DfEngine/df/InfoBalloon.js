/*
Class:
    df.InfoBalloon
Extends:
    Object

This class can show an info balloon next to a control to display errors or additional information. 
This info balloon consists of a simple div element that is positioned by the class next to the 
element. Used to display errors (WebBaseDEO.showControlError) and custom info balloons 
(WebBaseControl.showInfoBalloon).
    
Revision:
    2011/07/04  (HW, DAW) 
        Initial version.
    2013/12/10  (HW, DAW)
        Refactored from WebTooltip into InfoBalloon. Simplified so it doesn't inherit from WebObject
        any more (which wasn't needed).
*/
/* global df */
export class InfoBalloon {
    constructor(oControl, sCssClass, sMessage) {
        this.psMessage = sMessage;
        this.piHideDelay = 6000;
        this.pbShowOnHover = true;
        this.psCSSClass = sCssClass;

        this.poTarget = oControl;

        this._eElem = null;
        this._eEventElem = null;
        this._eParentRef = null;
        this._bFirstPos = true;
        this._bTopTooltip = false;
        this._tHideTimeout = null;
        this._tPositionInterval = null;

    }

    update() {
        if (this._eElem) {
            this._eElem.innerHTML = this.psMessage;
            this._eElem.className = "WebInfoBalloon " + this.psCSSClass;

            //  Reset position
            this._eElem.style.bottom = "";
            this._eElem.style.top = "";
            this._eElem.style.left = "";

            //  Recalculate position (from scratch)
            this._bTopTooltip = false;
            this._bFirstPos = true;
            this.position();
        }
    }

    init() {
        const eTarget = this.getTargetElem();

        if (!this._eElem && eTarget) {
            //  Create elem
            this._eElem = df.dom.create('<div class="WebInfoBalloon WebInfoBalloonHidden ' + this.psCSSClass + '"></div>');
            this._eElem.innerHTML = this.psMessage;

            //  Insert
            const eParent = this.poTarget?.topLayer() || document.body;
            eParent.appendChild(this._eElem);

            this._bTopTooltip = false;
            this._bFirstPos = true;
            this.position();

            if (this.pbShowOnHover) {
                df.dom.on("mouseover", eTarget, this.onMouseOver, this);
                df.dom.on("mouseout", eTarget, this.onMouseOut, this);
                this._eEventElem = eTarget;
            }
        }
    }

    /* 
    Remove DOM elements and clear event handlers when destroying the object.
    
    @private
    */
    destroy() {
        if (this._eElem && this._eElem.parentNode) {
            this._eElem.parentNode.removeChild(this._eElem);
        }
        this._eElem = null;
    }

    show() {
        if (!this._eElem) {
            this.init();
        } else {
            //  Make sure we are the last child in the container..
            if (this._eElem.parentNode.lastChild !== this._eElem) {
                this._eElem.parentNode.appendChild(this._eElem);
            }
        }
        this._show();
        this.setTimeout();
    }

    _show() {
        const that = this;

        if (this._eElem) {
            // this.position();
            // this._eElem.style.visibility = "visible";
            df.dom.addClass(this._eElem, "WebInfoBalloonVisible");
            df.dom.removeClass(this._eElem, "WebInfoBalloonHidden");

            if (!this._tPositionInterval) {
                this._tPositionInterval = setInterval(function () {
                    that.position();
                }, 300);
            }
        }
    }



    getTargetElem() {
        let eElem = this.poTarget._eElem;

        if (this.poTarget.getTooltipElem) {
            eElem = this.poTarget.getTooltipElem() || eElem;
        }

        return eElem;
    }

    hide() {
        const eElem = this._eElem;

        if (this._eElem) {
            this._hide();

            if (this._eEventElem) {
                df.dom.off("mouseover", this._eEventElem, this.onMouseOver, this);
                df.dom.off("mouseout", this._eEventElem, this.onMouseOut, this);
                this._eEventElem = null;
            }

            if (this._tHideTimeout) {
                clearTimeout(this._tHideTimeout);
                this._tHideTimeout = null;
            }


            setTimeout(function () {
                if (eElem.parentNode) {
                    eElem.parentNode.removeChild(eElem);
                }
            }, 3000);
            this._eElem = null;
        }
    }

    _hide() {
        if (this._eElem) {
            // this._eElem.style.visibility = "hidden";
            df.dom.addClass(this._eElem, "WebInfoBalloonHidden");
            df.dom.removeClass(this._eElem, "WebInfoBalloonVisible");
        }

        if (this._tPositionInterval) {
            clearInterval(this._tPositionInterval);
            this._tPositionInterval = null;
        }

    }

    position() {
        let iTop = 0, iLeft = 0;

        const eTarget = this.getTargetElem(); //  The element to position next
        const eTool = this._eElem;    //  The tooltip

        if (eTool && eTarget) {
            const iScreenWidth = df.dom.windowWidth();

            if (!df.sys.gui.isOnScreen(eTarget)) {
                eTool.style.display = "none";
                return;
            } else {
                eTool.style.display = "";
            }

            //    Calculate offsets using bounding rectangles (this is better when the content is scrolled)
            const oRectT = df.sys.gui.getBoundRect(eTarget);

            iTop = oRectT.top + oRectT.height;
            iLeft = oRectT.left + Math.max(Math.round((oRectT.width - 70) / 2), 0);

            //  Calculate width & height of the tooltip
            const iHeight = eTool.clientHeight + df.sys.gui.getVertBoxDiff(eTool);
            const iWidth = eTool.clientWidth + df.sys.gui.getHorizBoxDiff(eTool);
            //  Calculate the bottom coordiante
            const iBottom = iTop + eTarget.offsetHeight;

            if (this._bFirstPos) {
                //  Determine if we should make it a top balloon (we do that if there is not enough space below and enough space above)
                if (screen.height < (iTop + iHeight) && screen.height > (iBottom + iHeight)) {
                    this._bTopTooltip = true;
                    df.dom.addClass(this._eElem, "WebInfoBalloon_Top");
                }
                this._bFirstPos = false;
            }

            //  Optionally move it to the left if it is too wide (but rely on wrapping)
            if (iScreenWidth < iLeft + iWidth) {
                iLeft = Math.max(oRectT.left - 10, 0);
            }

            //  Position on top or at the bottom
            if (this._bTopTooltip) {
                eTool.style.bottom = iBottom + "px";
            } else {
                eTool.style.top = iTop + "px";
            }
            eTool.style.left = iLeft + "px";

        }
    }

    setTimeout() {
        const that = this;
        if (this.piHideDelay > 0) {
            if (this._tHideTimeout) {
                clearTimeout(this._tHideTimeout);
            }
            this._tHideTimeout = setTimeout(function () {
                that._hide();
            }, this.piHideDelay);
        }
    }

    /*
    Handles the mouseover event of the element. It displays the balloon.
    
    @param  oEvent  Event object.
    @private
    */
    onMouseOver(oEvent) {
        this._show();

        if (this._tHideTimeout) {
            clearTimeout(this._tHideTimeout);
            this._tHideTimeout = null;
        }
    }

    onMouseOut(oEvent) {
        this.setTimeout();
    }

    resize() {
        this.position();
    }
}