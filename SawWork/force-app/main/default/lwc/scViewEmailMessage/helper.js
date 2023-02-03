import tabDetails from "@salesforce/label/c.JV_Details";
import tabAttachments from "@salesforce/label/c.Jarvis_EmailMessage_Tab_Attachments";
import fromAddress from "@salesforce/label/c.Jarvis_EmailMessage_FromAddress";
import toAddress from "@salesforce/label/c.Jarvis_EmailMessage_ToAddress";
import ccAddress from "@salesforce/label/c.Jarvis_EmailMessage_CCAddress";
import subject from "@salesforce/label/c.Jarvis_EmailMessage_Subject";
import emailBody from "@salesforce/label/c.Jarvis_EmailMessage_HtmlBody";
import errorMessage from "@salesforce/label/c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastMessageError";
import inlineImageLabel from "@salesforce/label/c.Jarvis_EmailMessage_InlineImageLabel";
import fileNameColumn from "@salesforce/label/c.Jarvis_EMessageAttachmentsCol_Name";
import typeColumn from "@salesforce/label/c.Jarvis_AttachmentRL_Extension";
import sizeColumn from "@salesforce/label/c.Jarvis_EMessageAttachmentsCol_Size";
import errorTitle from "@salesforce/label/c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastTitleError";
import inlineImage from "@salesforce/label/c.Jarvis_EmailMessage_InlineImage";
import unknown from "@salesforce/label/c.Jarvis_EmailMessage_Unknown";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export const labels = {
    tabDetails,
    tabAttachments,
    fromAddress,
    toAddress,
    ccAddress,
    subject,
    emailBody,
    errorMessage,
    inlineImageLabel,
    fileNameColumn,
    typeColumn,
    sizeColumn,
    errorTitle,
    inlineImage,
    unknown
}

export const parseHtml = (emailBody) =>{
    let parser = new DOMParser();
    let htmlParsed = parser.parseFromString(emailBody, 'text/html');
    let htmlBodyTags = htmlParsed.getElementsByTagName('body');
    if(htmlBodyTags.length > 0) {
        return htmlBodyTags[0].innerHTML;
    }
    return emailBody;
}

export const replaceInlineImageLinks = (emailBody,attachments) => {
    let genericMessage = labels.inlineImageLabel.replace('{0}',labels.inlineImage);
    let parser = new DOMParser();
    let htmlParsed = parser.parseFromString(emailBody, 'text/html');
    let imgs = htmlParsed.getElementsByTagName('img');
    let attachmentNames = attachments.map(att => att.Name);
    let inlineImages = [...imgs].filter(img => img.src.startsWith('cid:'));
    inlineImages.forEach(img =>{
        if(img.src.includes('@')){
            let fileName = img.src.substring(4,img.src.lastIndexOf('@'));
            if (attachmentNames.includes(fileName)){
                img.alt = labels.inlineImageLabel.replace('{0}',fileName);
            }else{
                img.alt = genericMessage;
            }
        }else if(attachmentNames.includes(img.alt)){
            img.alt = labels.inlineImageLabel.replace('{0}',img.alt);
        }else {
            img.alt = genericMessage;
        }
    });

    let htmlBodyTags = htmlParsed.getElementsByTagName('body');
    if(htmlBodyTags.length > 0) {
        return htmlBodyTags[0].innerHTML;
    }
    return null;
}

export const ATTACHMENT_TABLE_COLUMNS = [
    {
        label: labels.fileNameColumn,
        fieldName: "Url",
        wrapText: true,
        type:'url',
        typeAttributes: {
            target: '_blank',
            label: {
                fieldName: 'Name'
            }
        }
    },
    {
        label: labels.typeColumn,
        fieldName: "Extension",
        wrapText: true
    },
    {
        label: labels.sizeColumn,
        fieldName: "Size",
        wrapText: true
    }
]

const ONE_KB = 1024;
const ONE_MB = 1024 * 1024;

export function bytesToSize(bytes) {
    if (bytes < ONE_KB){
        return bytes + ' bytes';
    } else if (bytes < ONE_MB){
        //return in KB
        return Math.round(bytes/ONE_KB) + ' KB';
    } else if(bytes >= ONE_MB){
        //return in MB
        return Math.round(bytes/ONE_MB) + ' MB';
    }
    return bytes;
}

export function showToast(ltngElem, variant,message,title,mode = 'dismissible'){
    const event = new ShowToastEvent({
        "title": title,
        "message": message,
        "mode" : mode,
        "variant" : variant
    });
    ltngElem.dispatchEvent(event);
}

export function getFileExtension(fileName) {
    if(fileName && fileName.length > 0 && fileName.includes('.')){
        return fileName.substring(fileName.lastIndexOf('.'))
    }else{
        return labels.unknown;
    }
}