import { LightningElement, api } from 'lwc';
import { reduceErrors } from 'c/l2QlwcUtil';

export default class L2QerrorPanel extends LightningElement {
	@api friendlyMessage = 'Error Searching Data.';
	@api errors;
	viewDetails = false;
	connectedCallback() {}
	get errorMessages() {
		return reduceErrors(this.errors);
	}
	handleCheckboxChange(event) {
		this.viewDetails = event.target.checked;
	}
	renderedCallback() {}
}