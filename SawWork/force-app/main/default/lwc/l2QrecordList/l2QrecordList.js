import { LightningElement, api } from 'lwc';
import LANG from '@salesforce/i18n/lang';

export default class L2QrecordList extends LightningElement {
	/* Begin Component API variables */
	@api record;
	@api searchfieldname;
	@api iconname;
	/* End Component API variables */
	/* Begin Component Local Variables */
	propCheck = [];
	iconsize = 'small';
	/* End Component Local Variables */
	connectedCallback() {
		for (var prop in this.record) {
			if (prop.toLowerCase() == 'id' || prop.toLowerCase() == this.searchfieldname.toLowerCase()) {
			} else {
				this.propCheck.push(this.record[prop]);
			}
		}
		if (this.propCheck.length > 0) {
			this.iconsize = 'medium';
		} else {
			this.iconsize = 'small';
		}
	}
	handleSelect(event) {
		event.preventDefault();
		const selectedRecord = new CustomEvent('select', {
			detail: this.record.Id
		});
		this.dispatchEvent(selectedRecord);
	}
}