({ //Init Handler
    doInit : function(component, event, helper) {
        //calling helper to get Report Id
        //Checking if the case status is closed. If it is closed hiding the Auto-Close button
        var action = component.get("c.getCaseReopenDetails");
        action.setParams({
            "parentCaseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var stat=response.getReturnValue();
            component.set("v.casestatus", stat.Status);
            if(stat.Status === 'Closed' || stat.Status === 'Rejected' || stat.Status === 'Unassigned' ){
                component.set("v.rcaTransitioButton",false);
            } else {
                component.set("v.rcaTransitioButton",true);
            }
            
        });
        $A.enqueueAction(action);
        helper.isPsCase(component, event, helper);
    },
    //Method 1: set "isEditModalOpen" attribute to false for hide/close model box 
    closeModal: function(component) {
        component.set("v.isOpenIndirect", false);
        
    }
    ,
    //Method 2: For Indirect customer
    IndirectCaseModal: function(component, event, helper) {
        helper.selectIndirectCustomer(component);
    }
    ,
    //Method 3 : For Reopen button
    reopen : function(component, event, helper) {
        helper.reOpenLogic(component ,event, helper);
    },
    
    //Method 4 : For Clone button
    
    clone: function(component, event, helper){
        var rec=component.get("v.recordId");
        var action = component.get("c.is_ps_case");
        component.set("v.Spinner", true);
        action.setParams({
            "RecCaseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state,isprofser,ps_url;
            state = response.getState();
            if (state === "SUCCESS") {
                isprofser = response.getReturnValue();
                if(isprofser.toString()==='Professional Services')
                {
                 ps_url="/apex/SC_CaseOverridePage?clone=1&retURL=%2F"+rec+"&id="+rec;
                 component.set("v.Spinner", false);
                 $A.get("e.force:navigateToURL").setParams({
                     "url": ps_url
                 }).fire();
                }
                else
                {
                    helper.CloneOtherRecType(component, event, helper);
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    
    //Method 5 : For Clone-Cancel button
    
    CancelClone : function(component, event, helper) {
        //Calling delete method in apex controller
        var action = component.get("c.DeleteclonedCase");
        //Closing Clone edit modal
        component.set("v.isOpenCloneEdit", false);
        action.setParams({
            "DeleteCaseId": component.get("v.ClonedCaseId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var ret= response.getReturnValue();
                console.log(ret);
            }
        });
        $A.enqueueAction(action);
        helper.showToastMessage(component, event, helper,'Warning','Case has not been cloned','warning','dismissible');        
    },
    
    //Method 6 : For Clone-Save button
    
    SaveClone : function(component, event, helper) {
        //Navigating to the cloned case
        var clonedrec=component.get("v.ClonedCaseId");
        component.find("edit").get("e.recordSave").fire();
        //Closing clone edit modal
        component.set("v.isOpenCloneEdit", false);
        $A.get("e.force:navigateToURL").setParams({
            "url": "/"+clonedrec 
        }).fire();
        helper.showToastMessage(component, event, helper,'Success','Case has been cloned','success','dismissible');
        
    },    
    
    
    //Method 7  : For Edit Case Modal 
    EditCaseModal: function(component) {
        //Get RecordtypeId of the case
        var rec=component.get("v.recordId");
        var action = component.get("c.getRecordTypeIdOfCase");
        action.setParams({
            "caseId": rec
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var recordTypeId = response.getReturnValue();
                var workspaceAPI = component.find("EditCaseworkspace");        
                var getParentTabId;
                workspaceAPI.getEnclosingTabId().then(function(tabId) {
                    getParentTabId=tabId;
                });
                
                // Method for opening SubTab in Console
                workspaceAPI.openSubtab({
                    parentTabId: getParentTabId,
                    url: '/apex/sc_editcase?Id=' +component.get("v.recordId")+ "&RecordType=" + recordTypeId,
                    focus: true
                })
                
                // Method for opening URL in Outside Console
                .catch(function() {
                    
                    $A.get("e.force:navigateToURL").setParams({ 
                        "url": "/apex/sc_editcase?Id=" +rec+ "&RecordType=" + recordTypeId
                    }).fire();
                });
            }
        });
        
        $A.enqueueAction(action);
    },
    
    //Method 8  : Navigate to Luna portal
    NavigateToPortal:function(component, event, helper) {
        helper.navigateToPortal(component);
    },
    //Method 9  : Handling drop down menu selection
    handleSelect:function(component, event) {
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue==='Auto Close')
        {
            var autoclose = component.get('c.AutoCloseCase');
            $A.enqueueAction(autoclose);
        }
        
    },
    
    //Method 10  : Open Invalid Case Modal
    openCloseInvalidModal:function(component, event, helper) {
        helper.openCloseInvalidModal(component);
    },
    
    //Method 11  : Saving Case as invalid  
    saveInvalidCase:function(component, event, helper) {
        var comments,action;
        comments = component.find('enter-close').get('v.value');
        component.set("v.isOpenCloseInvalidEdit", false);

        //Changes by Sharath for Billing Migration
        component.set("v.Spinner", true); 
        
        action = component.get("c.closeInvalid");
        action.setParams({
            "RecCaseId": component.get("v.recordId"),
            "Comments":comments
        });
        
        action.setCallback(this, function(response) {
            var returnval;
            var state = response.getState();
            //Changes by Sharath for Billing Migration
            component.set("v.Spinner", false);

            if (state === "SUCCESS") 
            {
                returnval= response.getReturnValue();
                if(returnval==='true')
                {
                    helper.showToastMessage(component, event, helper,'Done','Case has been marked Invalid!','success','dismissible');
                    $A.get('e.force:refreshView').fire();
                }
                // Changes by Sharath for ESESP-3659
                else
                {   //Showing the error message
                    helper.showToastMessage(component, event, helper,'Error!',returnval,'error','sticky');
                }                                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    //Method 12  : Close Invalid Case Modal
    CloseModal:function(component) {
        //Clsoing SOCC Escalation Modal and setting path to set to 1
        component.set("v.isSoccTemplate", false);
        component.set("v.CurrentStep", '1');
        
        component.set("v.isOpenCloseInvalidEdit", false);
    },
    
    //Method 13  : Auto Close Functionality
    
    AutoCloseCase:function(component, event, helper) {
        helper.autoCloseCase(component,event,helper);
    },
    
    //Method 14  : Navigate to Luna portal(ESESP-2278)
    NavigateToTool:function(component, event, helper) {
        helper.navigateToTools(component,event,helper);
    },
    
    //======================================SOCC Lightning Migration =========================================================================================================
    handleChange:function(component, event) {
        var changeValue = event.getParam("value");
        component.set("v.ChoosenEscalateOption", changeValue);
    },
    EscalateSOCCCase:function(component) {
        component.set("v.isSoccTemplate", true);
    },
    
    handlenext:function(component)
    {	var caseID=component.get("v.recordId");
     component.set("v.CurrentStep", '2');
     component.set("v.EditEscalatedCase", 'true'); 
     component.set("v.CreatedCaserecordId",caseID);       
     
    },
    handleSubmit :function(component, event)
    {
        

        var UIfields = event.getParam('fields');
        var josnfields=JSON.stringify(UIfields);
        var selectedRadioOption = component.get("v.ChoosenEscalateOption");
        var actioncase = component.get("c.CreateRelatedCase");
        // stop the form from submitting
        event.preventDefault();
        component.set("v.EscalationSpinner","true");
        actioncase.setParams({
            "caseId": component.get("v.recordId"),
            "ChoiceType":selectedRadioOption,
            "fields":josnfields
        });
        
        actioncase.setCallback(this, function(response) {
            component.set("v.EscalationSpinner","false");
            var returnval= response.getReturnValue();
            component.set("v.CurrentStep", '3');
            $A.get('e.force:refreshView').fire();
            window.open('/'+returnval, '_blank');
           
        });
        $A.enqueueAction(actioncase);  
    },
    //======================================End of escalate JS logic=========================================================================================================
    
    attachexistingcase:function(component, event, helper) 
    {
        var recordId = component.get("v.recordId");
        if(event.getParam("value")==='AttachCase')
        {
            console.log('attachCase called');
            var action1 = component.get("c.getParentCaseId");
            action1.setParams({
                "caseId": component.get("v.recordId"),
            });
            
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") 
                {
                    component.set("v.ParentCaseId",response.getReturnValue());
                    var parentId = component.get("v.ParentCaseId");
                    if(parentId===null)
                    {
                        parentId ='';
                    }
                    var url = '/apex/SC_ExistingCaseSearchPage?caseId='+recordId+'&parentCaseId='+parentId;                    
                    var workspaceAPI = component.find("EditCaseworkspace");
                    workspaceAPI.isConsoleNavigation().then(function(response1) {
                        
                        if(response1)
                        {	  
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                "url":url
                            });
                            urlEvent.fire();
                        }
                        else
                        {
                            window.open(url);
                        }
                    })
                    .catch(function(error) {
                        console.error(error);
                    });
                    
                }
                
            });
            $A.enqueueAction(action1);
        }
        else if(event.getParam("value")==='SOCC')
        {
            
            helper.soccreportinitial(component, event, helper);
            
        }
            else if(event.getParam("value")==='AckCustResp')
            {
                var toastEvent;
                var action = component.get("c.sendEmailSOCC");
                console.log('recordId'+recordId);
                action.setParams({
                    "CaseId": component.get("v.recordId"),
                });
                
                action.setCallback(this, function(response) {
                    toastEvent = $A.get("e.force:showToast");
                    if (response.getState() === "SUCCESS")
                    {
                        if(response.getReturnValue()===true)
                        {
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": "Customer Response Has Been Sent"
                            });
                            toastEvent.fire();
                        }
                        else if(response.getReturnValue()===false)
                        {
                            toastEvent.setParams({
                                "title": "Error!",
                                "message": "No Customer Email Logged on this Case"
                            });
                            toastEvent.fire();
                        }
                    }
                    else if(response.getState() === "ERROR")
                    {
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": "Customer Response Could not be Sent"
                        });
                        toastEvent.fire();
                    }
                    
                });
                $A.enqueueAction(action);
                
            }
        
    },
    
    //Perform Quality Coaching on Case:
    qualityCoaching : function(component, event, helper){
        helper.qualityCoaching(component);
        //Close modal
        window.setTimeout( $A.getCallback(function() {
            $A.get("e.force:closeQuickAction").fire();
        }), 2000 );
    },
    qualityCoachingRCA: function(component){
        var qualityCoachingEvent = $A.get("e.c:SC_QualityCoaching_Event");
        qualityCoachingEvent.setParams({ 
            "sourceId": component.get("v.recordId"),
            "sourceType": "RCA",
            "parentType": "RCA"
        });
        qualityCoachingEvent.fire();
        
        //Close modal
        window.setTimeout( $A.getCallback(function() {
            $A.get("e.force:closeQuickAction").fire();
        }), 2000 );
    },
    
    //ESESP-3659: Changes for Billing Case migration change by Sharath
    toggleBillingModal : function(component){
        var modalToggle = component.get("v.isOpenBillingClone");
        component.set("v.isOpenBillingClone",!modalToggle);
    },
        
    cloneBillingRecords : function(component, event, helper){
        
        
        var recordId = component.get("v.recordId");
        var action = component.get("c.cloneBillingCases");
        var count = ''+component.find("billingClone").get("v.value");
        console.log('recordId'+recordId);
        component.set("v.isOpenBillingClone",false);

        console.log('count: '+count);
            if(!count || count <= 0 )
            {
                helper.showToastMessage(component, event, helper,'','Enter a valid number!!','error','dismissible');
                return;
            }
            else if(count > 50)
            {
                helper.showToastMessage(component, event, helper,'','Number should be less than 50!!','error','dismissible');
                return;
                
            }
            component.set("v.Spinner",true);
            action.setParams({
                "caseId": recordId,
                "noOfClones" : count
            });
            
            action.setCallback(this, function(response) {
                component.set("v.Spinner",false);
                if (response.getState() === "SUCCESS")
                {   
                    if(response.getReturnValue()=== 'true')
                    {
                        console.log('response.getReturnValue(): ' + response.getReturnValue());
                        helper.showToastMessage(component, event, helper,'','Successfully Cloned!','success','dismissible');
                        var workspaceAPI = component.find("EditCaseworkspace");
                        var consoleUrl = '/lightning/o/Case/list?filterName=RecentlyViewedCases';
                        //console.log('In aura: ' + consoleUrl );
                        workspaceAPI.openTab({
                            url: consoleUrl,
                            focus: true
                        });
                    }
                    else
                    {
                        helper.showToastMessage(component, event, helper,'',response.getReturnValue(),'error','dismissible');
                    }
                }
                else if(response.getState() === "ERROR")
                {
                        helper.showToastMessage(component, event, helper,'','Error','error','dismissible');                    
                }
                
            });
            $A.enqueueAction(action);
            
        },

    openRCAPopup: function(component){
        component.set('v.isModalOpen',true);
    },
    closeModel: function(component){
        component.set('v.isModalOpen',false);
    },
    showSpinner:function(component){
        component.set("v.rcaSpinner",true);
    },
    hideSpinner:function(component){
        component.set("v.rcaSpinner",false);
    },
    refreshView:function(){
        $A.get('e.force:refreshView').fire();
    },
    onRemoteButtonOpenReceived: function (cmp,event,helper){
        var actionToOpen = event && event.getParam("actionName");
        if (actionToOpen){
            console.log('Opening action '+actionToOpen);
            helper.openAction(cmp,event,helper,actionToOpen);
        }else{
            helper.showToastMessage(cmp,event,helper,'Error','Invalid actionName provided: '+actionToOpen,'error','dismissible');
        }
    }
     
    
})