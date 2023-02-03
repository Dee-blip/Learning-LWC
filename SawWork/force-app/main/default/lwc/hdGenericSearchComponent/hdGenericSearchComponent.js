import { LightningElement, api, wire } from 'lwc';
import findRecords from '@salesforce/apex/HD_Custom_lookup_Controller.findRecords';
import getRecentlyViewedRecords from '@salesforce/apex/HD_Custom_lookup_Controller.getRecentlyViewedRecords';
import { getListUi, MRU } from 'lightning/uiListApi';


export default class HdGenericSearchComponent extends LightningElement {
    records;
    mru;
    error;
    selectedRecord;
    searchKey;
    selectedRecordValue;
    showAdvancedSearch = false;
    selectedTab = '2';
    isLoading;
    isError;
    errorMessage;
    @api size;
    @api index;
    @api searchPlaceholder;
    @api metadataFields;
    @api relationshipfield;
    @api iconname = "standard:account";
    @api objectName = 'Account';
    @api searchField;
    @api useToolingApi = false;
    @api additionalFilters = '';
    @api linkedItems;
    @api favourites;
    @api componentTitle;

    @wire(getListUi, {
        objectApiName: '$objectName',
        listViewApiName: MRU
    })
    wiredCallback({ error, data }) {
        if (data) {
            if (data.records.records) {
                this.mru = [];
                let recordIds = [];
                for (let record of data.records.records) {
                    recordIds.push(record.id);
                }
                getRecentlyViewedRecords({
                    searchParams: JSON.stringify({ objectIds: recordIds, fields: this.metadataFields, objectName: this.objectName, searchField: this.searchField })
                })
                    .then(result => {
                        this.mru = result;
                        this.isLoading = false;
                    })
                    .catch(error1 => {
                        this.isError = true;
                        this.errorMessage = error1.body.message;
                        this.isLoading = false;
                    });
            }
            this.isError = false;
            this.errorMessage = '';
        }
        else if (error) {
            this.isLoading = false;
            this.isError = true;
            this.errorMessage = error.body.message;
        }
    }

    handleAdvancedSearch() {
        this.showAdvancedSearch = !this.showAdvancedSearch;
    }

    handleSearchResults(event) {
        this.isLoading = false;
        this.selectedTab = '3';
        this.records = event.detail;
    }

    get displayMRUNoDataImage() {
        return !this.mru || this.mru.length === 0;
    }

    get displayNoDataImage() {
        return !this.records || this.records.length === 0;
    }

    get displayFavNoDataImage() {
        return !this.favourites || this.favourites.length === 0;
    }

    @api
    set errorStatus(value) {
        this.isError = (value) ? true : false;
        this.errorMessage = value;
    }

    get errorStatus() {
        return '';
    }

    handleSearchCriteriaDecoding(event) {
        this.isLoading = true;
        this.selectedTab = '3';
        findRecords({
            searchParams: JSON.stringify({
                searchKey: '',
                fields: this.metadataFields,
                objectName: this.objectName,
                searchField: this.searchField,
                additionalFilters: event.detail
            })
        })
            .then(result => {
                this.records = result;
                this.isLoading = false;
                this.isError = false;
                this.errorMessage = '';
            })
            .catch(error => {
                this.isError = true;
                this.errorMessage = error.body.message;
                this.isLoading = false;
                this.records = undefined;
            });

    }

    get lookupItemGridClass() {
        if (this.size === 'SMALL') {
            return 'slds-col slds-size_1-of-1';
        }
        else if (this.size === 'MEDIUM') {
            return 'slds-col slds-size_1-of-3';
        }
        return 'slds-col slds-size_1-of-3';

    }
}