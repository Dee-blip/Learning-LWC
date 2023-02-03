({
    doInit: function(component, event, helper) {
        let pageUrl = window.location.pathname;
        //console.log('SH List View Header : page url :'+pageUrl);
        let objectName = pageUrl.split("/")[4];
        //alert('SH : objectName :'+objectName);
        component.set("v.objectname",objectName);
        
        helper.serverSideCall(component, event, helper, "c.getButtonUrl",{objectName:objectName}).then(
            function(response) {
                console.log(response);
                var res = JSON.parse(response);
                console.log(res);
                console.log(res.Error);
                if (res.ERROR === undefined && res.type != 'standard') {
                    component.set("v.showButton","true");
                    component.set("v.newButtonLink", res.URL);
                    component.set("v.objectLabel", res.Label);
                    component.set("v.type",res.type);
                    component.set("v.objectAPIName",res.objectAPIName);
                }
            }
        ).catch(
            function(error) {
                console.log(error);
                //helper.showToast(component,event,helper,"Error!","Error.","error",true);
            }
        );
    },
    
    navigateToNew: function(component) {
    	console.log('Clicked on navigate');
        console.log(component.get("v.type"));
        if (component.get("v.type") == "standard") {
            console.log('Fire standard record create');
            var objectAPIName = component.get("v.objectAPIName");
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": objectAPIName
            });
            createRecordEvent.fire();
        } else {
            console.log('non standard');
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": component.get("v.newButtonLink")
            });
            urlEvent.fire();
        }
    }
})