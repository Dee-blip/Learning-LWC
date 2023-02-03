import { LightningElement,api } from 'lwc';

export default class ScPSAccountCustomCell extends LightningElement {
   @api isselected;
   @api mailername;
   @api arerecipientspresent;

   handlecheck(event){
  //  alert(event.target.name);
    //this.isselected = true;
    const selectEvent = new CustomEvent('handlecheckevent', {
        composed: true,
            bubbles: true,
            cancelable: true,
        detail: event.target.name
    });
   this.dispatchEvent(selectEvent);
   }

   handleUncheck(event){
    //this.isselected = false;
    const selectEvent = new CustomEvent('handleuncheckevent', {
        composed: true,
            bubbles: true,
            cancelable: true,
        detail: event.target.name
    });
   this.dispatchEvent(selectEvent);
   }
   
}