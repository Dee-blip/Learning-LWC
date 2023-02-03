import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClosedChimeForm from '@salesforce/apex/L2Q_LOE_Utility.getClosedChimeForm'; 

export default class ChimeFormFromProjects extends LightningElement {

    @track chimeform;
    @track error;
    @api recordId;
    
    
    @wire(getClosedChimeForm,{oppId:'$recordId'})
    wiredChmieForm({error, data})
    {
        if (data) {
            this.chimeform = data;
            this.error = undefined;
            console.log('this.chimeform :: '+ JSON.stringify(this.chimeform));
            //window.open("/" + recordId, '_self');
            //window.open("/" + this.chimeform.Id, "_blank" );
            window.open("/" + this.chimeform.Id, "_self" );

        } else if (error) {
            this.error = JSON.stringify(error);
            this.contacts = undefined;

            console.log('this.error : ' + this.error);

            if(this.error.includes('List has no rows for assignment to SObject'))
            {

                const evt = new ShowToastEvent({
                    title: 'Info',
                    message: 'There is no Closed Chime form linked to Opportunity',
                    variant: 'info',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);

            }
            else if (this.error.includes('You do not have access to the Apex class named'))
            {
                const evt = new ShowToastEvent({
                    title: "Error",
                    message: "You don't have access to view CHIME",
                    variant: "error",
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);

            }
            else 
            {
                const evt = new ShowToastEvent({
                    title: "Unknown Error",
                    message: this.error.body.message,
                    variant: "error",
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            

            setTimeout(function(){
                self.close();
            },3000);

        }

    }

}