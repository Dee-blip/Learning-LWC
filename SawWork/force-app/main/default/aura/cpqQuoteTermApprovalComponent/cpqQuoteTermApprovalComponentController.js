/**
 * onPageReferenceChange is used to initialize the approval type, record id, record type id from the PageRef parameters
 */
({
    onPageReferenceChange : function(component, event, helper) {

        let pageRef = component.get("v.pageReference");
        let actionType = pageRef.state.c__action;
        let recordId = pageRef.state.c__recordId;
        let recordTypeId = pageRef.state.c__recordTypeId
        component.set("v.actionType", actionType);
        component.set("v.adRecordId",recordId);
        component.set("v.adRecordTypeId",recordTypeId);
        if((actionType != 'Approve' && actionType != 'Reject')){
            helper.showNotification(component, 'error', 'Invalid Type: Action can not be taken.');
            let btn = component.find("submitButton");
            btn.set("v.disabled", true);
            return;
        }
    },
/**
 * handleLoad method is called when AD record loads and check for the valid output fields
 */
    handleLoad: function(component,event,helper){

        var payload = event.getParam("recordUi");
        let requestType = payload.record.fields["Approval_Request__c"].displayValue;
        let approvalStatus = payload.record.fields["Approval_Status__c"].displayValue;
        let quote = payload.record.fields["CPQ_Quote__c"].value;
        if(requestType == 'Carrier Quote Approval' || approvalStatus == 'Approved by OM' || approvalStatus == 'Rejected' || quote == null){
            let btn = component.find("submitButton");
            btn.set("v.disabled", true);
        }

    },

/**
 * handleSubmit method is called when AD is Approved/Rejected
 * set the validation overide and approval status of the record before updateing
 */
    handleSubmit: function(component, event, helper) {

        event.preventDefault();       // stop the form from submitting
        let fields = event.getParam('fields');
        let actionType = component.get("v.actionType");
        if(actionType === 'Approve'){
            fields.Approval_Status__c = 'Approved by OM';
        }
        else if(actionType === 'Reject'){
            fields.Approval_Status__c = 'Rejected'
        }
        fields.Validation_Override_CPQ__c = true;
        component.find('adRecordForm').submit(fields);
    },

/**
 *  handleSuccess is called when record is successfully committed to DB.
 *  The workspace tab will be closed after displaying message
 */
    handleSuccess: function(component, event, helper) {

        helper.showNotification(component, 'info' , 'Approval record updated successfully!');
        let workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo()
        .then(tabInfo =>{
            let focussedTabId = tabInfo.tabId
            return workspaceAPI.closeTab({tabId:focussedTabId});
        })
        .catch(error => {
            console.log(error);
        });
        
    }
})