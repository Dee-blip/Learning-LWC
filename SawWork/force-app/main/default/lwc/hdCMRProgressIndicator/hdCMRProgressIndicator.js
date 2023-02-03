import { LightningElement, api, track, wire } from 'lwc';
import getChange from '@salesforce/apex/HD_CMR_ChangeCalendar.getChange';
import approveOrRejectCMR from '@salesforce/apex/HD_CMR_ChangeCalendar.approveOrRejectCMR';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import hdQuickActionClick from '@salesforce/messageChannel/hdQuickActionClick__c';
import { loadStyle } from 'lightning/platformResourceLoader';
import HD_CMR_ProgressIndicator_Style from '@salesforce/resourceUrl/HD_CMR_ProgressIndicator_Style';

export default class HdCMRProgressIndicator extends LightningElement {
    @track listOfApprovals = [];
    @track recordData;
    @track selectedStep;
    @api recordId;
    @api isNotRecordDetailPage;
    @api channelName = '/event/CMR_Approval_Status_Event__e';
    currentStepProcessWorkItemId;
    approveRejectStep;
    popupTitle;
    buttonLabel;
    approveRejectComments;
    currentStepIndex;
    isLoading;
    expandCollapseIcon = 'utility:chevronright';
    isExpanded = false;
    isStyleLoaded;

    renderedCallback() {
        if (!this.isStyleLoaded) {
            Promise.all([
                loadStyle(this, HD_CMR_ProgressIndicator_Style)
            ]).then(() => {
                this.isStyleLoaded = true;
            })
                .catch(error => {
                    console.log(error.body.message);
                });
        }
    }

    @wire(getChange, { Id: '$recordId' })
    getRecordDataCallback(result) {
        if (result.data) {
            this.recordData = result.data;
        }
    }

    @wire(MessageContext)
    messageContext;

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
        if (message.quickAction === 'Recall') {
            this.popupTitle = 'Recall CMR';
            this.buttonLabel = 'Recall';
            let modal = this.template.querySelector('[data-id="modalPopup"]');
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

    onExpandCollapseClicked() {
        this.isExpanded = !this.isExpanded;
        this.expandCollapseIcon = (this.isExpanded) ? 'utility:chevrondown' : 'utility:chevronright';
    }

    @api set approvalList(value) {
        let formatter = new Intl.DateTimeFormat('en', {
            year: "numeric",
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: "true"
        })

        let approvedSteps = [];
        let rejectedSteps = [];
        let pendingSteps = [];
        for (let key in value) {
            if (value[key]) {
                let temp = { ...value[key] };
                temp.isSubmitted = value[key].status === 'Submitted';
                temp.isApproved = value[key].status === 'Approved';
                temp.isRejected = value[key].status === 'Rejected';
                temp.isPending = value[key].status === 'Pending';
                if(temp.displayName === 'Enterprise Financial Systems '){
                    temp.displayName = 'EFS';
                }else if(temp.displayName === 'Enterprise Management Systems '){
                    temp.displayName = 'EMS';
                }
                temp.approvalDate = (value[key]?.sysModDate) ? formatter.format(new Date(value[key]?.sysModDate)) : '';
                if (value[key].status === 'Submitted' || value[key].status === 'Approved') {
                    approvedSteps.push(temp);
                }
                else if (value[key].status === 'Rejected') {
                    rejectedSteps.push(temp);
                }
                else if (value[key].status === 'Pending') {
                    pendingSteps.push(temp);
                }
            }
        }
        this.listOfApprovals = [...approvedSteps, ...rejectedSteps, ...pendingSteps];
        
        this.selectedStep = this.listOfApprovals?.filter(item => item.startFlag === true)[0] ?? this.listOfApprovals[this.listOfApprovals.length - 1];
        this.currentStepIndex = this.selectedStep?.displayName;
    }

    get approvalList() {
        return this.listOfApprovals;
    }

    onStepChange(event) {
        this.currentStepIndex = parseInt(event.detail.value, 10);
    }

    onApproveClicked(event) {
        this.popupTitle = 'Approve CMR';
        this.buttonLabel = 'Approve';
        this.currentStepProcessWorkItemId = event.target.dataset.id;
        this.template.querySelector("[data-id='modalPopup']").open();
    }

    onRejectClicked(event) {
        this.popupTitle = 'Reject CMR';
        this.buttonLabel = 'Reject';
        this.currentStepProcessWorkItemId = event.target.dataset.id;
        this.template.querySelector("[data-id='modalPopup']").open();
    }

    onStepSelected(event) {
        this.selectedStep = this.listOfApprovals.filter(step => step.processWorkItemId === event.target.dataset.id)[0];
    }

    onChildApproveRejectClicked(event) {
        this.popupTitle = event.detail.buttonLabel + ' CMR';
        this.buttonLabel = event.detail.buttonLabel;
        this.currentStepProcessWorkItemId = event.detail.processWorkItemId;
        this.template.querySelector("[data-id='modalPopup']").open();
    }

    onModalApproveRejectClicked() {
        this.template.querySelector("[data-id='modalPopup']").close();
        this.isLoading = true;
        let messageString = (this.buttonLabel === 'Approve') ? 'Approv' : this.buttonLabel;
        approveOrRejectCMR({
            workingItemId: this.currentStepProcessWorkItemId,
            comments: this.approveRejectComments,
            actionToBePerformed: this.buttonLabel,
            currentCMR: this.recordData
        })
            .then(() => {
                if (!this.isNotRecordDetailPage) {
                    /* eslint-disable-next-line */
                    eval("$A.get('e.force:refreshView').fire();");
                }
                this.isLoading = false;
                this.currentStepProcessWorkItemId = '';
                this.showToast('CMR is ' + messageString + 'ed successfully.', 'Success', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.currentStepProcessWorkItemId = '';
                let message = (error?.body?.pageErrors?.length > 0) ? error?.body?.pageErrors[0]?.message : 'Error ' + messageString + 'ing CMR'
                this.showToast(message, '', 'error');
            });
    }

    onCloseModal() {
        this.template.querySelector("[data-id='modalPopup']").close();
    }

    onCommentsEntered(event) {
        this.approveRejectComments = event.target.value.trim();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(event);
    }

    get showProgressIndicator() {
        return this.listOfApprovals && this.listOfApprovals.length > 0;
    }

    get hasError() {
        return this.selectedStep?.isRejected ?? false;
    }

    get firstColWidth() {
        return "width:" + (1 / (this.listOfApprovals?.length * 2)) * 100 + "%;";
    }

    get secondColWidth() {
        return "width:" + ((this.listOfApprovals?.length - 1) / this.listOfApprovals?.length) * 100 + "%;";
    }
}