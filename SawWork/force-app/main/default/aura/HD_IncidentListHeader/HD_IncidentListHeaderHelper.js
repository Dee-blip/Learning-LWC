({
	getIncidentListHelper : function(cmp,evt) {
        var that = this;
        var sortBy = cmp.get("v.sortBy");
        var sortDirection = cmp.get("v.sortDirection");
       
        /*
        var sortBy = 'Name';
        var sortDirection = 'DESC';
      	if(typeof evt !='undefined')
        {
            
       	 	 sortBy = evt.getParam("sortBy");
        	 sortDirection = evt.getParam("sortDirection");
            
        }
        if(typeof sortBy =='undefined')
        {
            console.log('sortBy undefined');
            sortBy = 'Name';
            sortDirection = 'DESC';
        }*/
        var dynamicCmp = cmp.find("views");
        var recCmp = cmp.find("no_of_records");
        var recVal = recCmp.get("v.value");
        var viewCmp = cmp.find("ListViews");
        var viewVal = viewCmp.get("v.value");
        cmp.set("v.filterId",viewVal);
        var pageNum = cmp.find("pageInput").get("v.value");
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
        var re = new RegExp("^((IN|SR)?[0-9]{1,8})$");
        
            if(searchVal)
            {
                searchVal = searchVal.trim();
                var searchFrom = 0;
                if(searchVal.indexOf("IN")>=0||searchVal.indexOf("SR")>=0)
                {
                    searchFrom = 2;
                }
                searchVal = searchVal.substring(searchFrom);
                var zeroes = 8-searchVal.length;
                for(let i=0;i<zeroes;i++)
                {
                    searchVal = '0'.concat(searchVal);
                }
                
                
            }
       		var incList = $A.get("e.c:getIncidentList");
        	incList.setParams({"numRecords":recVal,"fltrId":viewVal,"searchVal":searchVal,"pageNum":pageNum,"sortBy":sortBy,"sortDirection":sortDirection}).fire();
        
        	/*window.setTimeout(
        	$A.getCallback(function() {
			var searchCmp = cmp.find("searchInput");
        	searchCmp.set("v.value",null);
            that.getIncidentListHelper(cmp,evt);
        }), 1800000
    );*/
        
	}
})