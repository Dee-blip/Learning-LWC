({
    doInit: function(component, event, helper) {

        var action = component.get("c.getAllQueues");
        action.setStorable();
        action.setCallback(this,function(data){
            if(data.getState() == 'SUCCESS'){
                var queueList = data.getReturnValue();
                var queues = [];
                for(let key in queueList){
                    queues[key]=queueList[key];
                    component.set("v.initialResult",queues);
            	}
            	//HD_Error_Logger.createLogger(component, event, helper, 'test', 'Type:System.DmlException;Line Number: 8;');
            }else if(data.getState() === 'ERROR'){
                 var errors = data.getError();
                 /* eslint-disable-next-line */
                 HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');
            }
        });
        $A.enqueueAction(action);
        
        
    },
    showChangeCategoryOpt: function(component, event,helper){
        component.set("v.showCatChangeOption",component.get("v.showCatChangeOption") ? false: true);
    },
    
    performSearch: function(component, event, helper) {
        var results;
    	
    	var elem = $A.util.getElement("queueInput");
    	
    	var value= $A.util.getElementAttributeValue(elem,"value");    
        
       	var resultsFinal=component.get("v.initialResult");
        
        var results1 = [];
        if(value == null || value == ''){
            //results1.push({name:"Triage Team",id:resultsFinal["Triage Team"]});
            results1 = [];
        } 
        else{
            var reg = new RegExp(value, 'i');
            for(let key in resultsFinal){
                if(key.match(reg)){
                    results1.push({name:key,id:resultsFinal[key]});
                }
            }
         	//results = resultsFinal;
        }//else
        //results1.push({name:"Triage Team",id:resultsFinal["Triage Team"]});
    	component.set("v.results",results1);
    },
    
    queueSelected: function(component, event, helper){

        var selectedValue = event.currentTarget.dataset.queue;
        var selectedId = event.currentTarget.dataset.queueid;
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedValue);
        component.set("v.selectedQueueId",selectedId);

    },
    
	transferTicket : function(component, event, helper) {
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        //validating note
        var note=$A.util.getElement("noteInput").value;
        var category="";
        category =  $A.util.getElement("hiddenCategoryId").value;
        if($A.util.getElement("categoryInput").value.trim() == '' ){
            category = '';
        }
        
        if(note == null || note == ''){
            warningMessages[index] = "Please enter a note";
            index++;
        }
        //validating effort
        var effort=$A.util.getElement("effortInput").value;
        if(effort == null || effort == ' '){
            warningMessages[index] = "Please enter Effort Estimate";
            index++;
        }
         //code to check effort
         //var re = new RegExp("(0[1-9]|[1-9][0-9]):([0-5][0-9])|((00):([1-5][0-9]))");
         var re = new RegExp("(00:[0-5][1-9])|(00:[1-5]0)|(01:00)");
         
        if(!effort.match(re)){
            warningMessages[index] = "Effort Estimate should be in the range 00:01 to 01:00";
            index++;
        }
        
        //validating queue
        var queue; 
        queue = component.get("v.selectedQueueId");
        if(queue == null || queue.trim() == ''){
            warningMessages[index] = "Please select a valid queue";
            index++;
        }
        
        component.set("v.warnings",warningMessages);
        
        if(warningMessages.length==0){
            //component.set("v.searchQuery","");
         	var incId = component.get("v.recordId");
         	
         	var action = component.get("c.transferIncident");
            action.setParams({
        		recordId : incId,
                queueName : queue,
                duration:effort,
                addedNote:note,
                categoryId: category
      		});
            action.setCallback(this,function(data){
                component.set("v.selectedQueueId","");
                component.set("v.searchQuery","");
                $A.util.getElement("effortInput").value = " ";
                $A.util.getElement("noteInput").value = " ";
                var state = data.getState();
                if(state != 'SUCCESS'){
                   /*  var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type":"error",
                        "message": "Something went wrong while performing the operation."
                    });
                    helper.doneWaiting(component);
                    toastEvent.fire();*/
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message,false, 'error');
            		helper.doneWaiting(component);
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                    return;
                }
                var data = data.getReturnValue();
                helper.doneWaiting(component);
                $A.get('e.force:refreshView').fire();
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
    		});
            $A.enqueueAction(action);
            helper.waiting(component);
        }
    }
    
})