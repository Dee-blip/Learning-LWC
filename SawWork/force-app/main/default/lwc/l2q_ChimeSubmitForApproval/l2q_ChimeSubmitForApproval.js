/**
 * @description       : Chime Product Approvals
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 01-14-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   10-22-2021   apyati   SFDC-8033 Initial Version
**/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import PRODUCTS_FIELD from '@salesforce/schema/CHIME__c.Prolexic_Products__c';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class L2q_ChimeSubmitForApproval  extends NavigationMixin(LightningElement) {

@api chimeRec;
@api products ;
@api requesttype ;
@track isLoading;
@track showErrorMessage;
@track showEditForm;
@track newDSR;
presalesrequestrectype;
chimedata;
prolexicproducts;
userId = USER_ID;


    connectedCallback(){

        this.isLoading= false;
        this.showEditForm= true;
        this.chimedata= this.chimeRec;
        this.prolexicproducts = this.products

    }
    
    @wire(getObjectInfo, { objectApiName: 'Deal_Support_Request__c' })
    objectdata({data,error}){
        if(data){
            let rectypes = data.recordTypeInfos;
            Object.keys(rectypes).forEach(key =>{
                if(rectypes[key].name === 'Pre-Sales Request'){
                    this.presalesrequestrectype = rectypes[key].recordTypeId;
                }
            })
        }else if(error){
            console.log('error',error);
        }
    };

    handleSubmit(event){
        this.isLoading = true;
        event.preventDefault();       // stop the form from submitting
        let fields = event.detail.fields;
        //fields.SE__c= this.userId;
        fields.CHIME__c = this.chimeRec.Id;
        fields.Account__c =  this.chimeRec.Account__c;
        fields.Opportunity__c=  this.chimeRec.Opportunity__c;
        fields.RecordTypeId= this.presalesrequestrectype;
        fields.Request_Type__c = 'STG Specialist';
        fields.Request_Sub_Type__c = this.requesttype;
        fields.Product__c= 'Prolexic';
        let line1 = 'Products:'+this.products;
        let line2 = 'Notes:'+fields.Notes__c;
        fields.Notes__c =line1+ '\n'+line2 ;
        fields.Validation_Override__c = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
     }

     handleSuccess(event){
        this.isLoading = false;
        this.newDSR = event.detail.id;
        this.navigateToDSR();
       // this.updateChimeProducts();
     }

     navigateToDSR() {
        let dsrId = this.newDSR.split('-')[0];
        let baseurl = window.location.origin;
        window.location = baseurl+'/'+dsrId;
        /*
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: dsrId,
                objectApiName: 'Deal_Support_Request__c',
                actionName: 'view'
            },
        });
        */
    }
    handleCancel(){
        const cancelEvent = new CustomEvent('cancel',{});
            this.dispatchEvent(cancelEvent);
    }

    updateChimeProducts(){
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.chimeRec.Id;
        fields[PRODUCTS_FIELD.fieldApiName] = this.prolexicproducts;
        const recordInput = { fields };

        updateRecord(recordInput)
                .then(() => {
                    console.log('Chime Products Updated');
                    return refreshApex(this.chimeRec);
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Updating Chime Record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
    }

}