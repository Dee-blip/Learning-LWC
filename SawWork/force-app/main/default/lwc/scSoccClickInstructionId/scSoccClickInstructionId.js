import { LightningElement, api } from 'lwc';


export default class ScSoccClickInstructionId extends LightningElement {
     @api insId;
     @api insName;

     viewInstruction(event){
          this.dispatchEvent(new CustomEvent('viewinstruction', {detail: this.insId, bubbles: true, composed: true}));
     }

     get getInsName(){
          return this.insName;
     }
}