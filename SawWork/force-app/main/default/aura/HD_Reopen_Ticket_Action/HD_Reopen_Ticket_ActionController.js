({
	reopenTicketAction : function(component, event, helper) {
		var reopenActoin = component.get("v.actionName");
        helper.reopenTicketHandle(component,event);
	}
})