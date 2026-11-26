import { WebListPagedModel } from '../WebListPagedModel.js';
import { WebListGroupSelector } from './WebListGroupSelector.js';

const C_LocalStorageName = "groupConfig";

/*
Class: 
    WebListGroupController

Controls the grouping logic of the WebList. 

Revision:
    2023/02/23  (HW, DAW) 
        Initial version.
*/
export class WebListGroupController{
    constructor(oList, oModel, oController){
        this.oL = oList;
        this.oM = oModel;
        this.oC = oController;

        oList._onKeyDown.addListener(this.onKeyDown, this);
        oList._onSettingChange.addListener(this.onSettingsChange, this);
        this.loadGroupConfig();
    }

    /**
     * Attaches to a grouping selector control by listening to its onGroupsChanged event.
     * 
     * @param {WebListGroupSelector} oSel   Selector object.
     */
    registerMenuGroupingSelector(oSel){
        oSel.onGroupsChanged.on(this.onGroupsChanged, this);
    }

    /**
     * Configures and enables automatic grouping based on the supplied configuration.
     * 
     * @param {Array} aGroups Group configuration.
     */
    applyGrouping(aGroups){
        const oL = this.oL, oM = this.oM;

        //  Validate settings
        if(oL.peGrouping != df.grpAutomatic){
            throw new df.Error(999, "Set peGrouping to groupAutomatic to use applyGrouping.");
        }
        if(oM instanceof WebListPagedModel){
            throw new df.Error(999, "Automatic grouping not supported with paged data loading. Set peDbGridType to gtAllData or gtManual to allow automatic grouping.");
        }

        //  Validate data
        if(!Array.isArray(aGroups)){
            throw new df.Error(999, "Received invalid grouping data, expected aray.");
        }
        aGroups.forEach(tGroup =>{ 
            if(!oL._aColumns[tGroup.iColumnId]){
                throw new df.Error(999, "Received invalid grouping data, invalid column id.");
            }
        });
        
        //  Update data        
        oM.aGroups = aGroups;
        oM.aGroupHeaders = [];
        oM.bIsGrouped = (aGroups.length > 0);

        //  Notify list of changes
        oL._onSettingChange.fire(this, {
            sType : "grouping"
        });
    }

    /**
     * Applies the supplied groups if we did not load grouping from storage.
     * 
     * @param {Boolean} bOverrideDefault 
     * @param {Array} aGroups 
     */
    applyGroupConfig(bOverrideDefault, aGroups){
        if(bOverrideDefault || !this.oL.pbStoreGroupConfig || localStorage.getItem(this.oL.getStorageName(C_LocalStorageName) == null)){
            this.applyGrouping(aGroups);
            this.storeGroupConfig();
        }
    }

    /**
     * Clears and disabled automatic grouping.
     */
    clearGrouping(){
        const oL = this.oL, oM = this.oM;

        oM.aGroups = [];
        oM.aGroupHeaders = [];
        oM.bIsGrouped = false;

        //  Notify model of changes
        oL._onSettingChange.fire(this, {
            sType : "grouping"
        });
    }

    /**
     * Writes the current config to the local storage.
     */
    storeGroupConfig(){
        const oL = this.oL;

        if(oL.pbStoreGroupConfig){
            localStorage.setItem(this.oL.getStorageName(C_LocalStorageName), JSON.stringify(this.oM.aGroups));
        }
    }

    /**
     * Loads the group config from local storage (if pbStoreGroupConfig is enabled).
     */
    loadGroupConfig(){
        const oL = this.oL;

        if(oL.pbStoreGroupConfig){
            const sData = localStorage.getItem(this.oL.getStorageName(C_LocalStorageName));
            if(sData){
                try{
                    const aGroups = JSON.parse(sData);
                    if(Array.isArray(aGroups)){
                        this.applyGrouping(aGroups);
                    }
                }catch(ex){
                    // Ignore
                }
            }
        }
    }

    /**
     * Fires the (server) event notifying of a change in the group config.
     */
    triggerOnGroupsChanged(){
        this.oL.fireEx({
            sEvent : "OnGroupConfigChanged",
            tActionData : this.oM.aGroups,
            sAltServerName : "privateOnGroupConfigChanged",
        })
    }

    /**
     * The actual automatic grouping logic. It first sorts the data and then loops over the set to determine the group headers.
     */
    groupData(){
        const oL = this.oL, oM = this.oM, aGroups = oM.aGroups;
        
        if(oL.peGrouping == df.grpAutomatic){
            let aSortCols = [], aCmpFuncs = [];

            //   Find comparison functions
            aGroups.forEach(tGroup => {
                aSortCols.push(tGroup.iColumnId);
                aCmpFuncs.push(df.sys.data.compareFunction(oL._aColumns[tGroup.iColumnId].peDataType, tGroup.bReverse));
            });
            if(oL.piSortColumn >= 0 && aSortCols.indexOf(oL.piSortColumn) == -1){
                aSortCols.push(oL.piSortColumn);
                aCmpFuncs.push(df.sys.data.compareFunction(oL._aColumns[oL.piSortColumn].peDataType, oL.pbReverseOrdering));
            }
            oL._aColumns.forEach((oCol, iIndex )=> {
                if(aSortCols.indexOf(iIndex) == -1){
                    aSortCols.push(iIndex);
                    aCmpFuncs.push(df.sys.data.compareFunction(oCol.peDataType, oL.pbReverseOrdering))
                }
            });
            
            //  Sort the data
            oM.aGroupHeaders = [];
            oM.customSortData(aSortCols, aCmpFuncs);
            
            //  Loop over data to generate group headers
            let aGrpHeadIndex = [];
            oM.aData.reduce((tPrevRow, tRow, iIndex) => {
                let bSwitch = (tPrevRow == null);
                
                tRow.iGroupHeaderIndex = -1;
                
                for(let iGrp = 0; iGrp < aGroups.length; iGrp++){
                    if(!bSwitch){
                        bSwitch = (aCmpFuncs[iGrp](tRow.aCells[aSortCols[iGrp]].sValue, tPrevRow.aCells[aSortCols[iGrp]].sValue) != 0);
                    }
                    if(bSwitch){
                        aGrpHeadIndex[iGrp] = oM.aGroupHeaders.length;
                        oM.aGroupHeaders.push({
                            iGroupIndex: iGrp,
                            iParentHeaderIndex: tRow.iGroupHeaderIndex,
                            sItem : tRow.aCells[aSortCols[iGrp]].sValue,
                            iItems : 1,
                            sTotal : "", 
                            bCollapsed : oL.pbGroupsCollapsible && oL.pbGroupsCollapseByDefault,
                            _iLogicalParentGroup : (iGrp > 0 ? aGrpHeadIndex[iGrp - 1] : -1)
                        });
                        tRow.iGroupHeaderIndex = aGrpHeadIndex[iGrp];
                    }else{
                        oM.aGroupHeaders[aGrpHeadIndex[iGrp]].iItems++;
                    }
                }

                tRow._iLogicalGroup = aGrpHeadIndex[aGroups.length - 1];

                return tRow;
            }, null);
        }else if(oL.peGrouping == df.grpCustom){
            let aGrpHeadIndex = [];
            
            //  Pass through the data to validat and set logical groups
            oM.aData.forEach((tRow) => {
                let iHeaderIndex = tRow.iGroupHeaderIndex;

                while(iHeaderIndex >= 0){
                    const tHead = oM.aGroupHeaders[iHeaderIndex];
                    if(!tHead) throw new df.Error(999, `Invalid weblist data, invalid group header reference for row ${tRow.sRowId}`, oL);
                    if(tHead.iParentHeaderIndex == iHeaderIndex) throw new df.Error(999, `Invalid weblist data, recursive group header index ${iHeaderIndex} `, oL);
                    if(!aGroups[tHead.iGroupIndex]) throw new df.Error(999, `Invalid weblist data, group ${tHead.iGroupIndex} referenced by group header ${iHeaderIndex} does not exist.`, oL)

                    aGrpHeadIndex[tHead.iGroupIndex] = iHeaderIndex;
                    tHead._iLogicalParentGroup = (tHead.iGroupIndex > 0 ? aGrpHeadIndex[tHead.iGroupIndex - 1] : -1);
                    iHeaderIndex = tHead.iParentHeaderIndex;
                }
                
                tRow._iLogicalGroup = aGrpHeadIndex[aGroups.length - 1];
            });
        }
    }

    /**
     * Updates the groups based on the config received.
     * 
     * @param {df.JSEvent} oEv Event object containing the new group config.
     */
    onGroupsChanged(oEv){
        this.applyGrouping(oEv.aGroups);
        this.storeGroupConfig();
        this.triggerOnGroupsChanged();
    }

    /**
     * Toggles collapse state of the specified group header. 
     * 
     * @param {Integer} iHeaderIndex Index of the group header that needs to be collapsed / expanded.
     */
    toggleGroupHeader(iHeaderIndex){
        const oM = this.oM;
        const tHeader = oM.aGroupHeaders[iHeaderIndex];
        if(!tHeader) return;

        tHeader.bCollapsed = !tHeader.bCollapsed;
        oM.prepDisplay();

        oM.onDataUpdate.fire(this, {
            sType : "display",
        }); 
        
        // Fire the (server) event notifying of a change in the collapse state of a group header
        this.oL.fireEx({
            sEvent : "OnGroupHeaderToggle",
            tActionData : tHeader,
            sAltServerName : "privateOnGroupHeaderToggle",
        })
    }

    /**
     * Collapses all the groups.
     * 
     * Triggered by ctrl - -.
     */
    collapseAll(){
        const oM = this.oM;

        if(oM.bIsGrouped){
            oM.aGroupHeaders.forEach(tHeader => tHeader.bCollapsed = true);
            oM.prepDisplay();
            
            oM.onDataUpdate.fire(this, {
                sType : "display",
            });
        }
    } 

    /**
     * Expands all the groups.
     * 
     * Triggered by ctrl - +.
     */
    expandAll(){
        const oM = this.oM;

        if(oM.bIsGrouped){            
            oM.aGroupHeaders.forEach(tHeader => tHeader.bCollapsed = false);
            oM.prepDisplay();
            
            oM.onDataUpdate.fire(this, {
                sType : "display",
            });
        }
    }

    /**
     * Collapses the group that contains the current row. Closes a level higer if the direct parent is already collapsed.
     * 
     * Triggered by the - key.
     * 
     * @returns True if a group was collapsed.
     */
    collapseCurrent(){
        const oM = this.oM;

        if(oM.iCurrentRow && oM.aData[oM.iCurrentRow]){
            let iGroupHeaderIndex = oM.aData[oM.iCurrentRow]._iLogicalGroup;

            while(iGroupHeaderIndex >= 0){
                const tHeader = oM.aGroupHeaders[iGroupHeaderIndex];
                if(!tHeader.bCollapsed){
                    tHeader.bCollapsed = true;

                    oM.prepDisplay();

                    oM.onDataUpdate.fire(this, {
                        sType : "display",
                        iDisplayItem : tHeader._iItemIndex
                    });
                    return true;
                }

                iGroupHeaderIndex = tHeader._iLogicalParentGroup;
            }
        }

        return false;
    }

    /**
     * Expands the group surrounding the currently selected row. It will expand the highest level that is collapsed.
     * 
     * Triggered by the + key.
     * 
     * @returns True if a group was expanded.
     */
    expandCurrent(){
        const oM = this.oM;

        if(oM.iCurrentRow && oM.aData[oM.iCurrentRow]){
            let iGroupHeaderIndex = oM.aData[oM.iCurrentRow]._iLogicalGroup;

            while(iGroupHeaderIndex >= 0){
                const tHeader = oM.aGroupHeaders[iGroupHeaderIndex];
                if(tHeader.bCollapsed && (tHeader._iLogicalParentGroup < 0 || !oM.aGroupHeaders[tHeader._iLogicalParentGroup].bCollapsed)){
                    tHeader.bCollapsed = false;

                    oM.prepDisplay();

                    oM.onDataUpdate.fire(this, {
                        sType : "display",
                    });
                    return true;
                }

                iGroupHeaderIndex = tHeader._iLogicalParentGroup;
            }
        }

        return false;
    }

    /**
     * Makes sure the current row is visible by expanding the groups that contain the current row (all levels).
     * 
     * @returns True if a group was expanded (and a redraw has been triggered).
     */
    makeCurrentRowVisible(){
        const oM = this.oM;
        let bChanged = false;

        if(oM.bIsGrouped && oM.iCurrentRow >= 0 && oM.aData[oM.iCurrentRow]){
            let iGroupHeaderIndex = oM.aData[oM.iCurrentRow]._iLogicalGroup;

            while(iGroupHeaderIndex >= 0){
                const tHeader = oM.aGroupHeaders[iGroupHeaderIndex];
                if(tHeader.bCollapsed){
                    tHeader.bCollapsed = false;
                    bChanged = true;
                }

                iGroupHeaderIndex = tHeader._iLogicalParentGroup;
            }
        }

        if(bChanged){
            oM.prepDisplay();

            oM.onDataUpdate.fire(this, {
                sType : "display",
            });
        }
        return bChanged;
    }

    /**
     * Handles the keydown event on the weblist and implements the grouping operations (expand, collapse, expand all, collapse all).
     * 
     * @param {df.events.JSEvent} oJSEvent Event object.
     * @returns False if the event is handled.
     */
    onKeyDown(oJSEvent){
        const oEv = oJSEvent.oDOMEvent;

        if(oEv.matchKey(df.settings.listKeys.collapseAllGrp)){
            this.collapseAll();
            oEv.stop();
            return false;
        }else if(oEv.matchKey(df.settings.listKeys.expandAllGrp)){
            this.expandAll();
            oEv.stop();
            return false;
        }else if(oEv.matchKey(df.settings.listKeys.collapseGrp)){
            this.collapseCurrent();
            oEv.stop();
            return false;
        }else if(oEv.matchKey(df.settings.listKeys.expandGrp)){
            this.expandCurrent();
            oEv.stop();
            return false;
        }
    }

    /**
     * Triggered when a property changes on the weblist. Makes sure the grouping properties are handled. 
     * @param {df.events.JSEvent} oEv   Event object.
     * @returns False if the event is handled.
     */
    onSettingsChange(oEv){
        const oM = this.oM;

        if(oM.bIsGrouped && (oEv.sProp == "pbGroupsCollapsible" || oEv.sProp == "pbGroupsCollapseByDefault")){
            this.groupData();

            oM.prepDisplay();

            oM.onDataUpdate.fire(this, {
                sType : "display",
            });
            return false;
        }
    }
}