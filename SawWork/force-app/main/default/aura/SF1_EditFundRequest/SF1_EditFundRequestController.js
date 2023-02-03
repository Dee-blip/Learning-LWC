({
    doInit : function(cmp, event, helper) {
        helper.hasEditingRights(cmp);
        helper.getPageObject(cmp);
        helper.loadPickListValues(cmp);
    },
    
    goBackToRecord : function(cmp, event, helper) {
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": cmp.get("v.recordId"),
            "slideDevName": 'detail'
        })
        
        sObjectEvent.fire();
    },
    
    
    saveFundObj : function(cmp, event, helper) 
    {  
        helper.saveTheObj(cmp);
        
    },
    changeSelection : function(component, event, helper) 
    {
        var selection = component.find("selectionActivity").get("v.value");
        if(selection == null)
        {
            selection = component.get("v.pageObject").Program_Type__c;
            
        }
        else {
            component.set("v.pageObject.Program_Type__c", selection);
        }
        
        
    },
    changeSelectionActivitySpender: function(component, event, helper) 
    {
        var selection = component.find("selection").get("v.value");
        if(selection == null)
        {
            selection = component.get("v.pageObject").Activity_Leader__c;
            
        }
        else {
            component.set("v.pageObject.Activity_Leader__c", selection);
        }
        
        
    },
    changeSelectionSOE: function(component, event, helper) 
    {
        var selection = component.find("selectionSOE").get("v.value");
        if(selection == null)
        {
            selection = component.get("v.pageObject").SOE_or_PubSec_Event__c ;
            
        }
        else {
            component.set("v.pageObject.SOE_or_PubSec_Event__c", selection);
        }
        
        
    },
    changeSelectionSpender: function(component, event, helper) 
    {
        var selection = component.find("spenderId").get("v.value");
        console.log('selection :',selection);
        if(selection == null)
        {
            selection = component.get("v.pageObject").Spender_Confirmed__c ;
            
        }
        else {
            component.set("v.pageObject.Spender_Confirmed__c", selection);
        }
        
        
    },
    showSpinner: function(component, event, helper) {
        if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "block";
        } 
    },
    
    hideSpinner : function(component,event,helper){
        if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "none";
        }
    }
})