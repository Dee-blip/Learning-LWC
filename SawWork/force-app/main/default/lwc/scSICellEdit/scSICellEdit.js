import { LightningElement, api } from 'lwc';


export default class ScSTMCellEdit extends LightningElement {
   
    @api title;
    
  

   

    handleDetails() {
        this.dispatchEvent(new CustomEvent('showtitles', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { title: this.title}
            }
        }));
      }

}