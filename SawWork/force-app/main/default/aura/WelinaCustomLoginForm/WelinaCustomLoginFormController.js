//Customer Community Component
({
    initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();    
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap2}).fire();
        component.set('v.isUsernamePasswordEnabled', helper.getIsUsernamePasswordEnabled(component, event, helper));
        component.set("v.isSelfRegistrationEnabled", helper.getIsSelfRegistrationEnabled(component, event, helper));
        component.set("v.communityForgotPasswordUrl", helper.getCommunityForgotPasswordUrl(component, event, helper));
        component.set("v.communitySelfRegisterUrl", helper.getCommunitySelfRegisterUrl(component, event, helper));
        component.set("v.isSSOloginPage", false);
        component.set("v.goToRegisterPage", true);
    },
    
    handleLogin: function (component, event, helpler) {
        helpler.handleLogin(component, event, helpler);
    },
    
    setStartUrl: function (component, event) {
        var startUrl = event.getParam('startURL');
        if(startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },
    
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    
    onKeyUp: function(component, event, helpler){
        //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helpler.handleLogin(component, event, helpler);
        }
    },
    
    navigateToForgotPassword: function(cmp) {
        var forgotPwdUrl = cmp.get("v.communityForgotPasswordUrl");
        var attributes = { url: forgotPwdUrl };
        if ($A.util.isUndefinedOrNull(forgotPwdUrl)) {
            forgotPwdUrl = cmp.get("v.forgotPasswordUrl");
        }
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    navigateToSelfRegister: function(cmp) {
        var selrRegUrl = cmp.get("v.communitySelfRegisterUrl");
        var attributes = { url: selrRegUrl };
        if (selrRegUrl == null) {
            selrRegUrl = cmp.get("v.selfRegisterUrl");
        }
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
	displayLogin: function(component) {
        var loginOption = component.find('loginOption');
        var mainArticle = component.find('mainArticle');
        component.set("v.isSSOloginPage",false);
        component.set("v.goToRegisterPage", true);
        $A.util.removeClass(mainArticle,'main-article');
        $A.util.addClass(mainArticle,'main-article-guest-login');
        $A.util.addClass(loginOption,'slds-hide');
	},
    
    SSOInitiation: function(component, event, helper) {
        helper.handleSSO(component, event, helper);
    }

})