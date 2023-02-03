({
    
    doInit: function(component, event, helper){
        var action = component.get("c.getAllStaffs");
        //action.setStorable();
        action.setCallback(this,function(data){
            if(data.getState() == 'SUCCESS'){
                var data = data.getReturnValue();
                localStorage.HD_AllStaffs = JSON.stringify(data);
                component.set("v.allStaffs",data);
            }else if(data.getState() == 'ERROR'){
                var errors = data.getError();
            	HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message,false, 'error');
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
            /* eslint-disable-next-line */
        	for(let key in resultsFinal){
                if(resultsFinal[key].Name.match(reg) || resultsFinal[key].Email.match(reg)){
                    results.push({name:resultsFinal[key].Name,id:resultsFinal[key].Id,email:resultsFinal[key].Email});
                }
            }
        }
    	component.set("v.results",results);       
    },
    
    selectStaff: function(component, event, helper){
        
        let selectedValue = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;     
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedName);
        component.set("v.selectedId",selectedValue);
        component.set("v.selectedStaff",selectedName);
        component.set("v.warnings",null);
        
    },
    assignOwner : function(component, event, helper) {

        if (event !== null && typeof event.getParam === 'function' && event.getParam("quickAction") && event.getParam("quickAction") !== 'Assign') {
            return;
        }

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
            //startTime = new Date();
        }
		var action = component.get("c.updateOwner");
        action.setParams({
        	recordId : incId,
            ownerId : ownerId
            //startTime : startTime
        });
         
       	action.setCallback(this,function(data){
         	helper.doneWaiting(component);
            component.set("v.selectedStaff",null);
           
            var state = data.getState();
            //alert(state);
                if(state == 'ERROR'){
                    /*var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type":"error",
                        "message": "Something went wrong while performing the operation."
                    });*/
                    var errors = data.getError();
            		HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message,false, 'error');
                    helper.doneWaiting(component);
                    //toastEvent.fire();
           			$A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();

                }
            var data = data.getReturnValue();
            $A.get('e.force:refreshView').fire();
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
            //auditEvent.fire();
            
            
    	});
        $A.enqueueAction(action);
       	helper.waiting(component);   
        //audit
        /*var auditAction = component.get("c.updateActionAudit");
        auditAction.setParams({
        	recordId : incId,
            actionName : 'Assign'
            //startTime : startTime,
           // endTime : new Date()            
        });
         
       	auditAction.setCallback(this,function(data){
            startTime = null;
    	});
        $A.enqueueAction(auditAction);*/
        
  	}
    
})