({
	onRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") 
        {
            console.log("Record is loaded successfully.");
			var psOverageFields = component.get("v.psOverageFields");
            var message;
            if(psOverageFields.Finance_Approver__c && psOverageFields.Overage_Stage__c === "Submitted")
            {
                message = "Pending for Finance Sign Off!";
            }
            else if(psOverageFields.GSS_Approver__c && psOverageFields.Overage_Stage__c === "Saved")
            {
                message = "The record is pending for Sign Off!";
            }
            component.set("v.message",message);
        }  
        else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
            console.log("ERRRORRR!!!!!" + component.get("v.recordError"));
        }
    }, 
})