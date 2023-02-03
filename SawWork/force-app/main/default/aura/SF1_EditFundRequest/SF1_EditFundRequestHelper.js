({  
    hasEditingRights : function(cmp)
    {
        var action = cmp.get("c.hasEditingRights");
        action.setParams({
            "recordID" : cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var hasEditingRights = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.hasEditingRights",hasEditingRights);
                cmp.set("v.hasNoEditingRights",!hasEditingRights);
                
                
             }
            
        });
        $A.enqueueAction(action);
    },
    getPageObject : function(cmp)
    {
        var action = cmp.get("c.getPageObject");
        action.setParams({
            "recordID" : cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var pageObject = response.getReturnValue();
            console.log('pageObject :',pageObject);
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.pageObject",pageObject);
                cmp.set("v.SpenderValue",pageObject.Spender_Confirmed__c);
                cmp.set("v.ActivityType",pageObject.Program_Type__c);
                cmp.set("v.ActivitySpenderr",pageObject.Activity_Leader__c);
                cmp.set("v.SOEorPubSecEvent",pageObject.SOE_or_PubSec_Event__c);
            }
            
        });
        $A.enqueueAction(action);
    },
    saveTheObj : function(cmp)
    {
        var pageObject = cmp.get("v.pageObject");
        
        console.log("Page Object == "+ JSON.stringify(pageObject));
        
        var action = cmp.get("c.saveObj");
        action.setParams({
            "pageObject"  : pageObject
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var message = response.getReturnValue();
            var navEvt = $A.get("e.force:navigateToSObject");
            
            if (cmp.isValid() && state === "SUCCESS" && message==='success') 
            {   
                cmp.set("v.showError",false);
                navEvt.setParams({
                    "recordId": cmp.get("v.recordId"),
                    "slideDevName": "detail"
                });
                
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if(cmp.isValid() && state === "SUCCESS" && message!=='success')
            {
                cmp.set("v.message",message);
                cmp.set("v.showError",true);
            }
            
        });
        
        $A.enqueueAction(action); 
        
    },
    
    loadPickListValues : function(cmp)
    {
        var action1 = cmp.get("c.loadPickListValuesFromUtil");
        action1.setParams({
            "sobjectName" : "SFDC_MDF__c",
            "picklistFieldName":"Program_Type__c"
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.activityTypeOptions",options);
            }
            
        });
        
        var action2 = cmp.get("c.loadPickListValuesFromUtil");
        action2.setParams({
            "sobjectName" : "SFDC_MDF__c",
            "picklistFieldName":"Activity_Leader__c"
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.activitySpender",options);
            }
            
        });
        var action3 = cmp.get("c.loadPickListValuesFromUtil");
        action3.setParams({
            "sobjectName" : "SFDC_MDF__c",
            "picklistFieldName":"SOE_or_PubSec_Event__c"
        });
        action3.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.SOEValues",options);
            }
            
        });
        $A.enqueueAction(action1);
        $A.enqueueAction(action2);
        $A.enqueueAction(action3);
    }
})