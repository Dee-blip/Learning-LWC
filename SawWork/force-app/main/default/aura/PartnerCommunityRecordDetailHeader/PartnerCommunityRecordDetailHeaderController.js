({
    doInit : function(component, event, helper) {
        
        /* Call server method to get Object API name based on the record Id
         */
        var spinner = component.find("pageSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        //SFDC-9134
        //generateRebateDoclink();
        var methodName = "c.getObjectName";
        var params = { 
                        recordId : component.get("v.recordId")
                     };
        
        helper.serverSideCall(component, event, helper, methodName, params).then(
            function(response) {
                var returnVal;
                var action;
                var objectName = response;
                if (objectName == "Opportunity") {
                    //SFDC-9134
                    action = component.get("c.generateCDlink");
                    action.setCallback(this, function(res) {
                        var state = res.getState();
                        console.log('state ====> ' + state);
                        if(state === 'SUCCESS'){
                             console.log('here in success');
                            returnVal = res.getReturnValue();
                            console.log('returnVal ==> ' + returnVal);
                            component.set("v.rebateDocURL", returnVal);
                        }
                        });
                        $A.enqueueAction(action);
                    var opptyId = component.get("v.recordId");
                    component.set("v.sObjectName",objectName);
                    helper.serverSideCall(component,event,helper,"c.getOppty", {opptyId : opptyId}).then(
                        function(response) {
                            var res = response;
                            component.set("v.oppty", response);
                        }
                    ).catch(
                        function(error) { 
                            console.log(error);
                        }
                    );
                    //Get rebate terms and conditions
                    helper.serverSideCall(component, event, helper,"c.getRebateTermsConditions").then(
                        function(response) {
                            var res = response;
                            component.set('v.valuesMap',response);
                        }
                    ).catch(
                        function(error) {
                            console.log(error);
                        }
                    );
                }
                
            }
        ).catch(
            function(error) {
                console.log(error);
            }
        );
    },
    
    toggleSection : function(component, event, helper) {
        component.set("v.showSection" ,!component.get("v.showSection")) ;
    },
    
    acceptJS : function(component, event, helper) {
        /*Call apex accept method :
         * That will set the rebate Tc related field on oppty for accept
         */
        helper.serverSideCall(component, event, helper, "c.accept").then(
            function(response) {
                var res = response;
                console.log('Successful : showing success toast');
                helper.showToast(component,event,helper,"Success!","Successfully accepted rebate terms and conditions.","success",true);
                console.log('Firing event from child');
                var event = component.getEvent("parentUpdateEvent");
                if (event != null) {
                    event.setParam("message", "refresh" );
                	event.fire();
                }
            }
        ).catch(
            function(error) {
                console.log(error);
                console.log('Error : showing error message');
                helper.showToast(component,event,helper,"Error!","Error accepting rebate terms and conditions.","error",true);
            }
        );
        $A.get('e.force:refreshView').fire();
    },
    
    rejectJS : function(component, event, helper) {
        helper.serverSideCall(component,event,helper,"c.reject").then( 
            function(response) {
                var res = response;
                console.log('SH : response :'+res);
                console.log('Firing event from child');
                var event = component.getEvent("parentUpdateEvent");
                if (event != null) {
                    event.setParam("message", "close" );
                    console.log('Fire close event');
                	event.fire();
                }
            }
        ).catch(
            function(error) {
                let errorData = JSON.parse(error.message);
                console.error(errorData.name +" (code "+ errorData.code +"): "+ errorData.message);
            }
        );
        $A.get('e.force:refreshView').fire();
    },

    //SFDC-9134
    /*generateRebateDoclink : function(component){
        var returnVal;
        var action = component.get("c.generateCDlink");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                returnVal = response.getReturnValue();
                component.set("v.rebateDocURL", returnVal);
            }
        });
        $A.enqueueAction(action);
    }*/
})