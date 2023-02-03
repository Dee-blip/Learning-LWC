export const SI_COLS = [
    {
    label: 'SI No',
    fieldName: 'siURL',
    initialWidth: 110,
    sortable: true,
    type: 'url', typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
}
    ,
{
    label: 'Category',
    fieldName: 'siCategoryID',
    sortable: true,
    type: 'text'
},
{
    label: 'Title',
    fieldName: 'servicereqtitle',
    type: 'text'
},

{
    label: 'Severity', fieldName: 'fkimpact', type: 'text', sortable: true
},
{
    label: 'Status',
    fieldName: 'fkstatus',
    sortable: true,
    type: 'text',
},
{
    label: 'Business Information Lead',
    fieldName: 'gssmanager',
    sortable: true,
    type: 'text'
},
{
    label: 'Impact Started',
    fieldName: 'outagestartdate',
    sortable: true,
    type: 'date', 
    typeAttributes: 
    {  
        day: 'numeric',  
        month: 'short',  
        year: 'numeric',  
        hour: '2-digit',  
        minute: '2-digit',  
        second: '2-digit',  
        hour12: true
    }
}

];