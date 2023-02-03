({
    doInit: function(component) {
        var actionName = component.get("v.action");
        var action = component.get("c.checkAccess");
        //Changes by Vikas for ESESP-1678
        var networkIdAction = component.get("c.fetchCommunityId");
        networkIdAction.setCallback(this, function(response){
            component.set("v.communityId",response.getReturnValue());
        });
        var hasAccess;
        action.setParams({
            documentGroupId : component.get("v.documentGroupId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                hasAccess = response.getReturnValue();
                if (hasAccess)
                {
                    if(actionName == 'Create')
                        component.set("v.isCreate", true);
                    else if(actionName == 'Edit')
                        component.set("v.isEdit", true);
                }
            }
        });
        if(actionName == 'Edit')
        {
            var articleType = component.get("c.fetchDocumentEditAccess");
            articleType.setParams({
                documentGroupId : component.get("v.documentGroupId")
            });
            articleType.setCallback(this, function(response){
                var state = response.getState();
                if(state == "SUCCESS"){
                    var communityBlog = response.getReturnValue();
                    if (communityBlog == true)
                        component.set("v.isEdit", true);
                    else
                        component.set("v.isEdit", false);
                }
            });
        }
        
        $A.enqueueAction(networkIdAction);
        $A.enqueueAction(action);
        if(articleType != null)
            $A.enqueueAction(articleType);
    },
    createDocument: function(component, event, helper) {
        var doc = component.get("v.doc");
        var newdoc;
        let url = '/customers/s/customer-community-document/';
        
        var documentGroupId = component.get("v.documentGroupId");
        if(doc.Title__c != '')
        {
            var action = component.get("c.createDocRecord");
            //Setting the Apex Parameter
            action.setParams({
                docRecord : doc,
                documentGroupId : documentGroupId
            });
            //Setting the Callback
            action.setCallback(this,function(a){
                //get the response state
                var state = a.getState();
                //check if result is successfull
                if(state == "SUCCESS"){
                   // alert(a.getReturnValue());
                    if(a.getReturnValue() != null && a.getReturnValue().indexOf('SIZEERROR')==0){
                        //alert('Document Description('+a.getReturnValue().substr(9)+' characters) exceeded maximum character(131072 characters) limit. Please reduce the size and save.');
                        alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_DescriptionTooLongError')); // eslint-disable-line no-alert
                    }
                    else if(a.getReturnValue() != null && a.getReturnValue().indexOf('EXCEPTION')==0){
                        //alert('Error while saving the document. '+a.getReturnValue().substr(9));
                        alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_ServerSideError')); // eslint-disable-line no-alert
                    }
                    else{
                        newdoc = ({'sobjectType': 'Customer_Community_Document__c', 'Title__c': ''});
                        url = url+a.getReturnValue();
                        component.set("v.isOpen", false);
                        component.set("v.doc",newdoc);
                        setTimeout(
                            function() 
                            { 
                                //$A.get('e.force:refreshView').fire(); 
                                //window.open(window.location.href,'_top');
                                //window.history.go();
                                window.location=url;
                                
                            }, 1000);
                    }
                } else if(state == "ERROR"){
                    //alert('Error in calling server side action');
                    alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_ServerSideError')); // eslint-disable-line no-alert
                }
            });
            //adds the server-side action to the queue        
            $A.enqueueAction(action);
        }
        else{
            //alert('Please enter the Title');
            alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_MissingTitleError')); // eslint-disable-line no-alert
        }
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
                            component.set("v.isOpen", true);
                            component.set("v.isNewForm", true);
                            component.set("v.isConfirmSave", true);
                            component.set("v.isDeleteForm", false);
                            component.set("v.isConfirmDelete", false);
                        } else if(state == "ERROR"){
                            //alert('Error in calling server side action');
                            alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_ServerSideError')); // eslint-disable-line no-alert
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
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_CommunityDocument_Create_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        //adds the server-side action to the queue        
        $A.enqueueAction(action);
    },
    showNewDocument: function(component, event, helper) {
        component.set("v.isOpen", true);
        component.set("v.isNewForm", true);
        component.set("v.isConfirmSave", true);
    },
    closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
      // changes by Vandhana for ESESP-1615 : Clear Title/Desc on Cancel
      component.find("blogTitleField").set("v.value",""); 
      component.find("blogDescField").set("v.value","");
    },
})