import { df } from '../df.js';
/*
Class:
    df.WebListTouchHandler

The touch logic of the WebList which is placed in a separate module. It implements touch scrolling 
(kinetic with bounce) if a WebListScrollingView is used. It also contains the logic for the swipe 
buttons. It does hook into the view classes pretty tightly.
    
Revision:
    2017/02/10  (HW, DAW) 
        Initial version.
*/

export class WebListTouchHandler {
    constructor(oList, oView, oModel, oController) {
        this.oL = oList;
        this.oV = oView;
        this.oM = oModel;
        this.oC = oController;


        this.iAutoScrollIncr = 1;

        this.iSwipeStartOffset = 0;
        this.iSwipeOffset = 0;

        this.eSwipeRow = null;
        this.eSwipeRowStart = null;
        this.eSwipeLeftBtns = null;
        this.eSwipeRightBtns = null;
    }

    afterRender(eList) {
        const oV = this.oV;

        if (window.PointerEvent) {    //  Microsofts new standard adopted by W3C for touch / mouse & pen events as of IE11
            df.dom.on("pointerdown", oV.eBody, this.onPointerDown, this);
        } else {
            df.dom.on("touchstart", oV.eBody, this.onTouchStart, this);
        }

        //  Attach a non passive touchmove listener to prevent move from causing a bounce at body level on IOS 10 Safari
        if (oV.bScroll && oV.eBodyWrp.addEventListener && this.oL.pbAutoColumnSizing) {
            oV.eBodyWrp.addEventListener("touchmove", function (e) {
                e.preventDefault();
            }, { passive: false });
        }
    }



    /*
    This event handler handles the touch event on mobile devices. It will scroll list if the touch is a 
    vertical sliding touch.
    
    @param  oEv     Event object (df.events.DOMEvent)
    @private
    */
    onTouchStart(oEv) {
        //  Only respond to single finger swipes
        if (oEv.e.targetTouches.length === 1) {
            this.touchScroll(false, oEv);
        }
    }

    onPointerDown(oEv) {
        if (oEv.e.pointerType === "pen" || oEv.e.pointerType === "touch") {
            this.touchScroll(true, oEv);
        }
    }

    touchScroll(bPointer, oEv) {
        const that = this, oV = this.oV, iTimeConstant = 325, bScrollable = !!oV.bScroll;
        let iY, iPrevY, iVelocity = 0, iAmplitude = 0, iTimestamp = Date.now(), iFrame,
            tTracker, iTarget, iMaxPX, iBounce, iBounceTime = 0, iStartOffset, iAuto,
            iX, iPrevX, bSwipe = false, bSwipeFixed = false;

        //  Stop running scroll animations
        oV.iAutoScroll = iAuto = this.iAutoScrollIncr++;
        // console.log(iAuto + ":touchStart  oV.iScrollOffsetPx:" + oV.iScrollOffsetPx);


        //  Initialize variables
        const bSwipable = this.swipeStart(oEv.getTarget());

        const iStartX = iPrevX = iX = (bPointer ? oEv.e.clientX : oEv.e.targetTouches[0].pageX);
        const iStartY = iFrame = iPrevY = iY = (bPointer ? oEv.e.clientY : oEv.e.targetTouches[0].pageY);

        if (bScrollable) {
            iStartOffset = oV.iScrollOffsetPx;
            iMaxPX = oV.getMaxPX();
            iBounce = oV.iTableHeight * 0.1;
        }

        //  Handles the move event and recalculates the scrollbar position accordingly
        function touchMove(oEv) {
            var iOffset, iDiff;

            //  Determine new touch position
            iY = (bPointer ? oEv.e.clientY : oEv.e.targetTouches[0].pageY);
            iX = (bPointer ? oEv.e.clientX : oEv.e.targetTouches[0].pageX);



            //  Switch between horizontal swipe and scroll
            if ((bSwipeFixed && bSwipe) || (!bSwipeFixed && Math.abs(iStartX - iX) > Math.abs(iStartY - iY))) {
                bSwipe = true;

                // console.log(iAuto + ":swipeRow iDiffX: " + (iStartX - iX));
                this.swipeRow(oEv.getTarget(), iStartX - iX);
            } else {
                if (bSwipe) {
                    //  Cancel swipe
                    this.swipeRowCancel();
                }

                if (bScrollable) {
                    //  Calculate new offset
                    iOffset = oV.iScrollOffsetPx + (iPrevY - iY);

                    //  Use elastic logic outside boundaries
                    if (iOffset < 0) {
                        iDiff = iStartOffset + (iStartY - iY);
                        iOffset = iDiff * 0.3;
                    } else if (iOffset > iMaxPX) {
                        iDiff = iStartOffset + (iStartY - iY) - iMaxPX;
                        iOffset = iMaxPX + iDiff * 0.3;
                    }

                    //  Perform scroll
                    oV.scrollTo(iOffset, false, false, true);
                    //console.log(iAuto + ":scrollRow x:" + iX + "  y:" + iY + "  startx:" + iStartX + " starty:" + iStartY + " iOffset:" + iOffset);

                    oEv.stop();
                }
            }

            //  Update administration
            iPrevY = iY;
            iPrevX = iX;

            if (bSwipable || bScrollable) {
                oEv.e.preventDefault();
            }
        }

        //
        //  Performs the kinetic scrolling animiation. Adjusts animation for bounce when outside of boundaries.
        //
        function autoScroll() {
            let iElapsed, iDelta;

            if (oV.iAutoScroll === iAuto && iAmplitude) {
                iElapsed = Date.now() - iTimestamp;

                //  Detect when outside boundaries
                if (oV.iScrollOffsetPx < 0 || oV.iScrollOffsetPx > iMaxPX) {
                    //  For the first time we need to calculate bounce values (target & time)
                    if (!iBounceTime) {
                        //  Determine how far we where with the autoscroll animation
                        const iDone = Math.abs((-iAmplitude * Math.exp(-iElapsed / iTimeConstant)) / iAmplitude);

                        //  Calculate bouncetime & amplitude based on current amplitude and done value
                        iBounceTime = iDone * 100;
                        iAmplitude = (Math.max(-iAmplitude / 2000, 1) * (oV.iScrollOffsetPx > iMaxPX ? iBounce : -iBounce)) * iDone;
                        iTarget = oV.iScrollOffsetPx + iAmplitude;

                        //  Reset counters
                        iTimestamp = Date.now();
                        iElapsed = Date.now() - iTimestamp;
                    }

                    iDelta = -iAmplitude * Math.exp(-iElapsed / iBounceTime);
                } else {
                    iDelta = -iAmplitude * Math.exp(-iElapsed / iTimeConstant);
                }
                const iOffset = iTarget + iDelta;

                //  Perform actuall scroll
                if (iDelta > 0.5 || iDelta < -0.5) {
                    // console.log(iAuto + ":autoScroll(iDelta : " + iDelta + ", iOffset : " + iOffset + ", iAmplitude:"+ iAmplitude + ")");
                    oV.scrollTo(iOffset, false, false, true);
                    df.dom.animFrame(autoScroll, this);
                } else {
                    //  If there isn't enough speed anymore we end the animation
                    // console.log(iAuto + ":autoScroll last(iDelta : " + iDelta + ", iOffset : " + iOffset + ", iAmplitude:"+ iAmplitude + ")");
                    oV.scrollTo(iTarget, false, false, true);

                    //  Perform animation back to limit when outside of boundaries
                    if (iTarget < 0) {
                        aniScroll.call(that, -oV.iScrollOffsetPx, ((iOffset / -iBounce) * 80));
                    } else if (iTarget > iMaxPX) {
                        aniScroll.call(that, iMaxPX - oV.iScrollOffsetPx, (((iOffset - iMaxPX) / iBounce) * 80));
                    }
                }
            }

        }


        //
        //  Handles the touch end and initiates scroll animations if needed.
        //
        function touchEnd(oEv) {
            // console.log(iAuto + ':touchEnd');

            if (bPointer) {
                df.dom.off("pointerup", document, touchEnd, this);
                df.dom.off("pointercancel", document, touchEnd, this);
                df.dom.off("pointermove", document, touchMove, this);
            } else {
                df.dom.off("touchend", document, touchEnd, this);
                df.dom.off("touchcancel", document, touchEnd, this);
                df.dom.off("touchmove", document, touchMove, this);
            }

            clearInterval(tTracker);
            if (bSwipe) {
                this.swipeRowEnd();
            }

            if (bScrollable) {
                //  Animate going back when outside of boundaries
                if (oV.iScrollOffsetPx < 0) {
                    aniScroll.call(this, -oV.iScrollOffsetPx, ((oV.iScrollOffsetPx / -iBounce) * 80));
                } else if (oV.iScrollOffsetPx > iMaxPX) {
                    aniScroll.call(this, iMaxPX - oV.iScrollOffsetPx, (((oV.iScrollOffsetPx - iMaxPX) / iBounce) * 80));
                } else if (!bSwipe) {
                    //  Determine if there is enough energy to do a kinetic scroll
                    if (iVelocity > 10 || iVelocity < -10) {
                        //  Calculate amplitude and target
                        iAmplitude = 1.9 * iVelocity;
                        iTarget = Math.round(oV.iScrollOffsetPx + iAmplitude);

                        //  Round target on a full row (only if inside the boundaries, else it will round to the limit which we do not want here)
                        if (iTarget > 0 && iTarget < iMaxPX) {
                            iTarget = oV.snapToRow(iTarget);
                        }

                        iTimestamp = Date.now();
                        //console.log(iAuto + ":touchEnd autoscroll  iTarget:" + iTarget + " iAmplitude: " + iAmplitude + " oV.iScrollOFsetPx:" + oV.iScrollOffsetPx);
                        df.dom.animFrame(autoScroll, this);
                    }
                }
            }

            if (Math.abs(iPrevY - iStartY) > 15 || Math.abs(iPrevX - iStartX) > 15) {
                //  Explicitly block click using bCancelClick if scrolling from a pointer as stopping the event won't stop the click event (Windows)
                if (bPointer) {
                    oV.bCancelClick = true;
                    setTimeout(function () {
                        oV.bCancelClick = false;
                    }, 200);
                }
            }
        }

        function aniScroll(iDelta, iLengthMS) {
            const oV = this.oV; 
            let iFrom, tStart, tEnd;

            // t: current time, b: begInnIng value, c: change In value, d: duration
            function easeInOutSine(t, b, c, d) {
                return -c / 2 * (Math.cos(Math.PI * t / d) - 1) + b;
            }

            // console.log(iAuto + ":aniScroll(iDelta : " + iDelta + ", iLengthMS : " + iLengthMS + ")");

            function animate() {
                var tCur, iStep;

                if (oV.iAutoScroll === iAuto) {
                    tCur = Math.min(Date.now(), tEnd);

                    iStep = easeInOutSine(tCur - tStart, iFrom, iDelta, tEnd - tStart);

                    // console.log(iAuto + ":animate(iStep : " + iStep + " iFrom: " + iFrom + " iDelta: " + iDelta );

                    oV.scrollTo(iStep, false, false, true);

                    if (tCur < tEnd && (iStep > 0.5 || iStep < 0.5)) {
                        df.dom.animFrame(animate, this);
                    }
                }
            }


            if (iDelta !== 0) {
                iFrom = oV.iScrollOffsetPx;

                tStart = Date.now();
                tEnd = tStart + iLengthMS;


                animate();
            }
        };

        //
        //  The tracker is executed on an interval and calculates the velocity based on the changed touch position.
        //
        function track() {

            //  Update administration
            const iNow = Date.now();
            const iElapsed = iNow - iTimestamp;
            iTimestamp = iNow;
            const iDelta = iFrame - iY;
            iFrame = iY;

            //  Update velocity
            const v = 500 * iDelta / (1 + iElapsed);
            iVelocity = 0.8 * v + 0.2 * iVelocity;  //  Use the previous velocity to smoothen excesses

            // console.log(iAuto + ":track    iFrame:" + iFrame + " iDelta:" + iDelta + " iElapsed:" + iElapsed + " iVelocity:" + iVelocity);
        }

        if (bPointer) {
            df.dom.on("pointerup", document, touchEnd, this);
            df.dom.on("pointercancel", document, touchEnd, this);
            df.dom.on("pointermove", document, touchMove, this);

        } else {
            df.dom.on("touchend", document, touchEnd, this);
            df.dom.on("touchcancel", document, touchEnd, this);
            df.dom.on("touchmove", document, touchMove, this);

        }
        tTracker = setInterval(track, 50);

        setTimeout(function () {
            bSwipeFixed = true;
        }, 300);
    }





    /* 
    Simulates a full swipe left. This is used by the keyboard input initiated by WebListController.
    */
    showSwipeLeft() {
        const eElem = this.oV.currentRowElem();
        let iOffset;

        if (eElem) {
            if (this.swipeStart(eElem)) {
                if (this.eSwipeRow && !this.eSwipeRowStart && this.iSwipeOffset < 0) {
                    this.swipeRowClose(this.eSwipeRow);
                    return true;
                }

                if (this.eSwipeRowStart) {
                    if (this.eSwipeRow && this.eSwipeRow !== this.eSwipeRowStart) {
                        this.swipeRowClose(this.eSwipeRow);
                    }
                    this.eSwipeRow = this.eSwipeRowStart;
                    this.eSwipeRowStart = null;
                }

                if (!this.eSwipeLeftBtns && !this.eSwipeRightBtns) {
                    this.initSwipeRow();
                }

                if (this.eSwipeLeftBtns) {
                    if (this.iSwipeStartOffset < 0) {
                        iOffset = 0;
                    } else {
                        iOffset = this.eSwipeLeftBtns.offsetWidth;
                    }
                    this.swipeAniOffset(this.eSwipeRow, iOffset);

                    return true;
                }

            }
        }
        return false;
    }

    /* 
    Simulates a full swipe right. This is used by the keyboard input initiated by WebListController.
    */
    showSwipeRight() {
        const eElem = this.oV.currentRowElem();
        let iOffset;

        if (eElem) {
            if (this.swipeStart(eElem)) {
                if (this.eSwipeRow && !this.eSwipeRowStart && this.iSwipeOffset > 0) {
                    this.swipeRowClose(this.eSwipeRow);
                    return true;
                }

                if (this.eSwipeRowStart) {
                    if (this.eSwipeRow && this.eSwipeRow !== this.eSwipeRowStart) {
                        this.swipeRowClose(this.eSwipeRow);
                    }
                    this.eSwipeRow = this.eSwipeRowStart;
                    this.eSwipeRowStart = null;
                }

                if (!this.eSwipeLeftBtns && !this.eSwipeRightBtns) {
                    this.initSwipeRow();
                }

                if (this.eSwipeRightBtns) {
                    if (this.iSwipeStartOffset > 0) {
                        iOffset = 0;
                    } else {
                        iOffset = -this.eSwipeRightBtns.offsetWidth;
                    }
                    this.swipeAniOffset(this.eSwipeRow, iOffset);

                    return true;
                }

            }
        }
        return false;
    }

    /* 
    Called when the user starts swiping (ontouchstart) to initialize the button swiping. It determines 
    if there are swipe buttons (enabling the detection for horizontal swiping.
    
    @param  eElem   DOM element on which swiping started.
    @return     True if there are active swipe buttons for this row.
    */
    swipeStart(eElem) {
        const oL = this.oL, oV = this.oV, oM = this.oM;
        let bFound = false;

        //  Determine swipe row
        while (eElem && eElem !== oV.eBody) {
            //  Check if we found the tr element and if it is part of the table
            if (eElem.tagName === "TABLE" && eElem.hasAttribute("data-dfisrow")) {
                bFound = true;
                break;
            }

            eElem = eElem.parentNode;
        }

        if (bFound) {
            this.iSwipeStartOffset = 0;
            if (this.eSwipeRow) {
                if (this.eSwipeRow === eElem) { // We are swiping the already opened row
                    this.iSwipeStartOffset = this.iSwipeOffset;
                    return true;
                }
            }



            const iRow = oM.rowIndexByRowId(eElem.getAttribute("data-dfrowid"));

            if (iRow > -1) {
                const tRow = oM.aData[iRow];

                for (let iBtn = 0; iBtn < oL._aSwipeBtns.length; iBtn++) {
                    const oBtn = oL._aSwipeBtns[iBtn];
                    const tCell = tRow.aCells[oBtn._iColIndex];

                    if (oBtn.isVisible(tCell)) {
                        this.eSwipeRowStart = eElem;
                        return true;
                    }
                }
            }
            this.eSwipeRowStart = null;
        }

        return false;
    }

    initSwipeRow() {
        let eLeft, eRight, aHtml, bRight = false, bLeft = false;
        const eRow = this.eSwipeRow, oM = this.oM, oL = this.oL;

        if (eRow) {
            //  Initialize swipe data
            const iRow = oM.rowIndexByRowId(eRow.getAttribute("data-dfrowid"));
            const tRow = oM.aData[iRow];

            const aLeftHtml = ['<table data-dfrowid="', (tRow ? tRow.sRowId : "empty"), '" class="WebList_SwipeBtns WebList_SwipeBtnsLeft"><tr>'];
            const aRightHtml = ['<table data-dfrowid="', (tRow ? tRow.sRowId : "empty"), '" class="WebList_SwipeBtns WebList_SwipeBtnsRight"><tr>'];

            //  Loop buttons and generate html
            for (let iBtn = 0; iBtn < oL._aSwipeBtns.length; iBtn++) {
                const oBtn = oL._aSwipeBtns[iBtn];
                const tCell = tRow.aCells[oBtn._iColIndex];

                if (oBtn.isVisible(tCell)) {
                    if (oBtn.pbPositionLeft) {
                        aHtml = aLeftHtml;
                        bLeft = true;
                    } else {
                        aHtml = aRightHtml;
                        bRight = true;
                    }
                    aHtml.push('<td data-dfswbtn="', iBtn, '" class="WebList_SwipeBtn ', oBtn.psCSSClass, ' ', tCell.sCssClassName, '" style="');

                    if (oBtn.piWidth > 0) {
                        aHtml.push('width: ', oBtn.piWidth, 'px; ');
                    }
                    aHtml.push('height: ', eRow.offsetHeight, 'px">', oBtn.btnHtml(tCell), '</td>');
                }
            }

            aLeftHtml.push('</tr></table>');
            aRightHtml.push('</tr></table>');

            //  Generate elements
            if (bLeft) {
                this.eSwipeLeftBtns = eLeft = df.dom.create(aLeftHtml.join(''));
                eRow.parentNode.insertBefore(eLeft, eRow);
            }
            if (bRight) {
                this.eSwipeRightBtns = eRight = df.dom.create(aRightHtml.join(''));
                eRow.parentNode.insertBefore(eRight, eRow);
            }
        }
    }

    /* 
    Called during the horizontal swipe operation to update the offset (ontouchemove). If the buttons are 
    not rendered it will do that and it will update the horizontal position of the swipe row.
    
    @param  iDiffX  The number of horizontal pixels moved relative to the swipe starting point.
    */
    swipeRow(eElem, iDiffX) {
        let iOffset, iMin = 0, iMax = 0;

        // df.debug("swipeRow: "  + iDiffX);

        //  If this is the first actual swipe operation on a touched row, so now we close an already opened row and make the start row the swipe
        if (this.eSwipeRowStart) {
            if (this.eSwipeRow) {
                this.swipeRowClose(this.eSwipeRow);
            }
            this.eSwipeRow = this.eSwipeRowStart;
            this.eSwipeRowStart = null;
        }

        if (this.eSwipeRow) {
            if (!this.eSwipeLeftBtns && !this.eSwipeRightBtns) {
                this.initSwipeRow();
            }

            if (this.eSwipeLeftBtns) {
                iMax = this.eSwipeLeftBtns.offsetWidth;
            }
            if (this.eSwipeRightBtns) {
                iMin -= this.eSwipeRightBtns.offsetWidth;
            }

            this.iSwipeOffset = iOffset = Math.max(Math.min(this.iSwipeStartOffset - iDiffX, iMax), iMin);
            df.dom.translateX(this.eSwipeRow, iOffset, false);
        }
    }

    /* 
    Called when the swipe operation is cancelled (the swipe action turned out to be vertical instead of 
    horizontal).
    */
    swipeRowCancel() {
        if (this.eSwipeRow) {
            this.swipeRowClose(this.eSwipeRow);
            this.eSwipeRow = null;
        }
    }

    /* 
    Closes a swipe row (removes buttons scrolls back to 0).
    
    @param  eRow    Swipe row to close (we do assume the left and right buttons are in the properties).
     */
    swipeRowClose(eRow) {
        const eLeft = this.eSwipeLeftBtns;
        const eRight = this.eSwipeRightBtns;

        this.swipeAniOffset(eRow, 0, function finish() {
            if (eLeft) {
                if (eLeft.parentNode) {
                    eLeft.parentNode.removeChild(eLeft);
                }
            }
            if (eRight) {
                if (eRight.parentNode) {
                    eRight.parentNode.removeChild(eRight);
                }
            }
        });

        this.eSwipeLeftBtns = null;
        this.eSwipeRightBtns = null;
    }

    /* 
    Called when the touch operation is finished (OnTouchEnd) and makes sure we always end up with fully 
    opened or fully closed buttons depending on the swipe direction and position.
    */
    swipeRowEnd() {
        let iOffset = this.iSwipeOffset;

        if (this.eSwipeRow) {
            if (this.iSwipeOffset > this.iSwipeStartOffset) {
                if (this.iSwipeOffset > 0) {
                    iOffset = this.eSwipeLeftBtns.offsetWidth;
                } else {
                    iOffset = 0;
                }
            } else {
                if (this.iSwipeOffset < 0) {
                    iOffset = 0 - this.eSwipeRightBtns.offsetWidth;
                } else {
                    iOffset = 0;
                }
            }

            if (iOffset === 0) {
                this.swipeRowClose(this.eSwipeRow);
                this.eSwipeRow = null;
            } else {
                this.swipeAniOffset(this.eSwipeRow, iOffset);
            }
        }
    }

    /* 
    Animates the horizontal movement while closing or opening of a swipe row using a CSS transition.
    
    @param  eRow    The row to animate.
    @param  iOffset The offset to animate towards.
    @param  fFinish Function called after animation.
    */
    swipeAniOffset(eRow, iOffset, fFinish) {
        df.dom.transition(eRow, "all 200ms", fFinish, this);
        df.dom.translateX(eRow, iOffset);

        this.iSwipeOffset = iOffset;
    }

    /* 
    Called by the onTableClick handler when a swipe button is clicked. Determines the row, sets the 
    Active class, selects the row and triggers the click on the button object.
    
    @param  oEv  DOM Event for the click.
    @param  eElem   The target element (td data-dfswbtn).
     */
    swipeBtnClick(oEv, eElem) {
        const oL = this.oL, oM = this.oM, eRow = this.eSwipeRow; 
        let eBtn = eElem, sRowId = null;

        while (eElem && eElem !== this.oV.eBody) {
            //  Check if we found the tr element and if it is part of the table
            if (eElem.tagName === "TABLE" && eElem.hasAttribute("data-dfrowid")) {
                sRowId = eElem.getAttribute("data-dfrowid");
                break;
            }

            eElem = eElem.parentNode;
        }

        if (sRowId) {
            const iRow = oM.rowIndexByRowId(sRowId);

            if (iRow >= 0) {
                //  Perform the rowchange
                this.oC.selectRow("row", iRow);

                //  Notify column of (after)click
                df.dom.addClass(eBtn, "WebCon_Active");
                oL._aSwipeBtns[eBtn.getAttribute("data-dfswbtn")].btnClick(oEv, oM.aData[iRow].sRowId, function (oEv) {
                    df.dom.removeClass(eBtn, "WebCon_Active");
                    this.swipeRowClose(eRow);
                    oL.focus();
                }, this);
            }
        }
    }

}
