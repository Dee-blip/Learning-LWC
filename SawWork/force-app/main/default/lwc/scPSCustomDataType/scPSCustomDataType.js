import LightningDatatable from 'lightning/datatable';

import importedCellEditTemplate from './scPSCustomDataTypeTemplate.html';
import importedCheckboxTemplate from './scPSCustomCheckboxTemplate.html';
import importedTextAreaTemplate from './scPSCustomTextAreaCellTemplate.html';



export default class scPSCustomDataType extends LightningDatatable {
    static customTypes = {
        cellEdit: {
            template: importedCellEditTemplate,
            typeAttributes: ['AccountName','AccountURL','areRecipientsPresent']
        },checkboxCell: {
            template: importedCheckboxTemplate,
            typeAttributes: ['isSelected','MailerName','areRecipientsPresent']
        },textareaCell: {
            template: importedTextAreaTemplate,
            typeAttributes: ['MailerName','DisableReason']
        }

    };
}