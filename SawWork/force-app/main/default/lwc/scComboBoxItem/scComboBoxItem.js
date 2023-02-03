import { LightningElement, api } from 'lwc';

export default class ComboBoxItem extends LightningElement {
    
    @api iconName;
    @api iconSrc;
    @api iconText;
    @api iconSize;
    @api iconVariant;
    @api text;
    @api metaText;
    @api uniqueId;

    handleSelect() {// eslint-disable-line no-use-before-define
        this.dispatchEvent(new CustomEvent('select', {detail: this.uniqueId}));// eslint-disable-line no-use-before-define
    }

}