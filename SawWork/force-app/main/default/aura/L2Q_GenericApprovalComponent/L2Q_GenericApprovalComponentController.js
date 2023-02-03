({
	init: function(component, event, helper) {
		helper.getInitialDataJS(component, event, helper);
		helper.setDisplayIcon(component, event, helper);
		//helper.setDataTableData(component);
		helper.getDataTableRows(component, helper);
		var openModalAction = component.get('v.openModalAction');
		if (openModalAction != 'No_Action') {
			component.set('v.buttonActionName', openModalAction);
			helper.handleRowActionMain(component, event, helper);
		}
	},

	navigateURL_BasedOnTheme: function(component, event, helper) {
		var ctarget = event.currentTarget;
		var navigationURL = ctarget.dataset.value;
		var themeDisplayed = component.get('v.themeDisplayed');
		console.log('navigateURL_BasedOnTheme themeDisplayed');
		console.log(themeDisplayed);
		if (themeDisplayed == 'Theme4d' || themeDisplayed == 'Theme4t') {
			sforce.one.navigateToURL(navigationURL);
		} else {
			window.open(navigationURL);
		}
	},

	navigateOnClick_BasedOnTheme: function(component, event, helper) {
		var ctarget = event.currentTarget;
		var dataValue = ctarget.dataset.value;
		var themeDisplayed = component.get('v.themeDisplayed');
		console.log('dataValue');
		console.log(dataValue);
		console.log('navigateOnClick_BasedOnTheme themeDisplayed');
		console.log(themeDisplayed);
		if (dataValue.substring(0, 3) == '00G') {
			if (themeDisplayed == 'Theme4d' || themeDisplayed == 'Theme4t') {
				sforce.one.navigateToURL(
					'/lightning/setup/Queues/page?address=%2Fp%2Fown%2FQueue%2Fd%3Fid%3D' + dataValue
				);
			} else {
				window.open(component.get('v.navigationPrefix') + 'setup/own/groupdetail.jsp?id=' + dataValue);
			}
		} else {
			if (themeDisplayed == 'Theme4d' || themeDisplayed == 'Theme4t') {
				sforce.one.navigateToSObject(dataValue);
			} else {
				window.open(component.get('v.navigationPrefix') + dataValue);
			}
		}
	},

	performSelectedAction: function(component, event, helper) {
		var selectedAction = component.get('v.buttonActionName');
		if (selectedAction == 'Reject') {
			if (
				helper.areAllRequiredFieldsSet(
					component,
					component.get('v.requiredFieldsToDisplayBasedOnAction_Reject')
				)
			) {
				helper.rejectApproval(component, event, helper);
			}
		} else if (selectedAction == 'Approve') {
			if (
				helper.areAllRequiredFieldsSet(
					component,
					component.get('v.requiredFieldsToDisplayBasedOnAction_Approve')
				)
			) {
				helper.approveApproval(component, event, helper);
			}
		} else if (selectedAction == 'Reassign') {
			if (
				helper.areAllRequiredFieldsSet(
					component,
					component.get('v.requiredFieldsToDisplayBasedOnAction_Reassign')
				)
			) {
				helper.reassignApproval(component, event, helper);
			}
		}
	},

	closeModal: function(component, event, helper) {
		//helper.closeModal(component, event, helper);
		//helper.clearData(component);
		helper.closeWindow(component);
	},

	/**Begin Rajesh Kumar JIRA # SFDC-6378 */
	checkreassignRecord: function(cmp, evt) {
		var selectedrecordId = evt.getParam('recordId');
		cmp.set('v.reassignedUserId', selectedrecordId);
	}
	/**End Rajesh Kumar JIRA # SFDC-6378 */
});