import TITLE from '@salesforce/label/c.JV_Title';
import LAST_MODIFIED from '@salesforce/label/c.Jarvis_AttachmentRL_LastModified';   
import EXTENSION from '@salesforce/label/c.Jarvis_AttachmentRL_Extension';  
import CREATED_BY  from '@salesforce/label/c.Jarvis_CaseLabel_Created_By_Name';
import ATTACHMENTS  from '@salesforce/label/c.Jarvis_AttachmentRL_Attachments';
import FILE_SIZE from '@salesforce/label/c.Jarvis_EMessageAttachmentsCol_Size';

const title = {   
    label: TITLE,
    fieldName: 'title',
    sortable: false,
    searchable: false,
    //type: 'scRichText',
    type: 'text',
    initialWidth: 215,
    hideDefaultActions : true
}; 
const extension = {   
    label: EXTENSION,
    fieldName: 'extension',
    sortable: false,
    searchable: false,
    //type: 'scRichText',
    type: 'text',
    hideDefaultActions : true,
    initialWidth: 75
};

const fileSize = {
    label: FILE_SIZE,
    fieldName: 'fileSize',
    soratble: false,
    searchable: false,
    type: 'text',
    hideDefaultActions : true,
    initialWidth: 60
}
                
const lastModified = {  
    label: LAST_MODIFIED,
    fieldName: 'lastModified',
    sortable: false,
    searchable: false,
    initialWidth: 125,
    hideDefaultActions : true,
    type: 'text' 
            
};

const createdBy = {   
    label: CREATED_BY,
    fieldName: 'createdBy',
    type: 'text',
    initialWidth: 150,
    sortable: false,
    searchable: false
};

/*const downloadURL = {
    type:'url',
    fieldName: 'downloadURL',
    cellAttributes: { iconName: 'utility:download' ,
    variant: 'bare'}

}*/


const downloadURL = {   label: '',
                    type: 'button-icon',
                    initialWidth: 30,
                    typeAttributes: {
                        title: 'Download',
                        name: 'downloadURL',
                        variant: 'bare',
                        iconName: 'utility:download'
                    }
                };





/*const actions = [
    { label: 'Download', name: 'download' }
];*/

export const ATTACHMENT_COLS = 
[ 
    title,
    extension,
    fileSize,
    lastModified,
    createdBy,
    downloadURL
];

export const ATTACHMENTS_HEADER = ATTACHMENTS;