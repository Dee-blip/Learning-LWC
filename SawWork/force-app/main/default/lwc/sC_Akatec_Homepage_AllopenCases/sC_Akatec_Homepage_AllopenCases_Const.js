export const TAB_COLS = [
    //1
    {
        label: 'AKAM Case ID',
        name: "akamCaseId",
        fieldName: 'AkamCaseIDURL',
        sortable: true,
        initialWidth: 125,
        type: 'button',
        typeAttributes:
            {
                label: {fieldName: 'akamcaseid'},
                variant: 'base',
                name: 'OpenCaseURL'
            },
    },
    //2
    {
        label: 'Account',
        name: "accountName",
        fieldName: 'AccountName',
        sortable: true,
        type: 'text',
        initialWidth: 125
    },
    //3
    {
        label: 'Severity',
        name: "severity",
        fieldName: 'Severity',
        sortable: true,
        type: 'text',
        initialWidth: '50'
    },
    //4
    {
        label: 'Geography',
        name: "geography",
        fieldName: 'Geography',
        sortable: true,
        type: 'text',
        cellAttributes: {class: {fieldName: 'GeographyColor'}}
    },
    //5
    {
        label: 'TSE',
        name: "tse",
        sortable: false,
        initialWidth: 60,
        type: 'button-icon',
        typeAttributes:
            {
                iconName: 'utility:people',
                variant: 'brand',
                name: 'viewTSE'
            }
    },
    //6
    {
        label: 'Subject',
        name: "subject",
        fieldName: 'Subject',
        type: 'text',
        wrapText: true,
        initialWidth: 140
    },
    //7
    {
        //Added Case Product by Aditi
        label: 'Case Product',
        name: "caseProduct",
        fieldName: 'caseProd',
        type: 'text',
        sortable: true,
        wrapText: true,
        initialWidth: 50
    },
    //8
    {
        label: 'Country',
        name: "country",
        fieldName: 'Country',
        sortable: true,
        type: 'text'
    },
    //9
    {
        label: 'Industry',
        name: "industry",
        fieldName: 'Industry',
        sortable: true,
        type: 'text'
    },
    //10
    {
        label: 'Region',
        name: "region",
        fieldName: 'Region',
        sortable: true,
        type: 'text'
    },
    //11
    {
        label: 'Territory',
        name: "territory",
        fieldName: 'Territory',
        sortable: true,
        type: 'text'
    },
    //12
    {
        label: 'Work Type',
        name: "workType",
        fieldName: 'WorkType',
        sortable: true,
        type: 'text'
    },
    //13-1 = 12
    {
        label: 'Age',
        name: "age",
        fieldName: 'Age',
        sortable: true,
        type: 'number',
        initialWidth: '50',
        cellAttributes: {alignment: 'left'}
    },
    //14
    {
        label: 'Support Level',
        name: "supportLevel",
        fieldName: 'SupportLevel',
        sortable: true,
        type: 'text'
    },
    //15
    {
        label: 'Case Owner',
        name: "caseOwner",
        fieldName: 'CaseOwner',
        sortable: true,
        type: 'text'
    },
    //16
    {
        label: 'SLA',
        name: "sla",
        fieldName: 'SLA',
        sortable: true,
        type: 'text',
        cellAttributes: {class: {fieldName: 'SLA_Color'}}
    },
    //17
    {
        type: 'action',
        name: "actions",
        typeAttributes: {
            rowActions: [
                {label: 'Assign', name: 'assign-case'},
                {label: 'View at a Glance', name: 'case-details'}
            ],
            menuAlignment: 'right'
        }
    }
];

export const QUEUE_COLS = [
    {
        label: 'Queue Name',
        fieldName: 'queueName',
        sortable: true,
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Count',
        fieldName: 'queueCount',
        sortable: true,
        type: 'text',
        hideDefaultActions: true

    }
];