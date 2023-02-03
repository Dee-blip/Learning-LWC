({
    doInit : function(component, event, helper) {
        helper.loadSectionData(component, event, helper);
        helper.loadCompetitors(component, event, helper);
    },
    refreshSectionData : function(component, event, helper) {
        helper.loadSectionData(component, event, helper);
    },
    navigateToDetail : function(component, event, helper) {
        window.location.href = '/lightning/r/Contact/'+event.target.id+'/view';
    },
    onSectionSelect : function(component, event, helper) {
        var sectionId = event.currentTarget.id;
        sectionId = sectionId.split('#header')[0];
        var section = document.getElementById(sectionId);
        section.classList.toggle("slds-show");
        section.classList.toggle("slds-hide");
        var addIcon = document.getElementById(sectionId+'#add');
        addIcon.classList.toggle("slds-show");
        addIcon.classList.toggle("slds-hide");
        var removeIcon = document.getElementById(sectionId+'#remove');
        removeIcon.classList.toggle("slds-show");
        removeIcon.classList.toggle("slds-hide");
    },
    saveMeddic : function(component, event, helper) {
        component.set("v.spinnerBool",true);
        var action = component.get("c.saveMeddicc");
        action.setParams({"sectionList":JSON.stringify(component.get("v.sectionList")),"opp":component.get("v.opp"),"needLoadingOfData":component.get("v.needLoadingOfData")});
        action.setCallback(this,function(response) {
            component.set("v.spinnerBool",false);
            var state = response.getState();
            if(state === "SUCCESS"){
                if(component.get("v.needLoadingOfData")){
                    var res=response.getReturnValue();
                    component.set("v.sectionList",res.sectionList);
                }
                component.set("v.needLoadingOfData",false);
                helper.showMessageHelper('success','Success!','MEDDICC updated successfully.');
                $A.get('e.force:refreshView').fire();
            }
            else if(state === "ERROR"){
                var errorMsg = response.getError()[0].message;
                if(errorMsg.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')){
                    errorMsg = errorMsg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1];
                    errorMsg = errorMsg.split(':')[0];
                }
                helper.showMessageHelper('error','Error!',errorMsg);
            }
            else{
            	helper.showMessageHelper('error','Error!','Unknown Error Occured.');  
            }
        });
        $A.enqueueAction(action);
    },
    onCompetitorChange : function(component, event, helper) {
        var allSections = component.get("v.sectionList");
        for(var i=0;i<allSections.length;i++){
            var qsList=allSections[i].questionList;
            for(var j=0;j<qsList.length;j++){
                if(qsList[j].question.AKAM_MEDDICC_Questionnaire_ID__c==component.get("v.competitorIdentified")){
                    var oppty = component.get("v.opp");
                    if((oppty.Competitor__c == 'null' || oppty.Competitor__c == undefined) && (oppty.Competitor_Secondary__c == 'null' || oppty.Competitor_Secondary__c == undefined) && (oppty.Other_Competitor_Name__c == '' || oppty.Other_Competitor_Name__c == undefined)){
                        qsList[j].response=false;
                    }
                    else{
                        qsList[j].response=true;
                    }
                    break;
                }
            }
        }
        component.set("v.sectionList",allSections);
        helper.setOverallProgress(component, event, helper);
    },
    onResponseChange : function(component, event, helper) {
        var response = event.getSource().get("v.checked");
        var question = event.getSource().get("v.class"); 
        var contactRoles = component.get("v.opp").OpportunityContactRoles;
        var hasEB=false;
        var hasChamp=false;
        var i;
        if(question==component.get("v.ebIdentified") || question==component.get("v.championIdentified") || question==component.get("v.competitorIdentified")){
            if(contactRoles){
                for(i=0;i<contactRoles.length;i++){
                    if(contactRoles[i].Role==component.get("v.ebRole")){
                        hasEB=true;
                    }
                    else if(contactRoles[i].Role==component.get("v.championRole")){
                        hasChamp=true;
                    }
                    if(hasEB && hasChamp) break;
                }
            }
            if(response && question==component.get("v.ebIdentified") && !hasEB){
                helper.showMessageHelper('warning','Warning!','Please select an Economic Buyer role in the Contact Roles on this opportunity.');
                event.getSource().set("v.checked",false);
                return;
            }
            else if(response && question==component.get("v.championIdentified") && !hasChamp){
                helper.showMessageHelper('warning','Warning!','Please select a Champion role in the Contact Roles on this opportunity.');
                event.getSource().set("v.checked",false);
                return;
            }
            else if(question==component.get("v.competitorIdentified") && response){
                var oppty = component.get("v.opp");
                if((oppty.Competitor__c == 'null' || oppty.Competitor__c == undefined) && (oppty.Competitor_Secondary__c == 'null' || oppty.Competitor_Secondary__c == undefined) && (oppty.Other_Competitor_Name__c == '' || oppty.Other_Competitor_Name__c == undefined)){
                    helper.showMessageHelper('warning','Warning!','Please select a Competitor on this opportunity.');
                    event.getSource().set("v.checked",false);
                    return;
                }
            }
        }
        helper.setOverallProgress(component, event, helper);
    }
})