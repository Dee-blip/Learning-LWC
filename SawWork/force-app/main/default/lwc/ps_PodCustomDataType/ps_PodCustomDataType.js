import LightningDatatable from 'lightning/datatable';
import importedCheckboxTemplate from './ps_PODCustomCheckboxTemplate.html';



export default class Ps_PodCustomDataType extends LightningDatatable {
    static customTypes = {
        checkboxCell: {
            template: importedCheckboxTemplate,
            typeAttributes: ['isSelected','accountId','accDeptId']
        }
    };

}