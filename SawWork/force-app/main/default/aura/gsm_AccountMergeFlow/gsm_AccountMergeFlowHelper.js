({
	setAccountTableData : function(component) {
		var action = component.get("c.getAccountData");
        component.set("v.accountData", null);
        action.setParam('accountParam',component.get("v.searchKeyword"));
        action.setParams({
            "accountParam" : component.get("v.searchKeyword"),
            "accId": component.get("v.recordId"),
        });
        var accountsList = [];
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state: ' + state);
      		if (state == 'SUCCESS') {
            	var accounts = JSON.parse(response.getReturnValue());
                for (var index in accounts) {
                	if (index > Number(accounts.rowsToDisplay) - 1) {
            			break;
          			}
                    var accountObj = {
                    	Id: '/' + accounts[index].Id, 
                        Name: accounts[index].Name,
                        AKAM_Account_ID__c: accounts[index].AKAM_Account_ID__c,
                        Account_Status__c: accounts[index].Account_Status__c,
                        AKAM_Created_Date__c: accounts[index].AKAM_Created_Date__c,
                        OwnerName: accounts[index].Owner.Name,
                        BillingCountry: accounts[index].BillingCountry
                        
                    }
                    accountsList.push(accountObj);
                };
				console.log('Accs = ');
                console.log(accountsList);
                component.set("v.accountData", accountsList);
            }
        });
    	$A.enqueueAction(action);
        
    },
    
	sortData: function(component, fieldName, sortDirection) {
        var data = component.get("v.accountData");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.accountData", data);
    },

	sortBy: function(field, reverse, primer) {
        var key = primer ?
          function(x) {
            return primer(x[field])
          } :
          function(x) {
            return x[field]
          };
        reverse = !reverse ? 1 : -1;
        return function(a, b) {
          return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
  	},
    
    setAccountAndDataSection : function(component) {
        var accountTypeSection = component.find("accountTypeSelectionId") ;
        var dataTableSection = component.find("accountSelectionId") ;
        $A.util.removeClass(accountTypeSection, 'slds-show');
        $A.util.addClass(accountTypeSection, 'slds-hide');
        $A.util.removeClass(dataTableSection, 'slds-hide');
        $A.util.addClass(dataTableSection, 'slds-show');
    },
    
    showAccountTypeMessage : function(component) {
        var accountTypeMessageSection = component.find("accountTypeMessageId") ;
        var accountTypeSelected = component.get("v.typeSelected");
        if(accountTypeSelected == 'winning')
            component.set("v.accountTypeMessage","Please note that as you have triggered the Account Merge Request from a Winning Account, you can select one or more losing accounts and submit the request");
        else
            component.set("v.accountTypeMessage","Please note that as you have triggered the Account Merge Request from a Losing Account, you can select only ONE winning account and submit the request");
        $A.util.removeClass(accountTypeMessageSection, 'slds-hide');
        $A.util.addClass(accountTypeMessageSection, 'slds-show');
    },
    
    hideAccountTypeMessage : function(component) {
        var accountTypeMessageSection = component.find("accountTypeMessageId") ;
        component.set("v.accountTypeMessage",null);
        $A.util.removeClass(accountTypeMessageSection, 'slds-show');
        $A.util.addClass(accountTypeMessageSection, 'slds-hide');
    },
    
    createAccountMergeRequest : function(component,event) {
        var createMergeAction = component.get("c.createAccountMerge");
        var accountType = component.get("v.typeSelected"); 
        console.log('selectedAccountIds = '+component.get("v.selectedAccountIds"));
        console.log('typeSelected = '+component.get("v.typeSelected"));
        console.log('recordId = '+component.get("v.recordId"));
        createMergeAction.setParams({
            "accountType" : component.get("v.typeSelected"),
            "targetAccIds": component.get("v.selectedAccountIds"),
            "sourceAccId": component.get("v.recordId")
        });
        
        createMergeAction.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state in Create Merge: ' + state);
            if (state == 'SUCCESS') {
                var mergeErrorSection = component.find("mergeRequestErrorId");
                var mergeSuccessSection = component.find("mergeRequestSuccessId");
                var resp = response.getReturnValue();
                console.log('resp in Create Merge: ' + resp);
                this.hideAccountTypeMessage(component);
                if(resp.includes("success")) {
                    component.set("v.successMessage", 'Merge Request(s) created Successfully. ')
                	$A.util.removeClass(mergeErrorSection, 'slds-show');
        			$A.util.addClass(mergeErrorSection, 'slds-hide');
                    
                    if(accountType == "losing") {
                        $A.util.removeClass(mergeSuccessSection, 'slds-hide');
                        $A.util.addClass(mergeSuccessSection, 'slds-show');
                        window.parent.location = '/' + resp.substr(8);
                    } else {
                        this.setAccountReqTableColumns(component);  
                        this.setAccountReqTableData(component);
                        this.sectionAction(component,"accountMergeReqsId","show");
                        this.sectionAction(component,"winningAccountSearchId","hide");
                        this.sectionAction(component,"searchId","hide");
                        this.sectionAction(component,"submitBtnId","hide");
                        this.sectionAction(component,"cancelBtnId","hide");
                        this.sectionAction(component,"mergeRequestMultiSuccessId","show");
                    } 

                   // window.parent.location = '/' + component.get("v.recordId");
                } else {
                    component.set("v.errorMessage", resp)
                    $A.util.removeClass(mergeErrorSection, 'slds-hide');
        			$A.util.addClass(mergeErrorSection, 'slds-show');
                    $A.util.removeClass(mergeSuccessSection, 'slds-show');
        			$A.util.addClass(mergeSuccessSection, 'slds-hide');
                    console.log('Error == '+component.get("v.errorMessage"));
                }
            }
        });
    	$A.enqueueAction(createMergeAction);
    },
    
    sectionAction : function(component,sectionId,type) {
        var section = component.find(sectionId) ;
        if(type == "hide") {
            $A.util.removeClass(section, 'slds-show');
            $A.util.addClass(section, 'slds-hide');
        } else {
            $A.util.removeClass(section, 'slds-hide');
            $A.util.addClass(section, 'slds-show');    
        }    
    },

    setAccountReqTableData : function(component) {
        var action = component.get("c.getAccountRequestsData");
        component.set("v.accountReqData", null);
        component.set("v.accountData=", null);
        action.setParams({
            "accId": component.get("v.recordId")
        });
        var accountsList = [];
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state: ' + state);
            if (state == 'SUCCESS') {
                var accounts = JSON.parse(response.getReturnValue());
                for (var index in accounts) {
                    if (index > Number(accounts.rowsToDisplay) - 1) {
                        break;
                    }
                    var accountObj = {
                        Id: '/' + accounts[index].Id, 
                        Name: accounts[index].Name,
                        Winning_Account_Name__c: accounts[index].Winning_Account_Name__c,
                        Losing_Account_Name__c: accounts[index].Losing_Account_Name__c,
                        Merge_Status__c: accounts[index].Merge_Status__c,
                        CreatedDate: accounts[index].CreatedDate
                    }
                    accountsList.push(accountObj);
                };
                console.log('Accs = ');
                console.log(accountsList);
                component.set("v.accountReqData", accountsList);
            }
        });
        $A.enqueueAction(action);
        
    },
    
    setAccountTableColumns : function(component) {
    	component.set('v.accountColumns', [
        	{
                label: 'Account Name',
                fieldName: 'Id',
                type: 'url',
                sortable: 'true',
                typeAttributes: {
                  label: {
                    fieldName: 'Name'
                  }
                }
			},
            {
                label: 'Akam Id',
                fieldName: 'AKAM_Account_ID__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Account Status',
                fieldName: 'Account_Status__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Created Date',
                fieldName: 'AKAM_Created_Date__c',
                sortable: 'true',
                type: 'date',
            },
            {
                label: 'Owner',
                fieldName: 'OwnerName',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Primary Country',
                fieldName: 'BillingCountry',
                sortable: 'true',
                type: 'text',
            },
		]);
	},

    setAccountReqTableColumns : function(component) {
        component.set('v.accountReqColumns', [
            {
                label: 'Account Request Name',
                fieldName: 'Id',
                type: 'url',
                sortable: 'true',
                typeAttributes: {
                  label: {
                    fieldName: 'Name'
                  }
                }
            },
            {
                label: 'Winning Account Name',
                fieldName: 'Winning_Account_Name__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Losing Account Name',
                fieldName: 'Losing_Account_Name__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Merge Status',
                fieldName: 'Merge_Status__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Created Date',
                fieldName: 'CreatedDate',
                sortable: 'true',
                type: 'date',
            },
        ]);
    },
    
})