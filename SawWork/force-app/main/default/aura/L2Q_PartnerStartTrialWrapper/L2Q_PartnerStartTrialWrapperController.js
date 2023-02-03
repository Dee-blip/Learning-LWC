({
	doInit: function(component, event, helper) {},
	internaluserNav: function(emp, evt, helper) {
		$A.get('e.force:closeQuickAction').fire();
		var selectedrecordId = evt.getParam('data');
		helper.navigate(emp, evt, helper, selectedrecordId);
	},
	//handles close action
	closequickAct: function(cmp, evet, helper) {
		$A.get('e.force:closeQuickAction').fire();
	}
});