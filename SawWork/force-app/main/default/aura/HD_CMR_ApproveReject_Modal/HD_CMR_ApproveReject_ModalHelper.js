({
	helperMethod : function() {
		
	},showErrorToast : function(component, event, helper,errorMessage) {
		var errorMessageTemp=errorMessage;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error Message',
            message: errorMessageTemp,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },

    showWarningToast : function(component, event, helper,errorMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Warning',
            message: errorMessage,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            messageTemplateData:'' ,
            duration:' 3000',
            key: 'info_alt',
            type: 'warning',
            mode: 'pester'
        });
        toastEvent.fire();
    },showSuccessToast : function(component, event, helper,successMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: successMessage,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 3000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    }
})