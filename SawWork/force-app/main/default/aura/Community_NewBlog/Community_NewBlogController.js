({
    doInit: function(component) {
        component.set("v.visibilityOptions", [{'label': $A.get('$Label.c.Jarvis_Community_NewBlog_VisibilityOption_Authenticated'), 'value': 'Authenticated'},{'label': $A.get('$Label.c.Jarvis_Community_NewBlog_VisibilityOption_Public'), 'value': 'Public'}]);
        var actionName = component.get("v.action");
        var action = component.get("c.checkAccess");
        var isBlogType = component.get("c.checkBlogType");
        var networkIdAction = component.get("c.fetchCommunityId");
        networkIdAction.setCallback(this, function(response){
            component.set("v.communityId",response.getReturnValue());
        });
        var CCPUser = false;
        var hasAccess;
        isBlogType.setParams({
            blogURL : window.location.pathname.replace("/customers/s/article/","")
        });
        isBlogType.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                if(response.getReturnValue())
                    component.set("v.isBlogType", true);
                else
                    component.set("v.isBlogType", false);
            }
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                hasAccess = response.getReturnValue();
                if (hasAccess){
                    CCPUser = true;
                    if(actionName == 'Create'){
                        component.set("v.isCreate", true);
                        if(component.get("v.visibility") == 'Public'){
                            component.set("v.blog.IsVisibleInCsp", true);
                            component.set("v.blog.IsVisibleInPkb", true);
                        }
                    }
                    else if(actionName == 'Edit')
                        component.set("v.isEdit", true);
                }
            }
        });
        if(actionName == 'Edit')
        {
            var hasKBAccess = component.get("c.checkKBAccess");
            hasKBAccess.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    if(response.getReturnValue())
                        component.set("v.isEdit", true);
                    else
                        component.set("v.isEdit", false);
                }
            });
            var hasAdminAccess = component.get("c.checkAdminAccess");
            var url = window.location.pathname.replace("/customers/s/article/","");
            hasAdminAccess.setParams({
                blogURL : url
            });
            hasAdminAccess.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    if(response.getReturnValue())
                        component.set("v.isDel", true);
                    else
                        component.set("v.isDel", false);
                }
            });
            //Commented by VIKAS
            /*var articleType = component.get("c.fetchArticleType");
            articleType.setParams({
                articleId : component.get("v.recordId")
            });
            articleType.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    var communityBlog = response.getReturnValue();
                    if(CCPUser)
                    {
                        if (communityBlog == true)
                            component.set("v.isEdit", true);
                        else
                            component.set("v.isEdit", false);
                    }
                }
            });*/
        }
        
        $A.enqueueAction(networkIdAction);
        $A.enqueueAction(isBlogType);
        $A.enqueueAction(action);
        if(hasKBAccess != null)
            $A.enqueueAction(hasKBAccess);
        if(hasAdminAccess != null)
            $A.enqueueAction(hasAdminAccess);
        //if(articleType != null)
            //$A.enqueueAction(articleType);
    },
    createBlog: function(component, event, helper) {
        /*var fileInput = component.find("fileId").get("v.files");
        if(fileInput != null && fileInput.length > 0)
            helper.uploadWithFiles(component, event, helper);
        else*/
        helper.uploadWithoutFiles(component, event, helper); 
    },
    showEditBlog: function(component, event, helper) {  
        var action = component.get("c.checkKBAccess");
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                if(a.getReturnValue() == true)
                {
                    var action = component.get("c.fetchBlogRecord");
                    //Setting the Apex Parameter
                    action.setParams({
                        blogId : component.get("v.recordId")
                    });
                    //Setting the Callback
                    action.setCallback(this,function(a){
                        //get the response state
                        var state = a.getState();
                        //check if result is successfull
                        if(state == "SUCCESS"){
                            component.set("v.blog", a.getReturnValue());
                            if(a.getReturnValue().IsVisibleInPkb == true)   
                                component.set("v.visibility", "Public");
                            else if(a.getReturnValue().IsVisibleInCsp == true)  
                                component.set("v.visibility", "Authenticated");
                            /*if(a.getReturnValue().Attachments__Name__s != null)
                                component.set("v.fileName", a.getReturnValue().Attachments__Name__s)*/
                            component.set("v.isOpen", true);
                            component.set("v.isNewForm", true);
                            component.set("v.isConfirmSave", true);
                            component.set("v.isDeleteForm", false);
                            component.set("v.isDelete", false);
                            component.set("v.isConfirmDelete", false);
                            component.set("v.isUploadFile", false);
                        } else if(state == "ERROR"){
                            alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                            //alert('Error in calling server side action');
                        }
                    });
                    //adds the server-side action to the queue        
                    $A.enqueueAction(action);
                }
                else{
                    component.set("v.isOpen", true);
                    component.set("v.isKbAccess", true);
                    component.set("v.isConfirmKbAccess", true);
                }
            } else if(state == "ERROR"){
                alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                //alert('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    showNewBlog: function(component, event, helper) {
        var action = component.get("c.checkKBAccess");
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                if(a.getReturnValue() == true)
                {
                    component.set("v.isOpen", true);
                    component.set("v.isNewForm", true);
                    component.set("v.isConfirmSave", true);
                }
                else{
                    component.set("v.isOpen", true);
                    component.set("v.isKbAccess", true);
                    component.set("v.isConfirmKbAccess", true);
                }
            } else if(state == "ERROR"){
                alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                //alert('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
      if(component.get("v.action") != 'Create')
          component.set("v.isEdit", true);
    },
    handleVisibilityChange: function(component, event, helper) {
        var visibility = event.getParam("value");
        if(visibility == 'Authenticated'){
            component.set("v.blog.IsVisibleInCsp", true);
            component.set("v.blog.IsVisibleInPkb", false);
        }
        else if(visibility == 'Public'){
            component.set("v.blog.IsVisibleInCsp", true);
            component.set("v.blog.IsVisibleInPkb", true);
        }
    },
    showDeleteBlog: function(component, event, helper) {
        var action = component.get("c.checkKBAccess");
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                if(a.getReturnValue() == true)
                {
                    component.set("v.isOpen", true);
                    component.set("v.isDelete", true);
                    component.set("v.isEdit", false);
                    component.set("v.isDeleteForm", true);
                    component.set("v.isConfirmDelete", true);
                    component.set("v.isNewForm", false);
                    component.set("v.isConfirmSave", false);
                    component.set("v.isUploadFile", false);
                }
                else{
                    component.set("v.isOpen", true);
                    component.set("v.isKbAccess", true);
                    component.set("v.isConfirmKbAccess", true);
                }
            } else if(state == "ERROR"){
                alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                //alert('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    deleteBlog : function(component, event, helper) {
        var action = component.get("c.deleteBlogRecord");
        //Setting the Apex Parameter
        action.setParams({
            blogId : component.get("v.recordId")
        });
        //Setting the Callback
        action.setCallback(this,function(a){
            //get the response state
            var state = a.getState();
            //check if result is successfull
            if(state == "SUCCESS"){
                var returnURL = window.location.href.split('/article')[0];
                returnURL+= '/topic/'+a.getReturnValue();
                window.location.href = returnURL+'?tabset-39dc1=2';
                //window.history.back();
            } else if(state == "ERROR"){
                alert($A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError')); // eslint-disable-line no-alert
                //alert('Error in calling server side action');
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    /*handleUploadFinished : function(component, event, helper) {
        var fileName = 'No File Selected..';
        console.log(event);
        //component.get("v.blog").Attachments__Name__s = '';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
    removeAttachment: function(component, event, helper) {
        var fileName = 'No File Selected..';
        component.set("v.fileName", fileName);
        component.get("v.blog").Attachments__Name__s = '';
        delete component.get("v.blog")['Attachments__Name__s'];
    },*/
    showUploadFile: function(component, event, helper){
        component.set("v.isOpen", true);
        component.set("v.isUploadFile", true);
        component.set("v.isEdit", false);
        component.set("v.isDelete", false);
        component.set("v.isNewForm", false);
        component.set("v.isDeleteForm", false);
        component.set("v.isKbAccess", false);
        component.set("v.isConfirmSave", false);
        component.set("v.isConfirmDelete", false);
        component.set("v.isConfirmKbAccess", false);
    },
    onFileUploaded:function(component,event,helper){
        component.set("v.Spinner", true);
        var files = component.get("v.fileToBeUploaded");
        if (files && files.length > 0) {
            var file = files[0][0];
            var reader = new FileReader();
            reader.onloadend = function() {
                var dataURL = reader.result;
                var content = dataURL.match(/,(.*)$/)[1];
                helper.upload(component, file, content, function(answer) {
                    component.set("v.Spinner", false);
                    component.set("v.isEdit", true);
                    component.set("v.isOpen", false);
                    if (answer == "success"){
                        helper.showToastMessage(component, event, helper, $A.get('$Label.c.Jarvis_Community_NewBlog_Toast_SuccessTitle'), $A.get('$Label.c.Jarvis_Community_NewBlog_Toast_SuccessMessage'),'success','dismissible'); //File Successfully Uploaded!
                        setTimeout(function() {location.reload(true);}, 3000);
                    }
                    else
                        helper.showToastMessage(component, event, helper, $A.get('$Label.c.Jarvis_Community_NewBlog_Toast_ErrorTitle'), $A.get('$Label.c.Jarvis_Community_NewBlog_ServerSideError'),'error','dismissible'); //Error in calling server side action
                });
            }
            reader.readAsDataURL(file);
        }
        else{
            component.set("v.Spinner", false);
        }
    }
})