import { LightningElement, api } from 'lwc';
//import the static resource
import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/scPaginationCss";
import {LABELS} from './i18n';
export default class ScPagination extends LightningElement {

    label = LABELS;
    _recordCount = 1000;
    @api get recordCount() {
        return this._recordCount;
    } 
    set recordCount(val) {
        this._recordCount = val;
        this._selectedPageNumber = '1';
        this.fireOnSelectEvent();
    }

    _records;
    @api get records() {
        return this._records;
    } 
    set records(val) {
        this._records = val;
        this._recordCount = val.length;
        this._selectedPageNumber = '1';
        this.fireOnSelectEvent();
    }
    @api maxPaginationButtons = 15;

    @api pageSizeButtons = [10, 25, 50, 100];

    _pageSize = 10;
    @api get pageSize() {
        return this._pageSize;
    }
    set pageSize(val) {
        this._pageSize = val;
    }

    // Selected Page Number, fire on select event on change of selectedPageNumber
    _selectedPageNumber = '1';
    @api get selectedPageNumber() {
        return this._selectedPageNumber;
    } 
    set selectedPageNumber(val) {
        this._selectedPageNumber = val;
    }

    // Page Size Options
    get pageSizeButtonsInfo() {
        const buttonInfo = this.pageSizeButtons.map(el => {
            return {label: el.toString(), 
                    value: el.toString(), 
                    css: el.toString() === this.pageSize.toString()
                                        ? 'btn btn-default active':  'btn btn-default '};
        });

        return buttonInfo;

    }

    // Max number of pages
    get numberOfPages() {
        return Math.ceil(this.recordCount / this.pageSize);
    }

    // convert labels and values to string and return options object => {label, value}
    getOption(label, value) {
        return { label: label.toString(), value: (value || label).toString() };
    }

    _paginationOptions;
    get paginationOptions() {

        // Building page buttons, start with selected page
        // add the  previous pages in sequence  at the beginning of page options array
        // add the  next page in sequence at the end of page options array
        const pageOptions = [this.getOption(this.selectedPageNumber)];

        // let prevPageCount = 0;
        // let nextPageCount = 0;

        for (let i = 0; i < this.maxPaginationButtons; i++) {
            const firstButtonVal = this.parseInt(pageOptions[0].value);
            const lastButtonVal = this.parseInt(pageOptions[pageOptions.length - 1].value);

            // add the  previous pages in sequence  at the beginning of page options array
            if (firstButtonVal > 1 && pageOptions.length < this.maxPaginationButtons) {
                pageOptions.unshift(this.getOption(firstButtonVal - 1));
            }
            // add the  next page in sequence at the end of page options array
            if (lastButtonVal < this.numberOfPages && pageOptions.length < this.maxPaginationButtons) {
                pageOptions.push(this.getOption(lastButtonVal + 1));
            }
        }

        const firstButtonVal = this.parseInt(pageOptions[0].value);
        const lastButtonVal = this.parseInt(pageOptions[pageOptions.length - 1].value);

        // Once the buttons are calculated, if first button is not 1
        // replace first two buttons with 1 and continuation indicator '...' 
        if (firstButtonVal !== 1) {
            pageOptions[0] = this.getOption(1);
            pageOptions[1] = this.getOption('...', 'first_continuation');
        }
        // Once the buttons are calculated, if last button is not numberOfPages( aka last page)
        // replace last two buttons with continuation indicator '...' and numberOfPages( aka last page) 
        if (lastButtonVal !== this.numberOfPages) {
            pageOptions[pageOptions.length - 1] = this.getOption(this.numberOfPages);
            pageOptions[pageOptions.length - 2] = this.getOption('...', 'last_continuation');
        }
        this._paginationOptions = pageOptions;

        return pageOptions;
    }

    // Navigate to previous page ( Only if selectedPage !== 1)
    handlePrevious() {
        if (this.selectedPageNumber > 1) {
            this._selectedPageNumber = (this.parseInt(this.selectedPageNumber) - 1).toString();
            this.fireOnSelectEvent();
        }
    }

    // Navigate to next page, Only if selectedPage < this.numberOfPages(aka lastPage)
    handleNext() {
        if (this.selectedPageNumber < this.numberOfPages) {
            this._selectedPageNumber = (this.parseInt(this.selectedPageNumber) + 1).toString();
            this.fireOnSelectEvent();
        }
    }

    //  On Page Number change, recalculate the page buttons and fire onselect event
    handlePageNumberChange(ev) {

        const selectedvalue = ev.detail.value;
        if (selectedvalue === 'first_continuation') {
            this._selectedPageNumber = (this.parseInt(this._paginationOptions[2].value) - 1).toString();
        } else if (selectedvalue === 'last_continuation') {
            this._selectedPageNumber = (this.parseInt(this._paginationOptions[this._paginationOptions.length - 3].value) + 1).toString();
        }
        else{
            this._selectedPageNumber = selectedvalue;
        }
        this.fireOnSelectEvent();
    }

    // On Page Size change, reset selected page to '1' and recalcuate page buttons
    handlePageSizeChange(ev) {
        this._pageSize = ev.currentTarget.value || ev.target.value;
        this._selectedPageNumber = '1';
        this.fireOnSelectEvent();
    }

    // fire on select event, pass selectd page, index of first and last record in selected page, page size
    fireOnSelectEvent() {
        const firstRecordIndex = ((this.selectedPageNumber - 1) * this.pageSize);
        const lastRecordIndex = ((this.selectedPageNumber * this.pageSize) < this.recordCount
                                                        ?(this.selectedPageNumber * this.pageSize)
                                                        : this.recordCount) -1;
        const eventPayload = {firstRecordIndex, lastRecordIndex, selectedPageNumber: this.selectedPageNumber, pageSize: this.pageSize};

        this.dispatchEvent(new CustomEvent('select', {detail:  eventPayload}));
        console.log('firing Event');
    }

    connectedCallback() {
        this.fireOnSelectEvent();
        loadStyle(this, staticStyleSheet);        
    }
    parseInt(val) {
        return parseInt(val, 10);
    }
}