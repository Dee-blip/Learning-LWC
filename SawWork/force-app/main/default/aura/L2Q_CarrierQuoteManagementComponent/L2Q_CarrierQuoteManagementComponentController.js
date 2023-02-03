({
	doBack: function(component, event, helper)
    {
        var redirectURL =  component.get("v.recordId");
        var myUserTheme= component.get('v.userTheme');
        console.log('user theme in back button'+myUserTheme);
        helper.redirectTo(component, redirectURL, myUserTheme, false);
    },
    handleSaveOrCancel: function(component, event, helper)
    {
        helper.startSpinner(component);
        console.log('in handleSave');
        var value = event.getParam("param");
        console.log(value);
        if(value=="Accept")
            helper.createAccount(component);
        else if(value=="Cancel"){
            var redirectURL =  component.get("v.recordId");
        	var myUserTheme= component.get('v.userTheme');
	        console.log(value);    
            helper.redirectTo(component, redirectURL, myUserTheme, false);
        }
    }
})