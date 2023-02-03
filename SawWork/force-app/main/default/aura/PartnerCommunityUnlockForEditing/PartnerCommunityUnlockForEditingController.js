({
    doInit: function(component, event, helper) {

        var recordId = component.get("v.recordId");
        console.log('Getting the text');
        helper.serverSideCall(component, event, helper, "c.getUnlockRecordText").then(
            function(response) {
                console.log('Unlock Message');
                console.log(response);
                component.set("v.confirmUnlockText",response);
            }
        ).catch(
            function(error) {
                console.log('Error getting the unlock text');
            }
        );
    },

    refreshEvent: function(component, event, helper) {
        var message = event.getParam("message");
        if (message == 'refresh') {
            $A.get('e.force:refreshView').fire();
        }
    },
    
    handleUnlockJS: function(component, event, helper) {
    	console.log("Unlocking the record: handle");
    	var recordId = component.get("v.recordId");
        component.set("v.isProgressing",'true');
        helper.toggleProgressBar(component,event,helper);
        helper.serverSideCall(component, event, helper, "c.handleUnlockRecord", {
            recordId: recordId
        }).then(
            function(response) {
                helper.toggleProgressBar(component);
                console.log('Successful unlock');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                helper.showToast(component,event,helper,"Success!","Successfully unlocked.","success",true);
            }
        ).catch(
            function(error) {
                helper.toggleProgressBar(component);
                $A.get("e.force:closeQuickAction").fire();
                helper.showErrorMessage(component,event,helper,error);
            }
        );
	},
    
    handleCancelJS: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
    
    
})