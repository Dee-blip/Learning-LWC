({
	doInit : function(component, event, helper) {
        var mergeRequestStatus = component.get("v.reqStatus");
        var losingAccId = component.get("v.losingRecordId").slice(0, -3);
        var winningAccId = component.get("v.winningRecordId").slice(0, -3);
        console.log('Losing Acc Id = '+losingAccId);
        console.log('Winning Acc Id = '+winningAccId);
        if(mergeRequestStatus != 'Contract Transfer Completed' 
           && mergeRequestStatus != 'Approved') {
            component.set("v.errorMessage","The accounts can be merged only if the status is " +
                          					"Approved or Contract Transfer Completed. Please modify"+
                          					" your selection and try again.");
            helper.sectionAction(component,"errorMessageId","show");
            helper.sectionAction(component,"backButtonId","show");
        } else {
            var fetchAccountStatus = component.get("c.checkAccountStatus");
            fetchAccountStatus.setParams({
            	"losingAccountId": losingAccId
        	});
            fetchAccountStatus.setCallback(this, function(response) {
                console.log('State = '+response.getState());
                if (response.getState() == 'SUCCESS') {
                    if(response.getReturnValue() == 'active') {
                    	component.set("v.errorMessage","Please ensure that all the active contracts"+ 
                                      				   " from the losing account have been transferred"+
                                      				   " to the winning account and Merge Status should"+
                                      				   " be set to Contract Transfer Completed.");    
                    	helper.sectionAction(component,"errorMessageId","show");
                        helper.sectionAction(component,"backButtonId","show");
                    } else {
                        helper.sectionAction(component,"backButtonId","hide");
                        component.set("v.successMessage","You are getting redirected to " + 
                                      					 "Accounts Merge Page");
                        helper.sectionAction(component,"mergeRequestSuccessId","show");
                        window.parent.location = '/merge/accmergewizard.jsp?goNext=+Next+&cid='+
                            					winningAccId+'&cid='+losingAccId+'&p2='+winningAccId;    
                    }
                }
            });
    		$A.enqueueAction(fetchAccountStatus);
        }
	},
    
    redirectToAccountReq : function(component, event, helper) {
        component.set("v.successMessage","You are getting redirected to " + 
                                      	 "Account Merge Request record");
        helper.sectionAction(component,"errorMessageId","hide");
        helper.sectionAction(component,"mergeRequestSuccessId","show");
        helper.sectionAction(component,"backButtonId","hide");
    	window.parent.location = '/' + component.get("v.recordId");    
    }
})