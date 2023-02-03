import { LightningElement, api } from 'lwc';

export default class Hd_CMR_Approvals_Details_View extends LightningElement {
    @api approvalDetails;
    @api selectedStep;
    selectedView = 'compact';

    get options() {
        return [
            { label: 'Compact', value: 'compact' },
            { label: 'Detailed', value: 'detailed' },
        ];
    }

    get isCompactView() {
        return this.selectedView === 'compact';
    }

    onViewChanged(event) {
        this.selectedView = event.detail.value;
    }

    onApproveRejectClicked(event) {
        this.dispatchEvent(new CustomEvent('approverejectclick', {
            bubbles: true,
            composed: true,
            detail: {
                buttonLabel: event.target.alternativeText ?? event.target.label,
                processWorkItemId: event.target.dataset.id
            }
        }));
    }
}