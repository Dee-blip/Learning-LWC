({
	loadStatus : function(component, event, helper) {
        
        var action = component.get("c.getChange"); 
        var RecordID = component.get("v.recordId");
        if(!RecordID)
        {
            //RecordID = 'a5E0S0000008caTUAQ'; //fail safe ID code for testing
        }
        console.log('->> Record ID: '+RecordID);
        action.setParams({ Id : RecordID });
        action.setCallback(this, function(data) {
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                var status = result.HD_Change_Status__c
                var stages = ['OPENED','SUBMITTED','AUTHORIZED', 'IN PROGRESS','COMPLETED', 'CLOSED'];
                
                if (result.HD_Change_Status__c == 'PENDING APPROVAL'){
                    status = 'SUBMITTED';
                }
                if( result.HD_Change_Status__c == 'CHANGE FAILED'){
                    stages = ['OPENED','SUBMITTED','AUTHORIZED', 'IN PPROGRESS','CHANGE FAILED', 'CLOSED'];
                }
                if( result.HD_Change_Status__c == 'CANCELLED'){
                    stages = ['OPENED','SUBMITTED','AUTHORIZED', 'IN PPROGRESS', 'CANCELLED'];
                }
                
                var statusMatch = false;
                var completedsteps = [];
                var pendingsteps = []
                for(var i= 0; i<stages.length; i++){
                    if(status == stages[i]){
                        statusMatch = true;
                        component.set("v.currentStage", status);
                        continue;
                    }
                    
                    if(statusMatch == false){
                        completedsteps.push(stages[i]);
                    }else{
                        pendingsteps.push(stages[i]);
                    }
                }
                
                component.set("v.completedStages",completedsteps );
                component.set("v.pendingStages",pendingsteps);
            }   
        });
        
        $A.enqueueAction(action);
		
	}
})