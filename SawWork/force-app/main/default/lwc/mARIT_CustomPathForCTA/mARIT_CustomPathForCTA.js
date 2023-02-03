import { LightningElement, api, track, wire } from 'lwc';
import saveLead from '@salesforce/apex/MARIT_CTAPathComponent.updateLeadStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//Imports for getting object info and status picklist values from object
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Lead_Qual_Status_Picklist from '@salesforce/schema/Lead.Lead_Qualification_Status__c';


export default class CustomCTAPath extends LightningElement {
    isTurnbackToBeDisplayed;
    stageValues = [
        { label: 'Stage-1', value: 'Prospect' },
        { label: 'Stage-2', value: 'Engaged' },
        { label: 'Stage-3', value: 'Qualified Engaged' },
        { label: 'Stage-4', value: 'Qualified Lead - Warm' },
        { label: 'Stage-5', value: 'Qualified Lead - Hot' },
    ];
    currentStep;
    cmbvalue;
    isCmbReadOnly = false;
    isButtonDisabled = false;
    leadRecObj = { 'sobjectType': 'Lead' };
    inProcMsg = 'CTA will automatically moved to In Process state with entry of either: Product line, ANUM fields, New Activity, QFA Meeting Date';
    bppValues;
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Lead_Qual_Status_Picklist})
    StatusPickList;
    @track value;
    @track items = [];
    @api leadObjAura;
    @api isLoaded = false;
    @api recordId;
    @api selectedStatus;
    @api
    getFiredFromAura() {
        const ele = this.template.querySelector('[data-id="testhide"]');
        const inputPicklist = this.template.querySelector('[data-id="hideInputPicklist"]');
        if (this.leadRecObj.Status = 'Closed' || this.leadRecObj.Status === 'Converted') {
            inputPicklist.style.display = 'none';
        }
        let statusVal = this.selectedStatus;
        if (statusVal.toLowerCase() === 'closed' || statusVal.toLowerCase() === 'converted') {
            ele.style.display = 'block';
            this.setPickListValues(this.selectedStatus);
        } else {
            ele.style.display = 'none';
        }
        if (this.selectedStatus === 'In Process') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'In Process: Important information',
                    message: this.inProcMsg,
                    variant: 'info',
                    mode: 'dismissable'
                })
            );
        }
    }

    // Called on page load
    renderedCallback() {
        if (JSON.parse(JSON.stringify(this.leadObjAura)).Id !== undefined) {
            this.leadRecObj = JSON.parse(JSON.stringify(this.leadObjAura));

            // show BPP as comma separated 
            if (this.leadRecObj.Buyer_Pain_Points__c !== null && this.leadRecObj.Buyer_Pain_Points__c !== undefined) {
                this.bppValues = this.leadRecObj.Buyer_Pain_Points__c.replaceAll(';', ', ');
            }

            // show the linear path
            if (this.leadRecObj.Lead_Qualification_Stage__c !== null || this.leadRecObj.Lead_Qualification_Stage__c !== undefined) {
                this.showBoxedSteps(this.leadRecObj.Lead_Qualification_Stage__c);
            }

            //hide combobox and show output picklist if the status is closed or converted
            const ele = this.template.querySelector('[data-id="testhide"]');
            if (this.leadRecObj.Status === 'Closed' || this.leadRecObj.Status === 'Converted') {
                ele.style.display = 'block';
                this.isCmbReadOnly = true;
                let updateButton = this.template.querySelector('lightning-button');
                updateButton.style.display = 'none';
                const comboboxPicklist = this.template.querySelector('[data-id="hideComboboxPicklist"]');
                const inputPicklist = this.template.querySelector('[data-id="hideInputPicklist"]');
                inputPicklist.style.display = 'block';
                comboboxPicklist.style.display = 'none';
            }
        }

    }

    // Picklist values for Lead Qualification Status 
    get options() {
        return JSON.parse(JSON.stringify(this.items));
    }

    // DO NOT DELETE
    /*showSteps(stage) {
        this.currentStep = stage;
    }*/

    // Boxed Linear approach 
    showBoxedSteps(stage) {
        this.isTurnbackToBeDisplayed = this.stageEquivalentToTurnback(stage);
        if (this.isTurnbackToBeDisplayed) {
            //show turnback
            if (this.stageValues.length < 6) {
                this.stageValues.push({ label: 'Stage-6', value: 'Turnback' });
            }
            if (this.template.querySelector('[data-id="Stage-6"]') !== null) {
                this.template.querySelector('[data-id="Stage-6"]').className = 'active-stage';
            }
        } else {
            // show stages without turnback
            this.showStageWithoutTurnback(stage);
        }
    }

    showStageWithoutTurnback(stage) {
        let stageToClassNameMap = [
            { key: 1, value: { stageName: 'Prospect', idValue:'[data-id="Stage-1"]'} },
            { key: 2, value: { stageName: 'Engaged', idValue:'[data-id="Stage-2"]'} },
            { key: 3, value: { stageName: 'Qualified Engaged', idValue:'[data-id="Stage-3"]'} },
            { key: 4, value: { stageName: 'Qualified Lead - Warm', idValue:'[data-id="Stage-4"]'} },
            { key: 5, value: { stageName: 'Qualified Lead - Hot', idValue:'[data-id="Stage-5"]'} },
        ];

        let i;
        for(i=0; i<5; i++) {
            if (stageToClassNameMap[i].value.stageName === stage) {
                break;
            }
            this.template.querySelector(stageToClassNameMap[i].value.idValue).className = 'passed-stage';
        }

        // for active stage
        this.template.querySelector(stageToClassNameMap[i].value.idValue).className = 'active-stage';
    }

    // return true or false based on the lead qualification stage
    stageEquivalentToTurnback(stage) {
        let stagesExcludedForTurnback = ['Prospect', 'Engaged', 'Qualified Engaged', 'Qualified Lead - Warm', 'Qualified Lead - Hot'];
        if (stagesExcludedForTurnback.includes(stage)) {
            return false;
        } else {
            return true;
        }
    }

    // Setting the picklist values based on the Lead Status selected from chevron
    setPickListValues(selectedStatus) {
        this.items = [];
        this.cmbvalue = null;
        let localClosedItemList = [];
        let localConvertedItemList = [];
        if (this.StatusPickList.data !== undefined) {
            this.StatusPickList.data.values.forEach(picklistValue => {
                if ((picklistValue.value !== "Turnback Auto Close for Nurture") && picklistValue.value.includes("Turnback") || picklistValue.value.includes("Closed")) {
                    localClosedItemList.push({ label: picklistValue.label, value: picklistValue.value });
                } else if (picklistValue.value === "Converted") {
                    localConvertedItemList.push({ label: picklistValue.label, value: picklistValue.value });
                }
            });
        }
        
        if (selectedStatus === 'Closed') {
            this.items = localClosedItemList.slice();
        }
        if (selectedStatus === 'converted') {
            this.cmbvalue = 'Converted';
            this.items = localConvertedItemList.slice();
        }
    }

    // cmbvalue handles the final picklisy lead qualification Status value.
    // Handler ensures that the value is set properly for saving later
    handleCmbChange(event) {
        this.cmbvalue = event.detail.value;
    }

    handleSubmit(event) {
        event.preventDefault();
        const ele2 = this.template.querySelector('[data-id="lwc-outerdiv"]');
        ele2.style.opacity  = '0.2';
        ele2.style.pointerEvents = "none";
        this.isLoaded = true;
        let objId = this.leadRecObj.Id;
        this.leadRecObj = JSON.parse(JSON.stringify(event.detail.fields));
        if (this.cmbvalue !== undefined && this.cmbvalue !== null) {
            this.leadRecObj['Lead_Qualification_Status__c'] = this.cmbvalue;
            this.leadRecObj['Id'] = objId;
            saveLead({ leadRec: this.leadRecObj })
                .then((result) => {
                    this.isLoaded = false;
                    ele2.style.opacity  = '1.0';
                    ele2.style.pointerEvents = "auto";
                    let output = result;
                    if (output.includes('Success')) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Lead updated',
                                variant: 'success'
                            })
                        );

                        this.dispatchEvent(new CustomEvent('recordChange'));
                    } else if (!output.includes('Success')) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Cannot update CTA record',
                                message: output,
                                variant: 'error',
                                mode: 'sticky'
                            })
                        );
                    }
                })
                .catch((error) => {
                    this.isLoaded = false;
                    console.log('error>>' + JSON.stringify(error));
                });
        } else {
            this.isLoaded = false;
            ele2.style.opacity  = '1.0';
            ele2.style.pointerEvents = "auto";
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Filed missing: Lead Qualification Status',
                    message: 'Please select Lead Qualification Status before updating the CTA.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }
    handleSuccess(event) {
        console.log('onsuccess event recordEditForm', event.detail.id);
    }
}