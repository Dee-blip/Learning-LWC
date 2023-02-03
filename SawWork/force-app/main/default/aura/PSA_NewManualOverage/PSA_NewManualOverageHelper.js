({
	showToastMessage : function(title,message,messagetemplate,type) 
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            messageTemplate: messagetemplate,
            duration:'5000',
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();                

	},
	showSpinnerHelper: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
       	
        console.log('hereee');
        component.set("v.Spinner", true); 
   	},
    
	 // this function automatic call by aura:doneWaiting event 
    hideSpinnerHelper : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    },
    
})