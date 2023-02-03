({
    setValues: function (component) {
        component.set('v.options','');
        let caseStatus = component.get("v.caseObject").Status;
        let caseProblem = component.get("v.caseObject").Problem__c;
        let options = [];
        if(caseStatus !== 'Closed'){
            options.push('Close Case');
        }
        if(caseProblem === 'Technicians'){
            options.push('Escalate Case');
        }  
        component.set('v.options',options);      
    },
    escalateCase: function(component, event, helper) {
        
        component.set("v.spinner",true);
        let actionSelected = component.find("actionId").get("v.value");
        
        if(actionSelected === 'Escalate Case'){
            component.set("v.simpleRecord.Problem__c","Specialist");
            component.set("v.uniqueIdentifier", component.get("v.recordId")+'-Case Escalation');
        }    
        else if(actionSelected === 'Close Case'){
            component.set("v.simpleRecord.Status","Closed");
            component.set("v.uniqueIdentifier", component.get("v.recordId")+'-Case Close');
        }
        component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                helper.showToast('Success', 'Case Saved Successfully.');
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
                helper.showToast('Error', 'User is offline, device do not support drafts.');
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: '+JSON.stringify(saveResult.error[0].message));
                helper.showToast('Error', 'Problem saving record, error: '+JSON.stringify(saveResult.error[0].message));
                component.set("v.spinner",false);
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error[0].message));
                helper.showToast('Error', 'Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error[0].message));
            }
            helper.checkLogStatus(component,helper);
        }));
    },
    
    closeEscalateCase: function() {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})