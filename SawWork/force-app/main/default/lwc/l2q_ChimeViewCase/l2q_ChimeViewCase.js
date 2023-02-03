import { LightningElement,api,track } from 'lwc';
import getCaseName from '@salesforce/apex/L2Q_LOE_Utility.getCaseNumber';

export default class L2q_ChimeViewCase extends LightningElement {
    @api isReviewCasePresent =false;
    @api isIntegrationCasePresent =false;
    @api integrationCaseId='';
    @api reviewCaseId=''
    @track reviewCaseNumber ='';
    @track integrationCaseNumber ='';
    @track reviewCaseOwner = '';
    @track integrationCaseOwner = '';
    handleCancel(event){
        const cancelEvent = new CustomEvent('cancel',{});
            this.dispatchEvent(cancelEvent);
    }
    handleViewReviewCase() {
        window.open('/' + this.reviewCaseId);
    }
    handleViewIntegrationCase() {
        window.open('/' + this.integrationCaseId);
    }
    connectedCallback(){
        
        if(this.isReviewCasePresent){
        getCaseName({caseId:this.reviewCaseId})
            .then(result => {
                this.reviewCaseNumber = result.CaseNumber;
                this.reviewCaseOwner = result.Owner.Name;
                     
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
        }  
        
        if(this.isIntegrationCasePresent){
            getCaseName({caseId:this.integrationCaseId})
                .then(result => {
                    this.integrationCaseNumber = result.CaseNumber;
                    this.integrationCaseOwner = result.Owner.Name;
                         
                })
                .catch(error => {
                    this.error = error;
                    this.isloading = false;
                });
            } 
    }
}