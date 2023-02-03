/**
 * Author : Rajesh Kumar 
 * JIRA : SFDC-7588
 * Description : This is reusable flow lookup , specially designed to be used in Lightning VisualFLow
 */
import { LightningElement, track, api } from 'lwc';
import findRecords from '@salesforce/apex/L2Q_CustomLookupController.findRecords';
import { isEmpty } from 'c/l2QlwcUtil';
var timefired = null;
export default class L2qflowlookup extends LightningElement {
    /**Begin Component API Definition */
    @api flowrecname = '';
    @api flowrecid = '';
    @api flowrequired = false;
    @api index;
    @api iconname = '';
    @api objectName = 'User';
    @api searchfield = 'Name';
    @api recordLimit = 15;
    @api placeholderText = '';
    @api whereClause = '';
    @api minSearchlen = 3;
    @api maxtimedelay = 300;
    @api fieldtodisplay;
    @api cssStyle = '';
    @api fieldlabel = '';
    @api fieldlabelcss = '';
    @api errorMessageonrequired = 'This is required field.';
    @api resultwarningMessage = '{"title":"Warning:","message":"No records were found based on current search criteria.","variant":"warning"}';
    /**End Component API Definition */

    @track records;
    @track error;
    @track selectedRecord;
    loaderAllowed = false;
    parsedmessage;
    issearchblank = false;

    connectedCallback() {
        this.parsedmessage = JSON.parse(this.resultwarningMessage);
        if (!isEmpty(this.flowrecname) && !isEmpty(this.flowrecid)) {
            this.selectedRecord = {};
            this.selectedRecord.Name = this.flowrecname;
            this.selectedRecord.Id = this.flowrecid;
        }
    }

    handleOnchange(event) {
        clearTimeout(timefired);
        event.preventDefault();
        this.error = undefined;
        this.maxtimedelay = parseInt(this.maxtimedelay);
        this.recordLimit = parseInt(this.recordLimit);
        const searchKey = event.detail.value == undefined ? '' : event.detail.value;
        if (searchKey.trim().length < parseInt(this.minSearchlen)) {
            this.records = null;
            this.loaderAllowed = false;
            this.issearchblank = false;
            return;
        }
        this.loaderAllowed = true;
        /* Call the Salesforce Apex class method to find the Records keeping some delay so call does not ahppen Immidietly */
        timefired = setTimeout(() => {
            findRecords({
                searchKey: searchKey,
                objectName: this.objectName,
                searchField: this.searchfield,
                recordLimit: this.recordLimit,
                whereClause: this.whereClause,
                suggestionField: this.fieldtodisplay
            })
                .then((result) => {
                    this.records = result;
                    for (let i = 0; i < this.records.length; i++) {
                        const rec = this.records[i];
                        this.records[i].Name = rec[this.searchfield];
                    }
                    this.error = undefined;
                    this.loaderAllowed = false;
                    if (this.records.length < 1) {
                        this.issearchblank = true;
                    }
                })
                .catch((error) => {
                    this.issearchblank = false;
                    this.loaderAllowed = false;
                    this.error = error;
                    this.records = undefined;
                });
        }, this.maxtimedelay);
    }
    handleSelect(event) {
        this.error = undefined;
        const selectedRecordId = event.detail;
        /* eslint-disable no-console*/
        this.selectedRecord = this.records.find((record) => record.Id === selectedRecordId);
        /* fire the event with the value of RecordId for the Selected RecordId */
        const selectedRecordEvent = new CustomEvent('selectedrec', {
            detail: { recordId: selectedRecordId, index: this.index }
        });
        this.dispatchEvent(selectedRecordEvent);
        this.flowrecid = this.selectedRecord.Id;
        this.flowrecname = this.selectedRecord.Name;
        console.log('JSOBn data ::' + JSON.stringify(this.selectedRecord));

    }
    handleRemove(event) {
        event.preventDefault();
        this.selectedRecord = undefined;
        this.records = undefined;
        this.error = undefined;
        /* fire the event with the value of undefined for the Selected RecordId */
        const selectedRecordEvent = new CustomEvent('selectedrec', {
            detail: { recordId: '', index: this.index }
        });
        this.dispatchEvent(selectedRecordEvent);
        this.flowrecid = '';
        this.flowrecname = '';
    }
    hidewarnMessage = () => {
        //function to hide warning message at instant
        var self = this;
        self.issearchblank = false;
    };
    //Flow Validations 
    @api
    validate() {
        if (isEmpty(this.flowrecid) && this.flowrequired) {
            return { isValid: false, errorMessage: this.errorMessageonrequired };
        } else {
            return {
                isValid: true
            };
        }
    }
}