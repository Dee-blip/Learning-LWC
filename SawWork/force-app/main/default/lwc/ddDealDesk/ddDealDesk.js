import { LightningElement, track, api, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// CSS Override - to force hide Standard App header
import noheader from '@salesforce/resourceUrl/noheader'; // for hiding header name bar in lwc components
import modal from '@salesforce/resourceUrl/modal'; // for hiding header name bar in lwc components

// Apex Actions - Get Deal and Save Deal
import getDeal from '@salesforce/apex/SC_DD_DealDeskCont.getDeal';
import saveDeal from '@salesforce/apex/SC_DD_DealDeskCont.saveDeal';
import saveOtherDeal from '@salesforce/apex/SC_DD_DealDeskCont.saveOtherDeal';

import { getRecord } from 'lightning/uiRecordApi';

// Import Constants from ddDealDeskConstants file
import {DEAL_FIELDS, ERROR_MSGS, CALC_MSG, DEAL_SOBJ_TYPE} from './ddDealDeskConstants';

import {serverCallError} from 'c/scUtil';

export default class DdDealDesk extends NavigationMixin(LightningElement) {
    // For Controlling the Layout size
    @track rightPanelTransition;
    @track showApprovalOptions;

    // Parameters to getDeal Apex method
    @track prodSelected;
    @track subProdSelected;
    @track account;
    @track akamAccId;
    @track requestedHours;
    @track requestedPrice;
    @track localCurrency;
    @track loeId;
    @track isNapCustomer;
    @api mode = 'new';

    @api recordId;
    // Evaluated Deal Returned from getDeal Apex method
    @track deal = {};

    // Default tab for EPS, ESR tabpanel - bottom right
    @track defaultTab = 'eps';

    get isEditMode() {
        return this.mode === 'edit';
    }
    handleEvaluate(ev) {
        let toEvalDeal = ev.detail;
        let subProdName = !toEvalDeal.subProdSelected || 0 === toEvalDeal.subProdSelected.length ? '' : '-' + toEvalDeal.subProdSelected;
        this.prodSelected = toEvalDeal.prodSelected;
        // getDeal Apex method - performs Deal Calculation and returns Deal SObject
        getDeal({
            akamAccountId: toEvalDeal.akamAccId,
            prodFullName: toEvalDeal.prodSelected + subProdName,
            packComp: toEvalDeal.packComp,
            requestedHours: toEvalDeal.requestedHours,
            requestedPriceLocal: toEvalDeal.requestedPrice,
            localCurrency: toEvalDeal.localCurrency,
            computedEsrLocal: toEvalDeal.computedEsr,
            loeId: toEvalDeal.loeId,
            isNapCustomer: toEvalDeal.isNapCustomer,
            isBelowMinPackageComp: toEvalDeal.isBelowMinPackageComp
        })
            .then(result => {
                this.rightPanelTransition = true;
                this.showApprovalOptions = true;
                this.deal = Object.assign({ Id: this.deal.Id}, JSON.parse(result));
                this.deal.sobjectType = this.deal.attributes.type;
                delete this.deal.attributes; 
            })
            .catch(error => {

                let errorCode  = error && error.body && error.body.message ;
                let errorConfig = ERROR_MSGS[errorCode] || ERROR_MSGS.ERR_DEAL_EVAL;
                serverCallError(this, error, errorConfig);
            });
    }

    handleOtherProduct(ev) {
        const otherProdInfo = ev.detail;
        // Save "Other" Deal and Open Sticky Toast Notification, with link to the Deal Record
       saveOtherDeal({ akamAccId: ev.detail.akamAccId,
                    prodSelected: ev.detail.prodSelected,
                    productName: ev.detail.productName,
                    productDescription: ev.detail.productDescription,
                    approvalType: ev.detail.approvalType,
                    explanationAndJustification: ev.detail.explanationAndJustification,
                    localCurrency: ev.detail.localCurrency,
                    requestedPrice:ev.detail.requestedPrice,
                    priceListPrice: ev.detail.priceListPrice,
                    isNapCustomer: ev.detail.isNapCustomer
                })
       // If Deal is Saved Successfully, Get Deal Record Page URL ( to Show Toast Notification )
      .then(result => {
        this.showApprovalOptions = false;
        this.deal = {Id: result}
        
          // Refresh Dataservcice
           refreshApex(this.dealRecordResult);
          this[NavigationMixin.GenerateUrl]({
              type: 'standard__recordPage',
              attributes: {
                  recordId: result,
                  actionName: 'view',
              },
          })
          // Show Toast Notification
          .then(url => {
               this.dealToastNotification(url);
          });
      })
      .catch(error => {
           serverCallError(this, error, ERROR_MSGS.ERR_DEAL_SAVE);
      });
        
    }

    get dealEvalutionMessage() {
        this.defaultTab = this.deal.Calculation_Type__c === 'ESR'? 'esr': 'eps';
        return CALC_MSG[this.deal.Calculation_Type__c];
    }

    // Handle Approve/ Reject/ Escalate Actions
    handleEvalAction(ev) {

        ev.preventDefault();

       if(ev.detail.action === 'Approve') {
           this.deal.Evaluation_Action__c = 'Approved';
           this.deal.Approval_Stage__c = 'Closed';
       } else if(ev.detail.action === 'Reject') {
           this.deal.Evaluation_Action__c = 'Rejected';
           this.deal.Approval_Stage__c = 'Closed';
       } else if(ev.detail.action === 'Escalate') {
           this.deal.Evaluation_Action__c = 'Escalated'
           this.deal.Approval_Stage__c = 'SLM/SLD';
       }
       this.deal.Comments__c = ev.detail.comments;
       this.deal.Commented_By__c = ev.detail.approverType;
       this.showApprovalOptions = false;

       // Save Deal and Open Sticky Toast Notification, with link to the Deal Record
       saveDeal({ deal: this.deal })
            // If Deal is Saved Successfully, Get Deal Record Page URL ( to Show Toast Notification )
           .then(result => {
               // Refresh Dataservcice
                refreshApex(this.dealRecordResult);
               this[NavigationMixin.GenerateUrl]({
                   type: 'standard__recordPage',
                   attributes: {
                       recordId: result,
                       actionName: 'view',
                   },
               })
               // Show Toast Notification
               .then(url => {
                    this.dealToastNotification(url);
               });
           })
           .catch(error => {
                serverCallError(this, error, ERROR_MSGS.ERR_DEAL_SAVE);
           });
   }

    connectedCallback() {
        loadStyle(this, noheader);
        loadStyle(this, modal);
    }

    dealToastNotification(url) {
        const event = new ShowToastEvent({
            "title": "Success!",
            "message": this.mode === 'edit'? "Record updated! {0}!": "Record created! {0}!",
            "variant": "success",
            "mode": "sticky",
            "messageData": [
                {
                    url,
                    label: 'Open Deal Page'
                }
            ]
        });
        this.dispatchEvent(event);
    }

    dealRecordResult;
    @wire(getRecord, { recordId: '$recordId', fields: DEAL_FIELDS  })  // }) layoutTypes: "Full"   
    getRecord(result ) {
        this.dealRecordResult = result;
        let { data, error } = result;
        if (error) {
            serverCallError(this, error, ERROR_MSGS.ERR_DEAL_LOAD);
        }
        if (data) {
            this.deal = {};
            this.rightPanelTransition = true;
            for(let [fName, fValue] of Object.entries(data.fields)) {
                this.deal[fName] = fValue.value;
            }
            this.deal.Account__r = {};
            for(let [fName, fValue] of Object.entries(data.fields.Account__r.value.fields)) {
                this.deal.Account__r[fName] = fValue.value;
            }
            
            this.deal.sobjectType = DEAL_SOBJ_TYPE;
            this.prodSelected = this.deal.GSS_Product_Name__c;
        }
    }

    get formCss() {
        let fCss = 'slds-col slds-size_1-of-1 slds-p-right_x-small flexed form row2';
        let fLeftCss = 'slds-col slds-size_1-of-1 slds-medium-size_4-of-12 slds-large-size_4-of-12 slds-p-right_x-small flexed formLeft row2';

        return this.rightPanelTransition ? fLeftCss : fCss;

    }

    get dashBoardCss() {
        if (this.rightPanelTransition) {
            return "slds-col slds-size_1-of-1 slds-medium-size-size_8-of-12 slds-large-size_8-of-12 flexed ";
        }
        return "slds-col slds-size_1-of-1 slds-medium-size-size_8-of-12 slds-large-size_8-of-12 flexed slds-hide ";
    }

}