import { LightningElement, api, track } from 'lwc';
import findRecords from '@salesforce/apex/HD_Custom_lookup_Controller.findRecords';


export default class HdLookup extends LightningElement {
    @track records;
    error;
    @api selectedRecord;
    @api index;
    @api searchPlaceholder;
    @api metadataFields = '';
    @api relationshipfield;
    @api iconname = "standard:account";
    @api objectName = 'Account';
    @api searchField = 'Name';
    @api useToolingApi = false;
    @api additionalFilters = '';
    @api showDropdown = false;
    @api showObjectList = false;
    @api supportedObjects;
    @api recordRetrieveLimit;
    isLookupFocused;
    searchKey;
    selectedRecordValue;
    isLoading;

    handleOnchange(event) {
        //event.preventDefault();
        this.searchKey = event.detail.value;
        this.isLookupFocused = true;
        this.isLoading = true;
        /* Call the Salesforce Apex class method to find the Records */
        findRecords({
            searchParams: JSON.stringify({
                searchKey: this.searchKey,
                fields: this.metadataFields,
                objectName: this.objectName,
                searchField: this.searchField,
                additionalFilters: this.additionalFilters,
                recordRetrieveLimit: this.recordRetrieveLimit
            })
        })
            .then(result => {
                this.records = result;
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('recordsretrieved', {
                    bubbles: true,
                    composed: true,
                    detail: this.records
                }));
            })
            .catch(error => {
                this.isLoading = false;
                this.error = error;
                this.records = undefined;
            });
    }

    connectedCallback() {
        if (this.supportedObjects && this.supportedObjects.length > 0) {
            /* eslint-disable-next-line */
            this.objectName = this.supportedObjects[0].value;
            /* eslint-disable-next-line */
            this.iconname = this.supportedObjects[0].objectIcon;
            /* eslint-disable-next-line */
            this.metadataFields = this.supportedObjects[0].metadataFields;
            /* eslint-disable-next-line */
            this.additionalFilters = this.supportedObjects[0].additionalFilters;
            /* eslint-disable-next-line */
            this.searchField = this.supportedObjects[0].searchField;
            /* eslint-disable-next-line */
            this.metadataFields = this.supportedObjects[0].metadataFields;
            /* eslint-disable-next-line */
            this.recordRetrieveLimit = this.supportedObjects[0].recordRetrieveLimit;
            /* eslint-disable-next-line */
            this.searchPlaceholder = 'Search ' + this.supportedObjects[0].label + 's';
        }
    }

    handleSelect(event) {
        const selectedRecordId = event.detail;
        /* eslint-disable no-console*/
        this.selectedRecord = this.records.find(record => record.Id === selectedRecordId);
        this.selectedRecordValue = this.getFieldValue();
        /* fire the event with the value of RecordId for the Selected RecordId */
        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                //detail : selectedRecordId
                detail: { value: selectedRecordId }
            }
        );
        this.isLookupFocused = true;
        this.dispatchEvent(selectedRecordEvent);
    }

    getFieldValue() {
        let fieldValue;
        if (this.searchField.includes('.')) {
            let nestedObject = this.selectedRecord;
            this.searchField.split('.').forEach(apiName => {
                if (apiName in nestedObject) {
                    nestedObject = nestedObject[apiName];
                }
            });
            fieldValue = nestedObject;
        }
        else {
            fieldValue = this.selectedRecord[this.searchField];
        }
        return fieldValue;
    }

    handleRemove(event) {
        event.preventDefault();
        this.selectedRecord = undefined;
        this.records = undefined;
        this.error = undefined;
        /* fire the event with the value of undefined for the Selected RecordId */
        const selectedRecordEvent = new CustomEvent(
            "selectedrec",
            {
                detail: { recordId: undefined, index: this.index, relationshipfield: this.relationshipfield }
            }
        );
        this.dispatchEvent(selectedRecordEvent);
    }

    get comboDropdownClass() {
        return (this.isLookupFocused) ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    handleKeyDown(event) {
        this.isLookupFocused = event.keyCode !== 27;
        // clearTimeout(this.typingTimer);
    }

    handleSearchInputFocus() {
        this.isLookupFocused = true;
    }

    handleObjectSelectorFocus() {
        this.isLookupFocused = false;
    }

    get searchInputClass() {
        return (this.showObjectList) ? 'slds-combobox_container slds-combobox-addon_end' : 'slds-combobox_container';
    }

    onObjectChange(event) {
        /* eslint-disable-next-line */
        this.selectedRecord = null;
        this.records = [];
        let selectedObject = this.supportedObjects.filter(item => item.value === event.detail.value);
        /* eslint-disable-next-line */
        this.objectName = selectedObject[0].value;
        /* eslint-disable-next-line */
        this.iconname = selectedObject[0].objectIcon;
        /* eslint-disable-next-line */
        this.metadataFields = selectedObject[0].metadataFields;
        /* eslint-disable-next-line */
        this.additionalFilters = selectedObject[0].additionalFilters;
        /* eslint-disable-next-line */
        this.recordRetrieveLimit = selectedObject[0].recordRetrieveLimit;
        /* eslint-disable-next-line */
        this.searchField = selectedObject[0].searchField;
        /* eslint-disable-next-line */
        this.searchPlaceholder = 'Search ' + selectedObject[0].label + 's...';
    }

    @api reportValidity() {
        let input = this.template.querySelector('lightning-input');
        let isValid;
        if (input?.value && !this.selectedRecord) {
            input.setCustomValidity("Select an option from the picklist or remove the search term.");
            input.reportValidity();
            isValid = false;
        }
        else {
            isValid = true;
        }
        return isValid;
    }
}