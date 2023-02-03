({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var getRelatedObjAction = component.get("c.getRelatedObjects");
        getRelatedObjAction.setParams(
            {
                recordId : recordId
            }
        );
        helper.serverSideCall(component,getRelatedObjAction).then(
            function(response) {
                console.log('SH : conditions - response :'+response);
                if (response != null) {
                    
                    var objectList = [];
                    for ( var key in response ) {
                        objectList.push({value:objectList[key], key:key});
                    }
                    component.set('v.objectList',objectList);
                    console.log('Map :'+response);
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
    
    navigateToRelatedButton : function(component, event, helper) {        
        var recordId = component.get("v.recordId");
        console.log('SH : object:'+event.getSource().get("v.title"));
        var objectLabel = event.getSource().get("v.title"); 
        var getURLAction = component.get("c.getButtonUrl");
        getURLAction.setParams(
            {
                objectLabel : objectLabel,
                recordId : recordId
            }
        );
        helper.serverSideCall(component,getURLAction).then( 
            function(response) {
                var res = JSON.parse(response);
                var url = res['URL'];
                url += '&parentId='+recordId;
                //console.log('Response :'+JSON.parse(response).URL);
                var urlEvent = $A.get("e.force:navigateToURL");
        		urlEvent.setParams({
            		"url": url
                });
                urlEvent.fire();
            }
        ).catch(
            function(error) {
                component.set("v.status" ,error ); 
                console.log(error);
            }
        );
        
        
    }
})