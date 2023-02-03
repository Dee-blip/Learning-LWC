({
	initialize : function(component, event, helper) {
        console.log('inside initilaize');
        helper.fetchDealDetails(component,event, true);
		
	},
    gotoRecord : function(component, event, helper) {
		var selectedItem = event.currentTarget; // Get the target object
   		var index = selectedItem.dataset.record; // Get its value i.e. the index
     	var selectedObj = component.get("v.ObjItems")[index]; // Use it retrieve the store record
		var sObjectEvent = $A.get("e.force:navigateToSObject");
		sObjectEvent.setParams({
        	"recordId": selectedObj.Id,
			"slideDevName": 'detail'
		})

		sObjectEvent.fire();

	},
        LoadMoreResults: function(cmp, event, helper) {
       
        var selection = cmp.get("v.userSelection");        
        var sObjectName = cmp.get("v.sObjectName");
        var offset =cmp.get("v.currentOffset");
        var pageSize =cmp.get("v.pageSize");
        var newOffset = String(parseInt(offset,10) +parseInt(pageSize,10));


        var action = cmp.get("c.getDetails");
        action.setParams({ "userSelection" : selection,
         "objectType" : sObjectName,
        "startValue" : offset,
        "pageSize" : pageSize});
        
        

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") {
                 var limitedList = response.getReturnValue();

                if(limitedList.length >0)
                {
                 var globalObjList = globalObjList.concat(limitedList);
                 var listItemCount = globalObjList.length;  
                 cmp.set("v.ObjItems",globalObjList);
                 cmp.set("v.listItemCount",listItemCount);
                 cmp.set("v.currentOffset",newOffset);
                 
                }
                else
                {
                    cmp.set("v.loadButtonLabel","No More Records"); 
                    var btn =  cmp.find("loadMoreButton");
                    btn.set("v.disabled",true);
                    document.getElementsByClassName('loadingButton')[0].style.width = "45vw";
                }
            }
       
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {
       if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "block";
        } 
    },
        
    hideSpinner : function(component,event,helper){
        if(document.getElementById("oppSpinner") != null)
        {
            document.getElementById("oppSpinner").style.display = "none";
        }
    }
})