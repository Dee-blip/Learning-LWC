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
}
    ,
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
    label: 'Status',
    fieldName: 'status',
    sortable: true,
    type: 'text',
    initialWidth: 80,
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
    initialWidth: 50
},
{
    label: 'Age',
    fieldName: 'age',
    sortable: true,
    type: 'number',
    initialWidth: 50

},
{
    label: 'Area',
    fieldName: 'area',
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
    label: 'Case Status',
    fieldName: 'case_status',
    sortable: true,
    type: 'text',
    initialWidth: 80
},

{
    type: 'action',
    typeAttributes: { rowActions: 
        [
            { label: 'Add LOE', name: 'add_loe' },
           { label: 'New External Team', name: 'new_ext_team' }

        ],
        menuAlignment: 'right'

    }
}

];