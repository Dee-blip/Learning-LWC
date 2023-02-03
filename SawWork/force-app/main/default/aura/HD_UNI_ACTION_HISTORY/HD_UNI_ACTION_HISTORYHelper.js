({
	ActionHistoryDataParserHelper : function(component,event) {
	    var actionHistoryDataRaw = component.get("v.actionHistoryData");
        var actionData = component.get("v.actionData");
        
        //Base logic here for data iteration
        var data = [];
        data.push(actionHistoryDataRaw);

        
        //Setting the component data value once the processing has been done
         component.set("v.actionData",data);
        
       // console.log('UNI Action >>>>> '+ JSON.stringify(data,null,2))
	}
})