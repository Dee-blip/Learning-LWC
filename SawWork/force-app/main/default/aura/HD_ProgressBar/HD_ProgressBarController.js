({

doInit : function(component, event, helper) 
    {
               
        //getting incident details 
        var action = component.get("c.getIncident");
        action.setParams({
            "incidentId" : component.get("v.recordId")
        });
        action.setCallback(this,function(data){
            var state = data.getState();
            if(state == "SUCCESS")
            {
                var response = data.getReturnValue();
            component.set("v.incidentObj",response);
            console.log(response.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c);
                var progress;
                console.log("Stage: "+response.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c)
                if( response.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c == 'Opened' )
                {
                  progress=1;                
                }else if( response.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c == 'Acknowledged')
                {
                    progress=2;
                    
                }else if( response.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c == 'In Process')
                {
                    progress=3;
                    
                }
                else
                {
                    progress=4;
                    
                }

            component.set("v.progress",progress);
            }//IF

            
        });
        
       $A.enqueueAction(action);

	}//doInit
})