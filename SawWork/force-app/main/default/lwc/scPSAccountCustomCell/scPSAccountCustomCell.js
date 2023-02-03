import { LightningElement,api } from 'lwc';

export default class ScPSAccountCustomCell extends LightningElement {
   @api accountname;
   @api accounturl;
   @api arerecipientspresent;

   renderedCallback() {
      if(!this.arerecipientspresent){
         const style = document.createElement('style');
         style.innerText = `c-sc-p-s-account-custom-cell .slds-button_icon svg{
         fill: red;
         }`;
         this.template.querySelector('lightning-button-icon').appendChild(style);
   }
}

   handleOpenRec(){
      window.open(this.accounturl)
   }
   handleRecipientCreate(event){
     
           console.log(event.target.name);
           
           const createEvent = new CustomEvent('handlecreatedlevent', {
               composed: true,
                   bubbles: true,
                   cancelable: true,
                   detail: {
                     data: { accname: this.accountname,accurl:this.accounturl}
                 }
           });
          this.dispatchEvent(createEvent);
          
   }
}