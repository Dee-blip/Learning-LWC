/** Client-Side Controller **/
({
    initialize: function (component, event, helper) {
        
        var columnAPIMap = component.get("v.colMap");
       
        var options = [];
        for(var key in columnAPIMap){
            
            options.push({value:key,label:columnAPIMap[key]});
        }
        
        var values = [];
        var columns = component.get("v.colOptions");
        
        component.set("v.listOptions", options);
        
        component.set("v.defaultOptions", columns);
        component.set("v.finalColumns",columns);
        
    },
    handleChange: function (component, event, helper) {
        // Get the list of the "value" attribute on all the selected options
        
        var selectedOptionsList = event.getParam("value");
        component.set("v.finalColumns",selectedOptionsList);
        
        
    },
    
    saveColumns: function (component, event, helper) {
       	
        var finalColsList = component.get("v.finalColumns");
        var columnAPIMap = component.get("v.colMap");
        console.log(finalColsList);
        console.log(columnAPIMap);
        
        
        var finalColsAPIList = [];
        
        var userColsMap = {};
        for(var x in finalColsList){
            var loopLabel = columnAPIMap[loopLabel];
            var loopAPI = finalColsList[x];
            finalColsAPIList.push(loopAPI);
            userColsMap[loopAPI] = columnAPIMap[loopAPI] ;
        }
        
        var eventCmp = component.getEvent("update_columns");//component.get("e.update_columns");
        eventCmp.setParams({"finalColumnsLabel":userColsMap, "finalColumnsAPI":finalColsAPIList}).fire();
        
        var renderEvent = component.getEvent("renderCustomizeForm");
      	renderEvent.setParams({"renderCustomizeForm":false}).fire();
        //update user preferences

    },
    
    hideCustomizeForm : function(component, event, helper){
        var renderEvent = component.getEvent("renderCustomizeForm");
        renderEvent.setParams({"renderCustomizeForm":false}).fire();
    }
})