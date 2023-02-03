/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-17-2021
 * @last modified by  : apyati 
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-17-2021   apyati   Initial Version
**/
import {LightningElement, api} from 'lwc';

export default class L2qConfirmationDialogue extends LightningElement {
    @api visible; //used to hide/show dialog
    @api title; //modal title
    @api name; //reference name of the component
    @api message; //modal message
    @api confirmLabel; //confirm button label
    @api cancelLabel; //cancel button label
    @api originalMessage; //any event/message/detail to be published back to the parent component

    //handles button clicks
    handleClick(){
        //dispatch a 'click' event so the parent component can handle it
        this.dispatchEvent(new CustomEvent('submit'));
    }
    handleCancel(){
        this.dispatchEvent(new CustomEvent('close'))
    }
}