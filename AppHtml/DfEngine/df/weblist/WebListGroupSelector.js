import { df } from "../../df.js";
/*
Class: 
    WebListGroupSelector

Implements the interface for configuring the WebList grouping by selecting columns.

Revision:
    2023/02/23  (HW, DAW) 
        Initial version.
*/
export class WebListGroupSelector {
    oL = null;
    aColumns = [];
    aGroups = [];
    eDragGroup = null;

    labels = {
        "title": "Group Columns",
        "add": "+ Add group",
        "addsub": "+ Add sub group",
        "groupselect": "Select group column",
        "dragrearrange": "Drag to rearrange",
        "switchsort": "Switch sorting direction",
        "remove": "Remove group",
    };

    //  Events implemented by WebListGroupController and WebMenuGroupingSelector
    onSizeChanged = new df.events.JSHandler();
    onGroupsChanged = new df.events.JSHandler();

    //  DOM Element references
    components = {
        eMain: null,
        eContainer: null,
        eSubGroupBtn: null,
        eFieldsSelected: null,
        eChip: null,
        eSelectDropdown: null, 
    };

    constructor(oWebList) {
        this.oL = oWebList;

        oWebList._onSettingChange.on(this.onWebListSettingsChange, this);
        
        //  Initialize
        this.loadTranslations();
        this.createElements();
        this.updateColumns();
    }

    /**
     * Load translations for the labels from WebApp object.
     */
    loadTranslations(){
        const oW = this.oL.getWebApp();

        if(!oW) return;

        this.labels.title = oW.getTrans("weblist_GroupColumns");
        this.labels.add = oW.getTrans("weblist_AddGroup");
        this.labels.addsub = oW.getTrans("weblist_AddSubGroup");
        this.labels.groupselect = oW.getTrans("weblist_GroupColumn");
        this.labels.dragrearrange = oW.getTrans("weblist_DragRearrange");
        this.labels.switchsort = oW.getTrans("weblist_SwitchSort");
        this.labels.remove = oW.getTrans("weblist_RemoveGroup");
    }

    /**
     * Called when the group selector is displayed. It updates the group config being displayed.
     * 
     * @returns DOM element containing the group selection interface.
     */
    render() {
        this.aGroups = this.oL._oModel.aGroups;
        this.renderGroups();
        df.dom.addClass(this.components.eSelectDropdown, "Web_Hidden");
        return this.components.eMain;
    }

    /**
     * Triggered by the WebList whenever the configuration changes. We use it to update the 
     * column config we have.
     * 
     * @param {df.JSEvent} oEv Event object.
     */
    onWebListSettingsChange(oEv) {
        this.updateColumns();
    }

    /**
     * Refresh the list of columns available in the weblist.
     */
    updateColumns() {
        this.aColumns = [];

        this.oL._aColumns.forEach(oCol => {
            if (oCol.pbRender && oCol.pbGroupable) {
                this.aColumns.push({
                    iColumnId: oCol._iCol,
                    // title: oCol.psCaption,
                    // tooltip: oCol.psToolTip,
                    sLabel: df.dom.encodeHtml(oCol.psCaption),
                });
            }
        });
    }

    

    /**
     * Generates the main element structure for the selector view and attaches event listeners.
     */
    createElements() {
        const eMain = this.components.eMain = df.dom.create(`<div class="WebGrpSel_Container">
                <div class="WebGrpSel_Head">
                    <div id="WebGrpSel_Title">${this.labels.title}</div>
                    <div class="WebGrpSel_Chip">0</div>
                </div>
                <div class="WebGrpSel_Fields"></div>
                <div class="WebGrpSel_Add">
                    <button type="button" class="WebGrpSel_Add_Button">${this.labels.add}</button>
                    <div class="WebGrpSel_DropDown Web_Hidden"></div>
                </div>
            </div>
        `);

        this.components.eChip = df.dom.query(eMain, ".WebGrpSel_Chip");
        this.components.eFieldsSelected = df.dom.query(eMain, ".WebGrpSel_Fields");
        this.components.eSubGroupBtn = df.dom.query(eMain, ".WebGrpSel_Add_Button");
        this.components.eSelectDropdown = df.dom.query(eMain, ".WebGrpSel_DropDown");

        df.dom.on("click", this.components.eMain, this.onMainClick, this);

        df.dom.on("click", this.components.eSubGroupBtn, this.onAddButtonClick, this);
        df.dom.on("click", this.components.eSelectDropdown, this.onAddDropDownClick, this);

        df.dom.on("click", this.components.eFieldsSelected, this.onFieldsClick, this);
        df.dom.on("change", this.components.eFieldsSelected, this.onFieldsChange, this);

        df.dom.on("dragstart", this.components.eFieldsSelected, this.onFieldsDragStart, this);
        df.dom.on("dragenter", this.components.eFieldsSelected, this.onFieldsDragEnter, this);
        df.dom.on("dragleave", this.components.eFieldsSelected, this.onFieldsDragLeave, this);
        df.dom.on("dragover", this.components.eFieldsSelected, this.onFieldsDragOver, this);
        df.dom.on("dragend", this.components.eFieldsSelected, this.onFieldsDragEnd, this);
        df.dom.on("drop", this.components.eFieldsSelected, this.onFieldsDragDrop, this);
    }

    /**
     * Stop clicks from bubbling (which causes the context menu to hide).
     * 
     * @param {df.DOMEvent} oEv 
     */
    onMainClick(oEv) {
        oEv.stop();
    }

    /**
     * Displays the pulldown for adding new columns.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onAddButtonClick(oEv) {
        const eDropDown = this.components.eSelectDropdown; // = df.dom.create(sHtml);
        const aCols = this.availableColumns();

        if (eDropDown.classList.contains("Web_Hidden")) {
            //  Generate dropdown content
            let sHtml = ``;
            this.components.eSelectDropdown.innerHTML = aCols.reduce((sHtml, tCol) => {
                return sHtml + `<div class="Web_Item" data-colid="${tCol.iColumnId}">${tCol.sLabel}</div>`;
            }, "");

            //  Position and display dropdown
            const rect = this.components.eSubGroupBtn.getBoundingClientRect();

            eDropDown.style.top = rect.bottom + "px";
            eDropDown.style.left = rect.left + "px";
            df.dom.removeClass(eDropDown, "Web_Hidden");
        } else {
            df.dom.addClass(eDropDown, "Web_Hidden");
        }
    }

    /**
     * Converts a column id into an index in the aColumns array.
     * 
     * @param {integer} iColId Column id.
     * @returns 
     */
    columnIndexById(iColId) {
        return this.aColumns.map(tCol => tCol.iColumnId).indexOf(parseInt(iColId, 10));
    }

    /**
     * Adds a group to the configuration when a column is clicked in the dropdown.
     * 
     * @param {df.DOMEvent} oEv 
     * @returns 
     */
    onAddDropDownClick(oEv) {
        //  Determine details of clicked column
        const iColId = oEv.getTarget()?.closest(".Web_Item[data-colid]")?.dataset.colid || null;
        if (iColId == null) return;

        const iColIndex = this.columnIndexById(iColId);
        if (iColIndex == -1) return;

        const oCol = this.aColumns[iColIndex];

        //  Add the group
        this.aGroups.push({
            iColumnId: oCol.iColumnId,
            sLabel: oCol.sLabel,
            bReverse: false
        });

        this.renderGroups();
        this.fireGroupsChanged();

        //  Hide the menu
        df.dom.addClass(this.components.eSelectDropdown, "Web_Hidden");
    }

    /**
     * Determines the list of available columns, which are the columns that are not used as a group already.
     * 
     * @returns Array of available columns.
     */
    availableColumns() {
        const aSelColIds = this.aGroups.map(tCol => tCol.iColumnId);
        const aResult = [];

        this.aColumns.forEach(tCol => {
            if (aSelColIds.indexOf(tCol.iColumnId) == -1) {
                aResult.push(tCol);
            }
        });

        return aResult;
    }

    /**
     * Display the list of configured groups by generating the HTML.
     */
    renderGroups() {
        const aCols = this.availableColumns();

        // Generate groups html
        this.components.eFieldsSelected.innerHTML = this.aGroups.reduce((sHtml, tGrp, iGrpIndex) => {
            sHtml += `<div class="WebGrpSel_Group" data-group="${iGrpIndex}" draggable="true">
                    <div class="WebGrpSel_Action" data-action="rearrange" title="${this.labels.dragrearrange}"><i class="WebGrpSel_IconReaarrange"></i></div>
                    <select class="WebGrpSel_GroupSelect" title="${this.labels.groupselect}">
                    <option value="${tGrp.iColumnId}" selected>${tGrp.sLabel}</option>
            `;
            
            sHtml += aCols.reduce((sHtml, tCol, iColIndex) => {
                return sHtml + `<option value="${tCol.iColumnId}">${tCol.sLabel}</option>`;
            }, "");
            
            sHtml += `</select>
                    <div class="WebGrpSel_Action" data-action="switchsort" title="${this.labels.switchsort}"><i class="${tGrp.bReverse ? "WebGrpSel_IconSortAsc" : "WebGrpSel_IconSortDesc"}"></i></div>
                    <div class="WebGrpSel_Action" data-action="remove" title="${this.labels.remove}"><i class="WebGrpSel_IconRemove"></i></div>
                </div>`;

            return sHtml;
        }, "");

        // Update chip
        df.dom.setText(this.components.eChip, this.aGroups.length);
        df.dom.setText(this.components.eSubGroupBtn, (this.aGroups.length > 0 ? this.labels.addsub : this.labels.add));


        this.onSizeChanged.fire(this);
    }

    /**
     * Handles a click event on the group section. If a button is clicked (like the remove button) it will perform that operation.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsClick(oEv) {
        //  Determine action & group index
        const sAction = oEv.getTarget().closest(".WebGrpSel_Action")?.dataset.action || null;
        const iGroup = oEv.getTarget().closest(".WebGrpSel_Group")?.dataset.group || null;
        if (sAction == null || iGroup == null || !this.aGroups[iGroup]) return;

        //  Perform action
        switch(sAction){
            case "remove":
                this.aGroups.splice(iGroup, 1);
                this.renderGroups();
                this.fireGroupsChanged();
                break;
            case "switchsort":
                this.aGroups[iGroup].bReverse = !this.aGroups[iGroup].bReverse;
                this.renderGroups();
                this.fireGroupsChanged();
                break;
        }
    }

    /**
     * The selected column for a group has changed, so we need to update our administration accordingly.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsChange(oEv) {
        //  Determine the newly selected column ID & group index
        const iColumnId = oEv.getTarget().closest(".WebGrpSel_GroupSelect")?.value || null;
        const iGroup = oEv.getTarget().closest(".WebGrpSel_Group")?.dataset.group || null;
        if (iColumnId == null || iGroup == null || !this.aGroups[iGroup]) return;

        const iColIndex = this.columnIndexById(iColumnId);
        if (iColIndex == -1) return;

        //  Update the group config
        this.aGroups[iGroup].iColumnId = this.aColumns[iColIndex].iColumnId;
        this.aGroups[iGroup].sLabel = this.aColumns[iColIndex].sLabel;
        this.renderGroups();
        this.fireGroupsChanged();
    }

    /**
     * Start of a group drag.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsDragStart(oEv) {
        const eGroup = oEv.getTarget().closest(".WebGrpSel_Group") || null;
        const iGroup = eGroup?.dataset.group || null;
        if (!eGroup || iGroup == null || !this.aGroups[iGroup]) return;

        oEv.e.dataTransfer.dropEffect = "move";
        oEv.e.dataTransfer.effectAllowed = "move";

        this.eDragGroup = eGroup;

        eGroup.classList.add("Web_Drag");
    }

    /**
     * Dragging over another group (swap them).
     * 
     * @param {df.DOMEvent} oEv 
     * @returns 
     */
    onFieldsDragOver(oEv) {
        const eOverGroup = oEv.getTarget().closest(".WebGrpSel_Group") || null;
        if (!this.eDragGroup || eOverGroup == null) return;

        oEv.e.preventDefault();
        oEv.stopPropagation();
        oEv.e.dataTransfer.dropEffect = "move";

        if (df.dom.isBefore(this.eDragGroup, eOverGroup)) {
            this.components.eFieldsSelected.insertBefore(this.eDragGroup, eOverGroup);
        } else {
            this.components.eFieldsSelected.insertBefore(this.eDragGroup, eOverGroup.nextSibling);
        }
    }

    /**
     * Drag finished.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsDragEnd(oEv) {
        if (!this.eDragGroup) return;

        oEv.e.preventDefault();
        oEv.stopPropagation();

        this.finishDrag();
    }

    /**
     * Prevent bubbling of drag event.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsDragEnter(oEv) {
        if (!this.eDragGroup) return;
        oEv.e.preventDefault();
        oEv.stopPropagation();
        const dataTransfer = oEv.e.dataTransfer;
        dataTransfer.dropEffect = "move";
    }

    /**
     * Drag finished.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsDragDrop(oEv) {
        if (!this.eDragGroup) return;
        oEv.e.preventDefault();
        oEv.stopPropagation();
        this.finishDrag();
    }

    /**
     * Prevent bubbling of drag event.
     * 
     * @param {df.DOMEvent} oEv 
     */
    onFieldsDragLeave(oEv) {
        if (!this.eDragGroup) return;
        oEv.e.preventDefault();
        oEv.stopPropagation();
    }

    /**
     * Handle finishing of the drag. While dragging we simply swapped DOM elements, now we need to update our administration accordingly.
     */
    finishDrag() {
        //  Find out where the dragged group ended up
        const iGroupIndex = this.eDragGroup?.dataset.group  || null;
        const iNexGroupIndex = this.eDragGroup?.nextElementSibling?.dataset.group || null;
        this.eDragGroup = null;
        if(iGroupIndex == null || !this.aGroups[iGroupIndex] || (iNexGroupIndex != null && !this.aGroups[iNexGroupIndex])) return;
        
        //  Update administration
        const tGrp = this.aGroups[iGroupIndex];
        this.aGroups.splice(iGroupIndex, 1);

        if(iNexGroupIndex != null){
            this.aGroups.splice(iNexGroupIndex, 0, tGrp);
        }else{
            this.aGroups.push(tGrp);
        }

        //  Propagate the change
        this.renderGroups();
        this.fireGroupsChanged();
    }

    /**
     * Fires the onGroupsChanged event which tells the WebList of this change!
     */
    fireGroupsChanged(){
        this.onGroupsChanged.fire(this, { 
            aGroups : this.aGroups 
        });
    }

}