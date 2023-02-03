({
	doInit : function(component,event,helper) {
		var fetchAccountDetails = component.get("c.getAccountDetail");
        fetchAccountDetails.setParams({
        	"accountId": component.get("v.recordId")
        });
        fetchAccountDetails.setCallback(this, function(response) {
        	if (response.getState() == 'SUCCESS') {
            	if(response.getReturnValue() != null) { 
                	component.set("v.accName",response.getReturnValue().Name);
                }
              	var userTheme = component.get("c.getUserTheme");
                userTheme.setCallback(this, function(response) {
                	if (response.getState() == 'SUCCESS') {
                    	if(response.getReturnValue() != null) { 
                        	component.set("v.userThemeValue",response.getReturnValue());	
                        }
                    }
                });
                $A.enqueueAction(userTheme);
            }
        });
    	$A.enqueueAction(fetchAccountDetails);
	},
  
  	redirectToAccount : function(component,event,helper) {
		//sforce.one.navigateToSObject("001W000000ceCS0IAM", "detail");
        window.parent.location = '/' + component.get("v.recordId");
	},
    
    showSpinner: function(cmp, event, helper) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        
    },
    
    hideSpinner : function(cmp,event,helper){
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-show");
    },
    
    afterTypeSelection : function(component,event,helper) {
        var changeValue = component.get("v.typeSelected");
        var isDirectAcc = component.get("v.directAcc");
        var isIndirectAcc = component.get("v.indirectAcc");
        console.log("isDirectAcc = "+isDirectAcc);
        console.log("isIndirectAcc = "+isIndirectAcc);
        if(changeValue != null) {
        	if(changeValue == 'winning') {
                helper.setAccountAndDataSection(component);
                helper.sectionAction(component,"losingAccountSearchId","hide");
                helper.sectionAction(component,"winningAccountSearchId","show");
            } else if(changeValue == 'losing'){
                var fetchAccountStatus = component.get("c.checkAccountStatus");
                fetchAccountStatus.setParams({
            		"losingAccountId": component.get("v.recordId")
        		});
                fetchAccountStatus.setCallback(this, function(response) {
                    if (response.getState() == 'SUCCESS') {
                    	if(response.getReturnValue() == 'active') {
                        	component.set("v.losingAccountConfirmMessage",
                                          "This account "+
                                          "has active contract(s), are you sure you want to proceed?");
                            helper.sectionAction(component,"losingAccountConfirmId","show");
                        }
                        else if(response.getReturnValue() == 'Inactive'){
                        	helper.setAccountAndDataSection(component);
                    		helper.sectionAction(component,"winningAccountSearchId","hide");
                    		helper.sectionAction(component,"losingAccountSearchId","show");   
                        } else {
                        	component.set("v.typeSelectionErrorMessage",response.getReturnValue()); 
                            helper.sectionAction(component,"typeSelectionErrorId","show");
                        }
                    }
                });
    			$A.enqueueAction(fetchAccountStatus);
            } 
        }
    },
    
    searchAccount : function(component,event,helper) {
        var mergeErrorSection = component.find("mergeRequestErrorId");
        $A.util.removeClass(mergeErrorSection, 'slds-show');
        $A.util.addClass(mergeErrorSection, 'slds-hide');
        helper.setAccountTableColumns(component);  
    	helper.setAccountTableData(component);  
        helper.showAccountTypeMessage(component);
    },
    
    updateColumnSorting: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    getSelectedName: function(component, event) {
        var selectedRows = event.getParam('selectedRows');
    	var selectedIds = [];
        for (var i = 0; i < selectedRows.length; i++) {
          selectedIds.push((selectedRows[i].Id).substr(1));
          console.log((selectedRows[i].Id).substr(1));
        }
        component.set("v.selectedAccountIds", selectedIds);
    },
    
    checkActiveAccounts: function(component, event,helper) {
        var checkLosingActiveAccountsAction = component.get("c.checkLosingAccountsStatus");
        var accountIds = [];
        if((component.get("v.typeSelected") == 'losing' && 
            component.get("v.losingActiveMessage") != 'confirmed') ||
           component.get("v.typeSelected") != 'losing') {
            if(component.get("v.typeSelected") == 'losing')
                accountIds.push(component.get("v.recordId"));
            else {
                accountIds = component.get("v.selectedAccountIds").slice();
                console.log('accountIds = '+accountIds);
            }
            checkLosingActiveAccountsAction.setParams({
                "losingAccountIds" : accountIds
            });
            checkLosingActiveAccountsAction.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state in Create Merge: ' + state);
                if (state == 'SUCCESS') {
                    if(response.getReturnValue() == 'inactive') {
                        helper.createAccountMergeRequest(component,event);
                    } else {
                        component.set("v.losingAccountConfirmMessage",response.getReturnValue());  
                        helper.sectionAction(component,"losingActiveAccountsConfirmId","show");
                    }
                }
            });
            $A.enqueueAction(checkLosingActiveAccountsAction);
        } else {
        	helper.createAccountMergeRequest(component,event);    
        }
    },
    
    hideLosingAccountModal: function(component, event,helper) {
        helper.sectionAction(component,"losingAccountConfirmId","hide");
    },
    
    hideLosingActiveAccountsModal: function(component, event,helper) {
        helper.sectionAction(component,"losingActiveAccountsConfirmId","hide");
    },
    
    proceedLosingAccountActive: function(component, event,helper) {
      	component.set("v.losingActiveMessage","confirmed");
        helper.sectionAction(component,"losingAccountConfirmId","hide");
        helper.setAccountAndDataSection(component);
        helper.sectionAction(component,"winningAccountSearchId","hide");
        helper.sectionAction(component,"losingAccountSearchId","show");
    },
    
    proceedLosingActiveAccounts: function(component, event,helper) {
    	helper.sectionAction(component,"losingActiveAccountsConfirmId","hide");  
        helper.createAccountMergeRequest(component,event);
    },
    
    
})