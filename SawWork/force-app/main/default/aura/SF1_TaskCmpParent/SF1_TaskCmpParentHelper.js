({
	initialize : function(component, event, attributes) {

		var paramMap = component.get("v.paramMap");
		var paramMapTaskInterface = component.get("v.paramMapTaskInterface");
		var comingFromTaskInterface = false;
		var opptyId;
		var oaId;
		console.log('intializing SF1_TaskCmpParent');
		console.log('paramMap :',paramMap);
		console.log('paramMapTaskInterface :',paramMapTaskInterface);
		var taskId;
		var showTaskPage = false;




		if(paramMap)
		{
			comingFromTaskInterface = paramMap['comingFromTaskInterface'];
			opptyId = paramMap['opptyId'];
			oaId = paramMap['oaId'];
	  }

		if(paramMapTaskInterface)
		{
			taskId= paramMapTaskInterface['taskId'];
			showTaskPage = paramMapTaskInterface['showTaskPage'];
		}

		if(attributes)
		{
			paramMap = attributes;
			comingFromTaskInterface = paramMap['comingFromTaskInterface'];
			opptyId = paramMap['opptyId'];
			oaId = paramMap['oaId'];
		}


		console.log('comingFromTaskInterface :',comingFromTaskInterface);

		if(!comingFromTaskInterface && !showTaskPage){
			console.log('inside 1');
				$A.createComponent("c:SF1_TaskApp", {


				}, function(newCmp) {
						if (component.isValid()) {
								component.set("v.body", newCmp);
						}
				});
		}

		else if(comingFromTaskInterface && !showTaskPage)
		{
			console.log('inside 2');
			$A.createComponent("c:SF1_TaskApp_OA_Cmp",
				{
							'opptyId' :opptyId,
							'oaId' :oaId
				},
				function(newComponent){
						component.set("v.body",newComponent);

			});
		}

		else if(showTaskPage)
		{
			console.log('inside 3');
			$A.createComponent("c:SF1_Component_TaskInterface",
				{
							'taskId' :taskId
				},
				function(newComponent){
						component.set("v.body",newComponent);

			});
		}

	}
})