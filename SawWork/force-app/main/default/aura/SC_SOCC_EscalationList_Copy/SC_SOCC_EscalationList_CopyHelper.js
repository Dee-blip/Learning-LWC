({
    showMultiToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode,duration_in_ms,recUrl,recName) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Escalation List :{0}',
            messageTemplateData: [{
                url: recUrl,
                label: recName,
            }],
            duration:duration_in_ms,
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    //Generic toast message method
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode,duration_in_ms) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Saved!',
            duration:duration_in_ms,
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },

    //Set invalid Escalation Contact List for the current row of copied PD
    setLInvalidEscalationCon : function(component, event, helper, index){
        helper.showSpinner(component, event, helper);
        let lCopiedEscalationList = component.get("v.lCopiedEscalationList");
		let templCopiedEscalationList = component.get("v.lCopiedEscalationList");
        //get the selected row
        let currEscalationList = lCopiedEscalationList[index];
        console.log(currEscalationList);

        //Server call to get the list of invalid Escalation Contacts which will be not copied 
        let action = component.get("c.getInvalidEscalationContacts");
        action.setParams({
            "pdId": currEscalationList.Policy_Domain__c,
            "escalationListId": currEscalationList.Id
        });

        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let notifyAndEscalationContactsWrapper = response.getReturnValue();
                let lInvalidEscalationCon = notifyAndEscalationContactsWrapper.lEscalationContact;
                let lInvalidEscalationViaCaseEmail = notifyAndEscalationContactsWrapper.lEscalationViaCaseEmail;
                let lIsNotCopiable = notifyAndEscalationContactsWrapper.notCopiable;
                
                component.set("v.lInvalidEscalationCon", lInvalidEscalationCon);
                component.set("v.lInvalidEscalationViaCaseEmail", lInvalidEscalationViaCaseEmail);
                templCopiedEscalationList[index].isNotCopiable = lIsNotCopiable;
                component.set("v.lCopiedEscalationList",templCopiedEscalationList);
                
                helper.setSelectedRowColor(component, event, helper, index);
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
        });
        $A.enqueueAction(action);
    },

    //Changing the view icon color of selected row
    setSelectedRowColor : function(component, event, helper, index){
        component.set("v.currentRow", index);
        //change view icon color
        let allViewIcons = component.find("viewicon");
        if(component.get("v.isRowAdded")){
            for(let eachViewIcon of allViewIcons){
                $A.util.removeClass(eachViewIcon, 'selectedPreviewIcon');
                $A.util.addClass(eachViewIcon, 'previewIcon');
            }
            $A.util.removeClass(allViewIcons[index], 'previewIcon');
            $A.util.addClass(allViewIcons[index], 'selectedPreviewIcon');
        }
        else
            $A.util.addClass(allViewIcons, 'selectedPreviewIcon');

        //change row background
        let allrows = component.find("eachrow");
        if(component.get("v.isRowAdded")){
            for(let eachRow of allrows){
                $A.util.removeClass(eachRow, 'selectedRow');
            }
            $A.util.addClass(allrows[index], 'selectedRow');
        }
        else
            $A.util.addClass(allrows, 'selectedRow');
    },

    // this function is automatically called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.mainSpinner", true); 
    },
     
    // this function is automatically called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.mainSpinner", false);
    }
})