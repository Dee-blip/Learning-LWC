({
	// promise to handle server call
	handleServercall: function (action, params) {
		return new Promise(
			$A.getCallback(function (resolve, reject) {
				if (params) {
					action.setParams(params);
				}
				action.setCallback(this, function (response) {
					let state = response.getState(); // es-lint verify server data
					if (state === 'SUCCESS') {
						resolve(response.getReturnValue());
					} else if (state === 'ERROR') {
						let errors = response.getError(); // es-lint verify sever data
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
	},
	// retrieve existing data from server
	retrieveData: function (cmp, evt, helper, mode) {
		cmp.set('v.isLoading', true);
		var mode1 = mode; //Rajesh
		helper
			.handleServercall(cmp.get('c.getData'), {
				objName: cmp.get('v.objName'),
				fieldSet: cmp.get('v.queryFields'),
				WhereClause: cmp.get('v.whereClause'),
				recordLimit: cmp.get('v.recordLimit'),
				orderby: cmp.get('v.orderby')
			})
			.then(
				function (res) {
					if (mode1 == 'pre' && res.length < 1) {
						helper.showToast(cmp, evt, helper, 'info', 'INFO !', 'No record found.');
					}
					let newObj = [];
					res.map((element) => {
						let obj = {};
						obj.fieldArray = helper.process(cmp, evt, helper, element);
						obj.uniqueKey = helper.generateUniquenumber();
						obj.recordId = element.Id ? element.Id : '';
						obj = helper.intializeChild(cmp, evt, helper, obj); //Rajesh Kumar - SFDC-7368 
						newObj.push(obj);
					});

					cmp.set('v.data', newObj);
					cmp.set('v.scrollData', JSON.parse(JSON.stringify(newObj))); // original server data for compare with changed Data
					cmp.set('v.isLoading', false);
				},
				function (rej) {
					cmp.set('v.isLoading', false);
					helper.showToast(cmp, evt, helper, 'error', 'Error !', JSON.stringify(rej));
				}
			);
	},
	// process existing record and handle readonly fields for closed records - also prepares internal arrey for dynamic field for the object to use in aura iteration
	process: function (cmp, evt, helper, obj) {
		var finArray = [];
		var schemaMap = cmp.get('v.schemaMap');
		var resArray = [];
		for (let key in obj) { // es-lint verify read only functionality 
			if (key !== 'Id' && key !== 'id' && key !== 'Capacity_Allocations__r') { // es-lint verify delete and read functionality 
				resArray.push({
					fieldapiName: key,
					fieldapiValue: obj[key],
					fieldType: schemaMap.get(key).fieldType,
					fieldPicklistvalues: schemaMap.get(key).picklistValues
				});
			}
		}
		let mp = new Map();
		resArray.forEach(function (el) {
			mp.set(el.fieldapiName, el);
		});
		cmp.get('v.schemaDetails').forEach(function (el) {
			let aobj = {}; // es-lint changed the name to be different from global one 
			if (mp.has(el.fieldapiName)) {
				aobj.fieldapiName = el.fieldapiName;
				aobj.fieldapiValue = mp.get(el.fieldapiName).fieldapiValue;
				aobj.fieldType = el.fieldType;
				aobj.fieldPicklistvalues = el.picklistValues;
				// obj.readonly = helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue); //schemaMap.get(el.fieldapiName).readonly; // SFDC-7352
				//aobj.readonly = cmp.get('v.ishistoricalMode') ? true : (el.fieldapiName === 'Unit_of_Measure__c' && !(mp.get('Delivery_Product__c').fieldapiValue === 'Ion' || mp.get('Delivery_Product__c').fieldapiValue === 'DSA')) ? true : helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue) //Rajesh Kumar | SFDC-7352 & Rajesh Kumar - SFDC-7608
				aobj.readonly = (el.fieldapiName === 'Unit_of_Measure__c' && !(mp.get('Delivery_Product__c').fieldapiValue === 'Ion' || mp.get('Delivery_Product__c').fieldapiValue === 'DSA')) ? true : helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue) //Rajesh Kumar | SFDC-7352
				aobj.isrequired = schemaMap.get(el.fieldapiName).isrequired;
			} else {
				aobj.fieldapiName = el.fieldapiName;
				aobj.fieldapiValue = '';
				aobj.fieldType = el.fieldType;
				aobj.fieldPicklistvalues = el.picklistValues;
				//obj.readonly = helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue); //schemaMap.get(el.fieldapiName).readonly; // SFDC-7352
				//aobj.readonly = cmp.get('v.ishistoricalMode') ? true : (el.fieldapiName === 'Unit_of_Measure__c' && !(mp.get('Delivery_Product__c').fieldapiValue === 'Ion' || mp.get('Delivery_Product__c').fieldapiValue === 'DSA')) ? true : helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue); //Rajesh Kumar | SFDC-7352 & Rajesh Kumar - SFDC-7608
				aobj.readonly = (el.fieldapiName === 'Unit_of_Measure__c' && !(mp.get('Delivery_Product__c').fieldapiValue === 'Ion' || mp.get('Delivery_Product__c').fieldapiValue === 'DSA')) ? true : helper.checkRowreadonlystatus(cmp, evt, helper, mp.get('Status__c').fieldapiValue); //Rajesh Kumar | SFDC-7352
				aobj.isrequired = schemaMap.get(el.fieldapiName).isrequired;
			}
			finArray.push(aobj);
		});
		return finArray;
	},
	// prepares metadata including picklist field values and multiselect and other type for new row
	rowIntializer: function (cmp, evt, helper) {
		let tempObj = {}; // Rajesh Kumar | SFDC-7368  
		var schemaMap = cmp.get('v.schemaMap');
		let arr = [];
		cmp.get('v.schemaDetails').forEach(function (el) {
			arr.push({
				fieldapiName: el.fieldapiName,
				fieldapiValue: el.fieldapiName === 'Status__c' ? //es-lint eqeqeq
					'Pending' : el.fieldapiName === 'APJ_Capacity__c' ||
						el.fieldapiName === 'EMEA_Capacity__c' ||
						el.fieldapiName === 'LATAM_Capacity__c' ||
						el.fieldapiName === 'North_America_Capacity__c' ?
						0 : schemaMap.get(el.fieldapiName).fieldType === 'BOOLEAN' ?
							false : schemaMap.get(el.fieldapiName).fieldType === 'MULTIPICKLIST' ? '' : null,
				fieldType: el.fieldType,
				fieldPicklistvalues: el.picklistValues,
				readonly: false,
				isrequired: el.isrequired
			});
		});
		//Begin  Rajesh Kumar | SFDC-7368
		tempObj.uniqueKey = helper.generateUniquenumber();
		tempObj.recordId = '';
		tempObj.fieldArray = arr;
		tempObj = helper.intializeChild(cmp, evt, helper, tempObj);
		return tempObj;
		//End  Rajesh Kumar | SFDC-7368
	},
	generateUniquenumber: function () {
		var dt = new Date().getTime();
		var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
			var r = ((dt + Math.random() * 16) % 16) | 0;
			dt = Math.floor(dt / 16);
			return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
		});
		return uuid;
	},
	showToast: function (component, event, helper, variant, title, message) {
		var toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			type: variant,
			title: title,
			message: message
		});
		toastEvent.fire();
	},
	objtoMap: function (obj) {
		let mp = new Map();
		for (let key in obj) {
			mp.set(obj[key].fieldapiName, obj[key]);
		}
		return mp;
	},
	// validate data before save for required field
	dataValidator: function (cmp, evt, helper, data) { // es-lint verify data validator is working fine 
		var schemaMap = cmp.get('v.schemaMap');
		if (data.length < 1) {
			helper.showToast(cmp, evt, helper, 'info', 'WARNING: ', 'No data found in scroll.');
			return false;
		}
		for (let i = 0; i < data.length; i++) {
			//var pervalidField = cmp.get('v.percentageValidationstring');
			let z = i + 1; // es-lint changed to let 
			for (let k = 0; k < data[i].fieldArray.length; k++) {
				if (schemaMap.get(data[i].fieldArray[k].fieldapiName).isrequired && (data[i].fieldArray[k].fieldapiValue === '' || data[i].fieldArray[k].fieldapiValue === undefined || data[i].fieldArray[k].fieldapiValue === null)) {
					helper.showToast(cmp, evt, helper, 'error', 'ERROR AT ROW NO : ' + z, "'" + schemaMap.get(data[i].fieldArray[k].fieldapiName).fieldLabel + "'" + ' is missing.');
					return false;
				}
			}

		}
		return true;
	},
	prepareServerdata: function (data) {
		let datatoSend = [];
		data.forEach(function (el) {
			let obj = {};
			obj.recordId = el.recordId;
			obj.uniqueKey = el.uniqueKey;
			obj.fieldArray = el.fieldArray;
			datatoSend.push(obj);
		});
		return datatoSend;
	},
	navigatetoRecorddetail: function (cmp, evt, helper, recordId) {
		var navEvt = $A.get('e.force:navigateToSObject');
		navEvt.setParams({
			recordId: recordId,
			slideDevName: 'detail'
		});
		navEvt.fire();
	},
	checkRowreadonlystatus: function (cmp, evt, helper, status) {
		if (cmp.get('v.readonlyStatus').includes(status)) {
			return true;
		}
		return false;
	},
	// below methods compares two object array and keeps only changed value sequence of large and small array must be maintained
	comparetwonestedArrays: function (cmp, evt, helper, largeArray, smallArary) {
		let serverData = [];
		try {
			if (smallArary.length > 0) {
				for (let i = 0; i < largeArray.length; i++) {
					if (largeArray[i].hasOwnProperty('requestedcapacity')) {//Rajesh - SFDC-7368
						delete largeArray[i].requestedcapacity;
					}
					if (largeArray[i].hasOwnProperty('approvedcapacity')) { //Rajesh - SFDC-7368
						delete largeArray[i].approvedcapacity;
					}
					if (i < smallArary.length) {
						// if (JSON.stringify(largeArray[i].fieldArray) !== JSON.stringify(smallArary[i].fieldArray)) {
						if (JSON.stringify(largeArray[i]) !== JSON.stringify(smallArary[i])) { //Begin  Rajesh Kumar | SFDC-7368 | Commented above code and compared for whole row change
							serverData.push(largeArray[i]);
						}
					} else {
						serverData.push(largeArray[i]);
					}
				}
			} else {
				if (largeArray.length > 0) {
					serverData = serverData.concat(largeArray);
				}
			}
		} catch (err) {
			console.log('compare error Message' + err.message);
		}

		return serverData;
	},
	//Begin  Rajesh Kumar | SFDC-7368
	// returns mapping for API Name versus reason
	returLabelmapping: function (emp, evt, helper, data) {
		let mp = new Map();
		data.forEach(el => {
			mp.set(el.apiname, el);
		})
		return mp;
	},
	// concatinatinng value region wise before  requested capacity || Approved capacity || Ideally in one transaction only one value would be stamped
	concatenateChangedarray: function (cmp, evt, helper, data) {
		data.forEach(el => {
			let apj = (el.apjcpAllocated === '') ? [] : JSON.parse(el.apjcpAllocated);
			let emea = (el.emeacpAllocated === '') ? [] : JSON.parse(el.emeacpAllocated);
			let latam = (el.latamcpAllocated === '') ? [] : JSON.parse(el.latamcpAllocated);
			let na = (el.nacpAllocated === '') ? [] : JSON.parse(el.nacpAllocated);
			let apjapp = (el.apjapprcp === '') ? [] : JSON.parse(el.apjapprcp);
			let emeaapp = (el.emeaapprcp === '') ? [] : JSON.parse(el.emeaapprcp);
			let latamapp = (el.latamapprcp === '') ? [] : JSON.parse(el.latamapprcp);
			let naapp = (el.naapprcp === '') ? [] : JSON.parse(el.naapprcp);
			let requestcombine = [...apj, ...emea, ...latam, ...na];
			let appcombine = [...apjapp, ...emeaapp, ...latamapp, ...naapp];
			// delete child properties if there is no changes so it will avoid server trip 
			// if (requestcombine.length > 0) { el.requestedcapacity = JSON.stringify(requestcombine); } else { delete el.requestedcapacity; }
			// if (appcombine.length > 0) { el.approvedcapacity = JSON.stringify(appcombine); } else { delete el.approvedcapacity; }
			el.requestedcapacity = requestcombine.length > 0 ? JSON.stringify(requestcombine) : '';
			el.approvedcapacity = appcombine.length > 0 ? JSON.stringify(appcombine) : '';
		})
		return data;
	},
	cloneChild: function (cmp, evt, helper, parentId, parentunqid, obj) {
		cmp.set('v.isLoading', true);
		let regionList = JSON.parse(cmp.get('v.fieldMapping')).regionlabels.split(',');
		let regionResult = new Map();
		let bufferObj = [{ data: obj.apjcpAllocated, region: regionList[0] }, { data: obj.emeacpAllocated, region: regionList[1] },
		{ data: obj.latamcpAllocated, region: regionList[2] }, { data: obj.nacpAllocated, region: regionList[3] }];
		regionResult = helper.handleunsavedData(cmp, evt, helper, bufferObj, regionResult, parentunqid); // copy unsaved child data
		helper.handleServercall(cmp.get("c.getallocatedCapacity"), {
			parentId: parentId, region: regionList
		}).then(function (result) {
			if (result.length > 0) {
				result.forEach(el => {
					if (regionResult.has(el.region)) {
						regionResult.set(el.region, regionResult.get(el.region) + ',' + JSON.stringify(cmp.find("l2qcapacityallocation1").rowIntializer('', parentunqid, el.region, '', el.country, el.allocatedcapacity, '0')).replace(/\\/g, ""));
					} else {
						if (el.country !== null && el.country !== '' && el.country !== undefined) {
							regionResult.set(el.region, JSON.stringify(cmp.find("l2qcapacityallocation1").rowIntializer('', parentunqid, el.region, '', el.country, el.allocatedcapacity, '0')).replace(/\\/g, ""));
						}
					}
				})

			}
			helper.setcloneData(cmp, parentunqid, regionResult, regionList);
		}, function (error) {
			cmp.set('v.isLoading', false);
			helper.showToast(cmp, evt, helper, 'error', 'ERROR: ', JSON.stringify(error));
		})

	},
	handleunsavedData: function (cmp, evt, helper, obj, regionResult, parentunqid) {
		try {
			obj.forEach(el => {
				let temp = '';
				if (el.data !== '') {
					JSON.parse(el.data).forEach(ln => {
						temp = (ln.recordid === '') ? temp + ',' + JSON.stringify(cmp.find("l2qcapacityallocation1").rowIntializer('', parentunqid, ln.region, '', ln.country, ln.allocatedcapacity, '0')).replace(/\\/g, "") : temp;
					})
				}
				if (temp !== '') {
					temp = (temp.charAt(0) === ',') ? temp.replace(',', '') : temp;
					regionResult = (temp !== '') ? regionResult.set(el.region, temp) : regionResult;
				}
			})
		}
		catch (error) {
			console.log('error-message-data==' + error.message);
		}
		return regionResult;
	},
	setcloneData: function (cmp, parentunqid, mappdeData, regionList) {
		try {
			let data = cmp.get('v.data');
			let index = data.findIndex(el => {
				return el.uniqueKey === parentunqid;
			})
			if (index !== -1) {
				data[index].apjcpAllocated = mappdeData.has(regionList[0]) ? '[' + mappdeData.get(regionList[0]) + ']' : '';
				data[index].emeacpAllocated = mappdeData.has(regionList[1]) ? '[' + mappdeData.get(regionList[1]) + ']' : '';
				data[index].latamcpAllocated = mappdeData.has(regionList[2]) ? '[' + mappdeData.get(regionList[2]) + ']' : '';
				data[index].nacpAllocated = mappdeData.has(regionList[3]) ? '[' + mappdeData.get(regionList[3]) + ']' : '';
			}
			cmp.set('v.data', data);
			cmp.set('v.isLoading', false);
		}
		catch (error) {
			cmp.set('v.isLoading', false);
			//helper.showToast(cmp, evt, helper, 'error', 'ERROR: ', 'setcloneData-method-error->' + error.message);
		}

	},
	// this is default intializer for each region for child object || Wanted to normalize the data for child seprately
	intializeChild: function (cmp, evt, helper, obj) {
		obj.nacpAllocated = '';
		obj.latamcpAllocated = '';
		obj.emeacpAllocated = '';
		obj.apjcpAllocated = '';
		obj.naapprcp = '';
		obj.latamapprcp = '';
		obj.emeaapprcp = '';
		obj.apjapprcp = '';
		return obj;
	},
	// reset values
	handleapprovalReset: function (cmp, evt, helper) {
		let index = evt.currentTarget.dataset.id;
		let fieldApiname = evt.currentTarget.dataset.record;
		let tempData = cmp.get('v.data');
		let fieldIndex = tempData[index].fieldArray.findIndex(el => {
			return el.fieldapiName === fieldApiname;
		})
		let statusValue = '';
		tempData[index].fieldArray.forEach(el => {
			if (el.fieldapiName === 'Status__c') {
				statusValue = el.fieldapiValue;
			}
		})
		try {
			switch (fieldApiname) {
				case 'APJ_Approved_Capacity__c':
					tempData = helper.resetIndexvalue(cmp, evt, helper, tempData, index, fieldIndex, 'apjapprcp', statusValue);
					break;
				case 'EMEA_Approved_Capacity__c':
					tempData = helper.resetIndexvalue(cmp, evt, helper, tempData, index, fieldIndex, 'emeaapprcp', statusValue);
					break;
				case 'LATAM_Approved_Capacity__c':
					tempData = helper.resetIndexvalue(cmp, evt, helper, tempData, index, fieldIndex, 'latamapprcp', statusValue);
					break;
				case 'North_America_Approved_Capacity__c':
					tempData = helper.resetIndexvalue(cmp, evt, helper, tempData, index, fieldIndex, 'naapprcp', statusValue);
					break;
				default:
					break;
			}
			cmp.set('v.data', tempData);
		}
		catch (err) {
			console.log('handleapprovalReset-error-detail-' + err.message);
		}
	},
	resetIndexvalue: function (cmp, evt, helper, tempData, index, fieldIndex, propertyName, status) {
		let changedData = [];
		if (tempData[index][propertyName] !== '') {
			JSON.parse(tempData[index][propertyName]).forEach(el => {
				if (el.approvedcapacity !== '0') {
					el.approvedcapacity = '0';
				}
				changedData.push(el);
			})
			tempData[index].fieldArray[fieldIndex].fieldapiValue = (status === 'Closed - Approved' || status === 'Closed - Modified Approved') ? '0' : '';
			tempData[index][propertyName] = ''; //making property blank 
		}
		else {
			tempData[index].fieldArray[fieldIndex].fieldapiValue = (status === 'Closed - Approved' || status === 'Closed - Modified Approved') ? '0' : '';
		}
		return tempData;
	},
	//End  Rajesh Kumar | SFDC-7368
	// Added below function as part of  Rajesh Kumar - SFDC-7608
	filterClause: function (cmp, evt, helper, type, addFilter) {
		let baseFilter = ' and  Account__c = ' + "'" + cmp.get('v.parentaccount') + "'";
		if (addFilter != '' && addFilter != undefined && addFilter != null) {
			baseFilter = baseFilter + addFilter;
		}
		if (type === 'new') {
			cmp.set('v.whereClause', baseFilter + cmp.get('v.cfilter'));
		} else {
			cmp.set('v.whereClause', baseFilter);
		}
	}
});