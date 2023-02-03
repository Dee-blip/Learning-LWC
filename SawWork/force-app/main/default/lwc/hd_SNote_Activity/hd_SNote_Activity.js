import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hd_SNote_Activity extends NavigationMixin(LightningElement) {
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
            title: 'attached a document on Webex Chat',
            when: new Date(this.when).toISOString(),
            daysAgo: (diffDays === 0) ? '' : (diffDays === 1) ? 'TODAY' : diffDays + ' DAYS AGO',
            who: this.item.Snote[0].who,
            whoId: '/' + this.item.Snote[0].user,
            highlightActivity: diffDays === 1,
            contentTitle: this.item.Snote[0].incident_History_ID_name,
            contentPrreview: this.item.Snote[0].richNote,
            contentId: this.item.Snote[0].incident_History_ID
        };

        return activity;
    }

    onPreviewClicked(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: event.target.dataset.id
            }
        })
    }
}