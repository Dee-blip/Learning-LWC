({
	init: function(component) {
		
		component.set('v.loadFlow', 'true');
		
		component.set('v.flowName', component.get("v.lightningFlowName"));
		component.set('v.loadFlowString', 'load_flow');
	},

	statusChange: function(component, event) {
		console.log('SH : flow status :' + event.getParam('status'));
		let status = event.getParam('status');
		console.log('flow status :::'+status);
		if (event.getParam('status') === 'FINISHED') {
			console.log('SH : redirect after flow finishes');

			let outputVariables = event.getParam('outputVariables');
			let urlValue = '';
			let outputVar;
			if (outputVariables !== null && outputVariables !=="") {
                for (let i = 0; i < outputVariables.length; i++) {
                    outputVar = outputVariables[i];
                    if (outputVar.name === 'redirectRecordId' && outputVar.value !== '')
                        urlValue = '/detail/' + outputVar.value;
                }
            }
			if (urlValue === '') {
				urlValue = '/recordlist/' + component.get('v.sObjectName') + '/Default';
			}

			let urlEvent = $A.get('e.force:navigateToURL');
			urlEvent.setParams({
				url: urlValue
			});
			urlEvent.fire();
		} else if (event.getParam('status') === 'Error') {
			$A.get('e.force:refreshView').fire();
		}
	},

	itemsChange: function(cmp) {
		let flow = cmp.find('flowData');
		flow.startFlow(cmp.get('v.flowName'), cmp.get('v.inputParam'));
	}
});