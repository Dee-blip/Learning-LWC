({
	init: function(component, event, helper) {
		var exeActionForObject = component.get('c.getFlowDetails');
		exeActionForObject.setParams({
			url: window.location.href
		});
		helper.serverSideCall(component, exeActionForObject).then(function(response) {
			var res = JSON.parse(response);
			var sObjectName = res.sObjectName;
			var parentId = res.parentId;
			var partnerInvolved = res.partnerInvolved;
			console.log('SH : parentId from server : ' + parentId);
			if (parentId == null || parentId == '') parentId = '';
            if (partnerInvolved == null) partnerInvolved = '';
			console.log('SH : parentId now : ' + parentId);
			console.log('SH : sObjectName :' + sObjectName);
			console.log('SH : partnerInvolved :' + partnerInvolved);
			component.set('v.sObjectName', sObjectName);
			if (sObjectName == 'Opportunity') {
				component.set('v.loadFlow', 'true');
				var inputVariables = [
					{
						name: 'PartnerInvolved',
						type: 'String',
						value: partnerInvolved
					},
					{
						name: 'netAllianceurl',
						type: 'String',
						value: '/partners/006/o'
					},
					{
						name: 'parentId',
						type: 'String',
						value: parentId
					}
				];
				// Find the component whose aura:id is "flowData"
				component.set('v.inputParam', inputVariables); //rajesh
				component.set('v.flowName', 'Deal_Registration_Flow'); //rajesh
				component.set('v.loadFlowString', 'load_flow'); //rajesh
			}
			if (sObjectName == 'SFDC_MDF__c') {
				component.set('v.loadFlow', 'true');
				var flow = component.find('flowData');

				var inputVariables = [
					{
						name: 'selectedPMAId',
						type: 'String',
						value: parentId
					},
					{
						name: 'linkNavigatorPrefix',
						type: 'String',
						value: '/partners/'
					}
				];
				component.set('v.inputParam', inputVariables);
				component.set('v.flowName', 'Simplified_Fund_Request_Flow'); 
				component.set('v.loadFlowString', 'load_flow');
			}

			if (sObjectName == 'SFDC_MDF_Claim__c') {
				component.set('v.loadFlow', 'true');
				var flow = component.find('flowData');

				var inputVariables = [
					{
						name: 'SelectedFRId',
						type: 'String',
						value: parentId
					},
					{
						name: 'linkNavigatorPrefix',
						type: 'String',
						value: '/partners/s'
					}
				];

				component.set('v.inputParam', inputVariables);
				component.set('v.flowName', 'Create_FC');
				component.set('v.loadFlowString', 'load_flow');
			}

			if (sObjectName == 'Lead') {
				component.set('v.loadFlow', 'true');
				var flow = component.find('flowData');

				var inputVariables = [
					{
						name: 'parentId',
						type: 'String',
						value: parentId
					}
				];
				component.set('v.inputParam', inputVariables);
				component.set('v.flowName', 'Lead_Creation_Flow');
				component.set('v.loadFlowString', 'load_flow');
			}

			if (sObjectName == 'Partner_Marketing_Plan__c') {
				component.set('v.loadFlow', 'true');
				var flow = component.find('flowData');
				component.set('v.flowName', 'PMP_PMA_Creation_and_Edit');
				component.set('v.loadFlowString', 'load_flow');
			}
		});
	},

	statusChange: function(component, event) {
		console.log('SH : flow status :' + event.getParam('status'));
		var status = event.getParam('status');
		if (event.getParam('status') == 'FINISHED') {
			console.log('SH : redirect after flow finishes');

			var outputVariables = event.getParam('outputVariables');
			console.log(outputVariables);
			var urlValue = '';
			var outputVar;
			if (outputVariables != null && outputVariables !="") {
                for (var i = 0; i < outputVariables.length; i++) {
                    outputVar = outputVariables[i];
                    if (outputVar.name === 'redirectRecordId' && outputVar.value != '')
                        urlValue = '/detail/' + outputVar.value;
                }
            }
			if (urlValue == '') {
				urlValue = '/recordlist/' + component.get('v.sObjectName') + '/Default';
				console.log('SH : flow status change. URL :' + urlValue);
			}

			var urlEvent = $A.get('e.force:navigateToURL');
			urlEvent.setParams({
				url: urlValue
			});
			urlEvent.fire();
		} else if (event.getParam('status') == 'Error') {
			$A.get('e.force:refreshView').fire();
		}
	},

	itemsChange: function(cmp, evt) {
		var flow = cmp.find('flowData');
		flow.startFlow(cmp.get('v.flowName'), cmp.get('v.inputParam'));
	}
});