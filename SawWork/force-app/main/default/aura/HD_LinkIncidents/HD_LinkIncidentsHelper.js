({
	getIncidentRecordsHelper : function(cmp) {
		
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
       
        var recordId = cmp.get("v.recordId");
        var action = cmp.get("c.getIncidentRecords");
            action.setParams({
                IncId : recordId,
                ticketNumber : searchVal
                
      		}); 
            action.setCallback(this,function(data){
                var response = data.getReturnValue();
                cmp.set("v.incidents",response);
                console.log("response length"+response.length);
                console.log(response);
    		});
			$A.enqueueAction(action);
	}
})