import { LightningElement,api } from 'lwc';

export default class ScPSCustomTextAreaCell extends LightningElement {
   
   @api mailername;
   @api disablereason;
   

   handleUpdateReason(event){
  //  alert(event.target.name);
   // alert(JSON.stringify(event.target.name)+'---'+event.target.value);
    const selectEvent = new CustomEvent('handleupdatereasonevent', {
        composed: true,
            bubbles: true,
            cancelable: true,
        detail: {name:event.target.name,value:event.target.value}
    });
   this.dispatchEvent(selectEvent);
   }

 
   
}