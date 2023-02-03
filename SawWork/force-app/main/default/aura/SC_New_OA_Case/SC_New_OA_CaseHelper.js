({
    //Generic Toast Message body
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    createOAOthersCase : function(component, event, helper,assignUsingRule,selectedRecordType) {
        //OA recordId
        var OARecId = component.get("v.recordId");
        
        var OAaction = component.get("c.fetchOADetails");
        OAaction.setParams({
            "OAId": OARecId
        });
        OAaction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var selectedOA  = response.getReturnValue();
                var accId = selectedOA.Associated_Opportunity__r.AccountId;
                var oppId = selectedOA.Associated_Opportunity__c;
                
                //Open case creation page
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Case",
                    "recordTypeId": selectedRecordType,
                    "defaultFieldValues": {
                        'Order_Approval__c' : OARecId,
                        'AccountId': accId,
                        'Opportunity__c': oppId,
                        'Case_Assignment_Using_Active_Rules__c': assignUsingRule
                    }
                });
                createRecordEvent.fire();
            }
            else if(response.getState() === "ERROR"){
                var errors = response.getError();
                var errorMessage = errors[0].message;
                helper.showToastMessage(component, event, helper,'Error',errorMessage,'error','dismissible');
                component.set("v.Spinner",false);
                var closeQuickAction = $A.get("e.force:closeQuickAction");
                closeQuickAction.fire();
            }
                else
                    helper.showToastMessage(component, event, helper,'Error','Something went wrong! Please try again!','error','dismissible');
        });
        $A.enqueueAction(OAaction);
    },
    createOAStdCase : function(component, event, helper,assignUsingRule,selectedRecordType) {
         //OA recordId
        var OARecId = component.get("v.recordId");
        
        var OAaction = component.get("c.createOACase");
        OAaction.setParams({
            "OAId": OARecId,
            "caseRecordType": selectedRecordType,
            "isAssignUsingRule": assignUsingRule
        });
        OAaction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": response.getReturnValue().Id,
                    "slideDevName": "related"
                    
                });
                navEvt.fire();
                helper.showToastMessage(component, event, helper,'Success','Case Created Successfully!','Success','dismissible');
            	component.set("v.Spinner",false);
            }
            else if(response.getState() === "ERROR"){
                var errors = response.getError();
                var errorMessage = errors[0].message;
                component.set("v.Spinner",false);
                var closeQuickAction = $A.get("e.force:closeQuickAction");
                closeQuickAction.fire();
                helper.showToastMessage(component, event, helper,'Error',errorMessage,'error','dismissible');
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Something went wrong! Please try again!','error','dismissible');
        });
        $A.enqueueAction(OAaction);
    },
    escalateCase: function(component, recId, recName) {
        var accId = null;
        var oppId = null;
        var oaId = null;
        var parentCaseId = recId;
        var caseAction = component.get("c.fetchCaseDetails");
        caseAction.setParams({
            "caseRecordId": parentCaseId
        });
        caseAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var parentCase  = response.getReturnValue();
                accId = parentCase.AccountId;
                oppId = parentCase.Opportunity__c;
                oaId = parentCase.Order_Approval__c;
                
                var ESCaction = component.get("c.fetchRecTypeId");
                ESCaction.setParams({
                    "recordTypeLabel": 'Order Approval-Escalations'
                });
                ESCaction.setCallback(this, function(response) {
                    if (response.getState() === "SUCCESS") {
                        var escalationRTId = response.getReturnValue();
                    }
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": "Case",
                        "recordTypeId": escalationRTId,
                        "defaultFieldValues": {
                            'ParentId' : parentCaseId,
                            'AccountId': accId,
                            'Opportunity__c': oppId,
                            'Order_Approval__c' : oaId,
                            'Approval_Detail_ID__c': recName
                        },
                    });
                    createRecordEvent.fire();
                });
                $A.enqueueAction(ESCaction);
            }
        });
        $A.enqueueAction(caseAction);
    },
})