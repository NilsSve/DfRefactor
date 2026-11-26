import { WebDragDropHelper } from './WebDragDropHelper.js';
import { WebFileUpload_Mixin } from '../WebBaseFileUpload.js';
import { df } from '../../df.js';

// Create base class for WebBaseFileUpload with WebFileUpload Mixin
class WebDragDropUploadBase extends WebFileUpload_Mixin(WebDragDropHelper) { } //df.mixin("df.WebFileUpload_Mixin", "df.WebDragDropHelper");

export class WebDragDropFileHelper extends WebDragDropUploadBase {
  constructor(sName, oParent) {
    super(sName, oParent);

    // this._bFileDrag = false;
    this._oCurDropZone = null;
  }

  create() {
    super.create();

    // WebDragDropFileHelpers need to register themselves with the WebApp's df.dragdrop logic
    // This is so we can make use of the single (existing) event handler on the document that can call all these helpers on a file entering the window.
    df.dragdrop.registerHelper(this);
  }

  onFileDrag(oEvent) {
    this._bInitializedDrag = true;
    this.highlightDropZones();
  }

  onDragEnd(oEv) {
    super.onDragEnd();
  }

  // OnDrop
  // Modified to call OnFileDrop on server
  onDrop(oEv, oSourceDfObj, oDropZone) {
    // console.log('FILE DROP');
    const oDragData = this._oDragData;
    const oDropData = oDropZone.getDropData();
    const bFileDrag = df.dragdrop.containsFiles(oEv.e);

    if ((oDragData || bFileDrag) && oDropZone && this.supportsDropAction(oDropZone._oControl, oDropZone._eDropAction)) {
      if (bFileDrag) {
        // Temporarily store data, we clear it again after processing the file upload
        this._tempDropData = oDropData;
        this._oCurDropZone = oDropZone;
        this.initFiles(oEv.e.dataTransfer.files);
        this.startUpload();
      } else {

        // Collect drag drop data
        var oDragDropData = {
          DragData: oDragData.oData,
          DropData: oDropData
        }

        // Send OnDrop serveraction
        this.serverAction("Drop", [this._oDragData.oControl.getLongName(), oDropZone._oControl.getLongName(), oDropZone._eDropPosition], oDragDropData);
      }
    }

    this.onDragEnd(oEv);
  }

  // Calls server side upload logic,
  // This is the default implementation, which can be modified to tailor specific classes needs
  // The server side function should always return an array containing the fileIndex and upload key (aka: asResults = [index][fileIndex, key])
  doStartUpload(fUploadCallback, aRows) {
    // ToDo: Maybe convert aRows to a nice object with {index, filename, size, mime} so we can parse this to a struct at the server. Nicer to work with..
    const oDragDropData = {
      DragData: aRows, // In this case, the drag data is the files info, which is stored in aRows
      DropData: this._tempDropData
    }
    //  Send call to initialize upload
    this.serverAction("FileDrop", [this._oCurDropZone._oControl.getLongName(), this._oCurDropZone._eDropPosition], oDragDropData, fUploadCallback);
  }

  // Augmented to reset the _tempDropData
  cleanupHelper(oEv) {
    super.cleanupHelper();

    this._tempDropData = null;
  }
}