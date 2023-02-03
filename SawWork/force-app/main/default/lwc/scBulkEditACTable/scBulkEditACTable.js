import LightningDatatable from 'lightning/datatable';
import scMultiSelect from './scMultiSelect.html';

export default class ScBulkEditACTable extends LightningDatatable {
     static customTypes = {
          scMultiSelect: {
               template: scMultiSelect,
               typeAttributes: ['authContactId', 'productInterestSelected']
          }
     };
}