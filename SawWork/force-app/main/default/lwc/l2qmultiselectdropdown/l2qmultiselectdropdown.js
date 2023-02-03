import { LightningElement, api, track } from 'lwc';
import { reduceErrors, isEmpty, returnErrormessage, checkerrtype, objectKeysToLowerCase } from 'c/l2QlwcUtil';

export default class L2qmultiselectdropdown extends LightningElement {
	@api choice = '';
	@api uniqueid;
	@api uniquestring;
	@api options = [];
	@track selectedOptions = '---None---';
	@track isAttributeRequired = false;
	@api fieldName;
	@api isMultiSelect;
	@api dropDownLength = 5;
	@api label;
	@api value = '';
	@track fieldLabelName;
	dependentOptions;
	@track isMouseOver;
	btnEvent;
	connectedCallback() {
		if (this.choice) {
			this.options = JSON.parse(JSON.stringify(this.choice));
		}
		let tempArray = this.value.split(';');
		let preSelect = '';
		this.options.map((el) => {
			if (tempArray.includes(el.label)) {
				el.isSelected = true;
				preSelect = preSelect + ';' + el.label;
			}
		});
		if (!isEmpty(preSelect)) {
			this.selectedOptions = preSelect.slice(1);
		}
		this.isMultiSelect = true;
	}
	selectionChangeHandler(event) {
		this.dispatchEvent(new CustomEvent('selected', { detail: event.target.value }));
	}

	get multiSelectClassAttr() {
		return this.isMultiSelect ? 'slds-dropdown__list slds-dropdown--length-' + this.dropDownLength : '';
	}

	get mainDivClassAttr() {
		return this.isMouseOver
			? 'slds-picklist slds-dropdown-trigger slds-dropdown-trigger--click slds-is-open'
			: 'slds-picklist slds-dropdown-trigger slds-dropdown-trigger--click';
	}
	handleMouseEnter(event) {
		this.btnEvent = event;
		this.isMouseOver = true;
	}

	handleMouseLeave() {
		this.isMouseOver = false;
	}
	handleSelection(event) {
		let tickedOptions = '';
		const selectedLabel = event.target.label;
		const selectedValue = event.target.checked;
		if (this.options) {
			this.options.forEach(function(option) {
				if (option.label === selectedLabel) {
					option.isSelected = selectedValue;
				}
			});
			this.options.forEach(function(option) {
				if (option.isSelected) {
					tickedOptions += option.label + ';';
				}
			});
			this.selectedOptions = tickedOptions.slice(0, -1);
		}
		if (!this.selectedOptions) {
			this.selectedOptions = '---None---';
		}
		//alert(this.selectedOptions);
		const selectedRecordEvent = new CustomEvent('select', {
			detail: {
				selectedValue: this.selectedOptions == '---None---' ? '' : this.selectedOptions,
				uniqueid: this.uniqueid,
				uniquestring: this.uniquestring
			}
		});
		this.dispatchEvent(selectedRecordEvent);
	}
}