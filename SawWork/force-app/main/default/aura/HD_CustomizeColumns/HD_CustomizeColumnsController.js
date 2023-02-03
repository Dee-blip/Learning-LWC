/** Client-Side Controller **/
({
    initialize: function (component, event, helper) {
        
        var action = component.get("c.getColumns");
        
            action.setCallback(this,function(data){
                var response = data.getReturnValue();
                component.set("v.colMap",response);
                var columnAPIMap = component.get("v.colMap");
        var options = [];
        for(var x in columnAPIMap){
            options.push({value:x, label:x});
        }
        
        /*
        //have to populate all possible columns here
        var options1 = [
            { value: "Response Prioritization Score", label: "Response Prioritization Score" },
            { value: "Priority", label: "Priority" },
            { value: "Parent Tree", label: "Parent Tree" },
            { value: "Category", label: "Category" },
            { value: "Status", label: "Status" },
            { value: "Client Name", label: "Client Name" },
            { value: "Short Description", label: "Short Description" },
            { value: "Owner", label: "Owner" },
            {value: "Client Email", label:"Client Email"},
            {value: "Client City",label:"Client City"}
        ];
            console.log("Options1: ");
            console.log(options1);
            */
        var values = [];
        var columns = component.get("v.colOptions");
                /*
        for(var i in options){
            if(columns.includes(options[i].label)){
                values.push(options[i].value);
            }
        }
        
                
               for(var i in columns){
                   for(var j in options){
            if(columns[i]==options[j].label){
                values.push(options[j].value);
                break;
            }
            }
        }       
        */
        component.set("v.listOptions", options);
        component.set("v.defaultOptions", columns);
                component.set("v.finalColumns",columns);
                helper.doneWaiting(component);
    		});
            $A.enqueueAction(action);
			helper.waiting(component);
        
    },
    handleChange: function (component, event, helper) {
        // Get the list of the "value" attribute on all the selected options
        
        var selectedOptionsList = event.getParam("value");
        component.set("v.finalColumns",selectedOptionsList);
        
        
    },
    
    saveColumns: function (component, event, helper) {
    // Retrieve an array of the selected options
        var finalColsList = component.get("v.finalColumns");
        var finalColsAPIList = [];
        var columnAPIMap = component.get("v.colMap");
        var userColsMap = {};
        for(var x in finalColsList){
            var loopLabel = finalColsList[x];
            var loopAPI = columnAPIMap[loopLabel];
            finalColsAPIList.push(loopAPI);
             userColsMap[loopLabel]=loopAPI;
        }
        
        //update user preferences
        
        var action = component.get("c.updateSelectedColumns");
        action.setParams({selectedColumns:userColsMap});
        
            action.setCallback(this,function(data){
                var setColumnsEvent = $A.get("e.c:hd_setCustomColumns");
        		setColumnsEvent.setParams({"finalColumnsLabel":finalColsList, "finalColumnsAPI":finalColsAPIList}).fire();
        		var renderEvent = $A.get("e.c:hd_renderCustomizeFormEvent");
       			renderEvent.setParams({"renderCustomizeForm":false}).fire();
                helper.doneWaiting(component);
            });
            $A.enqueueAction(action);
        	helper.waiting(component);
        
       
    },
    
    hideCustomizeForm : function(component, event, helper){
		var renderEvent = $A.get("e.c:hd_renderCustomizeFormEvent");
       	renderEvent.setParams({"renderCustomizeForm":false}).fire();
    }
})