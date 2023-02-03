({
    initialize : function(component, event, helper) {
        helper.loadPickList(component, event);
    },
    
    top : function(component, event, helper) {
        window.location.hash = 'top';
    },
	
	select : function(component, event, helper) {
		helper.fetchDealDetails(component, event, false);
	},
    selectList : function(component, event, helper) {
		helper.fetchDealDetails_dummy(component, event, false);
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
                    cmp.set("v.loadButtonLabel","No more records"); 
                    var btn =  cmp.find("loadMoreButton");
                    document.getElementsByClassName('loadingButton')[0].style.width="30vh";
                    document.getElementsByClassName('loadingButton')[0].style.marginLeft="26%";
                    btn.set("v.disabled",true);
                }
            }
       
        });
        $A.enqueueAction(action);
    },
    waiting : function(component, event, helper)
    {
    	if(document.getElementById("oppSpinner") != null)
    	{
    		document.getElementById("oppSpinner").style.display = "block";
   		}
         component.set("v.loadButtonLabel","Loading.."); 
    },
    doneWaiting : function(component, event, helper)
    {
    	if(document.getElementById("oppSpinner") != null)
    	{
			document.getElementById("oppSpinner").style.display = "none";
		}
        if(component.get("v.loadButtonLabel") != "No more records")
        {
        component.set("v.loadButtonLabel","Load more"); 
        }

    },
    setSObjectType : function(component, event, helper)
    {
        var sObjectType = event.getParam("selectedSObject");
        component.set("v.sObjectName", sObjectType);
        component.set("v.currentOffset","0");
        helper.loadPickList(component, event);
        
    }
})