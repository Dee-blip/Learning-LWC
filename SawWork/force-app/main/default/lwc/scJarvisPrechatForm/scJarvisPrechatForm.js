/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-22-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   12-27-2021   Vishnu Vardhan   Initial Version
**/
import BasePrechat from 'lightningsnapin/basePrechat';
import { api, track, wire } from 'lwc';
// import startChatLabel from '@salesforce/label/c.StartChat';
import getPreChatInfo from '@salesforce/apex/ScJarvisPrechatController.getPreChatInfo';
import getCaseId from '@salesforce/apex/ScJarvisPrechatController.getCaseId';
import { NavigationMixin } from 'lightning/navigation';
import { LABELS } from './i18n';
import JV_AKACHAT_DEPID from '@salesforce/label/c.JarvisAkachatDeploymentId';
import { loadStyle } from 'lightning/platformResourceLoader';
import jarvischatcss from '@salesforce/resourceUrl/jarvischat';


export default class ScJarvisPrechatForm extends NavigationMixin(BasePrechat) {
    @api prechatFields;
    @api backgroundImgURL;
    @track fields;
    @track namelist;

    pWrap;
    isFormInvalid = true;
    selectedRt;
    selectedRtValue;
    selRtName;
    productId;
    caseId;

    JV_AKACHAT_DEPID = JV_AKACHAT_DEPID;
    LABELS = LABELS;

    get isAkatec() {
        return this.selectedRt && this.selectedRt.label === this.LABELS.RT_AKATECH;
    }

    get isAmg() {
        return this.selectedRt && this.selectedRt.label === this.LABELS.RT_AMG;
    }

    get showChat() {

        const {amgButtonId, availableButtons, productList, productToButtonMapping} = this.pWrap || {};
        const isAkatecAvailable = Array.isArray(productList)  
                && Array.isArray(availableButtons) 
                && productList.find(bt => {
                    const prodButtonId = productToButtonMapping[bt.value];
                    return availableButtons.includes(prodButtonId);
                });

        const isAmgAvailable = amgButtonId //&& true;
                && Array.isArray(availableButtons) 
                && availableButtons.includes(amgButtonId);

        return (this.isAkatec && isAkatecAvailable) 
            || (this.isAmg && isAmgAvailable);
    }

    get hideSubject() {
        const {availableButtons} = this.pWrap || {};

        return (this.isAkatec && this.productId && !availableButtons.includes(this.prodButtonId));
    }

    get hideDesc() {
        const {availableButtons} = this.pWrap || {};

        return (this.isAkatec && this.productId && !availableButtons.includes(this.prodButtonId));
    }

    get hideStartButton() {
        const {availableButtons} = this.pWrap || {};

        return (this.isAkatec && this.productId && !availableButtons.includes(this.prodButtonId));
    }

    get showOfflinePage() {
        const {availableButtons} = this.pWrap || {};

        const isAkaProdSupportOffline = this.isAkatec && this.productId && !availableButtons.includes(this.prodButtonId);
        return this.selectedRt && (!this.showChat || isAkaProdSupportOffline);
    }

    get rtSreenCss() {
        return this.selectedRt ? 'slds-p-around_medium layer hide' : 'slds-p-around_medium layer';
    }

    get formCss() {
        return this.selectedRt ? 'slds-p-around_medium base' : 'slds-p-around_medium base';
    }
    
    handleFormChange(ev) {
        const inpid = ev.currentTarget.dataset.inpid;
        if( inpid === 'product') {
            this.productId = ev.currentTarget.value;
        } else if( inpid === 'akamcaseid') {
            const akamCaseIdEle = this.template.querySelector('[data-inpid="akamcaseid"]');
            akamCaseIdEle.setCustomValidity('');
            akamCaseIdEle.reportValidity();
        } 

        this.isFormInvalid = [...this.template.querySelectorAll('[data-inpid]')]
                            .find(el => !el.checkValidity());
    }

    @wire(getPreChatInfo, {deploymentId: JV_AKACHAT_DEPID})
    processGetPreChatInfo ({error, data}) {
        if (error) {
            // TODO: Error handling
        } else if (data) {
            this.pWrap = data;

            if(this.selRtName && !this.selectedRt ) {
                this.selectedRt = this.pWrap.categoryList.find(el => el.label === this.selRtName);
                this.selectedRtValue = this.selectedRt.value;
            }
        }
    }

    handleRtDescClick(ev) {
        const {categoryList} = this.pWrap || {};
        this.selRtName = ev.currentTarget.dataset.id;
        if(categoryList) {
            this.selectedRt = categoryList.find(el => el.label === this.selRtName);
            this.selectedRtValue = this.selectedRt.value;
        }
    }

    get showSpinner() {
        return this.selectedRtValue && !this.pWrap;
    }

    get prodButtonId() {
        const {productToButtonMapping} = this.pWrap || {};

        return this.productId && productToButtonMapping && productToButtonMapping[this.productId];
    }

    clearRtSelection() {
        this.selectedRt = '';
        this.selectedRtValue = '';
        if(!this.pWrap.availableButtons.includes(this.prodButtonId)) {
            this.productId = '';
        }
    }


    getInpFieldValue(dataInpid) {
        const el = this.template.querySelector(`[data-inpid="${dataInpid}"]`);
        return el && el.value;
    }

    /**
     * On clicking the 'Start Chatting' button, send a chat request.
     */
    handleStartChat() {   

        const akamcaseid = this.getInpFieldValue('akamcaseid');
        
        if(this.isAmg && akamcaseid) {            
            getCaseId({akamCaseId: akamcaseid})
            .then((result) => {
                this.caseId = result;
                this.triggerChat();
            }).catch(ex => {
                const errorMsg = ex && ex.body && ex.body.message;
                const akamCaseIdEle = this.template.querySelector('[data-inpid="akamcaseid"]');
                akamCaseIdEle.setCustomValidity(errorMsg);
                akamCaseIdEle.reportValidity();
            });

        } else {
            this.triggerChat();
        }
    
    }


    triggerChat() {

        const {contactId, accountId, categoryList, productList, amgButtonId, firstName, lastName} = this.pWrap || {};
        const recordTypeId = this.selectedRt.value;// this.template.querySelector('[data-inpid="category"]').value;
        const productId = this.productId;
        const product = productList.find(el => el.value === productId );
        const subject = this.getInpFieldValue('subject');
        const description = this.getInpFieldValue('description');
        const akamcaseid = this.getInpFieldValue('akamcaseid');

        let fields = [{label: 'FirstName', name: 'FirstName', value: firstName},
                     {label: 'LastName', name: 'LastName', value: lastName},
                     {label: 'Subject', name: 'Subject', value: subject}];

        const selRecType = categoryList.find((ct) => { return ct.value === recordTypeId });
        const buttonId = selRecType.label === 'Technical Support' ? this.prodButtonId : amgButtonId;

        
        let event = new CustomEvent(
            "setCustomField",
            {
                detail: {
                    callback:() => {
                        console.log("Callback");   

                        if(this.validateFields(fields).valid) {
                            this.startChat(fields);
                        } else {
                            console.warn("Prechat fields did not pass validation!");
                        }
                    } ,//this.template.querySelector("prechatAPI").startChat.bind(this, fields),
                    case: {
                        CaseId: this.caseId,
                        AkamCaseId: akamcaseid,
                        AccountId: accountId,
                        ContactId: contactId,
                        Subject: subject,
                        Description: description,
                        RecordTypeId: recordTypeId,
                        CaseOrigin: 'AkaChat Community',
                        CasProduct: product && product.label,
                        CaseProductId: product && product.value
                    },
                    transcript: {
                        Case_Record_Type__c: this.selectedRt.value, //this.template.querySelector('[data-inpid="category"]').value,
                    },
                    chat: {
                        ButtonId: buttonId
                    }
                }
            }
        );
        // Dispatch the event.
        document.dispatchEvent(event);
    }
    goToCreateCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { 
                url: '/customers/s/support?mode=newcase' 
            }
        });
    }

    connectedCallback() {            
        loadStyle(this, jarvischatcss).then(() => {
            console.log('style loaded');
        });
    }
}