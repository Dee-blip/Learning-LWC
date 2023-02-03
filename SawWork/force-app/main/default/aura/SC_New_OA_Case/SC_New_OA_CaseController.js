({
	doInit : function(component, event, helper) {
        var currentRecObject = component.get("v.sObjectName");
        if(currentRecObject == 'Approval_Details__c')
        {
            component.set("v.Spinner",true);
            if(component.get("v.showPopup"))
                component.set("v.showPopup",false);
            
            var EscAccess = component.get("c.checkEscalationAccess");
            EscAccess.setCallback(this, function(EscAccessResponse){
                if(EscAccessResponse.getReturnValue()){
                    component.set("v.showRTSelection",true);
                    var ADAction = component.get("c.fetchParentCaseId");
                    ADAction.setParams({
                        "ADId": component.get("v.recordId")
                    });
                    ADAction.setCallback(this, function(ADResponse){
                        var ADRecName = ADResponse.getReturnValue().Name;
                        var ADRecId = ADResponse.getReturnValue().Related_To__c;
                        var ADCaseRT = ADResponse.getReturnValue().Related_To__r.RecordType.DeveloperName;
                        if(ADCaseRT == 'Order_Approval_Deal_Desk' || ADCaseRT == 'Order_Approval_Legal')
                        	helper.escalateCase(component,ADRecId,ADRecName);
                        else{
                            component.set("v.Spinner",false);
                            if(!component.get("v.showPopup"))
                                component.set("v.showPopup",true);
                            component.set("v.showRTSelection",false);
                            component.set("v.escalationErrorMessage","This case can not be escalated");
                        }
                            
                    });
                    $A.enqueueAction(ADAction); 
                }
                else{
                    component.set("v.Spinner",false);
                    if(!component.get("v.showPopup"))
                        component.set("v.showPopup",true);
                    component.set("v.showRTSelection",false);
                    component.set("v.escalationErrorMessage","Oops.. Insufficient Access to Escalate a case");
                }
            });
            $A.enqueueAction(EscAccess);
        }
        else
        {
            component.set("v.showRTSelection",true);
            component.set("v.Spinner",false);
            if(!component.get("v.showPopup"))
                component.set("v.showPopup",true);
            var action = component.get("c.getOARecordTypes");
            var rtOrderList = ["Order Approval-Order Management", "Order Approval-Deal Desk", "Order Approval-Legal", "Order Approval-Sales Manager", "Order Approval-Others"];
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    var result = response.getReturnValue();
                    var rtMap = [];
                    for(var i = 0; i < rtOrderList.length; i++){
                        for(var key in result){
                            if(result[key] == rtOrderList[i]){
                                rtMap.push({value: key, label: result[key]})
                            }
                        }
                    }
                    if(rtMap.length > 0){
                        component.set("v.recordTypeMap", rtMap);
                    	component.set("v.defaultRecordType", rtMap[0].value);
                    }
                    else{
                        component.set("v.Spinner",false);
                        if(!component.get("v.showPopup"))
                            component.set("v.showPopup",true);
                        component.set("v.showRTSelection",false);
                        component.set("v.escalationErrorMessage","Oops.. Insufficient Access to Create a case");
                        var errorTarget = component.find('errorMsgId');
                        $A.util.addClass(errorTarget, 'changePadding');
                    }
                }
                else if(state === "ERROR"){
                    var errors = response.getError();
                    var errorMessage = errors[0].message;
                    helper.showToastMessage(component, event, helper,'Error',errorMessage,'error','dismissible');
                }
                    else
                        helper.showToastMessage(component, event, helper,'Error','Something went wrong! Please try again!','error','dismissible');
            });
            $A.enqueueAction(action); 
        }
	},
    
    createCase : function(component, event, helper){
        //Selected RecordType
    	var selectedRecordType = component.find("recordType").get("v.value");
        var assignUsingRule = false;
        component.get("v.recordTypeMap")[0].value
        for(var i = 0; i < component.get("v.recordTypeMap").length; i++){
            if(selectedRecordType == component.get("v.recordTypeMap")[i].value){
                if(component.get("v.recordTypeMap")[i].label == 'Order Approval-Deal Desk'
                   || component.get("v.recordTypeMap")[i].label == 'Order Approval-Legal'
                   || component.get("v.recordTypeMap")[i].label == 'Order Approval-Order Management'){
                    assignUsingRule = true;
                }
            }
        }
        
        if(assignUsingRule){
            component.set("v.Spinner",true);
            helper.createOAStdCase(component,event,helper,assignUsingRule,selectedRecordType)
        }
        else{
            helper.createOAOthersCase(component,event,helper,assignUsingRule,selectedRecordType)
        }
        //OA recordId
        /*var OARecId = component.get("v.recordId");
        
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
            else if(state === "ERROR"){
                var errors = response.getError();
                var errorMessage = errors[0].message;
                helper.showToastMessage(component, event, helper,'Error',errorMessage,'error','dismissible');
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Something went wrong! Please try again!','error','dismissible');
        });
        $A.enqueueAction(OAaction);*/
	},
    
    closeModal : function(component, event, helper){
    	var closeQuickAction = $A.get("e.force:closeQuickAction");
    	closeQuickAction.fire();
	}
})