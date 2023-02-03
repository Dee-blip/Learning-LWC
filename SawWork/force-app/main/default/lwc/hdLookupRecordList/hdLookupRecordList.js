import { LightningElement, api } from 'lwc';

export default class HdLookupRecordList extends LightningElement {
    @api record;
    @api fieldname;
    @api iconname;
    @api advancedTemplate = "true";
    @api size;
    metaData;
    showNewWindow;
    isMouseOver;

    handleSelect(event) {
        event.preventDefault();
        const selectedRecord = new CustomEvent(
            "select",
            {
                detail: this.record.Id
            }
        );
        /* eslint-disable no-console */
        //console.log( this.record.Id);
        /* fire the event to be handled on the Parent Component */
        this.dispatchEvent(selectedRecord);
    }

    get metaClass() {
        return this.metaData ? 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta' : 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small';
    }

    get fieldValue() {
        let fieldValue;
        if (this.fieldname.includes('.')) {
            let nestedObject = this.record;
            this.fieldname.split('.').forEach(apiName => {
                if (apiName in nestedObject) {
                    nestedObject = nestedObject[apiName];
                }
            });
            fieldValue = nestedObject;
        }
        else {
            fieldValue = (this.record && this.fieldname in this.record) ? this.record[this.fieldname] : this.record.Name;
        }
        return fieldValue;
    }

    get getURL() {
        return (this.record && 'Id' in this.record) ? '/' + this.record.Id : '';
    }

    @api
    set metaDataFields(metadataFieldNames) {
        this.metaData = [];
        if (this.record && metadataFieldNames) {
            metadataFieldNames.split(',').forEach(fieldApiName => {
                if (fieldApiName.includes('.')) {
                    let nestedFieldAPINames = fieldApiName.split('.');
                    let nestedObject = this.record;
                    nestedFieldAPINames.forEach(apiName => {
                        if (apiName in nestedObject) {
                            nestedObject = nestedObject[apiName];
                        }
                    });
                    this.metaData.push(nestedObject);
                }
                else {
                    if (fieldApiName in this.record) {
                        this.metaData.push(this.record[fieldApiName]);
                    }
                }
            });
        }
    }

    get metaDataFields() {
        return '';
    }

    onLinkClicked() {
        this.dispatchEvent(new CustomEvent("itemlinked", {
            detail: {
                Name: this.record[this.fieldname],
                Icon: this.iconname,
                Id: this.record.Id
            },
            bubbles: true,
            composed: true
        }));
    }

    onNewWindowClicked(event) {
        if (event.target.type !== 'media' && event.target.type !== 'button') {
            this.template.querySelector("c-hd-modal-popup").open();
        }
    }

    get showAdvancedTemplate() {
        return this.advancedTemplate === "true";
    }

    handleMouseEnter() {
        this.isMouseOver = true;
    }

    handleMouseOut() {
        this.isMouseOver = false;
    }

    get itemClass() {
        return (this.isMouseOver) ? 'slds-border_top slds-border_right slds-border_bottom slds-border_left slds-m-around_x-small slds-p-around_x-small backgroundHighlight' :
            'slds-border_top slds-border_right slds-border_bottom slds-border_left slds-m-around_x-small slds-p-around_x-small';
    }
    get linkIconClass() {
        return (this.isMouseOver) ? 'slds-show' : 'slds-hide';
    }

    get colSize() {
        return (this.size === 'SMALL') ? 10 : 8;
    }
}