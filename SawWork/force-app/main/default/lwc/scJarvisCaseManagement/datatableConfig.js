import {LABELS} from './i18n';

const preview = {   label: '',
                    type: "button-icon",
                    initialWidth: 30,
                    typeAttributes: {
                        title: LABELS.LB_COL_PREVIEW,
                        name: 'Case_Preview',
                        variant: 'bare',
                        iconName: 'action:preview'
                    }
                };

const caseId =  {   label: LABELS.LB_COL_CASE_ID,
                    fieldName: 'caseUrl',
                    searchFieldName: 'akamCaseID',
                    sortable: true,
                    sortType: 'text',
                    sortFieldName: 'akamCaseID',
                    searchable: true,
                    initialWidth: 125,
                    type: 'url', 
                    typeAttributes: { label: { fieldName: 'akamCaseID' }, target: '_self' },
                    hideDefaultActions : true
                };

const account = {   label: LABELS.LB_COL_ACCOUNT,
                    fieldName: 'accountName',
                    sortable: true,
                    sortType: 'text',
                    searchable: true,
                    type: 'text',
                    hideDefaultActions : true
                }; 
const policyDomain = {   label: LABELS.LB_COL_PD_NAME,
                    fieldName: 'pdName',
                    sortable: true,
                    sortType: 'text',
                    searchable: true,
                    initialWidth: 125,
                    type: 'text',
                    hideDefaultActions : true
                }; 
                
const caseType = {  label: LABELS.LB_COL_CASE_TYPE,
                    fieldName: 'caseType',
                    initialWidth: 150,
                    sortable: true,
                    sortType: 'text',
                    searchable: true,
                    type: 'text',
                    hideDefaultActions : true
                };
const severity = {  label: LABELS.LB_COL_SEVERITY,
                fieldName: 'severity',
                sortable: true,
                sortType: 'text',
                searchable: true,
                type: 'text',
                initialWidth: 100,
                hideDefaultActions : true
            };
const subject = {   label: LABELS.LB_COL_SUBJECT,
                    fieldName: 'subject',
                    type: 'text',
                    sortType: 'text',
                    initialWidth: 230,
                    sortable: true,
                    searchable: true
                };
const status = {    label: LABELS.LB_COL_STATUS,
                    fieldName: 'status',
                    sortable: true,
                    sortType: 'text',
                    searchable: true,
                    type: 'text',
                    hideDefaultActions : true
                };

const ceatedDate = {    label: LABELS.LB_COL_CREATED_DATE,
                        fieldName: 'createddatestr',
                        sortable: true,
                        sortType: 'date',
                        sortFieldName: 'createddate',
                        type: 'text',
                        hideDefaultActions : true
                    };
const updatedDate = {   label: LABELS.LB_COL_UPDATED_DATE,
                        fieldName: 'updateddatestr',
                        //fixedWidth: 130,
                        sortable: true,
                        sortType: 'date',
                        sortFieldName: 'updateddate',
                        type: 'text',
                        hideDefaultActions : true
                    };
const caseContact = {   label: LABELS.LB_COL_CUSTOMER_CONTACT,
                        fieldName: 'caseContact',
                        sortable: true,
                        sortType: 'text',
                        searchable: true,
                        type: 'text',
                        hideDefaultActions : true,
                        initialWidth: 125
                    };
export const ALL_COLS = [   preview,
                            caseId,
                            account,
                            caseContact,
                            caseType,
                            subject,
                            severity,
                            status,
                            ceatedDate,
                            updatedDate
                        ];
const TECH_COLS = [ preview,
                    caseId,
                    account,
                    caseContact,
                    subject,
                    severity,
                    status,
                    ceatedDate,
                    updatedDate
                ];
const SOCC_COLS = [ preview,
                    caseId,
                    account,
                    caseContact,
                    policyDomain,
                    subject,
                    severity,
                    status,
                    ceatedDate,
                    updatedDate
                ];
const PS_COLS = [ preview,
                    caseId,
                    account,
                    caseContact,
                    subject,
                    severity,
                    status,
                    ceatedDate,
                    updatedDate
                ];

const AMG_COLS = [ preview,
                    caseId,
                    account,
                    caseContact,
                    subject,
                    severity,
                    status,
                    ceatedDate,
                    updatedDate
                ];
const BILLING_COLS = [ preview,
                    caseId,
                    account,
                    caseContact,
                    subject,
                    severity,
                    status,
                    ceatedDate,
                    updatedDate
                ];

export const COL_MAP = {    'All': ALL_COLS,
                            'Technical': TECH_COLS ,
                            'Managed Security': SOCC_COLS,
                            'Professional Services': PS_COLS,
                            'AMG': AMG_COLS,
                            'Billing': BILLING_COLS
                        };