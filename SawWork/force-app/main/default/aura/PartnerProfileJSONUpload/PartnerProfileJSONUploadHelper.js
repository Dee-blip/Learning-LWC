({
    sendPartnerProfiles : function(component){
        var action = component.get("c.TranslatePartnerDetailsMethod");
        action.setCallback(this,function(response){
            var state = response.getState();
            var result;
            if(state=='SUCCESS'){
                result = response.getReturnValue();
                component.set("v.Spinner", false);
            }
            else
            {
                result = "Received bad response from Apex controller."
            }
            component.find('notifLib').showNotice({
                "variant": "info",
                "header": "Status",
                "message": result,
                closeCallback: function() {}
        	});
        });
        $A.enqueueAction(action);
    },
    
    updatePartnerProfiles : function(component,event){
        var uploadedFiles = event.getParam("files");
        for(var i=0; i<uploadedFiles.length; i++)
        {
            var fileName = uploadedFiles[i].name;
            fileName = fileName.substring(0, fileName.length - 5);
            var action = component.get("c.updatePartnerProfiles");
            action.setParams({
                "documentName": fileName
            });
            action.setCallback(this,function(response){  
                var state = response.getState(); 
                var result;
                if(state=='SUCCESS'){  
                    result = response.getReturnValue();
                    component.set("v.Spinner", false);
                }
                else
                {
                    result = "Received bad response from Apex controller."
                }
                component.find('notifLib').showNotice({
                    "variant": "info",
                    "header": "Status",
                    "message": result,
                    closeCallback: function() {}
                });
            });  
        	$A.enqueueAction(action); 
        }
    }, 
 })