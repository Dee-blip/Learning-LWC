({
    LogErrorAction : function(component, event) {
        var ErrorMsg = event.getParam('ErrorMsg');
        component.set('v.ErrorMsg',ErrorMsg);
        var StackTrace = event.getParam('StackTrace');
        var incidentId = event.getParam('IncidentId');
        var logErrorRecord =  component.get('c.logErrorRecord');
        logErrorRecord.setParams({
            ErrorMsg : ErrorMsg,
            Stacktrace : StackTrace, 
            IncidentId : incidentId        
        });
        logErrorRecord.setCallback(this,function(resp){
            var state = resp.getState();
            if( state === "SUCCESS")
            {  
                console.log("Error Logged !");
                var unifiedHistResp = resp.getReturnValue();
                
            }
            else if(state === "ERROR")
            {
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }//ERROR
            
        });
        $A.enqueueAction(logErrorRecord);		
    },
})