export const MY_TEAM_COLS = [
    {
        label: 'AKAM Case ID',
        fieldName: 'AkamCaseIDURL',
        sortable: true,
        initialWidth: 125,
        type: 'button',
        cellAttributes: { 
            class: { fieldName: 'RecentUpdateColor' }
     },
        typeAttributes:
        {
            label: { fieldName: 'akamcaseid' },
            variant: 'base',
            name: 'OpenCaseURL'
        }
    }
    ,
    {
        label: 'Account',
        fieldName: 'AccountName',
        sortable: true,
        type: 'text',
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Geography',
        fieldName: 'Geography',
        sortable: true,
        type: 'text',
        cellAttributes: { class: { fieldName: 'GeographyColor' } }
    },
    {
        label: 'Country',
        fieldName: 'Country',
        sortable: true,
        type: 'text'
    },
    {
        label: 'LOE',
        fieldName: 'LOE',
        sortable: true,
        type: 'number'
    },
    {
        label: 'Work Type',
        fieldName: 'WorkType',
        sortable: true,
        type: 'text'
    },
    
    {
        label: 'Status',
        fieldName: 'casestatus',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Severity',
        fieldName: 'Severity',
        sortable: true,
        type: 'text',
        initialWidth: '50'

    },
    {
        label: 'Support Level',
        fieldName: 'SupportLevel',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Age',
        fieldName: 'Age',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Case Owner',
        fieldName: 'CaseOwner',
        sortable: true,
        type: 'text'
    },
    {
        label: 'SLA',
        fieldName: 'SLA',
        sortable: true,
        type: 'text',
        cellAttributes: { class: { fieldName: 'SLA_Color' } }
    }
];

export const MY_OPEN_COLS = [
   {
        label: 'AKAM Case ID',
        fieldName: 'AkamCaseIDURL',
        sortable: true,
        initialWidth: 125,
        type: 'button',
        cellAttributes: { 
            class: { fieldName: 'RecentUpdateColor' }
     },
        typeAttributes:
        {
            label: { fieldName: 'akamcaseid' },
            variant: 'base',
            name: 'OpenCaseURL'
        }
    }
    ,
    {
        label: 'Account',
        fieldName: 'AccountName',
        sortable: true,
        type: 'text',
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Geography',
        fieldName: 'Geography',
        sortable: true,
        type: 'text',
        cellAttributes: { class: { fieldName: 'GeographyColor' } }
    },
    {
        label: 'Country',
        fieldName: 'Country',
        sortable: true,
        type: 'text'
    },
    {
        label: 'LOE',
        fieldName: 'LOE',
        sortable: true,
        type: 'number'
    },
    {
        label: 'Work Type',
        fieldName: 'WorkType',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Age',
        fieldName: 'Age',
        sortable: true,
        type: 'number',
        initialWidth: 80
    },
    {
        label: 'Status',
        fieldName: 'casestatus',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Severity',
        fieldName: 'Severity',
        sortable: true,
        type: 'text',
        initialWidth: '50'
    },
    {
        label: 'Support Level',
        fieldName: 'SupportLevel',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Next Action',
        fieldName: 'NextAction',
        sortable: true,
        type: 'text'
    },
    {
        label: 'AKAM Modified Date',
        fieldName: 'akamModifiedDate',
        sortable: true,
        initialWidth: 100,
        type: 'text'
    },
    {
        label: 'SLA',
        fieldName: 'SLA',
        sortable: true,
        type: 'text',
        cellAttributes: { class: { fieldName: 'SLA_Color' } }
    }
];