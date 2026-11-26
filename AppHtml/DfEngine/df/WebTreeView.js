import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';

/*
Name:
    df.WebTreeView
Type:
    Class

Implementation of the treeview control. This controls is capable of rendering a treeview using HTML 
based on information received from the server.
    
Revisions:
    2009/10/07  (HW, DAE)
        Created the initial version. 
    2012/04/03  (HW, DAW)
        Refactored the original AjaxTreeView and TreeView classes from the AJAX Library into a 
        single WebTreeView class. The new class is part of the new web framework for VDF 17.1.
*/

export class WebTreeView extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Web Properties
        this.prop(df.tBool, "pbShowIcons", true);
        this.prop(df.tBool, "pbAllowHtml", false);
        this.prop(df.tString, "psSelectedId", "");
        this.prop(df.tString, "psSelectedValue", "");

        //  Events
        this.event("OnSelect", df.cCallModeWait);
        this.event("OnExpand", df.cCallModeDefault);
        this.event("OnCollapse", df.cCallModeDefault);

        // @privates
        this._aRootItems = [];
        this._aItems = [];
        this._iAutoNum = 1000;
        this._tSelectedNode = null;

        this._bRedraw = false;

        this._eRootTable = null;

        this._eCurHoveredElem = null;
        this._fHoverTimeOut = null;

        this._sControlClass = "WebTreeView";
    }

    /*
    This method generates the wrapping HTML of the treeview. This includes an hidden anchor used for 
    receiving and keeping the focus.
    
    @param  aHtml   Stringbuilder array to which the HTML can be added.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebTree_Body" style="height: 10px;" ',
            (!this.isEnabled() ? 'tabindex="-1"' : 'tabindex="0"'), '>');
    }

    /*
    This method generates the HTML that closes the wrapping elements of the treeview.
    
    @param  aHtml   Stringbuilder array to which the HTML can be added.
    @private
    */
    closeHtml(aHtml) {
        aHtml.push('</div>');
        super.closeHtml(aHtml);
    }

    /*
    This method gathers references to the HTML elements and attaches DOM listeners.
    
    @private
    */
    afterRender() {
        const that = this;

        //  Get references
        this._eControl = df.dom.query(this._eElem, 'div.WebTree_Body');
        this._eFocus = this._eControl; //df.dom.query(this._eElem, 'a');

        super.afterRender();

        //  Attach event listeners
        df.dom.on("click", this._eControl, this.onBodyClick, this);
        df.dom.on("dblclick", this._eControl, this.onBodyDblClick, this);
        df.events.addDomKeyListener(this._eElem, this.onKey, this);

        //  Render the initial tree
        this.redraw();
        setTimeout(function () {
            if (that._tSelectedNode) {
                that.scrollToElement(that._tSelectedNode._eElem);
            }
        }, 50);

        setTimeout(function () {
            that.dragDropCleanup();
            that.dragDropInit();
        }, 50);
    }

    /* 
    Augments applyEnabled to set the tabindex attribute of the focus element.
    
    @param  bVal    The enabled state.
    */
    applyEnabled(bVal) {
        super.applyEnabled(bVal);

        if (this._eFocus) {
            this._eFocus.tabIndex = (bVal ? 0 : -1);
        }
    }


    // - - - - - - - - - Public API - - - - - - - - - -

    /*
    Getter method that determines the currently selected id.
    
    @return The ID of the currently selected node or "" if no node is selected.
    */
    get_psSelectedId() {
        if (this._tSelectedNode) {
            return this._tSelectedNode.sId;
        }
        return "";
    }

    /*
    Getter method that determines the currently selected value.
    
    @return The value of the currently selected node or "" if no node is selected.
    */
    get_psSelectedValue() {
        if (this._tSelectedNode) {
            return this._tSelectedNode.sValue;
        }
        return "";
    }


    /* 
    Setter method for the pbShowIcons property that redraws the tree based on the new setting. 
    
    @param  bVal    New value.
    @private
    */
    set_pbShowIcons(bVal) {
        this.pbShowIcons = bVal;

        this.redraw();
    }

    /*
    This method selects the node with the passed ID. Nothing happens if the ID is not found which can 
    happen because the tree doesn't always load all items.
    
    @param  sNodeId     ID of the tree node.
    @client-action
    */
    select(sNodeId) {
        const tNode = this.getNodeById(sNodeId);

        if (tNode) {
            this.doSelect(tNode, false);
        }
    }

    /*
    This method expands the node with the passed ID. Nothing happens if the ID is not found which can 
    happen because the tree doesn't always load all items.
    
    @param  sNodeId     Unique ID of the tree node.
    @client-action
    */
    expand(sNodeId) {
        const tNode = this.getNodeById(sNodeId);

        if (tNode && tNode.bFolder) {
            this.expandNode(tNode);
        }
    }

    /*
    This method collapses the node with the passed ID. Nothing happens if the ID is not found which can 
    happen because the tree doesn't always load all items.
    
    @param  sNodeId     Unique ID of the tree node.
    
    @client-action
    */
    collapse(sNodeId) {
        const tNode = this.getNodeById(sNodeId);

        if (tNode) {
            this.collapseNode(tNode);
        }
    }

    /*
    This method will collapse all nodes.
    
    @client-action
    */
    collapseAll() {

        for (let i = 0; i < this._aItems.length; i++) {
            if (this._aItems[i].bExpanded) {
                this.collapseNode(this._aItems[i]);
            }
        }

        //this.redraw();
    }

    /*
    This method refreshes the tree with the tree items encoded in the action data. The action data is a 
    two dimensional array that is used for sending 'complex data' with client actions. If a parent id is 
    provided then the nodes will be inserted as children of the parent node. If no parent id is provided 
    then the entire tree will be cleared and nodes will be inserted at the root of the tree.
    
    @param  sParentId     (optional) Unique ID of the parent tree node.
    
    
    @client-action
    */
    refresh(sParentId) {
        let tNode, sSelectedId;
        const aNodes = this._tActionData;

        //  Remeber selected item
        sSelectedId = this._tSelectedNode && (this._tSelectedNode.sId || "");
        if (!sSelectedId && this.psSelectedId) {
            sSelectedId = this.psSelectedId;
            this.psSelectedId = "";
        }

        if (sParentId) {
            //  Remove the sub nodes of the parent node first
            tNode = this.getNodeById(sParentId);

            if (tNode) {
                while (tNode._aChildren.length > 0) {
                    this.doRemove(tNode._aChildren[0], true);
                }
            }
            tNode._bIsLoaded = true;
        } else {
            //  Clear current tree
            this.clear();
            this.displayLoading();
        }

        for (let i = 0; i < aNodes.length; i++) {
            tNode = this.initNode(aNodes[i]);

            //  No parent id makes it a child of the parent we are loading for (root / "" if loading entire tree)
            if (!tNode.sParentId) {
                tNode.sParentId = sParentId || "";
            }


            //  Insert
            this.insert(tNode);
        }

        //  Try to reselect the selected item
        if (sSelectedId) {
            tNode = this.getNodeById(sSelectedId);
            if (tNode) {
                this._tSelectedNode = tNode;
            }
        } else {
            this._tSelectedNode = null;
        }
        //  Redraw
        this.redraw();
        this.hideLoading();
    }

    /*
    This method is called to update a node. The node should be sent as client-data (two dimensional 
    array). If the node is found using its ID it will be updated and the display will be refreshed.
    
    @client-action
    */
    updateNode() {
        var tNewNode, tOrigNode;
        const aNodes = this._tActionData;

        if (aNodes.length > 0) {
            //  Convert from data to node
            tNewNode = this.initNode(aNodes[0]);

            tOrigNode = this.getNodeById(tNewNode.sId);

            if (tOrigNode) {
                //  Update the node
                tOrigNode.sName = tNewNode.sName;
                tOrigNode.sAltText = tNewNode.sAltText;
                tOrigNode.sValue = tNewNode.sValue;
                tOrigNode.sCSSClass = tNewNode.sCSSClass;
                tOrigNode.sIcon = tNewNode.sIcon;
                tOrigNode.bFolder = tNewNode.bFolder;
                tOrigNode.bLoadChildren = tNewNode.bLoadChildren;

                //  Update display
                this.redraw();
            }
        }
    }

    /*
    This method is called to insert a new node. The node should be sent as client-data (two dimensional 
    array). 
    
    @client-action
    */
    insertNode() {
        let tNewNode;
        const aNodes = this._tActionData;

        if (aNodes.length > 0) {
            //  Convert from data to node
            tNewNode = this.initNode(aNodes[0]);

            this.insert(tNewNode);

            this.redraw();
        }
    }

    /*
    This method will remove a node from the tree. If the node is not found then nothing will happen.
    
    @param  sNodeId     The unique id of the node to remove.
    @client-action
    */
    removeNode(sNodeId) {
        const tNode = this.getNodeById(sNodeId);

        if (tNode) {
            this.doRemove(tNode);
            this.redraw();
        }
    }


    // - - - - - - - - - Engine - - - - - - - - - -

    /*
    This method is called to load the children of tree nodes that are expanded. A server-action is fired 
    to the server to load the nodes. The server will call a client-action called addSubItems to pass the 
    new items. The node is expanded when finished.
    
    @param  tParentNode     The node of which the child nodes need to be loaded.
    @private
    */
    loadSubNodes(tParentNode) {
        let sParentId = "", sParentValue = "", iParentLevel = 0;

        //  Display loading and determine call details
        if (tParentNode) {
            tParentNode._bIsLoading = true;
            this.displayLoading(tParentNode);

            sParentId = tParentNode.sId;
            sParentValue = tParentNode.sValue;
            iParentLevel = this.getLevel(tParentNode);
        } else {
            this.clear();
            this.displayLoading();

        }

        //  Perform the server-action
        this.serverAction("LoadSubNodes", [sParentId, sParentValue, iParentLevel], null, function (oEvent) {
            //  Update the parent node
            if (tParentNode) {
                tParentNode._bIsLoading = false;
                this.updateNodeCSS(tParentNode);
            }

            //  Expand the node or redraw the tree
            if (!oEvent.bError) {
                if (tParentNode) {
                    tParentNode._bIsLoaded = true;
                    this.expandNode(tParentNode);
                } else {
                    this.redraw();
                }
            }

            //  Hide loading
            this.hideLoading(tParentNode);
        }, this);
    }

    /*
    This client-action is called by the LoadSubNodes server-action to insert new nodes. The nodes will 
    be encoded into the action data (two dimensional array). The new nodes will be initialized and 
    inserted into the tree.
    
    @param  sParentId   Unique ID of the parent node indicating where to insert the ndoes.
    
    @client-action
    @private
    */
    addSubItems(sParentId) {
        let tNode
        const aNodes = this._tActionData;

        for (let i = 0; i < aNodes.length; i++) {
            tNode = this.initNode(aNodes[i]);

            //  No parent id makes it a child of the parent we are loading for (root / "" if loading entire tree)
            if (!tNode.sParentId) {
                tNode.sParentId = sParentId || "";
            }


            //  Insert
            this.insert(tNode);
        }
    }

    /*
    This method initializes a new node based on the passed raw data. The raw data is an array which 
    represents the node. This array is used when sending nodes from the server to client.
    
    @param  aRaw     Raw array representing the node.
    @return Node object.
    @private
    */
    initNode(tNode) {

        tNode._aChildren = [];
        tNode._tParent = null;
        tNode._eElem = null;
        tNode._eSubMenuRow = null;
        tNode._eSubMenuTable = null;

        tNode._bIsLoading = false;
        tNode._bIsLoaded = tNode.bExpanded; // Assume that if an item is expanded its sub nodes are provided


        //  Autonumber if needed
        if (!tNode.sId) {
            this._iAutoNum++;
            tNode.sId = this._iAutoNum.toString();
        }



        return tNode;
    }

    /*
    The node will be inserted into the tree based on its settings. If no (correct) 
    parent ID is found it will be added to the root. The display won't be updated so 
    the refresh method should be called.
    
    @param  tNode   New node (see: df.dataStructs.TAjaxTreeNode).
    */
    insert(tNode) {
        let tParent;

        //  Check if item doesn't already exist
        if (this.getNodeById(tNode.sId)) {
            throw new df.Error(5151, "Node IDs must be unique (ID: '{{0}}')", this, [tNode.sId]);
        }

        //  Search for parent
        if (tNode.sParentId) {
            tParent = this.getNodeById(tNode.sParentId);
        }

        //  Add to its parent
        if (tParent) {
            tNode._tParent = tParent;
            tParent._aChildren.push(tNode);
        } else {
            this._aRootItems.push(tNode);
        }

        //  Add to the full item list
        this._aItems.push(tNode);
    }

    /*
    All the nodes will be removed from the tree. The display is updated.
    */
    clear() {

        if (this._eRootTable) {
            this._eControl.removeChild(this._eRootTable);

            for (let i = 0; i < this._aItems.length; i++) {
                if (this._aItems[i]._eElem) {
                    this._aItems[i]._eElem.tNode = null;
                }
                this._aItems[i]._eElem = null;
                this._aItems[i]._eSubMenuRow = null;
                this._aItems[i]._eSubMenuTable = null;
            }
        }

        this._tSelectedNode = null;
        this._aItems = [];
        this._aRootItems = [];

        if (this._eControl) {
            this._eRootTable = this.constructTable();
            this._eControl.appendChild(this._eRootTable);
        }
    }

    /*
    Updates the display based on the internal node structure. Newly inserted nodes 
    will be displayed correctly. Expanded items stay expanded and the selected node 
    will still be selected.
    */
    redraw() {

        if (this._eControl) {
            this._bRedraw = true;

            if (this._eRootTable) {
                this._eControl.removeChild(this._eRootTable);

                for (let i = 0; i < this._aItems.length; i++) {
                    this._aItems[i]._eElem = null;
                    this._aItems[i]._eSubMenuRow = null;
                    this._aItems[i]._eSubMenuTable = null;
                }
            }
            this._eRootTable = this.constructTable();

            this.constructMenu(this._aRootItems, this._eRootTable);

            this._eControl.appendChild(this._eRootTable);

            this._bRedraw = false;
        }
    }

    /*
    Constructs a tree table (root or subitems).
    
    @private
    */
    constructTable() {
        const eTable = document.createElement("table");

        return eTable;
    }

    /*
    Constructs a node row at the given position in the table.
    
    @param  tNode       Node struct.
    @param  eTable      Table element to which the node row needs to be added.
    @param  iPos        Position in the table.
    @param  bIsStart    True if the node is the first node on his level.
    @param  bIsLast     True if the node is the last node on his level.
    @private
    */
    constructNode(tNode, eTable, iPos, bIsStart, bIsLast) {
        let eCell, sName;

        //  Determine if node has sub menu
        const bDoSub = tNode._aChildren.length > 0 || tNode.bLoadChildren;

        //  Create row
        const eRow = eTable.insertRow(iPos);
        eRow.setAttribute("data-dftree-id", tNode.sId);
        if (this.pbDragDropEnabled) {
            if (tNode.bFolder) {
                if (this.isSupportedDragAction(df.dragActions.WebTreeView.ciDragFolder)) {
                    eRow.setAttribute('draggable', true);
                }
            } else {
                if (this.isSupportedDragAction(df.dragActions.WebTreeView.ciDragItem)) {
                    eRow.setAttribute('draggable', true);
                }
            }

        }
        tNode._eElem = eRow;

        //  Tree cell
        eCell = eRow.insertCell(0);
        eCell.innerHTML = "<div>&nbsp;</div>";

        //  Content cell
        eCell = eRow.insertCell(eRow.cells.length);

        //  Text span
        sName = (this.pbAllowHtml ? tNode.sName : df.dom.encodeHtml(tNode.sName));
        eCell.innerHTML = '<span class="WebTree_Text" title="' + df.dom.encodeAttr(tNode.sAltText) + '">' + sName + '</span>';

        this.updateNodeCSS(tNode);

        //  Add listener(s)
        if (bDoSub) {
            // df.dom.on("click", eRow, this.onExpandClick, this);

            if (tNode.bExpanded) {
                iPos++;
                this.constructSubmenu(tNode, eTable, iPos, bIsLast);
            }
        }

        return iPos;
    }

    /*
    Generates the DOM elements for the given list of nodes on the given table.
    
    @param  aNodes  Array with nodes.
    @param  eTable  Table element.
    @private
    */
    constructMenu(aNodes, eTable) {
        let iPos = 0;

        for (let iNode = 0; iNode < aNodes.length; iNode++) {
            iPos = this.constructNode(aNodes[iNode], eTable, iPos, (iNode === 0 && eTable === this.eRootTable), (iNode === aNodes.length - 1));
            iPos++;
        }
    }

    /*
    Constructs the submenu that belongs to the given node.
    
    @param  tNode       Node element.
    @param  eTable      Table element in which the node is located.
    @param  iPos        Position to generate submenu on.
    @param  bIsLast     Determines wether the node is the last on this level.
    @private
    */
    constructSubmenu(tNode, eTable, iPos, bIsLast) {
        let eCell;

        const eRow = eTable.insertRow(iPos);
        eRow.className = "WebTree_SubRow" + (!this._bRedraw ? " WebTree_HiddenSubRow" : "");

        eCell = eRow.insertCell(0);
        eCell.className = (bIsLast ? "WebTree_ConLast" : "WebTree_Con");

        eCell = eRow.insertCell(1);
        eCell.innerHTML = "<table></table>";

        const eNewTable = df.dom.query(eCell, "table"); //this.constructTable();

        tNode._eSubMenuRow = eRow;
        tNode._eSubMenuTable = eNewTable;

        this.constructMenu(tNode._aChildren, eNewTable, false);

        //  Make visible after small timeout for possible animation
        if (!this._bRedraw) {
            setTimeout(function () {
                if (tNode._eSubMenuRow) {
                    df.dom.removeClass(tNode._eSubMenuRow, "WebTree_HiddenSubRow");
                }
            }, 20);
        }
    }

    /*
    Redefines the CSS classes set on the node elements.
    
    @private
    */
    updateNodeCSS(tNode) {

        if (tNode._eElem) {
            //  Update node CSS
            tNode._eElem.className = (tNode.bExpanded ? "WebTree_Expanded" : "WebTree_Collapsed") + (tNode === this._tSelectedNode ? " WebTree_Selected" : "") + " " + tNode.sCSSClass;

            const bFirst = this.isFirst(tNode);
            const bLast = this.isLast(tNode);
            const bRoot = this.isRoot(tNode);
            const bSub = this.hasChildren(tNode);

            tNode._eElem.cells[0].className = "WebTree_Item WebTree_" + ((bFirst && bRoot) || bLast ? (bFirst && bRoot ? "Start" : "") + (bLast ? "End" : "") : "Entry") + (bSub ? "Sub" : "");

            if (this.pbShowIcons) {
                const eCell = tNode._eElem.cells[1];

                if (tNode.sIcon && !tNode._bIsLoading) {
                    eCell.style.backgroundImage = "url('" + tNode.sIcon + "')";
                    eCell.style.backgroundRepeat = "no-repeat";
                    eCell.className = (tNode.bFolder ? "WebTree_Folder " : "WebTree_Icon ") + "WebTree_HasIcon";
                } else {
                    eCell.className = (tNode._bIsLoading ? "WebTree_IconLoading " : "WebTree_NoIcon ") + (tNode.bFolder ? "WebTree_Folder " : "WebTree_Icon ");
                    eCell.style.backgroundImage = "";
                    //  FIX: Internet Explorer 8 won't go back to CSS setting, this can cause problems when dynamically changing the icon at runtime
                    // eCell.style.backgroundPosition = "";
                }
            }
        }
    }

    // - - - - - - - Navigation - - - - - - - - -

    /*
    If the node is expanded it will be collapsed or the other way around.
    
    @param  tNode   Node to toggle (see: df.dataStructs.TAjaxTreeNode).
    */
    toggle(tNode) {
        if (tNode.bExpanded) {
            this.collapseNode(tNode);
        } else {
            this.expandNode(tNode);
        }
    }

    /*
    The node will be expanded.
    
    @param  tNode   Node to expand (see: df.dataStructs.TAjaxTreeNode).
    */
    expandNode(tNode) {
        tNode.bExpanded = true;

        if (tNode._bIsLoading) {
            return;
        }

        this.fire("OnExpand", [tNode.sId, tNode.sValue, this.getLevel(tNode)]);

        if (!tNode._bIsLoaded && tNode.bLoadChildren) {
            this.loadSubNodes(tNode);
        } else {
            if (tNode._eElem) {
                if (tNode._eSubMenuRow) { //  Unhide if DOM elements are already there
                    //   Display by removing CSS class (so a CSS3 transition can be used for animation)
                    df.dom.removeClass(tNode._eSubMenuRow, "WebTree_HiddenSubRow");
                } else {  //  Generate DOM elements
                    this.constructSubmenu(tNode, (tNode._tParent ? tNode._tParent._eSubMenuTable : this._eRootTable), tNode._eElem.rowIndex + 1, this.isLast(tNode));
                }
            }

            this.updateNodeCSS(tNode);
        }
    }

    /*
    The node will be collapsed.
    
    @param  tNode   Node to toggle (see: df.dataStructs.TAjaxTreeNode).
    */
    collapseNode(tNode) {
        tNode.bExpanded = false;

        this.fire("OnCollapse", [tNode.sId, tNode.sValue, this.getLevel(tNode)]);

        if (tNode._eSubMenuRow) {
            //   Hide by setting CSS class (so a CSS3 transition can be used for animation)
            df.dom.addClass(tNode._eSubMenuRow, "WebTree_HiddenSubRow");
        }

        //  If the selected item is now hidden we select the collapsed one
        if (this.isParent(this._tSelectedNode, tNode)) {
            while (tNode && !this.doSelect(tNode)) {
                tNode = tNode._tParent;
            }
        }

        this.updateNodeCSS(tNode);
    }

    /*
    The node above the currently selected node will be selected.
    */
    moveUp() {
        let tNode;

        if (this._tSelectedNode) {
            tNode = this._tSelectedNode;
            const iPos = this.getPosition(tNode);
            if (iPos > 0) {   //  Select the previous node on this level
                const aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);

                //  If this node is expanded move down till the last end node
                tNode = aList[iPos - 1];
                while (tNode.bExpanded && tNode._aChildren.length > 0) {
                    tNode = tNode._aChildren[tNode._aChildren.length - 1];
                }

                this.doSelect(tNode);
            } else {  //  Select the parent if available
                if (tNode._tParent) {
                    this.doSelect(tNode._tParent);
                }
            }
        }
    }

    /*
    The node below the currently selected node will be selected.
    */
    moveDown() {
        let tNode;

        if (this._tSelectedNode) {
            tNode = this._tSelectedNode;
            if (tNode.bExpanded && tNode._aChildren.length > 0) {  //  Select the first child
                this.doSelect(tNode._aChildren[0]);
            } else {
                while (tNode) {   //  Keep on moving levels up until a next node on the level is available or the root is reached
                    const aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);
                    const iPos = this.getPosition(tNode);

                    if (iPos < aList.length - 1) {
                        this.doSelect(aList[iPos + 1]);
                        break;
                    } else {
                        tNode = tNode._tParent;
                    }
                }
            }
        } else if (this._aRootItems.length > 0) {
            this.doSelect(this._aRootItems[0]);
        }

    }

    /*
    The currently selected node will be collapsed. 
    */
    doCollapse() {

        if (this._tSelectedNode) {
            const tNode = this._tSelectedNode;

            if (tNode.bExpanded && this.hasChildren(tNode)) {
                this.collapseNode(tNode);
            } else {
                if (tNode._tParent) {
                    this.doSelect(tNode._tParent);
                }
            }
        }
    }

    /*
    The currently selected node will be extended.
    */
    doExpand() {

        if (this._tSelectedNode) {
            const tNode = this._tSelectedNode;

            if (!tNode.bExpanded && this.hasChildren(tNode)) {
                this.expandNode(tNode);
            } else {
                if (tNode._aChildren.length > 0) {
                    this.doSelect(tNode._aChildren[0]);
                }
            }
        } else if (this._aRootItems.length > 0) {
            this.doSelect(this._aRootItems[0]);
        }
    }

    /*
    The first node will be selected.
    */
    moveFirst() {
        if (this._aRootItems.length > 0) {
            this.doSelect(this._aRootItems[0]);
        }
    }

    /*
    The last node will be selected.
    */
    moveLast() {
        let tNode;

        if (this._aRootItems.length > 0) {
            tNode = this._aRootItems[this._aRootItems.length - 1];

            while (tNode.bExpanded && tNode._aChildren.length > 0) {
                tNode = tNode._aChildren[tNode._aChildren.length - 1];
            }

            this.doSelect(tNode);
        }
    }

    /*
    This method will select the node that is passed.
    
    @param  tNode           Node to select.
    @param  bOptNoOnSelect  If true the OnSelect event is not fired.
    @return True if the node was successfully selected.
    */
    doSelect(tNode, bOptNoOnSelect) {

        //  When the selection changes then psSelectedId and psSelectedValue become synchronized
        this.addSync("psSelectedId");
        this.addSync("psSelectedValue");

        const tPrevSelected = this._tSelectedNode;

        //  Select the new node
        this._tSelectedNode = tNode;
        const bChanged = (this.psSelectedId !== tNode.sId);
        this.psSelectedId = tNode.sId;

        if (tPrevSelected) {
            this.updateNodeCSS(tPrevSelected);
        }
        this.updateNodeCSS(tNode);

        if (tNode._eElem) {
            this.scrollToElement(tNode._eElem);
        }

        if (!bOptNoOnSelect && bChanged) {
            this.fire("OnSelect", [tNode.sId, tNode.sValue, this.getLevel(tNode)]);
        }

        return true;
    }

    doRemove(tNode, bOptNoSelect) {
        let i, aList, bSelect = false;

        function removeSub(tNode) {
            //  Move into subnodes
            while (tNode._aChildren.length > 0) {
                removeSub.call(this, tNode._aChildren.pop());
            }

            tNode._eElem = null;
            tNode._eSubMenuRow = null;
            tNode._eSubMenuTable = null;

            //  De-select if it is the selected node
            if (tNode === this._tSelectedNode) {
                this._tSelectedNode = null;
                bSelect = true;
            }

            //  Remove from global list
            df.sys.data.removeFromArray(this._aItems, tNode);
        }

        removeSub.call(this, tNode);


        //  Remove from tree
        aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);
        if (aList) {
            //  Remove from structure
            for (i = 0; i < aList.length; i++) {
                if (aList[i] === tNode) {
                    aList.splice(i, 1);
                    break;
                }
            }
        }

        //  Reselect a node if needed
        if (bSelect && !bOptNoSelect) {
            if (aList && aList.length > 0) {
                this.doSelect(aList[i] || aList[i - 1]);
            } else {
                this.doSelect(tNode._tParent || this._aItems[0]);
            }
        }

    }

    // - - - - - - - Tree functions - - - - - - - -

    /*
    Determines the position of the nod on its level.
    
    @param  tNode   Node
    @return Position of the node on its level (-1 if not in the structure).
    @private
    */
    getPosition(tNode) {

        const aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);

        for (let iPos = 0; iPos < aList.length; iPos++) {
            if (aList[iPos] === tNode) {
                return iPos;
            }
        }

        return -1;
    }

    /*
    Determines if the node is the last of its level.
    
    @param  tNode   Node
    @return True if the node is the last.
    @private
    */
    isLast(tNode) {
        const aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);

        return (aList[aList.length - 1] === tNode);
    }

    /*
    Determines if the node is the first of its level.
    
    @param  tNode   Node
    @return True if the node is the first.
    @private
    */
    isFirst(tNode) {
        const aList = (tNode._tParent ? tNode._tParent._aChildren : this._aRootItems);

        return (aList[0] === tNode);
    }

    /*
    Determines if the node is in the root of the tree.
    
    @param  tNode   Node
    @return True if the node is in the root.
    @private
    */
    isRoot(tNode) {
        return (tNode._tParent ? false : true);
    }

    /*
    Determines if the node is a child of the parent node.
    
    @param  tNode   Node.
    @param  tParent Parent to determine.
    @returns    True if the parent is a parent of the child.
    @private
    */
    isParent(tNode, tParent) {
        while (tNode) {
            if (tNode === tParent) {
                return true;
            }

            tNode = tNode._tParent;
        }

        return false;
    }

    /*
    Determines the level of the node in the tree.
    
    @param  tNode   Node.
    @return Level (first level is 1).
    @private
    */
    getLevel(tNode) {
        let iLevel = 1;

        while (tNode._tParent) {
            iLevel++;
            tNode = tNode._tParent;
        }

        return iLevel;
    }

    /*
    Can be used to obtain a reference to a node struct.
    
    @param  sNodeId     Unique ID of the node.
    @return Reference to the node struct (see: df.dataStructs.TAjaxTreeNode).
    */
    getNodeById(sNodeId) {

        for (let i = 0; i < this._aItems.length; i++) {
            if (this._aItems[i].sId === sNodeId) {
                return this._aItems[i];
            }
        }

        return null;
    }

    /*
    Determines if the node has children.
    
    @param  tNode   Node
    @return True if the node has children.
    @private
    */
    hasChildren(tNode) {
        return (tNode.bLoadChildren && !tNode._bIsLoaded) || tNode._aChildren.length > 0;
    }

    // - - - - - - - Supportive - - - - - - - -

    /*
    Scrolls to the element if the
    
    @private
    */
    scrollToElement(eElem) {

        const oElem = df.sys.gui.getAbsoluteOffset(eElem);
        const oDiv = df.sys.gui.getAbsoluteOffset(this._eControl);

        const iTop = oElem.top - oDiv.top;

        if (iTop < this._eControl.scrollTop) {
            this._eControl.scrollTop = iTop;
        } else if (iTop + eElem.offsetHeight > this._eControl.scrollTop + this._eControl.clientHeight) {
            this._eControl.scrollTop = iTop + eElem.offsetHeight - this._eControl.clientHeight;
        }
    }

    /*
    This method handles the onclick event of the body. It first determines which tree item is clicked 
    and it makes a difference between clicking the expand / collapse button or the item itself. With 
    that information it will expand / collapse and / or select the tree item.
    
    @param  oEvent  The event object (see: df.events.DOMEvent).
    @private
    */
    onBodyClick(oEvent) {
        let sNodeId = null, bSelect = true, eElem = oEvent.getTarget();

        if (this.isEnabled()) {
            //  Bubble up in the DOM finding the Node ID and checking if text or tree is clicked
            while (eElem && !sNodeId && eElem !== this._eElem) {
                if (eElem.className.indexOf("WebTree_Item") >= 0) {
                    bSelect = false;
                }

                sNodeId = eElem.getAttribute("data-dftree-id");

                eElem = eElem.parentNode;
            }

            //  Get node object
            const tNode = this.getNodeById(sNodeId);

            if (tNode) {
                if (bSelect) {
                    //  Select and expand
                    if (this._tSelectedNode !== tNode) {
                        // this.returnFocus();
                        //  Expand the node if we want to
                        if (!tNode.bExpanded && this.hasChildren(tNode)) {
                            this.expandNode(tNode);
                        }

                        this.doSelect(tNode);
                    } else {
                        this.toggle(tNode);
                    }

                } else {
                    //  Switch expanded
                    this.toggle(tNode);


                }

                oEvent.stop();
            }

            this.focus();
        }
    }

    onBodyDblClick(oEvent) {
        let sNodeId = null, eElem = oEvent.getTarget();

        if (this.isEnabled()) {

            //  Bubble up in the DOM finding the Node ID and checking if text or tree is clicked
            while (eElem && !sNodeId && eElem !== this._eElem) {
                sNodeId = eElem.getAttribute("data-dftree-id");

                eElem = eElem.parentNode;
            }

            //  Get node object
            const tNode = this.getNodeById(sNodeId);

            if (tNode) {
                if (this.fireSubmit()) {
                    oEvent.stop();
                }
            }
        }
    }

    /*
    Handles the keypress event of the hidden focus anchor. Compares the event 
    details to the oKeyActions and executes the action if a match is found.
    
    @param  oEvent  Event object.
    @private
    */
    onKey(oEvent) {
        if (this.isEnabled()) {

            if (oEvent.matchKey(df.settings.treeKeys.moveUp)) {
                this.moveUp();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.moveDown)) {
                this.moveDown();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.collapse)) {
                this.doCollapse();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.extend)) {
                this.doExpand();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.moveFirst)) {
                this.moveFirst();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.moveLast)) {
                this.moveLast();
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.treeKeys.enter)) {
                if (this.fireSubmit()) {
                    oEvent.stop();
                }
            }
        }
    }

    /*
    Updates the node CSS and if null is received globally display loading.
    
    @param  tNode   Node struct.
    @private
    */
    displayLoading(tNode) {
        if (tNode) {
            this.updateNodeCSS(tNode);
        } else {
            if (this._eControl) {
                df.dom.addClass(this._eControl, "WebTree_Loading");
            }
        }
    }

    /*
    Updates the node CSS and if null is received globally hide loading.
    
    @param  tNode   Node struct.
    @private
    */
    hideLoading(tNode) {
        if (tNode) {
            this.updateNodeCSS(tNode);
        } else {
            if (this._eControl) {
                df.dom.removeClass(this._eControl, "WebTree_Loading");
            }
        }
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

    /*
    Augments the onFocus event handler and cancel the blurring. This is because the focus can switch 
    between elements within the treeview and we don't want that to cause a blur event.
    
    @param oEvent   Event object.
    @private
    */
    onFocus(oEvent) {
        super.onFocus(oEvent);
        this._bLozingFocus = false;
    }

    /*
    Augments the blur event and adds a little timeout before forwarding it. If we receive a focus event 
    within timeout we do not forward it because is a focus change within the treeview itself.
    
    @param  oEvent  Event object.
    @private
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
        }, 100);
    }

    // WebUIContext

    determineSelectorForWebUIContext(eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextTreeviewFolder:
            case df.WebUIContext.WebUIContextTreeviewItem:
                return "tr[data-dftree-id]";
        }
        return null;
    }

    verifyElementForWebUIContext(eElem, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextTreeviewFolder:
            case df.WebUIContext.WebUIContextTreeviewItem: {
                if (!eElem.hasAttribute('data-dftree-id')) return false;

                const iItemId = eElem.getAttribute("data-dftree-id");
                const hItem = this.getNodeById(iItemId);
                return ((hItem.bFolder && eContext === df.WebUIContext.WebUIContextTreeviewFolder) ||
                    (!hItem.bFolder && eContext === df.WebUIContext.WebUIContextTreeviewItem));
            }
        }
        return true;
    }

    retrieveValueFromWebUIContext(eElem, eContext) {
        switch (eContext) {
            case df.WebUIContext.WebUIContextTreeviewFolder:
            case df.WebUIContext.WebUIContextTreeviewItem: {
                if (!eElem.hasAttribute('data-dftree-id'))
                    break;
                return eElem.getAttribute('data-dftree-id')
            }
        }
        return null;
    }

    // === Drag & Drop ===

    getDragData(oEv, eDraggedElem) {
        try {
            const itemId = eDraggedElem.getAttribute("data-dftree-id") || -1;
            let item, eAction;

            if (itemId && itemId != -1 && (itemId != '' || itemId >= 0)) {
                // Destructure object to create a clone, then remove any privates (prevent circular json error)
                item = { ...this.getNodeById(itemId) };

                Object.keys(item).forEach(function (key) {
                    key.indexOf("_") == 0 && delete item[key];
                });

                if (item.bFolder) {
                    eAction = df.dragActions.WebTreeView.ciDragFolder;
                } else {
                    eAction = df.dragActions.WebTreeView.ciDragItem;
                }
            }
            return [{ data: item }, eAction]
        } catch (err) {
            // This can happen if the drag action is not supported, we don't want a nasty error if so.
            console.error("Attempt to perform unsupported drag action");
            return [null, null];
        }
    }

    getDropData(oDropZone, oPosition) {
        if (oDropZone && oDropZone._eDropElem) {
            const itemId = oDropZone._eDropElem.getAttribute("data-dftree-id") || -1;
            let item, eAction;

            if (itemId && itemId != -1 && (itemId != '' || itemId >= 0)) {
                // Destructure object to create a clone, then remove any privates (prevent circular json error)
                item = { ...this.getNodeById(itemId) };

                Object.keys(item).forEach(function (key) {
                    key.indexOf("_") == 0 && delete item[key];
                });

                if (item.bFolder) {
                    eAction = df.dropActions.WebTreeView.ciDropOnFolder;
                } else {
                    eAction = df.dropActions.WebTreeView.ciDropOnItem;
                }
            }

            const dropData = {
                data: item,
                action: eAction
            }

            return dropData;
        }
        return null;
    }

    initDraggableElements() {
        // because not all nodes / items are present at initialisation
        // setting draggable="true" is done constructNode
        // HR: Not sure if this is still needed
    }

    initDropZones() {
        this._aDropZones = [];

        super.initDropZones();

        if (this.isSupportedDropAction(df.dropActions.WebTreeView.ciDropOnFolder) ||
            this.isSupportedDropAction(df.dropActions.WebTreeView.ciDropOnItem)) {

            // Mark entire tree body as drop zone
            const eZone = (df.dom.query(this._eElem, '.WebTree_Body'));
            this.addDropZone(eZone);
        }
    }

    determineDropCandidate(oEv, aHelpers) {
        // DropOnControl and other drop actions cannot exist within the same control simultaneously
        // It makes sense to check for this first to get it out of the way as it is the simplest check
        if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebControl.ciDropOnControl))) {
            return [this._eElem, df.dropActions.WebControl.ciDropOnControl];
        }

        const eElem = document.elementFromPoint(oEv.e.clientX, oEv.e.clientY);
        let eNode = eElem?.closest('tr[data-dftree-id]');

        if (eNode) {
            // console.log(eNode);
            let id = eNode.getAttribute('data-dftree-id');
            let item = this.getNodeById(id);
            if (item.bFolder) {
                if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebTreeView.ciDropOnFolder))) {
                    return [eNode, df.dropActions.WebTreeView.ciDropOnFolder];
                }
            } else {
                if (aHelpers.find(oHelper => oHelper.supportsDropAction(this, df.dropActions.WebTreeView.ciDropOnItem))) {
                    return [eNode, df.dropActions.WebTreeView.ciDropOnItem];
                }
            }
        }

        return [null, null];
    }

    determineDropPosition(oEv, eElem) {
        return df.dropPositions.ciDropOn;
    }

    interactWithDropElem(dropZone, eElem) {
        if (dropZone._eDropAction == df.dropActions.WebControl.ciDropOnControl) {
            dropZone.highlightElement();
        } else {
            // Can add custom visual interaction here later if needed
            dropZone.highlightElement();
        }
    }

    doEmptyInteraction(dropZone) {
        if (this.isSupportedDropAction(df.dropActions.WebTreeView.ciDropOnRoot)) {
            // Can do custom visual interaction here later if needed
            dropZone.highlightElement();
            return df.dropActions.WebTreeView.ciDropOnRoot;
        } else if (this.isSupportedDropAction(df.dropActions.WebControl.ciDropOnControl)) {
            dropZone.highlightElement();
            return df.dropActions.WebControl.ciDropOnControl;
        }

        return null;
    }

    onControlDragOver(oEv, oDropZone, eDropElem) {
        // After 1 second, expand the currently hovered node
        if (eDropElem != this._eCurHoveredElem) {
            this._eCurHoveredElem = eDropElem;

            clearTimeout(this._fHoverTimeOut);

            if (this._eCurHoveredElem) {
                this._fHoverTimeOut = setTimeout(() => {
                    this.expand(this._eCurHoveredElem.getAttribute('data-dftree-id'));
                }, 1000);
            }
        }
    }

    hasData() {
        return (this._aItems && this._aItems.length > 0);
    }
}