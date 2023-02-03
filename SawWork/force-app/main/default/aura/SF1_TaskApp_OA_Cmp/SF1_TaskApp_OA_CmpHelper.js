({
	oaKeyMap : {
		 'Id' : 'Id',
		 'Name' :'Name',
		 'Associated_Account__c' :'Associated Account',
		 'Associated_Opportunity__r' :'Associated Opportunity',
		 'Opportunity_Owner__c' :'Opportunity Owner',
		 'Associated_Opportunity_Sales_Stage__c' :'Sales Stage',
		 'Approvals_Required__c' :'Approvals Required',
		 'Order_Expires_Unless_Duly_Executed_By__c':'Order Expires Unless Duly Executed By',
		 'Small_Deal__c' :'Small Deal'
 }
 ,
	getOrderApprovalAndRelatedTasks : function(cmp,event) {
		console.log('inside helper showOrderApprovalRecordandTasks');
		var oaId = cmp.get("v.oaId");
		console.log('oaId :' ,oaId);

		if(!oaId)
		{

				console.log('inside if of getOrderApprovalAndRelatedTasks');
				var action1 = cmp.get("c.getOrderApproval");
				var opptyId = cmp.get("v.opptyId");
				console.log('current opptyId :',opptyId);

        action1.setParams({
            "opptyId": opptyId
        });

        action1.setCallback(this, function(response) {
            var state = response.getState();
            var orderApproval = response.getReturnValue();
            console.log('orderApproval :',orderApproval);
						if(orderApproval) cmp.set("v.enableNewTask", false);
						else if(!orderApproval) cmp.set("v.enableNewTask", true);


						var oadetails = [];
						if(orderApproval)
						{
								for (let key in this.oaKeyMap)
								{

									if(key==='Associated_Opportunity__r')
									{
										oadetails.push({value:orderApproval[key]['Name'],key:this.oaKeyMap[key]});
									}
									else if(key!=='Id' && key!=='Associated_Opportunity__r' && key!=='Associated_Opportunity__c')
									{
												oadetails.push({value:orderApproval[key], key:this.oaKeyMap[key]});
									}

		            }


								console.log('oadetails :',oadetails);
						}

						if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.orderApproval", orderApproval);
								cmp.set("v.oadetails", oadetails);
								this.reloadTaskList(cmp,'');
            }
        });
				$A.enqueueAction(action1);
			}
			else
			{
				console.log('inside else of getOrderApprovalAndRelatedTasks');
				var action1 = cmp.get("c.getOrderApprovalById");
				action1.setParams({
            "oaId": oaId,
        });
				action1.setCallback(this, function(response) {
            var state = response.getState();
            var orderApproval = response.getReturnValue();
            console.log('orderApproval :',orderApproval);

						var oadetails = [];
						if(orderApproval)
						{
								for (key in this.oaKeyMap)
								{

									if(key==='Associated_Opportunity__r')
									{
										oadetails.push({value:orderApproval[key]['Name'],key:this.oaKeyMap[key]});
									}

									else if(key!=='Id' && key!=='Associated_Opportunity__r' && key!=='Associated_Opportunity__c')
									{
												oadetails.push({value:orderApproval[key], key:this.oaKeyMap[key]});
									}
		            }



								console.log('oadetails :',oadetails);
						 }


            if (cmp.isValid() && state === "SUCCESS")
            {
                cmp.set("v.orderApproval", orderApproval);
								if(orderApproval)	cmp.set("v.enableNewTask", false);
								else if(!orderApproval) cmp.set("v.enableNewTask", true);
								cmp.set("v.oadetails", oadetails);
								this.reloadTaskList(cmp,'');

            }


        });
				$A.enqueueAction(action1);
      }



	},

	reloadTaskList : function(cmp,status) {
				console.log('status :',status);
				if(!status)
				{
					status='Open';
				}
				console.log('status after if check :',status);
				var action = cmp.get("c.getTasksRelatedToOrderApproval");
				var oaID = cmp.get("v.orderApproval.Id");
				var listOfStatus=[];
				if(status === 'Open'){
					listOfStatus=['Not Started', 'In Progress', 'Waiting on someone else', 'Deferred'];
				}
				else if(status === 'Closed'){
					listOfStatus=['Completed'];
				}

				console.log('listOfStatus :',listOfStatus);
				console.log('oaId :',oaID);


				action.setParams({
						"oaId" : oaID,
						"listOfStatus":listOfStatus
				})

				action.setCallback(this, function(response){
						var state = response.getState();
						var listOfTasks = response.getReturnValue();
						var tsk;
						var string;
						console.log('listOfTasks :',listOfTasks);
						for(let i in listOfTasks)
						{
							tsk = listOfTasks[i];
							string = tsk['Subject'];

							if(string.length>28)
							{
								tsk['Subject']  = string.substring(0, 25);
								tsk['Subject'] = tsk['Subject']+'...';
							}
						}
						if(listOfTasks.length>0) cmp.set("v.tasksAvailable", true);
						if(listOfTasks.length<=0) cmp.set("v.tasksAvailable", false);
						if (cmp.isValid() && state === "SUCCESS")
						{
								cmp.set("v.listOfTasks", listOfTasks);
								console.log('listOfTasks :',cmp.get("v.listOfTasks"));
						}
				});

				$A.enqueueAction(action);
  	},

    navigateToCmp : function(component, event, helper ,name, attributes) {
    	/*console.log('inside controller navigateToCmp :',attributes);
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
    }
})