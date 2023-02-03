({
	componentGenerator : function(component,componentName,componentParameter) {
        
        var parameter = new Object();
        var cmppara = componentParameter.split(";");//looking for first set of delimiters
            for(var params in cmppara )
            {
               // console.log('params'+cmppara[params]);
                var iteratedParams = cmppara[params].split(":");
                parameter[iteratedParams[0]] = iteratedParams[1];//component.get("v.recordId");
            }
        	
           //console.log('-????'+JSON.stringify(parameter));
        $A.createComponent(
            componentName,//dynamicallty passing Component Name
            parameter,//dynamicaaly passing component object created
            function(newComp,status)
            {
                
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newComp);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    //console.log("Error: " + errorMessage);
                    console.log("Error");
                    // Show error message
                }
                
                
            }
        );
		
	},
})