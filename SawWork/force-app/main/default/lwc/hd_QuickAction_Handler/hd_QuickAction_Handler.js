import { LightningElement, wire, api } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import hdQuickActionClick from '@salesforce/messageChannel/hdQuickActionClick__c';
export default class Hd_QuickAction_Handler extends LightningElement {
    @api recordId;
    @wire(MessageContext)
    messageContext;
    quickAction;
    styleWidth = '';
    supportedQuickActions = ['NewTask','fillPIR','fillSONew','fillSOEdit'];
    data;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                hdQuickActionClick,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        this.quickAction = message.quickAction;
        this.data = message?.data;
        if (this.supportedQuickActions.includes(this.quickAction)) {
            let modal = this.template.querySelector('[data-id="modal"]');
            modal.open();
        }
    }

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get showNewTask() {
        return this.quickAction === 'NewTask';
    }

    get showNewPIR() {
        return this.quickAction === 'fillPIR';
    }

    get showNewSO() {
        return (this.quickAction === 'fillSONew' || this.quickAction === 'fillSOEdit');
    }

    get title() {
        if (this.quickAction === 'NewTask') {
            return 'New Task';
        }
        else if(this.quickAction === 'fillPIR') {
            this.styleWidth = "slds-modal_small";
            return 'New Post Implementation Review';
        }
        else if(this.quickAction === 'fillSONew') {
            this.styleWidth = "slds-modal_small";
            return 'New Service Outage';
        }
        else if(this.quickAction === 'fillSOEdit') {
            this.styleWidth = "slds-modal_small";
            return 'Edit Service Outage';
        }
        return '';
    }

    handleCloseModal() {
        this.template.querySelector('[data-id="modal"]').close();
    }
}