/***************************************************************************************************
* @author               Ashin Louis
* @date                 07/FEB/2022
* @JIRA                 ESESP-6647
* @Component Name       l2q_ChimeViewAllStdPstCases
* @LWCFileType          Js
* @description  This is used as Js file to display all the PST cases associated to the current 
                Standard-POC Chime record
*****************************************************************************************************/


import { LightningElement, wire, api } from 'lwc';
import getCases from '@salesforce/apex/viewAllCasesStdPOC.getCases';
const columns = [
    {
        label: 'Sl No',
        fieldName: 'slno',
        type: 'number',
        initialWidth: 100
    },
     {
        label: 'Case Number',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {label: { fieldName: 'CaseNumber' }, target: '_blank'}
    }, 
    {
        label: 'PST Case Products',
        fieldName: 'PST_Case_Product__c',
        type: 'text',
    }, 
    {
        label: 'Case Owner',
        fieldName: 'OwnerId',
        type: 'text'
    }
    
];

export default class L2q_ChimeViewAllStdPstCases extends LightningElement {
    consData = [];
    columns = columns;
    @api chimeId;  //The chimeID comes from parent LWC component : l2q_ChimeHeader
    

    //For Cancel button on the component
    handleCancel(event){
        const cancelEvent = new CustomEvent('cancel',{});
            this.dispatchEvent(cancelEvent);
    }

    //To fetch the cases of current chime record. 
    @wire(getCases, {chId:'$chimeId'})
    Cases({ error, data }) {
        
        if (data) {   
            let tempConList = []; 
            var i=0;
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.recordLink = '/' + tempConRec.Id;
                tempConRec.OwnerId = tempConRec.Owner.Name;
                tempConRec.slno = i+1;
                i=tempConRec.slno;
                tempConList.push(tempConRec);
                
            });
            
            this.consData = tempConList;
            this.error = undefined;
            console.table(this.consData);

        } else if(error)  {
            console.log('error is',error);
        }
    }
}