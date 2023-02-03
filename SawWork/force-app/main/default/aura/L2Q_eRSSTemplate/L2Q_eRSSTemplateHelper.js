({
	// Promise to return server side call
	asyncPromisereturn: function(action, params) {
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
						reject('Unknown Error');
					}
				});
				$A.enqueueAction(action, false);
			})
		);
	},
	setIntialvalue: function(cmp, evt, helper) {
		//cmp.set('v.disabledPagin',false);
		var filterName = $A.get('$Label.c.L2Q_eRssfilterType').split('#');
		var filterList = [];
		for (let i = 0; i < filterName.length; i++) {
			let obj = new Object();
			obj.label = filterName[i];
			obj.value = filterName[i];
			filterList.push(obj);
		}
		cmp.set('v.options', filterList);
		cmp.find('templatedId').set('v.value', filterName[0]);
		cmp.set('v.usedTemplate', filterName[0]);
	},

	// method to check field validity specially for null check
	checkfieldValidity: function(cmp, evt, helper, fieldId) {
		var isValid = false;
		var customValidity = cmp.find(fieldId).get('v.value');

		if (!customValidity.trim().length > 0) {
			cmp.find(fieldId).set('v.value', '');
		}
		var validity = cmp.find(fieldId).get('v.validity');
		isValid = validity.valid;
		return isValid;
	},

	uniqueNumbergenerator: function(cmp, evt, helper) {
		var dt = new Date().getTime();
		var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = ((dt + Math.random() * 16) % 16) | 0;
			dt = Math.floor(dt / 16);
			return (c == 'x' ? r : (r & 0x3) | 0x8).toString(16);
		});
		return uuid;
	},
	navigate: function(cmp, evt, helper, recordId) {
		var evt = $A.get('e.force:navigateToComponent');
		evt.setParams({
			componentDef: 'c:L2Q_eRSSEditTemplate',
			componentAttributes: {
				recordId: recordId
			}
		});
		evt.fire();
	},
	getTemplate: function(cmp, helper, templName) {
		var filterName = $A.get('$Label.c.L2Q_eRssfilterType').split('#');
		cmp.set('v.isloading', true);
		helper.asyncPromisereturn(cmp.get('c.returnmetadataString'), { developerName: 'erssTemplateColumn' }).then(
			function(result) {
				result = result.split('&');
				if (cmp.get('v.usedTemplate') == filterName[0]) {
					cmp.set('v.columns', JSON.parse(result[0]));
				} else if (cmp.get('v.usedTemplate') == filterName[1]) {
					cmp.set('v.columns', JSON.parse(result[1]));
				} else {
					cmp.set('v.columns', JSON.parse(result[1]));
				}

				if ($A.get('$Browser.formFactor') !== 'DESKTOP') {
					cmp.set('v.columns', JSON.parse(result[2]));
				}
				var pageSize = cmp.get('v.pageSize').toString();
				var pageNumber = cmp.get('v.pageNumber').toString();
				let params = {
					pageSize: pageSize,
					pageNumber: pageNumber,
					selectedView: templName
				};
				helper.asyncPromisereturn(cmp.get('c.returnData'), params).then(
					function(result) {
						result = helper.formatData(result);
						if (result.length < cmp.get('v.pageSize')) {
							cmp.set('v.isLastPage', true);
						} else {
							cmp.set('v.isLastPage', false);
						}
						cmp.set('v.dataSize', result.length);
						cmp.set('v.data', result);
						//cmp.set('v.isloading', false);
						//added for sec check
						let params = {};
						helper.asyncPromisereturn(cmp.get('c.checkAccess'), params).then(
							function(result) {
								cmp.set('v.writeAccess', result);
								cmp.set('v.isloading', false);
							},
							function(error) {
								cmp.set('v.isloading', false);
								helper.showToast(cmp, evt, helper, 'Error', 'error', error);
							}
						);
					},
					function(error) {
						helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
						cmp.set('v.isloading', false);
					}
				);
			},
			function(error) {
				cmp.set('v.isloading', false);
			}
		);
	},
	deleteRecord: function(cmp, evt, helper) {
		cmp.set('v.isloading', true);
		let recIdtodelete = cmp.get('v.deleteId');
		let params = { recId: recIdtodelete };
		helper.asyncPromisereturn(cmp.get('c.deleteTemplate'), params).then(
			function(result) {
				cmp.set('v.deleteId', '');
				helper.showToast(cmp, evt, helper, 'Success!', 'success', 'The record has been delete successfully.');
				var rows = cmp.get('v.data');
				for (let i = 0; i < rows.length; i++) {
					if (rows[i].Id == recIdtodelete) {
						rows.splice(i, 1);
					}
				}
				cmp.set('v.data', rows);
				cmp.set('v.isloading', false);
			},
			function(error) {
				cmp.set('v.isloading', false);
				cmp.set('v.deleteId', '');
				helper.showToast(cmp, evt, helper, 'Error!', 'error', error);
			}
		);
	},
	resetpageUtil: function(cmp, evt, helper) {
		cmp.set('v.pageNumber', 1);
		cmp.set('v.pageSize', 25);
		cmp.set('v.isLastPage', false);
		cmp.set('v.dataSize', 0);
		cmp.set('v.disabledPagin', false);
		cmp.find('nameSearch').set('v.value', '');
		cmp.find('versionSearch').set('v.value', '');
		cmp.find('ownerSearch').set('v.value', '');
	},
	formatData: function(records) {
		records.forEach(function(record) {
			record.OwnerName = record.Owner.Name;
		});
		return records;
	},
	showToast: function(cmp, evt, helper, title, type, message) {
		var toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			title: title,
			type: type,
			message: message
		});
		toastEvent.fire();
	},
	sortData: function(cmp, fieldName, sortDirection) {
		var data = cmp.get('v.data');
		var reverse = sortDirection !== 'asc';
		data.sort(this.sortBy(fieldName, reverse));
		cmp.set('v.data', data);
	},
	// sortBy: function(field, reverse, primer) {
	// 	var key = primer
	// 		? function(x) {
	// 				return primer(x[field]);
	// 			}
	// 		: function(x) {
	// 				return x[field];
	// 			};
	// 	reverse = !reverse ? 1 : -1;
	// 	return function(a, b) {
	// 		return (a = key(a)), (b = key(b)), reverse * ((a > b) - (b > a));
	// 	};
	// }

	//below sorting consider lower case as well
	sortBy: function(field, reverse, primer) {
		var key = primer
			? function(x) {
					return primer(
						x.hasOwnProperty(field)
							? typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]
							: 'aaa'
					);
				}
			: function(x) {
					return x.hasOwnProperty(field)
						? typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]
						: 'aaa';
				};
		reverse = !reverse ? 1 : -1;
		return function(a, b) {
			return (a = key(a)), (b = key(b)), reverse * ((a > b) - (b > a));
		};
	}
});