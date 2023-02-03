import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import hdQuickActionClick from '@salesforce/messageChannel/hdQuickActionClick__c';
import { refreshApex } from '@salesforce/apex';
import getServiceOutages from '@salesforce/apex/HD_CMR_BlackoutPeriod.getServiceOutages';

export default class HD_CMR_Service_Outages extends NavigationMixin(LightningElement) {

    serviceOutagesList;
    @track upcomingSOs = [];
    @track runningSOs = [];
    @track oldSOs = [];
    dataEle;
    receivedSO;
    @track diffServiceOutages = [];
    @track collectionValues = [];
    @track wiredResponse;
    isLoading = true;
    activeSections = ['Running Service Outages','Upcoming Service Outages'];

    @wire(MessageContext)
    messageContext;

    @api fireRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredResponse);
    }

    fireRefreshSO() {
        this.isLoading = true;
        refreshApex(this.wiredResponse);
    }

    @wire(getServiceOutages)
    getServiceOutages(result) {
        this.wiredResponse = result;
        this.isLoading = true;
        this.diffServiceOutages = [];
        this.upcomingSOs = [];
        this.runningSOs = [];
        this.oldSOs = [];
        if (result.data) {
            this.serviceOutagesList = result.data;
            const today = new Date();
            for(let i = 0 ; i < result.data.length; i++) {
                const soStartDate = new Date(result.data[i].BMCServiceDesk__Start_Date__c);
                const soEndDate = new Date(result.data[i].BMCServiceDesk__End_Date__c);
                let a = [{day: 'numeric'}, {month: 'short'}, {year: 'numeric'}];
                const start = this.join(soStartDate, a, '-');
                const end = this.join(soEndDate, a, '-');
                if (today < soStartDate) {
                    this.upcomingSOs.push({
                        soValue : result.data[i],
                        soIcon : 'active-step',
                        progress : 0,
                        styling : 'slds-is-absolute upcoming',
                        accord : false,
                        expandCollapseIcon : 'utility:chevronright',
                        currentStep : "1",
                        startDate : start,
                        endDate : end
                     });
                }
                else if (today >= soStartDate && today <= soEndDate) {
                    let progPercentage;
                    let sylingProg;
                    progPercentage = Math.floor((this.diffNoOfDays(today,soStartDate) / this.diffNoOfDays(soEndDate,soStartDate))*100);
                    if(progPercentage < 10) {
                        sylingProg = 'slds-is-absolute upcoming';
                    }
                    else if(progPercentage >= 10 && progPercentage < 100) {
                        sylingProg = 'slds-is-absolute running';
                    }
                    else {
                        sylingProg = 'slds-is-absolute complete';
                    }
                    this.runningSOs.push({
                       soValue : result.data[i],
                       soIcon : 'active-step',
                       progress : progPercentage,
                       styling : sylingProg,
                       accord : true,
                       expandCollapseIcon : 'utility:switch',
                       currentStep : "2",
                       startDate : start,
                       endDate : end
                    });
                }
                else {
                    this.oldSOs.push({
                        soValue : result.data[i],
                        soIcon : 'base-autocomplete',
                        progress : '100',
                        styling : 'slds-is-absolute old',
                        accord : false,
                        expandCollapseIcon : 'utility:chevronright',
                        currentStep : "3",
                        startDate : start,
                        endDate : end
                    });
                }
            }
            if(this.runningSOs.length > 0){
                this.diffServiceOutages.push({
                    soTime : 'Running Service Outages',
                    soTimeValue : this.runningSOs,
                })
            }
            if(this.upcomingSOs.length > 0){
                this.diffServiceOutages.push({
                    soTime : 'Upcoming Service Outages',
                    soTimeValue : this.upcomingSOs,
                })
            }
            if(this.oldSOs.length > 0){
                this.diffServiceOutages.push({
                    soTime : 'Elapsed Service Outages',
                    soTimeValue : this.oldSOs,
                })
            }
            this.isLoading = false;
        }
        else if (result.error) {
            this.isLoading = false;
        }
    }

    diffNoOfDays(first, second) {
        return (Math.floor((Date.UTC(first.getFullYear(), first.getMonth(), first.getDate()) - Date.UTC(second.getFullYear(), second.getMonth(), second.getDate())) / (1000 * 60 * 60 * 24)));
    }

    join(t, a, s) {
        function format(m) {
            let f = new Intl.DateTimeFormat('en', m);
            return f.format(t);
        }
        return a.map(format).join(s);
    }

    gotoRecord(event) {
        this.dataEle = event.target.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.dataEle,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url);
        });
    }

    publishSO(fillWhat, currentId, allValues, typeSO) {
        publish(this.messageContext, hdQuickActionClick, { quickAction: fillWhat, data: JSON.stringify({ currentRecordId: currentId, soValues: allValues, type : typeSO }) });
    }

    onClone(event){
        this.dataEle = event.target.dataset.id;
        this.publishSO('fillSONew',this.dataEle,this.diffServiceOutages,'clone');
    }

    onEdit(event) {
        this.dataEle = event.target.dataset.id;
        this.publishSO('fillSOEdit',this.dataEle,this.diffServiceOutages,'edit');
    }

    onNewSO() {
        this.publishSO('fillSONew','',this.diffServiceOutages,'new');
    }

    onExpandCollapseClicked(event) {
        this.receivedSO = event.target.dataset.id;

        for(let eachDiffSO in this.diffServiceOutages) {
            if(this.diffServiceOutages) {
                for(let eachSO in this.diffServiceOutages[eachDiffSO].soTimeValue) {
                    if(this.diffServiceOutages[eachDiffSO].soTimeValue[eachSO].soValue.Id === this.receivedSO){
                        this.diffServiceOutages[eachDiffSO].soTimeValue[eachSO].accord = !this.diffServiceOutages[eachDiffSO].soTimeValue[eachSO].accord;
                        this.diffServiceOutages[eachDiffSO].soTimeValue[eachSO].expandCollapseIcon = (this.diffServiceOutages[eachDiffSO].soTimeValue[eachSO].accord) ? 'utility:switch' : 'utility:chevronright';
                        break;
                    }
                }
            }
        }
    }
}