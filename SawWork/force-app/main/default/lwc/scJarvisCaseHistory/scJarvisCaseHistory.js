import { LightningElement,api } from 'lwc';

import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";

import {HISTORY_COLS,CASE_HISTORY_HEADER} from './scJarvisCaseHistoryLabel'

import getHistoryWrapper from '@salesforce/apex/SC_Jarvis_CaseHistory_Controller.getHistoryWrapper';


                
export default class ScJarvisCaseHistory extends LightningElement 
{
    @api recordId;

    data = [];
    columns=HISTORY_COLS;
    header=CASE_HISTORY_HEADER;
    offsetCount = 15;
    currentCount = 0;
    enableLoad = true;
    loadSpinner= false;
    tableClass = "tableStyle";

    connectedCallback() 
    {        
            //console.log('LOADED!!!!');
            loadStyle(this, staticStyleSheet);          
            this.loadData();
    }

    loadData()
    {
        
        this.loadSpinner = true;
        getHistoryWrapper({
                            'caseId' : this.recordId,
                            'currentCount':this.currentCount,
                            'offset':this.offsetCount
        })
        .then(result => {
            if(!result)
            {
                this.enableLoad = false;
            }
            else
            {
                this.data = [...this.data,...result];
                this.currentCount = this.data.length;                
            }
            
        })
        .then(result => {
            console.log(result);
            this.tableClass = this.currentCount > 8? "tableStyle scrollClass" : "tableStyle";            
            this.loadSpinner = false;     
        })
        .catch(error => {
            this.loadSpinner = false;
            console.log('The error: ' + error);
        });        

    }

}