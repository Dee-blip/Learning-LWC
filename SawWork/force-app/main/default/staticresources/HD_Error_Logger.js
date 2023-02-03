/*
@developer: Hemant kumar
javascript: closure based Module pattern adoption
*/
window.HD_Error_Logger = (function(){
    //private function for any utility parsing
    //private variables
    var message = "Something went wrong ? the development team has been notified ! :)";
    
    //function to show the toast message
    function showToast(component, event, helper, message, type)
    {
        try{
            var toastEvent = $A.get("e.force:showToast");
            console.log('>>>',toastEvent);           
            if(toastEvent != "undefined")
            {
                //console.debug("-->"+toastEvent);
                toastEvent.setParams({
                    "title": "Message",
                    "type": (type) ? type : "warning",
                    "message": message,
                    "mode":"sticky"
                });
                
            }//if
            toastEvent.fire();          
        }        
        catch(e){
            console.log("[ERROR:] "+e);
        }
        
    };//END
    
    //message to show the parsed error
    function errorParser(errorMsg)
    {   var trimmedMsg = "Something went Wrong, the development team has been notified !"
    var validation_Exception = "FIELD_CUSTOM_VALIDATION_EXCEPTION";
     if( errorMsg != null) 
     {
         var n =  errorMsg.search(validation_Exception);
         if( n > 0)
         {   
             console.log(" the length or validation flag --->> "+ validation_Exception.length);
             console.log(" the length or error message --->> "+ errorMsg.length);
             console.log('Search start point --->> is Validation '+n);
             trimmedMsg = errorMsg.slice(n+validation_Exception.length+1,errorMsg.length); 
             
             //regex to remove ": [Text__text__c]" type word from error message
           	  var regexFormat=/(: \[[A-Za-z_]+\])/g;
          	  trimmedMsg=trimmedMsg.replace(regexFormat,"");
            
             console.log("extracted Msg ---> "+trimmedMsg );
             
         }else
         {
             console.log('Search --->> is Validation '+n);
         }
     }//IF
     return trimmedMsg;
    }
    
    
    
    return { //making public API
        createLogger : function(component, event, helper,ErrorMsg,StackTrace,customErrorFlag, type ){
            console.log('Error logger event Fired !');
            //alert('Custome error Flag '+ customErrorFlag);
            //added the Custom Error flag o display custom error message
            
            if(customErrorFlag)
            { 
                message = ErrorMsg;
            }else
            {
                message = errorParser(ErrorMsg);
            }
            
            //alert('>>'+message);
            showToast(component, event, helper, message, type);
            var hdLoggerEvent = $A.get("e.c:HDLogger");//component.getEvent("HDLoggerEvent");
            hdLoggerEvent.setParams({
                "ErrorMsg":ErrorMsg,//"Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Priority is mandatory. Please select a value from Priority list: []",
                "StackTrace": StackTrace, //"Type:System.DmlException;Line Number: 8;Cause: null;StackTrace:AnonymousBlock: line 8, column 1"
                "IncidentId":component.get("v.recordId")
            });
            hdLoggerEvent.fire();            
            
        },
        
    };
    
    
}());










