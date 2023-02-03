import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent"
import { refreshApex } from '@salesforce/apex';
import fetchAllRelatedCases from '@salesforce/apex/SC_SI_PageLayoutButton_Controllor.fetchAllRelatedCases';
import delinkSIRecords from '@salesforce/apex/SC_SI_PageLayoutButton_Controllor.deLinkSIRecords';
import { NavigationMixin } from 'lightning/navigation';

export default class Sc_SI_CaseRelatedList extends NavigationMixin(LightningElement) {

 
    @api recordId;
    @api listRecords;
    @track noCaseExists = false;
    @track showSpinner = false;
    wiredCases;
    showRelatedList = false;
    selectedItemValue;
    caseCount;
    title;


    // Fetching Case Data
    @wire(fetchAllRelatedCases, { SIrecordId: '$recordId' })
    objData(value) {
        this.wiredCases = value; // track the provisioned value
        const { data, error } = value;

        if (data) {
            let tempCaseList = [];
            let caseRecords = JSON.parse(data);
            this.caseCount = JSON.parse(data).length;
            // restricting to display upto 3 records
            if (this.caseCount > 3) {
                for (let i = 0; i <= 2; i++) {
                    tempCaseList.push(caseRecords[i]);
                }
                this.listRecords = tempCaseList;
            }
            else {
                this.listRecords = caseRecords;
            }
            if (this.caseCount === 0) {
                this.noCaseExists = true;
            }
            this.title= 'Impacted Cases ('+ this.caseCount+')';

        }
        else if (error) {
            this.error = error;
            console.log('error//' + JSON.stringify(error));
        }

    }


    // Navigating to other component to display all related case records
    navigateToRelatedList() {

        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                componentName: "c__SC_SI_RelatedCasesNav"
            },
            state: {
                c__caseItems: this.listRecords,
                c__siRecId: this.recordId
            }
        });

    }

    // Delinking the Case from SI by upating on the Case
    handleDelink(event) {
        let caseId = this.listRecords[event.target.value].Id;
        this.showSpinner = true;
        delinkSIRecords({ CaserecordId: caseId })
            .then(result => {
                if (result === 'Success') {
                    this.showSpinner = false;

                    const toastEvt = new ShowToastEvent({
                        title: "Success",
                        message: "Case is delinked.",
                        variant: "Success",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                   // return refreshApex(this.wiredCases);
                    window.location.reload();

                }
                else {
                    this.showSpinner = false;
                    const toastEvt = new ShowToastEvent({
                        title: "Error",
                        message: result,
                        variant: "error",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.log("error//" + JSON.stringify(error));
            })
    }

    // Styling
    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `c-sc_-s-i_-case-related-list .titleButton .slds-button{
            color: black;
                    }`;
        this.template.querySelector('lightning-button').appendChild(style);

        const style2 = document.createElement('style');
        style2.innerText = `c-sc_-s-i_-case-related-list .customMenu .slds-button_icon-border-filled{
            width: 20px;
            height: 20px;
                            }`;
        this.template.querySelector('lightning-card').appendChild(style2);

        const style3 = document.createElement('style');
        style3.innerText = `c-sc_-s-i_-case-related-list .footerButton .slds-button{
            color: #3580d3;
                            }`;
        this.template.querySelector('lightning-button').appendChild(style3);


    }
}