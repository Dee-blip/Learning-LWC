({
    doInit : function(cmp, event, helper) {
        console.log('inside controller SF1_TaskApp_OA_Cmp doInit');
        helper.getOrderApprovalAndRelatedTasks(cmp,event);
        //document.getElementById('scrollToHeader').scrollIntoView();

    },
    switchTabToOA : function(component, event) {
        var OppDetailsTab = component.find("oppDetId") ;
        var ProdDetailsTab = component.find("prodDetId");
        var OppDetailsData = component.find("oppDetBodyId") ;
        var prodDetailsData = component.find("prodDetBodyId");
        $A.util.addClass(OppDetailsTab, 'slds-active');
        $A.util.removeClass(ProdDetailsTab, 'slds-active');
        $A.util.removeClass(prodDetailsData, 'slds-show');
        $A.util.removeClass(OppDetailsData, 'slds-hide');
        $A.util.addClass(OppDetailsData, 'slds-show');
        $A.util.addClass(prodDetailsData, 'slds-hide');
        console.log("OA Active");
    },
    switchTabToTasks : function(component, event) {
        var OppDetailsTab = component.find("oppDetId") ;
        var ProdDetailsTab = component.find("prodDetId") ;
        var OppDetailsData = component.find("oppDetBodyId") ;
        var prodDetailsData = component.find("prodDetBodyId") ;
        $A.util.addClass(ProdDetailsTab, 'slds-active');
        $A.util.removeClass(OppDetailsTab, 'slds-active');
        $A.util.removeClass(OppDetailsData, 'slds-show');
        $A.util.removeClass(prodDetailsData, 'slds-hide');
        $A.util.addClass(prodDetailsData, 'slds-show');
        $A.util.addClass(OppDetailsData, 'slds-hide');
        console.log("Tasks Active");
    },

    changeFilterForTask : function(component, event , helper) {
        console.log('inside controller changeSelection');
        var status = component.find("filterTask").get("v.value");
        console.log('status :',status);
        helper.reloadTaskList(component,status);
    },

    navigateBackToTaskApp: function(component, event , helper) {
        var name = 'c:SF1_TaskApp';
        var attributes={};
        helper.navigateToCmp(component, event, helper ,name ,attributes);
    },

    navigateToCreateNewTaskCmp : function(component, event , helper) {
        var name = 'c:SF1_TaskApp_CreateNewTask_Cmp';
        var oaID = component.get("v.orderApproval.Id");
        console.log('recordId from navigateToCreateNewTaskCmp :', oaID);
        var attributes={
            'recordId' : oaID,
            'comingFromTaskManagementApp' :true
        };
        helper.navigateToCmp(component, event, helper ,name, attributes);
    },

    goToOARecord  : function(component,event,helper){
        console.log('inside controller goToOARecord');
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        var oaId = component.get("v.orderApproval.Id");
        console.log('oaId :',oaId);
        if(sObjectEvent)
        {
            sObjectEvent.setParams({
                "recordId": oaId,
                "slideDevName": 'detail'
            })
            console.log('firing event');
            sObjectEvent.fire();
        }
        else
        {
            sforce.one.navigateToSObject(oaId, 'detail');
        }


    },

    goToTaskCustomInterface : function(component, event , helper) {
        var name = 'c:SF1_Component_TaskInterface';
        var taskId = event.currentTarget.id +'';
        var attributes={
            'taskId' : taskId
        };
        helper.navigateToCmp(component, event, helper ,name, attributes);
        /*
			var navEvt = $A.get("e.force:navigateToSObject");
			navEvt.setParams({
				"recordId": event.currentTarget.id,
				"slideDevName": "detail"
			});
			navEvt.fire();
			*/
        }
})