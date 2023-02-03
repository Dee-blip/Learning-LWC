({
    init: function(component, event, helper) {
        helper.showSpinnerHelper(component, event, helper);
        var action = component.get("c.getManualFieldsList");
        action.setCallback(this, function(response) {
            helper.hideSpinnerHelper(component, event, helper);
            var state = response.getState();
            var messageToShow = '';
            var toastType;
            if (state === "ERROR") 
            {
				helper.showToastMessage('Error!','Error!','Error!','error');                         
            }
            else if (state === "SUCCESS")
            {
                console.log('hashchange :' + window.location.href )
				var result =response.getReturnValue(); 
                result = JSON.parse(result);
                component.set("v.prefix",result.prefix);                
                console.log('recordType: ' + result.recordTypeId);                
                var createRecordEvent = $A.get("e.force:createRecord");

                createRecordEvent.setParams({
                    "entityApiName": "PS_Overage_Hours__c",
                    "recordTypeId": result.recordTypeId
                });
                createRecordEvent.fire();  
                
            }
            var dismissActionPanel = $A.get("e.force:closeQuickAction");            
			dismissActionPanel.fire();            
        });
        $A.enqueueAction(action);     

        
    },
    
    update : function(component, event, helper) {
		//var pageReference = component.get("v.pageReference");        
		var loc = window.location.href;
        if(loc.includes('recordTypeId') && loc.includes('new'))
        {
        	console.log('Modal OPEN');   
            component.set("v.wasOpen",true);
        }
        else if(loc.includes('new'))
        {
            console.log('Modal CLOSED');    
            if(component.get("v.wasOpen"))
            {
                var prefix = component.get("v.prefix");
                window.location.href = "/" + prefix + "/o";
                //var urlEvent = $A.get("e.force:navigateToURL");
                //var prefix = component.get("v.prefix");
                //console.log("prefix: " + prefix);
                //urlEvent.setParams({
                //  "url": "/" + prefix + "/o"
                //});  
                //urlEvent.fire();
                
            }
            
        }
        //console.log('loc :' + loc);
    }

})