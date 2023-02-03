import LightningElement  from 'lightning/datatable';
import richtextarea from './richtextareaTemplete.html';
import scMultiSelect from './scMultiSelect.html';

export default class ScCustomDatatable extends LightningElement {
    static customTypes = {
        richtextarea: {
            template: richtextarea,
            typeAttributes: ['richtextareaValue']
        },
        scMultiSelect: {
            template: scMultiSelect,
            typeAttributes: ['authContactId', 'productInterestSelected']
       }
    };
    /*static customTypes = {
        scMultiSelect: {
             template: scMultiSelect,
             typeAttributes: ['authContactId', 'productInterestSelected']
        }
   };*/
}