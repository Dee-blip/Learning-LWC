// COLUMNS FOR TSC TEAM
export const MY_OPEN_COLS =
[
    {
        label: 'Case (Creator)',
        type: 'akamCaseIDDatatype',
        initalWidth: 80,
        sortable: true,
        fieldName: 'akamCaseIdText',
        typeAttributes:
    {
            userNameRole: { fieldName: 'userNameRole' },
            akamCaseId: { fieldName: 'akamCaseId' },
            caseUrl: { fieldName: 'caseUrl' },
            userNameRoleUrl: { fieldName: 'userNameRoleUrl' }
        },
        wrapText: true
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        sortable: true,
        type: 'text',
        initialWidth: 40
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        type: 'url', 
        typeAttributes: { label: { fieldName: 'accountName' }, tooltip: 'Go to Account', target: '_blank' },
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'subject',
        type: 'text',
        sortable: true,
        initialWidth: 250,
        wrapText: true,
        typeAttributes: {tooltip: { fieldName:'subject'}, title: {fieldName:'subject'}}
    },
    {
        label: 'LOE',
        fieldName: 'caseloe',
        sortable: true,
        initialWidth: 40,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'caseloe' },
            variant: 'base',
            name: 'caseloe',
            title: 'Click to change LOE'
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText'}
    },
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'reqCompletionDate' },
            variant: 'base',
            name: 'reqCompletionDate',
            title: 'Click to change Requested Completion Date'
        },
        cellAttributes: { alignment: 'left', class: { fieldName: 'reqCompletionDateColour' }} 
    },
    {
        label: 'Age (Days)',
        fieldName: 'ageDays',
        sortable: true,
        initialWidth: 50,
        type: 'number',
        cellAttributes: { alignment: 'left'}
    },
    /*
    {
        label: 'Utilized Hours',
        fieldName: 'utilizedHours',
        sortable: true,
        type: 'number'
    },*/
    {
        label: 'Utilized Hours',
        fieldName: 'utilizedHours',
        type: 'hoursDatatype',
        initialWidth: 120,
        typeAttributes:
        {
            utilizedHours: { fieldName: 'utilizedHours' },
            billableHours: { fieldName: 'billableHours' },
            nonbillableHours: { fieldName: 'nonbillableHours' },
            internalHours: { fieldName: 'internalHours' },
            billableHoursClass: { fieldName: 'billableHoursClass' }
        }
    },
    {
        label: 'Next Planned Activity Date',
        fieldName: 'nextPlannedActivityDate',
        sortable: true,
        initialWidth: 100,
        type: 'text'
    },
    {
        label: 'Living Summary',
        fieldName: 'livingSummary',
        sortable: false,
        wrapText: true,
        type: 'button',
        initialWidth: 300,
        typeAttributes:
        {
            label: { fieldName: 'livingSummaryConcat' },
            variant: 'base',
            name: 'livingSummaryConcat',
            title: { fieldName: 'livingSummaryTop3' }
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText leftAlign' }
    },
    {
        label: 'Update',
        fieldName: '',
        sortable: false,
        type: 'button-icon',
        fixedWidth: 60,
        typeAttributes:
        {
            label: 'New Timecard',
            variant: 'brand',
            iconName:"utility:record_update",
            name: 'caseTimecardUpdate',
            title: 'Click to Update Case and Timecard'
        },
        cellAttributes: { alignment: 'center'}
    },
    {
        label: 'Close',
        fieldName: '',
        sortable: false,
        type: 'button-icon',
        fixedWidth: 60,
        typeAttributes:
        {
            label: 'Close Case',
            variant: 'error',
            iconName:"utility:close",
            name: 'closecase',
            title: 'Click to Close Case'
        },
        cellAttributes: { alignment: 'center'}
    }
    /*
    ,
    {
        type: 'action',
        typeAttributes:
        {
            rowActions: [
                { label: 'Close Case', name: 'closecase' },
                /*
                { label: 'Clone', name: 'clonecase' },
                { label: 'Clone on Multiple Accounts', name: 'multiclonecase' },
                { label: 'Edit', name: 'editcase' },
                { label: 'Acknowledge Case', disabled: {fieldName: 'disableCaseAckButton'}}
            ],
            menuAlignment: 'right'
        }
    }
    */
];

// COLUMNS FOR GS2 TEAM
export const MY_OPEN_COLS_GS2 =
[
    {
        label: 'Acknowledge',
        fieldName: '',
        sortable: false,
        type: 'button-icon',
        initialWidth: 40,
        title: 'Acknowledge Case',
        typeAttributes:
        {
            label: 'Acknowledge Case',
            variant: 'neutral',
            iconName: {fieldName: 'caseAckButtonIcon'},
            size: 'x-small',
            name: 'ackcase',
            title: 'Click to acknowledge this Case',
            tooltip: 'Click to acknowledge this Case',
            disabled: {fieldName: 'disableCaseAckButton'},
        },
        cellAttributes: { alignment: 'center', class: {fieldName: 'caseAckButtonBgClass'}}
    },
    {
        label: 'AKAM Case Id',
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "caseUrl",
        typeAttributes: {
            label: {
                fieldName: "akamCaseId"
            },
            tooltip: "Go To Case",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: "Creator",
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "userNameRoleUrl",
        typeAttributes: {
            label: {fieldName: "userNameRole"},
            tooltip: "Go To User",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        sortable: true,
        type: 'text',
        initialWidth: 40
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        initialWidth: 200,
        type: 'url', 
        typeAttributes: { label: { fieldName: 'accountName' }, tooltip: 'Go to Account', target: '_blank' },
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'subject',
        title: { fieldName:'subject'},
        type: 'text',
        sortable: true,
        initialWidth: 200,
        wrapText: true
    },
    {
        label: 'LOE',
        fieldName: 'caseloe',
        sortable: true,
        initialWidth: 40,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'caseloe' },
            variant: 'base',
            name: 'caseloe',
            title: 'Click to change LOE'
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText'}
    },
    /*
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'text',
        cellAttributes: { class: { fieldName: 'reqCompletionDateColour' } }
    },*/
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'reqCompletionDate' },
            variant: 'base',
            name: 'reqCompletionDate',
            title: 'Click to change Requested Completion Date'
        },
        cellAttributes: { alignment: 'left', class: { fieldName: 'reqCompletionDateColour' }} 
    },
    {
        label: 'Age (Days)',
        fieldName: 'ageDays',
        sortable: true,
        initialWidth: 50,
        type: 'number',
        cellAttributes: { alignment: 'left'}
    },
    {
        label: 'Utilized Hours',
        fieldName: 'utilizedHours',
        type: 'hoursDatatype',
        initialWidth: 120,
        typeAttributes:
        {
            utilizedHours: { fieldName: 'utilizedHours' },
            billableHours: { fieldName: 'billableHours' },
            nonbillableHours: { fieldName: 'nonbillableHours' },
            internalHours: { fieldName: 'internalHours' },
            billableHoursClass: { fieldName: 'billableHoursClass' }
        }
    },
    {
        label: 'Next Planned Activity Date',
        fieldName: 'nextPlannedActivityDate',
        sortable: true,
        initialWidth: 100,
        type: 'text'
    },
    {
        label: 'Living Summary',
        fieldName: 'livingSummary',
        sortable: false,
        wrapText: true,
        type: 'button',
        initialWidth: 300,
        typeAttributes:
        {
            label: { fieldName: 'livingSummaryConcat' },
            variant: 'base',
            name: 'livingSummaryConcat',
            title: { fieldName: 'livingSummaryTop3' }
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText leftAlign' }
    },
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        initialWidth: 100,
        type: 'text',
        wrapText: true
    },
    {
        label: 'Update',
        fieldName: '',
        sortable: false,
        type: 'button-icon',
        fixedWidth: 80,
        typeAttributes:
        {
            label: 'New Timecard',
            variant: 'brand',
            iconName:"utility:record_update",
            name: 'caseTimecardUpdate',
            title: 'Click to Update Case and Timecard'
        },
        cellAttributes: { alignment: 'center'}
    },
    {
        type: 'action',
        typeAttributes:
        {
            rowActions: [
                { label: 'Edit', name: 'editcase' },
                { label: 'Close Case', name: 'closecase' },
                { label: 'Clone', name: 'clonecase' },
                { label: 'Clone on Multiple Accounts', name: 'multiclonecase' }
                //,{ label: 'Acknowledge Case', disabled: {fieldName: 'disableCaseAckButton'}}
            ],
            menuAlignment: 'right'
        }
    }
];

export const MY_CREATED_COLS =
[
    {
        label: 'AKAM Case Id',
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "caseUrl",
        typeAttributes: {
            label: {
                fieldName: "akamCaseId"
            },
            tooltip: "Go To Case",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: "Owner",
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "userNameRoleUrl",
        typeAttributes: {
            label: {fieldName: "userNameRole"},
            tooltip: "Go To User",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        sortable: true,
        type: 'text',
        initialWidth: 40
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        initialWidth: 250,
        type: 'url', typeAttributes: { label: { fieldName: 'accountName' }, tooltip: 'Go to Account', target: '_blank' },
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'subject',
        title: { fieldName:'subject'},
        type: 'text',
        sortable: true,
        wrapText: true
    },
    {
        label: 'LOE',
        fieldName: 'caseloe',
        sortable: true,
        initialWidth: 40,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'caseloe' },
            variant: 'base',
            name: 'caseloe',
            title: 'Click to change LOE'
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText'}
    },
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'reqCompletionDate' },
            variant: 'base',
            name: 'reqCompletionDate',
            title: 'Click to change Requested Completion Date'
        },
        cellAttributes: { alignment: 'left', class: { fieldName: 'reqCompletionDateColour' }} 
    },
    {
        label: 'Age (Days)',
        fieldName: 'ageDays',
        sortable: true,
        initialWidth: 50,
        type: 'number',
        cellAttributes: { alignment: 'left'}
    },
    {
        label: 'Utilized Hours',
        fieldName: 'utilizedHours',
        type: 'hoursDatatype',
        initalWidth: 120,
        typeAttributes:
        {
            utilizedHours: { fieldName: 'utilizedHours' },
            billableHours: { fieldName: 'billableHours' },
            nonbillableHours: { fieldName: 'nonbillableHours' },
            internalHours: { fieldName: 'internalHours' },
            billableHoursClass: { fieldName: 'billableHoursClass' }
        }
    },
    {
        label: 'Next Planned Activity Date',
        fieldName: 'nextPlannedActivityDate',
        sortable: true,
        initialWidth: 100,
        type: 'text'
    },
    {
        label: 'Living Summary',
        fieldName: 'livingSummary',
        sortable: false,
        wrapText: true,
        type: 'button',
        initialWidth: 300,
        typeAttributes:
        {
            label: { fieldName: 'livingSummaryConcat' },
            variant: 'base',
            name: 'livingSummaryConcat',
            title: { fieldName: 'livingSummaryTop3' }
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText leftAlign' }
    },
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        initialWidth: 100,
        type: 'text',
        wrapText: true,
    },
    {
        label: 'Update',
        fieldName: '',
        sortable: false,
        type: 'button-icon',
        fixedWidth: 80,
        typeAttributes:
        {
            label: 'New Timecard',
            variant: 'brand',
            iconName:"utility:record_update",
            name: 'caseTimecardUpdate',
            title: 'Click to Update Case and Timecard'
        },
        cellAttributes: { alignment: 'center'}
    },
    {
        type: 'action',
        typeAttributes:
        {
            rowActions: [
                { label: 'Edit', name: 'editcase' },
                { label: 'Close Case', name: 'closecase' },
                { label: 'Clone', name: 'clonecase' },
                { label: 'Clone on Multiple Accounts', name: 'multiclonecase' },
            ],
            menuAlignment: 'right'
        }
    }
];

export const MY_TEAM_COLS =
[
    {
        label: 'AKAM Case Id',
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "caseUrl",
        typeAttributes: {
            label: {
                fieldName: "akamCaseId"
            },
            tooltip: "Go To Case",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: "Owner",
        type: 'url',
        initialWidth: 80,
        sortable: true,
        fieldName: "userNameRoleUrl",
        typeAttributes: {
            label: {fieldName: "userNameRole"},
            tooltip: "Go To User",
            target: "_blank"
        },
        wrapText: true
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        sortable: true,
        type: 'text',
        initialWidth: 70
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        initialWidth: 300,
        type: 'url', typeAttributes: { label: { fieldName: 'accountName' }, tooltip: 'Go to Account', target: '_blank' },
        wrapText: true
    },
    {
        label: 'Subject',
        fieldName: 'subject',
        title: { fieldName:'subject'},
        type: 'text',
        sortable: true,
        initialWidth: 300,
        wrapText: true
    },
    {
        label: 'LOE',
        fieldName: 'caseloe',
        sortable: true,
        initialWidth: 40,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'caseloe' },
            variant: 'base',
            name: 'caseloe',
            title: 'Click to change LOE'
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText'}
    },
    {
        label: 'Requested Completion Date',
        fieldName: 'reqCompletionDate',
        sortable: true,
        initialWidth: 100,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'reqCompletionDate' },
            variant: 'base',
            name: 'reqCompletionDate',
            title: 'Click to change Requested Completion Date'
        },
        cellAttributes: { alignment: 'left', class: { fieldName: 'reqCompletionDateColour' }} 
    },
    {
        label: 'Age (Days)',
        fieldName: 'ageDays',
        sortable: true,
        initialWidth: 50,
        type: 'number',
        cellAttributes: { alignment: 'left'}
    },
    {
        label: 'Utilized Hours',
        fieldName: 'utilizedHours',
        type: 'hoursDatatype',
        initialWidth: 120,
        typeAttributes:
        {
            utilizedHours: { fieldName: 'utilizedHours' },
            billableHours: { fieldName: 'billableHours' },
            nonbillableHours: { fieldName: 'nonbillableHours' },
            internalHours: { fieldName: 'internalHours' },
            billableHoursClass: { fieldName: 'billableHoursClass' }
        }
    },
    {
        label: 'Next Planned Activity Date',
        fieldName: 'nextPlannedActivityDate',
        sortable: true,
        initialWidth: 100,
        type: 'text'
    },
    {
        label: 'Living Summary',
        fieldName: 'livingSummary',
        sortable: false,
        wrapText: true,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'livingSummaryConcat' },
            variant: 'base',
            name: 'livingSummaryConcat',
            title: { fieldName: 'livingSummaryTop3' }
        },
        cellAttributes: { alignment: 'left', class: 'escBlueText leftAlign' }
    },
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        initialWidth: 100,
        type: 'text',
        wrapText: true,
    }
];