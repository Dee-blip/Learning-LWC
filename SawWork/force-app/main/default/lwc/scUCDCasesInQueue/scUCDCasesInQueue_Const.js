export const MY_OPEN_COLS = [
    
    {
        label: 'Case',
        fieldName: 'caseUrl',
        sortable: true,
        initialWidth: 125,
        type: 'url', typeAttributes: { label: { fieldName: 'akamCaseId' }, target: '_blank' }
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        sortable: true,
        type: 'text',
        initialWidth: 50,
        hideDefaultActions : true
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        initialWidth: 125,
        type: 'url', typeAttributes: { label: { fieldName: 'accountName' }, target: '_blank' }
    },

    /*{
        label: 'Assign',
        sortable: false,
        initialWidth: 60,
        type: 'button-icon',
        typeAttributes:
        {
            iconName: 'utility:adduser',
            variant: 'brand',
            tooltip: 'Click to assign Case to yourself',
            name: 'assign-case'
        }
    },*/
    {
        label: 'Subject',
        fieldName: 'subject',
        type: 'text',
        initialWidth: 130,
        sortable: true,
        wrapText: true
    },
    {
        label: 'Service',
        fieldName: 'Service',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Request Type',
        fieldName: 'ReqType',
        sortable: true,
        initialWidth: 125,
        type: 'text'
    },
    {
        label: 'Product',
        fieldName: 'caseProductName',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Age (Days)',
        fieldName: 'ageDays',
        sortable: true,
        type: 'number',
        initialWidth: 80,
        hideDefaultActions : true
    },
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'text',
        cellAttributes: { alignment: 'left', class: { fieldName: 'reqCompletionDateColour' }} 
    },
    {
        label: 'Description',
        fieldName: 'livingSummary',
        sortable: false,
        initialWidth: 80,
        type: 'button-icon',
        typeAttributes:
        {
            iconName: 'utility:preview',
            variant: 'brand',
            name: 'OpenDescription',
            disabled:{fieldName :'showlivingSummarybtn'}
        }
    },

    {
        label: 'Owner',
        fieldName: 'caseOwner',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Creator',
        fieldName: 'caseCreator',
        sortable: true,
        type: 'text'
    },
    {
        label: 'Origin',
        fieldName: 'caseOrigin',
        sortable: true,
        type: 'text'
    },
    {
        label: 'LOE',
        fieldName: 'caseloe',
        sortable: true,
        type: 'text',
        initialWidth: 80,
        hideDefaultActions : true
    },
    {
        label: 'Project',
        fieldName: 'ProjectURL',
        sortable: true,
        initialWidth: 125,
        type: 'url', typeAttributes: { label: { fieldName: 'Project' }, target: '_blank' }
    },
    /*{
        label: 'Pending Case Reason',
        fieldName: 'pendingCaseReason',
        sortable: false,
        initialWidth: 80,
        type: 'button-icon',
        typeAttributes:
        {
            iconName: 'utility:edit',
            variant: 'brand',
            name: 'open-pending-reason',
            disabled:{fieldName :'showpendingCaseReasonbtn'}
        }
    },*/
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        type: 'button',
        initialWidth: 125,
        typeAttributes:
        {
            label: { fieldName: 'status' },
            variant: 'base',
            name: 'open-pending-reason'
        }
    }
];


export const TERR_COLS = [
    
    {
        label: 'Geography',
        fieldName: 'geography',
        sortable: true,
        type: 'text',
        hideDefaultActions : true

    },
    {
        label: 'Region',
        fieldName: 'region',
        sortable: true,
        type: 'text',
        hideDefaultActions : true

    },
    {
        label: 'Area',
        fieldName: 'area',
        sortable: true,
        type: 'text',
        hideDefaultActions : true
    },
    {
        label: 'Zone',
        fieldName: 'zone',
        sortable: true,
        type: 'text',
        hideDefaultActions : true
    },
    {
        label: 'Territory',
        fieldName: 'territory',
        sortable: true,
        type: 'text',
        hideDefaultActions : true

    }

];

export const QUEUE_COLS = [
    {
        label: 'Queue Name',
        fieldName: 'queueName',
        sortable: true,
        type: 'text',
        hideDefaultActions : true
    },
    {
        label: 'Count',
        fieldName: 'queueCount',
        sortable: true,
        type: 'text',
        hideDefaultActions : true

    }
];