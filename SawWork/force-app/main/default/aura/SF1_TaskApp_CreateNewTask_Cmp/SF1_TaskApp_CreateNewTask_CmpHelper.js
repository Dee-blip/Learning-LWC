({
	taskTypeMap : {
		 'first' :'Deal Desk/Legal',  		//Create Deal Desk + Legal Task
		 'second' :'OM',		//Create OM Task
		 'third' :'Deal Desk',			//Create Deal Desk Task
		 'fourth' :'Legal',		//Create Legal Task
		 'fifth' :'China CDN',			//China CDN Approval
		 'sixth' :'Edgesuite Transition',			//Edgesuite Transition Approval
		 'seventh' :'PS',		//PS Approval
		 'eighth' :'Product Ops'			//Create Product Ops Request
 },


	loadPickListValues : function(cmp)
    {
        var action1 = cmp.get("c.loadPickListValuesFromUtil");
        action1.setParams({
            "sobjectName" : "Task",
            "picklistFieldName":"Status"
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.statusOptionsPicklist",options);
            }

        });

        var action2 = cmp.get("c.loadPickListValuesFromUtil");
        action2.setParams({
            "sobjectName" : "Task",
            "picklistFieldName":"Priority"
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.priorityOptions",options);
            }

        });

				var action3 = cmp.get("c.loadPickListValuesFromUtil");
        action3.setParams({
            "sobjectName" : "Task",
            "picklistFieldName":"Subject"
        });
        action3.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.subjectOptionsPicklist",options);
            }

        });

        $A.enqueueAction(action1);
        $A.enqueueAction(action2);
				$A.enqueueAction(action3);
    },

		navigateToCmp : function(component, event, helper ,name, attributes) {
    	/*console.log('inside controller navigateToCmp');
    	var evt = $A.get("e.force:navigateToComponent");
    	evt.setParams({
            componentDef : name,
            componentAttributes: attributes
        });

        evt.fire();
			*/
			console.log('inside navigateToCmp');
			var e = $A.get("e.c:SF1_NavigationBetweenComponentsEvent");
			e.setParams({
					"paramMap" : attributes,
					"nameOfCmp":name
			});
			e.fire();
    },

		getOrderApprovalRelatedData : function(cmp){
			var action1 = cmp.get("c.getOARelatedData");
			action1.setParams({
					"oaID" : cmp.get("v.recordId")
			});
			action1.setCallback(this, function(response) {
					var state = response.getState();
					var orderApproval = response.getReturnValue();
					if (cmp.isValid() && state === "SUCCESS")
					{
							cmp.set("v.orderApproval",orderApproval);
					}

			});

			$A.enqueueAction(action1);
		},

		navigateToOrderApprovalFromQuickAction : function(cmp)
		{
			var navEvt = $A.get("e.force:navigateToSObject");
			navEvt.setParams({
				"recordId": cmp.get("v.recordId"),
				"slideDevName": "detail"
			});
			navEvt.fire();
		}
})