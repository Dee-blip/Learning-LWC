({
    doInit : function(component, event, helper)
    {
        helper.initialize(component,event);

    },

    navigateToAllTask: function(component, event, helper)
    {
				console.log('navigateToAllTask ');
				var attributes = event.getParam('paramMap');
				var nameOfCmp = event.getParam('nameOfCmp');
				console.log('attributes :',attributes);
				console.log('nameOfCmp :',nameOfCmp);

				if(nameOfCmp === 'c:SF1_TaskApp_OA_Cmp')
				{
	        $A.createComponent(nameOfCmp,
						{
	                'opptyId' :attributes['opptyId'],
                  'oaId' :attributes['oaId']
	          },
						function(newComponent){
                component.set("v.body",'');
	              component.set("v.body",newComponent);

	      	});
			  }
				else if(nameOfCmp === 'c:SF1_TaskApp')
				{
					$A.createComponent(nameOfCmp,
						{

	          },
						function(newComponent){
	              component.set("v.body",newComponent);

	      	});
				}
				else if(nameOfCmp === 'c:SF1_TaskApp_CreateNewTask_Cmp')
				{
					$A.createComponent(nameOfCmp,
						{
	              'recordId' :attributes['recordId'],
								'comingFromTaskManagementApp' :attributes['comingFromTaskManagementApp']
	          },
						function(newComponent){
	              component.set("v.body",newComponent);

	      	});
				}
        else if(nameOfCmp === 'c:SF1_Component_TaskInterface')
				{
					$A.createComponent(nameOfCmp,
						{
	              'taskId' :attributes['taskId']
	          },
						function(newComponent){
	              component.set("v.body",newComponent);

	      	});
				}
        else if(nameOfCmp === 'c:SF1_TaskCmpParent')
				{
					  helper.initialize(component,event,attributes);
				}
    }
})