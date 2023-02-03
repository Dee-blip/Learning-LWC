import { LightningElement, track, api, wire } from 'lwc';
import getContractInfo from '@salesforce/apex/SC_DD_DealDeskCont.getContractInfo';
import { serverCallError } from 'c/scUtil';
const ERR_CONTRACT = {
    title: 'Error fetching contract Info',
    variant: 'error',
};
export default class DdContractInfo extends LightningElement {

    @api akamAccountId;
    @track contractData;

    @wire(getContractInfo, { accountId: '$akamAccountId' })
    contractInfo({ data, error }) {
        if (data) {
            let indexOfOther = data.findIndex( el => el.serviceProduct === 'Others');
            if(indexOfOther !== -1 ) {
                this.contractData = [...data.slice(0, indexOfOther), ...data.slice(indexOfOther + 1), data[indexOfOther]];
            } else {
                this.contractData = data;
            }
            
        } else if (error){
            serverCallError(this, error, ERR_CONTRACT);
        }
    }
}