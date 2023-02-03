({
    fetchRecords : function(component, event, helper) 
    {
        let recordId = component.get("v.recordId");
        var actionFieldMappings = component.get("c.getHandlerFieldMappings");
        actionFieldMappings.setCallback(this,function(responseNew){
            if(responseNew.getState()==="SUCCESS")
            {
                component.set("v.fieldsToShow",responseNew.getReturnValue());
                var action = component.get("c.getSituationToHandlerMappingsHandlerEscalationContacts");
                action.setParams({
                    pdId: recordId
                });
                action.setCallback(this, function(response){
                    if (response.getState() === "SUCCESS") 
                    {
                        let result = response.getReturnValue();
                        if(result.length > 0){
                            component.set('v.displayHandler',true);
                            component.set('v.displayMasterEditOption',true);
                        }
                        
                        component.set("v.ExistingSHMap", result);
                        component.set("v.lFilteredSHMap", result);
                        let handlerIdList=[];
                        let handlercount = [];
                        //Get unique handler count
                        Object.keys(result).forEach(key => {
                            handlercount.push(result[key].Handler__c);
                            handlerIdList.push(result[key].Handler__c); 
                        });
                        component.set('v.handlerIdList',handlerIdList);
                        component.set("v.noofhandlers",Array.from(new Set(handlercount)).length);
                        //component.set('v.ExistingSHMap',result);
                        
                    }
                });
                $A.enqueueAction(action); 
            }
        });
        $A.enqueueAction(actionFieldMappings);
    },
    filterRecords : function(component, event, helper) 
    {
        //Search Term
        let searchTerm = component.get("v.searchTerm");
        //All data
        let allData = component.get("v.ExistingSHMap");
        //Table data
        let data = component.get("v.lFilteredSHMap");
        
        // check is data is not undefined and its lenght is greater than 0
        if(data!=undefined || data.length>0)
        {
            // filter method create a new array that passes the search criteria (provided as function)  
            let filteredData = Object.values(allData).filter(word => (!searchTerm) || word.SHMap.Situation__r.Name.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || word.SHMap.Handler__r.Name.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || word.SituationNameList.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1);  
            console.log('filteredData'+filteredData);
            component.set("v.lFilteredSHMap", filteredData);
        }
    },
    
    onlyUnique:function(value, index, self) { 
        return self.indexOf(value) === index;
    },
    
    getHandlerEscalationContacts: function(component, event, helper) {
        
        console.log('here');
        console.log(component.get('v.handlerRecId'));
        let handlerId = component.get('v.handlerIdList');
        /*** First do a server Call and Get Escalation Id ***/
        let action = component.get("c.getHandlerEscContactList");
        action.setParams({
            "handlerIdList":handlerId
        });
        action.setCallback(this,function(response){
            console.log(response.getState());
            if(response.getState()==="SUCCESS")
            {
                console.log(response.getReturnValue());
                let returnValue = response.getReturnValue();
                let HandlerEscalationListObject = [];
                let HandlerEscalationContactObject = [];
                Object.keys(returnValue).forEach(key=>{
                    let keyofObject = returnValue[key].Handler.Id;
                    let valueofObject = returnValue[key].Handler;
                    let valueofObject2 = returnValue[key].EscalationContact;
                    
                    HandlerEscalationListObject.push({keyofObject,valueofObject});
                HandlerEscalationContactObject.push({keyofObject,valueofObject2});
                                                     
                                                    });
                                                     
                                                     component.set('v.HandlerEsclationList',HandlerEscalationListObject);
                                                     component.set('v.HandlerEscalationContact',HandlerEscalationContactObject);                                         
                                                     console.log(HandlerEscalationListObject);
                                                     console.log(HandlerEscalationContactObject);
                                                     
                                                     
                                                    }
                                                    });
                                                     $A.enqueueAction(action);
                                                     
                                                     
                                                    },})