({
	init : function(component, event, helper) {
        console.log('manage-operations-portal-access');
		window.location = '/partners/s/manage-operations-portal-access?id=' + component.get("v.recordId");
	}
})