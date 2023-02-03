({
	fetchDealDetails : function(cmp, event, overrideSelection) {
		cmp.set("v.ObjItems",null);
		var selection = cmp.find("selection").get("v.value");
		if(document.getElementById("searchBoxID") != null)
		{
			document.getElementById("searchBoxID").value = "";
	    }

	    if(overrideSelection)
	    {
	    	selection = cmp.get("v.listViewSelectOptions")[0];
	    	
	    }

		
		var action = cmp.get("c.getDetails");
		var sObjectName = cmp.get("v.sObjectName");
        var pageSize =cmp.get("v.pageSize");
        var offset = "0";
        if(pageSize == null)
        {
        	pageSize = "20";
        }
        var newOffset = String(parseInt(offset,10) +parseInt(pageSize,10));
        
		action.setParams({ "userSelection" : selection,
		 "objectType" : sObjectName,
		 "startValue" : offset,
         "pageSize" : pageSize});
		
		

        action.setCallback(this, function(response) {

			var state = response.getState();
			if (cmp.isValid() && state === "SUCCESS") {
				 var globalObjList = response.getReturnValue();
				 var listItemCount = globalObjList.length;	
				 cmp.set("v.ObjItems",globalObjList);
				 cmp.set("v.listItemCount",listItemCount);
				 cmp.set("v.userSelection", selection); 
				 cmp.set("v.currentOffset",newOffset);
				 cmp.set("v.pageSize",pageSize);
				 cmp.set("v.loadButtonLabel","Load more");
				 var btn =  cmp.find("loadMoreButton");
                 btn.set("v.disabled",false);
            }
       
		});
        $A.enqueueAction(action);
	},
    fetchDealDetails_dummy : function(cmp, event, overrideSelection){
        console.log('selection :',cmp.get("{!v.listName}"));

    }
})