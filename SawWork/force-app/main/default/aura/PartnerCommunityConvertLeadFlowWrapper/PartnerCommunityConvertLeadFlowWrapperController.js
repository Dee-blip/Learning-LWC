({
	init : function(component, event, helper) {
        
        var recordId = component.get("v.recordId");
        console.log('recordId :'+recordId);
		var flow = component.find("flowData");
        console.log('Loading convert flow');
        var inputVariables = [
            {
                name : "leadId",
                type : "String",
                value: recordId
            }
        ];
        
        var flowName = component.get("v.flowName");
        flow.startFlow("ConvertLead",inputVariables);
	},
    
    statusChange : function (component, event, helper) {
        console.log('SH : flow status :'+event.getParam('status'));
        var status = event.getParam('status');
        if (event.getParam('status') == "FINISHED") {
            console.log('SH : redirect after flow finishes');
            
            var outputVariables = event.getParam("outputVariables");
            console.log(outputVariables) ;
            var urlValue = "";
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                if(outputVar.name === "redirectRecordId" && outputVar.value != "")
                    urlValue = '/detail/'+outputVar.value;
            }
                
            if (urlValue == "") {
            	urlValue = '/recordlist/Lead/Default';
            	console.log('SH : flow status change. URL :'+urlValue);
            }
            
        	var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": urlValue
            });
            urlEvent.fire();
        } else if(event.getParam('status') == "Error") {
            console.log('Error converting lead');
            $A.get("e.force:closeQuickAction").fire();
            helper.showToast(component,event,helper,"Error!","Error Converting Lead.","error",true);
        }
        
    }
})