import { LightningElement,api,wire,track } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import classObject from "@salesforce/apex/P2r_Excel_Template_Manipulator.classObject"

const FIELDS = [
  'SBQQ__Quote__c.Prepared_For_End_User__c',
  'SBQQ__Quote__c.Opportunity_Reseller__c',
  'SBQQ__Quote__c.CreatedBy.Name',
  'SBQQ__Quote__c.CPQ_Quote_Type_Label__c',
  'SBQQ__Quote__c.SBQQ__EndDate__c',
  'SBQQ__Quote__c.SBQQ__ExpirationDate__c',
  'SBQQ__Quote__c.CPQ_Integration_Type__c',
  'SBQQ__Quote__c.CPQ_Order_Placed__c',
  'SBQQ__Quote__c.CurrencyIsoCode',
  'SBQQ__Quote__c.Name',
  'SBQQ__Quote__c.SBQQ__NetAmount__c',
  'SBQQ__Quote__c.CPQ_Biliing_Effective_Date__c',
  'SBQQ__Quote__c.SBQQ__SalesRep__r.Name',
  'SBQQ__Quote__c.Reseller_Akamai_Acct_ID__c',
  'SBQQ__Quote__c.Draft_water_mark__c'
]


export default class Cpq_p2r_excel_manipulate_data_wrapper_cmp extends LightningElement {
    @api recordId;
    @track state = {
        record:{},
        quotejson:{},
        error: undefined
    }    

      @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
      currentrecord({ error, data }) {
        if (data) {
            let cloned_state = { ...this.state };
            cloned_state.record = data;
            this.state = cloned_state;
            this.error = undefined;
            console.log('[data]'+ JSON.stringify(data.fields));
        } else if (error) {
            this.error = error;
            this.record = undefined;
            console.log('[ERRROR] '+error)
        }
    }// Wire Service to get your things done :)
    
    @wire(classObject, {recordId : '$recordId'})
    wiredData({data,error}){
      if(data){
        let cloned_state = {...this.state};
        cloned_state.quotejson = JSON.parse(data.response);
        this.state  = cloned_state;
        this.error = undefined;
        console.log('[data]'+ data.response);
      }
      else if( error ){
        this.error = error;
        this.record = undefined;
        console.log('[ERRROR] '+error.message);
      }
    }

    handleExcelpayload = ()=>{
        let payload = this.template.querySelector('c-p2r_excel_template_manipulator').excelpayload();
       payload.then((res)=>{console.log(JSON.stringify(res))})
        
    }//callchildMethod


}//END