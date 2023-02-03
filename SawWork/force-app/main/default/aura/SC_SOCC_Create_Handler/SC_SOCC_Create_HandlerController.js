({
    doinit:function(component, event, helper)
    { 
        /** Code block if Policy Domain is Populated From Parent **/
        var pageReference = component.get("v.pageReference");
        if(pageReference!=undefined)
        {
            let policyDomainId = pageReference.state.c__policyDomainId;
            if(policyDomainId!=undefined)
            {   
                //call helper to set Policy Domain
                helper.prePopulatePolicyDomain(component, event, helper,policyDomainId);
            }
        }
        
        var HandlerType = [
            { value: "", label: ""},
            { value: "Platform Alert Handler Type", label: "Platform Alert Handler Type"},
            { value: "Phone Call Handler Type", label: "Phone Call Handler Type" },
            { value: "Failed Authentication Handler Type", label: "Failed Authentication Handler Type" },
            { value: "Service Request through ACC Portal Handler Type", label: "Service Request through ACC Portal Handler Type" },
            { value: "Service Request Emailed to SOCC Handler Type", label: "Service Request Emailed to SOCC Handler Type" },
            { value: "Security Alert Handler Type", label: "Security Alert Handler Type" },
            { value: "Attack Handler Type", label: "Attack Handler Type"}
        ];
        component.set("v.HandlerType", HandlerType);
        /*** End of Handler Type Options ***/
        
        //Getting a list of all the fields to show. This is used when the handler type is changed
        var actionht = component.get('c.getFieldstoShow');
        actionht.setCallback(this,function(response){
            if(response.getState()==="SUCCESS")
            {
                let responseValue = response.getReturnValue();
                component.set('v.HandlerTypeFieldstoShow',responseValue);
            }
        });
        $A.enqueueAction(actionht);  
        
        //To check if the component is being called as a "Create Handler" page. If handlerId is null then new handler else it is called from edit
        let handlerId = component.get('v.recordId');
        if(typeof(handlerId) != "undefined" || handlerId!=null)
        {
            let action = component.get('c.getHandlerCompleteDetails');
            action.setParams({
                "handlerId":handlerId
            });
            action.setCallback(this,function(response){
                if(response.getState()==='SUCCESS')
                {   
                    
                    let responseValue = response.getReturnValue();
                    component.set('v.selectedPolicyDomainRecord',responseValue.policyDomain);
                    component.set('v.selectedPolicyDomainRecordId',responseValue.policyDomain.Id);
                    component.set('v.selectedHandlerTypeValue',responseValue.handlerType.Name);
                    component.set('v.handlerName',responseValue.handler.Name);
                    component.set('v.selectedEscalationListRecord',responseValue.escalationList);
                    component.set('v.situationInstruction',responseValue.handler.Situation_Instruction__c);
                    component.set('v.IgnoreCondition',responseValue.handler.Ignore_Condition__c);
                    let fieldstoshow = responseValue.handlerType.Fields_To_Show__c;
                    let fieldstoshowarray = fieldstoshow.split(",");
                    helper.showHideInstructions(component,fieldstoshowarray);
                    
                }
            });
            $A.enqueueAction(action);
        }
        helper.setTabName(component, event, helper,'New Handler');
    },
    
    emptyEscalationList : function(component, event, helper) 
    {
        //Show/Hide Escalation List 
        component.set('v.selectedPolicyDomainRecordId','');
        
        let childCompRef = component.find('escChild');
        component.set('v.selectedEscalationListRecord',{});
        var pillTarget = childCompRef.find("lookup-pill");
        var lookUpTarget = childCompRef.find("lookupField"); 
        
        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
    },
    
    saveHandler:function(component, event, helper) 
    {
        component.set('v.showspinner',true);
        let HandlerName = component.get('v.handlerName');
        let HandlerType = component.get('v.selectedHandlerTypeValue');
        let pdId  = component.get('v.selectedPolicyDomainRecord').Id;
        let escalationId = component.get('v.selectedEscalationListRecord').Id;
        let handlerId = component.get('v.recordId');
        let suggestedSituationInstruction = component.get('v.suggestedSituationInstruction');
        let suggestedIgnoreCondition = component.get('v.suggestedIgnoreCondition');
        
        if(HandlerName==null||HandlerType==null||pdId==null||HandlerType=='')
        {
            
            let title='Error';
            let message='Handler Name, Handler Type, and Policy Domain are required to create a Handler';
            let type = 'error';
            helper.componentToastHandler(component, title, message, type);
            component.set('v.showspinner',false);
        }
        else
        {
            let action = component.get('c.saveHandlerCreateInstruction');
            action.setParams({
                "Name":HandlerName,
                "HandlerId":handlerId,
                "HandlerType":HandlerType,
                "pdId":pdId,
                "ElId":escalationId,
                "SitInst":suggestedSituationInstruction, //changes for Approval
                "IgnrCon":suggestedIgnoreCondition //changes for Approval
            });
            action.setCallback(this,function(response){
                if(response.getState()==='SUCCESS')
                {   
                    component.set('v.handlerRec',response.getReturnValue());
                    let handlerRecId = response.getReturnValue().Handler.Id;
                    
                    /** Set View Mode **/
                    component.set('v.isView',true);
                    component.set('v.isNew',false);
                    component.set('v.isEdit',false);
                    
                    let title ='Success!';
                    let message = 'Handler changes saved!';
                    let type = 'success';
                    helper.componentToastHandler(component,title,message,type);
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.isConsoleNavigation().then(function(response) {
                        if(response){
                            //Workspace close & Redirect tab
                            workspaceAPI.getFocusedTabInfo().then(function(response) {
                                var focusedTabId = response.tabId;
                                
                                workspaceAPI.openTab({
                                    recordId: handlerRecId,
                                    focus: true
                                }).then(function(response){
                                    workspaceAPI.getTabInfo({
                                        tabId: response
                                    }).then(function(tabInfo){
                                        let resptabId = tabInfo.tabId;
                                        workspaceAPI.closeTab({tabId: focusedTabId});
                                        workspaceAPI.refreshTab({
                                            tabId:resptabId
                                        }).then(function(response){
                                            workspaceAPI.closeTab({tabId: focusedTabId});
                                            
                                        });
                                        
                                    });
                                    
                                });
                            })
                            
                            .catch(function(error) {
                                console.log(error);
                            });
                        }
                        else
                        {
                            /*var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": handlerRecId
                            });
                            navEvt.fire();*/
                           window.parent.location = '/' + handlerRecId;
                        }
                    })
                    .catch(function(error) {
                    });
                    
                    
                    component.set('v.showspinner',false);
                    
                }
                else if(response.getState()==='ERROR')
                {
                    let errors = response.getError();
                    console.log(errors);
                    console.log(errors[0]);
                    console.log(errors[0].message);
                    //console.log(errors[0].pageErrors[0].message);
                    if(errors)
                    {
                        
                        if(errors[0] && errors[0].message)
                        {
                            let title ='Error!';
                            let message = errors[0].message;
                            let type = 'error';
                            //helper.closeFocusedTab(component, event,helper,handlerRecId);
                            helper.componentToastHandler(component,title,message,type);
                            component.set('v.showspinner',false);
                        }
                        else if(errors[0]&&errors[0].pageErrors[0].message!=undefined)
                        {
                            let title ='Error!';
                            let message = errors[0].pageErrors[0].message;
                            let type = 'error';
                            //helper.closeFocusedTab(component, event,helper,handlerRecId);
                            helper.componentToastHandler(component,title,message,type);
                            component.set('v.showspinner',false);
                        }
                    }
                }
                
            });
            $A.enqueueAction(action);
        }
    },
    
    getEscalationDetails:function(component, event, helper) 
    {
        let escalationListId = component.get('v.selectedEscalationListRecord').Id;
        let action = component.get('c.getEscalationListContactDetails');
        action.setParams({
            "EscalationListId":escalationListId
        });
        
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS')
            {
                if(Object.keys(response.getReturnValue()).length>0)
                {
                    component.set('v.escalationrecordCount',true);
                    component.set("v.showEscalationContacts",true);
                    
                    var pdId=response.getReturnValue().Policy_Domain__c;
                    var isEditPage=false;
                    //setTimeout(function(){ 
                    var escalationContactEditSection = component.find("escalationContactEditSections");
                    escalationContactEditSection.getEscConData(pdId, escalationListId, isEditPage,false);
                    // }, 500);
                    
                }
            }
            else
            {
                component.set('v.escalationrecordCount',false);
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    cancel:function(component, event, helper)
    {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    var PDTabId=focusedTabId.split("_");
                    workspaceAPI.focusTab({tabId : PDTabId[0]});
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
            else
            {
                var pageReference = component.get("v.pageReference");
                //Called from create page
                if(pageReference!=undefined && pageReference.state.c__policyDomainId!=undefined)
                {
                    let policyDomainId = pageReference.state.c__policyDomainId;
                    window.parent.location = '/' + policyDomainId;

                }
                else //Called from edit page 
                {
                   window.parent.location = '/' + pageReference.attributes.recordId;

                }
            }
        })
        .catch(function(error) {
        });
        
    },
    
    handleChangeHandlerType:function(component,event,helper)
    { 
        let HandlerType = component.get('v.selectedHandlerTypeValue');
        //Hide or show the lookup fields based on the handler type values
        let fieldstoshow = component.get('v.HandlerTypeFieldstoShow');
        for (var i = 0; i < fieldstoshow.length; i++){
            if (fieldstoshow[i].Name == HandlerType){
                var fieldstoshowarray=fieldstoshow[i].Fields_To_Show__c;
            }
        }
        console.log('fieldstoshowarray'+fieldstoshowarray);
        if(typeof(fieldstoshowarray) != "undefined")
        { 
            fieldstoshowarray = fieldstoshowarray.split(",");
            helper.showHideInstructions(component,fieldstoshowarray);
        }
        //Setting to show all fields again
        else
        {
            let childCompRef = component.find('escChild');        
            $A.util.removeClass(childCompRef, 'slds-hide');          
            $A.util.addClass(childCompRef, 'slds-show');
            component.set('v.showSituationInstruction',true);
            component.set('v.showIgnoreCondition',true);
            component.set("v.showEscalationContacts",true);
        }
    }  
})