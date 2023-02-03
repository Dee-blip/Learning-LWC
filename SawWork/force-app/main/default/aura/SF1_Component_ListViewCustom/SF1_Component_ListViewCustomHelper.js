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
				 cmp.set("v.ObjItemsResult",globalObjList);
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
        cmp.set("v.ObjItems",null);
        var selection = cmp.get("itemSelected");
        console.log('selection :',selection);
		
    },

    localSearchOnKeyChange: function(component) {
       
       
        var searchKey = event.target.value;
        var objList = component.get("v.ObjItemsResult");
        var objListNew = new Array();
        var j =0;
        for (let i = 0; i < objList.length; i++) 
        { 
            if(objList[i].Name != null)
            {
        	   var localObjName = objList[i].Name.toUpperCase();
    		  if( localObjName.includes(searchKey.toUpperCase()))
    		  {
				objListNew[j] = objList[i];
				j++;
    		  }
            }

		}
              var btn =  component.find("loadMoreButton");
              $A.util.removeClass(btn, "hideButton");
		if(searchKey == null)
		{
			objListNew = objList;
           
      

		}
        else
        {
            var btn =  component.find("loadMoreButton");
            $A.util.addClass(btn, "hideButton");
        }
        var listItemCount = objListNew.length;
        component.set("v.ObjItems",objListNew);
        component.set("v.listItemCount",listItemCount);
    },


	loadPickList : function(cmp, event) {
		
		
		var action = cmp.get("c.getListViewLabels");
		var sObjectName = cmp.get("v.sObjectName");
		var useFilter = cmp.get("v.useFilter");
		if(useFilter == null)
		{
			useFilter = true;
		}
		action.setParams({ "objectType" : sObjectName,
						   "useFilter" :useFilter 
						});
		var self = this;

        action.setCallback(this, function(response) {

			var state = response.getState();
			if (cmp.isValid() && state === "SUCCESS") {
				 var lvLabels = response.getReturnValue();
				 cmp.set("v.listViewSelectOptions",lvLabels);
				 cmp.set("v.ObjItems",null);

				 //self.fetchDealDetails(cmp,event, true);
            }
           
       
		});
        $A.enqueueAction(action);
        
	}
})