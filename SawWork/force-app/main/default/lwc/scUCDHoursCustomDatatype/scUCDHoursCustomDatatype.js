// Changes by Vandhana Krishnamurthy for UCD

import LightningDatatable from 'lightning/datatable';

import importedHTMLTemplate from './scUCDUtilHoursTemplate.html';
import importedAKAMCaseIdTemplate from './scUCDAKAMCaseIDTemplate.html';

export default class ScUCDHoursCustomDatatype extends LightningDatatable 
{
    static customTypes = 
    {
        hoursDatatype: {
            template: importedHTMLTemplate,
            typeAttributes: ['utilizedHours','billableHours','nonbillableHours','internalHours','billableHoursClass'],
        },
        akamCaseIDDatatype:
        {
            template: importedAKAMCaseIdTemplate,
            typeAttributes: ['userNameRole','akamCaseId','caseUrl','userNameRoleUrl']
        }
    };
}