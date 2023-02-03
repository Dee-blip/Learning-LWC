import { LightningElement} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";
import getCaseCountData from '@salesforce/apex/SC_Jarvis_Case_Widget_Controller.getCaseCountData';
//import { assignHandler, maximize } from 'lightningsnapin/minimized';
import {LABELS} from './i18n';

export default class ScJarvisCaseWidget extends NavigationMixin(LightningElement) {
    label = LABELS;
    myOpenCaseCount;
    updatedCaseCount;
    closedCaseCount;
    displayWidget;
    displayNewCaseButton;
    
    goToSupportHome() {
        console.log('test');
        this[NavigationMixin.Navigate]({
        type : 'standard__webPage',
        attributes: {
        url : '/customers/s/support'
        }
        });
    }

    goToNewCase() {
        console.log('test');
        this[NavigationMixin.Navigate]({
        type : 'standard__webPage',
        attributes: {
        url : '/customers/s/support?mode=newcase'
        }
        });
    }

    connectedCallback(){        
        //console.log('Vam ');
        loadStyle(this, staticStyleSheet); 
        getCaseCountData().then(result => {
            console.log(result);
            this.myOpenCaseCount = result.myOpenCaseCount;
            this.updatedCaseCount = result.updatedCaseCount;
            this.closedCaseCount = result.closedCaseCount;
            this.displayWidget = result.displayWidget;
            this.displayNewCaseButton = result.displayNewCaseButton;
        })
        .catch(error => {
            console.log('The error: ' + error + JSON.stringify(error)) ;
        });

        

    }

    

    

}