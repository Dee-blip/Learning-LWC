({
	doInit : function(component, event, helper) {
		
      var action2 = component.get("c.getSO"); 
        action2.setParams({recId: component.get("v.recordId")})
       action2.setCallback(this, function(data) {
            var  resp = data.getReturnValue();
             let state = data.getState();
            
               if (state === "SUCCESS") {
                    console.log(" GET SO SUCCESS")
                    console.log(resp.BMCServiceDesk__Inactive__c);
                      component.set('v.servoutg', resp);
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
               } 
        });

       $A.enqueueAction(action2); 

    },
    
    soEdit: function(component, event, helper) {
        
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
             "recordId": component.get("v.recordId")
        });
        editRecordEvent.fire();

    },
    
    soDelete: function(component, event, helper) {
        var so = component.get('v.servoutg');
        var msg = 'Are sure you want to delete '+so.Name
        if (confirm(msg) != true) {
            return;
        }
        var action = component.get("c.deleteSO");
        action.setParams({
             "recId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(data) {
            var  message = data.getReturnValue();
             let state = data.getState();
            
               if (state === "SUCCESS") {
                   if (message !== null){
                       var resultsToast = $A.get("e.force:showToast");
                       var msg = ' Service Outage '+message+' deleted successfully';
                    resultsToast.setParams({
                        "title": "Deleted",
                        "message": msg,
                        "duration": "3000"
                    });
            
                     resultsToast.fire(); 
                      
                       var loc = "https://"+window.location.hostname+"/lightning/n/Service_Outage_Listing";
                       window.location.assign(loc);
                   }
                   
               } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
               } 
        });

       $A.enqueueAction(action); 

    },
    
    
     soactivate: function(component, event, helper) {
        var so = component.get('v.servoutg');
         var b_val = true;
         if (so.BMCServiceDesk__Inactive__c == true){
             b_val = false;
         }
         
         var action = component.get("c.toggleActiveSO");
        action.setParams({
             "recId": component.get("v.recordId"),
             "val": b_val
        });
         action.setCallback(this, function(data) {
            var  serout  = data.getReturnValue();
             let state = data.getState();
            
             if (state === "SUCCESS") {
                 component.set('v.servoutg',serout);
                 $A.get('e.force:refreshView').fire();

             } else if (state === "ERROR") {
                   var errors = data.getError();
                   console.log(errors.message);
               } 
         });
          $A.enqueueAction(action); 
     }  
    
})