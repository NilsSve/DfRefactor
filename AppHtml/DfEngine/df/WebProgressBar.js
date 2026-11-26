import { WebBaseControl } from './WebBaseControl.js';
import { df } from '../df.js';

/*
Class:
    df.WebProgressBar
Extends:
    df.WebBaseControl

The progressbar control is a simple control that consists of multiple div elements where the width 
as an percentage is used to show the progress.
    
Revision:
    2013/07/24  (RH, DAE) 
        Initial version.
*/
export class WebProgressBar extends WebBaseControl {
    constructor(sName, oParent) {
        super(sName, oParent);

        //  Web Properties
        this.prop(df.tInt, "piMaxValue", 100);
        this.prop(df.tInt, "piValue", 0);
        this.prop(df.tBool, "pbShowPercentage", true);
        this.prop(df.tString, "psCaption", "");
        this.prop(df.tInt, "piDecimals", "");

        // @privates
        this._eProgressBarWrp = null;
        this._eProgress = null;
        this._ePercentage = null;

        //  Configure super classes
        this.piColumnSpan = 0;
        this.pbShowLabel = false;
        this._sControlClass = "WebProgressBar";
    }

    /*
    This method generates the HTML for the progressbar.
    
    @param  aHtml   Array used as string builder for the HTML.
    @private
    */
    openHtml(aHtml) {
        super.openHtml(aHtml);

        aHtml.push('<div class="WebPB_Wrp', (this.pbShowPercentage || this.psCaption ? ' WebPB_ShowPercentage' : ''), '">');
        aHtml.push('<div>');
        aHtml.push('<div class="WebPB_Progress"></div>');
        if (this.psCaption !== "") {
            aHtml.push('<div class="WebPB_Percentage">', df.dom.encodeHtml(this.psCaption), '</div>');
        } else {
            aHtml.push('<div class="WebPB_Percentage"></div>');
        }
    }

    /*
    This method closes the progressbar wrapper
    
    @param  aHtml   Array string builder to add HTML to.
    @private
    */
    closeHtml(aHtml) {
        aHtml.push('</div></div>');

        super.closeHtml(aHtml);
    }

    /*
    This method is called after the HTML is added to the DOM and gets a reference to the
    Wrapper, progress and percentage divs
    
    @private
    */
    afterRender() {
        //  Get references
        this._eProgressBarWrp = df.dom.query(this._eElem, ".WebPB_Wrp");
        this._eProgress = df.dom.query(this._eElem, ".WebPB_Progress");
        this._ePercentage = df.dom.query(this._eElem, ".WebPB_Percentage");

        this.set_piValue(this.piValue);

        super.afterRender();
    }


    //-------------Helper functions

    /*
    This function calculates the current percentage of the progress bar
    */
    getPercentage(iCustomDecimals) {
        let iDecimals = this.piDecimals;
        if (iCustomDecimals !== undefined) {
            iDecimals = iCustomDecimals;
        }
        iDecimals = Math.pow(10, iDecimals);
        const fPercentage = (this.piValue / this.piMaxValue) * 100;

        return Math.round(fPercentage * iDecimals) / iDecimals;
    }


    //-------------Setters
    /*
    This function sets the new value of the progressbar and updates the DOM
    */
    set_piValue(iVal) {
        if (this._eProgress) {
            iVal = (iVal >= 0 ? (iVal <= this.piMaxValue ? iVal : this.piMaxValue) : 0);

            this.piValue = iVal;
            this._eProgress.style.width = this.getPercentage(2) + "%";
            df.dom.toggleClass(this._eProgress, "WebPB_Zero", iVal === 0);
            if (!this.psCaption) {
                df.dom.setText(this._ePercentage, this.getPercentage() + "%");
            }
        }
    }

    set_pbShowPercentage(bVal) {
        if (this._ePercentage) {
            df.dom.toggleClass(this._eProgressBarWrp, 'WebPB_ShowPercentage', bVal || this.psCaption);
        }
    }

    set_psCaption(sVal) {
        if (this._ePercentage) {
            this.psCaption = sVal;

            df.dom.toggleClass(this._eProgressBarWrp, 'WebPB_ShowPercentage', sVal || this.pbShowPercentage);
            if (sVal) {
                df.dom.setText(this._ePercentage, sVal);
            } else {
                //  Update with percentage value
                this.set_piValue(this.piValue);
            }
        }
    }

    set_piMaxValue(iVal) {
        this.piMaxValue = iVal;
        this.set_piValue(this.piValue);
    }
}