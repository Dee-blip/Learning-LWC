// Changes by Vandhana Krishnamurthy for UCD

import { LightningElement,api } from 'lwc';

export default class ScUcdCaseUtilHoursBubbles extends LightningElement
{
    @api utilizedHours;
    @api billableHours;
    @api nonbillableHours;
    @api internalHours;
    @api billableHoursClass;
    billableHoursTitle;

    connectedCallback()
    {
        if(this.billableHoursClass)
        {
            if(this.billableHoursClass.includes('yellowBubble'))
            {
                this.billableHoursTitle = 'Reaching LOE'
            }
            else if(this.billableHoursClass.includes('redBubble'))
            {
                this.billableHoursTitle = 'Overdone LOE'
            }
            else if(this.billableHoursClass.includes('darkGreyBubble'))
            {
                this.billableHoursTitle = 'Billable'
            }
        }
    }
}