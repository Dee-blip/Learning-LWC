({
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },
    
    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },

    getCountryList: function (component) {
        var action = component.get("c.getCountryPicklistVal");
        action.setCallback(this, function(a){
          var rtnValue = a.getReturnValue();
          if (rtnValue !== null) {
              component.set('v.countryPicklist', rtnValue.sort());
          }  
       });
    $A.enqueueAction(action);
    },
    
    handleSelfRegister: function (component) {
        var firstname = component.find("firstname").get("v.value");
        var lastname = component.find("lastname").get("v.value");
        var email = component.find("email").get("v.value");
        var companyName = component.find("companyName").get("v.value");
        var countryName = component.find("cntryPicklist").get("v.value");
        //var countryName = component.find("countryName").get("v.value");
        /*var stateName ='';
        if (!(countryName === 'USA' || countryName === 'Canada')) {
            stateName = component.find("stateName").get("v.value");
        }*/
        var action = component.get("c.selfRegister");
        var extraFields = JSON.stringify(component.get("v.extraFields"));
        var startUrl = component.get("v.startUrl");
        console.log(extraFields);
        console.log(startUrl);
        component.set("v.Spinner", true);
        //startUrl = decodeURIComponent(startUrl);
        action.setParams({firstname:firstname,lastname:lastname,email:email,companyName:companyName,countryName:countryName});
          action.setCallback(this, function(a){
          var rtnValue = a.getReturnValue();
          if (rtnValue !== null) {
            component.set("v.Spinner", false);
            component.set("v.showSuccess",false);
            if (rtnValue.includes('Please enter a valid state for the selected country.')) {
                component.set("v.errorMessage",'Please enter a valid state for the country.');
            } else if (rtnValue.includes('Please enter a valid country')) {
                component.set("v.errorMessage",'Please enter a valid country');
            } else if (rtnValue.includes('INVALID_EMAIL_ADDRESS')) {
                component.set("v.errorMessage",'Failed to register. Email address is not valid.');
            } else {
                component.set("v.errorMessage",'Failed to register. Please try again.' + rtnValue);
            }
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
    
    
    getExtraFields : function (component) {
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

    setBrandingCookie: function (component) {        
        var expId = component.get("v.expid");
        var action = null;
        if (expId) {
            action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){
                var rtnValue = a.getReturnValue();
                console.log(rtnValue);
            });
            $A.enqueueAction(action);
        }        
    },
    /*
	gotoURL : function () {
        var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({"url": startUrl});
    	urlEvent.fire();
	},*/
    
    cancelSelfRegisterHelper : function (component){
        var cancelAction = component.get("c.getHomeNetworkURL");
        var homeUrl;
        var status = null;
        cancelAction.setCallback(this, function(response){
            status=response.getState();
            console.log(status);
            if(status==="SUCCESS"){
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