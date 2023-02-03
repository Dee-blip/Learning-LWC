({
	/*helperMethod : function() {
		
	}*/
    
    
    toggle: function (cmp, event) {
        var spinner = cmp.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    }
    
    /*navigate : function (component,event) {
        console.log("Inside helper");
        console.log(component);
        
        var urlEvent = $A.get("e.force:navigateToURL");
        
        console.log("Redirecting now");
        var fcId = component.get("v.fundClaimId");
        var url = 'https://akamai--sfdcmay.cs3.my.salesforce.com/'+fcId;
        console.log(url);
        
        urlEvent.setParams({
          "url": url
        });
        console.log("Firing url event now");
        urlEvent.fire();
	}*/
    
    /*createRecord : function (component, event) {
        var navEvt = $A.get("e.force:navigateToSObject");
        var fcId = component.get("v.fundClaimId");
        navEvt.setParams({
          "recordId": fcId,
          "slideDevName": "related"
        });
        navEvt.fire();
	}*/
    
    
    
    /*navigate : function(component, event, helper) {

    //Find the text value of the component with aura:id set to "address"
    var address = component.find("address").get("v.value");

    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": '/' + +component.get(v.fundClaimId);
    });
    urlEvent.fire();
	}*/
    
    
})