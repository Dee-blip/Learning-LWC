({
	MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event) 
    {
        // start/show the loading spinner   
       // component.set("v.showLoadingSpinner", true);
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileId").get("v.files");
        
        var self = this;
        // get the first file using array index[0]  
        var file = fileInput[0];
 
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
 
            fileContents = fileContents.substring(dataStart);
            // call the uploadProcess method 
            self.uploadProcess(component, file, fileContents);
        });
 
        objFileReader.readAsDataURL(file);

    },
 
    uploadProcess: function(component, file, fileContents) {
        // set a default size or startpostiton as 0 
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
 
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    },
 
 
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        // call the apex method 'saveChunk'
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get("c.uploadFiles");
        action.setParams({
            parentId: component.get("v.newDocumentId"),
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileId: attachId,
        });
        var oldAttachId = attachId;
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    
                    this.addAttachmentToRecordHelper(component, attachId);

                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
            	component.set("v.errormessage","From server: " + response.getReturnValue());
               
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        if(oldAttachId != null)
                        {

                        this.addAttachmentToRecordHelper(component, oldAttachId);

                        }
                        else
                        {
                            component.set("v.errormessage","Error : "+errors[0].message);
                        }
                        
                    }
                } else {
                    component.set("v.errormessage","Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    initializeHelper : function(cmp, event, helper)
    {

        var action = cmp.get("c.getInitValues");
       


        action.setParams({ "objId" : cmp.get("v.recordId")

                         });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                if(returnVal != null && returnVal.size > 0)
                {
                    cmp.set("v.hasAccessError", false);
                    cmp.set('v.optionsDocumentType',returnVal.DocumentType);
                    cmp.set('v.selectedDocumentType',returnVal.DocumentType[0]);
                
                    cmp.set('v.optionsStandardCustomized',returnVal.AkamaiType);
                    cmp.set('v.selectedStandardCust',returnVal.AkamaiType[0]);
                    cmp.set('v.accountId',returnVal.Account[0]);
                    cmp.set('v.accountName',returnVal.Account[1]);
                    cmp.set('v.originalOpportunityId',returnVal.Opportunity[0]);
                    cmp.set('v.originalOpportunityName',returnVal.Opportunity[1]);
                }
                else
                {
                    cmp.set("v.errormessage","Insufficient permissions on the record. Make sure you have edit access to Add an attachment."); 
                    cmp.set("v.hasAccessError", true);
                    cmp.set("v.finished", true);
                }

            }
        });
        $A.enqueueAction(action);


    },
    createDocumentRepoRecord : function(component, event)
    {

        var action = component.get("c.insertDocumentRepoRecord");
       
        var masterLegalDocId;
        if(component.get('v.masterLegalDocObject') != null)
        {
            masterLegalDocId = component.get('v.masterLegalDocObject').Id;
        }
        action.setParams({ "docName" : component.get('v.documentName'),
        					"accountId" : component.get('v.accountId'),
        				   "effectiveDate" : component.get('v.selectedEffectiveDate'),
        				   "expirationDate" : component.get('v.selectedExpirationDate'),
						   "akamaiType" : component.get('v.selectedStandardCust'),
        				   "documentType" : component.get('v.selectedDocumentType'),
                           "originalOpportunityId" : component.get('v.originalOpportunityId'),
                           "masterLegalDocumentId" : masterLegalDocId,
                           "relatedObjectId" : component.get('v.recordId'),

                         });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                if(!returnVal.includes('Error'))
                {
                	component.set("v.newDocumentId",returnVal);  
                    this.uploadHelper(component, event);     	
                }
                else
               	{
               		component.set("v.errormessage",returnVal);	
               	}
            }
        });
        $A.enqueueAction(action);


    },
    checkAndCreateRepoRecord: function(component, event, helper) 
    {
        //check file size
        var fileInput = component.find("fileId").get("v.files");
        
        var self = this;
        // get the first file using array index[0]  
        var file = fileInput[0];
        if (file.size > self.MAX_FILE_SIZE) {
           
            component.set("v.fileName", 'Alert : File size cannot exceed 4.5MB.\n' + ' Selected file size: ' + (file.size/1000000)+'MB');
            return;
        }

        if( component.get('v.documentName') == "" || 
            component.get('v.selectedExpirationDate') == null || 
            component.get('v.selectedExpirationDate') == "" ||
            component.get('v.selectedEffectiveDate') == null ||
            component.get('v.selectedEffectiveDate') == "")
        {
            var error = '';
           if(component.get('v.documentName') == "")
           {
                error = error+"Name ";
           } 
          if(component.get('v.selectedEffectiveDate') == null || component.get('v.selectedEffectiveDate') == "")
           {
                error = error+"Effective Date ";
           }
           if(component.get('v.selectedExpirationDate') == null || component.get('v.selectedExpirationDate') == "")
           {
                 error = error+"Expiration Date ";
           }

           component.set("v.errormessage",error+" can not be empty");
        }
        else
        {
            component.set("v.errormessage","");
            component.set("v.successMessage","");
            this.createDocumentRepoRecord(component, event);
        }

    },
    addAttachmentToRecordHelper : function(component, attachId)
    {

        var action = component.get("c.addAttachmenttoRecord");
       
        action.setParams({ "recordId" : component.get('v.recordId'),
                            "attachmentId" :attachId,

                         });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                if(!returnVal.includes('Error'))
                {
                    component.set("v.successMessage","Uploaded successfully!");
                    component.set("v.finished", true);     
                }
                else
                {
                    component.set("v.errormessage",returnVal);   
                }
            }
        });
        $A.enqueueAction(action);       
    }
                       
})