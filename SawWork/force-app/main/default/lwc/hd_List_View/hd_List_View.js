import { LightningElement, api, track } from 'lwc';

export default class Hd_List_View extends LightningElement {
    @api columns = [];
    @api records = [];
    @api quickActions = [];
    @api listViews = [];
    @api menuItems = [];
    @api objectName;
    @api selectedListView;
    // @api isLoadingRecords;
    @api numberOfRecords;
    @api searchPlaceHolder;
    @api defaultColumns;
    @api allColumns;
    @api enableInfiniteLoading;
    @api sortBy;
    @api sortDirection;
    @track selectedMenuItem;
    isTitleHovered;
    isLoading;
    filterButtonState;
    summaryButtonState;

    @api
    setFilters(filterData) {
        this.template.querySelector('[data-id="listViewFilter"]').setFilters(filterData);
    }

    updateColumnSorting(event) {
        /* eslint-disable-next-line */
        this.sortBy = event.detail.fieldName;
        /* eslint-disable-next-line */
        this.sortDirection = event.detail.sortDirection;
        this.dispatchEvent(new CustomEvent("sort", {
            detail: {
                fieldName: event.detail.fieldName,
                sortDirection: event.detail.sortDirection,
            },
            bubbles: true,
            isComposed: true
        }));
    }

    set isLoadingRecords(value) {
        this.isLoading = value;
        if (!value) {
            const buttonIcon = this.template.querySelector('.slds-button__icon');
            buttonIcon.classList.remove('refreshRotate');
        }
    }

    @api
    get isLoadingRecords() {
        return this.isLoading;
    }
    onListViewTitleHover() {
        this.isTitleHovered = true;
    }

    onListViewTitleHoverOut() {
        this.isTitleHovered = false;
    }

    onListViewDropdownClicked() {
        this.template.querySelector('[data-id="listView"]').isOpen = !this.template.querySelector('[data-id="listView"]').isOpen;
    }

    loadMoreData() {
        this.dispatchEvent(new CustomEvent("loadmore"));
    }

    onMenuItemSelected(event) {
        let menuItemValue = event.target.dataset.id;
        this.selectedMenuItem = this.menuItems.filter(item => item.value === menuItemValue)[0];
        if (this.selectedMenuItem.isModal) {
            this.template.querySelector('[data-id="modal"]').open();
        }
    }

    onListViewFilterClicked() {
        this.filterButtonState = !this.filterButtonState;
        this.template.querySelector('c-hd_-list_-view_-filter_-expression').isOpen = this.filterButtonState;
    }

    onIncidentSummaryClicked() {
        this.summaryButtonState = !this.summaryButtonState;
        this.template.querySelector('c-hd_-incident_-preview').isOpen = this.filterButtonState;
    }

    get modalTitle() {
        return this.selectedMenuItem?.label;
    }

    onListViewSelected(event) {
        if (this.selectedListView?.listReference.id !== event.detail.listView.Id) {
            // this.selectedListView = event.detail.listView;
            this.dispatchEvent(new CustomEvent("listitemselected", {
                detail: {
                    listView: event.detail.listView
                },
                bubbles: true,
                isComposed: true
            }));
        }
    }

    handleQuickActionClick(event) {
        this.dispatchEvent(new CustomEvent("quickactionclicked", {
            detail: {
                quickAction: event.target.label
            },
            bubbles: true,
            isComposed: true
        }));
    }

    onRowActionPerformed(event) {
        this.dispatchEvent(new CustomEvent("rowclicked", {
            detail: {
                row: event.detail.row
            },
            bubbles: true,
            isComposed: true
        }));
    }

    handleSubmit() {
        if (this.showFieldsToDisplay) {
            let selectColumnsContent = this.template.querySelector('[data-id="selectColumns"]');
            this.dispatchEvent(new CustomEvent('menuitemsvaluechanged', {
                detail: {
                    data: selectColumnsContent?.updatedOptions,
                    eventId: 'selectFields'
                },
                bubbles: true,
                isComposed: true
            }));
        }

        this.template.querySelector('[data-id="modal"]').close();
    }

    handleRefresh(evt) {
        this.dispatchEvent(new CustomEvent('refresh', {
            bubbles: true,
            isComposed: true
        }));
        const buttonIcon = evt.target.querySelector('.slds-button__icon');
        buttonIcon.classList.add('refreshRotate');
        // return refreshApex(this.wiredActivities)
        //     .then(() => {
        //         buttonIcon.classList.remove('refreshRotate');
        //     });
        // setTimeout(() => {
        //     this.isLoadingRecords = false;
        // }, 5000);
    }

    handleCancel() {
        this.template.querySelector('[data-id="modal"]').close();
    }

    handleRecordSearch(event) {
        this.dispatchEvent(new CustomEvent('recordsearch', {
            detail: {
                searchString: event.target.value
            },
            bubbles: true,
            isComposed: true
        }));
    }

    get showSharingSettings() {
        return this.selectedMenuItem?.value === 'SharingSettings';
    }

    get showFieldsToDisplay() {
        return this.selectedMenuItem?.value === 'SelectFields';
    }

    get showRenameView() {
        return this.selectedMenuItem?.value === 'Rename';
    }

    get disableSave() {
        return this.selectedMenuItem?.value === 'SharingSettings';
    }

    get selectedListViewName() {
        return this.selectedListView?.label;
    }

    get titleClass() {
        return (this.isTitleHovered) ? 'slds-page-header__name titleHover' : ' slds-page-header__name';
    }

    get recordCount() {
        return (this.numberOfRecords === 1) ? '1 item' : (this.numberOfRecords ?? 0) + ' items';
    }

    get sortedBy() {
        let column = this.columns.filter(localColumn => this.sortBy === localColumn.fieldName);
        return (column && column.length > 0) ? column[0].label : '';
    }
}