({
	showToastMessage : function(type,message) 
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: message,
            messageTemplate: message,
            duration:' 5000',
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();                
		
	}
})