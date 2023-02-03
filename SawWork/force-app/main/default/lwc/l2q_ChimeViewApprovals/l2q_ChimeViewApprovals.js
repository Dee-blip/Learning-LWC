/**
 * @description       : Chime Product Approvals
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 03-22-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   10-22-2021   apyati   SFDC-8033 Initial Version
**/
import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getChimeProductApprovalDSRs from '@salesforce/apex/ChimeDSRController.getChimeProductApprovalDSRs';
import getAllProlexicProductsForChime from '@salesforce/apex/ChimeTriggerClass.getAllProlexicProductsForChime';
import checkPreSalesUser from '@salesforce/apex/ChimeTriggerClass.checkPreSalesUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class L2q_ChimeViewApprovals extends LightningElement {

    @api chimeRec;
    @api products;
    @track allQueAns = true;
    @track requesttype = '';
    @track isLoading;
    @track showErrorMessage;
    @track NoDataAfterRendering;
    @track showSubmitApprovalModal = false;
    @track newDSR;
    presalesrequestrectype;
    @track data;
    @track columns;
    prolexicproducts;
    chimedata;
    @track disableNewRequest = false;
    @track hasproductschange = false;

    COLUMNS = [
        {
            label: 'DSR',
            fieldName: 'NameURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: "_blank"
            },
        },
        {
            label: 'Account',
            fieldName: 'AccountURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'AccountName' },
                target: "_self"
            },

        },
        {
            label: 'Opportunity',
            fieldName: 'OpportunityURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'OpportunityName' },
                target: "_self"
            },

        },
        {
            label: 'Request Type ',
            fieldName: 'Request_Type__c',
        },
        {
            label: 'Request SubType',
            fieldName: 'Request_Sub_Type__c',
        },
        {
            label: 'Approval Status',
            fieldName: 'Approval_Status__c',
        },
        {
            label: 'Notes ',
            fieldName: 'Notes__c',
        },
    ];


    connectedCallback() {

        this.isLoading = true;
        this.fetchProducts();
        this.checkForPreSalesUser();
        this.columns = this.COLUMNS;
        this.chimedata = this.chimeRec;
        this.prolexicproducts = this.products;
        this.hasproductschange = false;
        if (this.products && this.chimedata && this.chimedata.Prolexic_Products__c) {
            let newarray = this.products.split(';');
            let oldarray = this.chimedata.Prolexic_Products__c.split(';');
            newarray.sort();
            oldarray.sort();
            if (newarray.length > oldarray.length) {
                this.hasproductschange = true;
            }
            else {
                for (let i = 0; i < newarray.length; i++) {
                    if (!oldarray.includes(newarray[i])) {
                        this.hasproductschange = true;
                        break;
                    }
                }
            }
            if (!this.prolexicproducts) {
                this.prolexicproducts = this.products;
            }
        }

        if (this.chimeRec.Product_Approval_Status__c === 'Integration Review Approved') {
            this.disableNewRequest = true;
        }

        this.fetchDSRs();
        this.isLoading = false;

    }


    @wire(getObjectInfo, { objectApiName: 'Deal_Support_Request__c' })
    objectdata({ data, error }) {
        if (data) {
            let rectypes = data.recordTypeInfos;
            Object.keys(rectypes).forEach(key => {
                if (rectypes[key].name === 'Pre-Sales Request') {
                    this.presalesrequestrectype = rectypes[key].recordTypeId;
                }
            })
        } else if (error) {
            console.log('error', error);
        }
    };

    fetchProducts() {
        getAllProlexicProductsForChime({ chimeId: this.chimeRec.Id })
            .then(result => {
                if (result && result.length > 0) {
                    let tempdata = JSON.parse(JSON.stringify(result));
                    let queans = true;
                    for (let i = 0; i < tempdata.length; i++) {
                        queans = queans && tempdata[i].Required_answer_on_product__c;
                    }
                    this.allQueAns = queans;
                    console.log('this.allQueAns ', this.allQueAns);
                }
            })
            .catch(error => {
                console.log('error', error);
                this.error = error;
                this.isloading = false;
            });
    }


    fetchDSRs() {
        getChimeProductApprovalDSRs({ chimeId: this.chimeRec.Id })
            .then(result => {

                let tempdata = JSON.parse(JSON.stringify(result));

                if (tempdata && tempdata.length > 0) {
                    for (let i = 0; i < tempdata.length; i++) {

                        tempdata[i].NameURL = '/' + tempdata[i].Id;
                        tempdata[i].AccountURL = '/' + tempdata[i].Account__r.Id;
                        tempdata[i].AccountName = tempdata[i].Account__r.Name;
                        if (Object.prototype.hasOwnProperty.call(tempdata[i], "Opportunity__r")){
                            tempdata[i].OpportunityURL = '/' + tempdata[i].Opportunity__r.Id;
                            tempdata[i].OpportunityName = tempdata[i].Opportunity__r.Name;
                        }
                    }

                    this.data = JSON.parse(JSON.stringify(tempdata));
                }
                else {
                    this.NoDataAfterRendering = true;
                }

            })
            .catch(error => {
                console.log('error', error);
            })
    }



    handleClose() {
        const cancelEvent = new CustomEvent('cancel', {});
        this.dispatchEvent(cancelEvent);
    }




    showSubmitForApproval() {

        if (this.chimeRec.Product_Approval_Status__c === 'Gating Review Approved' && !this.hasproductschange && !this.allQueAns) {
            this.showToast('Please answer all the mandatory questions in order to start the Product Approval peer-review.', "warning", "sticky");
        }
        else if (this.chimeRec.Product_Approval_Status__c === 'Gating Review Approved' && !this.hasproductschange) {
            this.requesttype = 'Integration Review';
            this.showSubmitApprovalModal = true;
        }
        else if (this.chimeRec.Product_Approval_Status__c === 'Gating Review Approved' && this.hasproductschange) {
            this.showToast('There are Products that are added after the Product Approval Gating Review was approved. So, please resubmit the existing Gating request present, to get the newly added products approved', "warning", "sticky");

        }
        else if (this.chimeRec.Product_Approval_Status__c === 'Not Started') {
            this.requesttype = 'Gating Review';
            this.showSubmitApprovalModal = true;
        }
        else if (this.chimeRec.Product_Approval_Status__c !== 'Gating Review Approved' && this.chimeRec.Product_Approval_Status__c.includes('Gating Review')) {
            this.showToast('ALERT - There is already a Product Approval peer-review request in progress.  Please use the existing request to make any changes', "warning", "sticky");
        }
        else if (this.chimeRec.Product_Approval_Status__c !== 'Integration Review Approved' && this.chimeRec.Product_Approval_Status__c.includes('Integration Review')) {
            this.showToast('ALERT - There is already a Product Approval peer-review request in progress.  Please use the existing request to make any changes', "warning", "sticky");
        }
    }

    hideSubmitForApproval() {
        this.showSubmitApprovalModal = false;
    }



    showToast(message, variant, mode) {
        const evt = new ShowToastEvent({
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    checkForPreSalesUser() {
        checkPreSalesUser()
            .then(result => {
                let isPreSalesuser = result;
                console.log('isPreSalesuser ->' + isPreSalesuser);
                if (!isPreSalesuser) {
                    this.disableNewRequest = true;
                }
            })
            .catch(error => {
                console.log('error', error);
            });
    }


}