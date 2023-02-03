({
	goToWarningsPage : function(component, event, helper) 
	{
		var opportunityId = component.get('v.oppId');
		sforce.one.navigateToURL("/one/one.app#/alohaRedirect/apex/OpportunityWarnings?opptyId="+opportunityId);


            
	}
})