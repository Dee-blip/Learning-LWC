/* eslint-disable no-console */
import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import bulkUpdateContactAvailability from "@salesforce/apex/SC_SOCC_EscalationListCtrl.bulkUpdateContactAvailability";
import getAvailabilty from "@salesforce/apex/SC_SOCC_EscalationListCtrl.getAvailabiltyRecords";

export default class SC_SOCC_Contact_Availablity extends LightningElement {
    @api recordId;
    @api edit = false;
    @track returnedData;
    @track error;
    shouldrender = false; //used to determine whether to execute code in rendercallback

    /** init method Connected CallBack */
    connectedCallback() {
        //you can build a method for a button
        getAvailabilty({ contactId: this.recordId })
            .then(result => {
                this.setReturnedData(result);
                console.log("result in init");
                console.log(result);
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleClickEditAll(event) {
        console.log(this.template.querySelector("table").classList);
        this.template.querySelector("table").classList.add("flexed");
        this.edit = true;
        this.shouldrender = true;
        console.log(this.template.querySelector("table"));
        console.log(this.edit);
    }
    renderedCallback() {
        if (this.shouldrender === true) {
            if (
                this.template.querySelectorAll("tr")[1].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[1].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[1].children[3].children[0].disabled = false;
            }
            if (
                this.template.querySelectorAll("tr")[2].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[2].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[2].children[3].children[0].disabled = false;
            }
            if (
                this.template.querySelectorAll("tr")[3].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[3].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[3].children[3].children[0].disabled = false;
            }
            if (
                this.template.querySelectorAll("tr")[4].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[4].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[4].children[3].children[0].disabled = false;
            }
            if (
                this.template.querySelectorAll("tr")[5].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[5].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[5].children[3].children[0].disabled = false;
            }
            if (
                this.template.querySelectorAll("tr")[6].children[1].children[0]
                    .value === "Specific Time"
            ) {
                this.template.querySelectorAll(
                    "tr"
                )[6].children[2].children[0].disabled = false;
                this.template.querySelectorAll(
                    "tr"
                )[6].children[3].children[0].disabled = false;
            }

            this.shouldrender = false;
        }
    }

    /* This method is to update all records */
    handleClickSaveAll(event) {
        let rowNodeList = this.template.querySelectorAll("tr");
        let availabilitylist = [];
        let isValid = true;
        for (let i = 1; i < 8; i++) {
            let row = rowNodeList[i];
            let dayofweek = row.children[0].innerHTML;
            let availability = row.children[1].children[0].value;
            let starttime = row.children[2].children[0].value;
            let endtime = row.children[3].children[0].value;
            let availrecid = row.dataset.item;

            console.log("start end time");
            console.log(starttime);
            console.log(endtime);

            if(availability === "Specific Time" && (!starttime || !endtime)){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Please populate Start Time and End Time for Availability = 'Specific Time'.",
                        message: " ",
                        variant: "error"
                    })
                );
                isValid = false;
                break;
            }

            let availabilityrec = { sobjectType: "SC_SOCC_Availability__c" };
            availabilityrec.Day_Of_Week__c = dayofweek;
            availabilityrec.Availability__c = availability;
            availabilityrec.Start_Time__c = starttime;
            availabilityrec.End_Time__c = endtime;
            availabilityrec.Id = availrecid;

            availabilitylist.push(availabilityrec);
        }

        console.log("availabilitylist", availabilitylist);
        console.log("availabilitylistlength" + availabilitylist.length);

        /* Call Apex Method Imperatively */
        if(isValid){
            bulkUpdateContactAvailability({ lAvailability: availabilitylist })
                .then(result => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Availability successfully edited!",
                            variant: "success"
                        })
                    );
                    this.edit = false;
                    getAvailabilty({ contactId: this.recordId })
                        .then(result => {
                            this.setReturnedData(result);
                            console.log("result in save");
                            console.log(result);
                        })
                        .catch(error => {
                            console.log(error);
                        });

                })
                .catch(error => {
                    this.error = error;
                    console.log(error);
                    if(error.body.message){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Failed",
                                message: error.body.message,
                                variant: "error"
                            })
                        );
                    }
                    else if(error.body.pageErrors){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Failed",
                                message: error.body.pageErrors[0].message,
                                variant: "error"
                            })
                        );
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Failed",
                                message: "Something went wrong. Please contact your Administrator.",
                                variant: "error"
                            })
                        );
                    }
                });
        }
        /* End of Call to Apex Method */
    }

    /* This method is to come out of edit mode */
    handleCancelButton() {
        this.edit = false;
    }



    get options() {
        return [
            { label: "All Day", value: "All Day" },
            { label: "Not Available", value: "Not Available" },
            { label: "Specific Time", value: "Specific Time" }
        ];
    }

    handleChangecombobox(event) {
        console.log(
            event.target.parentNode.parentNode.children[2].children[0].disabled
        );
        let availability = event.detail.value;
        //Make the time fields editable
        if (availability === "Specific Time") {
            event.target.parentNode.parentNode.children[2].children[0].disabled = false;
            event.target.parentNode.parentNode.children[3].children[0].disabled = false;
        } 
        else { //Make the time fields non-editable or disabled
            event.target.parentNode.parentNode.children[2].children[0].disabled = true;
            event.target.parentNode.parentNode.children[3].children[0].disabled = true;

            //set to 12:00AM to 12:00AM
            if(availability === "All Day"){
                event.target.parentNode.parentNode.children[2].children[0].value = "00:00:00.000";
                event.target.parentNode.parentNode.children[3].children[0].value = "00:00:00.000";
            }
            else{ //set to empty values
                event.target.parentNode.parentNode.children[2].children[0].value = "";
                event.target.parentNode.parentNode.children[3].children[0].value = "";
            }
        }
    }

    // Pad to 2 or 3 digits, default is 2
    pad(n, z) {
        z = z || 2;
        return ('00' + n).slice(-z);
    }

    //milliseconds to time format
    msToTime(s){
        let ms = s % 1000;
        s = (s - ms) / 1000;
        let secs = s % 60;
        s = (s - secs) / 60;
        let mins = s % 60;
        let hrs = (s - mins) / 60;
        return this.pad(hrs) + ':' + this.pad(mins) + ':' + this.pad(secs) + '.' + this.pad(ms, 3);
    }
    
    //Set correct time format
    setReturnedData(result){
        let returnedData = JSON.parse(JSON.stringify(result));
        for(let row of returnedData){
            if(row.Availability__c === "Specific Time"){
                row.Start_Time__c = this.msToTime(row.Start_Time__c);
                row.End_Time__c = this.msToTime(row.End_Time__c);
            }
            else if(row.Availability__c === "All Day"){
                row.Start_Time__c = "00:00:00.000";
                row.End_Time__c = "00:00:00.000";
            }
            else{
                row.Start_Time__c = "";
                row.End_Time__c = "";
            }
        }

        this.returnedData = returnedData;
    }
}