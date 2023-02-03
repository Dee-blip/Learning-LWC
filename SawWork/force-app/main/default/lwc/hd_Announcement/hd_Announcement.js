import { LightningElement, wire, track, api } from 'lwc';
import getActiveAnnouncement from '@salesforce/apex/HD_AnnouncementController.getActiveAnnouncement';
import getAnnouncementFeatures from '@salesforce/apex/HD_AnnouncementController.getAnnouncementFeatures';
import saveUserAnnouncement from '@salesforce/apex/HD_AnnouncementController.saveUserAnnouncement';
import getGlobalActiveAnnouncement from '@salesforce/apex/HD_AnnouncementController.getGlobalActiveAnnouncement';
import { CurrentPageReference } from 'lightning/navigation';
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';

export default class Hd_Announcement extends LightningElement {

    showModal = false; 
    @track announcement;
    @track features = [];
    showFeatureList = true; 
    selectedFeature; 
    hideAnnouncement = false;
    cookieAnnouncementIds = [];
    @api objectApiName;
    pageType;
    currentPageReference = null;
    

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference) {
           this.pageType = currentPageReference.type;
           this.getCookies();
           this.getGlobalAnnouncement();
        }
    }

    getGlobalAnnouncement(){
        getGlobalActiveAnnouncement({ 
            cookieAnnouncementIds : this.cookieAnnouncementIds 
        })
        .then((result) => {
            this.announcement = result;
            if(this.announcement === null)
                this.getOtherAnnouncement();
        })
        .catch(error => {
            console.log('Hd_Announcement.getGlobalAnnouncement : ' + error);
            this.logError('Hd_Announcement.getGlobalAnnouncement : ' + JSON.stringify(error));
        });
    }

    getOtherAnnouncement() {
        getActiveAnnouncement({ 
            cookieAnnouncementIds : this.cookieAnnouncementIds,
            pageType : this.pageType, 
            objectName : this.objectApiName
        })
        .then((result) => {
            this.announcement = result;
        })
        .catch(error => {
            console.log('Hd_Announcement.getOtherAnnouncement : ' + error);
            this.logError('Hd_Announcement.getOtherAnnouncement : ' + JSON.stringify(error));
        });
    }

    @wire(getAnnouncementFeatures, { parentId : '$announcement.Id' })
    wiredFeatures(result) {
        if(result.data){
            this.features = result.data;
            this.openModal();
        }
        else if(result.error) {
            console.log('Hd_Announcement.wiredFeatures : ' + result.error);
            this.logError('Hd_Announcement.wiredFeatures : ' + JSON.stringify(result.error));
        }
    }

    saveUser(hide) {
        saveUserAnnouncement({ 
            announcementId: this.announcement.Id, 
            hideAnnouncement: hide 
        });
    }

    get adjustHeight() {
       return 'height:' + 525/this.features.length + 'px;';
    }

    openModal() {   
        if(this.features.length) {
            this.showModal = true; 
            this.saveUser(false);
            this.setCookie();
        }
    }
       
    closeModal() {
        if(this.hideAnnouncement) {
            this.saveUser(true);
        }
        this.showModal = false;
    }

    showDetails(event) {
        this.selectedFeature = this.features.find(ele => ele.Id === event.currentTarget.dataset.id);
        this.showFeatureList = false;
    }

    hideDetails() {
        this.showFeatureList = true;
    }

    toggleShowAgain(event) {
        this.hideAnnouncement = event.target.checked;
    }

    setCookie() {
        var name = 'AnnouncementId_'+ this.announcement.Id;
        let date = new Date();
        date.setTime(date.getTime() + (24 * 60 * 60 * 1000));
        let expires = '; expires=' + date.toGMTString();
        document.cookie = name + '=' + escape(this.announcement.Id) + expires + '; path=/';
    }

    getCookies() {
        var keyValuePairs = document.cookie.split(';');
        for(let i = 0; i < keyValuePairs.length; i++) {
            let name = keyValuePairs[i].substring(0, keyValuePairs[i].indexOf('='));
            let value = keyValuePairs[i].substring(keyValuePairs[i].indexOf('=')+1);
            if(name.indexOf('AnnouncementId_') !== -1) {
                this.cookieAnnouncementIds.push(value);
            }
        }
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: this.recordId
        });
    }

}