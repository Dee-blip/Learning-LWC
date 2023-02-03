({
	getRecordListHelper : function(cmp,evt,helper) {
        var that = this;
        var recVal = cmp.find("no_of_records").get("v.value");
        var viewCmp = cmp.find("ListViews");
        var viewVal = viewCmp.get("v.value");
        cmp.set("v.filterId",viewVal);
        var pageNum = cmp.find("pageInput").get("v.value");
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
        var re = new RegExp("^((CR)?[0-9]{1,8})$");
        if(searchVal){
        	searchVal = searchVal.trim();
            var searchFrom = 0;
            if(searchVal.indexOf("CR") >= 0){
            	searchFrom = 2;
            }
            searchVal = searchVal.substring(searchFrom);
            var zeroes = 8-searchVal.length;
           	for(var i=0;i<zeroes;i++){
            	searchVal = '0'.concat(searchVal);
            }
                
                
       	}
            
       		var incList = cmp.getEvent("getChangeListEvent");
        	incList.setParams({"numRecords":recVal,"fltrId":viewVal,"searchVal":searchVal,"pageNum":pageNum}).fire();
        	
        	//console.log('Fired');
        
        	/*window.setTimeout(
                $A.getCallback(function() {
                var searchCmp = cmp.find("searchInput");
                if(searchCmp == null)
                    return;
                searchCmp.set("v.value",null);
                window.clearTimeout(that.getRecordListHelper(cmp,evt,helper));
                that.getRecordListHelper(cmp,evt,helper);
            }), 200000
    );*/
        
	}
})