import { WebBaseControl } from './WebBaseControl.js';
import { WebListView } from './WebListView.js';
import { WebListScrollingView } from './WebListScrollingView.js';
import { WebListPagedModel } from './WebListPagedModel.js';
import { WebListController } from './WebListController.js';
import { WebListGroupController } from './weblist/WebListGroupController.js';
import { WebListRowModel } from './WebListRowModel.js';
import { WebListHeaderView } from './WebListHeaderView.js';
import { WebListFooterView } from './WebListFooterView.js';
import { WebListTouchHandler } from './WebListTouchHandler.js';
import { WebListPlaceHolderView } from './WebListPlaceHolderView.js';
import { WebListModel } from './WebListModel.js';
import { df } from '../df.js';

/*
Class:
    df.WebList
Extends:
    df.WebBaseControl

This is the client-side representation of the cWebList control which shows a multi column list of 
data. The nested cWebColumn objects represent the grid columns. The cWebCheckboxColumn and 
cWebComboColumn classes will represent different types of columns. The cWebList is readonly and only 
allows the users to select a row. The cWebList can be data bound and then it will automatically find 
records.

The control is implemented using a MVC strategy where there are several views, a model and a 
controller. The following classes are part of this system:
df.WebList
    - Handles communication with the server.
    - Model for the server settings (properties, columns).
df.WebListModel
    - Model for the list data (all data is loaded at once).
df.WebListPagedModel
    - Model for paged list data (loads data in chunks from the server).
df.WebListView
    - Main view showing the list of data that does not support scrolling.
df.WebListScrollingView
    - Extends the list view with the scrolling logic.
df.WebListHeaderView
    - View displaying the header above the list.
df.WebListController
    - Executes row changes.
    - Executes loading of data pages.
df.WebListRowModel
    - Maintains the model of a row (multi line rows, row widths) and is capable of rendering a 
      single row (used by the View classes).
df.WebListTouchHandler
    - Implementation of touch scrolling for the WebListScrollingView and swipe buttons.

Communication between the classes mainly occurs events (onSettingChange, onDataChange, onRowChange) 
thrown by the WebList and the WebListModel. The WebList class (as the API with the server) 
communicates directly with the controller and the views do communicate with the controller. The 
controller on its turn manipulates the model which updates the views.

df.tWebRow = { 
    sRowId : df.tString, 
    sCssClassName : df.tString, 
    aCells : [ { 
        sValue : df.tString,  
        sTooltip : df.tString,
        sCssClassName : df.tString,
        aOptions : [ df.tString ]
    } ] 
};
    
Revision:
    2011/12/02  (HW, DAW) 
        Initial version.
    2017/02/14  (HW, DAW)
        Refactored into mini MVC model.
*/
df.cHideColumnCSS = ' style="visibility:hidden"';   //  Used to hide columns with pbVisible (overridden by the designer)

export class WebList extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tString, "psCurrentRowId", "");
        this.prop(df.tInt, "piCurrentRowIndex", -1);
        this.prop(df.tInt, "piRowCount", 0);

        this.prop(df.tBool, "pbShowHeader", true);
        this.prop(df.tBool, "pbShowFooter", false);
        this.prop(df.tBool, "pbShowSelected", true);

        this.prop(df.tBool, "pbDataAware", true);
        this.prop(df.tInt, "peDbGridType", df.gtAutomatic);
        this.prop(df.tInt, "peGrouping", df.grpDisabled);
        this.prop(df.tBool, "pbOfflineEditing", false);

        this.prop(df.tBool, "pbAutoSearch", true);
        this.prop(df.tBool, "pbColumnSortable", true);
        this.prop(df.tBool, "pbReverseOrdering", true);
        this.prop(df.tInt, "piSortColumn", 0);

        this.prop(df.tInt, "piMinHeight", 0);
        this.prop(df.tInt, "piHeight", 0);
        this.prop(df.tBool, "pbColumnsResizable", true);
        this.prop(df.tBool, "pbAutoColumnSizing", true);

        this.prop(df.tBool, "pbAllowColumnReordering", true);
        this.prop(df.tBool, "pbAllowColumnHiding", true);

        this.prop(df.tBool, "pbStoreColumnLayout", true);
        this.prop(df.tBool, "pbStoreGroupConfig", true);

        this.prop(df.tString, "psPlaceHolder", "");

        this.prop(df.tString, "psKeyBuddy", "");

        this.prop(df.tBool, "pbScroll", true);

        this.prop(df.tBool, "pbGroupsCollapsible", true);
        this.prop(df.tBool, "pbGroupsCollapseByDefault", true);

        this.event("OnRowClick", df.cCallModeWait);

        //  Child objects
        this._aColumns = [];
        this._aSwipeBtns = [];

        //  Modules
        this._oRowRenderer = null;
        this._oModel = null;
        this._oHeader = null;
        this._oBody = null;
        this._oFooter = null;
        this._oTouchHandler = null;
        this._oGrouping = null;

        //  Privates
        this._iColCount = 0;
        this._tRedraw = null;
        this._bLozingFocus = false;
        this._bScrollQueued = false;

        this._onSettingChange = new df.events.JSHandler();
        this._onResize = new df.events.JSHandler();
        this._onModulesCreated = new df.events.JSHandler();
        this._onKeyDown = new df.events.JSHandler();

        this.addSync("piCurrentRowIndex");
        this.addSync("psCurrentRowId");
        this.addSync("piRowCount");

        //  Actions we need to wait for due to integrety
        this.setActionMode("HandleProcessDataSet", df.cCallModeWait);
        this.setActionMode("ChangeCurrentRow", df.cCallModeWait);

        this.event("OnColumnLayoutChanged", df.cCallModeDefault);
        this.event("OnGroupConfigChanged", df.cCallModeDefault);
        this.event("OnGroupHeaderToggle", df.cCallModeDefault);

        this._sControlClass = "WebList";
    }

    /*
    Augmenting the addChild method to filter out columns and the swipe buttons.
    
    @private
    */
    addChild(oChild) {
        if (oChild._bIsColumn) {
            oChild._iColIndex = this._iColCount++;
            oChild._iCol = this._aColumns.length;
            this._aColumns.push(oChild);
        }
        if (oChild._bIsSwipeButton) {
            oChild._iColIndex = this._iColCount++;
            this._aSwipeBtns.push(oChild);
        }

        super.addChild(oChild);
    }

    /* 
    Initializes the modules that make the WebList component.
    */
    create() {
        this.recordColumnMapperDefaults(); // Save the initial defaults for later.
        this.loadLayout(true, false);      // Load any client stored settings but do not draw.
        this.rebuildColumnMapper(false);   // Build the initial mapper but without redraw, that comes later...

        this._oModel = this.createModel();
        this._oController = this.createController();

        this._oRowRenderer = this.createRowModel();

        this._oHeader = this.createHeaderView();
        this._oBody = this.createView();
        this._oFooter = this.createFooterView();

        this._oTouchHandler = this.createTouchHandler();

        this._oPlaceHolder = this.createPlaceHolder();

        this._oGrouping = this.createGrouping();

        this._oRowRenderer.init();

        this._onModulesCreated.fire(this);
    }

    /**
     * Initializes the grouping controller.
     * 
     * @returns WebListGroupController instance.
     * @private
     */
    createGrouping() {
        return new WebListGroupController(this, this._oModel, this._oController);
    }

    /**
     * Called from DataFlex to configure automatic grouping. Grouping config is passed as action data.
     * 
     * @param {String} bOverrideDefault True if this should override the grouping loaded from the store.
     * @clientaction
     */
    applyGroupConfig(bOverrideDefault) {
        this._oGrouping?.applyGroupConfig(df.toBool(bOverrideDefault), this._tActionData);
    }

    /**
     * Called from DataFlex to clear automatic grouping.
     * 
     * @clientaction
     */
    clearGroupConfig() {
        this._oGrouping?.clearGrouping();
    }

    /*
    This function returns the main storage name.
    
    Since a lot DataFlex applications run behind ISS as a directory instead of a subdomain,
    We will take up the host {domain + port} and the pathname {/WebOrder_199} into the name as prefix.
    
    @param sPostFix can be provided as an additional storage specifier and appends to the storage name with @ + value.
    @returns The final storage name of the current WebObject.
    */
    getStorageName(sPostFix) {
        if (sPostFix && sPostFix.length > 0) {
            return window.location.host +
                "." + window.location.pathname +
                "." + this.getLongName() +
                "@" + sPostFix;
        }

        return window.location.host +
            "." + window.location.pathname +
            "." + this.getLongName();
    }

    /*
    This function serializes all columns into its layout equivalents.
    
    It loops through all columns and creates an array of tWebColumnLayout's.
    
    @returns Array of tWebColumnLayout's.
    */
    serializeLayout() {
        const aLayout = [];

        for (let i = 0; i < this._aColumns.length; i++) {
            let oColLayout = {};
            oColLayout.sObjName = this._aColumns[i].getLongName();

            oColLayout.bFixed = this._aColumns[i].pbFixedWidth;
            oColLayout.iWidth = this._aColumns[i].piWidth;

            oColLayout.iPosition = this._aColumns[i].piPosition;
            oColLayout.bHidden = this._aColumns[i].pbHidden;

            aLayout.push(oColLayout);
        }

        return aLayout;
    }

    /*
    loadLayout returns either null or the a stored tWebColumnLayout array that are cached on the client.
    
    !!!This function is ignored if dfdebug=true is specified.!!!
    
    @param bLoadIntoMapper also restores them into the mapper as it sees fit.
    @param bRedraw orders it to visualize the loaded layout afterwards, only works with bLoadIntoMapper on true.
    @returns The stored layout.
    */
    loadLayout(bLoadIntoMapper, bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        let aLayout = null;
        if (this.pbStoreColumnLayout && !df.pbDebugging) {
            const sLayout = localStorage.getItem(this.getStorageName("layout"));
            if (sLayout) {
                try {
                    aLayout = JSON.parse(sLayout);

                    if (aLayout.length !== this._aColumns.length)
                        return null;

                    for (let i = 0; i < aLayout.length; i++) {
                        if (aLayout[i].sObjName !== this._aColumns[i].getLongName())
                            return null;
                    }
                } catch (ex) {
                    if (sLayout) { // Remove invalid cache.
                        localStorage.removeItem(this.getStorageName("layout"));
                    }
                    return null;
                }
            }

            if (aLayout && bLoadIntoMapper) {
                this.restoreColumnMapper(bRedraw, aLayout);
            }
        }

        return aLayout;
    }

    /*
    saveLayout stores the provided layout in the client's storage.
    
    !!!This function is ignored if dfdebug=true is specified.!!!
    
    @param aLayout the layout to store (tWebColumnLayout[]).
    */
    saveLayout(aLayout) {
        if (this.pbStoreColumnLayout && !df.pbDebugging) {
            try {
                localStorage.setItem(this.getStorageName("layout"), JSON.stringify(aLayout));
            } catch (ex) {
                // Ignore
            }
        }
    }

    /*
    triggerLayoutChange is thrown when a change is made to the layout.
    
    It saved the layout if the settings allow it and will throw a ColumnLayoutChanged event.
    */
    triggerLayoutChange(hSender) {
        const aLayout = this.serializeLayout();

        this.saveLayout(aLayout);

        this.fireEx({
            sEvent: "OnColumnLayoutChanged",
            tActionData: aLayout,
            sAltServerName: "privateOnColumnLayoutChanged"
        });
    }

    /*
    This function records the essential defaults for the position, pbRender, pbHidden for the resetting of the layout.
    */
    recordColumnMapperDefaults() {
        this._defaultLayout = this.serializeLayout();
    }

    /*
    This function restores all defaults of all columns.
    It already updates the mapper for us.
    */
    restoreColumnMapperDefaults() {
        this.restoreColumnMapper(true, this._defaultLayout);
    }

    /*
    This sets the mapper to the provided layout.
    
    It will set all column settings and redraw if desired.
    If the call is from the server it will use the actionData.
    
    @param bRedraw indicates whether to redraw.
    @param aLayout the layout to restore.
    @actionData optional should the call come from the server, parameter has priority.
    */
    restoreColumnMapper(bRedraw, aLayout) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        // If called from the server, apply the action data.
        if (Array.isArray(this._tActionData) && !Array.isArray(aLayout)) aLayout = this._tActionData;
        if (!Array.isArray(aLayout)) return;

        // Create a lookup set so that it is O(N) + O(1) instead of O(N^2)
        const lookupSet = [];
        for (let i = 0; i < this._aColumns.length; i++) {
            lookupSet[this._aColumns[i].getLongName()] = this._aColumns[i];
        }

        try {
            // Set all settings on the looked up ref.
            for (let i = 0; i < aLayout.length; i++) {
                const oColumnRef = lookupSet[aLayout[i].sObjName];
                if (oColumnRef) {
                    oColumnRef.pbFixedWidth = aLayout[i].bFixed;
                    oColumnRef.piWidth = aLayout[i].iWidth;
                    oColumnRef.piPosition = aLayout[i].iPosition;
                    oColumnRef.pbHidden = aLayout[i].bHidden;
                }
            }

            // Save the layout.
            aLayout = this.serializeLayout();
            this.saveLayout(aLayout);
            // Rebuild but do not redraw.
            this.rebuildColumnMapper(false);

            if (bRedraw) this.redraw();
        } catch (ex) {
            // If the server messes up or anything with the property names.
            // Ignore it, though this will most likely never happen.
        }
    }

    /*
    This function recreates the column mapper and should redraw afterwards to take effect.
    It also reorders the piPositions of all columns.
    */
    rebuildColumnMapper(bRedraw) {
        if (typeof bRedraw != "boolean") bRedraw = true;

        this._aColumnMapper = [];   // Initially contains positioned but unsorted columns.
        const aIndifferent = [];      // Contains all non-positioned columns (piPosition -1).

        for (let i = 0; i < this._aColumns.length; i++) {
            // Add them to an array based on their position.
            if (this._aColumns[i].piPosition !== -1) {
                this._aColumnMapper.push(this._aColumns[i]);
            } else {
                aIndifferent.push(this._aColumns[i])
            }
        }

        // Then we are going to sort the positioned array using the built in algorithm.
        this._aColumnMapper.sort(function (a, b) {
            const x = a.piPosition, y = b.piPosition;
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        });

        // Then we fill in the blanks as we have possilibly have some indifferent columns.
        let iIndex = 0;
        if (this._aColumnMapper.length > 0) {
            do {
                if (this._aColumnMapper[iIndex].piPosition !== iIndex) {
                    if (aIndifferent.length > 0) {
                        this._aColumnMapper.splice(iIndex, 0, aIndifferent[0]);
                        aIndifferent.splice(0, 1);
                    }
                    this._aColumnMapper[iIndex].piPosition = iIndex;
                }

            } while (++iIndex < this._aColumnMapper.length)
        }

        this._aColumnMapper = this._aColumnMapper.concat(aIndifferent); // Should we have any left? add those as well.
        if (aIndifferent.length > 0) {
            do {
                this._aColumnMapper[iIndex].piPosition = iIndex;
            } while (++iIndex < this._aColumnMapper.length)
        }

        if (bRedraw) this.redraw();
    }

    triggerRebuildHeaderMenu() {
        return this._oHeader.refreshColumnList();
    }

    triggerRestoreColumnLayout(hSender) {
        this.restoreColumnMapperDefaults(true); // Restore and redraw.
        this.triggerLayoutChange(hSender);
    }

    /* 
    Creates the view (body) module. Can be augmented for customization.
    */
    createView() {
        if (this.pbScroll) {
            return new WebListScrollingView(this, this._oModel, this._oController);
        } else {
            return new WebListView(this, this._oModel, this._oController);
        }
    }

    /* 
    Creates the controller module. Can be augmented for customization.
    */
    createController() {
        return new WebListController(this, this._oModel);
    }

    /* 
    Creates the model module. Can be augmented for customization.
    */
    createModel() {
        if (this.peDbGridType === df.gtAllData || this.peDbGridType === df.gtManual || !this.pbDataAware || !this.pbScroll) {
            return new WebListModel(this);
        } else {
            return new WebListPagedModel(this);
        }
    }

    /*
    Creates the row model module. Can be augmented for customization.
    */
    createRowModel() {
        return new WebListRowModel(this, this._oModel);
    }

    /*
    Creates the header view module. Can be augmented for customization.
    */
    createHeaderView() {
        return new WebListHeaderView(this, this._oModel, this._oController);
    }

    /*
    Creates the footer view module. Can be augmented for customization.
    */
    createFooterView() {
        return new WebListFooterView(this, this._oModel, this._oController);
    }

    /*
    Creates the place holder view module. Can be augmented for customization.
    */
    createPlaceHolder() {
        return new WebListPlaceHolderView(this, this._oModel);
    }

    /*
    Creates the touch handler module. Can be augmented for customization.
    */
    createTouchHandler() {
        return new WebListTouchHandler(this, this._oBody, this._oModel, this._oController);
    }

    focusHtml(aHtml){
        aHtml.push('<div class="WebList_Focus" tabindex="', (this.isEnabled() ? '0' : '-1'), '">');
    }

    openHtml(aHtml, bSkip) {
        super.openHtml(aHtml);

    
        this.focusHtml(aHtml);
        this._oHeader?.genHtml(aHtml);
        this._oBody?.genHtml(aHtml);
        this._oFooter?.genHtml(aHtml);
        this._oPlaceHolder?.genHtml(aHtml);
    }

    closeHtml(aHtml) {
        aHtml.push('</div>');

        super.closeHtml(aHtml);
    }

    afterRender() {

        this._eControl = this._eFocus = df.dom.query(this._eElem, 'div.WebList_Focus');

        
        this._oHeader?.afterRender(this._eElem);
        
        this._oBody?.afterRender(this._eElem);

        
        this._oFooter?.afterRender(this._eElem);

        this._oPlaceHolder?.afterRender(this._eElem);
        this._oTouchHandler?.afterRender(this._eElem);

        super.afterRender();

        this.updateEnabled();
        
        if(this._eFocus){
            df.dom.on("keydown", this._eFocus, this.onKeyDown, this);
            df.dom.on("keypress", this._eFocus, this.onKeyPress, this);
            df.dom.on("click", this._eElem, this.onListClick, this);
        }

        //  We set _bRenderChildren to true so that events like afterShow properly reach columns components (needed for previewer as well)
        this._bRenderChildren = true;

        //  Attach key handler to key buddy control when set
        if (this.psKeyBuddy) {
            const oObj = this.getWebApp().findObj(this.psKeyBuddy);
            if (oObj) {
                if (oObj instanceof WebBaseControl) {
                    this._eKeyBuddy = oObj._eControl;
                }
                if (!this._eKeyBuddy) {
                    this._eKeyBuddy = oObj._eElem;
                }

                df.events.addDomListener("keydown", this._eKeyBuddy, this.onKeyDown, this);
            }
        }

        this.dragDropInit();
    }

    afterRenderChildren() {

    }

    /* 
    Called by the WebBaseControl sizing logic when the height of the control changes and during i
    nitialization.
    
    @param  iHeight     The height in pixels (0 if it should size naturally).
    @param  bSense      If false the size is expected to not be the final size.
    */
    setHeight(iHeight, bSense) {
        if (this._eControl) {
            //  If a negative value is given we should size 'naturally'
            if (iHeight > 0) {
                iHeight -= this.getVertHeightDiff();

                iHeight = (iHeight < 0 ? 0 : iHeight);  //  FIX: IE8 doesn't handle negative values real well and this seems to happen somehow

                //  Set the height
                this._oBody.setHeight(iHeight);
            } else {
                this._oBody.setHeight(0);
            }

        }
    }

    /*
    Augment the add the header height diff.
    
    @return Height difference in pixels.
    @private
    */
    getVertHeightDiff() {
        let iResult = super.getVertHeightDiff();

        if (this._oHeader) {
            iResult += this._oHeader.offsetHeight();
        }

        if (this._oFooter) {
            iResult += this._oFooter.offsetHeight();
        }

        return iResult;
    }

    resize() {
        this._onResize.fire(this);

        super.resize();
    }

    /*
    Handles the keypress event and will initiate the auto search if needed. The keypress is used because 
    we need the character code and are not interested in special keys anyway. 
    
    @param  oEv  The event object.
    @private
    */
    onKeyPress(oEv) {
        //  Check enabled state
        if (!this.isEnabled()) {
            return;
        }

        return this._oController.keyPress(oEv);
    }

    /*
    This method handles the keypress event and initiates the actions bound to it. The 
    df.settings.listKeys define the exact key code's / combinations for the different actions.
    
    @param  oEv  The event object.
    @return False if we did handle the event and performed an action, true if we didn't do anything.
    */
    onKeyDown(oEv) {
        //  Check enabled state
        if (!this.isEnabled()) {
            return;
        }

        return this._onKeyDown.fire(this, { oDOMEvent: oEv }); //this._oController.keyDown(oEv);    
    }

    /* 
    Augments applyEnabled to set the tabindex attribute of the control element.
    
    @param  bVal    The enabled state.
    */
    applyEnabled(bVal) {
        if (this._eFocus) {
            df.dom.setTabIndex(this._eFocus, (bVal ? 0 : -1));
        }

        super.applyEnabled(bVal);
    }

    //  - - - - Server API - - - -

    /*
    
    @client-action
    */
    gridRefresh(bFirst, bLast) {
        const webListData = this._tActionData;

        //  Cancel row change and row click because we are going to refresh the data set and the row might not exist any more
        this.cancelServerAction("ChangeCurrentRow");
        this.cancelServerAction("OnRowClick");  //  Also cancel onclick as this causes problems because of the assumption that the ChangeCurrentRow has been executed

        this._oController.handleData(webListData, "page", "", df.toBool(bFirst), df.toBool(bLast));
    }

    /*
    This function handles a new page of data and adds it to the cache. Depending on the sType parameter 
    it will add or replace the cache. After this it will refresh the display.
    
    @client-action
    */
    handleDataPage(sType, sStartRowId, bFirst, bLast) {
        const webListData = this._tActionData;

        this._oController.handleData(webListData, sType, sStartRowId, df.toBool(bFirst), df.toBool(bLast));
    }

    /* 
    Called during the row change process.
    
    @param  bVal    True if row change was successful.
    @client-action
    */
    handleRowChange(bVal) {
        this._oController.handleRowChange(bVal);
    }

    /*
    This method is called by the server to update a single row in the cache or on the display; it is 
    usually called after a save. If sRowID is empty then it means that a new row is saved which is added 
    to the cache at the last location where a new row was displayed.
    
    @param  sRowID  The original rowid of the row to be updated; empty string if it's a new row.
    
    
    @client-action
    */
    updateRow(sRowId, bMergeRow) {
        const aRows = this.deserializeRows(this._tActionData);

        if (aRows.length > 0) {
            this._oController.updateRow(sRowId, aRows[0], df.toBool(bMergeRow));
        }
    }

    /* 
    Appends the received row (action data) to the list. Should only be used on non data aware lists.
    
    @client-action
    */
    dataSetAppendRow() {
        const aRows = this.deserializeRows(this._tActionData);

        if (aRows.length > 0) {
            this._oController.appendRow(aRows[0]);
        }
    }

    /* 
    Inserts the received row (action data) to the list. Should only be used on non data aware lists.
    
    @param  sBeforeRowID    RowID of the row indicating the position where the row should be inserted 
                            into the list.
    @client-action
    */
    dataSetInsertRowBefore(sBeforeRowID) {
        const aRows = this.deserializeRows(this._tActionData);

        if (aRows.length > 0) {
            this._oController.insertBefore(sBeforeRowID, aRows[0]);
        }
    }

    /* 
    Inserts the received row (action data) to the list. Should only be used on non data aware lists.
    
    @param  sAfterRowID    RowID of the row indicating the position where the row should be inserted 
                            into the list.
    @client-action
    */
    dataSetInsertRowAfter(sAfterRowID) {
        const aRows = this.deserializeRows(this._tActionData);

        if (aRows.length > 0) {
            this._oController.insertAfter(sAfterRowID, aRows[0]);
        }
    }

    /* 
    Removes a row from the list. Should only be used on non data aware lists.
    
    @param  sRowID  RowID indicating which row to remove.
    @client-action
    */
    dataSetRemoveRow(sRowId) {
        this._oController.removeRow(sRowId);
    }

    /* 
    Updates a row in the list based on the row passed in the action data.
    
    @param  sRowID  RowID indicating which row needs to be updated.
    @client-action
    */
    dataSetUpdateRow(sRowID) {
        const aRows = this.deserializeRows(this._tActionData);

        if (aRows.length > 0) {
            this._oController.updateRow(aRows[0].sRowId, aRows[0]);
        }
    }



    /*
    This method is called by the server to update the cache when a row is deleted. It removes the row 
    from the cache and updates the display.
    
    @param  sRowID   The unique ID of the row that is deleted.
    
    @client-action
    */
    removeRow(sRowId) {
        this._oController.removeRow(sRowId);
    }

    /*
    Augment the processDataSet function so that it copies data from the DEO’s to the cache before 
    sending the data to the server.
    
    @client-action
    */
    processDataSet(eOperation) {
        this._oController.processDataSet(eOperation);
    }

    /*
    Scrolls to the first record and selects it. It is called by the keyboard handler or from the server. 
    In case of a static grid it will directly call the selectRow function to select the first row, for a 
    non-static grid (pbDataAware is true or peDbGridType is not gtAutomatic) it will always refresh the 
    cache by loading the first page of records. Note that when pbOfflineEditing is true we need to load 
    the first cache page before changing rows.
    
    @client-action
    */
    moveToFirstRow() {
        this._oController.moveToFirstRow();
    }

    /*
    Scrolls to the last record and selects it. It is called by the keyboard handler or from the server. 
    In case of a static grid it will directly call the selectRow function to select the last row, for a 
    non-static grid (pbDataAware is true or peDbGridType is not gtAutomatic) it will always refresh the 
    cache by loading the last page of records. Note that when pbOfflineEditing is true we need to load 
    the last cache page before changing rows.
    
    @client-action
    */
    moveToLastRow() {
        this._oController.moveToLastRow();
    }

    /*
    This method selects the next row available in the cache and returns true if successful. It is called 
    by the key handler or the server.
    
    @return True if a next row is available.
    @client-action
    */
    moveDownRow() {
        this._oController.moveDownRow();
    }

    /*
    This method selects the previous row available in the cache and returns true if successful. It is 
    called by the key handler or the server.
    
    @return True if a previous row is available.
    @client-action
    */
    moveUpRow() {
        this._oController.moveUpRow();
    }

    /*
    This method performs a page down which means that it select the record one page down in the cache 
    and scrolls to it. A page in this context means the amount of rows that fit inside the grid view. It 
    is called by the key handler or the server.
    
    @client-action
    */
    movePageDown() {
        this._oController.movePageDown();
    }

    /*
    This method performs a page up which means that it select the record one page up in the cache and 
    scrolls to it. A page in this context means the amount of rows that fit inside the grid view. It is 
    called by the key handler or the server.
    
    @client-action
    */
    movePageUp() {
        this._oController.movePageUp();
    }

    /*
    This method moves to a specific row based on its row index.
    
    @client-action
    */
    moveToRow(iRowIndex) {
        this._oController.moveToRow(iRowIndex);
    }

    /*
    This method moves to a specific row based on its unique row ID.
    
    @client-action
    */
    moveToRowByID(sRowId) {
        this._oController.moveToRowByID(sRowId);
    }

    /* 
    This method scrolls horizontally to make sure a column is visible.
    
    @param  iCol    Column index.
    @client-action
    */
    scrollToCol(iCol) {
        if (this.pbScroll && this._oBody) {
            this._oBody.scrollToCol(iCol);
        }
    }

    /*
    @client-action
    */
    search(sSearch) {
        this._oController.search(sSearch);
    }

    /*
    @client-action
    */
    showSearch(sSearch) {
        this._oController.showSearch(sSearch);
    }

    expandAllGroups() {
        this._oGrouping?.expandAll();
    }

    collapseAllGroups() {
        this._oGrouping?.collapseAll();
    }

    set_psCurrentRowId(sVal) {
        if (this._oController) {
            this._oController.setCurrentRowId(sVal);
        }
    }

    set_pbAllowColumnReordering(bVal) {
        if (this.pbAllowColumnReordering !== bVal) {
            this._oHeader.setColumnReordering(this.pbAllowColumnReordering = bVal);
        }
    }

    set_pbAllowColumnHiding(bVal) {
        if (this.pbAllowColumnHiding !== bVal) {
            this._oHeader.setColumnHiding(this.pbAllowColumnHiding = bVal);
        }
    }

    get_psCurrentRowId() {
        return this.currentRowId();
    }
    get_piRowCount() {
        return (this._oModel && this._oModel.aData.length) || 0;
    }
    get_piCurrentRowIndex() {
        return (this._oModel && this._oModel.iCurrentRow);
    }

    set_piSortColumn(iVal) {
        this.propertyUpdate("piSortColumn", iVal);
    }
    set_pbReverseOrdering(bVal) {
        this.propertyUpdate("pbReverseOrdering", bVal);
    }
    set_psPlaceHolder(bVal) {
        this.propertyUpdate("psPlaceHolder", bVal);
    }
    set_pbShowHeader(bVal) {
        this.propertyUpdate("pbShowHeader", bVal);
    }
    set_pbShowFooter(bVal) {
        this.propertyUpdate("pbShowFooter", bVal);
    }
    set_pbShowSelected(bVal) {
        this.propertyUpdate("pbShowSelected", bVal);
    }
    set_pbColumnsResizable(bVal) {
        this.propertyUpdate("pbColumnsResizable", bVal);
    }
    set_pbAutoColumnSizing(bVal) {
        this.propertyUpdate("pbAutoColumnSizing", bVal);
        this.redraw();
    }
    set_pbGroupsCollapsible(bVal) {
        this.propertyUpdate("pbGroupsCollapsible", bVal);
    }
    set_pbGroupsCollapseByDefault(bVal) {
        this.propertyUpdate("pbGroupsCollapseByDefault", bVal);
    }

    // - - - - Supportive - - - -

    /* 
    Handles the update of a property by triggering onSettingChange so the modules can respond to the 
    change. It first stores the new values.
    
    @param  sProp   Name of the property.
    @param  val     The new value.
    */
    propertyUpdate(sProp, val) {

        if (this[sProp] !== val) {
            const prev = this[sProp];
            this[sProp] = val;
            this._onSettingChange.fire(this, {
                sType: "prop",
                sProp: sProp,
                newval: val,
                prevval: prev
            });
        }
    }

    /* 
    Called by the column object when its psValue is being updated.
    
    
    @param  oCol    The column object.
    @param  sVal    The new value.
    */
    updateCurrentCell(oCol, sVal) {
        this._oController.updateCell(oCol, sVal);
    }

    /* 
    Function that is called mainly by columns if their properties have changed. Forces a full redraw of 
    the grid after a short timeout. This timeout is added so that call handlers (like HandleChangeRow) 
    are not disturbed.
    */
    redraw() {
        const that = this;

        if (this._tRedraw) {
            clearTimeout(this._tRedraw);
        }

        this._tRedraw = setTimeout(function () {
            that._onSettingChange.fire(that, {
                sType: "prepare-redraw"
            });
            that._onSettingChange.fire(that, {
                sType: "redraw"
            });

            that._tRedraw = null;
        }, 10);
    }

    /*
    On destroy we clear any timeouts to prevent errors.
    */
    destroy(){
        super.destroy();

        if(this._tRedraw){
            clearTimeout(this._tRedraw);
        }
    }

    /*
    Inserts a single object (and its children) into the child structure of this object, 
    at a specific index.
    */
    insertChild(oChild, iIndex) {
        if (oChild._bIsColumn) {
            oChild._iColIndex = this._iColCount++;
            oChild._iCol = this._aColumns.length;
            this._aColumns.splice(iIndex, 0, oChild);
        }
        if (oChild._bIsSwipeButton) {
            oChild._iColIndex = this._iColCount++;
            this._aSwipeBtns.splice(iIndex, 0, oChild);
        }

        super.insertChild(oChild, iIndex);
    }

    /*
    Renders a specific child object. 
    eOptChild is an optional parameter that contains an existing DOM object for this web object.
    */
    renderChild(oChild, eOptChild) {
        this.redraw();
        super.renderChild(oChild, eOptChild);
    }

    /*
    Removes a child object from the parent's list of children.
    */
    removeChild(oChild) {
        const iIndex = this._aChildren.indexOf(oChild);

        if (oChild._bIsColumn) {
            oChild._iColIndex = this._iColCount--;
            oChild._iCol = this._aColumns.length;
            this._aColumns.splice(iIndex, 1);
        }
        if (oChild._bIsSwipeButton) {
            oChild._iColIndex = this._iColCount--;
            this._aSwipeBtns.splice(iIndex, 1);
        }

        super.removeChild(oChild);
    }

    /* 
    Unrenders a child object.
    */
    unrenderChild(oChild) {
        this.redraw();
        super.unrenderChild(oChild);
    }

    /* 
    Finds the cell element that belongs to this column for the current row.
    
    @param  oCol    Column object (df.WebColumn).
    @return DOM element (TD) for the column (null if not found / available).
    */
    getColCell(oCol) {
        return this._oBody.colCell(oCol);
    }

    /* 
    Finds the header cell for the specified column.
    
    @param  oCol    Column object (df.WebColumn).
    @return DOM element (TH) for the column header (null if not found / available).
    */
    getColHead(oCol) {
        return this._oHeader.colCell(oCol);
    }


    /* 
    Finds the cell element for the specified row and column.
    
    @param  iRow    Row number for which we want the cell element.
    @param  iCol    Column number for the cell.
    @return DOM element (TD) for the column (null if not found / available).
    */
    getCell(iRow, iCol) {
        const sRowId = this._oModel.rowIdByRowIndex(iRow);

        return this._oBody.cell(sRowId, iCol);
    }

    currentRowId() {
        return (this._oModel && this._oModel.sCurrentRowId) || "";
    }

    // - - - - - - - Focus - - - - - - -
    /*
    We override the focus method and make it give the focus to the hidden focus holder element.
    
    @return True if the List can take the focus.
    */
    focus() {
        if (this._bFocusAble && this.isEnabled() && this._eFocus) {
            this._eFocus.focus();

            this.objFocus();
            return true;
        }

        return false;
    }

    onListClick(oEv) {
        this.focus();
    }

    onFocus(oEvent) {
        if (!this._bHasFocus) {
            super.onFocus(oEvent);
        }

        this._bLozingFocus = false;
    }

    /*
    When a blur event is catched we don't know if it is a focus change within the list / grid (change 
    between columns) or really a change to somewhere else. So we use setTimeout to wait for a focus 
    event before we forward the onBlur to WebBaseControl.
    
    @param  oEvent  df.DomEvent
    */
    onBlur(oEvent) {
        const that = this;
        const superFunction = super.onBlur

        this._bLozingFocus = true;

        setTimeout(function () {
            if (that._bLozingFocus) {
                superFunction.call(that, oEvent);

                that._bLozingFocus = false;
            }
        }, 20);
    }

    /*
    Checks if the list has the focus. When the list is within the blur timeout (lozing focus) it will 
    figure out if another control outside the list has registered itself as focussed object.
    */
    hasFocus() {
        if (this._bHasFocus) {
            if (this._bLozingFocus) {
                //  Check if an object outside of the list has registered itself as the focussed object
                let oFocusObj = this.getWebApp()._oCurrentObj;
                while (oFocusObj != this && oFocusObj._oParent) {
                    oFocusObj = oFocusObj._oParent;
                }
                return oFocusObj == this;
            } else {
                return true;
            }
        }

        return false;
    }

    // WebUIContext

    bindHandlerForWebUIContext(oObj, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextListHead:
                this._oHeader?.registerHeaderMenu(oObj);
        }
        return true;
    }

    unbindHandlerForWebUIContext(oObj, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextListHead:
                this._oHeader?.unregisterHeaderMenu(oObj);
        }
        return true;
    }

    determineSelectorForWebUIContext(eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextListHead:
                return ".WebList_ColHead";
            case df.WebUIContext.WebUIContextListRow:
                return "table[data-dfrowid]";
            case df.WebUIContext.WebUIContextListFull:
                return "";
        }
        return null;
    }

    retrieveValueFromWebUIContext(eElem, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextListHead: {
                let eCaption = df.dom.query(eElem, '.WebList_ColCap');
                if (!eCaption)
                    return "";
                return eCaption.innerHTML;
            }
            case df.WebUIContext.WebUIContextListRow: {
                if (!eElem.hasAttribute('data-dfrowid'))
                    break;
                return eElem.getAttribute('data-dfrowid')
            }
            case df.WebUIContext.WebUIContextListFull: {
                let eIter = eElem;
                while (eIter && eIter.hasAttribute &&
                    !eIter.hasAttribute("data-dfrowid") &&
                    eIter != this._eElem) {
                    eIter = eIter.parentNode;
                }
                if (!(eIter?.hasAttribute('data-dfrowid')))
                    return "";
                return eIter.getAttribute('data-dfrowid')
            }
        }
        return null;
    }

    // Dragdrop

    getDragData(oEv, eDraggedElem) {
        try {
            const itemId = eDraggedElem.closest("table")?.getAttribute("data-dfrowid") || -1;
            let item;

            if (itemId && itemId != "empty" && itemId != -1 && (itemId != '' || itemId >= 0)) {
                // Destructure object to create a clone, then remove any privates - prevents circular json eror
                item = { ...this._oModel.aData[(this._oModel.rowIndexByRowId(itemId))] };

                Object.keys(item).forEach(function (key) {
                    key.indexOf("_") == 0 && delete item[key];
                });

                return [{ data: item }, df.dragActions.WebList.ciDragRow]
            }

            return [null, null];
        } catch (err) {
            // This can happen if the drag action is not supported, we don't want a nasty error if so.
            console.error("Attempt to perform unsupported drag action");
            return [null, null];
        }
    }

    getDropData(oDropZone, oPosition) {
        const itemId = (oDropZone._eDropElem && oDropZone._eDropElem.getAttribute("data-dfrowid")) || -1;
        let item;

        if (itemId && itemId != -1 && (itemId != '' || itemId >= 0)) {
            // Destructure object to create a clone, then remove any privates - prevents circular json eror
            item = { ...this._oModel.aData[(this._oModel.rowIndexByRowId(itemId))] }

            Object.keys(item).forEach(function (key) {
                key.indexOf("_") == 0 && delete item[key];
            });
        }

        const dropData = {
            data: item,
            action: df.dropActions.WebList.ciDropOnRow
        }

        return dropData;
    }

    initDropZones() {
        this._aDropZones = [];

        super.initDropZones();

        if (this.isSupportedDropAction(df.dropActions.WebList.ciDropOnRow)) {
            const eZone = (df.dom.query(this._eElem, '.WebList_BodyWrp'));
            this.addDropZone(eZone);
        }
    }

    determineDropCandidate(oEv, aHelpers) {
        // DropOnControl and other drop actions cannot exist within the same control simultaneously
        // It makes sense to check for this first to get it out of the way as it is the simplest check
        if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebControl.ciDropOnControl))) {
            return [this._eElem, df.dropActions.WebControl.ciDropOnControl];
        }

        // Check for DropOnRow, no need to continue if it doesn't exist
        if (!aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebList.ciDropOnRow))) {
            return [null, null];
        }

        const eElem = document.elementFromPoint(oEv.e.clientX, oEv.e.clientY);
        let eRow = eElem?.closest('[data-dfrowid]');

        if (eRow) {
            const sRowId = eRow.getAttribute('data-dfrowid');

            if (sRowId == 'empty_placeholder') {
                return [eRow.previousElementSibling || eRow.nextElementSibling || eRow, df.dropActions.WebList.ciDropOnRow];
            } else if (sRowId == 'empty') {
                while (eRow) {
                    const sRowId = eRow.getAttribute('data-dfrowid');
                    if (sRowId != 'empty' && sRowId != 'empty_placeholder') {
                        return [eRow, df.dropActions.WebList.ciDropOnRow];
                    }
                    eRow = eRow.previousElementSibling;
                }
            } else {
                return [eRow, df.dropActions.WebList.ciDropOnRow];
            }
        }

        return [null, null];
    }

    determineDropPosition(oEv, eElem) {
        const oRect = df.sys.gui.getBoundRect(eElem);
        // We want to check if we are more to the top or to the bottom of the hovered row
        const iMid = (oRect.bottom - (oRect.height / 2));
        if (oEv.e.clientY >= iMid) {
            return df.dropPositions.ciDropAfter;
        } else {
            return df.dropPositions.ciDropBefore;
        }
    }

    onControlDragOver(oEv, oDropZone, eDropElem) {
        if (!this._bScrollQueued && this.pbScroll) {
            let dY = 10;
            let dT = 100;
            const oRect = df.sys.gui.getBoundRect(oDropZone._eZone);

            // Drag scroll down
            const iBottomSection = oRect.bottom - 50;
            if (oEv.e.clientY <= oRect.bottom && (oEv.e.clientY > iBottomSection)) {
                const iDiffFromBottom = oRect.bottom - oEv.e.y;
                if (iDiffFromBottom < (iBottomSection * 0.5)) {
                    // accelerate scroll when closer to bottom
                    dT = 20;
                }
                this._bScrollQueued = true;
                setTimeout(() => {
                    this.dragScroll(dY)
                }, dT);
            }
            // Drag scroll up
            const iTopSection = oRect.top + 50;
            if (oEv.e.clientY >= oRect.top && (oEv.e.clientY < iTopSection)) {
                dY = -dY
                const iDiffFromTop = oEv.e.y - oRect.top;
                if (iDiffFromTop < (iTopSection * 0.5)) {
                    // accelerate scroll when closer to top
                    dT = 20;
                }
                this._bScrollQueued = true;
                setTimeout(() => {
                    this.dragScroll(dY)
                }, dT);
            }
        }
    }

    dragScroll(dY) {
        this._oBody?.scroll(dY, false);
        this._bScrollQueued = false;
    }

    interactWithDropElem(dropZone, eElem) {
        if (dropZone._eDropAction == df.dropActions.WebControl.ciDropOnControl) {
            // console.log('droponcontrol');
            dropZone.highlightElement();
        } else {
            // console.log('droplistrow');
            const eTempElem = document.createElement('table');
            df.dom.addClass(eTempElem, 'WebList_Row WebList_DropPlaceHolder');
            eTempElem.setAttribute('data-dfrowid', 'empty_placeholder');

            const iHeight = this.getPlaceholderRowHeight();

            if (iHeight && iHeight > 0) {
                eTempElem.style.height = (String(iHeight)) + "px"
            }

            dropZone.insertElement(eTempElem, eElem);
        }
    }

    doEmptyInteraction(dropZone) {
        if (this.isSupportedDropAction(df.dropActions.WebList.ciDropOnRow)) {
            const eTempElem = document.createElement('table');
            df.dom.addClass(eTempElem, 'WebList_Row WebList_DropPlaceHolder');

            const iHeight = this.getPlaceholderRowHeight();

            if (iHeight && iHeight > 0) {
                eTempElem.style.height = (String(iHeight)) + "px"
            }

            const eTargetElem = (df.dom.query(this._eElem, '.WebList_Body table'));
            dropZone.insertElement(eTempElem, eTargetElem, df.dropPositions.ciDropBefore);
            return df.dropActions.WebList.ciDropOnRow;
        } else if (this.isSupportedDropAction(df.dropActions.WebControl.ciDropOnControl)) {
            dropZone.highlightElement();
            return df.dropActions.WebControl.ciDropOnControl;
        }

        return null;
    }

    hasData() {
        return (this._oModel.aData && this._oModel.aData.length > 0);
    }

    getPlaceholderRowHeight() {
        const iAvgHeight = this._oBody.iAvgRowHeight;
        const iFirstRowHeight = df.dom.clientHeight(df.dom.query(this._eElem, '.WebList_Body table'));
        const iHeight = (iAvgHeight > 0 ? iAvgHeight : iFirstRowHeight) || 0;

        return iHeight;
    }

    /*
    These are left for now, even through we don't serialize to valuetrees any more. This leaves us with
    a spot where we could implement potential renames.
    */
    deserializeRows(aRows) { return aRows; }
    serializeRows(aRows) { return aRows; }
}