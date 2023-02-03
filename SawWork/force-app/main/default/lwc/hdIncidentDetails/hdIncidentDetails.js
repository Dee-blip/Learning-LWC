import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getClientIncidentData from '@salesforce/apex/HD_DetailControllerUtils.getClientIncidentData';
export default class HdIncidentDetails extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objType;
    showResolution = true;
    showDescription = true;
    isLoading = true;
    isIncident = false;
    isResolution = false;
    srType = 'Service Request';
    @track wiredResponse;

    @api fireRefresh() {
        // this.isLoading = true;
        refreshApex(this.wiredResponse);
    }

    @wire(getClientIncidentData, { recordId: '$recordId' })
    getClientIncidentDetail(result) {
        this.wiredResponse = result;
        if (result?.data) {
            if (result.data.BMCServiceDesk__Type__c === 'Incident') {
                this.isIncident = true;
                this.srType = result.data.BMCServiceDesk__Type__c;
            }
            if (result.data.BMCServiceDesk__incidentResolution__c) {
                this.isResolution = true;
            }
            this.isLoading = false;
        }
        else if (result?.error) {
            this.isLoading = false;
            window.console.log('Error in getClientIncidentDetail>> ' + JSON.stringify(result.error));
        }
    }
    handleDescriptionChevron() {
        this.showDescription = !this.showDescription;
    }
    handleResolutionChevron() {
        this.showResolution = !this.showResolution;
    }
    get backgroundStyle() {
        return 'background-image: url(' + this.photoUrl + ')';
    }
}