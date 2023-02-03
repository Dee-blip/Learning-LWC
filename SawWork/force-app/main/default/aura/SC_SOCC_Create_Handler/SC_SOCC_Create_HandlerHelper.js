({
    componentToastHandler: function(component, title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            type: type
        });
        toastEvent.fire();
    },
    
    setTabName: function(component, event, helper, tabHeading) {
        //Setting the tab name and icon
        let workspaceAPI = component.find("workspace");
        window.setTimeout(
            $A.getCallback(function() {
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    let focusedTabId = response.tabId;
                    workspaceAPI.setTabLabel({
                        tabId: focusedTabId,
                        label: tabHeading //set label you want to set
                    });
                    workspaceAPI.setTabIcon({
                        tabId: focusedTabId,
                        icon: "utility:adduser", //set icon you want to set
                        iconAlt: tabHeading //set label tooltip you want to set
                    });
                });
            }),
            500
        );
    },
    
    closeFocusedTab: function(component, event, helper, HandlerId) {
        console.log("#/Handler__c/" + HandlerId + "/view");
        var workspaceAPI = component.find("workspace");
        var navigatorApi = component.find("navService");
        workspaceAPI
        .getFocusedTabInfo()
        .then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId}).then(function(){
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId":HandlerId
                });
                navEvt.fire();
                
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    prePopulatePolicyDomain:function(component, event, helper, pdId)
    {
        let action = component.get('c.getPolicyDomainRecord');
        action.setParams({
            "pdID":pdId
        });
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                component.set('v.selectedPolicyDomainRecord',response.getReturnValue());
                component.set('v.selectedPolicyDomainRecordId',response.getReturnValue().Id);
            }
        });
        $A.enqueueAction(action);
    },
    showHideInstructions:function(component,fieldstoshowarray) 
    {
        let childCompRef = component.find('escChild');
        if(fieldstoshowarray.includes("Escalation_List__c"))
        {
            component.set("v.showEscalationContacts",true);
            $A.util.removeClass(childCompRef, 'slds-hide');          
            $A.util.addClass(childCompRef, 'slds-show');
        }
        else
        {   
            component.set("v.showEscalationContacts",false);
            $A.util.removeClass(childCompRef, 'slds-show');
            $A.util.addClass(childCompRef, 'slds-hide');
            component.set('v.selectedEscalationListRecord',{});
            
        }      
        //Situation Instruction
        if(fieldstoshowarray.includes("Situation_Instruction__c"))
        {
            component.set('v.showSituationInstruction',true);
        }
        else
        {
            component.set('v.showSituationInstruction',false);
            component.set('v.suggestedSituationInstruction','');
        }
        
        //Ignore Condition
        if(fieldstoshowarray.includes("Ignore_Condition__c"))
        {
            component.set('v.showIgnoreCondition',true);
        }
        else
        {
            component.set('v.showIgnoreCondition',false);
            component.set('v.suggestedIgnoreCondition','');
        }                 
    }
});