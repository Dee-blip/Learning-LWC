/** @Date		:	Jan 20 2021
* @Author		: 	Vishnu/ Sumukh SS / Sharath P
* @Description	:	JARVIS Support Home
WARNING : THIS IS A CUSTOMER FACING COMPONENT. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION.
*/
import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import getMyDashboardData from '@salesforce/apex/SC_Community_JarvisHomePage.getCasesinQueue';
import getCasedetails from '@salesforce/apex/SC_Community_JarvisHomePage.getCasedetails';
import saveUserCustomizations from '@salesforce/apex/SC_Community_JarvisHomePage.saveUserCustomizations';
import fetchAllCases from '@salesforce/apex/SC_Community_JarvisHomePage.fetchAllCases';

//import the static resource
import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";
import { COL_MAP } from './datatableConfig';

// LABELS - All UI labels except tab labels
// TabLabels - Tab labels with record count
import {LABELS,  TabLabels} from './i18n';

export default class ScJarvisCaseManagement extends NavigationMixin(LightningElement) {
    label = LABELS;

    activeMaintab = '';//'myActiveCases';
    activeMaintabLabel;
    activeSubtab = 'All';

    selectedCaseId;
    selectedCaseRec;

    // allcookieval;

    sortedByColumnName = 'createddatestr';
    sortDirection = 'desc';

    allData = [];
    now;

    showspinner = false;

    showCaseDetailModal = false;
    showCaseCreateModal = false;

    entitledAccounts = [];
    AccValue;
    pageSize;
    disableAccountSelection = false;
    RECORD_TYPES = [    { label: 'Technical', value: 'Technical'},
                        { label: 'Managed Security', value: 'Managed Security'},
                        { label: 'Professional Services', value: 'Professional Services'},
                        { label: 'AMG', value: 'AMG'},
                        { label: 'Billing', value: 'Billing'}
                    ];
    recordtypeTabVisibility = [ {technical: false},
                                {managedSecurity: false},
                                {profserv: false},
                                {amg: false},
                                {billing: false} ];

    @track _tableData = [];
    get tableData() {
        return this._tableData;
    }
    set tableData(val) {
        this._tableData = val;
        this.paginatedData = [];
    }

    get columns() {
        return COL_MAP[this.activeSubtab || 'All'];
    }
    get caseFilterOptions() {
        let searchableColumns = this.columns
            .filter(col => col.searchable)
            .map(col => { return { label: col.label, value: col.searchFieldName || col.fieldName } });

        return searchableColumns;
    }

    activeFilterColumns = [];

    constructor() {
        super();
        this.activeFilterColumns = this.caseFilterOptions.map(col => col.value);
    }

    handleSelectAllColFilters() {
        const selectAllColumns = !this.allColFilter;
        if (selectAllColumns) {
            this.activeFilterColumns = this.caseFilterOptions.map(col => col.value);
        } else {
            this.activeFilterColumns = [];
        }
        //this.validateCaseFilters();
    }

    get allColFilter() {
        return this.activeFilterColumns.length === this.caseFilterOptions.length;
    }

    handleColFilterChange(ev) {
        this.activeFilterColumns = ev.detail.value;
        //this.validateCaseFilters();
        this.filterCaseTable(this.searchStr);
    }

    queryTerm;
    // handleKeyUp(e) {
    //     this.queryTerm = e.target.value;
    //     clearTimeout(this.timeoutId);
    //     this.timeoutId = setTimeout(this.searchtable.bind(this), 500);
    // }

    searchStr;

    handleSearch(ev) {
        this.searchStr = ev.target.value ? ev.target.value.toLowerCase() : '';
        this.filterCaseTable(this.searchStr);
    }

    filterCaseTable(searchStr) {
        let searchableColumns = [];
        if (!this.activeFilterColumns || !this.activeFilterColumns.length) {
            searchableColumns = this.caseFilterOptions;
        } else {
            searchableColumns = this.caseFilterOptions.filter(el => this.activeFilterColumns.includes(el.value));
        }

        this.tableData = this.allData.filter(rec => {
            return (this.activeSubtab === 'All' || rec.recordtype === this.activeSubtab)
                && (!searchStr ||
                    searchableColumns.find(({ value }) => {
                        return (typeof rec[value] === 'string'
                            && rec[value].toLowerCase().includes(searchStr))
                    }));
        });
        this.searchResultsCount = this.tableData.length;
    }

    dataFetchDateTime;
    dataFetchValidityInMs = 60000;
    

    connectedCallback() {
        loadStyle(this, staticStyleSheet);        
        this.showspinner = true;
        window.addEventListener("visibilitychange", this.handleVisibilityChange.bind(this));
        this.getDashDetails();
    }
    handleVisibilityChange() {
        const dataAge = Date.now() - this.dataFetchDateTime;
        if(dataAge > this.dataFetchValidityInMs) {
            this.dataFetchDateTime = Date.now(); // to skip visibility changes for visibility changes in middle api call
            this.getDashDetails();
        }
    }

    mainFilterOptions;
    hasCaseCreateAccess;
    getDashDetails() {
        getMyDashboardData({
            queryType: this.activeMaintab,
            selectedAccountIds: this.selectedAccounts.map(el => el.id)
        })
            .then(result => {
                const { entitledAccounts, 
                        selectedAccountIds, 
                        caseList, 
                        entitledRecordtypes,
                        pageSize, 
                        hasCaseCreateAccess, 
                        queryType } = result;
                this.activeMaintab = queryType;
                this.showspinner = false;
                this.dataFetchDateTime = Date.now();
                this.now = Date.now();
                this.hasCaseCreateAccess = hasCaseCreateAccess;
                this.entitledAccounts = entitledAccounts.map(el => {
                    return { text: el.Name, metatext: el.AKAM_Account_ID__c, id: el.Id };
                });

                this.entitledAccounts.sort((a, b) => {
                    const acc1 = a.text.toUpperCase(); // ignore upper and lowercase
                    const acc2 = b.text.toUpperCase(); // ignore upper and lowercase
                    return acc1 === acc2 ? 0
                        : (acc1 < acc2 ? -1 : 1);
                });
                this.disableAccountSelection = entitledAccounts.length < 2;

                this.pageSize = pageSize + '';

                this.selectedAccounts = this.entitledAccounts.filter(ao => selectedAccountIds.includes(ao.id));

                this.updateLabels(result);

                switch (this.activeMaintab) {
                    case 'myActiveCases':
                        this.activeMaintabLabel = this.tabLabels.lbTabMyOpen;
                        break;
                    case 'myClosedCases':
                        this.activeMaintabLabel = this.tabLabels.lbTabMyClosed;
                        break;
                    case 'allActiveCases':
                        this.activeMaintabLabel = this.tabLabels.lbTabAllOpen;
                        break;
                    case 'allClosedCases':
                        this.activeMaintabLabel = this.tabLabels.lbTabAllClosed;
                        break;
                    default:
                        this.activeMaintabLabel = this.tabLabels.lbTabMyOpen;
                }

                this.allData = caseList;
                console.log('all cases' + JSON.stringify(this.allData, null, "\t"));
                if (this.activeSubtab !== 'All') {
                    this.handleActiveTab(this.activeSubtab);
                }
                else {
                    this.tableData = caseList;
                }
                this.selectedSubTabRecordCount = this.tableData.length;
                // Apply Search if Search String is not null
                if(this.searchStr) {
                    this.filterCaseTable(this.searchStr);
                }

                // Show Recordtype tab only
                //          - If User has entitlement for Record type 
                //          - or any Case for that record type
    
                this.recordtypeTabVisibility.technical = caseList.find(cs => cs.recordtype === 'Technical') || entitledRecordtypes.includes('Technical');
                this.recordtypeTabVisibility.managedSecurity = caseList.find(cs => cs.recordtype === 'Managed Security') || entitledRecordtypes.includes('Managed Security');
                this.recordtypeTabVisibility.profserv = caseList.find(cs => cs.recordtype === 'Professional Services') || entitledRecordtypes.includes('Professional Services');
                this.recordtypeTabVisibility.amg = caseList.find(cs => cs.recordtype === 'AMG') || entitledRecordtypes.includes('AMG');
                this.recordtypeTabVisibility.billing = caseList.find(cs => cs.recordtype === 'Billing') || entitledRecordtypes.includes('Billing');
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
    }

    saveUserCustz() {
        const accIdList = this.selectedAccounts.map(el => el.id);
        saveUserCustomizations({ accountIds: accIdList, pageSize: this.pageSize, queryType: this.activeMaintab}).then(result => {
            console.log('personalizationSuccess', result);
        }).catch(error => {
            console.log('personalizationError', error);
        });
    }

    selectedSubTabRecordCount;
    searchResultsCount;
    handleActiveTab(e) {
        var searchFilter;

        if (typeof e.target !== 'undefined') {
            searchFilter = e.target.value;
        }
        else {
            searchFilter = e;
        }
        this.activeSubtab = searchFilter;

        if (searchFilter !== 'All') {
            let allRecords = this.allData;

            let tempArray = [];

            for (let i = 0; i < allRecords.length; i++) {
                if (allRecords[i].recordtype && allRecords[i].recordtype.indexOf(searchFilter) !== -1) {
                    tempArray.push(allRecords[i]);
                }
            }
            this.tableData = tempArray;
        }
        else {
            this.tableData = this.allData;
        }
        this.selectedSubTabRecordCount = this.tableData.length;
        if (this.searchStr) {
            this.filterCaseTable(this.searchStr);
        }
        this.activeFilterColumns = this.caseFilterOptions.map(col => col.value);
    }

    get tabResultsMessage() {
        let message;
        if (this.searchStr && !this.selectedSubTabRecordCount) {
            message =  this.label.LB_NO_RESULTS;
        } else if (!this.selectedSubTabRecordCount) {
            message = this.label.LB_NO_RECORDS;
        }
        return message;
    }


    //Tab change for Master Tabs
    handleViewChange(e) {
        this.activeMaintab = e.target.value;
        this.showspinner = true;
        this.getDashDetails();
        this.saveUserCustz();
    }
    getTabLabel(tabName, count) {
        return `${tabName} (${count || 0})`;
    }

    choosenAccId;

    refreshTable() {
        this.showspinner = true;
        this.getDashDetails();
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let selectedCaseId = event.detail.row.caseUrl.substring(18);

        if (actionName === 'Case_Preview') {
            this.selectedCaseId = selectedCaseId;

            getCasedetails({
                caseid: selectedCaseId
            }).then(result => {
                this.selectedCaseRec = result;
                this.showCaseDetailModal = true;
            }).catch(error => {
                console.log(JSON.stringify(error));
            });
        }
    }

    sortBy(sortColumn, reverse) {
        const getFieldValue = (rec) => {
            const {fieldName, sortFieldName, sortType} = {...sortColumn};
            const toSortFieldName = sortFieldName || fieldName;
            const fiedValue = rec[toSortFieldName];

            if(!fiedValue) {
                return fiedValue;
            }

            if(sortType === 'text') {
                return fiedValue.toLowerCase();
            } 
            else if(sortType === 'date') {
                return new Date(fiedValue);
            }
            return fiedValue;
        }

        return function (rec1, rec2) {
            const value1 = getFieldValue(rec1);
            const value2 = getFieldValue(rec2);

            if (!value1) {
                return 1;
            }
            else if (!value2) {
                return -1;
            }
            
            return reverse * ((value1 > value2) - (value2 > value1));
            
        };

    }

    onHandleSort(event) {

        if (event) {
            this.sortedByColumnName = event.detail.fieldName;
            this.sortDirection = event.detail.sortDirection;
        }

        const sortColumn = this.columns.find(cl => {
            return cl.fieldName === this.sortedByColumnName;
        })

        this.tableData.sort(this.sortBy(sortColumn, this.sortDirection === 'asc' ? 1 : -1));
        this.tableData = [...this.tableData];
    }


    /* Download Logic */
    get downloadLabel() {
        return this.activeMaintabLabel ? this.activeMaintabLabel.split('(')[0] : '';
    }
    get downloadDisplayListLabel() {
        const tablabel = this.activeMaintab === 'myActiveCases' || this.activeMaintab === 'allActiveCases' 
                        ? this.label.LB_DISPLAYED_ACTIVE_CASES 
                        : this.label.LB_DISPLAYED_CLOSED_CASES;
        return tablabel;
    }
    handleDownload(ev) {
        const toDownloadView = ev.target.value;
        const downloadAccountName = this.selectedAccounts.length > 1 ? this.selectedAccounts.length + ' Accounts' : this.selectedAccounts[0].text;

        if(toDownloadView === 'displayedList') {
            const fileName = downloadAccountName + ' - ' + this.downloadDisplayListLabel + ' (' + this.tableData.length + ')';
            this.tableToCsv(this.tableData, this.columns, fileName);
        } else if (toDownloadView === 'all') {
            this.showspinner = true;
            // call fetch all method
            fetchAllCases({ selectedAccountIds: this.selectedAccounts.map(el => el.id) }).then(result => {
                console.log('Downalod success', result);
                const fileName = downloadAccountName + ' - All Active & Closed Cases (' + result.length + ')';
                this.tableToCsv(result, this.columns, fileName);
                this.showspinner = false;
            }).catch(error => {
                this.showspinner = false;
                console.log('Downalod error', error);
            });
        } else {
            const fileName = downloadAccountName + ' - ' + this.downloadLabel + ' (' + this.allData.length + ')';
            this.tableToCsv(this.allData, this.columns, fileName);
        }
    }

    selectedAccounts = [];
    /** Account Selection Handler */
    handleAccountSelection(ev) {
        this.selectedAccounts = ev.detail;
        this.showspinner = true;
        this.getDashDetails();
        this.saveUserCustz();
    }

    /* Pagination Logic */
    paginationInfo;
    paginatedData;

    handlePaginationSelect(ev) {
        const { firstRecordIndex, lastRecordIndex, pageSize } = ev.detail; //selectedPageNumber
        this.paginatedData = this.tableData.slice(firstRecordIndex, lastRecordIndex + 1);
        this.pageSize = pageSize;
        this.saveUserCustz();
    }
    get tableSize() {
        return this._tableData && this._tableData.length ? this._tableData.length : 0;
    }

    get paginationCss() {     
        return this._tableData && this._tableData.length  > 10 ? 'slds-p-vertical_large': 'slds-p-vertical_large slds-hide';
    }

    get showPaginationCss() {
        // showPagination
        return this._tableData && this._tableData.length > this.pageSize ? 'slds-p-vertical_large' : 'slds-p-vertical_large slds-hide';
    }

    @track tabLabels = new TabLabels();

    // Upate Case Count in Tab Labels
    updateLabels(dashInfo) {
        this.tabLabels.updateCount(dashInfo);
        this.mainFilterOptions = [
                { label: this.tabLabels.lbTabMyOpen, value: 'myActiveCases' },
                { label: this.tabLabels.lbTabAllOpen, value: 'allActiveCases' },
                { label: this.tabLabels.lbTabMyClosed, value: 'myClosedCases' },
                { label: this.tabLabels.lbTabAllClosed, value: 'allClosedCases' }
            ];
        this.template.querySelector('lightning-combobox').options = this.mainFilterOptions;
    }

    /* Pop up modals logic - Decide what To Show - Dashboard/ Preview  Modal/ Case  Create  Comp*/

    openNewCase() {
        this.showCaseCreateModal = true;
    }

    closeCaseDetailModal() {
        this.showCaseDetailModal = false;
    }

    closeCaseCreateModal() {
        this.showCaseCreateModal = false;
        if(this.cloneId) {
            // Navigate to the Account home page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.cloneId,
                    actionName: 'view',
                },
            });
        }
        else if(this.mode) {
            this.mode = '';
            const newPageRef = Object.assign({}, this.currPageRef);
            newPageRef.state = {};
            this[NavigationMixin.Navigate](
                newPageRef
            );
        }
    }

    get caseDetailModalCss() {
        return this.showCaseDetailModal ? 'slds-show' : 'slds-hide';
    }
    get caseCreateModalCss() {
        return this.showCaseCreateModal ? 'slds-show' : 'slds-hide';
    }
    get mainSectionCss() {
        return !this.showCaseCreateModal ? 'slds-show' : 'slds-hide';
    }

    mode;
    /* Case Cloning Logic - To Pass Clone Id to Case Create Component*/ 
    cloneId;
    currPageRef;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.currPageRef = currentPageReference;
            if (currentPageReference.state) {
                this.cloneId = currentPageReference.state.caseId;
                this.mode = currentPageReference.state.mode;
                if(this.cloneId || this.mode === 'newcase') {
                    this.showCaseCreateModal = true;
                }
            }
        }
    }
    /* Account Filter Pop Over Message Logic - Dsiplayed Only when there are multiple entitled Accounts and not all accounts are selected */
    get showAccountFilterToast(){
        return this.selectedAccounts && (this.selectedAccounts.length !== this.entitledAccounts.length);
    }
    
    dismissFilterMsgAndselectAllAcc()  {
        this.showspinner = true;
        this.selectedAccounts = [...this.entitledAccounts];//.filter(ao => selectedAccountIds.includes(ao.id));
        this.getDashDetails();
    }

    get headerLabel() {
        return (this.activeMaintabLabel || '').split('(')[0];
    }

    tableToCsv(tabdata, cols, fileName) {

        let csvHeader = cols.filter(el => el.label).map(el => el.label).join(',');
        // to support new or custom column types, update this string and if conditional blocks below
        const supportedColTypes = 'text; url';

        let csvBody = tabdata.map(row => {
            let rowStr = '';
            cols.forEach((col) => {
                if(!supportedColTypes.includes(col.type.toLowerCase())) {
                    return;
                }
    
                let fieldName;
                // to support new or custom column types, update these conditions
                if(col.type === 'text'){
                    fieldName = col.fieldName;
                } else if(col.type === 'url') {
                    fieldName = col.typeAttributes.label.fieldName;
                }  
    
                const cellVal = row[fieldName];
    
                let cellStr = cellVal? cellVal.toString(): '';
                if(cellStr.search(/("|,|\n)/g) >= 0) {
                    cellStr = '"' + cellStr + '"';
                }
                rowStr = rowStr + cellStr + ',';
            });
            return rowStr;
        }).join("\n");
    
        const csvData = '\uFEFF' + csvHeader + '\n' + csvBody;
        const blobData = new Blob([csvData], {type: 'text/plain'});
        const link = document.createElement('a');
        link.href = window.URL.createObjectURL(blobData);
        link.download = `${fileName}.csv`;
        link.click();
    }
}