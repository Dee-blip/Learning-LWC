import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getApprovalHistory from '@salesforce/apex/HD_CMR_ChangeCalendar.getApprovalHistory';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';

export default class Hd_CMR_Preview extends NavigationMixin(LightningElement) {
    @api record;
    isLoading = true;
    activeSections = ['CLI_DET', 'TIC_DET', 'TIC_SUM'];
    isOpen = false;
    isClose = true;
    subscription;
    channelName = '/event/CMR_Approval_Status_Event__e';
    @track wiredResponse;
    @track approvalList;

    connectedCallback() {
        // Register error listener     
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }
    get panelState() {
        return (this.isOpen) ? 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open slideUp' :
            'slds-docked-composer slds-grid slds-grid_vertical slideDown';
    }

    get minimizeIcon() {
        return 'utility:minimize_window';
    }

    onMinimizeClicked() {
        this.isOpen = !this.isOpen;
    }

    onFormLoaded() {
        this.isLoading = false;
    }

    @api forceOpen() {
        this.isClose = false;
        this.isOpen = true;
    }

    @wire(getApprovalHistory, { currentCMRId: '$recordId' })
    getApprovalDetails(result) {
        this.wiredResponse = result;
        if (result.data) {
            this.approvalList = result?.data;
        }
        else if (result.error) {
            console.log('Hd_CMR_Preview.getApprovalDetails : ' + result.error);
            this.logError('Hd_CMR_Preview.getApprovalDetails : ' + JSON.stringify(result.error));
        }
    }

    get recordId() {
        return this.record?.Id.replace('/', '');
    }

    get recordName() {
        return this.record?.Name;
    }

    get recordStatus() {
        return this.record?.BMCServiceDesk__Status__c;
    }

    get statusBadgeClass() {
        return this.recordStatus?.toUpperCase().replace(/ /g, '');
    }

    onCloseClicked() {
        this.isClose = true;
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            if (this.recordId === response.data.payload.Record_ID__c) {
                refreshApex(this.wiredResponse);
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

    registerErrorListener() {
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }

    naivgateToCMRRecord() {
        // Generate a URL to a User record page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        }).then((url) => {
            window.open(url, '_blank');
        });
    }
}