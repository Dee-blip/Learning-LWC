/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 12-21-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-26-2021   apyati   Initial Version
**/
import { LightningElement, track, api } from 'lwc';
import getProductSpecificFormAuditTrails from '@salesforce/apex/L2Q_CHIME_AuditTrail.getProductSpecificFormAuditTrails';

const columns = [
    {
        label: 'Field', fieldName: 'responseLink', type: 'url', cellAttributes: { class: 'historyClass' }, wrapText: true,
        typeAttributes: { label: { fieldName: 'productQuestion' }, value: { fieldName: 'responseLink' }, target: '_blank' }
    },
    { label: 'Previous Value', fieldName: 'PreviousValue__c', type: 'text', cellAttributes: { class: 'historyClass' }, wrapText: true },
    { label: 'New Value', fieldName: 'CurrentValue__c', type: 'text', cellAttributes: { class: 'historyClass' }, wrapText: true },
    {
        label: 'Last Modified By', fieldName: 'CreatedById', type: 'url',
        typeAttributes: { label: { fieldName: 'CreatedByName' }, value: { fieldName: 'linkName' }, target: '_blank' }, cellAttributes: { iconName: { fieldName: 'userIconType' }, iconPosition: 'left', class: 'editedByClass' }, wrapText: true
    },
    {
        label: 'Last Modified Date', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
            month: "long",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit"
        },
        cellAttributes: { class: 'dateClass' },
        wrapText: true
    },
];

export default class ChimeFormAuditTrailComponent extends LightningElement {
    columns = columns;
    @api formid;
    @track requiredAuditTrails;
    @track listOfProdTrails;
    @track areTrailsVisible = false;
    @track options;
    @track value;
    auditTrailsMap = {};
    @api
    formatTrailsJS(trails) {
        trails.map(eachRow => {
            let returnRow = eachRow;
            console.log(JSON.stringify(returnRow));
            if(returnRow.CHIME_Response__c && returnRow.CHIME_Response__r.Question_Type__c === 'Multipicklist'){
                
                let currObj = this.tryParseJSON(returnRow.CurrentValue__c);
                if(currObj){
                    let newCurrentValue='';
                    for(let i=0;i< currObj.length;i++ ){
                        newCurrentValue = (i===0? currObj[i]+'' : (newCurrentValue+', '+currObj[i]));
                    }
                    returnRow.CurrentValue__c = newCurrentValue;
                }

                
                let preObj = this.tryParseJSON(returnRow.PreviousValue__c);
                if(preObj){
                    let newPreviousValue='';
                    for(let i=0;i< preObj.length;i++ ){
                        newPreviousValue = (i===0? preObj[i]+'' : (newPreviousValue+', '+preObj[i]));
                    }
                    returnRow.PreviousValue__c = newPreviousValue;
                }
            }
            returnRow.CreatedByName = returnRow.CreatedBy.Name;
            returnRow.CreatedById = '/' + returnRow.CreatedById;
            if(returnRow.CHIME_Response__c){
            returnRow.productQuestion = returnRow.CHIME_Response__r.CHIME_Product_Question__r.Question_Text__c;
            }else{
            returnRow.productQuestion= returnRow.Field__c;
            }
            returnRow.responseLink = '/' + returnRow.Id;
            if (returnRow.isCustomerUpdated__c === true) {
                returnRow.userIconType = 'standard:customers';
            }
            else {
                returnRow.userIconType = 'standard:user';
            }
            return returnRow;
        });
        return trails;
    }

    getRequiredSetOfAuditTrails(productName) {
        return this.auditTrailsMap[productName];
    }

    getCompleteAuditTrail(cformId) {
        console.log('Inside Form Comp : ' + cformId);
        let options = [];
        getProductSpecificFormAuditTrails({ formId: cformId })
            .then((result) => {
                if (result) {
                    this.areTrailsVisible = true;
                    let copyData = JSON.parse(JSON.stringify(result));
                    console.log('copyData');
                    console.log(copyData);
                    let eachOption = { label: 'All', value: 'All', selected: true };
                    this.value = eachOption.value;
                    options.push(eachOption);
                    eachOption = { label: 'CHIME Form', value: 'CHIME Form', selected: false };
                    options.push(eachOption);
                    eachOption = { label: 'All Products', value: 'All Products', selected: false };
                    options.push(eachOption);
                    let allprodtrails =[];
                    let alltrails = [];
                    let chimetrails=[]
                    for (let eachProd in copyData) {
                        if(eachProd===null){
                            continue;
                        }
                        console.log('eachProd');
                        if( eachProd==='CHIME Form'){
                            chimetrails.push(...copyData[eachProd]);
                        }
                        if(eachProd!=='CHIME Form'){
                            eachOption = { label: eachProd, value: eachProd, selected: false };
                            options.push(eachOption);
                            allprodtrails.push(...copyData[eachProd]);
                        }
                        alltrails.push(...copyData[eachProd]);
                        console.log('alltrails');
                        console.log(alltrails);
                        this.auditTrailsMap[eachProd] = this.formatTrailsJS(copyData[eachProd]);
                    }
                    this.options = options;
                    this.auditTrailsMap['All'] = this.formatTrailsJS(alltrails);
                    this.auditTrailsMap['CHIME Form'] = this.formatTrailsJS(chimetrails);
                    this.auditTrailsMap['All Products'] = this.formatTrailsJS(allprodtrails);

                    this.requiredAuditTrails = this.getRequiredSetOfAuditTrails(options[0].value);

                    // let copyData = JSON.parse(JSON.stringify(result));
                    // let outArray = [];
                    // for (let eachProd in copyData) {
                    //     let innerObj = {
                    //         "productName": eachProd,
                    //         "auditTrails": this.formatTrailsJS(copyData[eachProd])
                    //     };
                    //     outArray.push(innerObj);
                    // }
                    // console.log(outArray);
                    // this.listOfProdTrails = outArray;
                }

               
            })
            .catch(error => {
                console.log("Error getting the result");
                console.log(error);
            }
            );
    }

    handleSelection(event) {
        console.log('Selected option : ' + event.detail.value);
        this.requiredAuditTrails = this.getRequiredSetOfAuditTrails(event.detail.value);
    }

    connectedCallback() {
        console.log('formid in connected callback : ' + this.formid);
        if (this.formid) {
            this.getCompleteAuditTrail(this.formid);
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