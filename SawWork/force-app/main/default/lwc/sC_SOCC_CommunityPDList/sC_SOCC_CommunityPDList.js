import { LightningElement, wire, track} from 'lwc';
import {LABELS} from './i18n';
import getPDList from '@salesforce/apex/SC_SOCC_CommunityController.getPDList';
import loading from '@salesforce/resourceUrl/loading';
//import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: LABELS.ACCOUNT_NAME_COLUMN, fieldName:"PDRecAccountName" },
    //{ label: 'Policy Domain', fieldName:"PDRecName" ,type:'button', initialWidth: 135, typeAttributes: {label: { fieldName: 'PDRecName' },variant:'base'}, sortable: true},
    { label: LABELS.POLICY_DOMAIN_COLUMN, fieldName:"PDRecName"},
    { label: LABELS.PRODUCT_COLUMN, fieldName: 'PDRecProduct' },
    { label: LABELS.ADDITIONAL_PRODUCT_COLUMN, fieldName: 'PDRecAdditionalProduct' },
    
    {label:LABELS.RUNBOOK_COLUMN,type: "button",border: 'none', typeAttributes: {
        label: LABELS.VIEW_BUTTON,
        name: 'View',
        title: LABELS.VIEW_BUTTON,
        disabled: false,
        value: 'view',
        iconPosition: 'left'
    }}
];
export default class ApexDatatableExample extends LightningElement {
    labels = LABELS;
    @track loading1;
    @track error;
    @track columns = columns;
    @track pdList = ' ';
    @track isPdListLoading;
    connectedCallback() {
        this.isPdListLoading = true;
        getPDList().then((data) => {
            this.pdList = data && data.length ? data : null;
            this.isPdListLoading = false;
        }).catch((error) => {
            this.isPdListLoading = false;
            console.log('error ', error);
        })
    }

    // @wire(getPDList)


    
    // procesPds({data, error}) {
        
    //     this.pdList = data && data.length ? data : null;
    //     if(this.pdList != null){
    //         this.loading1 = 'LOADING';
    //     }
    //     else{
    //         this.loading1 = 'LOADING';
    //     }
    //     console.log('data ', data);
    //     console.log('error ', error);
        
    // }

    // @api
    navigateToRecordViewPage(event) {
        if(event.detail.action.name === 'View')
            window.open('/customers/s/run-books?recordId='+event.detail.row.pdId,'_self');
        else
            window.open('/customers/s/detail/' + event.detail.row.pdId,'_self');
    }
}