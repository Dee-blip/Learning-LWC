({
	fetchDealDetails : function(cmp, event, overrideSelection) {
		//cmp.set("v.ObjItems",null);
        var selection = cmp.get("{!v.listName}");
		
        if(overrideSelection)
	    {
	    	selection = cmp.get("{!v.listName}");
	    	
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
                cmp.set("v.loadDone",true);
				 var listItemCount = globalObjList.length;
                console.log('listItemCount :',listItemCount);
                if(listItemCount==0){
                     cmp.set("v.noRecordsPresent",true);
                }
                else{
                     cmp.set("v.loadButtonLabel","Load more");
                     var btn =  cmp.find("loadMoreButton");
                     btn.set("v.disabled",false);
                }
				 cmp.set("v.ObjItems",globalObjList);
				 cmp.set("v.listItemCount",listItemCount);
				 cmp.set("v.userSelection", selection); 
				 cmp.set("v.currentOffset",newOffset);
				 cmp.set("v.pageSize",pageSize);
				 
            }
       
		});
        $A.enqueueAction(action);
	}
})