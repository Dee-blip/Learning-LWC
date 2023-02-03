({
        
    
    doInit: function(cmp) {
        //var object = cmp.get("v.ObjectName");
        //var recordTypeName = cmp.get("v.RecordType");
        console.log('Inside Init');
        var object = cmp.get("v.cti_object");
        var recordTypeName = cmp.get("v.cti_recordtype");
        //cmp.set("v.ObjectName", "Account");
        var action = cmp.get("c.getFieldWrapper");
        action.setParams
        (
            {
                objectName: object,
                recordType: recordTypeName,
                lob: cmp.get("v.lob"),
                defaultValues: cmp.get("v.defValues")
            }
        
        );
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state: ' + state);
            var messageToShow = '';
            var toastType;
            if (state === "ERROR") 
            {
                    var errors = response.getError();                       
                    console.log('errors[0].message: ' + errors[0].message);
                    // var toastEvent = $A.get("e.force:showToast");
                    // toastEvent.setParams({
                    //     title : 'Info Message',
                    //     message: 'Error occured',
                    //     messageTemplate: 'Error occured',
                    //     duration:' 5000',
                    //     key: 'info_alt',
                    //     type: 'error',
                    //     mode: 'dismissible'
                    // });
                    //toastEvent.fire();                
                
            }
            else if (state === "SUCCESS")
            {
                var result =response.getReturnValue(); 
                console.log("Inside SUCCESS!!");
                console.log(result);
                result = JSON.parse(result);
                var sectionNames = [];
                var recordTypeId;
                cmp.set("v.sections",result);
                for(var index = 0; index < result.length; index++)
                {
                    sectionNames.push(result[index]["sectionName"]);
                    if(result[index]["recordTypeId"] != null && result[index]["recordTypeId"] != undefined)
                    {
                        recordTypeId = result[index]["recordTypeId"];
                    }
                }
                setTimeout(function(){
                    console.log('hello');
                    cmp.set("v.openSections",sectionNames);
                },50);
                
                console.log(sectionNames);
                //cmp.set("v.fields",result);
                //console.log("RecordTypeId",cmp.get("v.RecordTypeId"));
                cmp.set("v.RecordTypeId",recordTypeId);
            }
            cmp.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);     

    },
   
    handleError: function(cmp, event, helper) {
        // errors are handled by lightning:inputField and lightning:nessages
        // so this just hides the spinnet
        console.log('HERE!!! inside handleerror');
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
        console.log('Message: ' + message);
        cmp.set('v.showSpinner', false);
        cmp.set("v.errorMessage",message);
        cmp.set("v.showMessageModal",true);
        
    },

    handleSuccess: function(cmp, event, helper) {
        console.log('HERE!!! inside handleSuccess');
        //cmp.set('v.showSpinner', false);
        var recId = event.getParam("response").id;
        console.log('HERE!!! inside handleSuccess: ' + recId);        
        helper.navigateToDetail(recId);
    },
    
    cancelDialog:function(cmp, event, helper) {
        //var dismissActionPanel = $A.get("e.force:closeQuickAction");
        helper.navigateToDetail('close');
        //dismissActionPanel.fire();
        cmp.destroy();
        
        
    },
    submitForm:function(cmp, event, helper) {
        event.preventDefault();
        //console.log('HERE!!!');
        var fields = cmp.find("field");
        console.log(JSON.stringify(fields));
        var isValid = true;
        fields.forEach(field => {
            if($A.util.hasClass(field,"required-class") && !field.get("v.value"))
            {
                $A.util.addClass(field,"slds-has-error");
                isValid = false;
            }
        });
        //var isValid = !fields.find(fld => $A.util.hasClass(fld,"required-class") && !fld.get("v.value"));
        console.log('isValid: ' + isValid);
        //var isValid = true;
        
        if(isValid) 
        {
                        console.log('INSIDE If');
            cmp.set('v.showSpinner', true);
            console.log('Submit');
            cmp.find("formId").submit();
            console.log('After Submit');
            
        } 
        else 
        {            
            //helper.showToastMessage('Error!','Please fill up the mandatory fields!','Error!','error');                         
            cmp.set("v.errorMessage",'Please Fill up the Mandatory Fields!');
            cmp.set("v.showMessageModal",true);

        }
        
    },
    
    closeMessage:function(cmp, event, helper) {
        cmp.set("v.showMessageModal",false);
        cmp.set("v.errorMessage","");
    }
})