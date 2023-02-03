import LightningDataTable from 'lightning/datatable';
import summary_Column_Template from './hd_CMR_Summary_Column.html';
export default class Hd_CMR_Custom_Table extends LightningDataTable {
    showPopOver = false;
    static customTypes = {
        summaryColumn: {
            template: summary_Column_Template,
            standardCellLayout: false
        }
    };
}