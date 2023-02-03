({
	doInit : function(component,event,helper) {
        
        var completeUrl = window.location.href;
        var hostname = window.location.hostname;
        var pageUrl = completeUrl.replace(hostname,'');
        console.log('page url :'+pageUrl);
        
        if (window.location.href.includes('form')) {
            console.log("Object creation is form based. Load Generic Form");
            var exeAction = component.get("c.getDefaultValues");
            exeAction.setParams(
                { 
                    url : pageUrl
                }
            );
            helper.serverSideCall(component,exeAction).then(
                function(response) {
                    var res = JSON.parse(response)
                    console.log(res);
                    component.set("v.sObjectName", res.sObjectName);
                    component.set("v.objectLabel", res.objectLabel);
                    component.set("v.customMetaDataObjName", res.customMetaDataObjName);
                    //console.log(res.currentRecordTypeId);
                    component.set("v.currentRecordTypeId", res.currentRecordTypeId);
                    component.set("v.defaultValues", res.defaultValues);
                    component.set("v.returnValPrefix",res.returnValPrefix);
                    //console.log('SH : All values are set');
                    component.set("v.parentLoaded", "true");
                }
            ).catch(
                function(error) {
                    component.set("v.status" ,error ); 
                    console.log(error);
                }
            );
        } else if (window.location.href.includes('standard')) {
            console.log('Fire standard record create');
            //var url = new URL(url_string);
            console.log(completeUrl);
			//var objectAPIName = url.searchParams.get("sObjectName");
			var objectAPIName = completeUrl.replace(/.*sObjectName=([^&]*).*|(.*)/, '$1');
            console.log(objectAPIName);
            
            window.setTimeout(
                $A.getCallback(function() {
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": objectAPIName
                    });
                    createRecordEvent.fire();
                }), 800
            );
        }
    }
})