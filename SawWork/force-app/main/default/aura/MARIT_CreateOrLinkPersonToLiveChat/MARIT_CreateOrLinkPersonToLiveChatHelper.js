({
	doInitHelper : function(component, event, helper) {
        var action = component.get('c.CheckIfLCAlreadyLinked');
        action.setParams({
            "LiveChatId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var data = JSON.parse(response.getReturnValue());
                if (data != null && data.Id != null) { 
                    component.set("v.selectedIndexId", data.Id);
                    component.set("v.personRecordName", data.Name);
                    component.set("v.isPersonLinked", true);
                    component.set("v.isFindorLinkButtonVisible", false);
                }
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    handleClickHelper : function(component, event, helper) {
        var searchText = component.get('v.searchText');
        var action = component.get('c.searchForIds');
        action.setParams({searchText: searchText});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var listIds = [];
                var length = response.getReturnValue().length;
                for(var i = 0 ; i < length ; i++) {
                    listIds.push(JSON.parse(response.getReturnValue()[i]));
                }
                component.set("v.recordIds", listIds);
            }
        });
        $A.enqueueAction(action);
    },
    linkpersontolivechatHelper : function(component, event, helper) {
        var index = component.get('v.recordIndex');
        var listItems = component.get('v.recordIds');
        var action = component.get('c.LinkPersonToLiveChat');
        action.setParams({
            "LiveChatId": component.get("v.recordId"),
            "personId": listItems[index].Id,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var data = JSON.parse(response.getReturnValue());
                if (data != null) {
                    $A.get('e.force:refreshView').fire();
                    component.set("v.selectedIndexId", data.Id);
                    component.set("v.personRecordName", data.Name);
                    component.set("v.isPersonLinked", true);
                    component.set("v.islistPopulated", false);
                }
            }
        });
        $A.enqueueAction(action);
    },
    backToSearchHelper : function(component, event, helper) {
        var action = component.get('c.IsC2ALinkedToLiveChat');
        action.setParams({
            "LiveChatId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var msg = response.getReturnValue();
                $A.get('e.force:refreshView').fire();
                if (msg === 'C2A Exists') {
                    alert("Cannot go back when C2A is linked!!!"); 
                } else if (msg === 'Successful'){
                    component.set("v.isPersonLinked", false);
                    component.set("v.islistPopulated", true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    hideLeadSection : function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            console.log(params);
            component.set("v.selectedIndexId", params.mlLeadId);
            component.set("v.personRecordName", params.personLeadName);
        }
        $A.get('e.force:refreshView').fire();        
        component.set("v.isPersonLinked", true);
        component.set("v.isCreatePersonClicked", false);
        component.set("v.islistPopulated", false);
    }
})