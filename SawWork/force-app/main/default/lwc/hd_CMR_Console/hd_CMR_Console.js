import { LightningElement, wire} from 'lwc';
import getUserType from '@salesforce/apex/HD_CMR_ChangeCalendar.getUserType';
import { NavigationMixin } from 'lightning/navigation';

export default class Hd_CMR_Console extends NavigationMixin(LightningElement) {
    showCalendarView = true;
    showListsView = false;
    showSOView = false;
    isCABManager = false;
    showCMR = true;
    calBrand = 'brand';
    listBrand = 'neutral';
    soBrand = 'neutral';
    
    @wire(getUserType)
    getUserQueue(result) {
        if (result.data) {
            if( result.data.includes('CAB')){
                this.isCABManager = true;
            }
        }
    }

    showCreateForm() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'BMCServiceDesk__Change_Request__c',
                actionName: 'new'
            }
        });
    }

    showCalView() {
        this.calBrand = 'brand';
        this.listBrand = 'neutral';
        this.soBrand = 'neutal';
        this.showCalendarView = true;
        this.showListsView = false;
        this.showSOView = false;
        this.showCMR = true;
    }

    showListView() {
        this.calBrand = 'neutal';
        this.listBrand = 'brand';
        this.soBrand = 'neutal';
        this.showCalendarView = false;
        this.showListsView = true;
        this.showSOView = false;
        this.showCMR = true;
    }

    showServiceOutage() {
        this.calBrand = 'neutral';
        this.listBrand = 'neutral';
        this.soBrand = 'brand';
        this.showCalendarView = false;
        this.showListsView = false;
        this.showSOView = true;
        this.showCMR = false;
    }
}