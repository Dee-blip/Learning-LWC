({
    addSuggestion : function(component) 
    {
        component.set('v.displayButton',true);
        component.set('v.situationSuggestionCapture','');
        component.set('v.ignoreSuggestionCapture','');
    },
    closeConfirmation:function(component) {
        component.set("v.confirmMasterEdit", false);
    },
    openConfirmation:function(component) {
        component.set("v.confirmMasterEdit", true);
    },
    saveSuggestion : function(component, event, helper) 
    {
        component.set('v.isSpinner',true); 
        //make server call to add insturction edit
        let a_SituationInstructionText = (component.get('v.situationSuggestionCapture') !== undefined) ? component.get('v.situationSuggestionCapture') : '';
        let a_IgnoreInstructionText = (component.get('v.ignoreSuggestionCapture') !== undefined) ? component.get('v.ignoreSuggestionCapture') : '';
        
        if((a_SituationInstructionText.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length === 0){
        	a_SituationInstructionText = (a_SituationInstructionText.replace(/(<([^>]+)>)/ig, '')).trim();
        }
        if((a_IgnoreInstructionText.replace( /(<([^>]+)>)/ig, '')).replace(/\s/g, '').length === 0){
        	a_IgnoreInstructionText = (a_IgnoreInstructionText.replace(/(<([^>]+)>)/ig, '')).trim();
        }
        
        if(a_SituationInstructionText === '' && a_IgnoreInstructionText === ''){
            let title = $A.get('$Label.c.Jarvis_HandlerDetail_ToastTitleError'); // 'ERROR!'
            let message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageNoSuggestionError'); // 'Please add atleast one suggestion'
            let type = 'error';
            helper.componentToastHandler(component,title,message,type);
            component.set('v.isSpinner',false); 
        }
        else{
            //call to server
            let action = component.get("c.addInstructionforApproval");
            action.setParams({
                "pdId":component.get('v.pdId'),
                "handlerId":component.get('v.handlerRecId'),
                "situationInstructionText":a_SituationInstructionText,
                "ignoreInstructionText":a_IgnoreInstructionText
            });
            
            action.setCallback(this,function(response){
                if(response.getState()==="SUCCESS")
                {
                    let title = $A.get('$Label.c.Jarvis_HandlerDetail_ToastTitleSuccess'); // 'Success!'
                    let message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageSuggestionSuccess'); // 'Your Suggestion Has Been Captured'
                    if(component.get("v.isCommunity") === true){
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageCommunitySuggestionSuccess'); // 'Runbook change requests submitted through Aloha Community all would generate a SOCC case, requiring SOCC review/approval. Please refer to the Change Request History section for updates';
                    }
                    let type = 'success';
                    helper.componentToastHandler(component,title,message,type);
                    $A.enqueueAction(component.get('c.cancelSuggestion'));
                    $A.enqueueAction(component.get('c.closeConfirmation'));
                    //$A.get('e.force:refreshView').fire();
                    let parentRef = component.get("v.parent");
                    parentRef.parentMethod(true);
                }
                else if(response.getState()==="ERROR"){
                    let title = $A.get('$Label.c.Jarvis_HandlerDetail_ToastTitleError'); //'ERROR!'
                    let message = response.getError()[0].message;
                    if(message === 'There are pending instructions for this Handler.') {
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_NoPendingNotifications')
                    }
                    else {
                        console.error(message);
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_ServerSideError');
                    }
                    let type = 'error';
                    helper.componentToastHandler(component,title,message,type);
                    $A.enqueueAction(component.get('c.cancelSuggestion'));
                    $A.enqueueAction(component.get('c.closeConfirmation'));
                }
            });
            $A.enqueueAction(action);
        }
        
    },
    
    cancelSuggestion : function(component) 
    {
        component.set('v.isSpinner',false); 
        component.set('v.displayButton',false);
    },
    
    handleRadioOptions:function(component, event)
    {
        console.log(event.getSource().get("v.value"));
        component.set('v.instructtype',event.getSource().get("v.value"));
    },
    masterEdit:function(component, event, helper)
    {
        component.set('v.showMultiEdit',true);
        helper.showFields(component, event, helper);
        /*let params = event.getParam('arguments');
        if (params) {
            component.set('v.showIgnoreCondition',params.showIgnoreCondition);
            component.set('v.showEscalationList',params.showEscalationList);
        }*/
    },
    updateMasterEdit:function(component, event, helper)
    {
        let params = event.getParam('arguments');
        if (params) {
            let action = component.get("c.addMultipleInstructionforApproval");
            action.setParams({
                "handlerIdInstMap":JSON.stringify(params.instructionWrapperList),
                "policyDomainId" : component.get('v.pdId')
            });
            
            action.setCallback(this,function(response){
                if(response.getState()==="SUCCESS")
                {
                    let title = $A.get('$Label.c.Jarvis_HandlerDetail_ToastTitleSuccess'); // 'Success!'
                    let message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageMultipleSuggestionsSuccess'); // 'Your Suggestions Has Been Captured'
                    if(component.get("v.isCommunity") === true){
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageCommunityMultipleSuggestionsSuccess'); // 'Runbook change requests submitted through Aloha Community all would generate a SOCC case, requiring SOCC review/approval. Please refer to the Instructions section for updates'
                    }
                    let type = 'success';
                    helper.componentToastHandler(component,title,message,type);
                    //$A.get('e.force:refreshView').fire();
                    let parentRef = component.get("v.parent");
                    parentRef.parentMethod(true);
                }
                else if(response.getState()==="ERROR"){
                    let message = response.getError()[0].message;
                    if(message === "List index out of bounds: 0")
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_ToastMessageNoInstructionSuggestedError'); // 'Please suggest atleast one instruction'
                    else if(message.startsWith('There are pending instructions for')) {
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_InstructionsPendingMultipleHandlersError') + message.substring(message.indexOf('for') + 1);
                    }
                    else {
                        console.error(message);
                        message = $A.get('$Label.c.Jarvis_HandlerDetail_ServerSideError');
                    }
                    let title = $A.get('$Label.c.Jarvis_HandlerDetail_ToastTitleError'); // 'ERROR!'
                    let type = 'error';
                    helper.componentToastHandler(component,title,message,type);
                    //$A.get('e.force:refreshView').fire();
                    let parentRef = component.get("v.parent");
                    parentRef.parentMethod();
                }
            });
            $A.enqueueAction(action);
        }
    },

    closeMasterEdit:function(component, event, helper)
    {
        component.set('v.showMultiEdit',false);
        helper.showFields(component, event, helper);
        component.set('v.situationSuggestionCapture','');
        component.set('v.ignoreSuggestionCapture','');
        /*let params = event.getParam('arguments');
        if (params) {
            component.set('v.showIgnoreCondition',params.showIgnoreCondition);
            component.set('v.showEscalationList',params.showEscalationList);
            component.set('v.situationSuggestionCapture','');
            component.set('v.ignoreSuggestionCapture','');
        }*/
    },
    printPage: function (component){
        let urlText;
        if(window.location.href.includes('/customers/')){
        	urlText = window.location.href.split('/s/')[0];
        }
        else if(window.location.href.includes('/lightning/')){
            urlText = window.location.href.split('lightning/')[0];
        }
        component.set("v.activeSectionsOpenned",JSON.stringify(component.get('v.activeSections')))
        component.set("v.isModalOpen", true);
        let printPageURL = urlText+'/apex/SC_SOCC_PrintRunbook?recordId=' + component.get('v.pdId')+'&isPrint=true&active=['+JSON.stringify(component.get('v.shMapId'))+']';
        component.set("v.vfURL",printPageURL);
    },
    
    PDFPage: function (component){
        let urlText;
        if(window.location.href.includes('/customers/')){
            urlText = window.location.href.split('/s/')[0];
        }
        else if(window.location.href.includes('/lightning/')){
            urlText = window.location.href.split('lightning/')[0];
        }
        component.set("v.activeSectionsOpenned",JSON.stringify(component.get('v.activeSections')))
        component.set("v.isModalOpen", true);
        let printPageURL = urlText+'/apex/SC_SOCC_PrintRunbook?recordId=' + component.get('v.pdId')+'&isPrint=false&active=['+JSON.stringify(component.get('v.shMapId'))+']';
        component.set("v.vfURL",printPageURL);
    },
    
    closeModel: function(component) {
        // Set isModalOpen attribute to false
        component.set("v.isModalOpen", false);
    },
    showNotification: function(component) {
        //component.set("v.isNotification", true);
        // Set isModalOpen attribute to false 
        if(component.get("v.isNotification") === false){
            component.set("v.isNotification", true);
            let action = component.get("c.showNotificationCase");
            action.setParams({
                "handlerId":component.get('v.handlerRecId')
            });
            
            action.setCallback(this,function(response){
                if(response.getState()==="SUCCESS")
                {
                    component.set("v.notificationMessage", $A.get("$Label.c.Jarvis_HandlerDetail_NoPendingNotifications")); // "There are no pending notifications"
                }
                else if(response.getState()==="ERROR"){
                    let errorMsg = response.getError()[0].message;
                    if(errorMsg.startsWith('Your edits are in review. For more information please refer case #')) {
                        component.set("v.notificationMessage", $A.get('$Label.c.Jarvis_HandlerDetail_EditsInReviewNotification') + errorMsg.substring(errorMsg.indexOf('#') + 1));
                    }
                    else {
                        console.error(errorMsg);
                        component.set("v.notificationMessage", $A.get('$Label.c.Jarvis_HandlerDetail_ServerSideError'));
                    }
                }
            });
            $A.enqueueAction(action);
        }
        else if(component.get("v.isNotification") === true){
            component.set("v.isNotification", false);
        }
        
    },
    hideNotification: function(component) {
        component.set("v.isNotification", false);
    },
    /*showNotificationOnHover: function(component, event, helper) {
        component.set("v.isNotification", true);
        let action = component.get("c.showNotificationCase");
        action.setParams({
            "handlerId":component.get('v.handlerRecId')
        });
        
        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                component.set("v.notificationMessage", "There are no pending notifications");
            }
            else if(response.getState()==="ERROR"){
                component.set("v.notificationMessage", response.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },*/
    
    doInit:function(component, event, helper)
    {
        component.set("v.options", [{'label': $A.get('$Label.c.Jarvis_HandlerDetail_SituationInstruction'), 'value': 'Situation Instruction'},{'label': $A.get('$Label.c.Jarvis_HandlerDetail_IgnoreCondition'), 'value': 'Ignore Condition'}]);
        component.set("v.notificationMessage", $A.get("$Label.c.Jarvis_HandlerDetail_NoPendingNotifications"));

        window.addEventListener("message", function(vfevent) {
            if(vfevent.data === 'false'){
                component.set("v.isModalOpen", false);
            }
        }, false);
        
        let action = component.get("c.getCommunityContactURL");

        action.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                component.set("v.editInPortalLink", response.getReturnValue());
                let actionIsCommunity = component.get("c.getCommunityAccess");
                actionIsCommunity.setCallback(this, function(responseIsCommunity){
                    if(responseIsCommunity.getState()==="SUCCESS"){
                        if(responseIsCommunity.getReturnValue() === true){
                            component.set("v.isCommunity",true);
                        }
                    }
                });
                $A.enqueueAction(actionIsCommunity);
            }
        });
        $A.enqueueAction(action);
        
        helper.showFields(component, event, helper);
        
        /*let handlerType = component.get("v.HandlerDetails").Handler_Type__r.Name;
        let fieldsToShow = component.get("v.fieldsToShowList");
        var fieldstoshowarray = '';
        for (var i = 0; i < fieldsToShow.length; i++){
            if (fieldsToShow[i].Name == handlerType){
                fieldstoshowarray = fieldsToShow[i].Fields_To_Show__c;
                break;
            }
        }
        if(typeof(fieldstoshowarray) != "undefined" && fieldstoshowarray.length > 0)
        { 
            fieldstoshowarray = fieldstoshowarray.split(",");
            if(fieldstoshowarray.includes("Ignore_Condition__c"))
            {
                component.set('v.showIgnoreCondition',true);
            }
            if(fieldstoshowarray.includes("Escalation_List__c"))
            {
                component.set('v.showEscalationList',true);
                var currPdId = component.get('v.pdId');
                var escalationListId = component.get('v.escalationContactId');
                var escalationContactEditSection = component.find("escalationContactEditSection");
                escalationContactEditSection.getEscConData(currPdId, escalationListId, false,false);
            }
        }*/

        /*if(handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
            component.set('v.showIgnoreCondition',true);
            component.set('v.showEscalationList',false);
        }
        if(handlerType == 'Attack Handler Type' ||handlerType == 'Security Alert Handler Type' || handlerType == 'Platform Alert Handler Type'){
            component.set('v.showEscalationList',true);
            //component.set('v.isEscalationList',true);
            var currPdId = component.get('v.pdId');
            var escalationListId = component.get('v.escalationContactId');
            var escalationContactEditSection = component.find("escalationContactEditSection");
            escalationContactEditSection.getEscConData(currPdId, escalationListId, false);
        }  */              
    }   
})