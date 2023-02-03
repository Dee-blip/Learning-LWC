/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-18-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-15-2021   apyati   Initial Version
**/
import { LightningElement ,api} from 'lwc';

export default class L2qManageProductButtonGroup extends LightningElement {
    @api oppName;
    @api accountName;
    @api enableSaveButton ;
    @api oppRecord;
    @api accId;
    @api oppId;
    @api enableActions = false;

    connectedCallback(){
        console.log(' enableActions'+ this.enableActions);
    }
    get accUrl(){
        return '/'+this.accId ;
    }
    get oppUrl(){
        return  '/'+this.oppId;
    }
    addProducts(){
        console.log('addproductsbutton');
        const evt = new CustomEvent('addproductsbutton');
        this.dispatchEvent(evt);
    }
    addRemoveContracts(){
        const evt = new CustomEvent('addremovecontractsbutton');
        this.dispatchEvent(evt);

    }
    refreshBaseline(){
        const evt = new CustomEvent('refreshbaseline');
        this.dispatchEvent(evt);

    }
    changeCurrency(){
        const evt = new CustomEvent('changecurrency');
        this.dispatchEvent(evt);

    }
    resetBaseline(){
        const evt = new CustomEvent('resettobaseline');
        this.dispatchEvent(evt);

    }
    cancelContract(){
        const evt = new CustomEvent('cancelcontract');
        this.dispatchEvent(evt);

    }
    handleCancel(){
        const evt = new CustomEvent('cancel');
        this.dispatchEvent(evt);

    }
    quickSaveHandler(){
        console.log('child handler quick save');
        const evt = new CustomEvent('quicksave');
        this.dispatchEvent(evt);

    }
    saveHandler(){
        const evt = new CustomEvent('save');
        this.dispatchEvent(evt);

    }
}