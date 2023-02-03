({
    doInit: function(component, event, helper) {

        var recordId = component.get("v.recordId");
        console.log('Proceed with submit');
        component.set("v.isProgressing",'true');
        helper.toggleProgressBar(component,event,helper);
        helper.serverSideCall(component, event, helper, "c.handleApproval", {
            recordId: recordId
        }).then(
            function(response) {
                console.log('Submitting');
                helper.toggleProgressBar(component);
                console.log('Successful submit');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                helper.showToast(component,event,helper,"Success!","Successfully submitted.","success",true);
            }
        ).catch(
            function(error) {
                helper.toggleProgressBar(component);
                $A.get("e.force:closeQuickAction").fire();
                helper.showErrorMessage(component,event,helper,error);
            }
        );
    },

    refreshEvent: function(component, event, helper) {
        var message = event.getParam("message");
        if (message == 'refresh') {
            $A.get('e.force:refreshView').fire();
        }
    }
})