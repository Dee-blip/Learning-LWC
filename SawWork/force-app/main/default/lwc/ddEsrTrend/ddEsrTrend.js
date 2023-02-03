import { LightningElement, track, api } from 'lwc';

export default class DdEsrTrand extends LightningElement {

    @track __deal;
    @track iconLabel;
    @api prodName;

    @api 
    get deal(){
        return this.__deal;
    }
    set deal(value) {
        this.__deal = value;
        this.iconLabel = '$' + value.Computed_ESR__c;
    }


    showEsrModal() {
        let custModal = this.template.querySelector('.acc-esr');
        custModal.toggle();
    }
    toggleEsr(ev) {
        ev.preventDefault();
        let inp = this.template.querySelector('div[name="accEsr"]');
        console.log('inp -->' + inp);
        inp.classList.toggle('visible');
    }
}