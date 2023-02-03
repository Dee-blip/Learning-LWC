/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 01-19-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-16-2021   apyati   Initial Version
**/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLayoutFields from '@salesforce/apex/ChimeDSRController.getLayoutFields';
export default class L2q_ChimeNewPocDsr extends NavigationMixin(LightningElement) {

    @api chimeId;
    @api opptyId;
    @api accId;
    @track isLoading;
    @track showErrorMessage;
    @track showEditForm;
    @track newDSR;
    presalesactivityrectype;
    chimedata;
    error;
    @track fieldsArray;



    connectedCallback() {
        this.fetchFields();
    }

    @wire(getObjectInfo, { objectApiName: 'Deal_Support_Request__c' })
    objectdata({ data, error }) {
        if (data) {
            console.log('recordtypeifos' + JSON.stringify(data.recordTypeInfos));
            let rectypes = data.recordTypeInfos;
            Object.keys(rectypes).forEach(key => {
                if (rectypes[key].name == 'Pre-Sales Activity') {
                    this.presalesactivityrectype = rectypes[key].recordTypeId;
                }
            });
            console.log('presalesactivityrectype' + this.presalesactivityrectype);
            this.showEditForm = true;
        } else if (error) {
            console.log('error', error);
        }
    };

    handleSubmit(event) {
        this.isLoading =true;
        event.preventDefault();       // stop the form from submitting
        var fields = event.detail.fields;
        console.log('Fields' + JSON.stringify(fields));
        //fields.Validation_Override__c = true;
        console.log('Fields' + JSON.stringify(fields));
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }


    handleSuccess(event) {
        this.newDSR = event.detail.id;
        console.log('onsuccess: ', this.newDSR);
        this.navigateToDSR();
    }

    handleError(event) {
        this.isLoading =false;
        console.log('onerror');
    }


    navigateToDSR() {

        let dsrId = this.newDSR.split('-')[0];
        let baseurl = window.location.origin;
        window.location = baseurl+'/'+dsrId;

        /*
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.newDSR,
                objectApiName: 'Deal_Support_Request__c',
                actionName: 'view'
            },
        });*/
    }
    handleCancel() {
        const cancelEvent = new CustomEvent('cancel', {});
        this.dispatchEvent(cancelEvent);
    }

    handleLoad(event) {
       // console.log('Layout => ', JSON.stringify(event.detail.layout));
       // console.log('fields => ', JSON.stringify(event.detail.fields));

    }


    fetchFields() {
        this.isLoading = true;
        this.fieldsArray = [];
        const objName = 'Deal_Support_Request__c';
        getLayoutFields({ objectName: objName })
            .then(data => {
                if (data) {
                    console.log('data..', data);

                    Object.keys(data).forEach(key => {
                        let section = {
                            sectionName: key,
                            sectionfields: data[key]
                        }
                        let fields = [];
                        section.sectionfields.forEach(name => {
                            let field = {
                                fieldName: name,
                                disabled: false
                            }
                            if (name == 'Account__c') {
                                field.fieldValue = this.accId;
                                field.disabled = true;
                            }
                            else if (name == 'Opportunity__c') {
                                field.fieldValue = this.opptyId;
                                field.disabled = true;
                            }
                            else if (name == 'CHIME__c') {
                                field.fieldValue= this.chimeId;
                                field.disabled = true;
                            }
                            else if (name == 'Request_Type__c') {
                                field.fieldValue = 'POC';
                                field.disabled = true;
                            }
                            fields.push(field);
                        });
                        section.sectionfields = fields;
                        this.fieldsArray.push(section);
                    });
                    console.log('fieldsArray..', ...this.fieldsArray);
                    this.error = undefined;
                    this.showEditForm = true;

                } else if (error) {
                    this.error = error;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                console.log('error', error);
                this.isLoading = false;
            });

    }

}