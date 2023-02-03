({
    loadSectionData : function(component, event, helper) {
        component.set("v.spinnerBool",true);
        var action = component.get("c.getInitialData");
        var state;
        var res;
        action.setParams({"opportunityId":component.get("v.recordId")});
        action.setCallback(this,function(response) {
            component.set("v.spinnerBool",false);
            state = response.getState();
            if(state === "SUCCESS"){
                res=response.getReturnValue();
                component.set("v.sectionList",res.sectionList);
                component.set("v.opp",res.opp);
                component.set("v.ebIdentified",res.ebIdentified);
                component.set("v.championIdentified",res.championIdentified);
                component.set("v.competitorIdentified",res.competitorIdentified);
                component.set("v.showSalesCoachingReview",res.showSalesCoachingReview);
                if(res.opp.MEDDICC__r == undefined){
                    component.set("v.needLoadingOfData",true);
                }
                this.setOverallProgress(component, event, helper);
            }
            else if(state === "ERROR"){
                helper.showMessageHelper('error','Error!',response.getError()[0].message);
            }
            else{
            	helper.showMessageHelper('error','Error!','Unknown Error Occured.');  
            }
        });
        $A.enqueueAction(action);
    },
    loadCompetitors : function(component, event, helper) {
        var action = component.get("c.getCompetitors");
        var state;
        action.setCallback(this,function(response) {
            state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.competitorList",response.getReturnValue());
            }
            else if(state === "ERROR"){
                helper.showMessageHelper('error','Error!',response.getError()[0].message);
            }
            else{
            	helper.showMessageHelper('error','Error!','Unknown Error Occured.');        
            }
        });
        $A.enqueueAction(action);
    },
    setOverallProgress : function(component, event, helper) {
        var allSections = component.get("v.sectionList");
        var overallCompletedVal=0;
        var secCompletedVal;
        var qsList;
        var i,j;
        for(i=0;i<allSections.length;i++){
            secCompletedVal=0;
            qsList=allSections[i].questionList;
            for(j=0;j<qsList.length;j++){
                if(qsList[j].response)
                    secCompletedVal=secCompletedVal+qsList[j].question.Question_Weightage__c;
                if(qsList[j].question.AKAM_MEDDICC_Questionnaire_ID__c==component.get("v.ebIdentified"))
                    component.set("v.showEconomicBuyerSelections",qsList[j].response);
                if(qsList[j].question.AKAM_MEDDICC_Questionnaire_ID__c==component.get("v.championIdentified"))
                    component.set("v.showChampionSelections",qsList[j].response);
            }
            overallCompletedVal=overallCompletedVal+secCompletedVal;
            allSections[i].sectionCompletion=parseInt((secCompletedVal*100)/allSections[i].sectionWeightage);
        }
        component.set("v.sectionList",allSections);
        component.set("v.progressValue",overallCompletedVal);
    },
    showMessageHelper : function(type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    }
})