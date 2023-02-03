({
	callController : function(component,helper) {

        var rId = component.get("v.recordId");
		var action = component.get("c.checkValidity");   
        console.log(action);
		action.setParams
        (
            {
                recordId: rId
            }
        
        );
        console.log('testst');
        action.setCallback(this, function(a) {
            var result =a.getReturnValue(); 
            console.log(result);
			if(result == 'Test records can only be associated to CloudTest on Demand Product!')
            {
				var toastEvent = $A.get("e.force:showToast");
		        toastEvent.setParams({
                    title : 'Info Message',
                    message: result,
                    messageTemplate: result,
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'info',
                    mode: 'dismissible'
		        });
        		toastEvent.fire();                
            }
            else
            {	
                	var projectId;
                	var milestoneId;
                	if(result == null)
                    {
                        projectId = rId;
                        milestoneId = null;
                    }
                	else
                    {
                        projectId = result;
                        milestoneId = rId;
                        
                    }
                	var field1 = "Engagement__c";
                	var field2 = "Deliverable__c";
	                var defaultFieldValuesObject ={};
                	defaultFieldValuesObject[field1] = projectId;
                	defaultFieldValuesObject[field2] = milestoneId;
                
                	var objectName = "Test__c";
					var createRecordEvent = $A.get("e.force:createRecord");
				    createRecordEvent.setParams({
				        "entityApiName": objectName,
                        "defaultFieldValues": defaultFieldValuesObject
				    });
				    createRecordEvent.fire();                
                
            }
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
			dismissActionPanel.fire();
            
        });
        $A.enqueueAction(action);     

           
	},

})