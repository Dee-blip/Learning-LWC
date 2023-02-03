({
	toggleModal : function(cmp, event, helper) {
		$A.util.toggleClass(cmp.find("modal"),'slds-fade-in-open');
        $A.util.toggleClass(cmp.find("modal-backdrop"),'slds-backdrop--open');
	},
})