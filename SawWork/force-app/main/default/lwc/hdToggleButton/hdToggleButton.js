import { LightningElement, track, wire, api} from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import ACCESS_PROV_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.ACD_Access_Provisioned__c';
import FINPUT_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.HD_ServiceRequest_FInput__c';
import APPROVAL_STATUS from '@salesforce/schema/BMCServiceDesk__Incident__c.HD_Approval_Status__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import METADATAID from '@salesforce/label/c.HD_Custom_Metadata_ID';

const METADATA_FIELDS = ['HD_Instance__mdt.MasterLabel', 'HD_Instance__mdt.SettingValue__c','HD_Instance__mdt.ChangePicklistColorSettings__c' ];
const INCIDENT_FIELDS = [ACCESS_PROV_FIELD, FINPUT_FIELD, APPROVAL_STATUS];

export default class HdToggleButton extends LightningElement {

@api recordId;
@track state = {
    isSelected : false,
    displaySpinner : true,
    disableButton : false,
    disableEdit : false,
    objmetadata : {}
};

teamNames;
recordInfo;
metadataInfo;
metadataid;

@wire(getRecord, { recordId: '$recordId', fields: INCIDENT_FIELDS })
wiredRecord({error,data}){
    if(data){
        this.recordInfo = data;
        this.metadataid = METADATAID; //Provided the values here to chain the second wire method
        this.state.isSelected = getFieldValue(data,ACCESS_PROV_FIELD);
    }
    else if(error){
        this.state.displaySpinner = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error Fetching Record',
                message: error.body.message,
                variant: 'error'
            })
        );    
    }
}

@wire(getRecord, { recordId: '$metadataid', fields: METADATA_FIELDS })
metadataRecord({error, data}) {
    if(data) {
        this.metadataInfo = data;
        window.console.log('data ====> '+ JSON.stringify(data));
        let currentData = data.fields;
        let teamValues =  currentData.ChangePicklistColorSettings__c.value;
        this.teamNames = teamValues.toLowerCase().split(";");
        this.state.objmetadata = {
            MasterLabel : currentData.MasterLabel.value,
            SettingValue : currentData.SettingValue__c.value
        }
        this.handleAttrUpdate();
    } 
    else if(error) {
        this.state.displaySpinner = false;
        window.console.log('error ====> '+JSON.stringify(error));
    }
}

get isPendingApproval(){
    return getFieldValue(this.recordInfo,APPROVAL_STATUS) === 'Approval Pending' && !this.state.disableButton;
}

get isAccessGranted(){
    return this.state.disableButton && !this.state.disableEdit;
}

handleAttrUpdate(){
    if(this.recordInfo && this.metadataInfo){
        let finput = getFieldValue(this.recordInfo,FINPUT_FIELD);
        window.console.log('finput ====> '+JSON.stringify(finput));
        this.state.disableEdit = (finput === null) ? true : !this.teamNames.includes(finput.toLowerCase());
        if(this.state.isSelected || this.state.disableEdit){
            this.state.disableButton = true;
        }    
        this.state.displaySpinner = false;
    }
}

handleClick() {
    this.state.displaySpinner = true;
    const fields = {};
    this.state.isSelected = !this.state.isSelected;
    fields.Id = this.recordId;
    fields[ACCESS_PROV_FIELD.fieldApiName] = this.state.isSelected;
    
    const recordInput = { fields };
    updateRecord(recordInput)
        .then(() => {
            this.state.displaySpinner = false;
            let successMessage = 'Success';
            if(this.state.isSelected){
                this.state.disableButton = true;
                successMessage = 'Access Granted';
            }
            else{
                successMessage = 'Access Revoked';
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: successMessage,
                    variant: 'success'
                })
            );
            // Display fresh data in the component
            return refreshApex(this.state.isSelected);
        })
        .catch(error => {
            this.state.displaySpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updating Record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });

}
}