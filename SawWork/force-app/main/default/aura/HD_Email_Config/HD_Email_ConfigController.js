({
	 doInit : function(component, event, helper){
       var action1 = component.get("c.getIncident"); 
       var self = this;
       action1.setParams({ incidentId : component.get("v.recordId") });
       var firstval = '';
       action1.setCallback(this, function(response) {
           if(response.getState() == 'SUCCESS'){
               var  rval = response.getReturnValue();
               component.set("v.incident",rval);
           }    
           else if(response.getState() == 'ERROR'){
                console.log('Failed to get initialized in get incident');
                
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
                return;
            }
        });

        $A.enqueueAction(action1); 
        
    },
    
    changeEmailConf : function(component, event, helper){
       var action1 = component.get("c.updateEmailConfig"); 
       var self = this;
       var datakey = event.currentTarget.dataset.key; 
       console.log(datakey) ;
       var boolval ; 
        
    switch(datakey) {
    case 'clientNotification':
        boolval = component.find("ar_clnt_notify").getElement().checked;
            console.log(" IN CL NT") ;
            console.log(boolval);
        break;
    case 'onCreation':
        boolval = component.find("ar_create_notify").getElement().checked;
        break;
    case 'onStatusChange':
        boolval = component.find("ar_status_notify").getElement().checked;
        break;
    case 'onNoteUpdate':
        boolval = component.find("ar_notes_notify").getElement().checked;    
        break;
   }
        
        console.log(" BOOLVal "+boolval);
      
        action1.setParams({ incidentId : component.get("v.recordId"), emailKey : datakey, val : boolval });
      
       action1.setCallback(this, function(response) {
           var state = response.getState();
           if(state == 'SUCCESS'){
               var  rval = response.getReturnValue();
               component.set("v.incident",rval);
           }    
           else if(state == 'ERROR'){
                console.log('Failed in email config');
                console.log(response.getReturnValue());
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
                
            }
           
           helper.doneWaiting(component);
           $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
        });
        
        helper.waiting(component);
        $A.enqueueAction(action1); 
        
    }

})