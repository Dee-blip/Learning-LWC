import { LightningElement, track, api, wire } from 'lwc';
import { getListInfoByName } from 'lightning/uiListsApi';
import { refreshApex } from '@salesforce/apex';
import CMR_OBJECT from '@salesforce/schema/BMCServiceDesk__Change_Request__c';
import getCMRRecords from '@salesforce/apex/HD_CMR_IndexPageRecords.getChangeList';
import getUserColumns from '@salesforce/apex/HD_CMR_IndexPageRecords.getUserColumns';
import getColumns from '@salesforce/apex/HD_CMR_IndexPageRecords.getColumns';
import getListViews from '@salesforce/apex/HD_CMR_IndexPageRecords.getAllListViews';
import updateSelectedColumns from '@salesforce/apex/HD_CMR_IndexPageRecords.updateSelectedColumns';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';

export default class Hd_CMR_List_View extends NavigationMixin(LightningElement) {
    @track cols = [];
    @track data = [];
    @track defaultColumns = [];
    @track selectedListView;
    @track wiredUserColsResponse;
    @track listViews = [];
    @track menuItems = [
        { label: 'New', value: 'New', isEnabled: true, itemURL: '/ui/list/FilterEditPage?ftype=01IG0000001okVO' },
        { label: 'Rename', value: 'Rename', isEnabled: true, itemURL: '/ui/list/FilterEditPage?ftype=01IG0000001okVO' },
        { label: 'Sharing Settings', value: 'SharingSettings', isEnabled: true, isModal: true },
        { label: 'Edit List Filters', value: 'EditListFilters', isEnabled: true, itemURL: '/ui/list/FilterEditPage?id=' },
        { label: 'Select Fields to Display', value: 'SelectFields', isEnabled: true, isModal: true },
        // { label: 'Delete', value: 'Delete', isEnabled: true }
    ];
    @api flexipageRegionWidth;
    listViewId;
    pageNo = 1;
    allRecordsLoaded;
    filterInfo;
    listViewApiName = 'Recent_Changes';
    searchPlaceHolder = 'Search CMRs by name...'
    isTitleHovered;
    showModal;
    sortBy = 'Id';
    sortDirection = 'ASC';
    showCMRSummary;
    selectedRecord;
    idFieldToName = new Map([
        ["Id", "Name"],
        ["HD_Sponsor__c", "HD_Sponsor_Name__c"],
        ["BMCServiceDesk__FKInitiator__c", "BMCServiceDesk__Initiator_First_Name__c-BMCServiceDesk__Initiator_Last_Name__c"],
        ["OwnerId", "HD_Owner_Name__c"]
    ]);
    quickActions = ['New', 'Printable View'];
    showPreview = false;

    gridPanelWidth = 12;
    previewPanelWidth = 5;

    @wire(getColumns)
    getColumnsCallback(result) {
        if (result.data) {
            let allCols = [];
            for (let col in result.data) {
                if (result.data[col]) {
                    allCols.push({ value: col, label: result.data[col] });
                }
            }
            this.allColumns = allCols;
        }
        else if (result.error) {
            this.showToast('Error retrieving columns for customizing', 'Error', 'error');
            console.log('Hd_CMR_List_View.getColumnsCallback : ' + result.error);
            this.logError('Hd_CMR_List_View.getColumnsCallback : ' + JSON.stringify(result.error));
        }
    }
    @track allColumns;

    @wire(getUserColumns)
    getUserColumnsCallback(result) {
        this.wiredUserColsResponse = result;
        if (result.data) {
            let colList = [];
            let defaultCols = [];
            colList.push({ label: 'Name', fieldName: 'Id', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, sortable: true });
            for (let col in result.data) {
                if (result.data[col]) {
                    if (col.toLowerCase().includes('date')) {
                        colList.push({
                            label: result.data[col], fieldName: col, type: 'date', sortable: true, typeAttributes: {
                                year: "numeric",
                                month: "short",
                                day: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: "true"
                            }
                        });
                    }
                    else if (col === 'Change_Summary__c') {
                        colList.push({ label: 'Summary', fieldName: 'Change_Summary__c', type: 'summaryColumn', sortable: true, wrapText: true });
                    }
                    else if (this.idFieldToName.has(col)) {
                        colList.push({ label: result.data[col], fieldName: col, type: 'url', typeAttributes: { label: { fieldName: this.idFieldToName.get(col) } }, sortable: false });
                    }
                    else {
                        colList.push({ label: result.data[col], fieldName: col, type: 'text', sortable: true });
                    }
                    defaultCols.push(col);
                }
            }
            colList.push({ type: 'button', fixedWidth: 70, typeAttributes: { iconName: 'utility:threedots', iconPosition: 'right', variant: 'base' } });
            this.cols = colList;
            this.defaultColumns = defaultCols;
        }
        else if (result.error) {
            this.showToast('Error retrieving columns for user', 'Error', 'error');
            console.log('Hd_CMR_List_View.getUserColumnsCallback : ' + result.error);
            this.logError('Hd_CMR_List_View.getUserColumnsCallback : ' + JSON.stringify(result.error));
        }
    }

    @wire(getListViews)
    getListViewsCallback(result) {
        if (result.data) {
            this.listViews = result.data;
        }
        else if (result.error) {
            this.showToast('Error retrieving listviews for object', 'Error', 'error');
            console.log('Hd_CMR_List_View.getListViewsCallback : ' + result.error);
            this.logError('Hd_CMR_List_View.getListViewsCallback : ' + JSON.stringify(result.error));
        }
    }

    handleQuickActionButtonClick(event) {
        switch (event.detail.quickAction) {
            case 'New':
                this.showCreateForm();
                break;
            case 'Printable View':
                this[NavigationMixin.Navigate]({
                    "type": "standard__webPage",
                    "attributes": {
                        "url": window.location.origin + '/a5E/x?fcf=' + this.listViewId.substring(0, 15)
                    }
                });
                break;
            default:
            // code block
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

    handleColumnSorting(event) {
        this.sortBy = (event.detail.fieldName === 'Id') ? 'Name' : event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.template.querySelector('[data-id="listView"]').pageNo = 0;
        this.loadMoreData(true);
    }

    loadMoreData(isReplace) {
        let listView = this.template.querySelector('[data-id="listView"]');
        listView.isLoadingRecords = true;
        listView.pageNo++;
        getCMRRecords({
            filterId: this.listViewId,
            noOfRecs: 50,
            ticketNumber: '',
            pageNo: this.template.querySelector('[data-id="listView"]').pageNo,
            orderBy: this.sortBy,
            sortDirection: this.sortDirection
        })
            .then(result => {
                if (typeof isReplace === 'boolean' && isReplace) {
                    this.data = this.replaceRecordIds(result?.records);
                }
                else {
                    this.data = [...this.data, ...this.replaceRecordIds(result?.records)];
                }
                listView.numberOfRecords = (this.data.length >= 50 && this.data.length !== result.noOfRecords) ? this.data.length + '+' : this.data.length;
                listView.enableInfiniteLoading = this.data.length < result.noOfRecords;
                listView.isLoadingRecords = false;
            })
            .catch(error => {
                this.showToast('Error loading additional rows for object', 'Error', 'error');
                console.log('Hd_CMR_List_View.loadMoreData : ' + error);
                this.logError('Hd_CMR_List_View.loadMoreData : ' + JSON.stringify(error));
            });
    }

    @wire(getListInfoByName, {
        objectApiName: CMR_OBJECT.objectApiName,
        listViewApiName: '$listViewApiName'
    }) listInfo({ error, data }) {
        if (data) {
            let listView = this.template.querySelector('[data-id="listView"]');
            listView.isLoadingRecords = true;
            console.log(JSON.stringify(data));
            this.selectedListView = data;
            this.listViewId = data?.listReference?.id;
            this.updateMenuItemURLs(this.listViewId);
            document.title = data?.label + ' | Change Management Request | Salesforce';
            listView.pageNo = 1;
            this.data = [];
            this.allRecordsLoaded = false;
            getCMRRecords({
                filterId: this.listViewId,
                noOfRecs: 50,
                ticketNumber: '',
                pageNo: listView.pageNo,
                orderBy: this.sortBy,
                sortDirection: this.sortDirection
            })
                .then(result => {
                    this.data = [...this.data, ...this.replaceRecordIds(result?.records)];
                    listView.numberOfRecords = (this.data.length >= 50 && this.data.length !== result.noOfRecords) ? this.data.length + '+' : this.data.length;
                    listView.enableInfiniteLoading = this.data.length < result.noOfRecords;
                    listView.isLoadingRecords = false;
                })
                .catch(localerror => {
                    this.showToast('Error loading initial rows for object', 'Error', 'error');
                    console.log('Hd_CMR_List_View.loadlistInfo.getCMRRecords : ' + localerror);
                    this.logError('Hd_CMR_List_View.loadlistInfo.getCMRRecords : ' + JSON.stringify(localerror));
                });
            listView.setFilters(data);
        } else if (error) {
            this.showToast('Error loading list view info for the selected listview', 'Error', 'error');
            console.log('Hd_CMR_List_View.loadlistInfo : ' + error);
            this.logError('Hd_CMR_List_View.loadlistInfo : ' + JSON.stringify(error));
        }
    }

    onListViewSelected(event) {
        this.listViewId = event.detail.listView.Id;
        this.updateMenuItemURLs(this.listViewId);
        this.listViewApiName = event.detail.listView.DeveloperName;
        this.template.querySelector('[data-id="listView"]').isLoadingRecords = true;
    }

    get titleClass() {
        return (this.isTitleHovered) ? 'slds-page-header__name titleHover' : 'slds-page-header__name';
    }

    updateMenuItemURLs(listViewId) {
        this.menuItems.forEach(menuItem => {
            if (menuItem.value === 'EditListFilters' || menuItem.value === 'Rename') {
                menuItem.itemURL = '/ui/list/FilterEditPage?id=' + listViewId;
            }
        });
    }

    handleCMRSearch(event) {
        let listView = this.template.querySelector('[data-id="listView"]');
        listView.isLoadingRecords = true;
        getCMRRecords({
            filterId: this.listViewId,
            noOfRecs: 50,
            ticketNumber: event.detail.searchString,
            pageNo: 1,
            orderBy: 'Name',
            sortDirection: 'ASC'
        })
            .then(result => {
                if (result) {
                    this.data = this.replaceRecordIds(result?.records);
                    listView.numberOfRecords = (this.data.length >= 50) ? '50+' : this.data.length;
                    listView.enableInfiniteLoading = this.data.length < result.noOfRecords;
                    listView.isLoadingRecords = false;
                }
            })
            .catch(error => {
                this.showToast('Error searching the CMR object', 'Error', 'error');
                console.log('Hd_CMR_List_View.handleCMRSearch.getCMRRecords : ' + error);
                this.logError('Hd_CMR_List_View.handleCMRSearch.getCMRRecords : ' + JSON.stringify(error));
            });
    }

    replaceRecordIds(data) {
        return data.map(record => {
            let modifiedRec = { ...record };
            this.idFieldToName.forEach((value, key) => {
                modifiedRec[key] = '/' + record[key];
            });
            return modifiedRec;
        })
    }

    handleRowClick(event) {
        this.selectedRecord = event.detail.row;
        this.showPreview = true;
        this.gridPanelWidth = 7;
    }

    handleDataRefresh() {
        let listView = this.template.querySelector('[data-id="listView"]');
        listView.isLoadingRecords = true;
        getCMRRecords({
            filterId: this.listViewId,
            noOfRecs: 50,
            ticketNumber: '',
            pageNo: 1,
            orderBy: this.sortBy,
            sortDirection: this.sortDirection
        })
            .then(result => {
                this.data = [...this.replaceRecordIds(result?.records)];
                listView.numberOfRecords = (this.data.length >= 50 && this.data.length !== result.noOfRecords) ? this.data.length + '+' : this.data.length;
                listView.enableInfiniteLoading = this.data.length < result.noOfRecords;
                listView.isLoadingRecords = false;
            })
            .catch(error => {
                this.showToast('Error loading records during refresh', 'Error', 'error');
                console.log('Hd_CMR_List_View.handleDataRefresh : ' + error);
                this.logError('Hd_CMR_List_View.handleDataRefresh : ' + JSON.stringify(error));
            });
    }

    handleMenuItemsValueChanged(event) {
        switch (event.detail.eventId) {
            case 'selectFields': {
                updateSelectedColumns({ selectedColumns: event.detail.data })
                    .then(() => {
                        refreshApex(this.wiredUserColsResponse);
                        this.allRecordsLoaded = false;
                        this.template.querySelector('[data-id="listView"]').pageNo = 0;
                        this.loadMoreData(true);
                    })
                    .catch(error => {
                        console.log('Error:' + error.body.message);
                        console.log('Error:' + error.message);
                    });
                break;
            }
            default: {
                break;
            }
        }
    }

    onClosePreview() {
        this.gridPanelWidth = 12;
        this.showPreview = false;
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: this.recordId
        });
    }

    showToast(message, title, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}