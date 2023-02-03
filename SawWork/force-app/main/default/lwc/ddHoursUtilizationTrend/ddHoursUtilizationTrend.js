import { LightningElement, api, track } from 'lwc';

export default class DdHoursUtilizationTrend extends LightningElement {
    @api deal;

    get psHours() {
        return (this.deal.PS_Hours__c || 0).toFixed(2);
    }
    get psDeliveryCost(){
        return (this.deal.PS_Delivery_Cost__c || 0).toFixed(2);
    }
    get akaTecHours() {
        return (this.deal.AkaTec_Hours__c || 0).toFixed(2);
    }

    get akaTecDeliveryCost() {
        return (this.deal.AkaTec_Delivery_Cost__c || 0).toFixed(2);
    }
    get socHours() {
        return (this.deal.SOC_Hours__c || 0).toFixed(2);
    }

    get soccDeliveryCost() {
        return (this.deal.SOCC_Delivery_Cost__c || 0).toFixed(2);
    }

    get totalCost() {
        return (this.deal.Total_Delivery_Cost__c || 0).toFixed(2);
    }
}