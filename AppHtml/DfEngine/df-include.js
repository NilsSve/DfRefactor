/*
Legacy include file for the DataFlex JavaScript Engine. This file generates the script and CSS 
includes. Note that it is recommend to include df-min.js or df-debug.js directly in your HTML to 
increase performance. Browser vendors also reccommend against using document.write for security 
reasons.
*/



(function(){  
    var aScripts, sRoot = "", bMinified, bShowBuffer, sPreloadTheme, sIncludePath, sVersionId, sV;
    
    //  Note: The following line is parsed and checked by the studio
    sVersionId = "25.0.30.78";
    
    //  Determine current include location
    aScripts = document.getElementsByTagName("script");
    sIncludePath = aScripts[aScripts.length - 1].src;
    if(sIncludePath.indexOf('DfEngine/df-include.js') > 0){
        sRoot = sIncludePath.substr(0, sIncludePath.indexOf('DfEngine/df-include.js'));
    }
    //  Determine version GET parameter
    sV = "?v=" + sVersionId;
    
    //  Determine include variables
    sRoot = (typeof(sDfRootPath) === "string" && sDfRootPath) || sRoot;   //  Path to include files relative to
    bMinified = !((typeof(bDfDebug) === "boolean" && bDfDebug) || document.location.href.toLowerCase().indexOf('dfdebug=true') > 0); //  Minified or full version
    bShowBuffer = ((typeof(bDfShowBuffer) === "boolean" && bDfShowBuffer) || document.location.href.toLowerCase().indexOf('dfshowbuffer=true') > 0); //  Include buffer debuggin tools
    sPreloadTheme = (typeof(sDfPreloadTheme) === "string" && sDfPreloadTheme) || null;  //  Preload a theme or not
    
    if(typeof(sDfBuildNr) === "string" && sDfBuildNr){  //  Add a custom string to the version GET parameter of the URL
        sV += "." + sDfBuildNr;
    }
    
    //  Writes a single include statement using the proper path and version extension
    function includeJS(sPath, bModule){
        document.write('<script src="' + sRoot + 'DfEngine/' + sPath + sV + '"' + (bModule ? ' type="module"' : '') + '></script>');
    }
    
    //  Include CSS (optionally preload a theme)
    document.write('<link href="' + sRoot + 'DfEngine/system.css' + sV + '" rel="stylesheet" type="text/css" />');
    if(sPreloadTheme){
        document.write('<link href="' + sRoot + 'CssThemes/' + sPreloadTheme + '/theme.css' + sV + '" rel="stylesheet" type="text/css" />');
        document.write('<link href="' + sRoot + 'CssStyle/application.css' + sV + '" rel="stylesheet" type="text/css" />');
    }
    
    //  Switch between full and minified
    if(bMinified){
        includeJS('df-min.js', false);
    }else{
        includeJS('df-debug.js', false);
    }
    
    if(bShowBuffer){
        console.log("dfshowbuffer=true: this feature has been removed in this version of the DataFlex Engine.");
    }

    const aWaiters = [];

    class WebAppDummy{
        constructor(sOptWebService) {
            this.psWebService = sOptWebService || "WebServiceDispatcher.wso";
            this.pbXHRWithCredentials = false;
            this.pbViewApp = true;

            this.psDisplayApp = null;
        }

        displayApp(sElement){
            this.psDisplayApp = sElement;
        }

    }
}());
