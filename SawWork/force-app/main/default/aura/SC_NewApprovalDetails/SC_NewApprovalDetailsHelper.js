({
	updateForNewButton : function(component,event,helper){
    	var parentCaseId = component.get("v.caseRecordId");
        var parentRTST = '';
        var ADRecordTypeName = '';
        var ADRecordTypeId = '';
        var approvalRequest = '';
        
        var getCaseDetails = component.get("c.fetchCaseDetails");
        getCaseDetails.setParams({
            "caseRecordId": parentCaseId
        })
        
        getCaseDetails.setCallback(this, function(response)
        {
            if(response.getState() == "SUCCESS"){
                parentRTST = response.getReturnValue().RecordType.Name+';'+response.getReturnValue().Sub_Type__c;
                if(response.getReturnValue().RecordType.Name == 'Order Approval-Deal Desk' 
                   || response.getReturnValue().RecordType.Name == 'Order Approval-Escalations')
                    ADRecordTypeName = 'Deal Desk Approval Details'
                else
                    ADRecordTypeName = 'Other Approval Details'
                 
                var getADRT = component.get("c.fetchADRecTypeId");
                getADRT.setParams({
                    "recordTypeLabel": ADRecordTypeName
                })  
                
                getADRT.setCallback(this, function(res){
                    ADRecordTypeId = res.getReturnValue();
                    
                    //Create Case Record With Default Values
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": "Approval_Details__c",
                        "recordTypeId": ADRecordTypeId,
                        "defaultFieldValues": {
                            'Related_To__c' : parentCaseId,
                            'Case_RT_ST__c' : parentRTST,
                            'Case_Record_Type__c' : response.getReturnValue().RecordType.Name,
                            'Approval_Status__c': 'Pending',
                            'Approval_Requested_By__c': $A.get("$SObjectType.CurrentUser.Id"),
                            'Order_Approval__c' : response.getReturnValue().Order_Approval__c,
                            'Opportunity__c' : response.getReturnValue().Opportunity__c
                        }
                    });
                    createRecordEvent.fire();
                });
                $A.enqueueAction(getADRT);  
            }
        });
        $A.enqueueAction(getCaseDetails); 
	},
    cloneMethod : function(component,event,helper){
        
        	var getDefaultQueryString = component.get("c.returnLayoutSectionFields");
        	getDefaultQueryString.setCallback(this, function(res){
                var queryString = res.getReturnValue();
                
                var recordId = component.get("v.recordId");
                var getCaseDetails = component.get("c.fetchApprovalDetailRecord");
                getCaseDetails.setParams({
                    "recordId": recordId,
                    "commaSeperatedFields": queryString
                });
                getCaseDetails.setCallback(this, function(response)
                {
                    if(response.getState() == "SUCCESS"){
                        var aprvDtl = response.getReturnValue();
                        var defaultADfields = {};
                        for ( var fld of queryString.split(',')){
                            if(fld != "")
                            	defaultADfields[fld] = aprvDtl[fld]
                        }
                        defaultADfields['Approval_Status__c'] = 'Pending';
                        //Create Case Record With Default Values
                        var createRecordEventClone = $A.get("e.force:createRecord");
                        createRecordEventClone.setParams({
                            "entityApiName": "Approval_Details__c",
                            "recordTypeId": aprvDtl['RecordTypeId'],
                            "defaultFieldValues": defaultADfields
                        });
                        createRecordEventClone.fire();
                	}
           		});
                $A.enqueueAction(getCaseDetails);
        });
        $A.enqueueAction(getDefaultQueryString);
    }   
    
})