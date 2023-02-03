({
    MAX_FILE_SIZE: 750 000, /* 1 000 000 * 3/4 to account for base64 */
    NUM_OF_ATTACHMENTS: 0,
    
    save : function(component) {
        var fileInput = component.find("file").getElement();
    	console.log("fileInput: ");
    	console.log(fileInput);
    	console.log("fileInput.files: ");
    	console.log(fileInput.files);
    	var file = null;    	
    	var fileContents = null;
    	var fr;
 		var num_of_files = fileInput.files.length;
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
 		for(i=0;i<num_of_files;i++){
    		file = fileInput.files[i];
    		var fileSize = (file.size / (1024*1024)).toFixed(2);
    		var maxSize = (this.MAX_FILE_SIZE / (1024*1024)).toFixed(2);
    		//console.log("File "+i+": "+file);
        	console.log('File size cannot exceed ' + maxSize);
    		console.log('Selected file size: ' + fileSize);
   
        	if (fileSize > maxSize) {
    			var msg = "File size cannot exceed " + maxSize +  " MB.\n" +
    		  	"Selected file size: " + fileSize+ " MB.";
                    var createToastEvent = $A.get("e.force:showToast");
                    createToastEvent.setParams({
                        "title": "Error",
                        "message": msg
                    });
                    createToastEvent.fire();
            	//alert('File size cannot exceed ' + this.MAX_FILE_SIZE + ' bytes.\n' +
    		  	//'Selected file size: ' + file.size);
    			component.find("file").getElement().value='';
    	    	return;
        	}
    
        	fr = new FileReader();
        
			var self = this;
			console.log('Self: ');
			console.log(self);
       		fr.onload = (function(f) 
            {
                return function(e)
                    {
                        fileContents = this.result;
                    	console.log("Title: "+f.name)
                    	var base64Mark = 'base64,';
                    	var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        
                    fileContents = fileContents.substring(dataStart);
                    console.log('json');
                    self.upload(component,f,fileContents);
                        
                    };
                     
     
            })(file);
           

        fr.readAsDataURL(file);
	}
    	//var message = num_of_files + " attachments created";
    	//component.set("v.attachMsg",message);
   },
        
    upload: function(component, f,fileContents) {
        var action = component.get("c.saveFile"); 
        //var fileInput = component.find("file").getElement();
    	//console.log("fileInput: ");
    	//console.log(fileInput);
    	//console.log("fileInput.files: ");
    	//console.log(fileInput.files);
 		//var numOfAttachments = fileInput.files.length;

        action.setParams({
            incId: component.get("v.recordId"),
            fileName: f.name,
            base64Data: encodeURIComponent(fileContents), 
            contentType: f.type
        });

        action.setCallback(this, function(a) {
            //if state= success
            //if error, show the file which failed
            var state = a.getState();
            console.log("Attach File state: "+state);
            if(state == 'SUCCESS'){
            	this.NUM_OF_ATTACHMENTS = this.NUM_OF_ATTACHMENTS + 1;
            	attachId = a.getReturnValue();
            	console.log("Attachment ID: ");
            	console.log(attachId);
            	//console.log("numOfAttachments:");
            	//console.log(numOfAttachments);
            	//alert("Attachment created: "+attachId);
            	console.log("Creating message: ");
        		var message = this.NUM_OF_ATTACHMENTS+" attachment(s) created";
        		console.log(message);
        		component.set("v.attachMsg",message);
        		$A.util.addClass(component.find("messages").getElement(), "uploading");
    			$A.util.removeClass(component.find("messages").getElement(), "notUploading");
        		component.find("file").getElement().value='';
                $A.get('e.force:refreshView').fire();
            }
            else if(state == 'ERROR'){
                var message = "Failed to attach file: "+file.name;
                component.set("v.attachMsg",message);
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
            
        });
        //$A.enqueueAction(action); 
        $A.run(function() {
            $A.enqueueAction(action); 
        });
        
        
        
    },
         waitingHelper: function(component) {
        var ele = component.find("Accspinner");
        console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
        //document.getElementById("Accspinner").style.display = "block";
     },
     
      doneWaitingHelper: function(component) {
            var ele = component.find("Accspinner");
          	console.log(ele);
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     }
})