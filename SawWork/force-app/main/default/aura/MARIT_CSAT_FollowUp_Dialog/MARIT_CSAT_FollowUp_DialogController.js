({
	doInit: function (component, event, helper) {
        helper.initHelper(component, event, helper);
    },
    handleSubmit: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
        fields["Follow_Up_Completed__c"] = true;
        if (component.get("v.setActualCompletionDate")) {
            var currentDateTime = new Date();
            fields["Actual_Completion_Date__c"] = currentDateTime.toISOString();
        }
        component.find('followUpForm').submit(fields);
    },
    handleOnSuccess : function(component, event, helper) {
        var param = event.getParams(); //get event params
        var fields = param.response.fields; //get all field info
        
        var recordId = param.response.id; //get record id
        $A.get("e.force:closeQuickAction").fire();
    },
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    handleError: function(component, event) {
        var errors = event.getParams();
        console.log("response", JSON.stringify(errors));
    }
})