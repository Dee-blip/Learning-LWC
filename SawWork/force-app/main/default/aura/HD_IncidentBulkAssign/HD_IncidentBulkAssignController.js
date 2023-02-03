({
    
    doInit: function(component, event, helper){
        var action = component.get("c.getAllStaffs");
        action.setStorable();
        action.setCallback(this,function(data){
            if(data.getState() == 'SUCCESS'){
                var data = data.getReturnValue();
                localStorage.HD_AllStaffs = JSON.stringify(data);
                component.set("v.allStaffs",data);
            }else if(data.getState() == 'ERROR'){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "error",
                        "message": data.getError()
                    });
                    toastEvent.fire();
            }
        });
        $A.enqueueAction(action); 
    },
    
	performSearch: function(component, event, helper) {
          //startTime = new Date(); 
        
       	var value = component.get("v.searchQuery");
        var resultsFinal=component.get("v.allStaffs");
        var results = [];
        
        if(value == null || value == ''){
        	results = [];
        }else{
            
         	var reg = new RegExp(value, 'i');
        	for(let key in resultsFinal){
                if(resultsFinal[key].Name.match(reg) || resultsFinal[key].Email.match(reg)){
                    results.push({name:resultsFinal[key].Name,id:resultsFinal[key].Id,email:resultsFinal[key].Email});
                }
            }
        }
    	component.set("v.results",results); 
        console.log("results"+results);
    },
    
    selectStaff: function(component, event, helper){
        var selectedValue = event.currentTarget.dataset.id;
        var selectedName = event.currentTarget.dataset.name;     
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedName);
        component.set("v.selectedId",selectedValue);
        component.set("v.selectedStaff",selectedName);
        component.set("v.warnings",null);
        
    },
    assignOwner : function(component, event, helper) {
    	var incId = component.get("v.recordId");
        var ownerId;
        if(event.getSource().getLocalId() == "Assign"){
        	ownerId = component.get("v.selectedId");            
            if(ownerId == ""){
            	component.set("v.warnings","Please select staff from the list below.");
                return;
            }
            component.set("v.warnings",null);
            component.set("v.searchQuery","");
            component.set("v.selectedId","");
        }
        else if(event.getSource().getLocalId() == "Assign to me"){
        	ownerId = null;
        }
		var action = component.get("c.bulkAssign");
        action.setParams({
        	incidentIds :component.get("v.incidentIds") ,
            incidentData : component.get("v.incidentData"),
            ownerId : ownerId
        });
         
       	action.setCallback(this,function(data){
         	helper.doneWaiting(component);
            component.set("v.selectedStaff",null);
            var state = data.getState();
                if(state == 'ERROR'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "error",
                        "message": data.getError()
                    });
                    toastEvent.fire();

                }
                else if(state == 'SUCCESS')
                {
                        var compEvent = component.getEvent("HD_ShowBulkUpdateResultsEvt");
                        compEvent.setParams({"results" : data.getReturnValue() });
                        compEvent.fire();
                }

      
    	});
        $A.enqueueAction(action);
       	helper.waiting(component);   
        
        
  	}
  	
        
    
    
})