({
	doInit : function(component, event, helper) 
    {
		 var ResultValue = component.get("v.DocuId");
         
		 var action = component.get("c.getdocuments"); 
         action.setParams({
            DocumentId:ResultValue
         });
        
         action.setCallback(this, function(response){
            var similarProperties = response.getReturnValue();
            //var DocuDesc = similarProperties.Description__c.replace(/<(.|\n)*?>/g, '');;
            component.set("v.Docu", similarProperties);
            //component.set("v.DocuDesc", DocuDesc);
        });
        
         $A.enqueueAction(action);
	}
})