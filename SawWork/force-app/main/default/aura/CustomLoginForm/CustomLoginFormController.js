//Customer Community Component
({
    initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();    
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap2}).fire();
        component.set("v.usernameLabel", $A.get("$Label.c.Jarvis_CustomLoginForm_Username"));
        component.set("v.passwordLabel", $A.get("$Label.c.Jarvis_CustomLoginForm_Password"));
        component.set("v.loginButtonLabel", $A.get("$Label.c.Jarvis_CustomLoginForm_LogInButton"));
        component.set("v.forgotPasswordLabel", $A.get("$Label.c.Jarvis_CustomLoginForm_ForgotPassword"));
        component.set("v.selfRegisterLabel", $A.get("$Label.c.Jarvis_CustomLoginForm_SelfRegister"));
        component.set('v.isUsernamePasswordEnabled', helper.getIsUsernamePasswordEnabled(component, event, helper));
        component.set("v.isSelfRegistrationEnabled", helper.getIsSelfRegistrationEnabled(component, event, helper));
        component.set("v.communityForgotPasswordUrl", helper.getCommunityForgotPasswordUrl(component, event, helper));
        component.set("v.communitySelfRegisterUrl", helper.getCommunitySelfRegisterUrl(component, event, helper));
        component.set("v.isSSOloginPage", true);
        component.set("v.goToRegisterPage", false);
    },
    
    handleLogin: function (component, event, helpler) {
        helpler.handleLogin(component, event, helpler);
    },
    
    setStartUrl: function (component, event, helpler) {
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
    
    navigateToForgotPassword: function(cmp, event, helper) {
        var forgotPwdUrl = cmp.get("v.communityForgotPasswordUrl");
        if ($A.util.isUndefinedOrNull(forgotPwdUrl)) {
            forgotPwdUrl = cmp.get("v.forgotPasswordUrl");
        }
        var attributes = { url: forgotPwdUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    navigateToSelfRegister: function(cmp, event, helper) {
        var selrRegUrl = cmp.get("v.communitySelfRegisterUrl");
        if (selrRegUrl == null) {
            selrRegUrl = cmp.get("v.selfRegisterUrl");
        }
    
        var attributes = { url: selrRegUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
	displayLogin: function(component, event, helper) {
        component.set("v.isSSOloginPage",false);
        component.set("v.goToRegisterPage", true);
        var loginOption = component.find('loginOption');
      	$A.util.addClass(loginOption, 'slds-hide');
        var mainArticle = component.find('mainArticle');
      	$A.util.removeClass(mainArticle, 'main-article');
        $A.util.addClass(mainArticle, 'main-article-guest-login');
	},
    
    SSOInitiation: function(component, event, helper) {
        helper.handleSSO(component, event, helper);
    }

})