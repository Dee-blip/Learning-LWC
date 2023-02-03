({
    //Method 1 : Called on component load
    doInit : function(component, event, helper) 
    {
        component.set("v.spinner", false);
        var currPage = component.get("v.action");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.today', today);
        
        if(currPage == 'Case Page')
        {
            component.set("v.isCasePage", true);
            var parentCaseId = component.get("v.recordId");
            var getOARecordTypes = component.get("c.fetchOARecordTypes");
            
            getOARecordTypes.setCallback(this, function(response)
            {
                if(response.getState() == "SUCCESS")
                {
                    var List_of_rec_type_label= response.getReturnValue();
                    var generateJSON_For_RecordTypeSelection ='';
                    var eachRecordType;  
                    var closedStatusList = ['Closed-Approved','Closed-Auto Approved','Closed-Approval Not Needed','Data Migration - Auto Close','Closed-Insufficient Information','Closed-Quote Term Updated','Closed-Quote Approved'];

                    var caseAppDet = component.get("c.fetchCaseApprovalDetails");
                    caseAppDet.setParams({
                        "caseRecordId" : parentCaseId
                    })
                    
                    caseAppDet.setCallback(this, function(response)
                    {
                        if(response.getState() == "SUCCESS")
                        {
                            if(!closedStatusList.includes(response.getReturnValue()[0].Status) && response.getReturnValue()[0].Approval_Details__r == undefined)
                            {
                                component.set("v.ADCreateModal", true);
                                component.set("v.popupMsg","Thank you for creating a case.  Don’t forget you must also raise an Approval Request by clicking “Raise a New Request”.  Without an approval request your submission is incomplete.");
                            }
                        }
                    });
                    $A.enqueueAction(caseAppDet);
                    
                    var getPicklists = component.get("c.pickilstReopenReasonCode");
                    getPicklists.setCallback(this, function(a) {
                        debugger;
                        component.set("v.reopenReasonValues", a.getReturnValue());
                        
                    });
                    $A.enqueueAction(getPicklists);
                    
                    var caseDet = component.get("c.fetchCaseDetails");
                    caseDet.setParams({
                        "caseRecordId" : parentCaseId
                    })
                    
                    caseDet.setCallback(this, function(response)
                    {
                        if(response.getState() == "SUCCESS")
                        {
                            var caseClosed = response.getReturnValue();
                            component.set("v.isMPCCCase",false);
                            component.set("v.isAutoClose",caseClosed.AutoClose__c);
                            component.set("v.caseobj",response.getReturnValue());
                            component.set("v.recordType", caseClosed.RecordType.DeveloperName);
                            component.set("v.isClosedCase", false);
                            component.set("v.isCPQCase", caseClosed.IsCreatedbyCPQ__c);
                            if(caseClosed.IsClosed && (caseClosed.Status == "Closed" || caseClosed.Status == "Closed-Approved" 
                                || caseClosed.Status === "Closed-Auto Approved" || caseClosed.Status === "Closed-Auto Rejected" 
                                || caseClosed.Status === "Closed-Approval Not Needed"
                                || caseClosed.Status === "Closed-Insufficient Information" || caseClosed.Status === "Closed-Quote Term Updated"
                                || caseClosed.Status === "Closed-Quote Approved") || caseClosed.Status === "Data Migration - Auto Close")
                                component.set("v.isClosedCase", true);
                            if(!(caseClosed.Opportunity__r.StageName).includes('Closed'))
                                component.set("v.isClosedOpp", false);
                            if(caseClosed.AKAM_System__c === 'MPCC')
                            {
                                component.set("v.isMPCCCase",true);
                            }
                        }
                    });
                    $A.enqueueAction(caseDet);
                    
                    
                    for (eachRecordType=0;eachRecordType<=List_of_rec_type_label.length-1;eachRecordType++)
                    {
                        if(List_of_rec_type_label[eachRecordType] == "Order Approval-Escalations")
                        {
                            var getCaseDetails = component.get("c.fetchCaseDetails");
                            getCaseDetails.setParams({
                                "caseRecordId": parentCaseId
                            })
                            
                            getCaseDetails.setCallback(this, function(response)
                            {
                                if(response.getState() == "SUCCESS")
                                {
                                    var caseRTName = response.getReturnValue().RecordType.DeveloperName;
                                    if(caseRTName == 'Order_Approval_Deal_Desk' || caseRTName == 'Order_Approval_Legal')
                                        component.set("v.showEscalateCase", true);
                                }
                            });
                            $A.enqueueAction(getCaseDetails);
                            break;  
                        }
                    }
                }
            });
            
            $A.enqueueAction(getOARecordTypes);
        }
        else if(currPage == 'Order Approval Page')
            component.set("v.isOAPage", true);    
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-show");
    },

    closeOACase: function(component, event, helper) 
    {
        if(component.get("v.closeCaseModal"))
            component.set("v.closeCaseModal", false);
        if(!component.get("v.closeCaseModal"))
            component.set("v.closeCaseModal", true);
    },
    
    // function automatic called by aura:waiting event  
    showSpinner: function(component, event, helper) 
    {
        component.set("v.spinner", true); 
    },
     
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper)
    {
        component.set("v.spinner", false);
    },
   
    reopenOACase : function(component, event, helper)
    {
        if(component.get("v.reopenCaseModal"))
            component.set("v.reopenCaseModal",false);
        if(!component.get("v.reopenCaseModal"))
            component.set("v.reopenCaseModal",true);
        
    },
    
    //Method 2 : To show SC_NewApprovalDetails component
    openApprovalDetails : function(component, event, helper) 
    {
        if(component.get("v.isOpenNewRequest"))
            component.set("v.isOpenNewRequest", false);
        if(!component.get("v.isOpenNewRequest"))
            component.set("v.isOpenNewRequest", true);
    },
    
    //Method 3 : To show SC_NewOACase component on Case Page
    openEscalationCase: function(component, event, helper) 
    {
        if(component.get("v.isOpenNewEscalateCase"))
            component.set("v.isOpenNewEscalateCase", false);
        if(!component.get("v.isOpenNewEscalateCase"))
            component.set("v.isOpenNewEscalateCase", true);
    },
    
    openNewCase: function(component, event, helper) 
    {
        if(component.get("v.isOpenNewCase"))
            component.set("v.isOpenNewCase", false);
        if(!component.get("v.isOpenNewCase"))
            component.set("v.isOpenNewCase", true);
    },
    
    closeRModal: function(component, event, helper) 
    {
        component.set("v.reopenCaseModal", false);
    },
    
    closeCModal: function(component, event, helper) 
    {
        component.set("v.closeCaseModal", false);
        component.set("v.isCloseCaseWarningShown", false);
        component.set("v.warningAckCheckboxValue", false);
    },
    
    closeCADModal: function(component, event, helper) 
    {
        component.set("v.ADCreateModal", false);
        var cmpTarget = component.find('newRequestId');
        $A.util.addClass(cmpTarget, 'highlightButton');
    },
    
    handleWarningAckCheckboxChange: function(component) 
    {
        component.find("warningAckCheckbox").reportValidity();
    },
    
    closeCaseMethod : function(component, event, helper) 
    { 
        let warningAckCheckboxChecked = component.get("v.warningAckCheckboxValue");
        if (component.get("v.isCloseCaseWarningShown") && !warningAckCheckboxChecked) {
            component.find("warningAckCheckbox").reportValidity();
            return;
        }
        component.set("v.closeCaseModal", false);
        component.set("v.isCloseCaseWarningShown", false);
        component.set("v.Spinner", true);
        var caseId = component.get("v.recordId");
        var closeCaseRef = component.get("c.closeCase");
        var closeStatusValue = component.find("statusValue").get("v.value");
        closeCaseRef.setParams({
            "caseRecId" : caseId,
            "closeStatus" : closeStatusValue
        })
        
        closeCaseRef.setCallback(this, function(response)
        {
            if(response.getState() == "SUCCESS")
            {
                component.set("v.Spinner", false);
                component.set("v.isClosedCase",true);
                var caseClosed = response.getReturnValue();
                component.set("v.caseobj",response.getReturnValue());
                if(closeStatusValue == 'Closed-Insufficient Information'){
                    helper.showToastMessage(component, event, helper,'Success','Case closed successfully.','Success','dismissible'); 
                } else{
                    helper.showToastMessage(component, event, helper,'Success','Good Job! Case Closed! Here\'s a 🍪','Success','dismissible'); 
                }
                      
                component.set("v.closeCaseModal", false);
                $A.get('e.force:refreshView').fire();
                var parentCaseId = component.get("v.recordId");
            }
            
            else if(response.getState() == "ERROR")
            {
                //component.set("v.closeCaseModal", false);
                component.set("v.Spinner", false);
                var x = response.getError();
                console.log('Error : '+x[0].message);
                helper.showToastMessage(component, event, helper,'Error',x[0].message,'Error','dismissible');       
            }
        });
        if (component.get("v.recordType") === "Order_Approval_Order_Management" && !warningAckCheckboxChecked &&
           (closeStatusValue === "Closed-Approved" || closeStatusValue === "Closed-Quote Approved")) {
            let areAnyRelatedOACasesPending = component.get("c.areAnyRelatedOACasesPending");
            areAnyRelatedOACasesPending.setParams({
                "caseId": caseId
            });
            areAnyRelatedOACasesPending.setCallback(this, function (response) {
                if (response.getState() === "SUCCESS") {
                    if (response.getReturnValue()) {
                        component.set("v.isCloseCaseWarningShown", true);
                        component.set("v.closeCaseModal", true);
                        component.set("v.Spinner", false);
                    }
                    else {
                        $A.enqueueAction(closeCaseRef);
                    }
                }
                else if (response.getState() === "ERROR") {
                    component.set("v.Spinner", false);
                    let x = response.getError();
                    console.log('Error : ' + x[0].message);
                    helper.showToastMessage(component, event, helper, 'Error', x[0].message, 'Error', 'dismissible');
                }
            });
            $A.enqueueAction(areAnyRelatedOACasesPending);
        }
        else {
            component.set("v.warningAckCheckboxValue", false);
            $A.enqueueAction(closeCaseRef);
        }
    },
    
    reopenCaseMethod : function(component, event, helper) 
    {
        component.set("v.reopenCaseModal", false);
        component.set("v.Spinner", true);
        var caseObj = component.get("v.caseobj");
        var reason = component.get('v.reOpenReason');
        var reopenCaseRef = component.get("c.reopenCase");
        reopenCaseRef.setParams({
            "caseR" : caseObj,
            "reason" : reason
        })
        
        reopenCaseRef.setCallback(this, function(response)
        {
            if(response.getState() == "SUCCESS")
            {
                component.set("v.isClosedCase",false);
                component.set("v.Spinner", false);
                var caseReopened = response.getReturnValue();
                console.log(caseReopened);
                component.set("v.caseobj",response.getReturnValue());
                component.set("v.reopenCaseModal", false);
                component.set("v.isOpenCase",true);
                
                var parentCaseId = component.get("v.recordId");
                $A.get('e.force:refreshView').fire();
                component.set("v.ADCreateModal", true);
                component.set("v.popupMsg","Thank you for reopening the case. Don’t forget you must also raise an Approval Request by clicking “Raise a New Request”. Without an approval request your submission is incomplete.");
            }
            else if(response.getState() == "ERROR")
            {
                component.set("v.reopenCaseModal", true);
                component.set("v.Spinner", false);
                var x = response.getError();
                console.log('Error : '+x[0].message);
                helper.showToastMessage(component, event, helper,'Error',x[0].message,'Error','dismissible');       
            }
        });
        $A.enqueueAction(reopenCaseRef);
    },
})