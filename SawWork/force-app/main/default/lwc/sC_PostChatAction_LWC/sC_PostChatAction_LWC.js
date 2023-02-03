/* eslint-disable no-console */
import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getCaseRecType from "@salesforce/apex/SC_Akachat_Lightning.getCaseRecType";
import getValidations from "@salesforce/apex/SC_Akachat_Lightning.getValidations";
import techincalCaseResolved from "@salesforce/apex/SC_Akachat_Lightning.techincalCaseResolved";
import amgCaseResolved from "@salesforce/apex/SC_Akachat_Lightning.amgCaseResolved";
import techincalCaseNotResolved from "@salesforce/apex/SC_Akachat_Lightning.techincalCaseNotResolved";
import amgCaseNotResolved from "@salesforce/apex/SC_Akachat_Lightning.amgCaseNotResolved";
import getRadioOptions from "@salesforce/apex/SC_Akachat_Lightning.getRadioOptions";

export default class SC_PostChatAction_LWC extends LightningElement {
  @api recordId;
  @api showCloseCase;
  @api recTypeIdAMG;
  @track showSpinner;
  @api buttonClicked;
  @track showRadioButtons;
  @track defaultView;
  @track amgView = false;
  @track techView = false;
  @track optionSelected;
  @track chatResolved;
  @track caseRecTypeId;
  @track caseRecTypeName;
  @track closeAMGCase = false;
  @track showfields = false;
  @track invalidCase;
  @track isCompleted;
  @track options = [];
  showButtons = false;
  selectedOption;
  closeTranscript;
  

  connectedCallback() {
    console.log('this.buttonClicked//'+this.buttonClicked);
    if (this.buttonClicked === true) {
      getValidations({ caseId: this.recordId })
        .then(result => {
          let scenario = result;
          console.log('tscenario//'+scenario);
          if (scenario === "Invalid") {
            this.invalidCase = true;
          }
          if (scenario === "Close Transcript") {
            this.closeTranscript = true;
          }
          if (scenario === "Completed") {
            this.isCompleted = true;
          }
          if (scenario === "Valid") {

            getRadioOptions()
              .then(response => {
                let finalRecList = [];
                response.forEach(function(item) {
                  finalRecList.push({ value: item, label: item });
                });
                this.options = finalRecList;
                this.showRadioButtons = true;
              })
              .catch(error => {
                this.error = error;
              });
          }
        })
        .catch(error => {
          this.error = error;
          console.log("error//" + JSON.stringify(error));
        });

      getCaseRecType({ caseId: this.recordId })
        .then(result => {
          let caseRecTypeData = result;
          // eslint-disable-next-line guard-for-in
          for (let key in caseRecTypeData) {
            this.caseRecTypeId = key;
            this.caseRecTypeName = caseRecTypeData[key];
          }

          if (this.caseRecTypeName === "AMG") {
            this.amgView = true;
          }
          if (
            this.caseRecTypeName === "Technical" ||
            this.caseRecTypeName === "Managed Security"
          ) {
            this.techView = true;
          }
        })
        .catch(error => {
          this.error = error;
        });
    }
  }

  handleChange(event) {
    this.showButtons = true;
    this.selectedOption = event.detail.value;
    if (this.selectedOption === "Resolved") {
      this.chatResolved = true;
    } else {
      this.chatResolved = false;
    }
    this.showfields = true;
  }

  closeModal() {
    this.showRadioButtons = false;
    const refreshEvent = new CustomEvent("refreshAction", {});
    // Fire the custom event
    this.dispatchEvent(refreshEvent);
  }

  handleSubmit(event) {
    event.preventDefault();
    this.showSpinner = true;
    let fields = event.detail.fields;

    if ((this.chatResolved === true) & (this.amgView === true)) {
      amgCaseResolved({
        caseId: this.recordId,
        fieldValues: fields,
        radioOption: this.selectedOption
      })
        .then(result => {
          this.showSpinner = false;
            this.closeModal();
            const toastEvt = new ShowToastEvent({
              title: "Success",
              message: "Completed Successfully. Please Close the Case.",
              variant: "Success",
              mode: "dismissible",
              duration: 5000
            });
            this.dispatchEvent(toastEvt);      
        })
        .catch(error => {
          this.showSpinner = false;
          this.error = error;
          console.log("error//" + JSON.stringify(error));
          this.showError(error);
        });
    }

    if ((this.chatResolved === true) & (this.techView === true)) {
      techincalCaseResolved({
        caseId: this.recordId,
        fieldValues: fields,
        radioOption: this.selectedOption
      })
        .then(result => {
          this.showSpinner = false;
          this.closeModal();
          const toastEvt = new ShowToastEvent({
            title: "Success",
            message: "Completed Successfully. Please Close the Case.",
            variant: "Success",
            mode: "dismissible",
            duration: 5000
          });
          this.dispatchEvent(toastEvt);
        })
        .catch(error => {
          this.showSpinner = false;
          this.error = error;
          console.log("error//" + JSON.stringify(error));
          this.showError(error);
        });
    }

    if ((this.chatResolved === false) & (this.amgView === true)) {
      amgCaseNotResolved({
        caseId: this.recordId,
        fieldValues: fields,
        radioOption: this.selectedOption
      })
        .then(result => {
          this.showSpinner = false;
          this.closeModal();
          const toastEvt = new ShowToastEvent({
            title: "Success",
            message: "Completed Successfully",
            variant: "Success",
            mode: "dismissible",
            duration: 5000
          });
          this.dispatchEvent(toastEvt);
        })
        .catch(error => {
          this.showSpinner = false;
          this.error = error;
          console.log("error//" + JSON.stringify(error));
          this.showError(error);
        });
    }

    if ((this.chatResolved === false) & (this.techView === true)) {
      techincalCaseNotResolved({
        caseId: this.recordId,
        fieldValues: fields,
        radioOption: this.selectedOption
      })
        .then(result => {
          this.showSpinner = false;
          this.closeModal();
          const toastEvt = new ShowToastEvent({
            title: "Success",
            message:
              "Completed Successfully. Your case has been re-routed to a queue.",
            variant: "Success",
            mode: "dismissible",
            duration: 5000
          });
          this.dispatchEvent(toastEvt);
        })
        .catch(error => {
          this.showSpinner = false;
          this.error = error;
          console.log("error//" + JSON.stringify(error));
          this.showError(error);
        });
    }
  }

  showError(error) {
    console.log("error in showError //" + JSON.stringify(error));
    console.log("error in showError 2 //" + error);
    const toastEvt = new ShowToastEvent({
      title: "Error",
      message: JSON.stringify(error.body.message),
      variant: "Error",
      mode: "dismissible",
      duration: 5000
    });
    this.dispatchEvent(toastEvt);
  }
}