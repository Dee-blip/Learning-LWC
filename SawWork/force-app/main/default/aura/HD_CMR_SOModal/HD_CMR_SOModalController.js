({
	firecloseEvent : function(component, event, helper) {
        console.log("Closeee")
       var cmpEvent = component.getEvent("closeModalEvt");
        cmpEvent.setParams({"setBoolean":false});
        cmpEvent.fire();
        console.log('FIRED');

		
	},
    closeModal: function(component, event, helper){
        component.closeModal();
    }
})