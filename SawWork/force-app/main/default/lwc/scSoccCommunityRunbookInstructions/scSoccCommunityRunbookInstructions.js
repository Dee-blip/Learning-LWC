// eslint-disable-next-line @lwc/lwc/no-async-operation
import { LightningElement,track,api } from 'lwc';
import {LABELS} from './i18n';
import fetchInstructions from '@salesforce/apex/SC_SOCC_CommunityController.fetchInstructions';
import CASE_FIELD from '@salesforce/schema/Instruction__c.Case__c';
import HANDLER_FIELD from '@salesforce/schema/Instruction__c.Handler__c';
//import scRichtextareaComponent from './scRichtextareaComponent';

//const DELAY = 200;
const columns = [
    {
        label: LABELS.INSTRUCTION_NAME_COLUMN, //'Instruction Name'
        fieldName: 'instructionRecName',
        type: 'text',
        typeAttributes: { label: { fieldName: 'instructionRecName' }, tooltip: 'Go to Instruction', target: '_blank' },
        sortable: true,
        initialWidth: 120, 
    },
    {
        label: LABELS.CASE_COLUMN, //'Case'
        fieldName: 'instructionRecAKAMCaseNumber',
        type: 'text',
        typeAttributes: { label: { fieldName: 'instructionRecAKAMCaseNumber' }, tooltip: 'Go to Case', target: '_blank' },
        sortable: true,
        initialWidth: 110, 
    },
    {
        label: LABELS.HANDLER_COLUMN, //Handler'
        fieldName: 'instructionHandlerRecName',
        type: 'text',
        sortable: true,
        initialWidth: 120, 
    },
    {
        label: LABELS.INSTRUCTION_TYPE_COLUMN, //'Instructions Type'
        fieldName: 'instructionRecType',
        type: 'text',
        sortable: true,
        initialWidth: 150, 
    },
    {
        label: LABELS.STATUS_COLUMN, //'Status'
        fieldName: 'instructionRecStatus',
        type: 'text',
        sortable: true,
        initialWidth: 104, 
    },
    {
        label: LABELS.CREATEDBY_COLUMN, //'Created By'
        fieldName: 'instructionRecCreatedBy',
        type: 'text',
        sortable: true,
        initialWidth: 120, 
    },
    {
        label: LABELS.CREATED_DATE_COLUMN, //'Created Date'
        fieldName: 'instructionRecCreatedDate',
        type: 'text',
        sortable: true,
        initialWidth: 150, 
    },
    { 
        label: LABELS.SUGGESTED_INSTR_COLUMN, //'Suggested Instructions'
        type: 'richtextarea', 
        typeAttributes: { 
            richtextareaValue:{ fieldName: 'instructionRecValue' },
            tooltip: { fieldName: 'instructionRecValueDisplay' }
        },
        cellAttributes:{height:'30px'}
    },
];

export default class ScSoccCommunityRunbookInstructions extends LightningElement {
    @api recordId;

    labels = LABELS;
    @track error;
    @track instructionList = [];;
    @track instructionDataCopy = [];
    @track slicedInstructionList = [];
    @track columns = columns;
    @track caseField = CASE_FIELD;
    @track handlerField = HANDLER_FIELD;
    @track sortBy = 'instructionRecCaseUrl';
    @track sortDirection = 'asc';
    //activeSections = [];
    @track pageSize = 10;

    totalInstructions = 0;
    offset = 1;
    paginationNumbers;
    showPagination = true;

    @track currentpage

    connectedCallback() {
        //let urlParams = new URLSearchParams(window.location.search);
        //let pdRecordId = urlParams.get('recordId');
        //let pdRecordId = 'iCbRoG%2BaFGXacuBpzugNyA%3D%3D'; 
        let pdRecordId = window.location.href.split('recordId=')[1];
        
        if(pdRecordId !== null){
            fetchInstructions({pdId:pdRecordId}).then((data) => {
                this.instructionList = data;
                this.instructionDataCopy = data;
                this.totalInstructions = data.length;
                this.calculatepaginationlogic();
            }).catch((error) => {
                this.instructionList = undefined;
                console.log('error ', error);
            })
        }
    }
    @api 
    searchInstructions(searchFilter){
        let allInstructionData = this.instructionList;
        let tempArray = [];

        searchFilter = searchFilter.toUpperCase();
        allInstructionData.forEach(function (eachRow) {
            if ((eachRow.instructionRecName && eachRow.instructionRecName.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.instructionRecCaseNumber && eachRow.instructionRecCaseNumber.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.instructionRecType && eachRow.instructionRecType.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.instructionRecStatus && eachRow.instructionRecStatus.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.instructionHandlerRecName && eachRow.instructionHandlerRecName.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.instructionRecValue && eachRow.instructionRecValue.toUpperCase().indexOf(searchFilter) !== -1)
            ) {
                tempArray.push(eachRow);
            }
        });
        this.instructionDataCopy = tempArray;

        this.totalInstructions = this.instructionDataCopy.length;
        this.calculatepaginationlogic();

        /*
        Search for accordian sections
        //Search Term
        let searchTerm = searchFilter;
        //All data
        let allData = this.instructionList;
        //Table data
        let data = this.slicedInstructionList;
        
        // check is data is not undefined and its lenght is greater than 0
        if(data!=undefined || data.length>0)
        {
            // filter method create a new array that passes the search criteria (provided as function)  
            let filteredData = Object.values(allData).filter(
                word => (!searchTerm) || 
                word.instructionRecName.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || 
                word.instructionRecAKAMCaseNumber.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || 
                word.instructionRecStatus.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 ||
                word.instructionRecType.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 ||
                word.instructionHandlerRecName.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 ||
                word.instructionRecValue.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1);  
            this.slicedInstructionList = filteredData;
        }
        */
    }

    updateColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;

        this.sortBy = fieldName;
        this.sortDirection = sortDirection;

        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        if (fieldname === 'instructionRecUrl')
            fieldname = 'instructionRecName';
        else if (fieldname === 'instructionRecCaseUrl')
            fieldname = 'instructionRecCaseNumber';

        let parseData = JSON.parse(JSON.stringify(this.slicedInstructionList));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.slicedInstructionList = parseData;
    }

    calculatepaginationlogic()
    {
        if(!this.pageSize)
            this.pageSize = this.totalInstructions;

        if(this.totalInstructions === 0)
        {
            this.paginationNumbers = 1;
            this.showPagination = false;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalInstructions / this.pageSize);
            this.showPagination = true;
        }
        if(this.offset>this.paginationNumbers) this.offset=1;
        
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        //this.instructionDataCopy = this.instructionList.slice((this.offset - 1) * this.pageSize, this.offset * this.pageSize);
        this.slicedInstructionList = this.instructionDataCopy.slice((this.offset - 1) * this.pageSize, this.offset * this.pageSize);

        window.clearTimeout(this.delayTimeout);
        this.disableEnableActions();
        
        /*this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);*/
    }
    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");

        buttons.forEach(bun => {
            /*if (bun.label === this.pageNo) {
                bun.disabled = true;
            } else {
                bun.disabled = false;
            }*/

            if (bun.label === "First") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Previous") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Next") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            } else if (bun.label === "Last") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            }
        });
    }
    handlePageClick(event) {
        let label = event.target.label;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleNext() {
        this.offset += 1;
        this.calculatepaginationlogic();
    }

    handlePrevious() {
        this.offset -= 1;
        this.calculatepaginationlogic();
    }

    handleFirst() {
        this.offset=1;
        this.calculatepaginationlogic();
    }

    handleLast() {
        this.offset=this.paginationNumbers;
        this.calculatepaginationlogic();
    }

    /*@api
    expandAll(){
        this.activeSections = this.slicedInstructionList.map(slicedInstructionList=>slicedInstructionList.instructionRecName);
    }

    @api
    collapseAll(){
        this.activeSections = [];
    }*/
}