({
    getData : function(cmp) {
        var action = cmp.get('c.getPendingApprovals');
        action.setParams({incidentId : cmp.get("v.recordId")}); 
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                   cmp.set('v.mydata', response.getReturnValue());
            } else if (state === "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "error",
                        "message": response.getError()
                    });
                    toastEvent.fire();
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();

        }));
        $A.enqueueAction(action);
    }
})