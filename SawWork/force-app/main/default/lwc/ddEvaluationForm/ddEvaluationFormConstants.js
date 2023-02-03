// Column Meta Data for Customer MRR Modal
export const MRR_COLS = [
    { label: 'Services Product', fieldName: 'Product__c', type: 'text', cellAttributes: { cellpadding: '10px' } },
    { label: 'Local Currency', fieldName: 'Local_Currency__c', type: 'text' },
    { label: 'Local Revenue (MRR)', fieldName: 'Local_Revenue__c', type: 'text' },
    { label: 'USD Revenue (MRR)', fieldName: 'USD_Revenue__c', type: 'currency', typeAttributes: { currencyCode: 'USD' } }
];

// Form Config for different modes(new, edit, read) - Controls display of each input element ( readonly/ editbale)
export const FORM_CONFIG = {
    new: {
        account: { disabled: false }, product: { disabled: false }, currency: { disabled: false },
        packageComp: { disabled: false }, reqPrice: { disabled: false }, napCust: { disabled: false },
    },
    edit: {
        account: { disabled: true }, product: { disabled: true }, currency: { disabled: false },
        packageComp: { disabled: false }, reqPrice: { disabled: false }, napCust: { disabled: false }
    },
    read: {
        account: { disabled: true }, product: { disabled: true }, currency: { disabled: true },
        packageComp: { disabled: true }, reqPrice: { disabled: true }, napCust: { disabled: true }
    }
};

// Message Codes and their config - Display Type(variant), title, mode 
export const ERROR_MSGS = {
    'ERR_APP_DOWN': {
        title: 'App Down For Maintenence',
        message: 'Deal Desk App is down for routine maintenance. Please come back later.',
        variant: 'error',
        mode: 'sticky'
    },
    'ERR_PROD_FETCH': { title: 'Product Fetch', variant: 'error' },
    'ERR_CURR_FETCH': { title: 'Fetching Currency', variant: 'error' },
    'ERR_ACC_SEARCH': { title: 'Account Search', variant: 'error' },
    'ERR_MRR_FETCH': { title: 'MRR Fetch', variant: 'error' }
};

export const CURRENCY_CBOX_CONFIG = { textField: 'label', keyField: 'key' };
export const ACCOUNT_CBOX_CNFIG = {
    textField: 'Name', metaTextField: 'AKAM_Account_ID__c', keyField: 'Id',
    iconProps: { name: 'standard:account', variant: '', size: 'small' }
};

export const OTHER_APPROVERS = [{ label: 'Discount', value: 'Discount' }, 
                                { label: 'Product min/max exception', value: 'Product min/max exception' }, 
                                { label: 'Special Contract Duration', value: 'Special Contract Duration' },
                                { label: 'Special Business Terms', value: 'Special Business Terms' },
                                { label: 'Special Payment Terms', value: 'Special Payment Terms' },
                                { label: 'Other', value: 'Other' }];