import { LightningElement, api } from 'lwc';

export default class SoccApprovalActions extends LightningElement {
     @api insId;

     approve(ev) {
          this.dispatchEvent(new CustomEvent('approveinstruction', {detail: this.insId, bubbles: true, composed: true}));
     }
     

     reject(ev) {
          console.log('reject method ', this.insId);
          this.dispatchEvent(new CustomEvent('rejectinstruction', {detail: this.insId, bubbles: true, composed: true}));
     }

}