export const ESC_COLS = [
    {
        label: 'Escalation Name',
        fieldName: 'escURL',
        initialWidth: 110,
        sortable: true,
        type: 'button', 
        typeAttributes: 
        { label: { fieldName: 'akam_esc_id' },             
        variant: 'base',
        name: 'OpenEscURL'
        }
    },
{
    label: 'Account',
    fieldName: 'account',
    sortable: true,
    type: 'text'
},
{
    label: 'Description',
    fieldName: 'description',
    type: 'text'
},
{
    label: 'Support Level', fieldName: 'support_level', type: 'text', sortable: true

},
{
    label: 'Geography',
    fieldName: 'geography',
    sortable: true,
    type: 'text',
    cellAttributes: { class: { fieldName: 'GeographyColor' } }
},
{
    label: 'Severity',
    fieldName: 'sev',
    sortable: true,
    type: 'text',
    initialWidth: '50'
},
{
    label: 'SLA',
    fieldName: 'SLAEsc',
    sortable: true,
    type: 'text',
    cellAttributes: { class: { fieldName: 'SLA_Color' } }
},
{
    label: 'Target Shift',
    fieldName: 'targetshift',
    sortable: true,
    type: 'text'
},
{
    label: 'Age',
    fieldName: 'age',
    sortable: true,
    type: 'number',
    initialWidth: 50

},
{
    label: 'Case Product',
    fieldName: 'product',
    sortable: true,
    type: 'text'
},
{
    label: 'AKAM Case ID',
    fieldName: 'caseURL',
    sortable: true,
    type: 'url',
    initialWidth: 80,
   typeAttributes: { label: { fieldName: 'akam_case_id' }, target: '_self' }

},
{
    label: 'Case Owner',
    fieldName: 'case_owner',
    sortable: true,
    type: 'text'
},
{
    label: 'Esc Queue',
    fieldName: 'esc_owner',
    sortable: true,
    type: 'text'
},

{
    type: 'action',
    typeAttributes: { rowActions: 
        [
            { label: 'Accept', name: 'accept' }
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