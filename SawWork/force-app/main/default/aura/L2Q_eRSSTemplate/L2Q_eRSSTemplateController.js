({
	doInit: function(cmp, evt, helper) {
		var filterName = $A.get('$Label.c.L2Q_eRssfilterType').split('#');
		cmp.set('v.searchResult', parseInt(cmp.get('v.pageSize')));
		helper.setIntialvalue(cmp, evt, helper);
		helper.getTemplate(cmp, helper, filterName[0]);
	},
	scriptsLoaded: function(cmp, evt, helper) {
		console.log('Script load successfull.');
	},
	createNewtemp: function(cmp, evt, helper) {
		evt.getSource().set('v.disabled', true);
		cmp.set('v.isLoading', true);
		if (helper.checkfieldValidity(cmp, evt, helper, 'createTemplateId')) {
			let params = {
				templateName: cmp.find('createTemplateId').get('v.value'),
				uniqueId: helper.uniqueNumbergenerator(cmp, evt, helper)
			};
			console.log('createNewtemp>>'+JSON.stringify(params));
			helper.asyncPromisereturn(cmp.get('c.createTemplate'), params).then(
				function(result) {
					if (result.length == 18 || result.length == 15) {
						cmp.set('v.isLoading', false);
						helper.showToast(cmp, evt, helper, 'Success!', 'success', 'Template created successfully.');
						helper.navigate(cmp, evt, helper, result);
					}
					cmp.set('v.isLoading', false);
				},
				function(error) {
					console.log('createNewtemp>>error>>'+error);
					helper.showToast(cmp, evt, helper, 'Error', 'error', error);
					cmp.set('v.isLoading', false);
					evt.getSource().set('v.disabled', false);
				}
			);
		} else {
			cmp.set('v.isLoading', false);
			cmp.find('createTemplateId').showHelpMessageIfInvalid();
			evt.getSource().set('v.disabled', false);
		}
	},
	createTemp: function(cmp, evt, helper) {
		cmp.set('v.istempMode', true);
	},
	//handling view changes
	handletempChange: function(cmp, evt, helper) {
		helper.resetpageUtil(cmp, evt, helper);
		cmp.set('v.usedTemplate', cmp.find('templatedId').get('v.value'));
		helper.getTemplate(cmp, helper, cmp.find('templatedId').get('v.value'));
		//helper.getColumnAndAction(cmp, evt, helper);
	},

	// handling next button
	handleNext: function(cmp, evt, helper) {
		var pageNumber = cmp.get('v.pageNumber');
		cmp.set('v.pageNumber', pageNumber + 1);
		helper.getTemplate(cmp, helper, cmp.get('v.usedTemplate'));
	},

	//handling previous button
	handlePrev: function(cmp, evt, helper) {
		var pageNumber = cmp.get('v.pageNumber');
		cmp.set('v.pageNumber', pageNumber - 1);
		helper.getTemplate(cmp, helper, cmp.get('v.usedTemplate'));
	},
	// handling row action on view and delete
	handleRowAction: function(cmp, evt, helper) {
		var actionName = evt.getParam('action').name;
		var recId = evt.getParam('row').Id;
		if (actionName == 'view') {
			helper.navigate(cmp, evt, helper, recId);
		} else {
			cmp.set('v.deleteId', recId);
			var selectedEventId = recId;
			var msg = 'Do you want to delete this template?';
			if (!confirm(msg)) {
				cmp.set('v.deleteId', '');
				return false;
			} else {
				helper.deleteRecord(cmp, evt, helper);
			}
		}
	},
	closeModel: function(cmp, evt, helper) {
		var evtSource = evt.getSource().getLocalId();
		cmp.set('v.' + evtSource, false);
		cmp.set('v.deleteId', '');
		cmp.set('v.isViewques', false);
		cmp.set('v.istempMode', false);
	},
	updateColumnSorting: function(cmp, event, helper) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		cmp.set('v.sortedBy', fieldName);
		cmp.set('v.sortedDirection', sortDirection);
		helper.sortData(cmp, fieldName, sortDirection);
	},
	handleSearch: function(cmp, evt, helper) {
		var formId = cmp.find('searchForm');
		var ev = evt.getSource().get('v.name');
		if (ev == 'Search.') {
			cmp.set('v.isSearchEnabled', false);
			$A.util.removeClass(formId, 'slds-hide');
			evt.getSource().set('v.name', 'Search');
		} else {
			$A.util.addClass(formId, 'slds-hide');
			evt.getSource().set('v.name', 'Search.');
			cmp.set('v.isSearchEnabled', true);
		}
	},
	//handling search functionality ...this function would be made generic based on number of fields required for search
	applySearch: function(cmp, evt, helper) {
		let count = 0;
		var searchId = [ 'nameSearch', 'versionSearch', 'ownerSearch' ];
		var listObj = [];
		var isSearchAllowed = false;
		for (let i = 0; i < searchId.length; i++) {
			if (
				helper.checkfieldValidity(cmp, evt, helper, searchId[i]) &&
				cmp.find(searchId[i]).get('v.value').trim().length > 0
			) {
				let obj = new Object();
				obj.label = cmp.find(searchId[i]).get('v.name');
				obj.value = cmp.find(searchId[i]).get('v.value').trim();
				listObj.push(obj);
				count++;
				isSearchAllowed = true;
			} else if (
				!helper.checkfieldValidity(cmp, evt, helper, searchId[i]) &&
				cmp.find(searchId[i]).get('v.value').trim().length > 0
			) {
				isSearchAllowed = false;
			} else {
			}
		}
		if (count > 0 && isSearchAllowed) {
			cmp.set('v.isloading', true);
			let params = {
				searchParams: JSON.stringify(listObj),
				selectedTemplates: cmp.find('templatedId').get('v.value').trim(),
				count: count
			};
			helper.asyncPromisereturn(cmp.get('c.templateSearch'), params).then(
				function(result) {
					console.log('template>Search>'+JSON.stringify(result));
					if (!result.length > 0) {
						helper.showToast(
							cmp,
							evt,
							helper,
							'Error!',
							'error',
							'No data found based on search criteria.'
						);
						cmp.set('v.isloading', false);
						return;
					}
					result = helper.formatData(result);
					cmp.set('v.data', result);
					cmp.set('v.disabledPagin', true);
					cmp.set('v.isloading', false);
				},
				function(error) {
					//console.log('template>error>'+error);
					helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
					cmp.set('v.isloading', false);
				}
			);
		} else {
			helper.showToast(
				cmp,
				evt,
				helper,
				'Error!',
				'error',
				"Search field can't be empty or should have valid value."
			);
		}
	},
	verifyNumber: function(cmp, evt, helper) {
		var val = evt.getSource().get('v.value').trim();
		if (isNaN(val.trim())) {
			evt.getSource().set('v.value'), null;
		}
	}
});