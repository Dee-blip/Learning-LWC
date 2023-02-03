/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 03-22-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-14-2021   apyati   SFDC-8036 added partneraccount
**/
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import checkCaseWithChime from '@salesforce/apex/ChimeTriggerClass.checkCaseAssociateWithChime';
import checkPreSalesUser from '@salesforce/apex/ChimeTriggerClass.checkPreSalesUser';
import hideChimeForm from '@salesforce/apex/ChimeTriggerClass.hideChimeForm';
import chimeDetails from '@salesforce/apex/ChimeTriggerClass.getChimeDetails';
import checkPermission from '@salesforce/apex/ChimeTriggerClass.checkPermissionToAcceptChime';
//import checkCasePermission from '@salesforce/apex/L2Q_LOE_Utility.isCaseButtonEnable';
import markLOEReview from '@salesforce/apex/L2Q_LOE_Utility.markChimeReviewComplete';
import getLOEReviewerId from '@salesforce/apex/L2Q_LOE_Utility.getReviewerId';
import getLOEAdminsId from '@salesforce/apex/L2Q_LOE_Utility.getAdminsId';
import sendReviewCompletion from '@salesforce/apex/L2Q_LOE_Utility.sendReviewCompletionEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SignOff_FIELD from '@salesforce/schema/CHIME__c.Sign_Off__c';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import { updateRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import LOE_MESSAGE from '@salesforce/messageChannel/l2q_LOERefresh__c';
//import method for CHIME Read only functionality
import checkForReadOnly from '@salesforce/apex/ChimeTriggerClass.checkForReadOnly';
import getAllProlexicProductsForChime from '@salesforce/apex/ChimeTriggerClass.getAllProlexicProductsForChime';
import hasTestPermission from '@salesforce/customPermission/ChimeReadOnly';


export default class L2q_ChimeHeader extends NavigationMixin(LightningElement) {
    @api recordId;
    @track chimedata;
    @track showProductLinkPopUp = false;
    @track showSuccessCriteriaPopUp = false;
    @track showContacts = false;
    isloading = false;
    //Below property to pass data to Transition component
    @api chimeStatus;
    @api permission;
    @api formStage;

    @track showEditForm = false;
    @track chimeReopened = false;
    @track chimeAccepted = false;
    @api showSubmitModal = false;
    @api showCaseComponent = false;
    @track showCaseButton = false;
    @track caseButtonLabel = 'Create Case';
    @track disableEditButton = false;
    @track showProductApprovalButton = false;
    @track showApprovalStatus = false;
    @track showProductApprovalModal = false;
    @track showProductApprovalToast = true;
    @track showHistoryModal = false;

    @track showPOCDSRsButton = false;
    @track showPOCDSRModal = false;

    @track viewIntegrationCase = false;
    @track viewReviewCase = false;
    @track showReviewCompleteButton = false;

    @track showTooltip = false;
    @track reviewerId = '';
    @track adminsId = [];

    @track accountLink = '';
    @track opportunityLink = '';
    @track partnerAccountLink = '';
    @track userLink = '';
    @track disableSubmitReview = false;
    @track parentId = '';
    @wire(MessageContext) messageContext;
    @track showCaseView = false;
    partneraccountid;
    partneraccountname;
    @track disableDSRActions = false;
    @track prolexicproducts;
    @track allQueAns = true;
    @track standardPoc = false;
    @track showPSTCaseComponent = false;
    @track pstStage = false;
    @track customPoc = false;
    @track showPSCaseComponent = false;
    @track hideLOE = false;
    @track standImplEnter = false;
    //****** Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 *****
    @track showCaseViewstdPOC = false;
    @track isIntegrationStage = false;
    @track isStageClosed = false;
    //****** Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 *****
    @track prolexicandApproval = true;

    Tooltiptext = '';
    subscription = null;

    @track fromContact;

    //P1 changes
    isPOC = false;
    POCDisable = false;
    EmergencyDisabled = false;
   
    //P2 Changes
    showPOC = false;

    isPreSalesuser = false;
    WorkAtRiskDisabled = false;
    ArchiveDisabled = false;
    disableArchiveButton = false;
    oppId;
    oppName;
    accId;
    accName;
    accType;
    accOwnerName;  

    mouseOver() {
        this.showTooltip = true;
    }

    mouseOut() {
        this.showTooltip = false;
    }

    connectedCallback() {
        this.isloading = true;
        this.fetchLOEReviewerId();
        this.fetchProducts();
        //  this.fetchLOEAdmins();
        this.loadChimeDetails();
        //Check Read only access
        this.checkReadOnlyAccess();
        this.checkForPreSalesUser();
        this.subscription = subscribe(
            this.messageContext,
            LOE_MESSAGE,
            (message) => {
                this.handleRefresh();
            });
        // this.checkingCaseButtinAccess();
    }

    handleRefresh() {
        this.fetchProducts();
        this.loadChimeDetails();

        //  this.checkingCaseButtinAccess();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state && currentPageReference.state.c__fromContact) {
            this.fromContact = true;
            console.log('fromContact', this.fromContact);
            //currentPageReference.state = '';
        }
    }

    fetchProducts() {

        this.prolexicproducts = '';

        getAllProlexicProductsForChime({ chimeId: this.recordId })
            .then(result => {

                console.log('result', ...result);
                if (result && result.length > 0) {
                    this.prolexicproducts = undefined;
                    let tempdata = JSON.parse(JSON.stringify(result));
                    let products;
                    let queans = true;

                    for (let i = 0; i < tempdata.length; i++) {
                        if (!products) {
                            products = tempdata[i].CHIME_Product__r.Product_Name__c;
                        } else {
                            products += ';' + tempdata[i].CHIME_Product__r.Product_Name__c;
                        }
                        queans = queans && tempdata[i].Required_answer_on_product__c;
                    }
                    this.allQueAns = queans;
                    this.prolexicproducts = products;
                    this.showApprovalStatus = true;
                    this.showProductApprovalButton = true;
                }
                else {
                    this.allQueAns = true;
                    this.prolexicproducts = undefined;
                    this.showApprovalStatus = false;
                    this.showProductApprovalButton = false;
                    this.prolexicandApproval = true;
                }
                console.log('prolexicproducts' + this.prolexicproducts);
                console.log('allQueAns' + this.allQueAns);

                console.log('showProductApprovalButton' + this.showProductApprovalButton);



            })
            .catch(error => {
                console.log('error', error);
                this.error = error;
                this.isloading = false;
            });

    }



    fetchLOEReviewerId() {
        getLOEReviewerId({ chimeId: this.recordId })
            .then(result => {
                this.reviewerId = result;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }

    /* fetchLOEAdmins() {
         getLOEAdminsId()
             .then(result => {
                 this.adminsId = result;
             })
             .catch(error => {
                 this.error = error;
                 this.isloading = false;
             });
     }*/

    /* checkingCaseButtinAccess() {
         checkCasePermission({ chimeFormID: this.recordId })
             .then(result => {
                 this.showCaseButton = result;
             })
             .catch(error => {
                 this.error = error;
                 this.isloading = false;
             });
     }*/
    loadChimeDetails() {
        chimeDetails({ chimeId: this.recordId })
            .then(result => {
                this.chimedata = JSON.parse(JSON.stringify(result));
                this.isloading = false;
                //Below added by Manish for Transition
                let operation;

                if (Object.prototype.hasOwnProperty.call(this.chimedata, "Partner_Involved__c")) {
                    this.partnerAccountLink = '/' + this.chimedata.Partner_Involved__c;
                    this.partneraccountid = this.chimedata.Partner_Involved__c;
                    this.partneraccountname = this.chimedata.Partner_Involved__r.Name;
                    console.log('partneraccountid' + this.partneraccountid);
                    console.log('partneraccountname' + this.partneraccountname);

                }
                this.userLink = '/' + this.chimedata.CreatedById;
                this.chimeStatus = this.chimedata.Status__c;
                this.formStage = this.chimedata.Stage__c;
                //P2 Changes
                /*if(this.chimedata.Is_POC_Demo__c === true){
                    this.showPOC = true;
                }else{
                    this.showPOC = false;
                }*/

                //P1 changes
                this.isPOC = this.chimedata.Is_POC_Demo__c;
                if (this.chimedata.Is_POC_Demo__c == true) {
                    this.EmergencyDisabled = true;
                    this.WorkAtRiskDisabled = true;
                    this.showPOCDSRsButton = true;
                    this.showProductApprovalButton = false;
                    this.prolexicandApproval = true;
                    this.showApprovalStatus = false;
                }
                if (this.chimedata.Is_POC_Demo__c &&
                    (this.chimedata.POC_Type__c == 'Standard-POC' || (this.chimedata.POC_Type__c === 'Custom-POC' && this.chimedata.Implementation_Type__c === 'Standard' && this.chimedata.All_Enterprise_Products__c === 'All'))) {
                    this.hideLOE = true;
                } else {
                    this.hideLOE = false;
                }
                if (this.chimedata.Stage__c == 'Closed' || this.chimedata.Stage__c == 'Integration') {
                    this.POCDisable = true;
                    this.EmergencyDisabled = true;
                    this.WorkAtRiskDisabled = true;
                    this.disableDSRActions = true;
                    this.showPSTCaseComponent = false;
                } else {
                    this.pstStage = true;
                }

                if (this.fromContact) {
                    console.log('this.fromContact');
                    this.showContacts = true;
                }

                if (this.chimeStatus == 'Reopened') {
                    this.chimeReopened = true;
                    this.chimeAccepted = false;
                    operation = 'Accept';
                    let reasons = this.chimedata.Reopen_Reason__c.replaceAll(";", ",");
                    if (this.chimedata.Notes__c != undefined || this.chimedata.Notes__c != null) {
                        this.Tooltiptext = 'Reopen Reasons: ' + reasons + ' Notes: ' + this.chimedata.Notes__c;
                    } else {
                        this.Tooltiptext = 'Reopen Reasons: ' + reasons + ' Notes: -NA-';
                    }
                }
                if (this.chimeStatus == 'Accepted') {
                    this.chimeAccepted = true;
                    this.chimeReopened = false;
                    operation = 'Reopen';
                }
                if ((this.formStage == 'Integration' && this.chimeStatus != 'Reopened') || this.formStage == 'Closed') {
                    this.disableEditButton = true;
                }
                if (this.chimeStatus == 'Not Accepted') {
                    operation = 'Accept';
                }
                //console.log('Status Value::' + this.chimeStatus);
                // Below added by Vishnu for Case buttin label
                if (this.chimedata.Integration_Case_ID__c != '' && this.chimedata.Integration_Case_ID__c != undefined) {
                    // this.caseButtonLabel = 'Update Case';
                    this.viewIntegrationCase = true;
                }
                if (this.chimedata.Review_Case_Id__c != '' && this.chimedata.Review_Case_Id__c != undefined) {
                    // this.caseButtonLabel = 'Update Case';
                    this.viewReviewCase = true;
                }
                console.log(' std poc yet : ', this.chimedata.POC_Type__c);
                if (this.chimedata.POC_Type__c !== null && this.chimedata.POC_Type__c === 'Standard-POC') {
                    this.standardPoc = true;
                }

                //******* Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 *******
                    if (this.chimedata.Stage__c === 'Integration') {
                    this.isIntegrationStage = true;
                }
                //******* Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 *******

                //******* Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 ******* added on Apr 20, 2022
                if (this.chimedata.Stage__c === 'Closed') {
                    this.isStageClosed = true;
                }
                //******* Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 ******* added on Apr 20, 2022

                if (this.chimedata.POC_Type__c !== null && this.chimedata.POC_Type__c === 'Custom-POC') {
                    this.customPoc = true;
                    console.log('nw : ' , this.chimedata.Implementation_Type__c , ' nn : ' , this.chimedata.All_Enterprise_Products__c );
                    if(this.chimedata.Implementation_Type__c === 'Standard' && this.chimedata.All_Enterprise_Products__c === 'All')
                    {
                        this.standImplEnter = true;
                    }
                    if(this.chimedata.Implementation_Type__c === 'Standard' && this.chimedata.All_Enterprise_Products__c !== 'All')
                    {
                        this.standImplEnter = false;
                    }

                }
                getLOEAdminsId()
                    .then(res => {
                        this.adminsId = res;
                        if (this.chimedata.LOE_Review_Status__c == 'Being Reviewed' && (userId == this.reviewerId || (this.adminsId.length > 0 && this.adminsId.includes(userId)))) {
                            this.showReviewCompleteButton = true;
                        }
                    })
                    .catch(error => {
                        this.error = error;
                        this.isloading = false;
                    });

                
                console.log(' inte co : ' , hasTestPermission );
 
                if (this.chimedata.LOE_Review_Status__c == 'Review Completed' || this.chimedata.Stage__c == 'Integration' || this.chimedata.Stage__c == 'Closed' || userId == this.reviewerId || hasTestPermission) {
                    this.disableSubmitReview = true;
                }
                console.log(' this.formStage  : ' , this.formStage , ' uid : ' , userId , ' rev id : ' , this.reviewerId );

                if (this.formStage != 'Closed' && this.formStage != 'Integration' && (userId != this.reviewerId) && hasTestPermission != true ) {
                    console.log('inn : ');
                    this.showCaseButton = true;
                }

                if (!this.chimedata.Is_POC_Demo__c && this.prolexicproducts && this.chimedata.Product_Approval_Status__c == 'Not Started' && this.showProductApprovalToast) {
                    this.showProductApprovalToast = false;
                    this.showToast('There is a product on this form which requires internal approvals before completing a sale. Please click on the Product Approvals option to start that review.', 'warning', 'sticky');
                }
                if (!this.chimedata.Is_POC_Demo__c && this.prolexicproducts && this.chimedata.Product_Approval_Status__c == 'Gating Review Approved' && this.showProductApprovalToast) {
                    this.showProductApprovalToast = false;
                    this.showToast('There is a product on this form which  requires Integration approval before completing a sale.  Please click on the Product Approvals option to start the Integration review.', 'warning', 'sticky');
                }
                console.log('bfro' );
                console.log('cndtn elvatd ' , this.showApprovalStatus , ' :: nn : ' , this.chimedata.Product_Approval_Status__c);
                if(this.chimedata.POC_Type__c == null && this.showProductApprovalButton === true && this.chimedata.Product_Approval_Status__c !== 'Integration Review Approved')
                {
                    console.log('diff set');
                    this.prolexicandApproval = false;
                }

                this.checkPermissionofUser(operation);

                if(this.standardPoc){
                    this.checkCasesWithChime();
                }
                else if(this.chimedata.Integration_Case_ID__c){
                    this.disableArchiveButton = true;
                }
                // Archive Chime
                this.hideChime(this.chimedata.Archive_Hidden__c);
               
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    checkPermissionofUser(action) {
        checkPermission({ operation: action })
            .then(result => {
                let res = result;
                this.permission = result;
                //console.log('result Value::calling method in child' + res);
                this.template.querySelector('c-chime-Transition').callFromParent(result);
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    navigateToAccount(event) {
        let accId = event.target.id;
        accId = accId.split('-')[0];
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accId,
                objectApiName: 'Account',
                actionName: 'view'
            },
        });
    }
    navigateToOpportunity(event) {
        let oppId = event.target.id;
        oppId = oppId.split('-')[0];
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: oppId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
        });
    }
    navigateToUser(event) {
        let uId = event.target.id;
        uId = uId.split('-')[0];
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: uId,
                objectApiName: 'User',
                actionName: 'view'
            },
        });
    }

    navigateToChime(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: "CHIME__c",
                actionName: "view"
            }
        },
            true
        );
    }

    handleOpenSuccessCriteria() {
        this.showSuccessCriteriaPopUp = true;
    }
    handleCloseSuccessCriteria() {
        this.showSuccessCriteriaPopUp = false;
        // window.location.href = '/'+ this.recordId;
    }
    handleLinksOpen() {
        this.showProductLinkPopUp = true;
    }
    handleClose() {
        this.showProductLinkPopUp = false;
    }

    handleContactsOpen() {
        this.showContacts = true;
    }
    handleContactsClose() {
        this.showContacts = false;
        this.navigateToChime();
    }

    childUpdated(event) {
        let value = event.detail;
        if (value == 'Reopened') {
            this.chimeReopened = true;
            this.chimeAccepted = false;
            //this.POCDisable = false;
        }
        else if (value == 'Accepted') {
            this.chimeAccepted = true;
            this.chimeReopened = false;
        }
    }

    showSubmitForReview() {
        this.showSubmitModal = true;

    }

    hideSubmitForReview() {
        this.showSubmitModal = false;
    }


    showProductApproval() {
        if (Object.prototype.hasOwnProperty.call(this.chimedata, "Opportunity__c")) {
            this.showProductApprovalModal = true;
        }else{
            this.showToast('Opportunity needs to be attached to this CHIME form to proceed.', 'warning', 'sticky');
        }
    }

    hideProductApproval() {
        this.showProductApprovalModal = false;
    }


    showPOCDSRs() {
        this.showPOCDSRModal = true;
    }

    hidePOCDSRs() {
        this.showPOCDSRModal = false;
    }

    showHistory() {
        this.showHistoryModal = true;
    }

    hideHistory() {
        this.showHistoryModal = false;
    }




    hideViewCase() {
        this.showCaseView = false;
    }

    //****** Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 ******
    hideStdPocCaseView() {
        this.showCaseViewstdPOC = false;
    }
    //****** Added by Ashin (7/FEB/2022) @JIRA:- ESESP-6647 ******

    showCaseComponentModal() {

        this.showCaseComponent = true;
    }
    showPSTCase() {
        this.showPSTCaseComponent = true;
    }

    showPSCase() {
        this.showPSCaseComponent = true;
    }

    hidePSTCaseCreate() {
        this.showPSTCaseComponent = false;
    }

    hidePSCaseCreate() {
        this.showPSCaseComponent = false;
    }

    hideCaseCreate() {
        this.showCaseComponent = false;
        //  eval("$A.get('e.force:refreshView').fire();");
        this.connectedCallback();
    }

    editChime() {
        if (this.disableEditButton) {
            this.showToast('You cannot Edit this CHIME form as it\'s either Accepted or Not Accepted', 'error', 'dismissable');
            return;
        }
        this.showEditForm = true;
        if (this.oppId != null)
            this.parentId = this.oppId;
        else
            this.parentId = this.accId;
    }

    closeQA() {
        this.showEditForm = false;
    }

    handleViewCase() {
        window.open('/' + this.chimedata.Integration_Case_ID__c);
    }

    handleViewReviewCase() {
        window.open('/' + this.chimedata.Review_Case_Id__c);
    }

    confirmReviewCompletion() {
        markLOEReview
        markLOEReview({ chimeId: this.recordId })
            .then(result => {
                //console.log(result);
                this.showToast('LOE review has been completed', 'success', 'dismissable');
                sendReviewCompletion({ chimeId: this.recordId }).then(res => {
                    //console.log(res);
                    window.setTimeout(function () { window.location.reload() }, 2000);
                });

            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }

    // Handling toasts
    showToast(message, variant, mode) {
        // alert('here');
        const evt = new ShowToastEvent({

            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    get viewCase() {
        return (this.viewIntegrationCase || this.viewReviewCase);
    }

    reopentext(event) {
        //console.log('inside reopentext',event);
        this.disableEditButton = false;
        this.Tooltiptext = 'Reopen Reasons: ' + event.detail.reasons + ' Notes:' + event.detail.notes;
    }
    /*
    saveSignOff(event){
        const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[SignOff_FIELD.fieldApiName] = event.target.checked;
    
            const recordInput = { fields };
            updateRecord(recordInput)
            .then(result => {
                //console.log("Sign Off field updated Successfull: "+result);
            })
            .catch(error => {
                //console.log("Sign Off field not updated: "+error);
            })
    }*/

    showViewCaseModal() {
        this.showCaseView = true;
    }

    //****** Added By Ashin (7/FEB/2022) ********
    showViewCaseModalstdPOC() {
        this.showCaseViewstdPOC = true;
    }
    //****** Added By Ashin (7/FEB/2022) ********

    renderedCallback() {
        const selectedStyle = document.createElement('style');
        selectedStyle.innerText = `c-l2q-chime-heafer .pocbadge{
            background-color: mediumturquoise;
        }`;
    }

    //P1 changes - SFDC-8934
    formAccepted(event) {
        this.disableEditButton = true;
    }

    responseDisable = false;
    disableBusinessGoals = false;
    checkReadOnlyAccess() {
        checkForReadOnly()
            .then(result => {
                console.log('result for checkForReadOnly', result);
                if (result == 'Edit') {
                    this.responseDisable = false;
                } else if (result == 'ReadOnly') {
                    this.disableArchiveButton = true;
                    this.responseDisable = true;
                    this.disableSubmitReview = true;
                    this.showCaseButton = false;
                    console.log('setting false;');
                    this.showReviewCompleteButton = false;
                    this.viewReviewCase = false;
                    this.viewIntegrationCase = false;
                    this.disableEditButton = true;
                    this.disableBusinessGoals = true;
                    //this.disableDeleteIcon= true;
                    this.makeUnclickable();
                    this.template.querySelector('[data-id="chimeProgressBar"]').className = 'unclickable';
                }
            })
            .catch(error => {
                console.log('error', error);
            });
    }

    showCloneModalPopup = false;
    showCloneModal() {
        this.showCloneModalPopup = true;
    }

    hideCloneModal() {
        this.showCloneModalPopup = false;
    }

    handleArchiveButton(){
        let isArchive = true;
        hideChimeForm({ chimeId: this.recordId, isArchive:isArchive})
        .then(result => {
            window.location.reload();
        })
        .catch(error => {

        });
        
    }

    handleUnarchiveButton(){
        let isArchive = false;
        hideChimeForm({ chimeId: this.recordId, isArchive:isArchive})
        .then(result => {
            window.location.reload();
        })
        .catch(error => {

        });
    }

    hideChime(value){
        if(value){
            this.ArchiveDisabled = true;
            if (Object.prototype.hasOwnProperty.call(this.chimedata, "Opportunity1__c")) {
                this.oppId = this.chimedata.Opportunity1__c;
                this.oppName = this.chimedata.Opportunity1__r.Name;
                this.opportunityLink = '/' + this.chimedata.Opportunity1__c;
            }
            this.accId = this.chimedata.Account1__c;
            this.accName = this.chimedata.Account1__r.Name;
            this.accOwnerName = this.chimedata.Account1__r.Owner.Name;
            this.accType = this.chimedata.Account1__r.Type;
            this.accountLink = '/' + this.chimedata.Account1__c;
            
            this.disableSubmitReview = true;
            this.showCaseButton = false;
            this.showReviewCompleteButton = false;
            this.viewReviewCase = false;
            this.viewIntegrationCase = false;
            this.disableEditButton = true;
            this.disableBusinessGoals = true;
            this.customPoc = false;
            this.standardPoc = false;
            this.showPOCDSRsButton = false;
        }
        else{
            this.ArchiveDisabled = false;
            if (Object.prototype.hasOwnProperty.call(this.chimedata, "Opportunity__c")) {
                this.oppId = this.chimedata.Opportunity__c;
                this.oppName = this.chimedata.Opportunity__r.Name;
                this.opportunityLink = '/' + this.chimedata.Opportunity__c;
            }
            this.accId = this.chimedata.Account__c;
            this.accName = this.chimedata.Account__r.Name;
            this.accOwnerName = this.chimedata.Account__r.Owner.Name;
            this.accType = this.chimedata.Account__r.Type;
            this.accountLink = '/' + this.chimedata.Account__c;

           if(!this.disableArchiveButton){
                this.disableSubmitReview = false;
                this.disableEditButton = false;
            }
        
        }
    }
    checkForPreSalesUser() {
        checkPreSalesUser()
            .then(result => {
                this.isPreSalesuser = result;
                if(!this.isPreSalesuser){
                    this.disableArchiveButton = true;
                }
            })
            .catch(error => {
                console.log('error', error);
            });
    }
    checkCasesWithChime(){
        checkCaseWithChime({ chimeId: this.recordId})
        .then(result => {
            if(result){
                this.disableArchiveButton = true;
            }
        })
        .catch(error => {
            console.log('error', error);
        });
    }
}