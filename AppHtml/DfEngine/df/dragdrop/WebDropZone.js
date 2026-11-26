export class WebDropZone {
  constructor(eZone, oControl) {
    this._eZone = eZone; // The underlying html element
    this._oControl = oControl; // Reference to the control this dropzone belongs to
    this._eInsertedElem = null; // Will contain the insertedElement so it can be removed later, can only contain 1
    this._aHelpers = []; // List of responsible helpers, filled upon starting the drag (when highlighting)
    this._eDropPosition = -1; // Determined position (on, before, or after) for the dropped element. -1 = unknown.
    this._eDropElem = null; // Temporary reference to the current element being dropped on
    this._eDropAction = -1; // Temporary reference to the elements' corresponding drop action
    this._iEnterCount = 0; // Used to determine if we actually left this dropzone when a dragLeave event fires
  }

  highlight(oHelper) {
    df.dom.addClass(this._eZone, "WebCon_DropZone");
    this.attachHandlers();

    // Add responsible helper
    this._aHelpers.push(oHelper);
  }

  unhighlight() {
    df.dom.removeClass(this._eZone, "WebCon_DropZone");
    this.detachHandlers();
    this.removeDropElemInteractions();

    // Remove responsible helpers
    this._aHelpers = [];

    // Cleanup
    this._eDropPosition = -1;
    this._eDropElem = null;
    this._eDropAction = -1;
    this._iEnterCount = 0;
  }

  destroy() {
    this.unhighlight();
  }

  attachHandlers() {
    df.dom.on("dragenter", this._eZone, this.onDragEnter, this);
    df.dom.on("dragleave", this._eZone, this.onDragLeave, this);
    df.dom.on("dragover", this._eZone, this.onDragOver, this);
    df.dom.on("drop", this._eZone, this.onDrop, this);
  }

  detachHandlers() {
    df.dom.off("dragenter", this._eZone, this.onDragEnter, this);
    df.dom.off("dragleave", this._eZone, this.onDragLeave, this);
    df.dom.off("dragover", this._eZone, this.onDragOver, this);
    df.dom.off("drop", this._eZone, this.onDrop, this);
  }

  getDropData() {
    return this._oControl.getDropData(this);
  }

  // DragDrop Events
  onDrop(oEv) {
    oEv.e.preventDefault();
    this._oControl.onDrop(oEv, this, this._eDropAction);
    this.removeDropElemInteractions();
    this._iEnterCount = 0;
  }

  onDragOver(oEv) {
    oEv.e.preventDefault();

    if (!this.controlHasData()) {
      this._eDropPosition = df.dropPositions.ciDropOnEmpty;
      this._eDropElem = null;
      this._eDropAction = this.doEmptyInteraction();
    } else {
      // Get the element that needs to be interacted with
      const [eDropElem, eDropAction] = this.getDropCandidate(oEv);
      const bOverDropPlaceHolder = this.isOverDropPlaceHolder(oEv);
      let ePosition;

      if (eDropElem == null && !bOverDropPlaceHolder) {
        this.removeDropElemInteractions();
        this._eDropElem = null;
        ePosition = this._eDropPosition = 0;
      }
      if (eDropElem != null && !bOverDropPlaceHolder) {
        ePosition = this.getDropPosition(oEv, eDropElem);
      }
      const bInteract = ((ePosition > 0 && eDropElem != null) && (eDropElem != this._eDropElem || this._eDropPosition != ePosition));
      if (bInteract && !bOverDropPlaceHolder) {
        this.removeDropElemInteractions();
        this._eDropElem = eDropElem;
        this._eDropPosition = ePosition;
        this._eDropAction = eDropAction;
        this.interactWithDropElem();
      }

      this._oControl.onControlDragOver(oEv, this, eDropElem);
    }
    return false;
  }

  onDragEnter(oEv) {
    oEv.e.preventDefault();
    this._iEnterCount++;
    // return false;
  }

  onDragLeave(oEv) {
    oEv.e.preventDefault();
    this._iEnterCount--;

    // Check if we actually left the dropzone
    // if (!this.isInDropZone(oEv)) {
    // Now use a simple counter, probably much more efficient...
    if (this._iEnterCount <= 0) {
      this.removeDropElemInteractions();
      this._eDropElem = null;
      this._eDropPosition = 0;
      this._iEnterCount = 0;
    }

    // return false;
  }

  // isInDropZone (oEv) {
  //   let eElem = document.elementFromPoint(oEv.e.x, oEv.e.y);

  //   while (eElem && eElem != this._oControl._eElem) {
  //       if (eElem == this._eZone) {
  //           return true;
  //       }
  //       eElem = eElem.parentNode;
  //   }

  //   return false;
  // }

  getDropCandidate(oEv) {
    const [eDropElem, eDropAction] = this._oControl.determineDropCandidate(oEv, this._aHelpers);

    return [eDropElem, eDropAction];
  }

  getDropPosition(oEv, eDropElem) {
    const ePosition = this._oControl.determineDropPosition(oEv, eDropElem);
    return ePosition;
  }

  isOverDropPlaceHolder(oEv) {
    let eElem = document.elementFromPoint(oEv.e.x, oEv.e.y);

    if (eElem) {
      return eElem.classList.contains("DfDragDrop_PlaceHolder");
    }

    return false;
  }

  controlHasData() {
    return this._oControl.hasData();
  }

  removeDropElemInteractions() {
    this.removeInsertedElement();
    this.clearHighlight();
  }

  interactWithDropElem() {
    this._oControl.interactWithDropElem(this, this._eDropElem);
  }

  doEmptyInteraction() {
    const eDropAction = this._oControl.doEmptyInteraction(this);
    return eDropAction;
  }

  highlightElement() {
    if (this._eDropElem) {
      df.dom.addClass(this._eDropElem, "WebCon_DragHover");
    }
  }

  clearHighlight() {
    if (this._eDropElem) {
      df.dom.removeClass(this._eDropElem, "WebCon_DragHover");
    }
  }

  insertElement(eElem, targetElem, eOptForceDropPosition) {
    if (!this._eInsertedElem) {
      df.dom.addClass(eElem, "DfDragDrop_PlaceHolder");
      eElem.setAttribute('data-dfdropplaceholder', true);

      let eDropPosition = eOptForceDropPosition || this._eDropPosition;

      switch (eDropPosition) {
        case df.dropPositions.ciDropBefore:
          targetElem.insertAdjacentElement('beforebegin', eElem);
          break;
        case df.dropPositions.ciDropAfter:
          targetElem.insertAdjacentElement('afterend', eElem);
          break;
        case df.dropPositions.ciDropOnEmpty:
          targetElem.appendChild(eElem);
          break;
      }

      this._eInsertedElem = eElem;
    }
  }

  removeInsertedElement() {
    if (this._eInsertedElem) {
      this._eInsertedElem?.parentNode?.removeChild(this._eInsertedElem);
      this._eInsertedElem = null;
    }
  }
};