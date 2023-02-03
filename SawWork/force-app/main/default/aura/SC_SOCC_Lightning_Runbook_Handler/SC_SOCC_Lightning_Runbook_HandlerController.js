({
    doInitnow : function(component, event, helper) {
        var rec=component.get("v.recordId");
        if (typeof(rec) != "undefined" && rec!=null)
        {	
            if(rec.includes("500"))
            {
                component.set("v.showRunBookDetails","false");
                var action = component.get("c.getCaseHandlerDetails");
                action.setParams({
                    "caseId": rec
                });
                action.setCallback(this, function(response) {
                    var returnval = response.getReturnValue();
                    if(returnval.StatusMessage=='Success'){
                        component.set("v.showRunBookDetails","true");
                        component.set("v.RunBookDetails",returnval.HandlerDetails);
                        var pdId=returnval.PolicyDomID;
                        var escalationListId=returnval.EscListID;
                        var isEditPage=false;
                        //setTimeout(function(){ 
                            var escalationContactEditSection = component.find("escalationContactEditSections");
                            escalationContactEditSection.getEscConData(pdId, escalationListId, isEditPage,true);
                        //}, 500);
                        
                    }
                    else 
                    {
                        component.set("v.showRunBookDetails","false");
                        component.set("v.CaseStatus",returnval.StatusMessage);
                    }
                });
                $A.enqueueAction(action);
            }
            else
            {
                component.set("v.showRunBookDetails","false");
                component.set("v.CaseStatus","Please navigate to a Case record page to view Runbook Instructions!");   
            }
        }
    },
    openNewTab:function(component, event, helper) {
        var ID = event.target.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                
                workspaceAPI.openTab({
                    pageReference: {
                        "type": "standard__recordPage",
                        "attributes": {
                            "recordId":ID,
                            "actionName":"view"
                        },
                        "state": {}
                    },
                    focus: true
                }).then(function(response) {
                    workspaceAPI.getTabInfo({
                        tabId: response
                    }).then(function(tabInfo) {
                    });
                }).catch(function(error) {
                    console.log(error);
                });
            }
            else
            {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": ID
                });
                navEvt.fire();
            }
        })
        .catch(function(error) {
        });
    }
    
})