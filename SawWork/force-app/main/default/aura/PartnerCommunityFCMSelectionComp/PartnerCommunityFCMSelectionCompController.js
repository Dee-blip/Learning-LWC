({
	doInit : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        helper.serverSideCall(component,event,helper,"c.getFCMValues",{recordId:recordId}).then(
            function(response) {
                console.log('SH : conditions - response :'+response);
                if (response != null) {
                    console.log(response);
                    var objectList = [];
                    for ( var key in response ) {
                        objectList.push({'label': response[key], 'value': key});
                    }
                    component.set('v.objectList',objectList);
                    console.log('Object list array - ');
                    console.log(objectList);
                    component.set('v.loadButtons','true');
                    //component.set("v.oppty", response);
                }
            }
        ).catch(
            function(error) {
                component.set("v.status" ,error ); 
                console.log(error);
            }
        );
	},
    
    updateRecordJS : function(component, event, helper) {
        let button = event.getSource();
    	button.set('v.disabled',true);
        var recordId = component.get("v.recordId");
        var selectedFCMValue = component.get("v.selectedValue");
        console.log('Select value :'+selectedFCMValue);
        component.set("v.isProgressing",'true');
        helper.toggleProgressBar(component,event,helper);
        helper.serverSideCall(component,event,helper,"c.updateRecord",{recordId:recordId,selectedFCM:selectedFCMValue}).then(
            function(response) {
                helper.toggleProgressBar(component);
                console.log('Successfully updated FCM');
                helper.showToast(component,event,helper,"Success!","Updated PAE.","success",true);
                if (component.getEvent("parentUpdateEvent") != null) {
                    var event = component.getEvent("parentUpdateEvent");
                    event.setParam("message", "refresh" );
                    event.fire();
                }
            }
        ).catch(
            function(error) {
                helper.toggleProgressBar(component);
                helper.showToast(component,event,helper,"Error!","Error updating PAE.","error",true);
                console.log(error);
                if (component.getEvent("parentUpdateEvent") != null) {
                    var event = component.getEvent("parentUpdateEvent");
                    event.setParam("message", "close" );
                    event.fire();
                }
            }
        );
    }
})