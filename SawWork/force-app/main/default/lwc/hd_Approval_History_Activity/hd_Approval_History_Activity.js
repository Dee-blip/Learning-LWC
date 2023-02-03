import { LightningElement, api, wire, track } from 'lwc';
import getApprovalHistory from '@salesforce/apex/HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate';

export default class Hd_Approval_History_Activity extends LightningElement {
    columns = [
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Assigned To', fieldName: 'assignedToId', type: 'url', typeAttributes: { label: { fieldName: 'assignedTo' } } },
        { label: 'Actual Approver', fieldName: 'actualApproverId', type: 'url', typeAttributes: { label: { fieldName: 'actualApprover' } } },
        { label: 'Comment', fieldName: 'comment', type: 'text' },
        { label: 'Date', fieldName: 'date', type: 'datetime' }
    ];
    approvals;
    @api item;
    @api isExpanded;
    @api when;
    @api recordId;
    @track activity;
    showPastApprovals;
    activeSections = [];
    expandCollapseText = 'Show Past Approvals';
    expandCollapseIcon = 'utility:expand_all';
    get itemClass() {
        return (this.isExpanded) ? 'slds-timeline__item_expandable slds-timeline__item_task slds-is-open' : 'slds-timeline__item_expandable slds-timeline__item_task';
    }

    toggleState() {
        /* eslint-disable-next-line */
        this.isExpanded = !this.isExpanded;
    }

    get stateIcon() {
        return (this.isExpanded) ? 'utility:switch' : 'utility:chevronright';
    }

    get itemTemplate() {
        let today = new Date();
        let when = new Date(this.when);
        let timeDiff = Math.abs(today.getTime() - when.getTime());
        let diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24));
        this.activity = {
            title: 'Approvals',
            when: new Date(this.when).toISOString(),
            daysAgo: (diffDays === 0) ? '' : (diffDays === 1) ? 'TODAY' : diffDays + ' DAYS AGO',
            highlightActivity: diffDays === 1,
            approvals: []
        };
        for (let historyItem of this.item['Approval History']) {
            this.getApprovalItem(historyItem, this.activity.approvals);
        }
        return this.activity;
    }

    get pastApprovalsExist() {
        return this.approvals && this.approvals.length > 0;
    }

    onShowPastApprovalsClicked() {
        this.showPastApprovals = !this.showPastApprovals;
        this.expandCollapseIcon = (this.showPastApprovals) ? 'utility:collapse_all' : 'utility:expand_all';
        this.expandCollapseText = (this.showPastApprovals) ? 'Hide Past Approvals' : 'Show Past Approvals';
    }

    @wire(getApprovalHistory, {
        targetObjectIdvalue: '$recordId',
        rowCount: '100'
    })
    getApprovalHistoryCallback(result) {
        if (result.data) {
            this.approvals = [];
            for (let activityDate in result.data) {
                if (result.data[activityDate]['Approval History']) {
                    for (let historyItem of result.data[activityDate]['Approval History']) {
                        this.getApprovalItem(historyItem, this.approvals, activityDate);
                    }
                }
            }
        }
        else if (result.error) {
            this.dispatchEvent(new CustomEvent('error', { detail: result.error.body.message }));
        }
    }

    getApprovalItem(historyActivity, container, activityDate) {
        if (activityDate === this.when) {
            return;
        }
        if (historyActivity.stepandworkitemunifiedlist) {
            let approvalItem = { title: '', data: [] };
            if (activityDate) {
                let options = { year: 'numeric', month: 'short', day: '2-digit' };
                let date = new Date(activityDate);
                let stringDate = date.toLocaleDateString("en-US", options);
                let itemsWithSimilarName = this.activeSections.filter(sectionName => sectionName.includes(stringDate));
                if (itemsWithSimilarName.length === 1) {
                    let oldItems = container.filter(item => item.title === stringDate);
                    oldItems[0].title = oldItems[0].title + '(1)';
                    let i = this.activeSections.indexOf(stringDate);
                    this.activeSections[i] = oldItems[0].title;
                }

                approvalItem.title = stringDate + ((itemsWithSimilarName.length > 0) ? '(' + (itemsWithSimilarName.length + 1) + ')' : '');
            }
            this.activeSections.push(approvalItem.title);
            for (let approvalStep of historyActivity.stepandworkitemunifiedlist) {
                approvalItem.data.push({
                    id: approvalStep.assigned_To_id,
                    status: approvalStep.stepstatus,
                    assignedTo: approvalStep.assigned_To,
                    assignedToId: '/' + approvalStep.assigned_To_id,
                    actualApprover: approvalStep.actual_Approver,
                    actualApproverId: '/' + approvalStep.actualApproverId,
                    comment: approvalStep.approval_Comment,
                    date: approvalStep.stepcreatedDate
                });
            }
            container.push(approvalItem);
        }
    }

    handleExpandCollapseHistory() {
        let expandCollapseButton = this.template.querySelector('lightning-button-stateful');
        expandCollapseButton.selected = !expandCollapseButton.selected;
        this.template.querySelector('lightning-accordion').activeSectionName = (expandCollapseButton.selected) ? this.activeSections : [];
    }
}