({
    initHelper: function(component, event, helper) {
        var action = component.get("c.GetFollowUpFields");
        component.set("v.isLoad", true);
        action.setParams({ recordId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.isLoad", false);
                var res = JSON.parse(response.getReturnValue());             
                component.set("v.fieldsFollowUp",JSON.parse(res.followUpFields));
                if (res.onLoadDate) {
                	component.set("v.Datetime", res.onLoadDate);
                } else {
                    var startDateTime = new Date();
                    component.set("v.Datetime", startDateTime.toISOString());
                }
                if (res.actualCompletionDate) {
                	component.set("v.setActualCompletionDate", false);
                } else {
                    component.set("v.setActualCompletionDate", true);
                }
            }
        });
        $A.enqueueAction(action);
    }
})