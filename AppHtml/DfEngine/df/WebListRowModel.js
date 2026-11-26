/*
Class:
    df.WebListRowModel

Models the row within the WebList its mini MVC model. It keeps track of the multi line row and 
column widths. It contains the code for rendering a single row.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
/* global df */
export class WebListRowModel {
    constructor(oList, oModel) {
        this.oL = oList;
        this.oM = oModel;

        this.iColMin = 20; //    Determines the minimum percentage available

        this.iRound = (df.sys.isIE && df.sys.iVersion <= 8 ? 1 : 100); //    This determines the decimals used (1 is none, 100 is 2) when rounding column widths (IE8 has issues with decimals on table cells)

        this.sTableWidth = "100%";

        oList._onSettingChange.on(this.onSettingChange, this);
    }

    init() {
        this.prepareLayout();
    }

    onSettingChange(oEv) {
        if (oEv.sType === "prepare-redraw") {
            this.prepareLayout();
        }
    }

    /* 
    This function generates the HTML for a single row and appends it to the string builder array that is 
    passed.
    
    @param  tRow    Row data.
    @param  aHtml   String builder to which html is appended.
    @param  bZebra  True for an odd row.
    @param  bFirst  True if this is the first list item
    @param  bLast   True if this is the last list item
    @private
    */
    rowHtml(tRow, aHtml, bZebra, iLevel, bFirst, bLast, iItemIndex) {
        const oL = this.oL;

        //  Assertion
        if (tRow && tRow.aCells.length < (oL._aColumns.length + oL._aSwipeBtns.length)) {
            throw new df.Error(999, "List data is not containing enough columns ({{0}} / {{1}}).", oL, [tRow.aCells.length, (oL._aColumns.length + oL._aSwipeBtns.length)]);
        }

        aHtml.push('<table data-dfisrow="true" data-dfitem="', iItemIndex, '" data-dfrowid="', (tRow ? tRow.sRowId : "empty"), (this.oL.pbDragDropEnabled && (this.oL.isSupportedDragAction(df.dragActions.WebList.ciDragRow) || this.oL.isSupportedDragAction(df.dragActions.WebMultiSelectList.ciDragRowSelection)) ? '" draggable="true"' : '" '), '" class="', this.rowClass(tRow, bZebra, iLevel, bFirst, bLast), '" style="width:', this.sTableWidth, '">');

        this.resizeRowHtml(aHtml);

        //  Loop cells
        for (let i = 0; i < this.oL._aColumnMapper.length; i++) {
            // Safety net for pbRender and pbHidden.
            if (!this.oL._aColumnMapper[i].pbRender || this.oL._aColumnMapper[i].pbHidden) continue;

            const oCol = this.oL._aColumnMapper[i];

            if (oCol.pbNewLine) {
                aHtml.push('</tr><tr>');
            }

            const sTooltip = (tRow && (tRow.aCells[oCol._iColIndex].sTooltip || (oCol.pbValueAsTooltip && oCol.tooltipValue(tRow.aCells[oCol._iColIndex])))) || "";

            let sClassSpecifier = tRow && tRow.fCellClass ?
                tRow.fCellClass(oCol, (tRow && tRow.aCells[oCol._iColIndex]) || null) :
                this.cellClass(oCol, (tRow && tRow.aCells[oCol._iColIndex]) || null);

            aHtml.push('<td data-dfcol="', oCol._iCol, '" class="', sClassSpecifier, '" title="', df.dom.encodeAttr(sTooltip), '"');

            if (oCol.piListRowSpan > 1) {
                aHtml.push(' rowspan="', oCol.piListRowSpan, '"');
            }
            if (oCol.piListColSpan > 1) {
                aHtml.push(' colspan="', oCol.piListColSpan, '"');
            }
            if (!oCol.pbVisible) {
                aHtml.push(df.cHideColumnCSS);
            }

            aHtml.push('>', (tRow ? this.cellHtml(oCol, tRow, tRow.aCells[oCol._iColIndex]) : '&nbsp;'), '</td>');
        }

        aHtml.push('</tr></table>');
    }

    /* 
    This function determines the CSS classnames applied to a cell within the list. This is done based on 
    several column properties including the data type.
    
    @param  oCol    The column object.
    @param  tCell    Row data.
    @private
    */
    cellClass(oCol, tCell) {
        const aClasses = [];

        aClasses.push(oCol._sCellClass);

        aClasses.push(oCol.isEnabled() ? df.CssEnabled : df.CssDisabled);

        if (oCol.pbEditable && this.oL._sControlClass === "WebGrid") {
            aClasses.push("WebEditable");
        }

        aClasses.push(oCol.peAlign === df.ciAlignLeft ? "WebList_AlignLeft" : (oCol.peAlign === df.ciAlignCenter ? "WebList_AlignCenter" : (oCol.peAlign === df.ciAlignRight ? "WebList_AlignRight" : "")));

        if (oCol.peDataType === df.ciTypeBCD) {
            aClasses.push("dfData_BCD");
        } else if (oCol.peDataType === df.ciTypeDate) {
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
    }

    /* 
    This function determines the classnames that are set on a list row. If an additional data member is 
    available in the row data that is used as CSS classname as well.
    
    @param  tRow    Row data.
    @param  bZebra  True if this is an odd row, false for an even row.
    @private
    */
    rowClass(tRow, bZebra, iLevel, bFirst, bLast) {
        const aClasses = ["WebList_Row"];

        if ((tRow && tRow.sRowId) === this.oM.sCurrentRowId) {
            aClasses.push("WebList_Selected");
        }

        aClasses.push((bZebra ? ' WebList_RowOdd' : ' WebList_RowEven'));

        if (!tRow) {
            aClasses.push("WebList_RowEmpty");
        }

        if (tRow && tRow.sCssClassName) {
            aClasses.push(tRow.sCssClassName);
        }

        aClasses.push(`Web_Level${iLevel}`);

        if (bFirst) {
            aClasses.push("Web_First");
        }
        if (bLast) {
            aClasses.push("Web_Last");
        }

        return aClasses.join(" ");
    }

    cellHtml(oCol, tRow, tCell) {
        
        tCell = tCell || { sValue: "", sTooltip: "", sCssClassName: "", aOptions: [] };

        //  We need to tempolary set the focus to false because we always want the masked value
        const bFocus = oCol._bHasFocus;
        oCol._bHasFocus = false;

        const sHtml = tRow && tRow.fCellHtml ?
            tRow.fCellHtml.call(oCol, tRow.sRowId, tCell) :
            oCol.cellHtml(tRow.sRowId, tCell);

        //  Restore the focus
        oCol._bHasFocus = bFocus;

        return sHtml;
    }

    resizeRowHtml(aHtml) {
        const aCols = this.aColWidths, bAllFixed = !this.oL.pbAutoColumnSizing;

        aHtml.push('<colgroup>');


        for (let i = 0; i < aCols.length; i++) {
            if (bAllFixed || aCols[i].bFixed) {
                aHtml.push('<col data-dfcol="', aCols[i].oCol._iCol, '" style="width: ', aCols[i].iPixels, 'px"></col>');
            } else {
                aHtml.push('<col data-dfcol="', aCols[i].oCol._iCol, '" style="width: ', aCols[i].iPercent, '%"></col>');
            }
        }


        aHtml.push('</colgroup>');
    }

    /* 
    This method prepares the layout before rendering. Its main task is to calculate the column widths 
    which can be fairly complicated with the support for multiline rows and fixed widths. It is a three 
    step process where first the row layout is calculated in memory and then the column widths are 
    determined and they are finally converted into percentages or pixels and stored.
    
    @private
    */
    prepareLayout() {
        let iCols = 0, iRow = 0, iCell = 0, aColWidths = [], iTotalPx = 0, iFixed = 0, iRatio = 0, oCol;
        const aTable = []


        //  Determine table layout
        for (let i = 0; i < this.oL._aColumnMapper.length; i++) {
            // Safety net for pbRender and pbHidden.
            if (!this.oL._aColumnMapper[i].pbRender || this.oL._aColumnMapper[i].pbHidden) continue;

            oCol = this.oL._aColumnMapper[i];

            //  We do not support a colspan or rowspan of 0 so we correct that first
            oCol.piListColSpan = Math.max(oCol.piListColSpan, 1);
            oCol.piListRowSpan = Math.max(oCol.piListRowSpan, 1);

            if (oCol.pbNewLine && aTable.length > 0) {
                if (aTable[iRow].length > iCols) {
                    iCols = aTable[iRow].length;
                }
                iRow++;
                iCell = 0;
            }

            //  Jump over cols already in use
            while (aTable[iRow] && aTable[iRow][iCell]) {
                iCell++;
            }

            //  Mark cells
            for (let x = 0; x < oCol.piListRowSpan; x++) {
                if (!aTable[iRow + x]) {
                    aTable[iRow + x] = [];
                }

                // Jump over cells here
                for (let y = 0; y < oCol.piListColSpan; y++) {
                    aTable[iRow + x][iCell + y] = oCol;
                }
            }

            iCell += oCol.piListColSpan;

        }

        //  Check if the last row is the longest
        if (aTable[iRow] && aTable[iRow].length > iCols) {
            iCols = aTable[iRow].length;
        }

        //  Determine width for each column
        for (let iCol = 0; iCol < iCols; iCol++) {
            aColWidths[iCol] = { bDef: false, bGues: false, bFixed: false, iWidth: 0, oCol: null };

            for (iRow = 0; iRow < aTable.length; iRow++) {
                oCol = aTable[iRow][iCol];
                if (oCol) {
                    if (oCol.piListColSpan === 1) {
                        aColWidths[iCol].bDef = true;
                        aColWidths[iCol].bFixed = oCol.pbFixedWidth;
                        aColWidths[iCol].iWidth = oCol.piWidth;
                        aColWidths[iCol].oCol = oCol;

                        break;
                    } else if (!aColWidths[iCol].bGues) {
                        aColWidths[iCol].bGues = true;
                        aColWidths[iCol].bFixed = oCol.pbFixedWidth;
                        aColWidths[iCol].iWidth = oCol.piWidth / oCol.piListColSpan;
                        aColWidths[iCol].oCol = oCol;
                    }
                }
            }

            if (aColWidths[iCol].bFixed) {
                iFixed += aColWidths[iCol].iWidth;
            } else {
                iRatio += aColWidths[iCol].iWidth;
            }
        }


        //  Store / convert column widths
        for (let iCol = 0; iCol < aColWidths.length; iCol++) {
            iTotalPx += aColWidths[iCol].iWidth;
            aColWidths[iCol].iPixels = aColWidths[iCol].iWidth;
            if (!aColWidths[iCol].bFixed) {
                // Pixel width or percentage?
                aColWidths[iCol].iPercent = Math.floor((aColWidths[iCol].iWidth * (100 / iRatio)) * this.iRound) / this.iRound;
            }
        }

        this.aColWidths = aColWidths;

        if (this.oL.pbAutoColumnSizing) {
            this.sTableWidth = "100%";
        } else {
            this.sTableWidth = iTotalPx + "px";
        }


    }

    recalcColumnSizes(iVCol, iDiff, bOverrideResizable) {
        let iTotal = 0, iColls = 0, iLast;


        if (this.oL.pbAutoColumnSizing) {
            //  Determine percentage to pixel ratio
            const iRatio = this.calcPixelRatio();

            //  Determine total space behind column
            for (let i = iVCol + 1; i < this.aColWidths.length; i++) {
                if (this.aColWidths[i].bFixed) {
                    iTotal += this.aColWidths[i].iPixels;
                } else {
                    iTotal += (this.aColWidths[i].iPercent * iRatio);
                }

                if (this.aColWidths[i].oCol.pbResizable || bOverrideResizable) {
                    iColls++;
                }
            }

            if (this.aColWidths[iVCol].bFixed) {
                this.aColWidths[iVCol].iPixels = this.aColWidths[iVCol].iPixels + iDiff;
            } else {
                this.aColWidths[iVCol].iPercent = ((this.aColWidths[iVCol].iPercent * iRatio) + iDiff) / iRatio;
            }


            while (Math.round(iDiff || 0) !== 0 && iDiff !== iLast) {
                const iColDiff = iDiff / iColls;
                iLast = iDiff;

                for (let i = iVCol + 1; i < this.aColWidths.length; i++) {
                    if (this.aColWidths[i].oCol.pbResizable || bOverrideResizable) {
                        const iPixels = (this.aColWidths[i].bFixed ? this.aColWidths[i].iPixels : this.aColWidths[i].iPercent * iRatio);
                        let iChanged = iPixels - iColDiff;
                        if (iChanged < this.iColMin) {
                            iChanged = this.iColMin;
                        }

                        if (this.aColWidths[i].bFixed) {
                            this.aColWidths[i].iPixels = iChanged;
                        } else {
                            this.aColWidths[i].iPercent = iChanged / iRatio;
                        }

                        iDiff -= (iPixels - iChanged);
                    }
                }
            }

            for (let i = 0; i < this.aColWidths.length; i++) {
                if (this.aColWidths[i].bFixed) {
                    this.aColWidths[i].oCol.piWidth = this.aColWidths[i].iPixels;
                } else {
                    this.aColWidths[i].oCol.piWidth = this.aColWidths[i].iPercent * 10;
                }
                this.aColWidths[i].oCol.addSync("piWidth");
            }
        } else {
            this.aColWidths[iVCol].oCol.piWidth = this.aColWidths[iVCol].iPixels = (this.aColWidths[iVCol].iPixels + iDiff);
            this.aColWidths[iVCol].oCol.addSync("piWidth");
        }


        //this.prepareLayout();
        this.oL.redraw();
    }


    calcPixelRatio() {
        let iFullWidth = this.oL._oBody.fullwidth();

        for (let i = 0; i < this.aColWidths.length; i++) {
            if (this.aColWidths[i].bFixed) {
                iFullWidth -= this.aColWidths[i].iPixels;
            }
        }

        //  Calculate & return ratio
        return iFullWidth / 100;
    }

    findVColNr(oCol) {
        const oL = this.oL;
        let iVCol = 0;

        for (let i = 0; i < oL._aColumnMapper.length; i++) {
            const oCur = oL._aColumnMapper[i];

            if (oCur.pbRender && !oCur.pbHidden) {
                if (oCur.pbNewLine) {
                    iVCol = 0;
                }
                if (oCur === oCol) {
                    return iVCol;
                }
                iVCol += oCur.piListColSpan;
            }
        }

        return -1;
    }

}