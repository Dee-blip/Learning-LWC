({
    doInit: function (component, event, helper) {

        helper.showButtonCheck(component, event);
        // helper.disableButtonCheck(component, event);
        
    },

    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            let lockFlag = component.get("v.quoteRecord.CPQ_Locked__c");
            let status = component.get("v.quoteRecord.SBQQ__Status__c");
            let customerType = component.get("v.quoteRecord.CPQ_CustomerType__c");
            if(lockFlag == false && status != 'Order Accepted' && customerType !== 'Existing Customer'){
                component.set("v.enableLock", true);
            }
            else{
                component.set("v.enableLock", false);
            }

            if(customerType === "Existing Customer"){
                let message = helper.getMessageString(component, $A.get("$Label.c.CPQ_Existing_Customer"));
                component.set("v.message", message);
                component.set("v.showCard", true);
            }

        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }

})