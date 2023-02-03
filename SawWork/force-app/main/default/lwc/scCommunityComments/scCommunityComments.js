/** @Date		:	March 20 2021
* @Author		: 	Sumukh SS / Vishnu
* @Description	:	Community Comments
*/
import { LightningElement, api, wire } from 'lwc';
import getCommentData from '@salesforce/apex/SC_CommunityCommentController.getCommentDetails';
import insertnewCaseComment from '@salesforce/apex/SC_CommunityCommentController.insertnewComment';
import insertFileComment from '@salesforce/apex/SC_CommunityCommentController.insertnewFileComment';

import getViewDetails from '@salesforce/apex/SC_CommunityCommentController.onLoadDetails';

import cssStyleSheet from "@salesforce/resourceUrl/SC_CommunityComments_Stylesheet";
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getLabels} from './i18n';

export default class ScCommunityComments extends NavigationMixin(LightningElement) {

    
    @api recordId;
    @api HeaderName;
    @api ApplicationName;
    @api isFileUpload = false;
    @api ParentObject;
    @api visibility = 'Public';
    @api hideHeader;
    @api settings;
    @api enablePolling;
    _pollingInterval;
    @api get pollingInterval() {
        return this._pollingInterval? parseInt(this._pollingInterval): 60000;
    }
    set pollingInterval(val) {
        this._pollingInterval = val;
    }

    labels = {};
    chatlist = [];
    emailId;
    emailBody = '';
    emailSubject = '';
    email = {};

    showImageCommentInModal = false;
    showEmailInModal = false;
    showCommentTextBox = false;
    showsmallCommentTextBox = true;
    showCaseClosedMessage = false;

    showFileUploadModal = false;
    showNoCommentWarning=false;
    commentBody;
    isCommunityRender;
    choosenView='';
    loadSpinner = false;

    sortFactor = -1;
    filter = 'all';

    get isJarvis() {
        return this.ApplicationName ==='JARVIS';
    }

    get isChime() {
        return this.ApplicationName ==='CHIME';
    }

    get inputFormats() {
        if(this.isJarvis) {
            return 'bold, italic, underline, list, clean, background, header, image';
        }
        else{
            return 'bold, italic, underline, list, clean, background, header';
        }
    }


    hideComponent;
    hideComponentMessage;
    connectedCallback() 
    {
        if(this.isChime) {
            this.showCommentTextBox = true;
        }
        this.labels = getLabels(this.ApplicationName);
        loadStyle(this, cssStyleSheet);
    
        if(this.isJarvis) {
            this.choosenView='lastestComments';
            getViewDetails({
                caseid: this.recordId
            }).then(result => {
                this.showCommentTextBox= result.userHasWriteAccess && !result.isCaseClosed ? true : false;
                this.showCaseClosedMessage= result.isCaseClosed;
                this.isCommunityRender=result.isCommunityLoad;
                // this.isCustomerCase = result.isCustomerCase;
                // this.isInScope = result.isInScope;
                //ESESP-6553 - removing jarvis logic variable from condition
                //if(!result.isCustomerCase || !result.isInScope) {
                if(!result.isCustomerCase) {
                    this.hideComponent = true;
                    /*this.hideComponentMessage = !result.isCustomerCase
                                    ? this.labels.NOT_AVAILABLE
                                    : this.labels.OUT_OF_SCOPE;*/
                    this.hideComponentMessage = this.labels.NOT_AVAILABLE;
                }
            }).catch(error => {
                console.log(JSON.stringify(error));
            });
        }
        this.getComments();      
    }
    
    result;
    getComments() {
        
        this.loadSpinner = true;

        getCommentData({
            parentid: this.recordId,
            application: this.ApplicationName,
            parentobject: this.ParentObject,
            //choosenView : this.choosenView,
            visibility : this.visibility
        }).then(result => {
            this.result = result;
            this.chatlist = this.getSortedAndFilteredList(result);
            this.loadSpinner = false;
        }).catch(error => {
            console.log(JSON.stringify(error));
            this.loadSpinner = false;
        });
    }

    getSortedAndFilteredList(chatList) {
        const updatedChatlist = chatList.filter(el => {
            return this.filter === 'all' 
                || (this.filter === 'onlyAkamai' && el.commentedBy === 'Internal User') 
                || (this.filter === 'onlyCustomer' && el.commentedBy === 'Customer');
        });
        updatedChatlist.sort((el1, el2) => (Date.parse(el1.createdDate) - Date.parse(el2.createdDate))*this.sortFactor);
        return updatedChatlist;
    }

    get actionOptions() {
        const actOptions = [
            { sortOrder: '-1', filter: 'all', label: this.labels.LATEST_COMMENTS_FIRST, type:'sort'},
            { sortOrder: '1', filter: 'all', label: this.labels.OLDEST_COMMENTS_FIRST, type:'sort'},
            { sortOrder: '1', filter: 'onlyAkamai', label: this.labels.ONLY_AKAMAI_COMMENTS, type:'filter'}
        ];
        if(!this.isCommunityRender) {
            actOptions.push({ sortOrder: '1', filter: 'onlyCustomer', label: this.labels.ONLY_CUSTOMER_COMMENTS, type:'filter'});
        }
        return actOptions;
    }

    openImage(e) {
        var commentid = e.currentTarget.dataset.value;
        const wrapRec = this.chatlist.find(el => (commentid) === el.commentId);
        this.showImageCommentInModal = true;
        this.commentBody = wrapRec.commentBody;
    }
    openEmail(e) {
        this.emailId = e.currentTarget.dataset.emailid;
        this.emailSubject = e.currentTarget.dataset.emailsubject;
        this.showEmailInModal = true;
        if(this.emailId !== this.email.Id) {
            this.email = {};
        }
    }

    get acceptedFormats() {
        return ['.3g2','.3gp','.7z','.acc','.ai','.aif','.asf','.asp',
        '.aspx','.asx','.avi','.bmp','.c','.cer','.cfm','.class','.cpp',
        '.crt','.cs','.csr','.css','.csv','.dat','.der','.doc','.docx','.eml',
        '.eps','.fla','.flac','.flv','.gif','.gz','.h','.har','.htm','.html',
        '.iff','.java','.jpeg','.jpg','.js','.json','.jsp','.key','.keychain',
        '.log','.m4a','.m4v','.mid','.midi','.mov','.mp3','.mp4','.mpeg','.mpg',
        '.msg','.mxl','.odt','.p12','.p7b','.p7c','.p7s','.pages','.pcap','.pdf',
        '.pem','.pfx','.php','.pkcs12','.pl','.png','.ppt','.pptx','.ps','.psd',
        '.py','.ra','.rar','.rm','.rpm','.rss','.rtf','.saz','.sh','.sitx','.svg',
        '.swf','.tar','.tar.gz','.tga','.thm','.tif','.tiff','.txt','.vcf','.vob',
        '.wav','.wma','.wmv','.wpd','.wps','.xhtml','.xls','.xlsx','.xml','.zip',
        '.zipx'];
    }

    handleCommentMenuSelect(ev) {
        this.sortFactor = parseInt(ev.currentTarget.dataset.orderby);
        this.filter = ev.currentTarget.dataset.filter;
        this.chatlist = this.getSortedAndFilteredList(this.result);
    }

    closeModal() {
        this.showImageCommentInModal = false;
        this.showFileUploadModal = false;
        this.showEmailInModal = false;
        //this.emailBody =  '';
    }

    inpErrorMessage;
    isInpValid = true;
    maxInpLength = 130000;
    handleSaveButtonClick() {

        const inputRichText = this.template.querySelector('lightning-input-rich-text');
        let commentStr = inputRichText.value;
        if(commentStr.length > this.maxInpLength) {
            this.inpErrorMessage = `${this.labels.ERR_MAX_LENGTH} - ${this.maxInpLength} . ${this.labels.ERR_CURR_LENGTH} ${commentStr.length} `;
            this.isInpValid = false;
            console.log('inpErrorMessage' + this.inpErrorMessage);
            return;
        }
        this.inpErrorMessage = '';
        this.isInpValid = true;

        if (!commentStr)  {
            return;
        }
        this.loadSpinner = true;
        insertnewCaseComment({
            parentid: this.recordId,
            application: this.ApplicationName,
            parentobject: this.ParentObject,
            comment: commentStr,
            visibility : this.visibility// 'Public'
        }).then(result => {
            this.getComments();
            this.refreshParentRecordPage();
            const inputRichText = this.template.querySelector('lightning-input-rich-text');
            inputRichText.value = '';
        }).catch(error => {
            console.log(JSON.stringify(error));
            this.loadSpinner = false;
            let errorMessage;

            if(error.body && error.body.pageErrors && error.body.pageErrors[0]) {
                errorMessage = error.body.pageErrors[0].message
            } else if(error.body.fieldErrors){
                Object.keys(error.body.fieldErrors).forEach(el => {
                    errorMessage = error.body.fieldErrors[el][0].message;
                });
            }
            this.dispatchEvent(new ShowToastEvent({
                title: this.labels.ERR_SAVE_COMMENT,
                message: errorMessage
                        ? errorMessage:
                        this.labels.ERR_SAVE_COMMENT,
                variant: 'error'
            }));
        });
    }

    handleUploadButtonClick() {
        this.showFileUploadModal = true;
    }
    refreshParentRecordPage() {
        getRecordNotifyChange([{recordId: this.recordId}]);
    }

    get showShareTooltip() {
        return this.isCommunityRender && this.isJarvis;
    }

    get showShareGuidanceText() {
        return !this.isCommunityRender && this.isJarvis;
    }

    showFileDetails(e) {
        var fileId = e.currentTarget.dataset.value;

        if (this.isCommunityRender === false) {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: fileId
                }
            })
        }
        else 
        {
            //ESESP-7094: changed record redirect to download
            let base_url = this.getBaseUrl();
            let complete_url = base_url + '/customers/sfc/servlet.shepherd/document/download/'+fileId;
            console.log(complete_url);
            window.open(complete_url, '_self');
        }
    }
    changeFocusToRichtext = false;
    //For JARVIS
    handleTexboxFocus() {
        this.showsmallCommentTextBox=false;
        this.changeFocusToRichtext = true;
    }

    getBaseUrl(){
        let baseUrl = 'https://'+window.location.host+'/';
        return baseUrl;
    }

    // Changes by Vishnu for JARVIS
    @wire(CurrentPageReference)
    pageRef;

    // POST UI render logic
    // If user is redirected from Comment Detail page, scroll to the relevant comment
    // If chat post/share box is expaned, Move focus to it

    renderedCallback() {

        // Scroll to the relevant comment
        const commId = this.pageRef && this.pageRef.state.c__communityCommentsId;
        const commentThreadRef = commId && this.template.querySelector(`c-sc-community-comments-item[data-commid='${commId}']`);
        if (commentThreadRef) {
            commentThreadRef.highlight = true;
            commentThreadRef.scrollIntoViewIfNeeded();
        }

        //  focus rich text box
        if(this.changeFocusToRichtext && this.isJarvis) {
            const largeTextBox = this.template.querySelector('lightning-input-rich-text.fullCommentInputJarvis');
            if(largeTextBox) {
                largeTextBox.focus();
            }
            this.changeFocusToRichtext = false;
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.showFileUploadModal = false;
        let message;
        if (uploadedFiles.length < 2) {
            message = '<u class="slds-text-title_caps" style="color: black;">Uploaded 1 file</u><br/><br/>';
        }
        else {
            message = '<u class="slds-text-title_caps" style="color: black;">Uploaded ' + uploadedFiles.length + ' files</u><br/><br/>';
        }
        let i = 0;
        for (i = 0; i < uploadedFiles.length; i++) {
            message += (i + 1) + '. ' + uploadedFiles[i].name + '<br/>';
        }

        insertFileComment({
            parentid: this.recordId,
            application: this.ApplicationName,
            parentobject: this.ParentObject,
            comment: message
        }).then(result => {
            console.log(JSON.stringify(result));
            this.getComments();
            this.showFileUploadModal = false;
            this.refreshParentRecordPage();

        }).catch(error => {
            console.log(JSON.stringify(error));
        });

    }
    handleFileUploadChange(ev) {
        console.log('handleFileUploadChange ', ev);
    }
}