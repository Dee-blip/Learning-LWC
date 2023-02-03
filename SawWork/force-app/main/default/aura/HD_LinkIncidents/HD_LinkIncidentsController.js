({
	doInit : function(cmp, event, helper) {
        var searchCmp = cmp.find("searchInput");
		searchCmp.set("v.value","");
        searchCmp.set("v.errors",null);
    	helper.getIncidentRecordsHelper(cmp);
        
	},
    onSearch : function(cmp, event, helper)
    {
        var searchCmp = cmp.find("searchInput");
        var searchVal = searchCmp.get("v.value");
        var re = new RegExp("^((IN|SR)?[0-9]{8})$");
        
        if(searchVal && !searchVal.match(re)){
            console.log('match:'+searchVal+searchVal.match(re));
           searchCmp.set("v.errors", [{message:"Enter a valid ticket number."}]);
        }
        else{
         	searchCmp.set("v.errors",null);
         	helper.getIncidentRecordsHelper(cmp);  
        }
    },
    
    linkTickets : function(cmp, event, helper) {
        var sel = cmp.get("v.selected"); 
        var recordId = cmp.get("v.recordId");
        console.log(sel);
        var action = cmp.get("c.linkIncidents2");
        action.setParams({
        		incidentId : recordId,
            	linkToIds : sel
      		}); 
        
            action.setCallback(this,function(data){
                
                var state = data.getState();
                console.log('state'+state);
                if(state === 'SUCCESS') {
                     
                    var response = data.getReturnValue();
                    //Fire refresh view event here
                    /*var url = "/one/one.app?#/sObject/"+recordId+"/view";
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": url
                    });
                    urlEvent.fire();*/
                	var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"success",
                        "message": "Incidents Linked." //Previous message: Linking Incidents
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }
                else if(state == 'ERROR')
                {
                    /*
                    var errors = data.getError();
                    console.log('errors'+errors);
                    console.log(errors);
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                    errors[0].message);
                            
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": errors[0].message
                            });
                            toastEvent.fire();

                            
                        }
                    } else {
                        console.log("Unknown error");
                        var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": "Unknown error"
                            });
                            toastEvent.fire();
                    }
                    */
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(cmp, event, helper, errors[0].message, errors[0].message,false,'error');
            		//helper.doneWaiting(component);
                   
                }
    			$A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire(); 

    		});
            $A.enqueueAction(action); 
                
               
        
	},
     
  selectRecord: function(component, event, helper) {
      
        var selectedItem = event.currentTarget;
      	var selectedId = selectedItem.dataset.id;
      console.log("selected object");
      console.log(selectedId);
        var selList = component.get("v.selected");
        console.log("checked"+selectedItem.checked);
        if(selectedItem.checked)
        {
            if(selList.length>=10)
            {
               selectedItem.checked = false;
                console.log("check"+selectedItem.checked);
               var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
                    "type" : "info",
        			"message": "Only 10 records can be selected at a time!"
    			});
    			toastEvent.fire();
				return;
            }
            else
            {
 	           selList.push(selectedId);              
            }
     
        }
        else
        {          
            var index = selList.indexOf(selectedId);
            selList.splice(index,1);
            
        }
      	component.set("v.selected", selList);
        var x = component.get("v.selected"); 
        console.log("x:"+x);

    },
    showModal: function(component, event, helper)
    {
        	var cmpTarget = component.find('linkIncidentsModal');
      		$A.util.removeClass(cmpTarget, 'slds-hide');

    },
     hideModal: function(component, event, helper)
    {
        	var cmpTarget = component.find('linkIncidentsModal');
      		$A.util.addClass(cmpTarget, 'slds-hide');

    }
    
    
})