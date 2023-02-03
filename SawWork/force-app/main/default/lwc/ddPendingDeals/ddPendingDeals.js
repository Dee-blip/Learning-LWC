import { LightningElement, track, wire } from 'lwc';
import getPendingDeals from '@salesforce/apex/SC_DD_DealDashboardCont.getPendingDeals';
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import {serverCallError} from 'c/scUtil';
const columns = [
    { label: 'Name', fieldName: 'dealUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, tooltip: { fieldName: 'Name' } } },
    { label: 'Account', fieldName: 'AccountName'},
    { label: 'Product', fieldName: 'ProductName'},
    { label: 'Zone', fieldName: 'Deal_Zone__c'},
    { label: 'Pending', fieldName: 'Approval_Stage__c'}
];


export default class DdPendingDeals extends NavigationMixin(LightningElement) {

    @track userId = Id;
    @track pendingDeals = [];
    @track columns = columns;


    @wire(getPendingDeals, {userId: '$userId'})
    processPendingDeals ({error, data}) {
        if (error) {
            serverCallError(this, error);
        } else if (data) {
            this.pendingDeals = [];
            data.forEach(dl => {
                let procDeal = Object.assign({}, dl);
                procDeal.AccountName = dl.Account__r.Name;
                procDeal.ProductName = dl.GSS_Product__r.Name;
                procDeal.dealUrl = '/' + dl.Id;
                this.pendingDeals.push(procDeal);
            });
        }
    }

    openDealPage(ev) {
        // Navigate to the Deal Record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: ev.currentTarget.dataset.id,
                actionName: 'view',
            },
        });
    }

}