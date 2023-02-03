({
    getData : function(component, event, helper) {
        component.set("v.isUserAuthorized", false);
        component.set("v.errorMessage", "Loading...!");
        helper.toggle(component, event);
        var params = event.getParam('arguments');
        if (params) {
            var sourceId = params.sourceId;
            var sourceType = params.sourceType;
            var parentType = params.parentType;
            component.set("v.sourceId", sourceId);
            component.set("v.sourceType", sourceType);
            component.set("v.parentType", parentType);
            
            var action = component.get("c.getRecords");
            action.setParams({
                "sourceId" : sourceId,
                "sourceType" : sourceType,
                "parentType" : parentType
            });
            
            action.setCallback(this, function(response){
                helper.toggle(component, event);
                var state = response.getState();
                if(state === "SUCCESS"){
                    var qualityCoachingWrapper = response.getReturnValue();
                    console.log("qualityCoachingWrapper");
                    console.log(qualityCoachingWrapper);
                    component.set("v.qualityCoaching", qualityCoachingWrapper.qualityCoaching);
                    component.set("v.tableData", qualityCoachingWrapper.tableData);
                    
                    var isUserAuthorized = qualityCoachingWrapper.isUserAuthorized;
                    var isWrongUser = qualityCoachingWrapper.isWrongUser;
                    if(isUserAuthorized && !isWrongUser)
                        component.set("v.isUserAuthorized", true);
                    else if(isUserAuthorized && isWrongUser){
                        component.set("v.errorMessage", "You cannot edit somebody else's record!");
                    }
                    else{
                        component.set("v.errorMessage", "Only escalation owner can perform Quality Coaching!");
                    }
                }
                else if(state === "ERROR"){;
                    var errors = response.getError();
                    component.set("v.errorMessage", "Darn it! Something went wrong: "+ errors[0].message);
                }
                else{
                    component.set("v.errorMessage", "Darn it! Something went wrong! Please try again or contact your System Administrator!");
                }
                
            });
            $A.enqueueAction(action);
            
        }
    },
    
    //Set Response value for each criteria when user changes the checkbox selection
    setResponseValue: function(component, event, helper){
        var currentCheckboxId = event.target.id;
        var isChecked = event.target.checked;
        //console.log("response method");
        //console.log(currentCheckboxId);
        //console.log(isChecked);
        for(var eachTable of component.get("v.tableData")){
            for(var eachQCC of eachTable.lQualityCoachingCriteria){
                console.log(eachQCC.qualityCoachingCriteria.Criteria_Number__c);
                var criteriaNumber = eachQCC.qualityCoachingCriteria.Criteria_Number__c.toString();
                if(("add-checkbox-" + criteriaNumber) == currentCheckboxId && isChecked){
                    eachQCC.qualityCoachingCriteria.Response__c = "Good";
                }
                if(("add-checkbox-" + criteriaNumber) == currentCheckboxId && !isChecked){
                    eachQCC.qualityCoachingCriteria.Response__c = "Need Fix";
                }
            }
        }
        //console.log(component.get("v.tableData"));
    },
    
    //Save the records
    saveRecord : function(component, event, helper){
        var DURATION_IN_MS='5000';
        component.set("v.dynamicButtonLabel",'Saving...');
        console.log(component.get("v.tableData"));
        
        //Server call to upsert the records
        var action = component.get('c.updateQualityCoachingDetails');
        action.setParams({ 
            "tableData" : JSON.stringify(component.get("v.tableData")),
            "notes": component.get("v.qualityCoaching").Notes__c,
            "sourceId": component.get("v.sourceId"),
            "sourceType": component.get("v.sourceType"),
            "parentType": component.get("v.parentType")
        });
        
        action.setCallback(this, function (response) {
            component.set("v.dynamicButtonLabel",'Save');
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                helper.showToastMessage(component, event, helper,'Saved','Thank you for the rating. Hungry for more? 👨‍🍳‍','success','dismissible', DURATION_IN_MS);
                $A.get('e.force:refreshView').fire();
                helper.closeUtilityItem(component, event);
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','sticky', DURATION_IN_MS);
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','sticky', DURATION_IN_MS);
        });
        $A.enqueueAction(action);
    },
    
    //For tooltip
    displayToolTip : function(component, event, helper) {
        var currentToolTipId = event.target.id;
        var currentToolTipIndex =  parseInt(currentToolTipId.split("-")[1])-1;
        var toggleText = component.find("tooltipText");
        console.log('toggleText');
        console.log(toggleText);
        $A.util.toggleClass(toggleText[currentToolTipIndex], "toggle");
    },

    displayOutToolTip : function(component, event, helper) {
        var currentToolTipId = event.target.id;
        var currentToolTipIndex =  parseInt(currentToolTipId.split("-")[1])-1;
        var toggleText = component.find("tooltipText");
        console.log('toggleText');
        console.log(toggleText);
        $A.util.toggleClass(toggleText[currentToolTipIndex], "toggle");
    }

})