import COMMENT_HEADER_JARVIS from '@salesforce/label/c.Jarvis_Comment_Header';	
import COMMMENT_DETAILS_JARVIS from '@salesforce/label/c.Jarvis_Comment_Case_Details';	
import FILE_UPLOAD_JARVIS from '@salesforce/label/c.Jarvis_Comment_File_Upload';	
import UPLOAD_FILE_JARVIS from '@salesforce/label/c.Jarvis_Comment_Upload_File';	
import FILE_DETAILS_JARVIS from '@salesforce/label/c.Jarvis_Comment_File_Details';	
import LATEST_COMMENTS_FIRST_JARVIS from '@salesforce/label/c.Jarvis_Comment_Latest_Comments_First';	
import OLDEST_COMMENTS_FIRST_JARVIS from '@salesforce/label/c.Jarvis_Comment_Oldest_Comments_First';	
import ONLY_AKAMAI_COMMENTS_JARVIS from '@salesforce/label/c.Jarvis_Comment_Only_Akamai_Comments';	
import ONLY_CUSTOMER_COMMENTS_JARVIS from '@salesforce/label/c.Jarvis_Comment_Only_Customer_Comments';	
import EMAIL_CHAT_ITEM from '@salesforce/label/c.Jarvis_Email_Chat';	
import ERR_SAVE_COMMENT from '@salesforce/label/c.JV_Error_Saving_Comment';	
import ERR_MAX_LENGTH from '@salesforce/label/c.JV_Comment_Max_Length';	
import ERR_CURR_LENGTH from '@salesforce/label/c.JV_Comment_Current_Length';

import FILE_UPLOADED from '@salesforce/label/c.Jarvis_Comment_File_Uploaded';	
import SHARE_BUTTON from '@salesforce/label/c.Jarvis_Comment_Share';	
import NOT_AVAILABLE from '@salesforce/label/c.JV_Internal_Not_Available';	
import OUT_OF_SCOPE from '@salesforce/label/c.JV_Case_Out_Of_Scope';	
import NO_COMMENTS_ACCESS from '@salesforce/label/c.Jarvis_Comment_No_Comment_Access';	
import NO_COMMENTS_NO_ACCESS from '@salesforce/label/c.Jarvis_Comment_No_Comment_No_Access';	
import WRITE_COMMENT from '@salesforce/label/c.Jarvis_Comment_Write_Comment';	
import SHARE_MSG_INTERNAL from '@salesforce/label/c.JV_ShareMsgInternal';	
import SHARE_MSG_EXTERNAL from '@salesforce/label/c.JV_ShareMsgExternal';	
import COMMENT_CASE_CLOSED from '@salesforce/label/c.Jarvis_Comment_Case_Closed';
import ATTACHMENT_WARNING_MSG from '@salesforce/label/c.JV_AttachmentWarningMsg';

import SF_FILE_BASE_URL from '@salesforce/label/c.JV_SfFileBaseUrl';	
import COMM_FILE_BASE_URL from '@salesforce/label/c.JV_CommunityFileBaseUrl';	

const CHIME_COMMMENT_DETAILS = 'CASE DETAILS';
const CHIME_FILE_UPLOAD = 'FILE UPLOAD';
const CHIME_UPLOAD_FILE = 'Upload File';
const CHIME_FILE_DETAILS = 'FILE DETAILS';
const CHIME_NO_COMMENTS = 'This form has no comments. Use the Share button above to add a new comment.';
    
export const getLabels = (appName) => {
    return {
        COMMMENT_DETAILS: appName ==='JARVIS'? COMMMENT_DETAILS_JARVIS: CHIME_COMMMENT_DETAILS,
        FILE_UPLOAD: appName ==='JARVIS'? FILE_UPLOAD_JARVIS: CHIME_FILE_UPLOAD,
        UPLOAD_FILE: appName ==='JARVIS'? UPLOAD_FILE_JARVIS: CHIME_UPLOAD_FILE,
        FILE_DETAILS: appName ==='JARVIS'? FILE_DETAILS_JARVIS: CHIME_FILE_DETAILS,
        NO_COMMENTS_ACCESS: appName ==='JARVIS'? NO_COMMENTS_ACCESS: CHIME_NO_COMMENTS,
        LATEST_COMMENTS_FIRST: LATEST_COMMENTS_FIRST_JARVIS,
        OLDEST_COMMENTS_FIRST: OLDEST_COMMENTS_FIRST_JARVIS,
        ONLY_AKAMAI_COMMENTS: ONLY_AKAMAI_COMMENTS_JARVIS,
        ONLY_CUSTOMER_COMMENTS: ONLY_CUSTOMER_COMMENTS_JARVIS,
        COMMENT_HEADER: COMMENT_HEADER_JARVIS,
        FILE_UPLOADED,
        SHARE_BUTTON,
        NO_COMMENTS_NO_ACCESS,
        WRITE_COMMENT,
        EMAIL_CHAT_ITEM,
        ERR_SAVE_COMMENT,
        ERR_MAX_LENGTH,
        ERR_CURR_LENGTH,
        NOT_AVAILABLE,
        OUT_OF_SCOPE,
        SHARE_MSG_INTERNAL,
        SHARE_MSG_EXTERNAL,
        COMM_FILE_BASE_URL,
        SF_FILE_BASE_URL,
        COMMENT_CASE_CLOSED,
        ATTACHMENT_WARNING_MSG
    };
};