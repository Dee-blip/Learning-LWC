import LightningDatatable from 'lightning/datatable';
import richTextColumnTemplate from './richTextColumnTemplate';

export default class CustomLwcDatatable extends LightningDatatable {
    static customTypes = {
        richText: {
            template: richTextColumnTemplate,
            standardCellLayout: true,
            typeAttributes: [''],
        }
    }
}