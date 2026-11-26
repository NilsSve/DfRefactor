import { WebListScrollingView } from './WebListScrollingView.js'
import { WebMenuColumnList } from './WebMenuColumnList.js'
import { WebMenuColumnRestorer } from './WebMenuColumnRestorer.js'
import { df } from '../df.js';

/*
Class:
    df.WebListHeaderView

One of the view classes in the list its mini MVC model. It is responsible for rendering the header 
and triggers click events on the controller. The WebList and WebListRowModel provide details needed 
to display the header.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/
export class WebListHeaderView {
    constructor(oList, oModel, oController) {
        this.oL = oList;
        this.oC = oController;
        this.oR = oList._oRowRenderer;

        this._oHeaderMenu = null;
        this._oHeaderMenuColumnList = null;
        this._oHeaderMenuColumnRestorer = null;
        this._bHeaderMenuPreviousState = true;

        this._oColumnNewLineCache = [];

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
        aHtml.push('<div class="WebList_Head"', (oL.pbShowHeader ? '' : ' style="display:none"'), '>');
        aHtml.push('<div class="WebList_HeadWrp', (oL.pbColumnsResizable ? ' WebList_ColResizable' : ''), (oL.pbAutoColumnSizing ? " WebList_AutoSize" : " WebList_HorizScroll"), '">');
        this.headerHtml(aHtml);
        aHtml.push('</div>');
        aHtml.push('</div>');
    }

    afterRender(eList) {
        this.eHead = df.dom.query(eList, "div.WebList_Head");
        this.eHeadWrp = df.dom.query(eList, "div.WebList_HeadWrp");

        df.dom.on("click", this.eHead, this.onHeadClick, this);
        df.dom.on("mousedown", this.eHead, this.onHeadMouseDown, this);
        df.dom.on("dblclick", this.eHead, this.onHeadDblClick, this);

        // Refresh column list.
        this.refreshColumnList();
        // Set the ordering state.
        this.setColumnReordering(this.oL.pbAllowColumnReordering); // Will also (re)render the Header Menu.
    }

    registerHeaderMenu(oMenu) {
        if (this._oHeaderMenu) {
            throw new df.Error(999, "A WebContextMenu with the context 'ListHead' is already registered, only one is allowed.", this);
        }
        this._oHeaderMenu = oMenu;
    }

    unregisterHeaderMenu(oMenu) {
        if (!this._oHeaderMenu || this._oHeaderMenu !== oMenu) {
            console.warn("A WebContextMenu with the context 'ListHead' is already registered, only one is allowed.", this);
        }
        this._oHeaderMenu = null;
    }

    registerMenuColumnList(oMenuColumnList) {
        if (this._oHeaderMenuColumnList) {
            throw new df.Error(999, "A WebMenuColumnList is already registered, only one is allowed.", this);
        }
        if (!(oMenuColumnList instanceof WebMenuColumnList)) {
            throw new df.Error(999, "registerMenuColumnList() should only be called with a WebMenuColumnList.", this);
        }
        this._oHeaderMenuColumnList = oMenuColumnList;
        this._oHeaderMenuColumnList.pbRender = this.oL.pbAllowColumnReordering;
    }

    registerMenuColumnRestorer(oMenuColumnRestorer) {
        if (this._oHeaderMenuColumnRestorer) {
            throw new df.Error(999, "A WebMenuColumnRestorer is already registered, only one is allowed.", this);
        }
        if (!(oMenuColumnRestorer instanceof WebMenuColumnRestorer)) {
            throw new df.Error(999, "registerMenuColumnRestorer() should only be called with a WebMenuColumnRestorer.", this);
        }
        this._oHeaderMenuColumnRestorer = oMenuColumnRestorer;
        this._oHeaderMenuColumnRestorer.pbRender = this.oL.pbAllowColumnReordering;
    }

    refreshColumnList() {
        this._oHeaderMenuColumnList?.refreshColumnList();
    }

    setColumnHiding(bVal) {
        if (this._oHeaderMenuColumnList)
            this._oHeaderMenuColumnList.pbRender = bVal;
        this.refreshColumnList();
    }

    setColumnReordering(bVal) {
        if (this._oHeaderMenuColumnRestorer)
            this._oHeaderMenuColumnRestorer.pbRender = bVal;

        if (bVal &&
            !df.sys.isMobile) {
            df.dom.on("dragstart", this.eHead, this.onHeadMouseDownWithDraggingProxy, this);
        } else {
            df.dom.off("dragstart", this.eHead, this.onHeadMouseDownWithDraggingProxy, this);
        }

        this._oHeaderMenu?.refreshMenu();
    }

    onHeadMouseDownWithDraggingProxy(oEv) {
        this.onHeadMouseDown(oEv, true);
    }

    headerHtml(aHtml) {
        const oL = this.oL, oR = this.oR;
        let sCssClass, oLast = null;

        aHtml.push('<table style="width:', oR.sTableWidth, '">');
        oR.resizeRowHtml(aHtml);
        aHtml.push('<tr>');

        //  Determine last
        oLast = this.oL._aColumnMapper[this.oL._aColumnMapper.length - 1];

        for (let i = 0; i < this.oL._aColumnMapper.length; i++) {
            // Safety net for pbRender and pbHidden
            if (!this.oL._aColumnMapper[i].pbRender || this.oL._aColumnMapper[i].pbHidden) continue;

            const oCol = this.oL._aColumnMapper[i];

            if (oCol.pbNewLine) {
                aHtml.push('</tr><tr>');
            }

            //  Determine column CSS class
            sCssClass = "WebList_ColHead";
            if (oCol._iCol === oL.piSortColumn) {
                sCssClass += (!oL.pbReverseOrdering ? " WebList_SortedReverse" : " WebList_Sorted");
            }
            if (oL.pbColumnSortable && oCol.pbSortable) {
                sCssClass += " WebList_Sortable";
            }
            if (oCol.headerCSS()) {
                sCssClass += " " + oCol.headerCSS();
            }
            sCssClass += " " + this.oR.cellClass(oCol, null);


            aHtml.push('<th ', this.oL.pbAllowColumnReordering ? 'draggable="true"' : '', ' class="', sCssClass, '" data-dfcol="', oCol._iCol, '"');
            if (oCol.piListRowSpan > 1) {
                aHtml.push(' rowspan="', oCol.piListRowSpan, '"');
            }
            if (oCol.piListColSpan > 1) {
                aHtml.push(' colspan="', oCol.piListColSpan, '"');
            }
            if (oCol.psToolTip) {
                aHtml.push(' title="', df.dom.encodeHtml(oCol.psToolTip), '"');
            }
            if (!oCol.pbVisible) {
                aHtml.push(df.cHideColumnCSS);
            }

            aHtml.push('><div>');
            aHtml.push('<div class="WebList_ColCap">', oCol.headerHtml(), '</div>');
            if (oCol.pbResizable && (!oL.pbAutoColumnSizing || oCol !== oLast)) {
                aHtml.push('<div class="WebList_ColSep" data-dfcol="', oCol._iCol, '"></div>');
            }

            aHtml.push('</div></th>');

        }
        aHtml.push('</tr></table>');

    }

    updateHeader() {
        const aHtml = [];
        const iPrevHeight = this.offsetHeight();

        if (this.oL.pbAllowColumnHiding) this.refreshColumnList();

        if (this.eHeadWrp) {
            this.headerHtml(aHtml);
            this.eHeadWrp.innerHTML = aHtml.join("");
        }

        //  Check if this update changed the size
        if (iPrevHeight != this.offsetHeight()) {
            this.oL.sizeChanged();
        }
    }

    /* 
    Queried by WebList to determine height used in height calculation of the body.
    */
    offsetHeight() {
        if (this.eHead) {
            return this.eHead.offsetHeight;
        }
    }


    /*
    Handles the onclick event on the list header. It will determine which column is clicked and if 
    pbColumnSortable is true and pbSortable of the column is true it will update the sorting by calling 
    the changeSorting method.
    
    @param  oEv  The event object (df.events.DOMEvent).
    @return
    */
    onHeadClick(oEv) {
        let eElem = oEv.getTarget();

        //  Check enabled state
        if (!this.oL.isEnabled()) {
            return;
        }


        //  Find the column header div
        while (eElem.parentNode && eElem !== this._eHead) {
            if (eElem.tagName === "TH" && eElem.hasAttribute("data-dfcol")) {
                //  Determine the column
                const iCol = parseInt(eElem.getAttribute("data-dfcol"), 10);

                if (this.oC.headClick(oEv, iCol)) {
                    oEv.stop();
                }
                return;
            }

            eElem = eElem.parentNode;
        }

    }

    /*
    Handles the double click event on the list header. It will determine which column is clicked and if 
    pbColumnSortable is true and pbSortable of the column is true it will update the sorting by calling 
    the changeSorting method.
    
    @param  oEv  The event object (df.events.DOMEvent).
    @return
    */
    onHeadDblClick(oEv) {
        let eElem = oEv.getTarget()

        //  Check enabled state
        if (!this.oL.isEnabled()) {
            return;
        }


        //  Find the column header div
        while (eElem.parentNode && eElem !== this._eHead) {
            if (eElem.tagName === "TH" && eElem.hasAttribute("data-dfcol")) {
                //  Determine the column
                const iCol = parseInt(eElem.getAttribute("data-dfcol"), 10);

                if (this.oC.headDblClick(oEv, iCol)) {
                    oEv.stop();
                }
                return;
            }

            eElem = eElem.parentNode;
        }

    }

    onHeadMouseDown(oEv, bDragging) {
        let eTarget = oEv.getTarget();

        //  Check enabled state
        if (!this.oL.isEnabled()) {
            oEv.stop();
            return false;
        }

        // Ignore a right-moouse click.
        if (oEv.e.button !== 0) return;

        if (this._oHeaderMenu && this._oHeaderMenu.isVisible()) {
            this._oHeaderMenu.hideMenu();
            return;
        }

        //    Check if it is the resize div
        if (eTarget.className === 'WebList_ColSep' && this.oL.pbColumnsResizable) {
            if (this._oHeaderMenu) {
                // Set the previous enabled state to a chaching variable for the context menu.
                this._bHeaderMenuPreviousState = this._oHeaderMenu.isEnabled();
                // Either way we disable the context menu for now, and enable it after the dragging stopped.
                this._oHeaderMenu.disable();
            }

            this.resizeColumn(oEv, parseInt(eTarget.getAttribute('data-dfcol'), 10));

            oEv.stop();
            return false;
        } else if ((eTarget.classList.contains('WebList_ColHead') || eTarget.className === 'WebList_ColCap') &&
            this.oL.pbAllowColumnReordering &&
            bDragging) {

            if (this._oHeaderMenu) {
                // Set the previous enabled state to a chaching variable for the context menu.
                this._bHeaderMenuPreviousState = this._oHeaderMenu.isEnabled();
                // Either way we disable the context menu for now, and enable it after the dragging stopped.
                this._oHeaderMenu.disable();
            }

            while (!eTarget.classList.contains('WebList_ColHead')) {
                eTarget = eTarget.parentNode;
            }

            const iColumn = parseInt(eTarget.getAttribute('data-dfcol'), 10);
            const that = this;

            // Create a cache for all pbNewLines to restore later.
            this._oColumnNewLineCache = [];
            for (let i = 0; i < this.oL._aColumnMapper.length; i++) {
                if (this.oL._aColumnMapper[i].pbNewLine) {
                    this._oColumnNewLineCache.push(i);
                    this.oL._aColumnMapper[i].pbNewLine = false;
                }
            }

            // Only in the case of newlines do we need to redraw.
            if (this._oColumnNewLineCache.length > 0) this.oL.redraw();

            // We have to wait for the render to finish in a rather nasty way.
            // Nothing to do about that as we don't have an event to await a render finish.
            // DOMNodeInsert was used before but was too instable as we don't know when it's done.
            //
            // setTimeout apparently worked historically by providing a 0. 
            // It would create a new queue event to process at the end of the browser event queue.
            // It would then come after the render had finished however this does not seem to work anymore.
            // Possilibly due to the new worker system in most browsers... so we just set a timeout of 100ms.
            setTimeout(function () {
                const eColumnHead = df.dom.query(that.eHead, '.WebList_ColHead[data-dfcol="' + iColumn + '"');
                that.moveColumn(eColumnHead, oEv, iColumn);
            }, this._oColumnNewLineCache.length > 0 ? 75 : 0);

            oEv.stop();
            return false;
        }

        return true;
    }

    moveColumn(eColumnHeader, oEv, iOriginalDbIndex) {
        const eColumnGhost = this.oL._eElem.cloneNode(true);  // We clone the whole list to keep styling.

        const aLayoutToMapperIndex = [];
        for (let i = 0; i < this.oL._aColumnMapper.length; i++) {
            if (this.oL._aColumnMapper[i].pbRender && !this.oL._aColumnMapper[i].pbHidden) {
                aLayoutToMapperIndex.push(i);
            }
        }

        // Then we need the actual element index since the data-dfcol/iOriginalDbIndex is used on the data side.
        const iOriginalIndexInLayout = Array.prototype.indexOf.call(eColumnHeader.parentNode.children, eColumnHeader);
        const iOriginalIndexInMapper = aLayoutToMapperIndex[iOriginalIndexInLayout];

        // Pre-allocate a new index to the same index.
        let iNewIndexInMapper = iOriginalIndexInMapper;

        // // We remove all possible text from the column header.
        for (let i = 0; i < eColumnHeader.childNodes.length; i++) {
            eColumnHeader.removeChild(eColumnHeader.childNodes[i]);
        }
        eColumnHeader.classList.add("WebList_Moving");

        // Then we lookup all cells that correspond to our column.
        const aColumnHeadedRows = df.dom.query(this.oL._oBody.eBody, 'td[data-dfcol="' + iOriginalDbIndex + '"', true);
        // We remove the text to create a sort of animation and apply styling.
        for (let i = 0; i < aColumnHeadedRows.length; i++) {
            aColumnHeadedRows[i].innerHTML = "";
            aColumnHeadedRows[i].classList.add("WebList_Moving");
        }

        // We want to attach the ghost as specific as possible thus we need to calculate the correction,
        // from the top-left corner of the orignal column-head or ghost to the cursor.
        // We apply this later every time.
        const oColumnHead_Rect = eColumnHeader.getBoundingClientRect();
        const iColumnGhost_MouseCorrection_X = oColumnHead_Rect.width / 2;
        const iColumnGhost_MouseCorrection_Y = oColumnHead_Rect.height / 2;

        // Now we are going to prune the ghost. We remove everything not having to do with our column.
        // This way we can keep the styling whilst moving only our column in the ghost.
        const aGhostColumnCells = df.dom.query(eColumnGhost, "[data-dfcol]", true);
        for (let i = 0; i < aGhostColumnCells.length; i++) {
            if (aGhostColumnCells[i].getAttribute("data-dfcol") != iOriginalDbIndex) { // If it isn't our column.
                aGhostColumnCells[i].parentNode.removeChild(aGhostColumnCells[i]);                 // Remove it.
            } else {
                // If it is our column; maximize the size since we correct this later.
                aGhostColumnCells[i].style.width = "100%";
            }
        }

        // If it contains a scrollbar remove it since it won't be used and isn't calculated into the width.
        const eVerticalScrollBar = df.dom.query(eColumnGhost, ".WebList_Scroll");
        if (eVerticalScrollBar) eVerticalScrollBar.parentNode.removeChild(eVerticalScrollBar);

        let aHorizontalScrollBars = df.dom.query(eColumnGhost, ".WebList_HorizScroll", true);
        for (let i = 0; i < aHorizontalScrollBars.length; i++) {
            df.dom.removeClass(aHorizontalScrollBars[i], "WebList_HorizScroll");
        }

        // If the list has a label; remove it.
        if (this.oL.pbShowLabel) {
            const eGhostListLabel = df.dom.query(eColumnGhost, "div > label", false);
            if (eGhostListLabel) eGhostListLabel.parentNode.removeChild(eGhostListLabel);
        }

        // Set all positional data on the ghost.
        eColumnGhost.style.position = "fixed";
        eColumnGhost.style.left = (oEv.e.clientX - iColumnGhost_MouseCorrection_X) + "px";
        eColumnGhost.style.top = (oEv.e.clientY - iColumnGhost_MouseCorrection_Y) + "px";
        eColumnGhost.style.width = oColumnHead_Rect.width + "px";
        // Very important is that we set the pointer-events to none.
        // This is required as we don't want to catch a ElementFromPoint request on the ghost.
        // Only IE11+ though....
        eColumnGhost.style["pointer-events"] = "none";
        (this.oL.topLayer() || document.body).appendChild(eColumnGhost);

        // Save the overflow and set it to hidden so we don't get any scrollbars.
        var sBodyOverflowCache = document.body.style.overflow;
        document.body.style.overflow = "hidden";

        const aColumnElements = df.dom.query(this.oL._eElem, '[data-dfcol="' + iOriginalDbIndex + '"', true);
        function updateColumnShadowPosition(iNewIndexOfColumn) {
            // Now we are going to move the column header from one place to another. 
            function moveElementToIndex(eElem, iIndex) {
                const eParent = eElem.parentNode;
                eParent.removeChild(eElem);

                if (iIndex >= eParent.childNodes.length) {
                    eParent.appendChild(eElem);
                } else {
                    eParent.insertBefore(eElem, eParent.childNodes[iIndex]);
                }
            }

            moveElementToIndex(eColumnHeader, iNewIndexOfColumn);
            for (let i = 0; i < aColumnElements.length; i++) {
                moveElementToIndex(aColumnElements[i], iNewIndexOfColumn);
            }
        }

        let dtLastHorizontalScroll = Date.now();
        const eHorizontalSrollbar = this.oL._oBody.eTableWrp;
        const iHorizontalScrollDeltaPx = 20;

        function onMove(oEv) {
            // Recorrect the ghost to the cursor and columnhead.
            eColumnGhost.style.left = (oEv.e.clientX - iColumnGhost_MouseCorrection_X) + "px";
            eColumnGhost.style.top = (oEv.e.clientY - iColumnGhost_MouseCorrection_Y) + "px";

            if (this.oL._oBody.eTableWrp) {
                let oScrollBarRect = eHorizontalSrollbar.getBoundingClientRect();
                if (Date.now() - dtLastHorizontalScroll > 100) {
                    if (oEv.e.clientX < oScrollBarRect.left + iHorizontalScrollDeltaPx + iHorizontalScrollDeltaPx) {
                        eHorizontalSrollbar.scrollLeft -= iHorizontalScrollDeltaPx;
                        dtLastHorizontalScroll = Date.now();
                    } else if (oEv.e.clientX > oScrollBarRect.right - iHorizontalScrollDeltaPx - iHorizontalScrollDeltaPx) {
                        eHorizontalSrollbar.scrollLeft += iHorizontalScrollDeltaPx;
                        dtLastHorizontalScroll = Date.now();
                    }
                }
            }

            // We grab the hovered over element and keep going till we find column data.
            let eTarget = oEv.getTarget();
            while (eTarget.hasAttribute && !eTarget.hasAttribute('data-dfcol') && eTarget != this.oL._eElem) {
                eTarget = eTarget.parentNode;
            }

            let eWebObject = eTarget;
            if (eTarget.hasAttribute && eTarget.hasAttribute('data-dfcol')) {
                while (eWebObject.hasAttribute && !eWebObject.hasAttribute('data-dfobj') && eTarget != this.oL._eElem) {
                    eWebObject = eWebObject.parentNode;
                }
            }

            // If no column data could be found it means we are outside of our object.
            // Or if we didn't find our own element.
            if (!eTarget.hasAttribute || !eTarget.hasAttribute('data-dfcol') || eWebObject !== this.oL._eElem) {
                // Set it to the original state.
                updateColumnShadowPosition(iOriginalIndexInLayout);
                return;
            }

            if (eTarget.classList.contains("WebList_Moving")) return;

            const oRect = eTarget.getBoundingClientRect();
            const iLeftBarrier = oRect.left + ((oRect.right - oRect.left) / 3);
            const iRightBarrier = oRect.right - ((oRect.right - oRect.left) / 3);

            // Don't do anything if we are not touching a barrier to avoid unnessesary flickering...
            if (oEv.e.x > iLeftBarrier && oEv.e.x < iRightBarrier) return;

            // Get the new column nr for reference.
            let iNewIndexInLayout = Array.prototype.indexOf.call(eTarget.parentNode.children, eTarget);

            // We are gonna check whether we are positioned more to the right of the element.
            // If so, we would want to insert it to the right of it.
            if (oEv.e.x <= iLeftBarrier) {
                if (iNewIndexInLayout > iOriginalIndexInLayout &&
                    iNewIndexInLayout > 0) {
                    iNewIndexInLayout--;
                }
            }
            else if (oEv.e.x > iRightBarrier) { // More to the right of the element.
                if (iNewIndexInLayout < iOriginalIndexInLayout &&
                    iNewIndexInLayout < eTarget.parentNode.children.length - 1) {
                    iNewIndexInLayout++;
                }
            }

            // Update the mapper index.
            iNewIndexInMapper = aLayoutToMapperIndex[iNewIndexInLayout];

            // Now we need to move the column definitions and cells to that location moving the rest of the elements to the right.
            updateColumnShadowPosition(iNewIndexInLayout);
        }

        //  Handles the events that should stop the drag and 
        function onStopMove(oEv) {
            // Re-enable the context menu.
            if (this._oHeaderMenu) this._oHeaderMenu.enable(this._bHeaderMenuPreviousState);

            // If we mouseup a non-left moouse button ignore that one.
            if (oEv.e.button !== 0) return;

            // Restore the overflow cache.
            document.body.style.overflow = sBodyOverflowCache;

            //  Remove event handlers
            df.dom.off("mouseup", window, onStopMove, this);
            df.dom.off("mousemove", window, onMove, this);

            // Remove the ghost from the view.
            eColumnGhost.parentNode.removeChild(eColumnGhost);

            // Restore newlines.
            for (let i = 0; i < this._oColumnNewLineCache.length; i++) {
                this.oL._aColumnMapper[this._oColumnNewLineCache[i]].pbNewLine = true;
            }

            // We grab the hovered over element and keep going till we find column data.
            let eTarget = oEv.getTarget();
            while (eTarget.hasAttribute && !eTarget.hasAttribute('data-dfcol') && eTarget != this.oL._eElem) {
                eTarget = eTarget.parentNode;
            }

            let eWebObject = eTarget;
            if (eTarget.hasAttribute && eTarget.hasAttribute('data-dfcol')) {
                while (eWebObject.hasAttribute && !eWebObject.hasAttribute('data-dfobj') && eTarget != this.oL._eElem) {
                    eWebObject = eWebObject.parentNode;
                }
            }

            // If no column data could be found it means we are outside of our object.
            // Or if we didn't find our own element.
            if (!eTarget.hasAttribute ||
                !eTarget.hasAttribute('data-dfcol') ||
                eWebObject !== this.oL._eElem) {
                this.oL.redraw();
                return;
            }

            // Let's move the columns inside of the column mapper.
            const oOrgCol = this.oL._aColumnMapper[iOriginalIndexInMapper];
            this.oL._aColumnMapper.splice(iOriginalIndexInMapper, 1);
            this.oL._aColumnMapper.splice(iNewIndexInMapper, 0, oOrgCol);

            // Remap the other positions after the first index either the original or new one.
            let iIndex = iNewIndexInMapper < iOriginalIndexInMapper ? iNewIndexInMapper : iOriginalIndexInMapper;
            for (; iIndex < this.oL._aColumnMapper.length; iIndex++) {
                this.oL._aColumnMapper[iIndex].piPosition = iIndex;
            }

            // Redraw all of it.
            this.oL.redraw();
            this.oL.triggerLayoutChange(this.oL._aChildren[iOriginalDbIndex]);
        }

        //  Attach event handlers
        df.dom.on("mouseup", window, onStopMove, this);
        df.dom.on("mousemove", window, onMove, this);
    }

    resizeColumn(oEv, iCol) {
        const oL = this.oL, oR = this.oR;
        let iPX = 0, iDiff = 0, iMin, iMax = 0;

        //  First create our drag mask
        const eMask = df.gui.dragMask(false, oL._eElem);
        eMask.style.cursor = "e-resize";

        //  Determine percentage to pixel ratio
        const iRatio = oR.calcPixelRatio(); //this.findColNr(oR.aColWidths[iCol].oCol));

        let eColumn = oEv.getTarget().parentNode;
        while (eColumn.hasAttribute && !eColumn.hasAttribute('data-dfcol') && eColumn != this.oL._eElem) {
            eColumn = eColumn.parentNode;
        }

        const iVCol = Array.prototype.indexOf.call(eColumn.parentNode.children, eColumn);

        //  Get fixed position of slider
        const oRect = oEv.getTarget().getBoundingClientRect();

        //  Determine current position and maximum
        if (oL.pbAutoColumnSizing) {
            for (let i = iVCol + 1; i < oR.aColWidths.length; i++) {
                if (oR.aColWidths[i].oCol.pbResizable) {   //  Do not increase maximum with columns that are not resizable so they never get smaller
                    if (oR.aColWidths[i].bFixed) {
                        iPX = oR.aColWidths[i].iPixels;
                    } else {
                        iPX = (oR.aColWidths[i].iPercent * iRatio);
                    }
                    //    Determine minimum
                    iMax += iPX - oR.iColMin;
                }
            }
        } else {
            iMax = screen.width - oRect.left;
        }
        const iStartX = oEv.getMouseX();

        //    Determine minimum
        if (oR.aColWidths[iVCol].bFixed || !oL.pbAutoColumnSizing) {
            iMin = -oR.aColWidths[iVCol].iPixels + oR.iColMin;
        } else {
            iMin = -(oR.aColWidths[iVCol].iPercent * iRatio) + oR.iColMin;
        }

        //    Create ghost separator

        const iLeft = oRect.left;
        const eGhost = df.dom.create('<div class="WebList_ColResizer"></div>');
        this.eHead.appendChild(eGhost);
        eGhost.style.left = iLeft + "px";
        eGhost.style.top = oRect.top + "px";
        eGhost.style.height = oL._eElem.clientHeight + "px"; //(this._eHead.clientHeight + this._eBody.clientHeight) + "px";

        //  Resizer function that handles the mousemove and calculates the pixel difference and moves the ghost separator
        function onResize(oEv) {
            const iNewX = oEv.getMouseX();

            //  Calculate new difference
            iDiff = iNewX - iStartX;

            //  Check against min and max
            if (iDiff < iMin) {
                iDiff = iMin;
            }
            if (iDiff > iMax) {
                iDiff = iMax;
            }

            // df.debug("iDiff (" + iDiff + ") = iNewX(" + iNewX + " - iStartX(" + iStartX + ");");
            //  Apply to ghost
            const iNewLeft = iLeft + iDiff;
            eGhost.style.left = iNewLeft + "px";
        }

        //  Handles the events that should stop the drag and 
        function onStopResize(oEv) {
            if (this._oHeaderMenu) this._oHeaderMenu.enable(this._bHeaderMenuPreviousState);

            if (oEv.e.button !== 0) return;

            //  Remove event handlers
            df.dom.off("mouseup", eMask, onStopResize, this);
            df.dom.off("mouseup", window, onStopResize, this);
            //df.dom.off("mouseout", eMask, onStopResize, this);
            df.dom.off("mousemove", eMask, onResize, this);

            //  Remove ghost & mask
            eGhost.parentNode.removeChild(eGhost);
            df.gui.hideMask(eMask);

            //  Update column sizes
            this.oR.recalcColumnSizes(iVCol, iDiff, false);
            this.oL.triggerLayoutChange(this.oL._aChildren[iCol]);
        }

        //  Attach event handlers
        df.dom.on("mouseup", eMask, onStopResize, this);
        df.dom.on("mouseup", window, onStopResize, this);
        //df.dom.on("mouseout", eMask, onStopDrag, this);
        df.dom.on("mousemove", eMask, onResize, this);
    }

    colCell(oCol) {
        return this.colCellByIndex(oCol._iCol);
    }

    colCellByIndex(iCol) {
        return df.dom.query(this.eHeadWrp, "th.WebList_ColHead[data-dfcol='" + iCol + "']");
    }

    onSettingChange(oEv) {
        const oL = this.oL;

        if (oEv.sType === "redraw") {
            this.updateHeader();
        } else if (oEv.sType === "sorting") {
            this.updateHeader();
        } else if (oEv.sType === "prop") {
            switch (oEv.sProp) {
                case "piSortColumn":
                case "pbReverseOrdering":
                    this.updateHeader();
                    break;
                case "pbShowHeader":
                    if (this.eHead) {
                        this.eHead.style.display = (oL.pbShowHeader ? "" : "none");
                        oL.sizeChanged();
                    }
                    break;
                case "pbColumnsResizable":
                    if (this.eHead) {
                        df.dom.toggleClass(this.eHeadWrp, "WebList_ColResizable", oL.pbColumnsResizable);
                    }
                    break;
                case "pbAutoColumnSizing":
                    df.dom.toggleClass(this.eHeadWrp, "WebList_AutoSize", this.oL.pbAutoColumnSizing);
                    df.dom.toggleClass(this.eHeadWrp, "WebList_HorizScroll", !this.oL.pbAutoColumnSizing);
            }
        }
    }

    onResize(oEv) {

        if (this.eHead && this.oL._oBody) {
            this.eHead.style.paddingRight = this.oL._oBody.scrollbarWidth() + "px";
        }
    }

    onHorizontalScroll(oEv) {
        if (this.eHeadWrp) {
            this.eHeadWrp.scrollLeft = oEv.nScrollX;
        }
    }
}