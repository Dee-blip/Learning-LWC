({
	doInit: function (cmp, evt, helper) {
		$A.get('e.force:closeQuickAction').fire();
		helper.handleServercall(cmp.get('c.redirectHandler'), { recId: cmp.get('v.recordId') }).then(
			(result) => { // Refactored for CPR Detail page : SFDC-7607
				$A.get('e.force:closeQuickAction').fire();
				let header = '<b>Account Name : </b>' + (result.hasOwnProperty('Account__r') ? result.Account__r.Name : result.Name) + ' <b>|</b> <b> AKAM Account Id : </b>' + (result.hasOwnProperty('Account__r') ? result.Account__r.AKAM_Account_ID__c : result.AKAM_Account_ID__c);
				window.location.href = '/lightning/cmp/c__L2Q_CapacityRequestComp?c__recordId=' + (result.hasOwnProperty('Account__r') ? result.Account__r.Id : cmp.get('v.recordId')) + '&c__objectApiname=Account' + '&c__header=' + header;
			},
			(error) => {
				console.log('load error-- ' + JSON.stringify(error));
				$A.get('e.force:closeQuickAction').fire();
				cmp.set('v.isLoading', false);
			}
		);
	}
});