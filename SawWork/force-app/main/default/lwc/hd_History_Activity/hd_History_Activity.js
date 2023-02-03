import { LightningElement, api } from 'lwc';

export default class Hd_History_Activity extends LightningElement {
    @api item;
    @api isExpanded;
    @api when;
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
        let activity = {
            when: new Date(this.when).toISOString(),
            daysAgo: (diffDays === 0) ? '' : (diffDays === 1) ? 'TODAY' : diffDays + ' DAYS AGO',
            who: this.item.History[0].who,
            whoId: '/' + this.item.History[0].user,
            highlightActivity: diffDays === 1,
            fields: []
        };
        for (let historyItem of this.item.History) {
            if (historyItem) {
                if (historyItem.action === 'Created.') {
                    activity.title = 'created the ticket with the following details';
                }
                else if (!activity.title && historyItem.action.includes('from UNASSIGNED to <b>ASSIGNED</b>')) {
                    activity.title = 'assigned the ticket';
                }
                else if (!activity.title && historyItem.action.includes('Changed <b>Owner</b>')) {
                    activity.title = 'changed the Owner of the ticket';
                }
                else if (!activity.title && historyItem.action.includes('Changed <b>Approver</b>')) {
                    activity.title = 'changed the Approver on the ticket';
                }
                else if (!activity.title && historyItem.action.includes('to <b>CLOSED</b>')) {
                    activity.title = 'Closed the ticket';
                }
                else if (!activity.title && historyItem.action.includes('to <b>RESOLVED</b>')) {
                    activity.title = 'Resolved the ticket';
                }
                else if (!activity.title && historyItem.action.includes('Changed <b>Routing</b>')) {
                    activity.title = 're-routed the ticket';
                }

                const regexp = /<b>[a-zA-Z 0-9-:/_]*<\/b>/g;
                let matches = [...historyItem.action.matchAll(regexp)];
                if (matches[0] && matches[1]) {
                    let strippedFieldName = matches[0].toString().replace('<b>', '').replace('</b>', '');
                    let fieldValue = historyItem.action.includes(' from ') ?
                        historyItem.action.substring(historyItem.action.indexOf(' from ') + 6, historyItem.action.indexOf(' to ')) + ' --> ' + matches[1] : matches[1];
                    activity.fields = [...activity.fields, { fieldName: strippedFieldName, fieldValue: fieldValue }];
                }
            }
        }

        if (!activity.title) {
            activity.title = 'updated the ticket with following values';
        }
        return activity;
    }
}