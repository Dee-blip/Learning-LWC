({
    /**
     *
     *
     * @param {*} component
     * @param {*} event
     * @param {*} helper
     */
    doInit : function(component, event, helper) 
    {
        console.log('Entering doInit of component SC_SOCC_Situation_to_Handler_Mapping');
        //Init Helper for Existing Situation to Handler Mappings
        helper.existingSHMapInitHandler(component, event, helper);
        helper.getRelevantSituationsHandler(component,event,helper);
        //helper.sortData(component,Situation__r.Name,helper);
        console.log('Exiting doInit of component SC_SOCC_Situation_to_Handler_Mapping');
    },
    
    /**
     *
     *
     * @param {*} component
     * @param {*} event
     * @param {*} helper
     */
    situationCatalogValueHandler:function(component, event, helper)
    {
        //making it blank initially
        component.set('v.selectedHandler','');
        component.set('v.HandlerOptions','');
        
        let SelectedSituationId = component.find("SituationSelect").get("v.value");
        
        //code block to disable buttons
        if(SelectedSituationId==='')
        {
            component.set('v.isdisabled',true);
        }
        else
        {
            component.set('v.isdisabled',false);
        }
        
        let pdid = component.get('v.recordId');
        var action = component.get("c.getHandlerPD");
        action.setParams({
            "situationId":SelectedSituationId,
            "pdId":pdid
        });
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                let result = response.getReturnValue();
                let lengthofresponse = Object.keys(result).length;
                if(lengthofresponse===0)
                {
                    component.set('v.isdisabled',true);
                    component.set('v.nohandlers',true);
                }
                else
                {
                    console.table(result);
                    component.set('v.nohandlers',false);
                    component.set('v.HandlerOptions',result);
                    component.set('v.selectedHandler',result[0].Id);
                }
            }
            
        });
        $A.enqueueAction(action);
        console.log('Exiting situationCatalogValueHandler of component SC_SOCC_Situation_to_Handler_Mapping');
    },
    
    /**
     *
     *
     * @param {*} component
     * @param {*} event
     * @param {*} helper
     */
    createSHMapping:function(component,event,helper)
    {
        let selectedSituationId = component.find("SituationSelect").get("v.value");
        let selectedHandlerId  =  component.find("HandlerSelect").get("v.value");
        let pdid = component.get('v.recordId');
        
        //check if situation is already present in situation array
        let exsistingSituationArray = component.get('v.SituationArray');
        
        //Check if the combination is already there
        let checkVariable = selectedSituationId+selectedHandlerId+pdid;
        let masterArray = component.get('v.SHMapExistingArray');
        if(masterArray.includes(checkVariable))
        {
            let title = "Error!";
            let message = 'Duplicate Situation to Handler Mapping';
            let type="error";
            helper.componentToastHandler(component,title,message,type);
            var appEvent = $A.get("e.c:shmaprefresh");
            appEvent.fire();
        }
        else if(exsistingSituationArray.includes(selectedSituationId))
        {
            let title = "Error!";
            let message = 'The Selected Situation is already tied to a handler';
            let type="error";
            helper.componentToastHandler(component,title,message,type);
            var appEvent = $A.get("e.c:shmaprefresh");
            appEvent.fire();
        }
            else
            {
                var action = component.get("c.createSituationToHandlerMapping");
                action.setParams({
                    "situationId":selectedSituationId,
                    "handlerId":selectedHandlerId,
                    "pdId":pdid
                });
                action.setCallback(this,function(response){
                    if(response.getState()==="SUCCESS")
                    {
                        let title = "Success!";
                        let message = 'Situation To Handler Mapping Has been Created';
                        let type="success";
                        helper.componentToastHandler(component,title,message,type);
                        var appEvent = $A.get("e.c:shmaprefresh");
                        appEvent.fire();
                        
                    }
                    else if (response.getState() === "ERROR") {
                        var errors = response.getError();
                        let errorMessage = "Darn it! Something went wrong! Please try again or contact your System Administrator!";
                        if(errors[0].message)
                            errorMessage = errors[0].message;
                        else if(errors[0].pageErrors[0].message)
                            errorMessage = errors[0].pageErrors[0].message;
                        helper.componentToastHandler(component,'Error',errorMessage,'error');   
                    }
                        else
                            helper.componentToastHandler(component,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error');
                    
                });
                $A.enqueueAction(action);          
            }
        
    },
    
    /*** Function to Delete a Mapping ***/
    deleteSHMapping:function(component,event,helper)
    {
        let shMapRecId=event.getSource().get("v.value");
        var action = component.get("c.deleteSHMappingRecord");
        action.setParams({
            "SHRecordId":shMapRecId,
        });
        action.setCallback(this,function(response){
            let state = response.getState();
            if(state === "SUCCESS")
            {
                let title = "Success!";
                let message = 'Situation to Handler Mapping Record Deleted';
                let type="success";
                helper.componentToastHandler(component,title,message,type);
                helper.existingSHMapInitHandler(component, event, helper);
                helper.getRelevantSituationsHandler(component,event,helper);
                var appEvent = $A.get("e.c:shmaprefresh");
                appEvent.fire();
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                let errorMessage = "Darn it! Something went wrong! Please try again or contact your System Administrator!";
                if(errors[0].message)
                    errorMessage = errors[0].message;
                else if(errors[0].pageErrors[0].message)
                    errorMessage = errors[0].pageErrors[0].message;
                helper.componentToastHandler(component,'Error',errorMessage,'error');   
            }
                else
                    helper.componentToastHandler(component,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error');
        });
        $A.enqueueAction(action);
    },
    
    /**
 * @description:Javascript function to Redirect to Handler Page and Close Modal
 * @param {*} component
 * @param {*} event
 * @param {*} helper
 */
    createHandler:function(component,event,helper)
    {
        let recordId = component.get('v.recordId');
        console.log('recordId '+recordId);
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__component",
            attributes: {
                componentName: "c__SC_SOCC_Create_Handler"
            },
            state: {
                "c__policyDomainId":recordId
            }
        };
        
        navService.navigate(pageReference);
        
    },
    
    sortTheColumn:function(component, event, helper){
       var fieldName = event.currentTarget.dataset.field;
       console.log('The field name '+fieldName);
       console.log('Calling sorting');
       helper.sortData(component,fieldName);
    }
    
})