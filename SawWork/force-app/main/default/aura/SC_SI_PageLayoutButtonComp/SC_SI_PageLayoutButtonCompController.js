({
    doInit: function(component, event, helper) {
        console.log('In aura refresh');
        
        component.set("v.showSpinner",true);
        
        var checkButtonVisibility = component.get("c.getButtonAccess");
        checkButtonVisibility.setParams({
            "SIrecordId": component.get("v.recordId")
        });
        
        checkButtonVisibility.setCallback(this, function(result)
                                          {
                                              if(result.getState() == 'SUCCESS'){
                                                  var res = JSON.parse(result.getReturnValue());
                                                  console.log('res in aura//'+JSON.stringify(res));
                                                  if(res.isIraptUser){
                                                      component.set("v.isIraptUser",true);
                                                  }
                                                  if(res.isCommunityAuthorized){
                                                      component.set("v.disableCommunity",false);
                                                  }
                                                  if(res.isAddproductAuthorized){
                                                      component.set("v.disableImpProds",false);
                                                  }
                                                  if(res.isTransitionAuthorized){
                                                      component.set("v.disableTransition",false);
                                                  }
                                                  if(res.isLinkCaseAuthorized){
                                                      component.set("v.disableAddCase",false);
                                                  }
                                                  if(res.isExtDependencyAuthorized){
                                                      component.set("v.disableExternalDep",false);
                                                  }
                                                  component.set("v.buttonLabel",res.communityButtonLabel);
                                                  component.set("v.incidentName",res.incidentName);
                                                  component.set("v.previousOwner",res.previousOwnerId);
                                                  component.set("v.showSpinner",false); 
                                                  
                                              }    
                                              else{
                                                  component.set("v.showSpinner",false);
                                              }
                                          });
        $A.enqueueAction(checkButtonVisibility);
        
    },
    
    handleClick : function(component, event, helper) {
        component.set("v.showModal",true);		
    },
    
    handleRefresh : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        component.set("v.showModal",false);
        component.set("v.showCommunityModal",false);
    },
    
    handleTransition  : function(component, event, helper) {
        component.set("v.showTransitionModal",true);		
    },
    
    handleCommunity :function(component, event, helper) {
        component.set("v.showCommunityModal",true);		
    },
    
    
    handleExternalDependency:function(component, event, helper) {
        var createRecordEventClone = $A.get("e.force:createRecord");
        createRecordEventClone.setParams({
            "entityApiName": "SC_SI_External_Dependency__c",
            "defaultFieldValues": {'Service_Incident__c':component.get("v.recordId")}
        });
        createRecordEventClone.fire();
    },
    handleAddCaseClick:function(component, event, helper) {
        component.set("v.showAddCaseModal",true);
    }    
    
    
})