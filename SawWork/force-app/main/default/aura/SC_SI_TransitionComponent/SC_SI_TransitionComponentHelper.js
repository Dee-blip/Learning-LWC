({
    handleInit : function(component, event, helper) {
        
        
        helper.getCurrentShift(component, event, helper);    
        
    },
    
    //mthod to get current shift.
    getCurrentShift : function(component, event, helper) {
        
        component.set("v.showSpinner",true);
        var getCurrentShift = component.get("c.getCurrentShiftDetails");
        
        
        
        getCurrentShift.setCallback(this, function(result)
                                    { 
                                        if(result.getState() == 'SUCCESS'){
                                            var res = result.getReturnValue();
                                            if(res == 'APAC')
                                                component.set("v.currentShift",'APJ');    
                                            else
                                                component.set("v.currentShift",res);
                                            component.set("v.showSpinner",false);   
                                            
                                        }    
                                    });
        $A.enqueueAction(getCurrentShift);
        
    },    
    
    //method to fetch new wake up time
    handleShiftChange : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var shift = "";
        shift = component.find("targetShift").get("v.value");//event.getSource().get("v.value");
        
        
        
        var getWakeTime = component.get("c.wakeUpTimeMethod");
        getWakeTime.setParams({
            "targetShiftTime": shift
        });
        
        getWakeTime.setCallback(this, function(result)
                                {
                                    
                                    if(result.getState() == 'SUCCESS'){
                                        var res = result.getReturnValue();
                                        
                                        component.set("v.wakeupTime",res);
                                    }  
                                    component.set("v.showSpinner",false);
                                });
        $A.enqueueAction(getWakeTime);
        
    },    
    
    handleCancel: function(component, event, helper) {
        debugger;
        if(component.get("v.fromSideSection") == true){
            component.set("v.showTransitionModal",false);
        }    
        else{
            var navEvent = $A.get("e.force:navigateToSObject");
            navEvent.setParams({
                recordId: component.get("v.recordId"),
                slideDevName: "detail"
            });
            navEvent.fire();
            $A.get('e.force:refreshView').fire();
        }            
        //$A.get("e.force:closeQuickAction").fire();
    },
    
    handleSubmit: function(component, event, helper) {
        //debugger;
        component.set("v.showSpinner",true);
        var notes = component.find("notes").get("v.value");
        var currentShift = component.get("v.currentShift");
        var suggestedBIL = component.get("v.selectedUserId");
        var targetShift = component.find("targetShift").get("v.value");
        var wakeUpTime = component.get('v.wakeupTime');
        if(targetShift == '' || notes == '' || notes == undefined){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "message": "Please fill required fields"
            });
            toastEvent.fire();
            component.set("v.showSpinner",false);
        }else{
            
            var saveTransition = component.get("c.saveTransition");
            saveTransition.setParams({
                "currentRecId" : component.get("v.recordId"),
                "notes": notes,
                "currentShift":currentShift,
                "newShift": targetShift,
                "wakeUpTime": wakeUpTime,
                "suggestedBIL":suggestedBIL,
                "previousOwner": component.get("v.previousOwner")
            });
            
            saveTransition.setCallback(this, function(result)
                                       {
                                           
                                           if(result.getState() == 'SUCCESS'){
                                               var res = result.getReturnValue();
                                               if(res == 'Success'){
                                                   var toastEvent = $A.get("e.force:showToast");
                                                   toastEvent.setParams({
                                                       "type": "Success",
                                                       "message": "Transition Record has been created"
                                                   });
                                                   toastEvent.fire();
                           
                        
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": "/"+component.get("v.recordId")
                        });
                        urlEvent.fire();
                        window.setTimeout(function(){
                          //  $A.get('e.force:refreshView').fire()
                          window.location.reload(true);
                        }, 1500);
                       // window.setTimeout(function(){window.location.reload(true)}, 1500);
                  //  }  
                    
                    
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "Error",
                        "message": res
                    });
                    toastEvent.fire();
                }
                
            }else{
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"Error",
                    "message": "Transition could not be performed , please contact Admin!!"
                });
                toastEvent.fire();
                
            }  
            component.set("v.showSpinner",false);
        });
            $A.enqueueAction(saveTransition);
        }
        
    }	
    
})