({
    /*uploadWithFiles: function(component, event, helper) {
        var self = this; 
        var fileInput = component.find("fileId").get("v.files");
        if(fileInput.length > 0)
        {
            var file = fileInput[0];
            if (file.size > 2500000) {
                component.set("v.fileName", 'Alert : File size cannot exceed 2500000 bytes.\n' + ' Selected file size: ' + file.size);
                return;
            }
            // create a FileReader object 
            var objFileReader = new FileReader();
            // set onload function of FileReader object   
            objFileReader.onload = $A.getCallback(function() {
                var fileContents = objFileReader.result;
                var base64 = 'base64,';
                var dataStart = fileContents.indexOf(base64) + base64.length;
                fileContents = fileContents.substring(dataStart);
                
                self.uploadWithoutFiles(component, event, helper, file, fileContents);
            });
            objFileReader.readAsDataURL(file);
        }
    },*/
    uploadWithoutFiles: function(component, event, helper) {
        var blog = component.get("v.blog");
        var newBlog;
        /*var aName;
        var aType;
        var aBody;
        if(file != null)
        {
            aName = file.name;
            aType = file.type;
            if(fileContents != null)
                aBody = fileContents;
        }*/
        var dataCategoryId = component.get("v.topicId");
        if(blog.Title != '')
        {
            var action = component.get("c.createBlogRecord");
            //Setting the Apex Parameter
            action.setParams({
                blogrecord : blog,
                dataCategoryId : dataCategoryId
            });
            //Setting the Callback
            action.setCallback(this,function(a){
                //get the response state
                var state = a.getState();
                //check if result is successfull
                if(state == "SUCCESS"){
                    if(a.getReturnValue().indexOf('SIZEERROR')==0){
                        alert($A.get('$Label.c.Jarvis_Community_NewBlog_DescriptionTooLongError')); // eslint-disable-line no-alert
                        //alert('Blog Description('+a.getReturnValue().substr(9)+' characters) exceeded maximum character(131072 characters) limit. Please reduce the size and save.');
                    }
                    else{
                        var curUrl = window.location.pathname;
                        curUrl = curUrl.split('topic/');
                        var newUrl = curUrl[0]+'article/'+a.getReturnValue();
                        newBlog = ({'sobjectType': 'Knowledge__kav', 'Title': '','UrlName': ''});
                        component.set("v.isOpen", false);
                        component.set("v.blog",newBlog);
                        //component.set("v.visibility",component.get("v.visibility"));
                        setTimeout(
                            function() 
                            { 
                                $A.get('e.force:refreshView').fire(); 
                                window.open(newUrl,'_top');
                            }, 1000);
                    }
                    
                } else if(state == "ERROR"){
                    alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                    //alert('Error in calling server side action');
                }
            });
            //adds the server-side action to the queue        
            $A.enqueueAction(action);
        }
        else{
            alert($A.get('$Label.c.Jarvis_Community_NewBlog_TitleMissingError')); // eslint-disable-line no-alert
            //alert('Please enter the Title');
        }
    },
    upload: function(component, file, base64Data, callback) {
        var action = component.get("c.uploadFile");
        console.log('type: ' + file.type);
        action.setParams({
            blogRecordId: component.get("v.recordId"),
            fileName: file.name,
            base64Data: base64Data,
            contentType: file.type
        });
        action.setCallback(this, function(a) {
            callback(a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    //Generic Toast Message body
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    }
})