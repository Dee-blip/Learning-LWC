({
/*
Author: Nikhil Karn
Date: 30th Oct, 2017
Details:
Last Modified By:
*/
    fireMe : function(component, event, helper){
        var currentDateAndTime= new Date();
        var action = component.get('c.addPageAudit');
        
        var nVer = navigator.appVersion;
        var nAgt = navigator.userAgent;
        var clientBrowserName  = navigator.appName;
        var fullVersion  = ''+parseFloat(navigator.appVersion); 
        var majorVersion = parseInt(navigator.appVersion,10);
        var nameOffset,verOffset,ix;
        
        // In Opera 15+, the true version is after "OPR/" 
        if ((verOffset=nAgt.indexOf("OPR/"))!=-1) {
            clientBrowserName = "Opera";
            fullVersion = nAgt.substring(verOffset+4);
        }
        // In older Opera, the true version is after "Opera" or after "Version"
        else if ((verOffset=nAgt.indexOf("Opera"))!=-1) {
            clientBrowserName = "Opera";
            fullVersion = nAgt.substring(verOffset+6);
            if ((verOffset=nAgt.indexOf("Version"))!=-1) 
                fullVersion = nAgt.substring(verOffset+8);
        }
        // In MSIE, the true version is after "MSIE" in userAgent
            else if ((verOffset=nAgt.indexOf("MSIE"))!=-1) {
                clientBrowserName = "Microsoft Internet Explorer";
                fullVersion = nAgt.substring(verOffset+5);
            }
        // In Chrome, the true version is after "Chrome" 
                else if ((verOffset=nAgt.indexOf("Chrome"))!=-1) {
                    clientBrowserName = "Chrome";
                    fullVersion = nAgt.substring(verOffset+7);
                }
        // In Safari, the true version is after "Safari" or after "Version" 
                    else if ((verOffset=nAgt.indexOf("Safari"))!=-1) {
                        clientBrowserName = "Safari";
                        fullVersion = nAgt.substring(verOffset+7);
                        if ((verOffset=nAgt.indexOf("Version"))!=-1) 
                            fullVersion = nAgt.substring(verOffset+8);
                    }
        // In Firefox, the true version is after "Firefox" 
                        else if ((verOffset=nAgt.indexOf("Firefox"))!=-1) {
                            clientBrowserName = "Firefox";
                            fullVersion = nAgt.substring(verOffset+8);
                        }
        // In most other browsers, "name/version" is at the end of userAgent 
                            else if ( (nameOffset=nAgt.lastIndexOf(' ')+1) < 
                                     (verOffset=nAgt.lastIndexOf('/')) ) 
                            {
                                clientBrowserName = nAgt.substring(nameOffset,verOffset);
                                fullVersion = nAgt.substring(verOffset+1);
                                if (clientBrowserName.toLowerCase()==clientBrowserName.toUpperCase()) {
                                    clientBrowserName = navigator.appName;
                                }
                            }
        // trim the fullVersion string at semicolon/space if present
        if ((ix=fullVersion.indexOf(";"))!=-1)
            fullVersion=fullVersion.substring(0,ix);
        if ((ix=fullVersion.indexOf(" "))!=-1)
            fullVersion=fullVersion.substring(0,ix);
        
        majorVersion = parseInt(''+fullVersion,10);
        
        if (isNaN(majorVersion)) {
            fullVersion  = ''+parseFloat(navigator.appVersion); 
            majorVersion = parseInt(navigator.appVersion,10);
        }
        
        clientBrowserName=clientBrowserName.toString();
        majorVersion=majorVersion.toString();
        action.setParams({
            incident:component.get('v.incident'),
            pageName:component.get('v.pageName'),
            pageVisitTime:currentDateAndTime,
            pageUrl:window.location.href,
            browserName:clientBrowserName,
            browserVersion:majorVersion
        });
        action.setCallback(this,function(resp){});
        $A.enqueueAction(action);
    }
})