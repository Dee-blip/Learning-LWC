/* 
Author:Rajesh Kumar -GSM Team
JIRA #: SFDC-6776
Description: This component serves the purpose of record selection in tabular format specially designed for flow can be used at other places as well
@todo : Error Message when no row found
*/
import { LightningElement, track, wire, api } from 'lwc';
import getrequiredRecords from '@salesforce/apex/L2Q_PartnerFlowController.findRecords';
import getColumnheader from '@salesforce/apex/L2Q_PartnerFlowController.getColumnheader';
import loadMore from '@salesforce/apex/L2Q_PartnerFlowController.loadMore';
import { reduceErrors, isEmpty, returnErrormessage, checkerrtype, objectKeysToLowerCase } from 'c/l2QlwcUtil';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertErrorlog from '@salesforce/apex/L2Q_PartnerFlowController.insertErrorlog';

export default class L2q_flowrecordselection extends LightningElement {
	/**Begin API Specification */
	@api selectedRecordid = '';
	@api selectedRecordname = '';
	@api initialRows = 20;
	@api objectapi = '';
	@api matchingrowsMessage = 'MATCHING RECORDS : ';
	@api metadatforCoulmnheader = '';
	@api errormessaagewhennoRecordselect = 'Please select a record to proceed further.';
	@api filterCondition = ' ';
	@api ldsstyleCss = 'height:500px';
	@api recordselectionRequired;
	@api intialLoadorder = ' order by lastmodifieddate desc ';
	/**End API Specification */
	fieldset = '';
	prefixNavigator = '/';
	selectedRecords;
	columns = [];
	rowNumberOffset = 0;
	error;
	cusError = { body: { message: '' } };
	data;
	maxRow = 1;
	isloading = true;
	isdataloading = false;
	totalNumberOfRows;
	enableInfiniteLoading = false;
	loadmoreoffset = 1;
	currentCount;
	rowsToLoad;
	// sorting parameters
	sortedBy;
	sortedDirection;
	isclassicMode = false;
	isclassicError = false;
	connectedCallback() {
		this.rowsToLoad = this.initialRows;
		this.currentCount = 0;
		this.isdataloading = true;
		this.getColumn();
	}
	//handles row selection based on record id
	onrowselect(event) {
		let record = event.detail.selectedRows;
		record.forEach((rec) => {
			this.selectedRecordid = rec.Id;
			this.selectedRecordname = rec.Name;
		});
		this.dispatchSelecteddata(this.selectedRecordid, this.selectedRecordname);
	}
	// function to set the column from metadata using server call
	getColumn() {
		let selectFields = ' ';
		getColumnheader({ headerMetadata: this.metadatforCoulmnheader })
			.then((result) => {
				console.log('result cl header >> ' + JSON.stringify(result));
				//get column from metadata and it will not have any blank value ...so there should not been any error
				this.columns = JSON.parse(result.coulmnHeader);
				this.columns.forEach((el) => {
					if (el.hasOwnProperty('fieldapiname')) {
						selectFields = selectFields + ',' + el.fieldapiname;
					}
				});
				this.fieldset = selectFields;
				console.log('this.fieldset' + this.fieldset);
				if (result.usertype.includes('partner')) {
					this.isclassicMode = false;
					this.prefixNavigator = '/partners/';
				} else {
					if (result.uiThemedisplayed == 'theme3') {
						this.isclassicMode = true;
					} else {
						this.isclassicMode = false;
					}
				}
				this.getData();
			})
			.catch((error) => {
				this.isloading = false;
			});
	}
	// function to get the all Data
	getData() {
		let attribute = {
			objectName: this.objectapi,
			fieldset: this.fieldset,
			recordOffset: parseInt(this.rowNumberOffset),
			recordLimit: parseInt(this.initialRows),
			whereClause: this.filterCondition,
			orderBy: this.intialLoadorder
		};
		getrequiredRecords(attribute)
			.then((result) => {
				console.log('result data  >> ' + JSON.stringify(result));
				this.totalNumberOfRows = result.recordCount;
				this.data = this.formatData(result.records);
				this.currentCount = this.initialRows;
				this.isloading = false;
				this.enableInfiniteLoading = true;
				if (!isEmpty(this.selectedRecordid)) {
					this.selectedRecords = [ this.selectedRecordid ];
				}
				this.isclassicError = false;
			})
			.catch((error) => {
				this.handleError(error);
			});
	}
	//handling load more event
	loadMore() {
		if (this.data.length >= this.totalNumberOfRows) {
			this.enableInfiniteLoading = false;
			if (this.totalNumberOfRows > this.rowsToLoad) {
				this.template.querySelector('[data-id="loadWarningId"]').classList.add('slds-show');
				this.template.querySelector('[data-id="loadWarningId"]').classList.remove('slds-hide');
			}
			//web api to hide no more data text once displayed for 8 sec ..
			var self = this;
			setTimeout(() => {
				self.template.querySelector('[data-id="loadWarningId"]').classList.add('slds-hide');
				self.template.querySelector('[data-id="loadWarningId"]').classList.remove('slds-show');
			}, 8000);
		} else {
			let recordOffset = parseInt(this.currentCount);
			let recordLimit = parseInt(this.initialRows);
			let attribute = {
				objectName: this.objectapi,
				fieldset: this.fieldset,
				recordOffset: parseInt(recordOffset),
				recordLimit: parseInt(recordLimit),
				whereClause: this.filterCondition,
				orderBy: this.intialLoadorder
			};
			this.template.querySelector('[data-id="loadingId"]').classList.add('slds-show');
			this.template.querySelector('[data-id="loadingId"]').classList.remove('slds-hide');
			loadMore(attribute)
				.then((result) => {
					console.log('result load more  >> ' + JSON.stringify(result.records));
					this.data = this.data.concat(this.formatData(result.records));
					this.template.querySelector('[data-id="loadingId"]').classList.remove('slds-show');
					this.template.querySelector('[data-id="loadingId"]').classList.add('slds-hide');
					recordOffset = parseInt(recordOffset) + parseInt(recordLimit);
					this.currentCount = recordOffset;
					if (!isEmpty(this.selectedRecordid)) {
						this.selectedRecords = [ this.selectedRecordid ];
					}
					this.isclassicError = false;
				})
				.catch((error) => {
					this.handleError(error);
				});
		}
	}

	//function to convert nested string property and return value for nested property ..i.e owner.profile.name will be resolved and value would be returned
	getDescendantProp(obj, desc) {
		obj = objectKeysToLowerCase(obj);
		desc = desc.toLowerCase();
		var arr = desc.split('.');
		while (arr.length && (obj = obj[arr.shift()]));
		return obj;
	}
	// formatData methods formats the record based on target id for a link also checks if field type is url
	formatData = (records) => {
		let columnMap = new Map();
		this.columns.forEach((element) => {
			if (element.hasOwnProperty('relatedorlink')) {
				// checks if data has relatedorlink property then based on that it assigns target after hyperlink click
				columnMap.set(element.fieldName, element);
			}
		});
		records.map((row) => {
			if (columnMap.size > 0) {
				for (let key of columnMap.keys()) {
					if (columnMap.get(key).type == 'url') {
						console.log('columnMap.get(key)++' + JSON.stringify(columnMap.get(key)));
						row[key] =
							this.prefixNavigator +
							this.getDescendantProp(row, columnMap.get(key).typeAttributes.targetId);
						row[columnMap.get(key).typeAttributes.label.fieldName] = this.getDescendantProp(
							row,
							columnMap.get(key).typeAttributes.targetlabel
						);
					} else {
						row[key] = this.getDescendantProp(row, columnMap.get(key).typeAttributes.targetlabel);
					}
				}
			}
		});
		return records;
	};

	// The method onsort event handler
	updateColumnSorting(event) {
		let fieldName = event.detail.fieldName;
		let sortDirection = event.detail.sortDirection;
		// assign the latest attribute with the sorted column fieldName and sorted direction
		this.sortedBy = fieldName;
		this.sortedDirection = sortDirection;
		console.log('Sort fieldName: ' + fieldName);
		console.log('sort direction: ' + sortDirection);
		let reverse = sortDirection !== 'asc';
		let data_clone = JSON.parse(JSON.stringify(this.data));
		console.log('BEFORE data_clone:' + JSON.stringify(data_clone));
		this.data = data_clone.sort(this.sortBy(fieldName, reverse));
		console.log('AFTER data_clone:' + JSON.stringify(data_clone));
	}
	sortBy(field, reverse, primer) {
		var key = primer
			? function(x) {
					return primer(
						x.hasOwnProperty(field)
							? typeof x[field] === 'string' ? x[field].toLowerCase() : x[field] //check field property of string type which handles lower and upper case
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
	// Hook to Flow's Validation engine if valid then true else false
	@api
	validate() {
		if (isEmpty(this.selectedRecordid) && this.recordselectionRequired == true) {
			return { isValid: false, errorMessage: this.errormessaagewhennoRecordselect };
		} else {
			return {
				isValid: true
			};
		}
	}

	showToast(title, message, variant, mode) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant,
				mode: mode
			})
		);
	}
	hideclassicError() {
		this.isclassicError = false;
	}
	// check if it's custom exception thrown in code else keep existing error
	handleError = (error) => {
		this.isloading = false;
		console.log('Error Details  >>' + JSON.stringify(error));
		if (checkerrtype(error)) {
			let errorDetail = JSON.parse(error.body.message);
			this.cusError.body.message = errorDetail.userMessage;
			this.loggingError(errorDetail.errName, errorDetail.errorsourceName, errorDetail.errorMessage);
		} else {
			this.cusError = error;
		}
		this.error = returnErrormessage(this.cusError);
		if (this.isclassicMode) {
			this.isclassicError = true;
		} else {
			this.showToast('Error', returnErrormessage(this.cusError), 'error', 'sticky');
		}
	};

	// async code to insert logs based on exception this utilizes UI/API
	loggingError = (logname, logclass, logmessage) => {
		const recordInput = { logname: logname, logclass: logclass, logmessage: logmessage };
		insertErrorlog(recordInput).then((result) => {}).catch((error) => {
			console.log('Error inserting log : ' + JSON.stringify(error));
		});
	};
	dispatchSelecteddata(recId, recName) {
		const selectedEvent = new CustomEvent('select', { detail: { recordid: recId, recordname: recName } });
		this.dispatchEvent(selectedEvent);
	}
}