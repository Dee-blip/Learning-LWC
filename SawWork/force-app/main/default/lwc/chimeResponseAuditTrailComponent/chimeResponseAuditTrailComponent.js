import { LightningElement, track, api } from 'lwc';
import getAuditTrails from '@salesforce/apex/L2Q_CHIME_AuditTrail.getAuditTrails';

const columns = [
    { label: 'Response History', fieldName: 'CurrentValue__c', type: 'text', cellAttributes: { class: 'historyClass' } },
    { label: 'Last Modified By', fieldName: 'CreatedById', type: 'url', typeAttributes: { label: { fieldName: 'CreatedByName' }, value: { fieldName: 'linkName' }, target: '_blank' }, cellAttributes: { iconName: { fieldName: 'userIconType' }, iconPosition: 'left', class: 'editedByClass' } },
    {
        label: 'Last Modified Date', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
            month: "long",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit"
        },
        cellAttributes: { class: 'dateClass' }
    },
];

export default class ChimeResponseAuditTrailComponent extends LightningElement {
    columns = columns;
    @api responseid;
    @track AuditTrails;

    @api
    getAuditTrailForResponse(responseId) {
        console.log('Inside Response Comp : ' + responseId);
        getAuditTrails({ responseId: responseId })
            .then((result) => {
                if (result) {
                    let copyData = JSON.parse(JSON.stringify(result));
                    let firstRowFlag = true;
                    copyData.map(eachRow => {
                        let returnRow = eachRow;
                        if(returnRow.CHIME_Response__r.Question_Type__c === 'Multipicklist'){
                            let currObj = this.tryParseJSON(returnRow.CurrentValue__c);
                            if(currObj){
                                let newCurrentValue='';
                                for(let i=0;i< currObj.length;i++ ){
                                    newCurrentValue = (i===0? currObj[i]+'' : (newCurrentValue+', '+currObj[i]));
                                }
                                returnRow.CurrentValue__c = newCurrentValue;
                            }
                        }
                        returnRow.CreatedByName = returnRow.CreatedBy.Name;
                        returnRow.CreatedById = '/' + returnRow.CreatedById;
                        if (returnRow.isCustomerUpdated__c === true) {
                            returnRow.userIconType = 'standard:customers';
                        }
                        else {
                            returnRow.userIconType = 'standard:user';
                        }
                        if (firstRowFlag === true) {
                            firstRowFlag = false;
                            returnRow.historyClass = returnRow.editedByClass = returnRow.dateClass = 'slds-text-color_success';
                        }
                        return returnRow;
                    });
                    console.log('copyData : ');
                    console.log(copyData);
                    this.AuditTrails = copyData;
                }
            })
            .catch(error => {
                console.log("Error getting the result"+error);
            }
            );
    }

    connectedCallback() {
        if (this.responseid) {
            this.getAuditTrailForResponse(this.responseid);
        }
    }
    tryParseJSON (jsonString){
        try {
            let o = JSON.parse(jsonString);
            if (o && typeof o === "object") {
                return o;
            }
        }
        catch (e) { 
            console.log(e);
        } 
        return false;
    }
}