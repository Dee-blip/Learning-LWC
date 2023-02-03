({
    initialize : function(cmp, event, helper)
    {
        
        helper.initializeHelper(cmp, event, helper);


    },
    doSave: function(component, event, helper) {
        component.set("v.errormessage","");
        component.set("v.successMessage","");
        if (component.find("fileId").get("v.files").length > 0) {
           helper.checkAndCreateRepoRecord(component, event, helper);
        } else {
             component.set("v.errormessage","Please Select a Valid File");
        }
    },
 
    handleFilesChange: function(component, event, helper) {
        var fileNameSingle = '';
        // var fileNameMultiple = 'No File Selected..';

        if (event.getSource().get("v.files").length > 0) 
        {
            fileNameSingle = event.getSource().get("v.files")[0]['name'];
            // fileNameMultiple = '';
        }
        

        // for(var i=0;i<event.getSource().get("v.files").length;i++)
        // {
        //     fileNameMultiple = fileNameMultiple + ' '+(i+1)+') '+ event.getSource().get("v.files")[i]['name'];
        // }
       
        component.set("v.fileName", fileNameSingle);
        component.set("v.documentName", fileNameSingle.substring(0, fileNameSingle.lastIndexOf(".")));
    },
    
    handleUploadFinished: function(component, event, helper) 
    {
        var uploadedFiles = event.getParam("files");
        alert("Files uploaded : " + uploadedFiles[0].documentId);
    },

    doBack: function(component, event, helper) 
    {
        var isClassic = component.get('v.fromClassic');
       
        var id =  component.get("v.recordId");
        if(isClassic == "true")
        {

            window.location.href='/' + id;
        }
        else
        {
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
            "recordId": id,
            "slideDevName": "detail"
          });
          urlEvent.fire();
        }
        
    },
})