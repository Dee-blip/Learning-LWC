({
    handleCancel : function(component, event, helper) {
		window.location.href = '/'+component.get("v.opportunityId");
    },
    doInit : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getInitialValues");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                var res = response.getReturnValue();
                var timeoutVal = res['TimeoutVal'];
                var activityStatus = [];
                activityStatus = res['ActivityStatus'].split(',');
                var whereClause = " Partner__c = '" + component.get("v.partnerInvolved") + "'";
                var activityStatusCondition = '';
                for(var i=0;i<activityStatus.length;i++){
                    activityStatusCondition += "Activity_Status__c = '" + activityStatus[i] + "' OR ";
                }
                if(activityStatusCondition != ''){
                    activityStatusCondition = activityStatusCondition.substring(0, activityStatusCondition.length-4);
                    whereClause += ' AND ' + '(' + activityStatusCondition + ')';
                }
                component.set("v.whereClause",whereClause);
                setTimeout(function() {
                    component.set("v.showSpinner",false);
                }, timeoutVal);
            }else{
            }
        });
        $A.enqueueAction(action);
    },
    handleSave : function(component, event, helper) {
        component.set("v.pageMessage","");
        var pmaId = component.get("v.pmaId");
        if(pmaId == null){
            component.set("v.msgSeverity","error");
            component.set("v.pageMessage","Partner Marketing Activity is required.");
        }
        else{
            component.set("v.pageMessage","");
            component.set("v.showSpinner",true);
            var action = component.get("c.updateOpportunity");
            action.setParams({"pmaId":pmaId, "opportunityId":component.get("v.opportunityId")});
            action.setCallback(this,function(response) {
                component.set("v.showSpinner",false);
                var state = response.getState();
                if(state === "SUCCESS"){
                    var res = response.getReturnValue();
                    if(res == 'success'){
                        component.set("v.msgSeverity","confirm");
                        component.set("v.pageMessage","Partner Marketing Activity updated successfully.");
                        window.location.href = '/'+component.get("v.opportunityId");
                    }
                    else{
                        component.set("v.msgSeverity","error");
                        component.set("v.pageMessage",res);
                    }
                }else{
                    component.set("v.msgSeverity","error");
                    component.set("v.pageMessage","ERROR");
                }
            });
            $A.enqueueAction(action);
        }
    }
})