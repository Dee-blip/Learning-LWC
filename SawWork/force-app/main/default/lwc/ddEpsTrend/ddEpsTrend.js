import { LightningElement, api } from 'lwc';

export default class DdEpsTrend extends LightningElement {
    @api deal;
    get zone(){
        return this.deal.EPS_Zone__c ? this.deal.EPS_Zone__c.toUpperCase(): '--';
    }
    get epsScore() {
        return this.deal.Expected_Profitability_Score__c && this.deal.Expected_Profitability_Score__c.toFixed(2);
    }
    get medianProfitabilityScore() {
        return (this.deal.Median_Profitability_Score__c || 0).toFixed(2);
    }
}