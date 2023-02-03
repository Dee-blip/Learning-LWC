import { LightningElement, api, track } from 'lwc';

export default class Hd_cmr_Blackout_Moratorium extends LightningElement {
    @api recordId;
    @api variant;
    @api serviceoutageblackout;
    @api serviceoutagemoratorium;
    @api changestartdate;
    title;
    viewMore;
    displayTooltip;
    alternativeText;
    whenCreated;
    styleClass;
    @track getServiceOuatgeValues;
    @track values;

    get when() {
        let beforeOrDuring = 'This CMR ';
        beforeOrDuring = beforeOrDuring.concat(this.whenCreated);
        return beforeOrDuring
    }

    onMouseOverAdditionalInfo() {
        this.displayTooltip = true;
        if(this.variant === 'standard:incident') {
            this.title = 'Blackout Details';
            this.viewMore = 'View More Blackout Details';
            this.alternativeText = 'Running Blackout';
            this.whenCreated = 'was created before Blackout';
            this.getServiceOuatgeValues = this.serviceoutageblackout;
            this.styleClass = 'slds-popover__header specialBlackout';
        }
        else if(this.variant === 'standard:scheduling_constraint') {
            this.title = 'Moratorium Details';
            this.viewMore = 'View More Moratorium Details';
            this.alternativeText = 'Running Moratorium';
            this.getServiceOuatgeValues = this.serviceoutagemoratorium;
            this.styleClass = 'slds-popover__header specialMoratorium';

            for(let key in this.serviceoutagemoratorium) {
                if(this.changestartdate < this.serviceoutagemoratorium[key].BMCServiceDesk__Start_Date__c) {
                    this.whenCreated = 'was created before Moratorium';
                }
                else if(this.changestartdate >= this.serviceoutagemoratorium[key].BMCServiceDesk__Start_Date__c) {
                    this.whenCreated = 'was created during Moratorium';
                }
            }
        }
    }

    onCloseButtonClick() {
        this.displayTooltip = false;
    }
}