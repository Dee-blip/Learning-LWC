import { LightningElement, api } from 'lwc';
import getAttachmentDetail from '@salesforce/apex/SC_Jarvis_Attachment_Detail_Ctrl.getAttachmentDetail'
import {LABELS, ATTACHMENT_INFO_HEADER, ATTACHMENT_DOWNLOAD} from './i18n';

export default class ScJarvisAttachmentDetailPage extends LightningElement {

    
    @api recordId;
    title;
    downLoadURL;
    attachmentValues;
    labels = LABELS;
    header = ATTACHMENT_INFO_HEADER;
    download = ATTACHMENT_DOWNLOAD;
    @api objectApiName = 'ContentDocument';

    connectedCallback() 
    { 
        this.loadData();
    }

    loadData(){
        getAttachmentDetail({
            labelvalues: this.labels,
            'attachmentId' : this.recordId,
            
        })
        .then(result => {
            if(!result)
            {
                console.log('---not in promise--');
                //this.enableLoad = false;
            }
            else
            {
                this.title = result.title;
                this.attachmentValues = result.attachmentDetails;
                this.downLoadURL = result.downloadURL;
                console.log('---in promise--');
                //console.log(this.data);             

            }
            
        });
    }

    downloadFile(){
        let baseUrl = this.getBaseUrl();
        let completeUrl = baseUrl + '/customers/sfc/servlet.shepherd/document/download/'+this.recordId;
         console.log(completeUrl);
        window.open(completeUrl, '_self');

    }

    getBaseUrl(){
        let baseUrl = 'https://'+window.location.host+'/';
        return baseUrl;
    }
}