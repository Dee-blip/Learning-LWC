({
    doInit : function(component, event, helper) {
        
        component.set("v.createFromCaseId", component.get("v.recordId"));
        helper.callServer(
            component,
            "c.getCaseRecType",
            function(response){
                var returnVal = response;
                var finalRecList = [];
                for(var i=0; i<returnVal.length; i++){
                    var recList = {'label': returnVal[i] , 'value' : returnVal[i]};
                    finalRecList.push(recList);
                }  
                component.set("v.caseRecTypes", finalRecList);
            });
            //ESESP-4265, get case record and check if clone peer button should be visible
            helper.callServer(
                component,
                "c.getCaseFields",
                function(response){
                    var result = response;
                    if(result && result.Service__c === 'Contract Management' && ( result.Request_Type__c === 'Contract Migration' || result.Request_Type__c === 'Service Migration') && result.Request_Sub_Type__c === 'Migration' && result.IsClosed === false){
                        component.set('v.showPeerReviewClone', true);
                    } else {
                        component.set('v.showPeerReviewClone', false);
                    }
                },{
                    "caseId": component.get("v.recordId")
                });
    },
    //ESESP-4265, peer review clone button logic
    peerReviewCloneJS:function(component, event, helper) {
        
        helper.callServer(
            component,
            "c.peerReviewClone",
            function(result)
            {
                var caseRecMap = result;
                var recTypeId;
                var caseRecValues;
                var createRecordEventClone;
                var key;
                for(key in caseRecMap){
                    if(key){
                        recTypeId = key;
                        caseRecValues = caseRecMap[key]; 
                    }
                    
                }
                createRecordEventClone = $A.get("e.force:createRecord");
                createRecordEventClone.setParams({
                    "entityApiName": "Case",
                    "recordTypeId": recTypeId,
                    "defaultFieldValues": caseRecValues
                });
                createRecordEventClone.fire();
                //component.set("v.relCaseButton", false);
            },
            {
                "caseId": component.get("v.recordId")
                
            }
        );
    },

    
    showRelCaseCmp : function(component, event, helper) {
        component.set("v.relCaseButton", true);		
    },
    
    handleChange:function(component, event, helper) {
        component.set("v.selectedRecType", event.getParam("value"));
    },
    
    
    closeModal : function(component, event, helper)
    {
        component.set("v.relCaseButton", false);
        
    },
    
    
    spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    },
    
    cloneSingle: function(component, event, helper)   
    {
        component.set("v.showSingleClone", true);
    },
    cloneMulti: function(component, event, helper)   
    {
        component.set("v.showMultiClone", true);
        helper.openCaseCloneTab(component, event, helper);
    },
    
    reopenCase: function(component, event, helper)   
    {
        helper.callServer(
            component,
            "c.reopenClosedCase",
            function(response){
                var errMsg = response;
                if(errMsg != null){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "Error",
                        "message": errMsg
                    });
                    toastEvent.fire();
                }
               if(errMsg == ''){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "Success",
                        "message": "The Case record has been updated successfully."
                    });
                    toastEvent.fire();
                    
                }
                $A.get('e.force:refreshView').fire();
                
            },{
                "caseId": component.get("v.recordId"),
            });    
    },
    
    childCase:function(component, event, helper) {
        var selectedRadioOption = component.get("v.selectedRecType");
        
        helper.callServer(
            component,
            "c.createChildcase",
            function(result)
            {
                var caseRecMap = result;
                for(var key in caseRecMap){
                    var recTypeId = key;
                    var caseRecValues = caseRecMap[key]; 
                }
                var createRecordEventClone = $A.get("e.force:createRecord");
                createRecordEventClone.setParams({
                    "entityApiName": "Case",
                    "recordTypeId": recTypeId,
                    "defaultFieldValues": caseRecValues
                });
                createRecordEventClone.fire();
                component.set("v.relCaseButton", false);
            },
            {
                "caseId": component.get("v.recordId"),
                "recType": selectedRadioOption,
                
            }
        );
    },
    closeCase:function(component, event, helper) {
        helper.callServer(
            component,
            "c.getCaseStatus",
            function(response){
                var returnVal = response;
                if(returnVal=='Closed')
                {
                    component.set("v.showCloseCase", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "Error",
                        "message": "Case Close is only available for open Cases"
                    });
                    toastEvent.fire();
                }
                else{
                    component.set("v.showCloseCase", true);                
                }
            },
            {
                "caseId" : component.get("v.recordId")
            });
        
        helper.callServer(
            component,
            "c.getAMGCaseRecTypeId",
            function(response){
                var returnVal = response;
                component.set("v.recTypeIdAMG", returnVal);
            });
    },
    
    
    closeCaseModal: function(component, event, helper) {
        component.set("v.showCloseCase", false);
    },
    
    submitForm : function(component, event, helper) 
    {
        var flds = event.getParam('fields');
        
        helper.callServer(
            component,
            "c.closeCases",
            function(response){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case has been updated successfully"
                });
                toastEvent.fire();
                component.set("v.showCloseCase", false);
                $A.get('e.force:refreshView').fire();
                
            },
            {
                "caseId" : component.get("v.recordId"),
                "caseFieldValues" : flds
            });
    },
    
    closeInvalid:function(component, event, helper) {
        
        helper.callServer(
            component,
            "c.getCaseStatus",
            function(response){
                var returnVal = response;
                if(returnVal=='Closed')
                {
                    component.set("v.showCloseInvalid", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "Error",
                        "message": "Case Close-Invalid is only available for open Cases"
                    });
                    toastEvent.fire();
                }
                else{
                    component.set("v.showCloseInvalid", true);                
                }
            },
            {
                "caseId" : component.get("v.recordId")
            });
    },
    
    closeInvalidModal : function(component, event, helper)
    {
        component.set("v.showCloseInvalid", false);
        
    },
    
    submitInvalid:function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");
        var commentVal = fields.Comments__c;
        
        helper.callServer(
            component,
            "c.closeCaseInvalid",
            function(result)
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case has been updated successfully"
                });
                toastEvent.fire();
                component.set("v.showCloseInvalid", false);
                $A.get('e.force:refreshView').fire();
                
                
            },
            {
                "caseId": component.get("v.recordId"),
                "commentsData": commentVal
                
            }
        );
    }
 
 })