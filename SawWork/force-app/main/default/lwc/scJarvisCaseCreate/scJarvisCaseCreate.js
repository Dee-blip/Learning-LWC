import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track } from 'lwc';

//import the static resource
import { loadStyle } from 'lightning/platformResourceLoader';
import {LABELS} from './i18n';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";


import getAccount from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getAccount';
import getCategories from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getCategories';
import getProducts from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getProducts';
import getProblem from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getProblem';
import getQuestions from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getQuestionRecords';
import getPDs from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getPolicyDomains';
import createCase from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.createCase';
import getCaseRecord from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getCaseRecord';
import getKnowledgeDiscussion from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getKnowledgeDiscussion';
import getArticleData from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getArticleData';
import saveVote from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.saveVote';
import cloneSetup from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.cloneSetup';
import alsoNotifyCheck from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.alsoNotifyCheck';
import getParentAccount from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getParentAccount';

export default class ScJarvisCaseCreate extends NavigationMixin(LightningElement) {
        
    //Load the spinner
    loadSpinner = false;

    selectedAccount;
    accounts= [];
    selectedParentAccount;
    parentAccounts = [];
    selectedParentAccountName;
    
    selectedCategory;
    categories = [];
    
    selectedPolicyDomain;
    pds= [];
    
    selectedCaseProduct;
    caseProducts= [];
    
    selectedProblem;
    problems= [];
    
    selectedSeverity;
    severities= [];

    severity;
    statusValue;
    createdByAccount;
    @api recordId;
    contactInfo = {};    

    kbArticles=[];
    communityDiscussions=[];
    articleClass='suggestedSectionHalfHeight';
    discussionClass='suggestedSectionHalfHeight';

    timeoutId;
    clickedArticle;
    showArticleModal = false;
    likeState = false;
    dislikeState = false;
    voteChange = false;
    
    productCategory;
    modalContentClass = 'slds-modal__content slds-p-bottom_small';
    //activeSections = ['Product Section', 'Information Section','Contact Information','Alternate Contact Information','File Upload'];
    activeSections = [LABELS.SECTION_ACCOUNT];
    articleSections = [LABELS.SECTION_ARTICLES,LABELS.SECTION_DISCUSSIONS];

    loggedInContact='';

    validEmailMessage = '';
    alternateEmail = '';
    questions=[];

    //currentPageReference = null; 
    @api cloneid;

    labels = LABELS;

    uploadedFiles = [];
    @track uploadedFilesPills = [];


    showSuggestionSection = true;

    showWarningModal=false;
    warningMessage='';
    uploadedFilesLabel = '';
    caseRecordToCreate;
    isReseller=false;
    get showValidation()
    {
        return this.validEmailMessage ? true: false;
    }
    get showAlternateValidation()
    {
        return this.alternateEmail ? true: false;
    }

    get displayParentAccount()
    {
        //return (this.parentAccounts !== null && this.parentAccounts !== undefined) && this.parentAccounts.length > 0 && !this.cloneid? true : false;
        return (this.parentAccounts !== null && this.parentAccounts !== undefined) && this.parentAccounts.length > 0 ? true : false;
    }

    get oneParentAccount()
    {
        //return (this.parentAccounts !== null && this.parentAccounts !== undefined) && this.parentAccounts.length === 1 && !this.cloneid? true : false;
        return (this.parentAccounts !== null && this.parentAccounts !== undefined) && this.parentAccounts.length === 1 ? true : false;
    }

    get displayParentAccountfield()
    {
        return this.selectedParentAccountName ? true : false;
    }

    get soccCase()
    {
        return this.selectedCategory === 'SOCC'? true: false;
    }

    get psCase()
    {
        return this.selectedCategory === 'PS'? true: false;
    }

    get areaProductLabel()
    {
        return this.selectedCategory === 'SOCC' ||  this.selectedCategory === 'Technical'? LABELS.CASE_PRODUCT : 
        this.selectedCategory === 'PS'? LABELS.CASE_PS_PRODUCT :LABELS.CASE_AREA;
    }
    get areaProductHelp()
    {
        return this.selectedCategory === 'Billing' || this.selectedCategory === 'AMG'? "" : 
        LABELS.CASE_PRODUCTHELP;
    }
    get serviceProblemHelp()
    {
        return this.selectedCategory === 'SOCC' || this.selectedCategory === 'Technical'? LABELS.CASE_PROBLEMHELP : 
        "";

    }
    get serviceProblemLabel()
    {
        return this.selectedCategory === 'Billing' || this.selectedCategory === 'AMG'? LABELS.CASE_SERVICE : 
        this.selectedCategory === 'PS' ? LABELS.CASE_PS_SERVICE: LABELS.CASE_PROBLEM;
    }

    get articlesExist()
    {
        return this.kbArticles !== undefined && this.kbArticles.length > 0? true : false;
    }
    
    get discussionExist()
    {
        return this.communityDiscussions !== undefined && this.communityDiscussions.length > 0? true : false;
    }

    
    get articlesDiscussionsExist()
    {
        return (this.kbArticles !== undefined && this.kbArticles.length > 0) || (this.communityDiscussions !== undefined && this.communityDiscussions.length > 0)?  true : false;
    }

    get scrollNeeded()
    {
        let articleLength = this.kbArticles !== undefined ? this.kbArticles.length : 0;
        let communityDiscussionsLength = this.communityDiscussions !== undefined ? this.communityDiscussions.length : 0;
        return (articleLength + communityDiscussionsLength) > 22 ? "suggestedSectionHeight overflowClass":"suggestedSectionHeight";
    }
    get articleSize()
    {
        return this.showSuggestionSection? 8 : 12;
    }
    get noProblem()
    {
        return this.problems !== undefined && this.problems.length > 1 && !this.cloneid? false : true;
    }

    get noProduct()
    {
        return this.caseProducts !== undefined && this.caseProducts.length > 1 && !this.cloneid? false : true;
    }

    get noCategory()
    {
        return this.categories !== undefined && this.categories.length > 1 && !this.cloneid? false : true;
    }

    get noAccount()
    {
        return this.accounts !== undefined && this.accounts.length > 1 && !this.cloneid? false : true;
    }

    get noSeverity()
    {
        return this.severities !== undefined && this.severities.length > 0 && 
        (this.selectedCategory === 'PS' || this.selectedCategory === "Technical")? false : true;
    }

    get noPolicyDomain()
    {
        return this.pds !== undefined && this.pds.length > 1 && !this.cloneid? false : true;
    }

    get emergingProduct()
    {
        return this.productCategory === 'Emerging'? true : false;
    }

    get carrierProduct()
    {
        return this.productCategory === 'Carrier'? true : false;
    }

    get showDescription()
    {
        return this.clickedArticle !== undefined && (this.clickedArticle.Article_Record_Type__c === "Community Blog" || this.clickedArticle.Article_Record_Type__c === "How To") ? true : false; 
    }
    get howToArticle()
    {
        return this.clickedArticle !== undefined && this.clickedArticle.Article_Record_Type__c === "How To" ? true : false; 
    }
    get procedureArticle()
    {
        return this.clickedArticle !== undefined && this.clickedArticle.Article_Record_Type__c === "Problem & Solution" ? true : false; 
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

    get showUploadedFilesPills(){
        return this.uploadedFilesPills.length > 0;
    }

    handleUploadFinished(event) {
        this.toggleSpinner(true);
        event.detail.files.forEach((file) => {
            console.log(file);
            this.uploadedFiles.push(file.documentId);
            this.uploadedFilesPills.push({
                type: 'icon',
                label: file.name,
                name: file.documentId,
                iconName: 'utility:file',
                style: 'margin-right:10px;',
                alternativeText: file.name,
            });
        });
        this.toggleSpinner(false);
        this.uploadedFilesLabel = this.labels.CASE_UPLOADED_FILES;
    }

    handleFilePillRemove(event) {
        this.uploadedFiles.splice(event.detail.index, 1);
        this.uploadedFilesPills.splice(event.detail.index, 1);
    }

    toggleSpinner(toggleVal)
    {
        this.loadSpinner = toggleVal;        
    }

    setModalClass()
    {   
        this.modalClass= this.articlesDiscussionsExist?
                        'slds-modal slds-fade-in-open slds-modal_large' : 
                        'slds-modal slds-fade-in-open slds-modal_medium';
        this.articleClass = this.articlesExist && this.discussionExist? 
                        'suggestedSectionHalfHeight':
                        this.articlesExist? 'suggestedSectionHeight' :
                        '';
        this.discussionClass = this.articlesExist && this.discussionExist? 
                        'suggestedSectionHalfHeight':
                        this.discussionExist? 'suggestedSectionHeight' :
                        '';
        this.articleSections = this.articlesExist && this.discussionExist? 
                        [LABELS.SECTION_ARTICLES,LABELS.SECTION_DISCUSSIONS]:
                        this.articlesExist? [LABELS.SECTION_ARTICLES]:
                        [LABELS.SECTION_DISCUSSIONS]
    }

    caseOwner;
    hasEditAccess;
    caseCreatedDate;
    connectedCallback() 
    {        
        //console.log('labels: ',LABELS);
        loadStyle(this, staticStyleSheet);        
        this.toggleSpinner(true);        
        //console.log('cloneId: ' +  this.cloneid);
        if(this.cloneid)
        {    
            this.toggleSpinner(true);        
            cloneSetup({'caseRecordId' : this.cloneid})
            .then(result => {
                //console.log('HERE2!!' + JSON.stringify(result));    
                this.selectedAccount = result.accounts[0].Id;
                this.accounts= result.accounts;
                this.parentAccounts = result.parentAccounts;
                if( result.parentAccounts !== null && result.parentAccounts !== undefined && result.parentAccounts.length === 1)
                {
                    this.selectedParentAccount = result.parentAccounts[0].Id;
                    this.selectedParentAccountName = result.parentAccounts[0].Name;
                }
                this.filteredAccountList = result.accounts;


                this.selectedCategory = result.categories.defaultValue;
                this.categories = result.categories.options;``
                
                if(result.policyDomains && result.policyDomains.defaultValue !== null)
                {
                    this.selectedPolicyDomain = result.policyDomains.defaultValue;
                    this.pds= result.policyDomains.options;
    
                }
                
                this.loggedInContact = result.loggedInContact;

                this.selectedCaseProduct = result.products.defaultValue;
                this.caseProducts= result.products.options;
                
                this.selectedProblem = result.problems.defaultValue;
                this.problems= result.problems.options;
                
                this.selectedSeverity = result.severity.defaultValue;
                this.severities= result.severity.options;
            
                this.questions = result.questions;

                this.kbArticles=result.searchResults.articles;
                this.communityDiscussions=result.searchResults.questions;
                
                this.setModalClass();

            })
            .then(result => {
                //this.activeSections = ['Account Section','Information Section','Product Section','Contact Information','Alternate Contact Information','Additional Email Address','Case Questionnaire'];                               
                console.log(result);
                this.activeSections =[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT,LABELS.SECTION_QUESTIONS];
                this.toggleSpinner(false);        

            })
            .catch(error => {
                this.toggleSpinner(false);
                this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                console.log('The error: ' + error +  JSON.stringify(error)) ;
            });        

        }
        else if(this.recordId)        
        {
            //Case Detail Page
            //console.log('This recordId: ' + this.recordId);
            //this.toggleSpinner(true);        
            this.detailSections = [LABELS.SECTION_CASE_INFORMATION,LABELS.ARTICLE_DESCRIPTION,LABELS.SECTION_CONTACT];
            getCaseRecord({'caseRecordId' : this.recordId})
            .then(result => {
                //console.log('HERE2!!' + JSON.stringify(result));    
                let caseRec = result.caseRecord;
                this.hasEditAccess = result.hasEditAccess;
                this.severity = result.severity;
                this.statusValue = result.statusValue;                
                if(caseRec.Contact)
                {
                    this.contactInfo.Name = caseRec.Contact.Name;
                    this.contactInfo.Email = caseRec.Contact.Email;
                    this.contactInfo.Phone = caseRec.Contact.Phone;
                    this.contactInfo.Company = caseRec.Contact.Company__c;    
                }
                this.selectedParentAccountName = caseRec.Parent_Account__r ? caseRec.Parent_Account__r.Name : undefined;
                this.caseOwner = caseRec.Owner && caseRec.OwnerId.startsWith('005') ? caseRec.Owner.Name : 'In Queue';
                this.caseCreatedDate = result.createdDate;
                this.isReseller = result.isReseller;
                this.createdByAccount = caseRec.AccountId !== caseRec.Created_By_Account__c? caseRec.Created_By_Account__r.Name : undefined;
                switch(result.recordType)
                {
                    case "AMG":
                        this.selectedCategoryLabel = 'Client Services Manager/ Business Support Issue';
                        this.selectedCaseProduct = caseRec.Service__c;
                        this.selectedProblem = caseRec.Request_Type__c;
                        this.selectedCategory = "AMG";
                    break;
                    case "Billing" :
                        this.selectedCategoryLabel = 'Billing Support Issue';
                        this.selectedCaseProduct = caseRec.Service__c;
                        this.selectedProblem = caseRec.Request_Type__c;
                        this.selectedCategory = "Billing";
                    break;
                    case "Emerging Products Engineering":
                    case "Technical":
                        this.selectedCaseProduct = caseRec.Case_Product__r ? caseRec.Case_Product__r.Name : '';
                        this.selectedProblem = caseRec.Customer_Problem__c;
                        this.selectedCategoryLabel = 'Technical Support Issue';
                        this.selectedCategory = "Technical";
                        this.productCategory =  result.recordType === "Technical" && result.subType === "Carrier" ? "Carrier" :
                        result.recordType === "Emerging Products Engineering" ? "Emerging": null;
                    break;
                    case "Managed Security":
                        this.selectedCategoryLabel = 'Managed Security Support';
                        this.selectedCaseProduct = caseRec.Case_Product__r ? caseRec.Case_Product__r.Name : '';
                        this.selectedProblem = caseRec.Problem__c;
                        this.selectedPolicyDomain = caseRec.Policy_Domain__r? caseRec.Policy_Domain__r.Name :'';
                        this.selectedCategory = "SOCC";
                    break;
                    case "Professional Services":
                        this.selectedCaseProduct = caseRec.Case_Product__r ? caseRec.Case_Product__r.Name : '';
                        this.selectedCategoryLabel = 'Professional Services Request (billable)';
                        this.selectedProblem = caseRec.Service__c;
                        this.selectedCategory = "PS";
                    break;
                    default:
                        console.log('Default case');
                }
                this.toggleSpinner(false);
                
            })
            .catch(error => {
                this.toggleSpinner(false);
                console.log('The error: ' + error +  JSON.stringify(error)) ;
                //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                //console.log('The error: ' + error +  JSON.stringify(error)) ;
            });        
    
        }
        else
        {
            //console.log('This recordId: ' + this.recordId);
            this.getAccountValues();
        }

    }
    onAccountChange(event)
    {
        this.onFieldChange(event);

        this.selectedAccount = event.detail.Id;
        console.log('this.selectedAccount:' + this.selectedAccount);
        this.resetVariables('account');
        
        if(this.selectedAccount)
        {
            this.toggleSpinner(true);
            this.getCategoryValues();    
        }
    }

    onParentAccountChange(event)
    {
        this.onFieldChange(event);
        this.selectedParentAccount = event.detail.Id;
        this.selectedParentAccountName = event.detail.Name;
        console.log('selectedParentAccount---'+this.selectedParentAccount);

    }

    callProductMethod(paramMap)
    {
        this.toggleSpinner(true);
        getProducts({'paramMap' : JSON.stringify(paramMap)})
        .then(result => {
            //console.log('HERE2!!' + JSON.stringify(result));    
            if(result.products.options.length === 1){
                if(this.selectedCategory !== "PS"){
                    this.selectedCaseProduct = result.products.options[0].value;
                    let problemParamMap = {};
                    problemParamMap.accountId = this.selectedAccount;
                    problemParamMap.category = this.selectedCategory;
                    problemParamMap.product = this.selectedCaseProduct;
                    problemParamMap.subject = this.subjectString;
                    this.getProblemValues(problemParamMap);
                }
            }
            this.caseProducts = result.products.options;
            if(this.selectedCategory === "PS")
            {
                if(result.policyDomains){
                    this.problems = result.policyDomains.options;
                    if(result.policyDomains.options.length === 1){
                        this.selectedProblem = result.policyDomains.options[0].value;
                    }
                }
                else{
                    this.problems = [];
                }
                //this.problems = result.policyDomains?result.policyDomains.options : [];
                this.severities = result.severity.options;
                this.selectedSeverity = result.severity.defaultValue;
                this.searchArticles();
            }
            this.toggleSpinner(false);
            
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        

    }
    
    onCategoryChange(event)
    {
        this.onFieldChange(event);

        this.selectedCategory = event.detail.value;
        
        this.resetVariables('category');
        if(this.selectedCategory === "SOCC")
        {        
            this.getPdValues();
        }
        else
        {
            if(this.selectedCategory === "AMG" || this.selectedCategory === "Billing"){
                this.getParentAccountValues();
            }
            let paramMap = {};
            paramMap.accountId = this.selectedAccount;
            paramMap.category = this.selectedCategory;
    
            //console.log('this.selectedCategory:' + this.selectedCategory);
            this.callProductMethod(paramMap);
        }

    }

    getPdValues(){
        getPDs({"accountId" : this.selectedAccount})
        .then(result => {
            //console.log('HERE2!!' + result);    
            this.pds = result.policyDomains.options;
            if(result.policyDomains.options.length === 1){
                this.selectedPolicyDomain = result.policyDomains.options[0].value;
                let paramMap = {};
                paramMap.policyDomainId = this.selectedPolicyDomain;
                paramMap.accountId = this.selectedAccount;
                this.callProductMethod(paramMap);
                this.activeSections =[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT];
            }
            this.toggleSpinner(false);
            
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });
    }

    onPdChange(event)
    {
        this.onFieldChange(event);

        this.selectedPolicyDomain = event.detail.value;
        this.resetVariables('policyDomain');

        let paramMap = {};
        paramMap.policyDomainId = this.selectedPolicyDomain;
        paramMap.accountId = this.selectedAccount;

        //console.log('this.policyDomainId:' + this.selectedPolicyDomain);

        this.callProductMethod(paramMap);
    }
    onCaseProductChange(event)
    {
        this.onFieldChange(event);
            
        this.selectedCaseProduct = event.detail.value;
        if(this.selectedCategory === "PS")
        {
            if(this.selectedCaseProduct)
            {
                this.searchArticles();
            }            
            //console.log('INSIDE PS CHANGE');
            return;
        }
        //console.log('outside PS CHANGE: ' + this.selectedCategory);
        this.resetVariables('product');
        let paramMap = {};
        
        paramMap.accountId = this.selectedAccount;
        paramMap.category = this.selectedCategory;
        paramMap.product = this.selectedCaseProduct;
        paramMap.subject = this.subjectString;

        //console.log('this.selectedCaseProduct:' + this.selectedCaseProduct);
        this.getProblemValues(paramMap);
        this.searchArticles();
    }

    getProblemValues(paramMap){
        this.toggleSpinner(true);
        getProblem({'paramMap' : JSON.stringify(paramMap)})
        .then(result => {
            //console.log('HERE2!!' + JSON.stringify(result));            
            this.problems = result.products.options;
            this.severities = result.severity.options;
            this.selectedSeverity = result.severity.defaultValue;
            this.productCategory = result.products.defaultValue;    
            // this.kbArticles=result.searchResults.articles;
            // this.communityDiscussions=result.searchResults.questions;
            if(result.products.options.length === 1){
                this.selectedProblem = result.products.options[0].value;
                if(this.selectedProblem && this.selectedCaseProduct && this.selectedCategory === "Technical")
                {
                    this.getQuestionsRecs();      
                }
            }
            //this.severities = result.
            this.toggleSpinner(false);
            
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });          
    }

    onProblemChange(event)
    {
        this.onFieldChange(event);

        this.selectedProblem = event.detail.value;
        // if(this.selectedCategory === 'PS')
        // {
        //     this.kbArticles = this.articles;
        //     this.setModalClass();
        //     return;
        // }
        // this.kbArticles = [];
        // this.setModalClass();
        //console.log('Fetch Questions');
        this.resetVariables('problem');   
        //if((this.selectedCategory === 'Technical' || this.selectedCategory === 'PS')
        if(this.selectedProblem && this.selectedCaseProduct && this.selectedCategory === "Technical")
        {
            this.getQuestionsRecs();      
        }
    }

    getQuestionsRecs(){
        getQuestions({'product' : this.selectedCaseProduct,
        'problem' : this.selectedProblem})
        .then(result => {
            //console.log('HERE2!!' + JSON.stringify(result));            
            this.questions = result.questions;
            console.log('questions' + result.questions);
            
            //this.severities = result.
            
            return true;
        })
        .then(result => {
            if(result)
            {
                //this.activeSections = ['Account Section','Product Section', 'Information Section','Case Questionnaire','Contact Information','Alternate Contact Information','Additional Email Address'];                
                this.activeSections =[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT,LABELS.SECTION_QUESTIONS];
            }                
            this.toggleSpinner(false);
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });
    }



    getAccountValues()
    {
        //console.log('HERE!!');
        getAccount({'returnSet' : false})
        .then(result => {
            //console.log('HERE2!!' + result);
            result = JSON.parse(result);
            this.accounts = result.accounts;
            this.filteredAccountList = result.accounts;
            this.loggedInContact = result.loggedInContact;

            if( result.accounts.length === 1){
                this.selectedAccount = result.accounts[0].Id;
                //this.categories = result.categories.options;
                this.getCategoryValues();
            }
            if(result.accounts.defaultValue !== undefined && result.accounts.defaultValue !== null)
            {
                this.selectedAccount = result.accounts.defaultValue;
                this.categories = result.categories.options;
            }
            //this.accounts = result;
            //console.log('this.accounts: ' + this.accounts);
            this.toggleSpinner(false);
            
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        
    }

    getParentAccountValues()
    {
        this.toggleSpinner(true);
        getParentAccount({'accountId' : this.selectedAccount})
        .then(result => {
            result = JSON.parse(result);
            this.parentAccounts = result.parentAccounts;
            console.log('--parentAccounts--'+this.parentAccounts);
            this.loggedInContact = result.loggedInContact;
            this.toggleSpinner(false);
            if( result.parentAccounts !== null && result.parentAccounts !== undefined && result.parentAccounts.length === 1){
                this.selectedParentAccount = result.parentAccounts[0].Id;
                this.selectedParentAccountName = result.parentAccounts[0].Name;
            }
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });  

    }


    getCategoryValues()
    {
        this.toggleSpinner(true);
        getCategories({'accountId' : this.selectedAccount})
        .then(result => {
            this.toggleSpinner(false);
            this.isReseller = result.isReseller;
            if(result.categories.options)
            {
                this.categories = [...result.categories.options].sort((a, b) => a.label - b.label);
            }
            if(result.categories.options.length === 1){
                this.selectedCategory = result.categories.options[0].value;
                if(this.selectedCategory === "SOCC"){
                    this.getPdValues();
                }
                else{
                    let paramMap = {};
                    paramMap.accountId = this.selectedAccount;
                    paramMap.category = this.selectedCategory;
                    this.callProductMethod(paramMap);
                }
            }
            else{
                this.selectedCategory = null;
            }
            // console.log('this.categories!!' + JSON.stringify(this.categories));    
        })
        .catch(error => {
            this.toggleSpinner(false);
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        
    }



    get questionsExist()
    {
        return this.questions !== undefined && this.questions.length > 0? true : false;
    }

    resetVariables(onChangeField)
    {
        switch(onChangeField) 
        {
            case "account" :
                this.selectedCategory = '';
                this.categories = [];

                this.selectedParentAccount = '';
                this.parentAccounts = [];
                
                this.selectedPolicyDomain = '';
                this.pds= [];
                
                this.selectedCaseProduct = '';
                this.caseProducts= [];
                
                this.selectedProblem = '';
                this.problems= [];
                
                this.selectedSeverity = '';
                this.severities= [];
            
                this.questions = [];
      
                //this.activeSections = ['Account Section'];
                this.activeSections =[LABELS.SECTION_ACCOUNT];
            break;
            case "category":
                this.selectedPolicyDomain = '';
                this.pds= [];

                this.selectedParentAccount = '';
                this.parentAccounts = [];
                
                this.selectedCaseProduct = '';
                this.caseProducts= [];
                
                this.selectedProblem = '';
                this.problems= [];
                
                this.selectedSeverity = '';
                this.severities= [];
            
                this.questions = [];
                if(this.selectedCategory !== 'SOCC')
                {                    
                    //this.activeSections = ['Account Section','Information Section','Product Section','Contact Information','Alternate Contact Information','Additional Email Address'];
                    this.activeSections =[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT];
                    //console.log('HERE!!' + this.activeSections);
                }
                break;
            case "policyDomain":
                this.selectedCaseProduct = '';
                this.caseProducts= [];
                
                this.selectedProblem = '';
                this.problems= [];
                
                this.selectedSeverity = '';
                this.severities= [];
            
                this.questions = [];

                //this.activeSections = ['Account Section','Product Section', 'Information Section','Contact Information','Alternate Contact Information','Additional Email Address'];
                this.activeSections =[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT];
                break;
            case "product":
                this.selectedProblem = '';
                this.problems= [];
                
                this.selectedSeverity = '';
                this.severities= [];
            
                this.questions = [];
                  break;
            case "problem":
                this.questions = [];
                  break;
             default:
                 console.log('Default Case'); 
          }
          this.kbArticles = [];
          this.setModalClass();
        //this.activeSections = ['Product Section', 'Information Section','Contact Information','Alternate Contact Information','File Upload'];
    }

    responseChange(event)
    {
        let target = this.template.querySelector(`[data-id="${event.target.dataset.id}"]`);
        target.classList.remove('slds-has-error');
        
        let index = event.target.dataset.index;

        let foundelement = this.questions[index];  
        let foundCopy = {... foundelement};  
        foundCopy.response = event.target.value;
        this.questions = [...this.questions];   
        this.questions[index] = foundCopy;

    }

    checkIfDuplicateExists(arrayToCheck){
        return new Set(arrayToCheck).size !== arrayToCheck.length;
    }
    
    disableSubmit = true;
    validateForm()
    {
        let validForm = true;
        let validEmail = true;
        let validUrl = true;
        this.validEmailMessage = '';
        this.alternateEmail = '';
        let toastheader='';
        const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        const urlRegex = /^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/;

        let classToCheck = ".requiredField";
        [...this.template.querySelectorAll(classToCheck)].forEach(inputCmp =>{
            if((inputCmp.label !== undefined || inputCmp.label !== null ) && inputCmp.label === "Parent Account")
            {
                if((JSON.stringify(inputCmp.value)).length < 7)
                {
                    inputCmp.classList.add('slds-has-error');
                    validForm = false;
                }
            }
            else if((inputCmp.value === undefined || inputCmp.value === null || inputCmp.value.trim().length === 0) && !(inputCmp.disabled))
            {
                inputCmp.classList.add('slds-has-error');
                validForm = false;
            }
        });
        
        let alternateContactEmail = this.template.querySelector(".Alternate_Contact_Email__c").value;
        let target;
        if(alternateContactEmail && !re.test(String(alternateContactEmail).toLowerCase()))
        {
            alternateContactEmail = "invalid";
            toastheader = this.labels.TOAST_INVALID;
            this.alternateEmail = this.labels.TOAST_INVALID_MESSAGE;
            target = this.template.querySelector(".Alternate_Contact_Email__c");
            target.classList.add('slds-has-error');

            this.showToast('error',this.alternateEmail,toastheader,'dismissible');
        }
        let alsoNotifyValues = this.template.querySelector(".Jarvis_Also_Notify__c").value;

        if(alsoNotifyValues)
        {
            
            let arrayToCheck = alsoNotifyValues.split(/[,;\s\n]+/);
            if(arrayToCheck.length > 10)
            {
                toastheader = this.labels.TOAST_LIMIT;
                this.validEmailMessage = this.labels.TOAST_LIMIT_MESSAGE;
                validEmail = false;
            }
            else if(this.checkIfDuplicateExists(arrayToCheck))
            {
                //validEmailMessage = 'Please remove duplicate values in Also Notify';
                toastheader = this.labels.TOAST_DUPLICATE;
                this.validEmailMessage = this.labels.TOAST_DUPLICATE_MESSAGE;
                validEmail = false;
            }
            else
            {
                //console.log('validEmail:' + validEmail);            
                validEmail = alsoNotifyValues.split(/[,;\s\n]+/).reduce(
                    function(valid,cur)
                    { 
                        return valid && re.test(String(cur).toLowerCase()); 
                    },
                    true
                ); 
                if(!validEmail)
                {
                    toastheader = this.labels.TOAST_INVALID;
                    this.validEmailMessage = this.labels.TOAST_INVALID_MESSAGE;    
                } 
            } 
            if(!validEmail)
            {
                target = this.template.querySelector(".Jarvis_Also_Notify__c");
                target.classList.add('slds-has-error');
                this.showToast('error',this.validEmailMessage,toastheader,'dismissible');
            }
                
        }
        

        if(classToCheck === ".requiredField" && this.questions)
        {
            this.questions.forEach(inputCmp => {
                //console.log('inputCmp.recordId: ' + inputCmp.recordId);
                
                if(inputCmp.questionType !== 'Checkbox' && inputCmp.required && (inputCmp.response === undefined || inputCmp.response === null || inputCmp.response.trim().length === 0))
                {
                    let target1 = this.template.querySelector(`[data-id="${inputCmp.recordId}"]`);
                    //console.log('target: ' + target);
                    target1.classList.add('slds-has-error');
                    validForm = false;
                }
                
                if(inputCmp.questionType === 'URL' && inputCmp.response && 
                !urlRegex.test(String(inputCmp.response).toLowerCase()))
                {
                    let target2 = this.template.querySelector(`[data-id="${inputCmp.recordId}"]`);
                    target2.classList.add('slds-has-error');
                    validUrl = false;
                }

                
            });
        }
        if(!validForm)
        {
            this.showToast('error',this.labels.TOAST_COMPLETE_MESSAGE,this.labels.TOAST_ERROR,'dismissible');
        }               
        if(!validUrl)
        {
            this.showToast('error',this.labels.TOAST_URL_MESSAGE,this.labels.TOAST_ERROR,'dismissible');
        }               
        if(validForm && validEmail && alternateContactEmail !== "invalid")
        {
            this.disableSubmit = false;
            if(!this.disableSubmit)
            {
                this.currentStep = 'complete';
                const buttonToClick = this.template.querySelector('.hidden');
                buttonToClick.click();
            } 
            this.disableSubmit = true;         
    
        }
        return validForm;
    }

    onFieldChange(event)
    {
        event.preventDefault();
        let target;
        let eventValue = event.detail.value;
        if(eventValue || event.target.dataset.field === "Alternate_Contact_Email__c" 
        || event.target.dataset.field === "Jarvis_Also_Notify__c")
        {
            target = this.template.querySelector(`[data-field="${event.target.dataset.field}"]`);
            target.classList.remove('slds-has-error');    
        }
        if(event.target.dataset.field === "Subject")
        {            
            this.subjectString = eventValue;
            clearTimeout(this.timeoutId); 
            this.timeoutId = setTimeout(this.searchArticles.bind(this), 500);     
        }      
        if(event.target.dataset.field === "Severity__c")
        {            
            this.selectedSeverity = eventValue;
        }   
        if(event.target.dataset.field === "Alternate_Contact_Email__c")
        {            
            this.alternateEmail = '';
        }   
        if(event.target.dataset.field === "Jarvis_Also_Notify__c")
        {            
            this.validEmailMessage = '';
        }   

    }

    searchArticles()
    {
        if((!this.subjectString || this.subjectString.length < 3) && (!this.selectedCaseProduct || this.selectedCaseProduct.length < 3))
        {
            this.kbArticles = [];
            this.communityDiscussions = [];
            this.setModalClass();
        }
        else
        {            
            getKnowledgeDiscussion(
                {
                    'subject' : this.subjectString,
                    'caseProduct' : this.selectedCaseProduct
                })
            .then(result => {
                //console.log('result: ' + JSON.stringify(result));
                //this.toggleSpinner(false);
                this.kbArticles = result.articles;
                this.communityDiscussions = result.questions;
                this.setModalClass();
            })
            .catch(error => {
                this.kbArticles = [];
                this.setModalClass();
                this.toggleSpinner(false);
                //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                console.log('The error: ' + error +  JSON.stringify(error)) ;
    
            });            
        }
    }
    
    onDiscussionClick(event)
    {
        let discussionId = event.target.dataset.id;
        //console.log('discussionId: ' + discussionId);
        let fullUrl = "/customers/s/question/" + discussionId;
        window.open(fullUrl,"_blank");

    }    
    onArticleClick(event)
    {
        let articleId = event.target.dataset.id;
        //console.log('articleId: ' + articleId);
        getArticleData({'articleId' : articleId})
        .then(result => {
            this.clickedArticle = result.articleRecord;
            this.likeState = result.vote === "Up" ? true : false;
            this.dislikeState = result.vote === "Down" ? true : false;
            this.showArticleModal=true;
        })
        .catch(error => {
            console.log('The error: ' + error +  JSON.stringify(error)) ;

        });            
    }

    handleLikeButtonClick() 
    {
        this.voteChange = true;
        this.likeState = !this.likeState;
        this.dislikeState = this.likeState? false : this.dislikeState;
    }

    handleDislikeButtonClick() 
    {
        this.voteChange = true;
        this.dislikeState = !this.dislikeState;
        this.likeState = this.dislikeState? false : this.likeState;
    }

    closeArticleModal()
    {
        if(this.voteChange)
        {
            let newVote = this.likeState ? 'Up' : (this.dislikeState ? 'Down' : 'None');
            saveVote({'articleId' : this.clickedArticle.Id,'vote' : newVote})
            .then(result => {
                console.log('Saved Vote: ' + result) ;
            })
            .catch(error => {
                console.log('The error: ' + error +  JSON.stringify(error)) ;
    
            });            
    
        }
        this.showArticleModal=false;
        this.clickedArticle = undefined;
        this.likeState = false;
        this.dislikeState = false;

    }
    navigateToRecord(recordToNavigate)
    {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordToNavigate,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });                
    }

    showToast(variant,message,title,mode)
    {
        const event = new ShowToastEvent({
            "title": title,
            "message": message,
            "mode" : mode,
            "variant" : variant,
            "duration": 5000
        });
        this.dispatchEvent(event);        
    }

    closeWarningModal()
    {
        this.caseRecordToCreate = null;
        this.showWarningModal = false;
    }
    submitHandler(event)
    {
        event.preventDefault();
        let caseRec ={};
        
        if(!this.disableSubmit)
        {
            let key;
            this.toggleSpinner(true);
            //console.log(JSON.stringify(event.detail.fields));
            for (key in event.detail.fields)
            {
                if(event.detail.fields[key])
                {
                    caseRec[key] = event.detail.fields[key].trim();
                }
            }   
            let caseQuestionnaire = '';
            if(this.questions)
            {
                this.questions.forEach(inputCmp => {
                    //console.log('inputCmp.recordId: ' + inputCmp.recordId);
                    if(inputCmp.response)
                    {
                        caseQuestionnaire += "\n\n" + inputCmp.question + "\n" + inputCmp.response.trim();
                    }                
                });
    
            }
            caseRec.Description = caseQuestionnaire ? caseRec.Description + caseQuestionnaire:
            caseRec.Description;

            //console.log('this.selectedCategory: ' + this.selectedCategory);
            switch(this.selectedCategory) 
            {
                case "AMG":
                case "Billing" :
                    caseRec.Service__c = this.selectedCaseProduct;
                    caseRec.Request_Type__c = this.selectedProblem;  
                    caseRec.RecordType = this.selectedCategory;
                break;
                case "Technical":
                    caseRec.Case_Product__c = this.selectedCaseProduct;
                    caseRec.Customer_Problem__c = this.selectedProblem;    
                    caseRec.RecordType = this.productCategory === 'Emerging' ? 'Emerging Products Engineering' :'Technical';         
                break;
                case "SOCC":
                    caseRec.Case_Product__c = this.selectedCaseProduct;
                    caseRec.Problem__c = this.selectedProblem;
                    caseRec.Policy_Domain__c = this.selectedPolicyDomain;
                    caseRec.RecordType = 'Managed Security';                       
                break;
                case "PS":
                    caseRec.Case_Product__c = this.selectedCaseProduct;
                    caseRec.Service__c = this.selectedProblem;              
                    caseRec.Problem__c = this.selectedProblem;    
                    caseRec.RecordType = 'Professional Services';          
                break;
                default:
                    console.log('Default Case');
            }
            if(this.productCategory === 'Carrier')
            {
                caseRec.Sub_Type__c = 'Carrier';
            }
            if(this.selectedCategory === 'Billing')
            {
                caseRec.Severity__c = '3';
            }

            console.log('--this.selectedParentAccount--'+this.selectedParentAccount);
            if(this.selectedParentAccount !== undefined || this.selectedParentAccount !== '')
            {
                caseRec.Parent_Account__c = this.selectedParentAccount;

            }
            caseRec.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
            caseRec.Origin='Community Web';
            caseRec.AccountId=this.selectedAccount;
            caseRec.Severity__c=this.selectedSeverity;
            this.caseRecordToCreate = caseRec;
            //console.log(JSON.stringify(caseRec));
            
            if(caseRec.Jarvis_Also_Notify__c || caseRec.Parent_Account__c)
            {
                this.warningMessage = '';
                
                
                if(caseRec.Jarvis_Also_Notify__c){

                    console.log('----caseRec.Parent_Account__c---'+caseRec.Parent_Account__c);
                    console.log('----.uploadedFiles---'+this.uploadedFiles);
                    this.toggleSpinner(true);

                    alsoNotifyCheck({
                        "emailString":caseRec.Jarvis_Also_Notify__c,
                        "accountIdString": this.selectedAccount,
                        "parentAccountIdString": caseRec.Parent_Account__c,
                        'caseRecord' : JSON.stringify(this.caseRecordToCreate),
                        'filesToAttach' : JSON.stringify(this.uploadedFiles)
                    }).then(result => {
                        if(result === "Success")
                        {
                            this.callCaseCreateMethod();
                        }
                        else if(result.startsWith("500"))
                        {
                            this.toggleSpinner(false);    
                            this.navigateToRecord(result);
                        }
                        else if(result === "Success with Parent")
                        {
                            this.toggleSpinner(false); 
                        }
                        else
                        {
                            //console.log('WANRMG' + result);
                            this.toggleSpinner(false);    
                            this.showWarningModal=true;
                            //console.log("this.showWarningModal: " + this.showWarningModal);
                            this.warningMessage+=this.labels.MODAL_ERROR1 + result;
                            this.warningMessage+=this.labels.MODAL_ERROR2;
                        }
                        
                    })
                    .catch(error => {
                        this.toggleSpinner(false);
                        //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                        console.log('The error: ' + error +  JSON.stringify(error)) ;
                    });     
                }

                if(caseRec.Parent_Account__c){
                    //this.warningMessage = this.labels.MODAL_ERROR3 + ' \'' + this.selectedParentAccountName+ '\'<br /><br /> ' + this.warningMessage;
                    this.warningMessage = this.labels.MODAL_ERROR3.replace("<Account_Name>", this.selectedParentAccountName)+ '<br /><br /> ' + this.warningMessage;
                    this.toggleSpinner(false);
                    this.showWarningModal=true;
                }
                
                
                
                        
    
            }
            else
            {
                console.log('---callCaseCreateMethod--2');
                this.callCaseCreateMethod();
            }
    
        }

    }

    callCaseCreateMethod()
    {
        console.log('---callCaseCreateMethod--Method');
        this.showWarningModal = false;
        if(this.caseRecordToCreate)
        {
            this.toggleSpinner(true);
            createCase({'caseRecord' : JSON.stringify(this.caseRecordToCreate), 'filesToAttach': JSON.stringify(this.uploadedFiles)})
            .then(result => {
                this.toggleSpinner(false);
                //console.log('result: ' + result);
                if(result.startsWith('500'))
                {
                    this.navigateToRecord(result);
                }
                else
                {
                    this.currentStep = 'createCase';
                    this.showToast('error',result,this.labels.TOAST_ERROR,'dismissible');
                }
            })
            .catch(error => {
                this.toggleSpinner(false);
                //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                console.log('The error: ' + error +  JSON.stringify(error)) ;
            });        
    
        }

    }
    closeModal()
    {
        this.resetVariables('account');
        this.selectedAccount='';
        const closeEvent = new CustomEvent('closecreateevent', {
            detail: {
                close: true
            }
        });
        this.dispatchEvent(closeEvent);        
    }

    accComboProps = 
    {
        textField: 'Name', metaTextField: 'AKAM_Account_ID__c', keyField: 'Id',
        iconProps: { name: 'standard:account', variant: '', size: 'small' }
    };
        
        
        // Handler for SearchaccNoResultsMsg
        filteredAccountList=[];
        accNoResultsMsg='';
        
        format(stringToFormat, ...formattingArguments) {
            //if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
            return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
                (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
        }

        handleAccSearch(event) 
        {
            event.preventDefault();
            const searchString = event.detail.toLowerCase();
            //console.log('searchString: ' + searchString);
            if(!searchString)
            {
                //console.log('NOTHIGN TO DO');
            }
            else
            {
                //console.log('In Search');
                
                
                this.filteredAccountList = this.accounts.filter(el => 
                        {
                            //console.log(el);
                            return this.caseInsensitiveStringSearch(el.Name, searchString) || this.caseInsensitiveStringSearch(el.AKAM_Account_ID__c, searchString)
                        });
                        LABELS.CASE_ACCOUNT_ERROR
                //this.accNoResultsMsg =  !this.filteredAccountList.length? `Couldn't find any account matching "${searchString}"` : '';
                this.accNoResultsMsg =  !this.filteredAccountList.length? this.format(LABELS.CASE_ACCOUNT_ERROR,searchString) : '';
    
            }
        }
        
        caseInsensitiveStringSearch(str1, str2) 
        {
            const str1Lower = str1?.toLowerCase();
            const str2Lower = str2?.toLowerCase();
            return str1Lower.includes(str2Lower);
        }    


        expandCollapse(event)
        {
            let dataId = event.target.dataset.id;

            switch(dataId)
            {
                case "Expand:Article":
                    this.articleSections = ["Related Articles","Community Discussions"];
                break; 
                case "Collapse:Article" :
                    this.articleSections = [];
                break;
                case "Collapse:Case":
                    this.activeSections = [];
                break;
                case "Expand:Case":
                    this.activeSections = this.questionsExist?
                    [LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT,LABELS.SECTION_QUESTIONS]
                    :[LABELS.SECTION_ACCOUNT,LABELS.SECTION_INFO,LABELS.SECTION_PRODUCT,LABELS.SECTION_CONTACT];
            
                break;  
                default:
                    console.log('Default case');             
            }
        }

        showCaseupdateModal = false;
        closeCaseUpdateModal() 
        {
            this.showCaseupdateModal = false;    
        }

        openUpdateModal()
        {
            this.showCaseupdateModal = true;    
        }

        //suggestionButtonLabel = "Hide Suggestion";
        suggestionButtonLabel = LABELS.BUTTON_HIDE_SUGGESTION;
        flipSuggestion()
        {
            this.showSuggestionSection = !this.showSuggestionSection;
            //this.suggestionButtonLabel = !this.showSuggestionSection? "Show Suggestion" : "Hide Suggestion";
            this.suggestionButtonLabel = !this.showSuggestionSection? LABELS.BUTTON_SHOW_SUGGESTION : LABELS.BUTTON_HIDE_SUGGESTION;
        }

        goToSearchPage()
        {
            let fullUrl = "/customers/s/global-search/";
            
            fullUrl += this.subjectString?encodeURI(this.subjectString) : encodeURI(this.selectedCaseProduct);

            window.open(fullUrl,"_blank");    
        }
}