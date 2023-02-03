import LightningDatatable from 'lightning/datatable';

import importedCellEditTemplate from './scSICellEditTemplate.html';


export default class scSICellEditCustomDatatype extends LightningDatatable {
    static customTypes = {
        cellEdit: {
            template: importedCellEditTemplate,
            typeAttributes: ['title']
        }
    };
}