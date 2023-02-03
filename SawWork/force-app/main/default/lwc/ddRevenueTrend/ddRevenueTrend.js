import { LightningElement, api, track } from 'lwc';

export default class DdRevenueTrend extends LightningElement {

    _deal;
    @api get deal() {
        return this._deal;
    }

    @track currMarginClr;
    set deal(value) {
        this._deal = value;
        this.currMarginClr = this.deal.EPS_Zone__c ? this.deal.EPS_Zone__c.toLowerCase() : 'grey';
    }

    get totalRevenueFiltered() {
        return (this.deal.Total_Revenue_Filtered__c || 0).toFixed(2);
    }
    get currentProfitabilityScore () {
        return (this.deal.Current_Profitability_Score__c || 0).toFixed(2);
    }
    get currentCustomerRoleMrr() {
        return (this.deal.Current_Customer_Role_MRR__c || 0).toFixed(2);
    } 
    get averageMonthlyRevenue() {
        return (this.deal.Average_Monthly_Revenue__c || 0).toFixed(2);
    } 

    get filteredRevenueMonths() {
        return this.deal.Filtered_Revenue_Months__c || '--';
    }

    get revenueMonths() {
        return this.deal.Revenue_Months__c || '--';
    }

    get totalRevenueUnfiltered() {
        return (this.deal.Total_Revenue_Unfiltered__c || 0).toFixed(2);
    }

}