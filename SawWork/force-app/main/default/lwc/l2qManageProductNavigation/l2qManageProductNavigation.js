/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-17-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-13-2021   apyati   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class L2qManageProductNavigation extends NavigationMixin(LightningElement) {
    @api recordId;

    renderedCallback() {
        console.log('recordID ===', this.recordId);
        let compDefinition = {
            componentDef: "c:l2qManageProductsOnOpp",
            attributes: {
                recordId12: this.recordId
            }
        };
        // Base64 encode the compDefinition JS object
        let encodedCompDef = btoa(JSON.stringify(compDefinition));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCompDef
            }
        });
    }
}