({
    getData : function(component, event, helper)
     {
        var calcCountValue;
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

            component.set('v.percScore',0);
            component.set('v.maxScore',0);
            component.set('v.totalScore',0);
            var action = component.get("c.getRecords");
            action.setParams({
                "sourceId" : sourceId,
                "sourceType" : sourceType,
                "parentType" : parentType
            });
            
            action.setCallback(this, function(response){
                var isIraptUser,isWrongUser,isIraptAdmin;
                helper.toggle(component, event);
                var state = response.getState();
                if(state === "SUCCESS"){
                    var qualityCoachingWrapper = response.getReturnValue();
                    isIraptAdmin = qualityCoachingWrapper.isIraptAdmin;
                    isWrongUser = qualityCoachingWrapper.isWrongUser;
                    isIraptUser = qualityCoachingWrapper.isIRAPTUser;
                    
                    if( isWrongUser ){
                        component.set("v.errorMessage", "Only IRAPT user can perform Quality Coaching!");
                        component.set("v.isWrongUser", true);
                    } else {
                        component.set("v.qualityCoaching", qualityCoachingWrapper.qualityCoaching);
                        component.set("v.tableData", qualityCoachingWrapper.tableData);
                        component.set("v.maxScore", qualityCoachingWrapper.maxScore);
                        calcCountValue = component.get('c.countScoreValue');
                        $A.enqueueAction(calcCountValue);
                        if( isIraptAdmin )
                            component.set("v.isIraptAdmin", true);
                        else if (isIraptUser) {
                            component.set("v.isIraptUser", true);
                        }
                        
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
    
    countScoreValue : function(component, event, helper){
       var criteriaMet = 0;
       var validity ;
        var isIraptAdmin = component.get('v.isIraptAdmin');
        var tableData = component.get('v.tableData');
        var count = 0;
        var maxScore = 0;
        for( var i =0; i<tableData.length; i++){
            if(isIraptAdmin){
                validity = component.find("response")[i].get("v.validity");
                if(validity && !validity.valid){
                    component.set('v.disableSave',true);
                    return;
                }
            }
            count = count + parseFloat(tableData[i].qualityCoachingCriteria.Score_Rca__c);
            if( parseFloat(tableData[i].qualityCoachingCriteria.Score_Rca__c) > 0){
                criteriaMet += 1; 
                maxScore += parseInt(tableData[i].qualityCoachingCriteria.Max_Score_RCA__c,10);
            }
        }
        component.set('v.disableSave',false);
        component.set('v.totalScore',count.toFixed(2));
        component.set('v.criteriaMet',criteriaMet);
        component.set('v.maxScore', maxScore);
        if(!count && count==0)
            component.set('v.percScore',0);
        else{
            component.set('v.percScore',Math.round(parseFloat(count*100/parseInt(maxScore,10))));
        }
        
    },
    
    //Save the records
    saveRecord : function(component, event, helper){
        var textarea;
        var DURATION_IN_MS;
        var action;
        if( !component.get("v.qualityCoaching").Notes__c ){
            textarea = component.find("notesValue");
            textarea.focus();
            textarea.reportValidity();
            
        } else {
            DURATION_IN_MS='5000';
            component.set('v.showSpinner',true);
            component.set("v.dynamicButtonLabel",'Saving...');
            
            
            //Server call to upsert the records
            action = component.get('c.updateQualityCoachingDetails');
            action.setParams({ 
                "tableData" : JSON.stringify(component.get("v.tableData")),
                "notes": component.get("v.qualityCoaching").Notes__c,
                "sourceId": component.get("v.sourceId"),
                "sourceType": component.get("v.sourceType"),
                "parentType": component.get("v.parentType"),
                "maxScore" : component.get('v.maxScore'),
                "criteriaMetNumber" : component.get('v.criteriaMet')
            });
            
            action.setCallback(this, function (response) {
                var state;
                var errors;
                component.set("v.dynamicButtonLabel",'Save');
                state = response.getState();
                if (state === "SUCCESS") {
                    $A.get("e.force:closeQuickAction").fire();
                    helper.showToastMessage(component, event, helper,'Saved','Thank you for the rating. Hungry for more? 👨‍🍳‍','success','dismissible', DURATION_IN_MS);
                    $A.get('e.force:refreshView').fire();
                    helper.closeUtilityItem(component, event);
                } 
                else if (state === "ERROR") {
                    errors = response.getError();
                    helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','sticky', DURATION_IN_MS);
                }
                else
                    helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','sticky', DURATION_IN_MS);

                component.set('v.showSpinner',false);
            });
            $A.enqueueAction(action);
        }
        
    },
    
    



})