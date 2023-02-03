import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getClientIncidentData from '@salesforce/apex/HD_DetailControllerUtils.getClientIncidentData';

const INCIDENT_FIELD = ['BMCServiceDesk__Incident__c.Client_Employee_ID__c'];
const INCIDENT_FIELD_OPTIONAL = ['BMCServiceDesk__Incident__c.Client_ID_Email__c',
    'BMCServiceDesk__Incident__c.BMCServiceDesk__Client_Phone__c', 'BMCServiceDesk__Incident__c.HD_Client_dept__c',
    'BMCServiceDesk__Incident__c.BMCServiceDesk__Client_Manager__c', 'BMCServiceDesk__Incident__c.HD_Client_City__c',
    'BMCServiceDesk__Incident__c.HD_Client_Division__c', 'BMCServiceDesk__Incident__c.Client_Region__c'];

export default class Hd_Incident_Client_Details extends NavigationMixin(LightningElement) {
    @api recordId;
    showClient = true;
    clientName;
    designation;
    photoUrl;
    clientId;
    initials;
    isClientDataLoading = true;
    isClientImageLoading = true;
    @track showFields = [{ fieldapiname: 'Client_Employee_ID__c', isvisible: true },
    { fieldapiname: 'BMCServiceDesk__Client_Phone__c', isvisible: true },
    { fieldapiname: 'BMCServiceDesk__Client_Manager__c', isvisible: true },
    { fieldapiname: 'HD_Client_Division__c', isvisible: true },
    { fieldapiname: 'Client_ID_Email__c', isvisible: true },
    { fieldapiname: 'HD_Client_dept__c', isvisible: true },
    { fieldapiname: 'HD_Client_City__c', isvisible: true },
    { fieldapiname: 'Client_Region__c', isvisible: true }];

    @wire(getRecord, { recordId: '$recordId', fields: INCIDENT_FIELD, optionalFields: INCIDENT_FIELD_OPTIONAL })
    wiredRecord({ error, data }) {
        if (data) {
            this.showFields.forEach(field => {
                field.isvisible = (field.fieldapiname in data.fields) && (data.fields[field.fieldapiname].value);
            });
            window.console.log('showFields>>> ' + JSON.stringify(this.showFields));
            this.isClientDataLoading = false;
        }
        else if (error) {
            this.isClientDataLoading = false;
            window.console.log('Error in wiredRecord>> ' + JSON.stringify(error));
        }
    }

    @wire(getClientIncidentData, { recordId: '$recordId' })
    getClientIncidentDetail({ error, data }) {
        if (data) {

            this.clientName = data.BMCServiceDesk__Client_Name__c;
            this.clientId = data.BMCServiceDesk__FKClient__c;
            this.designation = data.HD_Client_title__c;
            //Get First and Last word, except get First 2 in case there is only first name, for initials
            this.initials = this.clientName?.match(/(^\S\S?|\b\S)?/g).join("").match(/(^\S|\S$)?/g).join("").toUpperCase();

            let username = data.BMCServiceDesk__FKClient__r.Username;
            if (username) {
                this.photoUrl = "https://contacts.akamai.com/photos/" + username.substring(0, username.indexOf('@')) + ".jpg";
            }
            window.console.log('>>>>initials is : ' + this.initials);
            this.isClientImageLoading = false;
        }
        else if (error) {
            this.isClientImageLoading = false;
            window.console.log('Error in getClientIncidentDetail>> ' + JSON.stringify(error));
        }
    }

    get isLoading() { 
        return this.isClientDataLoading || this.isClientImageLoading;
    }

    gotoRecord(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url);
        });
    }
    handleClientChevron() {
        this.showClient = !this.showClient;
    }

    get backgroundStyle() {
        return 'background-image: url(' + this.photoUrl + ')';
    }
}