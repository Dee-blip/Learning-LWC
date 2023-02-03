({
	myAction : function(cmp, event, helper) {
        var compnt=cmp.find("selectedTicketsModal");
		$A.util.removeClass(compnt,"slds-hide");
        cmp.set("v.startTime",new Date());
        cmp.set("v.actionName",cmp.get("v.label")+'-Bulk');
        helper.calculateInactiveTime(cmp,event);
	},
    closeSelectedTicketsModal: function(component, event, helper) {
        var cmp=component.find("selectedTicketsModal");
		$A.util.addClass(cmp,"slds-hide");
	},
    
    closeWindow : function(component, event, helper) {
        var cmp=component.find("bulkUpdateModal");
		$A.util.addClass(cmp,"slds-hide");
	},
    
    showAction : function(component, event, helper) {
		var cmp=component.find("selectedTicketsModal");
		$A.util.addClass(cmp,"slds-hide");
        var cmp=component.find("bulkUpdateModal");
		$A.util.removeClass(cmp,"slds-hide");

         $A.createComponent(
            component.get("v.componentName"),
            {
                "incidentIds":component.get("v.incidentIds"),
                "incidentData":component.get("v.incidentData")
            },
            function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    //var body = cmp.get("v.body");
                    //body.push(newButton);
                    component.set("v.body", newCmp);
                }
               
                else if (status === "ERROR") {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "error",
                        "message": errorMessage
                    });
                    toastEvent.fire();
                }
            }
        );
        
	},
    handleShowBulkUpdateResultsEvt : function(component, event, helper) {
		
        var results = event.getParam("results");
        var incIds = component.get("v.incidentIds");
        var incs = component.get("v.incidentData");
        var incMap = {};
        for(var i = 0;i<incIds.length;i++)
        {
           incMap[incIds[i]] = incs[i]; 
        }
        var success = [];
        for(var i=0;i<results.successes.length;i++)
        {
          success.push(incMap[results.successes[i]]);  
        }
        component.set("v.success",success);
        var failureList = [];
        var failureResult = results.failures;
        for(var key in failureResult)
        {
            failureList.push([incMap[key],failureResult[key]]);
            
        }
        
        component.set("v.failure",failureList);
        var cmp=component.find("resultModal");
		$A.util.removeClass(cmp,"slds-hide");
        var cmp=component.find("bulkUpdateModal");
		$A.util.addClass(cmp,"slds-hide");
        $A.get("e.c:HD_RefreshEvent").fire();
        $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : 'SUCCESS' }).fire();
        
        component.set("v.incidentIds",[]);
        component.set("v.incidentData",[]);
        
	},
    
    closeresultModal : function(component, event, helper) {
		
        var cmp=component.find("resultModal");
		$A.util.addClass(cmp,"slds-hide");
	},
    clearIdleTime: function(component, event, helper) {
		component.set("v.idleTime",0);
	},
    resetStartTime: function(component, event, helper) {
		component.set("v.startTime",new Date());        
	},
})