/***
 * Author : Rajesh Kumar 
 * JIRA : # 6406
 * Description : Re-usable component for finding picklist value based on recordtype
 * API Specification => input/output param : objectApiname;objrecordtypeId;fieldapiName ; value; cssStyle; isrequired ; labelName ;errorMessage;
 */
import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { isEmpty } from 'c/l2QlwcUtil';

export default class L2QSobjectPicklistbyRecordType extends LightningElement {
	/*Begin Component API Specification */
	@api objectApiname = '';
	@api objrecordtypeId = '';
	@api fieldapiName = '';
	@api value = '';
	@api cssStyle = '';
	@api isrequired = false;
	@api labelName = '';
	@api errorMessage;
	/*End Component API Specification */

	@track options;
	@track noneLabel = [ { attributes: null, label: '--None--', validFor: [], value: '' } ];
	@track error;
	@track objName;
	@track rtypeId;

	constructor() {
		super();
		this.options = this.noneLabel;
		//If there is no predifned value for picklist then assign blank value
		if (isEmpty(this.value)) {
			this.value = '';
		}
	}
	connectedCallback() {}
	//get default trecordtype if not passed
	@wire(getObjectInfo, { objectApiName: '$objectApiname' })
	objectInfofunc({ error, data }) {
		if (data) {
			console.log('rtypeData=>' + JSON.stringify(data));
			const dfrtid = data.defaultRecordTypeId;
			console.log('dfrtid==>' + dfrtid);
			if (isEmpty(this.objrecordtypeId)) {
				this.rtypeId = dfrtid;
			} else {
				this.rtypeId = this.objrecordtypeId;
			}
			this.objName = this.objectApiname;
			this.error = undefined;
			console.log('rtypeId==>' + this.rtypeId);
		}
		if (error) {
			console.log('rtypeErrorData=>' + JSON.stringify(error));
			this.options = this.noneLabel;
			this.rtypeId = undefined;
			this.error = error;
			this.value = '';
		}
	}
	// wire adpater to fetch record this is immutable stream of data so be aware to make shallow copy read more : https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.data_wire_service_about
	@wire(getPicklistValuesByRecordType, { objectApiName: '$objName', recordTypeId: '$rtypeId' })
	PicklistValues({ error, data }) {
		if (data) {
			let tempArr = [];
			console.log('rtypeData>=>' + JSON.stringify(data));
			this.options = data.picklistFieldValues[this.fieldapiName].values; //option
			this.options = [ ...this.noneLabel, ...this.options ];
			this.error = undefined;
			this.options.forEach((el) => tempArr.push(el.value));
			console.log('tempArr=>' + tempArr);
			console.log('val' + tempArr.includes(this.value));
			if (tempArr.includes(this.value)) {
				// sometime if picklist value is avaliable but not defined for recordtype or deactivated then it does not shpw any value
			} else {
				this.value = '';
			}
		}
		if (error) {
			console.log('rtypeErrorData>=>' + JSON.stringify(error));
			this.options = this.noneLabel;
			this.value = '';
			this.error = error;
		}
	}
	//handle the data change and dispatch event based on selection
	handleChange(event) {
		this.value = event.target.value;
		const selectedEvent = new CustomEvent('valueselect', { detail: { selectedValue: this.value } });
		this.dispatchEvent(selectedEvent);
		const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.value);
		this.dispatchEvent(attributeChangeEvent);
	}
	//Hook to Flow's Validation engine if valid then true else false
	@api
	validate() {
		if (this.isrequired && isEmpty(this.value)) {
			return { isValid: false, errorMessage: this.errorMessage };
		}
		return {
			isValid: true,
			errorMessage: ''
		};
	}
}