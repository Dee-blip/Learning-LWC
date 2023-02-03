({
    initialize : function(cmp, event, helper)
    {
        
        helper.initializeHelper(cmp, event, helper);


    },

    submitComment:function(cmp, event, helper)
    {
        helper.submitCommentHelper(cmp, event, helper);
    },

    loadOAAndTaskComponent:function(component, event, helper)
    {

        console.log('inisde loadOAAndTaskComponent');
        var name = 'c:SF1_TaskApp_OA_Cmp';
        var opptyId = event.currentTarget.id;
        var attributes={
            'oaId' :component.get("v.relatedObjectId"),
            'comingFromTaskInterface':'true'
        };
        helper.navigateToCmp(component, event, helper ,name ,attributes);

    },

    showEditModal : function(cmp, event, helper)
    {
        var action = cmp.get("c.getTask");
        var taskId = cmp.get("v.taskId");


        action.setParams({ "taskId" : taskId

                          });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") {
                cmp.set("v.updateTaskObject",response.getReturnValue());
                helper.loadTaskStatusValues(cmp);
            }


        });
        $A.enqueueAction(action);





    },
    saveEditModal : function(cmp, event, helper)
    {
    	var action = cmp.get("c.editTask");
        var taskObj = cmp.get("v.updateTaskObject");
        //var originalLegalCheck = cmp.get("v.legalFollowUpNeeded");
        var originalOwner = cmp.get("v.taskAssignedToID");
        var originalStatus = cmp.get("v.taskStatus");
        var originalDueDate = new Date(cmp.get("v.taskDueDate"));
        var newDueDate = new Date(taskObj.ActivityDate);

        if(taskObj.OwnerId == null || taskObj.OwnerId == "")
        {
        	cmp.set("v.taskEditError","Error : Please select a valid User");
        }
        else if(originalStatus == taskObj.Status &&
        	    (originalDueDate.getDate() ==  newDueDate.getDate() && originalDueDate.getMonth() ==  newDueDate.getMonth() && originalDueDate.getFullYear() ==  newDueDate.getFullYear())&&
        	    originalOwner == taskObj.OwnerId)
        {
        	cmp.set("v.taskEditError","Warning : No Value changed");
        }
        else
        {



        	cmp.set("v.taskEditError","");

        action.setParams({ "taskObject" : taskObj

                          });

        action.setCallback(this, function(response) {

            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS")
            {
               cmp.set('v.displayEditModal', false);
               helper.initializeHelper(cmp, event, helper) ;
            }


        });
       $A.enqueueAction(action);
   		}


    },

    cancelEditModal : function(component, event, helper)
    {
        component.set('v.displayEditModal', false);
    },
    clearSearchBox : function(component, event, helper)
    {
        component.set('v.displayEditModal', false);
    },

    showModal : function(component, event, helper)
    {
        component.set('v.displayModal', true);
    },

    hideModal : function(component, event, helper)
    {
        component.set('v.displayModal', false);
    },
    showUserModal : function(component, event, helper)
    {
        component.set('v.displayUserModal', true);
    },
    selectUserModal : function(component, event, helper)
    {
        var userList = component.get("v.atMentionUserList");
        var thisUser = component.get('v.atMentionUserId');
        if(thisUser != null)
        {
            userList.push(thisUser);
            helper.appendUserToInputBox(component,thisUser);
        }

        component.set('v.displayUserModal', false);
        component.set('v.atMentionUserId',null);
        component.find("taskCommentInputId").getElement().focus();
    },
    cancelUserModal : function(component, event, helper)
    {
        component.set('v.atMentionUserId',null);
        component.set('v.displayUserModal', false);
        component.find("taskCommentInputId").getElement().focus();
    },
    commentBoxInFocus : function(cmp, event, helper)
    {
        var newComment = cmp.get("v.newtaskCommentInputbyUser");
        if(newComment != null)
        {
        	var ta = document.getElementsByTagName('textarea')[0];
        	ta.setSelectionRange(newComment.length,newComment.length);
    	}

    },
    commentBoxOutFocus: function(cmp, event, helper)
    {
        //  var cmpTarget = cmp.find('taskInfoSection');
        //  $A.util.removeClass(cmpTarget, 'slds-is-fixed');
        // $A.util.addClass(cmpTarget, 'slds-is-relative');


    }
})