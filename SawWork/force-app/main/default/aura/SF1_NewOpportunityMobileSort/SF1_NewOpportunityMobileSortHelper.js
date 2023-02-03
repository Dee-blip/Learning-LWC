({
	closeSortModal: function(component, event) {
		var cmpTarget = component.find('SortModalbox');
		var cmpBack = component.find('SortModalClose');
		$A.util.removeClass(cmpBack, 'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
	},
})