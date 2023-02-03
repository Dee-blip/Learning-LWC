({
    acceptCaseButton : function(component, event, helper){
        var isConfirmed = confirm("Are you sure you want to accept this request?");
        //if confirmed changing the Escalation owner
        if(isConfirmed){
            component.set("v.Spinner", true);
            //calling the method
            var action = component.get("c.acceptCase");
            action.setParams({
                "escId": component.get("v.recordId")
            });
            action.setCallback(this, function(response){
                var retVal = response.getReturnValue();
                if(retVal == 'success'){
                    helper.showToastMessage(component, event, helper,'Success','Request Successfully Accepted!','success','dismissible');
                    $A.get('e.force:refreshView').fire();
                }
                else
                    helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
                component.set("v.Spinner", false);
            });
            $A.enqueueAction(action);
            
        }
    },
    
    reject : function(component, event, helper) {
        component.set("v.isOpenRejectEdit", true);
    },
    
    saveRejectEsc : function(component, event, helper) {
        var rejectReasons = component.find('reject-reason').get('v.value');
        component.set("v.isOpenRejectEdit", false);
        component.set("v.Spinner", true);
        
        var action = component.get("c.rejectEscalation");
        action.setParams({
            "escId": component.get("v.recordId"),
            "rejectReason":rejectReasons
        });
        
        action.setCallback(this, function(response) {
            var retVal = response.getReturnValue();
            if (retVal === "success") {
                helper.showToastMessage(component, event, helper,'Success','Saved Successfully!','success','dismissible');
                $A.get('e.force:refreshView').fire();
            }
            else
                helper.showToastMessage(component, event, helper,'Error',retVal,'error','dismissible');
            component.set("v.Spinner", false);
        });
        $A.enqueueAction(action);   
    },
    
    closeRejectModal : function(component, event, helper) {
        component.set("v.isOpenRejectEdit", false);
    },
    
    addLOE : function(component, event, helper) {
        var action = component.get("c.getParentCaseId");
        action.setParams({
            "escId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var caseId = response.getReturnValue();
                //creating new Task for parent case
                var createTaskEvent = $A.get("e.force:createRecord");
                createTaskEvent.setParams({
                    "entityApiName": "Task",
                    "defaultFieldValues": {
                        'WhatId' : caseId,
                        'RecordTypeId' : '012G0000000z117IAA'
                    }
                });
                createTaskEvent.fire();
            }
            else{
                helper.showToastMessage(component, event, helper,'Error','Oops! Something went wrong, please try again!','error','dismissible');
            }
        });
        $A.enqueueAction(action); 
    },
    
    newExternalTeam : function(component, event, helper){
        var action = component.get("c.getEscDetails");
        action.setParams({
            "escId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var escRec = JSON.parse(response.getReturnValue());
            if(state === "SUCCESS"){
                var caseId = escRec["caseId"];
                var caseNumber = escRec["caseNumber"];
                var recordTypeId = escRec["recordTypeId"];
                $A.get("e.force:navigateToURL").setParams({
                    "url": '/apex/sc_escalationextteam?RecordType=' + recordTypeId + '&CF00NG000000A1cSF=' + caseNumber + '&CF00NG000000A1cSF_lkid=' + caseId,
                    "isredirect": true
                }).fire();
            }
            else{
                helper.showToastMessage(component, event, helper,'Error','Oops! Something went wrong, please try again!','error','dismissible');
            }
        });
        $A.enqueueAction(action); 
    }
})