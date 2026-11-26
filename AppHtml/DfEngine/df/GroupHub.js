/* 
Class:
    df.GroupHub
    
This class is a generic hub between providers and listeners that share data in groups. The group is 
identified by a string a unique string. Both providers and listeners register themselves to a 
specific group. Listeners implement the groupUpdate method which is called passing a data array with 
the new group data. This update is performed as soon as the contents of the group might have 
changed. This change can mean that the set of providers is changed or that a provider triggered an 
update by calling updateGroup. The provider needs to implement the collectGroup procedure which is 
called by the hub during an update to gather the data for that group during an update. It gets 
passed an array to which it can add its data. This class is being used by the group logic of the 
menu system.

Revision:
    2015/01/15  Creation (HW, DAW)
 */


export class GroupHub {
    constructor() {
        this._oGroups = {};
    }
    /* 
    Registers an object as listener for a specific group. Listener objects should implement the 
    groupUpdate function. Adding a listener causes groupUpdate to be called immediately to provide the 
    initial set of data.
    
    @param  sGroup      Name of the group.
    @param  oListener   Listener object.
    */
    addListener(sGroup, oListener) {
        sGroup = sGroup.toLowerCase();

        //  Initiate group if neede
        if (!this._oGroups[sGroup]) {
            this._oGroups[sGroup] = { aListeners: [], aProviders: [] };
        }

        //  Register listener
        this._oGroups[sGroup].aListeners.push(oListener);

        //  Do initial update
        const aData = this.collectGroup(sGroup);
        oListener.groupUpdate(aData);
    }

    /* 
    Unregisters an object as a listener for a specific group.
    
    @param  sGroup      Name of the group.
    @param  oListener   Listener object.
    */
    remListener(sGroup, oListener) {
        sGroup = sGroup.toLowerCase();

        if (this._oGroups[sGroup]) {
            const i = this._oGroups[sGroup].aListeners.indexOf(oListener);

            if (i >= 0) {
                //  Remove if found
                this._oGroups[sGroup].aListeners.splice(i, 1);
            }
        }
    }

    /* 
    Registers a provider for a specific group. Provider objects should implement the groupCollect 
    function that is called passing an array by reference to add the data to. Adding a provider causes 
    the group to update itself immediately.
    
    @param  sGroup      Name of the group.
    @param  oProv       The provider object.
    */
    addProvider(sGroup, oProv) {
        sGroup = sGroup.toLowerCase();

        //  Initiate group if needed
        if (!this._oGroups[sGroup]) {
            this._oGroups[sGroup] = { aListeners: [], aProviders: [] };
        }

        //  Register provider
        this._oGroups[sGroup].aProviders.push(oProv);

        //  Do initial update
        this.updateGroup(sGroup);
    }

    /* 
    Removes a provider from a specific group. Removing a provider causes a group to update itself.
    
    @param  sGroup  Name of the group.
    @param  oProv   Provider object to unregister.
    */
    remProvider(sGroup, oProv) {
        sGroup = sGroup.toLowerCase();

        //  Find group & provider
        if (this._oGroups[sGroup]) {
            const i = this._oGroups[sGroup].aProviders.indexOf(oProv);
            if (i >= 0) {

                //  Remove if found
                this._oGroups[sGroup].aProviders.splice(i, 1);

                //  Update group
                this.updateGroup(sGroup);
            }
        }
    }

    /* 
    Updates a specific group by collecting its data from the providers and then triggering the listeners 
    by calling their groupUpdate procedures.
    
    @param  sGroup  Name of the group.
    */
    updateGroup(sGroup) {
        sGroup = sGroup.toLowerCase();

        //  Check if there is anything to update
        if (this._oGroups[sGroup] && this._oGroups[sGroup].aListeners.length > 0) {
            //  Collect data
            const aData = this.collectGroup(sGroup);

            //  Update listeners with new data
            const aL = this._oGroups[sGroup].aListeners;
            for (let i = 0; i < aL.length; i++) {
                aL[i].groupUpdate(aData);
            }
        }
    }

    /* 
    Collects data for a specific group by calling groupCollect on all the providers. An array is passed 
    by reference to the groups so they can add their data.
    
    @param  sGroup      Name of the group.
    @return     Array with the group data.
    */
    collectGroup(sGroup) {
        let aData = []; 

        sGroup = sGroup.toLowerCase();

        //  Loop over providers to collect data
        const aP = this._oGroups[sGroup].aProviders;
        for (let i = 0; i < aP.length; i++) {
            aP[i].groupCollect(aData);
        }

        return aData;
    }

    /* 
    Returns all listener objects for a specific group.
    */
    getListeners(sGroup) {
        if (this._oGroups[sGroup]) {
            return this._oGroups[sGroup].aListeners.slice();
        }
        return [];
    }

};