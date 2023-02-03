({
	myAction : function(component, event, helper) 
    {
		helper.callServer(
            component,
            "c.getRecordDetails",
            function(result)
            {
                component.set("v.taskRec",result);
            },
            {
                "recordId" : component.get("v.recordId"),
                "objectName" : "Task",
                "fields" : "Id,DueDateProlexic__c"
            }
        );
	}
})