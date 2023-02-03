({
    initializeHelper : function(cmp, event, helper)
    {

        var action = cmp.get("c.getTaskDetails");
        var taskId = cmp.get("v.taskId");


        action.setParams({ "taskId" : taskId

                         });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") {
                var returnVal = JSON.parse(response.getReturnValue());

                cmp.set("v.currentUserName",returnVal.currentUserName);
                cmp.set("v.taskComment",returnVal.taskComment);
                cmp.set("v.taskStatus",returnVal.taskStatus);
                cmp.set("v.taskRelatedTo",returnVal.taskRelatedTo);
                cmp.set("v.taskSubject",returnVal.taskSubject);
                cmp.set("v.taskAssignedTo",returnVal.taskAssignedTo);
                cmp.set("v.taskAssignedToID", returnVal.taskAssignedToID);
                cmp.set("v.taskType",returnVal.taskType);
                cmp.set("v.taskUserCellPhone",returnVal.taskUserCellPhone);
                cmp.set("v.taskUserOfficePhone",returnVal.taskUserOfficePhone);
                cmp.set("v.relatedObjectId",returnVal.relatedObjectId);
                cmp.set("v.legalFollowUpNeeded",returnVal.legalFollowUpNeeded);
                cmp.set("v.taskDueDate",returnVal.taskDueDate);


            }


        });
        $A.enqueueAction(action);


    },
    submitCommentHelper:function(cmp, event, helper)
    {
        var newComment = cmp.get("v.newtaskCommentInputbyUser");
        var taskId = cmp.get("v.taskId");
        var taskOwnerId = cmp.get("v.taskAssignedToID");
        var userList = cmp.get("v.atMentionUserList");
        userList = helper.filterUsersByReadingComments(userList, newComment);
        var formattedComment = helper.formatCommentForAtMention(userList,newComment);
        var action = cmp.get("c.submitCommentbyUser");
        action.setParams({ "taskId" : taskId,
                          "taskOwnerId" : taskOwnerId,
                          "comment" : formattedComment,
                          "taggedUsersJSON" : $A.util.json.encode(userList)

                         });
        var self = this;
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if (cmp.isValid() && state === "SUCCESS")
                               {
                                   self.initializeHelper(cmp, event, helper) ;

                                   cmp.set("v.newtaskCommentInputbyUser","");
                                   // Flush the Userlist
                                   var emptyUserList = cmp.get("v.atMentionUserList");
                                   emptyUserList.length =0;
                                   cmp.set("v.atMentionUserList",emptyUserList);
                               }


                           });

        if(newComment != "" && newComment != null)
        {
            $A.enqueueAction(action);
        }
    },
    appendUserToInputBox:function(cmp, userObject)
    {
        var existingComment = cmp.get("v.newtaskCommentInputbyUser");
        if(existingComment == null)
        {
            existingComment = "@["+userObject.Name+"] ";
        }
        else
        {
            existingComment = existingComment + " @["+userObject.Name+"] ";
        }

        cmp.set("v.newtaskCommentInputbyUser", existingComment);
    },
    filterUsersByReadingComments:function(userList, newComment)
    {
        var newUserList = new Array();
        for (let user of userList)
        {
            var uNameTag = "@["+user.Name+"]";
            if(newComment.includes(uNameTag))
            {
                newUserList.push(user);
            }
        }
        return newUserList;
    },
    formatCommentForAtMention:function(userList, newComment)
    {
        var updatedComment = newComment;
        for (let user of userList)
        {
            var uNameTag = "@["+user.Name+"]";
            if(updatedComment.includes(uNameTag))
            {
                updatedComment = updatedComment.replace(uNameTag,"@"+user.Name);
            }
        }
        return updatedComment;
    },
    navigateToCmp : function(component, event, helper ,name, attributes) {
        console.log('inside navigateToCmp of SF1_Component_TaskInterface');
        var e = $A.get("e.c:SF1_NavigationBetweenComponentsEvent");
        e.setParams({
            "paramMap" : attributes,
            "nameOfCmp":name
        });
        e.fire();
    },
    loadTaskStatusValues : function(component) {
        var statusValues = component.get("c.loadTaskStatusPicklist");
        statusValues.setCallback(this, function(response) {
        var state = response.getState();
        var options = response.getReturnValue();
        if (component.isValid() && state === "SUCCESS") {
          component.set("v.taskStatusValues",options);
          component.set("v.taskEditError","");
          component.set('v.displayEditModal', true);
        }
        });
        $A.enqueueAction(statusValues);
    }

})