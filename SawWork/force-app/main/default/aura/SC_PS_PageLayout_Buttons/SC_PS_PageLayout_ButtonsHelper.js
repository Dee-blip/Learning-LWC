({ //Function for returning the record type of the case
    isPsCase : function(component){
        var action = component.get("c.is_ps_case");
        action.setParams({
            "RecCaseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var isps;
            var state = response.getState();
            if (state === "SUCCESS") {
                isps = response.getReturnValue();
                isps=isps.toString();
                component.set("v.CaseRecordType", isps); 
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    CloneOtherRecType : function(component){
        //Calling CloneCase method in class
        var action = component.get("c.cloneCase");
        action.setParams({
            "CaseId": component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var x;
            var state = response.getState();
            if (state === "SUCCESS") {
                x= response.getReturnValue();
                //Setting new cloned case ID for edit page
                component.set("v.ClonedCaseId ",x);
                //Opening Cloned Case Modal
                component.set("v.isOpenCloneEdit", true);
                component.set("v.Spinner", false); 
            }
        });
        $A.enqueueAction(action);
        
    },
    //Generic Toast Message body
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    
    // Reopen Logic
    reOpenLogic : function(component, event, helper){
        var x,today,closeDate,days,action1;
        //For getting Case Details from Apex
        var action = component.get("c.getCaseReopenDetails");
        action.setParams({
            "parentCaseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            x=response.getReturnValue();
            if(x.IsClosed.toString()==='false') //Checking if case is closed or not
            {	
                helper.showToastMessage(component, event, helper,'Warning','Re-open is only available on closed cases.','warning','dismissible');
            }
            else
            {
                today = new Date(); //Logic for checking if the closed date < 30days
                closeDate = new Date(x.AKAM_Closed_Date__c);
                days = Math.floor((today - closeDate)/ 1000/60/60/24);
                if(days <= 30) {
                    
                    action1 = component.get("c.updateCaseStatusReopen"); //Update case to reopen status
                    action1.setParams({
                        "parentCaseId": component.get("v.recordId")
                    });
                    action1.setCallback(this, function() {
                        helper.showToastMessage(component, event, helper,'Success','Case has been re-opened','success','dismissible');
                        $A.get('e.force:refreshView').fire(); //Refreshing the parent view
                        
                    });
                    $A.enqueueAction(action1);
                    
                } // end of days condition
                else
                {
                    helper.showToastMessage(component, event, helper,'Warning','Cases can only be reopened within 30 days of case closure. Please create a new case.','warning','dismissible');       
                }
            }
        });
        $A.enqueueAction(action);
        return true;
        
    },
    soccreportinitial : function(component, event, helper) 
    {
        var recordId,action2,url,urlEvent;
		var action = component.get("c.getReportId");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS")
            {
               component.set("v.reportid",response.getReturnValue());
                recordId = component.get('v.recordId');
                action2 = component.get("c.getAkamAccountIdSOCC");
                action2.setParams({
                    "CaseId":recordId
                    
                });
                action2.setCallback(this, function(response) {
                    if (response.getState() === "SUCCESS")
                    {
                        component.set("v.AkamAccountId",response.getReturnValue());
                        //Construct report Url
                        url = '/lightning/r/Report/';
                        url = url+component.get("v.reportid");
                        url = url+'/view?fv0=';
                        url = url+component.get("v.AkamAccountId");
                       
                        //Redirect to report
                        urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": url
                        });
                        urlEvent.fire();
                        
                    }
                    
                });
                $A.enqueueAction(action2);
               
            }
            
        });
        $A.enqueueAction(action);
        
	},

    openAction : function (cmp,event,helper,actionName){
        var action1,action2,action3;
        switch (actionName){
            case 'NavigateToTools' : return helper.navigateToTools(cmp,event,helper); //done
            case 'MarkCaseAsInvalid': return helper.openCloseInvalidModal(cmp);//done
            case 'SelectIndirectCustomer': return helper.selectIndirectCustomer(cmp) //done
            case 'AutoCloseCase': return helper.autoCloseCase(cmp,event,helper);//done
            case 'QualityCoaching': return helper.qualityCoaching(cmp);//done
            case 'ReOpenCase': return helper.reOpenLogic(cmp,event,helper)//done
            case 'EditCaseModal': return $A.enqueueAction(cmp.get('c.EditCaseModal'));
            case 'Clone': return $A.enqueueAction(cmp.get('c.clone'));
            case "LUNA": return helper.navigateToPortal(cmp);
            case "EscalateSOCCCase": return $A.enqueueAction(cmp.get('c.EscalateSOCCCase'));
            case "CloneBillingCase": return $A.enqueueAction(cmp.get('c.toggleBillingModal'));
            case "RCATransition": return $A.enqueueAction(cmp.get('c.openRCAPopup'));
            case "QualityCoachingRCA": return $A.enqueueAction(cmp.get('c.qualityCoachingRCA'));
            case 'AttachCase': {
                action1 = cmp.get('c.attachexistingcase');
                action1.setParams({value: "AttachCase"});
                return $A.enqueueAction(action1);
            }
            case 'ShowSOCCCases': {
                action2 = cmp.get('c.attachexistingcase');
                action2.setParams({value: "SOCC"});
                return $A.enqueueAction(action2);
            }
            case "AckCustomerResponse": {
                action3 = cmp.get('c.attachexistingcase');
                action3.setParams({value: "AckCustResp"});
                return $A.enqueueAction(action3);
            }
            default: helper.showToastMessage(cmp,null,helper,'Error','Invalid actionName provided: '+actionName,'error','dismissible');
        }
        return true;
    },

    qualityCoaching: function (component){
        var qualityCoachingEvent = $A.get("e.c:SC_QualityCoaching_Event");
        qualityCoachingEvent.setParams({
            "sourceId": component.get("v.recordId"),
            "sourceType": "Case",
            "parentType": "Case"
        });
        qualityCoachingEvent.fire();
        return true;
    },
    navigateToTools : function (component,event,helper){
        var state,toolUrl;
        var action = component.get("c.getToolUrl");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        //alert(component.get("v.recordId"));
        action.setCallback(this, function(response) {
            state = response.getState();
            if (state === "SUCCESS") {
                toolUrl = response.getReturnValue();
                window.open(toolUrl,'_blank');
            } else{
                helper.showToastMessage(component, event, helper,'Error',"Can't redirect to tools.akam.ai as Case is not assigned to a user",'Error','sticky');
            }
        });
        $A.enqueueAction(action);
        return true;
    },

    navigateToPortal : function (component){
        var state,akamAccountID,x;
        var action = component.get("c.getAkamAccountID");
        action.setParams({
            "RecordID": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            state = response.getState();
            if (state === "SUCCESS") {
                akamAccountID= response.getReturnValue();
                x=akamAccountID.AKAM_Account_ID__c;
                window.open('https://control.akamai.com/apps/home-page#/manage-account?accountId='+x, '_blank');

            }
        });
        $A.enqueueAction(action);
        return true;
    },
    openCloseInvalidModal : function (component){
        component.set("v.isOpenCloseInvalidEdit", true);
        return true;
    },
    selectIndirectCustomer : function (component){
        component.set("v.isOpenIndirect", true);
        return true;
    },
    autoCloseCase : function (component,event,helper){
        var state,returnval;
        var action = component.get("c.getcaseclosedetails");
        action.setParams({
            "RecCaseId": component.get("v.recordId"),
        });

        action.setCallback(this, function(response) {
            state = response.getState();
            if (state === "SUCCESS") {
                returnval= response.getReturnValue();
                if(returnval==='Auto Close Updated Successfully.')
                {
                    helper.showToastMessage(component, event, helper,'Done',returnval,'success','dismissible');
                    $A.get('e.force:refreshView').fire();
                }
                else
                    helper.showToastMessage(component, event, helper,'Error',returnval,'Error','sticky');

            }
        });
        $A.enqueueAction(action);
        return true;
    }
    
})