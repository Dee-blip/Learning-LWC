({
    doInit : function(component, event, helper) {
      
        var action = component.get("c.fetchInitialDetails");
        var storeResponse ;
        // set param to method  
          action.setParams({
              recId: component.get("v.recordId")
              
            });
        // set a callBack    
          action.setCallback(this, function(response) {
            
              var state = response.getState();
              if (state === "SUCCESS") {
                 storeResponse = response.getReturnValue();
                  if(storeResponse.loggedinUser.Profile.Name === 'Sales - Web' && storeResponse.loggedinUser.Title.includes('Customer Success Manager')){
                    component.set("v.isCXMUser",true);
                    helper.handleSubjectChange(component); 
                  component.set("v.relatedToName", storeResponse.relatedToName);
                  component.set("v.relatedToId", storeResponse.relatedToName);
                  component.set("v.selectedUserId", storeResponse.loggedinUserId);
                  component.set("v.selectedUser", storeResponse.loggedinUser);
                  
                 
                  component.set("v.showAssignedToLookUp",true);
                  component.set("v.subjectList",storeResponse.subjectList);
                  component.set("v.statusList",storeResponse.statusList);
                  component.set("v.priorityList",storeResponse.priorityList);
                  }else{
                    component.set("v.isCXMUser",false);
                  }
                  

                  component.set("v.showSpinner",false);
               
              }
              else if (state === "ERROR") {
                
                helper.showMyToast(component, event, helper,'Please contact System Administrator.','error');
                component.set("v.showSpinner",false);
                console.log(JSON.stringify(response.getError()));
          }
          else if (state === "INCOMPLETE") {
          
              helper.showMyToast(component, event, helper,'Please contact System Administrator.','error');
              component.set("v.showSpinner",false);
        }
   
          });
        // enqueue the Action  
          $A.enqueueAction(action);
    },
    handleCreateTask: function(component, event, helper) {
      var subjectVal;
      var statusVal;
      var dueDateVal;
      var commentsVal;
      var assignedToVal;
      var relatedToVal ;
      var nameVal ;
      var priorityVal;
      var product ;
      var feature;
      var action;
        component.set("v.showSpinner",true);
        if(component.find("subject").get("v.value") === 'Product Feature Consideration' && ($A.util.isUndefinedOrNull(component.find("parentField").get("v.value")) || $A.util.isEmpty(component.find("parentField").get("v.value")) || $A.util.isUndefinedOrNull(component.find("childField").get("v.value")) || $A.util.isEmpty(component.find("childField").get("v.value")))){
          helper.showMyToast(component, event, helper,'Please select Product and Feature.','error');
          component.set("v.showSpinner",false);
        }else{
        subjectVal = component.find("subject").get("v.value");
        statusVal = component.find("status").get("v.value");
        dueDateVal = component.find("dueDate").get("v.value");
        
        commentsVal = component.find("comments").get("v.value");
        assignedToVal = component.get("v.selectedUserId");
        relatedToVal = component.get("v.recordId");
        nameVal = component.get("v.selectedNameId");
        priorityVal = component.find("priority").get("v.value");
        product = '';
        feature = '';
        if(component.find("subject").get("v.value") === 'Product Feature Consideration'){
          product = component.find("parentField").get("v.value");
          feature = component.find("childField").get("v.value");
        }
        action = component.get("c.createCXMActivity");
       
        // set param to method  
          action.setParams({
              
              subjectVal : subjectVal,
              statusVal : statusVal,
              dueDateVal : dueDateVal,
              commentsVal : commentsVal,
              assignedToVal : assignedToVal,
              relatedToVal : relatedToVal,
              nameVal : nameVal,
              priorityVal : priorityVal,
              product :product,
              feature : feature

            });
        // set a callBack    
          action.setCallback(this, function(response) {
            
              var state = response.getState();
            
              if (state === "SUCCESS") {
                  if(response.getReturnValue().error === ''){
                        helper.showMyToast(component, event, helper,'Task has been successfully created','success');
                      //  alert(response.getReturnValue().taskId);
                        component.set("v.taskRecordId",response.getReturnValue().taskId);
                        component.set("v.stepName",'2. Upload Files');
                  }else{
                    helper.showMyToast(component, event, helper,'Please contact System Administrator.','error');
                  }
                  component.set("v.showSpinner",false);
              }
              else if (state === "ERROR") {
                 
                  helper.showMyToast(component, event, helper,'Please contact System Administrator.','error');
                  
                      component.set("v.showSpinner",false);
                      console.log(JSON.stringify(response.getError()));
                }
                else if (state === "INCOMPLETE") {
                
                    helper.showMyToast(component, event, helper,'Please contact System Administrator.','error');
                    component.set("v.showSpinner",false);
              }
   
          });
        // enqueue the Action  
          $A.enqueueAction(action);
        }

    } ,
    handleUploadFinished :function(component, event, helper) {
      // Close the action panel
      var dismissActionPanel = $A.get("e.force:closeQuickAction");
      dismissActionPanel.fire();
        helper.showMyToast(component, event, helper,'Selected files have been successfully uploaded.','success');
    }  ,
    
    

    handleSubjectChange : function(component, event, helper) {
      helper.handleSubjectChange(component);
      
    },

    parentFieldChange : function(component, event, helper) {
    helper.parentFieldChange(component);
	}
    
})