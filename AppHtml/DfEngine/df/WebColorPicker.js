import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';
/*
Class:
    df.WebColorPicker
Extends:
    df.WebBaseControl

This control is color picker based on the HSV color scheme. A color map with horizontally the colors 
and vertically the saturation is used to pick the color and a separate slider allows the velocity to 
be choosen. Both map and slider use a canvas with gradients for the rendering, no images are needed.

The resulting color is in RGB format as used everywhere on the web where a choice between 
hexadecimal notation and full rgb(r,g,b) notation is available.
    
Revision:
    2016/06/16  (HW, DAW) 
        Initial version.
*/
df.colorFormatHex = 1;
df.colorFormatRGB = 2;

df.settings.colorPickKeys = {
    colorUp: {           //  Arrow up
        iKeyCode: 38,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    colorDown: {         //  Arrow down
        iKeyCode: 40,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    colorLeft: {         //  Arrow left
        iKeyCode: 37,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    colorRight: {        //  Arrow right
        iKeyCode: 39,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    sliderUp: {         //  Page up
        iKeyCode: 33,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    sliderDown: {       //  Page down
        iKeyCode: 34,
        bCtrl: false,
        bShift: false,
        bAlt: false
    },
    enter: {           //  Enter
        iKeyCode: 13,
        bCtrl: false,
        bShift: false,
        bAlt: false
    }
};

export class WebColorPicker extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        this.prop(df.tBool, "pbShowColorBar", true);
        this.prop(df.tInt, "peColorFormat", df.colorFormatHex);
        this.prop(df.tInt, "piPaletteItemsPerRow", 6);

        this.prop(df.tString, "psValue", "#A53D40");
        this.addSync("psValue");

        //  Triggered when the color is changed (mouseup)
        this.event("OnChange");

        //  Client-side only event triggering at real time while the value changes
        this.OnRealtimeChange = new df.events.JSHandler();
        //  Triggered on enter
        this.OnEnter = new df.events.JSHandler();

        this._tDoubleClick = null;
        this._iDoubleClickWait = 800;

        //  Internally the color is stored as HSV values. Unless the psValue is changed from the outside 
        //  the HSV is used for manipulation and generation of the RGB string (to prevent rounding 
        //  issues from causing jumping of the controls.
        this._aHSV = [0, 0, 0];

        this._aColorPalette = [];

        this._sControlClass = "WebColorPicker";
    }

    create(tDef) {
        super.create();


        this.set_psValue(this.psValue);
    }

    openHtml(aHtml) {
        const aMainClasses = ['WebCP_Main'];

        super.openHtml(aHtml);

        if (this.pbShowColorBar) {
            aMainClasses.push('WebCP_ShowColorBar');
        }
        if (this._aColorPalette.length > 0) {
            aMainClasses.push('WebCP_ShowPalette');
        }

        aHtml.push('<div class="', aMainClasses.join(' '), '" tabindex="0">',

            '<div class="WebCP_ColorPalette">');

        this.genColorPaletteHtml(aHtml);

        aHtml.push('</div>',
            '<div class="WebCP_Picker">',
            '<div class="WebCP_ColorMap">',
            '<canvas width="0" height="0"></canvas>',
            '<div class="WebCP_Pointer"></div>',
            '</div>',
            '<div class="WebCP_GradSlider">',
            '<canvas width="0" height="0"></canvas>',
            '<div class="WebCP_Slide"></div>',
            '</div>',
            '</div>',
            '<div class="WebCP_ColorBar"></div>',
            '<div>');

    }

    closeHtml(aHtml) {

        super.closeHtml(aHtml);
    }

    afterRender() {
        this._eFocus = this._eControl = df.dom.query(this._eElem, ".WebCP_Main");

        this._ePicker = df.dom.query(this._eElem, '.WebCP_Picker');
        this._eColorPalette = df.dom.query(this._eElem, '.WebCP_ColorPalette');

        this._eColorMap = df.dom.query(this._eElem, ".WebCP_ColorMap");
        this._eMapCanvas = df.dom.query(this._eElem, ".WebCP_ColorMap canvas");
        this._ePointer = df.dom.query(this._eElem, ".WebCP_Pointer");

        this._eGradSlider = df.dom.query(this._eElem, ".WebCP_GradSlider");
        this._eSliderCanvas = df.dom.query(this._eElem, ".WebCP_GradSlider canvas");
        this._eSlide = df.dom.query(this._eElem, ".WebCP_Slide");

        this._eColorBar = df.dom.query(this._eElem, ".WebCP_ColorBar");

        super.afterRender();

        df.dom.on("mousedown", this._eColorMap, this.startMapMouse, this);
        df.dom.on("mousedown", this._eGradSlider, this.startSliderMouse, this);
        df.dom.on("click", this._eColorPalette, this.onPaletteClick, this);
        df.dom.on("dblclick", this._eColorPalette, this.onPaletteDblClick, this);
        df.events.addDomKeyListener(this._eFocus, this.onKey, this);
        df.events.addDomMouseWheelListener(this._eFocus, this.onMouseWheelScroll, this);

        //  Update DOM
        this._eColorBar.style.backgroundColor = this.psValue;
        df.dom.setText(this._eColorBar, this.psValue);
    }

    resize() {
        let iPalOffset = 0;

        if (this._aColorPalette.length > 0) {
            iPalOffset += this._eColorPalette.offsetHeight;
        }

        this._ePicker.style.top = iPalOffset + "px";

        super.resize();

        if (this._eControl.clientHeight) {
            if (this._eMapCanvas.width !== this._eColorMap.clientWidth || this._eMapCanvas.height !== this._eColorMap.clientHeight) {
                this.drawColorMap();
                this.positionPointer();
            }
            if (this._eSliderCanvas.width !== this._eGradSlider.clientWidth || this._eSliderCanvas.height !== this._eGradSlider.clientHeight) {
                this.drawGradientSlider();
            }
        }
    }

    drawColorMap() {
        const eCanvas = this._eMapCanvas;

        //  Size the canvas
        eCanvas.width = this._eColorMap.clientWidth;
        eCanvas.height = this._eColorMap.clientHeight;

        //  Get drawing context
        if (!this._mainctx) {
            this._mainctx = eCanvas.getContext('2d');
        }
        const ctx = this._mainctx;

        //  Clear
        ctx.clearRect(0, 0, eCanvas.width, eCanvas.height);

        //  Draw rainbow
        const hGrad = ctx.createLinearGradient(0, 0, eCanvas.width, 0);
        hGrad.addColorStop(0, '#F00');
        hGrad.addColorStop(1 / 6, '#FF0');
        hGrad.addColorStop(2 / 6, '#0F0');
        hGrad.addColorStop(3 / 6, '#0FF');
        hGrad.addColorStop(4 / 6, '#00F');
        hGrad.addColorStop(5 / 6, '#F0F');
        hGrad.addColorStop(1, '#F00');

        ctx.fillStyle = hGrad;
        ctx.fillRect(0, 0, eCanvas.width, eCanvas.height);

        //  Fade to white at the bototm
        const vGrad = ctx.createLinearGradient(0, 0, 0, eCanvas.height);
        vGrad.addColorStop(0, 'rgba(255,255,255,0)');
        vGrad.addColorStop(1, 'rgba(255,255,255,1)');

        ctx.fillStyle = vGrad;
        ctx.fillRect(0, 0, eCanvas.width, eCanvas.height);
    }

    positionPointer() {
        let iX = 0, iY = 0; 
        const aHSV = this.getHSV();

        iX = aHSV[0] * this._eMapCanvas.width;
        iY = (1 - aHSV[1]) * this._eMapCanvas.height;   //  Lightning determines vertical position

        iX -= this._ePointer.offsetWidth / 2;
        iY -= this._ePointer.offsetHeight / 2;

        this._ePointer.style.left = Math.round(iX) + "px";
        this._ePointer.style.top = Math.round(iY) + "px";

    }

    drawGradientSlider() {
        const eCanvas = this._eSliderCanvas;

        //  Size the canvas
        eCanvas.width = this._eGradSlider.clientWidth;
        eCanvas.height = this._eGradSlider.clientHeight;

        //  Get drawing context
        if (!this._sliderctx) {
            this._sliderctx = eCanvas.getContext('2d');
        }
        const ctx = this._sliderctx;

        //  Clear
        ctx.clearRect(0, 0, eCanvas.width, eCanvas.height);

        //  Calculate start color
        const aHSV = this.getHSV();
        aHSV[2] = 1;


        const aRGB = this.HSVtoRGB(aHSV);

        //  Fade to white at the bottom
        const vGrad = ctx.createLinearGradient(0, 0, 0, eCanvas.height);
        vGrad.addColorStop(0, this.RGBtoHexString(aRGB));
        vGrad.addColorStop(1, '#000000');

        ctx.fillStyle = vGrad;
        ctx.fillRect(0, 0, eCanvas.width, eCanvas.height);

        this.positionSlider();
    }

    positionSlider() {
        let iY = 0;
        const aHSV = this.getHSV();

        iY = (1 - aHSV[2]) * this._eSliderCanvas.height;
        iY -= Math.round(this._eSlide.offsetHeight / 2);

        this._eSlide.style.top = iY + "px";
    }

    /* 
    Called to add a single color to the color palette. Updates the palette if we've already rendered.
    
    @param  sColor          Color in hex or rgb string format.
    @param  sDescription    Text shown as title on the element.
    
    @client-action
    */
    addPaletteItem(sColor, sDescription) {
        const aHtml = [];

        this._aColorPalette.push({
            sColor: sColor,
            sDescription: sDescription
        });

        if (this._eElem) {
            this.genColorPaletteHtml(aHtml);

            this._eColorPalette.innerHTML = aHtml.join("");

            this.sizeChanged();
        }
    }

    /* 
    Called to refresh the entire color palette at once. Colors are sent as action data (array of 
    tWebColorPaletteItem items).
    
    @client-action
    */
    updatePalette() {
        const aHtml = [];

        this._aColorPalette = this._tActionData;

        if (this._eElem) {
            this.genColorPaletteHtml(aHtml);

            this._eColorPalette.innerHTML = aHtml.join("");

            df.dom.toggleClass(this._eControl, "WebCP_ShowPalette", this._aColorPalette.length > 0);

            this.sizeChanged();
        }
    }

    genColorPaletteHtml(aHtml) {
        const aPal = this._aColorPalette;

        if (aPal.length > 0) {
            aHtml.push('<table class="WebCP_Palette"><colgroup>');

            for (let i = 0; i < this.piPaletteItemsPerRow; i++) {
                aHtml.push('<col style="width: ', (Math.floor(1000 / this.piPaletteItemsPerRow) / 10), '%">');
            }

            aHtml.push('</colgroup><tr>');
            for (let i = 0; i < aPal.length; i++) {
                const sC = this.RGBtoHexString(this.stringToRGB(aPal[i].sColor));

                if (i % this.piPaletteItemsPerRow === 0 && i > 0) {
                    aHtml.push('</tr><tr>');
                }
                aHtml.push('<td class="WebCP_PalColor" style="background-color: ', sC, '" data-palcolor="', sC, '" title="', aPal[i].sDescription, '"></td>');
            }
            aHtml.push('</tr></table>');
        }

    }

    onPaletteClick(oEv) {
        let eEl = oEv.getTarget()
        const sPrevColor = this.psValue;

        if (!this.isEnabled()) {
            return;
        }

        while (eEl && eEl !== this._eColorPalette) {
            if (eEl.hasAttribute("data-palcolor")) {
                const aHSV = this.RGBtoHSV(this.stringToRGB(eEl.getAttribute("data-palcolor")));
                this.setHSV(aHSV);

                this.OnRealtimeChange.fire(this, {
                    sColor: this.psValue,
                    sPrevColor: sPrevColor
                });

                return;
            }
            eEl = eEl.parentNode;
        }
    }

    onPaletteDblClick(oEv) {
        let eEl = oEv.getTarget();

        if (!this.isEnabled()) {
            return;
        }

        while (eEl && eEl !== this._eColorPalette) {
            if (eEl.hasAttribute("data-palcolor")) {
                const aHSV = this.RGBtoHSV(this.stringToRGB(eEl.getAttribute("data-palcolor")));
                this.setHSV(aHSV);

                this.OnEnter.fire(this, { sColor: this.psValue });

                oEv.stop();

                return;
            }
            eEl = eEl.parentNode;
        }

    }

    startMapMouse(oEv) {
        let iX, iY;
        const aHSV = this.getHSV(), that = this;

        if (!this.isEnabled()) {
            return;
        }

        //  Check for double click
        if (this._tDoubleClick) {
            this.OnEnter.fire(this, { sColor: this.psValue });
            clearTimeout(this._tDoubleClick);
            this._tDoubleClick = null;
            oEv.stop();
            return;
        }
        //  Set double click timer
        this._tDoubleClick = setTimeout(function () {
            that._tDoubleClick = null;
        }, this._iDoubleClickWait);

        //  Create mask
        const eMask = df.gui.dragMask(false, this._eElem);
        eMask.style.cursor = "crosshair";

        //  Initial x & y calculations
        const oRect = df.sys.gui.getBoundRect(this._eMapCanvas);
        iX = oEv.getMouseX() - oRect.left;
        iY = oEv.getMouseY() - oRect.top;




        //  Calculates the color based on x and y inside the canvas converting those into hue and saturation
        function updateColor() {
            const sPrevColor = this.psValue;

            aHSV[0] = iX / oRect.width;
            aHSV[1] = 1 - (iY / oRect.height);

            this.setHSV(aHSV, true);

            this.OnRealtimeChange.fire(this, {
                sColor: this.psValue,
                sPrevColor: sPrevColor
            });
        }

        //  Updates x & y and triggers updateColor
        function onDrag(oEv) {
            iX = Math.min(Math.max(oEv.getMouseX() - oRect.left, 0), oRect.width);
            iY = Math.min(Math.max(oEv.getMouseY() - oRect.top, 0), oRect.height);

            updateColor.call(this);
        }

        //  Stops the drag, fires OnChange and cleans up
        function onStopDrag(oEv) {
            this.fire("OnChange", [this.psValue]);
            this.focus();

            //  Clean up
            df.dom.off("mouseup", eMask, onStopDrag, this);
            df.dom.off("mouseup", window, onStopDrag, this);
            df.dom.off("mousemove", eMask, onDrag, this);

            df.gui.hideMask(eMask);
        }

        //  Attach DOM listeners
        df.dom.on("mousemove", eMask, onDrag, this);
        df.dom.on("mouseup", window, onStopDrag, this);
        df.dom.on("mouseup", eMask, onStopDrag, this);

        oEv.stop();

        updateColor.call(this);
    }

    startSliderMouse(oEv) {
        let iY; 
        const aHSV = this.getHSV(), that = this;

        if (!this.isEnabled()) {
            return;
        }

        //  Check for double click
        if (this._tDoubleClick) {
            this.OnEnter.fire(this, { sColor: this.psValue });
            clearTimeout(this._tDoubleClick);
            this._tDoubleClick = null;
            return;
        }
        //  Set double click timer
        this._tDoubleClick = setTimeout(function () {
            that._tDoubleClick = null;
        }, this._iDoubleClickWait);

        //  Create mask
        const eMask = df.gui.dragMask(false, this._eElem);
        eMask.style.cursor = "n-resize";

        //  Initial y calculations
        const oRect = df.sys.gui.getBoundRect(this._eSliderCanvas);
        iY = oEv.getMouseY() - oRect.top;

        //  Updates the color by converting the vertical coordinate into the new saturation
        function updateColor() {
            const sPrevColor = this.psValue;

            aHSV[2] = 1 - (iY / oRect.height);

            this.setHSV(aHSV, false);

            this.OnRealtimeChange.fire(this, {
                sColor: this.psValue,
                sPrevColor: sPrevColor
            });
        }

        //  Updates the Y coordinate and triggers the updateColor
        function onDrag(oEv) {
            iY = Math.min(Math.max(oEv.getMouseY() - oRect.top, 0), oRect.height);

            updateColor.call(this);
        }

        //  Handles the mouseup, triggers OnChange and cleans up the mess
        function onStopDrag(oEv) {
            this.fire("OnChange", [this.psValue]);
            this.focus();

            //  Clean up
            df.dom.off("mouseup", eMask, onStopDrag, this);
            df.dom.off("mouseup", window, onStopDrag, this);
            df.dom.off("mousemove", eMask, onDrag, this);

            df.gui.hideMask(eMask);
        }

        df.dom.on("mousemove", eMask, onDrag, this);
        df.dom.on("mouseup", window, onStopDrag, this);
        df.dom.on("mouseup", eMask, onStopDrag, this);

        oEv.stop();

        updateColor.call(this);
    }



    adjustColor(iType, iVal) {
        const aHSV = this.getHSV(), sPrevColor = this.psColor;

        aHSV[iType] = Math.max(0, Math.min(1, aHSV[iType] + (iVal / 20)));
        this.setHSV(aHSV, (iType !== 2));

        this.OnRealtimeChange.fire(this, {
            sColor: this.psValue,
            sPrevColor: sPrevColor
        });
        this.fire("OnChange", [this.psValue]);
    }

    /* 
    Handles the mousewheel scroll event and increments / decrements the slider value when it happens.
    
    @param  oEvent  DOM Event object (df.events.DomEvent)
    @private
    */
    onMouseWheelScroll(oEvent) {
        const iDelta = oEvent.getMouseWheelDelta();

        if (!this.isEnabled()) {
            return;
        }

        if (iDelta > 0) {
            //  Scroll up
            this.adjustColor(2, 1);
        } else if (iDelta < 0) {
            //  Scroll down
            this.adjustColor(2, -1);
        }

        oEvent.stop();
    }

    /*
    Handles the keypress event of focus holder element. If the pressed key matches 
    one of the keys that are set it performs the action.
    
    @param  oEvent  Event object.
    @private
    */
    onKey(oEvent) {

        //  Generate key object to compare
        if (this.isEnabled()) {
            if (oEvent.matchKey(df.settings.colorPickKeys.colorUp)) { // Up (decrement with 7 days)
                this.adjustColor(1, 1);
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.colorDown)) { //  Down (increment with 7 days)
                this.adjustColor(1, -1);

                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.colorLeft)) { // Left (decrement with one day)
                this.adjustColor(0, -1);

                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.colorRight)) { // Right (increment with one day)
                this.adjustColor(0, 1);

                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.sliderUp)) { //  Month up
                this.adjustColor(2, 1);

                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.sliderDown)) { //    Month down
                this.adjustColor(2, -1);
                oEvent.stop();
            } else if (oEvent.matchKey(df.settings.colorPickKeys.enter)) { //    Enter
                this.OnEnter.fire(this, { sColor: this.psValue });
            }
        }
    }

    /* 
    Setter for the psValue which parses the RGB string into separate RGB values that are calculated into 
    the HSV value. It calls setHSV to update the color picker with the new color.
    
    @param  sV  The new color value (RGB color string).
    */
    set_psValue(sV) {

        const aRGB = this.stringToRGB(sV);

        const aHSV = this.RGBtoHSV(aRGB);

        if (this._aHSV[0] !== aHSV[0] || this._aHSV[1] !== aHSV[1] || this._aHSV[2] !== aHSV[2]) {
            this.setHSV(aHSV, true);
        }
    }

    /* 
    Hides or shows the color bar by adding / removing the classname. Also triggers a redraw of the map 
    and slider as their position has changed.
    
    @param  bVal    New value.
    */
    set_pbShowColorBar(bVal) {
        if (this._eColorBar) {
            df.dom.toggleClass(this._eControl, "WebCP_ShowColorBar", bVal);
            this.drawColorMap();
            this.drawGradientSlider();
        }
    }

    /* 
    @return Current HSV value in array (by value).
    @private
    */
    getHSV() {
        return this._aHSV.slice();
    }

    /* 
    Updates the current HSV value by updating the map position, slider and psValue.
    
    @param  aHSV                Array with HSV values.
    @param  bUpdateGradient     If true the color of the slider is updated.
    @private
    */
    setHSV(aHSV, bUpdateGradient) {
        //  Update central value
        this._aHSV = aHSV;

        //df.log("Set: H: " + this._aHSV[0].toString().substr(0, 4) + " S: " + this._aHSV[1].toString().substr(0, 4) + " V: " + this._aHSV[2].toString().substr(0, 4));

        //  Update psValue (after calculating RGB)
        const aRGB = this.HSVtoRGB(aHSV);
        if (this.peColorFormat === df.colorFormatHex) {
            this.psValue = this.RGBtoHexString(aRGB);
        } else {
            this.psValue = this.RGBtoRgbString(aRGB);
        }

        //  Update UI
        if (this._eControl) {
            if (this._eColorBar) {
                this._eColorBar.style.backgroundColor = this.psValue;
                df.dom.setText(this._eColorBar, this.psValue);
            }

            this.positionPointer();
            if (bUpdateGradient) {
                this.drawGradientSlider();
            } else {
                this.positionSlider();
            }
        }
    }

    RGBtoHSV(rgb) {
        let h;

        const r = rgb[0] / 255;
        const g = rgb[1] / 255;
        const b = rgb[2] / 255;
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const v = max;

        const d = max - min;
        const s = max === 0 ? 0 : d / max;

        if (max === min) {
            h = 0; // achromatic
        } else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }

        return [h, s, v];
    }

    HSVtoRGB(hsv) {
        let r, g, b;
        const h = hsv[0], s = hsv[1], v = hsv[2]

        const i = Math.floor(h * 6);
        const f = h * 6 - i;
        const p = v * (1 - s);
        const q = v * (1 - f * s);
        const t = v * (1 - (1 - f) * s);

        switch (i % 6) {
            case 0:
                r = v;
                g = t;
                b = p;
                break;
            case 1:
                r = q;
                g = v;
                b = p;
                break;
            case 2:
                r = p;
                g = v;
                b = t;
                break;
            case 3:
                r = p;
                g = q;
                b = v;
                break;
            case 4:
                r = t;
                g = p;
                b = v;
                break;
            case 5:
                r = v;
                g = p;
                b = q;
                break;
        }

        return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
    }

    RGBtoHexString(aRGB) {
        let sV = "#";

        for (let i = 0; i < aRGB.length; i++) {
            sV += df.sys.math.padZero(Math.round(aRGB[i]).toString(16), 2);
        }

        return sV;
    }

    hexStringToRGB(sColor) {
        if (sColor.length === 7) {
            return [parseInt(sColor.substr(1, 2), 16), parseInt(sColor.substr(3, 2), 16), parseInt(sColor.substr(5, 2), 16)];
        }
        if (sColor.length === 4) {
            return [parseInt(sColor.substr(1, 1) + sColor.substr(1, 1), 16), parseInt(sColor.substr(2, 1) + sColor.substr(2, 1), 16), parseInt(sColor.substr(3, 1) + sColor.substr(3, 1), 16)];
        }

        return [0, 0, 0];
    }

    RGBtoRgbString(aRGB) {
        return "rgb(" + aRGB.join(",") + ")";
    }

    rgbStringToRGB(sColor) {

        sColor = sColor.substr(4);
        if (sColor.charAt(sColor.length - 1) === ';') {
            sColor.substr(0, sColor.length - 1);
        }
        if (sColor.charAt(sColor.length - 1) === ')') {
            sColor.substr(0, sColor.length - 1);
        }

        const aRGB = sColor.split(",");
        if (aRGB.length === 3) {
            for (let i = 0; i < 3; i++) {
                aRGB[i] = Math.max(0, Math.min(255, parseInt(aRGB[i], 10)));
            }

            return aRGB;
        }

        return [0, 0, 0];
    }

    stringToRGB(sColor) {
        var aRGB = [0, 0, 0];

        if (sColor.substr(0, 1) === "#") {
            aRGB = this.hexStringToRGB(sColor);
        } else if (sColor.substr(0, 4).toLowerCase() === "rgb(") {
            aRGB = this.rgbStringToRGB(sColor);
        }

        return aRGB;
    }
};