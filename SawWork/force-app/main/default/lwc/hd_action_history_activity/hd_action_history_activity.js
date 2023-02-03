import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import switchToNewEmailUI from '@salesforce/apex/HD_Email_Composer_DockedCtrl.switchToNewUI';
import hdRecordPageCommunications from '@salesforce/messageChannel/hdRecordPageCommunications__c';

export default class Hd_History_Activity extends LightningElement {
    @api item;
    @api isExpanded;
    @api when;
    @wire(MessageContext)
    messageContext;
    @api isTicketClosed;
    switchToNewEmailUI;

    @wire(switchToNewEmailUI,{ customMetadataRecName : 'HD_New_UI_List', settingValue : 'ReplyEmail' })
    switchToNewEmailUI({data, error}) {
        if (data) {
            this.switchToNewEmailUI = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

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
        const regexp = /<b>[a-zA-Z 0-9-:/_]*<\/b>/;
        let actionActivity = {
            isActionActivity: true,
            title: this.item['Action History'][0].action.match(regexp).toString().replace('<b>', '').replace('</b>', ''),
            when: new Date(this.when).toISOString(),
            icon: this.item['Action History'][0].action.includes('Note') ? 'standard:note' : 'standard:email',
            daysAgo: (diffDays === 0) ? '' : (diffDays === 1) ? 'TODAY' : diffDays + ' DAYS AGO',
            who: this.item['Action History'][0].user_staff_name,
            whoId: '/' + this.item['Action History'][0].user_staff_ID,
            duration: this.item['Action History'][0].duration,
            note: this.item['Action History'][0].note,
            richNote: this.item['Action History'][0].richNote,
            highlightActivity: diffDays === 1,
            actionHistoryDescription: this.item['Action History'][0].action_History_Description,
            email: false,
            textBody: '',
            historyId: this.item['Action History'][0].incident_History_ID
        };
        if (actionActivity.title === 'Email Sent' || actionActivity.title === 'Email Received') {
            if(actionActivity.who && actionActivity.title === 'Email Sent') {
                actionActivity.title = 'Email Sent by';
            }
            else if(actionActivity.who && actionActivity.title === 'Email Received') {
                actionActivity.title = 'Email Received from';
            }
            actionActivity.email = true;
            if (actionActivity.richNote) {
                actionActivity.textBody = actionActivity.richNote;
            }
            else if (actionActivity.note) {
                actionActivity.textBody = actionActivity.note;
            }
        }
        else if (actionActivity.title === 'Incident Opened From Self Service') {
            actionActivity.textBody = actionActivity.actionHistoryDescription;
            actionActivity.email = false;
            actionActivity.icon = 'standard:case';
        }
        else if (actionActivity.title === 'Internal Note' || actionActivity.title === 'Transfer Note' || actionActivity.title === 'Client Note' || actionActivity.title === 'Notes') {
            actionActivity.title = 'added ' + actionActivity.title;
            actionActivity.email = false;
            if (actionActivity.note) {
                actionActivity.textBody = actionActivity.note;
            }
            else if(actionActivity.richNote) {
                actionActivity.textBody = actionActivity.richNote;
            }
            else {
                actionActivity.textBody = 'Note';
            }
        }
        else {
            actionActivity.icon = 'standard:work_step';
            actionActivity.email = false;
            if (actionActivity.note) {
                actionActivity.textBody = actionActivity.note;
            }
            else if (actionActivity.richNote) {
                actionActivity.textBody = actionActivity.richNote;
            }
            else {
                actionActivity.textBody = actionActivity.actionHistoryDescription;
            }
        }
        return actionActivity;
    }
    
    replyMail() {
        if(this.switchToNewEmailUI){
            let message = {hdRecordPageCommunications: 'openEmailDocker',tempHistoryId:this.itemTemplate.historyId};
            publish(this.messageContext, hdRecordPageCommunications, message);
        }else{
            this.dispatchEvent(new CustomEvent('replymailaction', {
                detail: { historyId: this.itemTemplate.historyId },
                bubbles: true,
                composed: true
            }));     
        }
    }
}