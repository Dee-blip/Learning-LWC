import { LightningElement,api,wire } from 'lwc';
import {LABELS} from './i18n';
import getLabelDetails from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getLabelDetails';

import {getRecord} from 'lightning/uiRecordApi';
import RECORDTYPE_FIELD from '@salesforce/schema/Case.RecordType.Name';


export default class ScJarvisCasePreview extends LightningElement 
{
    @api recordid;
    recordTypeName;
    labels = LABELS;
    akamcaseid;
    subject;
    caseValues;
    description;

    @wire(getRecord, { recordId: '$recordid', fields: [RECORDTYPE_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            console.log('HERE: ' + JSON.stringify(data));
            let recordTypeName = data.fields.RecordType.displayValue;
            console.log('this.recordTypeName: ' + recordTypeName);
            getLabelDetails ({
                labelvalues:this.labels,
                caseid : this.recordid,
                recordTypeName : recordTypeName,
                preview : true
    
            }).then(result => {
                console.log(JSON.stringify(result));
                this.akamcaseid=result.akamcaseid;
                this.subject=result.subject;
                this.description = result.description;
                this.description = this.description && this.description.includes('\n')? 
                this.description.replaceAll('\n','<br/>'): this.description;
                this.caseValues = result.caseValues;
                document.title = result.akamcaseid;
            }).catch(error1 => {
                console.log(JSON.stringify(error1));
            });
    
        } else if (error) {
            console.log('HERE: ' + JSON.stringify(error));
        }
    }

    closeModal()
    {        
        const closeEvent = new CustomEvent('closecreateevent', {
            detail: {
                close: true
            }
        });
        this.dispatchEvent(closeEvent);        
            
    }

}