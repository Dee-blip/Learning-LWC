import CASE_HISTORY_ACTION from '@salesforce/label/c.Jarvis_HistoryLabel_Action';
import CASE_HISTORY_DATE from '@salesforce/label/c.Jarvis_HistoryLabel_Date';   
import CASE_HISTORY_USER from '@salesforce/label/c.Jarvis_HistoryLabel_User';   
import CASE_HISTORY from '@salesforce/label/c.Jarvis_Card_Case_History';    

const action = {   
    label: CASE_HISTORY_ACTION,
    fieldName: 'action',
    sortable: false,
    searchable: false,
    type: 'scRichText',
    //type: 'text',
    hideDefaultActions : true,
    cellAttributes: { class: 'richTextAreaCustom' }
}; 
                
const actionTime = {  
    label: CASE_HISTORY_DATE,
    fieldName: 'actionTime',
    sortable: false,
    searchable: false,
    initialWidth: 150,
    hideDefaultActions : true,
    type: 'text' 
};
const user = {   
    label: CASE_HISTORY_USER,
    fieldName: 'user',
    type: 'text',
    initialWidth: 180,
    sortable: false,
    searchable: false
};

export const HISTORY_COLS = 
[ 
    actionTime,
    user,
    action
];    

export const CASE_HISTORY_HEADER = CASE_HISTORY;