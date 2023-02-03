import {
    api,
    LightningElement,
    track
} from 'lwc';

import findRecords from '@salesforce/apex/HD_Custom_lookup_Controller.findRecords';

const DELAY = 300;

export default class HdEmailLookup extends LightningElement {

    fetchedEmails; //users fetched on search to whom email needs to be sent
    @track selectedEmails = []; //selected users to whom email needs to be sent
    searchKey = '';
    toEmailList = []; 
    ccEmailList = []; 
    @api searchField; //fields' data to be fetched
    @api additionalFilters; //filter fields ('Where' condition)
    @api objName;
    boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @api emailType;
    addGeneralUser;
    blurTimeout;

    /* 1. To add users not found in the system .
       2. To hide user dropdown whenever cursor is out of dropdown. */
    onBlur() {
        this.blurTimeout = setTimeout(() => {
            
            if(this.addGeneralUser && this.searchKey){
                if(this.selectedEmails.length <= 9){
                this.selectedEmails.push({
                    "Id": '',
                    "Email": this.searchKey,
                    "Photo": 'https://contacts.akamai.com/photos/hbefjefh.jpg' //unknown user image
                });
                const selectedEvent = new CustomEvent('lookupselected', {
                    detail: {
                        emailList: this.selectedEmails,
                        emailType: this.emailType
                    }
                });
                this.dispatchEvent(selectedEvent);
                this.searchKey = '';
                }else{
                    const errorEvent = new CustomEvent('error', {
                        detail: {
                            errorMsg: 'Max recipient limit is 10.'
                        }
                    });
                    this.dispatchEvent(errorEvent);
                    
                }
            }

        }, 300);
    }

    onSelect(event) {

        let selectedEmailId = event.currentTarget.dataset.id;
        let emailListToFilter = this.selectedEmails.map(a => a.Id);
        if (!emailListToFilter.includes(selectedEmailId)) {
            if (this.selectedEmails.length <= 9) {
                this.selectedEmails.push({
                    "Id": event.currentTarget.dataset.id,
                    "Email": event.currentTarget.dataset.name,
                    "Photo": event.currentTarget.dataset.photo
                });
                const selectedEvent = new CustomEvent('lookupselected', {
                    detail: {
                        emailList: this.selectedEmails,
                        emailType: this.emailType
                    }
                });
                this.dispatchEvent(selectedEvent);
            } else {
                
                const errorEvent = new CustomEvent('error', {	
                    detail: {	
                        errorMsg: 'Max recipient limit is 10.'	
                    }	
                });	
                this.dispatchEvent(errorEvent);

            }


        }
        this.fetchedEmails = [];
        this.searchKey = '';
        this.addGeneralUser = false;
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';

    }

    handleRemovePill(event) {

        for (let i in this.selectedEmails) {
            if (this.selectedEmails[i].Id === event.target.value && this.selectedEmails[i].Id !== '') {
                this.selectedEmails.splice(i, 1);
            } else if (this.selectedEmails[i].Id === '' && event.target.dataset.name === this.selectedEmails[i].Email) {
                this.selectedEmails.splice(i, 1);
            }
        }
        const selectedEvent = new CustomEvent('lookupselected', {
            detail: {
                emailList: this.selectedEmails,
                emailType: this.emailType
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    //find matching users to add as recipients
    handlOnChange(event) {

        window.clearTimeout(this.delayTimeout);
        this.searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            
                findRecords({
                        searchParams: JSON.stringify({
                            searchKey: '',
                            fields: '',
                            objectName: this.objName,
                            searchField: this.searchField,
                            additionalFilters: "Name LIKE '%"+this.searchKey + "%' OR EMAIL LIKE '%"+this.searchKey + "%' LIMIT 10"
                        })
                    })
                    .then(result => {
                        let updatedEmails = [];
                        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
                        this.addGeneralUser = result.length === 0 ? true : false; //if this is true, unknown user email (which is not in the system) can be added.
                        for(let i=0; i<result.length; i++){
                            let clonedResult = Object.assign({}, result[i]);
                            if(clonedResult.Username){
                                clonedResult.SmallPhotoUrl = "https://contacts.akamai.com/photos/" + (clonedResult.Username).substring(0, (clonedResult.Username).indexOf('@')) + ".jpg";
                            }
                            updatedEmails.push(clonedResult);
                        }
                        this.fetchedEmails = updatedEmails;       
                    })
                    .catch(error => {
                        this.error = error;
                        this.fetchedEmails = undefined;
                    });
            
        }, DELAY);
    }

    //set onload 'To Email' from parent component 'hdEmailComposerDocked
    @api setToEmailFromParent(toEmails) {
        this.selectedEmails.push({
            "Id": '',
            "Email": toEmails.Email,
            "Photo": "https://contacts.akamai.com/photos/" + (toEmails.Email).substring(0, (toEmails.Email).indexOf('@')) + ".jpg"
        });

        this.toEmailList.push(toEmails);
    }

    connectedCallback(){
        document.addEventListener('click', (event) => {
            if (event.target !== this) {
                this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
            }
          });
    }

}