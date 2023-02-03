({
    doInit: function(component, event, helper) {
        // Prepare a new record from template
        component.set("v.isSpinnerEnabled",true);
        component.find("serviceoutageRecordCreator").getNewRecord(
            "BMCServiceDesk__Projected_Service_Outage__c", // sObject type (entityAPIName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newServiceOutage");
                var error = component.get("v.newServiceOutageError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    console.log("Record template initialized: " + rec);
                }
            })
        );
        
        
        helper.populateServiceOptions(component,event,helper);
      },
    
    handleSaveServiceOutage: function(component, event, helper) {
      
        
         helper.saveSO(component,event,helper);
       
    },
    
    onchange: function(component, event, helper){

        console.log(" ON CHANGE")
      if (component.find('enddatetime').get('v.value') > component.find('startdatetime').get('v.value'))
        {
          helper.getMatchingCMRList(component, event)
          
      }

    },
    
    showunselct: function(component, event, helper){
         var appr_tb = component.find("unselct_icon");


            $A.util.removeClass(appr_tb, 'slds-hide');
    },
    
    selclear: function(component, event, helper){
        console.log("in CTR");
         helper.clearserviceselection(component);
    }
    
    
   


  
 
 
    

})