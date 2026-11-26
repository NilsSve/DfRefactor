
export const dev = {
    /*
    If true the browser is supposed to be safari or part of the safari family.
    */
    isSafari: false,
    /*
    True if the browser seems to be Google Chrome.
    */
    isChrome: false,
    /*
    True if the browser seems to be Opera.
    */
    isOpera: false,
    /*
    If true the browser is supposed to be part of the mozilla family (usually
    FireFox).
    */
    isMoz: false,
    /*
    True if the browser seems to be Internet Explorer. Also true if we where not
    able to detect the browser type properly (if browser unknown threat it as IE
    policy).
    */
    isIE: false,
    /* 
    True if the browser seems to be Microsoft Edge.
    */
    isEdge: false,
    /*
    True if the WebKit layout engine is used (Safari & Chrome).
    */
    isWebkit: false,

    isMobile: false,
    isIOS: false,

    /*
    Indicates the browser version.
    */
    iVersion: 0,


    /* 
    Performs the device detection based on the user agent string. This sets / updates the isSafari, 
    isIE, .. properties!
    */
    detectDevice() {
        //  Check if something actually changed
        if (this._sPrevUA !== navigator.userAgent) {
            this._sPrevUA = navigator.userAgent;

            //  Reset values
            this.isSafari = false;
            this.isChrome = false;
            this.isOpera = false;
            this.isMoz = false;
            this.isIE = false;
            this.isEdge = false;
            this.isWebkit = false;
            this.isMobile = false;
            this.isIOS = false;

            /*
            Performing the version checks. In most situations we try to use object
            detection, but sometimes we still need version checks.
            */
            if (navigator.userAgent.indexOf("Trident") >= 0) {    //  Recognize IE 11 and higher
                this.isIE = true;
                if (document.documentMode) {
                    this.iVersion = document.documentMode;
                } else if (navigator.appVersion.indexOf("MSIE") >= 0) {
                    this.iVersion = parseInt(navigator.appVersion.substr(navigator.appVersion.indexOf("MSIE") + 4), 10);
                } else {
                    this.iVersion = parseInt(navigator.appVersion.substr(navigator.appVersion.indexOf("rv:") + 3), 10);
                }
            } else if (navigator.userAgent.indexOf("Edge/") >= 0) {
                this.isEdge = true;
                this.iVersion = parseFloat(navigator.appVersion.substr(navigator.appVersion.indexOf("Edge/") + 5));
            } else if (navigator.userAgent.indexOf("Chrome") >= 0) {
                this.isChrome = true;
                this.iVersion = parseFloat(navigator.appVersion.substr(navigator.appVersion.indexOf("Chrome/") + 7));
            } else if (navigator.userAgent.indexOf("Safari") >= 0) {
                this.isSafari = true;
                this.iVersion = parseFloat(navigator.appVersion.substr(navigator.appVersion.indexOf("Version/") + 8));
            } else if (navigator.product === "Gecko") {
                this.isMoz = true;
                this.iVersion = parseFloat(navigator.userAgent.substr(navigator.userAgent.indexOf("Firefox/") + 8));
            } else if (navigator.userAgent.indexOf("Opera") >= 0) {
                this.isOpera = true;
                this.iVersion = parseFloat(navigator.appVersion);
            } else {  //  Default to IE if we don't know
                this.isIE = true;
                this.iVersion = parseInt(navigator.appVersion.substr(navigator.appVersion.indexOf("MSIE") + 4), 10);

                if (document.documentMode) {
                    this.iVersion = document.documentMode;
                }
            }
            /*
            Determine if this is a mobile device (tablet or mobile phone).
            */
            if (/Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/i.test(navigator.userAgent)) {
                this.isMobile = true;
            }
            if (/(iPad|iPhone|iPod)/g.test(navigator.userAgent)) {
                this.isIOS = true;
            }

            if (navigator.userAgent.indexOf("AppleWebKit") >= 0) {
                this.isWebkit = true;
            }


        }
    }
}

dev.detectDevice();