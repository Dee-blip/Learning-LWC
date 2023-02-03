import { LightningElement, api } from 'lwc';

export default class DdHoursOverviewTrend extends LightningElement {
    @api deal;

    get psProjectBudgetHours(){
        return this.deal.PS_Project_Budget_Hours__c || 0;
    }

    get psAvgNonBillableHours() {
        return this.deal.PS_Avg_Non_Billable_Hours__c || 0;
    }
}