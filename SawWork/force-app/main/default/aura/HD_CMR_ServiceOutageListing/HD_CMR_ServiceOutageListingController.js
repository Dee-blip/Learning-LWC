({
	getserviceOutages : function(component, event, helper) {
		
      var action2 = component.get("c.getServiceOutages"); 
        
       action2.setCallback(this, function(data) {
            var  ret_cmrlist = data.getReturnValue();
             let state = data.getState();
            
               if (state === "SUCCESS") {
                    console.log(ret_cmrlist.length);
                      component.set('v.serviceoutages', ret_cmrlist);
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
                  

               } 
        });

       $A.enqueueAction(action2); 

    },
    
    handleCloseModal: function(component, event, helper){
        console.log(' Handle close');
       
      var status = event.getParam('eventtype');
      
       
      var msg = event.getParam('message'); 
         console.log( msg);
         $A.get('e.force:refreshView').fire();
        if(msg !== null && msg != ''){  
      var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": status,
                        "message": msg
                    });
            
               resultsToast.fire();
            
        }
               component.set("v.showCreate", false);
      
    },
    
    showCreateForm:  function(component, event, helper){

       component.set("v.showCreate", true);
      
    }
    
    
})