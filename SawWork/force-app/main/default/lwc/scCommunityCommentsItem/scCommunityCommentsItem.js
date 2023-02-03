import { LightningElement, api } from 'lwc';
import timeZone from '@salesforce/i18n/timeZone';
import locale from '@salesforce/i18n/locale';

export default class ScCommunityCommentsItem extends LightningElement {
    @api comment = {};
    @api highlight;
    timeZone = timeZone;
    locale = locale;
    get chatMessageCss() {
        let cssClass = this.comment.isOutboundMessage
                                ? 'slds-chat-message__text_outbound outbound-message'
                                : 'slds-chat-message__text_inbound inbound-message';
        if(this.highlight) {
            cssClass = cssClass + ' highlight ';
        }
        return cssClass + ' ' + this.comment.styleOverride;

    }

    get chatItemCss() {
        return this.comment.isOutboundMessage
                                ? 'slds-chat-listitem slds-chat-listitem_outbound'
                                : 'slds-chat-listitem slds-chat-listitem_inbound';
        //return cssClass + ' ' + this.comment.styleOverride;
    }
    get chatMetaCss() {
        return this.comment.isOutboundMessage 
                                ?'slds-chat-message__meta align-right'
                                :'slds-chat-message__meta';
    }
}