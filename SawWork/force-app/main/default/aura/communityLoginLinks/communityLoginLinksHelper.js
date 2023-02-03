({
    openLearnAkamai : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://learn.akamai.com/"
        });
        urlEvent.fire();
    },
    
    openAkamaidotCom : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://www.akamai.com/"
        });
        urlEvent.fire();
    },
    
    goToHome : function(component, event, helper) {
        console.log('event'+event);
		var getUrl = component.get("c.getNetworkURL");
        var supportUrl;
        console.log('getUrl'+getUrl);
        getUrl.setCallback(this, function(response){
            var status = response.getState();
            if(status === "SUCCESS"){
                supportUrl = response.getReturnValue();
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": supportUrl
                });
                urlEvent.fire();
            }
        });
        $A.enqueueAction(getUrl);
    },
    
    openCommunityHelp : function(component, event, helper) {
        var getUrl = component.get("c.getNetworkURL");
        var supportUrl;
        getUrl.setCallback(this, function(response){
            var status = response.getState();
            if(status === "SUCCESS"){
                supportUrl = response.getReturnValue();
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": supportUrl+"community-help"
                });
                urlEvent.fire();
            }
        });
        $A.enqueueAction(getUrl);
    },
    
    toggle : function(component, event, helper) {
        var toggleText = component.find("btnMenuList");
        $A.util.toggleClass(toggleText, "toggle");
    },
    
    doInit: function(component,event, helper) {
    }
})