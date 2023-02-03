/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 12-15-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-29-2021   apyati   SFDC-8654 Initial Version
**/
import { LightningElement ,api } from 'lwc';

export default class L2q_ChimeViewHistory extends LightningElement {

    @api chimeId;
    handleClose() {
        const cancelEvent = new CustomEvent('cancel', {});
        this.dispatchEvent(cancelEvent);
    }
}