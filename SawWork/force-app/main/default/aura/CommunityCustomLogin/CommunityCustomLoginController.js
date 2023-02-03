//Customer Community Component
({
	displayLogin : function(component, event, helper) {
        var loginForm = document.getElementsByClassName('salesforceIdentityLoginForm2');
        console.log(loginForm);
        loginForm[0].style.display = 'block';
        var loginOption = component.find('loginOption');
      	$A.util.addClass(loginOption, 'slds-hide');
        var mainArticle = component.find('mainArticle');
      	$A.util.removeClass(mainArticle, 'main-article');
        $A.util.addClass(mainArticle, 'main-article-guest-login');
	},
    
    SSOInitiation :function(component, event, helper) {
        var ssoUrl = component.get("v.ssoUrlUrl");
        if (ssoUrl == null) {
            ssoUrl = "https://iamakamai.sqaextranet.akamai.com/apps/auth/?spentityid=https://communityqa.akamai.com";
        }
        var attributes = { url: ssoUrl,isredirect: false };
        window.open(ssoUrl,'_self');
    }
    

})