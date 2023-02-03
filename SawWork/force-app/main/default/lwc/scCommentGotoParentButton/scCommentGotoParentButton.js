import { LightningElement, track, api, wire } from 'lwc';

import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import GO_TO_CONVERSATION from '@salesforce/label/c.JV_GotoConversation';	

export default class ScCommentGotoParentButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @api autoRedirect;
    record;
    goToConversation = GO_TO_CONVERSATION;
    // fields = ;
    goToCasePage() {
        this.navigateToParentRecordPage();
    }

    @track hideButton;
    
    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View']})
        redirectToParent({data}){
            if(data) {
                this.record = data;
                const app = this.record.fields.Application__c.value;
                
                this.hideButton = app === 'JARVIS' && this.autoRedirect;
                if(app === 'JARVIS' && this.autoRedirect) {
                    console.log('Navigating to Parent');
                    this.navigateToParentRecordPage();
                }
            }
        }

    navigateToParentRecordPage() {
        if(!this.record.fields.Parent_ID__c) {
            return;
        }
        // Navigate to the Parent Record
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.record.fields.Parent_ID__c.value,
                actionName: 'view',
            },
            state: {
                c__communityCommentsId: this.recordId
            }
        });
    }
}