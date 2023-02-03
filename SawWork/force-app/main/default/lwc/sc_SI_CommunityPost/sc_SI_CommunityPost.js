/* eslint-disable no-console */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent"
import getDataForCommunity from "@salesforce/apex/SC_SI_PageLayoutButton_Controllor.getDataForCommunity";
import syncFeedItem from "@salesforce/apex/SC_SI_PageLayoutButton_Controllor.syncFeedItem";


export default class Sc_SI_CommunityPost extends LightningElement {

    showModal = true;
    @api recordId;
    @api defBody;
    @api label;
    showSpinner = false;

    connectedCallback() {
        // Fetching the data from Service Incident for default values and from the already created post
        getDataForCommunity({ SIrecordId: this.recordId, buttonLabel: this.label })
            .then(result => {
                // Fetching the default data from Service Incident
                if (this.label === 'Create Community Post') {
                    let res = JSON.parse(result);
                    console.log('res//' + JSON.stringify(result))
                    this.defBody = res.customer_Advisory!=null ? res.timeValue + ' UTC   -   <b>' + res.status + '</b> <br/> <br/>' + res.customer_Advisory : res.timeValue + ' UTC  -  <b>' + res.status + '</b>';
                    console.log('this.defBody//' + this.defBody);
                }
                // Fetching the data from the created post
                else {
                    console.log('res 2//' + result)
                    this.defBody = result;
                }
            })
            .catch(error => {
                console.log("error//" + JSON.stringify(error));
                console.log("error//" + error);
            });
    }

    get myVal() {

        return this.defBody;

    }

    // Closing the Modal
    closeModal() {
        this.showModal = false;
        const refreshEvent = new CustomEvent("refreshAction", {});
        // Fire the custom event
        this.dispatchEvent(refreshEvent);
    }

    // Saving the Community Post
    savePost() {
        this.showSpinner = true;
        let inputData = this.template.querySelector('lightning-input-rich-text');
        console.log('inputData on save //' + inputData.value);
        syncFeedItem({ htmlData: inputData.value, SIrecordId: this.recordId, buttonLabel: this.label})
            .then(result => {

                this.showSpinner = false;
                console.log('result//'+result);

                if (result === 'Success') {
                    const toastEvt = new ShowToastEvent({
                        title: "Success",
                        message: this.label === 'Create Community Post' ? "Community Post was created." : "Community Post was updated.",
                        variant: "Success",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                    this.closeModal();
                }
                else {
                    const toastEvt = new ShowToastEvent({
                        title: "Error",
                        message: result,
                        variant: "Error",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                }


            })
            .catch(error => {
                this.showSpinner = false;
                console.log("error//" + JSON.stringify(error));
                console.log("error//" + error);
            })

    }


}