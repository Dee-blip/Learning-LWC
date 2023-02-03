({

	 doInit : function(cmp, event, helper) {
		console.log('orderApprovalId recordId :',cmp.get("v.recordId"));

		var tempMap={
			  'first' :'Deal Desk/Legal',  		//Create Deal Desk + Legal Task
				'second' :'OM',									//Create OM Task
				'third' :'Deal Desk',						//Create Deal Desk Task
				'fourth' :'Legal',							//Create Legal Task
				'fifth' :'China CDN',						//China CDN Approval
				'sixth' :'Edgesuite Transition',//Edgesuite Transition Approval
				'seventh' :'PS',								//PS Approval
				'eighth' :'Product Ops'					//Create Product Ops Request
		}

		helper.loadPickListValues(cmp);
		helper.getOrderApprovalRelatedData(cmp);
	},

	closeCreateNewTask : function(component,event,helper){
        console.log('inside controller closeCreateNewTask');
        component.set("v.showCreateNewTaskBody", false);
        component.set("v.showCreateNewTask", false);
				if(component.get("v.comingFromTaskManagementApp"))
				{
					var name='c:SF1_TaskApp_OA_Cmp';
					var opptyId = component.get("v.orderApproval.Associated_Opportunity__c");
	        var attributes={
	            'opptyId' :opptyId
	        };
	        helper.navigateToCmp(component, event, helper ,name ,attributes);
			  }
				else
				{
					helper.navigateToOrderApprovalFromQuickAction(component);
				}
  },

	createNewTaskBody : function(cmp,event,helper){
        console.log('inside controller createNewTaskBody');

        cmp.set("v.showCreateNewTask", false);


				var p_TaskType_key = event.getSource().getLocalId();

				console.log('p_TaskType_key :',p_TaskType_key);

				var p_TaskType = helper.taskTypeMap[p_TaskType_key];
				if(p_TaskType ==='Deal Desk/Legal')
				{
					cmp.set("v.legalFollowUpNeeded", true);
				}
				var oaID = cmp.get("v.recordId");

				console.log('p_orderId upon clicking on createNewTaskBody :',oaID);
				console.log('p_TaskType :',p_TaskType);

				var action = cmp.get("c.Create_Task_Ltng");
        action.setParams({
            "p_orderId" : oaID,
            "p_TaskType": p_TaskType
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var paramMap = response.getReturnValue();
            console.log('paramMap :',paramMap);
            //console.log('paramMap owner :',paramMap['what_id']);
            if (cmp.isValid() && state === "SUCCESS")
            {
							 cmp.set("v.showCreateNewTaskBody", true);
							 paramMap['status']='Not Started';
	             paramMap['priority']='Normal';
							 paramMap['legalFollowUpNeeded']=cmp.get("v.legalFollowUpNeeded");
							 paramMap['activityDate']=cmp.get("v.ActivityDate");
	             cmp.set("v.paramMap", paramMap);
							 var addSubjectOption  = paramMap['tsk5'];
							 console.log('addSubjectOption :',addSubjectOption);
							 cmp.set("v.subjectOptionsPicklist",cmp.get("v.subjectOptionsPicklist").concat(addSubjectOption));
            }

            });
        $A.enqueueAction(action);
    },
		closeCreateNewTaskBodyAndNavigatebackToOACmp : function(component,event,helper){
			  console.log('inside controller closeCreateNewTaskBodyAndNavigatebackToOACmp');
        component.set("v.showCreateNewTaskBody", false);
        component.set("v.showCreateNewTask", false);
				if(component.get("v.comingFromTaskManagementApp"))
				{
					var name='c:SF1_TaskApp_OA_Cmp';
					var opptyId = component.get("v.orderApproval.Associated_Opportunity__c");
	        var attributes={
	            'opptyId' :opptyId

	        };
	        helper.navigateToCmp(component, event, helper ,name ,attributes);
			  }
				else
				{
					helper.navigateToOrderApprovalFromQuickAction(component);
				}

    },
		closeErrorMessage: function(cmp,event,helper){
			cmp.set("v.showError",false);
			document.getElementById('message').style.display="none";
		},
		saveTaskAndNavigatebackToOACmp: function(cmp,event,helper){
			console.log('inside controller saveTaskAndNavigatebackToOACmp');
        if(cmp.get("v.subjectValue") != null && cmp.get("v.subjectValue") != ""){
			var currparamMap = cmp.get("v.paramMap");
        currparamMap['WhatId']=cmp.get("v.orderApproval.Id");
				currparamMap['legalFollowUpNeeded']=cmp.get("v.legalFollowUpNeeded")+'';
				currparamMap['activityDate']=cmp.get("v.ActivityDate");
				currparamMap['subject']=cmp.get("v.subjectValue");
				currparamMap['status']=cmp.get("v.statusValue");
				currparamMap['priority']=cmp.get("v.priorityValue");
        cmp.set("v.paramMap",currparamMap);
        console.log('paramMap : ',cmp.get("v.paramMap"));

        var action = cmp.get("c.createNewTask");
        action.setParams({
            "paramMap" : cmp.get("v.paramMap")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
						var message = response.getReturnValue();
						if (cmp.isValid() && state === "SUCCESS" && message==='success')
            {
                cmp.set("v.showCreateNewTaskBody", false);
                cmp.set("v.showCreateNewTask", false);
								cmp.set("v.showError",false);
								if(cmp.get("v.comingFromTaskManagementApp"))
								{
									var name='c:SF1_TaskApp_OA_Cmp';
									var opptyId = cmp.get("v.orderApproval.Associated_Opportunity__c");
									var attributes={
											'opptyId' :opptyId
									};
									helper.navigateToCmp(cmp, event, helper ,name ,attributes);
						    }
								else
								{
									helper.navigateToOrderApprovalFromQuickAction(cmp);
								}
            }
						else if(cmp.isValid() && state === "SUCCESS" && message!=='success')
            {
							  //message='FIELDS MARKED WITH * ARE MANDATORY';
								cmp.set("v.message",message);
                cmp.set("v.showError",true);
                document.getElementById('message').style.display="block";
								//document.getElementById('message').scrollIntoView();
            }

        });
       $A.enqueueAction(action);
        }
		},
		changeLegalFollowUpNeeded: function(component, event, helper)
    {
        var selection = component.find("legalId").get("v.checked");
        console.log('selection :',selection);
        if(selection == null)
        {
            selection = component.get("v.legalFollowUpNeeded");

        }
        else {
            component.set("v.legalFollowUpNeeded", selection);
        }


    },
		changeSubject: function(component, event, helper)
    {
        var selection = component.find("selectionSubject").get("v.value");
        console.log('selection :',selection);
        if(selection == null)
        {
            selection = component.get("v.subjectValue");

        }
        else {
            component.set("v.subjectValue", selection);
        }


    },
		changeStatus: function(component, event, helper)
    {
        var selection = component.find("selectionStatus").get("v.value");
        console.log('selection :',selection);
        if(selection == null)
        {
            selection = component.get("v.statusValue");

        }
        else {
            component.set("v.statusValue", selection);
        }


    },
		changePriority: function(component, event, helper)
    {
        var selection = component.find("selectionPriority").get("v.value");
        console.log('selection :',selection);
        if(selection == null)
        {
            selection = component.get("v.priorityValue");

        }
        else {
            component.set("v.priorityValue", selection);
        }


    },
		editSubject: function(component, event, helper){
			component.set("v.subjectShowAsPicklist", false);
			var val = component.get("v.subjectValue");
			component.find("editSubject").set("v.value",val);
			component.set("v.oldvalue",val);

		},
		goBackToPicklist: function(component, event, helper){
			component.set("v.subjectShowAsPicklist", true);
			var subjectOptionsPicklist = component.get("v.subjectOptionsPicklist");
			var oldvalue =component.get("v.oldvalue");
			console.log('oldvalue :',oldvalue);
			var indxOldValue = subjectOptionsPicklist.indexOf(oldvalue);
			console.log('indxOldValue :',indxOldValue);
			var newSubject = component.find("editSubject").get("v.value");
			console.log('newSubject :',newSubject);
			subjectOptionsPicklist[indxOldValue] = newSubject;
			component.set("v.subjectOptionsPicklist", subjectOptionsPicklist);
			component.find("selectionSubject").set("v.value",newSubject);
			component.set("v.subjectValue",newSubject);


		},
		makeTextAreaEditable: function(component, event, helper){
			document.getElementsByClassName("inputDesc")[0].contentEditable = "true";
		}

})