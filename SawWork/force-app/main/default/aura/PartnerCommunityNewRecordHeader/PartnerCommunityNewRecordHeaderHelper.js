({
	findLead : function(cmp,event,helper) {
        var navService = cmp.find("navService");
        var defaultValues;
        var action = cmp.get("c.getDefaultValues");
        var objectName = cmp.get("v.objectname");
        action.setParams(
            { 
                sObjectName : objectName,
                recId : ""
            }
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                defaultValues = response.getReturnValue();
            }
            else if (state === "ERROR") {
            	console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
        
        var pageReference = {
            
            type: "comm__namedPage",
            attributes: {
                name: "new-lead"
            },    
            state: {
                "sObjectName": "Lead"  ,
                "objectLabel": "Create Partner Lead",
                "customMetaDataObjName": "Lead",
                "currentRecordTypeId": "0120f000001IslP",
                "defaultValues": defaultValues,
                "returnValPrefix": "/partners/s"
            }
        };
        console.log('pageReference :'+pageReference);
        cmp.set("v.pageReference", pageReference);
        var defaultUrl = "#";
        navService.generateUrl(pageReference)
        .then($A.getCallback(function(url) {
            console.log('URL : '+url);
            cmp.set("v.url", url ? url : defaultUrl);
        }), $A.getCallback(function(error) {
            cmp.set("v.url", defaultUrl);
        }));
    }
})