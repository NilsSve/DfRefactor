import { WebListModel } from './WebListModel.js';
import { WebListView } from './WebListView.js';
import { df } from '../df.js';

/*
Class:
    WebListScrollingView
Extends:
    WebListView

Extends the main view class of the WebList its mini MVC model with scrolling logic. It uses a 
virtual scrolling system where only the visible rows and a few above / below are rendered. This 
keeps the number of DOM elements low and the performance up. It also supports paged data loading 
(WebListPagedModel) to support 'endless scrolling' where data is only partially loaded and chuncks 
of data are requested when needed.

Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
    2018/02/22  (HW, DAW)
        It now keeps track of independent row heights and calculates accordingly.
*/
 
export class WebListScrollingView extends WebListView{

heightCache = {

}

constructor(oList, oModel, oController){
    super(oList, oModel, oController);
    
    this.bScroll = true;

    this.bZebraTop = false;    //  Indicates wether the next row inserted on top should be a 'Odd' colored row
    this.bZebraBottom = false; //  Indicates wether the next row inserted at the bottom should be a 'Odd' colored row
    
    this.iTableOffset = 0;     //  The scrollOfset of the table (number of pixels between the first rendered row and the first visisble row)
    this.iScrollOffsetPx = 0;  //  The number of (virtual) pixels from the top of the list to the displayed part
    this.iRowDispOffset = 0;   //  The first row that is currently rendered
    this.iViewOffset = 0;      //  The number of rows rendered above the first visible row
    this.iRowsDispOffset = 0;  //  The total offset from the top of the cache to the first rendered row
    this.iRowDispLast = 0;     //  The last displayed row
    
    this.iPrefViewOffset = 8;      //  The preferred view offset (amount of rows rendered that are not visible)
    this.iMaxViewOffsetDiff = this.iPrefViewOffset / 2;      //  The preferred view offset (amount of rows rendered that are not visible)
    
    this.iLastScrollbarSet = 0;    //  The last scrollTop set to the scrollbar so we know if we need to redraw on this event
    this.bScrollbarDirty = false;  //  Sometimes when not rendered yet the scrollbar doesn't update properly, this property indicates that it is still off and needs to be corrected
    
    
    this.iAvgRowHeight = 0;     // Average row height used when a row is not rendered yet
    this.iTableHeight = 0;     //  The height of the table in pixels
    
    this.bNoRender = false;    //  Tempolary disables the rendering while initializing or updating the cache
    
    this.iAutoScroll = 0;      //  Used by the kinetic scrolling system to indicate that we are still "scrolling"
    
    this.oInitialFullEvent = null;
    this.bFirstFill = true;

    this.aItemHeightProcess = [];
    
    this.onHorizontalScroll = new df.events.JSHandler();
    this.onVerticalScroll = new df.events.JSHandler();

    this.bDelUpdDim = false;        //  If true a dimension update is scheduled
    this.bDelUpdDimForced = false;  //  If true the scheduled dimension updated is a forced update

    oList._onResize.on(this.onResize, this);

    this._oDimUpdConf = null;   //  Config for pending dimension update
}

genHtml(aHtml){
    aHtml.push('<div class="WebList_BodyWrp">');
    
    
    aHtml.push('<div class="WebList_Body', (this.oL.pbShowSelected ? ' WebList_ShowSelected' : ''), '">');
    
    aHtml.push('<div class="WebList_TableWrp', (this.oL.pbAutoColumnSizing ? " WebList_AutoSize" : " WebList_HorizScroll"), '">');
    aHtml.push('<div class="WebList_Table">');
    
    /* this.tableHtml(aHtml); */
    
    aHtml.push('</div></div></div>');
    aHtml.push('<div class="WebList_Scroll" tabindex="-1"><div class="WebList_Stretcher" style="width: 1px;"></div></div>');
    aHtml.push('</div>');
}

afterRender(eList){
    this.eTableWrp = df.dom.query(eList, "div.WebList_TableWrp");
    this.eTable = df.dom.query(eList, "div.WebList_Table");
    this.eScrollbar = df.dom.query(eList, "div.WebList_Scroll");
    this.eScrollStretch = df.dom.query(eList, "div.WebList_Scroll > div.WebList_Stretcher");
    
    super.afterRender(eList);
    
    
    df.events.addDomMouseWheelListener(this.eBody, this.onMouseWheelScroll, this);
    df.dom.on("scroll", this.eScrollbar, this.onScrollbarScroll, this);
    df.dom.on("scroll", this.eTableWrp, this.onHorizbarScroll, this);
    df.events.addDomCaptureListener("load", this.eTableWrp, this.onContentLoaded, this);
}

afterFirstFill(){
    df.dom.animFrame(function(){
        //  Scroll to the sort column
        if(this.oL.piSortColumn > 0){
            this.scrollToCol(this.oL.piSortColumn);
        }
    }, this);
}

onDataUpdate(oEv){
    let iOffsetTop;

    this.iMaxPX = null;
    if(oEv.sType === "full"){
        if(!this.eBody){
            this.oInitialFullEvent = oEv;
            return;
        }
                
        //  Clear row height (grouping does a refresh without creating new rows)
        this.clearHeightCache();

        this.updateScrollbarSize();
        
        this.bNoRender = true;
        const eRow = this.row(this.oM.sCurrentRowId);
        if(eRow){
            iOffsetTop = eRow.offsetTop - this.iTableOffset;
        }else{
            this.centerCurrentRow();
        }

    
        this.bNoRender = false;
        this.updatePosition(true);
        
        this.dimensionUpdate({
            bUpdateRows : false,
            bUpdateScrollbar : true,
            bForceRedraw : false,
            fFinished : () => {
                if (eRow){
                    this.smartRepositionCurrentRow(iOffsetTop);
                }else{
                    this.centerCurrentRow();
                }

            }
        });
        //  If there is no table height this is probably the initial rendering of the list so we do call centerCurrentRow in the next animation frame when hopefully iTableHeight is figured out.
        if(this.iTableHeight <= 0){
            df.dom.animFrame(function(){
                if(this.iTableHeight > 0){
                    this.centerCurrentRow();
                }
            }, this);
        }

        //  First time trigger afterFirstFill
        if(this.bFirstFill){
            this.bFirstFill = false;
            this.afterFirstFill();
        }
    }
    if(oEv.sType === "next"){
       this.updateScrollbarSize();
    }
    if(oEv.sType === "prev"){
        //  Update display props
        this.iScrollOffsetPx += oEv.iOffsetChange * (this.iAvgRowHeight || 20);
        this.iRowDispOffset += oEv.iOffsetChange;
        this.iRowsDispOffset += oEv.iOffsetChange;
        this.iRowDispLast += oEv.iOffsetChange;
        
        //  Update display
        this.bNoRender = true;
        this.updateScrollbarSize();
        this.eScrollbar.scrollTop = this.eScrollbar.scrollTop  + oEv.iOffsetChange * (this.iAvgRowHeight || 20);
        this.bNoRender = false;
        this.updatePosition();
    }
    if(oEv.sType === "row"){
        this.refreshRow(oEv.sUpdateRowId, oEv.sNewRowId);
    }
    if(oEv.sType === "cell"){
        this.refreshCell(oEv.sUpdateRowId, oEv.oCol);
    }
    if(oEv.sType === "newrow"){
        this.bNoRender = true;
        this.updateScrollbarSize();
        this.scrollToCurrentRow();
        this.bNoRender = false;

        this.updatePosition(true);
    }
    if(oEv.sType === "remrow"){
        this.bNoRender = true;
        this.updateScrollbarSize();
        this.scrollToCurrentRow();
        this.bNoRender = false;

        this.updatePosition(true);
    }
    if(oEv.sType === "display"){
        // Refresh caused by display table change where we want to keep the exact current position
        const iRowDispOffset = this.iRowDispOffset;
        const iTableOffset = this.iTableOffset;

        this.updatePosition(true);
        
        this.dimensionUpdate({
            bUpdateRows : false,
            bUpdateScrollbar : true,
            bForceRedraw : false,
            fFinished : () => {
                const iOffset = this.combinedRowHeightPx(0, iRowDispOffset) + iTableOffset;

                this.scrollTo(iOffset, false, false, false);
                if(oEv.iDisplayItem){
                    this.scrollToDisplayItem(oEv.iDisplayItem);
                }
            }
        });
    }
}

onRowChange(oEv){
    if(this.eBody){
        super.onRowChange(oEv);

        //  If a dimension update is pending we wait for it, else we center directly
        if(this._oDimUpdConf){
            this.dimensionUpdate({
                fFinished : () => {
                    this.scrollToCurrentRow();
                }
            });
        }else{
            this.scrollToCurrentRow();
        }
    }
}


onSettingChange(oEv){
    if(oEv.sType === "redraw"){
        this.updatePosition(true);
    }else if(oEv.sType === "prop" && oEv.sProp === "pbAutoColumnSizing"){
        df.dom.toggleClass(this.eTableWrp, "WebList_AutoSize", this.oL.pbAutoColumnSizing);
        df.dom.toggleClass(this.eTableWrp, "WebList_HorizScroll", !this.oL.pbAutoColumnSizing);
    }else{
        super.onSettingChange(oEv);
    }
}

// - - - - - - - Display & scroll - - - - - - -

/* 
Scrolls the specified amount of pixels up or down.
*/
scroll(iDelta, bSnap, bFromScrollbar){
    let iOffset;
    
    //  Determine new offset
    iOffset = this.iScrollOffsetPx;
    iOffset += iDelta;

    //  We do not check the boundaries because ScrollTo will do that..
    
    //  Perform actual scrolling 
    this.scrollTo(iOffset, bSnap, bFromScrollbar);
}

/* 
Scrolls to the specified offset. It optionally snaps to the closest row. 
*/
scrollTo(iOffset, bSnap, bFromScrollbar, bNoBoundaries){
    if(iOffset !== this.iScrollOffsetPx){
        this.iScrollOffsetPx = iOffset;
        
        //  We do not check boundaries or do snapping as updatePosition does that now
        this.updatePosition(false, bSnap, !!bNoBoundaries);
    
        //  Update scrollbar 
        if(!bFromScrollbar){
            this.updateScrollbarPos(this.iScrollOffsetPx);
        }

        this.onVerticalScroll.fire(this, {
            iScrollOffsetPx : this.iScrollOffsetPx
        });

        this.updateCache();
    }
}

/* 
Updates the display. It calculates which rows should be rendered, updates or refreshes the view, 
and updates the scrollOffset.

@param  bForceRedraw    Enforces a full redraw of the view.
@param  bSnap           Snaps to a specific row.
*/
updatePosition(bForceRedraw, bSnap, bNoBoundaries){
    const oM = this.oM;
    let  iViewOffsetPx, iScrollOffsetPx, iRowViewLast = null, iRowDispLast, iRowDispOffset, iRowScrollOffset = null, 
        iEmptyRows = 0, iTotalPx = 0, iViewEndOffsetPx, iRowPx, iMaxPX, iInitScrollOffsetPx, iViewRowOffsetPx;

    if(!this.eBody || this.bNoRender){
        return;
    }
    const iTableHeight = this.tableHeight();

    bSnap = !!bSnap;
    bNoBoundaries = !!bNoBoundaries;
    bForceRedraw = !!bForceRedraw;

    iMaxPX = this.getMaxPX();
    iInitScrollOffsetPx = iScrollOffsetPx = (bNoBoundaries ? this.iScrollOffsetPx : Math.min(this.iScrollOffsetPx, iMaxPX));
    iViewEndOffsetPx = Math.max(iScrollOffsetPx, 0) + iTableHeight; 
    
    //var sLog = "updatePosition(" + iScrollOffsetPx + ")";

    //  Loop over rows to determine the first & last rendered rows based on the height
    for(let i = 0; i < oM.aDisplay.length; i++){
        iRowPx = this.rowHeightPx(i);

        //  Snapping logic
        if(bSnap && iRowScrollOffset === null && iTotalPx + iRowPx > iScrollOffsetPx && iRowPx < (this.iAvgRowHeight * 1.5)){
            if((iScrollOffsetPx - iTotalPx) < (iRowPx / 2)){
                iScrollOffsetPx = iTotalPx;
            }else{
                iScrollOffsetPx = iTotalPx + iRowPx;
            }
        }

        iTotalPx += iRowPx;
        
        //  Find the first displayed row
        if(iRowScrollOffset === null && iTotalPx >= iScrollOffsetPx){
            if(bNoBoundaries){
                this.iScrollOffsetPx = iScrollOffsetPx;
            }else{
                this.iScrollOffsetPx = iScrollOffsetPx = Math.max(0, Math.min(iScrollOffsetPx, iMaxPX));
            }
            iViewEndOffsetPx = Math.max(iScrollOffsetPx, 0) + iTableHeight;

            iRowScrollOffset = i;
            iViewRowOffsetPx = iTotalPx - iRowPx;
        }

        //  Find the last displayed row
        if(iTotalPx >= iViewEndOffsetPx){
            iRowViewLast = i;
            break;
        }
    }

    //  Snap adjustment for the last row
    if(iMaxPX - iInitScrollOffsetPx < this.iAvgRowHeight * 0.5){
        iScrollOffsetPx = iMaxPX;
    }

    //  If we did not find a start offset
    if(iRowScrollOffset === null){
        if(bNoBoundaries){
            this.iScrollOffsetPx = iScrollOffsetPx;
        }else{
            this.iScrollOffsetPx = iScrollOffsetPx = Math.max(0, Math.min(iScrollOffsetPx, iMaxPX));
        }
        iViewEndOffsetPx = Math.max(iScrollOffsetPx, 0) + this.iTableHeight;

        iRowScrollOffset = 0;
        iViewRowOffsetPx = 0;
    }

    //  If we did not find an end offset
    if(iRowViewLast === null){
        iRowViewLast = Math.max(0, oM.aDisplay.length - 1);
    }
    
    //  See if we need empty rows at the end..
    if(iTotalPx < this.iTableHeight){
        iEmptyRows = (this.iTableHeight - iTotalPx) / (this.iAvgRowHeight || 20) + this.iPrefViewOffset;
    }
    
    //  Calculate the target row offset
    iRowDispOffset = Math.max(iRowScrollOffset - this.iPrefViewOffset, 0);
    iRowDispLast = Math.min(iRowViewLast + this.iPrefViewOffset, oM.aDisplay.length - 1);

    
    //  Choose between full redraw and adjustment. Adjustment is possible if the rows are already in the rendered area. 
    if(bForceRedraw || (iRowScrollOffset < this.iRowDispOffset) || (iRowViewLast > this.iRowDispLast) ||  this.iCalcEmptyRows !== iEmptyRows){
        // sLog += " --refresh list! " + iRowDispOffset + " --> " + iRowDispLast + " --- " + iEmptyRows;
        this.iCalcEmptyRows = iEmptyRows;
        this.iRowDispLast = iRowDispLast;
        this.iRowDispOffset = iRowDispOffset;
        
        this.refreshDisplay();
    }else{
        // sLog += " --adjust list! " + iRowDispOffset + " --> " + iRowDispLast;

        this.adjustDisplay(iRowDispOffset, iRowDispLast);
    }
    
    //  Calculate and update view scroll offset
    iViewOffsetPx = iScrollOffsetPx - (iViewRowOffsetPx - this.combinedRowHeightPx(this.iRowDispOffset, iRowScrollOffset));
    this.updateScrollOffset(iViewOffsetPx);
}

/*
Refreshes the dispay completely by regenerating the table html.
*/
refreshDisplay(){
    const aHtml = [];
    
    //  Warn for excessive rendering
    const iRows = this.iRowDispLast - this.iRowDispOffset;
    if(iRows > 100){
        console.warn(`Painting issue, painting ${iRows} rows`);
    }
    
    this.tableHtml(aHtml);
    
    if(df.sys.isIE){
        while(this.eTable.lastChild){
            this.eTable.removeChild(this.eTable.lastChild);
        }
    }

    this.eTable.innerHTML = aHtml.join('');
    
    //  Notify other modules
    this.onRowsRendered.fire(this);

    this.dimensionUpdate({
        bUpdateRows : true,
        bUpdateScrollbar : true,
        bForceRedraw : false
    });
}

/* 
Augments rowHtml and queues the generated row for height calculation once it is has been rendered.

*/
itemHtml(aHtml, iIndex){
    super.itemHtml(aHtml, iIndex);
    
    this.aItemHeightProcess.push(iIndex);
}

/* 
Overrides the tableHtml function as it now only renders the rows in the current view. It depends on
this.iRowDispOffset, this.iCalcRowDispLast and this.iCalcEmptyRows to be properly set by 
updatePosition.
*/
tableHtml(aHtml){
    const oM = this.oM;
    
    //  Loop rows
    for(let i = this.iRowDispOffset; i <= this.iRowDispLast && i < oM.aDisplay.length; i++){
        this.itemHtml(aHtml, i);
    }

    //  Generate "empty" rows
    for(let i = 0; i < this.iCalcEmptyRows; i++){
        this.oR.rowHtml(null, aHtml, ((i + this.iRowDispLast + 1) % 2==0), oM.aGroups.length, false, false);
    }
}

/* 
Adjusts the display by adding / removing rows on top or the bottom. This is done to improve scroll
performance (instead of full refresh).

@param  iRowDispOffset  The first row to be rendered.
@param  iRowDispLast    The last row to be rendered.
*/
adjustDisplay(iRowDispOffset, iRowDispLast){
    const iAllowedDiff = this.iMaxViewOffsetDiff;
    let bAdd = false;
    
    if(this.iRowDispOffset > iRowDispOffset){
        //  Add rows on top
        if(this.iRowDispOffset > (iRowDispOffset + iAllowedDiff)){
            while(this.iRowDispOffset > iRowDispOffset){
                this.iRowDispOffset--;
                this.insertRow(this.iRowDispOffset, true);
                
                bAdd = true;
            }
        }
        
        //  Remove rows on the bottom
        if(this.iRowDispLast > (iRowDispLast + iAllowedDiff)){
            while(this.iRowDispLast > iRowDispLast){
                this.removeBottomRow();
            }
        }
    }else{
                
        //  Add rows on the bottom
        if(this.iRowDispLast < (iRowDispLast - iAllowedDiff)){
            while(this.iRowDispLast < iRowDispLast){
                this.iRowDispLast++;
                this.insertRow(this.iRowDispLast, false);

                bAdd = true;                
            }
        }
        
        // Remove rows on top
        if(this.iRowDispOffset < (iRowDispOffset - iAllowedDiff)){
            while(this.iRowDispOffset < iRowDispOffset){
                this.removeTopRow();
            }
        }
    }

    if(bAdd){
        //  Notify other modules
        this.onRowsRendered.fire(this);
    }
}

/*
This method removes a single row from the display table. It makes sure the _iRowDispOffset and 
_iViewOffset are properly updated. It is called by the adjustDisplay method.

@private
*/
removeTopRow(){
    if(!this.eTable.firstChild) return;

    
    //  Remove things that are not rows on top first
    while(!this.eTable.firstChild.hasAttribute("data-dfitem")){
        this.eTable.removeChild(this.eTable.firstChild);
    }
    
    if(!this.eTable.firstChild) return;
    this.eTable.removeChild(this.eTable.firstChild);

    this.iRowDispOffset++;
    this.bZebraTop = !this.bZebraTop; 
}

/*
This method removes a single row from the top of the display table. It is called by the 
adjustDisplay method.

@private
*/
removeBottomRow(){
    if(!this.eTable.lastChild) return;

    //  Remove things that are not rows on top first
    while(!this.eTable.firstChild.hasAttribute("data-dfitem")){
        this.eTable.removeChild(this.eTable.lastChild);
    }
    
    if(!this.eTable.lastChild) return;
    this.eTable.removeChild(this.eTable.lastChild);

    this.iRowDispLast--;
    this.bZebraBottom = !this.bZebraBottom;
}

/* 
There are more rows rendered than there are visible. We hide the first extra top rows visible using
CSS translateY.

@param  
*/
updateScrollOffset(iOffset){
    if(this.eTable){
        this.iTableOffset = iOffset;

        df.dom.translateY(this.eTable, -iOffset, true);
        
        if(this.eTableWrp.scrollTop > 0){
            this.eTableWrp.scrollTop = 0;  //  Reset this as it somehow gets scrolled :S
        }
    }
}

/* 
This function inserts a single row into the list using DOM object creation. This is slower as using 
innerHTML but is faster as refreshing the entire table (which needs to be done using innerHTML).

@param  iItemIndex  Index of the inserted display item.
@param  bTop    True if the row needs to be inserted at the top, false for the bottom.
@private
*/
insertRow(iItemIndex, bTop){
    const aHtml = [];

    //  Generate row element
    this.itemHtml(aHtml, iItemIndex);
    const eElem = df.dom.create(aHtml);
    if(bTop){
        this.eTable.prepend(eElem);
    }else{
        this.eTable.appendChild(eElem);
    }
}

/**
 * Clears the height information cached.
 */
clearHeightCache(){
    //  Clear cached row heights as these might change
    this.oM.aDisplay.forEach(tItem => { 
        tItem._iRowHeight = null; 
    });
    
    this.heightCache = {};
}

/**
 * Determines the height of an element by looking at the BoundingClientRect which also includes fractions.
 * 
 * @param {DOM Element} eElem 
 * @returns Height of the element.
 */
realHeight(eElem){
    return eElem?.getBoundingClientRect().height || 0;
}

/**
 * Determines the vertical margin but assumes collapsing and repetition of the element. 
 * 
 * @param {DOM element} eElem 
 * @returns Vertical margin in pixels assuming they are collapsed.
 */
realMargin(eElem){
    const oStyle = df.sys.gui.getCurrentStyle( eElem);
    const iMarginTop = parseFloat(oStyle.marginTop) || 0;
    const iMarginBottom = parseFloat(oStyle.marginBottom) || 0;

    return Math.max(iMarginTop, iMarginBottom);
}

/**
 * Updates the row height of the specified row in the administration (_iRowHeight). It takes header elements into account.
 * 
 * @param {String} iItemIndex 
 * @returns 
 */
updateItemHeight(iItemIndex){
    const oM = this.oM;
    
    const eElem = this.item(iItemIndex); 
    if(!eElem)
        return false;

    // Row body height
    let iHeight = this.realHeight(eElem);

    // Row margins
    const sRowClass = eElem.className;
    if(!this.heightCache.hasOwnProperty(sRowClass)) this.heightCache[sRowClass] = this.realMargin(eElem);
    iHeight += this.heightCache[sRowClass];
    
    const bChange = oM.aDisplay[iItemIndex]._iRowHeight !== iHeight;
    oM.aDisplay[iItemIndex]._iRowHeight = iHeight;
    return bChange;
}

/*
Calculates the average row height and stores it in iAvgRowHeight.
*/
updateAvgRowHeight(){
    let iSum = 0, iCount = 0;

    this.oM.aDisplay.forEach(function(tItem){
        if(tItem._iRowHeight){
            iCount++;
            iSum += tItem._iRowHeight;
        }
    });

    if(iCount){
        this.iAvgRowHeight = iSum / iCount;
    }
    this.iMaxPX = 0;
}

/*
Updates the row heights for all rendered rows. If 
*/
updateRenderedRowHeights(){
    let bChange = false;

    for(let iItem = this.iRowDispOffset; iItem < this.oM.aDisplay.length && iItem <= this.iRowDispLast; iItem++){
        bChange |= this.updateItemHeight(iItem);
    }

    this.aItemHeightProcess = [];
    
    
    if(bChange){
        this.updateAvgRowHeight();
        this.iMaxPX = null;
    }

    return bChange;
}

/*
Processes row height calculations that need to be perfomed.

@return True if row heights have been recalculated.
*/
processRowHeights(){
    let iItemIndex, bChange = false;

    while(iItemIndex = this.aItemHeightProcess.pop()){
        bChange = true;
        this.updateItemHeight(iItemIndex);
    }
    
    if(bChange){
        this.iMaxPX = null;
        this.updateAvgRowHeight();
    }

    return bChange;
}

/*
Determines the row height for a specific row by looking at the cached value (or it takes the average).

@param  iRow    The row index.
@return Row height in pixels.
*/
rowHeightPx(iRow){
    let iHeightPx;
    const tItem = this.oM.aDisplay[iRow];

    if(tItem._iRowHeight){
        iHeightPx = tItem._iRowHeight;
    }else{
        iHeightPx = this.iAvgRowHeight || 20;
    }

    if(tItem.eType == WebListModel.displayTypes.row){
        iHeightPx += this.oM.aData[tItem.iIndex]._iRowHeightExtra || 0;
    }

    return iHeightPx;
}

/*
Calculates the height of multiple rows.

@param  iStart  Start row index.
@param  iTo     End row index.
@return    Total height in pixels.
*/
combinedRowHeightPx(iStart, iTo){
    const oM = this.oM;
    let iHeightPx = 0;

    for(let i = iStart; i < oM.aDisplay.length && i < iTo; i++){
        iHeightPx += this.rowHeightPx(i);
    }

    return iHeightPx;
}

/* 
Snaps the specific offset to the closest row position and returns the snapped offset. Used by touch handler.

@param  iOffsetPx   Offset in pixels.
@return Snapped offset (closest row).
*/
snapToRow(iOffsetPx){
    let iTotalPx = 0;
    const oM = this.oM;

    for(let i = 0; i < oM.aDisplay.length; i++){
        const iRowPx = this.rowHeightPx(i);

        //  Snapping logic
        if(iTotalPx + iRowPx > iOffsetPx){
            if((iOffsetPx - iTotalPx) < (iRowPx / 2)){
                return iTotalPx;
            }else{
                return iTotalPx + iRowPx;
            }
        }

        iTotalPx += iRowPx;
    }

    return iTotalPx;
}


/* 
Determines the maximum scrolling offset in pixels. It looks the height of the list and the height 
per row. It takes extra margin space into account for rows with an margin.
*/
getMaxPX(){
    if(this.iMaxPX){
        return this.iMaxPX;
    }
    return (this.iMaxPX = Math.max(this.combinedRowHeightPx(0, this.oM.aDisplay.length) - this.iTableHeight, 0));
}

/*
Updates the size of the stretch element defining the size of the scrollbar thingy based on the 
current cache.
*/
updateScrollbarSize(){
    const iHeight = this.combinedRowHeightPx(0, this.oM.aDisplay.length);
    
    if(this.eScrollStretch && this.eScrollStretch.clientHeight !== iHeight){
        this.eScrollStretch.style.height = iHeight + "px";
    }
}

/* 
Updates the position displayed by the scrollbar.

@param  iOffset     Offset in pixels from the top of the cache to the first displayed row.
*/
updateScrollbarPos(iOffset){
    let bDirty;
    const that = this;
    
    if(this.eScrollbar){
        this.eScrollbar.scrollTop = this.iLastScrollbarSet = iOffset;
        this.bScrollbarDirty = bDirty = Math.abs(this.eScrollbar.scrollTop - this.iLastScrollbarSet) > 5;
        
        if(bDirty){
            setTimeout(function(){
                if(that.bScrollbarDirty && that.eScrollbar.scrollTop !== that.iLastScrollbarSet){
                    that.eScrollbar.scrollTop = that.iLastScrollbarSet;
                }
                
                that.bScrollbarDirty = false;
            }, 300);
        }  
    }
}

/* 
Handles the scroll event of the scrollbar and will update the scroll position.

@param  oEv     Event object.
*/
onScrollbarScroll(oEv){
    const iOffset = this.eScrollbar.scrollTop;
    
    //  Ignore rounding changes up to 2 pixels and dirty scorllbar events
    if(Math.abs(iOffset - this.iLastScrollbarSet) > 2 && !this.bScrollbarDirty){

        this.iAutoScroll = 0;
        this.iLastScrollbarSet = iOffset;
        this.scrollTo(iOffset, true, true);
    }
}

/* 
Handles the mousewheel event and scrolls the list accordingly. It relies on the scroll function it
snapping logic.

@param  oEv     Event object.
*/
onMouseWheelScroll(oEv){
    const iDelta = oEv.getMouseWheelDelta();
    
    this.iAutoScroll = 0;
    
    if(iDelta > 0){
        //  Scroll up
        this.scroll(-((this.iAvgRowHeight || 20) * 2), true);
        
    }else if(iDelta < 0){
        //  Scroll down
        this.scroll((this.iAvgRowHeight || 20) * 2, true);
    }
    
    oEv.stop();
}

/* 
Triggers a cache update based on the current display boundaries by calling the controller object 
passing the currently displayed rows. The controller wil load extra rows if nessecary. 
*/
updateCache(){
    this.oC.triggerCacheUpdate(this.iRowDispOffset, this.iRowDispLast);
}

/* 
Centers the currently selected row on the screen.
*/
centerCurrentRow(){
    const oM = this.oM;
    
    const iItemIndex = oM.rowIndexToItemIndex(oM.iCurrentRow);
    const iTableHeight = this.tableHeight();
    if(iItemIndex >= 0 && iTableHeight > 0){
        let iOffsetPx = this.combinedRowHeightPx(0, iItemIndex);

        iOffsetPx = iOffsetPx - (iTableHeight / 2) + (this.rowHeightPx(iItemIndex) / 2);

        this.scrollTo(iOffsetPx, true, false);
    }
}

/*
Repositions the selected row based on the passed top offset that was stored before a refresh. This 
top offset is the number of pixels to the first rendered row.

@param  iOffsetTop  Offset to the first rendeeed row we try to restore.
*/
smartRepositionCurrentRow(iOffsetTop){
    const oM = this.oM;

    const iItemIndex = oM.rowIndexToItemIndex(oM.iCurrentRow);
    if(iItemIndex >= 0){
        this.smartRepositionDisplayItem(iItemIndex, iOffsetTop);
    }
}

/**
 * Repositions the display item based on passed top offset. 
 * 
 * @param {Integer} iItemIndex Index in the aDisplay array.
 * @param {Integer} iOffsetTop Offset in pixels to the first rendered row that we try to restore.
 */
smartRepositionDisplayItem(iItemIndex, iOffsetTop){
    let iOffsetPx = this.combinedRowHeightPx(0, iItemIndex);
    iOffsetPx -= iOffsetTop;

    if(iOffsetPx > 0 && iOffsetPx < this.getMaxPX()){
        this.scrollTo(iOffsetPx, true, false);
    }

    this.scrollToDisplayItem(iItemIndex); 
}

/* 
Scrolls to the currently selected row. Note that if the row is already on the screen it does nothing 
so it doesn't always refresh the display.
*/
scrollToCurrentRow(){
    this.scrollToRow(this.oM.sCurrentRowId);
}

/* 
Scrolls to the specified row. Note that if the row is already on the screen it does nothing 
so it doesn't always refresh the display.
*/
scrollToRow(sRowID){
    const oM = this.oM;
    
    let iRow = oM.rowIndexByRowId(sRowID);
    let iItemIndex = oM.rowIndexToItemIndex(iRow);
    if(iItemIndex >= 0){
        this.scrollToDisplayItem(iItemIndex);
    }
}
    
/**
 * Scrolls the specified item into the view.
 * 
 * @param {Integer} iItemIndex Index in the aDisplay array.
 */
scrollToDisplayItem(iItemIndex){
    let iOffsetPx = this.combinedRowHeightPx(0, iItemIndex);
    let iRowPx = this.rowHeightPx(iItemIndex);

    if(iOffsetPx < this.iScrollOffsetPx){
        this.scrollTo(iOffsetPx, true, false);
    }else if(iOffsetPx + iRowPx > this.iScrollOffsetPx + this.iTableHeight){
        iOffsetPx = iOffsetPx + iRowPx - this.iTableHeight; 

        this.scrollTo(iOffsetPx, false, false);
    }
}

scrollToCol(iCol){
    const oL = this.oL;
    let eCell;

    if(!oL.pbAutoColumnSizing){ 
        //  Get a cell element for this col (first try the current row, if not available try the first one available)
        eCell = this.colCellByIndex(iCol); 
        if(!eCell){
            eCell = (this.eBody && df.dom.query(this.eBody, "td[data-dfcol='" + iCol + "']")) || null;
        }

        if(eCell){
            if(eCell.offsetLeft < this.eTableWrp.scrollLeft){
                oL._oBody.scrollToHoriz(eCell.offsetLeft);
            }else if(eCell.offsetLeft + eCell.offsetWidth > (this.eTableWrp.clientWidth + this.eTableWrp.scrollLeft)){
                oL._oBody.scrollToHoriz(Math.min(eCell.offsetLeft, (eCell.offsetLeft + eCell.offsetWidth - this.eTableWrp.clientWidth)));
            }
        }
    }
}

scrollToHoriz(iScrollX){
    this.eTableWrp.scrollLeft = iScrollX;
}

/* 
Gets called during the resize process to set the height of the list. It updates the height of the 
body and scrollbar element.

@param  iHeight     Height to be set in pixels.
*/
setHeight(iHeight){
    iHeight -= df.sys.gui.getVertBoxDiff(this.eBody);
    iHeight -= df.sys.gui.getVertBoxDiff(this.eBodyWrp);
    
    iHeight = Math.max(iHeight, 0);
    
    //  Set the height on the grid body
    this.eBody.style.height = iHeight + "px";
    this.eScrollbar.style.height = (df.dom.clientHeight(this.eTableWrp) || iHeight || 0) + "px";
}

/* 
Determines the dimensions (table height) and detects a change in those. Also triggers a 
processRowHeights to be sure.

@return True if dimensions did change.
*/
determineDimensions(){
    let bChanged = false;
    
    if(this.eBody){
        this.iPrevTableHeight = this.iTableHeight;
        this.iTableHeight = this.eTableWrp.clientHeight || this.iTableHeight;
        
        bChanged = bChanged || this.iPrevTableHeight !== this.iTableHeight || this.iTableWidth !== this.eTableWrp.clientWidth;
        
        this.iTableWidth = this.eTableWrp.clientWidth;
    }
    
    return bChanged;
}

tableHeight(){
    return this.eTableWrp?.clientHeight || this.iTableHeight || 0;     
}

/*
Gives the browser a chance to recalculate the layout and do a repaint. Executes the provided 
function afterwards. Uses requestIdleCallback if availabe since that seems to give the best outcome, 
else it uses animationframe or timeout.

@param fFunc    Function to execute on repaint.
*/
waitForRepaint(fFunc){
    if(window.requestIdleCallback){
        window.requestIdleCallback(fFunc, { timeout : 40 });
    }else if(window.requestAnimationFrame){
        window.requestAnimationFrame(fFunc);
    }else{
        window.setTimeout(fFunc, 40);
    }
}

/*
Looks at the dimensions and updates the UI if nessecary. Steps will only be performed 
if the previous steps detected changes or the config object explicitly turned on a step.

1. Check if the WebList dimension changes.
2. Update all the row heights.
3. Update the scrollbar size.
4. Update the position (causes a redraw of rows if nessecary).
5. Update scrollbar width on header

{
    bUpdateRows : true,
    bUpdateScrollbar : true,
    bForceRedraw : true,
    fFinished : null
}
*/
dimensionUpdate(oConfig){
    oConfig = oConfig  || {};

    //  Save config
    if(this._oDimUpdConf){
        this._oDimUpdConf.bUpdateRows ||= oConfig.bUpdateRows;
        this._oDimUpdConf.bUpdateScrollbar ||= oConfig.bUpdateScrollbar;
        this._oDimUpdConf.bUpdateRows ||= oConfig.bUpdateRows;
        if(oConfig.fFinished){
            this._oDimUpdConf.aFinished.push(oConfig.fFinished);
        }
    }else{
        oConfig.aFinished = (oConfig.fFinished ? [ oConfig.fFinished ] : []);
        this._oDimUpdConf = oConfig;
    }

    this.waitForRepaint(() => {
        const oConfig = this._oDimUpdConf;
        if(!oConfig) return;
        this._oDimUpdConf = null;

        // 1. Check if the WebList dimension changes.
        let bChanged = this.determineDimensions();
    
        // 2. Update all the row heights.
        if (bChanged || oConfig.bUpdateRows){
            bChanged |= this.updateRenderedRowHeights();
        }else{
            bChanged |= this.processRowHeights();
        }

        // 3. Update the scrollbar size.
        if(bChanged  || oConfig.bUpdateScrollbar){
            this.updateScrollbarSize();
        }

        // 4. Update the position (causes a redraw of rows if nessecary).
        if(bChanged  || oConfig.bForceRedraw){
            this.updatePosition(oConfig.bForceRedraw);
        }

        // 5. Update scrollbar width on header
        if (this.eTableWrp)
            this.eTableWrp.style.paddingRight = this.scrollbarWidth() + "px";

        oConfig.aFinished.forEach((fFunc) => fFunc());
    });
}


/* 
Handles the onResize event and makes sure the dimensions are read from the DOM. If they change we 
trigger a redraw.

@param  oEv Event object.
*/
onResize(oEv){
    if(this.oInitialFullEvent){
        //  Render for the first time
        this.dimensionUpdate({
            bUpdateRows : true,
            bUpdateScrollbar : true,
            bForceRedraw : true,
            fFinished : () =>{
                if(this.oInitialFullEvent){
                    this.onDataUpdate(this.oInitialFullEvent);
                    this.oInitialFullEvent = null;
                }
            }
        });
    }else{
        this.dimensionUpdate({
            bUpdateRows : false,
            bUpdateScrollbar : false,
            bForceRedraw : false
        });
    }
}

/*
Captures the load event and makes sure that the size of the row containing the target element gets 
redetermined. This should solve issues with images inside lists that load slower. Unfortunately it
can also cause unnessecary resize operations, but only when a cWebImageColumn is used.

@param  oEv Event object.
*/
onContentLoaded(oEv){
    let eElem = oEv.getTarget();

    while(eElem && eElem !== this.eTableWrp){
        if(eElem.hasAttribute("data-dfrowid")){
            const sRowId = eElem.getAttribute("data-dfrowid");
            if(this.aItemHeightProcess.indexOf(sRowId) <= 0){
                this.aItemHeightProcess.push(sRowId);
                this.dimensionUpdate({
                    bUpdateRows : false,
                    bUpdateScrollbar : false,
                    bForceRedraw : false
                });
            }
            
            return;
        }
        eElem = eElem.parentNode;
    }
}

/* 
Used by the header view to determine the scrollbar width.
*/
scrollbarWidth(){
    return this.eScrollbar && this.eScrollbar.offsetWidth || 0; 
}

/* 
Used by WebListController to determine page size for page up and page down.
*/
getViewSize(){
    const iTableHeight = this.tableHeight();
    if(iTableHeight && this.iAvgRowHeight){
        return iTableHeight / this.iAvgRowHeight;
    }
    return 10;
}

/* 
Sets an extra (temporary) row height for a specific row, this is added to the existing row height. 
The cWebListExpandPanel uses this when expanding a row.

@param  sRowId  RowId of row to set extra height on.
@param  iExtra  The extra height to add to the administration.
*/
setExtraRowHeight(sRowId, iExtra){
    const oM = this.oM;

    const iRow = oM.rowIndexByRowId(sRowId);
    if(iRow >= 0){
        oM.aData[iRow]._iRowHeightExtra = iExtra;
        this.iMaxPX = null;
        this.updateScrollbarSize();
    }
}

/* 
Determines the extra height that is set for a specific row. 

@param  sRowId  RowId of the row to get the extra height of.
@return Extra height in pixels.
*/
getExtraRowHeight(sRowId){
    const oM = this.oM

    const iRow = oM.rowIndexByRowId(sRowId);
    if(iRow >= 0){
        return oM.aData[iRow]._iRowHeightExtra || 0;
    }
}

/* 
Handles the scroll event of the WebList_TableWrp and triggers the onHorizontalScroll event allowing
the header to update its scroll position.

@param  oEv     Event object.
*/
onHorizbarScroll(oEv){
    this.onHorizontalScroll.fire(this, {
        nScrollX : this.eTableWrp.scrollLeft
    });
}



}

export default WebListScrollingView;