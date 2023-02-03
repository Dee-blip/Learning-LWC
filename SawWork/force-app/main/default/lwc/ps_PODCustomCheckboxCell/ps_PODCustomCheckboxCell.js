import { LightningElement,api  } from 'lwc';
export default class Ps_PODCustomCheckboxCell extends LightningElement {

  

   @api isselected;
   @api accountid;
   @api accdeptid;
   //@api arerecipientspresent;


   connectedCallback(){

        console.log(this.accdeptid);
        // if(this.accdeptid == 'a7P4R000000boksUAA'){
        //     //alert(this.isselected);
        // }
       
   }


   handlecheck(event){
        //alert('from event fire comp :' , event.target.name);
    //this.isselected = true;
    console.log(event);
    const selectEvent = new CustomEvent('handlecheckevent', {
                composed: true,
                    bubbles: true,
                    cancelable: true,
                    detail: this.accdeptid != null ? this.accdeptid : this.accountid
            });
        this.dispatchEvent(selectEvent);
   }

   handleUncheck(event){
        console.log(event);
       //alert('from event fire comp :' , event.target.name);
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