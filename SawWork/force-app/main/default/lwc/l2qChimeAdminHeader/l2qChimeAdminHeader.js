/**
*  @Date		:	May 2 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Header for Chime Questionanaire application
*/

import { api, track, wire, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['PAC_Product_Catalog__c.Product_Name__c'];

export default class L2qChimeAdminHeader extends NavigationMixin(LightningElement) {

    @api productid;
    @track productName;

    product;

    @wire(getRecord, { recordId: '$productid', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading product',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.product = data;
            this.productName = this.product.fields.Product_Name__c.value;
        }
    }

    connectedCallback() {
        //Promise.all([
            //loadScript(this, noheader);
            this.productName = "Adaptive media";
       // ])
    }

    navigateToProductSelection() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                //Name of any CustomTab. Visualforce tabs, web tabs, Lightning Pages, and Lightning Component tabs
                apiName: 'Chime_Admin_Wizard'
            }
        })
    }
    
}