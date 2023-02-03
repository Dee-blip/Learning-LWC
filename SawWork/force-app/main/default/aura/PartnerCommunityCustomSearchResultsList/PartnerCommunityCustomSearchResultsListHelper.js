({
	serverSideCall : function(component,event,helper,method,params) {
        return new Promise(function(resolve, reject) {
            console.log('SH : Helper from parent component');
            console.log('Adding spinner')
            //var spinner = helper.asArray(component.find("pageSpinner"));
            var spinner = component.find("pageSpinner");
        	$A.util.toggleClass(spinner, "slds-hide");
            var action = component.get(method);
        	if(params){
            	action.setParams(params);
        	}
            action.setCallback(this, 
                               function(response) {
                                   console.log('Removing spinner');
                                   $A.util.toggleClass(spinner, "slds-hide");
                                   var state = response.getState();
                                   if (state === "SUCCESS") {
                                       resolve(response.getReturnValue());
                                   } else {
                                       reject(response.getError());
                                   }
                               });
            $A.enqueueAction(action);
        });
    },
    
    populateRecords : function(component,event,helper,objJson) {
    	console.log('Obj json here');
        console.log(objJson);
        if (!$A.util.isUndefinedOrNull(objJson)) {
            var objArray = JSON.parse(objJson);
                    console.log(objArray);
                    var totalLength = 0;
                    var objectList = [];
                    var objectAPINamesList = [];
                    objArray.forEach((item) => {
                        if (item.length > 0) {
                            objectAPINamesList.push(item[0].attributes.type);
                        }
                    });
                    console.log(objectAPINamesList);
                    if (objectAPINamesList.length == 0) {
                        console.log('No results');
                        component.set("v.noRecords",true);
                    } else {
                        helper.serverSideCall(component,event,helper,"c.getObjectLabelMap",{objAPINames:objectAPINamesList}).then(
                            function(response) {
                                console.log('SH : conditions - response :'+response);
                                if (response != null) {
                                    console.log(response);
                                    objArray.forEach((item) => {
                                        totalLength = totalLength + item.length;
                                        if (item.length > 0) {
                                        objectList.push(
                                        {
                                        value:item, 
                                        length: item.length,
                                        key: item[0].attributes.type,
                                        label: response[item[0].attributes.type],
                                        active:false
                                    }
                                                    );
                                }
                            });
                        objectList[0].active = true;
                        component.set('v.objectList',objectList);
                        component.set("v.showSearch",true);
                    }
                }
                ).catch(
                    function(error) {
                        component.set("v.status" ,error ); 
                        console.log(error);
                    }
                );
            }
		}
	}
})