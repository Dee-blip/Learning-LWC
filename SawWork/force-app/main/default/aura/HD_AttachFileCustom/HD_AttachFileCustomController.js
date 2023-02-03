({
    doInit: function(cmp,event){
      console.log("In init");
      console.log(cmp.get("v.valueFromPage"));
        var recordId = cmp.get("v.recordId");
        var url = "/apex/HD_AttachFilePage?id="+encodeURIComponent(recordId);
      cmp.set("v.ifmsrc",url);  
    },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
		var uploadedFiles = event.getParam("files");
        console.log("uploadedFiles:"); 
        console.log(uploadedFiles);
        console.log("Document ID:");
        console.log(uploadedFiles[0].documentId);
        var docId = uploadedFiles[0].documentId;
		// show success message – with no of files uploaded
		var action = component.get("c.convertFileToAttachment");
        action.setParams({
            incId: component.get("v.recordId"),
            fileId: docId
        });
    	action.setCallback(this,function(data){
    		var data = data.getReturnValue();
    		console.log("Data: "+data);
    		component.set("v.attachmentId",data);
    		console.log("v.attachmentId: "+component.get("v.attachmentId"));
		}); 
		 $A.enqueueAction(action); 
		var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
			"type" : "success",
			"message": uploadedFiles.length+" files has been updated successfully!"
        });
		toastEvent.fire();
        $A.get("e.force:refreshView").fire();
        // Close the action panel
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
    },
    
    save : function(component,event,helper){
        var recordId = component.get("v.recordId");
        var url = "https://akamai--p2rdemo.cs54.my.salesforce.com/apex/HD_AttachFilePage?id="+recordId;
        //window.open(url,'_self');
        var loadingWindow=window.open(url,'','top=100,left=100,height=300,width=600,toolbar=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=no,modal=yes');
        console.log('Reached back in component');
        console.log(loadingWindow);
        if(loadingWindow.closed){
            console.log('Attachment created');
        }
        else{
            console.log('Never true');
        }
    }

})