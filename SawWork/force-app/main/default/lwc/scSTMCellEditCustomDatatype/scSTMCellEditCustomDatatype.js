import LightningDatatable from 'lightning/datatable';

import importedCellEditTemplate from './scSTMCellEditTemplate.html';
import importedBubblesTemplate from './scSTMEmpBubblesTemplate.html';

export default class ScSTMCellEditCustomDatatype extends LightningDatatable {
    static customTypes = {
        cellEdit: {
            template: importedCellEditTemplate,
            typeAttributes: ['context', 'supportTeamSkill', 'firstName', 'lastName', 'login', 'team']
        },
        empBubbles: {
            template: importedBubblesTemplate,
            typeAttributes: ['teamsPrimary','teamsSecondary','teamsOthers','accountsPrimary','accountsSecondary']
        }
    };
}