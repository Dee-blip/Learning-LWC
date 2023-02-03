({
	doInit: function (cmp, evt, helper) {
		var pageRef;
		//var whereClause; // Commented as part of SFDC-7608
		cmp.set("v.isLoading", true);
		pageRef = cmp.get("v.pageReference");
		cmp.set("v.recordId", pageRef.state.c__recordId);
		cmp.set("v.header", pageRef.state.c__header);
		cmp.set("v.isLoading", true);
		cmp.set("v.hrWidth", "width:" + window.innerWidth + "px");
		//whereClause = " and  Account__c = " + "'" + pageRef.state.c__recordId + "'"; // code insight notification
		cmp.set('v.parentaccount', pageRef.state.c__recordId); // Added as part of SFDC-7608
		helper
			.handleServercall(cmp.get("c.checkAcessandbuildschema"), {
				parentId: cmp.get("v.recordId")
			})
			.then(
				function (res) {
					cmp.set("v.nullclonefield", res.nullclonefield); // SFDC-7368
					cmp.set("v.fieldMapping", res.fieldlabelMapping); // SFDC-7368
					cmp.set("v.countrysplitreadStatus", res.countrysplitreadStatus);// SFDC-7368
					cmp.set("v.timeZone", res.timeZone);
					cmp.set("v.ismetadataLoaded", true);
					cmp.set("v.schemaDetails", res.schemaData);
					cmp.set("v.queryFields", res.fieldSet);
					cmp.set("v.objName", res.objName);
					cmp.set("v.schemaMap", helper.objtoMap(cmp.get("v.schemaDetails")));
					cmp.set("v.recordLimit", res.recordLimit);
					cmp.set("v.scrollrecordLimit", res.maxrecordCreation);
					cmp.set("v.orderby", res.orderby);
					cmp.set("v.uomfd", res.uomfd);
					cmp.set("v.renderslide", true); // Added as part of SFDC-7608
					cmp.set("v.readonlyStatus", res.readonlyStatuscondition);
					//cmp.set("v.whereClause", whereClause + res.filter);
					cmp.set('v.cfilter', res.filter); // Added as part of SFDC-7608
					helper.filterClause(cmp, evt, helper, 'new', ''); // Added as part of SFDC-7608
					cmp.set("v.approvedFieldenabled", res.approvedFieldenabled); //Modifier Rajesh Kumar SFDC-7069
					if (
						res.cpheader !== null &&
						res.cpheader !== undefined &&
						res.cpheader !== ""
					) {
						let headerString = res.cpheader.split("#");
						cmp.set("v.timeZoneheader", headerString[0]);
						cmp.set("v.f2bheaderheader", headerString[1]);
					}
					helper.retrieveData(cmp, evt, helper, '');
				},
				function (rej) {
					cmp.set("v.isLoading", false);
					helper.showToast(cmp, evt, helper, "error", "ERROR: ", JSON.stringify(rej));
				}
			);
	},
	addRow: function (cmp, evt, helper) {
		if (cmp.get("v.data").length >= cmp.get("v.recordLimit")) {
			helper.showToast(cmp, evt, helper, "error", "ERROR: ", "More than " + cmp.get("v.recordLimit") + " records is not allowed in current scroll.");
			return;
		}
		let el = cmp.find("scData").getElement();
		el.scrollTop = el.scrollHeight;
		let arr = [];
		let dt = cmp.get("v.data");
		arr.push(helper.rowIntializer(cmp, evt, helper));
		cmp.set("v.data", dt.concat(arr));
	},
	// handle change for delivery product and same function can be used based on metadata in future
	handleChange: function (cmp, evt) {
		// let appValue = cmp.get('v.nullclonefield').split(','); // Code Insight Commented
		let tempData = cmp.get("v.data");
		let fd = cmp.get("v.uomfd").split("#");
		let fdValue = fd[1].split(";");
		var index = parseInt(evt.getSource().get("v.label"), 10); // use radix with parse int code insight
		var fldName = evt.getSource().get("v.name");
		var fldValue = evt.getSource().get("v.value");
		var mp = new Map();
		tempData[index].fieldArray.forEach((el) => {
			mp.set(el.fieldapiName, el);
		});
		if (fldName === fd[2]) {
			// if source of change id delivery product
			tempData[index].fieldArray.map(function (el) {
				//if (el.fieldapiName == fd[3] && fd[0].includes(fldValue)) {
				if (el.fieldapiName === fd[3] && fd[0].split(";")[0] === fldValue) { // Rajesh SFDC-7352 Commented above
					el.fieldapiValue = fdValue[0];
					el.readonly = true;
					return null;
				}
				// Begin Rajesh -  SFDC-7352
				else if (el.fieldapiName === fd[3] && (fd[0].split(";")[1] === fldValue || fd[0].split(";")[2] === fldValue)) {
					el.readonly = false;
					return null;
				}
				// End Rajesh -  SFDC-7352
				else if (el.fieldapiName === fd[3] && !fd[0].includes(fldValue)) {
					el.fieldapiValue = fdValue[1];
					el.readonly = true;
				} else {
					console.log('test');
				}
			});
		}
		cmp.set("v.data", tempData);
	},
	//below methods handles vertical scroll event.. on click of add row it puts scroll position to bottom most row.
	handleverticalScroll: function (cmp, evt) {
		let area = cmp.find("scData").getElement();
		let threshold = 2 * evt.target.clientHeight;
		let areaHeight = area.clientHeight;
		let scrollTop = evt.target.scrollTop;
		if (areaHeight - threshold < scrollTop) { }
	},
	// handles horizontal scroll to keep child element intact
	handleScroll: function (cmp, evt) {
		var el = evt.currentTarget.scrollWidth;
		cmp.set("v.hrWidth", "width:" + el + "px");
	},
	// delete current  buffer row for uncommited record
	deleteRow: function (cmp, evt) {
		var index = evt.currentTarget.dataset.record;
		let tempData = cmp.get("v.data");
		var isdelete = confirm("Are you sure you want to delete this record ?"); //es-lint rule to bex fixed
		if (isdelete) {
			tempData.splice(index, 1);
			cmp.set("v.data", tempData);
		}
	},
	// cloning the record from existing one and disable readonly for closed one
	cloneRecord: function (cmp, evt, helper) {
		if (cmp.get("v.data").length >= cmp.get("v.recordLimit")) {
			helper.showToast(cmp, evt, helper, "error", "ERROR: ", "More than " + cmp.get("v.recordLimit") + " records is not allowed in current scroll.");
			return null; //es - lint
		}
		let index = evt.currentTarget.dataset.record;
		let arrayObj = cmp.get("v.data");
		let obj = arrayObj[index];
		let newObj = JSON.parse(JSON.stringify(arrayObj[index]));
		// Begin Rajesh -  SFDC-7352
		let mp = new Map();
		newObj.fieldArray.forEach(function (el) {
			mp.set(el.fieldapiName, el);
		});
		// End Rajesh -  SFDC-7352
		newObj.uniqueKey = helper.generateUniquenumber();
		newObj.recordId = "";
		newObj = helper.intializeChild(cmp, evt, helper, newObj); // Rajesh - SFDC-7368
		let appValue = cmp.get('v.nullclonefield').split(',');
		newObj.fieldArray.map(function (el) {
			//while cloing make staus pending and approval number field 0 other field copy as it is
			el.fieldapiValue = (el.fieldapiName === "Status__c") ? "Pending" : (appValue.includes(el.fieldapiName) ? null : el.fieldapiValue);
			el.readonly = el.fieldapiName === "Unit_of_Measure__c" && !(mp.get("Delivery_Product__c").fieldapiValue === "Ion" || mp.get("Delivery_Product__c").fieldapiValue === "DSA") ? true : false;
		});
		arrayObj.splice(parseInt(index, 10) + 1, 0, newObj); // es-lint code insight
		cmp.set("v.data", arrayObj);
		helper.cloneChild(cmp, evt, helper, obj.recordId, newObj.uniqueKey, obj);// Rajesh - SFDC-7368
		return null; // code insight error es-lint
	},
	// saving the record and reload the saved data
	saveData: function (cmp, evt, helper) {
		if (helper.dataValidator(cmp, evt, helper, cmp.get("v.data"))) {
			let sendData = helper.comparetwonestedArrays(cmp, evt, helper, cmp.get("v.data"), cmp.get("v.scrollData"));
			if (sendData.length === 0) { //ese-lint code insight
				helper.showToast(cmp, evt, helper, "info", "WARNING: ", "There are no changes found to be saved.");
				return;
			}
			sendData = helper.concatenateChangedarray(cmp, evt, helper, sendData); // Rajesh - SFDC-7368
			let serverData = JSON.stringify(sendData);
			cmp.set("v.isLoading", true);
			helper.filterClause(cmp, evt, helper, (cmp.get('v.ishistoricalMode') === true ? 'old' : 'new'), ''); // Rajesh Kumar - SFDC-7608
			try { cmp.find("cprslider").clearFilter() } catch (err) { } // Rajesh Kumar - SFDC-7608
			helper.handleServercall(cmp.get("c.saveRecords"), { jsonData: serverData, objName: cmp.get("v.objName"), parentId: cmp.get("v.recordId") })
				.then(
					function (res) {
						console.log('res::::' + res);
						helper.retrieveData(cmp, evt, helper);
						helper.showToast(cmp, evt, helper, "success", "SUCCESS: ", "Records have been saved successfully!");
					},
					function (rej) {
						let errMessage = JSON.stringify(rej);
						let rowNum;
						if (errMessage.includes("CPR_ERROR_UNIQUEID") || errMessage.includes('CPR_ERROR_REQUEST_ALLOCATION_UNIQUEID') || errMessage.includes('CPR_ERROR_APPROVE_ALLOCATION_UNIQUEID')) {
							let errArr = errMessage.split(">>>##>>>");
							let uniqueId = errArr[0].split(":")[1];
							cmp.get("v.data").forEach(function (el, index) {
								if (JSON.stringify(el.uniqueKey).trim() === JSON.stringify(uniqueId).trim()) { // es-lint code insight 
									rowNum = index + 1;
								}
							});
							helper.showToast(cmp, evt, helper, "error", "ERROR AT ROW NO : " + rowNum, "DETAIL : " + errArr[1].replace('"', ""));
						} else {
							helper.showToast(cmp, evt, helper, "error", "ERROR: ", JSON.stringify(rej));
						}
						cmp.set("v.isLoading", false);
					}
				);
		}
	},
	// handle multi picklist record select operation
	handleSelect: function (cmp, evt) {
		var selectedValue = evt.getParam("selectedValue");
		var index0 = evt.getParam("uniqueid");
		var fieldName = evt.getParam("uniquestring");
		var tempdata = cmp.get("v.data");
		tempdata[index0].fieldArray.map(function (el) { //es-lint validate multiselect 
			if (el.fieldapiName === fieldName) { // es-lint 
				el.fieldapiValue = selectedValue;
			}
		});
		cmp.set("v.data", tempdata);
	},
	navigatetoRecord: function (cmp, evt, helper) {
		helper.navigatetoRecorddetail(cmp, evt, helper, cmp.get("v.recordId"));
	},
	handlerecordClick: function (cmp, evt, helper) {
		var recId = evt.currentTarget.dataset.record;
		helper.navigatetoRecorddetail(cmp, evt, helper, recId);
	},
	// calculating the width for column
	calculateWidth: function (component, event) { //ese-lint code insight remove helper 
		try {
			let childObj = event.target; // es-lint code insight | verify scroll is working fine 
			let mouseStart = event.clientX;
			component.set("v.currentEle", childObj);
			component.set("v.mouseStart", mouseStart);
			// Stop text selection event so mouse move event works perfectlly.
			if (event.stopPropagation) event.stopPropagation();
			if (event.preventDefault) event.preventDefault();
			event.cancelBubble = true;
			event.returnValue = false;
		} catch (err) {
			console.log('calculate width error==' + err.message); // es-lint removed alert code insight 
		}
	},

	handledecimalChange: function (cmp, evt) { // es-lint code insight | Verify decimal changes is working as expected
		var val = evt.getSource().get("v.value");
		try {
			// var val = evt.getSource().get("v.value"); 
			if (val !== undefined && val !== null && val !== "" && val !== "undefined") {
				evt.getSource().set("v.value", val.match(/^\d+\.?\d{0,3}/)[0]);
			}
		} catch (error) {
			console.log('handle-decimal-change-error->' + error.message);
		}
	},
	//Begin Rajesh - SFDC-7368
	// function to handle row level edit for request allocation and request approval
	handleEdit: function (cmp, evt, helper) { // es-lint verify record edit is working as expected 
		try {
			let mappingData = JSON.parse(cmp.get('v.fieldMapping'));
			let regionList = mappingData.regionlabels.split(',');
			let regionMap = helper.returLabelmapping(cmp, evt, helper, mappingData.mapping);
			let parentuniqueid = evt.currentTarget.dataset.id;
			let region = regionMap.get(evt.currentTarget.dataset.record);
			cmp.set('v.forapproval', region.isapprovalfield);
			let data = cmp.get('v.data');
			let index = data.findIndex(el => { return el.uniqueKey === parentuniqueid; });
			let cprName = '';
			let status = '';
			data[index].fieldArray.forEach(el => { if (el.fieldapiName === 'Name') { cprName = el.fieldapiValue; } if (el.fieldapiName === 'Status__c') { status = el.fieldapiValue; } });
			cmp.set('v.cprName', cprName);
			cmp.set('v.status', status);
			let allocatedCapacity = []; // es-lint fixes
			allocatedCapacity = (!region.isapprovalfield) ? ((region.label === regionList[0])) ? data[index].apjcpAllocated : ((region.label === regionList[1]) ? data[index].emeacpAllocated : ((region.label === regionList[2]) ? data[index].latamcpAllocated : ((region.label === regionList[3]) ? data[index].nacpAllocated : []))) : ((region.label === regionList[0])) ? data[index].apjapprcp : ((region.label === regionList[1]) ? data[index].emeaapprcp : ((region.label === regionList[2]) ? data[index].latamapprcp : ((region.label === regionList[3]) ? data[index].naapprcp : [])));
			cmp.set('v.allocatedCapacity', allocatedCapacity);
			cmp.set('v.region', region.label);
			cmp.set('v.parentrecid', evt.currentTarget.dataset.parent);
			cmp.set('v.parentuniqueid', parentuniqueid);
			cmp.set("v.isModalOpen", true);
		} catch (error) {
			helper.showToast(cmp, evt, helper, "error", "ERROR: ", 'handleEdit-error->' + error.message);
		}
	},
	closeModel: function (cmp) {
		cmp.set("v.isModalOpen", false);
	},
	updateRecords: function (cmp) {
		cmp.find("l2qcapacityallocation").updateRecord();
	},
	addallocations: function (cmp) {
		cmp.find("l2qcapacityallocation").addallocations();
	},
	handlecprAllocation: function (cmp, evt, helper) {
		try {
			let mappingData = JSON.parse(cmp.get('v.fieldMapping'));
			let requestregionMap = helper.returLabelmapping(cmp, evt, helper, mappingData.requestmapping);
			let approvedregionMap = helper.returLabelmapping(cmp, evt, helper, mappingData.approvedmapping);
			let regionList = mappingData.regionlabels.split(',');
			let evtDetail = evt.getParam('response');
			let recuniqueId = evtDetail.parentunqid;
			let region = evtDetail.region;
			let totalSum = evtDetail.sum;
			let forapproval = evtDetail.forapproval;
			let bufferData = cmp.get('v.data');
			let childval = evtDetail.childval.replace(/\\/g, '');
			//alert('evtDetail.childval==' + evtDetail.childval); // to be removed 
			let rowIndex = bufferData.findIndex(el => { return el.uniqueKey === recuniqueId; })
			let fieldIndex = bufferData[rowIndex].fieldArray.findIndex(el => { return el.fieldapiName === ((forapproval) ? approvedregionMap.get(region).label : requestregionMap.get(region).label); })
			bufferData[rowIndex].fieldArray[fieldIndex].fieldapiValue = totalSum;
			let reqmap = new Map();
			let apprmap = new Map();
			"apjcpAllocated,emeacpAllocated,latamcpAllocated,nacpAllocated".split(',').forEach((el, index) => { reqmap.set(regionList[index], el); })
			"apjapprcp,emeaapprcp,latamapprcp,naapprcp".split(',').forEach((el, index) => { apprmap.set(regionList[index], el); })
			if (forapproval) {
				bufferData[rowIndex][apprmap.get(region)] = childval.replace(/\\/g, "");  // this will not have null
			}
			else {
				bufferData[rowIndex][reqmap.get(region)] = childval.replace(/\\/g, ""); // this will not have null
			}
			cmp.set('v.data', bufferData);
			cmp.set('v.isModalOpen', false);
		} catch (err) {
			console.log('handlecprAllocation error=>' + err.message);
		}
	},

	handleApproval: function (cmp) {
		cmp.find("l2qcapacityallocation").handleApproval();
	},
	handleReset: function (cmp, evt, helper) {
		helper.handleapprovalReset(cmp, evt, helper);
	},

	//End Rajesh - SFDC-7368

	// Begin Rajesh Kumar SFDC-7608
	handleFilter: function (cmp, evt, helper) {
		var selectedValue = evt.getParam("searchmode");
		var filter = evt.getParam("filter");
		// alert('filter++' + filter);
		cmp.set('v.ishistoricalMode', selectedValue);
		if (selectedValue) {
			helper.filterClause(cmp, evt, helper, 'old', filter);
			helper.retrieveData(cmp, evt, helper, 'pre');
		}
		else {
			helper.filterClause(cmp, evt, helper, 'new', filter);
			helper.retrieveData(cmp, evt, helper, 'pre');
		}
	}
	// End Rajesh Kumar SFDC-7608
});