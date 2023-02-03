({
    
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },

    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },
    
    handleLogin: function (component) {
        var username = component.find("username").get("v.value");
        var password = component.find("password").get("v.value");
        var action = component.get("c.login");
        var startUrl = component.get("v.startUrl");
        var urlEvent= null;
        
        startUrl = decodeURIComponent(startUrl);
        
        action.setParams({username:username, password:password, startUrl:startUrl});
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set("v.errorMessage",rtnValue);
                component.set("v.showError",true);
            }
        });
        $A.enqueueAction(action);
    },
    
    getIsUsernamePasswordEnabled : function (component) {
        var action = component.get("c.getIsUsernamePasswordEnabled");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isUsernamePasswordEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getIsSelfRegistrationEnabled : function (component) {
        var action = component.get("c.getIsSelfRegistrationEnabled");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isSelfRegistrationEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCommunityForgotPasswordUrl : function (component) {
        var action = component.get("c.getForgotPasswordUrl");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communityForgotPasswordUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCommunitySelfRegisterUrl : function (component) {
        var action = component.get("c.getSelfRegistrationUrl");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communitySelfRegisterUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },

    setBrandingCookie: function (component) {
        var expId = component.get("v.expid");
        var action = null;
        if (expId) {
            action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){
                console.log(a);
             });
            $A.enqueueAction(action);
        }        
    },
    handleSSO :function (component) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1));
        var sURLVariables = sPageURL.split('&startURL')[1];
        var action = component.get("c.getSSOURL");
        var rtnValue = null;
        var attributes = null;
        action.setParams({
                relayState:sURLVariables
            }
        );
        action.setCallback(this, function(a){
            rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                attributes= {url:rtnValue,isredirect:false};
                console.log(attributes);
                window.open(rtnValue,'_self');
            }
        });
        $A.enqueueAction(action);
    }
})