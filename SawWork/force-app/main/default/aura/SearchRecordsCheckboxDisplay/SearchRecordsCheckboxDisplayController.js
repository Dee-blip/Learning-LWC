({
    //IW
    doInit : function(component, event, helper){
        var action = component.get("c.getAllRecs");
        var queryString = component.get("v.queryString");
        var fieldAPIName = component.get("v.fieldAPIName");
        var objectType = component.get("v.objectType");
        action.setParams({ queryString : queryString, objectType : objectType,fieldAPIName : fieldAPIName});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                                
                var lAvailVales = response.getReturnValue();
                var selectedValuesString = component.get("v.selectedValuesParam");
                var lSelectedValues;
                console.log('selectedValuesString---child'+selectedValuesString);
                if(selectedValuesString != "" && selectedValuesString != null){
                    lSelectedValues = selectedValuesString.split(",");
                    for(var i=0; i<lSelectedValues.length; i++){
                        lAvailVales.splice(lAvailVales.indexOf(lSelectedValues[i].trim()),1);
                    }
                    lSelectedValues.sort();
                }
				lAvailVales.sort();        		
	        	component.set("v.avaliableOpts",lAvailVales);
    	    	component.set("v.allAvaliableOpts",lAvailVales);
        		component.set("v.selectedOpts",lSelectedValues); 
        		component.set("v.availableCount",lAvailVales.length);
                if(lSelectedValues !== undefined){
                    component.set("v.selectedCount",lSelectedValues.length);
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);        
    },
    
	itemSelected : function(component, event, helper) {          
        var valueSelected = event.getSource().get("v.value");
		var ctarget =  event.currentTarget;
        var checkValue =  event.getSource();
    	var id_str = 1;
        //parseInt(ctarget.dataset.value);            	
        var selectedValue = component.get("v.avaliableOpts");
        var lSelectedValues = component.get("v.selectedOpts");
        var lAllAvaliValue = component.get("v.allAvaliableOpts");
        //var valueSelected = selectedValue[id_str];
        if(!lSelectedValues){
            lSelectedValues = [];
        }
        lSelectedValues.push(valueSelected);
        selectedValue.splice(selectedValue.indexOf(valueSelected),1);
        lAllAvaliValue.splice(lAllAvaliValue.indexOf(valueSelected),1);
        selectedValue.sort();
        lAllAvaliValue.sort();
        lSelectedValues.sort();
        component.set("v.avaliableOpts",selectedValue);
        component.set("v.allAvaliableOpts",lAllAvaliValue);
        component.set("v.selectedOpts",lSelectedValues);
        component.set("v.selectedCount",lSelectedValues.length);
        component.set("v.availableCount",lAllAvaliValue.length);
        //helper.invokeEventHelper(component, event, helper);
        
	},
    
    itemDeselected : function(component, event, helper) {
    	//var targetValue = event.currentTarget;
    	//var deselectedIndex = parseInt(targetValue.dataset.value);
        var valueDeselected = event.getSource().get("v.value");        
        var lAvailValues = component.get("v.avaliableOpts");
        var lSelectedValues = component.get("v.selectedOpts");
        var lAllAvailValues = component.get("v.allAvaliableOpts");
        var searchString = component.get("v.searchString");        
        if((searchString != null || searchString != "")
           && valueDeselected.toLowerCase().includes(searchString.toLowerCase())){
            lAvailValues.push(valueDeselected);
        }
        
        lAllAvailValues.push(valueDeselected);
        lSelectedValues.splice(lSelectedValues.indexOf(valueDeselected),1); 
        lAvailValues.sort();
        lAllAvailValues.sort();
        lSelectedValues.sort();
        component.set("v.avaliableOpts",lAvailValues);
        component.set("v.allAvaliableOpts",lAllAvailValues);
        component.set("v.selectedOpts",lSelectedValues);
        if(lSelectedValues !== undefined){
        component.set("v.selectedCount",lSelectedValues.length);
        }
        if(lAllAvailValues !== undefined){
        component.set("v.availableCount",lAllAvailValues.length);
        }
         helper.invokeEventHelper(component, event, helper);
    },
    
    searchProducts : function(component,event,helper){
        var searchString = component.get("v.searchString");
        var lAvailValues = component.get("v.avaliableOpts");
        var lAllAvailValues = component.get("v.allAvaliableOpts");
        var lSearchResults = [];
        var delayTimer;
        clearTimeout(delayTimer);
    	delayTimer = setTimeout(function() {
        // Do the ajax stuff
        for(var i = 0; i < lAllAvailValues.length; i++){            
            var incomingName = lAllAvailValues[i].toLowerCase();
            var sc = searchString;            
            if(lAllAvailValues[i].toLowerCase().includes(searchString.toLowerCase())){
                lSearchResults.push(lAllAvailValues[i]);
            }
        }
        component.set("v.avaliableOpts",lSearchResults); 
    	}, 1000);        
             
    },
    
    showSpinner : function(component,event,helper){
        component.set("v.spinner",true); 
        
    },
    hideSpinner : function(component,event,helper){
    	component.set("v.spinner",false);
	},
    

    
})