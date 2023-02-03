import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const DEAL_FIELDS = ['SC_DD_Deal__c.Id','SC_DD_Deal__c.EPS_Zone__c', 'SC_DD_Deal__c.Expected_Profitability_Score__c', 'SC_DD_Deal__c.Calculation_Type__c',
                    'SC_DD_Deal__c.ESR_Zone__c', 'SC_DD_Deal__c.Computed_ESR__c', 'SC_DD_Deal__c.Computed_ESR_Local__c', 
                    'SC_DD_Deal__c.List_Price__c', 'SC_DD_Deal__c.List_Price_Local__c', 'SC_DD_Deal__c.List_ESR__c', 
                    'SC_DD_Deal__c.List_ESR_Local__c', 'SC_DD_Deal__c.Median_Profitability_Score__c', 'SC_DD_Deal__c.Local_Currency__c',
                    'SC_DD_Deal__c.Package_Comp_Info__c', 'SC_DD_Deal__c.Deal_Zone__c', 'SC_DD_Deal__c.GSS_Product__c','SC_DD_Deal__c.GSS_Product_Name__c',
                    'SC_DD_Deal__c.Account__c', 'SC_DD_Deal__c.Approval_Stage__c', 'SC_DD_Deal__c.LOE_Id__c' ] ;  

const SOBJ_TYPE = 'SC_DD_Deal__c';

export default class DdDealRecordInfo extends LightningElement {

    @track deal;
    @api recordId;

    get isEsrOnly() {
        return this.deal.Calculation_Type__c === 'ESR';
    }
    

    @wire(getRecord, { recordId: '$recordId', fields: DEAL_FIELDS })  //layoutTypes: "Full" })    
    getRecord({ data, error }) {
        if (error) {
            console.log('error ', error);
        }
        if (data) {
            this.deal = {};
            for(let [fName, fValue] of Object.entries(data.fields)) {
                this.deal[fName] = fValue.value;
            }

            this.deal.sobjectType = SOBJ_TYPE;
        }
    }
}