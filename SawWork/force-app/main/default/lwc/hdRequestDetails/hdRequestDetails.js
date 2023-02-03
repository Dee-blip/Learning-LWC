import { LightningElement, wire, api, track } from 'lwc';
import getServiceRequestData from '@salesforce/apex/HD_Request_Detail_Input_Lightning.getDetails';
import getIsEditable from '@salesforce/apex/HD_Request_Detail_Input_Lightning.iseditableSR';
import { refreshApex } from '@salesforce/apex';

export default class HdRequestDetails extends LightningElement {
    @api recordId;
    @track srDetail;
    @track srData;
    srTitle;
    displayInSecondColumn = false;
    showDetails = true;
    isLoading = true;

    @api fireRefresh() {
        this.isLoading = true;
        refreshApex(this.srData);
    }

    @wire(getIsEditable, { incidentID : '$recordId'})
    wiredIsEnabled;

    @wire(getServiceRequestData, { incidentID : '$recordId'})
    wiredSRData(result){
        this.srData = result;
        if(result.data){
            let inputDetails =result.data.srInputDetails;
            let secondColDisplay = result.data.dataDisplayInSecondColumn;
            this.displayInSecondColumn = result.data.dataDisplayInSecondColumn;
            this.srTitle = result.data.srInformation.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c;
            let srdetails = [];

            if(!secondColDisplay){
                for(let key in inputDetails) {
                    if(inputDetails[key]){
                        srdetails.push(this.getMergeColumn(inputDetails[key],null));
                    }
                }
            }

            if(secondColDisplay){
                let masterArr =[];
                let col1 = [];
                let col2 = [];
                for(let key in inputDetails){
                    if(inputDetails[key]){
                        let secColumn = inputDetails[key].BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c ;

                        if(inputDetails[key].HD_Ffi_Response_Type__c !== 'Header Section'){
                            if(!secColumn){
                                col1.push(inputDetails[key]);
                            } else {
                                col2.push(inputDetails[key]);
                            }
                        }else{
                            let mergeArry = [];
                            mergeArry = this.mergeArray(col1,col2);
                            col1 =[];
                            col2 =[];
                            for(let x in mergeArry){
                                if(mergeArry[x]){
                                    masterArr.push(mergeArry[x]);
                                }
                            }

                            masterArr.push(this.getMergeColumn(inputDetails[key],null));
                        }
                    }
                }
                // to add details after end of input
                let mergeArry = [];
                mergeArry = this.mergeArray(col1,col2);
                for(let x in mergeArry){
                    if(mergeArry[x]){
                        masterArr.push(mergeArry[x]);
                    }
                }
                srdetails = masterArr;
            }
            this.srDetail = srdetails;
            this.isLoading = false;
        }
        else if(result.error){
            this.isLoading = false;
            window.console.log('Error in wiredSRData>> '+JSON.stringify(result.error));   
        }
    }

    getMergeColumn(data1, data2){
        let temp ={};
        if(data1){
            temp.key = data1.BMCServiceDesk__Input__c;
            temp.prompt = data1.BMCServiceDesk__Input__c;
            temp.response = data1.BMCServiceDesk__Response__c;
            temp.type = data1.HD_Ffi_Response_Type__c;
            temp.addinfo = data1.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c;
            temp.tooltip = data1.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c;
            if(temp.type === 'Header Section'){
                temp.isHeader = true;
            }
            if(temp.response === 'Data is encrypted'){
                temp.isEncrypted = true;
            }
            if(temp.addinfo === 0){
                temp.isNote = true;
            }
            if(temp.tooltip != null && temp.tooltip !== ''){
                temp.addTooltip = true;
            }
        }
        if(data2){
            temp.key2 = data2.BMCServiceDesk__Input__c;
            temp.prompt2 = data2.BMCServiceDesk__Input__c;
            temp.response2 = data2.BMCServiceDesk__Response__c;
            temp.type2 = data2.HD_Ffi_Response_Type__c;
            temp.addinfo2 = data2.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c;
            temp.tooltip2 = data2.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c;
            if(temp.type2 === 'Header Section'){
                temp.isHeader2 = true;
            }
            if(temp.response2 ==='Data is encrypted'){
                temp.isEncrypted2 = true;
            }
            if(temp.addinfo2 === 0){
                temp.isNote2 = true;
            }
            if(temp.tooltip2 != null && temp.tooltip2 !== ''){
                temp.addTooltip2 = true;
            }
        }
        return temp;
    }

    mergeArray(c1,c2){
        let mergeArry = [];
        let index =0;

        while(index < c1.length && index< c2.length){
            mergeArry.push(this.getMergeColumn(c1[index],c2[index]));
            index++;
        }
        while(index <c1.length){
            mergeArry.push(this.getMergeColumn(c1[index],null));
            index++;
        }
        while(index < c2.length){
            mergeArry.push(this.getMergeColumn(null,c2[index]));
            index++;
        }
        return mergeArry;
    }
    
    handleDetailsChevron(){
        this.showDetails=!this.showDetails;
    }
    handleEditSR(){
        const editClickEvent = new CustomEvent('editclick');
        this.dispatchEvent(editClickEvent);
    }
}