/* eslint-disable no-eval */
import {
    LightningElement,
    wire,
    api,
    track
} from 'lwc';
import {
    NavigationMixin
} from 'lightning/navigation';
import {
    refreshApex
} from '@salesforce/apex';
import getChange from '@salesforce/apex/HD_CMR_ChangeCalendar.getChange';
import getApprovalHistory from '@salesforce/apex/HD_CMR_ChangeCalendar.getApprovalHistory';
import matchingServiceOutage from '@salesforce/apex/HD_CMR_BlackoutPeriod.matchingServiceOutage';
import {
    subscribe,
    unsubscribe,
    onError
} from 'lightning/empApi';

export default class Hd_CMR_Highlight_Panel extends NavigationMixin(LightningElement) {
    @api recordId;
    @track values;
    @track wiredResponse;
    @track wiredResponse2;
    @track approvalList = [];
    change;
    changeName;
    changeStartDate;
    showApproval;
    statusclass;
    changeStatus;
    subscription;
    listOfActionsDisplay;
    cssClass;
    blackoutSO = false;
    moratoriumSO = false;
    variant;
    whenCreated;
    title;
    styleClass;
    serviceOutageTitle;
    serviceOutageInfo;
    serviceOutageDetailToShow;
    getServiceOuatgeValues;
    showAdditionalInfo = false;
    serviceOutageBlackout = [];
    serviceOutageMoratorium = [];
    isOpen;
    isLoading = true;
    channelName = '/event/CMR_Approval_Status_Event__e';

    connectedCallback() {
        // Register error listener     
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    @api fireRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredResponse);
        refreshApex(this.wiredResponse2);
        refreshApex(this.wiredResponse3);
    }

    @wire(matchingServiceOutage, {
        currentCMR: '$change'
    })
    getServiceOutageDetails(result) {
        this.wiredResponse3 = result;
        if (result.data) {
            for (let key in result.data) {
                if (result.data[key].BMCServiceDesk__Blackout__c === true) {
                    this.blackoutSO = true;
                    this.moratoriumSO = false;
                    this.variant = 'standard:incident';
                    this.serviceOutageBlackout.push(result.data[key]);
                    this.showAdditionalInfo = true;
                    this.whenCreated = 'was created before Blackout';
                    this.getServiceOuatgeValues = this.serviceOutageBlackout;
                    this.styleClass = 'slds-notify slds-notify_alert blackoutToast';
                    this.serviceOutageTitle = 'Running Blackout';
                } else if (result.data[key].Service_Outage_Type__c !== '' && this.blackoutSO !== true) {
                    this.moratoriumSO = true;
                    this.serviceOutageMoratorium.push(result.data[key]);
                    this.variant = 'standard:scheduling_constraint';
                    this.showAdditionalInfo = true;
                    this.getServiceOuatgeValues = this.serviceOutageMoratorium;
                    this.styleClass = 'slds-notify slds-notify_alert moratoriumToast';
                    this.serviceOutageTitle = 'Running Moratorium';
                }
            }
            this.isLoading = false;
            if(this.getServiceOuatgeValues){
                let serviceOutageFirstRec = this.getServiceOuatgeValues[0];
                let serviceOutageDetailToShowJson = [{
                        "key": this.serviceOutageTitle,
                        "value": serviceOutageFirstRec.Name,
                        "isText": true
                    },
                    {
                        "key": (this.serviceOutageTitle).includes("Blackout") ? "Blackout Start Date" : "Moratorium Start Date",
                        "value": serviceOutageFirstRec.BMCServiceDesk__Start_Date__c,
                        "isText": false
                    },
                    {
                        "key": (this.serviceOutageTitle).includes("Blackout") ? "Blackout End Date" : "Moratorium End Date",
                        "value": serviceOutageFirstRec.BMCServiceDesk__End_Date__c,
                        "isText": false
                    }
                ];
                this.serviceOutageDetailToShow = serviceOutageDetailToShowJson;
            }
            if (this.variant === 'standard:scheduling_constraint') {
                this.title = 'Moratorium Details';
                this.getServiceOuatgeValues = this.serviceOutageMoratorium;

                for (let key in this.serviceOutageMoratorium) {
                    if (this.changeStartDate < this.serviceOutageMoratorium[key].BMCServiceDesk__Start_Date__c) {
                        this.whenCreated = 'was created before Moratorium';
                    } else if (this.changeStartDate >= this.serviceOutageMoratorium[key].BMCServiceDesk__Start_Date__c) {
                        this.whenCreated = 'was created during Moratorium';
                    }
                }
            }
            let beforeOrDuring = 'This CMR ';
            this.serviceOutageInfo = beforeOrDuring.concat(this.whenCreated);
        } else if (result.error) {
            this.isLoading = false;
        }
    }

    @wire(getChange, {
        Id: '$recordId'
    })
    getChangeDetails(result) {
        this.wiredResponse2 = result;
        if (result.data) {
            this.change = result.data;
            this.changeName = result.data.Name;
            this.changeStartDate = result.data.BMCServiceDesk__Scheduled_Start_Date__c;
            if (result.data.HD_Change_Status__c !== 'OPENED' && result.data.HD_Change_Status__c !== 'CANCELLED' && result.data.CR_Approval_Status__c !== 'Recalled') {
                this.showApproval = true;
            }
            this.changeStatus = result.data.HD_Change_Status__c;
            this.statusclass = this.changeStatus.toUpperCase().replace(/ /g, '');
            this.cssClass = "slds-badge " + this.statusclass;

            let metaBeans = [];

            //lableToShow is map of redable message/ lables against the keyValue in json returned from server
            let metaBeansOrder = {
                "BMCServiceDesk__Change_Category__c": "Change Category",
                "Change_Priority__c": "Change Priority",
                "HD_Service_Impacted__c": "Service Impacted",
                "BMCServiceDesk__Scheduled_Start_Date__c": "No.of Days",
                "HD_Change_Status__c": "Status"
            };
            for (let key in metaBeansOrder) {
                if (result.data[key]) {
                    let temp = {};
                    temp.label = metaBeansOrder[key];
                    temp.key = result.data[key];
                    if (key === 'HD_Change_Status__c') {
                        temp.isText = true;
                        temp.class = this.cssClass;
                    } else if (key === 'BMCServiceDesk__Scheduled_Start_Date__c') {
                        temp.isIcon = true;
                        temp.iconName = 'utility:clock';
                        const today = new Date();
                        const cmrStartDate = new Date(result.data[key]);
                        const cmrEndDate = new Date(result.data.BMCServiceDesk__Scheduled_End_Date__c);
                        if (today < cmrStartDate) {
                            temp.label = 'Days to Start';
                            temp.key = this.diffNoOfDays(cmrStartDate, today);
                        } else if (today >= cmrStartDate && today <= cmrEndDate) {
                            temp.label = 'Running Days';
                            temp.key = this.diffNoOfDays(today, cmrStartDate);
                        } else {
                            temp.label = 'Elapsed Days';
                            temp.key = this.diffNoOfDays(today, cmrEndDate);
                        }
                    } else {
                        temp.isText = true;
                        temp.class = "float-left slds-m-top_x-small " + key + " " + result.data[key];
                    }
                    metaBeans.push(temp);
                }
            }
            this.values = metaBeans;
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
        }
    }

    diffNoOfDays(first, second) {
        return (Math.floor((Date.UTC(first.getFullYear(), first.getMonth(), first.getDate()) - Date.UTC(second.getFullYear(), second.getMonth(), second.getDate())) / (1000 * 60 * 60 * 24)));
    }

    @wire(getApprovalHistory, {
        currentCMRId: '$recordId'
    })
    getApprovalDetails(result) {
        let arrayOfApprovedMapKeys = [];
        let arrayOfRejectedMapKeys = [];
        let arrayOfPendingMapKeys = [];
        let listOFActionsWhichCurrentUserCanPerform = [];
        let tempValue;
        this.wiredResponse = result;
        if (result.data) {
            for (let key in result.data) {
                if (result.data[key]) {
                    tempValue = result.data[key].status;
                    if (tempValue === "Approved" || tempValue === "Submitted") {
                        arrayOfApprovedMapKeys.push(key);
                    } else if (tempValue === "Rejected") {
                        arrayOfRejectedMapKeys.push(key);
                    } else if (tempValue === "listOFActionsWhichCurrentUserCanPerform") {
                        listOFActionsWhichCurrentUserCanPerform = result.data[key].utilityList;
                    } else {
                        arrayOfPendingMapKeys.push(key);
                    }
                }
            }

            if (listOFActionsWhichCurrentUserCanPerform.length > 0) {
                this.listOfActionsDisplay = listOFActionsWhichCurrentUserCanPerform;
            }
            this.approvalList = result?.data;
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
        }
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            if (this.recordId === response.data.payload.Record_ID__c) {
                refreshApex(this.wiredResponse);
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}