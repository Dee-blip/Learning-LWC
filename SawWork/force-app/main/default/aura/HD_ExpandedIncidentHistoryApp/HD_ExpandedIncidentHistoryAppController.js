({
	doInit : function(component, event, helper) {
        var url = window.location.href;
        var queryValue = url.substring( url.indexOf('?') + 1 );//You will get the Query String
        var queryid = url.split("#")[1];
        var incId = null;
        var rowCount = null;
        if(queryid.indexOf('?') === -1)
        {
           queryid = queryid;
           incId = queryid;
        }
        else
        {
          incId = queryid.split("?")[0];
          rowCount =  queryValue.split("=")[1]; 
        }
        console.log(queryid +'--> '+ queryValue);
        
        component.set("v.incidentId",incId);	
        component.set("v.initComplete",true); 
        component.set("v.startTime",new Date());
        component.set("v.rowCount",queryValue.split("=")[1]);
        console.log("Inc id: "+component.get("v.incidentId")+ " rowCount -->"+rowCount);

	}
})