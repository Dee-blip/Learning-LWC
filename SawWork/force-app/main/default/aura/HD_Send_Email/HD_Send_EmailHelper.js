({
    MAX_FILE_SIZE: 25000000, /* 1 000 000 * 3/4 to account for base64 */
    NUM_OF_ATTACHMENTS: 0,
    
    sendEmailHelper : function(component) {
        var fileInput = component.find("file").getElement();
        var file = null;    	
        var fileContents = null;
        var fr;
        //    	var fileArr = [];
        var fileData = [];
        var num_of_files = fileInput.files.length;
        
        if(num_of_files>0)
        {
            if(num_of_files>10){
                var msg = "Cannot attach more than 10 files at a time";
                var createToastEvent = $A.get("e.force:showToast");
                createToastEvent.setParams({
                    "title": "Error",
                    "message": msg
                });
                createToastEvent.fire();
                component.find("file").getElement().value='';
                return;
            }
            for(var i=0;i<num_of_files;i++)
            {
                file = fileInput.files[i];
                //console.log("File "+i+": "+file);
                console.log('File size cannot exceed ' + this.MAX_FILE_SIZE);
                console.log('Selected file size: ' + file.size);
                
                if (file.size > this.MAX_FILE_SIZE) {
                    var msg = 'File size cannot exceed ' + this.MAX_FILE_SIZE+' Selected file size: ' + file.size;
                    var createToastEvent = $A.get("e.force:showToast");
                    createToastEvent.setParams({
                        "title": "Error",
                        "message": msg
                    });
                    createToastEvent.fire();
                    component.find("file").getElement().value='';
                    return;
                }
                var self = this;
                fr = new FileReader();
                fr.onload = (function(f)
                             {
                                 return function(e)
                                 {
                                     fileContents = this.result;
                                     var base64Mark = 'base64,';
                                     var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                                     
                                     fileContents = fileContents.substring(dataStart);
                                     
                                     fileContents =  encodeURIComponent(fileContents)
                                     fileData.push(JSON.stringify({fileName : f.name, fileType : f.type, fileContents: fileContents}));
                                     
                                     
                                     if(fileData.length == num_of_files)
                                     {
                                         self.send(component,fileData);
                                     }
                                     
                                 };
                                 
                                 
                             })(file);
                
                fr.readAsDataURL(file);
            }
        }
        else
        {
            this.send(component, fileData);
        }
    },
    waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
    },
    doneWaiting: function(component) {
        var ele = component.find("Accspinner");
        console.log(ele);
        $A.util.addClass(ele,"slds-hide");
        $A.util.removeClass(ele,"slds-show");
    },
    test : function(component, fileData) {
        var action = component.get("c.testMail");
        console.log('in test');
        console.log('file array'+fileData);
        console.log(JSON.stringify((fileData)));
        var fileDataStr = JSON.stringify((fileData));
        action.setParams({
            fileData : fileData
            
        }); 
        
        
        action.setCallback(this,function(data){
            console.log('test response came');
        });
        
        $A.enqueueAction(action); 
    },   
    send : function(component,event,helper) {
       var re = new RegExp("^([^@;]+@akamai.com)$");
       var warningMessages = [];
       component.set("v.warnings"," ");
       var index = 0;
       var fromAddr = component.find("fromAddress").get("v.value");
        if(fromAddr) {
       		this.validateEmail(fromAddr, "From", re, warningMessages, index);
        }
        else {
           warningMessages[index] = "Please select From: email address.";
           index++;
        }
        
       var toAddr = component.find("toAddress").get("v.value");
       if(toAddr) {
           this.validateEmail(toAddr, "To", re, warningMessages, index);
       }
       else {
           warningMessages[index] = "Please enter To: email address.Multiple email addresses should be separated by ';'.";
           index++;
       }
       
       var ccAddr = component.find("ccAddress").get("v.value");
       this.validateEmail(ccAddr, "Cc", re, warningMessages, index);
       if(ccAddr) {
        ccAddr = ccAddr.split(';');
       }
       
       var bccAddr = component.find("bccAddress").get("v.value");
       this.validateEmail(bccAddr, "Bcc", re, warningMessages, index);
       if(bccAddr) {
        bccAddr = bccAddr.split(';');
       }
        
       var template = component.find("emailTemplates").get("v.value");
       var subject = component.find("subject").get("v.value");
       var body = component.find("message").get("v.value");
       var incidentId = component.get("v.recordId");
        
       if(!template && !subject )
       {
           warningMessages[index] = "Please enter subject of the email";
           index++;
       }
       if(!template && !body )
       {
           warningMessages[index] = "Please enter body of the email";
           index++;
       }
       component.set("v.warnings",warningMessages);
       if(warningMessages.length==0)
       {
           var action = component.get("c.sendEmailNew");
           action.setParams({
               incidentId : incidentId,
               fromAddress : fromAddr,
               toAddresses : toAddr,
               ccAddresses : ccAddr,
               bccAddresses : bccAddr,
               templateId : template,
               subject : subject,
               body : body,
               documentId : component.get("v.documentId"),
               fileName : component.get("v.fileName")
           }); 
           
           action.setCallback(this,function(data){
               var state = data.getState();
               if(state == 'ERROR'){
                        var errors = data.getError();
                        
                        if(errors[0].message.indexOf("heap")!=-1||errors[0].message.indexOf("internal server error")!=-1)
                        {
                            /* eslint-disable-next-line */
                            HD_Error_Logger.createLogger(component, event, helper,"Attachment size limit exceeded.Please reduce the file size.", errors[0].message, true, 'error');
                            
                        }
                        //HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
                        else if(errors[0].message.indexOf("assignment to SObject")!=-1)
                        {
                            /* eslint-disable-next-line */
                            HD_Error_Logger.createLogger(component, event, helper, toAddr+" does not exist.", errors[0].message, true, 'error');
                            
                        }
                            else{
                                /* eslint-disable-next-line */
                                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');
                            }
                        $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire(); 
                        return;
                    }
                    
                    component.find("toAddress").set("v.value",component.get("v.incident").BMCServiceDesk__clientEmail__c);
                    component.find("subject").set("v.value","#(Ref:IN:"+component.get("v.incident").Name+")");
                    component.find("emailTemplates").set("v.value",null);
                    component.find("message").set("v.value",null);
                    component.find("message").set("v.placeholder","");
                    component.find("ccAddress").set("v.value",null);
                    component.find("bccAddress").set("v.value",null);
                    //component.find("file").set("v.value",null);
                    //component.find("file").getElement().value='';
                    component.find("subject").set("v.disabled","false");
                    component.set("v.previewFlag","false");
                    component.set("v.documentId",null);
                    component.set("v.fileName",null);
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        
                        "message": "Email sent successfully."
                    });
                    toastEvent.fire();
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                    
                });
            
            $A.enqueueAction(action); 
        }
       
       
   },
    validateEmail : function(email, fieldName, re, warningMessages, index) {
        if(email)
        {
            email = email.split(';'); 
            for (var i = 0 ; i<email.length;i++) {
                if(!email[i].match(re)){
                    warningMessages[index] = "Please enter a valid "+fieldName+": email address (example@akamai.com).Multiple email addresses should be separated by ';'.";
                    index++;
                    break;
                }
            }
        }
    },
    getFromAddresses : function(component, event) {
        var orgWideAddressAction = component.get("c.getOrgWideAddresses");        
        orgWideAddressAction.setCallback(this,function(data){
            var state = data.getState();
            if(state == 'SUCCESS'){
                const addresses = JSON.parse(data.getReturnValue());
                let defaultAddress = '';
                addresses.forEach((address) => {
                    if(address.DisplayName == 'Akamai Ticketing') {
                    	defaultAddress = address.Address;
                	}
                });
                component.set('v.fromAddresses', JSON.parse(data.getReturnValue()));
                component.find("fromAddress").set("v.value", defaultAddress);
            }else if(state == 'ERROR'){
                var errors = data.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, this, errors[0].message,errors[0].message, false, 'error');
                return;
            }
        });
        
        $A.enqueueAction(orgWideAddressAction);  
    }
})