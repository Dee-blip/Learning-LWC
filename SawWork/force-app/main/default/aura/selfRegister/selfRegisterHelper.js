({
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },
    
    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },
        
    handleSelfRegister: function (component, event, helper) {
        
        component.set("v.Spinner", true);
        var accountId = component.get("v.accountId");
        console.log("accountId "+accountId);
        var regConfirmUrl = component.get("v.regConfirmUrl");
        console.log("regConfirmUrl "+regConfirmUrl);
        var firstname = component.find("firstname").get("v.value");
        console.log("firstname "+firstname);
        var lastname = component.find("lastname").get("v.value");
        console.log("lastname "+lastname);
        var email = component.find("email").get("v.value");
        console.log("email "+email);
        var companyName = component.find("companyName").get("v.value");
        console.log("email "+companyName);
        var countryName = component.find("countryName").get("v.value");
        console.log("email "+countryName);
        var stateName = component.find("stateName").get("v.value");
        console.log("email "+stateName);
        var linkedIn = component.find("linkedIn").get("v.value");
        console.log("linkedIn "+linkedIn);
        var includePassword = component.get("v.includePasswordField");
        console.log("includePassword "+includePassword);
        var password = component.find("password").get("v.value");
        console.log("password "+password);
        var confirmPassword = component.find("confirmPassword").get("v.value");
        console.log("confirmPassword "+confirmPassword);
        var action = component.get("c.selfRegister");
        console.log("action "+action);
        var extraFields = JSON.stringify(component.get("v.extraFields"));
        console.log("extraFields "+extraFields);	// somehow apex controllers refuse to deal with list of maps
        var startUrl = component.get("v.startUrl");
        console.log("startUrl "+startUrl);
        
        //startUrl = decodeURIComponent(startUrl);
        
        action.setParams({firstname:firstname,lastname:lastname,email:email,linkedIn:linkedIn,companyName:companyName,countryName:countryName,stateName:stateName,
                password:password, confirmPassword:confirmPassword, accountId:accountId, regConfirmUrl:regConfirmUrl, extraFields:extraFields, startUrl:startUrl, includePassword:includePassword});
          action.setCallback(this, function(a){
          var rtnValue = a.getReturnValue();
          if (rtnValue !== null) {
             component.set("v.Spinner", false);
             component.set("v.showSuccess",false);
             component.set("v.errorMessage",rtnValue);
             component.set("v.showError",true);
    		
          }
          else{
              component.set("v.Spinner", false);
              component.set("v.showError",false);
              //component.set("v.successMessage","Your new account is waiting to be confirmed.");
              component.set("v.showSuccess",true);
              component.set("v.cancelButtonLabel",'Home');
              //component.set("v.isUserRegisterSuccessOpenModal", true);
              component.set("v.registerConfirmationText",true);
             // document.getElementsByClassName("forceCommunityRichTextInline")[0].style.display="none";
              /*var urlEvent = $A.get("e.force:navigateToURL");
    			urlEvent.setParams({
      			"url": '/CheckPasswordResetEmail',
                "isredirect": false
    		});*/
             // window.setTimeout($A.getCallback(function() {component.set("v.showSuccess",false);}),5000);
          }
              
       });
    $A.enqueueAction(action);
    },
    
    
    getExtraFields : function (component, event, helpler) {
        var action = component.get("c.getExtraFields");
        action.setParam("extraFieldsFieldSet", component.get("v.extraFieldsFieldSet"));
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.extraFields',rtnValue);
                console.log(rtnValue);
            }
        });
        $A.enqueueAction(action);
    },

    setBrandingCookie: function (component, event, helpler) {        
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ 
            	var rtnValue = a.getReturnValue();
                console.log(rtnValue);
            });
            $A.enqueueAction(action);
        }        
    },
    
	gotoURL : function (component, event, helper) {
    	var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      	"url": startUrl
    	});
    	urlEvent.fire();
	},
    
    cancelSelfRegisterHelper : function (component, event, helper){
        var cancelAction = component.get("c.getHomeNetworkURL");
        var homeUrl;
        cancelAction.setCallback(this, function(response){
       		var status = response.getState();
            console.log(status);
        	if(status === "SUCCESS"){
            	homeUrl = response.getReturnValue();
                window.open(homeUrl,'_top');
        	}
        });
        $A.enqueueAction(cancelAction);
    },
    
 
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isUserRegisterSuccessOpenModal", false);
      this.cancelSelfRegisterHelper(component, event, helper);
   },
    


})