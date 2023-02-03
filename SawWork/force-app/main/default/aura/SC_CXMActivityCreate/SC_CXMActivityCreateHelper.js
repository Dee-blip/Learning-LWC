({
    showMyToast : function(component, event, helper,message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissable',
            message: message,
            type : type
        });
        toastEvent.fire();
    } ,

    parentFieldChange : function(component) {
        var childValues;
        var childValueList 
        var controllerField = component.find("parentField");
        var controllerValue = controllerField.get("v.value");
        var pickListMap = component.get("v.pickListMap");
        var i;

        if (controllerValue !== '--- None ---') {
             //get child picklist value
            childValues = pickListMap[controllerValue];
            childValues = childValues.sort();
            childValueList = [];
            childValueList.push('--- None ---');
            for (i = 0; i < childValues.length; i++) {
                childValueList.push(childValues[i]);
            }

            // set the child list
            component.set("v.childList", childValueList);
            
            if(childValues.length > 0){
                component.set("v.disabledChildField" , false);  
            }else{
                component.set("v.disabledChildField" , true); 
            }
            
        } else {
            component.set("v.childList", ['--- None ---']);
            component.set("v.disabledChildField" , true);
        }
    },
    handleSubjectChange : function(component) {
        var action;
        var parentkeys;
        var parentField;
        if(component.find("subject").get("v.value") === 'Product Feature Consideration'){
          component.set("v.showProductsAndFeatures",true);
        }else{
          component.set("v.showProductsAndFeatures",false);
        }
         action = component.get("c.getDependentPicklist");
            action.setParams({
                ObjectName : component.get("v.objectName"),
                parentField : component.get("v.parentFieldAPI"),
                childField : component.get("v.childFieldAPI")
            });
            
            action.setCallback(this, function(response){
               var status = response.getState();
               var pickListResponse;
               var pickKey;
               var i;
               var pickMap;
                if(status === "SUCCESS"){
                    pickListResponse = response.getReturnValue();
                    
                    //save response 
                    component.set("v.pickListMap",pickListResponse.pickListMap);
                    component.set("v.parentFieldLabel",pickListResponse.parentFieldLabel);
                    component.set("v.childFieldLabel",pickListResponse.childFieldLabel);
                    
                    // create a empty array for store parent picklist values 
                    parentkeys = []; // for store all map keys 
                    parentField = []; // for store parent picklist value to set on lightning:select. 
                    
                    // Iterate over map and store the key
                    pickMap = pickListResponse.pickListMap;
                    for (pickKey in pickMap) {
                        if(pickKey){
                        parentkeys.push(pickKey);
                        }
                    }
                    parentkeys = parentkeys.sort();
                    
                    //set the parent field value for lightning:select
                    if (parentkeys !== undefined && parentkeys.length > 0) {
                        parentField.push('--- None ---');
                    }
                    
                    for (i = 0; i < parentkeys.length; i++) {
                        if(i >= 0){
                        parentField.push(parentkeys[i]);
                        }
                    }  
                    // set the parent picklist
                    component.set("v.parentList", parentField);
                    
                }
            });
            
            $A.enqueueAction(action);
      }
})