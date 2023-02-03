/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 07-15-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-15-2021   apyati   Initial Version
**/
import { LightningElement,api } from 'lwc';

export default class L2qContractPreview extends LightningElement {
    @api recordId;

    closePreview(){
        console.log('closepreview');
        this.dispatchEvent(new CustomEvent('closepreview'));
    }

}