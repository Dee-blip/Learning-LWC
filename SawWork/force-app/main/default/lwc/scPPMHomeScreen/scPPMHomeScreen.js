import { LightningElement } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import cssStyleSheet from "@salesforce/resourceUrl/SC_PPM_Stylesheet";

import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getCaseData from '@salesforce/apex/SC_PPM_HomePage_Controller.getCaseData';
import saveFilters from '@salesforce/apex/SC_PPM_HomePage_Controller.saveFilters';





/********************  CASE COLUMNS ***********************/
const columns = [{
    label: 'AKAM Case ID',
    fieldName: 'caseUrl',
    type: 'url',
    typeAttributes: { label: { fieldName: 'akamCaseId' } },
    cellAttributes: { class: { fieldName: 'caseColour' } },
    initialWidth: 100

},
{
    label: 'Account',
    fieldName: 'accountName',
    type: 'text',
    wrapText: true,
    initialWidth: 180
},
{
    label: 'Account Tier',
    fieldName: 'accountTier',
    type: 'text',
    initialWidth: 50

},
{
    label: 'Case Subject',
    fieldName: 'caseSubject',
    type: 'text',
    wrapText: true,
    initialWidth: 290
},
{
    label: 'Geography',
    fieldName: 'geography',
    type: 'text',
    initialWidth: 80
},
{
    label: 'Problem',
    fieldName: 'problem',
    type: 'text',
    initialWidth: 130
},
{
    label: 'Severity',
    fieldName: 'severity',
    type: 'text',
    initialWidth: '50',
    sortable: true
},
{
    label: 'Case Owner',
    fieldName: 'caseOwnerName',
    type: 'text',
    initialWidth: 140
},
{
    label: 'Task Type',
    fieldName: 'taskType',
    type: 'text',
    initialWidth: 50
},
{
    label: 'Task Subject',
    fieldName: 'taskSubject',
    type: 'text',
    wrapText: true,
    initialWidth: 80
},
{
    label: 'Task Due In',
    fieldName: 'taskDueDateinMinutes',
    type: 'text',
    cellAttributes: { class: { fieldName: 'TimeColor' } },
    initialWidth: 50,
    wrapText: true
},

{
    label: 'Case Last Update By?',
    fieldName: 'caseLastUpdateBy',
    type: 'text',
    initialWidth: 100
},
{
    label: 'Case Last Update',
    fieldName: 'caseLastUpdateTimeinMinutes',
    type: 'text',
    wrapText: true,
}
];

export default class ScPPMHomeScreen extends NavigationMixin(LightningElement) {

    columns = columns;
    caseData = [];
    allCaseData = [];
    caseDataPerPage = [];
    totalCases = 0;
    redCount = 0;
    whiteCount = 0;
    yellowCount = 0;
    displayCase = true;

    displayFilter = true;
    selectedSeverity = ['1', '2', '3'];
    selectedGeography = 'All'
    filterStringToSave = '';

    pollerId;
    timeoutId;

    notificationlist = [];
    notificationCenterHeader = "";

    offset = 1;
    paginationNumbers;
    currentpage;
    paginationRange = [];

    showSpinner = true;


    /********************  FILTER VALUES ***********************/
    get severityFilterValues() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
        ];
    }

    get geoFilterValues() {
        return [
            { label: 'All', value: 'All' },
            { label: 'APJ', value: 'APJ' },
            { label: 'EMEA', value: 'EMEA' },
            { label: 'LATAM', value: 'LATAM' },
            { label: 'NORTHAM', value: 'NORTHAM' }

        ];
    }

    /************************************  GET SAVED FILTERS AND POPULATE CASE DATA ***************************************/
    connectedCallback() {

        saveFilters()
            .then(result => {
                this.selectedSeverity = result.Severity.split(',');
                this.selectedGeography = result.Geography;

                window.addEventListener("visibilitychange", this.listenForMessage.bind(this));

                this.populateCaseData();

                this.pollerId = setInterval(() => {
                    this.populateCaseData();
                    console.log('In Poller CB'+ this.PollerId);
                }, 300000);
                console.log('poller Id//' + this.pollerId);
            })
            .catch(error => {
                console.log('Get Filter Error : ' + JSON.stringify(error));
                console.log('Get Filter Error : ' + error);
                this.error = error;
                this.showSpinner = false;
            });

        loadStyle(this, cssStyleSheet);
    }

    listenForMessage() {

        if (document.visibilityState !== 'visible') {
            console.log('User Away');
            window.clearInterval(this.PollerId);
        }
        else {
            console.log('User Back');
            this.resetPollerAndRefresh();
        }
    }

    populateCaseData() {
        this.showSpinner = true;
        getCaseData({ severityFilter: this.selectedSeverity, geographyFilter: this.selectedGeography })
            .then(result => {
                this.caseData = result.CaseData;
                this.allCaseData = result.CaseData;
                this.totalCases = result.totalCaseCount;
                this.redCount = result.totalRedCount;
                this.whiteCount = result.totalWhiteCount;
                this.yellowCount = result.totalYellowCount;

                this.calculateCasePaginationlogic();

                this.searchCases();

                this.showSpinner = false;
            })
            .catch(error => {
                console.log('casedata error : ' + JSON.stringify(error));
                console.log('casedata error : ' + error);
                this.error = error;
                this.showSpinner = false;
            });
    }




    toggleCaseTable() {
        this.displayCase = !this.displayCase;
    }

    showCaseTable() {
        let x = this.template.querySelector('.panelCase');
        if (this.totalCases <= 5)
            x.style.height = '35vh';
        else
            x.style.height = '70vh';
        this.displayCase = !this.displayCase;
    }

    hideCaseTable() {
        var x = this.template.querySelector('.panelCase');
        x.style.height = '0vh';
        this.displayCase = !this.displayCase;
    }


    renderedCallback() {

        let x = this.template.querySelector(".panelCase");
        if (this.displayCase && x !== null) {
            if (this.caseDataPerPage.length <= 5)
                x.style.height = "35vh";
            else
                x.style.height = "70vh";
        }

    }



    /*********************************************** SAVE AND APPLY FILTERS ******************************************************/


    showFilter() {
        this.displayFilter = !this.displayFilter;
    }

    hideFilter() {
        this.displayFilter = !this.displayFilter;
    }

    handleSeverityChange(event) {

        this.selectedSeverity = event.detail.value;

        if (!event.detail.value.toString()) {
            const toastEvt = new ShowToastEvent({
                title: '',
                message: 'Please select atleast one Case Severity value',
                variant: 'warning',
                mode: 'dismissible',
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }


    }

    handleGeographyChange(event) {
        this.selectedGeography = event.detail.value;
    }

    handleReset() {
        this.selectedSeverity = ['1', '2', '3'];
        this.selectedGeography = 'All';
    }

    applyFilters() {
        this.showSpinner = true;

        if (!this.selectedSeverity.toString()) {
            const toastEvt = new ShowToastEvent({
                title: '',
                message: 'Please select atleast one Case Severity value',
                variant: 'warning',
                mode: 'dismissible',
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.showSpinner = false;
        }
        else {
            this.resetPollerAndRefresh();
            this.saveFilter();
        }
    }

    saveFilter() {
        let severity = String(this.selectedSeverity);
        let geography = String(this.selectedGeography);

        this.filterStringToSave = 'Severity:' + severity + '&Geography:' + geography;

        if (severity && geography) {
            saveFilters({ filterToSave: this.filterStringToSave })
                .then(result => {
                    console.log('Saved Filters//' + result);
                    this.searchCases();
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.log('Save filter error://' + JSON.stringify(error));
                    console.log('Save filter error://' + error);
                });
        }
    }

    resetPollerAndRefresh(event) {
        console.log('In Poller Refresh');

        window.clearInterval(this.PollerId);
        this.PollerId = setInterval(() => {
            console.log('In Poller resetandrefresh : ' + this.PollerId);
            this.populateCaseData();
        }, 300000);
        if (typeof (event) != 'undefined') {
            this.showSpinner = true;
        }

        this.populateCaseData();

    }



    /* ******************************************* SEARCH METHODS ****************************************************** */
    clearSearchInput() {
        this.template.querySelector('.labelHidden').value = '';
        this.delayedSearch();
    }

    delayedSearch() {
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500);
    }

    searchCases() {

        let searchFilter = this.template.querySelector('.labelHidden').value;

        if (searchFilter !== '') {

            searchFilter = searchFilter.toUpperCase();

            let tempArray = [];

            this.allCaseData.forEach(function (eachRow) {
                if ((eachRow.akamCaseId && eachRow.akamCaseId.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.accountTier && eachRow.accountTier.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.caseSubject && eachRow.caseSubject.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.geography && eachRow.geography.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.problem && eachRow.problem.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.caseOwnerName && eachRow.caseOwnerName.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.tasktype && eachRow.tasktype.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.taskSubject && eachRow.taskSubject.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.caseLastUpdateBy && eachRow.caseLastUpdateBy.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.tasktype && eachRow.tasktype.toUpperCase().indexOf(searchFilter) !== -1)
                    || (eachRow.severity && eachRow.severity.toUpperCase().indexOf(searchFilter) !== -1)
                ) {
                    tempArray.push(eachRow);
                }
            });

            this.caseData = tempArray;
        }
        else {
            this.caseData = this.allCaseData;
        }

        this.totalCases = this.caseData.length;

        this.calculateCasePaginationlogic();

        let x = this.template.querySelector('.panelCase');
        if (this.caseDataPerPage.length <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";

    }


    /* ***************************************** Notification Center ********************************************** */

    getNavRecords(event) {
        //var t0 = performance.now();
        let buttonVal = event.target.value;
        var filteredlist = [];
        this.notificationCenterHeader = buttonVal === 'red' ? 'Initial Response Pending' :
            buttonVal === 'yellow' ? 'Customer Response Received' : 'Unassigned Case';

        for (let i = 0; i < this.allCaseData.length; i++) {
            if (this.allCaseData[i].caseColour === 'red' && buttonVal === 'red') {
                let x = {
                    akamId: this.allCaseData[i].akamCaseId,
                    caseRecId: this.allCaseData[i].caseId,
                    Body: 'Go to Case ' + this.allCaseData[i].akamCaseId
                };
                filteredlist.push(x);
            }
            else if
                (this.allCaseData[i].caseColour === 'yellow' && buttonVal === 'yellow') {
                let x = {
                    akamId: this.allCaseData[i].akamCaseId,
                    caseRecId: this.allCaseData[i].caseId,
                    Body: 'Go to Case ' + this.allCaseData[i].akamCaseId
                };
                filteredlist.push(x);
            }
            else if
                (this.allCaseData[i].caseColour === 'white' && buttonVal === 'white') {
                let x = {
                    akamId: this.allCaseData[i].akamCaseId,
                    caseRecId: this.allCaseData[i].caseId,
                    Body: 'Go to Case ' + this.allCaseData[i].akamCaseId
                };
                filteredlist.push(x);
            }
        }


        this.notificationlist = filteredlist;
        let sideNav = this.template.querySelector('.sidenav');
        sideNav.style.width = "250px";
    }

    closeNav() {
        var x = this.template.querySelector('.sidenav');
        x.style.width = "0px";
    }

    navigateToCase(event) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.value,
                objectApiName: 'Case',
                actionName: 'view'
            },
        });
    }

    /* ***************************************** PAGINATION ********************************************** */

    handlePaginationClick(event) {
        let page = event.target.dataset.item;
        this.offset = page;
        this.caseDataPerPage = this.caseData.slice((this.offset - 1) * 150, this.offset * 150);
        this.currentpage = this.offset + '/' + this.paginationNumbers;
    }

    calculateCasePaginationlogic() {
        var i;
        this.paginationRange = [];

        if (this.totalCases === 0) {
            this.paginationNumbers = 1;
        }
        else {
            this.paginationNumbers = Math.ceil(this.totalCases / 150);
        }
        if (this.offset > this.paginationNumbers) this.offset = 1;

        this.currentpage = this.offset + '/' + this.paginationNumbers;

        for (i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        this.caseDataPerPage = this.caseData.slice((this.offset - 1) * 150, this.offset * 150);
    }



}