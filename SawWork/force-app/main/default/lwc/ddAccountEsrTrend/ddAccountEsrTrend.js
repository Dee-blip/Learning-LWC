import { LightningElement, api } from 'lwc';

export default class DdAccountEsrTrend extends LightningElement {
    @api deal;
    @api prodName;

    get isUsd() {
        return this.deal.Local_Currency__c === 'US (USD)';
    }

    get currency() {
        let curr = this.deal.Local_Currency__c;
        return curr && curr.substring(curr.lastIndexOf('(') + 1, curr.lastIndexOf(')'));
    }

    get listPrice() {
        return this.isIntegrationProduct() ? 0: this.deal.List_Price__c;
    }

    get listPriceLocal() {
        return  this.isIntegrationProduct() ? 0: this.deal.List_Price_Local__c;
    }

    isIntegrationProduct() {
        return this.prodName && ( this.prodName.includes('Managed Integration') || this.prodName.includes( 'Standard Integration'));
    }
}