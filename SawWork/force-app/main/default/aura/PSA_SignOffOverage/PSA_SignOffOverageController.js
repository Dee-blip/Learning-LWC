({
    init: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var recId = component.get("v.recordId");
        console.log("recordId: " + recId);
        console.log("recordId: " + $A.get('$SObjectType.CurrentUser.ProfileId') );
    },
    
    onSubmitHandler: function(component,event,helper){
        event.preventDefault();
    },
    
    onRecordSuccess : function(component,event,helper){
        var message = component.get("v.messageToast");
        console.log("SUCCESS!" + message);
        var recId = component.get("v.recordId");
        setTimeout(function(){window.location.reload(true);},4000);
        helper.showToastMessage('Success!',message,'Success!','success');                         
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

    onRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") 
        {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            var psOverageFields = component.get("v.psOverageFields");
            console.log('GSS_Approver__c: ' + psOverageFields.GSS_Approver__c + ' :Finance_Approver__c: ' + psOverageFields.Finance_Approver__c);
            
            var action = component.get("c.getCLILinkedToProject");
            var projIds = [];
            projIds.push(psOverageFields.Project_ID__c);
            console.log('projIds: ' + projIds);
            action.setParams
            (
                {
                    projectIds: JSON.stringify(projIds)
                }
            
            );
            action.setCallback(this, function(response) {
                console.log('Coming here!!?? : ' + response.getState());
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
                    //result = JSON.parse(result);
                    console.log('result: ' + JSON.stringify(result, null, 2)); 
                    // changes: adding Overage Unit Of Measure filters
                    // 20.2 adding Units Low Filter on Approve
                    //var overageKey = '' + String(psOverageFields.Original_Contract_ID__c).substring(0, 15) + String(psOverageFields.CLI_End_Date__c) + 
                    //String(psOverageFields.CLI_Unit_of_Measure__c) + String(psOverageFields.Marketing_Product_Id__c);
                    var overageKey = psOverageFields.Overage_Filters__c;
                    var projectId = String(psOverageFields.Project_ID__c).substring(0, 15);
                    console.log('overageKey: ' + overageKey); 
                    
                    if(!((projectId in result) && result[projectId] === overageKey && 
                       psOverageFields.Original_Detail_ID__r.Record_Type__c === 'Overage'))
                    {
                        component.set("v.notMatchingCLI", true);
                        console.log('notMatchingCLI: TRUE' );
                    }
                    var messageToShow = '';
                    var toastType;
                            
                    helper.hideSpinner(component, event, helper);
                    if(component.get("v.notMatchingCLI") && psOverageFields.RecordType.Name === 'Automated')
                    {
                        helper.hideSpinner(component, event, helper);        
                        helper.showToastMessage('error','The Overage Contract Detail is not present in the system OR does not Match with the Project any more!','error','error');                         
                        helper.closeModalHelper(component,event,helper);
                        
                    }
                    else if((psOverageFields.GSS_Approver__c && psOverageFields.Overage_Stage__c != 'Saved') || 
                       (psOverageFields.Finance_Approver__c && psOverageFields.Overage_Stage__c === 'Signed - Off'))
                    {
                        helper.hideSpinner(component, event, helper); 
                        var signedOffMessage;
                        if(psOverageFields.GSS_Approver__c && psOverageFields.Overage_Stage__c == 'Submitted')
                        {
                            signedOffMessage = 'This Record has already been Submitted for Finance Sign - Off';
                        }
                        else 
                        {
                            signedOffMessage = 'This Record already been Signed Off';
                        }
                        helper.showToastMessage('info',signedOffMessage,'info','info');                         
                        helper.closeModalHelper(component,event,helper);
                        
                    }
                    else if(psOverageFields.Overage_Hours__c < psOverageFields.To_be_Billed_Hours__c && 
                            psOverageFields.GSS_Approver__c && 
                            psOverageFields.RecordType.Name === 'Automated')
                    {
                        helper.openModel(component,event,helper,'To Be Billed Hours is more than the Overage Hours. The Record will be submitted for Finance Approval. Do you want to proceed?');  
                        messageToShow = 'Successfully Submitted for Finance Sign Off!';
                    }
                    else if(psOverageFields.GSS_Approver__c && ((psOverageFields.RecordType.Name === 'Manual' && 
                            psOverageFields.Automated_Overage__c && 
                            psOverageFields.Overage_Hours__c >= psOverageFields.To_be_Billed_Hours__c ) || 
                            psOverageFields.Overage_Action__c === 'Postpone' || psOverageFields.Overage_Action__c === 'Waive'))
                    {
                        helper.openModel(component,event,helper,'The Record will be Signed Off. Do you want to proceed?');
                        messageToShow = 'Successfully Signed-Off!';
                    }
                    else if(psOverageFields.GSS_Approver__c && psOverageFields.RecordType.Name === 'Manual')
                    {
                        helper.openModel(component,event,helper,'The Record will be submitted for Finance Approval. Do you want to proceed?');
                        messageToShow = 'Successfully Submitted for Finance Sign Off!';
                    }
                    else if(psOverageFields.GSS_Approver__c || psOverageFields.Finance_Approver__c)
                    {
                            helper.openModel(component,event,helper,'Are you sure you want to Sign-Off?');
                            messageToShow = 'Successfully Signed-Off!';
                    }
                    else
                    {
                        helper.hideSpinner(component, event, helper);        
                        helper.showToastMessage('error','You do not have the permission to perform this action!','error','error');                         
                        helper.closeModalHelper(component,event,helper);
                            
                    }
                    component.set("v.messageToast",messageToShow);                
                    console.log('messageToShow: ' + messageToShow);
                }            
            });
            $A.enqueueAction(action);     
            
                                
        }  
        else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
            console.log("ERRRORRR!!!!!" + component.get("v.recordError"));
            helper.hideSpinner(component, event, helper);        
            helper.showToastMessage('error','There was an error. Please try again!','error','error');                         
            helper.closeModalHelper(component,event,helper);
            
        }
    }, 
    
    signOffSubmit : function(component, event, helper) {
        //console.log("THE user info: " + component.get("v.currentUser").Profile.Name);
        helper.showSpinner(component, event, helper);
        
        var psOverageFields = component.get("v.psOverageFields");
        
        var manualOverage = psOverageFields.RecordType.Name;
        psOverageFields.GSS_Approver__c || psOverageFields.Finance_Approver__c
        console.log('recordtype: ' +manualOverage );

        //check if GSS Approver || Finance Approver (Allow Finance to Approve Manual/Automated) 
        if((psOverageFields.GSS_Approver__c && manualOverage === "Automated") 
           || (psOverageFields.Finance_Approver__c && (manualOverage === "Manual" || manualOverage === "Automated")) )
        {
            console.log('INSIDE SIGNOFF');
            component.find("triggerField").set("v.value",true);
            //helper.signOffMethod(component,event,helper);  
            component.find("editRecord").submit();
        }
        else if(psOverageFields.GSS_Approver__c && manualOverage === "Manual")
        {
            console.log('INSIDE SUBMIT');   
            component.find("triggerField").set("v.value",true);
            //helper.submitMethod(component,event,helper);
            component.find("editRecord").submit();
        }
        else
        {   
            console.log('INVALID');            
            helper.hideSpinner(component, event, helper);
            helper.closeModalHelper(component,event,helper);         
            helper.showToastMessage('Invalid operation!','You are trying to perform an invalid operation!','Error!','error');
        }
                
    }    

})