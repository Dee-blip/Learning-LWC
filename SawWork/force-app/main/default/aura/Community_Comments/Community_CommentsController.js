({
    doInit : function(component, event, helper) {
        var userProfileAction = component.get("c.checkAccess");
        var hasAccess;
        userProfileAction.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                hasAccess = response.getReturnValue();
                if (hasAccess){
                    component.set("v.showAddCommentBtn", true);
                }
            }
        });
        var action = component.get("c.fetchBlogComments");
        //Setting the Apex Parameter
        action.setParams({
            blogId : component.get("v.blogId"),
            urlName : component.get("v.urlName")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var i = 0; i < response.getReturnValue().length; i++) {
                    var createdDate = response.getReturnValue()[i].comment.CreatedDate;
                    var formattedDate = new Date(createdDate);
                    var ampm = formattedDate.getHours() >= 12 ? 'pm' : 'am';
                    var finalDate = (formattedDate.toString().split(':')[0].slice(0,-3)).toString()+' at '+formattedDate.getHours()+':'+formattedDate.getMinutes()+' '+ampm;
                    response.getReturnValue()[i].comment.CreatedDate = finalDate.slice(4);
                }
                component.set("v.blogCommentList", response.getReturnValue());
                var cmpTarget = component.find("commentId");
                var cmpTargetRM = component.find("readMoreId");
                var cmpTargetRL = component.find("readLessId");
                if(response.getReturnValue().length == 1){
                    $A.util.addClass(cmpTarget, 'commentStyleCls');
                    if(component.get("v.blogCommentList")[0].comment.Comment__c.length < 300){
                        $A.util.removeClass(cmpTarget, 'commentStyleCls');
                        $A.util.addClass(cmpTarget, 'commentHeightStyleCls');
                        $A.util.addClass(cmpTargetRM, 'hideEle');
                    }
                    $A.util.addClass(cmpTargetRL, 'hideEle');
                }
                else{
                    for (var i = 0; i < response.getReturnValue().length; i++) {
                		$A.util.addClass(cmpTarget[i], 'commentStyleCls');
                        if(component.get("v.blogCommentList")[i].comment.Comment__c.length < 300){
                            $A.util.removeClass(cmpTarget[i], 'commentStyleCls');
                            $A.util.addClass(cmpTarget[i], 'commentHeightStyleCls');
                            $A.util.addClass(cmpTargetRM[i], 'hideEle'); 
                        }
                    }
                    for (var i = 0; i < response.getReturnValue().length; i++) {
                        $A.util.addClass(cmpTargetRL[i], 'hideEle');
                    }
                }
            }
        });
        $A.enqueueAction(userProfileAction);
        $A.enqueueAction(action);
    },
    showNewComment: function(component, event, helper) {
        var newComment = ({'sobjectType': 'Community_Blog_Comment__c', 'Name': '','Comment__c': '', 'Community_Blog_Id__c': ''});
        component.set("v.blogCommentRecord", newComment);
        component.set("v.showAddComment", true);
        component.set("v.isShowForm", true);
        component.set("v.isCreateForm", true);
        component.set("v.isEditForm", false);
        component.set("v.isDeleteForm", false);
        component.set("v.isConfirmSave", true);
        component.set("v.isConfirmDelete", false);
        component.set("v.isCommentBlank",false);
    },
    editComment: function(component, event, helper) {
        var action = component.get("c.fetchBlogComment");
        action.setParams({
            commentId : event.target.id
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                component.set("v.blogCommentRecord", a.getReturnValue());
                component.set("v.showAddComment", true);
                component.set("v.isShowForm", true);
                component.set("v.isCreateForm", false);
                component.set("v.isEditForm", true);
                component.set("v.isDeleteForm", false);
                component.set("v.isConfirmSave", true);
                component.set("v.isConfirmDelete", false);
            } else if(state == "ERROR"){
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_Community_Comments_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        $A.enqueueAction(action);
    },
    showDelForm: function(component, event, helper) {
        component.set("v.delCommRec", event.target.id);
        component.set("v.showAddComment", true);
        component.set("v.isShowForm", false);
        component.set("v.isCreateForm", false);
        component.set("v.isEditForm", false);
        component.set("v.isDeleteForm", true);
        component.set("v.isConfirmSave", false);
        component.set("v.isConfirmDelete", true);
        component.set("v.isCommentBlank",false);
    },
    deleteComment: function(component, event, helper) {
        var action = component.get("c.deleteBlogComment");
        action.setParams({
            commentId : component.get("v.delCommRec")
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                component.set("v.showAddComment", false);
                $A.get('e.force:refreshView').fire();
            } else if(state == "ERROR"){
                //alert('Error in calling server side action');
                alert($A.get('$Label.c.Jarvis_Community_Comments_ServerSideError')); // eslint-disable-line no-alert
            }
        });
        $A.enqueueAction(action);
    },
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "showAddComment" attribute to "Fasle"  
        component.set("v.showAddComment", false);
    },
    addComment: function(component, event, helper) {
        var blogComment = component.get("v.blogCommentRecord");
        var action = component.get("c.addBlogComment");
        var newComment;
        var textComment = blogComment.Comment__c.replace(/<[^>]*>/g, '');
        if(textComment.trim().length == 0){
            component.set("v.isCommentBlank",true);
            return false;
        }
        else{
            //Setting the Apex Parameter
            action.setParams({
                blogCommentrecord : component.get("v.blogCommentRecord"),
                blogId : component.get("v.blogId"),
                urlName : component.get("v.urlName")
            });
            
            action.setCallback(this,function(a){
                var state = a.getState();
                if(state == "SUCCESS"){
                    if(a.getReturnValue() != null && a.getReturnValue().indexOf('SIZEERROR')==0){
                        //alert('Comment('+a.getReturnValue().substr(9)+' characters) exceeded maximum character(131072 characters) limit. Please reduce the size and save.');
                        alert($A.get('$Label.c.Jarvis_Community_Comments_CommentTooLongError')); // eslint-disable-line no-alert
                    }
                    else{
                        component.set("v.showAddComment", false);
                        newComment = ({'sobjectType': 'Community_Blog_Comment__c', 'Name': '','Comment__c': '', 'Community_Blog_Id__c': ''});
                        component.set("v.blogCommentRecord",newComment);
                        $A.get('e.force:refreshView').fire();
                    }
                } 
                else if(state == "ERROR"){
                    //alert('Error in calling server side action');
                    alert($A.get('$Label.c.Jarvis_Community_Comments_ServerSideError')); // eslint-disable-line no-alert
                }
            });
            $A.enqueueAction(action);
        }
    },
    readMore: function(component, event) {
        var cmpTarget = component.find("commentId");
        var cmpTargetRM = component.find("readMoreId");
        var cmpTargetRL = component.find("readLessId");
        if(component.get("v.blogCommentList").length == 1){
            $A.util.removeClass(cmpTarget, 'commentStyleCls');
            $A.util.addClass(cmpTargetRM, 'hideEle');
            $A.util.removeClass(cmpTargetRL, 'hideEle');
        }
        else{
            for (var i = 0; i < component.get("v.blogCommentList").length; i++) {
                if(event.target.id == component.get("v.blogCommentList")[i].comment.Id){
                    $A.util.removeClass(cmpTarget[i], 'commentStyleCls');
                    $A.util.addClass(cmpTargetRM[i], 'hideEle');
                    $A.util.removeClass(cmpTargetRL[i], 'hideEle');
                }
            }
        }
    },
    
    readLess: function(component, event) {
        var cmpTarget = component.find("commentId");
        var cmpTargetRM = component.find("readMoreId");
        var cmpTargetRL = component.find("readLessId");
        if(component.get("v.blogCommentList").length == 1){
            $A.util.addClass(cmpTarget, 'commentStyleCls');
            $A.util.addClass(cmpTargetRL, 'hideEle');
            $A.util.removeClass(cmpTargetRM, 'hideEle');
            if(component.get("v.blogCommentList")[0].comment.Comment__c.length < 300)
                $A.util.addClass(cmpTargetRM, 'hideEle');
        }
        else{
            for (var i = 0; i < component.get("v.blogCommentList").length; i++) {
                if(event.target.id == component.get("v.blogCommentList")[i].comment.Id){
                    $A.util.addClass(cmpTarget[i], 'commentStyleCls');
                    $A.util.addClass(cmpTargetRL[i], 'hideEle');
                    $A.util.removeClass(cmpTargetRM[i], 'hideEle');
                    if(component.get("v.blogCommentList")[i].Comment__c.length < 300){
                        $A.util.addClass(cmpTargetRM[i], 'hideEle');
                    } 
                }
            }
        }
    }
})