({
   doInit : function(component, event, helper) {
       
       var navigationItemsJson = JSON.parse(sessionStorage.getItem('partnerQuickCreateCustom--records'));
       console.log('Quick creation component');
       if (navigationItemsJson != null) {
           console.log('Found items in cache');
           component.set("v.menuItems", navigationItemsJson);
       } else {
           helper.serverSideCall(component,event,helper,"c.getQuickCreateItems").then(
            function(response) {
                if (response != null) {
                    // Set the 'menuItems' variable back in the component.
                    sessionStorage.setItem('partnerQuickCreateCustom--records', JSON.stringify(response));
                    component.set("v.menuItems", response);
                }
            }
        ).catch(
            function(error) {
                component.set("v.status" ,error ); 
                console.log(error);
            }
        );
       }
       
    },
    
    scriptsLoaded : function(component, event, helper) {
         
      jQuery("document").ready(function(){
          console.log('scripts loaded');
      });
        
 	},
    
    onClick : function(component, event, helper) {
       console.log('Li clicked');
        console.log(event.target);
       var value = event.currentTarget.dataset.value;
        console.log('id :'+value);
        helper.serverSideCall(component, event, helper, "c.getButtonUrl",{objectName:value}).then(
            function(response) {
                console.log(response);
                var res = JSON.parse(response);
                console.log(res);
                console.log(res.Error);
                if (res.ERROR === undefined) {
                    component.set("v.showButton","true");
                    component.set("v.newButtonLink", res.URL);
                    component.set("v.objectLabel", res.Label);
                    component.set("v.type",res.type);
                    component.set("v.objectAPIName",res.objectAPIName);
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
                            "url": res.URL
                        });
                        urlEvent.fire();
                    }
                }
            }
        ).catch(
            function(error) {
                console.log(error);
                //helper.showToast(component,event,helper,"Error!","Error.","error",true);
            }
        );
     }
})