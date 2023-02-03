({
	handleServercall: function(action, params) {
		return new Promise(
			$A.getCallback(function(resolve, reject) {
				if (params) {
					action.setParams(params);
				}
				action.setCallback(this, function(response) {
					var state = response.getState();
					if (state === 'SUCCESS') {
						resolve(response.getReturnValue());
					} else if (state === 'ERROR') {
						var errors = response.getError();
						if (errors && errors[0] && errors[0].message) {
							reject(errors[0].message);
						}
					} else {
						reject('Unknown Error Occured ');
					}
				});
				$A.enqueueAction(action, false);
			})
		);
	}
});