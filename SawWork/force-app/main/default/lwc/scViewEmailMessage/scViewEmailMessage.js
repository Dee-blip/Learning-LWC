/** @Date		:	Feb 8 2022
 * @Author		: 	jrathod
 * @Description	:	Component to display Email Message details
 */

import {LightningElement,api,wire} from 'lwc';
import getEmail from "@salesforce/apex/SC_CommunityCommentController.getEmail";
import getAttachments from "@salesforce/apex/SC_CommunityCommentController.getAttachments";
import {bytesToSize, getFileExtension, labels, parseHtml, replaceInlineImageLinks, showToast} from "./helper";
import {ATTACHMENT_TABLE_COLUMNS} from "./helper";

const FIELDS_TO_SHOW_HTML = {
    FromAddress: labels.fromAddress,
    ToAddress: labels.toAddress,
    CcAddress: labels.ccAddress,
    Subject: labels.subject,
    HtmlBody: labels.emailBody
}

const FIELDS_TO_SHOW_PLAINTEXT = {
    FromAddress: labels.fromAddress,
    ToAddress: labels.toAddress,
    CcAddress: labels.ccAddress,
    Subject: labels.subject,
    TextBody: labels.emailBody
}

export default class ScViewEmailMessage extends LightningElement {

    @api
    emailMessageId;
    emailMessageRecord= {};
    attachments = [];
    attachmentTableColumns = ATTACHMENT_TABLE_COLUMNS;
    totalNumOfAttachments = 0;
    totalNumOfRetrievedAttachments = 0;


    @wire(getEmail, {emailId: '$emailMessageId'})
    onMessageRetrieve({data: record,error}){
        if (!!record){
            let {email,attachmentCount} = record;
            this.emailMessageRecord ={...email};
            this.totalNumOfAttachments = attachmentCount;
            if(this.emailMessageRecord.HtmlBody){
                this.emailMessageRecord.HtmlBody = parseHtml(this.emailMessageRecord.HtmlBody);
            }
            if (email.HasAttachment){
                this.retrieveAttachments();
            }
        }else if (error){
            console.error(error);
            showToast(this,'error',labels.errorMessage,labels.errorTitle)
        }
    }

    showSpinner_retrieveAttachments = false;

    async retrieveAttachments(){
        try{
            this.showSpinner_retrieveAttachments = true;
            let attachments = await getAttachments({
                parentId:this.emailMessageId});
            this.attachments = [...this.attachments,...attachments];
            if(this.emailMessageRecord.HtmlBody){
                this.emailMessageRecord.HtmlBody = replaceInlineImageLinks(this.emailMessageRecord.HtmlBody, this.attachments);
            }
        }catch (e) {
            console.error(e);
            showToast(this,'error',labels.errorMessage,labels.errorTitle);
        }finally {
            this.showSpinner_retrieveAttachments = false;
        }
    }

    get attachmentTabLabel(){
        return labels.tabAttachments.replace('{0}',this.totalNumOfAttachments);
    }

    get detailsTabLabel(){
        return labels.tabDetails;
    }

    get fieldsToShow(){
        return this.emailMessageRecord ? Object.entries(this.emailMessageRecord.HtmlBody ? FIELDS_TO_SHOW_HTML : FIELDS_TO_SHOW_PLAINTEXT).map(([name, label]) => {
            let value = this.emailMessageRecord[name];
            return {name,label,value}
        }) : [];
    }

    get attachmentRows(){
        return (this.attachments || []).map(attachment =>{
            attachment.Size = bytesToSize(attachment.BodyLength);
            attachment.Extension = getFileExtension(attachment.Name);
            return attachment;
        });
    }


}