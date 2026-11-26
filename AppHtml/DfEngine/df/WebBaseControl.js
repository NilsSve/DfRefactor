import { WebBaseUIObject } from './WebBaseUIObject.js';
/* globals df */
/* 
Class:
    df.WebBaseControl
Extends:
    df.WebBaseUIObject

The WebBaseControl defines the API for all controls that participate within the column flow layout 
system. This makes it one of the core classes of the framework. It defines properties like 
piColumnIndex and piColumnSpan and has the API for setting the height of the controls. It can 
generate the wrapping DOM elements (several DIV�s) that almost all controls need where subclasses 
will usually fill these. As every control supports a label this class also generates and positions 
the label.

Revisions:
    2011/08/02 (HW, DAW)
        Initial version.
*/

export class WebBaseControl extends WebBaseUIObject {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tInt, "piColumnIndex", 0);
        this.prop(df.tInt, "piColumnSpan", 1);

        this.prop(df.tInt, "piRowSpan", 1);
        this.prop(df.tInt, "piRowIndex", 0);

        this.prop(df.tBool, "pbShowLabel", true);
        this.prop(df.tString, "psLabel", "");
        this.prop(df.tInt, "peLabelPosition", 0);
        this.prop(df.tInt, "peLabelAlign", -1);
        this.prop(df.tInt, "piLabelOffset", -1);
        this.prop(df.tString, "psLabelColor", "");

        this.prop(df.tString, "psToolTip", "");

        this.prop(df.tBool, "pbFillHeight", false);
        this.prop(df.tInt, "piHeight", -1);
        this.prop(df.tInt, "piMinHeight", 0);

        this.event("OnFocus", df.cCallModeDefault);
        this.event("OnBlur", df.cCallModeDefault);

        //  @privates
        this._eInner = null;
        this._eLbl = null;
        this._eControlWrp = null;
        this._eControl = null;

        this._oInfoBalloon = null;
        this._oObserver = null;

        this._sControlId = df.dom.genDomId();

        //  Configure super classes
        this._bFocusAble = true;
        this._bHasFocus = false;
        this._sBaseClass = "WebControl";
        /*
        Determines if this control needs setHeight to be called to stretch to the full cell height in
        grid layout mode with pbFillHeight set to true. Defaults to true for compatiblity.
        */
        this._bJSSizing = true;
    }

    openHtml(aHtml) {
        //  Outermost div for positioning by parent, inner div for margins / paddings
        aHtml.push('<div class="', this.genClass(), '"');
        if (this.psHtmlId) {
            aHtml.push(' id="', this.psHtmlId, '"');
        }

        //  Insert the object name so the HTML element can be traced back to the right object
        aHtml.push(' data-dfobj="', this.getLongName(), '"');

        aHtml.push(' style=" ', (this.pbRender ? '' : 'display: none;'), (this.pbVisible ? '' : 'visibility: hidden;'), '"');
        aHtml.push('>');

        //  Optionally label
        if (this.pbShowLabel) {
            // aHtml.push('<div class="WebCon_Inner">');
            aHtml.push('<div class="WebCon_Inner ', (this.pbFillHeight ? 'WebCon_FillRow' : ''), '">');
            if (this.peLabelPosition != df.ciLabelRight) {
                aHtml.push(this.genLabelHtml());
            }
        } else {
            aHtml.push('<div class="WebCon_Inner ', (this.pbFillHeight ? 'WebCon_FillRow' : ''), '">');
        }

        //  Wrapper div for positioning of control
        aHtml.push('<div>');
    }

    /*
    Augment genClass to add the Web_FillHeight CSS class based on pbFillHeight.
    */
    genClass() {
        return super.genClass() + (this.pbFillHeight ? " Web_FillHeight" : "") + (this._bJSSizing ? " Web_JS_Sizing" : "");
    }

    closeHtml(aHtml) {
        aHtml.push('</div>');

        if (this.pbShowLabel && this.peLabelPosition == df.ciLabelRight) {
            aHtml.push(this.genLabelHtml());
        }

        aHtml.push('</div></div>');
    }

    genLabelHtml() {
        const aHtml = [];

        if (!df.sys.isMobile) {
            aHtml.push('<label for="', this._sControlId, '" class="', ((this.peLabelPosition == df.ciLabelFloat && this.psValue == '') ? 'WebCon_Unfloat' : 'WebCon_Float'), '" >', df.dom.encodeHtml(this.psLabel), '</label>');
        } else {
            aHtml.push('<label>', df.dom.encodeHtml(this.psLabel), '</label>');
        }

        return aHtml.join('');
    }

    afterRender() {
        //  Get references
        this._eInner = df.dom.query(this._eElem, "div.WebCon_Inner");
        this._eControlWrp = df.dom.query(this._eElem, "div.WebCon_Inner > div");
        if (this.pbShowLabel) {
            this._eLbl = df.dom.query(this._eElem, "div > label");
        }

        super.afterRender();
        if (this._eLbl) {
            df.dom.on("click", this._eLbl, this.onLblClick, this);
        }

        //  Call setters to apply properties
        this.posLabel(true);
        this.set_psLabelColor(this.psLabelColor);
        this.set_peLabelAlign(this.peLabelAlign);

        this.set_psToolTip(this.psToolTip);

        if (this._bJSSizing || this.piHeight > 0) {
            this.sizeHeight(-1);
        }

        if (this._oInfoBalloon) {
            this._oInfoBalloon.init();
            if (this._bShowInfoBallon) {
                this._oInfoBalloon.show();
            }
        }

        this.initObserver();
    }

    /*
    Augment to initialize size observer if nessecary.
    */
    afterShow() {
        super.afterShow();

        this.initObserver();
    }

    /*
    Augment to stop size observer if nessecary.
    */
    afterHide() {
        super.afterHide();

        this.destroyObserver();
    }

    /* 
    Augment destroy to destroy the infoballoon that might have been created.
    
    @private
    */
    destroy() {
        super.destroy();

        this._eLbl = null;
        this._eControlWrp = null;
        this._eInner = null;
        this._eControl = null;

        if (this._oInfoBalloon) {
            this._oInfoBalloon.destroy();
            this._oInfoBalloon = null;
        }

        this.destroyObserver();
    }


    /*
    Handler for the click event on the label. It calls the focus method to pass the focus to the 
    control. This is done manually here to emulate this behavior for controls with an artificial focus.
    
    @param  oEvent      DOM Event Object.
    @private
    */
    onLblClick(oEvent) {
        if (!df.sys.isMobile) {
            this.focus();
        }
    }



    set_psLabel(sVal) {
        if (this._eLbl) {
            if (!sVal) {
                sVal = " ";
            }
            df.dom.setText(this._eLbl, sVal);
        }
    }

    set_pbShowLabel(bVal) {
        this.pbShowLabel = bVal;

        this.posLabel(false);
        this.sizeChanged();
    }

    set_psLabelColor(sVal) {
        if (this._eLbl) {
            this._eLbl.style.color = sVal;
        }
    }

    set_peLabelAlign(iVal) {
        if (this._eLbl) {
            this._eLbl.style.textAlign = (iVal === df.ciAlignLeft ? "left" : (iVal === df.ciAlignCenter ? "center" : (iVal === df.ciAlignRight ? "right" : "")));
        }
    }

    set_piLabelOffset(iVal) {
        this.piLabelOffset = iVal;

        this.posLabel(false);
        this.sizeChanged();
    }

    set_peLabelPosition(iVal) {
        this.peLabelPosition = iVal;

        this.posLabel(false);
        this.sizeChanged();
    }

    set_psToolTip(sVal) {
        if (this._eControl) {
            this._eControl.title = sVal;
        }
    }

    set_piColumnIndex(iVal) {
        if (this.piColumnIndex !== iVal) {
            this.piColumnIndex = iVal;

            this.sizeChanged(true);
        }
    }

    set_piColumnSpan(iVal) {
        if (this.piColumnSpan !== iVal) {
            this.piColumnSpan = iVal;

            this.sizeChanged(true);
        }
    }

    set_psTextColor(sVal) {
        if (this._eControl) {
            this._eControl.style.color = sVal || '';
        }
    }

    set_psBackgroundColor(sVal) {
        if (this._eControl) {
            this._eControl.style.background = sVal || '';
            // this._eControl.style.backgroundColor = sVal || '';
            // this._eControl.style.backgroundImage = (sVal ? 'none' :'');
        }
    }

    set_piMinHeight(iVal) {
        if (this._eControl) {
            if (this.piMinHeight !== iVal) {
                this.piMinHeight = iVal;

                // Call sizing sytem to recalculate sizes
                this.sizeChanged();
            }
        }
    }

    set_piHeight(iVal) {
        if (this._eControl) {
            if (this.piHeight !== iVal) {
                this.piHeight = iVal;

                // Call sizing sytem to recalculate sizes
                this.sizeChanged();
            }
        }
    }

    set_pbFillHeight(bVal) {
        if (this._eControl) {
            df.dom.toggleClass(this._eElem, "Web_FillHeight", bVal);

            if (this.pbFillHeight !== bVal) {
                this.pbFillHeight = bVal;

                // Call sizing sytem to recalculate sizes
                this.sizeChanged(true);
            }

            this.initObserver();
        }
    }

    /*
    Initializes the ResizeObserver if nessecary. This allows us to listen to size changes in the grid so that
    our control can respond to that. In grid layout the grid determines the height of controls with pbFillHeight
    set to true. So the ResizeObserver is only created when this control is inside a grid layout and pbFillHeight
    is true and _bJSSizing is set to false.
    */
    initObserver() {
        if (this._bJSSizing && this.isInGridContainer() && this.pbFillHeight) {
            this.createObserver();
        } else {
            this.destroyObserver();
        }
    }

    /*
    Creates the size observer object.
    */
    createObserver() {
        if (!this._eElem || this._oObserver) return;

        this._oObserver = new ResizeObserver((entries) => {
            let nHeight = entries[0]?.contentRect.height;
            if (!nHeight) {
                nHeight = this._eElem.getBoundingClientRect()?.height || 0;
            }
            this.sizeHeight(nHeight);
        });

        this._oObserver.observe(this._eElem);
    }

    /*
    Destroys the size observer object.
    */
    destroyObserver() {
        if (this._oObserver) {
            this._oObserver.disconnect();
            this._oObserver = null;
        }
    }

    /**
     * Augment sizeChanged and perform a sizeHeight if we are not fill height. If we are fillheight the 
     * sizeHeight will be triggered via the resize logic of the container. The sizeHeight will recalculate 
     * internal control sizes if the control implements setHeight.
     * 
     * @param {Boolean} bPosition 
     */
    sizeChanged(bPosition) {
        if (this._eControl && !this.pbFillHeight) {
            this.sizeHeight(-1);
        }

        super.sizeChanged(bPosition);
    }

    sizeHeight(iExtHeight) {
        let iHeight = -1, bSense = false;

        //  Determine which height to use
        if (this.pbFillHeight) {
            iHeight = iExtHeight;

            bSense = iExtHeight > 0;
        } else if (this.piHeight > 0) {
            iHeight = this.piHeight;
            bSense = true;
        }

        //  Respect minimal height
        if (iHeight < this.piMinHeight) {
            iHeight = this.piMinHeight;

            bSense = bSense || !this.pbFillHeight;
        }

        //  Update the height
        this.setHeight(iHeight, bSense);

        //  Return the final height
        if (iHeight > 0) {
            return iHeight;
        }
    }

    /*
    Sets the height of the control taking margins, borders and the label into account.
    
    @param  iHeight     The height in pixels.
    @param  bSense      If false the size is expected to not be the final size.
    */
    setHeight(iHeight, bSense) {
        if (this._eControl) {
            //  If a negative value is given we should size 'naturalEly'
            if (iHeight > 0) {
                iHeight -= this.getVertHeightDiff();

                iHeight = (iHeight < 0 ? 0 : iHeight);  //  FIX: IE8 doesn't handle negative values real well and this seems to happen somehow

                //  Set the height
                this._eControl.style.height = iHeight + "px";
            } else {
                this._eControl.style.height = "";
            }

        }
    }

    /*
    Calculates the height difference that is substracted from the height before applied on _eControl. 
    It looks at the vertical box difference of several elements and the label.
    
    @return Number of pixels to substract from the height.
    @private
    */
    getVertHeightDiff() {
        let iResult = 0;

        //  If the label is on top we reduce that (note that this means that piMinHeight and piHeight are including the label)
        if ((this.peLabelPosition === df.ciLabelTop || this.peLabelPosition === df.ciLabelFloat) && this._eLbl) {
            iResult += this._eLbl.offsetHeight;
        }

        //  Substract the wrapping elements
        iResult += df.sys.gui.getVertBoxDiff(this._eInner);
        iResult += df.sys.gui.getVertBoxDiff(this._eControlWrp);
        iResult += df.sys.gui.getVertBoxDiff(this._eControl);

        return iResult;
    }

    /* 
    Updates the control its label based on the pbShowLabel, psLabel, peLabelPostion and piLabelOffset 
    properties. It will do this by setting CSS Classnames, calculating margins and removing / generating 
    the label element. This method is called by the setters of these properties.
    
    @private
    */
    posLabel(bFirst) {
        const iPos = this.peLabelPosition, iOffset = this.piLabelOffset;
        let sClass, sColumns = "", sRows = "";

        if (this._eElem) {
            //  Remove all label classes
            if (!bFirst) {
                df.dom.removeClass(this._eInner, "WebCon_HasLabel WebCon_TopLabel WebCon_RightLabel WebCon_LeftLabel");
            }

            if (!this.pbShowLabel) {
                //  Remove from the DOM
                if (this._eLbl) {
                    df.dom.off("click", this._eLbl, this.onLblClick, this);
                    this._eLbl.parentNode.removeChild(this._eLbl);
                    this._eLbl = null;
                }
            } else {
                //  Add to the DOM 
                if (!this._eLbl) {
                    if (!df.sys.isMobile) {
                        this._eLbl = df.dom.create('<label for="' + this._sControlId + '" class="' + ((this.peLabelPosition == df.ciLabelFloat && this.psValue == '') ? 'unfloat' : 'float') + '">&nbsp;</label>');
                    } else {
                        this._eLbl = df.dom.create('<label>&nbsp;</label>');
                    }

                    this.set_psLabel(this.psLabel);
                    this.set_psLabelColor(this.psLabelColor);
                    this.set_peLabelAlign(this.peLabelAlign);

                    this._eInner.insertBefore(this._eLbl, this._eInner.firstChild);

                    df.dom.on("click", this._eLbl, this.onLblClick, this);
                }
                if (!bFirst) {
                    df.dom.addClass(this._eInner, "WebCon_HasLabel");
                }

                //  Determine the classname and the required margin
                switch (iPos) {
                    case df.ciLabelLeft:
                        sClass = "WebCon_LeftLabel";
                        if (iOffset > 0) sColumns = `${iOffset}px minmax(0, 1fr)`;
                        break;
                    case df.ciLabelTop:
                        if (iOffset > 0) sRows = `${iOffset}px minmax(0, 1fr)`;
                        sClass = "WebCon_TopLabel";
                        break;
                    case df.ciLabelFloat:
                        sClass = "WebCon_TopLabel WebCon_FloatEnabled";
                        break;
                    case df.ciLabelRight:
                        sClass = "WebCon_RightLabel";
                        if (iOffset > 0) sColumns = `minmax(0, 1fr) ${iOffset}px`;
                        break;
                }

                //  Set CSS class on the inner div
                df.dom.addClass(this._eInner, sClass);
            }
            this._eInner.style.gridTemplateColumns = sColumns;
            this._eInner.style.gridTemplateRows = sRows;
        }
    }


    // - - - - - - - Information Balloon API - - - - - - - 
    /* 
    Used by the InfoBalloon class to determine where to align the info ballon on to.
    
    @private
    */
    getTooltipElem() {
        return this._eControlWrp;
    }

    /*
    Shows the info balloon with the provided CSS classname and content (html). 
    
    @param  sCssClass   The CSS classname applied to the balloon for styling.
    @param  sText       The HTML content displayed inside the balloon.
    @param  bShow       True if the the info balloon should be shown immediately
    @client-action
    */
    showInfoBalloon(sCssClass, sText, bShow) {
        bShow = df.toBool(bShow);

        if (this._oInfoBalloon) {
            this._oInfoBalloon.psCssClass = sCssClass;
            this._oInfoBalloon.psMessage = sText;
            this._oInfoBalloon.update();
        } else {
            this._oInfoBalloon = new df.InfoBalloon(this, sCssClass, sText);
        }
        if (this._eElem) {
            this._oInfoBalloon.init();

            if (bShow) {
                this._oInfoBalloon.show();
            }
        } else {
            this._bShowInfoBallon = bShow;
        }
    }

    /* 
    Hides the info balloon that is shown using showInfoBalloon.
    
    @client-action
    */
    hideInfoBalloon() {
        if (this._oInfoBalloon) {
            this._oInfoBalloon.hide();
        }
    }

    /*
    Implement the resize method to resize & reposition the info balloon (if displayed).
    */
    resize() {
        if (this._oInfoBalloon) {
            this._oInfoBalloon.resize();
        }

        this._aChildren.forEach(function (oC) {
            if (oC.resize) {
                oC.resize();
            }
        })
    }

    /**
     * @returns True if this control is located inside a container that uses the grid layout.
     */
    isInGridContainer() {
        return this._oParent?.isGridLayout?.();
    }

    // - - - - - - - - - Focus Handling - - - - - - - - - 
    focus() {
        if (this._bFocusAble && this.isEnabled() && this._eControl && this._eControl.focus) {
            try {
                this._eControl.focus();
            } catch (oErr) {

            }

            this.objFocus();
            return true;
        }

        return false;
    }

    attachFocusEvents() {
        //  Every major browser now supports focusin & focusout, so we don't need to capture
        df.dom.on("focusin", this._eElem, this.onFocus, this);
        df.dom.on("focusout", this._eElem, this.onBlur, this);
    }


    updateFocus(bFocus) {
        super.updateFocus(bFocus);

        df.dom.toggleClass(this._eElem, "WebCon_Focus", bFocus);

        if (bFocus) {
            this.fire("OnFocus");
        } else {
            this.fire("OnBlur");
        }

        this._bHasFocus = bFocus;
    }


}