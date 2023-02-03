/**
  @description       : This component is used to view/edit contacts on chime form
  @author            : apyati
  @team              : GSM
  @last modified on  : 02-24-2022
  @last modified by  : apyati
  Modifications Log
  Ver   Date         Author   Modification
 * 1.0   09-07-2021   apyati   Created for SFDC-8655 
 * 2.0   24-02-2022   apyati    Added showPopUp for SFDC-9409
**/
import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getChimeContacts from '@salesforce/apex/ChimeTriggerClass.getChimeContacts';
import getContacts from '@salesforce/apex/ChimeTriggerClass.getContacts';
import addChimeContacts from '@salesforce/apex/ChimeTriggerClass.addChimeContacts';
import removeChimeContacts from '@salesforce/apex/ChimeTriggerClass.removeChimeContacts';
import updateChimeContacts from '@salesforce/apex/ChimeTriggerClass.updateChimeContacts';



const ASSIGNED_CONTACTS = "Assigned";
const UNASSIGNED_CONTACTS = "Unassigned";

const tabsObj = [
    {
        tab: ASSIGNED_CONTACTS,
        helpText: "",
        fieldSet: 'Assigned_Contacts'
    },
    {
        tab: UNASSIGNED_CONTACTS,
        helpText: "",
        fieldSet: 'UnAssigned_Contacts'
    }
];



export default class L2qChimeViewEditContacts extends NavigationMixin(LightningElement) {

    @api recordId;
    @track tabs = tabsObj;
    @track defaultTabOnInitialization = ASSIGNED_CONTACTS;
    @track currentTabValue;
    @track columns;
    @track fieldApiNames = [];
    @track lookupFields = [];
    @track draftValues = [];
    @track data;
    @track maxrows;
    @track NoDataAfterRendering = false;
    @track displayDataTableFooter = false;
    @track displaycancel = false;
    @track showErrorMessage;
    @track displayRemoveBTN = false;
    @track displayAddBTN = false;
    @track displaysave = false;
    searchTerm = '';
    @track isLoading = false;

    //have this attribute to track data change
    @track draftValues = [];
    lastSavedData = [];
    selectedRow = [];
    selectedRecordsList = [];
    @track selectedAccountId;
    @track sortBy;
    @track sortDirection;
    saveDraftValues;

    @track isShowModal = false;
    @track headerValue;
    @track isCreateNewACR;
    @track isCreateNewContact;
    @track defaultValAccount;
    @track defaultValContact;
    @track successMessage;

    @track contacts;
    @track allContacts;
    @track listRecs;
    @track initialListRecs;
    @track error;
    @track columns;
    @api parentId;
    @api accountId;
    @api relatedObject;
    @api fields;
    @api relatedField;
    @api tableColumns;
    @api title;
    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    wiredList;
    showSearchContacts = false;
    contactsPageUrl;
    vals;
    newChimeContactUrl;
    chimeFormUrl;
    rowNumberOffset;
    @track recordsToDisplay;

    @api disableButtons = false;


    COL_ASSIGNED = [

        {
            label: 'Name',
            fieldName: 'Name__c',
            sortable: true
        },
        {
            label: 'Email',
            fieldName: 'Email__c',
            type: "email",
            sortable: true,
            //wrapText: true

        },
        {
            label: 'Phone',
            fieldName: 'Contact_Phone__c',
            sortable: true

        },
        {
            label: 'Chime Access',
            fieldName: 'Chime_access__c',
            type: 'boolean',
            sortable: true,
            editable: true,
        }/*
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions
            }
        }*/
    ];


    COL_UNASSIGNED = [
        {
            label: "Contact",
            fieldName: 'ContactURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'ContactName' },
                target: "_self"
            },
            sortable: true,
            //wrapText: true

        },
        {
            label: "Account",
            fieldName: 'AccountURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'AccountName' },
                target: "_self"
            },
            sortable: true,
            // wrapText: true

        },
        {
            label: 'Account Type ',
            fieldName: 'AccountType',
            sortable: true,
        },
        {
            label: 'Email',
            fieldName: 'Email',
            type: 'email',
            sortable: true,
            //wrapText: true
        },
        {
            label: 'Phone',
            fieldName: 'Phone',
            type: 'phone',
            sortable: true

        },
        {
            label: 'Chime Access',
            fieldName: 'ChimeAccess',
            type: 'boolean',
            sortable: true,
            editable: true
        }
    ];




    connectedCallback() {

        this.generateChimeContactURL();
        this.generateReturnURL();
    }



    handleRowAction(event) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'edit':
                this.dispatchEvent(new CustomEvent("closecontacts"));
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: this.relatedObject,
                        actionName: 'edit'
                    }
                });
                break;
            case 'delete':
                if (window.confirm("Are you sure you want to remove this Chime Contact?")) {
                    this.deleteContactAssociation(row.Id);
                }
                break;
            default:
        }

    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    //handle tab selection
    handleActiveTab(event) {
        this.currentTabValue = event.target.value;
        //  console.log('handleActiveTab' + this.currentTabValue);
        this.handleRefresh();
    }


    //handle row selected
    handleRowSelected(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecordsList = JSON.parse(JSON.stringify(selectedRows));
        //console.log(`SelectedRows --> ${JSON.stringify(selectedRows)}`);
        this.selectedRow = [];
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedRow.push({ Id: selectedRows[i].Id });
        }
        //console.log("selected row final => " + JSON.stringify(this.selectedRow));
        if (this.selectedRow.length > 0) {
            this.displayDataTableFooter = true;
            //this.displaycancel = true;
            //this.displaysave = true;
            this.showErrorMessage = undefined;
        }
    }


    handleRefresh() {

        console.log('handleRefresh called');
        this.NoDataAfterRendering = false;
        this.displayDataTableFooter = false;
        this.displaysave = false;
        this.displayAddBTN = false;
        this.displayRemoveBTN = false;
        this.showErrorMessage = undefined;
        this.selectedRecordsList = [];
        this.selectedRow = [];

        if (this.currentTabValue == ASSIGNED_CONTACTS) {
            this.columns = this.COL_ASSIGNED;
            this.data = undefined;
            console.log('parent', this.parentId);
            this.isLoading = true;
            getChimeContacts({ chimeId: this.parentId })
                .then((result) => {
                    if (result && result.length > 0) {
                        //console.log('Records are ' + JSON.stringify(result));
                        this.listRecs = result;
                        this.initialListRecs = result;
                        this.data = this.listRecs;
                        this.displayRemoveBTN = true;
                        this.displayAddBTN = false;
                    } else {
                        console.log('no records');
                        this.NoDataAfterRendering = true;
                        this.data = undefined;
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                });
        }
        else if (this.currentTabValue == UNASSIGNED_CONTACTS) {
            this.columns = this.COL_UNASSIGNED;
            this.data = undefined;
            this.isLoading = true;

            getContacts({ accId: this.accountId, chimeId: this.parentId })
                .then((result) => {
                    //console.log('data', ...result);
                    let tempdata = JSON.parse(JSON.stringify(result));
                    if (tempdata) {
                        for (let i = 0; i < tempdata.length; i++) {
                            tempdata[i].ChimeAccess = false;
                            tempdata[i].ContactURL = '/' + tempdata[i].Id;
                            tempdata[i].ContactName = tempdata[i].Name;
                            tempdata[i].AccountURL = '/' + tempdata[i].Account.Id;
                            tempdata[i].AccountName = tempdata[i].Account.Name;
                            tempdata[i].AccountType = tempdata[i].Account.Type;

                        }
                        this.allContacts = [...tempdata];
                        this.contacts = [...tempdata];
                        this.data = this.contacts;
                        this.displayRemoveBTN = false;
                        this.displayAddBTN = true;
                    } else {
                        this.NoDataAfterRendering = true;
                        this.data = undefined;
                    }

                    this.isLoading = false;

                }).catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                });
        }

    }


    getRecordURL(sObject, Id) {
        return "/lightning/r/" + sObject + "/" + Id + "/view";
    }

    handleIconRefresh() {
        this.searchTerm = '';
        this.handleRefresh();
    }


    startSearchTimer(event) {
        clearTimeout(this.timerId);
        this.timerId = setTimeout(this.doSearch.bind(this), 500);
    }

    showPopUp() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: "",
                message: 'Checking this Chime Access box will give this customer contact access to this CHIME form in the Akamai Community',
                variant: "warning"
            })
        );
    }



    handleCellChange(event) {
        this.saveDraftValues = event.detail.draftValues;
        //console.log(`saveDraftValues --> ${JSON.stringify(this.saveDraftValues)}`);

        this.saveDraftValues.forEach(draft => {
            if (this.selectedRecordsList && this.selectedRecordsList.length > 0) {
                let index = this.selectedRecordsList.findIndex(rec => rec.Id === draft.Id);
                if (index != -1) {
                    if (this.currentTabValue === ASSIGNED_CONTACTS) {
                        this.selectedRecordsList[index].Chime_access__c = draft.Chime_access__c;
                        if (draft.Chime_access__c) {
                            this.showPopUp();
                        }
                        this.displaysave = true;
                    } else {
                        this.selectedRecordsList[index].Has_Chime_Access__c = draft.ChimeAccess;
                        if (draft.ChimeAccess) {
                            this.showPopUp();
                        }
                        this.displaysave = false;
                    }
                }
            }
            if (this.recordsToDisplay && this.recordsToDisplay.length > 0) {
                let index = this.recordsToDisplay.findIndex(rec => rec.Id === draft.Id);
                if (index != -1) {
                    if (this.currentTabValue === ASSIGNED_CONTACTS) {
                        this.recordsToDisplay[index].Chime_access__c = draft.Chime_access__c;
                        if (draft.Chime_access__c) {
                            this.showPopUp();
                        }
                        this.displaysave = true;
                    } else {
                        this.recordsToDisplay[index].Has_Chime_Access__c = draft.ChimeAccess;
                        if (draft.ChimeAccess) {
                            this.showPopUp();
                        }
                        this.displaysave = false;
                    }
                }
            }
        });

    }

    //handler to remove CHIME Contacts from CHIME
    handleRemove(event) {
        const chimeContacts = this.selectedRecordsList;
        // console.log(`chimeContacts --> ${JSON.stringify(chimeContacts)}`);

        if (chimeContacts != undefined && chimeContacts.length > 0) {
            this.isLoading = true;
            removeChimeContacts({ chimeContacts: chimeContacts })
                .then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result,
                            variant: "success"
                        })
                    );

                    //clear the selected rows
                    this.selectedRow = [];

                    //hide the datatable footer
                    this.displayDataTableFooter = false;
                    this.displaycancel = false;

                    this.isLoading = false;

                    return this.handleRefresh();
                })
                .catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                })
        } else {
            this.showErrorMessage = "Please select a Contact to remove from the CHIME";
        }
    }

    handleAdd() {

        const chimeContacts = this.selectedRecordsList;

        if (chimeContacts != undefined && chimeContacts.length > 0) {
            this.isLoading = true;
            addChimeContacts({ selectedContacts: chimeContacts, chimeId: this.parentId })
                .then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result,
                            variant: "success"
                        })
                    );
                    //clear the selected rows
                    this.selectedRow = [];
                    //hide the datatable footer
                    this.displayDataTableFooter = false;
                    this.displaycancel = false;
                    this.isLoading = false;
                    this.template.querySelector('lightning-tabset').activeTabValue = ASSIGNED_CONTACTS;
                    return this.handleRefresh();
                })
                .catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                })
        }
        else {
            this.showErrorMessage = "Please select a Contact to remove";
        }
    }


    handleSave(event) {
        const chimeContacts = this.selectedRecordsList;
        //console.log(`chimeContacts --> ${JSON.stringify(chimeContacts)}`);

        if (chimeContacts != undefined && chimeContacts.length > 0) {
            this.isLoading = true;
            updateChimeContacts({ chimeContacts: chimeContacts })
                .then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result,
                            variant: "success"
                        })
                    );

                    //clear the selected rows
                    this.selectedRow = [];

                    //hide the datatable footer
                    this.displayDataTableFooter = false;
                    this.displaycancel = false;

                    this.isLoading = false;

                    return this.handleRefresh();
                })
                .catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                })
        } else {
            this.showErrorMessage = "Please select a Contact to update";
        }
    }


    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant,
                mode: mode
            }),
        );
    }


    doSorting(event) {

        //console.log('called doSorting');
        //console.log('label' + JSON.stringify(event.detail));

        var fname = event.detail.fieldName;
        if (fname.includes('URL')) {
            fname = fname.replace('URL', 'Name')
        }
        this.sortBy = fname;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
        this.sortBy = event.detail.fieldName;

    }


    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsToDisplay = parseData;
    }


    createNew() {
        var contextObject = {};
        contextObject.attributes = {};
        contextObject.attributes.recordId = this.accountId;

        //contextObject.attributes.returnURL = '/lightning/o/CHIME_Contact__c/new?defaultFieldValues=' + encodeURIComponent("CHIME__c=" + this.parentId + ",Contact__c=newcontactid") + '&backgroundContext=' + encodeURIComponent('/lightning/r/CHIME__c/' + this.parentId + '/view');

        contextObject.attributes.returnURL = this.newChimeContactUrl;

        let encodeContextObject = btoa(JSON.stringify(contextObject));


        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/o/Contact/new?useRecordTypeCheck=true&inContextOfRef=1.' + encodeContextObject
            }

        });
    }

    generateChimeContactURL() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'CHIME_Contact__c',
                actionName: 'new'
            },
            state: {
                c__chime: this.parentId,
                c__contact: "newcontactid"
            }
        }).then(url => {
            this.newChimeContactUrl = url;
        }).catch(error => {
            console.error('error=>', error);
        });
    }

    generateReturnURL() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'CHIME__c',
                recordId: this.parentId,
                actionName: 'view'
            },
            state: {
                c__fromcontact: true,
                c__contact: "newcontactid"
            }
        }).then(url => {
            this.chimeFormUrl = url;
        });
    }

    handlePaginatorChange(event) {
        //console.log('recordsToDisplay size' + event.detail.length);
        this.recordsToDisplay = JSON.parse(JSON.stringify(event.detail));

    }

}