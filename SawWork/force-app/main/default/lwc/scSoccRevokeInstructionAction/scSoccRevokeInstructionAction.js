import { LightningElement, api } from 'lwc';

export default class ScSoccRevokeInstructionAction extends LightningElement {
     @api insId;

     revoke(event){
          this.dispatchEvent(new CustomEvent('revokeinstruction', {detail: this.insId, bubbles: true, composed: true}));
     }
     edit(event){
          this.dispatchEvent(new CustomEvent('editinstruction', {detail: this.insId, bubbles: true, composed: true}));
     }
}