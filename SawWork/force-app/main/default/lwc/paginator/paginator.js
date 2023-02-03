/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-20-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-20-2021   apyati   Initial Version
**/
import { LightningElement, api, track } from 'lwc';

const DELAY = 300;
const recordsPerPage = [10, 25, 50, 100];
const pageNumber = 1;
const showIt = 'visibility:visible';
const hideIt = 'visibility:hidden'; //visibility keeps the component space, but display:none doesn't
export default class Paginator extends LightningElement {
    @api showSearchBox = false; //Show/hide search box; valid values are true/false
    @api showPagination; //Show/hide pagination; valid values are true/false
    @api pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
    @api totalRecords; //Total no.of records; valid type is Integer
    @api records; //All records available in the data table; valid type is Array 
    @track pageSize; //No.of records to be displayed per page
    @track totalPages; //Total no.of pages
    @track pageNumber = pageNumber; //Page number
    @track searchKey; //Search Input
    @track controlPagination = showIt;
    @track controlPrevious = hideIt; //Controls the visibility of Previous page button
    @track controlNext = showIt; //Controls the visibility of Next page button
    recordsToDisplay = []; //Records to be displayed on the page

    //Called after the component finishes inserting to DOM
    connectedCallback() {
        console.log('Paginatior--> connectedCallback()');
        if (this.pageSizeOptions && this.pageSizeOptions.length > 0)
            this.pageSize = this.pageSizeOptions[0];
        else {
            this.pageSize = this.totalRecords;
            this.showPagination = false;
        }
        this.controlPagination = this.showPagination === false ? hideIt : showIt;
        this.setRecordsToDisplay();
    }

    handleRecordsPerPage(event) {
        console.log('Paginatior--> handleRecordsPerPage()');
        this.pageSize = event.target.value;
        this.setRecordsToDisplay();
    }
    handlePageNumberChange(event) {
        console.log('Paginatior--> handlePageNumberChange()');

        if (event.keyCode === 13) {
            this.pageNumber = event.target.value;
            this.setRecordsToDisplay();
        }
    }
    previousPage() {
        console.log('Paginatior--> previousPage()');

        this.pageNumber = this.pageNumber - 1;
        this.setRecordsToDisplay();
    }
    nextPage() {
        console.log('Paginatior--> nextPage()');

        this.pageNumber = this.pageNumber + 1;
        this.setRecordsToDisplay();
    }

    @api
    setRecordsToDisplay() {
        console.log('Paginatior--> setRecordsToDisplay()');

        this.recordsToDisplay = [];
        if (!this.pageSize)
            this.pageSize = this.totalRecords;

        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

        this.setPaginationControls();

        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) break;
            this.recordsToDisplay.push(this.records[i]);
        }
        this.dispatchEvent(new CustomEvent('paginatorchange', { detail: this.recordsToDisplay })); //Send records to display on table to the parent component
    }
    setPaginationControls() {
        console.log('Paginatior--> setPaginationControls()');
        //Control Pre/Next buttons visibility by Total pages
        if (this.totalPages === 1) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        } else if (this.totalPages > 1) {
            this.controlPrevious = showIt;
            this.controlNext = showIt;
        }
        //Control Pre/Next buttons visibility by Page number
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
            this.controlPrevious = hideIt;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
            this.controlNext = hideIt;
        }
        //Control Pre/Next buttons visibility by Pagination visibility
        if (this.controlPagination === hideIt) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        }
    }
    handleKeyChange(event) {
        console.log('Paginatior--> handleKeyChange()');
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if (searchKey) {
            this.delayTimeout = setTimeout(() => {
                this.controlPagination = hideIt;
                this.setPaginationControls();

                this.searchKey = searchKey;
                let filteredRecords = this.records.filter(rec => JSON.stringify(rec).toLocaleLowerCase().includes(searchKey.toLocaleLowerCase()));
                if (filteredRecords && filteredRecords.length > 200) {
                    this.recordsToDisplay = filteredRecords.slice(0, 200);
                } else {
                    this.recordsToDisplay = filteredRecords;
                }
                this.dispatchEvent(new CustomEvent('paginatorchange', { detail: this.recordsToDisplay })); //Send records to display on table to the parent component
            }, DELAY);
        } else {
            this.controlPagination = showIt;
            this.setRecordsToDisplay();
        }
    }
}