import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";
import {ATTACHMENT_COLS, ATTACHMENTS_HEADER} from './scJarvisAttachmentRelatedListLabel';
import getAttachmentRelatedListWrapper from '@salesforce/apex/SC_Jarvis_AttachmentRL_Ctrl.getAttachmentRelatedListWrapper';
import updateCaseRecord from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.updateCaseRecord';


export default class ScJarvisAttachmentRelatedList extends LightningElement {

    @api recordId;


    columns = ATTACHMENT_COLS;
    header = ATTACHMENTS_HEADER;
    enableLoad = true;
    displayUploadFilesButton;
    tableClass = "tableStyle";
    data = [];
    currentCount = 0;

    caseRecord;

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

    

    connectedCallback() 
    {        
            console.log('LOADED!!!! Vam');
            //loadStyle(this, staticStyleSheet);          
            //loadSpinner = false;
            loadStyle(this, staticStyleSheet);       
            this.loadData();
    }

    loadData()
    {
        
        this.loadSpinner = true;
        console.log('This recordId: case Attachment ' + this.recordId);
        getAttachmentRelatedListWrapper({
            'caseId' : this.recordId
        })
        .then(result => {
            if(!result)
            {
                console.log('---not in promise--');
                this.enableLoad = false;
            }
            else
            {
                //this.data = [...this.data,...result];
                this.data = result.attachmentRecords;
                this.displayUploadFilesButton = result.displayUploadFileButton;
                console.log('---in promise--');
                this.loadSpinner = false;
                this.currentCount = this.data.length;   
                //console.log(this.data);             

            }
            
        })
        .then(result => {
            console.log(result);
            this.tableClass = this.currentCount > 8? "tableStyle scrollClass" : "tableStyle";            
            this.loadSpinner = false;     
        })
        .catch(error => {
            console.log('---in catch--');
            this.loadSpinner = false;
            //console.log('The error: ' + error +  JSON.stringify(error)) ;
            //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        


    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log(uploadedFiles);

        this.caseRecord = {};
        this.caseRecord.Id = this.recordId;

        updateCaseRecord({'updateRecord' : JSON.stringify(this.caseRecord)})
            .then(() => {
                              
                //console.log('result: ' + result);
                console.log('Date update successful!');
            })
            .catch(error => {
                console.log('The error: ' + error +  JSON.stringify(error)) ;
            });   
        
        this.loadData();
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'downloadURL') {
            let baseUrl = this.getBaseUrl();
            let completeUrl = baseUrl + '/customers/sfc/servlet.shepherd/document/download/'+row.downloadURL;
            console.log(completeUrl);
            window.open(completeUrl, '_self');
        }
    }

    getBaseUrl(){
        let baseUrl = 'https://'+window.location.host+'/';
        return baseUrl;
    }

}