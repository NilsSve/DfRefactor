import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';


export class WebDrawing extends WebBaseControl {
    constructor(sName, oParent) {
        // Configure superclasses
        super(sName, oParent);

        // Properties
        this.prop(df.tInt, "peDrawingJustification", 0);
        this.prop(df.tInt, "piDrawingWidth", 0);
        this.prop(df.tInt, "piDrawingHeight", 0);
        this.prop(df.tInt, "peResizeMode", 0);
        this.prop(df.tBool, "pbNoContextMenu", false);
        this.prop(df.tBool, "pbZoomable", false);
        this.prop(df.tNumber, "pfMinZoom", 0.125);
        this.prop(df.tNumber, "pfMaxZoom", 4);
        this.prop(df.tNumber, "pfDefaultZoom", 1);
        this.prop(df.tBool, "pbClientOnResize", false);
        this.prop(df.tBool, "pbDebugOutline", false);
        this.prop(df.tInt, "piDebugOutlineWidth", 1);
        this.prop(df.tString, "psDebugOutlineColor", "");
        this.prop(df.tBool, "pbShowBorder", false);
        this.prop(df.tString, "psCanvasBackgroundColor", "");

        /** @type {SVGGraphicsElement | null} */
        this._eDrawing = null;
        /** @type {Map<string, DrawingItem>} */
        this.drawingItemMap = new Map();
        this.drawingsBuffered = false;

        /** @type {number} */
        this.globalScale = 1;
        /** @type {Position} */
        this.panOffset = { x: 0, y: 0 };
        /** @type {Position} */
        this.previousMousePosition = undefined;

        this.ns = "http://www.w3.org/2000/svg";

        this._zoomBtns = undefined;
        this._btnZoomIn = undefined;
        this._btnZoomOut = undefined;
        this._btnZoomReset = undefined;

        this.wdResizeModeDisabled = 0;
        this.wdResizeModeScale = 1;
        this.wdResizeModeCrop = 2;

        this.wdInteractionOnMouseDown = 1;
        this.wdInteractionOnMouseUp = 2;
        this.wdInteractionOnMouseEnter = 4;
        this.wdInteractionOnMouseLeave = 8;
        this.wdInteractionOnMouseMove = 16;
        this.wdInteractionOnMouseClick = 32;
        this.wdInteractionOnMouseDoubleClick = 64;
        this.wdInteractionOnMouseDrag = 128;

        this._bJSSizing = true;

    }

    // Standard functions
    create() {
        // Throw error if scaling mode is enabled without a piDrawingWith and/or piDrawingHeight
        if (this.peResizeMode === this.wdResizeModeScale && (this.piDrawingWidth <= 0 || this.piDrawingHeight <= 0)) {
            throw new df.Error(999, "A piDrawingWidth and piDrawingHeight have to be defined when peResizeMode is set to Scaling.");
        }

        // Disallow pfMinZoom below 0
        if (this.pfMinZoom < 0) {
            throw new df.Error(999, "pfMinZoom cannot go below 0");
        }

        // Disallow pfMinZoom to be higher than pfMaxZoom
        if (this.pfMinZoom > this.pfMaxZoom) {
            throw new df.Error(999, "pfMinZoom cannot be higher than pfMaxZoom");
        }

        // Disallow pfMaxZoom to be lower than pfMinZoom
        if (this.pfMaxZoom < this.pfMinZoom) {
            throw new df.Error(999, "pfMaxZoom cannot be lower than pfMinZoom");
        }

        if (this.pfDefaultZoom < this.pfMinZoom || this.pfDefaultZoom > this.pfMaxZoom) {
            throw new df.Error(999, "The default zoom cannot be lower or higher than the pfMinZoom and/or pfMaxZoom");
        }
    }

    openHtml(aHtml) {
        // Forward send
        super.openHtml(aHtml);

        aHtml.push('<div class="WebDrawing-wrp">');
        aHtml.push('    <div class="WebDrawing-wrp-inner">');
        aHtml.push('        <div class="WebDrawing-zoom-buttons" style="display: none;">');
        aHtml.push('            <button class="WebDrawing-btn-zoom WebDrawing-btn-zoom-in">+</button>');
        aHtml.push('            <button class="WebDrawing-btn-zoom WebDrawing-btn-zoom-reset">&#x21bb</button>');
        aHtml.push('            <button class="WebDrawing-btn-zoom WebDrawing-btn-zoom-out">-</button>');
        aHtml.push('        </div>');
        aHtml.push('        <svg xmlns="http://www.w3.org/2000/svg" style="background-color:' + this.psCanvasBackgroundColor + '"></svg>');
        aHtml.push('    </div>');
        aHtml.push('</div>');
    }

    afterRender() {
        this.initializeDrawing();

        if (this.drawingsBuffered) {
            this.drawingsBuffered = false;
            this.createSVGDomElements(this.drawingItemMap);
        }

        // Forward send
        super.afterRender();

        this.set_pbShowBorder(this.pbShowBorder);
    }

    initializeDrawing() {
        this._eControl = df.dom.query(this._eElem, ".WebDrawing-wrp");
        this._eDrawing = this._eControl.querySelector("svg");

        this._zoomBtns = this._eControl.querySelector(".WebDrawing-zoom-buttons");
        this._btnZoomIn = this._eControl.querySelector(".WebDrawing-btn-zoom-in");
        this._btnZoomOut = this._eControl.querySelector(".WebDrawing-btn-zoom-out");
        this._btnZoomReset = this._eControl.querySelector(".WebDrawing-btn-zoom-reset");

        // Apply property settings
        if (this.pbNoContextMenu) this._eDrawing.addEventListener("contextmenu", e => e.preventDefault());
        if (this.pbDebugOutline) this._eDrawing.style.border = this.piDebugOutlineWidth + "px solid black", this._eDrawing.style.borderColor = this.psDebugOutlineColor;

        if (this.pbZoomable) {
            this._zoomBtns.style.display = "block";
            this.globalScale = this.pfDefaultZoom;

            this._eDrawing.addEventListener("wheel", (event) => {
                event.preventDefault();

                this.globalScale += event.deltaY * -0.001;

                this.updateViewBox();
            });

            this._eDrawing.addEventListener("mousedown", (event) => {
                this.previousMousePosition = this.getMousePos(event);
            });

            this._eDrawing.addEventListener("touchstart", (event) => {
                this.previousMousePosition = this.getTouchPos(event);
            });

            this._eDrawing.addEventListener("mousemove", (event) => {
                if (event.buttons !== 0) {
                    if (this.previousMousePosition !== undefined) {
                        event.preventDefault();

                        // Do panning
                        const currentMousePosition = this.getMousePos(event);
                        this.viewPanning(currentMousePosition);
                    }
                }
            });

            this._eDrawing.addEventListener("touchmove", (event) => {
                if (this.previousMousePosition !== undefined) {
                    event.preventDefault();

                    // Do panning
                    const currentMousePosition = this.getTouchPos(event);
                    this.viewPanning(currentMousePosition);
                }
            });

            this._btnZoomIn.addEventListener("click", () => {
                this.globalScale += 0.1;
                this.updateViewBox();
            });

            this._btnZoomOut.addEventListener("click", () => {
                this.globalScale += -0.1;
                this.updateViewBox();
            });

            this._btnZoomReset.addEventListener("click", () => {
                this.globalScale = this.pfDefaultZoom;
                this.updateViewBox();
            });
        }

        this.updateViewBox();
    }

    /**
     * View panning
     * @param {Position} currentMousePosition
     * @private
     */
    viewPanning(currentMousePosition) {
        // Calculate difference
        const diffX = this.previousMousePosition.x - currentMousePosition.x;
        const diffY = this.previousMousePosition.y - currentMousePosition.y;

        let diffXScaled = diffX / this.globalScale;
        let diffYScaled = diffY / this.globalScale;

        if (this.peResizeMode === this.wdResizeModeScale) {
            const ratio = Math.min(this._eControl.clientWidth / this.piDrawingWidth, this._eControl.clientHeight / this.piDrawingHeight);

            diffXScaled = diffXScaled / ratio;
            diffYScaled = diffYScaled / ratio;
        }

        this.panOffset.x += diffXScaled;
        this.panOffset.y += diffYScaled;

        this.updateViewBox();

        this.previousMousePosition = currentMousePosition;
    }

    updateViewBox() {
        this.globalScale = Math.min(Math.max(this.pfMinZoom, this.globalScale), this.pfMaxZoom); // Restrict scale

        let width = this.piDrawingWidth;
        let height = this.piDrawingHeight;

        if (this.peResizeMode === this.wdResizeModeCrop) {
            width = this._eControl.clientWidth;
            height = this._eControl.clientHeight;
        }

        const centerX = width / 2;
        const centerY = height / 2;

        const newWidth = width / this.globalScale;
        const newHeight = height / this.globalScale;

        const offsetX = this.panOffset.x + (centerX - newWidth / 2);
        const offsetY = this.panOffset.y + (centerY - newHeight / 2);

        this._eDrawing.setAttributeNS(null, "viewBox", `${offsetX} ${offsetY} ${newWidth} ${newHeight}`);
    }


    updateSizes() {
        if (this.peResizeMode !== this.wdResizeModeDisabled) {
            if (this._eControl.clientHeight) {
                if (this._eDrawing.width.baseVal.value !== this._eControl.clientWidth || this._eDrawing.height.baseVal.value !== this._eControl.clientHeight) {
                    if (this.peResizeMode === this.wdResizeModeScale) {
                        const heightRatio = this._eControl.clientHeight / this.piDrawingHeight;
                        const widthRatio = this._eControl.clientWidth / this.piDrawingWidth;

                        const newWidth = this.piDrawingWidth * widthRatio;
                        const newHeight = this.piDrawingHeight * heightRatio;

                        this._eDrawing.setAttributeNS(null, "width", newWidth.toString());
                        this._eDrawing.setAttributeNS(null, "height", newHeight.toString());
                    }
                    else if (this.peResizeMode === this.wdResizeModeCrop) {
                        this._eDrawing.setAttributeNS(null, "width", this._eControl.clientWidth.toString());
                        this._eDrawing.setAttributeNS(null, "height", this._eControl.clientHeight.toString());
                    }

                    this.updateViewBox();

                    if (this.pbClientOnResize) {
                        const dataToSend = this.createResizeEventData(this._eDrawing.width.baseVal.value, this._eDrawing.height.baseVal.value);
                        this.serverAction("HandleResize", [], dataToSend);
                    }
                }
            }
        }
        else {
            this._eDrawing.setAttributeNS(null, "width", this.piDrawingWidth.toString());
            this._eDrawing.setAttributeNS(null, "height", this.piDrawingHeight.toString());
        }
    }

    setHeight(iHeight, bSense) {
        super.setHeight(iHeight, bSense);

        if (bSense) {
            df.dom.animFrame(this.updateSizes, this);
        }
    }

    /**
     * Create resize event data
     * @param {number} viewWidth The view width
     * @param {number} viewHeight The view height
     * @private
     */
    createResizeEventData(viewWidth, viewHeight) {
        const data = {};

        data.fViewWidth = viewWidth;
        data.fViewHeight = viewHeight;

        return data;
    }

    // Client Events

    /**
     * Update drawing instructions
     */
    updateInstructions() {
        this.drawingItemMap = this.collectInstructions(this._tActionData, this.drawingItemMap);

        this.setGroupingPositions();
        this.updateDrawing();
    }

    /**
     * Reset and clear the entire drawing
     */
    clearDrawing() {
        if (this._eDrawing) {
            this.drawingItemMap = new Map();
            this._eDrawing.innerHTML = "";
            this.initializeDrawing();
        }
    }

    // Collect and apply instructions

    /**
     * Update the drawing
     * @private
     */
    updateDrawing() {
        if (this._eDrawing) {
            this.createSVGDomElements(this.drawingItemMap);
        } else {
            this.drawingsBuffered = true;
        }
    }

    setGroupingPositions() {
        for (const id of this.drawingItemMap.keys()) {
            const drawingItem = this.drawingItemMap.get(id);
            if (drawingItem.subDrawingItemMap.size > 0) {
                drawingItem.drawingItemData.position = this.getCentroidOfGrouping(drawingItem);
                this.drawingItemMap.set(id, drawingItem);
            }
        }
    }

    /**
     * Adjust the position of grouping children
     * @param {DrawingItem} drawingItem
     * @param {Position} currentCenter
     * @returns {DrawingItem}
     * @private
     */
    adjustChildrenPosition(drawingItem, currentCenter) {
        if (drawingItem.subDrawingItemMap.size > 0) {
            for (const [id, childDrawingItem] of drawingItem.subDrawingItemMap.entries()) {
                const childCurrentCenter = this.cloneObject(childDrawingItem.drawingItemData.position);

                const diffX = childDrawingItem.drawingItemData.position.x - currentCenter.x;
                const diffY = childDrawingItem.drawingItemData.position.y - currentCenter.y;

                childDrawingItem.drawingItemData.position.x = drawingItem.drawingItemData.position.x + diffX;
                childDrawingItem.drawingItemData.position.y = drawingItem.drawingItemData.position.y + diffY;

                if (childDrawingItem.drawingItemData.shape !== undefined) {
                    switch (childDrawingItem.drawingItemData.shape.type) {
                        case "rectangle":
                        case "rounded-rectangle":
                        case "image": {
                            const diffTLX = childDrawingItem.drawingItemData.shape.data.topLeft.x - currentCenter.x;
                            const diffTLY = childDrawingItem.drawingItemData.shape.data.topLeft.y - currentCenter.y;
                            const diffBRX = childDrawingItem.drawingItemData.shape.data.bottomRight.x - currentCenter.x;
                            const diffBRY = childDrawingItem.drawingItemData.shape.data.bottomRight.y - currentCenter.y;

                            childDrawingItem.drawingItemData.shape.data.topLeft.x = drawingItem.drawingItemData.position.x + diffTLX;
                            childDrawingItem.drawingItemData.shape.data.topLeft.y = drawingItem.drawingItemData.position.y + diffTLY;
                            childDrawingItem.drawingItemData.shape.data.bottomRight.x = drawingItem.drawingItemData.position.x + diffBRX;
                            childDrawingItem.drawingItemData.shape.data.bottomRight.y = drawingItem.drawingItemData.position.y + diffBRY;
                            break;
                        }
                        case "path": {
                            for (const subPoint of childDrawingItem.drawingItemData.shape.data.subPoints) {
                                const diffPosX = subPoint.position.x - currentCenter.x;
                                const diffPosY = subPoint.position.y - currentCenter.y;

                                subPoint.position.x = drawingItem.drawingItemData.position.x + diffPosX;
                                subPoint.position.y = drawingItem.drawingItemData.position.y + diffPosY;

                                if (subPoint.position2) {
                                    const diffPos2X = subPoint.position2.x - currentCenter.x;
                                    const diffPos2Y = subPoint.position2.y - currentCenter.y;

                                    subPoint.position2.x = drawingItem.drawingItemData.position.x + diffPos2X;
                                    subPoint.position2.y = drawingItem.drawingItemData.position.y + diffPos2Y;
                                }
                            }
                            break;
                        }
                    }
                }

                this.adjustChildrenPosition(childDrawingItem, childCurrentCenter);

                drawingItem.subDrawingItemMap.set(id, childDrawingItem);
            }
        }
    }

    /**
     * Collect all instructions
     * @param {RawInstruction[]} instructions Raw Instructions
     * @param {Map<string, DrawingItem>} drawingItemMap The Drawing Item Map
     * @private
     */
    collectInstructions(instructions, drawingItemMap) {
        let untrackedIdIndex = 0;

        for (let i = 0; i < instructions.length; i++) {
            const instr = instructions[i];

            /** @type {DrawingItem|null} */
            let drawingItem = {
                subDrawingItemMap: new Map(),
                hasEntered: false,
                hasLeft: true
            };

            // Add ! prefix to empty id to indicate special behaviour
            if (instr.sId === "") {
                if (instr.sType.startsWith("create-")) {
                    untrackedIdIndex++;
                }

                instr.sId = `!${untrackedIdIndex}`;
            }

            if (drawingItemMap.has(instr.sId)) {
                drawingItem = drawingItemMap.get(instr.sId);
            } else {
                drawingItemMap.forEach(element => {

                    if (element.subDrawingItemMap.size > 0) {

                        if (element.subDrawingItemMap.has(instr.sId)) {
                            drawingItem = element.subDrawingItemMap.get(instr.sId);
                        }

                    }

                });
            }

            if (instr.sType === "create-group") {
                const startSubInstructionIndex = instructions.findIndex(i => i.sType === "create-group" && i.sId === instr.sId);
                const endSubInstructionIndex = instructions.findIndex(i => i.sType === "end-create-group" && i.sId === instr.sId);

                if (endSubInstructionIndex === -1) {
                    throw new df.Error(999, `Group "${instr.sId}" has no corresponding EndCreateGroup instruction.`);
                }

                const subInstructions = instructions.slice(startSubInstructionIndex + 1, endSubInstructionIndex);

                // Take style instructions that should apply to the entire group
                if (drawingItem.drawingItemData === undefined) {
                    drawingItem.drawingItemData = {
                        visible: true,
                        shadowOffset: { x: 0, y: 0 },
                        position: {x:0 , y:0}
                    };
                }

                const groupInstructions = subInstructions.filter(si => si.sId === instr.sId);
                for (const groupInstr of groupInstructions) {
                    drawingItem = this.applyGroupedInstruction(drawingItem, groupInstr);
                    const subInstrToRemove = subInstructions.findIndex(si => si.sId === groupInstr.sId && si.sType === groupInstr.sType);
                    subInstructions.splice(subInstrToRemove, 1);
                }

                drawingItem.subDrawingItemMap = this.collectInstructions(subInstructions, drawingItem.subDrawingItemMap);

                i = endSubInstructionIndex;
            }
            else if (instr.sType === "create-layer") {
                const startSubInstructionIndex = instructions.findIndex(i => i.sType === "create-layer" && i.sId === instr.sId);
                const endSubInstructionIndex = instructions.findIndex(i => i.sType === "end-create-layer" && i.sId === instr.sId);

                if (endSubInstructionIndex === -1) {
                    throw new df.Error(999, `Layer "${instr.sId}" has no corresponding EndCreateLayer instruction.`);
                }

                const subInstructions = instructions.slice(startSubInstructionIndex + 1, endSubInstructionIndex);

                // Take style instructions that should apply to the entire group
                if (drawingItem.drawingItemData === undefined) {
                    drawingItem.drawingItemData = {
                        visible: true,
                        shadowOffset: { x: 0, y: 0 }
                    };
                }

                drawingItem.subDrawingItemMap = this.collectInstructions(subInstructions, drawingItem.subDrawingItemMap);

                i = endSubInstructionIndex;
            }
            else if (instr.sType === "delete-item") {
                this.deleteItem(instr.sId);
                drawingItem = null;
            }
            else {
                if (drawingItem.subDrawingItemMap.size > 0) {
                    drawingItem = this.applyGroupedInstruction(drawingItem, instr);
                }
                else {
                    drawingItem = this.applyInstruction(drawingItem, instr);
                }

            }

            if (drawingItem) {
                drawingItemMap.set(instr.sId, drawingItem);
            }
        }

        return drawingItemMap;
    }

    /**
     * Apply raw instruction to the item map
     * @param {DrawingItem} drawingItem The drawing item data
     * @param {RawInstruction} instr The raw instruction
     * @returns {DrawingItem} Applied instructions
     * @private
     */
    applyInstruction(drawingItem, instr) {
        drawingItem.drawingItemData = this.applyCreateInstruction(drawingItem.drawingItemData, instr);

        if (drawingItem.drawingItemData === undefined) {
            throw new df.Error(999, `There is no shape created for "${instr.sId}", cannot apply styling. Maybe you mistyped the ID?`);
        }

        drawingItem = this.applyNormalInstructions(drawingItem, instr);

        return drawingItem;
    }

    /**
     * Apply instructions for groupings
     * @param {DrawingItem} drawingItem The drawing item data
     * @param {RawInstruction} instr The raw instruction
     * @returns {DrawingItem} Applied instructions
     * @private
     */
    applyGroupedInstruction(drawingItem, instr) {
        drawingItem = this.applyNormalInstructions(drawingItem, instr);

        return drawingItem;
    }

    /**
     * Create the data from the instructions
     * @param {DrawingItemData} drawingItemData The drawing item data
     * @param {RawInstruction} instr The raw instruction
     * @returns {DrawingItemData} The created data
     * @private
     */
    applyCreateInstruction(drawingItemData, instr) {
        const typeName = instr.sType;
        const params = instr.asParams;

        if (typeName.startsWith("create-") && this.mapHasId(instr.sId)) {
            throw new df.Error(999, `A shape with the id "${instr.sId}" already exists`);
        }

        // Set some default values
        if (drawingItemData === undefined) {
            drawingItemData = {};
            drawingItemData.position = { x: 0, y: 0 };
            drawingItemData.scale = { width: 1, height: 1 };
            drawingItemData.shadowOffset = { x: 0, y: 0 };
            drawingItemData.visible = true;
            drawingItemData.closed = false;
        }

        // Create shapes

        switch (typeName) {
            case "create-rectangle": {
                const [posX, posY, width, height, radius] = params;

                drawingItemData.shape = {};
                drawingItemData.shape.data = {
                    topLeft: { x: parseFloat(posX), y: parseFloat(posY) },
                    bottomRight: { x: parseFloat(posX) + parseFloat(width), y: parseFloat(posY) + parseFloat(height) }
                };

                if (params.length > 4) {
                    drawingItemData.shape.type = "rounded-rectangle";
                    drawingItemData.shape.data.radius = parseFloat(radius);
                }
                else {
                    drawingItemData.shape.type = "rectangle";
                }

                // Set position to center of rectangle
                drawingItemData.position = this.getCentroid([drawingItemData.shape.data.topLeft, drawingItemData.shape.data.bottomRight]);
                break;
            }
            case "create-circle": {
                const [posX, posY, radius] = params;

                drawingItemData.shape = {};
                drawingItemData.shape.type = "circle";
                drawingItemData.shape.data = {
                    radius: parseFloat(radius)
                };

                // Set position to center of circle
                drawingItemData.position.x = parseFloat(posX);
                drawingItemData.position.y = parseFloat(posY);
                break;
            }
            case "create-ellipse": {
                const [posX, posY, radiusX, radiusY] = params;

                drawingItemData.shape = {};
                drawingItemData.shape.type = "ellipse";
                drawingItemData.shape.data = {
                    radiusX: parseFloat(radiusX),
                    radiusY: parseFloat(radiusY)
                };
                // Set position to center of ellipse
                drawingItemData.position.x = parseFloat(posX);
                drawingItemData.position.y = parseFloat(posY);
                break;
            }
            case "create-path":
                drawingItemData.shape = {};
                drawingItemData.shape.type = "path";
                drawingItemData.shape.data = {
                    subPoints: []
                };
                break;
            case "create-line": {
                const [pos1X, pos1Y, pos2X, pos2Y] = params;

                drawingItemData.shape = {};
                drawingItemData.shape.type = "path";
                drawingItemData.shape.data = {
                    subPoints: []
                };

                drawingItemData.shape.data.subPoints.push({
                    type: "moveTo",
                    position: { x: parseFloat(pos1X), y: parseFloat(pos1Y) }
                });
                drawingItemData.shape.data.subPoints.push({
                    type: "lineTo",
                    position: { x: parseFloat(pos2X), y: parseFloat(pos2Y) }
                });
                break;
            }
            case "create-text": {
                const [posX, posY, content, fontFamily, fontSize, justification, fontWeight, textDecoration] = params;

                drawingItemData.shape = {};
                drawingItemData.shape.type = "text";
                drawingItemData.shape.params = params;
                drawingItemData.textContent = content;
                drawingItemData.position.x = parseFloat(posX);
                drawingItemData.position.y = parseFloat(posY);
                drawingItemData.fontFamily = fontFamily;
                drawingItemData.fontSize = parseFloat(fontSize);
                drawingItemData.fillColor = "black";
                drawingItemData.strokeColor = "transparent";
                if (params.length > 5) drawingItemData.justification = this.enumJustificationIntToString(parseInt(justification));
                if (params.length > 6) drawingItemData.fontWeight = fontWeight;
                if (params.length > 7) drawingItemData.textDecoration = textDecoration;
                break;
            }
            case "create-image":
            case "create-svg": {
                const [path] = params;
                drawingItemData.shape = this.getImageShapeData(params);
                drawingItemData.imagePath = path;
                break;
            }
        }

        return drawingItemData;
    }

    /**
     * Get the shape data for an image or SVG
     * @param {string[]} params
     * @return {Shape} The image rectangle data
     */
    getImageShapeData(params) {
        const [_, left, top, right, bottom] = params;

        /** @type {Shape} */
        const shape = {
            type: "image"
        };

        if (params.length > 3) {
            shape.data = {
                topLeft: { x: parseFloat(left), y: parseFloat(top) },
                bottomRight: { x: parseFloat(right), y: parseFloat(bottom) }
            };
        }
        else {
            shape.data = {
                topLeft: { x: parseFloat(left), y: parseFloat(top) },
            };
        }

        return shape;
    }

    /**
     * Do processing for regular instruction types
     * @param {DrawingItem} drawingItem The drawing item data
     * @param {RawInstruction} instr The raw instruction
     * @returns {DrawingItem} The processed instruction
     * @private
     */
    applyNormalInstructions(drawingItem, instr) {
        const typeName = instr.sType;
        const params = instr.asParams;

        switch (typeName) {
            // Draw
            case "add":
                drawingItem.drawingItemData.shape.data.subPoints.push({
                    type: "add",
                    position: { x: parseFloat(params[0]), y: parseFloat(params[1]) }
                });
                drawingItem.drawingItemData.position = this.getCentroid(drawingItem.drawingItemData.shape.data.subPoints.map(sp => sp.position));
                break;
            case "moveTo":
                drawingItem.drawingItemData.shape.data.subPoints.push({
                    type: "moveTo",
                    position: { x: parseFloat(params[0]), y: parseFloat(params[1]) }
                });
                drawingItem.drawingItemData.position = this.getCentroid(drawingItem.drawingItemData.shape.data.subPoints.map(sp => sp.position));
                break;
            case "lineTo":
                drawingItem.drawingItemData.shape.data.subPoints.push({
                    type: "lineTo",
                    position: { x: parseFloat(params[0]), y: parseFloat(params[1]) }
                });
                drawingItem.drawingItemData.position = this.getCentroid(drawingItem.drawingItemData.shape.data.subPoints.map(sp => sp.position));
                break;
            case "quadraticCurveTo":
                drawingItem.drawingItemData.shape.data.subPoints.push({
                    type: "quadraticCurveTo",
                    position: { x: parseFloat(params[2]), y: parseFloat(params[3]) },
                    position2: { x: parseFloat(params[0]), y: parseFloat(params[1]) }
                });
                drawingItem.drawingItemData.position = this.getCentroid(drawingItem.drawingItemData.shape.data.subPoints.map(sp => sp.position));
                break;
            case "closePath":
                drawingItem.drawingItemData.shape.data.subPoints.push({
                    type: "closePath"
                });
                drawingItem.drawingItemData.closed = true;
                break;
            // Stroke style
            case "strokeWidth":
                drawingItem.drawingItemData.strokeWidth = parseFloat(params[0]);
                break;
            case "strokeColor":
                drawingItem.drawingItemData.strokeColor = params[0];
                break;
            case "strokeCap":
                drawingItem.drawingItemData.strokeCap = this.enumStrokeCapIntToString(parseInt(params[0]));
                break;
            case "strokeJoin":
                drawingItem.drawingItemData.strokeJoin = this.enumStrokeJoinIntToString(parseInt(params[0]));
                break;
            case "dashOffset":
                drawingItem.drawingItemData.dashOffset = parseFloat(params[0]);
                break;
            case "strokeDashes":
                drawingItem.drawingItemData.strokeDistance = params[0];

                if (params.length > 1) {
                    drawingItem.drawingItemData.whitespaceDistance = params[1];
                }
                break;
            // Fill style
            case "fillColor":
                drawingItem.drawingItemData.fillColor = params[0];
                break;
            // Shadow style
            case "shadowColor":
                drawingItem.drawingItemData.shadowColor = params[0];
                break;
            case "shadowBlur":
                drawingItem.drawingItemData.shadowBlur = parseFloat(params[0]);
                break;
            case "shadowOffset":
                drawingItem.drawingItemData.shadowOffset = { x: parseFloat(params[0]), y: parseFloat(params[1]) };
                break;
            // Font style
            case "fontFamily":
                drawingItem.drawingItemData.fontFamily = params[0];
                break;
            case "fontSize":
                drawingItem.drawingItemData.fontSize = parseFloat(params[0]);
                break;
            case "fontWeight":
                drawingItem.drawingItemData.fontWeight = params[0];
                break;
            case "textDecoration":
                drawingItem.drawingItemData.textDecoration = params[0];
                break;
            case "fontJustification":
                drawingItem.drawingItemData.justification = this.enumJustificationIntToString(parseInt(params[0]));
                break;
            case "textContent":
                drawingItem.drawingItemData.textContent = params[0];
                break;
            // Visibility style
            case "set-visibility":
                drawingItem.drawingItemData.visible = (params[0] == true);
                break;
            case "toggle-visibility":
                drawingItem.drawingItemData.visible = !drawingItem.drawingItemData.visible;
                break;
            case "add-svg-attribute":
                drawingItem.drawingItemData.customAttribute = {customAttributeName: params[0], customAttributeValue: params[1]}
                break;
            // Transform
            case "position": {
                let currentPos;

                drawingItem.drawingItemData.position.x = parseFloat(params[0]);
                drawingItem.drawingItemData.position.y = parseFloat(params[1]);

                if (drawingItem.drawingItemData.position !== undefined) {
                    currentPos = this.cloneObject(drawingItem.drawingItemData.position)
                    this.adjustChildrenPosition(drawingItem, currentPos);
                }
                break;
            }
            case "rotation":
                drawingItem.drawingItemData.rotation = parseFloat(params[0]);
                if (params.length > 1) {
                    drawingItem.drawingItemData.rotateInPlace = params[1];
                }
                break;
            case "scaling":
                if (drawingItem.drawingItemData.scale === undefined) drawingItem.drawingItemData.scale = {};
                drawingItem.drawingItemData.scale.width = parseFloat(params[0]);
                drawingItem.drawingItemData.scale.height = parseFloat(params[1]);
                break;
            case "enable-interaction": {
                // Set value to 0 if undefined
                if (drawingItem.enabledInteractions === undefined) drawingItem.enabledInteractions = 0;

                const flags = parseInt(params[0]);
                drawingItem.enabledInteractions = drawingItem.enabledInteractions | flags;
                break;
            }
            case "disable-interaction": {
                // Set value to 0 if undefined
                if (drawingItem.enabledInteractions === undefined) drawingItem.enabledInteractions = 0;
                const flags = parseInt(params[0]);

                // Only disable if the flag was actually set to prevent bitwise operation issues
                if (drawingItem.enabledInteractions & flags) {
                    drawingItem.enabledInteractions = drawingItem.enabledInteractions ^ flags;
                }

                break;
            }
            case "add-tooltip":
                drawingItem.drawingItemData.tooltip = params[0];
                break;
        }

        return drawingItem;
    }

    /**
     * Get the centroid of groupings
     * @param {DrawingItem} drawingItem
     * @returns {Position}
     */
    getCentroidOfGrouping(drawingItem) {
        /** @type {Position[]} */
        const positions = [];

        for (const subDrawingItem of drawingItem.subDrawingItemMap.values()) {
            // Is grouping
            if (subDrawingItem.subDrawingItemMap.size > 0) {
                subDrawingItem.drawingItemData.position = this.getCentroidOfGrouping(subDrawingItem);
            }

            positions.push(subDrawingItem.drawingItemData.position);
        }

        return this.getCentroid(positions);
    }

    // Draw instructions

    /**
     * Draw all drawing items in a map
     * @param {Map<string, DrawingItem>} drawingItemMap A map with drawing items
     * @private
     */
    createSVGDomElements(drawingItemMap) {
        for (const [id, drawingItem] of drawingItemMap) {
            this.createSVGDomElement(id, drawingItem);

            if (drawingItem.drawingItemData.pathItem !== undefined) {
                const existingElement = this._eDrawing.querySelector(`[df-wd-item-id="${id}"]`);

                // Only update DOM when something has actually changed, otherwise create a new element
                if (existingElement === null) {
                    this._eDrawing.appendChild(drawingItem.drawingItemData.pathItem);
                }
                else if (!existingElement.isEqualNode(drawingItem.drawingItemData.pathItem)) {
                    existingElement.replaceWith(drawingItem.drawingItemData.pathItem);
                }
            }
        }
    }

    /**
     * Draw a drawing instruction
     * @param {string} id
     * @param {DrawingItem} drawingItem The data
     * @private
     */
    createSVGDomElement(id, drawingItem) {
        if (drawingItem.subDrawingItemMap.size > 0) {
            drawingItem.drawingItemData.pathItem = document.createElementNS(this.ns, "g");
            drawingItem.drawingItemData.pathItem.setAttributeNS(null, "style", "pointer-events: bounding-box; transform-origin: center; transform-box: fill-box;");

            for (const [childId, childDrawingItem] of drawingItem.subDrawingItemMap.entries()) {
                this.createSVGDomElement(childId, childDrawingItem);
                this.applyStylesForGroupChildren(childDrawingItem, drawingItem.drawingItemData); // Apply styles from group
                drawingItem.drawingItemData.pathItem.setAttribute("df-wd-item-id", id);
                this.applyTransformStyles(drawingItem.drawingItemData);

                const existingElement = drawingItem.drawingItemData.pathItem.querySelector(`:scope > *[df-wd-item-id="${id}"]`);

                // Only update DOM when something has actually changed, otherwise create a new element
                if (existingElement === null) {
                    drawingItem.drawingItemData.pathItem.appendChild(childDrawingItem.drawingItemData.pathItem);
                }
                else if (!existingElement.isEqualNode(drawingItem.drawingItemData.pathItem)) {
                    existingElement.replaceWith(childDrawingItem.drawingItemData.pathItem);
                }

            }


            this.assignEvent(id, drawingItem);
        }
        else {
            if (drawingItem.drawingItemData.shape === undefined || drawingItem.drawingItemData.shape.type === "") return; // Ignore non-existent shape

            this.createSVGData(id, drawingItem.drawingItemData);
            this.applyStyles(drawingItem.drawingItemData);
            this.applyTransformStyles(drawingItem.drawingItemData);
            this.assignEvent(id, drawingItem);
        }
    }

    /**
     * Apply the Path 2D Data
     * @param {string} id The ID
     * @param {DrawingItemData} drawingItemData The drawing item data
     * @private
     */
    createSVGData(id, drawingItemData) {
        // Apply Path2D data
        switch (drawingItemData.shape.type) {
            case "rectangle": {
                drawingItemData.pathItem = document.createElementNS(this.ns, "rect");
                drawingItemData.pathItem.setAttributeNS(null, "x", drawingItemData.shape.data.topLeft.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "y", drawingItemData.shape.data.topLeft.y.toString());
                drawingItemData.pathItem.setAttributeNS(null, "width",
                    (drawingItemData.shape.data.bottomRight.x - drawingItemData.shape.data.topLeft.x).toString()
                );
                drawingItemData.pathItem.setAttributeNS(null, "height",
                    (drawingItemData.shape.data.bottomRight.y - drawingItemData.shape.data.topLeft.y).toString()
                );
                break;
            }
            case "rounded-rectangle":
                drawingItemData.pathItem = document.createElementNS(this.ns, "rect");
                drawingItemData.pathItem.setAttributeNS(null, "x", drawingItemData.shape.data.topLeft.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "y", drawingItemData.shape.data.topLeft.y.toString());
                drawingItemData.pathItem.setAttributeNS(null, "width",
                    (drawingItemData.shape.data.bottomRight.x - drawingItemData.shape.data.topLeft.x).toString()
                );
                drawingItemData.pathItem.setAttributeNS(null, "height",
                    (drawingItemData.shape.data.bottomRight.y - drawingItemData.shape.data.topLeft.y).toString()
                );
                drawingItemData.pathItem.setAttributeNS(null, "rx", drawingItemData.shape.data.radius.toString());
                drawingItemData.pathItem.setAttributeNS(null, "ry", drawingItemData.shape.data.radius.toString());
                break;
            case "circle":
                drawingItemData.pathItem = document.createElementNS(this.ns, "circle");
                drawingItemData.pathItem.setAttributeNS(null, "cx", drawingItemData.position.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "cy", drawingItemData.position.y.toString());
                drawingItemData.pathItem.setAttributeNS(null, "r", drawingItemData.shape.data.radius.toString());
                break;
            case "ellipse":
                drawingItemData.pathItem = document.createElementNS(this.ns, "ellipse");
                drawingItemData.pathItem.setAttributeNS(null, "cx", drawingItemData.position.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "cy", drawingItemData.position.y.toString());
                drawingItemData.pathItem.setAttributeNS(null, "rx", drawingItemData.shape.data.radiusX.toString());
                drawingItemData.pathItem.setAttributeNS(null, "ry", drawingItemData.shape.data.radiusY.toString());
                break;
            case "path": {
                /** @type {string[]} */
                const pathCommands = [];
                drawingItemData.pathItem = document.createElementNS(this.ns, "path");

                for (let i = 0; i < drawingItemData.shape.data.subPoints.length; i++) {
                    const subPoint = drawingItemData.shape.data.subPoints[i];

                    switch (subPoint.type) {
                        case "add":
                        case "lineTo": {
                            if (i === 0) pathCommands.push(`M ${subPoint.position.x},${subPoint.position.y}`);
                            else pathCommands.push(`L ${subPoint.position.x},${subPoint.position.y}`);

                            break;
                        }
                        case "moveTo": {
                            pathCommands.push(`M ${subPoint.position.x},${subPoint.position.y}`);
                            break;
                        }
                        case "quadraticCurveTo": {
                            pathCommands.push(`Q ${subPoint.position2.x},${subPoint.position2.y} ${subPoint.position.x},${subPoint.position.y}`);
                            break;
                        }
                        case "closePath":
                            pathCommands.push("Z");
                            break;
                    }
                }

                drawingItemData.pathItem.setAttributeNS(null, "d", pathCommands.join(" "));
                break;
            }
            case "text": {
                drawingItemData.pathItem = document.createElementNS(this.ns, "text");
                drawingItemData.pathItem.setAttributeNS(null, "x", drawingItemData.position.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "y", drawingItemData.position.y.toString());
                drawingItemData.pathItem.setAttributeNS(null, "font-family", drawingItemData.fontFamily);
                drawingItemData.pathItem.setAttributeNS(null, "font-size", drawingItemData.fontSize.toString());
                drawingItemData.pathItem.setAttributeNS(null, "text-anchor", drawingItemData.justification);
                drawingItemData.pathItem.setAttributeNS(null, "font-weight", drawingItemData.fontWeight);
                drawingItemData.pathItem.setAttributeNS(null, "text-decoration", drawingItemData.textDecoration);
                drawingItemData.pathItem.setAttributeNS(null, "stroke", drawingItemData.strokeColor);
                drawingItemData.pathItem.setAttributeNS(null, "fill", drawingItemData.fillColor);
                drawingItemData.pathItem.textContent = drawingItemData.textContent;
                break;
            }
            case "image": {
                drawingItemData.pathItem = document.createElementNS(this.ns, "image");
                drawingItemData.pathItem.setAttributeNS(null, "x", drawingItemData.shape.data.topLeft.x.toString());
                drawingItemData.pathItem.setAttributeNS(null, "y", drawingItemData.shape.data.topLeft.y.toString());
                if (drawingItemData.shape.data.bottomRight !== undefined) {
                    drawingItemData.pathItem.setAttributeNS(null, "width",
                        (drawingItemData.shape.data.bottomRight.x - drawingItemData.shape.data.topLeft.x).toString()
                    );
                    drawingItemData.pathItem.setAttributeNS(null, "height",
                        (drawingItemData.shape.data.bottomRight.y - drawingItemData.shape.data.topLeft.y).toString()
                    );
                }
                drawingItemData.pathItem.setAttributeNS(null, "href", drawingItemData.imagePath);
                drawingItemData.pathItem.setAttributeNS(null, "onmousedown", "return false");
                break;
            }
        }

        drawingItemData.pathItem.setAttribute("df-wd-item-id", id);
    }

    /**
     * Apply styles for children of group
     * @param {DrawingItem} drawingItem The drawing item
     * @param {DrawingItemData} parentDrawingItemData The parent drawing item
     * @private
     */
    applyStylesForGroupChildren(drawingItem, parentDrawingItemData) {
        if (drawingItem.subDrawingItemMap.size > 0) {
            for (const childDrawingItem of drawingItem.subDrawingItemMap.values()) {
                this.applyStylesForGroupChildren(childDrawingItem, parentDrawingItemData);
            }
        }

        // Stroke style
        if (drawingItem.drawingItemData.strokeWidth === undefined && parentDrawingItemData.strokeWidth !== undefined) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke-width", parentDrawingItemData.strokeWidth.toString());
        if (drawingItem.drawingItemData.strokeColor === undefined && parentDrawingItemData.strokeColor !== undefined) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke", parentDrawingItemData.strokeColor);
        if (drawingItem.drawingItemData.strokeCap === undefined && parentDrawingItemData.strokeCap !== undefined) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke-linecap", parentDrawingItemData.strokeCap);
        if (drawingItem.drawingItemData.strokeJoin === undefined && parentDrawingItemData.strokeJoin !== undefined) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke-linejoin", parentDrawingItemData.strokeJoin);
        //Stroke dashes
        const dashList = [];
        if (drawingItem.drawingItemData.strokeDistance === undefined && parentDrawingItemData.strokeDistance !== undefined) dashList.push(parentDrawingItemData.strokeDistance);
        if (drawingItem.drawingItemData.whitespaceDistance === undefined && parentDrawingItemData.whitespaceDistance !== undefined) dashList.push(parentDrawingItemData.whitespaceDistance);
        if (dashList.length > 0) {
            drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke-dasharray", dashList.join());
        }
        if (drawingItem.drawingItemData.dashOffset === undefined && parentDrawingItemData.dashOffset !== undefined) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "stroke-dashoffset", parentDrawingItemData.dashOffset);

        // Fill style
        // Special case for path, don't fill path unless it's closed
        if (drawingItem.drawingItemData.shape?.type === "path" && drawingItem.drawingItemData.fillColor === undefined && drawingItem.drawingItemData.closed === false) {
            drawingItem.drawingItemData.pathItem.setAttributeNS(null, "fill", "none");
        }

        if (drawingItem.drawingItemData.fillColor === undefined && parentDrawingItemData.fillColor !== undefined) {
            drawingItem.drawingItemData.pathItem.setAttributeNS(null, "fill", parentDrawingItemData.fillColor);
        }

        // Shadow style
        const shadowList = [];
        if (drawingItem.drawingItemData.shadowOffset.x === 0 && drawingItem.drawingItemData.shadowOffset.y === 0 && parentDrawingItemData.shadowOffset.x !== 0 && parentDrawingItemData.shadowOffset.y !== 0) {
            shadowList.push(`${parentDrawingItemData.shadowOffset.x}px ${parentDrawingItemData.shadowOffset.y}px`);
        } else shadowList.push("0px 0px");
        if (drawingItem.drawingItemData.shadowBlur === undefined && parentDrawingItemData.shadowBlur !== undefined) shadowList.push(`${parentDrawingItemData.shadowBlur}px`);
        if (drawingItem.drawingItemData.shadowColor === undefined && parentDrawingItemData.shadowColor !== undefined) shadowList.push(parentDrawingItemData.shadowColor);
        if (shadowList.length > 1) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "style", `filter: drop-shadow(${shadowList.join(" ")});`);

        // Visibility
        if (parentDrawingItemData.visible === false) drawingItem.drawingItemData.pathItem.setAttributeNS(null, "visibility", "hidden");
        else drawingItem.drawingItemData.pathItem.setAttributeNS(null, "visibility", "");

        //Custom attributes
        if (drawingItem.drawingItemData.customAttribute === undefined && parentDrawingItemData.customAttribute !== undefined) {
            drawingItem.drawingItemData.pathItem.setAttributeNS(null, parentDrawingItemData.customAttribute.customAttributeName, parentDrawingItemData.customAttribute.customAttributeValue);
        };

        // Tooltip
        if (drawingItem.drawingItemData.tooltip === undefined && parentDrawingItemData.tooltip !== undefined) {
            let titleElement = document.createElementNS(this.ns, "title");
            titleElement.textContent = parentDrawingItemData.tooltip;
            drawingItem.drawingItemData.pathItem.append(titleElement);
        }
    }

    /**
     * Apply styles
     * @param {DrawingItemData} drawingItemData The drawing item data
     * @private
     */
    applyStyles(drawingItemData) {
        // Stroke style
        if (drawingItemData.strokeWidth !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-width", drawingItemData.strokeWidth.toString());
        if (drawingItemData.strokeColor !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke", drawingItemData.strokeColor);
        else drawingItemData.pathItem.setAttributeNS(null, "stroke", "black");
        if (drawingItemData.strokeCap !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-linecap", drawingItemData.strokeCap);
        if (drawingItemData.strokeJoin !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-linejoin", drawingItemData.strokeJoin);

        //Stroke dashes
        if (drawingItemData.strokeDistance !== undefined && drawingItemData.whitespaceDistance === undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-dasharray", drawingItemData.strokeDistance);
        if (drawingItemData.strokeDistance !== undefined && drawingItemData.whitespaceDistance !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-dasharray", drawingItemData.strokeDistance + "," + drawingItemData.whitespaceDistance);
        if (drawingItemData.dashOffset !== undefined) drawingItemData.pathItem.setAttributeNS(null, "stroke-dashoffset", drawingItemData.dashOffset);

        // Fill style
        // Special case for path, don't fill path unless it's closed
        if (drawingItemData.shape?.type === "path" && drawingItemData.fillColor === undefined && drawingItemData.closed === false) {
            drawingItemData.pathItem.setAttributeNS(null, "fill", "none");
        }

        if (drawingItemData.fillColor !== undefined) {
            drawingItemData.pathItem.setAttributeNS(null, "fill", drawingItemData.fillColor);
        } else {
            drawingItemData.pathItem.setAttributeNS(null, "fill", "transparent");
        }

        // Shadow style
        const shadowList = [];
        if (drawingItemData.shadowOffset.x !== 0 && drawingItemData.shadowOffset.y !== 0) {
            shadowList.push(`${drawingItemData.shadowOffset.x}px ${drawingItemData.shadowOffset.y}px`);
        } else {
            shadowList.push("0px 0px");
        }
        if (drawingItemData.shadowBlur) shadowList.push(`${drawingItemData.shadowBlur}px`);
        if (drawingItemData.shadowColor) shadowList.push(drawingItemData.shadowColor);
        if (shadowList.length > 1) drawingItemData.pathItem.setAttributeNS(null, "style", `filter: drop-shadow(${shadowList.join(" ")});`);

        //Visibility
        if (drawingItemData.visible === true) drawingItemData.pathItem.setAttributeNS(null, "visibility", "");
        else drawingItemData.pathItem.setAttributeNS(null, "visibility", "hidden");

        //Custom attributes
        if (drawingItemData.customAttribute !== undefined) drawingItemData.pathItem.setAttributeNS(null, drawingItemData.customAttribute.customAttributeName, drawingItemData.customAttribute.customAttributeValue);

        //Tooltip
        if (drawingItemData.tooltip !== undefined) {
            let titleElement = document.createElementNS(this.ns, "title");
            titleElement.textContent = drawingItemData.tooltip;
            drawingItemData.pathItem.append(titleElement);
        }
    }

    /**
     * Apply transform styles
     * @param {DrawingItemData} drawingItemData The drawing item data
     * @private
     */
    applyTransformStyles(drawingItemData) {
        // Transform
        let transformList = [];
        if (drawingItemData.rotation !== undefined) transformList.push(`rotate(${drawingItemData.rotation})`);
        if (drawingItemData.rotateInPlace !== undefined) drawingItemData.pathItem.setAttributeNS(null, "transform-origin", drawingItemData.position.x + " " + drawingItemData.position.y);
        if (drawingItemData.scale !== undefined) {
            if (drawingItemData.scale?.width !== 1 && drawingItemData.scale?.height !== 1) transformList.push(`scale(${drawingItemData.scale.width}, ${drawingItemData.scale.height})`);
        }
        if (transformList.length > 0) drawingItemData.pathItem.setAttributeNS(null, "transform", transformList.join(" "));
    }

    // Event Handling

    /**
     * Assign events to the drawing
     * @param {string} id
     * @param {DrawingItem} drawingItem
     * @private
     */
    assignEvent(id, drawingItem) {
        if (id.startsWith("!")) return; // Ignore exclamation IDs

        const element = drawingItem.drawingItemData.pathItem;

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseClick) {
            element.addEventListener("click", (event) => {
                this.handleEvent("HandleMouseClick", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseDoubleClick) {
            element.addEventListener("dblclick", (event) => {
                this.handleEvent("HandleMouseDoubleClick", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseUp) {
            element.addEventListener("mouseup", (event) => {
                this.handleEvent("HandleMouseUp", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseDown) {
            element.addEventListener("mousedown", (event) => {
                event.preventDefault();
                this.handleEvent("HandleMouseDown", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseMove) {
            element.addEventListener("mousemove", (event) => {
                this.handleEvent("HandleMouseMove", event, id, drawingItem);

                if (event.buttons !== 0) {
                    this.handleEvent("HandleMouseDrag", event, id, drawingItem);
                }
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseDrag) {
            element.addEventListener("mousemove", (event) => {
                if (event.buttons !== 0) {
                    this.handleEvent("HandleMouseDrag", event, id, drawingItem);
                }
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseEnter) {
            element.addEventListener("mouseenter", (event) => {
                this.handleEvent("HandleMouseEnter", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseLeave) {
            element.addEventListener("mouseleave", (event) => {
                this.handleEvent("HandleMouseLeave", event, id, drawingItem);
            });
        }

        // Touchscreen events
        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseUp) {
            element.addEventListener("touchend", (event) => {
                this.handleEvent("HandleMouseUp", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseClick) {
            element.addEventListener("touchstart", (event) => {
                event.preventDefault();
                this.handleEvent("HandleMouseClick", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseDown) {
            element.addEventListener("touchstart", (event) => {
                event.preventDefault();
                this.handleEvent("HandleMouseDown", event, id, drawingItem);
            });
        }

        if (drawingItem.enabledInteractions & this.wdInteractionOnMouseMove) {
            element.addEventListener("touchmove", (event) => {
                this.handleEvent("HandleMouseMove", event, id, drawingItem);
            });
        }
    }

    /**
     * Handle an event and send it to the server
     * @param {string} eventName
     * @param {MouseEvent} event
     * @param {string} id
     * @param {DrawingItem} drawingItem
     */
    handleEvent(eventName, event, id, drawingItem) {
        const dataToSend = this.createEventData(drawingItem.drawingItemData, event);
        this.serverAction("ReceiveEventData", [eventName, id], dataToSend, null);
    }

    /**
     * Create a value tree of the event data and the drawing item
     * @param {DrawingItemData} drawingItemData The item data
     * @param {MouseEvent | TouchEvent} e The event data
     * @return Value tree of the event data
     * @private
     */
    createEventData(drawingItemData, e) {
        const data = {};

        data.eMouseButtons = 0;
        data.tMousePosition = { fX: 0, fY: 0 };

        if (e.touches !== undefined && e.touches.length > 0) {
            let tempXandY;
            tempXandY = this.getTouchPos(e);
            data.tMousePosition.fX = tempXandY.x;
            data.tMousePosition.fY = tempXandY.y;
        }
        else if (e.buttons !== undefined) {
            let tempXandY;
            data.eMouseButtons = e.buttons;
            tempXandY = this.getMousePos(e);
            data.tMousePosition.fX = tempXandY.x;
            data.tMousePosition.fY = tempXandY.y;
        }

        // Positioning
        data.tPosition = {};
        data.tPosition.fX = drawingItemData.position?.x ?? 0;
        data.tPosition.fY = drawingItemData.position?.y ?? 0;
        data.fRotation = drawingItemData.rotation ?? 0;
        data.tScaling = {};
        data.tScaling.fWidth = drawingItemData.scale?.width ?? 1;
        data.tScaling.fHeight = drawingItemData.scale?.height ?? 1;

        // Stroke style
        data.sStrokeColor = drawingItemData.strokeColor ?? "transparent";
        data.fStrokeWidth = drawingItemData.strokeWidth ?? 0;
        data.iStrokeCap = this.enumStrokeCapStringToInt(drawingItemData.strokeCap);
        data.iStrokeJoin = this.enumStrokeJoinStringToInt(drawingItemData.strokeJoin);
        data.fDashOffset = drawingItemData.dashOffset ?? 0;

        // Fill style
        data.sFillColor = drawingItemData.fillColor ?? "transparent";

        // Shadow style
        data.sShadowColor = drawingItemData.shadowColor ?? "transparent";
        data.fShadowBlur = drawingItemData.shadowBlur ?? 0;
        data.tShadowOffset = {};
        data.tShadowOffset.fX = drawingItemData.shadowOffset?.x ?? 0;
        data.tShadowOffset.fY = drawingItemData.shadowOffset?.y ?? 0;

        // Font style
        data.sTextContent = drawingItemData.textContent ?? "";
        data.sFontFamily = drawingItemData.fontFamily ?? "sans-serif";
        data.fFontSize = drawingItemData.fontSize ?? 10;
        data.eJustification = this.enumJustificationStringToInt(drawingItemData.justification);
        data.sFontWeight = drawingItemData.fontWeight ?? "";
        data.sTextDecoration = drawingItemData.textDecoration ?? "";

        return data;
    }

    /**
     * Get the position of the mouse on the drawing
     * @param {MouseEvent} e The event data
     * @returns {Position}
     * @private
     */
    getMousePos(e) {
        const rect = this._eDrawing.getBoundingClientRect();

        return {
            x: e.clientX - rect.left,
            y: e.clientY - rect.top
        };
    }

    /**
     * Get the position of the finger on the drawing
     * @param {TouchEvent} e
     * @returns {Position}
     * @private
     */
    getTouchPos(e) {
        const rect = this._eDrawing.getBoundingClientRect();

        return {
            x: e.touches[0].clientX - rect.left,
            y: e.touches[0].clientY - rect.top
        };
    }

    // Helper functions

    /**
     * Get the centroid from a bunch of sub points
     * @param {Position[]} positions The sub points
     * @return {Position} The centroid of the points
     * @private
     */
    getCentroid(positions) {
        // Sum up X and Y coordinates
        const sumX = positions.map(p => p.x).reduce((previous, current) => previous + current);
        const sumY = positions.map(p => p.y).reduce((previous, current) => previous + current);

        // Calculate centroid
        /** @type {Position} */
        const position = {};
        position.x = sumX / positions.length;
        position.y = sumY / positions.length;

        return position;
    }

    /**
     * Delete an item from the drawing
     * @param {string} id The ID of the item
     * @private
     */
    deleteItem(id) {
        this.drawingItemMap = this.recursiveDeleteFromMap(id, this.drawingItemMap);
    }

    /**
     * Recursively delete items from the map
     * @param {string} idToRemove The ID to remove
     * @param {Map<string, DrawingItem>} drawingItemMap The drawing item map
     * @returns {Map<string, DrawingItem>} The new drawing item map
     * @private
     */
    recursiveDeleteFromMap(idToRemove, drawingItemMap) {
        /** @type {string[]} */
        const itemsToRemove = [];

        // Collect ids of items to remove
        for (const [id, drawingItem] of drawingItemMap.entries()) {
            if (drawingItem.subDrawingItemMap.size > 0) {
                drawingItem.subDrawingItemMap = this.recursiveDeleteFromMap(idToRemove, drawingItem.subDrawingItemMap);
            }

            if (id === idToRemove) {
                itemsToRemove.push(id);
                const existingElement = this._eDrawing.querySelector(`:scope > *[df-wd-item-id="${id}"]`);
                if (existingElement !== null) this._eDrawing.removeChild(existingElement);
            }
        }

        // Removes items from map
        for (const itemToRemove of itemsToRemove) {
            drawingItemMap.delete(itemToRemove);
        }

        return drawingItemMap;
    }

    /**
     * Clone a object
     * @param {Object} input
     * @returns {Object}
     */
    cloneObject(input) {
        return JSON.parse(JSON.stringify(input));
    }

    /**
     * Convert a blob to base64
     * @param blob The Data Blob
     * @returns {Promise<string>} The return data string as Base64
     */
    blobImageToBase64(blob) {
        return new Promise((resolve, _) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                const result = reader.result.replace("data:image/png;base64,", "");
                resolve(result);
            };

            reader.readAsDataURL(blob);
        });
    }

    /**
     * Check if the canvas map already has this id
     * @param {String} idToCheck The ID to check
     * @returns {boolean} True if the ID exists in the map
     * @private
     */
    mapHasId(idToCheck) {
        return this.checkMapChildren(idToCheck, this.drawingItemMap);
    }

    /**
     *
     * @param {string} idToCheck
     * @param {Map<string, DrawingItem>} drawingItemMap
     * @return {boolean} True if the ID exists in the map
     * @private
     */
    checkMapChildren(idToCheck, drawingItemMap) {
        for (const [id, drawingItem] of drawingItemMap.entries()) {
            if (id === idToCheck) {
                return true;
            }

            if (drawingItem.subDrawingItemMap.size > 0) {
                const result = this.checkMapChildren(idToCheck, drawingItem.subDrawingItemMap);

                if (result) {
                    return true;
                }
            }
        }

        return false;
    }

    // Export and Import

    async exportDrawingToImage() {
        // Clone svg element
        const svgCopy = this._eDrawing.cloneNode(true);

        // Convert image paths to data urls
        const svgImages = svgCopy.querySelectorAll("image");
        for (const svgImage of svgImages) {
            const response = await fetch(svgImage.href.baseVal);
            const imgBlob = await response.blob();
            const svgImageReader = new FileReader();
            svgImageReader.readAsDataURL(imgBlob);
            const result = await new Promise((resolve) => {
                svgImageReader.onloadend = () => {
                    resolve(svgImageReader.result);
                };
            });

            svgImage.setAttributeNS(null, "href", result);
        }

        const drawing = document.createElement("Canvas");
        drawing.width = svgCopy.width.baseVal.value;
        drawing.height = svgCopy.height.baseVal.value;
        const ctx = drawing.getContext("2d");
        const data = (new XMLSerializer()).serializeToString(svgCopy);
        const img = new Image();
        const svgBlob = new Blob([data], { type: 'image/svg+xml;charset=utf-8' });
        const svgDrawingReader = new FileReader();
        svgDrawingReader.readAsDataURL(svgBlob);
        img.src = await new Promise((resolve) => {
            svgDrawingReader.onloadend = () => {
                resolve(svgDrawingReader.result);
            };
        });

        img.addEventListener("load", () => {
            ctx.drawImage(img, 0, 0);
            let result = drawing.toDataURL("image/png").replace("data:image/png;base64,", "");
            this.serverAction("OnReceiveImage", [result]);
        });
    }

    exportDrawingDataToJSON() {
        const result = JSON.stringify(Object.fromEntries(this.drawingItemMap));
        this.serverAction("OnReceiveJSONExport", [result], null, null);
    }

    /**
     * Import JSON data from the server to the drawing
     * @param {string} jsonInput The JSON string data
     */
    importDrawingFromJSON(jsonInput) {
        this.drawingItemMap = Object.entries(JSON.parse(jsonInput));
        this.updateDrawing();
    }

    // Enum conversion

    /**
     * Convert stroke cap type string to stroke ID
     * @param {DrawingLineCap} input Stroke cap type
     * @returns {0 | 1 | 2} Stoke cap type ID
     * @private
     */
    enumStrokeCapStringToInt(input) {
        switch (input) {
            case "round":
                return 0;
            case "square":
                return 1;
            case "butt":
            default:
                return 2;
        }
    }

    /**
     * Convert stroke cap numeric ID to type string
     * @param {0 | 1 | 2} input Stroke cap type ID
     * @return {DrawingLineCap} Stroke cap type
     * @private
     */
    enumStrokeCapIntToString(input) {
        switch (input) {
            case 0:
                return "round";
            case 1:
                return "square";
            case 2:
            default:
                return "butt";
        }
    }

    /**
     * Convert stroke join type to numeric ID
     * @param {DrawingLineJoin} input Stroke join type
     * @returns {0 | 1 | 2} Stroke join type ID
     * @private
     */
    enumStrokeJoinStringToInt(input) {
        switch (input) {
            case "miter":
            default:
                return 0;
            case "round":
                return 1;
            case "bevel":
                return 2;
        }
    }

    /**
     * Convert stroke join numeric ID to type
     * @param {0 | 1 | 2} input Stroke join type ID
     * @return {DrawingLineJoin} Stroke join type
     * @private
     */
    enumStrokeJoinIntToString(input) {
        switch (input) {
            case 0:
            default:
                return "miter";
            case 1:
                return "round";
            case 2:
                return "bevel";
        }
    }

    /**
     * Convert justification type to numeric ID
     * @param {"start" | "middle" | "end"} input Justification type
     * @returns {0 | 1 | 2} Justification type ID
     * @private
     */
    enumJustificationStringToInt(input) {
        switch (input) {
            default:
            case "start":
                return 0;
            case "middle":
                return 1;
            case "end":
                return 2;
        }
    }

    /**
     * Convert stroke join numeric ID to type
     * @param {0 | 1 | 2} input Justification type ID
     * @returns {"start" | "middle" | "end"} Justification type
     * @private
     */
    enumJustificationIntToString(input) {
        switch (input) {
            default:
            case 0:
                return "start";
            case 1:
                return "middle";
            case 2:
                return "end";
        }
    }

    /**
     * 
     * @param {string} color The new background color for the canvas. Allows both color words such as "red" and hexcode.
     * @private
     */
    set_psCanvasBackgroundColor(color) {
        this._eDrawing.style.backgroundColor = color;
    }

    /*
    This method determines if the control is shown with a border. It does this by removing 
    or adding the "WebDrawing_Box" CSS class.
    
    @param  bVal    The new value.
    */
    set_pbShowBorder(bVal) {
        this.pbShowBorder = bVal
        if (this._eControl) {
            df.dom.toggleClass(this._eControl, "WebDrawing_Box", this.pbShowBorder);
        }
    }
}