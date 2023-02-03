({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.getMapOfFieldNamesvsApiName");
        action.setParams({
            "sObjectName": component.get("v.sObjectName")
        });
        
        action.setCallback(this, function(response) {
            var listOfFieldNames = [];
            var mapOfFieldNamesvsApiName = {};
            var state = response.getState();
            mapOfFieldNamesvsApiName = response.getReturnValue();
            console.log('mapOfFieldNamesvsApiName :',mapOfFieldNamesvsApiName);
            if (component.isValid() && state === "SUCCESS") 
            {   
                component.set("v.mapOfFieldNamesvsApiName",mapOfFieldNamesvsApiName);
            }
            
            for(let fieldName in mapOfFieldNamesvsApiName){
                listOfFieldNames.push({value:fieldName});
            }
            component.set("v.listOfFieldNames",listOfFieldNames);
            
            var currentSortByMap = component.get("v.sortBy");
            var listOfFieldNames = component.get("v.listOfFieldNames");
            
            
            
        });
        $A.enqueueAction(action);
    }
    ,
    hideVisibleAfterClickingOnSort : function(component, event, helper) {
        helper.hideVisibleAfterClickingOnSort(component, event, helper);	
    },
    showSortDetails : function(component, event, helper) {
        var eventValue= event.getParam("sortingOrder");
        var currentSortByMap = {};
        var fieldName,ascOrDesc;
        if(eventValue && eventValue!="")
        {
            eventValue = eventValue.split("##");
            fieldName = eventValue[0];
            ascOrDesc = eventValue[1];
            currentSortByMap[fieldName] = ascOrDesc;
            component.set("v.sortBy",currentSortByMap);
        }
        
        else
            document.getElementById("visibleAfterClickingOnSort").style.display="flex";
        
    },
    
    applyTheSortingSelected : function(component, event, helper) {
        var currentSortByMap = component.get("v.sortBy");  //containingasc desc order of fields
        console.log('currentSortByMap :',currentSortByMap);
        var mapOfFieldNamesvsApiName= component.get("v.mapOfFieldNamesvsApiName");
        var orderByQueryPart="";
        
        for(let fieldName in currentSortByMap)
        {
            if(mapOfFieldNamesvsApiName[fieldName])
                orderByQueryPart = orderByQueryPart + mapOfFieldNamesvsApiName[fieldName]+" "+currentSortByMap[fieldName]+", ";
        }
        
        orderByQueryPart = orderByQueryPart.substring(0,orderByQueryPart.length-2);
        console.log("orderByQueryPart :"+orderByQueryPart);
        console.log("----x----x----x----x----x----x----x----");
        
        var setEvent = $A.get("e.c:SF1_orderByQueryComponentEvent");
        setEvent.setParams({
            "orderByString":orderByQueryPart
        });
        setEvent.fire();
        
        /*
        var listOfRecordsToBeSorted= [];
        listOfRecordsToBeSorted = component.get("v.listOfRecordsToBeSorted");
        for(i in listOfRecordsToBeSorted)
        {
          //console.log(i,":",listOfRecordsToBeSorted[i].StageName);
        }
        console.log("----x----x----x----x----x----x----x----");
        */
        
        helper.hideVisibleAfterClickingOnSort(component, event, helper);
        
        //pass orderByQueryPart to the component from where sort has been called , 
        //in this case SF1_LocateOpportunityQuickAction , call the getItems method again , 
        //build query using soqlbuilder and use currentSortByMap to implement order by clause,
        //load the data again , resetting all the other variables of pagination.
        //passing listOfRecordsToBeSorted to this component not required .
        
        
        
    }
    
})