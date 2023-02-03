({
    //Method 1: to fetch the approval details records of the case.
    onLoad: function(component, event) {
        //call apex class method
        var action = component.get("c.fetchApprovalDetails");

        //sets the parameters to be passed to apex method.
        action.setParams({
            "caseId": component.get("v.recordId")
        })
        
        //logic after the server call is done.
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue().length > 0){
                    
                    for (var i = 0; i < response.getReturnValue().length; i++) {
                        if(response.getReturnValue()[i].AKAM_Modified_Date__c != null)
                        {
                            var modifiedDate1 = response.getReturnValue()[i].AKAM_Modified_Date__c;
                            var modifiedDate = new Date(new Date(modifiedDate1).toUTCString().slice(0,-4));
                            var hours = modifiedDate.getHours();
                            var minutes = modifiedDate.getMinutes();
                            var ampm = hours >= 12 ? 'PM' : 'AM';
                            hours = hours % 12;
                            hours = hours ? hours : 12; // the hour '0' should be '12'
                            minutes = minutes < 10 ? '0'+minutes : minutes;
                            var strTime = hours + ':' + minutes + ' ' + ampm;
                            var finalTime =  modifiedDate.getMonth()+1 + "/" + modifiedDate.getDate() + "/" + modifiedDate.getFullYear() + " " + strTime;
                            response.getReturnValue()[i].AKAM_Modified_Date__c = finalTime;
                        }
                    }
                    
                    component.set('v.allApprovalDetailsList', response.getReturnValue());
                    component.set('v.showRecords', true);
                    component.find("box3").set("v.value", false);
                    this.displayRecords(component, event, response.getReturnValue());
                }
                // set deafult count and select all checkbox value to false on load 
                component.set("v.selectedCount", 0);
                component.set("v.showStatus", false);
        		component.set("v.disableStatusChange", true);
            }
        });
        $A.enqueueAction(action);
    },
    //Method 2: Show the escalate button on the AD related list for DD/Legal case and only to the case owner if the user has access to escalate a case
    showEscalateButton: function(component, event) {
        var parentCaseId = component.get("v.recordId");
        var EscAccess = component.get("c.checkEscalationAccess");
        EscAccess.setCallback(this, function(EscAccessResponse){
            if(EscAccessResponse.getReturnValue()){
                var getCaseDetails = component.get("c.fetchCaseDetails");
                getCaseDetails.setParams({
                    "caseRecordId": parentCaseId
                })
                
                getCaseDetails.setCallback(this, function(response){
                    if(response.getState() == "SUCCESS")
                    {
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        var caseRTName = response.getReturnValue().RecordType.DeveloperName;
                        if(userId == response.getReturnValue().OwnerId && (caseRTName == 'Order_Approval_Deal_Desk' || caseRTName == 'Order_Approval_Legal'))
                            component.set("v.showEscalateCase", true);
                    }
                });
                $A.enqueueAction(getCaseDetails);
            }
        });
        $A.enqueueAction(EscAccess);
    },
    
    //Method 3: sets the values to display records on the table
    displayRecords: function(component, event, approvalDetailsList) {
        var approvalDetails = [];
        //if the number of returned records is less that 6 then just save the values to attributes
        if(approvalDetailsList.length <= 6){
            component.set('v.approvalDetailsList', approvalDetailsList);
            component.set('v.totalRecords', approvalDetailsList.length);
        }
        //if the number of returned records is more that 6, then save the values to attributes and display the show more button
        else{
            for (var i = 0; i <=5; i++) {
                approvalDetails.push(approvalDetailsList[i]);
            }  
            component.set('v.approvalDetailsList', approvalDetails);
            component.set('v.totalRecords', "6+");
            component.set("v.isShowMore", true);
            component.set("v.isShowLess", false);
        }
    },
    
    //Method 4: gets the controlling field(Case Record Type) picklist values from apex
    getCtrlPLValues: function(component, event) {
        var ctrlPL = component.get("c.fetchControllingPLValues");
        ctrlPL.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != ''){
                    component.set("v.ctrlPLValues", response.getReturnValue());
                }
            }
        });
        $A.enqueueAction(ctrlPL);
    },
    
    //Method 5: gets the dependent field(Approval Status) picklist values from apex
    getDepenPLValues: function(component, event) {
        var depenPL = component.get("c.fetchDependentPLValues");
        depenPL.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != ''){
                    component.set("v.depenPLValues", response.getReturnValue());
                }
            }
        });
        $A.enqueueAction(depenPL);
    },
    
    //Method 6: updates the status of all the records selected
    updateSelectedHelper: function(component, event, deleteRecordsIds,valueSelected) {
        //call apex class method
        var updateAD = component.get("c.updateRecords");
        // pass the all selected record's Id's to apex method 
        updateAD.setParams({
            "recordIdList": deleteRecordsIds,
            "statusValue": valueSelected
        });
        updateAD.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(state);
                var resultStr = response.getReturnValue().split('&&');
                
                //Hide the spinner
                component.set("v.Spinner", false);
                if(resultStr[0] != '' && resultStr[1] == '')
                {
                    this.showSuccessToast(component, event, resultStr[0]);
                }
                if(resultStr[0] == '' && resultStr[1] != '')
                {
                    this.showErrorToast(component, event, resultStr[1]);
                }
                if(resultStr[0] != '' && resultStr[1] != '')
                {
                    var finalMsg = resultStr[0]+"\r\n"+resultStr[1];
                    //alert(finalMsg);
                    this.showInfoToast(component, event, finalMsg);
                }
                
                component.set("v.showStatusBox", false);
                // call the onLoad function for refresh the List view 
                component.set("v.selectedStatus",'--None--');
                //refresh view
                $A.get('e.force:refreshView').fire();   
                this.onLoad(component, event);
            }
        });
        $A.enqueueAction(updateAD);
    },
    
    //Method 7: Set the Status value respective to the case record type
    fetchDependentStatusValues: function(component, event) {
        var fetchSL = component.get('c.fetchStatusList');
        var dependentStatues = [];
        dependentStatues.push("--None--");
        fetchSL.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.statusList",response.getReturnValue());
                var statusValues = this.getDependentOptions(component, event);
                var rt = component.get("v.allApprovalDetailsList")[0].Case_Record_Type__c;
                //Remove hardcode values
                for(var i=0;i<statusValues[rt].length;i++)
                {
                    dependentStatues.push(statusValues[rt][i].value);
                }
                component.set("v.statusList",dependentStatues);
                //Hide the spinner
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(fetchSL);
    },
    
    //Method 8: To show the success message on status update
    showSuccessToast : function(component, event, successMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success Message',
            message: successMessage,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    
    //Method 9: To show the error message on status update
    showErrorToast : function(component, event, errMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error Message',
            message: errMessage,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    
    //Method 10: To get the icon of Approval Detail object
    getIcon: function(component, event) {
        component.set("v.iconValue", "custom:custom33")
        component.set("v.tempIconValue", "custom:custom33")
        /*
        //call apex class method
        var fetchIcon = component.get("c.getIconName");
        // pass the all selected record's Id's to apex method 
        fetchIcon.setParams({
            "sObjectName": 'Approval_Details__c'
        });
        fetchIcon.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                //alert(response.getReturnValue());
                //component.set("v.iconValue", response.getReturnValue())
                component.set("v.iconValue", "custom:custom33")
                //component.set("v.tempIconValue", response.getReturnValue())
                component.set("v.tempIconValue", "custom:custom33")
            }
        });
        $A.enqueueAction(fetchIcon);
        */
    },
    //Method 11: To open the record to be edited
    doEdit: function(component, recId) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recId
        });
        editRecordEvent.fire();
    },
    //Method 12: Called when the Delete button is clicked on record and displays the Popup window for confirmation.
    showDeleteBox: function(component, recId) {
        component.set("v.showStatusBox", true);
        component.set("v.isStatusChange", false);
        component.set("v.isDetailDelete", true);
        component.set("v.deleteRecordId",recId);
    },
    //Method 11: Called when the Delete button is clicked on record and displays the Popup window for confirmation.
    doDelete: function(component, recId) {
        //component.set("v.deleteRecordId",recId);
        component.find("recordHandler").reloadRecord();
    },
    //Method 12: Performs edit/delete action based on the item clicked on each row
    deleteUpdateRecord: function(component, event){
        var message = '';
        component.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) {
            if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
                message = '';
            } else if (deleteResult.state === "INCOMPLETE") {
                message = 'User is offline, device do not support drafts';
            } else if (deleteResult.state === "ERROR") {
                message = 'Problem deleting record, error: ' + JSON.stringify(deleteResult.error);
            } else {
                message = 'Unknown problem, state: ' + deleteResult.state + ', error: ' + JSON.stringify(deleteResult.error);
            }
        }));
        if(message != '')
            this.showErrorToast(component, event, message);
        else
            this.showSuccessToast(component, event, 'Record deleted successfully.');
        component.set("v.showStatusBox", false);
        // call the onLoad function for refresh the List view    
        this.onLoad(component, event);
    },
    //Method 13: To create an escalation case from the line item level
    escalateCase: function(component, recId) {
        var accId = null;
        var oppId = null;
        var oaId = null;
        var parentCaseId = component.get("v.recordId");
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
                            'Approval_Detail_ID__c': recId
                        },
                    });
                    createRecordEvent.fire();
                });
                $A.enqueueAction(ESCaction);
            }
        });
        $A.enqueueAction(caseAction);
    },
    //Method 14: To show the error message on status update
    showInfoToast : function(component, event, errMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Warning Message',
            message: errMessage,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 10000',
            key: 'info_alt',
            type: 'warning',
            mode: 'pester '
        });
        toastEvent.fire();
    },
    //Method 15: Below 3 methods are to get the dependent values of ths picklist
    getDependentOptions: function(component, event) {
        // Set up return object
        var dependentOptions = {};
 		var ctrlPLValues = component.get("v.ctrlPLValues");
		var depenPLValues = component.get("v.depenPLValues");
        var ctrlValues = JSON.parse(ctrlPLValues);
        
        for (var i=0; i<ctrlValues.length; i++) {
            dependentOptions[ctrlValues[i].label] = [];
        }
        // For each dependent value, check whether it is valid for each controlling value
        var depValues = JSON.parse(depenPLValues);
        for (var i=0; i<depValues.length; i++) {
            var thisOption = depValues[i];
            var validForDec = this.decodeBase64(thisOption.validFor);
            for (var ctrlValue=0; ctrlValue<100; ctrlValue++) {
                var testBitVal = this.testBit(validForDec, ctrlValue);
                if (testBitVal) {
                    dependentOptions[ctrlValues[ctrlValue].label].push(thisOption);
                }
            }
        }
        return dependentOptions;
    },
    //Method 16: To clone existing Approval Detailrecord
    cloneAD: function(component, recId) {
       
        
        	var getDefaultQueryString = component.get("c.returnLayoutSectionFields");
        	getDefaultQueryString.setCallback(this, function(res){
                var queryString = res.getReturnValue();
                
                var recordId = recId;
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
        
    },
    testBit: function(validFor, pos) {
        var byteToCheck = Math.floor(pos/8);
        var bit = 7 - (pos % 8);
        return ((Math.pow(2, bit) & validFor.charCodeAt(byteToCheck)) >> bit) == 1;
    },
    decodeBase64: function(s) {
        var e={},i,b=0,c,x,l=0,a,r='',w=String.fromCharCode,L=s.length;
        var A="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        for(i=0;i<64;i++){e[A.charAt(i)]=i;}
        for(x=0;x<L;x++){
            c=e[s.charAt(x)];b=(b<<6)+c;l+=6;
            while(l>=8){((a=(b>>>(l-=8))&0xff)||(x<(L-2)))&&(r+=w(a));}
        }
        return r;
    }
})