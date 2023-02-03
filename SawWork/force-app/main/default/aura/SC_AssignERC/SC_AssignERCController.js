({
    init: function(component, event, helper) {
        var recId = component.get("v.recordId");
        console.log("recordId: " + recId);
    },
    
    submitForm: function(component,event,helper){
        helper.showSpinner(component, event, helper);
        component.find("editRecord").submit();   
    },
    
    onRecordSuccess : function(component,event,helper){
        console.log("SUCCESS!" );
        var recId = component.get("v.recordId");
        helper.hideSpinner(component, event, helper);        
        helper.showToastMessage('Success!','Successfully Saved!','Success!','success');                         
        helper.closeModalHelper(component,event,helper);
    },
    onRecordSubmit : function(component,event,helper){
        console.log('Inside SUBMIT!');
        event.preventDefault();
    },
    recordLoaded : function(component,event,helper){
        console.log('Inside Load!');
        var initERC = component.find("ercField").get("v.value");
        component.set("v.initERC", initERC); 
        console.log("initERC: " + initERC);
    },
    onRecordError : function(component,event,helper){
        console.log('In the error method!');
        var eventName = event.getName();
        var eventDetails = event.getParam("error");
        var message = '';
        console.log('eventDetails: ' + JSON.stringify(eventDetails, null, 2));
        if(eventDetails != undefined && 
           eventDetails.body != undefined && 
           eventDetails.body.output != undefined)
        {
            var output = eventDetails.body.output;
            if(output.errors != undefined && output.errors.length > 0)
            {
                for(var index = 0; index < output.errors.length; index++)
                {
                    message += output.errors[index].message + '\n';
                }
            }
            if(output.fieldErrors != undefined)
            {
                for (var field in output.fieldErrors)
                {
                    if(output.fieldErrors[field] != undefined && output.fieldErrors[field].length > 0)
                    {
                        message += output.fieldErrors[field][0].message + '\n';    
                    }
                    
                }
            }
        }
        else
        {
            message = 'Unknown Error!'
        }
        helper.hideSpinner(component, event, helper);        
        helper.showToastMessage('Error!',message,'Error!','error');                         
        //setTimeout(function(){helper.closeModalHelper(component,event,helper);},1000);
        helper.closeModalHelper(component,event,helper);
    },
        
    closeModal:function(component,event,helper){
        helper.closeModalHelper(component,event,helper);  
    },

    closeDialog:function(component,event,helper){
        helper.closeDialogHelper(component,event,helper);  
    },

    
    validateERC: function(component, event, helper) {
        
        console.log("In validateERC method");
        var enteredERC = component.find("ercField").get("v.value");
        enteredERC = !enteredERC? '' : enteredERC.trim();
        var initERC = component.get("v.initERC");
        
        if(initERC === enteredERC)
        {
            console.log('No Change');
            helper.showToastMessage('info','No Changes in ERC!','info','info');
        }
        else if(enteredERC.length === 0)
        {
            helper.showSpinner(component, event, helper);
            console.log('Null or blank ERC!');
            component.find("ercField").set("v.value", "");
            component.find("editRecord").submit();               
        }
        else if(enteredERC.length >= 4)
        {
            console.log("Inside the method ");
            var recId = component.get("v.recordId");
            var action = component.get("c.getERCWrapper");
            
            console.log("recId: " + recId);
            console.log("erc: " + enteredERC);        
            helper.showSpinner(component, event, helper);
            
            action.setParams
            (
                {
                    accountId : recId, 
                    currentERC: enteredERC
                }
                
            );
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "ERROR") 
                {
                    console.log('Failed!!!!');  
                    helper.hideSpinner(component, event, helper);        
                    helper.showToastMessage('error','There was an error. Please try again!','error','error');                         
                    helper.closeModalHelper(component,event,helper);
                    
                }
                else if (state === "SUCCESS")
                {
                    console.log('In Success!!!!!!');
                    var result =response.getReturnValue(); 
                    result = JSON.parse(result);
                    console.log('result: ' + JSON.stringify(result, null, 2)); 
                    //console.log('result: ' + result);
                    console.log('isValid: ' + result['isValid']);
                    console.log('accountNames: ' + result['accountNames']);
                    
                    if(result['isValid'] === false)
                    {
                        console.log('isValid: ' + result['isValid']);
                        helper.hideSpinner(component, event, helper);        
                        helper.showToastMessage('error','Accounts that share an ERC must be assigned to the same support team!','error','error');
                    }
                    else if(result['accountNames'].length > 0)
                    {
                        helper.hideSpinner(component, event, helper);        
                        helper.openModel(component,event,helper,'The ERC entered is already assigned to the following Accounts: ' +result['accountNames']+ '. Do you wish to proceed?');
                    }
                    else
                    {
                        console.log('HERE in else block!');
                        component.find("editRecord").submit();   
                    }
                }            
            });        
    
            $A.enqueueAction(action);        
            
        }
        else
        {
            helper.showToastMessage('error','ERC must have atleast 4 digits!','error','error');
        }
     }, 

})