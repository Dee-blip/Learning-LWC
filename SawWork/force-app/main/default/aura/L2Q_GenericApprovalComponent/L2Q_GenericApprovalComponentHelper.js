({
	setDisplayIcon: function(component, event, helper) {
		var SObjectName = component.get('v.approvalSObjectName');
		if (!SObjectName.includes('__c')) {
			component.set('v.SObjectIcon', 'standard:' + SObjectName.toLowerCase());
		}
	},

	setDataTableData: function(component) {
		var disableRowActions = component.get('v.disableRowActions');
		var actionsEnabled = [
			{
				label: 'Reassign',
				name: 'Reassign',
				disabled: disableRowActions
			},
			{
				label: 'Approve',
				name: 'Approve',
				disabled: disableRowActions
			},
			{
				label: 'Reject',
				name: 'Reject',
				disabled: disableRowActions
			}
		];

		var actionsDisabled = [
			{
				label: 'Reassign',
				name: 'Reassign',
				disabled: true
			},
			{
				label: 'Approve',
				name: 'Approve',
				disabled: true
			},
			{
				label: 'Reject',
				name: 'Reject',
				disabled: true
			}
		];

		component.set('v.requiredApprovalColumns', [
			{
				label: 'Step Name',
				fieldName: 'stepName',
				sortable: 'true',
				type: 'text'
			},
			{
				label: 'Date',
				fieldName: 'date',
				sortable: 'true',
				type: 'date',
				sortable: 'true'
			},
			{
				label: 'Status',
				fieldName: 'status',
				sortable: 'false',
				type: 'text'
			},
			{
				label: 'Assigned To',
				fieldName: 'assignedTo',
				sortable: 'true',
				type: 'text'
			},
			{
				label: 'Actual Approver',
				fieldName: 'acctualApprover',
				type: 'text',
				sortable: 'true'
			},
			{
				label: 'Comments',
				fieldName: 'comments',
				type: 'text',
				sortable: 'false'
			},
			{
				fieldName: 'actions',
				type: 'action',
				typeAttributes: {
					rowActions: actionsEnabled
				}
			}
		]);
		component.set('v.previousApprovalColumns', [
			{
				label: 'Step Name',
				fieldName: 'stepName',
				sortable: 'true',
				type: 'text'
			},
			{
				label: 'Date',
				fieldName: 'date',
				sortable: 'true',
				type: 'date',
				sortable: 'true'
			},
			{
				label: 'Status',
				fieldName: 'status',
				sortable: 'false',
				type: 'text'
			},
			{
				label: 'Assigned To',
				fieldName: 'assignedTo',
				sortable: 'true',
				type: 'text'
			},
			{
				label: 'Actual Approver',
				fieldName: 'acctualApprover',
				type: 'text',
				sortable: 'true'
			},
			{
				label: 'Comments',
				fieldName: 'comments',
				type: 'text',
				sortable: 'false'
			},
			{
				fieldName: 'actions',
				type: 'action',
				typeAttributes: {
					rowActions: actionsDisabled
				}
			}
		]);
	},

	getDataTableRows: function(component, helper) {
		var currentRecordId = component.get('v.currentRecordId');
		console.log('currentRecordId : ' + currentRecordId);
		var getApprovals = component.get('c.getApprovalsForSpecifiedRecordId');
		getApprovals.setParams({
			recordId: currentRecordId
		});
		getApprovals.setCallback(this, function(response) {
			var state = response.getState();
			if (state == 'SUCCESS') {
				var listOfApprovalsThatRequireApprovals = [];
				var listOfApprovalsPreApprovals = [];
				var returnVal = response.getReturnValue();
				console.log(returnVal);
				if (returnVal['availableForApproval'] == 'false') {
					component.set('v.disableRowActions', true);
				}
				component.set('v.themeDisplayed', returnVal['themeDisplayed']);
				helper.setDataTableData(component);
				var returnValObj = JSON.parse(returnVal['jsonData']);
				console.log(returnValObj);
				var approvalList = JSON.parse(returnValObj['myApprovalList']);
				console.log('approvalList');
				console.log(approvalList);
				var setCurrentActiveRow = false;
				if (component.get('v.openModalAction') != 'No_Action') {
					//component.set("v.currentActiveRow",)
					setCurrentActiveRow = true;
					console.log('here 1');
					var currentActiveRowId = component.get('v.currentActiveRowId');
					console.log(currentActiveRowId);
				}
				for (var index in approvalList) {
					var eachApproval = {
						id: approvalList[index]['approvalStepId'],
						stepName: approvalList[index]['requestName'],
						date: approvalList[index]['submittedDate'],
						status: approvalList[index]['status'],
						assignedTo: approvalList[index]['originalActorName'],
						acctualApprover: approvalList[index]['lastActorName'],
						comments: approvalList[index]['comments'],
						assignedToId: approvalList[index]['originalActorId'],
						acctualApproverId: approvalList[index]['lastActorId'],
						reassignHref:
							component.get('v.navigationPrefix') +
							'apex/' +
							component.get('v.currentHandlingPage') +
							'?openModalAction=Reassign&currentActiveRowId=' +
							approvalList[index]['approvalStepId'] +
							'&Id=' +
							component.get('v.currentRecordId'),
						approveHref:
							component.get('v.navigationPrefix') +
							'apex/' +
							component.get('v.currentHandlingPage') +
							'?openModalAction=Approve&currentActiveRowId=' +
							approvalList[index]['approvalStepId'] +
							'&Id=' +
							component.get('v.currentRecordId'),
						rejectHref:
							component.get('v.navigationPrefix') +
							'apex/' +
							component.get('v.currentHandlingPage') +
							'?openModalAction=Reject&currentActiveRowId=' +
							approvalList[index]['approvalStepId'] +
							'&Id=' +
							component.get('v.currentRecordId')
					};
					if (setCurrentActiveRow && approvalList[index]['approvalStepId'] == currentActiveRowId) {
						component.set('v.currentActiveRow', eachApproval);
						console.log('currentActiveRow : ' + eachApproval);
					}
					if (approvalList[index]['status'] == 'Pending') {
						listOfApprovalsThatRequireApprovals.push(eachApproval);
					} else {
						listOfApprovalsPreApprovals.push(eachApproval);
					}
				}
                
                if (approvalList.length > 0) {
                    component.set('v.afterInitialCallBack', true);
					console.log('afterInitialCallBack' + true);
                }
				console.log('listOfApprovalsThatRequireApprovals');
				console.log(listOfApprovalsThatRequireApprovals);
				console.log('listOfApprovalsPreApprovals');
				console.log(listOfApprovalsPreApprovals);
				component.set('v.requiredApprovalData', listOfApprovalsThatRequireApprovals);
				component.set('v.previousApprovalData', listOfApprovalsPreApprovals);
				
			}
		});

		$A.enqueueAction(getApprovals);
	},

	closeWindow: function(component) {
		var themeDisplayed = component.get('v.themeDisplayed');
		if (themeDisplayed == 'Theme4d' || themeDisplayed == 'Theme4t') {
			sforce.one.navigateToSObject(component.get('v.currentRecordId'));
		} else {
			window.close();
		}
	},

	closeModal: function(component, event, helper) {
		var cmpTarget = component.find('SortModalbox');
		var cmpBack = component.find('SortModalClose');
		$A.util.removeClass(cmpBack, 'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
		helper.clearData(component);
	},

	openModal: function(component, event) {
		var cmpTarget = component.find('SortModalbox');
		var cmpBack = component.find('SortModalClose');
		$A.util.addClass(cmpTarget, 'slds-fade-in-open');
		$A.util.addClass(cmpBack, 'slds-backdrop--open');
		$A.util.addClass(cmpBack, 'showModalOnParent');
	},

	handleRowActionMain: function(component, event, helper) {
		var selectedAction = component.get('v.buttonActionName');
		if (selectedAction == 'Reject') {
			component.set('v.typeOfAction', 'Reject this Approval Request');
		} else if (selectedAction == 'Approve') {
			component.set('v.typeOfAction', 'Approve this Approval Request');
		} else if (selectedAction == 'Reassign') {
			component.set('v.typeOfAction', 'Reassign this Approval Request');
		}
		//helper.openModal(component, event);
	},

	desetErrors: function(component) {
		component.set('v.hasErrors', false);
		component.set('v.errorMessageReturned', 'Unexpected error Occurred!');
	},

	rejectApproval: function(component, event, helper) {
		helper.desetErrors(component);
		var fields = component.get('v.requiredFieldsToDisplayBasedOnAction_Reject');
		fields = fields.listOfFields;
		console.log(fields);

		var currentActiveRow = component.get('v.currentActiveRow');
		console.log('currentActiveRow');
		console.log(JSON.stringify(currentActiveRow));
		var rejectApprovalControllerVar = component.get('c.rejectApprovalController');
		var fieldVsValueMap = {};
		for (var index = 0; index < fields.length; index++) {
			if (fields[index].value != null && fields[index].value != '') {
				fieldVsValueMap[fields[index].fieldAPIName] = fields[index].value;
			}
		}
		console.log('fieldVsValueMap');
		console.log(fieldVsValueMap);
		rejectApprovalControllerVar.setParams({
			recordId: component.get('v.currentRecordId'),
			approvalComments: component.get('v.approvalComments'),
			approvalWorkItemId: currentActiveRow['id'],
			mapOfFieldVsValue: fieldVsValueMap
		});
		rejectApprovalControllerVar.setCallback(this, function(response) {
			var state = response.getState();
			console.log(state);
			if (state == 'SUCCESS') {
				var returnVal = response.getReturnValue();
				console.log(returnVal);
				if (returnVal.includes('Successfully')) {
					helper.closeWindow(component);
				} else {
					component.set('v.hasErrors', true);
					if (returnVal.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
						component.set('v.errorMessageReturned', helper.formatErrorMessage(returnVal));
					} else {
						component.set('v.errorMessageReturned', returnVal);
					}
				}
			}
		});

		$A.enqueueAction(rejectApprovalControllerVar);
		helper.clearData(component);
	},
	formatErrorMessage: function(returnVal) {
		var returnValSplit = returnVal.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
		var requiredErrorMessage = returnValSplit[returnValSplit.length - 1];
		if (requiredErrorMessage.includes(': []')) {
			requiredErrorMessage = requiredErrorMessage.replace(': []', '');
		}
		return requiredErrorMessage;
	},
	approveApproval: function(component, event, helper) {
		helper.desetErrors(component);
		var currentActiveRow = component.get('v.currentActiveRow');
		console.log('currentActiveRow');
		console.log(JSON.stringify(currentActiveRow));
		//SFDC-6078
		var fields = component.get('v.requiredFieldsToDisplayBasedOnAction_Approve');
		fields = fields.listOfFields;
		console.log(fields);
		var fieldVsValueMap = {};
		for (var index = 0; index < fields.length; index++) {
			if (fields[index].value != null && fields[index].value != '') {
				fieldVsValueMap[fields[index].fieldAPIName] = fields[index].value;
			}
		}
		console.log('fieldVsValueMap on Approval');
		console.log(fieldVsValueMap);

		var approveApprovalControllerVar = component.get('c.approveApprovalController');
		approveApprovalControllerVar.setParams({
			recordId: component.get('v.currentRecordId'),
			approvalComments: component.get('v.approvalComments'),
			approvalWorkItemId: currentActiveRow['id'],
			mapOfFieldVsValue: fieldVsValueMap
		});
		approveApprovalControllerVar.setCallback(this, function(response) {
			var state = response.getState();
			if (state == 'SUCCESS') {
				var returnVal = response.getReturnValue();
				console.log(returnVal);
				if (returnVal.includes('Successfully')) {
					helper.closeWindow(component);
				} else {
					component.set('v.hasErrors', true);
					if (returnVal.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
						component.set('v.errorMessageReturned', helper.formatErrorMessage(returnVal));
					} else {
						component.set('v.errorMessageReturned', returnVal);
					}
				}
			}
		});

		$A.enqueueAction(approveApprovalControllerVar);

		helper.clearData(component);
		helper.closeModal(component, event, helper);
	},
	reassignApproval: function(component, event, helper) {
		helper.desetErrors(component);
		var fields = component.get('v.requiredFieldsToDisplayBasedOnAction_Reassign');
		fields = fields.listOfFields;
		console.log(fields);

		var currentActiveRow = component.get('v.currentActiveRow');
		console.log('currentActiveRow');
		console.log(JSON.stringify(currentActiveRow));
		var reassignApprovalControllerVar = component.get('c.reassignApprovalController');

		reassignApprovalControllerVar.setParams({
			recordId: component.get('v.currentRecordId'),
			approvalComments: component.get('v.approvalComments'),
			reassignTo: component.get('v.reassignedUserId'),
			approvalWorkItemId: currentActiveRow['id']
		});
		reassignApprovalControllerVar.setCallback(this, function(response) {
			var state = response.getState();
			if (state == 'SUCCESS') {
				var returnVal = response.getReturnValue();
				console.log(returnVal);
				if (returnVal.includes('Successfully')) {
					helper.closeWindow(component);
				} else {
					component.set('v.hasErrors', true);
					if (returnVal.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
						component.set('v.errorMessageReturned', helper.formatErrorMessage(returnVal));
					} else {
						component.set('v.errorMessageReturned', returnVal);
					}
				}
			}
		});

		$A.enqueueAction(reassignApprovalControllerVar);

		helper.clearData(component);
		helper.closeModal(component, event, helper);
	},
	getInitialDataJS: function(component, event, helper) {
		var SObjectName = component.get('v.approvalSObjectName');
		var getInitialDataVar = component.get('c.getInitialData');
		getInitialDataVar.setParams({
			sObjectName: component.get('v.approvalSObjectName'),
			fieldOverrideMetadata: component.get('v.fieldOverrideMetadata'),
			/**Begin Rajesh Kumar JIRA # SFDC-6378 */
			recordId: component.get('v.currentRecordId')
			/**End Rajesh Kumar JIRA # SFDC-6378 */
		});
		getInitialDataVar.setCallback(this, function(response) {
			component.set('v.initCallBackComplete', true);
			var state = response.getState();
			if (state == 'SUCCESS') {
				//this.getDataTableRows(component, helper); // added by Rajesh
				var returnVal = response.getReturnValue(); 
				if(returnVal.SpenderCheckboxMarked === 'true'){ //SFDC-8759
                    console.log('here');
                    console.log(component.get('v.SpenderFlagRequired'));
                    component.set('v.SpenderFlagRequired', 'false');
                    console.log('after ' + component.get('v.SpenderFlagRequired'));
                }
				if(returnVal.SpenderCheckboxMarked === 'false'){
                    console.log(component.get('v.SpenderFlagRequired'));
                    component.set('v.SpenderFlagRequired', 'true');
                    console.log('after ' + component.get('v.SpenderFlagRequired'));
                    
                }
				/**Begin Rajesh Kumar JIRA # SFDC-6378 */
				var isPaestep = returnVal['paeStep'].toLowerCase() === 'true'; 

				var isExternalUser = returnVal['externalUser'] ==='yes';
				if (
					isExternalUser &&
					isExternalUser != '' &&
					isExternalUser!== 'undefined' &&
					isExternalUser!== undefined &&
					isExternalUser != null
					){
					component.set('v.isExternalUser',true); 
				} //SDFC 7024

				if (
					isPaestep && 
					(returnVal['whereClause'] == '' ||
						returnVal['whereClause'] == undefined ||
						returnVal['whereClause'] == 'undefined' ||
						returnVal['whereClause'] == null)
				) {
					component.set('v.whereClause', ' and id = ' + "'" + '000000000000000' + "'");
				} else if (isPaestep) {
					component.set(
						'v.whereClause',
						' and id in ' +
						returnVal.whereClause +
							' and isActive = true ' +
							' and usertype = ' +
							" 'Standard' "
					);
				} else if (
					returnVal['whereClause'] != '' &&
					returnVal['whereClause'] != 'undefined' &&
					returnVal['whereClause'] != undefined &&
					returnVal['whereClause'] != null
				) {
					component.set(
						'v.whereClause',
						' and id not in ' +
						returnVal.whereClause  +
							' and isActive = true ' +
							' and usertype = ' +
							" 'Standard' "
					);
				} else {
					component.set('v.whereClause', ' and isActive = true ' + ' and usertype = ' + " 'Standard' ");
				}
				/**End Rajesh Kumar JIRA # SFDC-6378 */
				component.set('v.navigationPrefix', returnVal['navigationPrefix']);
				console.log(returnVal['navigationPrefix']);
				var fieldDescriptorWrapperObj = JSON.parse(returnVal['fieldDescriptorWrapper']);

				var requiredFieldsToDisplayBasedOnAction_Reassign;
				var requiredFieldsToDisplayBasedOnAction_Approve;
				var requiredFieldsToDisplayBasedOnAction_Reject;

				for (var i = 0; i < fieldDescriptorWrapperObj.length; i++) {
					if (fieldDescriptorWrapperObj[i]['actionType'] == 'Reassign') {
						requiredFieldsToDisplayBasedOnAction_Reassign = {
							listOfFields: fieldDescriptorWrapperObj[i]['listOfFieldDescriptors'],
							displayCommentsSection: fieldDescriptorWrapperObj[i]['displayCommentsSection']
						};
					} else if (fieldDescriptorWrapperObj[i]['actionType'] == 'Approve') {
						requiredFieldsToDisplayBasedOnAction_Approve = {
							listOfFields: fieldDescriptorWrapperObj[i]['listOfFieldDescriptors'],
							displayCommentsSection: fieldDescriptorWrapperObj[i]['displayCommentsSection']
						};
					} else if (fieldDescriptorWrapperObj[i]['actionType'] == 'Reject') {
						requiredFieldsToDisplayBasedOnAction_Reject = {
							listOfFields: fieldDescriptorWrapperObj[i]['listOfFieldDescriptors'],
							displayCommentsSection: fieldDescriptorWrapperObj[i]['displayCommentsSection']
						};
					}
				}
				console.log(returnVal);
				console.log('requiredFieldsToDisplayBasedOnAction_Reject');
				console.log(requiredFieldsToDisplayBasedOnAction_Reject);
				component.set(
					'v.requiredFieldsToDisplayBasedOnAction_Reassign',
					requiredFieldsToDisplayBasedOnAction_Reassign
				);
				component.set(
					'v.requiredFieldsToDisplayBasedOnAction_Approve',
					requiredFieldsToDisplayBasedOnAction_Approve
				);
				component.set(
					'v.requiredFieldsToDisplayBasedOnAction_Reject',
					requiredFieldsToDisplayBasedOnAction_Reject
				);
			}
		});
		$A.enqueueAction(getInitialDataVar);
	},

	clearData: function(component) {
		component.set('v.renderAction', true);
		component.set('v.errorMessage', 'Unexpected error Occurred!');
	},

	areAllRequiredFieldsSet: function(component, fieldDescList) {
		fieldDescList = fieldDescList.listOfFields;
		//fieldDescList = fieldDescList.listOfFieldDescriptors;
		console.log('fieldDescList : ');
		console.log(JSON.stringify(fieldDescList.listOfFields));
		var flag = true;
		for (var i = 0; i < fieldDescList.length; i++) {
			if (
				fieldDescList[i]['isRequired'] != null &&
				fieldDescList[i]['isRequired'] != false &&
				(fieldDescList[i]['value'] == null ||
					fieldDescList[i]['value'] == undefined ||
					fieldDescList[i]['value'] == '' ||
					fieldDescList[i]['value'] == '--None--')
			) {
				flag = false;
				console.log('here');
				console.log(fieldDescList[i]);
			}
		}
		if (component.get('v.buttonActionName') == 'Reassign') {
			var reassignedUserIdVar = component.get('v.reassignedUserId');
			console.log('reassignedUserIdVar');
			console.log(reassignedUserIdVar);
			if (reassignedUserIdVar == null || reassignedUserIdVar == '') {
				flag = false;
			}
		}
		if (flag == false) {
			component.set('v.errorMessage', 'All Required Fields Not Set');
		}
		component.set('v.renderAction', flag);
		return flag;
	}
});