({
    doInit: function (component) {
        let featureAccessAction = component.get("c.hasFeatureAccess");
        featureAccessAction.setParams({
            customPermission: 'HD_Pilot_Users'
        });
        featureAccessAction.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                component.set('v.showNewUI', result.getReturnValue());
            }
            else if (result.getState() === 'ERROR') {
                let errors = result.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(featureAccessAction);
    },
    changeView: function (component, event) {
        var action = event.getParam("current_view");
        component.set("v.current_view", action || "cal"); //setting current-view to cal in case of events failure
    }
})