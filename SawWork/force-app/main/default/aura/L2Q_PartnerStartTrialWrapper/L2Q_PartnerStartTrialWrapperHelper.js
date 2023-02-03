({
	navigate: function(component, event, helper, navAttribute) {
		var navigateEvent = $A.get('e.force:navigateToComponent');
		navigateEvent.setParams({
			componentDef: 'c:L2Q_StartTrial_IntermediateComp',
			componentAttributes: navAttribute
		});
		navigateEvent.fire();
	}
});