({
    initHelper: function(component, event, helper) {
        var action = component.get("c.getLeadObj");
        action.setParams({ leadId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                if (res !== null && res.lObj != null && res.lObj !== undefined) {
                    component.set("v.leadRecord", res.lObj);
                    component.set("v.showBody", true);
                }
                if (res.uraObj === null || (res.uraObj!==null && !res.uraObj.HasEditAccess)) {
                    component.set("v.isPathReadOnly", true);
                    //helper.disableLightingPath(component, event, helper);
                }
                if (res.lObj !== null && (res.lObj.Status === 'Closed' || res.lObj.Status==="Converted")) {
                    component.set("v.isPathReadOnly", true);
                }
            }
            else if (state === "ERROR")
            {
                return 'Failed';
            }
        });
        $A.enqueueAction(action);
    },
    /*onRenderhelper: function(component, event, helper) {
        var obj = component.get("v.leadRecord");
        if (obj !== undefined && (obj.Status === 'Closed' || obj.Status==="Converted")) {
            helper.disableLightingPath(component, event, helper);
            component.set("v.hideUpdateButton", true);
        }
    },*/
    handleSelecthelper: function(component, event, helper) {
        var stepName = event.getParam("detail").value;
        component.set("v.statusValue", stepName);
        component.find('childlwc').getFiredFromAura();
    },
    /*disableLightingPath : function (component, event, helper) {
        // this will be called when CTA lead status is closed or converted
        var cmpTarget = component.find('path');
        $A.util.addClass(cmpTarget, 'changeMe');
    }*/
})