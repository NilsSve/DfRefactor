import { WebListScrollingView } from './WebListScrollingView.js'
import { df } from '../df.js';
/*
Class:
    df.WebListFooterView

One of the view classes in the list its mini MVC model. It is responsible for rendering the footer 
and triggers click events on the controller. The WebList and WebListRowModel provide details needed 
to display the Footer.

Revision:
    2021/09/08  (BN, DAW) 
        Initial version.
*/
export class WebListFooterView {
    constructor(oList, oModel, oController) {
        this.oL = oList;
        this.oC = oController;
        this.oR = oList._oRowRenderer;
        this.oM = oModel;

        oList._onResize.on(this.onResize, this);
        oList._onSettingChange.on(this.onSettingChange, this);
        oList._onModulesCreated.on(this.onModulesCreated, this);
    }

    onModulesCreated(oEv) {
        const oV = this.oL._oBody;

        if (oV instanceof WebListScrollingView) {
            oV.onHorizontalScroll.on(this.onHorizontalScroll, this);
        }
    }

    genHtml(aHtml) {
        const oL = this.oL;
        aHtml.push('<div class="WebList_Footer WebList_Body"', (oL.pbShowFooter ? '' : ' style="display:none"'), '>');
        aHtml.push('<div class="WebList_FooterWrp WebList_BodyWrp', (oL.pbColumnsResizable ? ' WebList_ColResizable' : ''), (oL.pbAutoColumnSizing ? " WebList_AutoSize" : " WebList_HorizScroll"), '">');
        this.footerHtml(aHtml);
        aHtml.push('</div>');
        aHtml.push('</div>');
    }

    afterRender(eList) {
        this.eFooter = df.dom.query(eList, "div.WebList_Footer");
        this.eFooterWrp = df.dom.query(eList, "div.WebList_FooterWrp");
    }

    footerHtml(aHtml) {
        const oFooterRow = {
            aCells: [],
            sCssClassName: "",
            sRowId: "_WebList_Footer",
            iGroupHeaderIndex: -1,
            fCellClass(oCol, tCell) {
                const aClasses = [];

                aClasses.push(oCol._sCellClass);

                aClasses.push(df.CssDisabled);

                aClasses.push(oCol.peFooterAlign === df.ciAlignLeft ? "WebList_AlignLeft" : (oCol.peFooterAlign === df.ciAlignCenter ? "WebList_AlignCenter" : (oCol.peFooterAlign === df.ciAlignRight ? "WebList_AlignRight" : "")));

                if (oCol.peFooterDataType === df.ciTypeBCD) {
                    aClasses.push("dfData_BCD");
                } else if (oCol.peFooterDataType === df.ciTypeDate) {
                    aClasses.push("dfData_Date");
                } else {
                    aClasses.push("dfData_Text");
                }

                if (oCol.psCSSClass) {
                    aClasses.push(oCol.psCSSClass);
                }

                if (tCell && tCell.sCssClassName) {
                    aClasses.push(tCell.sCssClassName);
                }

                return aClasses.join(" ");
            },
            fCellHtml(sRowId, tCell) {
                let sVal = tCell.sValue;

                if (sVal.length === 0) return '&nbsp;';

                sVal = df.sys.data.serverToType(sVal, this.peFooterDataType);
                sVal = df.sys.data.typeToDisplay(sVal, this.peFooterDataType, this.getWebApp(),
                    this._bHasFocus, this.psFooterMask, this.piFooterPrecision);

                if (!this.pbAllowHtml) {
                    sVal = df.dom.encodeHtml(sVal);
                }

                return (sVal !== '' ? sVal : '&nbsp;');
            }
        };

        // We have to merge the swipe buttons with the value columns.
        let aMergedColumns = this.oL._aColumns.concat(this.oL._aSwipeBtns);

        aMergedColumns.sort(function (a, b) {
            const x = a._iColIndex, y = b._iColIndex;
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        });

        for (let i = 0; i < aMergedColumns.length; i++) {
            oFooterRow.aCells.push({
                sValue: aMergedColumns[i].psFooterValue || "",
                sTooltip: "",
                sCssClassName: "",
                aOptions: []
            });
        }

        this.oR.rowHtml(oFooterRow, aHtml, true);
    }

    updateFooter() {
        const aHtml = [];

        if (this.eFooterWrp) {
            this.footerHtml(aHtml);
            this.eFooterWrp.innerHTML = aHtml.join("");
        }
    }

    /* 
    Queried by WebList to determine height used in height calculation of the body.
    */
    offsetHeight() {
        if (this.eFooter) {
            return this.eFooter.offsetHeight;
        }
    }

    onSettingChange(oEv) {
        const oL = this.oL;

        if (oEv.sType === "redraw") {
            this.updateFooter();
        } else if (oEv.sType === "sorting") {
            this.updateFooter();
        } else if (oEv.sType === "prop") {
            switch (oEv.sProp) {
                case "piSortColumn":
                case "pbReverseOrdering":
                    this.updateFooter();
                    break;
                case "pbShowFooter":
                    if (this.eFooter) {
                        this.eFooter.style.display = (oL.pbShowFooter ? "" : "none");
                        oL.sizeChanged();
                    }
                    break;
                case "pbColumnsResizable":
                    if (this.eFooter) {
                        df.dom.toggleClass(this.eFooterWrp, "WebList_ColResizable", oL.pbColumnsResizable);
                    }
                    break;
                case "pbAutoColumnSizing":
                    df.dom.toggleClass(this.eFooterWrp, "WebList_AutoSize", this.oL.pbAutoColumnSizing);
                    df.dom.toggleClass(this.eFooterWrp, "WebList_HorizScroll", !this.oL.pbAutoColumnSizing);
            }
        }
    }

    onResize(oEv) {

        if (this.eFooter && this.oL._oBody) {
            this.eFooter.style.paddingRight = this.oL._oBody.scrollbarWidth() + "px";
        }
    }

    onHorizontalScroll(oEv) {
        if (this.eFooterWrp) {
            this.eFooterWrp.scrollLeft = oEv.nScrollX;
        }
    }
};